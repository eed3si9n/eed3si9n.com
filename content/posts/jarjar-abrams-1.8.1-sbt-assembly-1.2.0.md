---
title:       "Jar Jar Abrams 1.8.1 and sbt-assembly 1.2.0"
type:        story
date:        2022-02-13
url:         /jarjar-abrams-1.8.1-sbt-assembly-1.2.0
tags:        [ "sbt" ]
---

  [@vladimirkl]: https://github.com/vladimirkl
  [@gabrielrussoc]: https://github.com/gabrielrussoc
  [@er1c]: https://github.com/er1c
  [jarjar-abrams24]: https://github.com/eed3si9n/jarjar-abrams/pull/24
  [jarjar-abrams21]: https://github.com/eed3si9n/jarjar-abrams/pull/21
  [jarjar-abrams23]: https://github.com/eed3si9n/jarjar-abrams/pull/23

Jar Jar Abrams 1.8.1 and sbt-assembly 1.2.0 are released.

[Jar Jar Abrams](https://eed3si9n.com/jarjar-abrams) is an experimental extension to Jar Jar Links, intended to shade Scala libraries.

<!--more-->

## bug fixes

- Fixes "UTF8 string too large" error in ScalaSigAnnotationVisitor [jarjar-abrams#24][jarjar-abrams24] by [@vladimirkl][@vladimirkl]

## enhancements

- Adds support for service providers [jarjar-abrams#21][jarjar-abrams21] by [@gabrielrussoc][@gabrielrussoc]
- Publishes the über JAR of `jarjar` as `jarjar-assembly.jar` by [@er1c][@er1c] in [jarjar-abrams#23][jarjar-abrams23]

sbt-assembly 1.2.0 upgrades the Jar Jar Abrams dependency to 1.8.1.
