Hi everyone. On behalf of the sbt project, I am happy to announce sbt 1.5.0-M1. This is the fifth feature release of sbt 1.x, a binary compatible release focusing on new features. sbt 1.x is released under Semantic Versioning, and the plugins are expected to work throughout the 1.x series.


The headline features of sbt 1.5.0 is:

- Scala 3 support

### How to upgrade

You can upgrade to sbt 1.5.0-M1 by putting the following in `project/build.properties`:

<code>
sbt.version=1.5.0-M1
</code>

### Scala 3 support

sbt 1.5.0 adds built-in Scala 3 support, contributed by Scala Center. Main implementation was done by Adrien Piquerez ([@adpi2][@adpi2]) based on EPFL/LAMP's [sbt-dotty](https://github.com/lampepfl/dotty/tree/master/sbt-dotty).

**Note**: Due to the transitive dependencies to Dokka, which is planned to be removed eventually, the following resolver is required to use Scala 3.0.0-M3 for now:

<scala>
ThisBuild / resolvers += Resolver.JCenterRepository
</scala>

After this resolver is added, you can now use Scala 3.0.0-M3 like any other Scala version.

<scala>
ThisBuild / scalaVersion := "3.0.0-M3"
ThisBuild / resolvers += Resolver.JCenterRepository
</scala>

This will compile the following `Hello.scala`:

<scala>
package example

@main def hello(arg: String*): Unit =
  if arg.isEmpty then println("hello")
  else println(s"hi ${arg.head}")
</scala>

### Scala 2.13-3.x sandwich

Scala 3.0.x [shares](https://www.scala-lang.org/2019/12/18/road-to-scala-3.html) the standard library with Scala 2.13, and since Scala 2.13.4, they can mutually consume the output of each other as external library. This allows you to create Scala 2.13-3.x sandwich, a layering of dependencies coming from different Scala versions.

sbt 1.5.0 introduces new cross building operand to use `_3` variant when `scalaVersion` is 2.13.x, and vice versa:

<scala>
("a" % "b" % "1.0").cross(CrossVersion.for3Use2_13)

("a" % "b" % "1.0").cross(CrossVersion.for2_13Use3)
</scala>

These are analogous to `%%` operator that selects `_2.13` etc based on `scalaVersion`. 

**Warning**: Libraries such as Cats may encode a particular notion in different ways for Scala 2.13 and 3.0. For example, arity abstraction may use Shapeless HList in Scala 2.13, but built-in Tuple types in Scala 3.0. Thus it's generally not safe to have `_2.13` and `_3` versions of the same library in the classpath, even transitively. Library authors should generally treat Scala 3.0 as any other major version, and generally prefer to cross publish `_3` variant to avoid the conflict. Application developers should be free to use `.cross(CrossVersion.for3Use2_13)` as long as the transitive dependency graph will not introduce `_2.13` variant of a library you already have in `_3` variant.

[lm#361][lm361] by [@adpi2][@adpi2]

### Eviction error

sbt 1.5.0 removes eviction warning, and replaces it with stricter eviction error. Unlike the eviction warning that was based on speculation, eviction error only uses the [`ThisBuild / versionScheme` information][versionScheme] supplied by the library authors.

For example:

<scala>
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
</scala>

The above build will fail to build `use/compile` with the following error:

<scala>
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
</scala>

This is because Cats Effect 2.x and 3.x are found in the classpath, and Cats Effect has declared that it uses early-semver. If the user wants to opt-out of this, the user can do so per module:

<scala>
ThisBuild / libraryDependencySchemes += "org.typelevel" %% "cats-effect" % "always"
</scala>

or globally as:

<scala>
ThisBuild / evictionErrorLevel := Level.Info
</scala>

[@eed3si9n][@eed3si9n] implemented this in [#6221][6221], inspired in part by Scala Center's [sbt-eviction-rules](https://github.com/scalacenter/sbt-eviction-rules), which was implemented by Alexandre Archambault ([@alxarchambault][@alxarchambault]) and Julien Richard-Foy ([@julienrf][@julienrf]).

### Other updates

- Use 2010-01-01 for the repeatable build timestamp wipe-out to avoid negative date [#6254][6254] by [@takezoe][@takezoe] (There's an active discussion to use commit date instead)
- Adds FileInput/FileOutput that avoids intermediate String parsing [#5515][5515] by [@jtjeferreira][@jtjeferreira]

### Participation

sbt 1.5.0-M1 was brought to you by 14 contributors. Eugene Yokota (eed3si9n), Adrien Piquerez, Ethan Atkins, João Ferreira, Eric Peters, Erlend Hamnaberg, Erwan Queffélec, Martin Duhem, Matthias Kurz, Mirco Dotta, Arthur McGibbon, Guillaume Martres, Kenji Yoshida (xuwei-k), Luc Henninger, Naoki Takezoe. Thanks!

Thanks to everyone who's helped improve sbt and Zinc 1 by using them, reporting bugs, improving our documentation, porting builds, porting plugins, and submitting and reviewing pull requests.

For anyone interested in helping sbt, there are many avenues for you to help, depending on your interest. If you're interested, [Contributing](https://github.com/sbt/sbt/blob/develop/CONTRIBUTING.md), ["help wanted"](https://github.com/sbt/sbt/issues?q=is%3Aissue+is%3Aopen+label%3A%22help+wanted%22), ["good first issue"](https://github.com/sbt/sbt/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22), and [Discussions](https://github.com/sbt/sbt/discussions/) are good starting points.

  [versionScheme]: https://www.scala-sbt.org/1.x/docs/Publishing.html#Version+scheme
  [@adpi2]: https://twitter.com/adrienpi2
  [@jtjeferreira]: https://github.com/jtjeferreira
  [@takezoe]: https://github.com/takezoe
  [@eed3si9n]: https://twitter.com/eed3si9n
  [@julienrf]: https://twitter.com/julienrf
  [@alxarchambault]: https://twitter.com/alxarchambault
  [lm361]: https://github.com/sbt/librarymanagement/pull/361
  [5515]: https://github.com/sbt/sbt/pull/5515
  [6254]: https://github.com/sbt/sbt/pull/6254
  [6221]: https://github.com/sbt/sbt/pull/6221