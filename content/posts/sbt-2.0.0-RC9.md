---
title: "sbt 2.0.0-RC9"
type: story
date: 2026-02-16
url: /sbt-2.0.0-RC9
tags: [ "sbt" ]
---

Hi everyone. On behalf of the sbt project, I am happy to announce sbt 2.0.0-RC8, a beta version of sbt 2.x. sbt 2.0 is a new version of sbt, based on Scala 3 constructs and Bazel-compatible cache system.

Please try it out, and report any issues you might come across. **Note**: sbt 2.0.0-RC9 will keep binary compatibility with 2.0.0 and 2.x.

### Key changes since 2.0.0-RC8

- JDK 17 + Scala 3.8.1 in metabuild
- Maven BOM (Bill of Materials) usage support
- client-side console
- `rootProject` macro
- experimental dependency lock
- experimental Ivyless publishing

See <https://github.com/sbt/sbt/releases/tag/v2.0.0-RC9> for the full details.

<!-- more -->

### Headline features of sbt 2.0

- sbt 2.x uses Scala 3.x for build definitions and plugins (Both sbt 1.x and 2.x are capable of building Scala 2.x and 3.x)
- Common settings. Bare settings are added to all subprojects, as opposed to just the root subproject, and thus replacing the role that ThisBuild has played.
- `test` changed to incremental test.
- Local/remote cache system that is Bazel-compatible. `compile` and `test` are both rewritten to be cachable tasks.
- Project matrix, which was available via plugin in sbt 1.x, is in-sourced in sbt 2.x.
- Extension of the unified slash syntax to support query of subprojects.
- Build Server Protocol improvements. In sbt 2.x the `run` task is non-blocking.
- New documentation

