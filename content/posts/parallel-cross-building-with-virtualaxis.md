---
title:       "parallel cross building with VirtualAxis"
type:        story
date:        2019-11-04
draft:       false
promote:     true
sticky:      false
url:         /parallel-cross-building-with-virtualaxis
aliases:     [ /node/310 ]
---

This is part 2 of the post about [sbt-projectmatrix](https://github.com/sbt/sbt-projectmatrix/), an experimental plugin that I've been working to improve the cross building in sbt. Here's [part 1](http://eed3si9n.com/parallel-cross-building-using-sbt-projectmatrix). I've just released 0.4.0.

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

Previous post also discussed the idea of extending the idea to cross-platform and cross-library building.

### problem with 0.2.0

Two issues were submitted [Support for mixed-style matrix dependencies #13](https://github.com/sbt/sbt-projectmatrix/issues/13) and [Support for pure Java subprojects #14](https://github.com/sbt/sbt-projectmatrix/issues/14) that made me realize the limitation of 0.2.0 design. In 0.2.0, each row was expressed as follows:

```scala
final class ProjectRow(
    val idSuffix: String,
    val directorySuffix: String,
    val scalaVersions: Seq[String],
    val process: Project => Project
) {}
```

This limited the thing we can track using the row to one dimension (like platform) plus a specific Scala version. The reported issues are variants of each other in a sense that it's about relating one row in a matrix to a row in another matrix with a slighly weaker constraint.

### VirtualAxis

sbt-projectmatrix 0.4.0 introduces `VirtualAxis` although you can use sbt-projectmatrix without understanding it initially.

```scala
/** A row in the project matrix, typically representing a platform + Scala version.
 */
final class ProjectRow(
    val autoScalaLibrary: Boolean,
    val axisValues: Seq[VirtualAxis],
    val process: Project => Project
)

/** Virtual Axis represents a parameter to a project matrix row. */
sealed abstract class VirtualAxis {
  def directorySuffix: String

  def idSuffix: String

  /* The order to sort the suffixes if there were multiple axes. */
  def suffixOrder: Int = 50
}

object VirtualAxis {
  /**
   * WeakAxis allows a row to depend on another row with Zero value.
   * For example, Scala version can be Zero for Java project, and it's ok.
   */
  abstract class WeakAxis extends VirtualAxis

  /** StrongAxis requires a row to depend on another row with the same selected value. */
  abstract class StrongAxis extends VirtualAxis
  
  ....
}
```

`ProjectRow` is now a set of `VirtualAxis`. Typical use of `VirtualAxis` will be for tracking platform (JVM, JS, Native) and Scala versions. The `VirtualAxis` class splits into two subclasses `WeakAxis` and `StrongAxis`.

`StrongAxis` requires that the related rows to have the same value, which is useful for things like platform. On the other hand, `WeakAxis` can either have the same value, or no value. An example of this is Scala version.

```scala
lazy val intf = (projectMatrix in file("intf"))
  .jvmPlatform(autoScalaLibrary = false)

lazy val core = (projectMatrix in file("core"))
  .dependsOn(intf)
  .jvmPlatform(scalaVersions = Seq("2.12.10", "2.11.12"))
```

In the above, the matrix `core` has two JVM rows corresponding to the Scala versions 2.12.10 and 2.11.12. Because `ScalaVersionAxis` is a weak axis it's able to depend on the JVM row in `intf` without a Scala version.

### parallel cross-library building

We can implement parallel cross-library building by defining a custom `VirtualAxis`. In `project/LightbendConfigAxis.scala`:

```scala
import sbt._

case class LightbendConfigAxis(idSuffix: String, directorySuffix: String) extends VirtualAxis.WeakAxis {
}
```

Then in `build.sbt`:

```scala
ThisBuild / organization := "com.example"
ThisBuild / version := "0.1.0-SNAPSHOT"

lazy val config12 = LightbendConfigAxis("Config1_2", "config1.2")
lazy val config13 = LightbendConfigAxis("Config1_3", "config1.3")

lazy val scala212 = "2.12.10"
lazy val scala211 = "2.11.12"

lazy val app = (projectMatrix in file("app"))
  .settings(
    name := "app"
  )
  .customRow(
    scalaVersions = Seq(scala212, scala211),
    axisValues = Seq(config12, VirtualAxis.jvm),
    settings = Seq(
      moduleName := name.value + "_config1.2",
      libraryDependencies += "com.typesafe" % "config" % "1.2.1",
    )
  )
  .customRow(
    scalaVersions = Seq(scala212, scala211),
    axisValues = Seq(config13, VirtualAxis.jvm),
    settings = Seq(
      moduleName := name.value + "_config1.3",
      libraryDependencies += "com.typesafe" % "config" % "1.3.3",
    )
  )
```

Note that `LightbendConfigAxis` extends `VirtualAxis.WeakAxis`. This allows `app` matrix to depend on other matrices that do not use the `LightbendConfigAxis`.

### referencing the generated subprojects

You might want to reference one of the projects within `build.sbt`:

```scala
lazy val core212 = core.jvm("2.12.10")

lazy val appConfig12_212 = app.finder(config13, VirtualAxis.jvm)("2.12.10")
  .settings(
    publishMavenStyle := true
  )
```

### Scala Native support

Thanks to Tatsuno-san ([@exoego](https://github.com/exoego)), we have Scala Native support in sbt-projectmatrix in addition to Scala.JS support since 0.3.0. To use this, you need to setup sbt-scala-native as well:

```scala
lazy val core = (projectMatrix in file("core"))
  .settings(
    name := "core",
    Compile / run mainClass := Some("a.CoreMain")
  )
  .nativePlatform(scalaVersions = Seq("2.11.12"))
```

### summary

- sbt-projectmatrix enables parallel building of multiple Scala versions and JVM/JS/Native cross building.
- `VirtualAxis` allows flexible inter-matrix dependencies between Scala-Java matrix, and custom cross-library axis.
