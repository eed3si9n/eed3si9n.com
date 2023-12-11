---
title: "sbt 1.10.0-M1"
type: story
date: 2023-12-07
url: /sbt-1.10.0-beta
tags: [ "sbt" ]
---

Hi everyone. On behalf of the sbt project, I am happy to announce sbt 1.10.0-M1. This is the tenth feature release of sbt 1.x, a binary compatible release focusing on new features. sbt 1.x is released under Semantic Versioning, and the plugins are expected to work throughout the 1.x series. Please try it out, and report any issues you might come across.

The headline features of sbt 1.10.0 are:

- Zinc fixes
- CommandProgress API

<!--more-->

### How to upgrade

The sbt version used for your build is upgraded by putting the following in `project/build.properties`:

```bash
sbt.version=1.10.0-M1
```

This mechanism allows that sbt 1.10.0-M1 is used only for the builds that you want.

### Zinc fixes

* Fixes IncOptions.useOptimizedSealed not working for Scala 2.13 by @Friendseeker in [zinc#1278][zinc1278]
* Includes extra invalidations in initial validation to fix initial compilation error by @Friendseeker in [zinc#1284][zinc1284]
* Refixes compact names w/o breaking local names by @dwijnand in [zinc#1259][zinc1259]
* Undoes Protobuf workaround for build to work on Apple Silicon by @Friendseeker in [zinc#1277][zinc1277]
* Uses `ClassTag` instead of `Manifest` by @xuwei-k in [zinc#1265][zinc1265]
* Encodes parent trait private members in `extraHash` to propagate `TraitPrivateMembersModified` across external dependency by @Friendseeker in [zinc#1289][zinc1289]
* Includes internal dependency in `extraHash` computation by @Friendseeker in [zinc#1290][zinc1290]
* Invalidates macro source when its dependency changes by @dwijnand in [zinc#1282][zinc1282]
* Deletes products of previous analysis when dropping previous analysis by @Friendseeker in [zinc#1293][zinc1293]
* Uses the most up-to-date analysis for binary to source class name lookup by @Friendseeker in [zinc#1287][zinc1287]

### New CommandProgress API

sbt 1.10.0 adds a new CommandProgress API.

This was contributed by @dragos in https://github.com/sbt/sbt/pull/7350

### other updates

* JLine 3.24.1 and JAnsi 2.4.0. by @hvesalai in https://github.com/sbt/sbt/pull/7419
* BSP: Implements `buildTarget/javacOptions` by @adpi2 in https://github.com/sbt/sbt/pull/7352
* Supports cross-build for external project ref by @RustedBones in https://github.com/sbt/sbt/pull/7389
* Avoids deprecated `java.net.URL` constructor by @xuwei-k in https://github.com/sbt/sbt/pull/7398
* Fixes bug of unmanagedResourceDirectories by @minkyu97 in https://github.com/sbt/sbt/pull/7178
* Fixes `updateSbtClassifiers` task by @azdrojowa123 in https://github.com/sbt/sbt/pull/7437

### Donate to Scala Center

Scala Center is a non-profit center at EPFL to support education and open source.

- <https://scala.epfl.ch/donate.html>

 [zinc1278]: https://github.com/sbt/zinc/pull/1278
 [zinc1284]: https://github.com/sbt/zinc/pull/1284
 [zinc1259]: https://github.com/sbt/zinc/pull/1259
 [zinc1277]: https://github.com/sbt/zinc/pull/1277
 [zinc1265]: https://github.com/sbt/zinc/pull/1265
 [zinc1289]: https://github.com/sbt/zinc/pull/1289
 [zinc1290]: https://github.com/sbt/zinc/pull/1290
 [zinc1282]: https://github.com/sbt/zinc/pull/1282
 [zinc1293]: https://github.com/sbt/zinc/pull/1293
 [zinc1287]: https://github.com/sbt/zinc/pull/1287
