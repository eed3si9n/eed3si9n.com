[#304]: https://github.com/harrah/xsbt/issues/304
[#315]: https://github.com/harrah/xsbt/issues/315
[#327]: https://github.com/harrah/xsbt/issues/327
[#335]: https://github.com/harrah/xsbt/issues/335
[#393]: https://github.com/harrah/xsbt/issues/393
[#396]: https://github.com/harrah/xsbt/issues/396
[#380]: https://github.com/harrah/xsbt/issues/380
[#389]: https://github.com/harrah/xsbt/issues/389
[#388]: https://github.com/harrah/xsbt/issues/388
[#387]: https://github.com/harrah/xsbt/issues/387
[#386]: https://github.com/harrah/xsbt/issues/386
[#378]: https://github.com/harrah/xsbt/issues/378
[#377]: https://github.com/harrah/xsbt/issues/377
[#368]: https://github.com/harrah/xsbt/issues/368
[#394]: https://github.com/harrah/xsbt/issues/394
[#369]: https://github.com/harrah/xsbt/issues/369
[#403]: https://github.com/harrah/xsbt/issues/403
[#412]: https://github.com/harrah/xsbt/issues/412
[#415]: https://github.com/harrah/xsbt/issues/415
[#420]: https://github.com/harrah/xsbt/issues/420
[#462]: https://github.com/harrah/xsbt/pull/462
[#472]: https://github.com/harrah/xsbt/pull/472
[Launcher]: https://github.com/harrah/xsbt/wiki/Launcher

# Plan for 0.12.0

## Changes from 0.12.0-Beta2 to 0.12.0-RC1

 * Support globally overriding repositories ([#472]).  Define the repositories to use by putting a standalone `[repositories]` section (see the [Launcher] page) in `~/.sbt/repositories` and pass `-Dsbt.override.build.repos=true` to sbt.  Only the repositories in that file will be used by the launcher for retrieving sbt and Scala and by sbt when retrieving project dependencies.  (@jsuereth)

 * The launcher can launch all released sbt versions back to 0.7.0.

 * A more refined hint to run 'last' is given when a stack trace is suppressed.

 * Use java 7 Redirect.INHERIT to inherit input stream of subprocess ([#462],[#327]).  This should fix issues when forking interactive programs. (@vigdorchik)

 * Delete a symlink and not its contents when recursively deleting a directory.

 * The [Howto pages](http://www.scala-sbt.org/howto.html) on the [new site](http://www.scala-sbt.org) are at least readable now.  There is more content to write and more formatting improvements are needed, so [pull requests are welcome](https://github.com/sbt/sbt.github.com).

 * Use the binary version for cross-versioning even for snapshots and milestones.
Rely instead on users not publishing the same stable version against both stable Scala or sbt releases and snapshots/milestones.

 * API for embedding incremental compilation.  This interface is subject to change, but already being used in [a branch of the scala-maven-plugin](https://github.com/davidB/scala-maven-plugin/tree/feature/sbt-inc).

 * Experimental support for keeping the Scala compiler resident.  Enable by passing `-Dsbt.resident.limit=n` to sbt, where `n` is an integer indicating the maximum number of compilers to keep around.

## Changes from 0.12.0-M2 to 0.12.0-Beta2

 * Support for forking tests ([#415])
 * force 'update' to run when invoked directly ([#335])
 * `projects add/remove <URI>` for temporarily working with other builds
 * added `print-warnings` task that will print unchecked and deprecation warnings from the previous compilation without needing to recompile (Scala 2.10+ only)
 * various improvements to `help` and `tasks` commands as well as new `settings` command ([#315])
 * fix detection of ancestors for java sources
 * fix the resolvers used for `update-sbt-classifiers` ([#304])
 * fix auto-imports of plugins ([#412]) 
 * poms for most artifacts available via a virtual repository on repo.typesafe.com ([#420])
 * bump jsch version to 0.1.46. ([#403])
 * Added support for loading an ivy settings file from a URL.

## Changes from 0.12.0-M1 to M2

 * `test-quick` ([#393]) runs the tests specified as arguments (or all tests if no arguments are given) that:
  1. have not been run yet OR
  2. failed the last time they were run
  3. had any transitive dependencies recompiled since the last successful run OR
 * Argument quoting ([#396])
  * `> command "arg with spaces,\n escapes interpreted"`
  * `> command """arg with spaces,\n escapes not interpreted"""` 
  *  For the first variant, note that paths on Windows use backslashes and need to be escaped (`\\`).  Alternatively, use the second variant, which does not interpret escapes.
  * For using either variant in batch mode, note that a shell will generally require the double quotes themselves to be escaped.
 * The `help` command now accepts a regular expression to use to search the help.  See `help help` for details.
 * The sbt plugins repository is added by default for plugins and plugin definitions. [#380]
 * Properly resets JLine after being stopped by Ctrl+z (unix only). [#394]
 * `session save` overwrites settings in `build.sbt` (when appropriate). [#369]
 * other fixes/improvements: [#368], [#377], [#378], [#386], [#387], [#388], [#389]

### Binary sbt plugin dependency declarations in 0.12.0-M2

Declaring sbt plugin dependencies, as declared in sbt 0.11.2, will not work 0.12.0-M2. Instead of declaring a binary sbt plugin dependency within your plugin definition with:

```scala
  addSbtPlugin("a" % "b" % "1.0")
```

You instead want to declare that binary plugin dependency with:

```scala
libraryDependencies +=
  Defaults.sbtPluginExtra("a" % "b" % "1.0, "0.12.0-M2", "2.9.1")
```

This will only be an issue with binary plugin dependencies published for milestone releases of sbt going forward.

For convenience in future releases, a variant of `addSbtPlugin` will be added to support a specific sbt version with

```scala
  addSbtPlugin("a" % "b" % "1.0", sbtVersion = "0.12.0-M2")
```


## Changes from 0.11.2 to 0.12.0-M1

 * Plugin configuration directory precedence (see details below)
 * JLine 1.0 (details below)
 * Fixed source dependencies (details below)
 * Enhanced control over parallel execution (details below)
 * The cross building convention has changed for sbt 0.12 and Scala 2.10 and later (details below)
 * Aggregation has changed to be more flexible (details below)
 * Task axis syntax has changed from key(for task) to task::key (details below)
 * The organization for sbt has to changed to `org.scala-sbt` (was: org.scala-tools.sbt).  This affects users of the scripted plugin in particular.

## Details of major changes from 0.11.2 to 0.12.0

## Plugin configuration directory

In 0.11.0, plugin configuration moved from `project/plugins/` to just `project/`, with `project/plugins/` being deprecated.  Only 0.11.2 had a deprecation message, but in all of 0.11.x, the presence of the old style `project/plugins/` directory took precedence over the new style.  In 0.12.0, the new style takes precedence.  Support for the old style won't be removed until 0.13.0.

  1. Ideally, a project should ensure there is never a conflict.  Both styles are still supported, only the behavior when there is a conflict has changed.  
  2. In practice, switching from an older branch of a project to a new branch would often leave an empty `project/plugins/` directory that would cause the old style to be used, despite there being no configuration there.
  3. Therefore, the intention is that this change is strictly an improvement for projects transitioning to the new style and isn't noticed by other projects.

## JLine

Move to jline 1.0.  This is a (relatively) recent release that fixes several outstanding issues with jline but, as far as I can tell, remains binary compatible with 0.9.94, the version previously used. In particular:

  1. Properly closes streams when forking stty on unix.
  2. Delete key works on linux.  Please check that this works for your environment as well.
  3. Line wrapping seems correct.

## Parsing task axis

There is an important change related to parsing the task axis for settings and tasks that fixes [#202](https://github.com/harrah/xsbt/issues/202)

  1. The syntax before 0.12 has been `{build}project/config:key(for task)`
  2. The proposed (and implemented) change for 0.12 is `{build}project/config:task::key`
  3. By moving the task axis before the key, it allows for easier discovery (via tab completion) of keys in plugins.
  4. It is not planned to support the old syntax.  It would be ideal to deprecate it first, but this would take too much time to implement.

## Aggregation

Aggregation has been made more flexible.  This is along the direction that has been previously discussed on the mailing list.

  1. Before 0.12, a setting was parsed according to the current project and only the exact setting parsed was aggregated.
  2. Also, tab completion did not account for aggregation.
  3. This meant that if the setting/task didn't exist on the current project, parsing failed even if an aggregated project contained the setting/task.
  4. Additionally, if compile:package existed for the current project, *:package existed for an aggregated project, and the user requested 'package' run (without specifying the configuration) *:package wouldn't be run on the aggregated project (it isn't the same as the compile:package key that existed on the current).
  5. In 0.12, both of these situations result in the aggregated settings being selected.  For example,
    1. Consider a project `root` that aggregates a subproject `sub`.
    2. `root` defines `*:package`.
    3. `sub` defines `compile:package` and `compile:compile`.
    4. Running `root/package` will run `root/*:package` and `sub/compile:package`
    5. Running `root/compile` will run `sub/compile:compile`
  6. This change depends on the change to parsing the task axis.

## Parallel Execution

Fine control over parallel execution is supported as described here: https://github.com/harrah/xsbt/wiki/Parallel-Execution

  1. The default behavior should be the same as before, including the `parallelExecution` settings.
  2. The new capabilities of the system should otherwise be considered experimental.
  3. Therefore, `parallelExecution` won't be deprecated at this time.

## Source dependencies

A fix for issue [#329](https://github.com/harrah/xsbt/issues/329) is included.  This fix ensures that only one version of a plugin is loaded across all projects.  There are two parts to this.

  1. The version of a plugin is fixed by the first build to load it.  In particular, the plugin version used in the root build (the one in which sbt is started in) always overrides the version used in dependencies.
  2. Plugins from all builds are loaded in the same class loader.

Additionally, Sanjin's patches to add support for hg and svn URIs are included.

  1. sbt uses subversion to retrieve URIs beginning with `svn` or `svn+ssh`.  An optional fragment identifies a specific revision to checkout.
  2. Because a URI for mercurial doesn't have a mercurial-specific scheme, sbt requires the URI to be prefixed with `hg:` to identify it as a mercurial repository.
  3. Also, URIs that end with `.git` are now handled properly.

## Cross building

The cross version suffix is shortened to only include the major and minor version for Scala versions starting with the 2.10 series and for sbt versions starting with the 0.12 series.  For example, `sbinary_2.10` for a normal library or `sbt-plugin_2.10_0.12` for an sbt plugin.  This requires forward and backward binary compatibility across incremental releases for both Scala and sbt.

  1. This change has been a long time coming, but it requires everyone publishing an open source project to switch to 0.12 to publish for 2.10 or adjust the cross versioned prefix in their builds appropriately.
  2. Obviously, using 0.12 to publish a library for 2.10 requires 0.12.0 to be released before projects publish for 2.10.
  3. At the same time, sbt 0.12.0 itself should be published against 2.10.0 or else it will be stuck in 2.9.x for the 0.12.x series.
  4. There is now the concept of a binary version.  This is a subset of the full version string that represents binary compatibility.  That is, equal binary versions implies binary compatibility.  All Scala versions prior to 2.10 use the full version for the binary version to reflect previous sbt behavior.  For 2.10 and later, the binary version is `<major>.<minor>`.
  5. The cross version behavior for published artifacts is configured by the crossVersion setting.  It can be configured for dependencies by using the `cross` method on `ModuleID` or by the traditional %% dependency construction variant.  By default, a dependency has cross versioning disabled when constructed with a single % and uses the binary Scala version when constructed with %%.
  6. For snapshot/milestone versions of Scala or sbt (as determined by the presence of a '-' in the full version), dependencies use the binary Scala version by default, but any published artifacts use the full version.  The purpose here is to ensure that versions published against a snapshot or milestone do not accidentally pollute the compatible universe.  Note that this means that declaring a dependency on a version published against a milestone requires an explicit change to the dependency definition.
  7. The artifactName function now accepts a type ScalaVersion as its first argument instead of a String.  The full type is now `(ScalaVersion, ModuleID, Artifact) => String`.  ScalaVersion contains both the full Scala version (such as 2.10.0) as well as the binary Scala version (such as 2.10).
  8. The flexible version mapping added by Indrajit has been merged into the `cross` method and the %% variants accepting more than one argument have been deprecated.  Some examples follow.

These are equivalent:

```scala
"a" % "b" % "1.0"
"a" % "b" % "1.0" cross CrossVersion.Disabled
```

These are equivalent:

```scala
"a" %% "b" % "1.0"
"a" % "b" % "1.0" cross CrossVersion.binary
```

This uses the full Scala version instead of the binary Scala version:

```scala
"a" % "b" % "1.0" cross CrossVersion.full
```

This uses a custom function to determine the Scala version to use based on the binary Scala version:

```scala
"a" % "b" % "1.0" cross CrossVersion.binaryMapped {
  case "2.9.1" => "2.9.0" // remember that pre-2.10, binary=full
  case x => x
}
```

This uses a custom function to determine the Scala version to use based on the full Scala version:

```scala
"a" % "b" % "1.0" cross CrossVersion.fullMapped {
  case "2.9.1" => "2.9.0"
  case x => x
}
```

Using a custom function is used when cross-building and a dependency isn't available for all Scala versions.  This feature should be less necessary with the move to using a binary version.
