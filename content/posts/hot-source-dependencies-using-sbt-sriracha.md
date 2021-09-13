---
title:       "hot source dependencies using sbt-sriracha"
type:        story
date:        2018-05-20
changed:     2019-04-06
draft:       false
promote:     true
sticky:      false
url:         /hot-source-dependencies-using-sbt-sriracha
aliases:     [ /node/260 ]
tags:        [ "sbt" ]
---

Source dependencies is one of features that existed in sbt since ever, but hasn't been documented well.

### immutable source dependency

Here's how to declare source dependency to the latest commit for scopt commandline option parsing library.

<scala>
lazy val scoptJVMRef = ProjectRef(uri("git://github.com/scopt/scopt.git#c744bc48393e21092795059aa925fe50729fe62b"), "scoptJVM")

ThisBuild / organization := "com.example"
ThisBuild / scalaVersion := "2.12.2"

lazy val root = (project in file("."))
  .dependsOn(scoptJVMRef)
  .settings(
    name := "Hello world"
  )
</scala>

When you start sbt and run `compile`, sbt will automatically clone scopt/scopt under the staging directory, and link the builds together.

This also means that your sbt versions need to be compatible, and also you might end up with unwanted triggered plugins.

Another limitation is that staging directory does not get updated after the initial clone.

### hybrid dependency

What I would like instead, is a hybrid dependency that I can hook up multiple repositories, and code and test at once; but for publishing use Maven binary as the dependency.

To do this, I wrote an experimental plugin called sbt-sriracha. Add this to `project/plugins.sbt`:

<scala>
addSbtPlugin("com.eed3si9n" % "sbt-sriracha" % "0.1.0")
</scala>

Then now you can write:

<scala>
lazy val scoptJVMRef = ProjectRef(workspaceDirectory / "scopt", "scoptJVM")
lazy val scoptJVMLib = "com.github.scopt" %% "scopt" % "3.7.0"

lazy val root = (project in file("."))
  .sourceDependency(scoptJVMRef, scoptJVMLib)
  .settings(
    name := "Hello world"
  )
</scala>

This will use normal binary dependency by default. You can check that looking at the `libraryDependency` setting:

<code>
$ sbt
sbt:helloworld> libraryDependencies
[info] * org.scala-lang:scala-library:2.12.6
[info] * com.github.scopt:scopt:3.7.0
</code>

To switch to the source mode, run sbt with `-Dsbt.sourcemode=true`:

<code>
$ sbt -Dsbt.sourcemode=true
[info] Loading settings from build.sbt ...
[error] java.lang.RuntimeException: Invalid build URI (no handler available): file:///Users/eed3si9n/workspace/scopt/
....
</code>

The build failed to load, because `workspaceDirectory / "scopt"` didn't have the valid build. Check out scopt/scopt under `$HOME/workspace`, and try again.

<code>
$ cd $HOME/workspace
$ git clone https://github.com/scopt/scopt
</code>

Now `sbt -Dsbt.sourcemode=true` should run, and `internalDependencyClasspath` should include scopt.

<code>
$ sbt -Dsbt.sourcemode=true
sbt:helloworld> show internalDependencyClasspath
[info] Compiling 2 Scala sources to /Users/eed3si9n/workspace/scopt/jvm/target/scala-2.12/classes ...
[info] Done compiling.
[info] * Attributed(/Users/eed3si9n/workspace/scopt/jvm/target/scala-2.12/classes)
[info] * Attributed(/Users/eed3si9n/work/hellotest/someProject/target/scala-2.12/classes)
</code>

### trying Scala 2.13.0-M4

One motivation to set this up is trying 2.13.0-M4 or some version of Scala before your upstream dependency has published one for it. For example, as of this writing scopt for 2.13.0-M4 is not yet available, but I can call `++2.13.0-M4!` with `sbt.sourcemode=true`.

<code>
$ sbt -Dsbt.sourcemode=true
sbt:helloworld> ++2.13.0-M4!
[info] Forcing Scala version to 2.13.0-M4 on all projects.
[info] Reapplying settings...

sbt:helloworld> console
[info] Starting scala interpreter...
Welcome to Scala 2.13.0-M4 (Java HotSpot(TM) 64-Bit Server VM, Java 1.8.0_171).
Type in expressions for evaluation. Or try :help.

scala> val parser = new scopt.OptionParser[Unit]("scopt") {}
parser: scopt.OptionParser[Unit] = $anon$1@28e39e04
</code>

### testing with source dependencies

An interesting use case for source dependencies might be for test frameworks. If you are maintaining libraries, and want to publish before all the test frameworks are available for the Scala version (or Scala.JS and native versions?) you could use source dependencies to make sure your tests pass.

µTest might be a good candidate to try this experiment since it's available for Scala.JS and native; however, as of this writing there's no µTest for Scala 2.13.0-M3. This is fine, since we can use source dependencies, and typically we do not need to publish our tests.

Since µTest is on sbt 0.13, I've updated it to 1.1.5, and also made a branch that merges Yoshida-san's [PR for 2.13.0-M4](https://github.com/lihaoyi/utest/pull/163) and [my own](https://github.com/lihaoyi/utest/pull/167).

Add this to `project/plugins.sbt`:

<scala>
addSbtPlugin("com.eed3si9n" % "sbt-sriracha" % "0.1.0")
</scala>

Using sbt-sriracha, we can define a hybrid dependency to µTest as follows: 

<scala>
lazy val utestJVMRef = ProjectRef(uri("git://github.com/eed3si9n/utest.git#5b19f47c"), "utestJVM")
lazy val utestJVMLib = "com.lihaoyi" %% "utest" % "0.6.4"

lazy val root = (project in file("."))
  .sourceDependency(utestJVMRef % Test, utestJVMLib % Test)
  .settings(
    name := "Hello world",
    testFrameworks += new TestFramework("utest.runner.Framework"),
  )
</scala>

Now using these changes I can run custom µTest on Scala 2.13.0-M4.

<code>
$ sbt -Dsbt.sourcemode=true
sbt:helloworld> ++2.13.0-M4!
sbt:helloworld> test
-------------------------------- Running Tests --------------------------------
X foo.HelloTests.test1 28ms
  utest.AssertionError: assert(a + b == 7)
  a: Int = 1
  b: Int = 3
    utest.asserts.Asserts$.assertImpl(Asserts.scala:114)
    foo.HelloTests$.$anonfun$tests$2(Test.scala:10)
[info] Tests: 1, Passed: 0, Failed: 1
[error] Failed tests:
[error] 	foo.HelloTests
[error] (Test / test) sbt.TestsFailedException: Tests unsuccessful
</code>

If you want to further hack on µTest, just substitute `utestJVMRef` to `ProjectRef(IO.toURI(workspaceDirectory / "utest"), "utestJVM")`.

### update: Scala 2.13.0-RC1

Here's what you can use for Scala 2.13.0-RC1

<scala>
lazy val utestVersion = "0.6.6"
lazy val utestJVMRef = ProjectRef(uri("git://github.com/eed3si9n/utest.git#79950544"), "utestJVM")
lazy val utestJVMLib = "com.lihaoyi" %% "utest" % utestVersion
lazy val utestJSRef = ProjectRef(uri("git://github.com/eed3si9n/utest.git#79950544"), "utestJS")
lazy val utestJSLib = "com.lihaoyi" %% "utest_sjs0.6" % utestVersion
</scala>

### summary

- sbt can use source dependencies
- sbt-sriracha adds `addSourceDependency(...)` to support hybrid of source and binary dependency
- This can be used to emulate single repo, or mimic upstream libraries and test frameworks
