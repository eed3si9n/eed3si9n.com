---
title: "sbt 1.12.14 and 2.0.3"
type: story
date: 2026-07-16
url: /sbt-1.12.14-and-2.0.3
tags: [ "sbt" ]
---

The headline features of sbt 1.12.14 and 2.0.3 are:

- Backport of [CVE-2026-26032](https://app.opencve.io/cve/CVE-2026-26032) fix for Ivy (while sbt might not be affected)
- Update to Jawn 1.7.0 for [CVE-2026-59990](https://github.com/typelevel/jawn/security/advisories/GHSA-cc4v-rvgp-2pf3) and [CVE-2026-61814](https://github.com/typelevel/jawn/security/advisories/GHSA-w4cm-gvhj-cgw6) fixes

See also [sbt 2.0 change summary](https://www.scala-sbt.org/2.x/docs/en/changes/sbt-2.0-change-summary.html) for the details.

<!--more-->

Hi everyone. On behalf of the sbt project, I am happy to announce sbt 1.12.14 and  sbt 2.0.3.

sbt 2.0 is a new major series of sbt, based on Scala 3 constructs and Bazel-compatible cache system. sbt 2.x is released under Semantic Versioning, and the plugins are expected to work throughout the 2.x series. Please try it out, and report any issues you might come across.

### How to upgrade

The sbt version used for your build is upgraded by putting the following in `project/build.properties`:

```bash
sbt.version=2.0.3
```

This mechanism allows that sbt 2.0.3 (or 1.12.14) is used only for the builds that you want.

Download **the official sbt runner** from SDKMAN, or download from <https://github.com/sbt/sbt/releases/tag/v2.0.3> to upgrade the `sbt` shell script, sbtn, and the launcher.

### 🐛 Bug fixes

* fix: Fixes packager cache by [@raboof][@raboof] in [ivy#57](https://github.com/sbt/ivy/pull/57)
* deps: sjson-new 0.15.1, which transitively updates Jawn by [@eed3si9n][@eed3si9n] in [#9458](https://github.com/sbt/sbt/pull/9458)
* fix: Fixes JVM option capability in the launcher config by [@anatoliykmetyuk][@anatoliykmetyuk] in [#9452](https://github.com/sbt/sbt/pull/9452)

### Participation

Thanks to everyone who's helped improve sbt and Zinc by using them, reporting bugs, improving our documentation, porting builds, porting plugins, and submitting and reviewing pull requests.

For anyone interested in helping sbt, there are many avenues for you to help, depending on your interest. If you're interested, [Contributing](https://github.com/sbt/sbt/blob/develop/CONTRIBUTING.md), ["help wanted"](https://github.com/sbt/sbt/issues?q=is%3Aissue+is%3Aopen+label%3A%22help+wanted%22), ["good first issue"](https://github.com/sbt/sbt/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22), and [Discussions](https://github.com/sbt/sbt/discussions/) are good starting points.

----

### FYI - Scala Days talk

I gave a talk in Scala Days 2025 about sbt 2.0 ([recording](https://www.youtube.com/watch?v=GM2ywMb4z7A), [slide deck](https://www.slideshare.net/slideshow/sbt-2-0-go-big-scala-days-2025-edition/282592302)).

### Donate to Scala Center

Scala Center is a non-profit center at EPFL to support education and open source.

- [The Scala Center Fundraising Campaign](https://scala-lang.org/blog/2023/09/11/scala-center-fundraising.html)

  [@eed3si9n]: https://github.com/eed3si9n
  [@anatoliykmetyuk]: https://github.com/anatoliykmetyuk
  [@adpi2]: https://github.com/adpi2
  [@dwijnand]: https://github.com/dwijnand
  [@xuwei-k]: https://github.com/xuwei-k
  [@mrdziuban]: https://github.com/mrdziuban
  [@bitloi]: https://github.com/bitloi
  [@BrianHotopp]: https://github.com/BrianHotopp
  [@tanishiking]: https://github.com/tanishiking
  [@jozanek]: https://github.com/jozanek
  [@raboof]: https://github.com/raboof
  [@mrdziuban]: https://github.com/mrdziuban
  [@yhefamly]: https://github.com/yhefamly
