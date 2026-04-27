---
title: "sbt 1.12.10"
type: story
date: 2026-04-27
url: /sbt-1.12.10
tags: [ "sbt" ]
---

The headline feature of sbt 1.12.10 is:

- Update to log4j 2.25.4, fixing CVE-2026-34477, CVE-2026-34478, CVE-2026-34479, and CVE-2026-34480
- Backport of eviction error in `Test` configuration

See also [1.12.0 release note](/sbt-1.12.0) for the details on 1.12.x features.

<!--more-->

Hi everyone. On behalf of the sbt project, I am happy to announce sbt 1.12.10. This is the twelfth feature release of sbt 1.x, a binary compatible release focusing on new features. sbt 1.x is released under Semantic Versioning, and the plugins are expected to work throughout the 1.x series. Please try it out, and report any issues you might come across.

### How to upgrade

The sbt version used for your build is upgraded by putting the following in `project/build.properties`:

```bash
sbt.version=1.12.10
```

This mechanism allows that sbt 1.12.10 is used only for the builds that you want.

Download **the official sbt runner** from SDKMAN, or download from <https://github.com/sbt/sbt/releases/tag/v1.12.10> to upgrade the `sbt` shell script and the launcher.

### Updates

* deps: Update log4j to 2.25.4, fixing CVE-2026-34477, CVE-2026-34478, CVE-2026-34479, and CVE-2026-34480 by [@dancewithheart] in [#9086](https://github.com/sbt/sbt/pull/9086)
* deps: Update Gigahorse to 0.9.4, which pulls in httpclient5 5.6.1 by [@eed3si9n] in [#9125](https://github.com/sbt/sbt/pull/9125)
* deps: Update sbtn to 2.0.0-RC13 by [@eed3si9n] in [#9139](https://github.com/sbt/sbt/pull/9139)
* Backport of eviction error in `Test` configuration by [@zainab-ali] in [#9102](https://github.com/sbt/sbt/pull/9102)

### 🐛 Bug fixes

* fix: Hide JDK warnings if JDK 26 or later by [@xuwei-k] in [#9068](https://github.com/sbt/sbt/pull/9068)
* fix: Fixes managedScalaInstance false support by [@eed3si9n] in [#9121](https://github.com/sbt/sbt/pull/9121)

### Participation

sbt 1.12.10 was brought to you by four contributors, according to `git shortlog -sn --group=author --group=trailer:co-authored-by --no-merges v1.12.9...`: Eugene Yokota (eed3si9n), Piotr Paradziński, Kenji Yoshida (xuwei-k), Zainab Ali. Thanks!

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
  [@dancewithheart]: https://github.com/dancewithheart
  [@zainab-ali]: https://github.com/zainab-ali
