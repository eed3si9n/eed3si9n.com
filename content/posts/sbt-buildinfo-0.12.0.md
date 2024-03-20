---
title:       "sbt-buildinfo 0.12.0"
type:        story
date:        2024-03-20
url:         /sbt-buildinfo-0.12.0
tags:        [ "sbt" ]
---

  [198]: https://github.com/sbt/sbt-buildinfo/pull/198

sbt-buildinfo 0.12.0 is released. [sbt-buildinfo](https://github.com/sbt/sbt-buildinfo) is a small sbt plugin to generate `BuildInfo` object from your build definitions.

<!--more-->

### Scala 3 support

sbt-buildinfo 0.12.0 adds Scala 3 support. Prior to this release `toJson` method would emit warnings on Scala 3. This fixes it by adding new renderers for Scala 3.

This change was contributed by Roland Reckel in [#198][198].
