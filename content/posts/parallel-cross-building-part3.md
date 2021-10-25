---
title:       "parallel cross building, part 3"
type:        story
date:        2020-04-13
draft:       false
promote:     true
sticky:      false
url:         /parallel-cross-building-part3
aliases:     [ /node/325 ]
tags:        [ "sbt" ]
---

This is part 3 of the post about [sbt-projectmatrix](https://github.com/sbt/sbt-projectmatrix/), an experimental plugin that I've been working to improve the cross building in sbt. Here's [part 1](http://eed3si9n.com/parallel-cross-building-using-sbt-projectmatrix) and [part 2](http://eed3si9n.com/parallel-cross-building-with-virtualaxis). I've just released 0.5.0.

### recap: building against multiple Scala versions

After adding sbt-projectmatrix to your build, here's how you can set up a matrix with two Scala versions.

```scala
ThisBuild / organization := "com.example"
ThisBuild / scalaVersion := "2.12.10"
ThisBuild / version      := "0.1.0-SNAPSHOT"

lazy val core = (projectMatrix in file("core"))
  .settings(
    name := "core"
  )
  .jvmPlatform(scalaVersions = Seq("2.12.10", "2.11.12"))
```

This will create subprojects `coreJVM2_11` and `coreJVM2_12`. Unlike `++` style stateful cross building, these will build in parallel. This part has not changed.

Previous post also discussed the idea of VirtualAxis so a row can express multiple concepts.

### what's new in 0.5.0

0.4.0 came pretty close, but there are some issue I ran into when I tried to use it in a real project. First is the lack of `%` syntax.

It's fairly common for subprojects to depend only from `Test` configuration, or depend on `Compile` from `Compile`, and `Test` from `Test`. 0.5.0 adds `%` to make this possible.

```scala
lazy val app = (projectMatrix in file("app"))
  .dependsOn(core % "compile->compile;test->test")
  .settings(
    name := "app"
  )
  .jvmPlatform(scalaVersions = Seq("2.12.10"))

lazy val core = (projectMatrix in file("core"))
  .settings(
    name := "core"
  )
  .jvmPlatform(scalaVersions = Seq("2.12.10", "2.13.1"))
```

Another feature that's available to `Project` is `.configure(...)` method. It takes a vararg of `Project => Project` functions, and applies them in order. Since some of the builds I deal with uses `.configure(...)` this helps me migrate from `Project` to `ProjectMatrix`.

### zincApiInfo example

Here's from Zinc build I'm working:

```scala
lazy val compilerInterface = (projectMatrix in internalPath / "compiler-interface")
  .enablePlugins(ContrabandPlugin)
  .settings(
    minimalSettings,
    name := "Compiler Interface",
    exportJars := true,
    crossPaths := false,
  )
  .jvmPlatform(autoScalaLibrary = false)
  .configure(addSbtUtilInterface)

lazy val zincApiInfo = (projectMatrix in internalPath / "zinc-apiinfo")
  .dependsOn(compilerInterface, compilerBridge, zincClassfile % "compile;test->test")
  .settings(
    name := "zinc ApiInfo",
    compilerVersionDependentScalacOptions,
    mimaSettings,
  )
  .jvmPlatform(scalaVersions = List(scala212, scala213))
  .configure(addBaseSettingsAndTestDeps)
```

In the above, both `compilerInterface` and `zincApiInfo` are project matrices. `compilerInterface` is how a Java-only matrix looks like, and `zincApiInfo` is a Scala project matrix with multiple Scala versions.

Unlike the traditional multi-project setup, this would create a subproject for each Scala version so a fairly complex web of projects can be set up without using `++` commands.

### summary

- sbt-projectmatrix enables parallel building of multiple Scala versions and JVM/JS/Native cross building.
- sbt-projectmatrix 0.5.0 adds `%` support for inter-matrix dependencies.
