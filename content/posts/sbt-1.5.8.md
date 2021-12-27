---
title:       "sbt 1.5.8"
type:        story
date:        2021-12-20
draft:       false
promote:     true
url:         /sbt-1.5.8
tags:        [ "sbt" ]
---

  [@eed3si9n]: https://github.com/eed3si9n
  [@Nirvikalpa108]: https://github.com/Nirvikalpa108
  [@adpi2]: https://github.com/adpi2
  [@eatkins]: https://github.com/eatkins
  [@dwijnand]: https://github.com/dwijnand
  [@retronym]: https://github.com/retronym
  [@augi]: https://github.com/augi
  [6755]: https://github.com/sbt/sbt/pull/6755

I'm happy to announce sbt 1.5.8 patch release is available. Full release note is here - https://github.com/sbt/sbt/releases/tag/v1.5.8

### Highlights

- Updates log4j 2 to 2.17.0, which fixes a denial of service vulnerability caused by infinite recursion (CVE-2021-45105) [#6755][6755] by [@augi][@augi]

<!--more-->

### How to upgrade

Download **the official sbt runner + launcher** from SDKMAN or download from <https://github.com/sbt/sbt/releases/>.

In addition, the sbt version used for your build is upgraded by putting the following in `project/build.properties`:

```bash
sbt.version=1.5.8
```

This mechanism allows that sbt 1.5.8 is used only for the builds that you want.

### Participation

sbt 1.5.8 was brought to you by 1 contributor. Michal Augustýn. Thank you!

Thanks to everyone who's helped improve sbt and Zinc 1 by using them, reporting bugs, improving our documentation, porting builds, porting plugins, and submitting and reviewing pull requests.

For anyone interested in helping sbt, there are many avenues for you to help, depending on your interest. If you're interested, [Contributing](https://github.com/sbt/sbt/blob/develop/CONTRIBUTING.md), ["help wanted"](https://github.com/sbt/sbt/issues?q=is%3Aissue+is%3Aopen+label%3A%22help+wanted%22), ["good first issue"](https://github.com/sbt/sbt/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22) are good starting points. If you have ideas let us know on [sbt Discussions](https://github.com/sbt/sbt/discussions).

### Donate/Hire April

Apparently April, an active contributor to Scala compiler has been sick without diagnosis. Let's help her out!

- https://www.gofundme.com/f/help-april-survive-while-sick
- https://twitter.com/NthPortal/status/1412504710754541572

### Donate to Play

- https://www.playframework.com/sponsors
