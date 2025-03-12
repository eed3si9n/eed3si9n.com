---
title: "sbt 2.0.0-M4"
type: story
date: 2025-03-12
url: /sbt-2.0.0-M4
tags: [ "sbt" ]
---

Hi everyone. On behalf of the sbt project, I am happy to announce sbt 2.0.0-M4, a beta version of sbt 2.x. Please try it out, and report any issues you might come across. Note that sbt 2.x is released under Semantic Versioning, and the plugins will need to be published for the specific milestone version.

I work on sbt in my own time with collaboration with [Adrien Piquerez](https://www.linkedin.com/in/adrien-piquerez-22b478177/) and other volunteers, like Kenji Yoshida, Jerry Tan, Matthias Kurz (Play maintainer), and recently Billy at EngFlow to name a few.

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

## Key changes since 2.0.0-M3

See <https://github.com/sbt/sbt/releases/tag/v2.0.0-M4> for the full details.

- Client-side `run`. See below
- `Def.inputTaskDyn` support. See below
- Scala 3.6.4 in the metabuild. See below
- Many refactoring PRs contributed by Yoshida-san, bringing code base up to date with Scala 3

### How to upgrade

Download **the official sbt runner** for sbt 1.10.10 or later from SDKMAN, or download from <https://github.com/sbt/sbt/releases/tag/v1.10.10> to upgrade the `sbt` shell script and the launcher. Runner can launch any version of sbt.

The sbt version used for your build is upgraded by putting the following in `project/build.properties`:

```bash
sbt.version=2.0.0-M4
```

This mechanism allows that sbt 2.0.0-M4 is used only for the builds that you want.

### Client-side run

When you install sbt 1.10.10, the `sbt` script defaults to using sbtn (GraalVM native-image client) for sbt 2.x. What sbt 2.0.0-M4 implements the ability to send the `run` task back to sbtn, which will fork a fresh JVM. All you have to do is:

```bash
sbt run
```

One of the aims of running this on the client-side is to avoid blocking the sbt server.

This was contributed by Eugene Yokota in [#8060](https://github.com/sbt/sbt/pull/8060). See also [sbt run](https://www.scala-sbt.org/2.x/docs/en/reference/sbt-run.html) on sbt 2.x docs.

### `Def.inputTaskDyn` support

sbt 2.0.0-M4 implements dynamic input task `Def.inputTaskDyn`. This has existed in sbt 1.x, but we haven't ported it yet to Scala 3 macros yet.

This was contributed by Eugene Yokota and Adrien Piquerez in [#8033](https://github.com/sbt/sbt/pull/8033).

### Scala 3.6.4 in the metabuild

sbt 2.0.0-M4 uses Scala 3.6.4 in the metabuild. Rather than staying with Scala 3.3.x LTS (which will EOL in 2026), our current decision is to adopt the latest stable Scala 3.x versions.

### Other updates and bug fixes

* fix: Fixes `updateSbtClassifiers` task by [@unkarjedy][@unkarjedy] in [#8024](https://github.com/sbt/sbt/pull/8024)
* fix: Fixes `semanticdbEnabled` by [@eed3si9n][@eed3si9n] + [@bjaglin][@bjaglin] in [#8029](https://github.com/sbt/sbt/pull/8029) + [#8061](https://github.com/sbt/sbt/pull/8061)
* fix: Fixes `build.sbt` position in the error messages by [@eed3si9n][@eed3si9n] in [#8013](https://github.com/sbt/sbt/pull/8013)
* fix: Adds Retry around directory creation by [@eed3si9n][@eed3si9n] in [#7979](https://github.com/sbt/sbt/pull/7979)

### Plugin ecosystem migration

After we released [sbt 2.0.0-M2](/sbt-2.0.0-beta) in October 2024, we initially focused on learning through migrating the sbt plugins. [Help us cross build](https://github.com/sbt/sbt/wiki/sbt-2.x-plugin-migration) wiki page currently lists dozens migrated to sbt 2.0.0-M2 and 2.0.0-M3 by cross building to sbt 1.x and 2.x.

This includes popular plugins like sbt-assembly and sbt-buildinfo, but also sbt-ci-release, which includes sbt-pgp, sbt-sonatype, sbt-dynver, and sbt-git. See [Migrating from sbt 1.x][migration] if you're interested in cross building plugins.

### Participation

sbt 2.0.0-M4 was brought to you by 9 contributors. Eugene Yokota (eed3si9n), Kenji Yoshida (xuwei-k), Jerry Tan (Friendseeker), Dmitrii Naumenko, Josh Soref, Adrien Piquerez, Brice Jaglin, Lukas Rytz, Matthias Kurz. Thanks!

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
  [@unkarjedy]: https://github.com/unkarjedy
  [@bjaglin]: https://github.com/bjaglin
  [migration]: https://www.scala-sbt.org/2.x/docs/en/changes/migrating-from-sbt-1.x.html
