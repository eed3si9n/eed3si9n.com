---
title:       "sbt-assembly 1.0.0"
type:        story
date:        2021-06-07
draft:       false
promote:     true
sticky:      false
url:         /sbt-assembly-1.0.0
aliases:     [ /node/396 ]
tags:        [ "sbt" ]
---

  [432]: https://github.com/sbt/sbt-assembly/pull/432
  [422]: https://github.com/sbt/sbt-assembly/pull/422
  [427]: https://github.com/sbt/sbt-assembly/pull/427
  [430]: https://github.com/sbt/sbt-assembly/pull/430
  [@eed3si9n]: https://github.com/eed3si9n/
  [@xuwei-k]: https://github.com/xuwei-k
  [@nevillelyh]: https://github.com/nevillelyh
  [maven-assembly-plugin]: https://maven.apache.org/plugins/maven-assembly-plugin/

In June of 2011, I started working on sbt-assembly for sbt 0.10, based on Coda Hale's assembly-sbt from sbt 0.7, which in turn was probably inspired by [maven-assembly-plugin][maven-assembly-plugin]. After ten years, I'm going to call this one 1.0.0. sbt-assembly 1.0.0 is published to Maven Central.

<!--more-->

### what does it do?

The plugin creates an über-JAR that can be used for easier deployment. As opposed to the regular JAR file created with `packageBin` task, an über-JAR is one big JAR file with your code, Scala standard library, and all the extenal dependency files. It's a JAR file that can be executed as:

<code>
$ java -jar target/scala-2.13/hello-assembly-0.1.0-SNAPSHOT.jar
</code>

Over the years, it has also added various features related to über-JAR such as merge strategy and shading.

### setup

In `plugins.sbt` add:

```scala
addSbtPlugin("com.eed3si9n" % "sbt-assembly" % "1.0.0")
```

See below for POM consistency setup.

### usage

<code>
> assembly
</code>

### changes with compatibility implication

