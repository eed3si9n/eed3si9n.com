---
title:       "sbt 1.9.8"
type:        story
date:        2023-12-13
url:         /sbt-1.9.8
tags:        [ "sbt" ]
---

Hi everyone. On behalf of the sbt project, I'm happy to announce sbt 1.9.8 patch release is available. Full release note is here - https://github.com/sbt/sbt/releases/tag/v1.9.8

See [1.9.0 release note](/sbt-1.9.0) for the details on 1.9.x features.

### Highlights

- Fixes `IO.getModifiedOrZero` on Alpine etc, by using clib `stat()` instead of non-standard `__xstat64` abi by [@bratkartoffel][@bratkartoffel] in [io#362][io362]

<!--more-->

### How to upgrade

The sbt version used for your build must be upgraded by putting the following in `project/build.properties`:

```bash
sbt.version=1.9.8
```

This mechanism allows that sbt 1.9.8 is used only for the builds that you want.

Download **the official sbt runner** from, `cs setup`, SDKMAN, or download from <https://github.com/sbt/sbt/releases/tag/v1.9.8> to upgrade the `sbt` shell script and the launcher.

## Other updates and fixes

- As a temporary fix for JLine issue, this disables vi-style effects inside emacs by [@hvesalai][@hvesalai] in [#7420][7420]
- Backports fix for `updateSbtClassifiers` not downloading sources [#7437][7437] by [@azdrojowa123][@azdrojowa123]
- Backports missing logger methods that take Java Supplier [#7447][7447] by [@mkurz][@mkurz]

### Participation

Thanks to everyone who's helped improve sbt and Zinc by using them, reporting bugs, improving our documentation, porting builds, porting plugins, and submitting and reviewing pull requests.

For anyone interested in helping sbt, there are many avenues for you to help, depending on your interest. If you're interested, [Contributing](https://github.com/sbt/sbt/blob/develop/CONTRIBUTING.md), ["help wanted"](https://github.com/sbt/sbt/issues?q=is%3Aissue+is%3Aopen+label%3A%22help+wanted%22), ["good first issue"](https://github.com/sbt/sbt/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22), and [Discussions](https://github.com/sbt/sbt/discussions/) are good starting points.

----

### Donate to Scala Center

Scala Center is a non-profit center at EPFL to support education and open source.

- [The Scala Center Fundraising Campaign](https://scala-lang.org/blog/2023/09/11/scala-center-fundraising.html)

  [@eed3si9n]: https://github.com/eed3si9n
  [@adpi2]: https://github.com/adpi2
  [@xuwei-k]: https://github.com/xuwei-k
  [@mdedetrich]: https://github.com/mdedetrich
  [@mkurz]: https://github.com/mkurz
  [@bratkartoffel]: https://github.com/bratkartoffel
  [@hvesalai]: https://github.com/hvesalai
  [@azdrojowa123]: https://github.com/azdrojowa123
  [io362]: https://github.com/sbt/io/pull/362
  [7420]: https://github.com/sbt/sbt/pull/7420
  [7437]: https://github.com/sbt/sbt/pull/7437
  [7447]: https://github.com/sbt/sbt/pull/7447
