---
title:       "enforcing Semantic Versioning with sbt-strict-update"
type:        story
date:        2020-12-14
draft:       false
promote:     true
sticky:      false
url:         /enforcing-semver-with-sbt-strict-update
aliases:     [ /node/373 ]
tags:        [ "scala" ]
---

  [1]: https://github.com/sbt/sbt-strict-update
  [2]: https://github.com/scalacenter/sbt-eviction-rules
  [5976]: https://github.com/sbt/sbt/issues/5976
  [Publishing]: https://www.scala-sbt.org/1.x/docs/Publishing.html#Version+scheme

[Rob wrote](https://twitter.com/tpolecat/status/1338168877474308097):

> I want to tell sbt "this specific version breaks binary compatibility, so don't resolve it via eviction, fail the build instead." How do I do this? Complete answers only, I'm done trying to figure it out by following clues.

I wrote a small sbt plugin [sbt-strict-update][1] to do this.

Add this to `project/plugins.sbt`:

<scala>
addSbtPlugin("com.eed3si9n" % "sbt-strict-update" % "0.1.0")
</scala>

and then add this to `build.sbt`:

<scala>
ThisBuild / libraryDependencySchemes += "org.typelevel" %% "cats-effect" % "early-semver"
</scala>

That's it.

<scala>
ThisBuild / scalaVersion := "2.13.3"
ThisBuild / libraryDependencySchemes += "org.typelevel" %% "cats-effect" % "early-semver"

lazy val root = (project in file("."))
  .settings(
    name := "demo",
    libraryDependencies ++= List(
      "org.http4s" %% "http4s-blaze-server" % "0.21.11",
      "org.typelevel" %% "cats-effect" % "3.0-8096649",
    ),
  )
</scala>

Now if Rob tries to `compile` this build, he should get:

<code>
sbt:demo> compile
[warn] There may be incompatibilities among your library dependencies; run 'evicted' to see detailed eviction warnings.
[error] stack trace is suppressed; run last update for the full output
[error] (update) found version conflict(s) in library dependencies; some are suspected to be binary incompatible:
[error]
[error]   * org.typelevel:cats-effect_2.13:3.0-8096649 (early-semver) is selected over {2.2.0, 2.0.0, 2.0.0, 2.2.0}
[error]       +- demo:demo_2.13:0.1.0-SNAPSHOT                      (depends on 3.0-8096649)
[error]       +- org.http4s:http4s-core_2.13:0.21.11                (depends on 2.2.0)
[error]       +- io.chrisdavenport:vault_2.13:2.0.0                 (depends on 2.0.0)
[error]       +- io.chrisdavenport:unique_2.13:2.0.0                (depends on 2.0.0)
[error]       +- co.fs2:fs2-core_2.13:2.4.5                         (depends on 2.2.0)
[error] Total time: 0 s, completed Dec 13, 2020 11:53:31 PM
</code>

### strict resolution

There's been multiple attempts at making the dependency resolution more strict. Thus far none of them have worked.

One of my own attempt at calling on the user's attention about potential incompatibility was eviction warning. However, I can't think of a more unpopular feature than eviction warning in practice because despite its well intention, there are too many false positives.

We can actually fix this by removing all guessing completely. During my summer of Scala Center collaboration I added `ThisBuild / versionScheme`. This information could be used to improve eviction warning, but in general we should either not warn anything or fail the build if we know the incompatibility for sure.

sbt-strict-update reuses the eviction warning facility, but it'll stay quiet until it knows there's an error for sure. Since `versionScheme` is likely not used yet, I added `libraryDependencySchemes` key similar to Scala Center's [sbt-eviction-rules][2] so the app users can specify the libraries' version schemes.

### set ThisBuild / versionScheme

If you're a library author, please start setting `ThisBuild / versionScheme`. See [Publishing][Publishing] for details.

### next steps

In sbt 1.5.0, we should remove eviction warning as already suggested in [#5976][5976], and replace it with this.
