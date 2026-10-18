---
title: "sbt 2.0.10"
type: story
date: 2026-10-02
url: /sbt-2.0.10
tags: [ "sbt" ]
---

The headline features of sbt 2.0.10 are:

- Updates to Coursier 2.1.26
- `sbt` runner script honors `JAVA_HOME` environment variable
- Read-only CAS, to prevent CAS corruption
- Other backported fixes

See also [sbt 2.0 change summary](https://www.scala-sbt.org/2.x/docs/en/changes/sbt-2.0-change-summary.html) for the sbt 2.0 changes in general.

<!--more-->

Hi everyone. On behalf of the sbt project, I am happy to announce sbt 2.0.10. sbt 2.0 is a new major series of sbt, based on Scala 3 constructs and Bazel-compatible cache system. sbt 2.x is released under Semantic Versioning, and the plugins are expected to work throughout the 2.x series. Please try it out, and report any issues you might come across.

### How to upgrade

The sbt version used for your build is upgraded by putting the following in `project/build.properties`:

```bash
sbt.version=2.0.10
```

This mechanism allows that sbt 2.0.10 is used only for the builds that you want.

Download **the official sbt runner** from SDKMAN, or download from <https://github.com/sbt/sbt/releases/tag/v2.0.10> to upgrade the `sbt` shell script, sbtn, and the launcher.

### Changes with compatibility implications

- `sbt` runner script honors `JAVA_HOME` environment variable by [@anatoliykmetyuk][@anatoliykmetyuk] in [#9825](https://github.com/sbt/sbt/pull/9825)

### 🚀 Updates

- deps: Updates to Coursier 2.1.26, and sets user agent header by [@eed3si9n][@eed3si9n] in [#9784](https://github.com/sbt/sbt/pull/9784), [#9852](https://github.com/sbt/sbt/pull/9852), [#9786](https://github.com/sbt/sbt/pull/9786), and [#9818](https://github.com/sbt/sbt/pull/9818)

### 🐛 Bug fixes

- fix: Removes write permission from the CAS to prevent cache corruption by [@eed3si9n][@eed3si9n] in [#9847](https://github.com/sbt/sbt/pull/9847)
- fix: Implements copy-on-write for symlinks by [@eed3si9n][@eed3si9n] in [#io#568)](https://github.com/sbt/io/pull/568)
- fix: Restores the pipelining early output on an action-cache hit by [@PhoenixmitX][@PhoenixmitX] in [#9793](https://github.com/sbt/sbt/pull/9793)
- fix: Reads scripted `pause` from standard input by [@anatoliykmetyuk][@anatoliykmetyuk] in [#9824](https://github.com/sbt/sbt/pull/9824)
- fix: Keeps the interrupt flag when writing to the thin client by [@pierscin][@pierscin] and [@eed3si9n][@eed3si9n] in [#9848](https://github.com/sbt/sbt/pull/9848) / [#9855](https://github.com/sbt/sbt/pull/9855)

### Participation

sbt 2.0.10 is brought to you by 4 contributors. Eugene Yokota (eed3si9n), Anatolii Kmetiuk, Michał Pierściński, and PhoenixmitX. Thanks!

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
  [@PhoenixmitX]: https://github.com/PhoenixmitX
  [@pierscin]: https://github.com/pierscin
