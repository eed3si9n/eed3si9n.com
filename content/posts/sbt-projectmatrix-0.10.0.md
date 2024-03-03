---
title:       "sbt-projectmatrix 0.10.0"
type:        story
date:        2024-03-01
url:         /sbt-projectmatrix-0.10.0
tags:        [ "sbt" ]
---

I've released [sbt-projectmatrix](https://github.com/sbt/sbt-projectmatrix) 0.10.0.

<!--more-->

## about sbt-projectmatrix

sbt-projectmatrix is a new implementation of cross building feature that encodes cross build as subprojects. The following will create core and core2_12. Unlike ++ style stateful cross building, these will build in parallel.

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

## updates

* Adds `projectMatrixBaseDirectory` setting by @hugo-vrijswijk in [#88][88]
* Adds support for non-matrix projects to be aggregated in and depended on by matrix projects by @vilunov in [#89][89]

  [88]: https://github.com/sbt/sbt-projectmatrix/pull/88
  [89]: https://github.com/sbt/sbt-projectmatrix/pull/89
