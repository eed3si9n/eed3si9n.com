---
title: "sbt 2.0.0-RC15"
type: story
date: 2026-06-08
url: /sbt-2.0.0-RC15
tags: [ "sbt" ]
---

### Key changes since 2.0.0-RC14

- Scala 3.8.4
- ByteStream chunked upload/download
- Fixes publishing platform-specific artifacts

See <https://github.com/sbt/sbt/releases/tag/v2.0.0-RC15>

<!--more-->

Hi everyone. On behalf of the sbt project, I am happy to announce sbt 2.0.0-RC15, a beta version of sbt 2.x. sbt 2.0 is a new version of sbt, based on Scala 3 constructs and Bazel-compatible cache system.

Please try it out, and report any issues you might come across. **Note**: sbt 2.0.0-RC15 will keep binary compatibility with 2.0.0 and 2.x.

### Headline features of sbt 2.0

- sbt 2.x uses Scala 3.x for build definitions and plugins (Both sbt 1.x and 2.x are capable of building Scala 2.x and 3.x)
- Common settings. Bare settings are added to all subprojects, as opposed to just the root subproject, and thus replacing the role that ThisBuild has played.
- `test` changed to incremental test.
- Local/remote cache system that is Bazel-compatible. `compile` and `test` are both rewritten to be cachable tasks.
- Project matrix, which was available via plugin in sbt 1.x, is in-sourced in sbt 2.x.
- Extension of the unified slash syntax to support query of subprojects.
- Build Server Protocol improvements. In sbt 2.x the `run` task is non-blocking.
- New documentation

