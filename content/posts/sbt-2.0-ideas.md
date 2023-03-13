---
title:       "sbt 2.0 ideas"
type:        story
date:        2023-03-13
url:         sbt-2.0-ideas
tags:        [ "sbt" ]
---

  [scalasphere2019]: https://www.youtube.com/watch?v=h8ACmUHQ2jg
  [part1]: /sudori-part1
  [part2]: /sudori-part2
  [part3]: /sudori-part3
  [6746]: https://github.com/sbt/sbt/pull/6746
  [2899]: https://github.com/sbt/sbt/issues/2899
  [3681]: https://github.com/sbt/sbt/issues/3681
  [4183]: https://github.com/sbt/sbt/issues/4183
  [common-settings]: /simplifying-sbt-with-common-settings
  [query]: https://github.com/sbt/sbt/discussions/6801

It's spring time, and spring makes us hopeful. I'll be attending Tooling Summit next week, so I think this would be a good time to gather my toughts around sbt 2.

<!--more-->

## Introduction

### Continuity: no huge jumps, but make it fun

Similar to sbt 0.13 to 1.0 development that I oversaw, my general philosophy is to avoid making huge jumps concepturally from sbt 1, and if we have to make jumps we should try it during sbt 1.x either as a feature release or a plugin.

At the same time, we should take advantage of the chance to break API compatibility, and aim to fix confusing things or improve on some aspects where we can.

### sbt 2.0.0-alpha7

Two most complicated parts of sbt are the internal of the `build.sbt` macros and understanding the incremental compiler[^1]. After Scala 3 was released, I decided to reimplement the build macros using Scala 3, and document the process. ([sudori part1][part1], [part2][part2], and [part3][part3]). Using it as a basis, I've been porting sbt codebase into Scala 3 in [sbt/sbt#6746][6746]. Many of the code and tests are commented out, but the basic features like `compile` and `test` now works, and I've made it available on Maven Central as 2.0.0-alpha7.

```
sbt.version=2.0.0-alpha7
```

In other words, sbt on Scala 3 is no longer a vaporware.

## simpler build tool

I'd like to demonstrate what I meant by "taking advantage of the chance to break API compatibility."
Normally during the sbt 1.x cycle, all we can do is add features, and we can't change the build semantics or remove things.

### idea 1: simplify sbt with common settings

About an year ago I wrote an idea-only blog post [simplifying sbt with common settings][common-settings], in which I proposed that we can treat bare settings as common settings in all subprojects. 2.0.0-alpha7 implements this unification of common settings and bare settings. It took me only a day to get the initial implementation.

```scala
scalaVersion := "3.2.2"
organization := "com.example"

// TODO: make it work without root
lazy val root = (project in file("."))
lazy val core = project
lazy val util = project
  .settings(
    scalaVersion := "2.13.10",
  )
```

So if we go with this, `scalaVersion` and `organization` will be injected into all subprojects, but can be rewired by `.settings(...)`:

```
sbt:root> core/scalaVersion
[info] 3.2.2
sbt:root> util/scalaVersion
[info] 2.13.10
```

What's cool is that this also resolves the [dynamic dispatch][2899] issue.

```scala
scalaVersion := "3.2.2"
organization := { "com.example" + name.value }

// TODO: make it work without root
lazy val root = (project in file("."))
lazy val core = project
lazy val util = project
  .settings(
    scalaVersion := "2.13.10",
  )
```

```
sbt:root> util/organization
[info] com.exampleutil
```

Since `organization` setting is injected into `util` subproject, `name.value` is re-evaluated in the context of `util`, instead of `root`. In general, this should eliminate the need for `ThisBuild`-scoping as well.

### idea 2: subsume platform cross building `%%%`

