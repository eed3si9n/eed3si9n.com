---
title: "reducing scaladoc file size with sbt-salad-days"
type: story
date: 2026-06-20
url: /reducing-scaladoc-file-size-with-sbt-salad-days
tags: [ "sbt" ]
---

A few days ago, Maven Central Repository has introduced [Maven Central Publishing Limits](https://central.sonatype.org/publish/maven-central-publishing-limits/). See Brian Fox's [Open Publishing, Commercial Scale](https://www.sonatype.com/blog/open-publishing-commercial-scale) for the background:

> A maintainer publishing normal releases for an open source project is one thing. A large commercial entity using Maven Central as the last-mile distribution channel for SDKs, agents, generated clients, integrations, or other commercial software components is another.

He recommends that higher-volume commercial organizations move to Maven Central Publisher Pro. Letigimate open source projects must either reduce the release size or request an exemption for review. As of this writing, the monthly soft limit for the file size is 80 MB.

This event has triggered many of the Scala library maintainers to realize that on Scala 3, Scaladoc file is often the largest file per module. Looking at the `unzip -l` shows that the Scaladoc JAR includes fonts and `scripts/inkuire.js` ([VirtusLab/Inkuire](https://github.com/VirtusLab/Inkuire) seems to be a search library), totalling over 2.5 MB:

```
   203030  01-01-2010 00:00   webfonts/fa-solid-900.eot
   309828  01-01-2010 00:00   fonts/Inter-Regular.ttf
   314712  01-01-2010 00:00   fonts/Inter-Medium.ttf
   315756  01-01-2010 00:00   fonts/Inter-SemiBold.ttf
   316100  01-01-2010 00:00   fonts/Inter-Bold.ttf
   370523  01-01-2010 00:00   scripts/scaladoc-scalajs.js
   747545  01-01-2010 00:00   webfonts/fa-brands-400.svg
   918991  01-01-2010 00:00   webfonts/fa-solid-900.svg
   939517  01-01-2010 00:00   scripts/inkuire.js
```

As a quick workaround, I've created an sbt plugin that removes all fonts and `scripts/inkuire.js` for both sbt 1.x and 2.x:

```scala
addSbtPlugin("com.eed3si9n" % "sbt-salad-days" % "0.1.0")
```

This reduces the near-empty Scaladoc to 420 KB.

```bash
$ ls -lh /private/tmp/aaa/target/scala-3.3.8/aaa_3-0.1.0-SNAPSHOT-javadoc.jar
420K /private/tmp/aaa/target/scala-3.3.8/aaa_3-0.1.0-SNAPSHOT-javadoc.jar
```

The Scaladoc for <https://repo1.maven.org/maven2/com/eed3si9n/sbt-salad-days_sbt2_3/0.1.0/> is also 420 KB.


### Reference

- [Open Publishing, Commercial Scale](https://www.sonatype.com/blog/open-publishing-commercial-scale), Brian Fox
- [Maven Central Publishing Limits](https://central.sonatype.org/publish/maven-central-publishing-limits/)
- [sbt-salad-days](https://github.com/sbt/sbt-salad-days)
- See [scala3#26387](https://github.com/scala/scala3/issues/26387) 'Scaladoc impact on deployments size' to discuss actual fixes.
