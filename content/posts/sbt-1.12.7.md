---
title: "sbt 1.12.7"
type: story
date: 2026-03-23
url: /sbt-1.12.7
tags: [ "sbt" ]
---

The headline feature of sbt 1.12.7 is:

- [CVE-2026-32948][CVE-2026-32948] fix

See also [1.12.0 release note](/sbt-1.12.0) for the details on 1.12.x features.

**Note**: sbt 1.12.7 has a source dependency bug. Use sbt 1.12.8 instead.

<!--more-->

Hi everyone. On behalf of the sbt project, I am happy to announce sbt 1.12.6. This is the twelfth feature release of sbt 1.x, a binary compatible release focusing on new features. sbt 1.x is released under Semantic Versioning, and the plugins are expected to work throughout the 1.x series. Please try it out, and report any issues you might come across.

### How to upgrade

The sbt version used for your build is upgraded by putting the following in `project/build.properties`:

```bash
sbt.version=1.12.7
```

This mechanism allows that sbt 1.12.7 is used only for the builds that you want.

Download **the official sbt runner** from SDKMAN, or download from <https://github.com/sbt/sbt/releases/tag/v1.12.7> to upgrade the `sbt` shell script and the launcher.

### CVE-2026-32948 Source dependency feature (via crafted VCS URL) leading to arbitrary code execution on Windows

sbt 1.12.7 fixes [CVE-2026-32948][CVE-2026-32948]. Recently Anatolii Kmetiuk at Scala Center discovered a vulnerability in sbt's source dependency feature `ProjectRef(...)` and `RootProject(...)`. The URL for the version control system allows branch specification via the URL fragment, which is passed to Windows `cmd` shell. A malicious user can craft an URL that allows arbitrary code execution.

Anatolii also provided a fix from a private fork [1ce945](https://github.com/sbt/sbt/commit/1ce945b6b79cbe3cef6c0fe9efbbd2904e0f479e) and [3a474a](https://github.com/sbt/sbt/commit/3a474ab060df4dbfa825a7e7bc97e00056519800). We recommend upgrading to sbt 1.12.7, especially if you're on Windows.

### Other update

* deps: Revert to lm-coursier to 2.1.10 (Coursier 2.12.24) by [@eed3si9n][@eed3si9n] in [#8918](https://github.com/sbt/sbt/pull/8918)

### Welcome Anatolii Kmetiuk

We'd like to announce a new committer to the sbt project: Anatolii "Toli" Kmetiuk at Scala Center. Toli has been working with Eugene for a few months now on the sbt 2.x migration initiatives. See for example his recent blog post [Migrating sbt plugins to sbt 2 with sbt2-compat plugin](https://www.scala-lang.org/blog/2026/03/02/sbt2-compat.html).

### Participation

Thanks to everyone who's helped improve sbt and Zinc by using them, reporting bugs, improving our documentation, porting builds, porting plugins, and submitting and reviewing pull requests.

For anyone interested in helping sbt, there are many avenues for you to help, depending on your interest. If you're interested, [Contributing](https://github.com/sbt/sbt/blob/develop/CONTRIBUTING.md), ["help wanted"](https://github.com/sbt/sbt/issues?q=is%3Aissue+is%3Aopen+label%3A%22help+wanted%22), ["good first issue"](https://github.com/sbt/sbt/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22), and [Discussions](https://github.com/sbt/sbt/discussions/) are good starting points.

----

### Donate to Scala Center

Scala Center is a non-profit center at EPFL to support education and open source.

- [The Scala Center Fundraising Campaign](https://scala-lang.org/blog/2023/09/11/scala-center-fundraising.html)

  [@eed3si9n]: https://github.com/eed3si9n
  [@adpi2]: https://github.com/adpi2
  [@dwijnand]: https://github.com/dwijnand
  [@xuwei-k]: https://github.com/xuwei-k
  [@mrdziuban]: https://github.com/mrdziuban
  [@azdrojowa123]: https://github.com/azdrojowa123
  [CVE-2026-32948]: https://github.com/sbt/sbt/security/advisories/GHSA-x4ff-q6h8-v7gw
