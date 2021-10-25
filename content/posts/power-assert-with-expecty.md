---
title:       "bringing back power assert with Expecty"
type:        story
date:        2018-05-28
changed:     2018-05-29
draft:       false
promote:     true
sticky:      false
url:         /power-assert-with-expecty
aliases:     [ /node/262 ]
---

  [sbt-sriracha]: http://eed3si9n.com/hot-source-dependencies-using-sbt-sriracha
  [g2009]: http://groovy-lang.org/releasenotes/groovy-1.7.html#Groovy17releasenotes-PowerAsserts
  [rpower]: https://github.com/k-tsj/power_assert
  [jspower]: https://github.com/power-assert-js/power-assert
  [rspower]: https://github.com/gifnksm/power-assert-rs
  [expecty]: https://github.com/pniederw/expecty
  [expecty2]: https://github.com/eed3si9n/expecty
  [10]: https://github.com/pniederw/expecty/pull/10
  [14]: https://github.com/monix/minitest/pull/14
  [minitest]: https://github.com/monix/minitest
  [pp2012]: https://groups.google.com/d/msg/scala-language/Z4ByvmQESJ0/SaFj7QBproYJ
  [2]: https://gist.github.com/paulp/3019862

Last week I wrote about [using source dependencies with sbt-sriracha][sbt-sriracha] for testing purpose. This week we'll look into using Expecty to do power assert.

