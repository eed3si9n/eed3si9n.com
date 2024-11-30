---
title:       "sbt-projectmatrix 0.10.1"
type:        story
date:        2024-11-24
url:         /sbt-projectmatrix-0.10.1
tags:        [ "sbt" ]
---

  [@kijuky]: https://github.com/kijuky
  [@eed3si9n]: https://github.com/eed3si9n

I've released sbt-projectmatrix 0.10.1. Full release note is <https://github.com/sbt/sbt-projectmatrix/releases/tag/v0.10.1>.

<!--more-->

## about sbt-projectmatrix

sbt-projectmatrix is a future implementation of cross building feature that encodes cross build as subprojects. The following will create `core` and `core2_12`. Unlike `++` style stateful cross building, these will build in parallel.

```scala
ThisBuild / organization := "com.example"
ThisBuild / scalaVersion := "2.13.13"
ThisBuild / version      := "0.1.0-SNAPSHOT"

lazy val core = (projectMatrix in file("core"))
  .settings(
    name := "core"
  )
  .jvmPlatform(scalaVersions = Seq("2.13.13", "2.12.19"))
```

In addition, cross building against Scala.JS, Scala Native, or arbitrary virtual axis is also supported. See previous posts [part 1](/parallel-cross-building-using-sbt-projectmatrix), [part 2](/parallel-cross-building-with-virtualaxis), and [part 3](/parallel-cross-building-part3) for more details.

## fixes Scala 2.13-3.x sandwich support

In case you're not aware, Scala 3.x series shares the standard library with Scala 2.13.x series, and through compatibility efforts like TASTy reader, libraries compiled against Scala 2.13 and 3.x can interoperate with each other. I've been calling this Scala 2.13-3.x sandwich:

- Apps compiled against Scala 2.13.x can depend on the following layers
- Libraries compiled against Scala 3.x can depend on the following layers
- scala-library, and libraries that depend only on Scala 2.13

I implemented [parallel cross building sandwich](/parallel-cross-building-sandwich), before Scala 3.0 actually shipped, and apparently it worked only for beta versions. I recently fixed this on sbt 2.x code base, and [#97](https://github.com/sbt/sbt-projectmatrix/pull/97) backports some parts of the fix so Scala 2.13-3.x sandwich actually works with projectMatrix.

## updates

* fix: Fixes `lib/` directory support by [@kijuky][@kijuky] in [#91](https://github.com/sbt/sbt-projectmatrix/pull/91)
