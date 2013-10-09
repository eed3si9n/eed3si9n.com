  [1]: https://github.com/sbt/sbt/blob/541375cde65635a7d2c6132d1ed96aaaefb38466/util/collection/src/main/scala/sbt/Settings.scala#L414
  [2]: https://github.com/sbt/sbt/blob/541375cde65635a7d2c6132d1ed96aaaefb38466/main/settings/src/main/scala/sbt/Structure.scala#L116
  [3]: https://github.com/sbt/sbt/blob/541375cde65635a7d2c6132d1ed96aaaefb38466/main/settings/src/main/scala/sbt/Structure.scala#L138
  [4]: https://github.com/sbt/sbt/blob/541375cde65635a7d2c6132d1ed96aaaefb38466/main/settings/src/main/scala/sbt/std/InputWrapper.scala#L93
  [5]: http://www.scala-sbt.org/0.13.0/docs/Extending/Plugins-Best-Practices.html
  [6]: https://github.com/sbt/sbt-assembly
  [7]: https://github.com/sbt/sbt-assembly/blob/dcbc1a41faa5baa26c048993ca4e6ce280b96946/src/main/scala/sbtassembly/Plugin.scala#L360
  [8]: http://www.scala-sbt.org/0.13.0/docs/Getting-Started/Scopes.html
  [9]: http://stackoverflow.com/questions/18611316
  [10]: http://stackoverflow.com/questions/19201509
  [11]: https://github.com/akka/akka/blob/e05d30aeaacdb99ea25718bb5de6118fbb37f3ae/project/Unidoc.scala
  [12]: https://github.com/sbt/sbt-unidoc
  [13]: http://www.scala-sbt.org/0.13.0/docs/Detailed-Topics/Tasks.html#getting-values-from-multiple-scopes
  [202]: https://github.com/sbt/sbt/issues/202

Warning: This is a memo about sbt for intermediate users.

### setting system

At the heart of sbt 0.13 is the setting system, just like sbt 0.12. Let's look at [Settings.scala][1]:

<scala>
trait Init[Scope] {
  ...

  final case class ScopedKey[T](
    scope: Scope,
    key: AttributeKey[T]) extends KeyedInitialize[T] {
    ...
  }

  sealed trait Initialize[T] {
    def dependencies: Seq[ScopedKey[_]]
    def evaluate(map: Settings[Scope]): T
    ...
  }

  sealed class Setting[T] private[Init](
    val key: ScopedKey[T], 
    val init: Initialize[T], 
    val pos: SourcePosition) extends SettingsDefinition {
    ...
  }
}
</scala>

If we ignore `pos` for now, a setting of `T` consists of the lhs `key` whose type is `ScopedKey[T]`, and the rhs `init` whose type is `Initialize[T]`.

### first dimension

For simplicity, we can think of `ScopedKey[T]` to be `SettingKey[T]` and `TaskKey[T]` scoped in the default context like the current project. Then all we have left is essentially `Initialize[T]`, which has a sequence of dependent keys and some potential to evaluate to `T`. The operator that works directly with `Initialized[T]` is `<<=` implemented in the keys. See [Structure.scala][2]:

<scala>
sealed trait DefinableSetting[T] {
  final def <<= (app: Initialize[T]): Setting[T] = 
    macro std.TaskMacro.settingAssignPosition[T]
  ...
}
</scala>

Guessing from its name, the macro is assigning `pos`. In sbt 0.12, `Initialize[T]` was constructed by calling monkey-patched `apply` or `map` method on tuple of keys. In sbt 0.13, there is nicer `:=` operator. See [Structure.scala][3]:

<scala>
sealed trait DefinableTask[T] {
  def := (v: T): Setting[Task[T]] = 
    macro std.TaskMacro.taskAssignMacroImpl[T]
}
</scala>

Plain `:=` operator expects an argument of type `T` and it creates an instance of `Setting[T]` or `Setting[Task[T]]` supposedly with an internal `Initalize[T]` instance. When the macro sees keys calling `value` method, it automatically converts the entire expression into a `<<=` expression.

