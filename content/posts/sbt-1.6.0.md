---
title:       "sbt 1.6.0"
type:        story
date:        2021-12-26
draft:       false
promote:     true
sticky:      false
url:         /sbt-1.6.0
tags:        [ "sbt" ]
---

Hi everyone. On behalf of the sbt project, I am happy to announce sbt 1.6.0. This is the sixth feature release of sbt 1.x, a binary compatible release focusing on new features. sbt 1.x is released under Semantic Versioning, and the plugins are expected to work throughout the 1.x series. Please try it out, and report any issues you might come across.

The headline features of sbt 1.6.0 are:

- Improved JDK 17 support
- BSP improvements
- Zinc improvements
- Remote caching improvements
- Tab completion of global keys

<!--more-->

### How to upgrade

Download **the official sbt runner** from SDKMAN or download from <https://github.com/sbt/sbt/releases/tag/v1.6.0>.

In addition, the sbt version used for your build is upgraded by putting the following in `project/build.properties`:

```bash
sbt.version=1.6.0
```

This mechanism allows that sbt 1.6.0 is used only for the builds that you want.

### Changes with compatibility implications

- The Scala version used to compile `build.sbt` is updated to [Scala 2.12.15](https://github.com/scala/scala/releases/tag/v2.12.15), which improves the compatibility with JDK 17+. The metabuild is compiled with `-Xsource:3` flag [#6664][6664] by [@Nirvikalpa108][@Nirvikalpa108] + [@eed3si9n][@eed3si9n]
- `sbt.TrapExit` is dropped due to Security Manager being deprecated in JDK 17. Calling `sys.exit` in `run` or `test` would shutdown the sbt session. Use [forking](https://www.scala-sbt.org/1.x/docs/Forking.html) to prevent it [#6665][6665] by [@eed3si9n][@eed3si9n]
- sbt 1.6.0 reads credentials from the file specified using `SBT_CREDENTIALS` environment variable, following sbt launcher [#6724][6724] by [@daddykotex][@daddykotex]

### BSP improvements

- Fixes `.sbtopts`  not getting picked up when sbt server is started by Metals [#6593][6593] by [@adpi2][@adpi2]
- Fixes BSP IntelliJ import when `java` is not on `PATH` [#6576][6576] by [@github-samuel-clarenc][@github-samuel-clarenc]
- Implements BSP `buildTarget/cleanCache`, which fixes IntelliJ `rebuild` [#6638][6638] by [@hmemcpy][@hmemcpy]
- Implements BSP `build/taskProgress` notifications [#6642][6642] by [@hmemcpy][@hmemcpy]
- Improves BSP IntelliJ import by sending information about sbt server process failure  [#6573][6573] by [@github-samuel-clarenc][@github-samuel-clarenc]
- Makes BSP requests robust to some target failures [#6609][6609] by [@adpi2][@adpi2]
- Sends BSP diagnostics and meaningful error message when reloading fails [#6566][6566] by [@adpi2][@adpi2]
- Fixes handling of sources in the base directory [#6701][6701] by [@adpi2][@adpi2]
- Fixes `sbtn` buffer not printing out all the outputs on system out [#6703][6703] by [@adpi2][@adpi2]
- Fixes infinite loop when server fails to load [#6707][6707] by [@adpi2][@adpi2]
- Fixes handling of fake position such as `<macro>`, which are occasionally returned by the compiler [#6730][6730] by [@eed3si9n][@eed3si9n]
- Adds `sbt shutdownall` to shutdown all sbt server instances [#6697][6697] by [@er1c][@er1c]
- Adds `sbt --no-server` to not start the server or use a virtual terminal [#6728][6728] by [@eed3si9n][@eed3si9n]

### Zinc improvements

- Fixes under-compilation of folded constants (see also [SI-7173][SI-7173]) [zinc@d15228][zincd15228]/[zinc#1003][zinc1003] by [@ephemerist][@ephemerist] and [@dwijnand][@dwijnand]
- Fixes over-compilation of extended classes on JDK 11 [zinc#998][zinc998] by [@lrytz][@lrytz]
- Improves performance of loading used names from persisted `Analysis` file [zinc#995][zinc995] by [@dwijnand][@dwijnand]
- Fixes hashing of large files [zinc#1018][zinc1018] by [@niktrop][@niktrop]

### Remote caching improvements

sbt 1.6.0 improves remote caching of `resources` directory by virtualizing the internal sync state (`copy-resources.txt`). This allows incremental `resource` directory synching to be resumed from the remote cache, similar to how Zinc has been able to resume incremental compilation from the remote cache. This was contributed by Amina Adewusi ([@Nirvikalpa108][@Nirvikalpa108]) as [#6611][6611].

### Other updates

- Updates to lm-coursier 2.0.10, which uses [Coursier 2.1.0-M2](https://github.com/coursier/coursier/releases/tag/v2.1.0-M2). This fixes full Scala suffix getting incorrectly overwritten by `scalaVersion` [#6753][6753] by [@eed3si9n][@eed3si9n]
- Fixes tab completion of global keys [#6716][6716] by [@eed3si9n][@eed3si9n]
- Fixes shutdown hook error in timing report [#6630][6630] by [@Nirvikalpa108][@Nirvikalpa108]
- Fixes `ClassCastException` in `XMainConfiguration` [#6649][6649] by [@eed3si9n][@eed3si9n]
- Moves `scalaInstanceTopLoader` to `compileBase` settings [#6480][6480] by [@adpi2][@adpi2]
- Fixes `crossSbtVersions` included into `lintBuild` [#6656][6656] by [@Nirvikalpa108][@Nirvikalpa108]
- Fixes `realpathish` function in `sbt` runner script [#6641][6641] by [@darabos][@darabos]
- Fixes repeated version numbers in eviction error [lm#386][lm386] by [@rtyley][@rtyley]
- Flyweights `ConfigRef` to reduce heap usage [lm#390][lm390] by [@eed3si9n][@eed3si9n]
- Adds Windows Java home selectors for JDK cross building [#6684][6684] by [@kxbmap][@kxbmap]
- Makes scripted Java home configurable using `scripted / javaHome` [#6673][6673] by [@kxbmap][@kxbmap]
- `maven.repo.local` system property configures local Maven repository [lm#391][lm391] by [@peter-janssen][@peter-janssen]

### Participation

sbt 1.6.0 was brought to you by 27 contributors. Eugene Yokota (eed3si9n), Adrien Piquerez, Kenji Yoshida (xuwei-k), Jason Zaugg, Dale Wijnand, Amina Adewusi, Igal Tabachnik, Eathan Atkins, Eric Peters, Michal Augustýn, Daniel Darabos, Samuel CLARENC, kijuky, kxbmap, Arun Sethia, David Francoeur, Hani Khan, Lukas Rytz, Nikolay.Tropin, Nima Taheri, Peter Janssen, Roberto Tyley, Ubaldo Pescatore, Victor Babenko, William Narmontas, dependabot[bot], gontard. Thanks!

Thanks to everyone who's helped improve sbt and Zinc by using them, reporting bugs, improving our documentation, porting builds, porting plugins, and submitting and reviewing pull requests.

For anyone interested in helping sbt, there are many avenues for you to help, depending on your interest. If you're interested, [Contributing](https://github.com/sbt/sbt/blob/develop/CONTRIBUTING.md), ["help wanted"](https://github.com/sbt/sbt/issues?q=is%3Aissue+is%3Aopen+label%3A%22help+wanted%22), ["good first issue"](https://github.com/sbt/sbt/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22), and [Discussions](https://github.com/sbt/sbt/discussions/) are good starting points.

### Donate/Hire April

Apparently April, an active contributor to Scala compiler has been sick without diagnosis. Let's help her out!

- https://github.com/sponsors/NthPortal
- https://twitter.com/NthPortal/status/1412504710754541572

### Donate to Play

- https://www.playframework.com/sponsors

  [@eed3si9n]: https://github.com/eed3si9n
  [@Nirvikalpa108]: https://github.com/Nirvikalpa108
  [@adpi2]: https://github.com/adpi2
  [@er1c]: https://github.com/er1c
  [@eatkins]: https://github.com/eatkins
  [@dwijnand]: https://github.com/dwijnand
  [@retronym]: https://github.com/retronym
  [@github-samuel-clarenc]: https://github.com/github-samuel-clarenc
  [@hmemcpy]: https://github.com/hmemcpy
  [@lrytz]: https://github.com/lrytz
  [@ephemerist]: https://github.com/ephemerist
  [@rtyley]: https://github.com/rtyley
  [@darabos]: https://github.com/darabos
  [@nimatrueway]: https://github.com/nimatrueway
  [@kxbmap]: https://github.com/kxbmap
  [@kijuky]: https://github.com/kijuky
  [@daddykotex]: https://github.com/daddykotex
  [@niktrop]: https://github.com/niktrop
  [@peter-janssen]: https://github.com/peter-janssen
  [6480]: https://github.com/sbt/sbt/pull/6480
  [6566]: https://github.com/sbt/sbt/pull/6566
  [6593]: https://github.com/sbt/sbt/pull/6593
  [6576]: https://github.com/sbt/sbt/pull/6576
  [6573]: https://github.com/sbt/sbt/pull/6573
  [6609]: https://github.com/sbt/sbt/pull/6609
  [6611]: https://github.com/sbt/sbt/pull/6611
  [6630]: https://github.com/sbt/sbt/pull/6630
  [6649]: https://github.com/sbt/sbt/pull/6649
  [6638]: https://github.com/sbt/sbt/pull/6638
  [6641]: https://github.com/sbt/sbt/pull/6641
  [6642]: https://github.com/sbt/sbt/pull/6642
  [6656]: https://github.com/sbt/sbt/pull/6656
  [6664]: https://github.com/sbt/sbt/pull/6664
  [6665]: https://github.com/sbt/sbt/pull/6665
  [6675]: https://github.com/sbt/sbt/pull/6675
  [6684]: https://github.com/sbt/sbt/pull/6684
  [6673]: https://github.com/sbt/sbt/pull/6673
  [6693]: https://github.com/sbt/sbt/pull/6693
  [6697]: https://github.com/sbt/sbt/pull/6697
  [6701]: https://github.com/sbt/sbt/pull/6701
  [6703]: https://github.com/sbt/sbt/pull/6703
  [6699]: https://github.com/sbt/sbt/pull/6699
  [6707]: https://github.com/sbt/sbt/pull/6707
  [6716]: https://github.com/sbt/sbt/pull/6716
  [6725]: https://github.com/sbt/sbt/pull/6725
  [6724]: https://github.com/sbt/sbt/pull/6724
  [6728]: https://github.com/sbt/sbt/pull/6728
  [6730]: https://github.com/sbt/sbt/pull/6730
  [6753]: https://github.com/sbt/sbt/pull/6753
  [SI-7173]: https://github.com/scala/bug/issues/7173
  [zinc995]: https://github.com/sbt/zinc/pull/995
  [zinc998]: https://github.com/sbt/zinc/issues/998
  [zinc1003]: https://github.com/sbt/zinc/pull/1003
  [zincd15228]: https://github.com/sbt/zinc/pull/985/commits/d15228951f3de0ae07c0da5f34b84be5f0e7a4bb
  [zinc1018]: https://github.com/sbt/zinc/pull/1018
  [lm386]: https://github.com/sbt/librarymanagement/pull/386
  [lm390]: https://github.com/sbt/librarymanagement/pull/390
  [lm391]: https://github.com/sbt/librarymanagement/pull/391
