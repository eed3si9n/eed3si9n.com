---
title:       "sbt 1.10.5"
type:        story
date:        2024-11-03
url:         /sbt-1.10.5
tags:        [ "sbt" ]
---

  [@eed3si9n]: https://github.com/eed3si9n
  [@adpi2]: https://github.com/adpi2
  [@xuwei-k]: https://github.com/xuwei-k
  [@Friendseeker]: https://github.com/Friendseeker
  [@raboof]: https://github.com/raboof

Hi everyone. On behalf of the sbt project, I'm happy to announce that sbt 1.10.5 patch release is available. Full release note is here - https://github.com/sbt/sbt/releases/tag/v1.10.5

See [1.10.0 release note](/sbt-1.10.0) for the details on 1.10.x features.

### Highlights

- Updates to Coursier 2.1.14 via lm-coursier 2.1.5
- Fixes to sbtn

<!--more-->

### How to upgrade

The sbt version used for your build must be upgraded by putting the following in `project/build.properties`:

```bash
sbt.version=1.10.5
```

This mechanism allows that sbt 1.10.5 is used only for the builds that you want.

Download **the official sbt runner** from SDKMAN, or download from <https://github.com/sbt/sbt/releases/tag/v1.10.5> to upgrade the `sbt` shell script and the launcher.

### Coursier 2.1.14 and lm-coursier 2.1.5

sbt 1.10.5 updates the library management engine to lm-coursier 2.1.5, which uses Coursier 2.1.14. There's been a few contributions from the sbt maintainers and plugin authors:

* Fixes license information forwarding by [@raboof][@raboof] in [sbt-coursier#507](https://github.com/coursier/sbt-coursier/pull/507)
* Fixes ejb package handling by [@eed3si9n][@eed3si9n] in [coursier#3041](https://github.com/coursier/coursier/pull/3041)
* Fixes dependency resolution of sbt plugins by [@adpi2][@adpi2] in [coursier#3088](https://github.com/coursier/coursier/pull/3088)

### Bug fixes and updates

* fix: Reverts sbtn to using glibc by [@Friendseeker][@Friendseeker] and [@eed3si9n][@eed3si9n]
* fix: Fixes sbtn to return exit code `1` on error by [@Friendseeker][@Friendseeker] in [#7854](https://github.com/sbt/sbt/pull/7854)
* fix: Fixes `++` with a command argument with slash by [@eed3si9n][@eed3si9n] in [#7862](https://github.com/sbt/sbt/pull/7862)
* fix: Replaces Narrow No-Break Space (NNBS) in date strings with a whitespace to prevent mojibakeh by [@Friendseeker][@Friendseeker] in [#7846](https://github.com/sbt/sbt/pull/7846)

### Participation

Thanks to everyone who's helped improve sbt and Zinc by using them, reporting bugs, improving our documentation, porting builds, porting plugins, and submitting and reviewing pull requests.

For anyone interested in helping sbt, there are many avenues for you to help, depending on your interest. If you're interested, [Contributing](https://github.com/sbt/sbt/blob/develop/CONTRIBUTING.md), ["help wanted"](https://github.com/sbt/sbt/issues?q=is%3Aissue+is%3Aopen+label%3A%22help+wanted%22), ["good first issue"](https://github.com/sbt/sbt/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22), and [Discussions](https://github.com/sbt/sbt/discussions/) are good starting points.

----

### Donate to Scala Center

Scala Center is a non-profit center at EPFL to support education and open source.

- [The Scala Center Fundraising Campaign](https://scala-lang.org/blog/2023/09/11/scala-center-fundraising.html)