<scala>
name := {
  organization.value + "-" + baseDirectory.value.getName
}
</scala>

is expanded into

<scala>
name <<= (organization, baseDirectory) { (o, b) =>
  o + "-" + b  
}
</scala>

This is nice because `:=` works the same for both settings and tasks.

<scala>
val startServer = taskKey[Unit]("start server.")
val integrationTest = taskKey[Unit]("integration test.")

integrationTest := {
  val x = startServer.value
  println("do something")
}

startServer := {
  println("start")
}
</scala>

`start.value` is evaluated at runtime based on the value associated with the key. This kind of task-to-task dependency can be found in other build tools like Ant. This is the primary dimension in sbt.

Where `:=` starts to break down a bit is when you try to define the task elsewhere.

<scala>
val orgBaseDirName = {
  organization.value + "-" + baseDirectory.value.getName
}

name := orgBaseDirName
</scala>

This will results in the following error:

<code>
build.sbt:14: error: `value` can only be used within a task or setting macro, such as :=, +=, ++=, Def.task, or Def.setting.
  organization.value + "-" + baseDirectory.value.getName
               ^
</code>

To wrap the block in the appropriate macro, we need to write it as:

<scala>
val orgBaseDirName: Def.Initialize[String] = Def.setting {
  organization.value + "-" + baseDirectory.value.getName
}

name := orgBaseDirName
</scala>

The type annotation on `orgBaseDirName` is not required, but it helps to know this clearly. The next error message is no surprise:

<code>
build.sbt:17: error: type mismatch;
 found   : sbt.Def.Initialize[String]
 required: String
name := orgBaseDirName
        ^
[error] Type error in expression
</code>

`:=` expects `String`, so we need to evaluate `Initialize[String]`. Interestingly, `value` method works here too. `value` method is defined in `MacroValue[T]`. See [InputWrapper.scala][4]:

<scala>
sealed abstract class MacroValue[T] {
  @compileTimeOnly("`value` can only be used within a task or setting macro, such as :=, +=, ++=, Def.task, or Def.setting.")
  def value: T = macro InputWrapper.valueMacroImpl[T]
}
</scala>

There's an implicit conversion that injects `value` method to anonymous `Initialize[T]` instances and setting keys (keys are `Initialize[T]` too).

### per-task settings

