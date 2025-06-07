---
title:       "sbt 1.11.1"
type:        story
date:        2025-06-02
url:         /sbt-1.11.1
tags:        [ "sbt" ]
---

  [@eed3si9n]: https://github.com/eed3si9n
  [@adpi2]: https://github.com/adpi2
  [@dwijnand]: https://github.com/dwijnand
  [@xuwei-k]: https://github.com/xuwei-k
  [@mkurz]: https://github.com/mkurz
  [@mrdziuban]: https://github.com/mrdziuban
  [@rtyley]: https://github.com/rtyley

Hi everyone. On behalf of the sbt project, I'm happy to announce that sbt 1.11.1 patch release is available. Full release note is here - https://github.com/sbt/sbt/releases/tag/v1.11.1

See [1.11.0 release note](/sbt-1.11.0) for the details on 1.11.x features.

<!--more-->

### How to upgrade

The sbt version used for your build must be upgraded by putting the following in `project/build.properties`:

```bash
sbt.version=1.11.1
```

This mechanism allows that sbt 1.11.1 is used only for the builds that you want.

Download **the official sbt runner** from SDKMAN, or download from <https://github.com/sbt/sbt/releases/tag/v1.11.1> to upgrade the `sbt` shell script and the launcher.

### Changes with compatibility implications

* fix: sbt 1.11.1 changes the default `sbtPluginPublishLegacyMavenStyle` to `false` since Central Portal no longer accepts sbt plugin artifacts in the legacy style by [@eed3si9n][@eed3si9n] in [#8148](https://github.com/sbt/sbt/pull/8148). This means that any plugins published using sbt 1.11.1 requires sbt 1.9.0 and up.

### Bug fixes and updates

* fix: Fixes memory leak in `update` task by [@mrdziuban][@mrdziuban] in [sbt-coursier#563](https://github.com/coursier/sbt-coursier/pull/563)
* fix: Adds `sonaDeploymentName` to `excludeLintKeys` by [@rtyley][@rtyley] in [#8143](https://github.com/sbt/sbt/pull/8143)
* ci: Use Central Portal to publish sbt itself by [@eed3si9n][@eed3si9n] in [#8147](https://github.com/sbt/sbt/pull/8147)

### Happy Pride

In honor of sapphic, gay, bi, trans, non-binary, and queer contributors and members of Scala community <https://www.scala-sbt.org/> will be flying Progress Flag during this month:

![progress flag](/images/sbt-progress.png)

### Participation

Thanks to everyone who's helped improve sbt and Zinc by using them, reporting bugs, improving our documentation, porting builds, porting plugins, and submitting and reviewing pull requests.

For anyone interested in helping sbt, there are many avenues for you to help, depending on your interest. If you're interested, [Contributing](https://github.com/sbt/sbt/blob/develop/CONTRIBUTING.md), ["help wanted"](https://github.com/sbt/sbt/issues?q=is%3Aissue+is%3Aopen+label%3A%22help+wanted%22), ["good first issue"](https://github.com/sbt/sbt/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22), and [Discussions](https://github.com/sbt/sbt/discussions/) are good starting points.

----

### Donate to Scala Center

Scala Center is a non-profit center at EPFL to support education and open source.

- [The Scala Center Fundraising Campaign](https://scala-lang.org/blog/2023/09/11/scala-center-fundraising.html)
