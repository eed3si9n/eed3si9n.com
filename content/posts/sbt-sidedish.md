---
title:       "downloading and running app on the side with sbt-sidedish"
type:        story
date:        2017-03-27
draft:       false
promote:     true
sticky:      false
url:         /sbt-sidedish
aliases:     [ /node/218 ]
---

  [@shanedelmore]: https://twitter.com/shanedelmore
  [app]: https://github.com/eed3si9n/sbt-rewritedemo/blob/225e207e1619eafb56e5ff22add60ebca8f9a8c1/app/src/main/scala/RewriteApp.scala

I've been asked by a few people on downloading JARs, and then running them from an sbt plugin.
Most recently, Shane Delmore ([@shanedelmore][@shanedelmore]) asked me about this at nescala in Brooklyn.

During an unconference session I hacked together a demo, and I continued some more after I came home.

### sbt-sidedish

sbt-sidedish is a toolkit for plugin authors to download and run an app on the side from a plugin.
It on its own does not define any plugins.

### rewritedemo, a commandline app

First, create a command line app that you want to run on the side. This could be in Scala 2.11 or 2.12.
Here's [a demo app][app] I wrote that uses Scalafix to add an import statement to some code. Scalafix is a Scala code rewriting tool and library that uses scala.meta. See Scalafix docs and sources for the details on that.

### sbt-rewritedemo, an sbt plugin

Next, suppose you want to run rewritedemo against some subproject in your build and derive another subproject.
Here's a plugin you can write using sbt-sidedish.

```scala
package sbtrewritedemo

import sbt._
import Keys._
import sbtsidedish.Sidedish

object RewriteDemoPlugin extends AutoPlugin {
  override def requires = sbt.plugins.JvmPlugin

  object autoImport extends RewriteDemoKeys
  import autoImport._

  val sidedish = Sidedish("sbtrewritedemo-metatool",
    file("sbtrewritedemo-metatool"),
    // scalaVersion
    "2.12.1",
    // ModuleID of your app
    List("com.eed3si9n" %% "rewritedemo" % "0.1.2"),
    // main class
    "sbtrewritedemo.RewriteApp")

  override def extraProjects: Seq[Project] =
    List(sidedish.project
      // extra settings
      .settings(
        // Resolve the app from sbt community repo.
        resolvers += Resolver.bintrayIvyRepo("sbt", "sbt-plugin-releases")
      ))

  override def projectSettings = Seq(
    rewritedemoOrigin := "example",
    sourceGenerators in Compile +=
      Def.sequential(
        Def.taskDyn {
          val example = LocalProject(rewritedemoOrigin.value)
          val workingDir = baseDirectory.value
          val out = (sourceManaged in Compile).value / "rewritedemo"
          Def.taskDyn {
            val srcDirs = (sourceDirectories in (example, Compile)).value
            val srcs = (sources in (example, Compile)).value
            val cp = (fullClasspath in (example, Compile)).value
            val jvmOptions = List("-Dscalameta.sourcepath=" + "\"" + srcDirs.mkString(java.io.File.pathSeparator) + "\"",
              "-Dscalameta.classpath=" + "\"" + cp.mkString(java.io.File.pathSeparator)+ "\"",
              "-Drewrite.out=" + out)
            Def.task {
              sidedish.forkRunTask(workingDir, jvmOptions = jvmOptions, args = Nil).value
            }
          }
        },
        Def.task {
          val out = (sourceManaged in Compile).value / "rewritedemo"
          (out ** "*.scala").get
        }
      ).taskValue
  )
}

trait RewriteDemoKeys {
  val rewritedemoOrigin = settingKey[String]("")
}

object RewriteDemoKeys extends RewriteDemoKeys
```

This uses synthetic subproject feature that was added in sbt 0.13.13.

The tricky part is passing the right arguments to the app from the user's build. I had to double wrap dynamic tasks to refer to the source directories from the origin and pass it in as JVM options.

### how sbt-rewritedemo gets used

build.properties:

```scala
sbt.version=0.13.13
```

plugins.sbt:

```scala
addSbtPlugin("com.eed3si9n" % "sbt-rewritedemo" % "0.1.2")
```

build.sbt:

```scala
lazy val example = (project in file("example"))
  .settings(
    name := "example",
    scalaVersion := "2.12.1"
  )

lazy val derived1 = (project in file("derived1"))
  .enablePlugins(RewriteDemoPlugin)
  .settings(
    name := "derived1",
    rewritedemoOrigin := "example",
    scalaVersion := "2.12.1"
  )
```

Now suppose we have `Example.scala` under `example/src/main/scala/Example.scala`:

```scala
package foo

object Example extends App {
  println(Seq(1, 2, 3))
}
```

When you run `derived1/compile` from the sbt shell, it runs the rewrite app using Scala 2.12 and generates the following file under the managed source directory:

```scala
package foo

import scala.collection.immutable.Seq
object Example extends App {
  println(Seq(1, 2, 3))
}
```

In other words, using sbt-sidedish we could run 2.12 app from an sbt plugin.
