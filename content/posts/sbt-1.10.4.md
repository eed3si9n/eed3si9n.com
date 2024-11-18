---
title:       "sbt 1.10.4"
type:        story
date:        2024-10-28
url:         /sbt-1.10.4
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

Hi everyone. On behalf of the sbt project, I'm happy to announce that sbt 1.10.4 patch release is available. Full release note is here - https://github.com/sbt/sbt/releases/tag/v1.10.4

See [1.10.0 release note](/sbt-1.10.0) for the details on 1.10.x features.

sbt 1.10.4 contains mostly minor bug fixes.

<!--more-->

### How to upgrade

The sbt version used for your build must be upgraded by putting the following in `project/build.properties`:

```bash
sbt.version=1.10.4
```

This mechanism allows that sbt 1.10.4 is used only for the builds that you want.

Download **the official sbt runner** from SDKMAN, or download from <https://github.com/sbt/sbt/releases/tag/v1.10.4> to upgrade the `sbt` shell script and the launcher.

### Bug fixes and updates

* fix: Change the default analysis format to older binary, and make Consistent Analysis opt-in by [@Friendseeker][@Friendseeker] in [#7807](https://github.com/sbt/sbt/pull/7807)
* fix: Fixes Jansi deprecation notice by switching to jline-terminal-jni by [@Friendseeker][@Friendseeker] in [#7811](https://github.com/sbt/sbt/pull/7811)
* fix: Fixes GLIBC_2.32 issue on sbtn by statically linking musl by [@Friendseeker][@Friendseeker] in [#7823](https://github.com/sbt/sbt/pull/7823)
* fix: Throw exception when `sbt new` fails to find template by [@Friendseeker][@Friendseeker] in [#7835](https://github.com/sbt/sbt/pull/7835)
* fix: Fixes `~` with `Global / onChangedBuildSource := ReloadOnSourceChanges` by [@Friendseeker][@Friendseeker] in [#7838](https://github.com/sbt/sbt/pull/7838)
* fix: Fixes "Unrecognized option: --server" error on BSP server by [@eed3si9n][@eed3si9n] in [#7824](https://github.com/sbt/sbt/pull/7824)
* fix: Fixes pipelined build while changing version frequently by [@Friendseeker][@Friendseeker] in [#7830](https://github.com/sbt/sbt/pull/7830)

### Participation

sbt 1.10.4 was brought to you by three contributors and one good bot. Jerry Tan (Friendseeker), Eugene Yokota (eed3si9n), philippus, Scala Steward. Thanks!

Thanks to everyone who's helped improve sbt and Zinc by using them, reporting bugs, improving our documentation, porting builds, porting plugins, and submitting and reviewing pull requests.

For anyone interested in helping sbt, there are many avenues for you to help, depending on your interest. If you're interested, [Contributing](https://github.com/sbt/sbt/blob/develop/CONTRIBUTING.md), ["help wanted"](https://github.com/sbt/sbt/issues?q=is%3Aissue+is%3Aopen+label%3A%22help+wanted%22), ["good first issue"](https://github.com/sbt/sbt/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22), and [Discussions](https://github.com/sbt/sbt/discussions/) are good starting points.

----

### Donate to Scala Center

Scala Center is a non-profit center at EPFL to support education and open source.

- [The Scala Center Fundraising Campaign](https://scala-lang.org/blog/2023/09/11/scala-center-fundraising.html)
