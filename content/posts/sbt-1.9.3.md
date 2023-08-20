---
title:       "sbt 1.9.3"
type:        story
date:        2023-07-24
url:         /sbt-1.9.3
tags:        [ "sbt" ]
---

Hi everyone. On behalf of the sbt project, I'm happy to announce sbt 1.9.3 patch release is available. Full release note is here - https://github.com/sbt/sbt/releases/tag/v1.9.3

See [1.9.0 release note](/sbt-1.9.0) for the details on 1.9.x features.

### Highlights

- Actionable diagnostics (aka quickfix) fixes

<!--more-->

### How to upgrade

Download **the official sbt runner** from SDKMAN or download from <https://github.com/sbt/sbt/releases/tag/v1.9.3> to upgrade the `sbt` shell script and the launcher:

```bash
$ sdk install sbt 1.9.3
$ sdk upgrade sbt # or upgrade
```

The sbt version used for your build is upgraded by putting the following in `project/build.properties`:

```bash
sbt.version=1.9.3
```

This mechanism allows that sbt 1.9.3 is used only for the builds that you want.

### Actionable diagnostics (aka quickfix)

Actionable diagnostics, or quickfix, is one of areas in Scala tooling taht's been getting attention since Chris Kipp presented it in the March 2023 Tooling Summit. Chris has written the [roadmap][actionable] and sent [sbt/sbt#7242][7242] that kick started the effort, but now there's been steady progress in [Build Server Protocol][bsp527], [Dotty](https://github.com/lampepfl/dotty/issues/17337), [Scala 2.13](https://github.com/scala/scala/pull/10406/), IntelliJ, Zinc, etc. Metals 1.0.0, for example, is now capable of surfacing code actions as a quickfix.

![code action](images/code_action.svg)

sbt 1.9.3 adds a new interface called `AnalysisCallback2` to relay code actions from the compiler(s) to Zinc's Analysis file. Future version of Scala 2.13.x (and hopefully Scala 3) will release with proper code actions, but as a demo I've implemented a code action for procedure syntax usages even on current Scala 2.13.11 with `-deprecation` flag. You can try this with Metals 1.0.0 + [using sbt as Metals build server](https://www.scala-sbt.org/1.x/docs/IDE.html#metals):

<img src="images/sbt-1.9.3-800.gif" width="700" />

This was contributed by Eugene Yokota in [zinc#1226][zinc1226]. Special thanks to [@lrytz][@lrytz] for identifying this issue in [zinc#1214](https://github.com/sbt/zinc/discussions/1214).

### other updates

- Adds M1/M2/Aarch64 build of sbtn into the installer [@julienrf][@julienrf] in [#7329][7329]
- Fixes scripted test timing out after 5 minutes by [@eed3si9n][@eed3si9n] in [#7336][7336]

### Participation

Thanks to everyone who's helped improve sbt and Zinc by using them, reporting bugs, improving our documentation, porting builds, porting plugins, and submitting and reviewing pull requests.

For anyone interested in helping sbt, there are many avenues for you to help, depending on your interest. If you're interested, [Contributing](https://github.com/sbt/sbt/blob/develop/CONTRIBUTING.md), ["help wanted"](https://github.com/sbt/sbt/issues?q=is%3Aissue+is%3Aopen+label%3A%22help+wanted%22), ["good first issue"](https://github.com/sbt/sbt/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22), and [Discussions](https://github.com/sbt/sbt/discussions/) are good starting points.

----

### 🏳️‍🌈 Support Ukraine 🇺🇦

Forbidden Colours has started a fundraising campaign to support organisations in Poland, Hungary and Romania that are welcoming LGBTIQ+ refugees.

<https://www.forbidden-colours.com/2022/02/26/support-ukrainian-lgbtiq-refugees/>

### Donate to Scala Center

Scala Center is a non-profit center at EPFL to support education and open source.

- <https://scala.epfl.ch/donate.html>

  [@eed3si9n]: https://github.com/eed3si9n
  [@Nirvikalpa108]: https://github.com/Nirvikalpa108
  [@adpi2]: https://github.com/adpi2
  [@er1c]: https://github.com/er1c
  [@eatkins]: https://github.com/eatkins
  [@dwijnand]: https://github.com/dwijnand
  [@ckipp01]: https://github.com/ckipp01
  [@mdedetrich]: https://github.com/mdedetrich
  [@xuwei-k]: https://github.com/xuwei-k
  [@lrytz]: https://github.com/lrytz
  [@julienrf]: https://github.com/julienrf
  [7242]: https://github.com/sbt/sbt/pull/7242
  [7251]: https://github.com/sbt/sbt/pull/7251
  [7329]: https://github.com/sbt/sbt/pull/7329
  [7336]: https://github.com/sbt/sbt/pull/7336
  [zinc1186]: https://github.com/sbt/zinc/pull/1186
  [zinc1226]: https://github.com/sbt/zinc/pull/1226
  [bsp527]: https://github.com/build-server-protocol/build-server-protocol/pull/527
  [actionable]: https://contributors.scala-lang.org/t/roadmap-for-actionable-diagnostics/6172/1