The second dimension in sbt is the task-scoping of keys. Task scoping had been there, but it has become more prominent through the sbt plugin community trying to figure out best use of keys. I had a small part to this along with [Brian (@bmc)](https://github.com/bmc), [Doug (@softprops)](https://github.com/softprops), [Josh (@jsuereth)](https://github.com/jsuereth), and [Mark (@harrah)](https://github.com/harrah). Two things that came out of numerous ML posts and irc chat were:

- [Plugins Best Practices][5]
- [sbt/sbt#202: Task-scoped keys][202]

Using [sbt/sbt-assembly][6] as example, `jarName` is customized as follows:

<scala>
import AssemblyKeys._

assemblySettings

jarName in assembly := "something.jar"
</scala>

This is a useful concept because it allows a setting to limit its effect within the build definition. Here's another example:

<scala>
import AssemblyKeys._

assemblySettings

test in assembly := {}
</scala>

`assembly` task, by default, runs `test` task before it creates a fat jar, but in the above the build user has suppressed the behavior. What's actually going on is that `assembly` task was written in a way such that it does not directly depend on the `test` task. Instead, it depends on `assembly::test` task. See [Plugin.scala][7]:

<scala>
private def assemblyTask(key: TaskKey[File]): Initialize[Task[File]] = Def.task {
  val t = (test in key).value
  val s = (streams in key).value
  Assembly((outputPath in key).value, (assemblyOption in key).value,
    (packageOptions in key).value, (assembledMappings in key).value,
    s.cacheDirectory, s.log)
}

lazy val baseAssemblySettings: Seq[sbt.Def.Setting[_]] = Seq(
  assembly := assemblyTask(assembly).value,
  ...
  test in assembly := (test in Test).value,
  ...
}
</scala>

By scoping `test` key into `assembly` task, sbt-assembly provides an extension point for the build user.

### configuration

Configuration is the third dimension in sbt that is not well understood. Getting Started guide's [Scopes][8] defines it as follows:

> A configuration defines a flavor of build, potentially with its own classpath, sources, generated packages, etc. The configuration concept comes from Ivy, which sbt uses for managed dependencies, and from [MavenScopes](http://maven.apache.org/guides/introduction/introduction-to-dependency-mechanism.html#Dependency_Scope).

The key point here is that a configuration has its own classpath and sources. The most widely used configuration besides the default one is `Test`. It has its own set of source code and libraries.

Regular syntax for scoping a key to a configuration is `key in Test` in Scala and `test:key` in the shell. Managed library is different since it uses `%` to denote the configuration for `libraryDependencies`.

<scala>
libraryDependencies += "org.specs2" %% "specs2" % "2.2.3" % "test"
</scala>

`% "test"` is short for `% "test->default"`, which grabs `Compile` artifacts from depenencies and puts them in `Test` configuration of this project.

It's relatively easy to define custom configuration. But building up the settings tree sometimes could be tricky. Some of the StackOverflow sbt questions I've answered boiled down to setting up configurations.

Take [Multiple executable jar files with different external dependencies from a single project with sbt-assembly][9] for instance. Here's the `build.sbt` that I posted:

<scala>
import AssemblyKeys._

val Dispatch10 = config("dispatch10") extend(Compile)
val TestDispatch10 = config("testdispatch10") extend(Dispatch10)
val Dispatch11 = config("dispatch11") extend(Compile)
val TestDispatch11 = config("testdispatch11") extend(Dispatch11)

val root = project.in(file(".")).
  configs(Dispatch10, TestDispatch10, Dispatch11, TestDispatch11).
  settings( 
    name := "helloworld",
    organization := "com.eed3si9n",
    scalaVersion := "2.10.2",
    compile in Test := inc.Analysis.Empty,
    compile in Compile := inc.Analysis.Empty,
    libraryDependencies ++= Seq(
      "net.databinder.dispatch" %% "dispatch-core" % "0.10.0" % "dispatch10", 
      "net.databinder.dispatch" %% "dispatch-core" % "0.11.0" % "dispatch11",
      "org.specs2" %% "specs2" % "2.2" % "testdispatch10",
      "org.specs2" %% "specs2" % "2.2" % "testdispatch11",
      "com.github.scopt" %% "scopt" % "3.0.0"
    )
  ).
  settings(inConfig(Dispatch10)(Defaults.configSettings ++ baseAssemblySettings ++ Seq(
    sources := (sources in Compile).value,
    resources := (resources in Compile).value,
    internalDependencyClasspath := Nil,
    test := (test in TestDispatch10).value,
    test in assembly := test.value,
    assemblyDirectory in assembly := cacheDirectory.value / "assembly-dispatch10",
    jarName in assembly := name.value + "-assembly-dispatch10_" + version.value + ".jar"
  )): _*).
  settings(inConfig(TestDispatch10)(Defaults.testSettings ++ Seq(
    sources := (sources in Test).value,
    resources := (resources in Test).value,
    internalDependencyClasspath := Seq((classDirectory in Dispatch10).value).classpath
  )): _*).
  settings(inConfig(Dispatch11)(Defaults.configSettings ++ baseAssemblySettings ++ Seq(
    sources := (sources in Compile).value,
    resources := (resources in Compile).value,
    internalDependencyClasspath := Nil,
    test := (test in TestDispatch11).value,
    test in assembly := test.value,
    assemblyDirectory in assembly := cacheDirectory.value / "assembly-dispatch11",
    jarName in assembly := name.value + "-assembly-dispatch11_" + version.value + ".jar"
  )): _*).
  settings(inConfig(TestDispatch11)(Defaults.testSettings ++ Seq(
    sources := (sources in Test).value,
    resources := (resources in Test).value,
    internalDependencyClasspath := Seq((classDirectory in Dispatch11).value).classpath
  )): _*)
</scala>

Given the identical source code for main and test, the above build sets up configurations that use Dispatch 0.10 and 0.11. Running `dispatch10:assembly` would create a fat jar using Dispatch 0.10, and running `dispatch11:assembly` would create a fat jar using Dispatch 0.11. This was possible due to the fact that sbt-assembly was designed to be configuration-neutral.

Another example that show cases configuration is [How to format the sbt build files with scalariform automatically?][10] Here's `scalariform.sbt`:

<scala>
import scalariform.formatter.preferences._
import ScalariformKeys._

lazy val BuildConfig = config("build") extend Compile
lazy val BuildSbtConfig = config("buildsbt") extend Compile

noConfigScalariformSettings

inConfig(BuildConfig)(configScalariformSettings)

inConfig(BuildSbtConfig)(configScalariformSettings)

scalaSource in BuildConfig := baseDirectory.value / "project"

scalaSource in BuildSbtConfig := baseDirectory.value

includeFilter in (BuildConfig, format) := ("*.scala": FileFilter)

includeFilter in (BuildSbtConfig, format) := ("*.sbt": FileFilter)

format in BuildConfig := {
  val x = (format in BuildSbtConfig).value
  (format in BuildConfig).value
}

preferences := preferences.value.
  setPreference(AlignSingleLineCaseStatements, true).
  setPreference(AlignParameters, true)
</scala>

Running `build:scalariformFormat` would format the `**.sbt` and `project/**.scala` files. This too was possible because sbt-scalariform is configuration-neutral. But because it uses `includeFilter` instead of `sources`, I had to create two configurations to do one job.

### ScopeFilter

There's a file called [Unidoc.scala][11] in Akka project that a few people knew about. It defines `unidoc` task which aggregates source code from all projects defined in the build, and runs Scaladoc on it. Very useful for any projects that modularizes build into small subprojects.

Naturally, my idea was to borrow the code and make it into [sbt-unidoc][12] plugin. Then a few weeks ago [@inkytonik](https://github.com/inkytonik) told me that he would like to run it for `Test` configuration. All this talk about configuration neutrality, and there I was.

When I got around to implementing the source aggregation across multiple projects and configurations, I stumbled across a gem added in sbt 0.13 called ScopeFilter. The details are described in [Getting values from multiple scopes][13].

> The general form of an expression that gets values from multiple scopes is:
>
>     <setting-or-task>.all(<scope-filter>).value
>
> The `all` method is implicitly added to tasks and settings. 

And here's the example aggregating all sources:

<scala>
val filter = ScopeFilter(inProjects(core, util), inConfigurations(Compile))
// each sources definition is of type Seq[File],
//   giving us a Seq[Seq[File]] that we then flatten to Seq[File]
val allSources: Seq[Seq[File]] = sources.all(filter).value
allSources.flatten
</scala>

All I had to do for sbt-unidoc was to create settings for `ProjectFilter` and `ConfigurationFilter` and let the user rewire it. Here's the example of exluding a project:

<scala>
val root = (project in file(".")).
  settings(commonSettings: _*).
  settings(unidocSettings: _*).
  settings(
    name := "foo",
    unidocProjectFilter in (ScalaUnidoc, unidoc) := inAnyProject -- inProjects(app)
  ).
  aggregate(library, app)
</scala>

and here's another example, which adds multiple configurations:

<scala>
val root = (project in file(".")).
  settings(commonSettings: _*).
  settings(unidocSettings: _*).
  settings(
    name := "foo",
    unidocConfigurationFilter in (TestScalaUnidoc, unidoc) := inConfigurations(Compile, Test),
  ).
  aggregate(library, app)
</scala>

Internally, I just run `all` on `sources`:

<scala>
val f = (unidocScopeFilter in unidoc).value
sources.all(f)
</scala>

The fourth dimension in sbt is the project, and we now have a vehicle to travel through the third and forth dimension. Where we take this is up to us.
