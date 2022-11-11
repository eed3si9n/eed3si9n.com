---
title:       "sbt 1.7.3"
type:        story
date:        2022-10-30
url:         /sbt-1.7.3
tags:        [ "sbt" ]
---

I'm happy to announce sbt 1.7.3 patch release is available. Full release note is here - https://github.com/sbt/sbt/releases/tag/v1.7.3

See [1.7.0 release note](/sbt-1.7.0) for the details on 1.7.x features.

### Highlights

- Updates underlying Coursier from 2.1.0-M2 to 2.1.0-M7-18-g67daad6a9 (lm-coursier-shaded 2.0.12) by [@eed3si9n][@eed3si9n]

<!--more-->

### How to upgrade

Download **the official sbt runner + launcher** from `cs setup`, SDKMAN, or download from <https://github.com/sbt/sbt/releases/>.

In addition, the sbt version used for your build is upgraded by putting the following in `project/build.properties`:

```bash
sbt.version=1.7.3
```

This mechanism allows that sbt 1.7.3 is used only for the builds that you want.

### Participation

sbt 1.7.2 was brought to you by 2 contributors. Eugene Yokota (eed3si9n), Vedant. Thank you!

Thanks to everyone who's helped improve sbt and Zinc 1 by using them, reporting bugs, improving our documentation, porting builds, porting plugins, and submitting and reviewing pull requests.

For anyone interested in helping sbt, there are many avenues for you to help, depending on your interest. If you're interested, [Contributing](https://github.com/sbt/sbt/blob/develop/CONTRIBUTING.md), ["help wanted"](https://github.com/sbt/sbt/issues?q=is%3Aissue+is%3Aopen+label%3A%22help+wanted%22), ["good first issue"](https://github.com/sbt/sbt/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22) are good starting points. If you have ideas let us know on [sbt Discussions](https://github.com/sbt/sbt/discussions).

### 🏳️‍🌈 Support Ukraine 🇺🇦

Forbidden Colours has started a fundraising campaign to support organisations in Poland, Hungary and Romania that are welcoming LGBTIQ+ refugees.

<https://www.forbidden-colours.com/2022/02/26/support-ukrainian-lgbtiq-refugees/>

  [@eed3si9n]: https://github.com/eed3si9n
  [@Nirvikalpa108]: https://github.com/Nirvikalpa108
  [@adpi2]: https://github.com/adpi2
  [@er1c]: https://github.com/er1c
  [@eatkins]: https://github.com/eatkins
  [@dwijnand]: https://github.com/dwijnand
  [@ckipp01]: https://github.com/ckipp01
  [@gontard]: https://github.com/gontard
  [@frosforever]: https://github.com/frosforever
