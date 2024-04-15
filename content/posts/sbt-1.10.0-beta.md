---
title: "sbt 1.10.0-RC2"
type: story
date: 2024-04-15
url: /sbt-1.10.0-beta
tags: [ "sbt" ]
---

  [@eed3si9n]: https://github.com/eed3si9n
  [@adpi2]: https://github.com/adpi2
  [@dwijnand]: https://github.com/dwijnand
  [@xuwei-k]: https://github.com/xuwei-k
  [@mdedetrich]: https://github.com/mdedetrich
  [@mkurz]: https://github.com/mkurz
  [@hvesalai]: https://github.com/hvesalai
  [@Friendseeker]: https://github.com/Friendseeker
  [@RustedBones]: https://github.com/RustedBones
  [@minkyu97]: https://github.com/minkyu97
  [@azdrojowa123]: https://github.com/azdrojowa123
  [@SethTisue]: https://github.com/SethTisue
  [@Tammo0987]: https://github.com/Tammo0987
  [@azolotko]: https://github.com/azolotko
  [@rtyley]: https://github.com/rtyley
  [7350]: https://github.com/sbt/sbt/pull/7350
  [7352]: https://github.com/sbt/sbt/pull/7352
  [7470]: https://github.com/sbt/sbt/pull/7470
  [7475]: https://github.com/sbt/sbt/pull/7475
  [7480]: https://github.com/sbt/sbt/pull/7480
  [7496]: https://github.com/sbt/sbt/pull/7496
  [7516]: https://github.com/sbt/sbt/pull/7516
  [7513]: https://github.com/sbt/sbt/pull/7513
  [7419]: https://github.com/sbt/sbt/pull/7419
  [7389]: https://github.com/sbt/sbt/pull/7389
  [7398]: https://github.com/sbt/sbt/pull/7398
  [7178]: https://github.com/sbt/sbt/pull/7178
  [7437]: https://github.com/sbt/sbt/pull/7437
  [sip51]: https://docs.scala-lang.org/sips/drop-stdlib-forwards-bin-compat.html
  [zinc1319]: https://github.com/sbt/zinc/pull/1319
  [zinc1316]: https://github.com/sbt/zinc/pull/1316
  [zinc1314]: https://github.com/sbt/zinc/pull/1314
  [zinc1326]: https://github.com/sbt/zinc/pull/1326
  [zinc1324]: https://github.com/sbt/zinc/pull/1324
  [zinc1312]: https://github.com/sbt/zinc/pull/1312
  [zinc1310]: https://github.com/sbt/zinc/pull/1310
  [zinc1278]: https://github.com/sbt/zinc/pull/1278
  [zinc1284]: https://github.com/sbt/zinc/pull/1284
  [zinc1259]: https://github.com/sbt/zinc/pull/1259
  [zinc1277]: https://github.com/sbt/zinc/pull/1277
  [zinc1265]: https://github.com/sbt/zinc/pull/1265
  [zinc1289]: https://github.com/sbt/zinc/pull/1289
  [zinc1290]: https://github.com/sbt/zinc/pull/1290
  [zinc1282]: https://github.com/sbt/zinc/pull/1282
  [zinc1293]: https://github.com/sbt/zinc/pull/1293
  [zinc1288]: https://github.com/sbt/zinc/pull/1288
  [zinc1287]: https://github.com/sbt/zinc/pull/1287
  [lm436]: https://github.com/sbt/librarymanagement/pull/436
  [lm433]: https://github.com/sbt/librarymanagement/pull/433

Hi everyone. On behalf of the sbt project, I am happy to announce sbt 1.10.0-RC2. This is the tenth feature release of sbt 1.x, a binary compatible release focusing on new features. sbt 1.x is released under Semantic Versioning, and the plugins are expected to work throughout the 1.x series. Please try it out, and report any issues you might come across.

The headline features of sbt 1.10.0 are:

- [SIP-51][sip51] Support for Scala 2.13 Evolution
- A wide range of Zinc fixes contributed by Jerry Tan and others
- CommandProgress API
- ConsistentAnalysisFormat: New Zinc Analysis serialization

<!--more-->

### How to upgrade

The sbt version used for your build is upgraded by putting the following in `project/build.properties`:

```bash
sbt.version=1.10.0-RC2
```

This mechanism allows that sbt 1.10.0-RC2 is used only for the builds that you want.

### Changes since sbt 1.10.0-RC1

- ConsistentAnalysisFormat is enabled by default.
- Updates to SIP-51 error message.

