---
title:       "sbt-buildinfo 0.10.0"
type:        story
date:        2020-08-09
draft:       false
promote:     true
sticky:      false
url:         /sbt-buildinfo-0.10.0
aliases:     [ /node/351 ]
tags:        [ "sbt" ]
---

 [111]: https://github.com/sbt/sbt-buildinfo/pull/111
 [126]: https://github.com/sbt/sbt-buildinfo/pull/126
 [128]: https://github.com/sbt/sbt-buildinfo/pull/128
 [141]: https://github.com/sbt/sbt-buildinfo/pull/141
 [150]: https://github.com/sbt/sbt-buildinfo/pull/150
 [151]: https://github.com/sbt/sbt-buildinfo/pull/151
 [155]: https://github.com/sbt/sbt-buildinfo/pull/155
 [156]: https://github.com/sbt/sbt-buildinfo/pull/156
 [157]: https://github.com/sbt/sbt-buildinfo/pull/157
 [164]: https://github.com/sbt/sbt-buildinfo/pull/164
 [@dwijnand]: https://github.com/dwijnand
 [@yarosman]: https://github.com/yarosman
 [@damdev]: https://github.com/damdev
 [@eed3si9n]: https://github.com/eed3si9n
 [@xuwei-k]: https://github.com/xuwei-k
 [@smarter]: https://github.com/smarter
 [@pcejrowski]: https://github.com/pcejrowski
 [@bilal-fazlani]: https://github.com/bilal-fazlani
 [@xerial]: https://github.com/xerial
 [@leviramsey]: https://github.com/leviramsey

I'm happy to announce sbt-buildinfo 0.10.0. [sbt-buildinfo](https://github.com/sbt/sbt-buildinfo) is a small sbt plugin to generate `BuildInfo` object from your build definitions.

Since the last feature release was in 2018, there have been some pending contributions. I think the important thing is that it compiles with `-Xlint` and `-Xfatal-warnings` on both Scala 2.13.3 and 2.12.12.

<!--more-->

### Breaking change: scala.collection.immutable.Seq

sbt-buidinfo 0.10.0 will generate `scala.collection.immutable.Seq(...)` instead of `scala.collection.Seq(...)`.

This was contributed as [#150][150] by [@smarter][@smarter].

### Breaking change: output local time

sbt-buildinfo 0.10.0 will output build time in local time (using JSR-310 `java.time.Instant`) with timezone string.

```scala
buildInfoOptions += BuildInfoOption.BuildTime
```

This was contributed as [#156][156]/[#157][157] by [@xerial][@xerial] and [@leviramsey][@leviramsey]

### BuildInfoOption.PackagePrivate

```scala
buildInfoOptions += BuildInfoOption.PackagePrivate
```

sbt-buidinfo 0.10.0 adds a new option to make `BuildInfo` package private. This was contributed as [#151][151] by [@pcejrowski][@pcejrowski].

### BuildInfoOption.ConstantValue

```scala
buildInfoOptions ++= Seq(BuildInfoOption.ConstantValue, BuildInfoOption.PackagePrivate)
```

sbt-buidinfo 0.10.0 adds a new option to make `BuildInfo` fields [constant value definitions](https://www.scala-lang.org/files/archive/spec/2.12/04-basic-declarations-and-definitions.html#value-declarations-and-definitions) when possible.

```scala
package hello

import scala.Predef._

private[hello] case object BuildInfo {
  /** The value is "helloworld". */
  final val name = "helloworld"
  /** The value is "0.1". */
  final val version = "0.1"

  ....
}
```

We recommend making `BuildInfo` package private if you use this option. [#164][164] by [@eed3si9n][@eed3si9n]

### bug fixes and updates

- Fixes macro hygiene [#128][128] by [@dwijnand][@dwijnand]
- Fixes JSON output [#126][126] by [@yarosman][@yarosman]
- Fixes `ScalaCaseClassRenderer` rendering [#111][111] by [@damdev][@damdev]
- Fixes symbol literals by [@eed3si9n][@eed3si9n]
- Adds testing on JDK 11 [#141][141] by [@xuwei-k][@xuwei-k]
- Adds `// $COVERAGE-OFF$` ... `// $COVERAGE-ON$` [#155][155] by [@bilal-fazlani][@bilal-fazlani]

### contributors

sbt-buildinfo 0.10.0 is brought to you by the following contributors:

<code>
    10  Eugene Yokota (eed3si9n)
     9  Kenji Yoshida (xuwei-k)
     4  Philippus
     3  Mitchell Skaggs
     3  Yaroslav Derman
     2  Filipe Regadas
     2  Pawel Cejrowski
     1  Andreas Flierl
     1  Dale Wijnand
     1  Taro L. Saito
     1  Bilal Fazlani
     1  dfranetovich
     1  joriscode
     1  Guillaume Martres
     1  Frank S. Thomas
     1  Levi Ramsey
</code>

Thanks!