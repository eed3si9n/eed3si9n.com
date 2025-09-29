---
title: "sbt 2.0.0-RC5"
type: story
date: 2025-09-21
url: /sbt-2.0.0-RC5
tags: [ "sbt" ]
---

Hi everyone. On behalf of the sbt project, I am happy to announce sbt 2.0.0-RC5, a beta version of sbt 2.x. sbt 2.0 is a new version of sbt, based on Scala 3 constructs and Bazel-compatible cache system.

Please try it out, and report any issues you might come across. **Note**: sbt 2.0.0-RC5 will keep binary compatibility with 2.0.0 and 2.x.

### Headline features

- sbt 2.x uses Scala 3.x for build definitions and plugins (Both sbt 1.x and 2.x are capable of building Scala 2.x and 3.x)
- Common settings. Bare settings are added to all subprojects, as opposed to just the root subproject, and thus replacing the role that ThisBuild has played.
- `test` changed to incremental test.
- Local/remote cache system that is Bazel-compatible. `compile` and `test` are both rewritten to be cachable tasks.
- Project matrix, which was available via plugin in sbt 1.x, is in-sourced in sbt 2.x.
- Extension of the unified slash syntax to support query of subprojects.
- Build Server Protocol improvements. In sbt 2.x the `run` task is non-blocking.
- New documentation

