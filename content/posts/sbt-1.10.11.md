---
title:       "sbt 1.10.11"
type:        story
date:        2025-03-17
url:         /sbt-1.10.11
tags:        [ "sbt" ]
---

  [@eed3si9n]: https://github.com/eed3si9n
  [@adpi2]: https://github.com/adpi2
  [@xuwei-k]: https://github.com/xuwei-k
  [@Friendseeker]: https://github.com/Friendseeker

Hi everyone. On behalf of the sbt project, I'm happy to announce that sbt 1.10.11 patch release is available. Full release note is here - <https://github.com/sbt/sbt/releases/tag/v1.10.11>.

See [1.10.0 release note](/sbt-1.10.0) for the details on 1.10.x features.

### Highlights

- Fixes compiler crashes causing the compilation to retry 10 times
- `sbt --client shutdown` short-circuit
- Coursier retry on Windows file system limitation

<!--more-->

### How to upgrade

The sbt version used for your build must be upgraded by putting the following in `project/build.properties`:

```bash
sbt.version=1.10.11
```

This mechanism allows that sbt 1.10.11 is used only for the builds that you want.

Download **the official sbt runner** from SDKMAN, or download from <https://github.com/sbt/sbt/releases/tag/v1.10.11> to upgrade the `sbt` shell script and the launcher.

### Bug fixes and updates

* Updates Coursier from 2.1.22 → 2.1.23 by [@eed3si9n][@eed3si9n] in [#8069](https://github.com/sbt/sbt/pull/8069)
* fix: Fixes `compile` task retrying itself on compiler crashes by [@eed3si9n][@eed3si9n] in [#8070](https://github.com/sbt/sbt/pull/8070)
* fix: `sbt --client shutdown` short-circuits if the server is not already running by [@eed3si9n][@eed3si9n] in [#8057](https://github.com/sbt/sbt/pull/8057)
* fix: Fixes `sbt --client` on Windows by [@eed3si9n][@eed3si9n] in [#8071](https://github.com/sbt/sbt/pull/8071)
* fix: Avoids creating target on `sbt --version` by [@eed3si9n][@eed3si9n] in [#8066](https://github.com/sbt/sbt/pull/8066)
* fix: Fixes slash syntax keys in Scala 2.13 evolution message by [@eed3si9n][@eed3si9n] in [#8067](https://github.com/sbt/sbt/pull/8067)

### Participation

Thanks to everyone who's helped improve sbt and Zinc by using them, reporting bugs, improving our documentation, porting builds, porting plugins, and submitting and reviewing pull requests.

For anyone interested in helping sbt, there are many avenues for you to help, depending on your interest. If you're interested, [Contributing](https://github.com/sbt/sbt/blob/develop/CONTRIBUTING.md), ["help wanted"](https://github.com/sbt/sbt/issues?q=is%3Aissue+is%3Aopen+label%3A%22help+wanted%22), ["good first issue"](https://github.com/sbt/sbt/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22), and [Discussions](https://github.com/sbt/sbt/discussions/) are good starting points.

----

### Donate to Scala Center

Scala Center is a non-profit center at EPFL to support education and open source.

- [The Scala Center Fundraising Campaign](https://scala-lang.org/blog/2023/09/11/scala-center-fundraising.html)
