---
title:       "sbt 1.10.2"
type:        story
date:        2024-09-15
url:         /sbt-1.10.2
tags:        [ "sbt" ]
---

  [@eed3si9n]: https://github.com/eed3si9n
  [@adpi2]: https://github.com/adpi2
  [@dwijnand]: https://github.com/dwijnand
  [@xuwei-k]: https://github.com/xuwei-k
  [@rochala]: https://github.com/rochala
  [@lervag]: https://github.com/lervag
  [@jroper]: https://github.com/jroper
  [@invadergir]: https://github.com/invadergir

Hi everyone. On behalf of the sbt project, I'm happy to announce that sbt 1.10.2 patch release is available. Full release note is here - https://github.com/sbt/sbt/releases/tag/v1.10.2

See [1.10.0 release note](/sbt-1.10.0) for the details on 1.10.x features.

<!--more-->

### How to upgrade

The sbt version used for your build must be upgraded by putting the following in `project/build.properties`:

```bash
sbt.version=1.10.2
```

This mechanism allows that sbt 1.10.2 is used only for the builds that you want.

Download **the official sbt runner** from SDKMAN, or download from <https://github.com/sbt/sbt/releases/tag/v1.10.2> to upgrade the `sbt` shell script and the launcher.

### Changes with compatibility implications

* Uses `_sbt2_3` suffix for sbt 2.x by [@eed3si9n][@eed3si9n] in [#7671](https://github.com/sbt/sbt/pull/7671)

### Bug fixes and updates

* Fixes the attribute key name from `serverIdleTimeOut` to  `serverIdleTimeout` to match the variable name by [@lervag][@lervag] in [#7651](https://github.com/sbt/sbt/pull/7651)
* Fixes incremental Scala-Java mixed compilation that produces JAR directly by by [@adpi2][@adpi2] in [zinc#1377](https://github.com/sbt/zinc/pull/1377)
* Fixes over-compilation when using a class directory as a library by [@adpi2][@adpi2] in [zinc#1382](https://github.com/sbt/zinc/pull/1382)
* Perf: Copy bytes directly instead of using `scala.reflect.io.Streamable` by [@rochala][@rochala] in [zinc#1395](https://github.com/sbt/zinc/pull/1395)
* Includes all sources and resources in source jar by [@jroper][@jroper] in [#7630](https://github.com/sbt/sbt/pull/7630)
* Fixes the handling of `Optional` inter-project dependency in BSP by [@adpi2][@adpi2] in [#7568](https://github.com/sbt/sbt/pull/7568)
* Trims spaces around k and v to tolerate extra whitespace in `build.properties` by [@invadergir][@invadergir] in [7585](https://github.com/sbt/sbt/pull/7585)
* Fixes legacy repositories like `scala-tools-releases` in `repositories` file blocking sbt from launching by [@eed3si9n][@eed3si9n] in [launcher#104](https://github.com/sbt/launcher/pull/104)
* Fixes stale BSP diagnostics by [#7610](https://github.com/sbt/sbt/pull/7610)
* Fixes scripted support for sbt 2.x by [@eed3si9n][@eed3si9n] in [#7672](https://github.com/sbt/sbt/pull/7672)
* Avoids using `ThreadDeath` for future JDK compatibility by [@xuwei-k][@xuwei-k] in [#7652](https://github.com/sbt/sbt/pull/7652)
* Avoids using `ZipError` for future JDK compatibility by [@eed3si9n][@eed3si9n] in [zinc#1393](https://github.com/sbt/zinc/pull/1393)

### Participation

sbt 1.10.2 was brought to you by nine contributors and one good bot. Eugene Yokota (eed3si9n), Scala Steward, Adrien Piquerez, redacted, Michael Sesterhenn, James Roper, Karl Yngve Lervåg, Kenji Yoshida (xuwei-k), Vasil Vasilev, rochala. Thanks!

Thanks to everyone who's helped improve sbt and Zinc by using them, reporting bugs, improving our documentation, porting builds, porting plugins, and submitting and reviewing pull requests.

For anyone interested in helping sbt, there are many avenues for you to help, depending on your interest. If you're interested, [Contributing](https://github.com/sbt/sbt/blob/develop/CONTRIBUTING.md), ["help wanted"](https://github.com/sbt/sbt/issues?q=is%3Aissue+is%3Aopen+label%3A%22help+wanted%22), ["good first issue"](https://github.com/sbt/sbt/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22), and [Discussions](https://github.com/sbt/sbt/discussions/) are good starting points.

----

### Donate to Scala Center

Scala Center is a non-profit center at EPFL to support education and open source.

- [The Scala Center Fundraising Campaign](https://scala-lang.org/blog/2023/09/11/scala-center-fundraising.html)
