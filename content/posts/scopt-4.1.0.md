---
title:       "scopt 4.1.0"
type:        story
date:        2022-07-02
url:         /scopt-4.1.0
tags:        [ "scala" ]
---

scopt 4.1.0 is released. To try new scopt 4.1.0:

```scala
libraryDependencies += "com.github.scopt" %% "scopt" % "4.1.0"
```

scopt 4.1.0 is cross published to the following build matrix:

| Scala Version | JVM | JS (1.x) |  JS (0.6.x) |  Native (0.4.x) |
| ------------- | :-: | :------: | :---------: | :------------:  |
| 3.x           | ✅  |   ✅     |     n/a     |      ✅        |
| 2.13.x        | ✅  |   ✅     |     ✅      |      ✅        |
| 2.12.x        | ✅  |   ✅     |     ✅      |      ✅        |
| 2.11.x        | ✅  |   ✅     |     ✅      |      ✅        |

scopt is a little command line options parsing library. See https://eed3si9n.com/scopt4 or [readme](https://github.com/scopt/scopt) for the details on how to use scopt.

<!--more-->

### Bug fixes

* Fixes scopt  parsing options after encountering `--` by @avdv in [#317][317]
* Fixes #264: nested commands parsing by @cstroe in [#339][339]
* Fixes parsing multiple arguments with `minOccurs(...)` by @jamesfielder in [#314][314]
* Fixes missing `withFallBack` method for `OParser` by @yuanyuma in [#336][336]
* Fixes locale is not working when parsing `java.util.Calendar` by @kururuken in [#319][319]

### Updates

* Supports passing `-` (a single dash) as an argument by @avdv in [#316][316]
* Adds support for parsing `Short` by @bricka in [#335][335]
* Adds support for parsing `scala.io.Source` by @vincentdehaan in [#309][309]
* Adds support for parsing `java.nio.file.Path` by @piegamesde in [#332][332]
* Adds support for parsing `URI` on Scala Native by @xuwei-k in [#331][331]

### Participation

According to `git shortlog` scopt 4.1.0 is brought to you by 12 contributors, most of them first-time contributors. Thanks!

```
$ git shortlog -sn --no-merges v4.0.1...develop
    11  Eugene Yokota
     6  Claudio Bley
     2  xuwei-k
     2  Alex Figl-Brick
     1  kururuken
     1  piegames
     1  pirak
     1  yuanyuma
     1  Cosmin Stroe
     1  James Fielder
     1  Timothy Klim
     1  Vincent de Haan
```

### 🏳️‍🌈 Support Ukraine 🇺🇦

Forbidden Colours has started a fundraising campaign to support organisations in Poland, Hungary and Romania that are welcoming LGBTIQ+ refugees.

<https://www.forbidden-colours.com/2022/02/26/support-ukrainian-lgbtiq-refugees/>

  [314]: https://github.com/scopt/scopt/pull/314
  [317]: https://github.com/scopt/scopt/pull/317
  [339]: https://github.com/scopt/scopt/pull/339
  [336]: https://github.com/scopt/scopt/pull/336
  [319]: https://github.com/scopt/scopt/pull/319
  [316]: https://github.com/scopt/scopt/pull/316
  [335]: https://github.com/scopt/scopt/pull/335
  [309]: https://github.com/scopt/scopt/pull/309
  [331]: https://github.com/scopt/scopt/pull/331
  [332]: https://github.com/scopt/scopt/pull/332
