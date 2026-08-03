---
title: "sbt 2.0.5"
type: story
date: 2026-08-03
url: /sbt-2.0.5
tags: [ "sbt" ]
---

The headline features of sbt 2.0.5 are:

- In-process test ClassLoader change
- `update` task performance improvements
- Common settings bug fix

See also [sbt 2.0 change summary](https://www.scala-sbt.org/2.x/docs/en/changes/sbt-2.0-change-summary.html) for the details.

<!--more-->

Hi everyone. On behalf of the sbt project, I am happy to announce sbt 2.0.4. sbt 2.0 is a new major series of sbt, based on Scala 3 constructs and Bazel-compatible cache system. sbt 2.x is released under Semantic Versioning, and the plugins are expected to work throughout the 2.x series. Please try it out, and report any issues you might come across.

### How to upgrade

The sbt version used for your build is upgraded by putting the following in `project/build.properties`:

```bash
sbt.version=2.0.5
```

This mechanism allows that sbt 2.0.5 is used only for the builds that you want.

Download **the official sbt runner** from SDKMAN, or download from <https://github.com/sbt/sbt/releases/tag/v2.0.5> to upgrade the `sbt` shell script, sbtn, and the launcher.

### Changes with compatibility implications

#### In-process test ClassLoader change

sbt 2.0.5 flips the default value of `closeClassLoaders` to `true`, which will close the in-process, ad-hoc test ClassLoaders. This is intended to fix `AccessDeniedException` observed on Windows.
While closing the ad-hoc test ClassLoader should work in many cases, some tests or libraries that do not join all threads may experience `ClassNotFound` issue.

To workaround the issue, you can fork the test as follows:

```scala
Test / fork := true
```

This was contributed by [@eed3si9n][@eed3si9n] in [#9538](https://github.com/sbt/sbt/pull/9538)

### 🐛 Bug fixes

* fix: Fixes `a/build.sbt` setting leakage by [@eed3si9n][@eed3si9n] in [#9519](https://github.com/sbt/sbt/pull/9519)
* fix: Fixes sbt runner failing to start sbtn on Windows by [@ColOfAbRiX][@ColOfAbRiX] in [#9520](https://github.com/sbt/sbt/pull/9520)
* fix: Fixes forked run baseDirectory by [@eed3si9n][@eed3si9n] in [#9531](https://github.com/sbt/sbt/pull/9531)
* fix: Fixes remote cache header values with `=` by [@KilianSwissborg][@KilianSwissborg] in [#9534](https://github.com/sbt/sbt/pull/9534)
* fix: Fixes pipelined build deadlocks by [@BrianHotopp][@BrianHotopp] in [#9542](https://github.com/sbt/sbt/pull/9542)

### 🚀 Updates

* perf: Improve `update` performance by fixing projectCache by [@hoangmaihuy][@hoangmaihuy] in [#9522](https://github.com/sbt/sbt/pull/9522)
* perf: Improve `update` performance by avoiding artifact content hashing by [@hoangmaihuy][@hoangmaihuy] in [#9524](https://github.com/sbt/sbt/pull/9524)
* sbtn 2.0.0-731e6666 by [@eed3si9n][@eed3si9n] in [#9545](https://github.com/sbt/sbt/pull/9545)

### Participation


sbt 2.0.4 is brought to you by 5 contributors. Eugene Yokota (eed3si9n), Mai Huy Hoàng, Brian Hotopp, Fabrizio Colonna, KilianSwissborg. Thanks!

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
  [@kevin-lee]: https://github.com/kevin-lee
  [@ColOfAbRiX]: https://github.com/ColOfAbRiX
  [@hoangmaihuy]: https://github.com/hoangmaihuy
  [@KilianSwissborg]: https://github.com/KilianSwissborg
