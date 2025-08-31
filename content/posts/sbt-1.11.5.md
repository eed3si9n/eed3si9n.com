---
title:       "sbt 1.11.5"
type:        story
date:        2025-08-24
url:         /sbt-1.11.5
tags:        [ "sbt" ]
---

  [@eed3si9n]: https://github.com/eed3si9n
  [@adpi2]: https://github.com/adpi2
  [@dwijnand]: https://github.com/dwijnand
  [@xuwei-k]: https://github.com/xuwei-k
  [@mkurz]: https://github.com/mkurz
  [@hamzaremmal]: https://github.com/hamzaremmal
  [@unkarjedy]: https://github.com/unkarjedy
  [@jeanmarc]: https://github.com/jeanmarc

Hi everyone. On behalf of the sbt project, I'm happy to announce that sbt 1.11.5 patch release is available.

The headline features of sbt 1.11.5 are:

- Scala 3.8.0 (currently nightly) support
- Scala Nightly repository support
- Central Repository publishing improvements
- `sbt --jvm-client`
- sbtn improvements

Full release note is here - <https://github.com/sbt/sbt/releases/tag/v1.11.5>. See [1.11.0 release note](/sbt-1.11.0) for the details on 1.11.x features.

<!--more-->

### How to upgrade

The sbt version used for your build must be upgraded by putting the following in `project/build.properties`:

```bash
sbt.version=1.11.5
```

This mechanism allows that sbt 1.11.5 is used only for the builds that you want.

Download **the official sbt runner** from SDKMAN, or download from <https://github.com/sbt/sbt/releases/tag/v1.11.5> to upgrade the `sbt` shell script and the launcher.

### changes with compatibility implications

* sbtn is built using `ubuntu-22.04` image, which will require similar Linux version with glibc 2.32 and above.

### Scala Nightly repository

Scala Team now publishes nightlies to a dedicated Artifactory instance. sbt 1.11.5 adds a new resolver for this:

```scala
resolvers += Resolver.scalaNightlyRepository

ThisBuild / scalaVersion := "3.8.0-RC1-bin-20250823-712d5bc-NIGHTLY"
Compile / scalacOptions += "-language:experimental.captureChecking"
```

This was contributed by [Hamza Remmal][@hamzaremmal] at EPFL in [lm#532](https://github.com/sbt/librarymanagement/pull/532)

### Scala 3.8.0 support

Scala 3.8.0 will in-source the Scala standard library (`scala-library`) instead of using one from Scala 2.13. sbt 1.11.5 relaxes the Coursier same-version enforcement to support Scala 3.8.0.

This was pair programmed by [@hamzaremmal][@hamzaremmal] + [@eed3si9n][@eed3si9n] during Scala Days 2025 as [#8226](https://github.com/sbt/sbt/pull/8226)

### `sbt --jvm-client`

sbt 1.11.5 runner script adds new `--jvm-client` flag to launch the JVM version of the thin client. The implementation is the Scala code which sbtn is based on. This will be useful on platforms or CPU architectures that we do not build sbtn.

This was contributed by [@eed3si9n][@eed3si9n] in [#8232](https://github.com/sbt/sbt/pull/8232)

### 🚀 features and other updates

* Central Repository publishing: Shows validation errors if present by [@unkarjedy][@unkarjedy] in [#8191](https://github.com/sbt/sbt/pull/8191)
* Central Repository publishing: Includes the root subproject name into the deployment by [@jeanmarc][@jeanmarc] in [#8219](https://github.com/sbt/sbt/pull/8219)
* Reduces sbtn outputs by [@eed3si9n][@eed3si9n] in [#8234](https://github.com/sbt/sbt/pull/8234)

### Participation

sbt 1.11.5 was brought to you by four contributors and two good bots. Eugene Yokota (eed3si9n), Hamza Remmal, Scala Steward, Dmitrii Naumenko, JeanMarc van Leerdam, dependabot. Thanks!

Thanks to everyone who's helped improve sbt and Zinc by using them, reporting bugs, improving our documentation, porting builds, porting plugins, and submitting and reviewing pull requests.

For anyone interested in helping sbt, there are many avenues for you to help, depending on your interest. If you're interested, [Contributing](https://github.com/sbt/sbt/blob/develop/CONTRIBUTING.md), ["help wanted"](https://github.com/sbt/sbt/issues?q=is%3Aissue+is%3Aopen+label%3A%22help+wanted%22), ["good first issue"](https://github.com/sbt/sbt/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22), and [Discussions](https://github.com/sbt/sbt/discussions/) are good starting points.

----

### FYI - Scala Days talk slides

I gave a talk in Scala Days this week about sbt 2.0. Here is the [slide deck](https://www.slideshare.net/slideshow/sbt-2-0-go-big-scala-days-2025-edition/282592302).

### Donate to Scala Center

Scala Center is a non-profit center at EPFL to support education and open source.

- [The Scala Center Fundraising Campaign](https://scala-lang.org/blog/2023/09/11/scala-center-fundraising.html)
