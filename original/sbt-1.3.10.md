  [2366]: https://github.com/sbt/sbt/issues/2366
  [5498]: https://github.com/sbt/sbt/pull/5498
  [ivy36]: https://github.com/sbt/ivy/pull/36
  [@eed3si9n]: https://github.com/eed3si9n

I'm happy to announce sbt 1.3.10 patch release. Full release note is here - https://github.com/sbt/sbt/releases/tag/v1.3.10

### How to upgrade

Normally changing the `project/build.properties` to

```
sbt.version=1.3.10
```

would be ok. However, given that the release may contain fixes to scripts and also because your initial resolution would be faster with `*.(zip|tgz|msi)` that contains all the JAR files, we recommend you use the installer distribution. They will be available from SDKMAN etc.

#### Notes about Homebrew

Homebrew maintainers have added a dependency to JDK 13 because they want to use more brew dependencies [brew#50649](https://github.com/Homebrew/homebrew-core/issues/50649). This causes sbt to use JDK 13 even when `java` available on PATH is JDK 8 or 11.

To prevent `sbt` from running on JDK 13, install [jEnv](https://www.jenv.be/) or switch to using [SDKMAN](https://sdkman.io/).

### Highlights

- Adds support for `null`/blank-realm credential for Maven repos hosted on Azure DevOps or Google Cloud Platform [ivy#36][ivy36] / [#2366][2366] by [@eed3si9n][@eed3si9n]
- Updates to sjson-new 0.8.3 [#5498][5498] by [@eed3si9n][@eed3si9n]

### Participation

sbt 1.3.10 was brought to you by Eugene Yokota (eed3si9n).

Thanks to everyone who's helped improve sbt and Zinc 1 by using them, reporting bugs, improving our documentation, porting builds, porting plugins, and submitting and reviewing pull requests.

For anyone interested in helping sbt, there are many avenues for you to help, depending on your interest. If you're interested, [Contributing](https://github.com/sbt/sbt/blob/develop/CONTRIBUTING.md), ["help wanted"](https://github.com/sbt/sbt/issues?q=is%3Aissue+is%3Aopen+label%3A%22help+wanted%22), ["good first issue"](https://github.com/sbt/sbt/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22) are good starting points.
