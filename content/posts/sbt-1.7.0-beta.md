---
title:       "sbt 1.7.0-RC1"
type:        story
date:        2022-06-27
url:         /sbt-1.7.0-beta
tags:        [ "sbt" ]
---

Hi everyone. On behalf of the sbt project, I am happy to announce sbt 1.7.0-RC1. This is the seventh feature release of sbt 1.x, a binary compatible release focusing on new features. sbt 1.x is released under Semantic Versioning, and the plugins are expected to work throughout the 1.x series. Please try it out, and report any issues you might come across.

<!--more-->

### How to upgrade

Download **the official sbt runner** from SDKMAN or download from <https://github.com/sbt/sbt/releases/tag/v1.7.0-RC1>.

The sbt version used for your build is upgraded by putting the following in `project/build.properties`:

```bash
sbt.version=1.7.0-RC1
```

This mechanism allows that sbt 1.7.0-RC1 is used only for the builds that you want.

### Changes with compatibility implications

- Drops OkHttp 3.x dependency [lm#399][lm399] by [@eed3si9n][@eed3si9n]
- Updates to Scala 2.12.16
- Moves domain socket location to `XDG_RUNTIME_DIR` and `/tmp` [#6887][6887] by [@AlonsoM45][@AlonsoM45]
- Deprecates `Resolver.sonatypeRepo` and adds `Resolver.sonatypeOssRepos`, which includes https://s01.oss.sonatype.org/ [lm393][lm393] by [@armanbilge][@armanbilge]

### `++` command updates

Previously `++ <sv> <command1>` filtered subprojects using `crossScalaVersions` having the same ABI suffix as `<sv>`. This incorrectly matched subprojects with `3.1.3` when `++ 3.0.1 test` is given. sbt 1.7.0 fixes this by requiring `++ <sv> <command1>` to be backward compatible. [Rui Gonçalves](https://github.com/ruippeixotog) contributed this fix as [lm#400][lm400].

In [#6894][6894], [Arnout Engelen](https://github.com/raboof) contributed expansion to `++ <sv> <command1>` so `<sv>` part can be given as a [semantic version selector](https://github.com/npm/node-semver) expression, such as `2.13.x`. Note that the expression may match at most one Scala version to switch into.

### Scala 3 compiler error improvements

In [zinc#1082][zinc1082], [Toshiyuki Takahashi](https://github.com/tototoshi) contributed a fix to ignore `Problem#rendered` passed from the compiler when sbt uses position mapper to transform the position. This is aimed at fixing the error reporting for Play on Scala 3.

In [#6874][6874], [Chris Kipp](https://github.com/ckipp01) extended `xsbti.Problem` to track richer information available in Scala 3. This is aimed at enhancing the compilation errors reported to BSP client such as Metals.

### BSP updates

- Fixes sbt sending cumulative `build/publishDiagnostics` in BSP [#6847][6847] by [@tanishiking][@tanishiking]
- Adds optional framework field to the BSP response [#6830][6830] by [@kpodsiad][@kpodsiad]
- Adds BSP environment request support [#6858][6858] by [@kpodsiad][@kpodsiad]

### Other updates

- Fixes ipcsocket JNI cleanup code deleting empty directories in `/tmp` [ipc#23][ipc23] by [@eed3si9n][@eed3si9n]
- Fixes command argument parsing with quotes in `-a="b c"` pattern [#6816][6816] by [@Nirvikalpa108][@Nirvikalpa108]
- Fixes `ThisBuild / includePluginResolvers` [#6849][6849] by [@bjaglin][@bjaglin]
- Fixes watchOnTermination callbacks [#6870][6870] by [@eatkins][@eatkins]

### 🏳️‍🌈 Support Ukraine 🇺🇦

Forbidden Colours has started a fundraising campaign to support organisations in Poland, Hungary and Romania that are welcoming LGBTIQ+ refugees.

<https://www.forbidden-colours.com/2022/02/26/support-ukrainian-lgbtiq-refugees/>

### Donate to Play

- https://www.playframework.com/sponsors

  [@eed3si9n]: https://github.com/eed3si9n
  [@Nirvikalpa108]: https://github.com/Nirvikalpa108
  [@adpi2]: https://github.com/adpi2
  [@er1c]: https://github.com/er1c
  [@eatkins]: https://github.com/eatkins
  [@dwijnand]: https://github.com/dwijnand
  [@kpodsiad]: https://github.com/kpodsiad
  [@bjaglin]: https://github.com/bjaglin
  [@tanishiking]: https://github.com/tanishiking
  [@AlonsoM45]: https://github.com/AlonsoM45
  [@armanbilge]: https://github.com/armanbilge
  [6814]: https://github.com/sbt/sbt/pull/6814
  [6816]: https://github.com/sbt/sbt/pull/6816
  [6830]: https://github.com/sbt/sbt/pull/6830
  [6849]: https://github.com/sbt/sbt/pull/6849
  [6847]: https://github.com/sbt/sbt/pull/6847
  [6874]: https://github.com/sbt/sbt/pull/6874
  [6870]: https://github.com/sbt/sbt/pull/6870
  [6858]: https://github.com/sbt/sbt/pull/6858
  [6887]: https://github.com/sbt/sbt/pull/6887
  [6894]: https://github.com/sbt/sbt/pull/6894
  [zinc1082]: https://github.com/sbt/zinc/pull/1082
  [lm393]: https://github.com/sbt/librarymanagement/pull/393
  [lm399]: https://github.com/sbt/librarymanagement/pull/399
  [lm400]: https://github.com/sbt/librarymanagement/pull/400
  [ipc23]: https://github.com/sbt/ipcsocket/pull/23
