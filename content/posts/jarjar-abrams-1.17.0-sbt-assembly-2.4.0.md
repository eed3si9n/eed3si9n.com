---
title: "Jar Jar Abrams 1.17.0 and sbt-assembly 2.4.0"
type: story
date: 2026-07-22
url: /jarjar-abrams-1.17.0-sbt-assembly-2.4.0
tags: [ "sbt" ]
---

Jar Jar Abrams 1.17.0 and sbt-assembly 2.4.0 are released.

[Jar Jar Abrams](/jarjar-abrams) is an experimental extension to Jar Jar Links, intended to shade Scala libraries.

<!--more-->

## 🐛 bug fixes

* fix: Fixes `keep` directive, race condition, and improve logging by [@holtherndon-stripe][@holtherndon-stripe] in [jarjar-abrams#88](https://github.com/eed3si9n/jarjar-abrams/pull/88)
* fix: Fixes `keep` by separating the process by [@shanielh][@shanielh] in [#575](https://github.com/sbt/sbt-assembly/pull/575)
* fix: Fixes file merging by [@piotrp][@piotrp] in [#571](https://github.com/sbt/sbt-assembly/pull/571)
* fix: Fixes `$` handling in patterns by [@szeiger][@szeiger] in [jarjar-abrams#64](https://github.com/eed3si9n/jarjar-abrams/pull/64)
* fix: Fixes inlining losing constant pool after shading by [@kitbellew][@kitbellew] in [jarjar-abrams#94](https://github.com/eed3si9n/jarjar-abrams/pull/94)

## updates

* deps: ASM 9.10.1 by [@eed3si9n][@eed3si9n] in [jarjar-abrams#95](https://github.com/eed3si9n/jarjar-abrams/pull/95)
* deps: jarjar-abrams-core 1.17.0 by [@eed3si9n][@eed3si9n] in [#575](https://github.com/sbt/sbt-assembly/pull/575)

  [@eed3si9n]: https://github.com/eed3si9n
  [@holtherndon-stripe]: https://github.com/holtherndon-stripe
  [@shanielh]: https://github.com/shanielh
  [@piotrp]: https://github.com/piotrp
  [@szeiger]: https://github.com/szeiger
  [@kitbellew]: https://github.com/kitbellew
