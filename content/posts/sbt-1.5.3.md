---
title:       "sbt 1.5.3"
type:        story
date:        2021-06-01
draft:       false
promote:     true
sticky:      false
url:         /sbt-1.5.3
aliases:     [ /node/395 ]
tags:        [ "sbt" ]
---

  [6504]: https://github.com/sbt/sbt/pull/6504
  [6511]: https://github.com/sbt/sbt/pull/6511
  [6514]: https://github.com/sbt/sbt/pull/6514
  [6522]: https://github.com/sbt/sbt/pull/6522
  [6517]: https://github.com/sbt/sbt/pull/6517
  [6499]: https://github.com/sbt/sbt/pull/6499
  [6523]: https://github.com/sbt/sbt/pull/6523
  [5405]: https://github.com/sbt/sbt/issues/5405
  [io317]: https://github.com/sbt/io/pull/317
  [io319]: https://github.com/sbt/io/pull/319
  [lm377]: https://github.com/sbt/librarymanagement/pull/377
  [lm379]: https://github.com/sbt/librarymanagement/pull/379
  [zinc979]: https://github.com/sbt/zinc/pull/979
  [@eed3si9n]: https://github.com/eed3si9n
  [@Nirvikalpa108]: https://github.com/Nirvikalpa108
  [@adpi2]: https://github.com/adpi2
  [@bjaglin]: https://github.com/bjaglin
  [@mkurz]: https://github.com/mkurz
  [@pikinier20]: https://github.com/pikinier20
  [@eatkins]: https://github.com/eatkins
  [@dwijnand]: https://github.com/dwijnand
  [@SethTisue]: https://github.com/SethTisue

I'm happy to announce sbt 1.5.3 patch release is available. Full release note is here - https://github.com/sbt/sbt/releases/tag/v1.5.3

### How to upgrade

Download **the official sbt runner + launcher** from SDKMAN or download from <https://github.com/sbt/sbt/releases/>.

In addition, the sbt version used for your build is upgraded by putting the following in `project/build.properties`:

<code>
sbt.version=1.5.3
</code>

This mechanism allows that sbt 1.5.3 is used only for the builds that you want.

### Highlights

- Fixes `scalacOptions` not getting forwarded to ScalaDoc in Scala 3 [#6499][6499] by [@pikinier20][@pikinier20]
- Fixes undercompilation of sealed traits that extends other seal traits [zinc#979][zinc979] by [@dwijnand][@dwijnand]
- Fixes version parsing not recognizing dots in a prerelease tag [lm#377][lm377] by [@Nirvikalpa108][@Nirvikalpa108]
- Fixes `inputFile` resolving to incorrect files when file specific globs are used [io#319][io319] by [@eatkins][@eatkins]
- Updates to Scala 2.12.14 [#6522][6522] by [@mkurz][@mkurz]

For more details please see https://github.com/sbt/sbt/releases/tag/v1.5.3

### Participation

sbt 1.5.3 was brought to you by 9 contributors. Eugene Yokota (eed3si9n), Matthias Kurz, Adrien Piquerez, Amina Adewusi, Brice Jaglin, Dale Wijnand, Ethan Atkins, Filip Zybała, Seth Tisue. Thank you!

Thanks to everyone who's helped improve sbt and Zinc 1 by using them, reporting bugs, improving our documentation, porting builds, porting plugins, and submitting and reviewing pull requests.

For anyone interested in helping sbt, there are many avenues for you to help, depending on your interest. If you're interested, [Contributing](https://github.com/sbt/sbt/blob/develop/CONTRIBUTING.md), ["help wanted"](https://github.com/sbt/sbt/issues?q=is%3Aissue+is%3Aopen+label%3A%22help+wanted%22), ["good first issue"](https://github.com/sbt/sbt/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22) are good starting points. If you have ideas let us know on [sbt Discussions](https://github.com/sbt/sbt/discussions).

### Donate to April

Apparently April, an active contributor to Scala compiler has been sick without diagnosis. Let's help her out!

https://www.gofundme.com/f/help-april-survive-while-sick
