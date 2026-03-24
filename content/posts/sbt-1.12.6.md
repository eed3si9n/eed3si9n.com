---
title: "sbt 1.12.6"
type: story
date: 2026-03-15
url: /sbt-1.12.6
tags: [ "sbt" ]
---

The headline feature of sbt 1.12.6 is:

- Coursier 2.12.25-M24 update
- log4j 2.25.3 update

See also [1.12.0 release note](/sbt-1.12.0) for the details on 1.12.x features.

<!--more-->

Hi everyone. On behalf of the sbt project, I am happy to announce sbt 1.12.6. This is the twelfth feature release of sbt 1.x, a binary compatible release focusing on new features. sbt 1.x is released under Semantic Versioning, and the plugins are expected to work throughout the 1.x series. Please try it out, and report any issues you might come across.

### How to upgrade

The sbt version used for your build is upgraded by putting the following in `project/build.properties`:

```bash
sbt.version=1.12.6
```

This mechanism allows that sbt 1.12.6 is used only for the builds that you want.

Download **the official sbt runner** from SDKMAN, or download from <https://github.com/sbt/sbt/releases/tag/v1.12.6> to upgrade the `sbt` shell script and the launcher.

### Updates

* deps: Update lm-coursier to 2.1.12 (Coursier 2.12.25-M24) by [@majk-p][@majk-p] in [#8902](https://github.com/sbt/sbt/pull/8902)
* feat: Retry on HTTP 5xx during dependency resolution by [@majk-p][@majk-p] in [sbt-coursier#601](https://github.com/coursier/sbt-coursier/pull/601)
* deps: Update log4j to 2.25.3 by [@eed3si9n][@eed3si9n] in [#8872](https://github.com/sbt/sbt/pull/8872)
* deps: Update `semanticdbVersion` in SemanticdbPlugin.scala by [@xuwei-k][@xuwei-k] in [#8885](https://github.com/sbt/sbt/pull/8885)

### Participation

Thanks to everyone who's helped improve sbt and Zinc by using them, reporting bugs, improving our documentation, porting builds, porting plugins, and submitting and reviewing pull requests.

For anyone interested in helping sbt, there are many avenues for you to help, depending on your interest. If you're interested, [Contributing](https://github.com/sbt/sbt/blob/develop/CONTRIBUTING.md), ["help wanted"](https://github.com/sbt/sbt/issues?q=is%3Aissue+is%3Aopen+label%3A%22help+wanted%22), ["good first issue"](https://github.com/sbt/sbt/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22), and [Discussions](https://github.com/sbt/sbt/discussions/) are good starting points.

----

### Donate to Scala Center

Scala Center is a non-profit center at EPFL to support education and open source.

- [The Scala Center Fundraising Campaign](https://scala-lang.org/blog/2023/09/11/scala-center-fundraising.html)

  [@eed3si9n]: https://github.com/eed3si9n
  [@adpi2]: https://github.com/adpi2
  [@dwijnand]: https://github.com/dwijnand
  [@xuwei-k]: https://github.com/xuwei-k
  [@mrdziuban]: https://github.com/mrdziuban
  [@azdrojowa123]: https://github.com/azdrojowa123
  [@calm329]: https://github.com/calm329
  [@MkDev11]: https://github.com/MkDev11
  [@eureka928]: https://github.com/eureka928
  [@majk-p]: https://github.com/majk-p
