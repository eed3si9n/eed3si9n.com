---
title:       "sudori part 5"
type:        story
date:        2024-09-08
draft:       false
url:         /sudori-part5
tags:        [ "sbt" ]
---

  [part3]: /sudori-part3
  [part4]: /sudori-part4
  [sbt-remote-cache]: /sbt-remote-cache
  [sbt-remote-cache-with-bazel-compat]: /sbt-remote-cache-with-bazel-compat
  [7644]: https://github.com/sbt/sbt/pull/7644
  [Mokhov2018]: https://www.microsoft.com/en-us/research/uploads/prod/2018/03/build-systems.pdf

This is a blog post on sbt 2.x development, continuing from [part 3][part3], [sbt 2.x remote cache][sbt-remote-cache], [sbt 2.x remote cache with Bazel compatibility][sbt-remote-cache-with-bazel-compat], [sudori part 4][part4] etc. I work on sbt 2.x in my own time with collaboration with the Scala Center and other volunteers, like Billy at EngFlow. These posts are extended PR descriptions to share the features that will come to a future version of sbt.

### introduction

I was on a late summer vacation in a beach town in Connecticut this week — checking out local skate spots, dipping into cool Long Island Sound, and comparing lobster rolls. In between skateboarding and beach going, I worked on remote test caching in sbt, and a few experiments related to the idea. I'd like to share some of my findings here, mostly as a development write-up.

In [sudori part 4][part4] we looked into remote caching of `compile` task. While caching `compile` is useful, most of the CI (continuous integration) systems spend their time running tests, not just compiling code. Bazel achieves orders-of-magnitude faster CI in part due the default `test` command being remote cached. In other words, using Bazel, if a test runs once on a CI machine, the test result will be cached until its input changes.

An advanced sbt user might note that sbt already includes the `testQuick` task for local incremental testing. The issue with `testQuick` is that its invalidation relies on timestamps, which are non-hermetic, and thus not reproducible across machines. In this post, we'll discuss test caching for sbt 2.x that can be shared safely across the machines. The corresponding pull request is [sbt/sbt#7644][7644].

<!--more-->

### the anatomy of sbt 1.x testQuick

As a reference, it would be useful to understand how `testQuick` works in sbt 1.x in a bit more details. In sbt, there's a mechanism called `TestsListener` where a build user can register a lister to handle test events, like test completing. sbt 1.x implements a lister by default called [TestStatusReporter](https://github.com/sbt/sbt/blob/v1.10.1/testing/src/main/scala/sbt/TestStatusReporter.scala):

```scala
private[sbt] class TestStatusReporter(f: File) extends TestsListener {
  private lazy val succeeded: concurrent.Map[String, Long] = TestStatus.read(f)
  def startGroup(name: String): Unit = { succeeded.remove(name); () }
  def endGroup(name: String, result: TestResult): Unit = {
    if (result == TestResult.Passed)
      succeeded(name) = System.currentTimeMillis
  }
  def doComplete(finalResult: TestResult): Unit = {
    TestStatus.write(succeeded, "Successful Tests", f)
  }
}
```

In short, every time a test passes, the current timestamp is recorded. At the end of `test`, `TestStatus.write(...)` writes a Java properties file named `succeeded_tests` in a known location under `target/`.