The `%%%` operator, introduced by Scala.JS, is a brilliant mechanism that allows sbt to build JavaScript project which can depend on mixture of Scala.JS and JVM libraries. However, Anton has [brought](https://github.com/sbt/sbt/discussions/6736) up:

> `%%%` vs `%%` is a constant pain point and can lead to downstream breakages.

It's also hard to explain to newcomers what `%%%` is. In short, `%%%` allows you to do _both_ Scala cross building and platform cross building. In the discussion I've proposed that:

> What I suggest would be to obliterate `%%%` and do whatever it needs to do (capture sjs prefix under JS subproject etc) as part of normal `%%`/sbt operation.

sbt 2.0.0-alpha7 implements this. `ModuleID(...)` now has a new field called `platformOpt`, which defaults to `None`. sbt has a new key called `platform`, which will automatically inject the platform suffix on `%%` dependencies.

```scala
scalaVersion := "2.13.10"
platform := Platform.sjs1
libraryDependencies += "com.github.scopt" %% "scopt" % "4.1.0"
```

In the above, `update` will resolve to `com.github.scopt:scopt_sjs1_2.13:4.1.0`.

```
sbt:root> util/update
[info] Updating
https://repo1.maven.org/maven2/com/github/scopt/scopt_sjs1_2.13/4.1.0/scopt_sjs1_2.13-4.1.0.pom
https://repo1.maven.org/maven2/org/scala-js/scalajs-library_2.13/1.10.1/scalajs-library_2.13-1.10.1.pom
[info] Resolved  dependencies
[info] Fetching artifacts of
https://repo1.maven.org/maven2/com/github/scopt/scopt_sjs1_2.13/4.1.0/scopt_sjs1_2.13-4.1.0.jar
https://repo1.maven.org/maven2/org/scala-js/scalajs-library_2.13/1.10.1/scalajs-library_2.13-1.10.1.jar
```

If you want to explictly depend on JVM libraries you can do:

```scala
scalaVersion := "2.13.10"
platform := Platform.sjs1
libraryDependencies += ("com.github.scopt" %% "scopt" % "4.1.0").platform(Platform.jvm)
```

This too was relatively small implementation, but hopefully eases the pain around platform cross building.

### idea 3-A: limit dependency configuration to `Compile` and `Test`

Here are some more ideas to simplify sbt.
sbt generally allows creating of custom dependency configuration, but it doesn't work well. For the most part, anything that requires custom configuration should likely be handled using separate subproject instead.

### idea 3-B: discourage the use of task scoping

I don't know if we can eliminate task scoping altogether, but maybe we should discourage the use of task scoping, and start creating new keys like:

```scala
consoleScalacOptions
docScalacOptions
```

### idea 4: unify settings and tasks

It might be worth trying to remove plain settings, and make everything a task of some kind, maybe well-cached tasks, available in layers of cache.

## improving on sbt 1.x innovations

### idea 5: BSP support + persistent workers

To preventing blocking the sbt server, we should consider shipping off long-running tasks to persistent workers, similar to today's `fork` or `bgRun`. The candidate tasks are `run`, `test`, and `console`, but `compile` could be one too.

### idea 6: more disk cache and remote cache

Extending the idea of cached compilation in sbt 1.4.0, we should generalize the mechanism so any tasks can participate in the remote caching.

### idea 7: make Coursier the default

Coursier is already the default for dependency resolution, but I think Ivy is involved in publishing. We should consider dropping Ivy from the main artifact, and default to `publishM2` for `publishLocal` etc.

### idea 8-A: in-source project matrix

For cross building, in-source and document project matrix.

### idea 8-B: sbt query

See [sbt query][query]. Query would be used to filter down the subprojects:

```scala
$ sbt query ...
scopt
scopt3
scopt2_12
scoptJS
scoptJS3
scoptJS2_12

$ sbt query ...?platform=sjs1
scoptJS
scoptJS3
scoptJS2_12

$ sbt qtest ...?platform=sjs1
```

### idea 9: use assembly JAR for sbt

This is based on the idea proposed by Olaf in [#4183][4183]. To speed up the resolution, we should consider creating an über JAR that includes all of sbt code, but with normal external dependencies.

## housekeeping

### idea 10: directory standard

See [#3681][3681].

- Consider restructuring `target/` directory such that there's a single directory that all subprojects will output files.
- Consider adopting XDG Base Directory Specification where possible.

### idea 11: documentation

All sbt 1.x major changes and 2.0 changes need to be documented.

Maybe this is also a good timing to switch to some other static site generator like MkDocs or Docusaurus.

## feedback

I created a discussion thread <https://github.com/sbt/sbt/discussions/7174> on GitHub. Let me know what you think there.

Also please note that the above is my view point, and I'll be discussing with other contributors and stakeholders, so the eventual roadmap might shift.

  [^1]: For the incremental compiler, I gave a talk in 2019 [Analysis of Zinc][scalasphere2019], which people can listen to if they want to know the internals more.
