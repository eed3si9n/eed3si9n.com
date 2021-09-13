---
title:       "sbt 1.4.0"
type:        story
date:        2020-10-05
draft:       false
promote:     true
sticky:      false
url:         /sbt-1.4.0
aliases:     [ /node/357 ]
tags:        [ "sbt" ]
---

Hi everyone. On behalf of the sbt project, I am happy to announce sbt 1.4.0. This is the fourth feature release of sbt 1.x, a binary compatible release focusing on new features. sbt 1.x is released under Semantic Versioning, and the plugins are expected to work throughout the 1.x series.

The headline features of sbt 1.4.0 are:

- build server protocol (BSP) support
- sbtn: a native thin client for sbt
- build caching
- `ThisBuild / versionScheme` to take the guessing out of eviction warning

<!--more-->

### How to upgrade

Download **the official sbt launcher** from SDKMAN or download from <https://www.scala-sbt.org/download.html>. This installer includes the `sbtn` binary.

In addition, the sbt version used for your build is upgraded by putting the following in `project/build.properties`:

<code>
sbt.version=1.4.0
</code>

This mechanism allows that sbt 1.4.0 is used only for the builds that you want.

### Build server protocol (BSP) support

sbt 1.4.0 adds build server protocol (BSP) support, contributed by [Scala Center](https://contributors.scala-lang.org/t/build-server-protocol-in-sbt/4234). Main implementation was done by Adrien Piquerez ([@adpi2](https://twitter.com/adrienpi2)) based on [@eed3si9n](https://twitter.com/eed3si9n)'s prototype.

When sbt 1.4.0 starts, it will create a file named `.bsp/sbt.json` containing a machine-readable instruction on how to run `sbt -bsp`, which is a command line program that uses standard input and output to communicate to sbt server using build server protocol.

#### How to import to IntelliJ using BSP

1. Start sbt in a terminal
2. Open IntelliJ IDEA 2020.1.2 or later
3. Select "Open or import", and select "BSP Project"

#### How to import to VS Code + Metals

1. Delete existing `.bsp`, `.metals`, `.bloop` directories if any
2. Open VS Code in the working directory
3. Ignore the prompt to import the project
4. Start `sbt -Dsbt.semanticdb=true` in the Terminal tab. Wait till it displays "sbt server started"
5. Navigate to Metals view, and select "Restart build server"
6. Type `compile` into the sbt session to generate SemanticDB files

<img border="0" alt="" src="/images/bsp-metals-1.4.0.gif" width="720" />

[#5538][5538]/[#5443][5443] by [@adpi2][@adpi2]

### Native thin client

sbt 1.4.0 adds an official native thin client called `sbtn` that supports all tasks. If you're using the official sbt launcher 1.4.0 and not the knockoff kind you can use `--client` option to run the native thin client:

<code>
$ sbt --client compile
$ sbt --client shutdown
</code>

The native thin client will run sbt (server) as a daemon, which avoids the JVM spinup and loading time for the second call onwards. This could an option if you would like to use sbt from the system shell such as Zsh and Fish.

Remember to call `sbt --client shutdown` when you're done! If you want to enable this via an environment variable you can set `SBT_NATIVE_CLIENT` to `true`.
`sbtn` binary files are also available from https://github.com/sbt/sbtn-dist/releases/tag/v1.4.0

[#5620][5620] by [@eatkins][@eatkins]

### ThisBuild / versionScheme

sbt 1.4.0 adds a new setting called `ThisBuild / versionScheme` to track version scheme of the build:

<scala>
ThisBuild / versionScheme := Some("early-semver")
</scala>

The supported values are `"early-semver"`, `"pvp"`, and `"semver-spec"`. sbt will include this information into `pom.xml` and `ivy.xml` as a property. In addition, sbt 1.4.0 will use the information to take the guessing out of eviction warning when this information is available. [#5724][5724] by [@eed3si9n][@eed3si9n]

### VirtualFile + RemoteCache

sbt 1.4.0 / Zinc 1.4.0 virtualizes the file paths tracked during incremental compilation. The benefit for this that the state of incremental compilation can shared across _different_ machines, as long as `ThisBuild / rootPaths` are enumerated beforehand.

To demonstrate this, we've also added **experimental** [cached compilation](http://eed3si9n.com/cached-compilation-for-sbt) feature to sbt. All you need is the following setting:

<scala>
ThisBuild / pushRemoteCacheTo := Some(MavenCache("local-cache", file("/tmp/remote-cache")))
</scala>

Then from machine 1, call `pushRemoteCache`. This will publish the `*.class` and Zinc Analysis artifacts to the location. Next, from machine 2, call `pullRemoteCache`.

[zinc#712][zinc712]/[#5417][5417] by [@eed3si9n][@eed3si9n]

### Build linting

On start up, sbt 1.4.0 checks for unused settings/tasks. Because most settings are on the intermediary to other settings/tasks, they are included into the linting by default. The notable exceptions are settings used exclusively by a command. To opt-out, you can either append it to `Global / excludeLintKeys` or set the rank to invisible.

[#5153][5153] by [@eed3si9n][@eed3si9n]

### Conditional task

sbt 1.4.0 adds support for conditional task (or Selective task), which is a new kind of task automatically created when `Def.task { ... }` consists of an `if`-expression:

<scala>
bar := {
  if (number.value < 0) negAction.value
  else if (number.value == 0) zeroAction.value
  else posAction.value
}
</scala>

Unlike the regular (Applicative) task composition, conditional tasks delays the evaluation of then-clause and else-clause as naturally expected of an `if`-expression. This is already possible with `Def.taskDyn { ... }`, but unlike dynamic tasks, conditional task works with `inspect` command. See [Selective functor for sbt](http://eed3si9n.com/selective-functor-in-sbt) for more details. [#5558][5558] by [@eed3si9n][@eed3si9n]

### Incremental build pipelining

sbt 1.4.0 adds experimental incremental build pipelining. To enable build pipelining for the build:

<scala>
ThisBuild / usePipelining := true
</scala>

To opt-out of creating an early output for some of the subprojects:

<scala>
exportPipelining := false
</scala>

[#5703][5703] by [@eed3si9n][@eed3si9n]

### sbt-dependency-graph is in-sourced

sbt 1.4.0 brings in Johannes Rudolph's sbt-dependency-graph plugin into the code base.
Since it injects many tasks per subprojects, the plugin is split into two parts:
- `MiniDependencyTreePlugin` that is enabled by default, bringing in `dependencyTree` task to `Compile` and `Test` configurations
- Full strength `DependencyTreePlugin` that is enabled by putting the following to `project/plugins.sbt`:

<scala>
addDependencyTreePlugin
</scala>

### Fixes with compatibility implications

- Replaces Apache Log4j with our own logger by default to avoid Appender leakage. Use `ThisBuild / useLog4J := true` to use Log4j. [#5731][5731] by [@eatkins][@eatkins]
- Makes JAR file creation repeatable by sorting entry by name and dropping timestamps [#5344][5344]/[io#279][io279] by [@raboof][@raboof]
- Loads bare settings in the alphabetic order of the build files [#2697][2697]/[#5447][5447] by [@eed3si9n][@eed3si9n]
- Loads `val`s from top-to-bottom within a build file [#2232][2232]/[#5448][5448] by [@eed3si9n][@eed3si9n]
- HTTP resolvers require explicit opt-in using `.withAllowInsecureProtocol(true)` [#5593][5593] by [@eed3si9n][@eed3si9n]
- Ctrl-C during triggered execution `~` returns to the shell instead of shutting down sbt [#5804][5804] by [@eatkins][@eatkins]

### Other updates

- Updates shell to use JLine 3 for better tab completion [#5671][5671] by [@eatkins][@eatkins]
- Adds support for Scala 2.13-3.0 sandwich [#5767][5767] by [@eed3si9n][@eed3si9n]
- Throws an error if you run sbt from `/` without `-Dsbt.rootdir=true` [#5112][5112] by [@eed3si9n][@eed3si9n]
- Upates `StateTransform` to accept `State => State` [#5260][5260] by [@eatkins][@eatkins]
- Fixes various issues around background run [#5259][5259] by [@eatkins][@eatkins]
- Turns off supershell when `TERM` is set to "dumb" [#5278][5278] by [@hvesalai][@hvesalai]
- Avoids using system temporary directories for logging [#5289][5289] by [@eatkins][@eatkins]
- Adds library endpoint for `sbt.ForkMain` [#5315][5315] by [@olafurpg][@olafurpg]
- Avoids using last modified time of directories to invalidate `doc` [#5362][5362] by [@eatkins][@eatkins]
- Fixes the default artifact of packageSrc for custom configuration [#5403][5403] by [@eed3si9n][@eed3si9n]
- Fixes task cancellation handling [#5446][5446]/[zinc#742][zinc742] by [@azolotko][@azolotko]
- Adds `toTaskable` method injection to `Initialize[A]` for tuple syntax [#5439][5439] by [@dwijnand][@dwijnand]
- Fixes the error message for an undefined setting [#5469][5469] by [@nigredo-tori][@nigredo-tori]
- Updates `semanticdbVersion` to 4.3.7 [#5481][5481] by [@anilkumarmyla][@anilkumarmyla]
- Adds `Tracked.outputChangedW` and `Tracked.inputChangedW` which requires typeclass evidence of `JsonWriter[A]` instead of `JsonFormat[A]` [#5513][5513] by [@bjaglin][@bjaglin]
- Fixes various supershell interferences [#5319][5319] by [@eatkins][@eatkins]
- Adds [extension methods](https://github.com/sbt/sbt/blob/develop/main/src/main/scala/sbt/UpperStateOps.scala) to `State` to faciliate sbt server communication [#5207][5207] by [@eed3si9n][@eed3si9n]
- Adds support for weighed tags for `testGrouping` [#5527][5527] by [@frosforever][@frosforever]
- Updates to sjson-new, which shades Jawn 1.0.0 [#5595][5595] by [@eed3si9n][@eed3si9n]
- Fixes NullPointerError when credential realm is `null` [#5526][5526] by [@3rwww1][@3rwww1]
- Adds `Def.promise` for long-running tasks to communicate to another task [#5552][5552] by [@eed3si9n][@eed3si9n]
- Uses Java's timestamp on JDK 10+ as opposed to using native call [io#274][io274] by [@slandelle][@slandelle]
- Adds retry with backoff during publish (`-Dsbt.repository.publish.attempts` set to 3) [lm#340][lm340] by [@izharahmd][@izharahmd]
- Improves failure message for PUT [lm#309][lm309] by [@swaldman][@swaldman]
- Adds provenance to AnalyzedClass [zinc#786][zinc786] by [@dwijnand][@dwijnand] + [@mspnf][@mspnf]
- Makes hashing childrenOfSealedClass stable [zinc#788][zinc788] by [@dwijnand][@dwijnand]
- Fixes performance regressions around build source monitoring [#5530][5530] by [@eatkins][@eatkins]
- Fixes performance regressions around super shell [#5531][5531] by [@eatkins][@eatkins]
- Various performance improvements in Zinc [zinc#756][zinc756]/[zinc#763][zinc763] by [@retronym][@retronym]
- Adds a monitor to warn about excessive GC [#5812][5812] by [@eatkins][@eatkins]
- Fixes forked tests running tests twice when they match multiple fingerprints [#5800][5800] by [@Duhemm][@Duhemm]

### Participation

sbt 1.4.0 was brought to you by 34 contributors. Ethan Atkins, Eugene Yokota (eed3si9n), Johannes Rudolph, Dale Wijnand, Adrien Piquerez, Jason Zaugg, Arnout Engelen, Josh Soref, Guillaume Martres, Maksim Ochenashko, Anil Kumar Myla, Brice Jaglin, Claudio Bley, João Ferreira, Steve Waldman, frosforever, Alex Zolotko, Heikki Vesalainen, Ismael Juma, Stephane Landelle, Jannik Theiß, izharahmd, lloydmeta, Alexandre Archambault, Eric Peters, Erwan Queffelec, Kenji Yoshida (xuwei-k), Martin Duhem, Olafur Pall Geirsson, Renato Cavalcanti, Vincent PERICART, nigredo-tori. Thanks!

Thanks to everyone who's helped improve sbt and Zinc 1 by using them, reporting bugs, improving our documentation, porting builds, porting plugins, and submitting and reviewing pull requests.

For anyone interested in helping sbt, there are many avenues for you to help, depending on your interest. If you're interested, [Contributing](https://github.com/sbt/sbt/blob/develop/CONTRIBUTING.md), ["help wanted"](https://github.com/sbt/sbt/issues?q=is%3Aissue+is%3Aopen+label%3A%22help+wanted%22), ["good first issue"](https://github.com/sbt/sbt/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22) are good starting points.

### Note to plugin authors

If you build and publish a plugin using sbt 1.4.0, your users will also be forced to upgrade to sbt 1.4.0 immediately. To prevent this you can cross build your plugin against sbt 1.2.8 (while using sbt 1.4.0) as follows:

<scala>
pluginCrossBuild / sbtVersion := "1.2.8"
</scala>

### Appendix

To test sbt server manually, make sure to have an sbt session running, and start `sbt -bsp` in another termnial. And paste the following in:

<code>
{ "jsonrpc": "2.0", "id": 1, "method": "build/initialize", "params": { "displayName": "foo", "version": "1.0.0", "bspVersion": "2.0.0-M5", "rootUri": "file:///tmp/hello", "capabilities": { "languageIds": ["scala"] } } }
</code>

Then enter `\r\n` (type `Enter`, `Ctrl-J` for zsh). This should return:

<code>
Content-Length: 200
Content-Type: application/vscode-jsonrpc; charset=utf-8

{"jsonrpc":"2.0","id":1,"result":{"displayName":"sbt","version":"1.4.0-SNAPSHOT","bspVersion":"2.0.0-M5","capabilities":{"compileProvider":{"languageIds":["scala"]},"dependencySourcesProvider":true}}}
</code>

  [5112]: https://github.com/sbt/sbt/pull/5112
  [5153]: https://github.com/sbt/sbt/pull/5153
  [5260]: https://github.com/sbt/sbt/pull/5260
  [5259]: https://github.com/sbt/sbt/pull/5259
  [5278]: https://github.com/sbt/sbt/pull/5278
  [5289]: https://github.com/sbt/sbt/pull/5289
  [5315]: https://github.com/sbt/sbt/pull/5315
  [5344]: https://github.com/sbt/sbt/pull/5344
  [5362]: https://github.com/sbt/sbt/pull/5362
  [5403]: https://github.com/sbt/sbt/pull/5403
  [5207]: https://github.com/sbt/sbt/pull/5207
  [5446]: https://github.com/sbt/sbt/pull/5446
  [5447]: https://github.com/sbt/sbt/pull/5447
  [2697]: https://github.com/sbt/sbt/issues/2697
  [5448]: https://github.com/sbt/sbt/pull/5448
  [2232]: https://github.com/sbt/sbt/issues/2232
  [5439]: https://github.com/sbt/sbt/pull/5439
  [5469]: https://github.com/sbt/sbt/pull/5469
  [5481]: https://github.com/sbt/sbt/pull/5481
  [5513]: https://github.com/sbt/sbt/pull/5513
  [5417]: https://github.com/sbt/sbt/pull/5417
  [5319]: https://github.com/sbt/sbt/pull/5319
  [5527]: https://github.com/sbt/sbt/pull/5527
  [5530]: https://github.com/sbt/sbt/pull/5530
  [5531]: https://github.com/sbt/sbt/pull/5531
  [5538]: https://github.com/sbt/sbt/pull/5538
  [5443]: https://github.com/sbt/sbt/pull/5443
  [5593]: https://github.com/sbt/sbt/pull/5593
  [5595]: https://github.com/sbt/sbt/pull/5595
  [5526]: https://github.com/sbt/sbt/pull/5526
  [5552]: https://github.com/sbt/sbt/pull/5552
  [5558]: https://github.com/sbt/sbt/pull/5558
  [5724]: https://github.com/sbt/sbt/pull/5724
  [5620]: https://github.com/sbt/sbt/pull/5620
  [5671]: https://github.com/sbt/sbt/pull/5671
  [5703]: https://github.com/sbt/sbt/pull/5703
  [5622]: https://github.com/sbt/sbt/pull/5622
  [5767]: https://github.com/sbt/sbt/pull/5767
  [5812]: https://github.com/sbt/sbt/pull/5812
  [5800]: https://github.com/sbt/sbt/pull/5800
  [5804]: https://github.com/sbt/sbt/pull/5804
  [5782]: https://github.com/sbt/sbt/pull/5782
  [5788]: https://github.com/sbt/sbt/pull/5788
  [5731]: https://github.com/sbt/sbt/pull/5731
  [5839]: https://github.com/sbt/sbt/pull/5839
  [5865]: https://github.com/sbt/sbt/pull/5865
  [5878]: https://github.com/sbt/sbt/pull/5878
  [io274]: https://github.com/sbt/io/pull/274
  [io279]: https://github.com/sbt/io/pull/279
  [lm309]: https://github.com/sbt/librarymanagement/pull/309
  [lm340]: https://github.com/sbt/librarymanagement/pull/340
  [zinc712]: https://github.com/sbt/zinc/pull/712
  [zinc742]: https://github.com/sbt/zinc/pull/742
  [zinc756]: https://github.com/sbt/zinc/pull/756
  [zinc763]: https://github.com/sbt/zinc/pull/763
  [zinc786]: https://github.com/sbt/zinc/pull/786
  [zinc788]: https://github.com/sbt/zinc/pull/788
  [@eed3si9n]: https://github.com/eed3si9n
  [@eatkins]: https://github.com/eatkins
  [@dwijnand]: https://github.com/dwijnand
  [@hvesalai]: https://github.com/hvesalai
  [@olafurpg]: https://github.com/olafurpg
  [@raboof]: https://github.com/raboof
  [@azolotko]: https://github.com/azolotko
  [@nigredo-tori]: https://github.com/nigredo-tori
  [@anilkumarmyla]: https://github.com/anilkumarmyla
  [@bjaglin]: https://github.com/bjaglin
  [@frosforever]: https://github.com/frosforever
  [@adpi2]: https://github.com/adpi2
  [@3rwww1]: https://github.com/3rwww1
  [@slandelle]: https://github.com/slandelle
  [@swaldman]: https://github.com/swaldman
  [@retronym]: https://github.com/retronym
  [@mspnf]: https://github.com/mspnf
  [@iRevive]: https://github.com/iRevive
  [@Duhemm]: https://github.com/Duhemm
  [@jtjeferreira]: https://github.com/jtjeferreira
  [@izharahmd]: https://github.com/izharahmd
