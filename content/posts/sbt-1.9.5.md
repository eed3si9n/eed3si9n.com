---
title:       "sbt 1.9.5"
type:        story
date:        2023-09-14
url:         /sbt-1.9.5
tags:        [ "sbt" ]
---

**Update**: ⚠️ sbt 1.9.5 is broken, because it causes Scala compiler to generate wrong class names for anonymous class on lambda. Please refrain from publishing libraries with it while we investigate. See [cala/bug#12868](https://github.com/scala/bug/issues/12868#issuecomment-1720848704) for details.

Hi everyone. On behalf of the sbt project, I'm happy to announce sbt 1.9.5 patch release is available. Full release note is here - https://github.com/sbt/sbt/releases/tag/v1.9.5

See [1.9.0 release note](/sbt-1.9.0) for the details on 1.9.x features.

### Highlights

- Switches to pre-compiled compiler bridge for Scala 2.13.12+ [#7374][7374] by [@eed3si9n][@eed3si9n]
- Fixes NPE when just `-X` is passed to `scalacOptions` [zinc#1246][zinc1246] by [@unkarjedy][@unkarjedy]

<!--more-->

### How to upgrade

The sbt version used for your build must be upgraded by putting the following in `project/build.properties`:

```bash
sbt.version=1.9.5
```

This mechanism allows that sbt 1.9.5 is used only for the builds that you want.

Download **the official sbt runner** from, `cs setup`, SDKMAN, or download from <https://github.com/sbt/sbt/releases/tag/v1.9.5> to upgrade the `sbt` shell script and the launcher.

## Other updates

- Fixes internal representation of class symbol names [zinc#1244][zinc1244] by [@dwijnand][@dwijnand]
- Fixes `NumberFormatException` in `CrossVersionUtil.binaryScalaVersion` [lm#426][lm426] by [@HelloKunal][@HelloKunal]
- Fixes `scripted` client/server instability on Windows [#7087][7087] by [@mdedetrich][@mdedetrich]
- Fixes `sbt` launcher script bug on Windows [#7365][7365] by [@JD557][@JD557]
- Fixes `help` command on oldshell [#7358][7358] by [@azdrojowa123][@azdrojowa123]
- Adds `allModuleReports` to `UpdateReport` [lm#428][lm428] by [@mdedetrich][@mdedetrich]
- Handles javac warning messages [zinc#1228][zinc1228] by [@Arthurm1][@Arthurm1]
- Enables inliner for Scala 2.13 compiler bridge [zinc#1247][zinc1247] by [@mdedetrich][@mdedetrich]

### Participation

Thanks to everyone who's helped improve sbt and Zinc by using them, reporting bugs, improving our documentation, porting builds, porting plugins, and submitting and reviewing pull requests.

For anyone interested in helping sbt, there are many avenues for you to help, depending on your interest. If you're interested, [Contributing](https://github.com/sbt/sbt/blob/develop/CONTRIBUTING.md), ["help wanted"](https://github.com/sbt/sbt/issues?q=is%3Aissue+is%3Aopen+label%3A%22help+wanted%22), ["good first issue"](https://github.com/sbt/sbt/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22), and [Discussions](https://github.com/sbt/sbt/discussions/) are good starting points.

----

### 🏳️‍🌈 Support Ukraine 🇺🇦

Forbidden Colours has started a fundraising campaign to support organisations in Poland, Hungary and Romania that are welcoming LGBTIQ+ refugees.

<https://www.forbidden-colours.com/2022/02/26/support-ukrainian-lgbtiq-refugees/>

### Donate to Scala Center

Scala Center is a non-profit center at EPFL to support education and open source.

- [The Scala Center Fundraising Campaign](https://scala-lang.org/blog/2023/09/11/scala-center-fundraising.html)

  [@eed3si9n]: https://github.com/eed3si9n
  [@Nirvikalpa108]: https://github.com/Nirvikalpa108
  [@adpi2]: https://github.com/adpi2
  [@er1c]: https://github.com/er1c
  [@eatkins]: https://github.com/eatkins
  [@dwijnand]: https://github.com/dwijnand
  [@mdedetrich]: https://github.com/mdedetrich
  [@JD557]: https://github.com/JD557
  [@azdrojowa123]: https://github.com/azdrojowa123
  [@HelloKunal]: https://github.com/HelloKunal
  [@unkarjedy]: https://github.com/unkarjedy
  [@Arthurm1]: https://github.com/Arthurm1
  [7374]: https://github.com/sbt/sbt/pull/7374
  [7087]: https://github.com/sbt/sbt/pull/7087
  [7365]: https://github.com/sbt/sbt/issues/7365
  [7358]: https://github.com/sbt/sbt/pull/7358
  [zinc1246]: https://github.com/sbt/zinc/pull/1246
  [zinc1244]: https://github.com/sbt/zinc/pull/1244
  [zinc1228]: https://github.com/sbt/zinc/pull/1228
  [zinc1247]: https://github.com/sbt/zinc/pull/1247
  [lm426]: https://github.com/sbt/librarymanagement/pull/426
  [lm428]: https://github.com/sbt/librarymanagement/pull/428
