---
title:       "december adventure 2023"
type:        story
date:        2023-12-27
url:         /december-adventure-2023
---

Inspired by [d6](http://plastic-idolatry.com/erik/2023/dec/) and [the original](https://eli.li/december-adventure), I'm going to try to work on something small everyday. I'll post on [Mastodon as well](https://elk.zone/mastodon.social/@eed3si9n/111511724828068883).

my goal: work on sbt 2.x, other open source like sbt 1.x and plugins, or some post on this site, like music or recipe.

<!--more-->
<a id="#30"></a>
#### 2023-12-30
my wife and I prepare osechi (お節), japanese new year food some vegan, others non-veg. given that osechi is actually similar to korean dishes, we first hit H-Mart to grab side dishes like pickled radish, boiled black beans, also cream puffs, clementines, imported kelp, dried shiitake mushrooms etc.

next I prepared two kinds of vegan dashi (broth), kombu dashi and dried shiitake dashi, which form the foundation of osechi. recipe is at [/recipes/vegan-dashi](/recipes/vegan-dashi.html).

<a id="#28"></a>
#### 2023-12-28
I wanted to generalize `@cacheOptOut(...)` attribute to:

```scala
@cacheLevel(include = Array(CacheLevelTag.Local, ...))
```

so we can mark some input to be no-cache, local-only, or both local and remote.

```scala
@meta.getter
class cacheLevel(
    include: Array[CacheLevelTag],
) extends StaticAnnotation

enum CacheLevelTag:
  case Local
  case Remote
end CacheLevelTag

object CacheLevelTag:
  private[sbt] val all: Array[CacheLevelTag] = Array(CacheLevelTag.Local, CacheLevelTag.Remote)

  given CacheLevelTagToExpr: ToExpr[CacheLevelTag] with
    def apply(tag: CacheLevelTag)(using Quotes): Expr[CacheLevelTag] =
      tag match
        case CacheLevelTag.Local  => '{ CacheLevelTag.Local }
        case CacheLevelTag.Remote => '{ CacheLevelTag.Remote }

  given CacheLevelTagFromExpr: FromExpr[CacheLevelTag] with
    def unapply(expr: Expr[CacheLevelTag])(using Quotes): Option[CacheLevelTag] =
      expr match
        case '{ CacheLevelTag.Local }  => Some(CacheLevelTag.Local)
        case '{ CacheLevelTag.Remote } => Some(CacheLevelTag.Remote)
        case _                         => None
end CacheLevelTag
```

the macro code to extract the `cacheLevel` tags looks like this:

```scala
def isCacheInput: Boolean = tags.nonEmpty
lazy val tags = extractTags(qual)
private def extractTags(tree: Term): List[CacheLevelTag] =
  def getAnnotation(tree: Term) =
    Option(tree.tpe.termSymbol) match
      case Some(x) => x.getAnnotation(cacheLevelSym)
      case None    => tree.symbol.getAnnotation(cacheLevelSym)
  def extractTags0(tree: Term) =
    getAnnotation(tree) match
      case Some(annot) =>
        annot.asExprOf[cacheLevel] match
          case '{ cacheLevel(include = Array.empty[CacheLevelTag]($_)) } => Nil
          case '{ cacheLevel(include = Array[CacheLevelTag]($include*)) } =>
            include.value.get.toList
          case _ => sys.error(Printer.TreeStructure.show(annot) + " does not match")
      case None => CacheLevelTag.all.toList
  tree match
    case Inlined(_, _, tree) => extractTags(tree)
    case Apply(_, List(arg)) => extractTags(arg)
    case _                   => extractTags0(tree)
```

it's pretty cool that we can pattern match on the `cacheLevel(...)` tree using quote syntax. in the above, `include.value` uses `FromExpr` to directly parse the direct values. to pass the tags back into the code, we do something like the following, which uses `ToExpr` typeclass, to construct an `Expr` of a list:

```scala
val tagsExpr = '{ List(${ Varargs(tags.map(Expr[CacheLevelTag](_))) }: _*) }
```

This refactoring required some repetitive edits, so picked up a few Helix tricks along the way (all in the user manual):

- jump to next error in the buffer: `]d`
- select inside of a closest surrounding pair: `mim`
- use a register: `"<reg>`
- replace with yanked text: `R`

<a id="#27"></a>
#### 2023-12-27
I've implemented the new caching in a new subproject called `utilCacheResolver`, but I've consolidated it to existing `utilCache` instead by dropping Scala 2.x support.

next, I've [replaced](https://github.com/sbt/sbt/pull/7464/commits/8f393e8c23837f1b55731430c4ca98a77e5057d0) `ActionInput` class with a Scala 3 [opaque type](https://docs.scala-lang.org/scala3/reference/other-new-features/opaques.html) called `Digest` instead:

```scala
import sjsonnew.IsoString

opaque type Digest = String

object Digest:
  def apply(s: String): Digest =
    validateString(s)
    s

  private def validateString(s: String): Unit =
    val tokens = s.split("-").toList
    tokens match
      case "md5" :: value :: Nil     => ()
      case "sha1" :: value :: Nil    => ()
      case "sha256" :: value :: Nil  => ()
      case "sha384" :: value :: Nil  => ()
      case "sha512" :: value :: Nil  => ()
      case "murmur3" :: value :: Nil => ()
      case _                         => throw IllegalArgumentException(s"unexpected digest: $s")
    ()

  given IsoString[Digest] = IsoString.iso(x => x, s => s)
end Digest
```

for some reason I thought it's not possible to implement an opaque type at top-level, but I guess it's not a problem. it almost doesn't do anything, and that's sort of the point. previously, these almost-nothings still required a dedicated case class (or value class) but opaque type gives a nicer solution that compiles away, and hopefully easier to maintain binary compatibility.

<a id="#26"></a>
#### 2023-12-26
went to a brunch at friends' house. we've learned the lesson and contacted the hosts ahead of bringing a baker's dozen of Hoboken Hot Bagels (the best bagel in the world) with two kinds of cream cheese and a pound of lox (smoked salmon), and other pastries

went skating at the park in the evening. worked on tail stop.

for the remote cache PR, contiued on change the blob hashing to SHA-256 because bunch of tests failed yesterday. eventually got it to work. I've been faking the caching of metabuild, but somehow this change required me to actually implement a disk cache during the booting process.

<a id="#25"></a>
#### 2023-12-25
fixed JavaDoc support. it's not that the JavaDoc support has regressed but the caching around JavaDoc needed tweaking because of the version conflict of sjson-new between that's being used in Zinc and sbt/sbt.

also modified the blob hashing to use SHA-256.

<a id="#23"></a>
#### 2023-12-23
my wife and I were invited to a fancy holiday party. only we didn't know it was going to be a fancy, catered party, so we baked two pies and brought them (no one else brought food).

![baked brie](/images/dec_2023_baked_brie.jpg)

first one is straight up Alexa Weibel's [baked brie and caramelized vegetable pie](https://cooking.nytimes.com/recipes/1024809-baked-brie-and-caramelized-vegetable-pie?unlocked_article_code=1.IU0.PuB4.V6kEMLD0JVhe&smid=share-url) on nyt cooking. I made it for Thanksgiving this year, and made this again, this time with puff pastry. so good.

![apple pie](/images/dec_2023_apple_pie.jpg)

second one is an americanized tarte au pomme, using new york honeycrisps and apple sauce.

<a id="#22"></a>
#### 2023-12-22
renamed `ActionValue` to `ActionResult` to match the name on [Remote Execution API][remote_execution].

similarly for compatibility, hashed the action puts using SHA256 at the end. the input Merkle tree is still hashed using Murmur3 64-bit, so it's not a true tree of SHA256s. to avoid collisions, maybe extending the middle part to Murmur3 128-bit would be a good improvement later.

<a id="#21"></a>
#### 2023-12-21
reviewed a Zinc [pull request](https://github.com/sbt/zinc/pull/1312) by Jerry Tan regarding infinite compilation loop. incremental compilation is confusing, but this is especially confusing one because it has something to do with mixed Scala and Java compilation, that regressed when we started support for build pipelining (ability to start compiling depender subprojects midway through the compiler phases).

I am also starting to browse Bazel's [Remote Execution API][remote_execution] as one does. I noticed that the hashing algorithms are hard coded to a few sets, and does not include FarmHash. It's not uncommon to have 1000 JARs on a classpath, and really didn't want to introduce cryptographic hash, but I might have to potentially for safety. MD5 is the most commonly available non-cryptographic hash (just kidding, or am I?).

<a id="#20"></a>
#### 2023-12-20
finished translating the blog post into Japanese.

added a few sections that I thought about while translating: hermeticity issues, and package aggregation issue, which is the issue I mentioned yesterday.

<a id="#19"></a>
#### 2023-12-19
signed myself up to an Advent Calendar, and started translating the [sbt 2.x remote cache](/sbt-remote-cache) post into Japanese.

one feedback I got on Discord from Matthias Berndt on the blog post:

> Ideally it would be possible to cache compilation at a more granular level, like files or even top-level definitions.

this is an interesting feedback, apparently based on his experiment using Pants 2 that implements file-level caching. another way of thinking about this what I called "wildfire" problem in Analysis of Zinc talk. simply reverting the dependency graph would spread invalidation like a wildfire. Zinc 1.x uses name hashing to tackle this.

<a id="#18"></a>
#### 2023-12-18
not much coding progress, but thinking about initialization of the cache. one somewhat unique characteristic of sbt is that the `build.sbt` file together with `project/*.scala` are compiled using sbt. this is called metabuild.

if we cached the `compile` task, then the compilation of the metabuild will also be cached. I was going to let the build user configure the cache stores in `build.sbt`. if we go with that plan, then I guess metabuild caching would just be hardcoded to an unobtrusive default? we can let the user pass some settings in environment variables etc. if we let build users configure cache stores using plugins, and metabuild and meta-metabuild requires disk cache, hopefully it's not too bad.

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
  [remote_execution]: https://github.com/bazelbuild/remote-apis/blob/main/build/bazel/remote/execution/v2/remote_execution.proto
