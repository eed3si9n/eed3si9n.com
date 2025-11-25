---
title: "sbt 1.12.0-M2"
type: story
date: 2025-11-25
url: /sbt-1.12.0-M2
tags: [ "sbt" ]
---

  [@eed3si9n]: https://github.com/eed3si9n
  [@adpi2]: https://github.com/adpi2
  [@dwijnand]: https://github.com/dwijnand
  [@xuwei-k]: https://github.com/xuwei-k
  [@mrdziuban]: https://github.com/mrdziuban

Hi everyone. On behalf of the sbt project, I am happy to announce sbt 1.12.0-M2. This is the twelfth feature release of sbt 1.x, a binary compatible release focusing on new features. sbt 1.x is released under Semantic Versioning, and the plugins are expected to work throughout the 1.x series. Please try it out, and report any issues you might come across.

The headline features of sbt 1.12.0 are:

- Scala 3.8 REPL support

Full release note is here - <https://github.com/sbt/sbt/releases/tag/v1.12.0-M2>

<!--more-->

### How to upgrade

The sbt version used for your build is upgraded by putting the following in `project/build.properties`:

```bash
sbt.version=1.12.0-M2
```

This mechanism allows that sbt 1.12.0-M2 is used only for the builds that you want.

### Scala 3.8 REPL

sbt 1.12.0 adds Scala 3.8 REPL support. Scala 3.8, which is currently available as a RC1, is planned to split its REPL into a separate artifact from the compiler.

```scala
ThisBuild / scalaVersion := "3.8.0-RC1"

// Uncomment for a nightly
// resolvers += Resolver.scalaNightlyRepository
```

To adjust to this change, sbt 1.12.0 adds a new sandbox configuration to resolve `scala3-repl`, which then is funneled to a classloader used by the `console` task. This was contributed by Eugene in [zinc#1612](https://github.com/sbt/zinc/pull/1612) and [#8349](https://github.com/sbt/sbt/pull/8349).

### JAR-less scala3_library

Scala 3.8 in-sources the standard library into scala/scala3 repository, so there's no need for `scala3_library` to publish JAR files, however, doing so causes "Missing scala3-library jar file" error. sbt 1.12.0 adds support for JAR-less `scala3_library` artifact. This was contributed by Hamza Remmal at EPFL in [#8387](https://github.com/sbt/sbt/pull/8387).

### Other changes

* Fixes `*.sbt` parsing to support `-Xsource:3` syntax in by [@eed3si9n][@eed3si9n] in [8368](https://github.com/sbt/sbt/pull/8368)
* Increases Protobuf recursion limit used to persist Zinc Analysis to 200 (default is 100) by [@mrdziuban][@mrdziuban] in [zinc#1606](https://github.com/sbt/zinc/pull/1606)
* Updates `semanticdbVersion` to 4.14.1 by [@xuwei-k][@xuwei-k] in [#8342](https://github.com/sbt/sbt/pull/8342)

### Participation

Thanks to everyone who's helped improve sbt and Zinc by using them, reporting bugs, improving our documentation, porting builds, porting plugins, and submitting and reviewing pull requests.

For anyone interested in helping sbt, there are many avenues for you to help, depending on your interest. If you're interested, [Contributing](https://github.com/sbt/sbt/blob/develop/CONTRIBUTING.md), ["help wanted"](https://github.com/sbt/sbt/issues?q=is%3Aissue+is%3Aopen+label%3A%22help+wanted%22), ["good first issue"](https://github.com/sbt/sbt/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22), and [Discussions](https://github.com/sbt/sbt/discussions/) are good starting points.

----

### Donate to Scala Center

Scala Center is a non-profit center at EPFL to support education and open source.

- [The Scala Center Fundraising Campaign](https://scala-lang.org/blog/2023/09/11/scala-center-fundraising.html)
