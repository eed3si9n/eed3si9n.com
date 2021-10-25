---
title:       "sbt 1.5.0"
type:        story
date:        2021-04-04
changed:     2021-04-13
draft:       false
promote:     true
sticky:      false
url:         /sbt-1.5.0
aliases:     [ /node/386 ]
tags:        [ "sbt" ]
---

Hi everyone. On behalf of the sbt project, I am happy to announce sbt 1.5.0. This is the fifth feature release of sbt 1.x, a binary compatible release focusing on new features. sbt 1.x is released under Semantic Versioning, and the plugins are expected to work throughout the 1.x series.

The headline features of sbt 1.5.0 are:

- Scala 3 support
- Eviction error
- Deprecation of sbt 0.13 syntax
- Coursier-based launcher

### How to upgrade

Download **the official sbt launcher** from SDKMAN or download from <https://github.com/sbt/sbt/releases/tag/v1.5.0>. This installer includes the new Coursier-based launcher.

In addition, the sbt version used for your build is upgraded by putting the following in `project/build.properties`:

<code>
sbt.version=1.5.0
</code>

This mechanism allows that sbt 1.5.0 is used only for the builds that you want.

### Scala 3 support

sbt 1.5.0 adds built-in Scala 3 support, contributed by Scala Center. Main implementation was done by Adrien Piquerez ([@adpi2][@adpi2]) based on EPFL/LAMP's [sbt-dotty](https://github.com/lampepfl/dotty/tree/master/sbt-dotty). You can now use Scala 3.0.0-RC2 like any other Scala version.

```scala
ThisBuild / scalaVersion := "3.0.0-RC2"
```

This will compile the following `Hello.scala`:

```scala
package example

@main def hello(arg: String*): Unit =
  if arg.isEmpty then println("hello")
  else println(s"hi ${arg.head}")
```

