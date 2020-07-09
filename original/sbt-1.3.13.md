 [5634]: https://github.com/sbt/sbt/pull/5634
 [5587]: https://github.com/sbt/sbt/issues/5587
 [lm337]: https://github.com/sbt/librarymanagement/pull/337
 [sbt-coursier212]: https://github.com/coursier/sbt-coursier/pull/212
 [lp324]: https://github.com/sbt/sbt-launcher-package/pull/324
 [lp322]: https://github.com/sbt/sbt-launcher-package/pull/322
 [lp325]: https://github.com/sbt/sbt-launcher-package/pull/325
 [@eed3si9n]: https://github.com/eed3si9n
 [@l-konov]: https://github.com/l-konov
 [@henricook]: https://github.com/henricook
 [@er1c]: https://github.com/er1c

I'm happy to announce sbt 1.3.13 patch release. Full release note is here - https://github.com/sbt/sbt/releases/tag/v1.3.13.

Special thanks to Scala Center. It takes time to review bug reports, pull requests, make sure contributions land to the right places, and Scala Center sponsored me to do maintainer tasks for sbt during June.

### How to upgrade

Normally changing the `project/build.properties` to

```
sbt.version=1.3.13
```

would be ok. However, given that the release may contain fixes to scripts and also because your initial resolution would be faster with `*.(zip|tgz|msi)` that contains all the JAR files, we recommend you use the installer distribution. They will be available from SDKMAN etc:

```
sdk upgrade sbt
```

#### Notes about Homebrew

Homebrew maintainers have added a dependency to JDK 13 because they want to use more brew dependencies [brew#50649](https://github.com/Homebrew/homebrew-core/issues/50649). This causes sbt to use JDK 13 even when `java` available on PATH is JDK 8 or 11.

To prevent `sbt` from running on JDK 13, install [jEnv](https://www.jenv.be/) or switch to using [SDKMAN](https://sdkman.io/).

### Highlights

- sbt 1.3.13 brings in Giter8 0.13.1, which should fix regex problem on Windows.
- Fixes `missingOk` under Coursier [#5634][5634]/[sbt-coursier#212][sbt-coursier212] by [@eed3si9n][@eed3si9n]

### Participation

sbt 1.3.13 was brought to you by Scala Center + 4 contributors. Eugene Yokota (eed3si9n), Henri Cook, Eric Peters, and l-konov. Thank you!

Thanks to everyone who's helped improve sbt and Zinc 1 by using them, reporting bugs, improving our documentation, porting builds, porting plugins, and submitting and reviewing pull requests.

For anyone interested in helping sbt, there are many avenues for you to help, depending on your interest. If you're interested, [Contributing](https://github.com/sbt/sbt/blob/develop/CONTRIBUTING.md), ["help wanted"](https://github.com/sbt/sbt/issues?q=is%3Aissue+is%3Aopen+label%3A%22help+wanted%22), ["good first issue"](https://github.com/sbt/sbt/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22) are good starting points.
