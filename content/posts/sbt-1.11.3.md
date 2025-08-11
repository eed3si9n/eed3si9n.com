---
title:       "sbt 1.11.3"
type:        story
date:        2025-07-05
url:         /sbt-1.11.3
tags:        [ "sbt" ]
---

  [@eed3si9n]: https://github.com/eed3si9n
  [@adpi2]: https://github.com/adpi2
  [@dwijnand]: https://github.com/dwijnand
  [@xuwei-k]: https://github.com/xuwei-k
  [@mkurz]: https://github.com/mkurz
  [@guizmaii]: https://github.com/guizmaii
  [@unkarjedy]: https://github.com/unkarjedy
  [@inglor]: https://github.com/inglor

Hi everyone. On behalf of the sbt project, I'm happy to announce that sbt 1.11.3 patch release is available. Full release note is here - https://github.com/sbt/sbt/releases/tag/v1.11.3

See [1.11.0 release note](/sbt-1.11.0) for the details on 1.11.x features.

<!--more-->

### How to upgrade

The sbt version used for your build must be upgraded by putting the following in `project/build.properties`:

```bash
sbt.version=1.11.3
```

This mechanism allows that sbt 1.11.3 is used only for the builds that you want.

Download **the official sbt runner** from SDKMAN, or download from <https://github.com/sbt/sbt/releases/tag/v1.11.3> to upgrade the `sbt` shell script and the launcher.

### Bug fixes and updates

* Adds `sonaUploadRequestTimeout` setting to configure the upload timeout when publishing to the Central Repo by [@guizmaii][@guizmaii] in [#8171](https://github.com/sbt/sbt/pull/8171)
* fix: Adds support for `pluginCrossBuild/sbtBinaryVersion` "1.3", which is used by IntelliJ Scala plugin (fixes #8166) by [@unkarjedy][@unkarjedy] in [#8167](https://github.com/sbt/sbt/pull/8167)
* fix: Fixes the import order to satisfy SemanticDB by [@inglor][@inglor] in [#8162](https://github.com/sbt/sbt/pull/8162)

### Participation

sbt 1.11.3 was brought to you by four contributors. Jules Ivanic, Dmitrii Naumenko, Leonidas Spyropoulos, and Eugene Yokota (eed3si9n). Thanks!

Thanks to everyone who's helped improve sbt and Zinc by using them, reporting bugs, improving our documentation, porting builds, porting plugins, and submitting and reviewing pull requests.

For anyone interested in helping sbt, there are many avenues for you to help, depending on your interest. If you're interested, [Contributing](https://github.com/sbt/sbt/blob/develop/CONTRIBUTING.md), ["help wanted"](https://github.com/sbt/sbt/issues?q=is%3Aissue+is%3Aopen+label%3A%22help+wanted%22), ["good first issue"](https://github.com/sbt/sbt/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22), and [Discussions](https://github.com/sbt/sbt/discussions/) are good starting points.

----

### Donate to Scala Center

Scala Center is a non-profit center at EPFL to support education and open source.

- [The Scala Center Fundraising Campaign](https://scala-lang.org/blog/2023/09/11/scala-center-fundraising.html)