`testQuick` filters down the defined test suite candidates using [testQuickFilter](https://github.com/sbt/sbt/blob/v1.10.1/main/src/main/scala/sbt/Defaults.scala#L1432-L1473), which calculates the most-recent timestamp of the transitive dependencies of the test implementation:

```scala
val stamps = collection.mutable.Map.empty[String, Long]
def stamp(dep: String): Long = {
  val stamps = for (a <- ans) yield intlStamp(dep, a, Set.empty)
  if (stamps.isEmpty) Long.MinValue
  else stamps.max
}
def intlStamp(c: String, analysis: Analysis, s: Set[String]): Long =
  ....
def noSuccessYet(test: String) = succeeded.get(test) match {
  case None     => true
  case Some(ts) => stamps.synchronized(stamp(test)) > ts
}
```

By _transitive dependencies_, I mean both class dependencies and library JARs.

### what is an incremental tests?

Rewording [Build Systems à la Carte (Mokhov et al, 2018)][Mokhov2018] a bit, we can think of an incremental test to be: A test system is _minimal_ if it executes test suites at most once per run and only if they transitively depend on inputs that changed since the previous run. We can define a test system to be _incremental_ if it runs at least the minimal tests, and sometimes more.

At first it seems similar to the incremental compilation, but there's a critical difference between compiling and testing. With Scala, we can often ignore the body of methods during compilation. Bazel goes as far to define `ijar` which blanks out the implementation entirely for Java. So if class `B` calls `A#foo` in `A`, incremental compilation often does not invalidate `B` when the body of `A#foo` changes. For testing, changes in the method body matter.

Let's use some examples. Assume we have the following classes:

```scala
// Animal.scala
package example

trait Animal:
  def walk: Int = 0
end Animal

// Cow.scala
package example

class Cow extends Animal:
  def moo: Int = 0
end Cow

// Mineral.scala
package example

trait Mineral:
  def ok: Boolean = true
end Mineral
```

And the following JUnit 4 test:

```scala
package example

import org.junit.Test
import org.junit.Assert.assertEquals

class CowTest:
  @Test
  def testMoo: Unit =
    val cow = Cow()
    assertEquals(cow.moo, 0)
end CowTest
```

Based on the minimality:

1. Changing `CowTest` itself should invalidate the previous test result
2. Changing `Cow` should invalidate the previous test result
3. Changing `Animal` should invalidate the previous test result
4. Changing `Mineral` should not invalidate the previous test result

A remote cached test would perform the above operations across multiple machines.

### step 1: hermetic incremental testing

Before we get into remote caching, we need to fix the reliance on timestamp, which is non-hermetic. Bazel forms a dependency graph between subprojects, or _targets_, and the caching and invalidation happens at the target boundary. That doesn't quite work for sbt where one subproject contains many test suites.

We can, however, create a sub-JAR graph at the class granularity, which is what Zinc Analysis tracks for incremental compilation. The way I think about it is that incremental compilation forms a monoid in the category of `*.class` where the arrow goes out following the method calls only when the signature changes. Whereas, incremental testing forms a monoid in the category of `*.class` where the arrow goes out of the method calls anytime the bytecode changes.

| -           |       object |                  arrow |
|-------------|-------------:|-----------------------:|
| bazel test  | JAR (target) |         JAR dependency |
| sbt compile |    `*.class` |      method call / API |
| sbt test    |    `*.class` | method call / bytecode |

sbt already has a task called `definedTests` to automatically detect test suites in a subproject. I'm introducing a new task called `definedTestDigests`, which is typed to `Map[String, Digest]`. `Digest` represents a combo of a cryptographic hash and the file size, but here, we are using it as a [Merkle tree](https://en.wikipedia.org/wiki/Merkle_tree) of digests.

```scala
class ClassStamper(
    classpath: Seq[Attributed[HashedVirtualFileRef]],
    converter: FileConverter,
):
  /**
   * Given a classpath and a class name, this tries to create a SHA-256 digest.
   * @param className className to stamp
   * @param extraHashes additional information to include into the returning digest
   */
  private[sbt] def transitiveStamp(
      className: String, extaHashes: Seq[Digest]): Option[Digest] =
    val digests = SortedSet(analyses.flatMap(internalStamp(className, _, Set.empty)): _*)
    if digests.nonEmpty then Some(Digest.sha256Hash(digests.toSeq ++ extaHashes: _*))
    else None

  private def internalStamp(
      className: String,
      analysis: Analysis,
      alreadySeen: Set[String],
  ): SortedSet[Digest] =
    ....
end ClassStamper
```

The `internalStamp(...)` method follows similar logic as `testQuick`, except it will calculate SHA-256 of the bytecode instead of the compilation timestamp. We can trigger `definedTestDigests` task immediately after `compile` to pre-calculate the Merkle tree of SHA-256 hashes for all discovered test suites.

```scala
  // cache the test digests against the fullClasspath.
  def definedTestDigestTask: Initialize[Task[Map[String, Digest]]] = Def.cachedTask {
    val cp = (Keys.test / fullClasspath).value
    val testNames = Keys.definedTests.value.map(_.name).toVector.distinct
    val converter = fileConverter.value
    val sv = Keys.scalaVersion.value
    val inputs = (Keys.compile / Keys.compileInputs).value
    // by default this captures JVM version
    val extraInc = Keys.extraIncOptions.value
    // throw in any information useful for runtime invalidation
    val salt = s"""$sv
${converter.toVirtualFile(inputs.options.classesDirectory)}
${extraInc.mkString(",")}
"""
    val extra = Vector(Digest.sha256Hash(salt.getBytes("UTF-8")))
    val stamper = ClassStamper(cp, converter)
    Map((testNames.flatMap: name =>
      stamper.transitiveStamp(name, extra) match
        case Some(ts) => Seq(name -> ts)
        case None     => Nil
    ): _*)
  }
```

Given that a class can be cross built across different JVM versions, Scala versions, and JVM vs JS vs Native, we capture additional information as `salt`, which are hashed together. This `Digest` can be used in `succeeded_tests` replacing the timestamp. Given a test suite like `CowTest`, if the file contains the same `Digest` as the current `Digest`, that means the test can be skipped.

### step 2: caching the test results

The nice thing about sbt 2.x's caching system is that the interface for the local disk cache and the remote cache is unified. So we have to get it into the sbt 2.x caching system once and that should implement both disk cache and remote cache.

Keeping with the Bazel tradition, a cacheable unit would be called an action cache. Since I'm going to only cache the successful tests, we can represent them with an integer value `0`. The new `TestStatusReporter` can do this after each test suite succeeds:

```scala
private[sbt] class TestStatusReporter(
    digests: Map[String, Digest],
    cacheConfiguration: BuildWideCacheConfiguration,
) extends TestsListener:
  // int value to represent success
  private final val successfulTest = 0

  /**
   * If the test has succeeded, record the fact that it has
   * using its unique digest, so we can skip the test later.
   */
  def endGroup(name: String, result: TestResult): Unit =
    if result == TestResult.Passed then
      digests.get(name) match
        case Some(ts) =>
          // treat each test suite as a successful action that returns 0
          ActionCache.cache(
            key = (),
            codeContentHash = ts,
            extraHash = Digest.zero,
            tags = CacheLevelTag.all.toList,
            config = cacheConfiguration,
          ): (_) =>
            ActionCache.actionResult(successfulTest)
        case None => ()
    else ()
end TestStatusReporter
```

Next on the `testQuick` filter, we can check if the action cache exists for the Merkle tree:

```scala
def hasSucceeded(className: String): Boolean = digests.get(className) match
  case None     => false
  case Some(ts) => hasCachedSuccess(ts)

def hasCachedSuccess(ts: Digest): Boolean =
  val input = cacheInput(ts)
  ActionCache.exists(input._1, input._2, input._3, config)

def cacheInput(value: Digest): (Unit, Digest, Digest) =
  ((), value, Digest.zero)
```

If the action cache exists, we know it's `0`, so we don't bother grabbing the value.

### demo 1: passing information

See [sbt 2.x remote cache with Bazel compatibility][sbt-remote-cache-with-bazel-compat] on how to configure remote cache with different backends. Let's try testing using `CowTest`.

```scala
package example

import org.junit.Test
import org.junit.Assert.assertEquals

class CowTest:
  @Test
  def testMoo: Unit =
    val cow = Cow()
    assertEquals(cow.moo, 0)
end CowTest
```

**directory 1**:

First the test works normally:

```bash
$ sbt
[info] welcome to sbt 2.0.0-alpha11-SNAPSHOT (Azul Systems, Inc. Java 1.8.0_402)
....
sbt:inctest> testQuick
[info] Updating inctest_3
[info] Resolved inctest_3 dependencies
....
[info] Passed: Total 1, Failed 0, Errors 0, Passed 1
[success] elapsed time: 3 s, cache 0%, 6 onsite tasks
```

**directory 2**:

Next, copy the entire directory to another directory, wipe out the disk cache, and rerun the test:

```bash
$ rmtrash $HOME/Library/Caches/sbt/v2/ && rmtrash target && rmtrash project/target
$ sbt
[info] welcome to sbt 2.0.0-alpha11-SNAPSHOT (Azul Systems, Inc. Java 1.8.0_402)
sbt:inctest> testQuick
....
[info] Passed: Total 0, Failed 0, Errors 0, Passed 0
[info] No tests to run for Test / testQuick
[success] elapsed time: 2 s, cache 20%, 1 remote cache hit, 4 onsite tasks
```

Although it was within the same laptop, this shows that the test result from one directory carries over to another via the Bazel-compatible remote cache.

### demo 2: invalidations

Let's test the minimality criteria. First, change the test itself in some way to make sure it fails:

```scala
package example

import org.junit.Test
import org.junit.Assert.assertEquals

class CowTest:
  @Test
  def testMoo: Unit =
    val cow = Cow()
    assertEquals(cow.moo, 1)
end CowTest
```

```bash
sbt:inctest> testQuick
[error] Test example.CowTest.testMoo failed: java.lang.AssertionError: expected:<0> but was:<1>, took 0.002 sec
[error]     at example.CowTest.testMoo(CowTest.scala:10)
[error]     ...
[error] Failed: Total 1, Failed 1, Errors 0, Passed 0
[error] Failed tests:
[error]   example.CowTest
[error] (Test / testQuick) sbt.TestsFailedException: Tests unsuccessful
[error] elapsed time: 0 s, cache 100%, 5 remote cache hits
```

This failed as expected. Next change `Cow#moo` to return `1`:

```scala
package example

class Cow extends Animal:
  def moo: Int = 1
end Cow
```

Now it passes as expected. Next change the implementation of `Animal` trait:

```scala
package example

trait Animal:
  def walk: Int = 0
  def swim: Int = 0
end Animal
```

```bash
sbt:inctest> testQuick
[info] compiling 1 Scala source to target/out/jvm/scala-3.4.2/inctest/backend ...
[info] compiling 1 Scala source to target/out/jvm/scala-3.4.2/inctest/backend ...
[info] Passed: Total 1, Failed 0, Errors 0, Passed 1
[success] elapsed time: 1 s, cache 16%, 1 remote cache hit, 5 onsite tasks
```

This reran the test as expected. Finally, let's change the implementation of `Mineral`, which should not shake the `CowTest`:

```scala
package example

trait Mineral:
  def ok: Boolean = false
end Mineral
```

```bash
sbt:inctest> testQuick
[info] compiling 1 Scala source to target/out/jvm/scala-3.4.2/inctest/backend ...
[info] Passed: Total 0, Failed 0, Errors 0, Passed 0
[info] No tests to run for Test / testQuick
[success] elapsed time: 0 s, cache 20%, 1 remote cache hit, 4 onsite tasks
```

This worked as expected, since it compiled, but did _not_ invalidate the `CowTest` result. There might be a lot of small details we can improve, but hopefully this demonstrates the idea of remote caching of the tests.

### summary

In [sbt/sbt#7644][7644] I've implemented remote test caching for sbt 2.x that stores test success results across machine boundaries. `testQuick`, which can replace `test` only runs the tests that have been invalidated by input changes. Unlike sbt 1.x, the PR uses Merkle tree to perform the invalidation, which makes it hermetic to share across the machines. Caching the test result can speedup the CI jobs by orders of magnitude.

### Appdendix A: what is sudori?

Sweet and sour pork, often made with bell peppers and pineapple in Asia, is called 酢豚 (subuta) in Japan, or vinegar pork, and is one of bacronyms for sbt. 酢鶏 (sudori), or vinegar chicken, is a variant of subuta substituting pork with chicken, and it's a codename I've been using to discuss sbt 2.x. The word ketchup is said to derive from Hokkien word 膎汁 (kôe-chiap or kê-chiap) from southern coastal China, meaning fish sauce, which re-entered China from Vietnam in 1700s. Through trade, fish sauce also became popular in Britain, where it eventually became a mushroom paste. In 1800s, Americans started making it with tomatoes. In a sense, it's interesting how Cantonese dish like 咕嚕肉 (gūlōuyuhk), stomach-growling pork incorporates the American ketchup, making a full circle as sweet and sour pork.

### Appendix B: why did you use JUnit 4?

It turns out that some test frameworks use non-hermetic macros. For example, when I changed the directory munit produced different bytecode:

```diff
--- a/example/CowTest.class.asm
+++ b/example/CowTest.class.asm
@@ -56,7 +56,7 @@
     ]
     NEW munit/Location
     DUP
-    LDC "/Users/xxx/inctest/src/test/scala/example/CowTest.scala"
+    LDC "/Users/xxx/inctest2/src/test/scala/example/CowTest.scala"
     BIPUSH 6
     INVOKESPECIAL munit/Location.<init> (Ljava/lang/String;I)V
     INVOKEVIRTUAL example/CowTest.assert (Lscala/Function0;Lscala/Function0;Lmunit/Location;)V
```

**Update**: I sent [scalameta/munit#823](https://github.com/scalameta/munit/pull/823) to fix this.