See also [sbt 2.0 change summary](https://www.scala-sbt.org/2.x/docs/en/changes/sbt-2.0-change-summary.html) for the details.

## Key changes since 2.0.0-RC4

See <https://github.com/sbt/sbt/releases/tag/v2.0.0-RC5> for the full details.

* Updates Contraband to generate `given`s instead of `implicit lazy val` by  [@xuwei-k][@xuwei-k] in [contraband#188](https://github.com/sbt/contraband/pull/188)
* Updates Contraband to generate `enum` instead of `case object` by [@xuwei-k][@xuwei-k] in [contraband#207](https://github.com/sbt/contraband/pull/207)
* deps: Scala 3.7.3 by [@xuwei-k][@xuwei-k] in [#8276](https://github.com/sbt/sbt/pull/8276)
* Adds Auto aggregate `.autoAggregate` on `Project`. See below
* Adds `runTaskUnhandled` to `Extracted` by [@BillyAutrey][@BillyAutrey] in [#8283](https://github.com/sbt/sbt/pull/8283)
* fix: Fixes removeN operator `--=` by [@eed3si9n][@eed3si9n] in [#8260](https://github.com/sbt/sbt/pull/8260)
* fix: Fixes forked test error handling on JDK 17 by [@eed3si9n][@eed3si9n] in [#8271](https://github.com/sbt/sbt/pull/8271)
* fix: Catches Gson parsing error during forked tests by [@eed3si9n][@eed3si9n] in [#8282](https://github.com/sbt/sbt/pull/8282)

### Auto aggregation

In sbt 0.13 and 1.x, users had to choose between defining the root project manually to get the stable id or let sbt automatically define the root project that aggregates the subprojects.

sbt 2.0.0-RC5 adds `Project#autoAggregate` method so you get both the benefits.

```scala
lazy val root = (project in file("."))
  .autoAggregate
  .settings(
    name := "foo-root",
    publish / skip := true,
  )
```

This was contributed by [@eed3si9n][@eed3si9n] in [#8290](https://github.com/sbt/sbt/pull/8290).

### How to upgrade

Download **the official sbt runner** for sbt 1.11.6 or later from SDKMAN, or download from <https://github.com/sbt/sbt/releases/tag/v1.11.6> to upgrade the `sbt` shell script and the launcher. Runner can launch any version of sbt.

The sbt version used for your build is upgraded by putting the following in `project/build.properties`:

```bash
sbt.version=2.0.0-RC5
```

This mechanism allows that sbt 2.0.0-RC5 is used only for the builds that you want.

### Performance improvements

Adrien Piquerez contributed a series of PRs to improve performance while he was at Scala Center.

* perf: Reduce number of long-living instances to speed up startup by 20% relative to 2.0.0-M2 (41% speedup compared to sbt 1.10.2) by [@adpi2][@adpi2] in [#7866](https://github.com/sbt/sbt/pull/7866)
* perf: Reduce creation of `Setting` and `Initialize`  by [@adpi2][@adpi2] in [#7880](https://github.com/sbt/sbt/pull/7880)
* perf: Refactor `Settings` and optimize indexing of aggregate keys by [@adpi2][@adpi2] in [#7879](https://github.com/sbt/sbt/pull/7879)
* perf: Remove instances of `Info` and `BasicAttributeMap` by [@adpi2][@adpi2] in [#7882](https://github.com/sbt/sbt/pull/7882)

### Scala 3.7.4 in the metabuild

sbt 2.0.0-RC5 uses Scala 3.7.3 in the metabuild. Rather than staying with Scala 3.3.x LTS (which will EOL in 2026), our current decision is to adopt the latest stable Scala 3.x versions built on JDK 8.

### Documentation localization

[sbt 2.x documentation](https://www.scala-sbt.org/2.x/docs/en/index.html) is reorganized following the four-documentation principle ([Diátaxis](https://diataxis.fr/)).

Some of the pages are localized, for example [why sbt exists](https://www.scala-sbt.org/2.x/docs/en/guide/why-sbt-exists.html) (English), [sbt の存在理由](https://www.scala-sbt.org/2.x/docs/ja/guide/why-sbt-exists.html) (Japanese), and [sbt 的存在理由](https://www.scala-sbt.org/2.x/docs/zh-cn/guide/why-sbt-exists.html) (Chinese, Simplified). Contributions are welcome in this area as well.

### Plugin ecosystem migration

[Help us cross build](https://github.com/sbt/sbt/wiki/sbt-2.x-plugin-migration) wiki page currently lists dozens of plugins being migrated to sbt 2.x by cross building to sbt 1.x and 2.x. Let us know a plugin you need is missing from the migration effort.

### Participation

I work on sbt in my own time with collaboration with Scala Center, Adrien Piquerez (alumni), and other volunteers, like Kenji Yoshida, Jerry Tan, Matthias Kurz (Play maintainer), and recently Billy at EngFlow to name a few.

sbt 2.0.0-RC5 was brought to you by many contributors, including those who contributed to sbt 1.x series, migrating plugins, but according to `git shortlog -sn --no-merges 00eba85d98c854527125ae1655b5332c19b5afd8...733bcfb23997930915b563e7d27b1a1f6c0490da --not 1.11.x` and `git shortlog -sn --no-merges 242bd18d30c418620024d089b587f6d263d34247...v2.0.0-RC5 --not 1.11.x`:

```
333 Eugene Yokota (eed3si9n)
133 Adrien Piquerez
113 Kenji Yoshida (xuwei-k)
31  Jerry Tan (friendseeker)
14  Yasuhiro Tatsuno
10  João Ferreira
9   Anton Sviridov
9   dependabot[bot]
3   Brice Jaglin
3   Martin Duhem
2   Billy Autrey
2   Damian Reeves
2   Dmitrii Naumenko
2   Frank S. Thomas
2   Josh Soref
2   Kamil Podsiadło
2   Matt Dziuban
2   Matthew de Detrich
2   Miguel Vilá
1   Guillaume Massé
1   Hamza Remmal
1   Hugo van Rijswijk
1   Jakub Kozłowski
1   James Roper
1   Karl Yngve Lervåg
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

### FYI - Scala Days talk slides

I gave a talk in Scala Days this week about sbt 2.0. Here is the [slide deck](https://www.slideshare.net/slideshow/sbt-2-0-go-big-scala-days-2025-edition/282592302).

### Donate to Scala Center

Scala Center is a non-profit center at EPFL to support education and open source.

- [The Scala Center Fundraising Campaign](https://scala-lang.org/blog/2023/09/11/scala-center-fundraising.html)

  [@eed3si9n]: https://github.com/eed3si9n
  [@adpi2]: https://github.com/adpi2
  [@Duhemm]: https://github.com/Duhemm
  [@xuwei-k]: https://github.com/xuwei-k
  [@BillyAutrey]: https://github.com/BillyAutrey
  [@unkarjedy]: https://github.com/unkarjedy
  [@bjaglin]: https://github.com/bjaglin
  [migration]: https://www.scala-sbt.org/2.x/docs/en/changes/migrating-from-sbt-1.x.html
