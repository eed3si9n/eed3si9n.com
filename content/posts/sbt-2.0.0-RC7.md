---
title: "sbt 2.0.0-RC7"
type: story
date: 2025-11-26
url: /sbt-2.0.0-RC7
tags: [ "sbt" ]
---

Hi everyone. On behalf of the sbt project, I am happy to announce sbt 2.0.0-RC7, a beta version of sbt 2.x. sbt 2.0 is a new version of sbt, based on Scala 3 constructs and Bazel-compatible cache system.

Please try it out, and report any issues you might come across. **Note**: sbt 2.0.0-RC7 will keep binary compatibility with 2.0.0 and 2.x.

### Key changes since 2.0.0-RC6

See <https://github.com/sbt/sbt/releases/tag/v2.0.0-RC7> for the full details.

* Scala 3.7.4 in the metabuild
* `scalaEarlyVersion` setting and source directories
* `cleanFull` command
* No-op compilation performance improvements

<!-- more -->

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

Download **the official sbt runner** for sbt 1.11.7 or later from SDKMAN, or download from <https://github.com/sbt/sbt/releases/tag/v1.11.7> to upgrade the `sbt` shell script and the launcher. Runner can launch any version of sbt.

The sbt version used for your build is upgraded by putting the following in `project/build.properties`:

```bash
sbt.version=2.0.0-RC7
```

This mechanism allows that sbt 2.0.0-RC7 is used only for the builds that you want.

### `scalaEarlyVersion` setting

