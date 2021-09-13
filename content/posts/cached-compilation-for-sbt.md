---
title:       "cached compilation for sbt"
type:        story
date:        2020-05-06
changed:     2020-05-07
draft:       false
promote:     true
sticky:      false
url:         /cached-compilation-for-sbt
aliases:     [ /node/331 ]
tags:        [ "sbt" ]
summary:
  The notion of cached compilation or remote cache has been around for a while now, but often it required the setup has not been easy. If we can bake build-as-function feature into basic tool chain such as Zinc and sbt, Scala community in general can benefit from it to speed up the build.

  Even for open source projects, if Travis CI publishes into Bintray or something, the contributors might be able to resume compilation off of the last build.

  The PR for sbt change is [sbt/sbt#5534](https://github.com/sbt/sbt/pull/5534), and the virtualization change in Zinc is [sbt/zinc#712](https://github.com/sbt/zinc/pull/712).
---

Ever since I learned about Google's build infrastructure Blaze, which is today open sourced as Bazel, I've thought of having a similar facility for Scala's tool chain. This is not particularly original since there's been prior works such as Peter Vlugter and Ben Dougherty's work on [nailgun Zinc](https://github.com/typesafehub/zinc/commits/master/src/main/scala/com/typesafe/zinc/SbtAnalysis.scala), which was used in Pants, and Krzysztof Romanowski's [Hoarder](https://github.com/romanowski/hoarder). These rely on the idea of transforming the absolute paths appearing in Zinc Analysis file for each working directory.

Before I go into the details of what I've been working on, let's demonstrate the problem space.

### machine-dependence of the build

Here's how Akka's `akka-actor/compile` looks like on sbt 1.3.10:

<code>
cd ~/work/quicktest/
git clone git@github.com:akka/akka.git akka-0
cd akka-0
sbt
akka > akka-actor/compile
[info] Generating 'Tuples.scala'
[info] Generating 'Functions.scala'
[info] Updating
[info] Resolved  dependencies
[info] Updating
[info] Formatting 22 Java sources...
[info] Reformatted 0 Java sources
[info] Compiling 191 Scala sources and 28 Java sources to /Users/eed3si9n/work/quicktest/akka-0/akka-actor/target/scala-2.12/classes ...
....
[success] Total time: 39 s, completed May 6, 2020 1:53:36 PM
</code>

To emulate someone else doing the same work, let's copy this directory to another location:

<code>
cd ~/work/quicktest/
cp -r akka-0 akka-1
cd akka-1
sbt
akka > akka-actor/compile
[info] Generating 'Tuples.scala'
[info] Generating 'Functions.scala'
[info] Formatting 22 Java sources...
[info] Reformatted 0 Java sources
[info] Compiling 191 Scala sources and 28 Java sources to /Users/eed3si9n/work/quicktest/akka-1/akka-actor/target/scala-2.12/classes ...
....
[success] Total time: 48 s, completed May 6, 2020 1:57:33 PM
</code>

The same work is repeated twice. If you're working with a team of developers, this process would be repeated every morning. If your team grows, so does the speed of code growth, and the amount of duplicated work. The idea of the cached compilation is to avoid compilation if it's already been done.

### build as function

In ScalaSphere 2019's 'Analysis of Zinc' talk, I proposed two subgoals towards build as function in Zinc:

- liberation from a machine
- liberation from time

Both Scala compiler and Java compiler is able handle an abtraction notion of virtual file. Rather than manipulating the state of Zinc, I think it's better if we can do away with the idea of using working-directory specific absolute paths during compilation. For large-scale build tools, this facility can be used for example to keep all sources in-memory. Furthermore, keeping a bunch of `java.io.File` with full absolute paths could add up.

Internally all relevant file paths such as sources, libraries, and output `*.class` files are converted to a `VirtualFileRef`. The default implementation will convert `/Users/xxx/work/quicktest/cats-0/kernel/src/main/scala/cats/kernel/Band.scala` to `${BASE}/kernel/src/main/scala/cats/kernel/Band.scala`. (It's currently `${0}`, but we'll likely change it to `${BASE}`.)

The second part of the proposal is to remove timestamp as the invalidation key. Timestamp is fairly efficient, so we will continue to use it, but it should be double checked using content hash. Hashing technology has improved over the years. Cryptographic hashing such as SHA-1 could take a few seconds to hash 1000 JAR files, but an efficient non-cyptographic hashing can do so in a fraction of a second. I chose Zero-Allocation-Hashing's implementation of FarmHash.

### integration with sbt

Here's the workflow using my locally built sbt 1.4.0-SNAPSHOT. First we need to add the following line to `build.sbt`:

<scala>
ThisBuild / pushRemoteCacheTo := Some(MavenCache("local-cache", file("/tmp/remote-cache")))
</scala>

This could be any Maven-style repository. You'd likely not want to mix this with the repository you use for the actual artifacts.

Next, from sbt shell type in  `akka-actor/pushRemoteCache`:

<code>
akka > akka-actor/pushRemoteCache
[info] Formatting 22 Java sources...
[info] Reformatted 0 Java sources
[info] Generating 'Tuples.scala'
[info] Generating 'Functions.scala'
[info] Wrote /Users/eed3si9n/work/quicktest/akka-0/akka-actor/target/scala-2.12/akka-actor_2.12-2.6.5+25-683868f9+20200506-1411.pom
[info] Compiling 191 Scala sources and 28 Java sources to /Users/eed3si9n/work/quicktest/akka-0/akka-actor/target/scala-2.12/classes ...
....
[info]  published akka-actor_2.12 to file:/tmp/remote-cache/com/typesafe/akka/akka-actor_2.12/0.0.0-683868f9fe/akka-actor_2.12-0.0.0-683868f9fe.pom
[info]  published akka-actor_2.12 to file:/tmp/remote-cache/com/typesafe/akka/akka-actor_2.12/0.0.0-683868f9fe/akka-actor_2.12-0.0.0-683868f9fe-cached-compile.jar
[info]  published akka-actor_2.12 to file:/tmp/remote-cache/com/typesafe/akka/akka-actor_2.12/0.0.0-683868f9fe/akka-actor_2.12-0.0.0-683868f9fe-cached-test.jar
[success] Total time: 45 s, completed May 6, 2020 2:12:11 PM
</code>

"683868f9fe" in the above is `remoteCacheId`. For now I'm using Git commit id for this, but you can change to what makes sense in your build. Maybe this will change to hash of all sources.

In a different working directory, type in `clean` and `akka-actor/pullRemoteCache`:

<code>
cd ~/work/quicktest/
cp -r akka-0 akka-1
cd akka-1
sbt
akka > clean
[success] Total time: 1 s, completed May 6, 2020 2:17:40 PM
akka > akka-actor/pullRemoteCache
[success] Total time: 1 s, completed May 6, 2020 2:17:46 PM
</code>

Next type in `akka-actor/compile`:

<code>
akka > akka-actor/compile
[info] Formatting 22 Java sources...
[info] Reformatted 0 Java sources
[info] Generating 'Tuples.scala'
[info] Generating 'Functions.scala'
[info] Compiling 1 Scala source to /Users/eed3si9n/work/quicktest/akka-1/akka-actor/target/scala-2.12/classes ...
[success] Total time: 4 s, completed May 6, 2020 2:21:13 PM
</code>

Looks like Java formatting and code generation might be triggering some compilation. This actually shows how flexible this setup is. Since the incremental compiler is used to dealing with partially matching code bases, it will just work on the differences from the remote cache.

In other words, we were able to _resume_ incremental compilation from a remote cache. The same concept could be applied across the commit history for example. For example, if the remote cache is not available for the current commit id, likely we could go back a few commits before in the history and resume compilation off of an old cache. For this simple test, 45s vs (1 + 4)s is still 9x speedup.

### what's in a remote cache?

Currently, remote cache JAR contains the classes directory and zipped up Zinc Analysis file. Since all build tools should be able publish to a Maven repository, and resolve out of Maven repository, this idea should be able carry over to any build tools that use Zinc.

This idea could expand out to things like test results. sbt currently stores the list of succeeded tests and their timestamps. Using that `testQuick` run incremental tests. If we used the content hash, or something that does not depend on the timestamp, we might be able to run only the tests that's been affected by the last CI run.

### cached compilation for all

The notion of cached compilation or remote cache has been around for a while now, but often setting it up has not been easy. If we can bake build-as-function feature into basic tool chain such as Zinc and sbt, Scala community in general can benefit from it to speed up the build.

Even for open source projects, if Travis CI publishes into Bintray or something, the contributors might be able to resume compilation off of the last build.

The PR for sbt change is [sbt/sbt#5534](https://github.com/sbt/sbt/pull/5534), and the virtualization change in Zinc is [sbt/zinc#712](https://github.com/sbt/zinc/pull/712).
