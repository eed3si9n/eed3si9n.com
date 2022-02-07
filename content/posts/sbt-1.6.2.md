---
title:       "sbt 1.6.2"
type:        story
date:        2022-02-01
draft:       false
promote:     true
url:         /sbt-1.6.2
tags:        [ "sbt" ]
---

  [@eed3si9n]: https://github.com/eed3si9n
  [@Nirvikalpa108]: https://github.com/Nirvikalpa108
  [@adpi2]: https://github.com/adpi2
  [@eatkins]: https://github.com/eatkins
  [@dwijnand]: https://github.com/dwijnand
  [@retronym]: https://github.com/retronym
  [6806]: https://github.com/sbt/sbt/pull/6806
  [6803]: https://github.com/sbt/sbt/pull/6803
  [6799]: https://github.com/sbt/sbt/pull/6799
  [lm395]: https://github.com/sbt/librarymanagement/pull/395

I'm happy to announce sbt 1.6.2 patch release is available. Full release note is here - https://github.com/sbt/sbt/releases/tag/v1.6.2

See [1.6.0 release note](/sbt-1.6.0) for the details on 1.6.x features.

### Highlights

- sbt 1.6.2 adds `License` object with predefined licenses.
- Fixes test framework loading failure not failing the build [#6806][6806] by [@eed3si9n][@eed3si9n]

<!--more-->

### How to upgrade

Download **the official sbt runner + launcher** from SDKMAN or download from <https://github.com/sbt/sbt/releases/>.

In addition, the sbt version used for your build is upgraded by putting the following in `project/build.properties`:

```bash
sbt.version=1.6.2
```

This mechanism allows that sbt 1.6.2 is used only for the builds that you want.

### License

sbt 1.6.2 adds `License` object that defines predefined license values:

```scala
licenses := List(License.Apache2)
```

Predefined values are `License.Apache2`, `License.MIT`, `License.CC0`, and `License.GPL3_or_later`. [lm#395][lm395] by [@eed3si9n][@eed3si9n]

### Participation

Thanks to everyone who's helped improve sbt and Zinc 1 by using them, reporting bugs, improving our documentation, porting builds, porting plugins, and submitting and reviewing pull requests.

For anyone interested in helping sbt, there are many avenues for you to help, depending on your interest. If you're interested, [Contributing](https://github.com/sbt/sbt/blob/develop/CONTRIBUTING.md), ["help wanted"](https://github.com/sbt/sbt/issues?q=is%3Aissue+is%3Aopen+label%3A%22help+wanted%22), ["good first issue"](https://github.com/sbt/sbt/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22) are good starting points. If you have ideas let us know on [sbt Discussions](https://github.com/sbt/sbt/discussions). See also my [small changes](https://twitter.com/eed3si9n/status/1488200993519153155) thread.

### Donate/Hire April

Apparently April, an active contributor to Scala compiler has been sick without diagnosis. Let's help her out!

- https://github.com/sponsors/NthPortal
- https://twitter.com/NthPortal/status/1412504710754541572

### Donate to Play

- https://www.playframework.com/sponsors
