---
title:       "sbt 1.10.1"
type:        story
date:        2024-07-07
url:         /sbt-1.10.1
tags:        [ "sbt" ]
---

  [@eed3si9n]: https://github.com/eed3si9n
  [@adpi2]: https://github.com/adpi2
  [@dwijnand]: https://github.com/dwijnand
  [@xuwei-k]: https://github.com/xuwei-k
  [@mdedetrich]: https://github.com/mdedetrich
  [@mkurz]: https://github.com/mkurz
  [@desbo]: https://github.com/desbo
  [@steinybot]: https://github.com/steinybot
  [@szeiger]: https://github.com/szeiger
  [@vasilmkd]: https://github.com/vasilmkd

Hi everyone. On behalf of the sbt project, I'm happy to announce that sbt 1.10.1 patch release is available. Full release note is here - https://github.com/sbt/sbt/releases/tag/v1.10.1

See [1.10.0 release note](/sbt-1.10.0) for the details on 1.10.x features.

<!--more-->

### How to upgrade

The sbt version used for your build must be upgraded by putting the following in `project/build.properties`:

```bash
sbt.version=1.10.1
```

This mechanism allows that sbt 1.10.1 is used only for the builds that you want.

Download **the official sbt runner** from SDKMAN, or download from <https://github.com/sbt/sbt/releases/tag/v1.10.1> to upgrade the `sbt` shell script and the launcher.

### Bug fixes and updates

* Fixes column/position information missing from the javac error messages in IntelliJ by [@vasilmkd][@vasilmkd] in [zinc#1373](https://github.com/sbt/zinc/pull/1373) / [SCL-22799](https://youtrack.jetbrains.com/issue/SCL-22799/Missing-Line-and-Column-Info-in-Compilation-Error-Message-for-Java-SBT-project)
* Fixes backslash handling in `expandMavenSettings` by [@desbo][@desbo] in [lm#444](https://github.com/sbt/librarymanagement/pull/444)
* Fixes JSON serialization of `Map` and `LList` in sjson-new 0.10.1 by [@steinybot][@steinybot] + [@eed3si9n][@eed3si9n] in [sjson-new#142](https://github.com/eed3si9n/sjson-new/pull/142)
* Fixes the hash code for empty files in the classpath cache by [@szeiger][@szeiger] in [zinc#1366](https://github.com/sbt/zinc/pull/1366)
* Fixes `forceUpdatePeriod` by [@adpi2][@adpi2] in [sbt#7567](https://github.com/sbt/sbt/pull/7567)
* Fixes BSP handling of `Optional` inter-project dependencies by [@adpi2][@adpi2] in [sbt#7568](https://github.com/sbt/sbt/pull/7568)
* Ignores `jcenter` and `scala-tools-releases` entries in the `~/.sbt/repositories` file by [@eed3si9n][@eed3si9n] in [launcher#104](https://github.com/sbt/launcher/pull/104)

### PSA: sbt/setup-sbt

GitHub Actions' runner images have long installed `sbt` by default, but they have stopped that for newer images like macOS 13, macOS 14, and `ubuntu-24.04`. To workaround this issue, we have created a custom GitHub Action that installs `sbt` runner script:

```yaml
- name: Setup JDK
  uses: actions/setup-java@v4
  with:
    distribution: temurin
    java-version: 17
    cache: sbt
- uses: sbt/setup-sbt@v1
```

See [setup-sbt GitHub Action](/setup-sbt) for more details.

### Participation

sbt 1.10.1 was brought to you by nine contributors and two good bots. Eugene Yokota (eed3si9n), Vasil Vasilev, Adrien Piquerez, Scala Steward, Seth Tisue, Jason Pickens, João Ferreira, Matthias Kurz, Sam Desborough, Stefan Zeiger, dependabot. Thanks!

Thanks to everyone who's helped improve sbt and Zinc by using them, reporting bugs, improving our documentation, porting builds, porting plugins, and submitting and reviewing pull requests.

For anyone interested in helping sbt, there are many avenues for you to help, depending on your interest. If you're interested, [Contributing](https://github.com/sbt/sbt/blob/develop/CONTRIBUTING.md), ["help wanted"](https://github.com/sbt/sbt/issues?q=is%3Aissue+is%3Aopen+label%3A%22help+wanted%22), ["good first issue"](https://github.com/sbt/sbt/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22), and [Discussions](https://github.com/sbt/sbt/discussions/) are good starting points.

----

### Donate to Scala Center

Scala Center is a non-profit center at EPFL to support education and open source.

- [The Scala Center Fundraising Campaign](https://scala-lang.org/blog/2023/09/11/scala-center-fundraising.html)
