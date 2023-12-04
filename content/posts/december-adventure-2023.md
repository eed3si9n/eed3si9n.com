---
title:       "december adventure 2023"
type:        story
date:        2023-12-02
url:         /december-adventure-2023
---

Inspired by [d6](http://plastic-idolatry.com/erik/2023/dec/) and [the original](https://eli.li/december-adventure), I'm going to try to work on something small everyday. I'll post on [Mastodon as well](https://elk.zone/mastodon.social/@eed3si9n/111511724828068883).

my goal: work on sbt 2.x, other open source like sbt 1.x and plugins, or some post on this site, like music or recipe.

<!--more-->

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