See also [sbt 2.0 change summary](https://www.scala-sbt.org/2.x/docs/en/changes/sbt-2.0-change-summary.html) for the details.

### How to upgrade

Download **the official sbt runner** for sbt 1.12.3 or later from SDKMAN, or download from <https://github.com/sbt/sbt/releases/tag/v1.12.3> to upgrade the `sbt` shell script, the launcher, and sbtn. Runner can launch any version of sbt.

The sbt version used for your build is upgraded by putting the following in `project/build.properties`:

```bash
sbt.version=2.0.0-RC9
```

This mechanism allows that sbt 2.0.0-RC9 is used only for the builds that you want.


### changes with compatibility implications

* Disables delegation of scoped settings and tasks on shell by [@eed3si9n][@eed3si9n] in [#8539](https://github.com/sbt/sbt/pull/8539)

## 🚀 updates

### JDK 17 + Scala 3.8.1 in metabuild

sbt 2.0.0-RC9 upgrades the Scala version used on the metabuild to Scala 3.8.1 after notifying the community in the users forum. This means that you would need JDK 17 or later to run sbt 2.x.

This was contributed by Eugene Yokota in [#8530](https://github.com/sbt/sbt/pull/8530).

### Maven BOM (Bill of Materials) usage support

sbt 2.0.0-RC9 adds Maven BOM (Bill of Materials) usage support. Subprojects can depend on published BOM artifacts using `.pomOnly()`:

```scala
libraryDependencies += ("com.fasterxml.jackson" % "jackson-bom" % "2.21.0").pomOnly()
```

These bill of materials are forwarded to Coursier via via `Resolve.addBom()`, which should introduce version constraints for specific libraries (such as Jackson). You can use `"*"` to declare versionless dependency:

```scala
libraryDependencies += "com.fasterxml.jackson.core" % "jackson-core" % "*"
```

This will let Coursier automatically fill in the version based on the bill of material constraints (in this case `"2.21.0"`).

This feature was contributed by [@bitloi][@bitloi] in [#8675](https://github.com/sbt/sbt/pull/8675).

### client-side console

Similar to the client-side run, sbt 2.0.0 implements the ability to send `console` (Scala REPL) back to the sbtn, which forks a fresh JVM to run the REPL. All you have to do is:

```bash
sbt console
```

One of the aims of running this on the client-side is to avoid blocking the sbt server.

This was contributed by Eugene Yokota and [@calm329][@calm329] in [#8604](https://github.com/sbt/sbt/pull/8604), [#8677](https://github.com/sbt/sbt/pull/8604), [#8705](https://github.com/sbt/sbt/pull/8705), [#8722](https://github.com/sbt/sbt/pull/8722).

### rootProject macro

sbt 2.0.0-RC9 support `rootProject` macro:

```scala
lazy val root = rootProject
  .autoAggregate
```

This is a shortcut for `(project in file("."))`, which tends to a boilerplate in `build.sbt`. This was contributed by [@bitloi][@bitloi] in [#8671](https://github.com/sbt/sbt/pull/8671).

### experimental: dependency lock

sbt 2.0.0-RC9 adds an experimental support for dependency locking.

```bash
sbt dependencyLock
```

This will generate `deps.lock` files in the base directory of each subproject. When a lock file is present, Coursier resolution is no longer called. This ensures reproducible builds across different machines and CI environments.

```bash
sbt dependencyLockCheck
```

`dependencyLockCheck` validates that the lock file is up-to-date.

This feature was contributed by [@MkDev11][@MkDev11] in [#8581](https://github.com/sbt/sbt/pull/8581).

### experimental: Ivyless publishing

sbt 1.x internally uses Apache Ivy for publishing; sbt 2.0.0-RC9 introduces experimental Ivyless publishing.

```bash
useIvy := false
```

This will use Ivyless implementation for `publishLocal` and `publish`. `ixy.xml` file generation uses Coursier.

This was contributed by [@calm329][@calm329] and [@bitloi][@bitloi] in [#8634](https://github.com/sbt/sbt/pull/8634), [#8686](https://github.com/sbt/sbt/pull/8686), [#8692](https://github.com/sbt/sbt/pull/8692)

### test-related changes

* feat: `testOnly` supports `...` as a wildcard pattern [@byteforge38][@byteforge38] in [#8577](https://github.com/sbt/sbt/pull/8577)
* feat: Adds `testForkedParallelism` setting for forked test parallelism by [@MkDev11][@MkDev11] in [#8453](https://github.com/sbt/sbt/pull/8453)
* feat: The root-level `testOnly` is changed to a command so it fails when no test classes match by [@calm329][@calm329] in [#8607](https://github.com/sbt/sbt/pull/8607)
* feat: Scripted should fail when no tests match the pattern by [@gayanMatch][@gayanMatch] in [#8457](https://github.com/sbt/sbt/pull/8457)
* fix: Fixes `explicitlySpecified` and selectors for `testOnly` by [@Eruis2579][@Eruis2579] in [#8727](https://github.com/sbt/sbt/pull/8727)


### other updates

* Adds "3-latest.candidate" support for Scala 3 release candidates by [@calm329][@calm329] in [#8596](https://github.com/sbt/sbt/pull/8596)
* Report eviction errors for `Test` dependencies by [@calm329][@calm329] in [#8451](https://github.com/sbt/sbt/pull/8451)
* Notify sbtn client when command is queued by [@bitloi][@bitloi] in [#8568](https://github.com/sbt/sbt/pull/8568)
* Drops other idle servers on client exit by [@calm329][@calm329] in [#8701](https://github.com/sbt/sbt/pull/8701)
* Allow system JNA on OpenBSD by making `jna.nosys` conditional by [@calm329][@calm329] in [#8452](https://github.com/sbt/sbt/pull/8452)
* Set terminal window title during `run` by [@MkDev11][@MkDev11] in [#8492](https://github.com/sbt/sbt/pull/8492)
* Cache failed compilation to avoid repeated failures by [@MkDev11][@MkDev11] in [#8490](https://github.com/sbt/sbt/pull/8490)
* Adds `csrLocalArtifactsShouldBeCached` setting for caching local artifacts by [@MkDev11][@MkDev11] in [#8504](https://github.com/sbt/sbt/pull/8504)
* Adds `dependencyLicenseInfo` by [@saber04414][@saber04414] in [#8506](https://github.com/sbt/sbt/pull/8506)
* Adds GitHub setup-java action support in `CrossJava` by [@MkDev11][@MkDev11] in [#8574](https://github.com/sbt/sbt/pull/8574)
* Adds `scriptedKeepTempDirectory` setting by [@bitloi][@bitloi] in [#8621](https://github.com/sbt/sbt/pull/8621)
* Adds per-channel project cursor for sbtn by [@bitloi][@bitloi] in [#8649](https://github.com/sbt/sbt/pull/8649)

## 🐛 bug fixes

### runner script-related fixes

* fix: Fixes the IDE debugger option on Windows by [@MkDev11][@MkDev11] in [#8440](https://github.com/sbt/sbt/pull/8440)
* fix: Fixes `--sbt-version` option handling by [@Angel98518][@Angel98518] in [#8446](https://github.com/sbt/sbt/pull/8446)
* fix: Fixes `sbt --client new` combination by [@MkDev11][@MkDev11] in [#8512](https://github.com/sbt/sbt/pull/8512)
* fix: Fixes `sbt new` argument parsing on Windows by [@MkDev11][@MkDev11] in [#8509](https://github.com/sbt/sbt/pull/8509)
* fix: Fixes sbtopts files priority in sbt runner by [@mohansinghi][@mohansinghi] in [#8514](https://github.com/sbt/sbt/pull/8514)
* fix: Fixes `-X` support on Windows batch runner by [@GlobalStar117][@GlobalStar117] in [#8566](https://github.com/sbt/sbt/pull/8566)
* fix: Fixes the handling of special characters in dot files by [@circlecrystalin][@circlecrystalin] in [#8558](https://github.com/sbt/sbt/pull/8558)
* fix: Fixes restore CLI precedence over `.sbtopts` by [@it-education-md][@it-education-md] in TODO
* fix: Handle paths with parentheses in sbt.bat on Windows by [@PandaMan][@PandaMan] in [#8656](https://github.com/sbt/sbt/pull/8656)
* fix: Handle JVM parameters with spaces in dot files by [@Eruis2579][@Eruis2579] in [#8730](https://github.com/sbt/sbt/pull/8730)

### other fixes

* fix: Restores Scala 2 reflect/compiler unification by [@calm329][@calm329] in [#8700](https://github.com/sbt/sbt/pull/8700) / [#8733](https://github.com/sbt/sbt/pull/8733)
* fix: Makes `libraryClassName` relation deterministic under concurrency by [@lihaoyi][@lihaoyi] in [zinc#1638](https://github.com/sbt/zinc/pull/1638)
* fix: Invalidates update cache across commands when dependencies change by [@calm329][@calm329] in [#8501](https://github.com/sbt/sbt/pull/8501)
* fix: Handles relocated dependencies in `dependencyTree` by [@calm329][@calm329] in [#8489](https://github.com/sbt/sbt/pull/8489)
* fix: Adds symlink optimization to `ActionCache.get` by [@tellorian][@tellorian] + [@MkDev11][@MkDev11] + [@azdrojowa123][@azdrojowa123] in [#8456](https://github.com/sbt/sbt/pull/8456) / [#8479](https://github.com/sbt/sbt/pull/8479) / [#8461](https://github.com/sbt/sbt/pull/8461) / [#8716](https://github.com/sbt/sbt/pull/8716)
* fix: Allow `dependencyTree` to run despite eviction errors by [@eureka928][@eureka928] in [#8554](https://github.com/sbt/sbt/pull/8554)
* fix: Prevents server boot when `--no-server` is used by [@SmartDever02][@SmartDever02] in [#8444](https://github.com/sbt/sbt/pull/8444)
* fix: Skips interactive prompt in batch mode when project loading by [@Francluob][@Francluob] in [#8447](https://github.com/sbt/sbt/pull/8447)
* fix: Applies dependencyOverrides to delivered Ivy XML by [@MkDev11][@MkDev11] in [#8463](https://github.com/sbt/sbt/pull/8463)
* fix: Filters out JAR paths in BSP diagnostics on Windows by [@MkDev11][@MkDev11] in [#8482](https://github.com/sbt/sbt/pull/8482)
* fix: Fixes ProjectMatrix invalid project ID with `CrossVersion.full` by [@byteforge38][@byteforge38] in [#8484](https://github.com/sbt/sbt/pull/8484)
* fix: Fixes updateSbtClassifiers using wrong Scala version for cross-built plugins by [@calm329][@calm329] in [#8495](https://github.com/sbt/sbt/pull/8495)
* fix: Allows `++` command to accept projects not in current state by [@MkDev11][@MkDev11] in [#8505](https://github.com/sbt/sbt/pull/8505)
* fix: Fixes pipelining flags applied to unsupported Scala versions by [@0xsatoshi99][@0xsatoshi99] in [#8499](https://github.com/sbt/sbt/pull/8499)
* fix: Uses strict matching for `scala-library` JAR detection by [@MkDev11][@MkDev11] in [#8507](https://github.com/sbt/sbt/pull/8507)
* fix: Fixes StackOverflowError when reporting self-referencing exceptions by [@MkDev11][@MkDev11] in [#8508](https://github.com/sbt/sbt/pull/8508)
* fix: Fixes `--no-colors` setting for sbtn by [@gayanMatch][@gayanMatch] in [#8517](https://github.com/sbt/sbt/pull/8517)
* fix: Fixes command logs by [@SalesforcePeak][@SalesforcePeak] in [#8515](https://github.com/sbt/sbt/pull/8515)
* fix: Fixes `whatDependsOn` error by [@Dairus01][@Dairus01] in [#8462](https://github.com/sbt/sbt/pull/8462)
* fix: Trim whitespaces from `sbt.version` in `build.properties` by [@0xsatoshi99][@0xsatoshi99] in [#8524](https://github.com/sbt/sbt/pull/8524)
* fix: Fixes `watchTriggers` to control what triggers by [@mohansinghi][@mohansinghi] in [#8525](https://github.com/sbt/sbt/pull/8525)
* fix: Fixes `inputFileChanges` with nested task scopes by [@MkDev11][@MkDev11] in [#8516](https://github.com/sbt/sbt/pull/8516)
* fix: Preserves user-defined `scalacOptions` in `doc` task scope by [@MkDev11][@MkDev11] in [#8528](https://github.com/sbt/sbt/pull/8528)
* fix: Starts server when explicitly requested via BSP/thin client by [@MkDev11][@MkDev11] in [#8529](https://github.com/sbt/sbt/pull/8529)
* fix: Propagates `SBT_OPTS` to BSP config by [@MkDev11][@MkDev11] in [#8531](https://github.com/sbt/sbt/pull/8531)
* fix: Prevents test from hanging when forked process crashes by [@MkDev11][@MkDev11] in [#8536](https://github.com/sbt/sbt/pull/8536)
* fix: Logs server response body on publish failure by [@MkDev11][@MkDev11] in [#8537](https://github.com/sbt/sbt/pull/8537)
* fix: Skips checksums for PGP signature files (`.asc`) by [@Dairus01][@Dairus01] in [#8535](https://github.com/sbt/sbt/pull/8535)
* fix: Fixes `NullPointerException` on exit by [@SmartDever02][@SmartDever02] in [#8448](https://github.com/sbt/sbt/pull/8448)
* fix: Formats Seq values consistently in multi-project builds by [@GlobalStar117][@GlobalStar117] in [#8567](https://github.com/sbt/sbt/pull/8567)
* fix: Prevents forked test cross talk by [@eed3si9n][@eed3si9n] in [#8575](https://github.com/sbt/sbt/pull/8575)
* fix: Lazily caches hostname resolution at object level by [@calm329][@calm329] in [#8603](https://github.com/sbt/sbt/pull/8603)
* fix: Uses `-external-mappings` for Scala 3 doc task #6652 by [@calm329][@calm329] in [#8602](https://github.com/sbt/sbt/pull/8602)
* fix: Suppresses "Multiple main classes" warning for runMain commands by [@calm329][@calm329] in [#8613](https://github.com/sbt/sbt/pull/8613)
* fix: Skips eviction warning when winner satisfies version range by [@calm329][@calm329] in [#8616](https://github.com/sbt/sbt/pull/8616)
* fix: Throws on `addCompilerPlugin(foo % Test)` by [@bitloi][@bitloi] in [#8622](https://github.com/sbt/sbt/pull/8622)
* fix: Displays HTTP response body when bundle upload fails by [@DeborahOlaboye][@DeborahOlaboye] in [#8630](https://github.com/sbt/sbt/pull/8630)
* fix: Detects alias name conflicts by [@bitloi][@bitloi] in [#8659](https://github.com/sbt/sbt/pull/8659)
* fix: Fixes subproject evaluation order by [@eed3si9n][@eed3si9n] in [#8672](https://github.com/sbt/sbt/pull/8672)
* fix: Skips writing `sbt.version` in scripted test directories by [@bitloi][@bitloi] in [#8673](https://github.com/sbt/sbt/pull/8673)
* fix: Fixes subproject deps with different Scala versions by [@bitloi][@bitloi] in [#8681](https://github.com/sbt/sbt/pull/8681)
* fix: Fixes `extraProjects` with auto-root aggregate breaks key aggregation by [@bitloi][@bitloi] in [#8690](https://github.com/sbt/sbt/pull/8690)
* fix: Allows defining the root project from `extraProjects` by [@bitloi][@bitloi] in [#8694](https://github.com/sbt/sbt/pull/8694)
* fix: Respect explicit platform settings in dependency resolution by [@Eruis2579][@Eruis2579] in [#8697](https://github.com/sbt/sbt/pull/8697)
* fix: Fixes configuration identifier for display by [@bitloi][@bitloi] in [#8698](https://github.com/sbt/sbt/pull/8698)
* fix: Fixes BSP compile to return `StatusCode.Error` on failure by [@Eruis2579][@Eruis2579] in [#8709](https://github.com/sbt/sbt/pull/8709)
* fix: Fixes `ThisBuild`-scoped keys using root project's aggregates by [@bitloi][@bitloi] in [#8703](https://github.com/sbt/sbt/pull/8703)
* fix: Fixes evicted warning for version intervals by [@Eruis2579][@Eruis2579] in [#8719](https://github.com/sbt/sbt/pull/8719)
* fix: Handles `CancellationException` gracefully with `usePipelining` by [@Eruis2579][@Eruis2579] in [#8718](https://github.com/sbt/sbt/pull/8718)
* fix: Fixes `lastGrep` to ignore ANSI escape sequences by [@Eruis2579][@Eruis2579] in [#8726](https://github.com/sbt/sbt/pull/8726)
* fix: Fixes the local artifact handling in `updateSbtClassifiers` task by [@azdrojowa123][@azdrojowa123] in [#8734](https://github.com/sbt/sbt/pull/8734)
* fix: Fixes sbt 2.x metabuild resolution by [@eed3si9n][@eed3si9n] in [#8743](https://github.com/sbt/sbt/pull/8743)

### Documentation localization

[sbt 2.x documentation](https://www.scala-sbt.org/2.x/docs/en/index.html) is reorganized following the four-documentation principle ([Diátaxis](https://diataxis.fr/)).

Some of the pages are localized, for example [why sbt exists](https://www.scala-sbt.org/2.x/docs/en/guide/why-sbt-exists.html) (English), [sbt の存在理由](https://www.scala-sbt.org/2.x/docs/ja/guide/why-sbt-exists.html) (Japanese), and [sbt 的存在理由](https://www.scala-sbt.org/2.x/docs/zh-cn/guide/why-sbt-exists.html) (Chinese, Simplified). Contributions are welcome in this area as well.

### Plugin ecosystem migration

[Help us cross build](https://github.com/sbt/sbt/wiki/sbt-2.x-plugin-migration) wiki page currently lists dozens of plugins being migrated to sbt 2.x by cross building to sbt 1.x and 2.x. Let us know a plugin you need is missing from the migration effort.

### Participation

I work on sbt in my own time with collaboration with Scala Center, Anatolii Kmetiuk, Adrien Piquerez (alumni), and other volunteers, like Kenji Yoshida, Jerry Tan, Matthias Kurz (Play maintainer), and recently Billy Autrey to name a few.

sbt 2.0.0-RC9 was brought to you by many contributors, including those who contributed to sbt 1.x series, migrating plugins, but according to `git shortlog -sn --no-merges 00eba85d98c854527125ae1655b5332c19b5afd8...733bcfb23997930915b563e7d27b1a1f6c0490da --not 1.11.x` and `git shortlog -sn --no-merges 242bd18d30c418620024d089b587f6d263d34247...v2.0.0-RC9 --not 1.11.x`:

```
443 Eugene Yokota (eed3si9n)
168 Kenji Yoshida (xuwei-k)
146 Adrien Piquerez
51  Jerry Tan (friendseeker)
35  MkDev11
24  bitloi
22  Scala Steward
21  calm329
15  dependabot[bot]
14  Yasuhiro Tatsuno
13  E.G
11  Pandaman
10  João Ferreira
9   Anton Sviridov
8   Aleksandra Zdrojowa
7   Anatolii Kmetiuk
5   Dairus
4   Martin Duhem
4   Matt Dziuban
4   john0030710
3   Angel98518
3   Brice Jaglin
3   gayanMatch
2   Billy Autrey
2   Damian Reeves
2   Dmitrii Naumenko
2   Frank S. Thomas
2   Jame4u
2   Josh Soref
2   Kamil Podsiadło
2   Li Haoyi
2   Matthew de Detrich
2   Miguel Vilá
2   Pluto
2   SID
2   Satoshi Dev
2   byteforge
2   circlecrystalin
1   Deborah Funmilola Olaboye
1   Dream
1   Francluob
1   Guillaume Massé
1   Hamza Remmal
1   Hugo van Rijswijk
1   Jakub Kozłowski
1   James Roper
1   Karl Yngve Lervåg
1   Marco Zühlke
1   Matthias Kurz
1   NeedmeFordev
1   Nikita Vilunov
1   OlegYch
1   Pegasus
1   Rex Kerr
1   Roberto Tyley
1   Saber
1   SalesforcePeak
1   SlowBrainDude
1   Zainab Ali
1   bohdansolovie
1   dive2tech
1   kijuky
1   nathanlao
```

Thanks to everyone who's helped improve sbt and Zinc by using them, reporting bugs, improving our documentation, porting builds, porting plugins, and submitting and reviewing pull requests.

For anyone interested in helping sbt, there are many avenues for you to help, depending on your interest. If you're interested, [Contributing](https://github.com/sbt/sbt/blob/develop/CONTRIBUTING.md), ["help wanted"](https://github.com/sbt/sbt/issues?q=is%3Aissue+is%3Aopen+label%3A%22help+wanted%22), ["good first issue"](https://github.com/sbt/sbt/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22), and [Discussions](https://github.com/sbt/sbt/discussions/) are good starting points.

----

### FYI - Scala Days talk

I gave a talk in Scala Days 2025 about sbt 2.0 ([slide deck](https://www.slideshare.net/slideshow/sbt-2-0-go-big-scala-days-2025-edition/282592302)).

### Donate to Scala Center

Scala Center is a non-profit center at EPFL to support education and open source.

- [The Scala Center Fundraising Campaign](https://scala-lang.org/blog/2023/09/11/scala-center-fundraising.html)

  [migration]: https://www.scala-sbt.org/2.x/docs/en/changes/migrating-from-sbt-1.x.html
  [@eed3si9n]: https://github.com/eed3si9n
  [@anatoliykmetyuk]: https://github.com/anatoliykmetyuk
  [@adpi2]: https://github.com/adpi2
  [@xuwei-k]: https://github.com/xuwei-k
  [@BillyAutrey]: https://github.com/BillyAutrey
  [@unkarjedy]: https://github.com/unkarjedy
  [@lihaoyi]: https://github.com/lihaoyi
  [@lrytz]: https://github.com/lrytz
  [@mrdziuban]: https://github.com/mrdziuban
  [@azdrojowa123]: https://github.com/azdrojowa123
  [@Angel98518]: https://github.com/Angel98518
  [@bitloi]: https://github.com/bitloi
  [@bohdansolovie]: https://github.com/bohdansolovie
  [@byteforge38]: https://github.com/byteforge38
  [@calm329]: https://github.com/calm329
  [@circlecrystalin]: https://github.com/circlecrystalin
  [@Dairus01]: https://github.com/Dairus01
  [@DeborahOlaboye]: https://github.com/DeborahOlaboye
  [@dive2tech]: https://github.com/dive2tech
  [@eureka928]: https://github.com/eureka928
  [@Eruis2579]: https://github.com/Eruis2579
  [@Francluob]: https://github.com/Francluob
  [@gayanMatch]: https://github.com/gayanMatch
  [@GlobalStar117]: https://github.com/GlobalStar117
  [@it-education-md]: https://github.com/it-education-md
  [@MkDev11]: https://github.com/MkDev11
  [@mohansinghi]: https://github.com/mohansinghi
  [@PandaMan]: https://github.com/PandaMan
  [@saber04414]: https://github.com/saber04414
  [@SalesforcePeak]: https://github.com/SalesforcePeak
  [@SmartDever02]: https://github.com/SmartDever02
  [@tellorian]: https://github.com/tellorian
  [@0xsatoshi99]: https://github.com/0xsatoshi99
