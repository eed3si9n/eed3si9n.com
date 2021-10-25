---
title:       "sbt 1.4.9"
type:        story
date:        2021-03-10
draft:       false
promote:     true
sticky:      false
url:         /sbt-1.4.9
aliases:     [ /node/385 ]
tags:        [ "sbt" ]
---

  [6290]: https://github.com/sbt/sbt/pull/6290
  [6326]: https://github.com/sbt/sbt/pull/6326
  [6352]: https://github.com/sbt/sbt/pull/6352
  [6353]: https://github.com/sbt/sbt/pull/6353
  [6366]: https://github.com/sbt/sbt/pull/6366
  [@takezoe]: https://github.com/takezoe
  [@RafalSumislawski]: https://github.com/RafalSumislawski
  [@mkurz]: https://github.com/mkurz
  [@sideeffffect]: https://github.com/sideeffffect
  [@eed3si9n]: https://github.com/eed3si9n

I'm happy to announce sbt 1.4.9 patch release is available. Full release note is here - https://github.com/sbt/sbt/releases/tag/v1.4.9

### How to upgrade

Download **the official sbt launcher** from SDKMAN or download from <https://github.com/sbt/sbt/releases/>.

In addition, the sbt version used for your build is upgraded by putting the following in `project/build.properties`:

```bash
sbt.version=1.4.9
```

This mechanism allows that sbt 1.4.9 is used only for the builds that you want.

### Highlights

- sbt 1.4.9 fixes JLine 2 fork + JAnsi version to match that of JLine 3.19.0 to fix line reading, which among other things affected IntelliJ import.
- sbt 1.4.9 is a maintenance patch. The most notable thing is that this was that it was released without using Bintray, and a few things were dropped. See below for details.

### Changes with compatibility implications

sbt 1.4.9 is published to Sonatype OSS without going through Bintray.

- Prior to 1.4.8, `sbt-launcher` was published **twice** under `sbt-launch.jar` and Maven-compatible `sbt-launch-<version>.jar`. We're no longer going to publish the Maven incompatible form of the launcher JAR. The latest sbt-extras has already migrated to the correct URL, but CI environments using an older version of it may experience disruptions.
- DEB and RPM packages are not provided for this release. I hope we will have a replacement repo up to eventually be able to support this, but we do not have one yet. For now, download `*.tgz` from GitHub release.

### Migration note for Travis CI

If you're using Travis CI, you might run into the above issue because it's using an older version of sbt-extras. Here's how you can use the official sbt launcher script instead:

```bash
install:
  - |
    # update this only when sbt-the-bash-script needs to be updated
    export SBT_LAUNCHER=1.4.9
    export SBT_OPTS="-Dfile.encoding=UTF-8"
    curl -L --silent "https://github.com/sbt/sbt/releases/download/v$SBT_LAUNCHER/sbt-$SBT_LAUNCHER.tgz" > $HOME/sbt.tgz
    tar zxf $HOME/sbt.tgz -C $HOME
    sudo rm /usr/local/bin/sbt
    sudo ln -s $HOME/sbt/bin/sbt /usr/local/bin/sbt
script:
  - sbt -v "+test"
```

### Fixes

- Fixes `sourcePositionMappers` added by Play not getting called [#6352][6352] by [@mkurz][@mkurz]
- Upgrade to JLine 3.19.0 to work around Scala 2.13.5 REPL breakage [#6366][6366] by [@eed3si9n][@eed3si9n]
- Fixes concurrent `testQuick` leading to an infinite loop [#6326][6326] by [@RafalSumislawski][@RafalSumislawski]
- Fixes `ZipEntry` timestamp to 2010-01-01 to prevent negative value [#6290][6290] by [@takezoe][@takezoe]
- Display a better error message for "sbt server is already booting" problem [#6353][6353] by [@sideeffffect][@sideeffffect]

### Participation

sbt 1.4.9 (1.4.8) was brought to you by 6 contributors. Ethan Atkins, Eugene Yokota (eed3si9n), Matthias Kurz, Naoki Takezoe, Ondra Pelech, Rafał Sumisławski. Thank you!

Thanks to everyone who's helped improve sbt and Zinc 1 by using them, reporting bugs, improving our documentation, porting builds, porting plugins, and submitting and reviewing pull requests.

For anyone interested in helping sbt, there are many avenues for you to help, depending on your interest. If you're interested, [Contributing](https://github.com/sbt/sbt/blob/develop/CONTRIBUTING.md), ["help wanted"](https://github.com/sbt/sbt/issues?q=is%3Aissue+is%3Aopen+label%3A%22help+wanted%22), ["good first issue"](https://github.com/sbt/sbt/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22) are good starting points. If you have ideas let us know on [sbt Discussions](https://github.com/sbt/sbt/discussions).

### Donate to April

Apparently April, an active contributor to Scala compiler has been sick without diagnosis. Let's help her out!

https://www.gofundme.com/f/help-april-survive-while-sick