- `assembly` no longer runs `test` by default. Running `test` I think was a vestige from Maven phases, and it doesn't really make sense in sbt. [#432][432] by [@eed3si9n][@eed3si9n]
- Deprecated keys `jarName`, `mergeStrategy` etc are removed. Use `assemblyJarName`, `assemblyMergeStrategy` instead. [#432][432] by [@eed3si9n][@eed3si9n]

### ThisBuild / assemblyMergeStrategy

Following my own advice in [Plugin Best Practice](https://www.scala-sbt.org/1.x/docs/Plugins-Best-Practices.html#Provide+default+values+in), I tried to provide the default values for as many settings in `globalSettings`:

```
assemblyAppendContentHash     assemblyCacheOutput           assemblyCacheUnzip
assemblyExcludedJars          assemblyMergeStrategy         assemblyShadeRules
```

This mean that those keys can be used as:

```scala
ThisBuild / assemblyMergeStrategy := ...

// or
lazy val app = (project in file("app"))
  .settings(
    assemblyMergeStrategy := ...

    // more settings here ...
  )
```

`ThisBuild / assemblyMergeStrategy` is shared across all subprojects.

### negative time fix

I fixed the "Negative Time" warning in [#430][430]. This bug is a reminder that JAR file is basically a ZIP file, which is a hot mess. Internally it uses DOS timestamp, so it stores time at 2 second resolution, and epoch starts from January 1st of 1980.

To make the build reproducible, sbt 1.4.0 started wiping out the timestamps in the JAR files, but it used January 1st of 1970. Until this was fixed in sbt 1.4.8, we have JAR files out in the wild with timestamp set to an invalid timestamp that JDK 11 interprets to UNIX timestamp `-3600000`, or November 20, 1969 08:00+Z. Because some operating systems are unable to handle timestamps before 1970, JDK 11 then throws an exception "Negative Time." sbt-assembly 1.0.0 will reset these timestamps as January 1st, 2010 instead.

### other fixes

- Fixes "Ignored unknown package option FixedTimestamp" warning on sbt 1.5.x [#422][422] by [@xuwei-k][@xuwei-k]
- Fixes examples on the README to use slash syntax [#427][427] by [@nevillelyh][@nevillelyh]

### POM consistency setup

If you're behind a corporate firewall, and you want to access Maven Central via Artifactory but with POM consistency check enabled:

In `plugins.sbt` add:

```scala
addPomConsisntentSbtPlugin2021Draft("com.eed3si9n" % "sbt-assembly" % "1.0.0")

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

### participation

According to `git shortlog -sn --no-merges`, sbt-assembly was brought to you by 68 contributors. Thanks!

Thanks to everyone who's helped improve sbt-assembly using them, reporting bugs, improving our documentation, submitting pull requests and answering Stackoverflow questions.

<code>
   269  Eugene Yokota (eed3si9n)
    45  Kenji Yoshida (xuwei-k)
    15  Robert J. Macomber
    12  Jeroen ter Voorde
     9  Coda Hale
     5  Eric Christiansen
     5  LolHens
     5  Sean Sullivan
     5  Wu Xiang
     4  Thomas Lockney
     3  Ahmed Bhamjee
     3  Alex Wilson
     3  Roland
     3  Sam Halliday
     3  Shiva Wu
     2  Christopher Hodapp
     2  Derek Chen-Becker
     2  Eliran Bivas
     2  Grigory Pomadchin
     2  Mathias Bogaert
     2  Pierre Kisters
     2  yuval.itzchakov
     1  Adrian Bravo
     1  Ben Fradet
     1  Björn Antonsson
     1  Damian
     1  David Ignjic
     1  dfranetovich
     1  Eric Poitras
     1  Forest Fang
     1  Frank S. Thomas
     1  Ian Hummel
     1  ipostanogov
     1  Jaesang Kim
     1  Jeff Hodges
     1  Jeffrey Olchovy
     1  Johannes Rudolph
     1  Jorge Ortiz
     1  Joseph Naegele
     1  Josh Devins
     1  Joshua Gao
     1  kellydavid
     1  Kewei Shang
     1  Kirill A. Korinskiy
     1  Krzysztof Ciesielski
     1  Lucas Torri
     1  Luke Kysow
     1  Mal Graty
     1  Mark Harrah
     1  Martin Mauch
     1  nafg
     1  Nathan Hamblen
     1  Neville Li
     1  Onilton Maciel
     1  Peter Romov
     1  Peter Vlugter
     1  Philip Wills
     1  romusz
     1  Ryan Gross
     1  sam
     1  Samuel Tardieu
     1  Santeri Paavolainen
     1  Seth Tisue
     1  Stephane Landelle
     1  TANIGUCHI Masaya
     1  Will Sargent
     1  Ólafur Páll Geirsson
     1  菅原 浩
</code>

Before DMing or emailing me your sbt-assembly questions, please read the [issue reporting guideline](https://github.com/sbt/sbt-assembly/blob/develop/CONTRIBUTING.md).

For anyone interested in helping sbt-assembly, feel free to pick up GitHub issues or questions on [StackOverflow](https://stackoverflow.com/questions/tagged/sbt-assembly?tab=Unanswered).

### related plugins

For deployment purposes, there are other plugins that you might want to consider.

- [sbt-native-packager](https://github.com/sbt/sbt-native-packager) creates zip files, Docker images and more without unzipping/re-zipping the JAR files. For many deployment scenarios, this would be the go to.
- [sbt-onejar](https://github.com/sbt/sbt-onejar) also creates an über-JAR, but it embeds JAR files directly inside the JAR file.
- [sbt-proguard](https://github.com/sbt/sbt-proguard) also creates an über-JAR, and it's able to shrink the size by removing unused classes.
- [sbt-native-image](https://github.com/scalameta/sbt-native-image) creates a GraalVM native image, as in native executable. For command line apps, this is my current favorite.

I'm not quite sure why sbt-assembly remains to be a relatively popular option. Maybe companies are used to maven-assembly-plugin, so it's convenient for projects like Spark to say either you're using sbt or Maven, use assembly for deployment.
