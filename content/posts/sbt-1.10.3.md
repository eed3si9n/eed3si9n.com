---
title:       "sbt 1.10.3"
type:        story
date:        2024-10-19
url:         /sbt-1.10.3
tags:        [ "sbt" ]
---

  [@eed3si9n]: https://github.com/eed3si9n
  [@adpi2]: https://github.com/adpi2
  [@xuwei-k]: https://github.com/xuwei-k
  [@Friendseeker]: https://github.com/Friendseeker
  [@gabrieljones]: https://github.com/gabrieljones
  [@smarter]: https://github.com/smarter
  [@Ichoran]: https://github.com/Ichoran
  [@SethTisue]: https://github.com/SethTisue
  [GHSA-735f-pc8j-v9w8]: https://github.com/advisories/GHSA-735f-pc8j-v9w8

Hi everyone. On behalf of the sbt project, I'm happy to announce that sbt 1.10.3 patch release is available. Full release note is here - https://github.com/sbt/sbt/releases/tag/v1.10.3

See [1.10.0 release note](/sbt-1.10.0) for the details on 1.10.x features.

### Highlights

- [CVE-2024-7254][GHSA-735f-pc8j-v9w8]. sbt 1.10.3 updates protobuf-java library to 3.25.5 to address reported potential Denial of Service
- Updates metabuild Scala version to 2.12.20
- Fixes for the spurious "illegal reflective access operation" error on JDK 11
- Reverting the invalidation of circular-dependent sources

<!--more-->

### How to upgrade

The sbt version used for your build must be upgraded by putting the following in `project/build.properties`:

```bash
sbt.version=1.10.3
```

This mechanism allows that sbt 1.10.3 is used only for the builds that you want.

Download **the official sbt runner** from SDKMAN, or download from <https://github.com/sbt/sbt/releases/tag/v1.10.3> to upgrade the `sbt` shell script and the launcher.

## Protobuf with potential Denial of Service (CVE-2024-7254)

sbt 1.10.3 updates protobuf-java library to 3.25.5 to address CVE-2024-7254 / [GHSA-735f-pc8j-v9w8][GHSA-735f-pc8j-v9w8], which states that while parsing unknown fields in the Protobuf Java library, a maliciously crafted message can cause a StackOverflow error. Given the nature of how Protobuf is used in Zinc as internal serialization, we think the impact of this issue is minimum. However, security software might still flag this to be an issue while using sbt or Zinc, so upgrade is advised. This issue was originally reported by [@gabrieljones][@gabrieljones] and was fixed by Jerry Tan ([@Friendseeker][@Friendseeker]) in [zinc#1443](https://github.com/sbt/zinc/pull/1443).

[@adpi2][@adpi2] at Scala Center has also configured dependency graph submission to get security alerts in [zinc#1448](https://github.com/sbt/zinc/pull/1448).

## Reverting the invalidation of circular-dependent sources

sbt 1.10.3 reverts the initial invalidation of circular-dependent Scala source pairs.

There had been a series of incremental compiler bugs such as "Invalid superClass" and "value b is not a member of A" that would go away after `clean`. The root cause of these bugs were identified by [@smarter][@smarter] [zinc#598](https://github.com/sbt/zinc/issues/598#issuecomment-449028234) and [@Friendseeker][@Friendseeker] to be partial compilation of circular-dependent sources where two sources `A.scala` and `B.scala` use some constructs from each other.

sbt 1.10.0 fixed this issue via [zinc#1284](https://github.com/sbt/zinc/pull/1284) by invalidating the circular-dependent pairs together. In other words, if `A.scala` was changed, it would immediately invalidate `B.scala`. It turns out, that people have been writing circular-dependent code, and this has resulted in multiple reports of Zinc's over-compilation ([zinc#1420](https://github.com/sbt/zinc/issues/1420), [zinc#1461](https://github.com/sbt/zinc/issues/1461)). Given that the invalidation seems to affect the users more frequently than the original bug, we're going to revert the fix for now. We might bring this back with an opt-out flag later on. The revert was contributed by by Li Haoyi in [zinc#1462](https://github.com/sbt/zinc/pull/1462).

## Improvement: ParallelGzipOutputStream

sbt 1.10.0 via [zinc#1326](https://github.com/sbt/zinc/pull/1326) added a new consistent (repeatable) formats for Analysis storage. As a minor optimization, the pull request also included an implementation of `ParallelGzipOutputStream`, which would reduce the generate file size by 20%, but with little time penalty. Unfortunately, however, we have observed in CI that that the `scala.concurrent.Future`-based implementation gets stuck in a deadlock. [@Ichoran][@Ichoran] and [@Friendseeker][@Friendseeker] have contributed an alternative implementation that uses Java threads directly, which fixes the issue in [zinc#1466](https://github.com/sbt/zinc/pull/1466).

### Bug fixes and updates

* deps: Updates metabuild Scala version to 2.12.20 by [@SethTisue][@SethTisue] in [#7636](https://github.com/sbt/sbt/pull/7636)
* fix: Fixes spurious "illegal reflective access operation" error on JDK 11 by updating JLine to 3.27.0 by [@Friendseeker][@Friendseeker] in [#7695](https://github.com/sbt/sbt/pull/7695)
* fix: Fixes transitive invalidation interfering with cycle stopping condition by [@Friendseeker][@Friendseeker] in [zinc#1397](https://github.com/sbt/zinc/pull/1397)
* fix: Fixes dependency resolution of sbt plugins by excluding custom extra attributes from POM dependencies by [@adpi2][@adpi2] in [lm#451](https://github.com/sbt/librarymanagement/pull/451)
* fix: Fixes directory permission issue under a multi-user environment by [@eed3si9n][@eed3si9n] [ipcsocket#43](https://github.com/sbt/ipcsocket/pull/43)
* deps: Updates `sbt init` template deps by [@xuwei-k][@xuwei-k] in [#7730](https://github.com/sbt/sbt/pull/7730)
* Updates sbt runner to default to sbtn for sbt 2.x by [@eed3si9n][@eed3si9n] in [#7775](https://github.com/sbt/sbt/pull/7775)

### Participation

sbt 1.10.3 was brought to you by eight contributors and one good bot. Jerry Tan (Friendseeker), Eugene Yokota (eed3si9n), Kenji Yoshida (xuwei-k), Scala Steward, Adrien Piquerez, Ichoran, Li Haoyi, Seth Tisue, and nathanlao. Thanks!

Thanks to everyone who's helped improve sbt and Zinc by using them, reporting bugs, improving our documentation, porting builds, porting plugins, and submitting and reviewing pull requests.

For anyone interested in helping sbt, there are many avenues for you to help, depending on your interest. If you're interested, [Contributing](https://github.com/sbt/sbt/blob/develop/CONTRIBUTING.md), ["help wanted"](https://github.com/sbt/sbt/issues?q=is%3Aissue+is%3Aopen+label%3A%22help+wanted%22), ["good first issue"](https://github.com/sbt/sbt/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22), and [Discussions](https://github.com/sbt/sbt/discussions/) are good starting points.

----

### Donate to Scala Center

Scala Center is a non-profit center at EPFL to support education and open source.

- [The Scala Center Fundraising Campaign](https://scala-lang.org/blog/2023/09/11/scala-center-fundraising.html)
