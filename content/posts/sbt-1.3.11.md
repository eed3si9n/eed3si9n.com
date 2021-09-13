---
title:       "sbt 1.3.11"
type:        story
date:        2020-05-29
draft:       false
promote:     true
sticky:      false
url:         /sbt-1.3.11
aliases:     [ /node/339 ]
tags:        [ "sbt" ]
---

[ivy39]: https://github.com/sbt/ivy/pull/39
  [5059]: https://github.com/sbt/sbt/issues/5059
  [5512]: https://github.com/sbt/sbt/pull/5512
  [5497]: https://github.com/sbt/sbt/issues/5497
  [5535]: https://github.com/sbt/sbt/pull/5535
  [5537]: https://github.com/sbt/sbt/pull/5537
  [5540]: https://github.com/sbt/sbt/pull/5540
  [5563]: https://github.com/sbt/sbt/pull/5563
  [5580]: https://github.com/sbt/sbt/pull/5580
  [launcher75]: https://github.com/sbt/launcher/pull/75
  [@itviewer]: https://github.com/itviewer
  [@eed3si9n]: https://github.com/eed3si9n
  [@retronym]: https://github.com/retronym
  [@drocsid]: https://github.com/drocsid
  [@bjaglin]: https://github.com/bjaglin
  [@dwijnand]: https://github.com/dwijnand

I'm happy to announce sbt 1.3.11 patch release. Full release note is here - https://github.com/sbt/sbt/releases/tag/v1.3.11.

Special thanks to Scala Center. It takes time to review bug reports, pull requests, make sure contributions land to the right places, and Scala Center sponsored me to do maintainer tasks for sbt during May. Darja + whole Scala Center crew have been chill to work with.

### How to upgrade

Normally changing the `project/build.properties` to

```
sbt.version=1.3.11
```

would be ok. However, given that the release may contain fixes to scripts and also because your initial resolution would be faster with `*.(zip|tgz|msi)` that contains all the JAR files, we recommend you use the installer distribution. They will be available from SDKMAN etc:

```
sdk upgrade sbt
```

#### Notes about Homebrew

Homebrew maintainers have added a dependency to JDK 13 because they want to use more brew dependencies [brew#50649](https://github.com/Homebrew/homebrew-core/issues/50649). This causes sbt to use JDK 13 even when `java` available on PATH is JDK 8 or 11.

To prevent `sbt` from running on JDK 13, install [jEnv](https://www.jenv.be/) or switch to using [SDKMAN](https://sdkman.io/).

### Highlights

sbt 1.3.11 updates lm-coursier to [2.0.0-RC6-4](https://github.com/coursier/sbt-coursier/releases/tag/v2.0.0-RC6-4), which deprecates `$HOME/.coursier/cache` directory in favor of OS specific cache locations:

- `$HOME/Library/Caches/Coursier/v1` for macOS
- `%LOCALAPPDATA%\Coursier\Cache\v1` for Windows
- `$HOME/.cache/coursier/v1` for Linux etc

Other fixes:

- Updates Apache Ivy to handle HTTP redirects [ivy#39][ivy39] / [#5059][5059] by [@itviewer][@itviewer]
- Updates sbt-giter8-resolver to 0.12.0, which brings in [`giter8.version` support](http://eed3si9n.com/giter8-0.12.0) in `project/build.properties` [#5537][5537] by [@drocsid][@drocsid]

### Participation

sbt 1.3.11 was brought to you by Scala Center + 7 contributors. Eugene Yokota (eed3si9n), Alexandre Archambault, Brice Jaglin, Colin Williams, Dale Wijnand, Jason Zaugg, and Xinjun Ma. Thank you!

Thanks to everyone who's helped improve sbt and Zinc 1 by using them, reporting bugs, improving our documentation, porting builds, porting plugins, and submitting and reviewing pull requests.

For anyone interested in helping sbt, there are many avenues for you to help, depending on your interest. If you're interested, [Contributing](https://github.com/sbt/sbt/blob/develop/CONTRIBUTING.md), ["help wanted"](https://github.com/sbt/sbt/issues?q=is%3Aissue+is%3Aopen+label%3A%22help+wanted%22), ["good first issue"](https://github.com/sbt/sbt/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22) are good starting points.