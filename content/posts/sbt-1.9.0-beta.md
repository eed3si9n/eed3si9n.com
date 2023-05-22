---
title:       "sbt 1.9.0-RC3"
type:        story
date:        2023-05-15
url:         /sbt-1.9.0-beta
tags:        [ "sbt" ]
---

Hi everyone. On behalf of the sbt project, I am happy to announce sbt 1.9.0-RC2. This is the nineth feature release of sbt 1.x, a binary compatible release focusing on new features. sbt 1.x is released under Semantic Versioning, and the plugins are expected to work throughout the 1.x series. Please try it out, and report any issues you might come across.

The headline features of sbt 1.9.0 are:

- POM consistency of sbt plugin publishing
- `sbt new`, a text-based adventure
- `releaseNotesURL` setting
- Deprecation of `IntegrationTest` configuration

<!--more-->

### How to upgrade

Download **the official sbt runner** from SDKMAN or download from <https://github.com/sbt/sbt/releases/tag/v1.9.0-RC3> to upgrade the `sbt` shell script and the launcher:

```bash
$ sdk install sbt 1.9.0-RC3
```

The sbt version used for your build is upgraded by putting the following in `project/build.properties`:

```bash
sbt.version=1.9.0-RC3
```

This mechanism allows that sbt 1.9.0-RC3 is used only for the builds that you want.

### Changes since sbt 1.9.0-RC2

