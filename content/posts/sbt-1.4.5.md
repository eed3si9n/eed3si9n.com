---
title:       "sbt 1.4.5"
type:        story
date:        2020-12-14
changed:     2021-01-18
draft:       false
promote:     false
sticky:      false
url:         /sbt-1.4.5
aliases:     [ /node/375 ]
tags:        [ "sbt" ]
---

I'm happy to announce sbt 1.4.5 patch release is available. Full release note is here - https://github.com/sbt/sbt/releases/tag/v1.4.5

### How to upgrade

Download **the official sbt launcher** from SDKMAN or download from <https://github.com/sbt/sbt/releases/>.

In addition, the sbt version used for your build is upgraded by putting the following in `project/build.properties`:

<code>
sbt.version=1.4.5
</code>

This mechanism allows that sbt 1.4.5 is used only for the builds that you want.

### Highlights

- sbt 1.4.5 adds support for Apple silicon (AArch64 also called ARM64) [#6162][6162]/[#6169][6169] by [@eatkins][@eatkins]
- Updates to Coursier 2.0.7 [#6120][6120] by [@jtjeferreira][@jtjeferreira]
- Fixes watch shell option [#6166][6166] by [@eatkins][@eatkins]
- Fixes `onLoad` to run with the correct `FileTreeRepository` and `CacheStoreFactory` [#6190][6190] by [@mkurz][@mkurz]

### Participation

sbt 1.4.5 was brought to you by 4 contributors. Ethan Atkins, Matthias Kurz, Eugene Yokota (eed3si9n), João Ferreira. Thank you!

Thanks to everyone who's helped improve sbt and Zinc 1 by using them, reporting bugs, improving our documentation, porting builds, porting plugins, and submitting and reviewing pull requests.

For anyone interested in helping sbt, there are many avenues for you to help, depending on your interest. If you're interested, [Contributing](https://github.com/sbt/sbt/blob/develop/CONTRIBUTING.md), ["help wanted"](https://github.com/sbt/sbt/issues?q=is%3Aissue+is%3Aopen+label%3A%22help+wanted%22), ["good first issue"](https://github.com/sbt/sbt/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22) are good starting points. If you have ideas let us know on [sbt Discussions](https://github.com/sbt/sbt/discussions).

### Donate to April

Apparently April, an active contributor to Scala compiler has been sick without diagnosis. Let's help her out!

https://www.gofundme.com/f/help-april-survive-while-sick

  [6162]: https://github.com/sbt/sbt/issues/6162
  [6169]: https://github.com/sbt/sbt/pull/6169
  [6166]: https://github.com/sbt/sbt/pull/6166
  [6120]: https://github.com/sbt/sbt/pull/6120
  [6190]: https://github.com/sbt/sbt/pull/6190
  [@adpi2]: https://github.com/adpi2
  [@eed3si9n]: https://github.com/eed3si9n
  [@eatkins]: https://github.com/eatkins
  [@jtjeferreira]: https://github.com/jtjeferreira
  [@mkurz]: https://github.com/mkurz
