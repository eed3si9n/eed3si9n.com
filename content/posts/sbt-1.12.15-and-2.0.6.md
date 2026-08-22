---
title: "sbt 1.12.15 and 2.0.6"
type: story
date: 2026-08-07
url: /sbt-1.12.15-and-2.0.6
tags: [ "sbt" ]
---

The headline features of sbt 1.12.15 and 2.0.6 are:

* Vulnerability fix for remote code execution via server when `serverConnectionType` is set to `Tcp`

See also [sbt 2.0 change summary](https://www.scala-sbt.org/2.x/docs/en/changes/sbt-2.0-change-summary.html) for the details on sbt 2.0.

<!--more-->

Hi everyone. On behalf of the sbt project, I am happy to announce sbt 1.12.15 and  sbt 2.0.6.

### How to upgrade

The sbt version used for your build is upgraded by putting the following in `project/build.properties`:

```bash
sbt.version=1.12.15
```

This mechanism allows that sbt 1.12.15 (or 2.0.6) is used only for the builds that you want.

Download **the official sbt runner** from SDKMAN, or download from <https://github.com/sbt/sbt/releases/tag/v2.0.6> to upgrade the `sbt` shell script, sbtn, and the launcher.

### Remote code execution via server

sbt team received a security report [GHSA-m2pw-22cj-jq4v](https://github.com/sbt/sbt/security/advisories/GHSA-m2pw-22cj-jq4v) from [Arpit Jain](https://github.com/arpitjain099) that when the `serverConnectionType` is set to `Tcp`, an attacker is able to execute arbitrary code remotely via the sbt server. sbt 1.12.15 and 2.0.6 fix this bug. Builds with the default serverConnectionType are not affected.

We recommend removing the `serverConnectionType` setting, or upgrading to a patched version or later. In an affected build, the setting might look like this:

```scala
Global / serverConnectionType := ConnectionType.Tcp
```

The remediation was implemented by [@eed3si9n][@eed3si9n] and [@anatoliykmetyuk][@anatoliykmetyuk].

### Other updates

* fix: Preserve file timestamp in local disk cache by [@eed3si9n][@eed3si9n] in [#9559](https://github.com/sbt/sbt/pull/9559)
* perf: Improve `update` task by caching file hashes by [@takayahilton][@takayahilton] in [#9559](https://github.com/sbt/sbt/pull/9559)

### Participation

Thanks to everyone who's helped improve sbt and Zinc by using them, reporting bugs, improving our documentation, porting builds, porting plugins, and submitting and reviewing pull requests.

For anyone interested in helping sbt, there are many avenues for you to help, depending on your interest. If you're interested, [Contributing](https://github.com/sbt/sbt/blob/develop/CONTRIBUTING.md), ["help wanted"](https://github.com/sbt/sbt/issues?q=is%3Aissue+is%3Aopen+label%3A%22help+wanted%22), ["good first issue"](https://github.com/sbt/sbt/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22), and [Discussions](https://github.com/sbt/sbt/discussions/) are good starting points.

----

### FYI - Scala Days talk

I gave a talk in Scala Days 2025 about sbt 2.0 ([recording](https://www.youtube.com/watch?v=GM2ywMb4z7A), [slide deck](https://www.slideshare.net/slideshow/sbt-2-0-go-big-scala-days-2025-edition/282592302)).

### Donate to Scala Center

Scala Center is a non-profit center at EPFL to support education and open source.

- [The Scala Center Fundraising Campaign](https://scala-lang.org/blog/2023/09/11/scala-center-fundraising.html)

  [@eed3si9n]: https://github.com/eed3si9n
  [@anatoliykmetyuk]: https://github.com/anatoliykmetyuk
  [@adpi2]: https://github.com/adpi2
  [@dwijnand]: https://github.com/dwijnand
  [@xuwei-k]: https://github.com/xuwei-k
  [@mrdziuban]: https://github.com/mrdziuban
  [@bitloi]: https://github.com/bitloi
  [@BrianHotopp]: https://github.com/BrianHotopp
  [@tanishiking]: https://github.com/tanishiking
  [@jozanek]: https://github.com/jozanek
  [@raboof]: https://github.com/raboof
  [@mrdziuban]: https://github.com/mrdziuban
  [@takayahilton]: https://github.com/takayahilton
