---
title:       "tag-based back publishing with sbt"
type:        story
date:        2024-10-21
url:         /tag-based-back-publishing-with-sbt
tags:        [ "sbt" ]
---

sbt-ci-release 1.9.2 is released, implementing tag-based back publishing support.

<!--more-->

## background

In the earlier years of Scala, every patch version broke binary compatibility, and all libraries must be built for a specific patch version of Scala. One of the immune system the Scala community developed against this challenge was to _cross build_ the same set of source code against mutiple versions of Scala by appending `_2.10` suffix. If a new version of Scala arrived that required no changes to the code, we could _back publish_ to an existing version number. The velocity of Scala evolution has stabilized since then, but the cross building has come in handy for various other axes like Scala JVM + JS + Native, testing against binary-incompatible milestone versions of Scala, sbt, etc.

In June 2018, Ólafur Geirsson revolutionlized library publishing in Scala by creating sbt-ci-release [1.0.0](https://github.com/sbt/sbt-ci-release/tree/v1.0.0), which fully automated the publishing process from tags. What was amazing was how it reused GPG signing from sbt-pgp, tag versioning from sbt-dynver, and Sonatype releasing from sbt-sonatype. In other words, the ingredient for the full automation was _almost_ there. What Olaf standardized with extensive REAME was how information can be passed via environment variables.

Today, I released sbt-ci-release 1.9.x, implementing tag-based back publishing support.

## back publishing

sbt-ci-release 1.9.2 implements a mini DSL for the Git tag:

```
version[@command|@a.b.c|@a.b."x"][#comment]
```

This allows library and plugin authors to back publish a code base. A back-publish tag is split via `@` character, and uses `#` to denote comments. Let's look into some uses cases of how back publishing can be implemented.

#### "GitOps" back publishing

`v1.2.3#unique_comment`, for example `v1.2.3#native0.5_3`.

If you prefer to keep most of the information in a git branch, you can just use the comment functionality.

1. Branch off of `v1.2.3` to create `release/1.2.3` branch, and send a PR to:
   a. Update appropriate dependency (sbt, Scala Native etc)
   b. Modify the `CI_RELEASE` environment variable to encode the actions you want to take, like `;++3.x;foo_native/publishSigned`. For GitHub Actions, it would be in `.github/workflows/release.yml`
2. Tag the branch to `v1.2.3#unique_comment`. For record keeping, encode the version you're trying to back publishing for e.g. `v1.2.3#native0.5_3`

Previously the version would've been `v1.2.3#native0.5_3`, but with sbt-ci-release 1.9.x, the version would be `v1.2.3`.

#### Publishing against a specific Scala version

`v1.2.3@2.13.15`, `v1.2.3@3.x`, or `v1.2.3@3.x#unique_comment`.

There are a few situations where one might back publish a library for a specific Scala version:

1. Compiler plugin is published against full Scala version, like 2.13.14, 2.13.15, etc.
2. For Scala compiler milestones, you want to republish your library

For compiler plugins, `v1.2.3@2.13.15` will expand to `;++2.13.15!;publishSigned` and release all subprojects under the current branch with Scala 2.13.15.

#### Publishing against a specific sbt version

`v1.2.3@3.x#unique_comment`

We can use this to back publish sbt 2.x plugins.

1. Branch off of `v1.2.3` to create `release/1.2.3` branch, and send a PR to update `pluginCrossBuild / sbtVersion`:
   ```scala
   (pluginCrossBuild / sbtVersion) := {
     ScalaBinaryVersion.value match {
       case "2.12" => "1.5.8"
       case _      => "2.0.0-M3"
     }
   }
   ```
2. Tag the brach to `v1.2.3@3.x#sbt2.0.0-M3`

#### Publishing against a new Scala JS backend, Scala Native, etc

`v1.2.3@+foo_native/publishSigned#unique_comment`

1. Branch off of `v1.2.3` to create `release/1.2.3` branch, and send a PR to update the appropriate Scala Native version etc.
2. Tag the branch to `v1.2.3@+foo_native/publishSigned#native0.5`

This will run the `+foo_native/publishSigned` command as the `CI_RELEASE` command.

## summary

sbt-ci-release 1.9.2 implements a mini DSL for the Git tag to support back publishing.
Library authors can use this to either implement GitOps-style back publishing, or tag-based back publishing where the Scala version and the commands are embedded in the Git tag.
