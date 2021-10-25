---
title:       "POM consistency for sbt plugins"
type:        story
date:        2021-05-23
draft:       false
promote:     true
sticky:      false
url:         /pom-consistency-for-sbt-plugins
aliases:     [ /node/392 ]
tags:        [ "sbt" ]
---

There's a long-standing bug that sbt maintainers have known for a while, which is that when sbt plugin is published to a Maven repository, the POM file sbt generates is not valid. From a mailing list thread titled [[0.12] plan](https://groups.google.com/g/simple-build-tool/c/qH7xE0jvBMk/m/LMt6wlkTMRoJ) for instance, Mark McBride reported it in 2012:

> On the maven note, the poms generated for plugins aren't actually
> valid. Trying to upload them to artifactory without disabling pom
> consistency checks fails :/

Here's an example. sbt-pgp 2.1.2 is published to <https://repo1.maven.org/maven2/com/github/sbt/sbt-pgp_2.12_1.0/2.1.2/sbt-pgp-2.1.2.pom>, but if you look at the POM file name it's `sbt-pgp-2.1.2.pom`, not matching the URL structure `sbt-pgp_2.12_1.0`. Since most plugins were published to Bintray until recently, and because only a few plugins were published to Sonatype OSSRH, which seems to be okay with this, this issue has not gotten too much attention.

Fast forward 2021, Bintray was discontinued, and now that more plugins are published to Sonatype OSSRH, companies that use Artifactory to front Maven Central are running into this. Active GitHub issue is [sbt/sbt#3410](https://github.com/sbt/sbt/issues/3410). I will discuss an experimental workaround for this.

### republishing the plugins

First clone the plugins you want to republish, and make sure sbt-bintray is removed, since it takes over the publishing. Next add the following to the plugin build:

```scala
// set some unique postfix
ThisBuild / version := "0.15.0-Pets1"

lazy val root = (project in file("."))
  .enablePlugins(SbtPlugin)
  .settings(
    name := "sbt-assembly",
    ....

    publishMavenStyle := true,
    // add this
    pomConsistency2021DraftSettings,
  )

// Add the following
lazy val pomConsistency2021Draft = settingKey[Boolean]("experimental")

/**
 * this is an unofficial experiment to re-publish plugins with better Maven compatibility
 */
def pomConsistency2021DraftSettings: Seq[Setting[_]] = Seq(
  pomConsistency2021Draft := Set("true", "1")(sys.env.get("POM_CONSISTENCY").getOrElse("false")),
  moduleName := {
    if (pomConsistency2021Draft.value)
      sbtPluginModuleName2021Draft(moduleName.value,
        (pluginCrossBuild / sbtBinaryVersion).value)
    else moduleName.value
  },
  projectID := {
    if (pomConsistency2021Draft.value) sbtPluginExtra2021Draft(projectID.value)
    else projectID.value
  },
)

def sbtPluginModuleName2021Draft(n: String, sbtV: String): String =
  s"""${n}_sbt${if (sbtV == "1.0") "1" else if (sbtV == "2.0") "2" else sbtV}"""

def sbtPluginExtra2021Draft(m: ModuleID): ModuleID =
  m.withExtraAttributes(Map.empty)
   .withCrossVersion(CrossVersion.binary)
```

Now run sbt with the environment variable `POM_CONSISTENCY=1` and publish to your Nexus or Artifactory or use `publishM2` to test locally:

```bash
$ POM_CONSISTENCY=1 sbt
> publish
```

This should produce a POM like this:

<xml>
<project xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns="http://maven.apache.org/POM/4.0.0">
    <modelVersion>4.0.0</modelVersion>
    <groupId>com.eed3si9n</groupId>
    <artifactId>sbt-assembly_sbt1_2.12</artifactId>
    <packaging>jar</packaging>
    <description>sbt plugin to create a single fat jar</description>
    <url>https://github.com/sbt/sbt-assembly</url>
    <version>0.15.0-Pets1</version>
    ....
</project>
</xml>

### using the re-published plugin

To use this, put the following in `project/plugins.sbt`:

```scala
// add resolver to your Nexus or Artifactory
// resolvers += Resolver.mavenLocal
addPomConsisntentSbtPlugin2021Draft("com.eed3si9n" % "sbt-assembly" % "0.15.0-Pets1")

def sbtPluginModuleName2021Draft(n: String, sbtV: String): String =
  s"""${n}_sbt${if (sbtV == "1.0") "1" else if (sbtV == "2.0") "2" else sbtV}"""

def sbtPluginExtra2021Draft(m: ModuleID): ModuleID =
  m.withExtraAttributes(Map.empty)
   .withCrossVersion(CrossVersion.binary)

def addPomConsisntentSbtPlugin2021Draft(m: ModuleID): Setting[Seq[ModuleID]] =
  libraryDependencies += {
    val sbtV = (pluginCrossBuild / sbtBinaryVersion).value
    sbtPluginExtra2021Draft(m)
      .withName(sbtPluginModuleName2021Draft(m.name, sbtV))
  }
```

This should resolve the plugin from your Maven repository.

### why was it like this?

Ivy has a concept of extra attributes, which provides extra axis that can be part of the resolution. When an sbt plugin is published to Ivy repository it uses the extra attributes to encode both the Scala version and sbt versions, so multiple sbt versions can exist under a Scala version. Mangling this information into URL is how extra attributes are encoded when a module is published to a Maven repository.

This is different from classifiers, since you can't append classifiers afterwards, but you can back publish an sbt plugin after a new version becomes available. Basically Ivy repo has richer information in this regard, so as long as we were running our own plugin repository, it made sense to keep using extra attributes.

Now that we will be publishing to Maven repos, it's time to adapt.

### disclaimer

As indicated by repetative `2021Draft`, this is just an idea at this point. I think we should adopt this for sbt 2.x and you could probably start using this internally, but this is subject to change based on more findings and feedbacks.

### license

To the extent possible under law, the author(s) have dedicated all copyright and related and neighboring rights to this template to the public domain worldwide. This code example is distributed without any warranty. See http://creativecommons.org/publicdomain/zero/1.0/.
