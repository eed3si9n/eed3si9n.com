---
title:       "Bintray to JFrog Artifactory migration status and sbt 1.5.1"
type:        story
date:        2021-04-26
changed:     2021-04-27
draft:       false
promote:     true
sticky:      false
url:         /bintray-to-jfrog-artifactory-migration-status-and-sbt-1.5.1
aliases:     [ /node/389 ]
---

  [runner]: https://raw.githubusercontent.com/sbt/sbt/v1.5.1/sbt
  [6431]: https://github.com/sbt/sbt/pull/6431
  [6425]: https://github.com/sbt/sbt/pull/6425
  [6456]: https://github.com/sbt/sbt/pull/6456
  [6436]: https://github.com/sbt/sbt/issues/6436
  [6434]: https://github.com/sbt/sbt/pull/6434
  [launcher95]: https://github.com/sbt/launcher/pull/95
  [launcher96]: https://github.com/sbt/launcher/pull/96
  [@adpi2]: https://github.com/adpi2
  [@eed3si9n]: https://github.com/eed3si9n
  [@eatkins]: https://github.com/eatkins
  [@xuwei-k]: https://github.com/xuwei-k
  [@ashleymercer]: https://github.com/ashleymercer
  [@guilgaly]: https://github.com/guilgaly
  [@steinybot]: https://github.com/steinybot

I'm happy to announce sbt 1.5.1 patch release is available. Full release note is here - https://github.com/sbt/sbt/releases/tag/v1.5.1. This post will also report the Bintray to JFrog Artifactory migration.

### Bintray to JFrog Artifactory migration status

First and foremost, I would like to thank JFrog for their continued support of sbt project and the Scala ecosystem.

As sbt was taking off in the number of contributors and plugins, we had a Bintray-shaped problem. We wanted individuals to create Ivy-layout repository, publish sbt plugins, but somehow aggregate the resolution to them. Having Github sbt organization allowed fluid ownership of plugin sources, but distributing the binary files were challenge as sbt version was churning. We adopted Bintray in 2014 and it provided the distribution mechanism during our growth years. In addition, we used Bintray to host Debian and RPM installers for sbt, paid for by Lightbend.

In February 2021, JFrog announced that they will be sunsetting Bintray service. Since then, JFrog has been proactive in communicating with us, scheduling meetings, granting us [open source sponsorship](https://jfrog.com/open-source/), and providing the migration toolkit.

There's now a cloud-hosted Artifactory instance licensed to **Scala Center**, and fully sponsored by **JFrog**. Let's call this "Artsy" in this post instead of _the Artifactory instance_. With the release of sbt 1.5.1, I think we can say that the migration is done.

#### read side

- As of April 18th, I have migrated all sbt plugins and sbt 0.13 artifacts to Artsy, and Lightbend IT team has redirected https://repo.scala-sbt.org/scalasbt/ to point to Artsy as well, so **existing builds should continue to work without making any changes** today and after May 1st. Please check for [an issue](https://github.com/sbt/sbt/issues), and report it if this is not the case.

#### write side

We plan to make Artsy's `sbt-plugin-releases` a read-only repo. This means if you're a plugin author, you will need to migrate to [Sonatype OSSRH](https://central.sonatype.org/publish/publish-guide/). Once organization name is granted, you can automate the publishing using [sbt-ci-release](https://github.com/olafurpg/sbt-ci-release).

Given the relative stability provided by the binary compatibility of modern sbt, I think we should use this as an opportunity to wean ourselves off from the Ivy layout repository.

#### Linux support

- As of April 26th, Debian package will be published to `deb https://repo.scala-sbt.org/scalasbt/debian all main` on Artsy. The older releases are hosted on `deb https://repo.scala-sbt.org/scalasbt/debian /`.

```bash
echo "deb https://repo.scala-sbt.org/scalasbt/debian all main" | sudo tee /etc/apt/sources.list.d/sbt.list
echo "deb https://repo.scala-sbt.org/scalasbt/debian /" | sudo tee /etc/apt/sources.list.d/sbt_old.list
curl -sL "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x2EE0EA64E40A89B84B2DF73499E82A75642AC823" | sudo apt-key add
sudo apt-get update
sudo apt-get install sbt
```

- RPM repository file is hosted at `https://www.scala-sbt.org/sbt-rpm.repo`. The RPM packages are hosted on Artsy.

```bash
# remove old Bintray repo file
sudo rm -f /etc/yum.repos.d/bintray-rpm.repo
curl -L https://www.scala-sbt.org/sbt-rpm.repo > sbt-rpm.repo
sudo mv sbt-rpm.repo /etc/yum.repos.d/
sudo yum install sbt
```

To minimize the bandwidth requirement, both DEB file and RPM file will include only the `sbt` runner file without `sbt-launch.jar`.

### sbt 1.5.1

Let's talk about the sbt 1.5.1 patch release.

#### How to upgrade

Download **the official sbt runner** from SDKMAN or download from <https://www.scala-sbt.org/download.html>. This installer includes the `sbtn` binary.

In addition, the sbt version used for your build is upgraded by putting the following in `project/build.properties`:

```bash
sbt.version=1.5.1
```

This mechanism allows that sbt 1.5.1 is used only for the builds that you want.

### Highlights of sbt 1.5.1

- sbt 1.5.1 in-sources [sbt][runner] runner script to sbt/sbt repo, and implements `sbt-launch.jar` download
- Fixes spurious "@nowarn annotation does not suppress any warnings" in sbt plugins [#6431][6431] by [@adpi2][@adpi2]

Full more details please see https://github.com/sbt/sbt/releases/tag/v1.5.1.

### Using the official runner on Travis CI

If for some reason the unofficial `sbt` doesn't work, the following can be used to install the official `sbt` runner:

```bash
install:
  - |
    export SBT_OPTS=""
    curl -L --silent "https://raw.githubusercontent.com/sbt/sbt/v1.5.1/sbt" > $HOME/sbt
    chmod +x $HOME/sbt && sudo mv $HOME/sbt /usr/local/bin/sbt
```

### Participation

sbt 1.5.1 was brought to you by 6 contributors. Eugene Yokota (eed3si9n), Adrien Piquerez, Ashley Mercer, Guillaume Galy, Jason Pickens, Kenji Yoshida (xuwei-k), Philippus Baalman. Thank you!

Thanks to everyone who's helped improve sbt and Zinc 1 by using them, reporting bugs, improving our documentation, porting builds, porting plugins, and submitting and reviewing pull requests.

For anyone interested in helping sbt, there are many avenues for you to help, depending on your interest. If you're interested, [Contributing](https://github.com/sbt/sbt/blob/develop/CONTRIBUTING.md), ["help wanted"](https://github.com/sbt/sbt/issues?q=is%3Aissue+is%3Aopen+label%3A%22help+wanted%22), ["good first issue"](https://github.com/sbt/sbt/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22), and [Discussions](https://github.com/sbt/sbt/discussions/) are good starting points.

### Donate to April

Apparently April, an active contributor to Scala compiler has been sick without diagnosis. Let's help her out!

https://www.gofundme.com/f/help-april-survive-while-sick
