---
title:       "sbt 1.9.7"
type:        story
date:        2023-10-22
url:         /sbt-1.9.7
tags:        [ "sbt" ]
---

Hi everyone. On behalf of the sbt project, I'm happy to announce sbt 1.9.7 patch release is available. Full release note is here - https://github.com/sbt/sbt/releases/tag/v1.9.7

See [1.9.0 release note](/sbt-1.9.0) for the details on 1.9.x features.

### Highlights

- [CVE-2023-46122](https://github.com/sbt/sbt/security/advisories/GHSA-h9mw-grgx-2fhf). sbt 1.9.7 updates its IO module to 1.9.7, which fixes parent path traversal vulnerability in `IO.unzip`. This was discovered and reported by Kenji Yoshida ([@xuwei-k][@xuwei-k]), and fixed by [@eed3si9n][@eed3si9n] in [io#360][io360].

<!--more-->

### How to upgrade

The sbt version used for your build must be upgraded by putting the following in `project/build.properties`:

```bash
sbt.version=1.9.7
```

This mechanism allows that sbt 1.9.7 is used only for the builds that you want.

Download **the official sbt runner** from, `cs setup`, SDKMAN, or download from <https://github.com/sbt/sbt/releases/tag/v1.9.7> to upgrade the `sbt` shell script and the launcher.

### CVE-2023-46122: Zip Slip (arbitrary file write) vulnerability

See [CVE-2023-46122](https://github.com/sbt/sbt/security/advisories/GHSA-h9mw-grgx-2fhf) for the most up to date information. This affects all sbt versions prior to 1.9.7.

Path traversal vulnerabilty was discovered in `IO.unzip` code, and was reported by Kenji Yoshida ([@xuwei-k][@xuwei-k]). This is a very common vulnerability known as [Zip Slip](https://security.snyk.io/research/zip-slip-vulnerability), and was found and fixed in plexus-archiver, Ant, etc. Given a specially crafted zip or JAR file, `IO.unzip` allows writing of arbitrary file. The follow is an example of a malicious entry:

```
+2018-04-15 22:04:42 ..... 20 20 ../../../../../../root/.ssh/authorized_keys
```

When executed on some path with six levels, `IO.unzip` could then overwrite a file under `/root/`. sbt main uses `IO.unzip` only in `pullRemoteCache` and `Resolvers.remote`, however, many projects use `IO.unzip(...)` directly to implement custom tasks and tests.

This issue was fixed by [@eed3si9n][@eed3si9n] in [io#360][io360].

### Non-determinism from AutoPlugins loading

We've known that occasionally some builds non-deterministically flip-flops its behavior when a task or a setting is set by two independent AutoPlugins, i.e. two plugins that neither depends on the other.

sbt 1.9.7 attempts to fix non-determinism of plugin loading order.
This was contributed by [@eed3si9n][@eed3si9n] in [#7404][7404].

## Other updates and fixes

- Updates Coursier to 2.1.7 by [@regiskuckaertz][@regiskuckaertz] in [#7392][7392]
- Updates Swoval to 2.1.12 by [@eatkins][@eatkins] in [io#353][io353].
- Fixes `.sbtopts` support for `sbt` runner script on Windows by [@ptrdom][@ptrdom] in [#7393][7393]
- Adds documentation on `scriptedSbt` key by [@mdedetrich][@mdedetrich] in [#7383][7383]
- Includes the URL in `dependencyBrowseTree` log by [@mkurz][@mkurz] in [#7396][7396]

### Participation

Thanks to everyone who's helped improve sbt and Zinc by using them, reporting bugs, improving our documentation, porting builds, porting plugins, and submitting and reviewing pull requests.

For anyone interested in helping sbt, there are many avenues for you to help, depending on your interest. If you're interested, [Contributing](https://github.com/sbt/sbt/blob/develop/CONTRIBUTING.md), ["help wanted"](https://github.com/sbt/sbt/issues?q=is%3Aissue+is%3Aopen+label%3A%22help+wanted%22), ["good first issue"](https://github.com/sbt/sbt/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22), and [Discussions](https://github.com/sbt/sbt/discussions/) are good starting points.

----

### Donate to Scala Center

Scala Center is a non-profit center at EPFL to support education and open source.

- [The Scala Center Fundraising Campaign](https://scala-lang.org/blog/2023/09/11/scala-center-fundraising.html)

  [@eed3si9n]: https://github.com/eed3si9n
  [@Nirvikalpa108]: https://github.com/Nirvikalpa108
  [@adpi2]: https://github.com/adpi2
  [@er1c]: https://github.com/er1c
  [@eatkins]: https://github.com/eatkins
  [@dwijnand]: https://github.com/dwijnand
  [@xuwei-k]: https://github.com/xuwei-k
  [@regiskuckaertz]: https://github.com/regiskuckaertz
  [@ptrdom]: https://github.com/ptrdom
  [@mdedetrich]: https://github.com/mdedetrich
  [@mkurz]: https://github.com/mkurz
  [7404]: https://github.com/sbt/sbt/pull/7404
  [7392]: https://github.com/sbt/sbt/pull/7392
  [7393]: https://github.com/sbt/sbt/pull/7393
  [7396]: https://github.com/sbt/sbt/pull/7396
  [7383]: https://github.com/sbt/sbt/pull/7383
  [io353]: https://github.com/sbt/io/pull/353
  [io360]: https://github.com/sbt/io/pull/360
