---
title:       "simplifying sbt with common settings"
type:        story
date:        2022-02-07
draft:       false
promote:     true
url:         /simplifying-sbt-with-common-settings
tags:        [ "sbt" ]
---

sbt is simple, in a sense that it has a few concepts like settings and tasks, and it achieves a wide variety of things. An idea popped into my head today that could simplify sbt further. I don't have an implementation on this yet.

<!--more-->

### deprecate `ThisBuild`

In recent years, I have been a proponent of `ThisBuild` as a way of factoring out common settings such as:

```scala
ThisBuild / scalaVersion := "3.1.1"
ThisBuild / organization := "com.example"
```

`ThisBuild` is a special subproject that the users can use to set fallback values for settings such as `scalaVersion` and `organization`. This is a useful way to keep such settings in one place when you have multiple subprojects in a build.

In practice however, `ThisBuild` is very finicky to use due to various limitations.

First, it doesn't work on all settings and tasks. For `ThisBuild` scoping to work, the key must be absent from `projectSettings`, which one would not know unless they read the code or run `inspect <key>`. For example, setting `ThisBuild / target` would have no effect since `target` is a project-level setting.

Second, `x.value` does not dynamically dispatch its call like object-oriented programming languages do with `this.foo()`. See [.value lookup vs dynamic dispatch](https://www.scala-sbt.org/1.x/docs/Scope-Delegation.html#.value+lookup+vs+dynamic+dispatch).
So for a contrived example let's consider:

```scala
ThisBuild / scalaVersion := "3.1.1"
ThisBuild / organization := "com." + scalaVersion.value

lazy val core = project

lazy val util = project
  .settings(
    scalaVersion := "2.13.8",
  )
```

In the above, `ThisBuild / organization` does not change between `core` and `util`, because the rhs `scalaVersion.value` does not dynamically dispatch. In other words, `ThisBuild` works only for a specific rhs.

Third problem is the cognitive load. `ThisBuild` is often useful for `scalaVersion`, but if we show `ThisBuild / scalaVersion`, we'd need to explain what it does. Scoping rules are most often cited as the most confusing aspect of sbt, and `ThisBuild` behavior is a contributing factor to the confusion.

[#2899](https://github.com/sbt/sbt/issues/2899) proposes to implement dynamic dispatch. Set aside the fact that we don't have an implementation for it, we still won't completely remove the problem of needing to teach people what `ThisBuild` would do.

A better solution, I think is to deprecate and remove `ThisBuild` altogether.

### commonSettings

Since the benefit of using `ThisBuild` essentially is to factor out common settings, we could instead create a way of declaring common settings:

```scala
commonSettings(
  scalaVersion := "3.1.1",
  organization := "com.example",
)
```

The semantics of `commonSettings(...)` would be a `projectSettings` to an implicit `AutoPlugin`, which is somewhere before the `.settings(...)` clause of each subproject.

```scala
commonSettings(
  scalaVersion := "3.1.1",
  organization := "com.example",
)

lazy val core = project

lazy val util = project
  .settings(
    scalaVersion := "2.13.8",
  )
```

In this case, `util/scalaVersion` will evaluate to `"2.13.8"` because `commonSettings` will be prepended.

```scala
// equivalent sbt 1.x build
val commonSettings = Seq(
  scalaVersion := "3.1.1",
  organization := "com.example",
)

lazy val core = project
  .settings(commonSettings)

lazy val util = project
  .settings(
    commonSettings,
    scalaVersion := "2.13.8",
  )
```

Now let's look at the dispatch problem:

```scala
commonSettings(
  scalaVersion := "3.1.1",
  organization := "com." + scalaVersion.value,
)

lazy val core = project

lazy val util = project
  .settings(
    scalaVersion := "2.13.8",
  )
```

`util/organization` will evaluate to `com.2.13.8` as expected because project-level settings will behave in a more predictable manner.

### sbt 2.x: Unification with `ThisBuild`

If we can deprecate `ThisBuild` in sbt 1.x, potentially `ThisBuild` can silently migrate to be `commonSettings(...)`.

In some of pathological cases the behavior would be different, but we can remove a whole category of scoping.

### sbt 2.x: Unification with bare settings?

Another thing we should consider is the unification of `commonSettings(...)` and bare settings. In other words, what if in sbt 2.x we could write:

```scala
scalaVersion := "3.1.1"
organization := "com.example"

lazy val core = project

lazy val util = project
  .settings(
    scalaVersion := "2.13.8",
  )
```

and the bare settings like `scalaVersion` are treated as `commonSettings(...)`.

This would bridge the transition between single- and multi-project builds.

### concerns

A predictable concern with unifying with the bare setting is that the semantics of the identical `build.sbt` will be different between sbt 1.x and 2.x. So in that sense, it might be more straight forward to warn people to use `commonSettings(...)` when there are multiple subprojects.

Another related issue would be `build.sbt` appearing inside the subproject directories like `foo/bar/build.sbt`. Maybe we should consider deprecating those anyway, but it is incompatible with the notion of bare settings being common settings.

This will certainly add the number of settings sbt needs to resolve during the startup.
To some extent, that is a necessary drawback we'd have to take for any solution that would act in a dynamic dispatch-like way. I would say it's worth taking the hit if we can reduce the complexity of overall design.

Independently we should also consider load speedup tactics such as local caching.

### summary

As an alternative to build-level settings (`ThisBuild`), we should consider creating an automatic subproject-level settings called `commonSettings(...)`.

If it works out, it could subsume `ThisBuild` usages as well as bare settings that are compatible with multi-project build.
