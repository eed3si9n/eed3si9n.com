---
title: "sbt 2.0.1"
type: story
date: 2026-06-29
url: /sbt-2.0.1
tags: [ "sbt" ]
---


The headline features of sbt 2.0.1 are:

- Incremental test performance improvement
- sbt runner fixes
- Global plugin loading fix
- Coursier 2.1.25-M26

See also [sbt 2.0 change summary](https://www.scala-sbt.org/2.x/docs/en/changes/sbt-2.0-change-summary.html) for the details.

<!--more-->

Hi everyone. On behalf of the sbt project, I am happy to announce sbt 2.0.1. sbt 2.0 is a new major series of sbt, based on Scala 3 constructs and Bazel-compatible cache system. sbt 2.x is released under Semantic Versioning, and the plugins are expected to work throughout the 2.x series. Please try it out, and report any issues you might come across.

### How to upgrade

The sbt version used for your build is upgraded by putting the following in `project/build.properties`:

```bash
sbt.version=2.0.1
```

This mechanism allows that sbt 2.0.1 is used only for the builds that you want.

Download **the official sbt runner** from SDKMAN, or download from <https://github.com/sbt/sbt/releases/tag/v2.0.1> to upgrade the `sbt` shell script, sbtn, and the launcher.

### 🐛 Bug fixes

* fix: Fixes sbt runner parsing `build.properties` with whitespaces by [@anatoliykmetyuk][@anatoliykmetyuk] in [#9374](https://github.com/sbt/sbt/pull/9374)
* fix: Fixes global plugin loading by [@eed3si9n][@eed3si9n] in [#9391](https://github.com/sbt/sbt/pull/9391) / [#9380](https://github.com/sbt/sbt/pull/9380)
* fix: Fixes sbt runner support on OpenBSD by [@eed3si9n][@eed3si9n] in [#9394](https://github.com/sbt/sbt/pull/9394)
* fix: Fixes `--allow-empty` and `--sbt-create` by [@anatoliykmetyuk][@anatoliykmetyuk] in [#9370](https://github.com/sbt/sbt/pull/9370)
* fix: Fixes BSP `publishDiagnostics` propagation by [@anatoliykmetyuk][@anatoliykmetyuk] in [#9376](https://github.com/sbt/sbt/pull/9376)
* fix: Fixes macro expansion for higher-kinded type arguments by [@tanishiking][@tanishiking] in [#9377](https://github.com/sbt/sbt/pull/9377)
* fix: Fixes IllegalAccessError analyzing Java compiled with `--add-exports` by [@jozanek][@jozanek] in [zinc#1714](https://github.com/sbt/zinc/pull/1714) / [zinc#1729](https://github.com/sbt/zinc/pull/1729)
* fix: Fixes incremental compilation of inlined constants in Java by [@jozanek][@jozanek] in [zinc#1721](https://github.com/sbt/zinc/pull/1721)
* fix: Fixes incremental compilation of Java annotation usage by [@jozanek][@jozanek] in [zinc#1722](https://github.com/sbt/zinc/pull/1722)
* fix: Fixes incremental compilation of transitive Java super types by [@jozanek][@jozanek] in [zinc#1732](https://github.com/sbt/zinc/pull/1732)

### 🚀 Updates

* perf: Update to Coursier 2.1.25-M26 by [@retronym][@retronym] in [#9382](https://github.com/sbt/sbt/pull/9382)
* perf: Improves performance of incremental test by [@mrdziuban][@mrdziuban] + [@yhefamly][@yhefamly] in [#9253](https://github.com/sbt/sbt/pull/9253) + [#9364](https://github.com/sbt/sbt/pull/9364)

### Participation

sbt 2.0.1 is brought to you by 7 contributors. Jozef Koval, Anatolii Kmetiuk, Eugene Yokota (eed3si9n), Jason Zaugg, Matt Dziuban, Rikito Taniguchi, and Yannick Heiber. Thanks!

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
  [@retronym]: https://github.com/retronym
  [@mrdziuban]: https://github.com/mrdziuban
  [@yhefamly]: https://github.com/yhefamly
