---
title: "sbt 2.0.9"
type: story
date: 2026-09-14
url: /sbt-2.0.9
tags: [ "sbt" ]
---

The headline features of sbt 2.0.9 are:

- AccessDeniedException fix on Windows
- Hermeticity fix for SemanticDB plugin
- Build pipelining fix backports

See also [sbt 2.0 change summary](https://www.scala-sbt.org/2.x/docs/en/changes/sbt-2.0-change-summary.html) for the sbt 2.0 changes in general.

<!--more-->

Hi everyone. On behalf of the sbt project, I am happy to announce sbt 2.0.9. sbt 2.0 is a new major series of sbt, based on Scala 3 constructs and Bazel-compatible cache system. sbt 2.x is released under Semantic Versioning, and the plugins are expected to work throughout the 2.x series. Please try it out, and report any issues you might come across.

### How to upgrade

The sbt version used for your build is upgraded by putting the following in `project/build.properties`:

```bash
sbt.version=2.0.9
```

This mechanism allows that sbt 2.0.9 is used only for the builds that you want.

Download **the official sbt runner** from SDKMAN, or download from <https://github.com/sbt/sbt/releases/tag/v2.0.9> to upgrade the `sbt` shell script, sbtn, and the launcher.

### 🐛 Bug fixes

- fix: Fixes AccessDeniedException on Windows by creating JAR in situ by [@eed3si9n][@eed3si9n] in [io#558](https://github.com/sbt/io/pull/558)
- fix: Fixes unhermetic `semanticdbTargetRoot` in the compile cache key by [@christianharrington][@christianharrington] in [#9711](https://github.com/sbt/sbt/pull/9711)
- fix: Fixes pipelined build with Java sources by [@anatoliykmetyuk][@anatoliykmetyuk] in [#9574](https://github.com/sbt/sbt/pull/9574)
- fix: Keep macro subprojects off the pipelined classpath by [@stasimus][@stasimus] in [#9719](https://github.com/sbt/sbt/pull/9719)
- fix: Fixes sbt runner script not starting on openSUSE by [@alexasl][@alexasl] in [#9753](https://github.com/sbt/sbt/pull/9753)
- Update to sbtn 2.1.0-M1 https://github.com/sbt/sbt/pull/9755

### Participation

sbt 2.0.9 is brought to you by 5 contributors. Anatolii Kmetiuk, Eugene Yokota (eed3si9n), Alexander, Christian Harrington, and Stas Shevchenko. Thanks!

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
  [@xuwei-k]: https://github.com/xuwei-k
  [@BrianHotopp]: https://github.com/BrianHotopp
  [@tanishiking]: https://github.com/tanishiking
  [@jozanek]: https://github.com/jozanek
  [@raboof]: https://github.com/raboof
  [@mrdziuban]: https://github.com/mrdziuban
  [@unkarjedy]: https://github.com/unkarjedy
  [@azdrojowa123]: https://github.com/azdrojowa123
  [@stasimus]: https://github.com/stasimus
  [@christianharrington]: https://github.com/christianharrington
  [@alexasl]: https://github.com/alexasl
