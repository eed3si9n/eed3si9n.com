---
title:       "sbt 1.11.4"
type:        story
date:        2025-08-04
url:         /sbt-1.11.4
tags:        [ "sbt" ]
---

  [@eed3si9n]: https://github.com/eed3si9n
  [@adpi2]: https://github.com/adpi2
  [@dwijnand]: https://github.com/dwijnand
  [@xuwei-k]: https://github.com/xuwei-k
  [@mkurz]: https://github.com/mkurz

Hi everyone. On behalf of the sbt project, I'm happy to announce that sbt 1.11.4 patch release is available. Full release note is here - https://github.com/sbt/sbt/releases/tag/v1.11.4

See [1.11.0 release note](/sbt-1.11.0) for the details on 1.11.x features.

<!--more-->

### How to upgrade

The sbt version used for your build must be upgraded by putting the following in `project/build.properties`:

```bash
sbt.version=1.11.4
```

This mechanism allows that sbt 1.11.4 is used only for the builds that you want.

Download **the official sbt runner** from SDKMAN, or download from <https://github.com/sbt/sbt/releases/tag/v1.11.4> to upgrade the `sbt` shell script and the launcher.

### Bug fixes and updates

* fix: Fixes sbt plugin cross building by [@eed3si9n][@eed3si9n] in [lm#528](https://github.com/sbt/librarymanagement/pull/528)
* fix: Fixes `sonaUploadRequestTimeout` by scoping it globally by [@eed3si9n][@eed3si9n] in [#8190](https://github.com/sbt/sbt/pull/8190)

### Participation

Thanks to everyone who's helped improve sbt and Zinc by using them, reporting bugs, improving our documentation, porting builds, porting plugins, and submitting and reviewing pull requests.

For anyone interested in helping sbt, there are many avenues for you to help, depending on your interest. If you're interested, [Contributing](https://github.com/sbt/sbt/blob/develop/CONTRIBUTING.md), ["help wanted"](https://github.com/sbt/sbt/issues?q=is%3Aissue+is%3Aopen+label%3A%22help+wanted%22), ["good first issue"](https://github.com/sbt/sbt/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22), and [Discussions](https://github.com/sbt/sbt/discussions/) are good starting points.

----

### Donate to Scala Center

Scala Center is a non-profit center at EPFL to support education and open source.

- [The Scala Center Fundraising Campaign](https://scala-lang.org/blog/2023/09/11/scala-center-fundraising.html)
