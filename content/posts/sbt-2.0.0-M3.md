---
title: "sbt 2.0.0-M3"
type: story
date: 2024-12-18
url: /sbt-2.0.0-M3
tags: [ "sbt" ]
---

Hi everyone. On behalf of the sbt project, I am happy to announce sbt 2.0.0-M3, a beta version of sbt 2.x. Please try it out, and report any issues you might come across. Note that sbt 2.x is released under Semantic Versioning, and the plugins will need to be published for the specific milestone version.

I work on sbt in my own time with collaboration with [Adrien Piquerez](https://www.linkedin.com/in/adrien-piquerez-22b478177/) at Scala Center and other volunteers, like Kenji Yoshida, Jerry Tan, Matthias Kurz (Play maintainer), and recently Billy at EngFlow to name a few.

**Note**: This is still a beta. You might need to occasionally wipe out `target`, `project/target/`, `$HOME/Library/Caches/sbt/v2/` etc

### Headline features

- sbt 2.x uses Scala 3.x for build definitions and plugins (Both sbt 1.x and 2.x are capable of building Scala 2.x and 3.x)
- Common settings. Bare settings are added to all subprojects, as opposed to just the root subproject, and thus replacing the role that ThisBuild has played.
- Local/remote cache system that is Bazel-compatible. `compile` and `test` are both rewritten to be cachable tasks.
- `test` changed to incremental test.
- Project matrix, which was available via plugin in sbt 1.x, is in-sourced in sbt 2.x.
- Extension of the unified slash syntax to support query of subprojects.
- Build Server Protocol improvements. In sbt 2.x the `run` task is non-blocking.
- New documentation

See [sbt 2.0.0-beta release note](/sbt-2.0.0-beta) for the details.

### How to upgrade

The sbt version used for your build is upgraded by putting the following in `project/build.properties`:

```bash
sbt.version=2.0.0-M3
```

This mechanism allows that sbt 2.0.0-M2 is used only for the builds that you want.

Download **the official sbt runner** from SDKMAN, or download from <https://github.com/sbt/sbt/releases/tag/v1.10.2> to upgrade the `sbt` shell script and the launcher. Runner can launch any version of sbt.

### Plugin ecosystem migration

After we released [sbt 2.0.0-M2](/sbt-2.0.0-beta) in October, we initially focused on learning through migrating the sbt plugins. [Help us cross build](https://github.com/sbt/sbt/wiki/sbt-2.x-plugin-migration) wiki page currently lists **20 plugins** migrated to sbt 2.0.0-M2 by cross building to sbt 1.x and 2.x.

This includes popular plugins like sbt-assembly and sbt-buildinfo, but also sbt-ci-release, which includes sbt-pgp, sbt-sonatype, sbt-dynver, and sbt-git. See [Migrating from sbt 1.x][migration] if you're interested in cross building plugins.

## Key changes since 2.0.0-M2

See <https://github.com/sbt/sbt/releases/tag/v2.0.0-M3> for the full details.

- Scala 3.6.2 in the metabuild. See below
- Avoids URL. See below
- Data type for License. See below
- Glob expression in scripted
- Performance improvements. See below

### Scala 3.6.2 in the metabuild

sbt 2.0.0-M3 uses Scala 3.6.2 in the metabuild. Rather than staying with Scala 3.3.x LTS (which will EOL in 2026), our current decision is to adopt the latest stable Scala 3.x versions. This allows plugin authors freedom to choose any Scala 3.x libraries and use new Scala 3.x features. This is subject to change, if too many changes are introduced.

### Changes with compatibility implication: Avoid URL

- `url(...)` function will return URI for source compatibility with sbt 1.x
- `homepage`, `organizationHomepage`, `apiURL`, `apiMappings`, `releaseNotesURL` key are typed to URI type

This is motivated by the fact that the `URL#equals` accesses network.

### Changes with compatibility implication: License

Instead of a `(String, URL)` tuple, license information will be tracked using a data type:

```scala
final class License private (
  val spdxId: String,
  val uri: java.net.URI,
  val distribution: Option[String],
  val comments: Option[String])
....

object License:
  lazy val Apache2: License =
    License("Apache-2.0", URI("https://www.apache.org/licenses/LICENSE-2.0.txt"))

  lazy val MIT: License =
    License("MIT", URI("https://opensource.org/licenses/MIT"))

  lazy val CC0: License =
    License("CC0-1.0", URI("https://creativecommons.org/publicdomain/zero/1.0/legalcode"))

  def PublicDomain: License = CC0

  lazy val GPL3_or_later: License =
    License("GPL-3.0-or-later", URI("https://spdx.org/licenses/GPL-3.0-or-later.html"))
```

This change was contributed by Matthew de Detrich in [#7927](https://github.com/sbt/sbt/pull/7927).

### Glob expression in scripted

One of the changes between sbt 1.x and 2.x that was difficult to absorb was the difference in the `target` location. To workaround this issue, we're introducing `||` and glob expression in scripted commands such as `exists`.

```bash
# before
$ absent target/out/jvm/scala-3.3.1/clean-managed/src_managed/foo.txt
$ exists target/out/jvm/scala-3.3.1/clean-managed/src_managed/bar.txt

#after
$ absent target/**/src_managed/foo.txt
$ exists target/**/src_managed/bar.txt
```

For multi-project builds we can write:

```bash
$ exists target/**/proj/src_managed/bar.txt || proj/target/**/src_managed/bar.txt
```

This feature was contributed by Eugene Yokota in [#7932](https://github.com/sbt/sbt/pull/7932).

### Performance improvements

Adrien Piquerez contributed a series of PRs to improve performance.

* perf: Reduce number of long-living instances to speed up startup by 20% relative to 2.0.0-M2 (41% speedup compared to sbt 1.10.2) by [@adpi2][@adpi2] in [#7866](https://github.com/sbt/sbt/pull/7866)
* perf: Reduce creation of `Setting` and `Initialize`  by [@adpi2][@adpi2] in [#7880](https://github.com/sbt/sbt/pull/7880)
* perf: Refactor `Settings` and optimize indexing of aggregate keys by [@adpi2][@adpi2] in [#7879](https://github.com/sbt/sbt/pull/7879)
* perf: Remove instances of `Info` and `BasicAttributeMap` by [@adpi2][@adpi2] in [#7882](https://github.com/sbt/sbt/pull/7882)

### Other updates and bug fixes

* Update `sbtResolvers` default value by [@xuwei-k][@xuwei-k] in [#7799](https://github.com/sbt/sbt/pull/7799)
* Remove `useJCenter` settingKey by [@xuwei-k][@xuwei-k] in [#7801](https://github.com/sbt/sbt/pull/7801)
* Add Mapper that returns VirtualFile based mappings by [@jtjeferreira][@jtjeferreira] + [@eed3si9n][@eed3si9n] in [#7949](https://github.com/sbt/sbt/pull/7949)
* Replace the use of compilation timestamp in detectAPIChanges with content hashes by [@Friendseeker][@Friendseeker] in [zinc#1430](https://github.com/sbt/zinc/pull/1430)
* fix: Fixes `doc` task by using ScalaInstance from update by [@eed3si9n][@eed3si9n] in [#7878](https://github.com/sbt/sbt/pull/7878)
* fix: Resurrect `or` for tasks by [@eed3si9n][@eed3si9n] in [#7749](https://github.com/sbt/sbt/pull/7749)
* fix: Fixes concurrency issue in `ParallelGzipOutputStream` by reimplementing it using raw threads by [@Ichoran][@Ichoran] + [@Friendseeker][@Friendseeker] in [zinc#1456](https://github.com/sbt/zinc/pull/1456)
* fix: Fix `csrCacheDirectory` and add test by [@adpi2][@adpi2] in [#7762](https://github.com/sbt/sbt/pull/7762)
* fix: Fix type error if too many `.value` by [@xuwei-k][@xuwei-k] in [#7773](https://github.com/sbt/sbt/pull/7773)
* fix: Fix Scala 3.x - 2.12 sandwich for matrix by [@eed3si9n][@eed3si9n] in [#7907](https://github.com/sbt/sbt/pull/7907)
* fix: Remove `-Wconf:cat=unused-nowarn:s` from the metabuild, which was showing warning by [@eed3si9n][@eed3si9n] in [#7924](https://github.com/sbt/sbt/pull/7924)
* fix: Fix root project detection by [@eed3si9n][@eed3si9n] in [#7925](https://github.com/sbt/sbt/pull/7925)
* fix: concurrency control around `build.sbt` parsing by [@eed3si9n][@eed3si9n] in [#7938](https://github.com/sbt/sbt/pull/7938)
* fix: Use JDK path, not JRE path by [@eed3si9n][@eed3si9n] in [#7948](https://github.com/sbt/sbt/pull/7948)

### Participation

sbt 2.0.0-M3 was brought to you by eight contributors and one good bot. Kenji Yoshida (xuwei-k), Eugene Yokota (eed3si9n), Jerry Tan (Friendseeker), Adrien Piquerez, João Ferreira, Matthew de Detrich, Ichoran, Nathan Lao. Thanks!

Thanks to everyone who's helped improve sbt and Zinc by using them, reporting bugs, improving our documentation, porting builds, porting plugins, and submitting and reviewing pull requests.

For anyone interested in helping sbt, there are many avenues for you to help, depending on your interest. If you're interested, [Contributing](https://github.com/sbt/sbt/blob/develop/CONTRIBUTING.md), ["help wanted"](https://github.com/sbt/sbt/issues?q=is%3Aissue+is%3Aopen+label%3A%22help+wanted%22), ["good first issue"](https://github.com/sbt/sbt/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22), and [Discussions](https://github.com/sbt/sbt/discussions/) are good starting points.

----

### Donate to Scala Center

Scala Center is a non-profit center at EPFL to support education and open source.

- [The Scala Center Fundraising Campaign](https://scala-lang.org/blog/2023/09/11/scala-center-fundraising.html)

  [@eed3si9n]: https://github.com/eed3si9n
  [@adpi2]: https://github.com/adpi2
  [@xuwei-k]: https://github.com/xuwei-k
  [@Friendseeker]: https://github.com/Friendseeker
  [@jtjeferreira]: https://github.com/jtjeferreira
  [@Ichoran]: https://github.com/Ichoran
  [migration]: https://www.scala-sbt.org/2.x/docs/en/changes/migrating-from-sbt-1.x.html
