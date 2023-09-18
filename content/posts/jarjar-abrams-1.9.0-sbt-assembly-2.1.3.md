---
title:       "Jar Jar Abrams 1.9.0 and sbt-assembly 2.1.3"
type:        story
date:        2023-09-17
url:         /jarjar-abrams-1.9.0-sbt-assembly-2.1.3
tags:        [ "sbt" ]
---

  [jarjar-abrams35]: https://github.com/eed3si9n/jarjar-abrams/pull/35
  [jarjar-abrams34]: https://github.com/eed3si9n/jarjar-abrams/pull/34
  [@kterusaki]: https://github.com/kterusaki
  [@daniellansun]: https://github.com/daniellansun

Jar jar Abrams 1.9.0 and sbt-assembly 2.1.3 are released with security vulnerability fixes.

[Jar Jar Abrams](https://eed3si9n.com/jarjar-abrams) is an experimental extension to Jar Jar Links, intended to shade Scala libraries.

<!--more-->

## security fix

- Jar jar Abrams maintains a fork of Jar Jar Links, which has depended on Ant and maven-plugin-api. Version 1.8.3 updates Ant and maven-plugin-api, to fix security vulnerabilities ([CVE-2020-11979](https://github.com/advisories/GHSA-f62v-xpxf-3v68) etc), contributed by [@kterusaki][@kterusaki] in [#35][jarjar-abrams35]. Version 1.9.0 separates Ant and maven-plugin-api plugins to different artifacts, so they do not bleed into sbt-assembly etc.


## update

- Updates ASM to 9.5 by [@daniellansun][@daniellansun] in [#34][jarjar-abrams34]

sbt-assembly 2.1.3 upgrades the Jar Jar Abrams dependency to 1.9.0.
