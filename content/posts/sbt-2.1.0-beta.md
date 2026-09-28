---
title: "sbt 2.1.0 beta (2.1.0-M3)"
type: story
date: 2026-09-28
url: /sbt-2.1.0-beta
tags: ["sbt"]
---

Hi everyone. On behalf of the sbt project, I am happy to announce sbt 2.1.0-M1. This is the beta version of the first feature release of sbt 2.x, a binary compatible release focusing on new features.

The headline features of sbt 2.1.0 are:

- Scala 3.9.0 on metabuild
- Ivyless publishing
- Updated `clean` task
- Testing UX improvements
- Various performance improvements

The full release note is at <https://github.com/sbt/sbt/releases/tag/v2.1.0-M1> and <https://github.com/sbt/sbt/releases/tag/v2.1.0-M3>. See also [sbt 2.0 change summary](https://www.scala-sbt.org/2.x/docs/en/changes/sbt-2.0-change-summary.html).

<!--more-->

### How to upgrade

You can upgrade to sbt 2.1.0-M3 by putting the following in `project/build.properties`:

```bash
sbt.version=2.1.0-M3
```

This mechanism allows that sbt 2.1.0-M3 is used only for the builds that you want.

Download **the official sbt runner** from SDKMAN, or download from <https://github.com/sbt/sbt/releases/tag/v2.1.0-M3> to upgrade the `sbt` shell script, sbtn, and the launcher.

### Changes since 2.1.0-M1

- Updates to Coursier 2.1.25, which enables custom HTTP user agent.
- Updates to Gigahorse 0.9.6 to work around Apache HttpClient issue with HTTP/2.
- Updates to scala-xml 2.5.0, scala-parser-combinators 2.5.0, and Caffeine 3.2.4 for sun.misc.Unsafe migration.
- Identity map optimization.
- `remoteCacheRequestTimeout` setting.
- `sbt` runner script honors `JAVA_HOME`.
- Many other bug fixes.

### Changes with compatibility implications

- Metabuild is updated to Scala 3.9.
- Apache Ivy is removed from the dependency.
- `sbt` runner script honors `JAVA_HOME`.

#### Scala 3.9 on metabuild

sbt 2.1.0 updates the Scala version used by the metabuild to Scala 3.9.0.

Since both sbt 2.x and Scala 3.x are only backward compatible across minor versions, appropriate Scala version must be used for building sbt plugins. This also means that a plugin built using sbt 2.1.x will not work on sbt 2.0.x:

| sbt 2.x | Scala 3.x | Plugin works on sbt 2.0.x |
| ------: | --------: | :-----------------------: |
| 2.0.x   | 3.8.x     | ✅                        |
| 2.1.0   | 3.9.x     | ❌                        |

**Plugin authors**: Here's how to set the minimal sbt version for your plugin:

```scala
pluginCrossBuild / sbtVersion := {
  scalaBinaryVersion.value match {
    case "2.12" => "1.9.9"
    case _      => "2.0.8"
  }
}
```

#### Publishing

sbt 2.1.0 removes Apache Ivy from its transitive dependency, which was previously used for publishing, and implements Ivyless publishing.

