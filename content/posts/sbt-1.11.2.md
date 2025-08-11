---
title:       "sbt 1.11.2"
type:        story
date:        2025-06-07
url:         /sbt-1.11.2
tags:        [ "sbt" ]
---

  [@eed3si9n]: https://github.com/eed3si9n
  [@adpi2]: https://github.com/adpi2
  [@dwijnand]: https://github.com/dwijnand
  [@xuwei-k]: https://github.com/xuwei-k
  [@mkurz]: https://github.com/mkurz
  [@mrdziuban]: https://github.com/mrdziuban
  [@rtyley]: https://github.com/rtyley

Hi everyone. On behalf of the sbt project, I'm happy to announce that sbt 1.11.2 patch release is available. Full release note is here - https://github.com/sbt/sbt/releases/tag/v1.11.2

See [1.11.0 release note](/sbt-1.11.0) for the details on 1.11.x features.

<!--more-->

### How to upgrade

The sbt version used for your build must be upgraded by putting the following in `project/build.properties`:

```bash
sbt.version=1.11.2
```

This mechanism allows that sbt 1.11.2 is used only for the builds that you want.

Download **the official sbt runner** from SDKMAN, or download from <https://github.com/sbt/sbt/releases/tag/v1.11.2> to upgrade the `sbt` shell script and the launcher.

### Changes with compatibility implications

* Adds `Resolver.sonatypeCentralSnapshots`, `Resolver.sonatypeCentralRepo(...)` and deprecates `Resolver.sonatypeOssRepos(...)`, `Opts.resolver.sonatypeOssReleases `, `Opts.resolver.sonatypeOssSnapshots`, etc by [@eed3si9n][@eed3si9n] in [lm#517](https://github.com/sbt/librarymanagement/pull/517) / [#8156](https://github.com/sbt/sbt/pull/8156)

### Bug fixes and updates

* fix: Fixes intermittent `NullPointerError` in `update` task introduced in sbt 1.11.1 by reverting the use of `WeakReference`s by [@mrdziuban][@mrdziuban] in [sbt-coursier#564](https://github.com/coursier/sbt-coursier/pull/564)

### Happy Pride

In honor of sapphic, gay, bi, trans, non-binary, and queer contributors and members of Scala community <https://www.scala-sbt.org/> will be flying Progress Flag during this month:

![progress flag](/images/sbt-progress.png)

### Participation

Thanks to everyone who's helped improve sbt and Zinc by using them, reporting bugs, improving our documentation, porting builds, porting plugins, and submitting and reviewing pull requests.

For anyone interested in helping sbt, there are many avenues for you to help, depending on your interest. If you're interested, [Contributing](https://github.com/sbt/sbt/blob/develop/CONTRIBUTING.md), ["help wanted"](https://github.com/sbt/sbt/issues?q=is%3Aissue+is%3Aopen+label%3A%22help+wanted%22), ["good first issue"](https://github.com/sbt/sbt/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22), and [Discussions](https://github.com/sbt/sbt/discussions/) are good starting points.

----

### Donate to Scala Center

Scala Center is a non-profit center at EPFL to support education and open source.

- [The Scala Center Fundraising Campaign](https://scala-lang.org/blog/2023/09/11/scala-center-fundraising.html)