Power assert (or power assertion) is a variant of `assert(...)` function that that prints out detailed error message automatically. It was originally implemented by Peter Niederwieser ([@pniederw](https://twitter.com/pniederw)) for [Spock](http://spockframework.org/), and in 2009 it was merged into [Groovy 1.7][g2009]. Power assert has spread to [Ruby][rpower], [JavaScript][jspower], [Rust][rspower], etc.

### traditional assert statements

Let's say you have something like `a * b`. Using a traditional `assert`, we would write:

```scala
scala> assert(a * b == 7, s"a = $a; b = $b; a * b = ${a * b}")
java.lang.AssertionError: assertion failed: a = 1; b = 3; a * b = 3
```

You often end up writing up log statements or error message that inspects all the variables.

### Expecty

For Scala, Peter Niederwieser himself wrote a mini library called [Expecty][expecty] around 2012 that implements power assert. This is a good news and bad. It's good because it's there for us. It's partly bad because this original Expecty has not been updated since 2014, and has not yet adopted cross publishing convention, maybe because it's using Gradle as the build. Also it's doing the GitHub-as-repo thing. Basically it's looks abandoned.

I wanted give Expecty a try, so I forked the repo to [eed3si9n/expecty][expecty2], added sbt build, patched up the code so it works with 2.10, 2.11, 2.12, and 2.13.0-M4, sent a few [pull requests][10] upstream, changed the package name, and published my fork to Maven Central:

```scala
libraryDependencies += "com.eed3si9n.expecty" %% "expecty" % "0.11.0" % Test
```

and for Scala.JS and Scala Native:

```scala
libraryDependencies += "com.eed3si9n.expecty" %%% "expecty" % "0.11.0" % Test
```

Here's how we can use this:

```scala
scala> import com.eed3si9n.expecty.Expecty.assert
import com.eed3si9n.expecty.Expecty.assert

scala> assert(a * b == 7)
java.lang.AssertionError:

assert(a * b == 7)
       | | | |
       1 3 3 false

  at com.eed3si9n.expecty.Expecty$ExpectyListener.expressionRecorded(Expecty.scala:25)
  at com.eed3si9n.expecty.RecorderRuntime.recordExpression(RecorderRuntime.scala:34)
  ... 38 elide
```

As you can see, you get a nicer error message automatically.

If you're using ScalaTest, this feature is available as [DiagrammedAssertions](https://gist.github.com/bvenners/6b52677e801683df8d0a).

### Minitest for 2.13.0-M4

[Minitest][minitest] is a lightweight testing framework, that has nothing but `test("...") {}`, `setup`, and `teardown`, like classic JUnit. This is interesting since it's available for Scala.JS as well. However, as of this writing, ScalaCheck is not out yet for Scala 2.13.0-M4, so Minitest is also not out yet.

With [a small patch][14] I was able to get Minitest working locally. All I need to do is check that out under `$HOME/workspace` and use [sbt-sriracha][sbt-sriracha]:

```scala
val minitestJVMRef = ProjectRef(IO.toURI(workspaceDirectory / "minitest"), "minitestJVM")
val minitestJVMLib = "io.monix" %% "minitest" % "2.1.1"

lazy val scoptJVM = scopt.jvm.enablePlugins(SiteScaladocPlugin)
  .sourceDependency(minitestJVMRef % Test, minitestJVMLib % Test)
  .settings(
    testFrameworks += new TestFramework("minitest.runner.Framework")
  )
```

Once we have the binary available for Scala 2.13.0-M4, we can get rid of this contraption and use the normal `libraryDependencies`.

### Minitest + Expecty

Combining Minitest and Expecty is easy. First you add the Expecty fork to the build:

```scala
val minitestJVMRef = ProjectRef(IO.toURI(workspaceDirectory / "minitest"), "minitestJVM")
val minitestJVMLib = "io.monix" %% "minitest" % "2.1.1"

lazy val scoptJVM = scopt.jvm.enablePlugins(SiteScaladocPlugin)
  .sourceDependency(minitestJVMRef % Test, minitestJVMLib % Test)
  .settings(
    libraryDependencies += "com.eed3si9n.expecty" %% "expecty" % "0.11.0" % Test,
    testFrameworks += new TestFramework("minitest.runner.Framework")
  )
```

Next, define a trait as follows:

```scala
import com.eed3si9n.expecty.Expecty

trait PowerAssertions {
  lazy val assert: Expecty = new Expecty()
}
```

Then you can write tests like this:

```scala
import minitest._

object ImmutableParserSpec extends SimpleTestSuite with PowerAssertions {
  test("int parser should parse 1") {
    intParser("--foo", "1")
    intParser("--foo:1")
  }

  val intParser1 = new scopt.OptionParser[Config]("scopt") {
    override def showUsageOnError = true
    head("scopt", "3.x")
    opt[Int]('f', "foo").action( (x, c) => c.copy(intValue = x) )
    help("help")
  }
  def intParser(args: String*): Unit = {
    val result = intParser1.parse(args.toSeq, Config())
    assert(result.get.intValue == 1)
  }

  ....
}
```

Let's change the value 1 to 2, and see how it fails.

```scala
[info] - int parser should parse 1 *** FAILED ***
[info]   AssertionError:
[info]
[info]   assert(result.get.intValue == 2)
[info]          |      |   |        |
[info]          |      |   1        false
[info]          |      Config(false,1,0,,0.0,false,false,0.0,http://localhost,0 days,,,,List(),ChampHashMap(),List(),)
[info]          Some(Config(false,1,0,,0.0,false,false,0.0,http://localhost,0 days,,,,List(),ChampHashMap(),List(),))
[info]     com.eed3si9n.expecty.Expecty$ExpectyListener.expressionRecorded(Expecty.scala:25)
[info]     com.eed3si9n.expecty.RecorderRuntime.recordExpression(RecorderRuntime.scala:34)
[info]     ImmutableParserSpec$.intParser(ImmutableParserSpec.scala:258)
[info]     ImmutableParserSpec$.$anonfun$new$3(ImmutableParserSpec.scala:18)
[info]     minitest.SimpleTestSuite.$anonfun$test$1(SimpleTestSuite.scala:27)
[info]     minitest.api.TestSpec$.$anonfun$sync$1(TestSpec.scala:51)
[info]     minitest.api.TestSpec.apply(TestSpec.scala:27)
[info]     minitest.api.Properties.$anonfun$iterator$2(Properties.scala:38)
[info]     minitest.api.TestSpec.apply(TestSpec.scala:27)
[info]     minitest.runner.Task.loop$1(Task.scala:40)
[info]     minitest.runner.Task.$anonfun$execute$1(Task.scala:47)
[info]     scala.concurrent.Future.$anonfun$flatMap$1(Future.scala:259)
[info]     scala.concurrent.impl.Promise.$anonfun$transformWith$1(Promise.scala:37)
[info]     scala.concurrent.impl.CallbackRunnable.run(Promise.scala:60)
[info]     java.util.concurrent.ForkJoinTask$RunnableExecuteAction.exec(ForkJoinTask.java:1402)
[info]     java.util.concurrent.ForkJoinTask.doExec(ForkJoinTask.java:289)
[info]     java.util.concurrent.ForkJoinPool$WorkQueue.runTask(ForkJoinPool.java:1056)
[info]     java.util.concurrent.ForkJoinPool.runWorker(ForkJoinPool.java:1692)
[info]     java.util.concurrent.ForkJoinWorkerThread.run(ForkJoinWorkerThread.java:157)
```

Sweet.

### let's use more power asserts

`assert(...)` function is a useful tool that's used in wide ranges of code both in main and test code.
Power assert doesn't fully replace test frameworks, but it would give power to existing tests like scripted and partests.

In 2012, Paul Phillips sent a note to scala-language mailing list, titled [expressive assertions: the best thing ever][pp2012]:

> I have long been very envious of the languages which can do useful things with asserts.  Then came the macros...
>
> I adapted Peter Niederwieser's [expecty][expecty] so it could be used with the signatures of assert/assume/require, then built the compiler with it.  [Look!][2] I dare you to say there is anything better in this life or the next.

### summary

- Expecty brings power assert to Scala.
- Using sbt-sriracha I can use Minitest before it's available for 2.13.0-M4.
- Minitest and Expecty compose.
