---
title:       "sbt 1.9.9"
type:        story
date:        2024-02-23
url:         /sbt-1.9.9
tags:        [ "sbt" ]
---

  [@eed3si9n]: https://github.com/eed3si9n
  [@adpi2]: https://github.com/adpi2
  [@xuwei-k]: https://github.com/xuwei-k
  [@mdedetrich]: https://github.com/mdedetrich
  [@mkurz]: https://github.com/mkurz
  [@hvesalai]: https://github.com/hvesalai
  [7502]: https://github.com/sbt/sbt/issues/7502
  [7503]: https://github.com/sbt/sbt/pull/7503
  [io367]: https://github.com/sbt/io/pull/367

Hi everyone. On behalf of the sbt project, I'm happy to announce sbt 1.9.9, a Scala 2.13.13 commemorative patch release. Full release note is here - https://github.com/sbt/sbt/releases/tag/v1.9.9

See [1.9.0 release note](/sbt-1.9.0) for the details on 1.9.x features.

### Highlights

- To fix `console` task on Scala 2.13.13, sbt 1.9.9 backports updates to JLine 3.24.1 and JAnsi 2.4.0 by [@hvesalai][@hvesalai] in [#7503][7503] / [#7502][7502]
- To fix sbt 1.9.8's `UnsatisfiedLinkError` with `stat`, sbt 1.9.9 removes native code that was used to get the millisecond-precision timestamp that was broken ([JDK-8177809](https://bugs.openjdk.org/browse/JDK-8177809)) on JDK 8 prior to [OpenJDK 8u302](https://mail.openjdk.org/pipermail/jdk8u-dev/2021-July/014118.html)  by [@eed3si9n][@eed3si9n] in [io#367][io367]

<!--more-->

### How to upgrade

The sbt version used for your build must be upgraded by putting the following in `project/build.properties`:

```bash
sbt.version=1.9.9
```

This mechanism allows that sbt 1.9.9 is used only for the builds that you want.

Download **the official sbt runner** from, `cs setup`, SDKMAN, or download from <https://github.com/sbt/sbt/releases/tag/v1.9.9> to upgrade the `sbt` shell script and the launcher.

### Participation

sbt 1.9.9 was brought to you by four contributors. Kenji Yoshida (xuwei-k), Eugene Yokota (eed3si9n), Heikki Vesalainen, and Jerry Tan
 (friendseeker). Thanks!

Thanks to everyone who's helped improve sbt and Zinc by using them, reporting bugs, improving our documentation, porting builds, porting plugins, and submitting and reviewing pull requests.

For anyone interested in helping sbt, there are many avenues for you to help, depending on your interest. If you're interested, [Contributing](https://github.com/sbt/sbt/blob/develop/CONTRIBUTING.md), ["help wanted"](https://github.com/sbt/sbt/issues?q=is%3Aissue+is%3Aopen+label%3A%22help+wanted%22), ["good first issue"](https://github.com/sbt/sbt/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22), and [Discussions](https://github.com/sbt/sbt/discussions/) are good starting points.

----

### Donate to Scala Center

Scala Center is a non-profit center at EPFL to support education and open source.

- [The Scala Center Fundraising Campaign](https://scala-lang.org/blog/2023/09/11/scala-center-fundraising.html)
