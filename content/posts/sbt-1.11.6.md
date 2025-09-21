---
title:       "sbt 1.11.6"
type:        story
date:        2025-09-06
url:         /sbt-1.11.6
tags:        [ "sbt" ]
---

  [@eed3si9n]: https://github.com/eed3si9n
  [@adpi2]: https://github.com/adpi2
  [@dwijnand]: https://github.com/dwijnand
  [@xuwei-k]: https://github.com/xuwei-k
  [@azdrojowa123]: https://github.com/azdrojowa123

Hi everyone. On behalf of the sbt project, I'm happy to announce that sbt 1.11.6 patch release is available.

The headline features of sbt 1.11.6 are:

- Launcher 1.5.0
- Internal dependency classpath fix
- sbtn client-side run fix

Full release note is here - <https://github.com/sbt/sbt/releases/tag/v1.11.6>. See [1.11.0 release note](/sbt-1.11.0) for the details on 1.11.x features.

<!--more-->

### How to upgrade

The sbt version used for your build must be upgraded by putting the following in `project/build.properties`:

```bash
sbt.version=1.11.6
```

This mechanism allows that sbt 1.11.5 is used only for the builds that you want.

Download **the official sbt runner** from SDKMAN, or download from <https://github.com/sbt/sbt/releases/tag/v1.11.6> to upgrade the `sbt` shell script and the launcher.

### 🚀 Launcher 1.5.0

sbt 1.11.6 ships with Launcher 1.5.0, ported to Scala 3.

* Update launcher code base to to Scala 3.7.2 by [@eed3si9n][@eed3si9n] in [sbt/launcher#126](https://github.com/sbt/launcher/pull/126)
* refactor: Adds `-Xsource:3` option by [@xuwei-k][@xuwei-k] in [sbt/launcher#117](https://github.com/sbt/launcher/pull/117)
* deps: Removes Apache Ivy dependency from launcher by [@eed3si9n][@eed3si9n] in [sbt/launcher#127](https://github.com/sbt/launcher/pull/127)

### 🐛 bug fixes

* fix: Fixes internal dependency classpath by [@azdrojowa123][@azdrojowa123] in [#8257](https://github.com/sbt/sbt/pull/8257)
* fix: Fixes sbtn client-side run on JDK 8 by [@eed3si9n][@eed3si9n] in [#8259](https://github.com/sbt/sbt/pull/8259)

### Participation

sbt 1.11.6 was brought to you by four contributors and one good bot. Eugene Yokota (eed3si9n), Kenji Yoshida (xuwei-k), Aleksandra Zdrojowa, Matthias Kurz, and dependabot. Thanks!

Thanks to everyone who's helped improve sbt and Zinc by using them, reporting bugs, improving our documentation, porting builds, porting plugins, and submitting and reviewing pull requests.

For anyone interested in helping sbt, there are many avenues for you to help, depending on your interest. If you're interested, [Contributing](https://github.com/sbt/sbt/blob/develop/CONTRIBUTING.md), ["help wanted"](https://github.com/sbt/sbt/issues?q=is%3Aissue+is%3Aopen+label%3A%22help+wanted%22), ["good first issue"](https://github.com/sbt/sbt/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22), and [Discussions](https://github.com/sbt/sbt/discussions/) are good starting points.

----

### FYI - Scala Days talk slides

I gave a talk in Scala Days this week about sbt 2.0. Here is the [slide deck](https://www.slideshare.net/slideshow/sbt-2-0-go-big-scala-days-2025-edition/282592302).

### Donate to Scala Center

Scala Center is a non-profit center at EPFL to support education and open source.

- [The Scala Center Fundraising Campaign](https://scala-lang.org/blog/2023/09/11/scala-center-fundraising.html)
