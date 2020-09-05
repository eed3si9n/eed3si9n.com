This is part 4 of the post about [sbt-projectmatrix](https://github.com/sbt/sbt-projectmatrix/), an experimental plugin that I've been working to improve the cross building in sbt. Here's [part 1](http://eed3si9n.com/parallel-cross-building-using-sbt-projectmatrix), [part 2](http://eed3si9n.com/parallel-cross-building-with-virtualaxis), and [part 3](http://eed3si9n.com/parallel-cross-building-part3). I've just released 0.6.0.

### recap: building against multiple Scala versions

After adding sbt-projectmatrix to your build, here's how you can set up a matrix with two Scala versions.

<scala>
ThisBuild / organization := "com.example"
ThisBuild / scalaVersion := "2.12.12"
ThisBuild / version      := "0.1.0-SNAPSHOT"

lazy val core = (projectMatrix in file("core"))
  .settings(
    name := "core"
  )
  .jvmPlatform(scalaVersions = Seq("2.12.12", "2.13.3"))
</scala>

This will create subprojects for each `scalaVersion`. Unlike `++` style stateful cross building, these will build in parallel. This part has not changed.

Previous post also discussed the idea of using `%` to scope dependencies to a configuration.

### new in 0.6.0: simpler project ID

Instead of appending `JVM2_13` suffix, starting sbt-projectmatrix 0.6.0, axes `JVM` and `2_13` will be considered a default and it will generate subproject named `core` or `util` as opposed to `coreJVM2_13`.

### new in 0.6.0: 2.13-3.0 sandwich support

Scala 3.0 will have built-in interoperability with Scala 2.13.x, and 2.13.x branch has also recently added Scala 3.0 interoperability known as [TASTy reader](https://github.com/scala/scala/pull/9109). Details aside, we can now use this to write one subproject in Dotty and another using 2.13.

sbt-projectmatrix 0.6.0 allows you to create matrices of subprojects that will detect 2.13-3.0 sandwich and automatically wire them when available:

<scala>
val scala212 = "2.12.12"
// TODO use 2.13.4 when it's out
val scala213 = "2.13.4-bin-aeee8f0"
val dottyVersion = "0.23.0"
ThisBuild / resolvers += "scala-integration" at "https://scala-ci.typesafe.com/artifactory/scala-integration/"


lazy val fooApp = (projectMatrix in file("foo-app"))
  .dependsOn(fooCore)
  .settings(
    name := "foo app",
  )
  .jvmPlatform(scalaVersions = Seq(dottyVersion))

lazy val fooCore = (projectMatrix in file("foo-core"))
  .settings(
    name := "foo core",
  )
  .jvmPlatform(scalaVersions = Seq(scala213, scala212))

lazy val barApp = (projectMatrix in file("bar-app"))
  .dependsOn(barCore)
  .settings(
    name := "bar app",
  )
  .jvmPlatform(scalaVersions = Seq(scala213))

lazy val barCore = (projectMatrix in file("bar-core"))
  .settings(
    name := "bar core",
  )
  .jvmPlatform(scalaVersions = Seq(dottyVersion))
</scala>

This backports [sbt/sbt#5767](https://github.com/sbt/sbt/pull/5767) so using this 2.13-3.0 sandwich becomes available to sbt 1.2 and above.

### summary

- sbt-projectmatrix enables parallel building of multiple Scala versions and JVM/JS/Native cross building.
- sbt-projectmatrix 0.6.0 simplifies the generated project ID.
- sbt-projectmatrix 0.6.0 enables Scala 2.13-3.0 interoperability within a build.