sbt 2.0.0-RC7 introduces a new setting called `scalaEarlyVersion`, which is the early `scalaBinaryVersion`. In sbt 2.x, `unmanagedSourceDirectories` will use this setting instead of the `scalaBinaryVersion`. This means that during the milestone series like Scala 2.13.0-M1, we can use `scala-2.13` directory. This was contributed in [#8373](https://github.com/sbt/sbt/pull/8373).

### `cleanFull` command

sbt 2.0.0-RC7 adds `cleanFull` command, which clears the local disk cache. This was contributed in [#8379](https://github.com/sbt/sbt/pull/8379).

## 🐛 bug fixes since 2.0.0-RC-6

* fix: Recover gracefully when disk cache can't be read or parsed as JSON by [@mrdziuban][@mrdziuban] in [#8332](https://github.com/sbt/sbt/pull/8332)
* fix: Trigger only load (without loadFailed) in the case of NetworkChannel by [@azdrojowa123][@azdrojowa123] in [#8375](https://github.com/sbt/sbt/pull/8375)
* fix: Fixes JLine history by [@eed3si9n][@eed3si9n] in [#8388](https://github.com/sbt/sbt/pull/8388)

### Performance improvements

Eugene Yokota contributed a series of PRs to improve the no-op compilation performance.

Adrien Piquerez contributed a series of PRs to improve performance while he was at Scala Center.

* perf: Reduce number of long-living instances to speed up startup by 20% relative to 2.0.0-M2 (41% speedup compared to sbt 1.10.2) by [@adpi2][@adpi2] in [#7866](https://github.com/sbt/sbt/pull/7866)
* perf: Reduce creation of `Setting` and `Initialize`  by [@adpi2][@adpi2] in [#7880](https://github.com/sbt/sbt/pull/7880)

### Scala 3.7.4 in the metabuild

sbt 2.0.0-RC7 uses Scala 3.7.4 in the metabuild. Rather than staying with Scala 3.3.x LTS (which will EOL in 2026), our current decision is to adopt the latest stable Scala 3.x versions built on JDK 8.

### Documentation localization

[sbt 2.x documentation](https://www.scala-sbt.org/2.x/docs/en/index.html) is reorganized following the four-documentation principle ([Diátaxis](https://diataxis.fr/)).

Some of the pages are localized, for example [why sbt exists](https://www.scala-sbt.org/2.x/docs/en/guide/why-sbt-exists.html) (English), [sbt の存在理由](https://www.scala-sbt.org/2.x/docs/ja/guide/why-sbt-exists.html) (Japanese), and [sbt 的存在理由](https://www.scala-sbt.org/2.x/docs/zh-cn/guide/why-sbt-exists.html) (Chinese, Simplified). Contributions are welcome in this area as well.

### Plugin ecosystem migration

[Help us cross build](https://github.com/sbt/sbt/wiki/sbt-2.x-plugin-migration) wiki page currently lists dozens of plugins being migrated to sbt 2.x by cross building to sbt 1.x and 2.x. Let us know a plugin you need is missing from the migration effort.

### Participation

I work on sbt in my own time with collaboration with Scala Center, Adrien Piquerez (alumni), and other volunteers, like Kenji Yoshida, Jerry Tan, Matthias Kurz (Play maintainer), and recently Billy at EngFlow to name a few.

sbt 2.0.0-RC7 was brought to you by many contributors, including those who contributed to sbt 1.x series, migrating plugins, but according to `git shortlog -sn --no-merges 00eba85d98c854527125ae1655b5332c19b5afd8...733bcfb23997930915b563e7d27b1a1f6c0490da --not 1.11.x` and `git shortlog -sn --no-merges 242bd18d30c418620024d089b587f6d263d34247...v2.0.0-RC7 --not 1.11.x`:

```
358 Eugene Yokota (eed3si9n)
133 Adrien Piquerez
129 Kenji Yoshida (xuwei-k)
31  Jerry Tan (friendseeker)
14  Yasuhiro Tatsuno
13  dependabot[bot]
10  João Ferreira
9   Anton Sviridov
4   Matt Dziuban
3   Aleksandra Zdrojowa
3   Brice Jaglin
3   Martin Duhem
2   Billy Autrey
2   Damian Reeves
2   Dmitrii Naumenko
2   Frank S. Thomas
2   Josh Soref
2   Kamil Podsiadło
2   Matthew de Detrich
2   Miguel Vilá
1   Guillaume Massé
1   Hamza Remmal
1   Hugo van Rijswijk
1   Jakub Kozłowski
1   James Roper
1   Karl Yngve Lervåg
1   Lukas Rytz
1   Marco Zühlke
1   Matthias Kurz
1   Nikita Vilunov
1   OlegYch
1   Roberto Tyley
1   SlowBrainDude
1   Zainab Ali
1   kijuky
1   nathanlao
```

Thanks to everyone who's helped improve sbt and Zinc by using them, reporting bugs, improving our documentation, porting builds, porting plugins, and submitting and reviewing pull requests.

For anyone interested in helping sbt, there are many avenues for you to help, depending on your interest. If you're interested, [Contributing](https://github.com/sbt/sbt/blob/develop/CONTRIBUTING.md), ["help wanted"](https://github.com/sbt/sbt/issues?q=is%3Aissue+is%3Aopen+label%3A%22help+wanted%22), ["good first issue"](https://github.com/sbt/sbt/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22), and [Discussions](https://github.com/sbt/sbt/discussions/) are good starting points.

----

### Donate to Scala Center

Scala Center is a non-profit center at EPFL to support education and open source.

- [The Scala Center Fundraising Campaign](https://scala-lang.org/blog/2023/09/11/scala-center-fundraising.html)

  [@eed3si9n]: https://github.com/eed3si9n
  [@adpi2]: https://github.com/adpi2
  [@Duhemm]: https://github.com/Duhemm
  [@xuwei-k]: https://github.com/xuwei-k
  [@BillyAutrey]: https://github.com/BillyAutrey
  [@unkarjedy]: https://github.com/unkarjedy
  [@lrytz]: https://github.com/lrytz
  [@mrdziuban]: https://github.com/mrdziuban
  [@azdrojowa123]: https://github.com/azdrojowa123
  [migration]: https://www.scala-sbt.org/2.x/docs/en/changes/migrating-from-sbt-1.x.html
