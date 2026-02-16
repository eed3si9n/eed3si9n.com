---
title: "sbt 1.12.3"
type: story
date: 2026-02-14
url: /sbt-1.12.3
tags: [ "sbt" ]
---

Hi everyone. On behalf of the sbt project, I am happy to announce sbt 1.12.3. This is the twelfth feature release of sbt 1.x, a binary compatible release focusing on new features. sbt 1.x is released under Semantic Versioning, and the plugins are expected to work throughout the 1.x series. Please try it out, and report any issues you might come across.

The headline feature of sbt 1.12.3 is:

- restoration of scala-reflect alignment
- backports of runner script fixes

See also [1.12.0 release note](/sbt-1.12.0) for the details on 1.12.x features.

<!--more-->

### How to upgrade

The sbt version used for your build is upgraded by putting the following in `project/build.properties`:

```bash
sbt.version=1.12.3
```

This mechanism allows that sbt 1.12.3 is used only for the builds that you want.

Download **the official sbt runner** from SDKMAN, or download from <https://github.com/sbt/sbt/releases/tag/v1.12.3> to upgrade the `sbt` shell script and the launcher.

### Smørrebrød - the end of Scala 2.13-3.x sandwich

Until recently Scala 2.13 and Scala 3.x releases have maintained a bilateral interoperability, built on top of common Scala standard library (`scala-library`), and implementing TASTy reader and Pickle reader on each side. To take advantage of this compatibility sbt 1.5.0 introduced `.cross(CrossVersion.for2_13Use3)` etc to allow Scala 3.x libraries to be mixed into the Scala 2.13 dependency graph.

The interoperability has become [one-way only](https://contributors.scala-lang.org/t/sbt-1-12-1-and-unmoored-scala-reflect-scala-compiler-issue/7376/7) in Scala 3.8.1, which releases its own `scala-library`, and generally inclined to move forward with its own standard library in the future. This means that 3.x libraries and subprojects that were compiled using Scala 3.8+ can no longer be included into Scala 2.13 subprojects.

Doing so often results in a `scala-reflect` not found error, since `scala-reflect` is not published for Scala 3.8+. This is because sbt (correctly) tries to align `scala-library`, `scala-reflect`, and `scala-compiler` versions. sbt 1.12.3 restores this behavior that was broken in sbt 1.12.2, and displays a specific warning when `scala-reflect` not found is detected.

To fix this, either
- Keep Scala 3 subproject or transitive dependency to 3.7 or below, or
- Migrate the Scala 2.13 subproject to Scala 3.x

This was contributed by [@calm329][@calm329] and [@eed3si9n][@eed3si9n] in [#8707](ttps://github.com/sbt/sbt/pull/8707) and [#8733](https://github.com/sbt/sbt/pull/8733).

### Other changes

* fix/bport: Restore runner precedence over `.sbtopts` by [@it-education-md][@it-education-md] in [#8695](https://github.com/sbt/sbt/pull/8695)
* fix/bport: Handle JVM parameters with spaces in dot files by [@Eruis2579][@Eruis2579] in [#8730](https://github.com/sbt/sbt/pull/8730)
* fix/bport: Handle `--script-version` sbt 2.x project dirs by [@Eruis2579][@Eruis2579] in [#8715](https://github.com/sbt/sbt/pull/8715)
* fix/bport: Handle `--version` in sbt 2.x project dirs by [@it-education-md][@it-education-md] in [#8735](https://github.com/sbt/sbt/pull/8735)

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
  [@Eruis2579]: https://github.com/Eruis2579
  [@it-education-md]: https://github.com/it-education-md
