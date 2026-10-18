---
title: "sbt 2.0.11"
type: story
date: 2026-10-18
url: /sbt-2.0.11
tags: [ "sbt" ]
---

The headline features of sbt 2.0.11 are:

- Workaround for SemanticDB asynchronous writes
- Better Docker support
- Other backported bug fixes

See also [sbt 2.0 change summary](https://www.scala-sbt.org/2.x/docs/en/changes/sbt-2.0-change-summary.html) for the sbt 2.0 changes in general.

<!--more-->

Hi everyone. On behalf of the sbt project, I am happy to announce sbt 2.0.11. sbt 2.0 is a new major series of sbt, based on Scala 3 constructs and Bazel-compatible cache system. sbt 2.x is released under Semantic Versioning, and the plugins are expected to work throughout the 2.x series. Please try it out, and report any issues you might come across.

### How to upgrade

The sbt version used for your build is upgraded by putting the following in `project/build.properties`:

```bash
sbt.version=2.0.11
```

This mechanism allows that sbt 2.0.11 is used only for the builds that you want.

Download **the official sbt runner** from SDKMAN, or download from <https://github.com/sbt/sbt/releases/tag/v2.0.11> to upgrade the `sbt` shell script, sbtn, and the launcher.

### 🐛 Bug fixes

- fix: Fix AccessDeniedException writing SemanticDB by [@eed3si9n][@eed3si9n] in [#9878](https://github.com/sbt/sbt/pull/9878)
- fix: Fixes `.m2/settings.xml` overriding `sbtResolvers` by [@eed3si9n][@eed3si9n] in [#9828](https://github.com/sbt/sbt/pull/9828)
- fix: Keep accepting after a client fails by [@kitbellew][@kitbellew] in [#9691](https://github.com/sbt/sbt/pull/9691)
- fix: Fix task output lost by the thin client under CPU load by [@eed3si9n][@eed3si9n] in [#9868](https://github.com/sbt/sbt/pull/9868)
- fix: Read all forked test output before reporting the fork's exit by [@eugkhp][@eugkhp] in [#9860](https://github.com/sbt/sbt/pull/9860)
- fix: Use `Path.userHome` to work around `user.home` returning `?` by [@eed3si9n][@eed3si9n] in [#9866](https://github.com/sbt/sbt/pull/9866)
- fix: Fail a gRPC batch read when a blob fails by [@eugkhp][@eugkhp] in [#9904](https://github.com/sbt/sbt/pull/9904)
- fix: Fix pipelined compile hanging when compile inputs fail by [@jleider][@jleider] in [#9896](https://github.com/sbt/sbt/pull/9896)
- fix: Workaround compiler-interface eviction when depending on the remote cache plugin by [@eed3si9n][@eed3si9n] in [#9913](https://github.com/sbt/sbt/pull/9913)
- Make logging robust against closed sbtn by [@eed3si9n][@eed3si9n] in [#9911](https://github.com/sbt/sbt/pull/9911)
- fix: Fix BSP connection getting dropped by [@eed3si9n][@eed3si9n] in [#9911](https://github.com/sbt/sbt/pull/9911)

### Participation

sbt 2.0.11 is brought to you by 4 contributors. Eugene Yokota (eed3si9n), Eugene (eugkhp), Albert Meltzer, and Justin Leider. Thanks!

Thanks to everyone who's helped improve sbt and Zinc by using them, reporting bugs, improving our documentation, porting builds, porting plugins, and submitting and reviewing pull requests.

For anyone interested in helping sbt, there are many avenues for you to help, depending on your interest. If you're interested, [Contributing](https://github.com/sbt/sbt/blob/develop/CONTRIBUTING.md), ["help wanted"](https://github.com/sbt/sbt/issues?q=is%3Aissue+is%3Aopen+label%3A%22help+wanted%22), ["good first issue"](https://github.com/sbt/sbt/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22), and [Discussions](https://github.com/sbt/sbt/discussions/) are good starting points.

----

### FYI - Scala Days 2026 talk

I gave a talk in Scala Days 2026 in Berlin about sbt 2.0 ([recording](https://www.youtube.com/watch?v=d4UCnN0q2Ss), [slide deck](https://speakerdeck.com/eed3si9n/sbt-2-dot-0-takeoff)).

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
  [@kitbellew]: https://github.com/kitbellew
  [@eugkhp]: https://github.com/eugkhp
  [@jleider]: https://github.com/jleider
