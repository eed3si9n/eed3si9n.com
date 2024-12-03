---
title:       "sbt 1.10.6"
type:        story
date:        2024-11-30
url:         /sbt-1.10.6
tags:        [ "sbt" ]
---

  [@eed3si9n]: https://github.com/eed3si9n
  [@adpi2]: https://github.com/adpi2
  [@xuwei-k]: https://github.com/xuwei-k
  [@Friendseeker]: https://github.com/Friendseeker
  [@dwijnand]: https://github.com/dwijnand
  [@Androz2091]: https://github.com/Androz2091

Hi everyone. On behalf of the sbt project, I'm happy to announce that sbt 1.10.6 patch release is available. Full release note is here - https://github.com/sbt/sbt/releases/tag/v1.10.6

See [1.10.0 release note](/sbt-1.10.0) for the details on 1.10.x features.

### Highlights

- Updates to Coursier 2.1.19 via lm-coursier 2.1.6
- Fix to Ctrl-C (cancelling)

<!--more-->

### How to upgrade

The sbt version used for your build must be upgraded by putting the following in `project/build.properties`:

```bash
sbt.version=1.10.6
```

This mechanism allows that sbt 1.10.6 is used only for the builds that you want.

Download **the official sbt runner** from SDKMAN, or download from <https://github.com/sbt/sbt/releases/tag/v1.10.6> to upgrade the `sbt` shell script and the launcher.

### Coursier 2.1.19 and lm-coursier 2.1.6

sbt 1.10.6 updates the library management engine to lm-coursier 2.1.6, which uses Coursier 2.1.19. This includes Maven BOM (bill of materials) related changes that was contributed by Alexandre Archambault. Coursier 2.1.17 release note states

> This release changes the way "BOMs" or "dependency management" are handled during resolution, and allows users to add BOMs to a resolution. This changes the way versions are picked when BOMs or dependency management are involved, which has an impact on the resolution of libraries from many JVM ecosystems, such as Apache Spark, Springboot, Quarkus, etc.


### Fix to Ctrl-C (cancelling)

Since [2017](https://github.com/sbt/sbt/pull/3477) `run` task has delegated the functionality to `bgRun` mechanism. This has caused Ctrl-C cancellation to not take effect for `run`. sbt 1.10.6 fixes the bug by forwarding the cancellation to background runs started by `run`. This fix was contributed by Jerry Tan ([@Friendseeker][@Friendseeker]) in [#7916](https://github.com/sbt/sbt/pull/7916).

### Other bug fixes and updates

* fix: Fixes `sbt --client` support on openSUSE by [@Androz2091][@Androz2091] in [#7895](https://github.com/sbt/sbt/pull/7895)
* fix: Synchronizes `dependencyTree` console output by [@Friendseeker][@Friendseeker] in [#7906](https://github.com/sbt/sbt/pull/7906)
* fix: Synchronizes `java.awt.Desktop.browse()` during `dependencyBrowseTree` by [@Friendseeker][@Friendseeker] in [#7905](https://github.com/sbt/sbt/pull/7905)
* perf: Better memory efficiency for Zinc Analysis by [@dwijnand][@dwijnand] in [zinc#1494](https://github.com/sbt/zinc/pull/1494)
* fix: Passes `useConsistent` to `staticCachedStore` by [@Friendseeker][@Friendseeker] in [#7869](https://github.com/sbt/sbt/pull/7869)
* Make reproducibility toggleable for `ConsistentAnalysisFormat` by [@Friendseeker][@Friendseeker] in [zinc#1479](https://github.com/sbt/zinc/pull/1479)
* `clean` clears `previousCompile` by [@Friendseeker][@Friendseeker] in [#1487](https://github.com/sbt/zinc/pull/1487) / [#7922](https://github.com/sbt/sbt/pull/7922)

### Participation

Thanks to everyone who's helped improve sbt and Zinc by using them, reporting bugs, improving our documentation, porting builds, porting plugins, and submitting and reviewing pull requests.

For anyone interested in helping sbt, there are many avenues for you to help, depending on your interest. If you're interested, [Contributing](https://github.com/sbt/sbt/blob/develop/CONTRIBUTING.md), ["help wanted"](https://github.com/sbt/sbt/issues?q=is%3Aissue+is%3Aopen+label%3A%22help+wanted%22), ["good first issue"](https://github.com/sbt/sbt/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22), and [Discussions](https://github.com/sbt/sbt/discussions/) are good starting points.

----

### Donate to Scala Center

Scala Center is a non-profit center at EPFL to support education and open source.

- [The Scala Center Fundraising Campaign](https://scala-lang.org/blog/2023/09/11/scala-center-fundraising.html)
