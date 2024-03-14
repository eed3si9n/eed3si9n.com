---
title:       "Jar Jar Abrams 1.14.0 and sbt-assembly 2.2.0"
type:        story
date:        2024-03-14
url:         /jarjar-abrams-1.14.0-sbt-assembly-2.2.0
tags:        [ "sbt" ]
---

  [jarjar-abrams52]: https://github.com/eed3si9n/jarjar-abrams/pull/52
  [jarjar-abrams53]: https://github.com/eed3si9n/jarjar-abrams/pull/53
  [jarjar-abrams54]: https://github.com/eed3si9n/jarjar-abrams/pull/54
  [520]: https://github.com/sbt/sbt-assembly/pull/520
  [@cdkrot]: https://github.com/cdkrot
  [@patrick-premont]: https://github.com/patrick-premont
  [@shuttie]: https://github.com/shuttie

Jar Jar Abrams 1.14.0 and sbt-assembly 2.2.0 are released.

[Jar Jar Abrams](/jarjar-abrams) is an experimental extension to Jar Jar Links, intended to shade Scala libraries.

<!--more-->

## updates

- Reduces memory usage by avoiding to buffer entry contents during `MergeStrategy.deduplicate` by [@shuttie][@shuttie] in [#520][520]
- Preserves class files during shading when no meaningful transformations are applied by [@cdkrot][@cdkrot] in [jarjar-abrams#52][jarjar-abrams52]
- Modifies `zap` so that it removes matched resources by [@patrick-premont][@patrick-premont] in [jarjar-abrams#53][jarjar-abrams53]
- Removes empty directories after shading by [@patrick-premont][@patrick-premont] in [jarjar-abrams#54][jarjar-abrams54]

sbt-assembly 2.2.0 upgrades the Jar Jar Abrams dependency to 1.14.0.