**Note**: To support cross testing of various Scala 3.x releases, `crossTarget` directory will contain the full Scala version. [#6415][6415]

### Scala 2.13-3.x sandwich

Scala 3.0.x [shares](https://www.scala-lang.org/2019/12/18/road-to-scala-3.html) the standard library with Scala 2.13, and since Scala 2.13.4, they can mutually consume the output of each other as external library. This allows you to create Scala 2.13-3.x sandwich, a layering of dependencies coming from different Scala versions.

sbt 1.5.0 introduces new cross building operand to use `_3` variant when `scalaVersion` is 2.13.x, and vice versa:

```scala
("a" % "b" % "1.0").cross(CrossVersion.for3Use2_13)

("a" % "b" % "1.0").cross(CrossVersion.for2_13Use3)
```

These are analogous to `%%` operator that selects `_2.13` etc based on `scalaVersion`. 

**Warning**: Library authors should generally treat Scala 3.0 as any other major version, and prefer to cross publish `_3` variant to avoid the conflict. Some libraries may encode a particular notion in different ways for Scala 2.13 and 3.0. For example, arity abstraction may use Shapeless HList in Scala 2.13, but built-in Tuple types in Scala 3.0. Thus it's generally not safe to have `_2.13` and `_3` versions of the same library in the classpath, even transitively. Application developers should be free to use `.cross(CrossVersion.for3Use2_13)` as long as the transitive dependency graph will not introduce `_2.13` variant of a library you already have in `_3` variant.

[lm#361][lm361] by [@adpi2][@adpi2]

### Deprecation of sbt 0.13 syntax

sbt 1.5.0 deprecates both the sbt 0.13 style shell syntax `proj/cofing:intask::key` and sbt 0.13 styld build.sbt DSL `key in (Compile, intask)` in favor of the unified slash syntax.

There's a [syntactic Scalafix rule for unified slash syntax](https://eed3si9n.com/syntactic-scalafix-rule-for-unified-slash-syntax)
to semi-automatically rewrite existing sbt 0.13 syntax to the slash syntax. Currently it requires the use of scalafix CLI
and it's not very precise (because it's a syntactic rule that only looks at the shape of the code) but it gets most of the job done.

<code>
$ scalafix --rules=https://gist.githubusercontent.com/eed3si9n/57e83f5330592d968ce49f0d5030d4d5/raw/7f576f16a90e432baa49911c9a66204c354947bb/Sbt0_13BuildSyntax.scala *.sbt project/*.scala
</code>

See <https://www.scala-sbt.org/1.x/docs/Migrating-from-sbt-013x.html#slash> for details.

### Eviction error

sbt 1.5.0 removes eviction warning, and replaces it with stricter eviction error. Unlike the eviction warning that was based on speculation, eviction error only uses the [`ThisBuild / versionScheme` information][versionScheme] supplied by the library authors.

For example:

```scala
lazy val use = project
  .settings(
    name := "use",
    libraryDependencies ++= Seq(
      "org.http4s" %% "http4s-blaze-server" % "0.21.11",
      // https://repo1.maven.org/maven2/org/typelevel/cats-effect_2.13/3.0.0-M4/cats-effect_2.13-3.0.0-M4.pom
      // is published with early-semver
      "org.typelevel" %% "cats-effect" % "3.0.0-M4",
    ),
  )
```

The above build will fail to build `use/compile` with the following error:

```scala
[error] stack trace is suppressed; run last use / update for the full output
[error] (use / update) found version conflict(s) in library dependencies; some are suspected to be binary incompatible:
[error]
[error]   * org.typelevel:cats-effect_2.12:3.0.0-M4 (early-semver) is selected over {2.2.0, 2.0.0, 2.0.0, 2.2.0}
[error]       +- use:use_2.12:0.1.0-SNAPSHOT                        (depends on 3.0.0-M4)
[error]       +- org.http4s:http4s-core_2.12:0.21.11                (depends on 2.2.0)
[error]       +- io.chrisdavenport:vault_2.12:2.0.0                 (depends on 2.0.0)
[error]       +- io.chrisdavenport:unique_2.12:2.0.0                (depends on 2.0.0)
[error]       +- co.fs2:fs2-core_2.12:2.4.5                         (depends on 2.2.0)
[error]
[error]
[error] this can be overridden using libraryDependencySchemes or evictionErrorLevel
```

This is because Cats Effect 2.x and 3.x are found in the classpath, and Cats Effect has declared that it uses early-semver. If the user wants to opt-out of this, the user can do so per module:

```scala
ThisBuild / libraryDependencySchemes += "org.typelevel" %% "cats-effect" % "always"
```

or globally as:

```scala
ThisBuild / evictionErrorLevel := Level.Info
```

On the other hand, if you want to bring back the guessing feature in eviction warning, you can do using the following settings:

```scala
ThisBuild / assumedVersionScheme := VersionScheme.PVP
ThisBuild / assumedVersionSchemeJava := VersionScheme.EarlySemVer
ThisBuild / assumedEvictionErrorLevel := Level.Warn
```

[@eed3si9n][@eed3si9n] implemented this in [#6221][6221], inspired in part by Scala Center's [sbt-eviction-rules](https://github.com/scalacenter/sbt-eviction-rules), which was implemented by Alexandre Archambault ([@alxarchambault][@alxarchambault]) and Julien Richard-Foy ([@julienrf][@julienrf]).

### ThisBuild / packageTimestamp setting

In sbt 1.4.0 we started wiping out the timestamps in JAR to make the builds more repeatable. This had an unintended consequence of breaking Play's last-modified response header.

To opt out of this default, the user can use:

```scala
ThisBuild / packageTimestamp := Package.keepTimestamps

// or

ThisBuild / packageTimestamp := Package.gitCommitDateTimestamp
```

[#6237][6237] by [@eed3si9n][@eed3si9n]

### Coursier-based launcher

sbt launcher shipped in the official installer of sbt is a generic launcher that is able to launch all versions of sbt. For the sbt launcher shipped with sbt 1.5.0 installer, its internal dependency resolver used to resolve sbt itself was updated from Apache Ivy to Coursier (Dependency resolver for the built has been updated to Coursier in sbt 1.3.0).

You can use `-Dsbt.launcher.coursier=false` to opt out of using Coursier and used Apache Ivy instead. [launcher#86][launcher86] by [@eed3si9n][@eed3si9n]

### Other updates

- Fixes `SemanticdbPlugin` creating duplicate `scalacOptions` or dropping `-Yrangepos` [#6296][6296]/[#6316][6316] by [@bjaglin][@bjaglin] and [@eed3si9n][@eed3si9n]
- Fixes tab completion of dependency configurations `Compile`, `Test`, etc [#6283][6283] by [@eed3si9n][@eed3si9n]
- Fixes exit code calculation in `StashOnFailure` [#6266][6266] by [@melezov][@melezov]
- Fixes concurrency issues with `testQuick` [#6326][6326] by [@RafalSumislawski][@RafalSumislawski]
- Updates to Scala 2.12.13.
- Updates to Coursier 2.0.12, includes `reload` memory fix by [@jtjeferreira] and behind-the-proxy IntelliJ import fix added by [@eed3si9n][@eed3si9n]
- Warns when `ThisBuild / versionScheme` is missing while publishing [#6310][6310] by [@eed3si9n][@eed3si9n]
- Use 2010-01-01 for the repeatable build timestamp wipe-out to avoid negative date [#6254][6254] by [@takezoe][@takezoe] (There's an active discussion to use commit date instead)
- Adds FileInput/FileOutput that avoids intermediate String parsing [#5515][5515] by [@jtjeferreira][@jtjeferreira]
- Support credential file without realm [lm#367][lm367] by [@MasseGuillaume][@MasseGuillaume]
- Support MUnit out of box [#6335][6335] by [@julienrf][@julienrf]
- Automatically publishLocal plugin dependency subprojects before `scripted` [#6351][6351] by [@steinybot][@steinybot]
- Update Launcher to use Coursier to download the artifact [launcher#86][launcher86] by [@eed3si9n][@eed3si9n]

### Participation

sbt 1.5.0 was brought to you by 30 contributors. Eugene Yokota (eed3si9n), Adrien Piquerez, Ethan Atkins, João Ferreira, Matthias Kurz, Eric Peters, Jason Zaugg, Sam Halliday, Arthur Sengileyev, Erlend Hamnaberg, Erwan Queffélec, Guillaume Martres, Guillaume Massé, Martin Duhem, Mirco Dotta, Arthur McGibbon, Brice Jaglin, Cyrille Chepelov, Dale Wijnand, Eric Meisel, Jason Pickens, Josef Vlach, Julien Richard-Foy, Kenji Yoshida (xuwei-k), Luc Henninger, Marcos Pereira, Marko Elezovic, Naoki Takezoe, Ondra Pelech, Rafał Sumisławski. Thanks!

Thanks to everyone who's helped improve sbt and Zinc 1 by using them, reporting bugs, improving our documentation, porting builds, porting plugins, and submitting and reviewing pull requests.

For anyone interested in helping sbt, there are many avenues for you to help, depending on your interest. If you're interested, [Contributing](https://github.com/sbt/sbt/blob/develop/CONTRIBUTING.md), ["help wanted"](https://github.com/sbt/sbt/issues?q=is%3Aissue+is%3Aopen+label%3A%22help+wanted%22), ["good first issue"](https://github.com/sbt/sbt/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22), and [Discussions](https://github.com/sbt/sbt/discussions/) are good starting points.

### Donate to April

Apparently April, an active contributor to Scala compiler has been sick without diagnosis. Let's help her out!

https://www.gofundme.com/f/help-april-survive-while-sick

  [versionScheme]: https://www.scala-sbt.org/1.x/docs/Publishing.html#Version+scheme
  [@adpi2]: https://twitter.com/adrienpi2
  [@jtjeferreira]: https://github.com/jtjeferreira
  [@takezoe]: https://github.com/takezoe
  [@eed3si9n]: https://twitter.com/eed3si9n
  [@julienrf]: https://twitter.com/julienrf
  [@alxarchambault]: https://twitter.com/alxarchambault
  [@bjaglin]: https://github.com/bjaglin
  [@RafalSumislawski]: https://github.com/RafalSumislawski
  [@melezov]: https://github.com/melezov
  [@MasseGuillaume]: https://github.com/MasseGuillaume
  [@steinybot]: https://github.com/steinybot
  [@arixmkii]: https://github.com/arixmkii
  [lm361]: https://github.com/sbt/librarymanagement/pull/361
  [lm367]: https://github.com/sbt/librarymanagement/pull/367
  [6296]: https://github.com/sbt/sbt/pull/6296
  [5515]: https://github.com/sbt/sbt/pull/5515
  [6254]: https://github.com/sbt/sbt/pull/6254
  [6221]: https://github.com/sbt/sbt/pull/6221
  [6283]: https://github.com/sbt/sbt/pull/6283
  [6237]: https://github.com/sbt/sbt/pull/6237
  [6316]: https://github.com/sbt/sbt/pull/6316
  [6310]: https://github.com/sbt/sbt/pull/6310
  [6326]: https://github.com/sbt/sbt/pull/6326
  [6266]: https://github.com/sbt/sbt/pull/6266
  [6335]: https://github.com/sbt/sbt/pull/6335
  [6351]: https://github.com/sbt/sbt/pull/6351
  [6403]: https://github.com/sbt/sbt/pull/6403
  [6401]: https://github.com/sbt/sbt/pull/6401
  [6397]: https://github.com/sbt/sbt/pull/6397
  [6408]: https://github.com/sbt/sbt/pull/6408
  [6415]: https://github.com/sbt/sbt/issues/6415
  [launcher86]: https://github.com/sbt/launcher/pull/86
  [launcher89]: https://github.com/sbt/launcher/pull/89
  [launcher92]: https://github.com/sbt/launcher/pull/92
  [launcher93]: https://github.com/sbt/launcher/pull/93
  [zinc968]: https://github.com/sbt/zinc/pull/968
  [lm372]: https://github.com/sbt/librarymanagement/pull/372
