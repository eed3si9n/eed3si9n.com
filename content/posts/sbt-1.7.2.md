---
title:       "sbt 1.7.2"
type:        story
date:        2022-10-03
url:         /sbt-1.7.2
tags:        [ "sbt" ]
---

I'm happy to announce sbt 1.7.2 patch release is available. Full release note is here - https://github.com/sbt/sbt/releases/tag/v1.7.2

See [1.7.0 release note](/sbt-1.7.0) for the details on 1.7.x features.

### Highlights

- Fixes invalidation of incremental `testQuick` task [#6903][6903] by [@gontard][@gontard]
- Updates `sbt new` by default to use Giter8 0.15.0
- Updates launcher to support Scala 3 apps [#7035][7035] by [@eed3si9n][@eed3si9n]
- Adds `diagnosticCode` and `diagnosticRelatedInforamation` (sic) to `InterfaceUtil.problem(...)` [#7006][7006] by [@ckipp01][@ckipp01]
- Forwards `diagnosticCode` to BSP [#6998][6998] by [@ckipp01][@ckipp01]

<!--more-->

### How to upgrade

Download **the official sbt runner + launcher** from `cs setup`, SDKMAN, or download from <https://github.com/sbt/sbt/releases/>.

In addition, the sbt version used for your build is upgraded by putting the following in `project/build.properties`:

```bash
sbt.version=1.7.2
```

This mechanism allows that sbt 1.7.2 is used only for the builds that you want.

### Participation

sbt 1.7.2 was brought to you by 11 contributors. Eugene Yokota (eed3si9n), Svend Vanderveken, Sébastien Boulet, Scala Steward, Arman Bilge, Chris Kipp, Devin Fisher, Adrien Piquerez, Matthias Kurz, Yosef Fertel, dependabot[bot]. Thank you!

Thanks to everyone who's helped improve sbt and Zinc 1 by using them, reporting bugs, improving our documentation, porting builds, porting plugins, and submitting and reviewing pull requests.

For anyone interested in helping sbt, there are many avenues for you to help, depending on your interest. If you're interested, [Contributing](https://github.com/sbt/sbt/blob/develop/CONTRIBUTING.md), ["help wanted"](https://github.com/sbt/sbt/issues?q=is%3Aissue+is%3Aopen+label%3A%22help+wanted%22), ["good first issue"](https://github.com/sbt/sbt/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22) are good starting points. If you have ideas let us know on [sbt Discussions](https://github.com/sbt/sbt/discussions).

### 🏳️‍🌈 Support Ukraine 🇺🇦

Forbidden Colours has started a fundraising campaign to support organisations in Poland, Hungary and Romania that are welcoming LGBTIQ+ refugees.

<https://www.forbidden-colours.com/2022/02/26/support-ukrainian-lgbtiq-refugees/>

### Donate to Play

- https://www.playframework.com/sponsors

  [6903]: https://github.com/sbt/sbt/pull/6903
  [6978]: https://github.com/sbt/sbt/pull/6978
  [6998]: https://github.com/sbt/sbt/pull/6998
  [7035]: https://github.com/sbt/sbt/pull/7035
  [6824]: https://github.com/sbt/sbt/pull/6824
  [7038]: https://github.com/sbt/sbt/pull/7038
  [7006]: https://github.com/sbt/sbt/pull/7006
  [7041]: https://github.com/sbt/sbt/pull/7041
  [@eed3si9n]: https://github.com/eed3si9n
  [@Nirvikalpa108]: https://github.com/Nirvikalpa108
  [@adpi2]: https://github.com/adpi2
  [@er1c]: https://github.com/er1c
  [@eatkins]: https://github.com/eatkins
  [@dwijnand]: https://github.com/dwijnand
  [@ckipp01]: https://github.com/ckipp01
  [@gontard]: https://github.com/gontard
  [@frosforever]: https://github.com/frosforever
