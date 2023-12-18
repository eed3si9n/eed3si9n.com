---
title:       "december adventure 2023"
type:        story
date:        2023-12-14
url:         /december-adventure-2023
---

Inspired by [d6](http://plastic-idolatry.com/erik/2023/dec/) and [the original](https://eli.li/december-adventure), I'm going to try to work on something small everyday. I'll post on [Mastodon as well](https://elk.zone/mastodon.social/@eed3si9n/111511724828068883).

my goal: work on sbt 2.x, other open source like sbt 1.x and plugins, or some post on this site, like music or recipe.

<!--more-->
<a id="#17"></a>
#### 2023-12-17
fixed all the scripted tests on [#7464][7464], and wrapped up the blog post - [sbt 2.x remote cache](/sbt-remote-cache).

<a id="#16"></a>
#### 2023-12-16
went out to a nice Sichuan restaurant called [Peppercorn Station 青花椒](https://www.peppercornstation.com/) in Jersey City to celebrate my first boss's retirement. enjoyed catching up with him after a long time, as well as the elevated Sichuan cuisine. went staking in my local park afterwards for a while.

continuing on the scripted test, looked into `source-dependencies/binary`, which looks like this:

```scala
lazy val dep = project

lazy val use = project
  .settings(
    (Compile / unmanagedJars) += ((dep / Compile / packageBin) map Attributed.blank).value
  )
```

it dawned on me looking at this seemingly innocuous build that if I'm changing `packageBin` to `HashedVirtualFileRef`, I'd have to change `unmanagedJars`, and other tasks related to JARs also to `HashedVirtualFileRef`. eventually I changed the definition of `Def.Classpath` to:

```scala
type Classpath = Seq[Attributed[HashedVirtualFileRef]]
```

this is a pretty big change, since various code in sbt relates to classpath.

<a id="#15"></a>
#### 2023-12-15
continuing from yesterday, addressed scripted test failures under `dependency-management/*`. one of bugs I caught along the way was that compiler options weren't part of the cache key, and test legitimately failed when it succeeded to compile with bogus `javacOptions`.

<a id="#14"></a>
#### 2023-12-14
back to hacking on sbt 2.x remote cache. I tried to change `target` back to per subproject, but quickly realized that for virtual files having a unified `${OUT}` location is more convenient. in other words, instead of dealing with `foo/target/` and `bar/target/` separately we want one `target/out/` directory that I can map as `${OUT}`.

so I just need to tackle the scripted tests head on. I looked at a handful today under `actions/*` and `package/*`, and they weren't too bad. to navigate around deeply nested scripted tests quickly, I did bust out Sublime Text. opened a draft PR [#7464][7464].

<a id="#13"></a>
#### 2023-12-13
released [sbt 1.9.8](/sbt-1.9.8), featuring a fix of `IO.getModifiedOrZero` to use `clib.stat()` so it would work on Alpine 3.19, contributed by Simon F.

<a id="#12"></a>
#### 2023-12-12
I haven't gotten enough sleep, so went to bed before midnight last night. woke up a few times in the middle and commented on a few GitHub issues, but slept till the morning.

one of the issues I've been commenting says that sbt doesn't work on Alpine 3.19. back in 2017, sbt impled its own `getLastModifiedTime` using `libc.__xstat` because JDK 8 had an accuracy bug. this apprently broke on recent Alpine. I encouraged the reporter to send a PR for the fix, and he did. also it turned out that timestamp has been fixed in JDK 8
[#7455](https://github.com/sbt/sbt/issues/7455).

<a id="#11"></a>
#### 2023-12-11
looking into failing scripted tests. a large number of tests are failing, but this was expected because many of the tests use existence of directory as a proxy to check if something compiled or not. as part of caching, I've changed the `target` setting to point to `target/out/jvm/scala-<scalaVersion>/<moduleName>` of the working directory, as opposed to creating `target/` directory per subproject.

I might defer the change till later to reduce the breaking tests. in general, if `compile` become cached, some characteristics of the tests might change, like returning a cached answer, as opposed to excercising Zinc, so I might need to disable caching.

<a id="#10"></a>
#### 2023-12-10
worked on `compile` task caching. the mysterious bug from yesterday turned out to be something silly. I have a subproject called `utilCacheResolver`, and at some point during git history changes it dropped out of the aggregation, and it wasn't included in `publishLocal`, so basically my code changes weren't reflected in the tests.

there were other small issues here and there, but eventually I got the `compile` task to cache using the new mechanism. I'll probably add more details on the blog post, but the code looks like [2023d3e8](https://github.com/eed3si9n/sbt/commit/2023d3e82b3885527533b240486f69e76e7c64b7). further tweaking is required, but I'm happy to get to this milestone.

<a id="#9"></a>
#### 2023-12-09
working on caching of `compile` task. for some reason the output file is created under `out/${OUT}/jvm/...` even though I am looking for `${OUT}` in `syncBlobs(...)` method. I must be missing something simple, and I can't move forward until I figure this out.

<a id="#7"></a>
#### 2023-12-07

a bit cheating because it's work related, but it gives me an excuse to talk about monorepo layouts, which there are a few styles.

- Birdcage: this is probably a more common kind of monorepo where you have a bunch of top-level projects side-by-side, each with `src/main/scala/com/example` etc. sbt builds look a bit like this too.
- Science: if you get rid of the top-level projects, and have `src/main/scala/com/example/` and `src/test/scala/com/example/`, you have Science layout. this is great if you want 1:1:1 rule, where you want one target per Bazel package.
- Google3: if you get rid of the `main|test` and language marker, and directly put `com/example/`, supposedly you get Google3. at first it looks odd, but it would be nice to call `bazel build com/example/...` or `bazel test com/example/...` and let Bazel figure out what to test. it's nice for Python and Protobuf where the directory structure already matches the package.

since we use a BUILD generator, I worked on polyglot BUILD generation feature a bit. [bazeltools/bzl-gen-build#170](https://github.com/bazeltools/bzl-gen-build/pull/170) adds `--append` so you can keep generating on top, and it seems to work.

<a id="#6"></a>
#### 2023-12-06

released [sbt 1.10.0-M1](/sbt-1.10.0-beta), featuring various Zinc fixes and better CommandProgress API, all contributed by the community.

<a id="#5"></a>
#### 2023-12-05

made more progress on the [remote cache](/sbt-remote-cache) post (still draft), now around 2063 words. finally I was able to get into more concrete details on the disk cache, and also write up a case study for caching `packageBin` task.

while writing it, I realized I could change the return types of some tasks to `HashedVirtualFileRef` that got added in day 2, so made that change. I guess this is a form of rubberducking.

<a id="#4"></a>
#### 2023-12-04

went to a local park after work to skate for a while. it was cold, but it's nice to have an empty basketball court for myself. worked on pushing and tictacs. I want to able to push while leaving the center of gravity above the board.

worked on the [remote cache](/sbt-remote-cache) post (still draft).

<a id="#3"></a>
#### 2023-12-03

released [bazel_jar_jar 0.1.0](https://github.com/bazeltools/bazel_jar_jar/releases/tag/v0.1.0), a Bazel rule to create shaded JAR. this release was motivated by BCR release automation contributed by Fabian Meumertzheim.

cleaned up the git history of the [sbt-2.x-cache](https://github.com/sbt/sbt/compare/develop...eed3si9n:sbt:wip/sbt-2.x-cache?expand=1) branch, by dropping the changes that I already landed on `develop` branch, and squashing related commits together.

drove 6h back from the conference. listened to [The Interstitium episode on Radiolab](https://radiolab.org/podcast/interstitium) as well as the mixtape. started writing [a blog post on sbt remote cache](/sbt-remote-cache) (still draft).

<a id="#2"></a>
#### 2023-12-02

released [scalaxb 1.12.0](https://scalaxb.org/scalaxb-1.12.0), an XML databinding for Scala. scalaxb 1.12.0 features scalaxbJaxbPackage option to use Jakarta, contributed by Matt Dziuban, and the code gen cross compiled to Scala 3, contributed by Kenji Yoshida. Besides releasing and organizing release notes, the behind the scenes work I did today was updating the tests in Maven plugin so it builds using Scala 2.12 stuff.

some progress on [rfc-1][rfc-1]. during the inital prototype I realized it's useful to have `HashedVirtualFileRef`, which is stronger than `VirtualFileRef` but weaker than `VirtualFile`, so added a Java implementation in Zinc.

<a id="#1"></a>
#### 2023-12-01

I drove 5 hours with immunologists across new england. released my 5h mixtape, which I used to reprogram them. [hyperparameter optimization (2023.12 mixtape)](/2023.12-mixtape). worked on scalaxb at night.

  [rfc-1]: https://eed3si9n.com/sbt-cache-ideas/
  [7464]: https://github.com/sbt/sbt/pull/7464
