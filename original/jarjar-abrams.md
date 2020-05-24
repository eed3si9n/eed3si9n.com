[Jar Jar Abrams](https://github.com/eed3si9n/jarjar-abrams) is an **experimental** Scala extension of Jar Jar Links, a utility to shade Java libraries.

For library authors, the idea of other library is a double-edged sword. On one hand, using other libraries avoids unnecessary duplication of work, not using other libraries is almost hypocritical. On the other hand, each library you add would add a transitive dependency to your users, increasing the possibility of conflict. This is partly due to the fact that within a single running program you can one have one version of a library.

This type of conflict happens often in a setup, where a program runs on top of a runtime or a framework. sbt plugins are like that. Spark is another example. One way to mitigate this to shade the transitive libraries under your own package. In 2004, herbyderby (Chris Nokleberg) created a tool called [Jar Jar Links](https://code.google.com/archive/p/jarjar/) that can repackage libraries.

In 2015, Wu Xiang [added](https://github.com/sbt/sbt-assembly/pull/162) shading support to [sbt-assembly](https://github.com/sbt/sbt-assembly) using Jar Jar Links. This was a step forward, but the challenges remained. One of the issues was that Scala compiler includes ScalaSignature information into the `*.class` files, but Jar Jar was not aware of it. Fast forward to 2020, Jeroen ter Voorde implemented ScalaSignature conversion in [sbt-assembly#393](https://github.com/sbt/sbt-assembly/pull/393). Instead of keeping it in sbt-assembly, I wanted to split this up into its own library.

### core API

At the core there's `Shader` object that implements `shadeDirectory` function.

<scala>
package com.eed3si9n.jarjarabrams

object Shader {
  def shadeDirectory(
      rules: Seq[ShadeRule],
      dir: Path,
      mappings: Seq[(Path, String)],
      verbose: Boolean
  ): Unit = ...
}
</scala>

The function expects the `dir` to be a directory containing unzipped JAR file.

### sbt-jarjar-abrams

To demonstrate the usage, I created an sbt plugin that shades one library at a time.

Add the following to `project/plugins.sbt`:

<scala>
addSbtPlugin("com.eed3si9n.jarjarabrams" % "sbt-jarjar-abrams" % "0.1.0")
</scala>

`build.sbt` would look like this:

<scala>
ThisBuild / version := "0.1.0-SNAPSHOT"
ThisBuild / organization := "com.example"
ThisBuild / scalaVersion := "2.12.11"

lazy val shadedJawn = project
  .enablePlugins(JarjarAbramsPlugin)
  .settings(
    name := "shaded-jawn",
    jarjarLibraryDependency := "org.typelevel" %% "jawn-parser" % "1.0.0",
    jarjarShadeRules += ShadeRuleBuilder.moveUnder("org.typelevel", "shaded")
  )

lazy val use = project
  .dependsOn(shadedJawn)
</scala>

jawn-parser is now shaded under `shaded` package. We can confirm that using the REPL:

<scala>
sbt:jarjar> use/console
[info] Starting scala interpreter...
Welcome to Scala 2.12.11 (OpenJDK 64-Bit Server VM, Java 1.8.0_232).
Type in expressions for evaluation. Or try :help.

scala> shaded.org.typelevel.jawn.Facade
res0: shaded.org.typelevel.jawn.Facade.type = shaded.org.typelevel.jawn.Facade$@131cedd
</scala>

We can try stacking multiple-layers of shaded libraries by mimicking the original dependency graph:

<scala>
ThisBuild / organization := "com.example"
ThisBuild / scalaVersion := "2.12.11"

lazy val shadedJawn = project
  .enablePlugins(JarjarAbramsPlugin)
  .settings(
    name := "shaded-jawn",
    jarjarLibraryDependency := "org.typelevel" %% "jawn-parser" % "1.0.0",
    jarjarShadeRules += ShadeRuleBuilder.moveUnder("org.typelevel", "shaded")
  )

lazy val shadedJawnAst = project
  .enablePlugins(JarjarAbramsPlugin)
  .dependsOn(shadedJawn)
  .settings(
    name := "shaded-jawn-ast",
    jarjarLibraryDependency := "org.typelevel" %% "jawn-ast" % "1.0.0",
    jarjarShadeRules += ShadeRuleBuilder.moveUnder("org.typelevel", "shaded")
  )

lazy val use = project
  .dependsOn(shadedJawnAst)
</scala>

Here's REPL:

<scala>
sbt:jarjar> use/console
[info] Starting scala interpreter...
Welcome to Scala 2.12.11 (OpenJDK 64-Bit Server VM, Java 1.8.0_232).
Type in expressions for evaluation. Or try :help.

scala> shaded.org.typelevel.jawn.ast.JParser.parseUnsafe("""{ "x": 10 }""")
res0: shaded.org.typelevel.jawn.ast.JValue = {"x":10}
</scala>

### use at your own risk

I want to note again that all this is experimental. Many libraries depend on things like config files and other runtime behaviors that Jar Jar Abrams won't convert.

I'm cautiously optimistic that this may be able to shade some transitive libraries out of sbt, so sbt plugin authors can freely use different versions.