This was contributed by [@bitloi][@bitloi], [@fury0928][@fury0928], [@BrianHotopp][@BrianHotopp], and [@eed3si9n][@eed3si9n] in [#8686](https://github.com/sbt/sbt/pull/8686), [#8866](https://github.com/sbt/sbt/pull/8866), [#8894](https://github.com/sbt/sbt/pull/8894), [#8975](https://github.com/sbt/sbt/pull/8975), [#8988](https://github.com/sbt/sbt/pull/8988), [#8996](https://github.com/sbt/sbt/pull/8996), [#9069](https://github.com/sbt/sbt/pull/9069), [#9463](https://github.com/sbt/sbt/pull/9463), [#9533](https://github.com/sbt/sbt/pull/9533), and [#9615](https://github.com/sbt/sbt/pull/9615) etc.

### clean task

To restore the semantics of `clean` in the presence of disk cache, sbt 2.1.0 updates the `clean` task to act as a cache invalidator. Regardless of the cache state, running `clean` would invalidate the cache for the next command execution. This can be scoped to subproject or configuration:

```bash
$ sbt foo/clean
$ sbt foo/compile
```

This was contributed by [@eed3si9n][@eed3si9n] in [#9752](https://github.com/sbt/sbt/pull/9752).

### Test UX improvements

#### Test summary

When tests are executed, sbt 2.1.0 displays a test summary at the end, listing the failed test suites as follows:

```bash
[error] Test summary (2 test tasks failed):
[error]   a / Test / testQuick
[error]         com.example.a.TestA     FAIL
[error]   b / Test / testQuick
[error]         com.example.b.TestB     FAIL
[error]
[error] failed: total 4, failed 2, errors 0, passed 2, cached 2
```

Successful tests will display only a terse summary by default:

```bash
[info] passed: total 4, failed 0, errors 0, passed 4, cached 4
```

`--test_summary=success` can override the behavior to list the successful test as well. Test summary was contributed by [@eed3si9n][@eed3si9n] and [@BrianHotopp][@BrianHotopp] in [#9602](https://github.com/sbt/sbt/pull/9602) + [#9214](https://github.com/sbt/sbt/pull/9214).

#### Test cache opt-out

sbt 2.1.0 can let you opt out of test result caching:

```bash
$ sbt test --cache_test_result=false
```

This was contributed by [@anatoliykmetyuk][@anatoliykmetyuk] in [#9675](https://github.com/sbt/sbt/pull/9675).

#### workerMaxInstances and testTopology

sbt 2.1.0 adds new settings `workerMaxInstances` and `testTopology` to control test scheduling,
especially of the forked tests. Use `Global / workerMaxInstances` to change the number of worker instances. The default is set to 2:

```scala
// or sbt -Dsbt.worker_max_instances=2
Global / workerMaxInstances := 2
```

Use the `testTopology` setting to control whether you want to split the test classes into multiple workers or keep them together. The default was changed to split to 2 groups:

```scala
Test / testTopology := TestTopology.subprojectSplit(2)
```

To keep all classes in a subproject on one worker instead, use:

```scala
Test / testTopology := TestTopology.subprojectExclusive
```

This was contributed by [@eed3si9n][@eed3si9n] in [#9665](https://github.com/sbt/sbt/pull/9665).

### Source dependency update

sbt 2.1.0 provides better control to handle source dependencies.

This was contributed by [@seroperson][@seroperson] in [#8880](https://github.com/sbt/sbt/pull/8880).

### Identity map optimization

In sbt 2.1.0, a key assignment (`:=`) whose right-hand side is `expr.value` short-circuits to `x.set(expr)`.
This is helpful in avoiding `JsonFormat[A]` when `expr` is an uncached task.

This was contributed by [@eed3si9n][@eed3si9n] in [#9831](https://github.com/sbt/sbt/pull/9831)

### ⚡ Performance improvements

- perf: lightweight `UpdateReport` cache persistence by [@bitloi][@bitloi] in [#8815](https://github.com/sbt/sbt/pull/8815)
- perf: Cache `AutoPlugin` `projectSettings`/`projectConfigurations` by [@volcano303][@volcano303] in [#9077](https://github.com/sbt/sbt/pull/9077)
- perf: Resolve dependencies in parallel under the super shell by [@BrianHotopp][@BrianHotopp] in [#9295](https://github.com/sbt/sbt/pull/9295)
- Optimize `InterfaceUtil` by [@xuwei-k][@xuwei-k] in [#9223](https://github.com/sbt/sbt/pull/9223)
- perf: Intern `UpdateReport` values by [@hoangmaihuy][@hoangmaihuy] in [#9523](https://github.com/sbt/sbt/pull/9523)
- perf: Keep the Analysis cached across an action cache output sync by [@hoangmaihuy][@hoangmaihuy] in [#9550](https://github.com/sbt/sbt/pull/9550)
- perf: Skip extracting a dirzip whose digest already matches by [@hoangmaihuy][@hoangmaihuy] in [#9555](https://github.com/sbt/sbt/pull/9555)
- perf: Optimize `UpdateReport` disk format by [@hoangmaihuy][@hoangmaihuy] in [#9515](https://github.com/sbt/sbt/pull/9515)
- perf: Skip re-packaging the class directory when zinc recompiles nothing by [@hoangmaihuy][@hoangmaihuy] in [#9609](https://github.com/sbt/sbt/pull/9609)
- perf: Copy instead of symlink when restoring the disk cache on APFS by [@hoangmaihuy][@hoangmaihuy] in [#9623](https://github.com/sbt/sbt/pull/9623)
- perf: Avoid re-sorting watch inputs on every file event by [@stasimus][@stasimus] in [#9650](https://github.com/sbt/sbt/pull/9650)
- perf: Write `packageBin` JARs and action cache zips in parallel by [@hoangmaihuy][@hoangmaihuy] in [#9661](https://github.com/sbt/sbt/pull/9661)
- perf: Cut redundant hashing in disk action cache by [@stasimus][@stasimus] in [#9649](https://github.com/sbt/sbt/pull/9649)
- perf: Populate the in-memory cache on a read by [@hoangmaihuy][@hoangmaihuy] in [#9657](https://github.com/sbt/sbt/pull/9657)

### 🚀 Other updates

- Adds project id to Zinc debug log by [@Achieve3318][@Achieve3318] in [#8750](https://github.com/sbt/sbt/pull/8750)
- feat: Support `doc / skip := true` by [@fury0928][@fury0928] in [#8824](https://github.com/sbt/sbt/pull/8824)
- feat: case-insensitive tab completion by [@bitloi][@bitloi] in [#8827](https://github.com/sbt/sbt/pull/8827)
- dependencyTree: add `--append` for file output in multi-module builds by [@oolokioo7][@oolokioo7] in [#8878](https://github.com/sbt/sbt/pull/8878)
- feat: Eviction error for downgrade of Scala 3.x by [@bitloi][@bitloi] in [#8912](https://github.com/sbt/sbt/pull/8912)
- feat: Add English aliases `cross` and `switch` for `+` / `++` by [@jonathanchang31][@jonathanchang31] in [#9051](https://github.com/sbt/sbt/pull/9051)
- feat: BSP `buildTarget/dependencyModules` by [@jsdevninja][@jsdevninja] in [#9085](https://github.com/sbt/sbt/pull/9085)
- feat: Forward test events to listeners as they are emitted by [@claytonlin1110][@claytonlin1110] in [#9087](https://github.com/sbt/sbt/pull/9087)
- feat: Adds `ModuleID#exclude` that accepts `a %% b` by [@seroperson][@seroperson] in [#8756](https://github.com/sbt/sbt/pull/8756)
- Specific error message for defining types in `build.sbt` by [@xuwei-k][@xuwei-k] in [#9579](https://github.com/sbt/sbt/pull/9579)
- Use JDK's Unix domain socket for bootserver by [@eed3si9n][@eed3si9n] in [#9427](https://github.com/sbt/sbt/pull/9427)
- feat: Adds `Seq[Initialize[Task[T]]]#join` extension method by [@jozanek][@jozanek] in [#9347](https://github.com/sbt/sbt/pull/9347)
- feat: Adds `LoggerContext.removeAppender` for single appender removal by [@stasimus][@stasimus] in [#9740](https://github.com/sbt/sbt/pull/9740)
- feat: Improve Zinc invalidation debug logs by [@jozanek][@jozanek] in [zinc#1765](https://github.com/sbt/zinc/pull/1765)
- feat: Adds `ProjectMatrix#configureRows` and `configurePlatforms` methods by [@kitbellew][@kitbellew] in [#9765](https://github.com/sbt/sbt/pull/9765)
- feat: Persistent worker for tests by [@eed3si9n][@eed3si9n] in [#9678](https://github.com/sbt/sbt/pull/9678)
- `remoteCacheRequestTimeout` setting by [@eed3si9n][@eed3si9n] in [#9829](https://github.com/sbt/sbt/pull/9829)

### 🐛 Bug fixes

80+ bug fixes. See <https://github.com/sbt/sbt/releases/tag/v2.1.0-M1> and <https://github.com/sbt/sbt/releases/tag/v2.1.0-M3>.

### Participation

sbt 2.1.0-M1 is brought to you by 36 contributors. Eugene Yokota (eed3si9n), Kenji Yoshida (xuwei-k), BrianHotopp, Anatolii Kmetiuk, Jozef Koval, Dream, Mai Huy Hoàng, Stas Shevchenko, bitloi, Albert Meltzer, BitToby, Daniil Sivak, Dmitrii Naumenko, corevibe555, it-education-md, oolokioo7, Arnout Engelen, Christian Harrington, Li Haoyi, Matt Dziuban, Matthias Kurz, Merlin Hughes, Pandaman, Angel98518, BinaryWorldTl, BitCompass, Clayton, Jonathan Chang, Philippus Baalman, Tu Nguyen, Viktor Rudebeck, atoz96, ckstck, jimcody1995, since-2017-hub, volcano303. Thanks!

Thanks to everyone who's helped improve sbt and Zinc by using them, reporting bugs, improving our documentation, porting builds, porting plugins, and submitting and reviewing pull requests.

For anyone interested in helping sbt, there are many avenues for you to help, depending on your interest. If you're interested, [Contributing](https://github.com/sbt/sbt/blob/develop/CONTRIBUTING.md), ["help wanted"](https://github.com/sbt/sbt/issues?q=is%3Aissue+is%3Aopen+label%3A%22help+wanted%22), ["good first issue"](https://github.com/sbt/sbt/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22), and [Discussions](https://github.com/sbt/sbt/discussions/) are good starting points.

  [@eed3si9n]: https://github.com/eed3si9n
  [@anatoliykmetyuk]: https://github.com/anatoliykmetyuk
  [@xuwei-k]: https://github.com/xuwei-k
  [@Achieve3318]: https://github.com/Achieve3318
  [@azdrojowa123]: https://github.com/azdrojowa123
  [@bitloi]: https://github.com/bitloi
  [@BrianHotopp]: https://github.com/BrianHotopp
  [@claytonlin1110]: https://github.com/claytonlin1110
  [@fury0928]: https://github.com/fury0928
  [@hoangmaihuy]: https://github.com/hoangmaihuy
  [@jonathanchang31]: https://github.com/jonathanchang31
  [@jozanek]: https://github.com/jozanek
  [@jsdevninja]: https://github.com/jsdevninja
  [@kitbellew]: https://github.com/kitbellew
  [@mrdziuban]: https://github.com/mrdziuban
  [@oolokioo7]: https://github.com/oolokioo7
  [@raboof]: https://github.com/raboof
  [@seroperson]: https://github.com/seroperson
  [@stasimus]: https://github.com/stasimus
  [@tanishiking]: https://github.com/tanishiking
  [@unkarjedy]: https://github.com/unkarjedy
  [@volcano303]: https://github.com/volcano303
