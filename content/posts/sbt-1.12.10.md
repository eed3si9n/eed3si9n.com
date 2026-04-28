---
title: "sbt 1.12.10"
type: story
date: 2026-04-27
url: /sbt-1.12.10
tags: [ "sbt" ]
---

The headline feature of sbt 1.12.10 is:

- Update to log4j 2.25.4, fixing [CVE-2026-34477](https://github.com/advisories/GHSA-6hg6-v5c8-fphq), [CVE-2026-34478](https://github.com/advisories/GHSA-445c-vh5m-36rj), [CVE-2026-34479](https://github.com/advisories/GHSA-h383-gmxw-35v2), and [CVE-2026-34480](https://github.com/advisories/GHSA-3pxv-7cmr-fjr4)
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

### Eviction error in `Test` configuration

In sbt 1.12.10, eviction error extends to the `Test` configuration.

This means that `update` that previously worked might start to fail, especially for Scala Native project:

```bash
sbt:jawn-root> update
[error] stack trace is suppressed; run last parserNative / update for the full output
[error] (parserNative / update) found version conflict(s) in library dependencies; some are suspected to be binary incompatible:
[error]
[error]   * org.scala-native:test-interface_native0.5_2.12:0.5.11 (strict) is selected over 0.5.8 for test
[error]       +- org.typelevel:jawn-parser_native0.5_2.12:1.6.0-237-b6b4456-20260428T023336Z-SNAPSHOT (depends on 0.5.11)
[error]       +- org.scalacheck:scalacheck_native0.5_2.12:1.19.0    (depends on 0.5.8)
[error]
[error]
[error] this can be overridden using libraryDependencySchemes or evictionErrorLevel
```

To workaround the Scala Native issue, relax the constraint of `org.scala-native:test-interface` as follows:

```scala
ThisBuild / libraryDependencySchemes += "org.scala-native" %% "test-interface_native0.5" % VersionScheme.EarlySemVer
```

Alternatively, you can opt out of checking the `Test` configuration:

```scala
ThisBuild / evictionWarningOptions := (ThisBuild / evictionWarningOptions).value
  .withConfigurations(List(Compile))
```

This feature was contributed by [@calm329] and [@zainab-ali] in [#8451](https://github.com/sbt/sbt/pull/8451) + [#9102](https://github.com/sbt/sbt/pull/9102)

### Updates

* deps: Update log4j to 2.25.4, fixing [CVE-2026-34477](https://github.com/advisories/GHSA-6hg6-v5c8-fphq), [CVE-2026-34478](https://github.com/advisories/GHSA-445c-vh5m-36rj), [CVE-2026-34479](https://github.com/advisories/GHSA-h383-gmxw-35v2), and [CVE-2026-34480](https://github.com/advisories/GHSA-3pxv-7cmr-fjr4) by [@dancewithheart] in [#9086](https://github.com/sbt/sbt/pull/9086)
* deps: Update Gigahorse to 0.9.4, which pulls in httpclient5 5.6.1 by [@eed3si9n] in [#9125](https://github.com/sbt/sbt/pull/9125)
* deps: Update sbtn to 2.0.0-RC13 by [@eed3si9n] in [#9139](https://github.com/sbt/sbt/pull/9139)

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
  [@calm329]: https://github.com/calm329