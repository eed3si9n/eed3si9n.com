---
title: "sbt 2.0.2"
type: story
date: 2026-07-13
url: /sbt-2.0.2
tags: [ "sbt" ]
---

The headline features of sbt 2.0.2 are:

- Metabuild resolution fix
- Build pipelining fix
- Remote cache timeout fix
- sbtn stdout replaying fix

See also [sbt 2.0 change summary](https://www.scala-sbt.org/2.x/docs/en/changes/sbt-2.0-change-summary.html) for the details.

<!--more-->

Hi everyone. On behalf of the sbt project, I am happy to announce sbt 2.0.2. sbt 2.0 is a new major series of sbt, based on Scala 3 constructs and Bazel-compatible cache system. sbt 2.x is released under Semantic Versioning, and the plugins are expected to work throughout the 2.x series. Please try it out, and report any issues you might come across.

### How to upgrade

The sbt version used for your build is upgraded by putting the following in `project/build.properties`:

```bash
sbt.version=2.0.2
```

This mechanism allows that sbt 2.0.2 is used only for the builds that you want.

Download **the official sbt runner** from SDKMAN, or download from <https://github.com/sbt/sbt/releases/tag/v2.0.2> to upgrade the `sbt` shell script, sbtn, and the launcher.

### 🐛 Bug fixes

* fix: Fixes metabuild dependency downgrade via plugin by [@anatoliykmetyuk][@anatoliykmetyuk] in [#9426](https://github.com/sbt/sbt/pull/9426)
* fix: Fixes build pipelining by [@anatoliykmetyuk][@anatoliykmetyuk] in [#9425](https://github.com/sbt/sbt/pull/9425)
* fix: Fixes remote cache ByteStream timeout by [@yhefamly][@yhefamly] in [#9413](https://github.com/sbt/sbt/pull/9413)
* fix: Fixes sbtn stdout relaying by [@BrianHotopp][@BrianHotopp] in [#9411](https://github.com/sbt/sbt/pull/9411) / [#9414](https://github.com/sbt/sbt/pull/9414)
* fix: Fixes auto import of givens by [@xuwei-k][@xuwei-k] in [#9409](https://github.com/sbt/sbt/pull/9409)
* fix: Fixes `shutdownall` in sbt runner by [@eed3si9n][@eed3si9n] in [#9435](https://github.com/sbt/sbt/pull/9435)
* fix: Fixes attribute string in `pom.xml` to be deterministic [@raboof][@raboof] in [ivy#51](https://github.com/sbt/ivy/pull/51)
* fix: Fixes ivyless publishing of sbt plugins by [@anatoliykmetyuk][@anatoliykmetyuk] in [#9416](https://github.com/sbt/sbt/pull/9416)

### Updates

* Deprecate `url(...)` and `Resolver.url(...)` in favor of `uri(...)` by [@eed3si9n][@eed3si9n] in [#9420](https://github.com/sbt/sbt/pull/9420)
* Tweak server startup message by [@eed3si9n][@eed3si9n] in [#9429](https://github.com/sbt/sbt/pull/9429)
* ipcsocket 1.8.0 by [@eed3si9n][@eed3si9n] in [#9436](https://github.com/sbt/sbt/pull/9436)


### Participation

sbt 2.0.2 is brought to you by 6 contributors. Eugene Yokota (eed3si9n), Anatolii Kmetiuk, BrianHotopp, Arnout Engelen, Kenji Yoshida (xuwei-k), Yannick Heiber. Thanks!

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
