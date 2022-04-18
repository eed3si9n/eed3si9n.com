---
title:       "sbt 1.7.0-M2"
type:        story
date:        2022-04-17
url:         /sbt-1.7.0-beta
tags:        [ "sbt" ]
---

Hi everyone. On behalf of the sbt project, I am happy to announce sbt 1.7.0-M2. This is the seventh feature release of sbt 1.x, a binary compatible release focusing on new features. sbt 1.x is released under Semantic Versioning, and the plugins are expected to work throughout the 1.x series. Please try it out, and report any issues you might come across.

<!--more-->

### How to upgrade

<!--
Download **the official sbt runner** from SDKMAN or download from <https://github.com/sbt/sbt/releases/tag/v1.6.0-RC2>.
-->

The sbt version used for your build is upgraded by putting the following in `project/build.properties`:

```bash
sbt.version=1.7.0-M2
```

This mechanism allows that sbt 1.7.0-M1 is used only for the builds that you want.

### Scala 3 forward compatibility support

sbt 1.7.0 implements support for Scala 3.1.2's improved forward compatibility feature.

```scala
ThisBuild / scalaVersion       := "3.1.2"
ThisBuild / scalaOutputVersion := "3.0.2"
```

This sets the `-scala-output-version` compiler option to `3.0`, which lets us generate TASTy files and bytecode compatible with older Scala 3.x versions, while using newer Scala 3.x compiler at runtime. In addition, runtime Scala version and POM entries are also downgraded to `3.0.2`.

The sbt support for this was contributed by Michał Pałka at VirtusLab as [#6814][6814].

### Scala 3 compiler error improvements

In [zinc#1082][zinc1082], [Toshiyuki Takahashi](https://github.com/tototoshi) contributed a fix to ignore `Problem#rendered` passed from the compiler when sbt uses position mapper to transform the position. This is aimed at fixing the error reporting for Play on Scala 3.

In [#6874][6874], [Chris Kipp](https://github.com/ckipp01) extended `xsbti.Problem` to track richer information available in Scala 3. This is aimed at enhancing the compilation errors reported to BSP client such as Metals.

### BSP updates

- Fixes sbt sending cumulative `build/publishDiagnostics` in BSP [#6847][6847] by [@tanishiking][@tanishiking]
- Adds optional framework field to the BSP response [#6830][6830] by [@kpodsiad][@kpodsiad]
- Adds BSP environment request support [#6858][6858] by [@kpodsiad][@kpodsiad]

### Other updates

- Fixes command argument parsing with quotes in `-a="b c"` pattern [#6816][6816] by [@Nirvikalpa108][@Nirvikalpa108]
- Fixes `ThisBuild / includePluginResolvers` [#6849][6849] by [@bjaglin][@bjaglin]
- Fixes watchOnTermination callbacks [#6870][6870] by [@eatkins][@eatkins]

  [@eed3si9n]: https://github.com/eed3si9n
  [@Nirvikalpa108]: https://github.com/Nirvikalpa108
  [@adpi2]: https://github.com/adpi2
  [@er1c]: https://github.com/er1c
  [@eatkins]: https://github.com/eatkins
  [@dwijnand]: https://github.com/dwijnand
  [@kpodsiad]: https://github.com/kpodsiad
  [@bjaglin]: https://github.com/bjaglin
  [@tanishiking]: https://github.com/tanishiking
  [6814]: https://github.com/sbt/sbt/pull/6814
  [6816]: https://github.com/sbt/sbt/pull/6816
  [6830]: https://github.com/sbt/sbt/pull/6830
  [6849]: https://github.com/sbt/sbt/pull/6849
  [6847]: https://github.com/sbt/sbt/pull/6847
  [6874]: https://github.com/sbt/sbt/pull/6874
  [6870]: https://github.com/sbt/sbt/pull/6870
  [6858]: https://github.com/sbt/sbt/pull/6858
  [zinc1082]: https://github.com/sbt/zinc/pull/1082
