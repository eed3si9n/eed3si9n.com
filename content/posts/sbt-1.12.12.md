---
title: "sbt 1.12.12"
type: story
date: 2026-06-14
url: /sbt-1.12.12
tags: [ "sbt" ]
build:
  list: never
---

The headline feature of sbt 1.12.12 is:

- Fix for console that references `java.sql` on JDK 9+

See also [1.12.0 release note](/sbt-1.12.0) for the details on 1.12.x features.

<!--more-->

Hi everyone. On behalf of the sbt project, I am happy to announce sbt 1.12.12. This is the twelfth feature release of sbt 1.x, a binary compatible release focusing on new features. sbt 1.x is released under Semantic Versioning, and the plugins are expected to work throughout the 1.x series. Please try it out, and report any issues you might come across.

### How to upgrade

The sbt version used for your build is upgraded by putting the following in `project/build.properties`:

```bash
sbt.version=1.12.12
```

This mechanism allows that sbt 1.12.12 is used only for the builds that you want.

Download **the official sbt runner** from SDKMAN, or download from <https://github.com/sbt/sbt/releases/tag/v1.12.12> to upgrade the `sbt` shell script and the launcher.

### 🐛 Bug fixes

* fix: Fixes console that references Java module classes on JDK 9+ by [@BrianHotopp][@BrianHotopp] in [#9327](https://github.com/sbt/sbt/pull/9327)
* fix: Fixes `sbt --version` to now show JDK warnings on JDK 25 by [@bitloi][@bitloi]  in [#8822](https://github.com/sbt/sbt/pull/8822)
* fix: Fixes stdout/stderr not displaying on sbtn by [@BrianHotopp][@BrianHotopp] in [#9265](https://github.com/sbt/sbt/pull/9265)
* fix: Ensure resources are copied atomically by [@anatoliykmetyuk][@anatoliykmetyuk] in [#9196](https://github.com/sbt/sbt/pull/9196)

### Participation

Thanks to everyone who's helped improve sbt and Zinc by using them, reporting bugs, improving our documentation, porting builds, porting plugins, and submitting and reviewing pull requests.

For anyone interested in helping sbt, there are many avenues for you to help, depending on your interest. If you're interested, [Contributing](https://github.com/sbt/sbt/blob/develop/CONTRIBUTING.md), ["help wanted"](https://github.com/sbt/sbt/issues?q=is%3Aissue+is%3Aopen+label%3A%22help+wanted%22), ["good first issue"](https://github.com/sbt/sbt/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22), and [Discussions](https://github.com/sbt/sbt/discussions/) are good starting points.

----

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
