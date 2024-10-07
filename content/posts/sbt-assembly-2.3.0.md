---
title:       "sbt-assembly 2.3.0, Contraband 0.6.0, and sbt-pgp 2.3.0"
type:        story
date:        2024-10-06
url:         /sbt-assembly-2.3.0
tags:        [ "sbt" ]
---

sbt-assembly 2.3.0, Contraband 0.6.0, and sbt-pgp 2.3.0 are released. Those plugins are cross published to Maven Central for sbt 1.x and sbt 2.0.0-M2, which came out two days ago. Many thanks to Kenji Yoshida ([@xuwei-k][@xuwei-k]) for many pull requests he's been sending.

<!--more-->

### sbt-pgp 2.3.0

sbt-pgp provides PGP signing for sbt. Since publishing to Sonatype OSS requires PGP signing this is an essential plugin for library authors.

Here are sbt 2.x migration PRs:

* Prepare for Scala 3, sbt 2 build by [@xuwei-k][@xuwei-k] in [#205](https://github.com/sbt/sbt-pgp/pull/205)
* Adds Scala 3 build setting for gpg-library by [@xuwei-k][@xuwei-k] in [#208](https://github.com/sbt/sbt-pgp/pull/208)
* Uses slash syntax in test. Prepare for sbt 2 by [@xuwei-k][@xuwei-k] in [#213](https://github.com/sbt/sbt-pgp/pull/213)
* Cross build to sbt 2.x by [@eed3si9n][@eed3si9n] in [#214](https://github.com/sbt/sbt-pgp/pull/214)

Full release note is at <https://github.com/sbt/sbt-pgp/releases/tag/v2.3.0>.

### sbt-assembly 2.3.0

sbt-assembly creates über JAR, and provides shading.

Here are sbt 2.x migration PRs:

* refactor: Uses new slash syntax by [@xuwei-k][@xuwei-k] in [#531](https://github.com/sbt/sbt-assembly/pull/531)
* Cross build to sbt 2.x by [@eed3si9n][@eed3si9n] in [#533](https://github.com/sbt/sbt-assembly/pull/533)
* refactor: Update the types by [@eed3si9n][@eed3si9n] in [#535](https://github.com/sbt/sbt-assembly/pull/535)

Full release note is at <https://github.com/sbt/sbt-assembly/releases/tag/v2.3.0>

This required a lot of shim to get to work, and it still needs more work to get to feature parity. I'll be updating the [migration guide][migration]. For example, some of the tasks that used to return `java.io.File` return `xsbi.HashedVirtualFileRef`. The general _idea_ of the file is represented by `xsbi.HashedVirtualFileRef` and `xsbi.VirtualFile` (I've written about this extensitvely in [sbt 2.x remote cache](/sbt-remote-cache)). To use the same `*.scala` source but target both sbt 1.x and 2.x, we can create a shim, like `PluginCompat.scala`.

```scala
// src/main/scala-3/PluginCompat.scala

package sbtfoo

import java.nio.file.{ Path => NioPath }
import sbt.*
import xsbti.{ FileConverter, HashedVirtualFileRef, VirtualFile }

object PluginCompat:
  type FileRef = HashedVirtualFileRef
  type Out = VirtualFile

  def toNioPath(a: Attributed[HashedVirtualFileRef])(using conv: FileConverter): NioPath =
    conv.toPath(a.data)
end PluginCompat
```

and here's sbt 1.x:

```scala
// src/main/scala-2.12/PluginCompat.scala

package sbtfoo

private[sbtfoo] object PluginCompat {
  type FileRef = java.io.File
  type Out = java.io.File

  def toNioPath(a: Attributed[File])(implicit conv: FileConverter): NioPath =
    a.data.toPath()
}
```

Now, we can use `PluginCompat.FileRef` and it would internally point to different types for sbt 1.x and 2.x.

### Contraband 0.6.0

[Contraband](https://www.scala-sbt.org/contraband/) is a GraphQL Schema dialect that I created to define data types. A unique feature is that it can evolve the API and produce binary-compatible Scala data binding. It can also generate sjson-new codec, which is used by sbt.

Here are sbt 2.x migration PRs:

* refactor: Add Scala 3 build by [@xuwei-k][@xuwei-k] in [#171](https://github.com/sbt/contraband/pull/171)
* refactor: Prepare for Scala 3 by [@xuwei-k][@xuwei-k] in [#164](https://github.com/sbt/contraband/pull/164)
* refactor: Replaces deprecated unicode arrow by [@xuwei-k][@xuwei-k] in [#166](https://github.com/sbt/contraband/pull/166)
* refactor: Uses `foldLeft` instead of deprecated `/:` by [@xuwei-k][@xuwei-k] in [#176](https://github.com/sbt/contraband/pull/176)
* refactor: Removes deprecated `[this]` qualifier by [@xuwei-k][@xuwei-k] in [#180](https://github.com/sbt/contraband/pull/180)
* refactor: Adds `-Xsource:3` option. Avoid deprecated `with` by [@xuwei-k][@xuwei-k] in [#181](https://github.com/sbt/contraband/pull/181)
* ci: Enable sbt 2.x build by [@xuwei-k][@xuwei-k] in [#182](https://github.com/sbt/contraband/pull/182)
* ci: Update `contrabandSjsonNewVersion`. Enable sbt 2 scripted test by [@xuwei-k][@xuwei-k] in [#184](https://github.com/sbt/contraband/pull/184)

Full release note is at <https://github.com/sbt/contraband/releases/tag/v0.6.0>

### some notes

sbt ecosystem has a lot of plugins. [Help us cross build](https://github.com/sbt/sbt/wiki/sbt-2.x-plugin-migration) them to both sbt 1.x and 2.x.

⚠️ **Disclaimer**: While sbt 2.x is in its beta (`2.0.0-Mx`), which we hope to release at some regular cadence, we do not keep the compatibility. In other words, until the final 2.0.0 comes out, we'd be regularly burning down the 2.x plugin ecosystem. As you can tell from the PRs, many of the migration are Scala 3.x migration and slash syntax, so M2 effort won't be wasted. You can participate as a weekend hike or a multi-month thru-hike.

  [@eed3si9n]: https://github.com/eed3si9n
  [@xuwei-k]: https://github.com/xuwei-k
  [migration]: https://www.scala-sbt.org/2.x/docs/en/changes/migrating-from-sbt-1.x.html
