---
title:       "sbt 1.9.4"
type:        story
date:        2023-08-24
url:         /sbt-1.9.4
tags:        [ "sbt" ]
---

Hi everyone. On behalf of the sbt project, I'm happy to announce sbt 1.9.4 patch release is available. Full release note is here - https://github.com/sbt/sbt/releases/tag/v1.9.4

See [1.9.0 release note](/sbt-1.9.0) for the details on 1.9.x features.

### Highlights

- Updates Coursier to 2.1.6 to address [CVE-2022-46751](https://github.com/advisories/GHSA-2jc4-r94c-rp7h)
- Updates Ivy fork to 2.3.0-sbt-396a783bba347016e7fe30dacc60d355be607fe2 to address [CVE-2022-46751](https://github.com/advisories/GHSA-2jc4-r94c-rp7h)

<!--more-->

### How to upgrade

The sbt version used for your build must be upgraded by putting the following in `project/build.properties`:

```bash
sbt.version=1.9.4
```

This mechanism allows that sbt 1.9.4 is used only for the builds that you want.

Download **the official sbt runner** from, `cs setup`, SDKMAN, or download from <https://github.com/sbt/sbt/releases/tag/v1.9.4> to upgrade the `sbt` shell script and the launcher.

### CVE-2022-46751

[CVE-2022-46751](https://github.com/advisories/GHSA-2jc4-r94c-rp7h) is a security vulnerability discovered in Apache Ivy, but found also in Coursier.

With coordination with Apache Foundation, Adrien Piquerez from Scala Center backported the fix to both our Ivy 2.3 fork and Coursier. sbt 1.9.4 updates them to the fixed versions.

## Other updates

* Fixes `sbt_script` lookup by replacing all spaces with `%20` (not only the first one) in the path. by @arturaz in https://github.com/sbt/sbt/pull/7349
* Fixes scala-debug-adapter#543: Maintain order of internal deps by @adpi2 in https://github.com/sbt/sbt/pull/7347
* Adds a Scala 3 seed to the `sbt new` menu by @SethTisue in https://github.com/sbt/sbt/pull/7354

### Participation

Thanks to everyone who's helped improve sbt and Zinc by using them, reporting bugs, improving our documentation, porting builds, porting plugins, and submitting and reviewing pull requests.

For anyone interested in helping sbt, there are many avenues for you to help, depending on your interest. If you're interested, [Contributing](https://github.com/sbt/sbt/blob/develop/CONTRIBUTING.md), ["help wanted"](https://github.com/sbt/sbt/issues?q=is%3Aissue+is%3Aopen+label%3A%22help+wanted%22), ["good first issue"](https://github.com/sbt/sbt/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22), and [Discussions](https://github.com/sbt/sbt/discussions/) are good starting points.

----

### 🏳️‍🌈 Support Ukraine 🇺🇦

Forbidden Colours has started a fundraising campaign to support organisations in Poland, Hungary and Romania that are welcoming LGBTIQ+ refugees.

<https://www.forbidden-colours.com/2022/02/26/support-ukrainian-lgbtiq-refugees/>

### Donate to Scala Center

Scala Center is a non-profit center at EPFL to support education and open source.

- <https://scala.epfl.ch/donate.html>

  [7021]: https://github.com/sbt/sbt/pull/7021
  [6985]: https://github.com/sbt/sbt/pull/6985
  [6992]: https://github.com/sbt/sbt/pull/6992
  [7010]: https://github.com/sbt/sbt/pull/7010
  [7030]: https://github.com/sbt/sbt/pull/7030
  [7053]: https://github.com/sbt/sbt/pull/7053
  [@eed3si9n]: https://github.com/eed3si9n
  [@Nirvikalpa108]: https://github.com/Nirvikalpa108
  [@adpi2]: https://github.com/adpi2
  [@er1c]: https://github.com/er1c
  [@eatkins]: https://github.com/eatkins
  [@dwijnand]: https://github.com/dwijnand
  [@ckipp01]: https://github.com/ckipp01
  [@povder]: https://github.com/povder
  [@easel]: https://github.com/easel
  [@987Nabil]: https://github.com/987Nabil