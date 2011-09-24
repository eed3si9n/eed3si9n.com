I've recently started looking at sbt 0.10 by porting some of the plugins. This isn't a full tutorial, and I might not have all the facts right, but I hope you find this useful, especially if you're writing a plugin.

## don't panic
If you've just landed from 0.7 world, sbt 0.10 is overwhelming. Take your time to understand the concepts, and I assure you that you'll get it in time, and really love it.

## three representations
There are three ways you may interact with sbt 0.10, which could be confusing at first.

1. shell, which you get when you start sbt 0.10.
2. Quick Configuration DSL, which goes into `build.sbt` or in `settings` sequence.
3. good old Scala code, aka Full Configuration.

Each representation fits into a different kind of usage model. When you're simply using sbt to build a project, you will mostly spend your time in the shell, issuing commands like `publish-local`. When you want to configure basic settings like library dependencies, you then move on to Quick Configuration DSL in `build.sbt`. Finally, when you're defining subprojects or writing a plugin, you still have the full power of Scala using Full Configuration.

## the basic concepts (key-value)
At the heart of sbt 0.10 is a key-value table called `settings`. For example, the name of the project is stored in a setting called `name` and it could be invoked from the shell as `name`:

    > name          
    [info] helloworld

What's interesting, is that `settings` not only stores static project settings, but it also stores tasks. An example of such task is `publishLocal` and it could be invoked from the shell as `publish-local`:

    > publish-local
    [info] Packaging /Users/eed3si9n/work/helloworld/target/scala-2.8.1.final/helloworld_2.8.1-0.1-sources.jar ...
    ....
    
In 0.7 these tasks would be declared as a method that returns `Task` object, like `publishLocalAction` method together with a lazy value that declares its dependencies. To modify the behavior of a task, you would override the underlying method. To reuse the behavior you could also directly invoke these methods, for example to package a jar file. 

In 0.10, both settings and tasks are just entries in `settings` sequence.

<scala>val name = SettingKey[String]("name", "Name.")
...
val publishLocal = TaskKey[Unit]("publish-local", "Publishes artifacts to the local repository.")</scala>
    
Since both settings and tasks are referred to by their key, it's essential to familiarize yourself with the key names if you're writing a plugin. [Key.scala][1] defines the predefined keys.

## settings vs tasks
Initially, it's not that important to know the difference between settings and tasks.
Settings are static values without side effects that only depend either on constants or other settings. In other words, these are values that can be cached, and will not change until the project is reloaded.

Tasks on the other hand may depend on external sources like file system, and may incur side effects like deleting a directory.

## the basic concepts (dependencies)
What makes sbt 0.10 interesting is that each entries in the `settings` can declare dependencies to the other keys. (When I say keys, I mean settings and tasks, but you get the idea)
For example, `publishLocalConfiguration`'s dependencies are declared as follows:

<scala>publishLocalConfiguration <<= (packagedArtifacts, deliverLocal, ivyLoggingLevel) map {
	(arts, ivyFile, level) => publishConfig(arts, Some(ivyFile), logging = level )
},</scala>

The above is an example of sbt 0.10's Quick Configuration DSL. It adds dependencies from `publishLocalConfiguration` to `packagedArtifacts`, `deliverLocal`, and `ivyLoggingLevel` and calculates the value by calling `publishConfig` using the values from dependent keys. What's more, you can wire any of the keys to an arbitrary value in `build.sbt` without any class inheritance.

