---
title: "sbt 1.12.11"
type: story
date: 2026-05-02
url: /sbt-1.12.11
tags: [ "sbt" ]
---

The headline feature of sbt 1.12.11 is:

- Rollback eviction error in `Test`

See also [1.12.0 release note](/sbt-1.12.0) for the details on 1.12.x features.

<!--more-->

Hi everyone. On behalf of the sbt project, I am happy to announce sbt 1.12.11. This is the twelfth feature release of sbt 1.x, a binary compatible release focusing on new features. sbt 1.x is released under Semantic Versioning, and the plugins are expected to work throughout the 1.x series. Please try it out, and report any issues you might come across.

### Eviction error in `Test` configuration

sbt 1.12.11 rolls back the eviction error in `Test` configuration since it breaks Scala Native builds due to [scala-native#4844](https://github.com/scala-native/scala-native/issues/4844).


You can opt into eviction error in `Test` configuration as follows:

```scala
ThisBuild / evictionWarningOptions ~= (_.withConfigurations(List(Compile, Test)))
```

To workaround the Scala Native issue, relax the constraint of `org.scala-native:test-interface` as follows:

```scala
ThisBuild / libraryDependencySchemes += "org.scala-native" %% "test-interface_native0.5" % VersionScheme.EarlySemVer
```

### How to upgrade

The sbt version used for your build is upgraded by putting the following in `project/build.properties`:

```bash
sbt.version=1.12.11
```

This mechanism allows that sbt 1.12.10 is used only for the builds that you want.

Download **the official sbt runner** from SDKMAN, or download from <https://github.com/sbt/sbt/releases/tag/v1.12.11> to upgrade the `sbt` shell script and the launcher.

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
  [@dancewithheart]: https://github.com/dancewithheart
  [@zainab-ali]: https://github.com/zainab-ali
  [@calm329]: https://github.com/calm329