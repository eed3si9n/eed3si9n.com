---
title: "sbt 1.12.1"
type: story
date: 2026-01-26
url: /sbt-1.12.1
tags: [ "sbt" ]
---

Hi everyone. On behalf of the sbt project, I am happy to announce sbt 1.12.1. This is the twelfth feature release of sbt 1.x, a binary compatible release focusing on new features. sbt 1.x is released under Semantic Versioning, and the plugins are expected to work throughout the 1.x series. Please try it out, and report any issues you might come across.

The headline feature of sbt 1.12.1 is:

- scala-reflect not found problem on Scala 3.8.1

Full release note is here - <https://github.com/sbt/sbt/releases/tag/v1.12.1>

<!--more-->

### How to upgrade

The sbt version used for your build is upgraded by putting the following in `project/build.properties`:

```bash
sbt.version=1.12.1
```

This mechanism allows that sbt 1.12.1 is used only for the builds that you want.

Download **the official sbt runner** from SDKMAN, or download from <https://github.com/sbt/sbt/releases/tag/v1.12.1> to upgrade the `sbt` shell script and the launcher.

### scala-reflect not found problem

Using a mechanism so-called Scala 2.13-3.x sandwich, we can construct dependency graph that depends on 3.x from 2.13. On Scala 2.13, we also have a same-version policy, which enforces the scala-library and scala-reflect vesion to be the same. The same-version policy no longer holds when 3.8.1 is depended from 2.13.x, because this bumps scala-library version to 3.8.1, however scala-reflect 3.8.1 does not exist.

To workaround this issue, sbt 1.12.1 drops the same-version constraint for 2.13.x. This was contributed by [@eed3si9n][@eed3si9n] in [#8633](https://github.com/sbt/sbt/pull/8633).

### Other changes

* fix: Invalidates `update` cache across commands when dependencies change by [@calm329][@calm329] in [#8593](https://github.com/sbt/sbt/pull/8593)
* fix: Fixes missing `project` directory on `--addPluginSbtFile` command by [@azdrojowa123][@azdrojowa123] in [#8583](https://github.com/sbt/sbt/pull/8583)
* fix: Fixes `sbt --client new` combination by [@MkDev11][@MkDev11] in [#8512](https://github.com/sbt/sbt/pull/8512)
* fix: Fixes `sbt new` argument parsing on Windows by [@MkDev11][@MkDev11] in [#8509](https://github.com/sbt/sbt/pull/8509)
* fix: Fixes sbtopts files priority in sbt runner script by [@mohansinghi][@mohansinghi] in [#8520](https://github.com/sbt/sbt/pull/8520)
* fix: Fixes `-X` support on Windows batch runner by [@GlobalStar117][@GlobalStar117] in [#8566](https://github.com/sbt/sbt/pull/8566)

### Participation

sbt 1.12.1 was brought to you by 6 contributors and two good bots: Eugene Yokota (eed3si9n), MkDev11, calm329, E.G, SID, and Aleksandra Zdrojowa. Thanks!

Thanks to everyone who's helped improve sbt and Zinc by using them, reporting bugs, improving our documentation, porting builds, porting plugins, and submitting and reviewing pull requests.

For anyone interested in helping sbt, there are many avenues for you to help, depending on your interest. If you're interested, [Contributing](https://github.com/sbt/sbt/blob/develop/CONTRIBUTING.md), ["help wanted"](https://github.com/sbt/sbt/issues?q=is%3Aissue+is%3Aopen+label%3A%22help+wanted%22), ["good first issue"](https://github.com/sbt/sbt/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22), and [Discussions](https://github.com/sbt/sbt/discussions/) are good starting points.

----

### Donate to Scala Center

Scala Center is a non-profit center at EPFL to support education and open source.

- [The Scala Center Fundraising Campaign](https://scala-lang.org/blog/2023/09/11/scala-center-fundraising.html)

  [@eed3si9n]: https://github.com/eed3si9n
  [@adpi2]: https://github.com/adpi2
  [@dwijnand]: https://github.com/dwijnand
  [@xuwei-k]: https://github.com/xuwei-k
  [@mrdziuban]: https://github.com/mrdziuban
  [@azdrojowa123]: https://github.com/azdrojowa123
  [@calm329]: https://github.com/calm329
  [@MkDev11]: https://github.com/MkDev11
  [@mohansinghi]: https://github.com/mohansinghi
  [@GlobalStar117]: https://github.com/GlobalStar117
