---
title:       "sbt 1.9.2"
type:        story
date:        2023-07-06
url:         /sbt-1.9.2
tags:        [ "sbt" ]
---

Hi everyone. On behalf of the sbt project, I'm happy to announce sbt 1.9.2 patch release is available. Full release note is here - https://github.com/sbt/sbt/releases/tag/v1.9.2

See [1.9.0 release note](/sbt-1.9.0) for the details on 1.9.x features.

<!--more-->

### Updates

sbt 1.9.2 fixes cross building support `+` and `++` for mixed Scala patch versions.

sbt's stateful cross building has gone though several iterations:

- In sbt 1.0.0 we adopted [sbt-doge](https://github.com/sbt/sbt-doge) implementation, which inverted the ordering of subproject aggregation and Scala version switching to support having different Scala versions within a build.
- sbt-doge implementation was an improvement over sbt 0.13, but it was too lenient on `++`. For example, if a subproject `core` listed `Seq("2.13.11")` in `crossScalaVersions`, it would allow switching to Scala 2.13.1 using `++ 2.13.1`.
- In July, 2022 with [sbt 1.7.0](https://eed3si9n.com/sbt-1.7.0) `++` command became stricter. In addition to `++ 2.13.x` support, `++ 2.13.1` would no longer switch unless the subproject listed `"2.13.1"`.
- In most builds, sbt 1.7.0 behavior would be ok, but there are times where we need to intentionally have two subprojects use _different_ Scala versions. For example, a compiler plugin is published for Scala patch versions that it supports, which can depend on `core` library published one for Scala 2.12.x, 2.13.x, 3.x etc.
- To address this issue, sbt 1.9.2 now allows `++` to fall back to a binary compatible Scala version. For example, `++ 2.13.1` allows `core` subproject to fall back to 2.13.11 because Scala 2.13.x series maintains bidirectional binary compatibility.

This fix was contributed by [@eed3si9n][@eed3si9n] in [#7328][7328].

### Participation

Thanks to everyone who's helped improve sbt and Zinc by using them, reporting bugs, improving our documentation, porting builds, porting plugins, and submitting and reviewing pull requests.

For anyone interested in helping sbt, there are many avenues for you to help, depending on your interest. If you're interested, [Contributing](https://github.com/sbt/sbt/blob/develop/CONTRIBUTING.md), ["help wanted"](https://github.com/sbt/sbt/issues?q=is%3Aissue+is%3Aopen+label%3A%22help+wanted%22), ["good first issue"](https://github.com/sbt/sbt/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22), and [Discussions](https://github.com/sbt/sbt/discussions/) are good starting points.

### 🏳️‍🌈 Support Ukraine 🇺🇦

Forbidden Colours has started a fundraising campaign to support organisations in Poland, Hungary and Romania that are welcoming LGBTIQ+ refugees.

<https://www.forbidden-colours.com/2022/02/26/support-ukrainian-lgbtiq-refugees/>

### Donate to Scala Center

Scala Center is a non-profit center at EPFL to support education and open source.

- <https://scala.epfl.ch/donate.html>

  [@eed3si9n]: https://github.com/eed3si9n
  [7328]: https://github.com/sbt/sbt/pull/7328
