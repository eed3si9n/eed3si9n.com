---
title:       "sbt plugin classpath isolation"
type:        story
date:        2026-08-15
url:         /sbt-plugin-classpath-isolation
---

  [1]: https://www.scala-sbt.org/2.x/docs/en/recipes/plugin-isolation.html

A build performs assortment of tasks, often reusing existing libraries and tools. The plugin mechanism in sbt enables reuse, by adding libraries to the metabuild. It works well for lightweight tasks or integration with CLI such as `gpg` etc. However, adding more libraries to the metabuild may not be desirable or possible. For example, tools like Scalafix or Coursier are written in some Scala version, which may not be compatible with the Scala version used by sbt 2.x or 1.x. For this reason, the idea of plugin classpath isolation comes up occasionally, which we will look into in this post. See [Isolate plugin classpath recipe][1] for the full source.

<!--more-->

### overview

The gist of the idea is:

1. Define a command-line app.
2. Execute the command-line app from your plugin via `run`.

Because sbt implements the `run` task using a sandbox classloader, rather than shelling out, this is effectively same as having classpath isolation. Additional feature needed for classpath isolation has been around since sbt 0.13.13. In fact, I've written a similar post [downloading and running app on the side](/sbt-sidedish) in 2017. This is an improved version without needing sbt-sidedish.

### synthetic subproject

A plugin can create a synthetic subproject by overriding `extraProjects`:

```scala
package example

import sbt.{ *, given }
import Keys.*

object BootstrapPlugin extends AutoPlugin:
  override lazy val requires = sbt.plugins.JvmPlugin

  lazy val bootstrapCs = project
    .settings(
      scalaVersion := "2.12.21",
      libraryDependencies += "io.get-coursier" %% "coursier-cli" % "2.1.14",
      Compile / run / mainClass := Some("coursier.cli.Coursier"),
      // applicable to sbt 2.x only
      clientSide := false,
    )

  override lazy val extraProjects = Vector(bootstrapCs)

  ....
end BootstrapPlugin
```

In this example, we will add Coursier CLI that was built using Scala 2.12. Because it will be injected to the build, be sure to prefix the name with your plugin name, like `bootstrapCs`.

### calling the command-line

Using the Coursier CLI, we can implement a task that generates a bootstrap JAR. Let's start with the following keys:

```scala
  object autoImport:
    val packageBootstrap = taskKey[HashedVirtualFileRef]("packageBootstrap")
    val packageBootstrapArgs = settingKey[Seq[String]]("packageBootstrapArgs")
    val packageBootstrapOutput = settingKey[File]("packageBootstrapOutput")
  end autoImport
  import autoImport.*
```

The actual implementation looks as follows:

```scala
  override lazy val projectSettings = Vector(
    packageBootstrapOutput := target.value / "bootstrap" / s"${moduleName.value}.jar",
    packageBootstrapArgs := {
      val coord =
        s"${organization.value}:${name.value}_${scalaBinaryVersion.value}:${version.value}"
      val sv = scalaVersion.value
      Vector("bootstrap", "--verbose", "--bat=true",
        "--scala-version", sv,
        "-f", coord,
        "-o", packageBootstrapOutput.value.toString)
    },
    packageBootstrap := Def.uncached {
      // to process args before toTask, we need to use dynamic tasks
      (Def.taskDyn {
        // phase 1
        val c = fileConverter.value
        val args = packageBootstrapArgs.value
        val out = packageBootstrapOutput.value
        // phase 2
        val outVf: HashedVirtualFileRef = c.toVirtualFile(out.toPath())
        IO.createDirectory(out.getParentFile())
        // phase 3
        (bootstrapCs / Compile / run)
          .toTask(args.mkString(" ", " ", ""))
          .map(_ => outVf)
      }).value
    },
  )
```

In the above, `packageBootstrapOutput` and `packageBootstrapArgs` are settings to construct the command-line arguments that will be passed in to Coursier CLI. The `packageBootstrap` task uses `Def.taskDyn`, or a dynamic task, which lets us compose tasks sequentially (our encoding of `flatMap`).

The input into Coursier CLI is string arguments, and the expected outputs are files. Any console output it makes would automatically display to the terminal:

```bash
sbt:isolation-root> app/publishLocal
sbt:isolation-root> app/packageBootstrap
[info] running coursier.cli.Coursier bootstrap --verbose --bat=true --scala-version 3.8.4 -f com.example:hello_3:0.1.0-SNAPSHOT -o /.../isolation/target/out/jvm/scala-3.8.4/hello/bootstrap/hello.jar
  Dependencies:
com.example:hello_3:0.1.0-SNAPSHOT:
Wrote /.../isolation/target/out/jvm/scala-3.8.4/hello/bootstrap/hello.jar
Wrote /.../isolation/target/out/jvm/scala-3.8.4/hello/bootstrap/hello.jar.bat
[success] elapsed time: 3 s, cache 100%, 17 disk cache hits
```

This shows that `app/packageBootstrap` in sbt 2.x called Coursier CLI to build a bootstrap JAR.

### a note on forking

While defining the `bootstrapCs` subproject, we intentionally set the `clientSide` to `false`:

```scala
clientSide := false,
```

This overrides the default client-side run, so Coursier CLI will execute inside of the same JVM as the sbt server. One caveat is that CLI programs will often call `sys.exit(1)` and it will shutdown the sbt server:

```bash
sbt:isolation-root> bootstrapCs/run --help
[info] running coursier.cli.Coursier --help
Usage: coursier <COMMAND>
Coursier is the Scala application and artifact manager.
It can install Scala applications and setup your Scala development environment.
It can also download and cache artifacts from the web.
....
$
```

If you want to protect your build from `sys.exit(1)`, you have to fork the `run`:

```scala
// default for sbtn
clientSide := true,
// for sbt --server
Compile / run / fork := true,
```

The tradeoff is that forking would potentially run slower compared to the in-process `run` due to JVM warmup, so it might depend on how many times the task would be called.

### summary

sbt plugin classpath isolation can be implemented in both sbt 2.x and 1.x by creating a CLI program as a synthetic subproject in a Scala version of your choice. See [Isolate plugin classpath recipe][1] for the full source.