See also [sbt 2.0 change summary](https://www.scala-sbt.org/2.x/docs/en/changes/sbt-2.0-change-summary.html) for the details.

### How to upgrade

Download **the official sbt runner** for sbt 1.12.11 or later from SDKMAN, or download from <https://github.com/sbt/sbt/releases/tag/v1.12.11> to upgrade the `sbt` shell script, the launcher, and sbtn. Runner can launch any version of sbt.

The sbt version used for your build is upgraded by putting the following in `project/build.properties`:

```bash
sbt.version=2.0.0-RC15
```

This mechanism allows that sbt 2.0.0-RC15 is used only for the builds that you want.

### 🐛 Bug fixes

* fix: ByteStream chunked upload/download to workaround gRPC 4MB limits by [@eed3si9n][@eed3si9n] in [#9298](https://github.com/sbt/sbt/pull/9298)
* fix: Fixes publishing platform-specific artifacts (like Scala Native) by [@arashi01][@arashi01] in [#9293](https://github.com/sbt/sbt/pull/9293)
* fix: Fixes cross build caching by [@eed3si9n][@eed3si9n] in [#9305](https://github.com/sbt/sbt/pull/9305)

### Updates

* deps: Update to Scala 3.8.4 by [@xuwei-k][@xuwei-k] + [@eed3si9n][@eed3si9n] in [#9302](https://github.com/sbt/sbt/pull/9302) / [io#522](https://github.com/sbt/io/pull/522)

### Documentation localization

[sbt 2.x documentation](https://www.scala-sbt.org/2.x/docs/en/index.html) is reorganized following the four-documentation principle ([Diátaxis](https://diataxis.fr/)).

Most pages are localized, for example [why sbt exists](https://www.scala-sbt.org/2.x/docs/en/guide/why-sbt-exists.html) (English), [sbt の存在理由](https://www.scala-sbt.org/2.x/docs/ja/guide/why-sbt-exists.html) (Japanese), and [sbt 的存在理由](https://www.scala-sbt.org/2.x/docs/zh-cn/guide/why-sbt-exists.html) (Chinese, Simplified). Contributions are welcome in this area as well.

### Plugin ecosystem migration

[Help us cross build](https://github.com/sbt/sbt/wiki/sbt-2.x-plugin-migration) wiki page currently lists dozens of plugins being migrated to sbt 2.x by cross building to sbt 1.x and 2.x. Let us know a plugin you need is missing from the migration effort.

### Participation

I work on sbt in my own time with collaboration with Scala Center, Anatolii Kmetiuk (new maintainer), Adrien Piquerez (alumni), and other volunteers, like Kenji Yoshida, Jerry Tan, Matthias Kurz (Play maintainer), and recently Billy Autrey to name a few.

sbt 2.0.0-RC15 was brought to you by many contributors, including those who contributed to sbt 1.x series, migrating plugins, but according to `git shortlog -sn --no-merges 00eba85d98c854527125ae1655b5332c19b5afd8...733bcfb23997930915b563e7d27b1a1f6c0490da --not 1.11.x` and `git shortlog -sn --group=author --group=trailer:co-authored-by --no-merges 242bd18d30c418620024d089b587f6d263d34247...v2.0.0-RC15 --not 1.12.x`:

```
537 Eugene Yokota (eed3si9n)
209 Kenji Yoshida (xuwei-k)
146 Adrien Piquerez
51  Jerry Tan (friendseeker)
37  MkDev11
34  bitloi
30  Scala Steward
21  calm329
16  Anatolii Kmetiuk
15  dependabot[bot]
14  Yasuhiro Tatsuno
13  E.G
11  Pandaman
10  João Ferreira
9   Anton Sviridov
8   Aleksandra Zdrojowa
7   Dream
7   GlobalStar117
7   Matt Dziuban
5   Dairus
4   Martin Duhem
4   john0030710
3   Angel98518
3   BrianHotopp
3   Brice Jaglin
3   Li Haoyi
3   gayanMatch
2   Ali Rashid
2   Billy Autrey
2   BitToby
2   Brian Hotopp
2   Damian Reeves
2   Daniil Sivak
2   Dmitrii Naumenko
2   Douglas Ma
2   Frank S. Thomas
2   Jame4u
2   Josh Soref
2   Kamil Podsiadło
2   Marco Zühlke
2   Matthew de Detrich
2   Matthias Kurz
2   Michał Pawlik
2   Miguel Vilá
2   NeedmeFordev
2   Pluto
2   Renzo
2   Rikito Taniguchi
2   SID
2   Satoshi Dev
2   byteforge
2   circlecrystalin
2   it-education-md
1   Albert Meltzer
1   Deborah Funmilola Olaboye
1   Eve
1   Francluob
1   Guillaume Massé
1   Hamza Remmal
1   Hugo van Rijswijk
1   Idan Ben-Zvi
1   Jakub Kozłowski
1   James Roper
1   Karl Yngve Lervåg
1   Lazz
1   Lukas Rytz
1   Nikita Vilunov
1   OlegYch
1   Pegasus
1   Rex Kerr
1   Roberto Tyley
1   Saber
1   SalesforcePeak
1   SlowBrainDude
1   Zainab Ali
1   bohdansolovie
1   chrisrock1124
1   corevibe555
1   dev-miro26
1   dive2tech
1   fireXtract
1   kijuky
1   nathanlao
```

Thanks to everyone who's helped improve sbt and Zinc by using them, reporting bugs, improving our documentation, porting builds, porting plugins, and submitting and reviewing pull requests.

For anyone interested in helping sbt, there are many avenues for you to help, depending on your interest. If you're interested, [Contributing](https://github.com/sbt/sbt/blob/develop/CONTRIBUTING.md), ["help wanted"](https://github.com/sbt/sbt/issues?q=is%3Aissue+is%3Aopen+label%3A%22help+wanted%22), ["good first issue"](https://github.com/sbt/sbt/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22), and [Discussions](https://github.com/sbt/sbt/discussions/) are good starting points.

----

### FYI - Scala Days talk

I gave a talk in Scala Days 2025 about sbt 2.0 ([recording](https://www.youtube.com/watch?v=GM2ywMb4z7A), [slide deck](https://www.slideshare.net/slideshow/sbt-2-0-go-big-scala-days-2025-edition/282592302)).

### Donate to Scala Center

Scala Center is a non-profit center at EPFL to support education and open source.

- [The Scala Center Fundraising Campaign](https://scala-lang.org/blog/2023/09/11/scala-center-fundraising.html)

  [migration]: https://www.scala-sbt.org/2.x/docs/en/changes/migrating-from-sbt-1.x.html
  [@eed3si9n]: https://github.com/eed3si9n
  [@anatoliykmetyuk]: https://github.com/anatoliykmetyuk
  [@adpi2]: https://github.com/adpi2
  [@xuwei-k]: https://github.com/xuwei-k
  [@bitloi]: https://github.com/bitloi
  [@eureka0928]: https://github.com/eureka0928
  [@tanishiking]: https://github.com/tanishiking
  [@bittoby]: https://github.com/bittoby
  [@mkurz]: https://github.com/mkurz
  [@zainab-ali]: https://github.com/zainab-ali
  [@arashi01]: https://github.com/arashi01
  [@lihaoyi]: https://github.com/lihaoyi
  [@BrianHotopp]: https://github.com/BrianHotopp
