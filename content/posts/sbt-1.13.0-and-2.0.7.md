---
title: "sbt 1.13.0 and 2.0.7"
type: story
date: 2026-08-21
url: /sbt-1.13.0-and-2.0.7
tags: [ "sbt" ]
---

The headline features of sbt 1.13.0 are

* Vulnerability fix for remote code execution via BSP when `serverConnectionType` is set to `Tcp`
* Scala 3.9.0 REPL support

<!--more-->

Hi everyone. On behalf of the sbt project, I am happy to announce sbt 1.13.0 and sbt 2.0.7. See also [sbt 2.0 change summary](https://www.scala-sbt.org/2.x/docs/en/changes/sbt-2.0-change-summary.html) for the details on sbt 2.0.

### How to upgrade

The sbt version used for your build is upgraded by putting the following in `project/build.properties`:

```bash
sbt.version=1.13.0
```

This mechanism allows that sbt 1.13.0 (or 2.0.7) is used only for the builds that you want.

Download **the official sbt runner** from SDKMAN, or download from <https://github.com/sbt/sbt/releases/tag/v2.0.7> to upgrade the `sbt` shell script, sbtn, and the launcher.

### Remote code execution via BSP

sbt team received a security report [GHSA-943m-f264-54p4](https://github.com/sbt/sbt/security/advisories/GHSA-943m-f264-54p4) from [Stas Shevchenko](https://github.com/stasimus) that when the `serverConnectionType` is set to `Tcp`, an attacker is able to execute arbitrary code remotely via BSP. sbt 1.13.0 and 2.0.7 fix this bug.

Builds with the default `serverConnectionType` are not affected. We recommend removing the `serverConnectionType` setting, or upgrading to a patched version or later. In an affected build, the setting might look like this:

```scala
Global / serverConnectionType := ConnectionType.Tcp
```

Since BSP does not have authentication, BSP support will be dropped when the connection type is set to `Tcp`. The remediation was implemented by Stas as well.

### Scala 3.9 REPL support

Scala 3.9 (at the time 3.9.0-RC6) has adopted JLine 4.0.14, as opposed to JLine 3.x used by sbt 1.x. sbt 1.13.0 implements a workaround that allows `console` task to run with Scala 3.9.

This was contributed by [@Gedochao][@Gedochao] as [#9564](https://github.com/sbt/sbt/pull/9564).

### Other updates

* `IO.jarParallel` and `IO.zipParallel` by [@hoangmaihuy][@hoangmaihuy] in [io#540](https://github.com/sbt/io/pull/540)

### 🐛 Other bug fixes

* fix: Avoid rewriting unchanged plugin descriptors by [@unkarjedy][@unkarjedy] in [#9613](https://github.com/sbt/sbt/pull/9613)
* fix: Fixes `-V` parsing in sbt runners by [@anatoliykmetyuk][@anatoliykmetyuk] in [#9626](https://github.com/sbt/sbt/pull/9626)

### 🐛 sbt 2.x bug fixes

* fix: Guard diskcache against path traversal by [@eed3si9n][@eed3si9n] in [#9605](https://github.com/sbt/sbt/pull/9605)
* fix: Name the platform in `CrossVersion(module, scalaModuleInfo)` by [@kitbellew][@kitbellew] in [#9620](https://github.com/sbt/sbt/pull/9620)
* fix: Fixes `scalacOptions` in BSP using `VirtualFileRef` by [@azdrojowa123][@azdrojowa123] in [#9610](https://github.com/sbt/sbt/pull/9610)
* fix: Fixes filesystem traversal order affecting cache stability by [@christianharrington][@christianharrington] in [#9646](https://github.com/sbt/sbt/pull/9646)

### Participation

sbt 1.13.0 and 2.0.7 are brought to you by 9 contributors. Eugene Yokota (eed3si9n), Albert Meltzer, Aleksandra Zdrojowa, Anatolii Kmetiuk, Christian Harrington, Dmitrii Naumenko, Mai Huy Hoàng, Piotr Chabelski, Stas Shevchenko.

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
  [@takayahilton]: https://github.com/takayahilton
  [@Gedochao]: https://github.com/Gedochao
  [@takayahilton]: https://github.com/takayahilton
  [@hoangmaihuy]: https://github.com/hoangmaihuy
  [@unkarjedy]: https://github.com/unkarjedy
  [@kitbellew]: https://github.com/kitbellew
  [@azdrojowa123]: https://github.com/azdrojowa123
  [@christianharrington]: https://github.com/christianharrington
