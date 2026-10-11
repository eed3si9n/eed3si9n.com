---
title:       "scopt 4.2.0"
type:        story
date:        2026-10-04
url:         /scopt-4.2.0
tags:        [ "scala" ]
---

scopt 4.2.0 is released. To try new scopt 4.2.0:

```scala
libraryDependencies += "com.github.scopt" %% "scopt" % "4.2.0"
```

scopt 4.2.0 is cross published to the following build matrix:

| Scala Version | JVM | JS (1.x) |  Native (0.5.x) |
| ------------- | :-: | :------: | :------------:  |
| 3.x           | ✅  |   ✅     |      ✅         |
| 2.13.x        | ✅  |   ✅     |      ✅         |
| 2.12.x        | ✅  |   ✅     |      ✅         |

scopt 4.2 and later require JDK 17 for Scala 3.x.

scopt is a little command line options parsing library. See https://eed3si9n.com/scopt4 or [readme](https://github.com/scopt/scopt) for the details on how to use scopt.

<!--more-->

### Space-separated list

scopt 4.2.0 adds support for space-separated list (as opposed to comma-separated list).

```scala
val spaceSepParser1 = new scopt.OptionParser[Config]("scopt") {
  head("scopt", "4.x")
  opt[SpaceSep[Int]]('f', "foo").action({ case (s, c) =>
    c.copy(spaceSepInts = s)
  })
  help("help")
}
```

This was contributed by [@NancyD2017][@NancyD2017] in [#367](https://github.com/scopt/scopt/pull/367).

### Other updates


* Use Scala 3.9.0 by [@eed3si9n][@eed3si9n] in [#368](https://github.com/scopt/scopt/pull/368)

### Participation

According to `git shortlog` scopt 4.2.0 is brought to you by 6 contributors. Thanks!

```
$ git shortlog -sn --no-merges v4.1.0...develop
     13  Kenji Yoshida (xuwei-k)
     6   Eugene Yokota
     1   Anastasiia
     1   Jeff Cousens
     1   Lorenzo Gabriele
     1   Yosef Fertel
```

  [@eed3si9n]: https://github.com/eed3si9n
  [@NancyD2017]: https://github.com/NancyD2017
