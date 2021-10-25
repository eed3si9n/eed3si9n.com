---
title:       "remote caching sbt builds with Bintray"
type:        story
date:        2020-10-25
changed:     2020-11-02
draft:       false
promote:     true
sticky:      false
url:         /remote-caching-sbt-builds-with-bintray
aliases:     [ /node/364 ]
tags:        [ "sbt" ]
---

The feature in sbt and Zinc 1.4.x that I spent most amount of time and energy probably is the virtualization of file, and lifting out timestamps. Combined together, we can liberate the Zinc state from machine-specificity and time, and become the foundation we lay towards building incremental remote caching for Scala. I blogged about this in [cached compilation for sbt](https://eed3si9n.com/cached-compilation-for-sbt). This is part 2.

Now that sbt 1.4.x is out, there is a growing interest in this feature among people who want to try this out.

### remote cache server

To operate remote cache, we need remote cache server. For the initial rollout, I wanted to make it easier to try this without an additional server, so I made it compatible with Maven repository instead, including `MavenCache("local-cache", file("/tmp/remote-cache"))`. Next step up would be to try sharing the remote cache across the machine.

[JFrog Bintray](https://bintray.com/) might be a good fit for the time being since it can act as a Maven repository. Publishing to Bintray requires a RESTful API, which sbt-bintray encapsulates.

I should note that Bazel provides support for remote caching using [HTTP protocol and gRPC][1], which then could be backed by Nginx, bazel-remote, Google Cloud Storage, or anything that speaks HTTP. That is probably the way to go eventually since we don't really need to resolve them like library dependencies.

### sbt-bintray-remote-cache

For people who want to use remote caching now, I've created sbt-bintray-remote-cache, a spin-off of sbt-bintray.

To try put the following in `project/plugins.sbt`:

```scala
addSbtPlugin("org.foundweekends" % "sbt-bintray-remote-cache" % "0.6.1")
```

#### Bintray repo and package

Next go to `https://bintray.com/<your_bintray_user>/` and create a new **Generic** repository with the name **`remote-cache`**. This step is important because you don't want to mix and match remote cache with real artifacts!

Then create a _package_ within the remote-cache repo. The granularity should typically be one package for one build.

#### credentials

To push remote cache, you need to provide Bintray credentials (user name and API key) using a credential file or environment variables. Locally it would use the same credential file as sbt-bintray (`$HOME/.bintray/.credentials`). On the CI machine it would use _different_ environment variables:

- `BINTRAY_REMOTE_CACHE_USER` 
- `BINTRAY_REMOTE_CACHE_PASS`

This is so you can use different authentication in case you're using both sbt-bintray and sbt-bintray-remote-cache.

#### build.sbt

Then in your `build.sbt`:

```scala
ThisBuild / bintrayRemoteCacheOrganization := "your_bintray_user or organization"
ThisBuild / bintrayRemoteCachePackage := "your_package_name"
```

This will automatically configure `ThisBuild / pushRemoteCacheTo` setting.

#### pushing and pulling remote cache

From the sbt shell type in `akka-actor/pushRemoteCache`:

<code>
akka > akka-actor/pushRemoteCache
[info] Wrote /Users/eed3si9n/work/quicktest/akka-0/akka-actor/target/scala-2.12/akka-actor_2.12-2.6.5+28-d4f0358c+20201025-1417.pom
[info] compiling 1 Scala source to /Users/eed3si9n/work/quicktest/akka-0/akka-actor/target/scala-2.12/classes ...
[info] Validating all packages are set private or exported for OSGi explicitly...
[warn] bnd: Unused Private-Package instructions, no such package(s) on the class path: [akka.osgi.impl]
[info]  published akka-actor_2.12 to https://api.bintray.com/maven/eed3si9n/remote-cache/akka/com/typesafe/akka/akka-actor_2.12/0.0.0-d4f0358cbd/akka-actor_2.12-0.0.0-d4f0358cbd.pom
[info]  published akka-actor_2.12 to https://api.bintray.com/maven/eed3si9n/remote-cache/akka/com/typesafe/akka/akka-actor_2.12/0.0.0-d4f0358cbd/akka-actor_2.12-0.0.0-d4f0358cbd-cached-compile.jar
[info]  published akka-actor_2.12 to https://api.bintray.com/maven/eed3si9n/remote-cache/akka/com/typesafe/akka/akka-actor_2.12/0.0.0-d4f0358cbd/akka-actor_2.12-0.0.0-d4f0358cbd-cached-test.jar
[success] Total time: 30 s, completed Oct 25, 2020 2:18:46 PM
</code>

To try this remote cache, type in `clean`, `akka-actor/pullRemoteCache`, and `akka-actor/compile`:

<code>
akka > clean
[success] Total time: 5 s, completed Oct 25, 2020 2:19:10 PM
akka > akka-actor/pullRemoteCache
[info] Updating
https://api.bintray.com/maven/eed3si9n/remote-cache/akka/com/typesafe/akka/akka-actor_2.12/0.0.0-d4f0358cbd/akka-actor_2.12-0.0.0-d4f0358cbd.pom
  100.0% [##########] 1.5 KiB (1.4 KiB / s)
[info] Resolved  dependencies
[info] Fetching artifacts of
https://api.bintray.com/maven/eed3si9n/remote-cache/akka/com/typesafe/akka/akka-actor_2.12/0.0.0-d4f0358cbd/akka-actor_2.12-0.0.0-d4f0358cbd-cached-test.jar
  100.0% [##########] 388 B (473 B / s)
https://api.bintray.com/maven/eed3si9n/remote-cache/akka/com/typesafe/akka/akka-actor_2.12/0.0.0-d4f0358cbd/akka-actor_2.12-0.0.0-d4f0358cbd-cached-compile.jar
  100.0% [##########] 4.1 MiB (2.2 MiB / s)
[info] Fetched artifacts of
[info] remote cache artifact extracted for Some(cached-compile)
[info] remote cache artifact extracted for Some(cached-test)
[success] Total time: 4 s, completed Oct 25, 2020 2:19:20 PM
akka > akka-actor/compile
[info] Formatting 22 Java sources...
[info] Reformatted 0 Java sources
[info] Generating 'Tuples.scala'
[info] Generating 'Functions.scala'
[success] Total time: 2 s, completed Oct 25, 2020 2:19:35 PM
</code>

The compilation is done in 2s. akka-actor usually takes 35~40s.

#### cleaning up the old cache

One concern some of you might have is the accumulation of endless binary cache file. I've created a task that would keep minimum 100 entries but delete entries older than a month.

<code>
akka > bintrayRemoteCacheCleanOld
[info] fetching package versions for package akka
[info] - 0.0.0-d4f0358cbd
[info] - 0.0.0-394b4fba9c
[info] about to delete Vector(0.0.0-d4f0358cbd, 0.0.0-394b4fba9c)
[info] eed3si9n/akka@0.0.0-d4f0358cbd was discarded
[info] eed3si9n/akka@0.0.0-394b4fba9c was discarded
</code>

### some more thoughts

sbt 1.4.1 uses Git commit id as the remote cache id, but I don't think it's efficient since that would invalidate all the cache for each commit. A better solution probably is to use content hash of all inputs [sbt/sbt#5842](https://github.com/sbt/sbt/issues/5842). [sbt/sbt#6026](https://github.com/sbt/sbt/pull/6026) is my PR that implements content-based remoteCacheId.

To get better caching, we will likely have to cache more things like formatting states and generated code. We might also need to evaluate the repeatability of the generated code.

- Yoshida-san is making [xuwei-k/sbt-remote-cache-playframework](https://github.com/xuwei-k/sbt-remote-cache-playframework) to make Play's generated code more repeatable.
- Arnout Engelen sent [playframework/twirl#378](https://github.com/playframework/twirl/pull/378) to make paths in Twirl-generated code relative.

  [1]: https://docs.bazel.build/versions/2.0.0/remote-caching.html
