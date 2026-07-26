---
title: "sbt 2.0.4"
type: story
date: 2026-07-26
url: /sbt-2.0.4
tags: [ "sbt" ]
---

The headline features of sbt 2.0.4 are:

- Forked runs in current directory
- Caching-related bug fixes
- Memory improvement on large builds

See also [sbt 2.0 change summary](https://www.scala-sbt.org/2.x/docs/en/changes/sbt-2.0-change-summary.html) for the details.

<!--more-->

Hi everyone. On behalf of the sbt project, I am happy to announce sbt 2.0.4. sbt 2.0 is a new major series of sbt, based on Scala 3 constructs and Bazel-compatible cache system. sbt 2.x is released under Semantic Versioning, and the plugins are expected to work throughout the 2.x series. Please try it out, and report any issues you might come across.

### How to upgrade

The sbt version used for your build is upgraded by putting the following in `project/build.properties`:

```bash
sbt.version=2.0.4
```

This mechanism allows that sbt 2.0.4 is used only for the builds that you want.

Download **the official sbt runner** from SDKMAN, or download from <https://github.com/sbt/sbt/releases/tag/v2.0.4> to upgrade the `sbt` shell script, sbtn, and the launcher.

### Changes with compatibility implications

### Forked run working directory

Starting sbt 2.0.4, the working directory for forked run will be changed to the build's working directory instead of the subproject's `baseDirectory`.

```scala
scalaVersion := "3.8.4"

lazy val app = project
```

This is intended to make client-side run behave similar to sbt 1's `run` task. For example, `app/run` will run inside `.` as opposed to `app`. This was contributed by [@jozanek][@jozanek] in [#9442](https://github.com/sbt/sbt/pull/9442).

### 🐛 Bug fixes

* fix: Fixes test ClassLoader retention issues by [@kevin-lee][@kevin-lee] in [#9485](https://github.com/sbt/sbt/pull/9485)
* fix: Fixes common settings with a plugin with `extraProjects` by [@eed3si9n] in [#9495](https://github.com/sbt/sbt/pull/9495)
* fix: Fixes dependency tree rendering on some libraries by [@anatoliykmetyuk][@anatoliykmetyuk] in [#9371](https://github.com/sbt/sbt/pull/9371)
* fix: Fixes tests not detecting stale resources by [@eed3si9n][@eed3si9n] in [#9469](https://github.com/sbt/sbt/pull/9469)
* fix: Fixes sbtn not propagating `-java-home` by [@BrianHotopp][@BrianHotopp] in [#9448](https://github.com/sbt/sbt/pull/9448)
* fix: Fixes `clean` task not cleaning sona-staging by [@eed3si9n][@eed3si9n] in [#9479](https://github.com/sbt/sbt/pull/9479)
* fix: Fixes reboot from sbtn by [@BrianHotopp][@BrianHotopp] in [#9497](https://github.com/sbt/sbt/pull/9497)

### 🐛 Caching related bug fixes

* fix: Fixes hashes for directories in MappedVirtualFile by [@raboof][@raboof] in [zinc#1747](https://github.com/sbt/zinc/pull/1747)
* fix: Fixes `Def.declareOutput` invoked in a loop by [@BrianHotopp][@BrianHotopp] in [#9492](https://github.com/sbt/sbt/pull/9492)
* fix: Fixes partial cache restoration by [@stasimus][@stasimus] in [#9488](https://github.com/sbt/sbt/pull/9488)
* fix: Fixes system errors getting cached as compilation errors by [@BrianHotopp][@BrianHotopp] in [#9464](https://github.com/sbt/sbt/pull/9464)
* fix: Improves cache restoration when the expected outputs are missing by [@BrianHotopp][@BrianHotopp] in [#9473](https://github.com/sbt/sbt/pull/9473)
* fix: Fixes gRPC channels recreated on reload by [@eed3si9n][@eed3si9n] in [#9502](https://github.com/sbt/sbt/pull/9502)
* fix: Fixes scalaCompilerBridgeBin task leaking project name by [@eed3si9n][@eed3si9n] in [#9506](https://github.com/sbt/sbt/pull/9506)
* refactor: Separate file I/O from cache-write serialization by [@BrianHotopp][@BrianHotopp] in [#9496](https://github.com/sbt/sbt/pull/9496)

### 🚀 Updates

* feat: Skip checksum generation for `*.asc` file during publishing by [@eed3si9n][@eed3si9n] in [#9499](https://github.com/sbt/sbt/pull/9499)
* feat: Move compiler bridge to `update` by [@eed3si9n][@eed3si9n] in [#8836](https://github.com/sbt/sbt/pull/8836)
* feat: Allow opt-out of transient warning by [@eed3si9n][@eed3si9n] in [#9437](https://github.com/sbt/sbt/pull/9437)
* perf: Intern directory item conversions in MappedFileConverter by [@hoangmaihuy][@hoangmaihuy] in [#1751](https://github.com/sbt/zinc/pull/1751)
* perf: Intern analysis values while deserializing by [@hoangmaihuy][@hoangmaihuy] in [#1754](https://github.com/sbt/zinc/pull/1754)

### Participation

sbt 2.0.4 is brought to you by 8 contributors. Eugene Yokota (eed3si9n), Brian Hotopp, Mai Huy Hoàng, Anatolii Kmetiuk, Arnout Engelen, Jozef Koval, Kevin Lee, Stas Shevchenko. Thanks!

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
  [@stasimus]: https://github.com/stasimus
  [@hoangmaihuy]: https://github.com/hoangmaihuy
