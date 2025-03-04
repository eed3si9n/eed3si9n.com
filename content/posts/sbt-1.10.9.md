---
title:       "sbt 1.10.9"
type:        story
date:        2025-03-03
url:         /sbt-1.10.9
tags:        [ "sbt" ]
---

  [@eed3si9n]: https://github.com/eed3si9n
  [@adpi2]: https://github.com/adpi2
  [@xuwei-k]: https://github.com/xuwei-k
  [@Friendseeker]: https://github.com/Friendseeker
  [@unkarjedy]: https://github.com/unkarjedy
  [@jsoref]: https://github.com/jsoref
  [@mkurz]: https://github.com/mkurz
  [@rochala]: https://github.com/rochala
  [@dwickern]: https://github.com/dwickern
  [@mehdignu]: https://github.com/mehdignu

Hi everyone. On behalf of the sbt project, I'm happy to announce that sbt 1.10.9 patch release is available. Full release note is here - https://github.com/sbt/sbt/releases/tag/v1.10.9.

- There's now [**sbt 1.10.10**](/sbt-1.10.10)
- sbt 1.10.8 is skipped since we found a bug post-release

See [1.10.0 release note](/sbt-1.10.0) for the details on 1.10.x features.

### Highlights

- Adds `allowUnsafeScalaLibUpgrade` setting
- Zinc bug fix to improve local source dependency invalidation
- sbtn client-side run capability (not enabled in sbt 1.x)

<!--more-->

### How to upgrade

The sbt version used for your build must be upgraded by putting the following in `project/build.properties`:

```bash
sbt.version=1.10.9
```

This mechanism allows that sbt 1.10.9 is used only for the builds that you want.

Download **the official sbt runner** from SDKMAN, or download from <https://github.com/sbt/sbt/releases/tag/v1.10.9> to upgrade the `sbt` shell script and the launcher.

### allowUnsafeScalaLibUpgrade setting

sbt 1.10.9 adds a new `allowUnsafeScalaLibUpgrade` setting to opt out of the Scala 2.13 Evolution ([SIP-51](https://docs.scala-lang.org/sips/drop-stdlib-forwards-bin-compat.html)) check.

Starting sbt 1.10.0, sbt started enforcing that a Scala 2.13.x patch version in `scalaVersion` must be newer than the scala-library found in the dependency graph. `allowUnsafeScalaLibUpgrade` allows you to opt out of this check.

```scala
allowUnsafeScalaLibUpgrade := true
```

This change was contributed by Lukas Rytz in [#8012](https://github.com/sbt/sbt/pull/8012).

### sbtn update

sbt 1.10.9 ships with an update to sbtn that enables client-side jobs. This feature will be used by sbt 2.x. See [sudori part 7: client-side run with sbt](/sudori-part7-client-side-run-with-sbt/).

### Other bug fixes and updates

* fix: Fixes local source dependency invalidation by [@rochala][@rochala] in [zinc#1528](https://github.com/sbt/zinc/pull/1528)
* BSP: Implements `jvmBuildTarget` for `workspace/buildTargets` by [@Friendseeker][@Friendseeker] in [#7913](https://github.com/sbt/sbt/pull/7913)
* Detects user-specific JDK installations on macOS by [@unkarjedy][@unkarjedy] in [#8032](https://github.com/sbt/sbt/pull/8032)
* Makes timing outputs consistently show hours and hint at time format by [@jsoref][@jsoref] in [#8019](https://github.com/sbt/sbt/pull/8019)
* Backports SHA-256, SHA-384, and SHA-512 checksum support to forked Apache Ivy by [@mkurz][@mkurz] in [ivy#49](https://github.com/sbt/ivy/pull/49)
* fix: Clear Zinc Analysis Cache during `Compile / clean`, `Test / clean` by [@Friendseeker][@Friendseeker] in [#7969](https://github.com/sbt/sbt/pull/7969)
* fix: Fixes spurious upstream compilation when calling `previousCompile` by [@Friendseeker][@Friendseeker] in [#7983](https://github.com/sbt/sbt/pull/7983)
* fix: Fixes race condition in NetworkChannel by [@dwickern][@dwickern] in [#8005](https://github.com/sbt/sbt/pull/8005)
* fix: Fixes Chrome tracing file by [@eed3si9n] in [#8020](https://github.com/sbt/sbt/pull/8020)
* fix: Fixes incorrect sbt architecture logging in the runner script by [@mehdignu][@mehdignu] in [#8038](https://github.com/sbt/sbt/pull/8038)
* fix: Fixes stdout freshness issue by [@eed3si9n] in [#8048](https://github.com/sbt/sbt/pull/8048)
* fix: Fixes `sbt init` by [@eed3si9n] in [#8049](https://github.com/sbt/sbt/pull/8049)

### Participation

sbt 1.10.9 was brought to you by 15 contributors and one good bot. Eugene Yokota (eed3si9n), Jiahui "Jerry" Tan (Friendseeker), Scala Steward, Yongshun Shreck Ye, Jędrzej Rochala, Derek Wickern, Dmitrii Naumenko, Jaikiran Pai, Josh Soref, Kenji Yoshida (xuwei-k), Lukas Rytz, Matthias Kurz, Michał Pawlik, Seth Tisue, Timothy John Perisho Eccleston, mehdi. Thanks!

Thanks to everyone who's helped improve sbt and Zinc by using them, reporting bugs, improving our documentation, porting builds, porting plugins, and submitting and reviewing pull requests.

For anyone interested in helping sbt, there are many avenues for you to help, depending on your interest. If you're interested, [Contributing](https://github.com/sbt/sbt/blob/develop/CONTRIBUTING.md), ["help wanted"](https://github.com/sbt/sbt/issues?q=is%3Aissue+is%3Aopen+label%3A%22help+wanted%22), ["good first issue"](https://github.com/sbt/sbt/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22), and [Discussions](https://github.com/sbt/sbt/discussions/) are good starting points.

----

### Donate to Scala Center

Scala Center is a non-profit center at EPFL to support education and open source.

- [The Scala Center Fundraising Campaign](https://scala-lang.org/blog/2023/09/11/scala-center-fundraising.html)
