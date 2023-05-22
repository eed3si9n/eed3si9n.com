---
title:       "sbt 1.8.3"
type:        story
date:        2023-05-12
url:         /sbt-1.8.3
tags:        [ "sbt" ]
---

Hi everyone. On behalf of the sbt project, I'm happy to announce sbt 1.8.3 patch release fixing a security vulnerability. Full release note is here - https://github.com/sbt/sbt/releases/tag/v1.8.3

See [1.8.0 release note](/sbt-1.8.0) for the details on 1.8.x features.

### Highlights

- Fixes `sbt.io.IO.withTemporaryFile` not limiting access on Unix-like systems in [io#344][io344]/[zinc#1185][zinc1185] by [@eed3si9n][@eed3si9n]

<!--more-->

### IO.withTemporaryFile fix

sbt 1.8.3 fixes `sbt.io.IO.withTemporaryFile` etc not limiting access on Unix-like systems. Prior to this patch release, some functions were using `java.io.File.createTempFile`, which does not set strict file permissions, as opposed to the NIO-equivalent that does.

This means that on a shared Unix-like systems, build user or plugin's use of `sbt.io.IO.withTemporaryFile` etc would have exposed the information to other users.

This issue was reported by Oleksandr Zolotko at IBM, and was fixed by Eugene Yokota ([@eed3si9n][@eed3si9n]) in [io#344][io344]/[zinc#1185][zinc1185].

### How to upgrade

Download **the official sbt runner + launcher** from `cs setup`, SDKMAN, or download from <https://github.com/sbt/sbt/releases/>.

In addition, the sbt version used for your build is upgraded by putting the following in `project/build.properties`:

```bash
sbt.version=1.8.3
```

This mechanism allows that sbt 1.8.3 is used only for the builds that you want.

### Other updates

sbt 1.8.3 backports Zinc and IO fixes from 1.9.0-RC2 as well.

- Fixes Zinc incremental compilation looping infinitely [zinc#1182][zinc1182] by [@CarstonSchilds][@CarstonSchilds]
- Fixes spurious whitespace in the runner script by [@keynmol][@keynmol] in [#7134][7134]
- Fixes NullPointerError under `-Vdebug` by [@som-snytt][@som-snytt] in [zinc#1141][zinc1141]
- Avoids deprecated `java.net.URL` constructor by [@xuwei-k][@xuwei-k] in [io#341][io341]
- Updates to Swoval 2.1.10 by [@eatkins][@eatkins] in [io#343][io343]
- Notifies `ClassFileManager` from `IncOptions` in `Incremental.prune` by [@lrytz] in [zinc1148][zinc1148]
- Adds `FileFilter.nothing` and `FileFilter.everything` by [@mdedetrich][@mdedetrich] in [io#340][io340]

### Participation

Thanks to everyone who's helped improve sbt and Zinc 1 by using them, reporting bugs, improving our documentation, porting builds, porting plugins, and submitting and reviewing pull requests.

For anyone interested in helping sbt, there are many avenues for you to help, depending on your interest. If you're interested, [Contributing](https://github.com/sbt/sbt/blob/develop/CONTRIBUTING.md), ["help wanted"](https://github.com/sbt/sbt/issues?q=is%3Aissue+is%3Aopen+label%3A%22help+wanted%22), ["good first issue"](https://github.com/sbt/sbt/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22) are good starting points. If you have ideas let us know on [sbt Discussions](https://github.com/sbt/sbt/discussions).

### Support to Scala Center

Scala Center is a non-profit center at EPFL to support education and open source.

- https://scala.epfl.ch/donate.html

  [@eed3si9n]: https://github.com/eed3si9n
  [@Nirvikalpa108]: https://github.com/Nirvikalpa108
  [@adpi2]: https://github.com/adpi2
  [@er1c]: https://github.com/er1c
  [@eatkins]: https://github.com/eatkins
  [@dwijnand]: https://github.com/dwijnand
  [@ckipp01]: https://github.com/ckipp01
  [@mdedetrich]: https://github.com/mdedetrich
  [@xuwei-k]: https://github.com/xuwei-k
  [@nrinaudo]: https://github.com/nrinaudo
  [@CarstonSchilds]: https://github.com/CarstonSchilds
  [@som-snytt]: https://github.com/som-snytt
  [@lrytz]: https://github.com/lrytz
  [@dragos]: https://github.com/dragos
  [@keynmol]: https://github.com/keynmol
  [@mzuehlke]: https://github.com/mzuehlke
  [@yoshinorin]: https://github.com/yoshinorin
  [@liang3zy22]: https://github.com/liang3zy22
  [@adriaanm]: https://github.com/adriaanm
  [7096]: https://github.com/sbt/sbt/pull/7096
  [7215]: ttps://github.com/sbt/sbt/pull/7215
  [7191]: https://github.com/sbt/sbt/pull/7191
  [7228]: https://github.com/sbt/sbt/pull/7228
  [7134]: https://github.com/sbt/sbt/pull/7134
  [7165]: https://github.com/sbt/sbt/pull/7165
  [7154]: https://github.com/sbt/sbt/pull/7154
  [7227]: https://github.com/sbt/sbt/pull/7227
  [7171]: https://github.com/sbt/sbt/pull/7171
  [7234]: https://github.com/sbt/sbt/pull/7234
  [zinc1182]: https://github.com/sbt/zinc/pull/1182
  [zinc1141]: https://github.com/sbt/zinc/pull/1141
  [zinc1148]: https://github.com/sbt/zinc/pull/1148
  [lm410]: https://github.com/sbt/librarymanagement/pull/410
  [lm411]: https://github.com/sbt/librarymanagement/pull/411
  [lm413]: https://github.com/sbt/librarymanagement/pull/413
  [lm415]: https://github.com/sbt/librarymanagement/pull/415
  [io340]: https://github.com/sbt/io/pull/340
  [io341]: https://github.com/sbt/io/pull/341
  [io343]: https://github.com/sbt/io/pull/343
  [coursier2633]: https://github.com/coursier/coursier/pull/2633
  [io344]: https://github.com/sbt/io/pull/344
  [zinc1185]: https://github.com/sbt/zinc/pull/1185