- Fixes `sbt.io.IO.withTemporaryFile` not limiting access on Unix-like systems in [io#344][io344]/[zinc#1185][zinc1185] by [@eed3si9n][@eed3si9n]
- Deprecates misspelled `Problem#diagnosticRelatedInforamation` by [@ckipp01][@ckipp01] in [#7241][7241]
- Adds `actions` to `Problem`, allowing the compiler to forward actions that can address diagnostics, by [@ckipp01][@ckipp01] in [#7242][7242] and [@eed3si9n][@eed3si9n] in [#7251][7251]/[zinc#1186][zinc1186]

### Changes since sbt 1.9.0-RC1

- Fixes `libraryDependencySchemes` not overriding `assumedVersionScheme` [lm#415][lm415] by [@adriaanm][@adriaanm]
- Fixes RC1 not working on sbt-reproducible-builds [#7234][7234] by [@adpi2][@adpi2]
- Updates to sbt-giter8-resolver 0.16.2 by [@eed3si9n][@eed3si9n]
- More interactive `sbt new` by [@eed3si9n][@eed3si9n]

### POM consistency of sbt plugin publishing

sbt 1.9.0 publishes sbt plugin to Maven repository in a POM-consistent way. sbt has been publishing POM file of sbt plugins as `sbt-something-1.2.3.pom` even though the artifact URL is suffixed as `sbt-something_2.12_1.0`. This allowed "sbt-something" to be registered by Maven Central, allowing [search](https://central.sonatype.com/search?smo=true&q=sbt-pgp). However, as more plugins moved to Maven Central, it was considered that keeping POM consisntency rule was more important, especially for corporate repositories to proxy them.

sbt 1.9.0 will publish using both the conventional POM-inconsistent style and POM-consisntent sytle so prior sbt releases can still consume the plugin. However, this can be opted-out using `sbtPluginPublishLegacyMavenStyle` setting.

This fix was contributed by Adrien Piquerez ([@adpi2][@adpi2]) at Scala Center in [coursier#2633][coursier2633], [sbt#7096][7096] etc.

### `sbt new`, a text-based adventure

sbt 1.9.0 adds text-based menu when `sbt new` or `sbt init` is called without arguments:

```
$ sbt -Dsbt.version=1.9.0-RC2 init
....

Welcome to sbt new!
Here are some templates to get started:
 a) scala/toolkit.local               - Scala Toolkit (beta) by Scala Center and VirtusLab
 b) typelevel/toolkit.local           - Toolkit to start building Typelevel apps
 c) sbt/cross-platform.local          - A cross-JVM/JS/Native project
 d) scala/scala-seed.g8               - Scala 2 seed template
 e) playframework/play-scala-seed.g8  - A Play project in Scala
 f) playframework/play-java-seed.g8   - A Play project in Java
 g) scala-js/vite.g8                  - A Scala.JS + Vite project
 i) holdenk/sparkProjectTemplate.g8   - A Scala Spark project
 m) spotify/scio.g8                   - A Scio project
 n) disneystreaming/smithy4s.g8       - A Smithy4s project
 q) quit
Select a template (default: a):
```

Unlike Giter8, `.local` template creates `build.sbt` etc in the **current directory**, and reboots into an sbt session.

This was contributed by Eugene Yokota in [#7228][7228].

### `releaseNotesURL` setting

sbt 1.9.0 adds `releaseNotesURL` setting, which creates `info.releaseNotesUrl` property in the POM file. This will then be used by Scala Steward. See [
Add release notes URLs to your POMs](https://contributors.scala-lang.org/t/add-release-notes-urls-to-your-poms/6059/1) for details.

This was contributed by Arman Bilge in [lm#410][lm410].

<a id="IntegrationTest"></a>

### Deprecation of IntegrationTest configuration

sbt 1.9.0 deprecates `IntegrationTest` configuration. ([RFC-3](/sbt-drop-custom-config/) proposes to deprecate general use of configuration axis beyond `Compile` and `Test`, and this is the first installment of the change.)

The recommended migration path is to create a subproject named "integration", or "foo-integration" etc.

```scala
lazy val integration = (project in file("integration"))
  .dependsOn(core) // your current subproject
  .settings(
    publish / skip := true,
    // test dependencies
    libraryDependencies += something % Test,
  )
```

From the shell you can run:

```scala
> integration/test
```

Assuming these are slow tests compared to the regular tests, I might not aggregate them at all from other subprojects, and maybe only run it on CI, but it's up to you.

Why deprecate `IntegrationTest`? `IntegrationTest` was a demoware for the idea of custom configuration axis, and now that we are planning to deprecate the mechanism to simplify sbt, we wanted to stop advertising it. We won't remove it during sbt 1.x series, but deprecation signals the non-recommendation status.

### Changes with compatibility implications

- Deprecates `IntegrationTest` configuration by [@eed3si9n][@eed3si9n]. See above.
- Updates underlying Coursier to 2.1.2 by [@eed3si9n][@eed3si9n].

### Other updates

- Fixes Zinc incremental compilation looping infinitely [zinc#1182][zinc1182] by [@CarstonSchilds][@CarstonSchilds]
- Fixes `libraryDependencySchemes` not overriding `assumedVersionScheme` [lm#415][lm415] by [@adriaanm][@adriaanm]
- Fixes spurious whitespace in the runner script by [@keynmol][@keynmol] in [#7134][7134]
- Makes `RunProfiler` available by [@dragos][@dragos] in [#7215][7215]
- Makes `publishLocal / skip` work by [@mdedetrich][@mdedetrich] in [#7165][7165]
- Fixes NullPointerError under `-Vdebug` by [@som-snytt][@som-snytt] in [zinc#1141][zinc1141]
- Fixes Maven `settings.xml` properties expansion by [@nrinaudo][@nrinaudo] in [lm#413][lm413]
- Adds `FileFilter.nothing` and `FileFilter.everything` by [@mdedetrich][@mdedetrich] in [io#340][io340]
- Adds `Resolver.ApacheMavenSnapshotsRepo` by [@mdedetrich][@mdedetrich]
- Avoids deprecated `java.net.URL` constructor by [@xuwei-k][@xuwei-k] in [io#341][io341]
- Updates to Swoval 2.1.10 by [@eatkins][@eatkins] in [io#343][io343]
- Updates to sbt-giter8-resolver 0.16.2 by [@eed3si9n][@eed3si9n]
- Fixes dead lock between `LoggerContext` and `Terminal` by [@adpi2][@adpi2] in [#7191][7191]
- Notifies `ClassFileManager` from `IncOptions` in `Incremental.prune` by [@lrytz] in [zinc1148][zinc1148]
- Updates usage info for java-home in the runner script by [@liang3zy22][@liang3zy22] in [#7171][7171]
- Deprecates misspelled `Problem#diagnosticRelatedInforamation` by [@ckipp01][@ckipp01] in [#7241][7241]
- Adds `actions` to `Problem`, allowing the compiler to forward actions that can address diagnostics, by [@ckipp01][@ckipp01] in [#7242][7242] and [@eed3si9n][@eed3si9n] in [#7251][7251]/[zinc#1186][zinc1186]

### Behind the scene

- Replaces olafurpg/setup-scala with actions/setup-java by [@mzuehlke][@mzuehlke] in [#7154][7154]
- Uses `sonatypeOssRepos` instead of `sonatypeRepo` by [@yoshinorin][@yoshinorin] in [#7227][7227]

### Participation

sbt 1.9.0 was brought to you by 23 contributors: Eugene Yokota (eed3si9n), Adrien Piquerez, Arman Bilge, Chris Kipp, Matthias Kurz, yoshinorin, Matthew de Detrich, Adriaan Moors, Iulian Dragos, Lukas Rytz, Anton Sviridov, Carston Schilds, Ethan Atkins, Julien Richard-Foy, Kenji Yoshida (xuwei-k), Liang Yan, Marco Zühlke, Nicolas Rinaudo, Seth Tisue, Som Snytt, Vedant, msolomon-ck. Thanks!

Thanks to everyone who's helped improve sbt and Zinc by using them, reporting bugs, improving our documentation, porting builds, porting plugins, and submitting and reviewing pull requests.

For anyone interested in helping sbt, there are many avenues for you to help, depending on your interest. If you're interested, [Contributing](https://github.com/sbt/sbt/blob/develop/CONTRIBUTING.md), ["help wanted"](https://github.com/sbt/sbt/issues?q=is%3Aissue+is%3Aopen+label%3A%22help+wanted%22), ["good first issue"](https://github.com/sbt/sbt/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22), and [Discussions](https://github.com/sbt/sbt/discussions/) are good starting points.

### Donate to Scala Center

Scala Center is a non-profit center at EPFL to support education and open source.

- https://scala.epfl.ch/donate.html

  [@eed3si9n]: https://github.com/eed3si9n
  [@Nirvikalpa108]: https://github.com/Nirvikalpa108
  [@adpi2]: https://github.com/adpi2
  [@er1c]: https://github.com/er1c
  [@eatkins]: https://github.com/eatkins
  [@dwijnand]: https://github.com/dwijnand
  [@ckipp01]: https://github.com/ckipp01
  [@mdedetrich]: https://github.com/mdedetrich
  [@xuwei-k]: https://github.com/xuwei-k
  [@nrinaudo]: https://github.com/nrinaudo
  [@CarstonSchilds]: https://github.com/CarstonSchilds
  [@som-snytt]: https://github.com/som-snytt
  [@lrytz]: https://github.com/lrytz
  [@dragos]: https://github.com/dragos
  [@keynmol]: https://github.com/keynmol
  [@mzuehlke]: https://github.com/mzuehlke
  [@yoshinorin]: https://github.com/yoshinorin
  [@liang3zy22]: https://github.com/liang3zy22
  [@adriaanm]: https://github.com/adriaanm
  [7096]: https://github.com/sbt/sbt/pull/7096
  [7215]: ttps://github.com/sbt/sbt/pull/7215
  [7191]: https://github.com/sbt/sbt/pull/7191
  [7228]: https://github.com/sbt/sbt/pull/7228
  [7134]: https://github.com/sbt/sbt/pull/7134
  [7165]: https://github.com/sbt/sbt/pull/7165
  [7154]: https://github.com/sbt/sbt/pull/7154
  [7227]: https://github.com/sbt/sbt/pull/7227
  [7171]: https://github.com/sbt/sbt/pull/7171
  [7234]: https://github.com/sbt/sbt/pull/7234
  [7241]: https://github.com/sbt/sbt/pull/7241
  [7242]: https://github.com/sbt/sbt/pull/7242
  [7251]: https://github.com/sbt/sbt/pull/7251
  [zinc1182]: https://github.com/sbt/zinc/pull/1182
  [zinc1141]: https://github.com/sbt/zinc/pull/1141
  [zinc1148]: https://github.com/sbt/zinc/pull/1148
  [zinc1186]: https://github.com/sbt/zinc/pull/1186
  [lm410]: https://github.com/sbt/librarymanagement/pull/410
  [lm411]: https://github.com/sbt/librarymanagement/pull/411
  [lm413]: https://github.com/sbt/librarymanagement/pull/413
  [lm415]: https://github.com/sbt/librarymanagement/pull/415
  [io340]: https://github.com/sbt/io/pull/340
  [io341]: https://github.com/sbt/io/pull/341
  [io343]: https://github.com/sbt/io/pull/343
  [coursier2633]: https://github.com/coursier/coursier/pull/2633
  [io344]: https://github.com/sbt/io/pull/344
  [zinc1185]: https://github.com/sbt/zinc/pull/1185
  [zinc1186]: https://github.com/sbt/zinc/pull/1186
