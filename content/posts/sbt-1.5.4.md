---
title:       "sbt 1.5.4"
type:        story
date:        2021-06-14
draft:       false
promote:     true
sticky:      false
url:         /sbt-1.5.4
aliases:     [ /node/397 ]
tags:        [ "sbt" ]
---

  [@peter-janssen]: https://github.com/peter-janssen
  [@eed3si9n]: https://github.com/eed3si9n
  [@Nirvikalpa108]: https://github.com/Nirvikalpa108
  [@adpi2]: https://github.com/adpi2
  [@eatkins]: https://github.com/eatkins
  [@dwijnand]: https://github.com/dwijnand
  [@retronym]: https://github.com/retronym
  [@quelgar]: https://github.com/quelgar
  [lm380]: https://github.com/sbt/librarymanagement/pull/380
  [zinc982]: https://github.com/sbt/zinc/pull/982
  [zinc983]: https://github.com/sbt/zinc/pull/983
  [ipcsocket14]: https://github.com/sbt/ipcsocket/pull/14
  [6539]: https://github.com/sbt/sbt/pull/6539
  [6538]: https://github.com/sbt/sbt/pull/6538

I'm happy to announce sbt 1.5.4 patch release is available. Full release note is here - https://github.com/sbt/sbt/releases/tag/v1.5.4

### How to upgrade

Download **the official sbt runner + launcher** from SDKMAN or download from <https://github.com/sbt/sbt/releases/>.

In addition, the sbt version used for your build is upgraded by putting the following in `project/build.properties`:

<code>
sbt.version=1.5.4
</code>

This mechanism allows that sbt 1.5.4 is used only for the builds that you want.

### Highlights

- Fixes compiler ClassLoader list to use `compilerJars.toList` (For Scala 3, this drops support for 3.0.0-M2) [#6538][6538] by [@adpi2][@adpi2]
- Fixes undercompilation of package object causing "Symbol 'type X' is missing from the classpath" [zinc#983][zinc983] by [@retronym][@retronym]
- Fixes overcompilation with scalac `-release` flag [zinc#982][zinc982] by [@retronym][@retronym]
- Fixes BSP on ARM Macs by keeping JNI server socket to keep using JNI [ipcsocket#14][ipcsocket14] by [@quelgar][@quelgar]

For more details please see https://github.com/sbt/sbt/releases/tag/v1.5.4

### Participation

sbt 1.5.4 was brought to you by 6 contributors. Eugene Yokota (eed3si9n), Jason Zaugg, Adrien Piquerez, Peter Janssen, Lachlan O'Dea, dependabot. Thank you!

Thanks to everyone who's helped improve sbt and Zinc 1 by using them, reporting bugs, improving our documentation, porting builds, porting plugins, and submitting and reviewing pull requests.

For anyone interested in helping sbt, there are many avenues for you to help, depending on your interest. If you're interested, [Contributing](https://github.com/sbt/sbt/blob/develop/CONTRIBUTING.md), ["help wanted"](https://github.com/sbt/sbt/issues?q=is%3Aissue+is%3Aopen+label%3A%22help+wanted%22), ["good first issue"](https://github.com/sbt/sbt/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22) are good starting points. If you have ideas let us know on [sbt Discussions](https://github.com/sbt/sbt/discussions).

### Donate to April

Apparently April, an active contributor to Scala compiler has been sick without diagnosis. Let's help her out!

https://www.gofundme.com/f/help-april-survive-while-sick
