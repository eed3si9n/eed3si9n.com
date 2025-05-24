---
title: "sbt 1.11.0"
type: story
date: 2025-05-24
url: /sbt-1.11.0
tags: [ "sbt" ]
---

  [@eed3si9n]: https://github.com/eed3si9n
  [@adpi2]: https://github.com/adpi2
  [@dwijnand]: https://github.com/dwijnand
  [@xuwei-k]: https://github.com/xuwei-k

Hi everyone. On behalf of the sbt project, I am happy to announce sbt 1.11.0. This is the eleventh feature release of sbt 1.x, a binary compatible release focusing on new features. sbt 1.x is released under Semantic Versioning, and the plugins are expected to work throughout the 1.x series. Please try it out, and report any issues you might come across.

The headline features of sbt 1.11.0 are:

- Support for the Central Repository publishing

Full release note is here - <https://github.com/sbt/sbt/releases/tag/v1.11.0>

<!--more-->

### How to upgrade

The sbt version used for your build is upgraded by putting the following in `project/build.properties`:

```bash
sbt.version=1.11.0
```

This mechanism allows that sbt 1.11.0 is used only for the builds that you want.

### Central Repository publishing

The Central Repository (aka Maven Central) has long been the pillar of the JVM ecosystem including Scala. The mechanism to publish libraries to the Central has been hosted by Sonatype as OSS Repository Hosting (OSSRH) via HTTP PUT, but in March it was [announced](https://central.sonatype.org/news/20250326_ossrh_sunset/) that the endpoint will be sunset in June 2025 in favor of the [Central Portal](https://central.sonatype.org/publish/publish-portal-guide/) at <https://central.sonatype.com/>.

sbt 1.11.0 implements a built-in support to publish to Central Repository via the Central Portal. To publish to the Central Portal, first set `ThisBuild / publishTo` setting to the `localStaging` repository:

```scala
ThisBuild / publishTo := {
  val centralSnapshots = "https://central.sonatype.com/repository/maven-snapshots/"
  if (isSnapshot.value) Some("central-snapshots" at centralSnapshots)
  else localStaging.value
}
```

Add `credentials` to the host `central.sonatype.com` using the generated user token user name and password. When you're ready to publish, call `publishSigned` task (available via [sbt-pgp](https://github.com/sbt/sbt-pgp)). At this point, the JARs and POM files will be staged to your local `target/sona-staging` directory.

Next, call `sonaUpload` to upload to the Central Portal and manually release the bundle, or call `sonaRelease` to upload and automatically release to the Cental Repository.

This was contributed by [@eed3si9n][@eed3si9n] in [#8126](https://github.com/sbt/sbt/pull/8126). The feature was inspired by sbt-sonatype's workflow pioneered by Taro Saito, and [sonatype-central-client](https://github.com/lumidion/sonatype-central-client) spearheaded by David Doyle at [Lumidion](https://www.lumidion.com/).


#### Note: Central Portal account

To convert an account to the Central Portal, go to <https://central.sonatype.com/>, nagivate to **Sign In**, then use the existing Sonatype user name and password to try to log in. If it doesn't work, use **Forgot password** link to reset the password instead of creating a fresh account.
This should let you log into the Central Portal while still keeping your namespaces still associated with Legacy OSSRH publishing until you migrate them.

### What about sbt-ci-release?

sbt-ci-release 1.11.0-RC3 is published as well, which defaults to using `sonaRelease` as the `CI_SONATYPE_RELEASE` step. In other words, newer version of sbt-ci-release assumes that you have sbt 1.11.0 or later.

I think this is a reasonable assumption since there will be no Legacy OSSRH endpoint after June 30, 2025.

### Participation

Thanks to everyone who's helped improve sbt and Zinc by using them, reporting bugs, improving our documentation, porting builds, porting plugins, and submitting and reviewing pull requests.

For anyone interested in helping sbt, there are many avenues for you to help, depending on your interest. If you're interested, [Contributing](https://github.com/sbt/sbt/blob/develop/CONTRIBUTING.md), ["help wanted"](https://github.com/sbt/sbt/issues?q=is%3Aissue+is%3Aopen+label%3A%22help+wanted%22), ["good first issue"](https://github.com/sbt/sbt/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22), and [Discussions](https://github.com/sbt/sbt/discussions/) are good starting points.

----

### Donate to Scala Center

Scala Center is a non-profit center at EPFL to support education and open source. Please consider [donating](https://scala.epfl.ch/donate.html) to them, and publicly tweet/toot at @eed3si9n and @scala_lang when you do (I don't work for them, but we maintain sbt together).
