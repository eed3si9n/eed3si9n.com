---
title:       "Jar Jar Abrams 1.14.1 and sbt-assembly 2.3.1"
type:        story
date:        2025-01-19
url:         /jarjar-abrams-1.14.1-sbt-assembly-2.3.1
tags:        [ "sbt" ]
---

  [@eed3si9n]: https://github.com/eed3si9n
  [@mzuehlke]: https://github.com/mzuehlke
  [@Locke]: https://github.com/Locke

Jar Jar Abrams 1.14.1 and sbt-assembly 2.3.1 are released.

[Jar Jar Abrams](/jarjar-abrams) is an experimental extension to Jar Jar Links, intended to shade Scala libraries.

<!--more-->

## updates

- Jar Jar Abrams 1.14.1 attempts to fix the resource file shading on Windows by [@eed3si9n][@eed3si9n] in [jarjar-abrams#63](https://github.com/eed3si9n/jarjar-abrams/pull/63)
- Fixes `assemblyOutputPath` by [@mzuehlke][@mzuehlke] in [#548](https://github.com/sbt/sbt-assembly/pull/548)
- Fixes `assemblyExcludedJars` by [@Locke][@Locke] in [#549](https://github.com/sbt/sbt-assembly/pull/549)
