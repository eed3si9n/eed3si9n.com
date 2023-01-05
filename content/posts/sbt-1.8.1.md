---
title:       "sbt 1.8.1"
type:        story
date:        2023-01-03
url:         /sbt-1.8.1
tags:        [ "sbt" ]
---

Happy new year! On behalf of the sbt project, I'm happy to announce sbt 1.8.1 patch release is available. Full release note is here - https://github.com/sbt/sbt/releases/tag/v1.8.1

See [1.8.0 release note](/sbt-1.8.0) for the details on 1.8.x features.

### Highlights

- Fixes slf4j 2.x getting pulled into the metabuild [#7115][7115] by [@eed3si9n][@eed3si9n]
- Adds sbtn (GraalVM native client) for Linux on Aarch64 [ipcsocket#33][ipcsocket33], [#7108][7108] etc by [@mkurz][@mkurz] and [@eed3si9n][@eed3si9n]
- Fixes BSP support on Windows by making `PATH` environment variable case insensitive by [#7085][7085] by [@dos65][@dos65]

<!--more-->

### How to upgrade

Download **the official sbt runner + launcher** from `cs setup`, SDKMAN, or download from <https://github.com/sbt/sbt/releases/>.

In addition, the sbt version used for your build is upgraded by putting the following in `project/build.properties`:

```bash
sbt.version=1.8.1
```

This mechanism allows that sbt 1.8.1 is used only for the builds that you want.

### Participation

sbt 1.8.1 was brought to you by 6 contributors. Eugene Yokota (eed3si9n), Matthias Kurz, Andrzej Ressel, Svend Vanderveken, Vadim Chelyshov, dependabot[bot], tagtekinb. Thank you!

Thanks to everyone who's helped improve sbt and Zinc 1 by using them, reporting bugs, improving our documentation, porting builds, porting plugins, and submitting and reviewing pull requests.

For anyone interested in helping sbt, there are many avenues for you to help, depending on your interest. If you're interested, [Contributing](https://github.com/sbt/sbt/blob/develop/CONTRIBUTING.md), ["help wanted"](https://github.com/sbt/sbt/issues?q=is%3Aissue+is%3Aopen+label%3A%22help+wanted%22), ["good first issue"](https://github.com/sbt/sbt/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22) are good starting points. If you have ideas let us know on [sbt Discussions](https://github.com/sbt/sbt/discussions).

### Support Scala Center

Individuals can donate and directly [support Scala Center](/support-scala-center-2022).

### 🏳️‍🌈 Support Ukraine 🇺🇦

Forbidden Colours has started a fundraising campaign to support organisations in Poland, Hungary and Romania that are welcoming LGBTIQ+ refugees.

<https://www.forbidden-colours.com/2022/02/26/support-ukrainian-lgbtiq-refugees/>


  [7115]: https://github.com/sbt/sbt/pull/7115
  [7085]: https://github.com/sbt/sbt/pull/7085
  [7108]: https://github.com/sbt/sbt/pull/7108
  [ipcsocket33]: https://github.com/sbt/ipcsocket/pull/33
  [@eed3si9n]: https://github.com/eed3si9n
  [@Nirvikalpa108]: https://github.com/Nirvikalpa108
  [@adpi2]: https://github.com/adpi2
  [@er1c]: https://github.com/er1c
  [@eatkins]: https://github.com/eatkins
  [@dwijnand]: https://github.com/dwijnand
  [@mkurz]: https://github.com/mkurz
  [@dos65]: https://github.com/dos65
