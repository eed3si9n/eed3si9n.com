---
title: "sbt 2.0.0-M2"
type: story
date: 2024-10-04
url: /sbt-2.0.0-beta
tags: [ "sbt" ]
---

Hi everyone. On behalf of the sbt project, I am happy to announce sbt 2.0.0-M2, a beta version of sbt 2.x. Please try it out, and report any issues you might come across. Note that sbt 2.x is released under Semantic Versioning, and the plugins will need to be published for the specific milestone version.

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

### How to upgrade

The sbt version used for your build is upgraded by putting the following in `project/build.properties`:

```bash
sbt.version=2.0.0-M2
```

This mechanism allows that sbt 2.0.0-M2 is used only for the builds that you want.

Download **the official sbt runner** from SDKMAN, or download from <https://github.com/sbt/sbt/releases/tag/v1.10.2> to upgrade the `sbt` shell script and the launcher. Runner can launch any version of sbt.

### New documentation

We're rewriting and reorganizing documentation as [The Book of sbt](https://www.scala-sbt.org/2.x/docs/en/index.html). See [sbt 2.0 changes](https://www.scala-sbt.org/2.x/docs/en/changes/sbt-2.0-change-summary.html) for the full list of changes.

See [Migrating from sbt 1.x][migration] for the migration guide.

### Cross build plugins

In sbt 2.x, if you cross build an sbt plugin with Scala 3.x and 2.12.x, it will automatically cross build against sbt 1.x and sbt 2.x:

```scala
// using sbt 2.x
lazy val plugin = (projectMatrix in file("plugin"))
  .enablePlugins(SbtPlugin)
  .settings(
    name := "sbt-vimquit",
  )
  .jvmPlatform(scalaVersions = Seq("3.3.3", "2.12.20"))
```

If you use `projectMatrix`, make sure to move the plugin to a subdirectory like `plugin/`. Use sbt 1.10.2 or later, if you want to cross build using sbt 1.x.

### Common settings

In sbt 2.x, the bare settings in `build.sbt` are interpreted to be common settings, and are injected to all subprojects. This means we can now set `scalaVersion` without using `ThisBuild` scoping:

```scala
scalaVersion := "3.5.1"
```

This also fixes the so-called dynamic dispatch problem:

```scala
lazy val hi = taskKey[String]("")
hi := name.value + "!"
```

In sbt 1.x `hi` task will capture the name of the root project, but in sbt 2.x it will return the `name` of each subproject with `!`:

```scala
$ export SBT_NATIVE_CLIENT=true
$ sbt show hi
[info] entering *experimental* thin client - BEEP WHIRR
[info] terminate the server with `shutdown`
> show hi
[info] foo / hi
[info]  foo!
[info] hi
[info]  root!
```

Contributed by [@eed3si9n][@eed3si9n] in [#6746][6746]

### sbt query

To filter down the subprojects, sbt 2.x introduces sbt query.

```bash
$ export SBT_NATIVE_CLIENT=true
$ sbt foo.../test
```

The above runs all subprojects that begins with `foo`.

```bash
$ sbt ...@scalaBinaryVersion=3/test
```

The above runs all subprojects whose `scalaBinaryVersion` is `3`. Contributed by [@eed3si9n][@eed3si9n] in [#7699][7699]

### Local/remote cache system

sbt 2.x implements cached task, which can automatically cache the task results to local disk and Bazel-compatible remote cache. Initially, `compile` and `test` are both rewritten to be cachable. Plugin authors can use this to make their tasks remote-cachable.

```scala
lazy val task1 = taskKey[String]("doc for task1")

task1 := (Def.cachedTask {
  name.value + version.value + "!"
}).value
```

This tracks the inputs into the `task1` and creates a machine-wide disk cache, which can also be configured to also use a remote cache. Since it's common for sbt tasks to also produce files on the side, we also provide a mechanism to cache file contents:

```scala
lazy val task1 = taskKey[String]("doc for task1")

task1 := (Def.cachedTask {
  val converter = fileConverter.value
  ....
  val output = converter.toVirtualFile(somefile)
  Def.declareOutput(output)
  name.value + version.value + "!"
}).value
```

See also [Caching](https://www.scala-sbt.org/2.x/docs/en/concepts/caching.html) documentation. Contributed by [@eed3si9n][@eed3si9n] in [#7464][7464] / [#7525][7525]

### Next steps

See [Migrating from sbt 1.x][migration] for the migration guide.

- Please try using it, and report bugs, or contribute bug fixes.
- sbt ecosystem has a lot of plugins. [Help us cross build](https://github.com/sbt/sbt/wiki/sbt-2.x-plugin-migration) them to both sbt 1.x and 2.x.

  [6746]: https://github.com/sbt/sbt/pull/6746
  [7464]: https://github.com/sbt/sbt/pull/7464
  [7525]: https://github.com/sbt/sbt/pull/7525
  [7671]: https://github.com/sbt/sbt/pull/7671
  [7686]: https://github.com/sbt/sbt/pull/7686
  [7699]: https://github.com/sbt/sbt/pull/7699
  [7700]: https://github.com/sbt/sbt/pull/7700
  [7712]: https://github.com/sbt/sbt/pull/7712
  [@eed3si9n]: https://github.com/eed3si9n
  [@adpi2]: https://github.com/adpi2
  [migration]: https://www.scala-sbt.org/2.x/docs/en/changes/migrating-from-sbt-1.x.html