### Changes with compatibility implications

- For SIP-51 support, `scalaVersion` can no longer be a lower 2.13.x version number than its transitive depdencies. See below for details.
- Updates lm-coursier-shaded to 2.1.4, which brings in Coursier 2.1.9 [#7513][7513].
- Updates Jsch to [mwiede/jsch](https://github.com/mwiede/jsch) fork by [@azolotko][@azolotko] in [lm#436][lm436]
- Updates the Scala version used by sbt 1.x to 2.12.19 by [@SethTisue][@SethTisue] in [#7516][7516].

### SIP-51 Support for Scala 2.13 Evolution

Modern Scala 2.x has kept both forward and backward binary compatibility so a library compiled using Scala 2.13.12 can be used by an application compiled with Scala 2.13.11 etc, and vice versa. The forward compatibility restricts Scala 2.x from evolving during the patch releases, so in [SIP-51][sip51] Lukas Rytz at Lightbend Scala Team proposed:

> I propose to drop the forwards binary compatibility requirement that build tools enforce on the Scala 2.13 standard library. This will allow implementing performance optimizations of collection operations that are currently not possible. It also unblocks adding new classes and new members to existing classes in the standard library.

Lukas has also contributed changes to sbt 1.10.0 to enforce stricter `scalaVersion`. Starting sbt 1.10.0, when a Scala 2.13.x patch version newer than `scalaVersion` is found, it will fail the build as follows:

```scala
sbt:foo> run
[error] stack trace is suppressed; run last scalaInstance for the full output
[error] (scalaInstance) expected `foo/scalaVersion` to be "2.13.10" or later,
[error] but found "2.13.5"; upgrade scalaVerion to fix the build.
[error]
[error] to support backwards-only binary compatibility (SIP-51),
[error] the Scala 2.13 compiler cannot be older than scala-library on the
[error] dependency classpath.
[error] see `foo/evicted` to know why scala-library 2.13.10 is getting pulled in.
```

When you see the error message like above, you can fix this by updating the Scala version to the suggested version (e.g. 2.13.10):

```scala
ThisBuild / scalaVersion := "2.13.10"
```

Side note: Old timers might know that [sbt 0.13.0](https://www.scala-sbt.org/0.13/docs/ChangeSummary_0.13.0.html#sbt+0.13.0) also introduced the idea of *scala-library as a normal dependency*. This created various confusions as developers expected `scalaVersion`, compiler version, and scala-library version as expected to align. With the hindsight, sbt 1.10.0 will continue to respect `scalaVersion` to be the source-of-truth, but will reject bad ones at build time.

This was contributed by Lukas Rytz in [#7480][7480].

### Zinc fixes

* Fixes macro undercompilation by invalidating macro call sites when a type parameter changes by [@Friendseeker][@Friendseeker] in [zinc#1316][zinc1316]
* Fixes macro undercompilation by invalidating macro source when its dependency changes by [@dwijnand][@dwijnand] in [zinc#1282][zinc1282]
* Fixes SAM type undercompilation by [@Friendseeker][@Friendseeker] in [zinc#1288][zinc1288]
* Fixes infinite incremental loop when Scala and Java are involved by [@Friendseeker][@Friendseeker] in [zinc#1312][zinc1312]
* Fixes overcompilation on default parameter changes by [@Friendseeker][@Friendseeker] in [zinc#1324][zinc1324]
* Fixes `IncOptions.useOptimizedSealed` not working for Scala 2.13 by [@Friendseeker][@Friendseeker] in [zinc#1278][zinc1278]
* Includes extra invalidations in initial validation to fix initial compilation error by [@Friendseeker][@Friendseeker] in [zinc#1284][zinc1284]
* Refixes compact names without breaking local names by [@dwijnand][@dwijnand] in [zinc#1259][zinc1259]
* Undoes Protobuf workaround for build to work on Apple Silicon by [@Friendseeker][@Friendseeker] in [zinc#1277][zinc1277]
* Uses `ClassTag` instead of `Manifest` by [@xuwei-k][@xuwei-k] in [zinc#1265][zinc1265]
* Encodes parent trait private members in `extraHash` to propagate `TraitPrivateMembersModified` across external dependency by [@Friendseeker][@Friendseeker] in [zinc#1289][zinc1289]
* Includes internal dependency in `extraHash` computation by [@Friendseeker][@Friendseeker] in [zinc#1290][zinc1290]
* Deletes products of previous analysis when dropping previous analysis by [@Friendseeker][@Friendseeker] in [zinc#1293][zinc1293]
* Uses the most up-to-date analysis for binary to source class name lookup by [@Friendseeker][@Friendseeker] in [zinc#1287][zinc1287]
* Fixes inconsistent Analysis by removing source stamp caching by [@Friendseeker][@Friendseeker] in [zinc#1319][zinc1319]
* Invalidate sources that depends on `@inline` methods in Scala 2.x by [@Friendseeker][@Friendseeker] in [zinc#1310][zinc1310]
* Fixes `-Xshow-phases` handling by [@Friendseeker][@Friendseeker] in [zinc#1314][zinc1314]

### ConsistentAnalysisFormat: new Zinc Analysis serialization

sbt 1.10.0 adds a new Zinc serialization format that is faster and repeatable, unlike the current Protobuf-based serialization. Benchmark data based on scala-library + reflect + compiler:

|                             | Write time | Read time | File size |
|-----------------------------|------------|-----------|-----------|
| sbt Text                    |    1002 ms |    791 ms |   ~ 7102 kB |
| sbt Binary                  |     654 ms |    277 ms |   ~ 6182 kB |
| ConsistentBinary            |     157 ms |    100 ms |   3097 kB |

Since Zinc Analysis is internal to sbt, sbt 1.10.0 will enable this format by default. The following setting can be used to opt-out:

```scala
Global / enableConsistentCompileAnalysis := false
```

This was contributed by Stefan Zeiger at Databricks in [zinc#1326][zinc1326].

### New CommandProgress API

sbt 1.10.0 adds a new CommandProgress API.

This was contributed by Iulian Dragos at Gradle Inc in [#7350][7350].

### Other updates

* JLine 3.24.1 and JAnsi 2.4.0 by [@hvesalai][@hvesalai] in [#7419][7419]
* Supports cross-build for external project ref by [@RustedBones][@RustedBones] in [#7389][7389]
* Avoids deprecated `java.net.URL` constructor by [@xuwei-k][@xuwei-k] in [#7398][7398]
* Fixes bug of unmanagedResourceDirectories by [@minkyu97][@minkyu97] in [#7178][7178]
* Fixes `updateSbtClassifiers` task by [@azdrojowa123][@azdrojowa123] in [#7437][7437]
* Fixes `packageSrc` to include `managedSources` by [@Friendseeker][@Friendseeker] in [#7470][7470]
* Fixes publishing to use the publisher specified using the `publisher` setting by [@Tammo0987][@Tammo0987] in [#7475][7475]
* Fixes eviction warning message by avoid repeating versions by [@rtyley][@rtyley] in [lm#433][lm433]
* BSP: Implements `buildTarget/javacOptions` by [@adpi2][@adpi2] in [#7352][7352]
* BSP: Adds `noOp` field in the compile report by [@adpi2][@adpi2] in [#7496][7496]

### Participation

sbt 1.10.0-RC2 was brought to you by 23 contributors and two good bots: Jerry Tan (friendseeker), Scala Steward, Eugene Yokota (eed3si9n), Kenji Yoshida (xuwei-k), Lukas Rytz, Adrien Piquerez, Iulian Dragos, Dale Wijnand, Domantas Petrauskas, dependabot[bot], Martin Duhem, Heikki Vesalainen, Aleksandra Zdrojowa, Matthias Kurz, Regis Kuckaertz, Seth Tisue, Stefan Zeiger, Alex Zolotko, Hagai Ovadia, Jakub Kozłowski, Michel Davit, Minkyu Lee, Philippus Baalman, Roberto Tyley, Tammo Steffens. Thanks!

Thanks to everyone who's helped improve sbt and Zinc by using them, reporting bugs, improving our documentation, porting builds, porting plugins, and submitting and reviewing pull requests.

For anyone interested in helping sbt, there are many avenues for you to help, depending on your interest. If you're interested, [Contributing](https://github.com/sbt/sbt/blob/develop/CONTRIBUTING.md), ["help wanted"](https://github.com/sbt/sbt/issues?q=is%3Aissue+is%3Aopen+label%3A%22help+wanted%22), ["good first issue"](https://github.com/sbt/sbt/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22), and [Discussions](https://github.com/sbt/sbt/discussions/) are good starting points.

----

### Donate to Scala Center

Scala Center is a non-profit center at EPFL to support education and open source. Please consider [donating](https://scala.epfl.ch/donate.html) to them, and publicly tweet/toot at @eed3si9n and @scala_lang when you do (I don't work for them, but we maintain sbt together).
