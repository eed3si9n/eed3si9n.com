---
title:       "sbt 1.8.0-RC1"
type:        story
date:        2022-11-07
url:         /sbt-1.8.0-beta
tags:        [ "sbt" ]
---

Hi everyone. On behalf of the sbt project, I am happy to announce sbt 1.8.0-RC1. This is the eighth feature release of sbt 1.x, a binary compatible release focusing on new features. sbt 1.x is released under Semantic Versioning, and the plugins are expected to work throughout the 1.x series. Please try it out, and report any issues you might come across.

### Highlights

sbt 1.8.0 is a small release focused on upgrading scala-xml to 2.x. In theory this breaks the binary compatibility in the plugin ecosystem, but in practice there's already a mixture of both 1.x and 2.x.

If you encounter a conflict in plugins, try putting the following in `project/plugins.sbt`:

```scala
ThisBuild / libraryDependencySchemes += "org.scala-lang.modules" %% "scala-xml" % VersionScheme.Always
```

<!--more-->

### How to upgrade

Download **the official sbt runner** from SDKMAN or download from <https://github.com/sbt/sbt/releases/tag/v1.8.0-RC1> to upgrade the `sbt` shell script and the launcher.

The sbt version used for your build is upgraded by putting the following in `project/build.properties`:

```bash
sbt.version=1.8.0-RC1
```

This mechanism allows that sbt 1.8.0-RC1 is used only for the builds that you want.

## Changes with compatibility implications

- Updates to Scala 2.12.17 + Scala compiler 2.12.17, which upgrades to scala-xml 2.x [#7021][7021]

## Bug fixes

- Fixes background job logging [#6992][6992] by [@adpi2][@adpi2]

## Other updates

- Adds long classpath support on JDK 9+ via argument file (opt out using `-Dsbt.argsfile=false` or `SBT_ARGSFILE` environment variable) [#7010][7010] by [@easel][@easel]
- Adds out-of-box ZIO Test support [#7053][7053] by [@987Nabil][@987Nabil]
- Adds support for newly introduced `buildTarget/outputPaths` method of Build Server Protocol. [#6985][6985] by [@povder][@povder]

### Participation

sbt 1.8.0-RC1 was brought to you by 12 contributors.

```
16  Eugene Yokota (eed3si9n)
10  gontard
5  dependabot[bot]
5  Chris Kipp
4  Devin Fisher
3  Adrien Piquerez
3  Alex
2  Vedant
2  frosforever
1  Nabil Abdel-Hafeez
1  Krzysztof Pado
1  Erik LaBianca
```

Thanks to everyone who's helped improve sbt and Zinc by using them, reporting bugs, improving our documentation, porting builds, porting plugins, and submitting and reviewing pull requests.

For anyone interested in helping sbt, there are many avenues for you to help, depending on your interest. If you're interested, [Contributing](https://github.com/sbt/sbt/blob/develop/CONTRIBUTING.md), ["help wanted"](https://github.com/sbt/sbt/issues?q=is%3Aissue+is%3Aopen+label%3A%22help+wanted%22), ["good first issue"](https://github.com/sbt/sbt/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22), and [Discussions](https://github.com/sbt/sbt/discussions/) are good starting points.

### 🏳️‍🌈 Support Ukraine 🇺🇦

Forbidden Colours has started a fundraising campaign to support organisations in Poland, Hungary and Romania that are welcoming LGBTIQ+ refugees.

<https://www.forbidden-colours.com/2022/02/26/support-ukrainian-lgbtiq-refugees/>

### Donate to Play

- https://www.playframework.com/sponsors

  [7021]: https://github.com/sbt/sbt/pull/7021
  [6985]: https://github.com/sbt/sbt/pull/6985
  [6992]: https://github.com/sbt/sbt/pull/6992
  [7010]: https://github.com/sbt/sbt/pull/7010
  [7030]: https://github.com/sbt/sbt/pull/7030
  [7053]: https://github.com/sbt/sbt/pull/7053
  [@eed3si9n]: https://github.com/eed3si9n
  [@Nirvikalpa108]: https://github.com/Nirvikalpa108
  [@adpi2]: https://github.com/adpi2
  [@er1c]: https://github.com/er1c
  [@eatkins]: https://github.com/eatkins
  [@dwijnand]: https://github.com/dwijnand
  [@ckipp01]: https://github.com/ckipp01
  [@povder]: https://github.com/povder
  [@easel]: https://github.com/easel
  [@987Nabil]: https://github.com/987Nabil