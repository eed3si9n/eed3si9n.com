---
title:       "sbt 1.6.0-M1"
type:        story
date:        2021-09-19
draft:       false
promote:     true
sticky:      false
url:         /sbt-1.6.0-beta
aliases:     [ /node/408 ]
tags:        [ "sbt" ]
---

Hi everyone. On behalf of the sbt project, I am happy to announce sbt 1.6.0-M1. This is the first milestone (M1) of the 1.6.x feature release, a binary compatible release focusing on new features. sbt 1.x is released under Semantic Versioning, and the plugins are expected to work throughout the 1.x series. Please try it out, and report any issues you might come across.

The headline features of sbt 1.6.0 are:

- Improved JDK 17 support
- BSP improvements
- Remote caching improvements
- Zinc improvements

<!--more-->

### How to upgrade

You can upgrade to sbt 1.6.0-M1 by putting the following in `project/build.properties`:

```bash
sbt.version=1.6.0-M1
```

### Changes with compatibility implications

- The Scala version used to compile `build.sbt` is updated to [Scala 2.12.15](https://github.com/scala/scala/releases/tag/v2.12.15), which improves the compatibility with JDK 17+. The metabuild is compiled with `-Xsource:3` flag [#6664][6664] by [@Nirvikalpa108][@Nirvikalpa108] + [@eed3si9n][@eed3si9n]
- `sbt.TrapExit` is dropped due to Security Manager being deprecated in JDK 17. Calling `sys.exit` in `run` or `test` would shutdown the sbt session. Use [forking](https://www.scala-sbt.org/1.x/docs/Forking.html) to prevent it [#6665][6665] by [@eed3si9n][@eed3si9n]

### BSP improvements

- Fixes `.sbtopts` not getting picked up when sbt server is started by Metals [#6593][6593] by [@adpi2][@adpi2]
- Fixes BSP IntelliJ import when `java` is not on `PATH` [#6576][6576] by [@github-samuel-clarenc][@github-samuel-clarenc]
- Implements BSP `buildTarget/cleanCache`, which fixes IntelliJ `rebuild` [#6638][6638] by [@hmemcpy][@hmemcpy]
- Implements BSP `build/taskProgress` notifications [#6642][6642] by [@hmemcpy][@hmemcpy]
- Improves BSP IntelliJ import by sending information about sbt server process failure  [#6573][6573] by [@github-samuel-clarenc][@github-samuel-clarenc]
- Makes BSP requests robust to some target failures [#6609][6609] by [@adpi2][@adpi2]
- Sends BSP diagnostics and meaningful error message when reloading fails [#6566][6566] by [@adpi2][@adpi2]

### Remote caching improvements

sbt 1.6.0 improves remote caching of `resources` directory by virtualizing the internal sync state (`copy-resources.txt`). This allows incremental `resource` directory synching to be resumed from the remote cache, similar to how Zinc has been able to resume incremental compilation from the remote cache. This was contributed by Amina Adewusi ([@Nirvikalpa108][@Nirvikalpa108]) as [#6611][6611].

### Zinc improvements

- Fixes under-compilation of folded constants (see also [SI-7173][SI-7173]) [zinc@d15228][zincd15228]/[zinc#1003][zinc1003] by [@ephemerist][@ephemerist] and [@dwijnand][@dwijnand]
- Fixes over-compilation of extended classes on JDK 11 [zinc#998][zinc998] by [@lrytz][@lrytz]
- Improves performance of loading used names from persisted `Analysis` file [zinc#995][zinc995] by [@dwijnand][@dwijnand]

### Other updates

- Fixes shutdown hook error in timing report [#6630][6630] by [@Nirvikalpa108][@Nirvikalpa108]
- Fixes `ClassCastException` in `XMainConfiguration` [#6649][6649] by [@eed3si9n][@eed3si9n]
- Moves `scalaInstanceTopLoader` to `compileBase` settings [#6480][6480] by [@adpi2][@adpi2]
- Fixes `crossSbtVersions` included into `lintBuild` [#6656][6656] by [@Nirvikalpa108][@Nirvikalpa108]

### Participation

sbt 1.6.0-M1 was brought to you by 16 contributors. Eugene Yokota (eed3si9n), Adrien Piquerez, Jason Zaugg, Igal Tabachnik, Amina Adewusi, Dale Wijnand, Eathan Atkins, Samuel CLARENC, Daniel Darabos, Eric Peters, Lukas Rytz, Roberto Tyley, Ubaldo Pescatore, Victor Babenko, William Narmontas, dependabot[bot]. Thanks!

Thanks to everyone who's helped improve sbt and Zinc 1 by using them, reporting bugs, improving our documentation, porting builds, porting plugins, and submitting and reviewing pull requests.

For anyone interested in helping sbt, there are many avenues for you to help, depending on your interest. If you're interested, [Contributing](https://github.com/sbt/sbt/blob/develop/CONTRIBUTING.md), ["help wanted"](https://github.com/sbt/sbt/issues?q=is%3Aissue+is%3Aopen+label%3A%22help+wanted%22), ["good first issue"](https://github.com/sbt/sbt/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22), and [Discussions](https://github.com/sbt/sbt/discussions/) are good starting points.

  [@eed3si9n]: https://github.com/eed3si9n
  [@Nirvikalpa108]: https://github.com/Nirvikalpa108
  [@adpi2]: https://github.com/adpi2
  [@eatkins]: https://github.com/eatkins
  [@dwijnand]: https://github.com/dwijnand
  [@retronym]: https://github.com/retronym
  [@github-samuel-clarenc]: https://github.com/github-samuel-clarenc
  [@hmemcpy]: https://github.com/hmemcpy
  [@lrytz]: https://github.com/lrytz
  [@ephemerist]: https://github.com/ephemerist
  [6480]: https://github.com/sbt/sbt/pull/6480
  [6566]: https://github.com/sbt/sbt/pull/6566
  [6593]: https://github.com/sbt/sbt/pull/6593
  [6576]: https://github.com/sbt/sbt/pull/6576
  [6573]: https://github.com/sbt/sbt/pull/6573
  [6611]: https://github.com/sbt/sbt/pull/6611
  [6630]: https://github.com/sbt/sbt/pull/6630
  [6649]: https://github.com/sbt/sbt/pull/6649
  [6638]: https://github.com/sbt/sbt/pull/6638
  [6642]: https://github.com/sbt/sbt/pull/6642
  [6656]: https://github.com/sbt/sbt/pull/6656
  [6664]: https://github.com/sbt/sbt/pull/6664
  [6665]: https://github.com/sbt/sbt/pull/6665
  [SI-7173]: https://github.com/scala/bug/issues/7173
  [zinc995]: https://github.com/sbt/zinc/pull/995
  [zinc998]: https://github.com/sbt/zinc/issues/998
  [zinc1003]: https://github.com/sbt/zinc/pull/1003
  [zincd15228]: https://github.com/sbt/zinc/pull/985/commits/d15228951f3de0ae07c0da5f34b84be5f0e7a4bb