The dependencies of a setting or a task can be checked from the shell using `inspect` command:

    > inspect publish-local
    [info] Task
    [info] Description:
    [info] 	Publishes artifacts to the local repository.
    [info] Provided by:
    [info] 	{file:/Users/eed3si9n/work/helloworld/}default/*:publish-local
    [info] Dependencies:
    [info] 	{file:/Users/eed3si9n/work/helloworld/}default/*:ivy-module
    [info] 	{file:/Users/eed3si9n/work/helloworld/}default/*:publish-local-configuration
    [info] 	{file:/Users/eed3si9n/work/helloworld/}default/*:streams(for publish-local)
    [info] Delegates:
    [info] 	{file:/Users/eed3si9n/work/helloworld/}default/*:publish-local
    [info] 	{file:/Users/eed3si9n/work/helloworld/}/*:publish-local    

## the basic concepts (scope aka configuration)
Another interesting aspect of the `settings` is that the entries as well as the declared dependencies can be scoped in a configuration.
What does that mean? Suppose you are defining a task called `assembly` that runs the test and creates an executable jar file. Here's how it could look in a plugin definition:
    
<scala>val assembly = TaskKey[Unit]("assembly")

lazy val assemblySettings: Seq[sbt.Project.Setting[_]] = Seq(
  assembly <<= (test in Test) map { _ =>
    // do something
  }
)</scala>

In the above code, `test in Test` is an example of a scoped key. In the shell, it could be invoked as `test:test`.

The user is somewhat stuck with the `test in Test` dependencies. We can improve this by creating our own scope called `Assembly`.

<scala>val Assembly = config("assembly")
val assembly = TaskKey[Unit]("assembly")

lazy val assemblySettings: Seq[sbt.Project.Setting[_]] = Seq(
  assembly <<= (test in Assembly) map { _ =>
    // do something
  },
  test in Assembly <<= (test in Test) map { x => x }
)</scala>

Should the user choose not to run the tests, he or she can override `test in Assembly` without compromising the main `test` task. This feature is so useful Mark provided a convenient shorthand called `inConfig`, which automatically puts the sequence of settings into a scope. Every time I wrote `map { x => x}` it felt dirty, because feels like a boilerplate. Today Mark told me that I can write this as `identity` in the mailing list. The above could be rewritten as follows:
    
<scala>val Assembly = config("assembly")
val assembly = TaskKey[Unit]("assembly")

lazy val assemblySettings: Seq[sbt.Project.Setting[_]] = inConfig(Assembly)(Seq(
  assembly <<= (test) map { _ =>
    // do something
  },
  test <<= (test in Test).identity
)) ++
Seq(
  assembly <<= (assembly in Assembly).identity
)</scala>

The scoping rids the need to put prefixes to all the methods and fields in the plugin, and instead encourages the reuse of general keys.

**Edit (9/16/2011)**:
sbt imports all members of the plugins. To avoid naming conflict, Josh Suereth has come up with a pattern to work around this issue, described in [SBT and Plugin design][27]. Here's a modified version:

<scala>val assembly = TaskKey[Unit]("assembly")
  
class Assembly {}  
object Assembly extends Assembly {
  val Config = config("assembly")
  implicit def toConfigKey(x: Assembly): ConfigKey = ConfigKey(Config.name)
  
  lazy settings: Seq[sbt.Project.Setting[_]] = inConfig(Config)(Seq(
    assembly <<= (test) map { _ =>
      // do something
    },
    test <<= (test in Test).identity
  )) ++
  Seq(
    assembly <<= (assembly in Config).identity
  ) 
}</scala>

## read the documents, source, and other's source
The [the official wiki][2] is full of useful information. It feels a bit scattered, but you can usually find information if you know what you're looking for. Here are links to some useful pages:
- [Migrating from SBT 0.7.x to 0.10.x][8]
- [Settings][3]
- [Basic Configuration][4]
- [Full Configuration][11]
- [Library Management][5]
- [Plugins][9]
- [Task Basics][6]
- [Common Tasks][7]
- [Mapping Files][10]

When you're looking for an example, source often is the quickest place to find the answer. Scala X-Ray and scaladocs make it easy to navigate from one source to the other.
- [SXR Documentation][21]
- [API Documentation][22]

In a mailing list thread titled [Adrift in a sea of types][12] Mark mentions three sources:
- [Default.scala][13] ("All of the built in settings are defined there.")
- [Keys.scala][1] ("The keys are in Keys.")
- [Structure.scala][14] ("Most of these [implicit conversions] are in Scoped, which is in Structure.scala.")

## read other plugins
When you're starting out on writing a plugin, you can learn many tricks by reading [other plugin's source][18]. Here are the samples that I've used:
- [eed3si9n/sbt-assembly][16]
- [softprops/coffeescripted-sbt][15]
- [siasia/xsbt-web-plugin][19]
- [Proguard.scala][17]
- [ijuma/sbt-idea][20]
- [jsuereth/xsbt-ghpages-plugin][28]

## learn the small changes from 0.7
What motivated me to write this guide is all the renames and changes that I stumbled while porting  [codahale/assembly-sbt][23] to sbt 0.10 as [eed3si9n/sbt-assembly][16]. We can see both plugins side by side and see what changed.

### version number
before (in build.properties):
<scala>project.version=0.1.1
</scala>

after (in build.sbt):
<scala>posterousNotesVersion := "0.4"

version <<= (sbtVersion, posterousNotesVersion) { (sv, nv) => "sbt" + sv + "_" + nv }</scala>

Unlike 0.7 plugins that were distributed as source package, 0.10 plugins are packaged as binary. This adds dependency to the exact version of sbt. So far there was been 0.10.0 and 0.10.1 already, and plugins compiled against 0.10.0 does not work against 0.10.1. As a workaround, I have adopted the above versioning convention. Likely, there will be some solution in the future. Stay tuned.

### super class
before:
<scala>package assembly

trait AssemblyBuilder extends BasicScalaProject {
</scala>

after:
<scala>package sbtassembly
  
object Plugin extends sbt.Plugin { 
</scala>

So the change shows the subtle, but important differences in where the plugin stands in sbt 0.10. In 0.7 plugin was a trait mixed into your project object ("is-a" relationship). In 0.10, it's a library loaded into the project's execution environment ("has-a" relationship).

### where the settings go
before:<br>
in the trait.

after:
<scala>
  ...
  lazy val settings: Seq[sbt.Project.Setting[_]] = inConfig(Config)(Seq(
    ...
  ))</scala>

Instead of defining methods to be overridden, for plugins, we create a sequence of `sbt.Project.Setting[_]` that the user can load using `seq(...)`. This allows the build authors to decide whether to include the plugin settings or not. The only exception is if you're defining a global command, in which case you would override `settings`.

### settings that are meant to be overridden
before:
<scala>  def assemblyJarName = name + "-assembly-" + this.version + ".jar"
</scala>

after:
<scala>object Assembly extends Assembly {
  ...
  lazy val jarName           = SettingKey[String]("jar-name") in Config
  ...
  lazy val settings: Seq[sbt.Project.Setting[_]] = inConfig(Config)(Seq(
    jarName <<= (name, version) { (name, version) => name + "-assembly-" + version + ".jar" },
    ...
  ))
}</scala>

Define an entry in the `settings` with declared dependencies to other keys (`name` and `version`). Quick Configuration DSL adds [an injected method `apply`][24] to the pair, so you can pass in a function value to calculate the value of `jarName` key. Thanks to scoping and modularity, we can also name this `jarName` without the prefix. Because this is wrapped in `Assembly` object, it can be referred to in build.sbt as `Assembly.jarName`.

### static type of Quick Configuration DSL is `Initialize[A]`
before:
<scala>  def assemblyTask(...)

  lazy val assembly = assemblyTask(...) dependsOn(test) describedAs("Builds an optimized, single-file deployable JAR.")</scala>

after:
<scala>  val assembly = TaskKey[File]("assembly", "Builds a single-file deployable jar.")
  ...
  private def assemblyTask: Initialize[Task[File]] = 
    (test, ...) map { (t, ...) =>
    }
  
  lazy val settings: Seq[sbt.Project.Setting[_]] = inConfig(Config)(Seq(
    assembly <<= assemblyTask,
    ...
  ))  
</scala>

You can stuff everything in `settings`, but that quickly becomes cluttered, so I started to clean it up inspired by Keith Irwin's [coffeescripted-sbt][15] implementation. 

### `outputPath` is `target`, and `Path` is `sbt.File`
before:
<scala>  def assemblyOutputPath = outputPath / assemblyJarName
</scala>

after:
<scala>  val outputPath        = SettingKey[File]("output-path")
  ...
  lazy val settings: Seq[sbt.Project.Setting[_]] = inConfig(Config)(Seq(
    outputPath <<= (target, jarName) { (t, s) => t / s },
    ...
  ))</scala>

What used to be called `outputPath` is now a key called `target: SettingKey[File]`.

`sbt.File` is an alias to `java.io.File`, which implicitly converts to `sbt.RichFile`, which replaces `Path` in 0.7. So just say `dir: File`, and you can write `dir / name`.

### `runClasspath` is `fullClasspath in Runtime`
before:
<scala>  def assemblyClasspath = runClasspath
</scala>

after:
<scala>  lazy val settings: Seq[sbt.Project.Setting[_]] = inConfig(Config)(Seq(
    fullClasspath <<= (fullClasspath in Runtime).identity,
    ...
  ))</scala>
  
### reuse existing keys
before:
<scala>  def assemblyClasspath = runClasspath
</scala>

after:
<scala>  lazy val settings: Seq[sbt.Project.Setting[_]] = inConfig(Config)(Seq(
    fullClasspath <<= (fullClasspath in Runtime).identity,
    ...
  ))</scala>

So `fullClasspath in Assembly` is seeded with the value from `fullClasspath in Runtime`, but if the user wants to he or she can override it later, but without defining a hook method. Neat, right?

### a classpath is a `Classpath`, not `Pathfinder`
before:
<scala>  classpath: Pathfinder
</scala>

after:
<scala>  classpath: Classpath
</scala>

### functions that are meant to be overridden
before:
<scala>  def assemblyExclude(base: PathFinder) =
    (base / "META-INF" ** "*") --- 
      (base / "META-INF" / "services" ** "*") ---
      (base / "META-INF" / "maven" ** "*")</scala>
      
after:
<scala>  val excludedFiles     = SettingKey[Seq[File] => Seq[File]]("excluded-files")  

  private def assemblyExcludedFiles(base: Seq[File]): Seq[File] =
    ((base / "META-INF" ** "*") ---
      (base / "META-INF" / "services" ** "*") ---
      (base / "META-INF" / "maven" ** "*")).get
      
  lazy val settings: Seq[sbt.Project.Setting[_]] = inConfig(Config)(Seq(
    excludedFiles := assemblyExcludedFiles _,
    ...
  ))</scala>

This is slightly complicated. Since sbt 0.10 no longer relies on inheritance for overriding the behaviors, we need to track the method into key-value `settings`. In Scala, you need the method into a function value to assign it to a variable, so we have `assemblyExcludedFiles _`. The type of this function value is `Seq[File] => Seq[File]`.

### prefer `Seq[File]` over `Pathfinder`
before:
<scala>  base: PathFinder
</scala>

after:
<scala>  base: Seq[File]
</scala>

`Seq[File]` can be converted into `Pathfinder` implicitly, and 0.10 way is to use normal Scala types like `File` and `Seq[File]` where it's exposed for extension.

### `##` is done via file mapping
before:
<scala>  val base = (Path.lazyPathFinder(tempDir :: directories) ##)
  (descendents(base, "*") --- exclude(base)).get</scala>
  
after:
<scala>  val base = tempDir +: directories
  val descendants = ((base ** (-DirectoryFilter)) --- exclude(base)).get
  descendants x relativeTo(base)</scala>

See [Mapping Files][25] for the details.
> Tasks like `package`, `packageSrc`, and `packageDoc` accept mappings from an input file to the path to use in the resulting artifact (jar).

Using `x` method you can generate mappings.

### `FileUtilities` is `IO`
before:
<scala>  FileUtilities.clean(assemblyConflictingFiles(tempDir), true, log)
</scala>

after:
<scala>  IO.delete(conflicting(Seq(tempDir)))
</scala>

Apparently I didn't get the memo on this rename, so I asked the mailing list, which is very helpful. Browse [API Documentation][22] and look into companion objects to see if they have interesting methods for you.

### `packageTask` is `Package`
before:
<scala>  packageTask(...)
</scala>

after:
<scala>  Package(config, cacheDir, s.log)
</scala>

### acquire `logger` from `streams`
before:
<scala>  log.info("Including %s".format(jarName))
</scala>

after:
<scala>  (streams) map { (s) =>
    val log = s.log 
    log.info("Including %s".format(jarName))
  }</scala>

From [Basic Tasks][6]:
> New in sbt 0.10 are per-task loggers, which are part of a more general system for task-specific data called Streams. This allows controlling the verbosity of stack traces and logging individually for tasks as well as recalling the last logging for a task.

## search the mailing list, ask the mailing list
The [simple-build-tool mailing list][26] is full of useful information. There's a fair chance someone else got stuck on an issue, so try searching the list (and sort the results by date to see new stuff first).

When you get stuck, don't be shy and ask the mailing list. Someone would usually get back to you with an useful answer.

## thx
Thank you for reading all the way. I'm hoping this would save someone's time. I am going repeat again that I am no sbt 0.10 expert, so I may have gotten half the stuff wrong. Consult the official docs and experts if in doubt.

  [1]: http://harrah.github.com/xsbt/latest/sxr/Keys.scala.html
  [2]: https://github.com/harrah/xsbt/wiki
  [3]: https://github.com/harrah/xsbt/wiki/Settings
  [4]: https://github.com/harrah/xsbt/wiki/Basic-Configuration
  [5]: https://github.com/harrah/xsbt/wiki/Library-Management
  [6]: https://github.com/harrah/xsbt/wiki/Tasks
  [7]: https://github.com/harrah/xsbt/wiki/Common-Tasks
  [8]: https://github.com/harrah/xsbt/wiki/Migrating-from-SBT-0.7.x-to-0.10.x
  [9]: https://github.com/harrah/xsbt/wiki/Plugins
  [10]: https://github.com/harrah/xsbt/wiki/Mapping-Files
  [11]: https://github.com/harrah/xsbt/wiki/Full-Configuration
  [12]: https://groups.google.com/group/simple-build-tool/browse_thread/thread/d2a842c8182c99d5#msg_660cd082183f6dc3
  [13]: http://harrah.github.com/xsbt/latest/sxr/Defaults.scala.html
  [14]: http://harrah.github.com/xsbt/latest/sxr/Structure.scala.html
  [15]: https://github.com/softprops/coffeescripted-sbt/blob/master/src/main/scala/coffeescript.scala
  [16]: https://github.com/eed3si9n/sbt-assembly/blob/sbt0.10/src/main/scala/assembly/AssemblyPlugin.scala
  [17]: https://github.com/harrah/xsbt/blob/0.10/project/Proguard.scala
  [18]: https://github.com/harrah/xsbt/wiki/sbt-0.10-plugins-list
  [19]: https://github.com/siasia/xsbt-web-plugin/blob/master/src/main/scala/WebPlugin.scala
  [20]: https://github.com/ijuma/sbt-idea/blob/sbt-0.10/src/main/scala/org/sbtidea/SbtIdeaPlugin.scala
  [21]: http://harrah.github.com/xsbt/latest/sxr/index.html
  [22]: http://harrah.github.com/xsbt/latest/api/index.html
  [23]: https://github.com/codahale/assembly-sbt/blob/development/src/main/scala/assembly/AssemblyBuilder.scala
  [24]: https://github.com/harrah/xsbt/blob/0.10/main/Structure.scala#L432
  [25]: https://github.com/harrah/xsbt/wiki/Mapping-Files
  [26]: http://groups.google.com/group/simple-build-tool
  [27]: http://suereth.blogspot.com/2011/09/sbt-and-plugin-design.html
  [28]: https://github.com/jsuereth/xsbt-ghpages-plugin
