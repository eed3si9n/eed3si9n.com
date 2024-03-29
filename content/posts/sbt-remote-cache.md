---
title: "sbt 2.x remote cache"
type: story
date: 2023-12-18
url: /sbt-remote-cache
---

  [build-system]: https://www.microsoft.com/en-us/research/uploads/prod/2018/03/build-systems.pdf
  [7464]: https://github.com/sbt/sbt/pull/7464
  [HashWriter]: https://github.com/eed3si9n/sjson-new/blob/66f05ac562a5c4ed544d24c41aacf3b69a9318f4/core/src/main/scala/sjsonnew/HashWriter.scala
  [JsonFormat]: https://github.com/eed3si9n/sjson-new/blob/develop/core/src/main/scala/sjsonnew/JsonFormat.scala
  [reibitto]: https://reibitto.github.io/blog/remote-caching-with-sbt-and-s3/
  [tweets]: https://twitter.com/eed3si9n/status/1319626955159896064

### introduction

A remote cache, or a cloud build system, can speed up builds dramatically by sharing build results ([Mokhov 2018][build-system]). This is a feature that I've been interested ever since heard about Blaze (now open sourced as Bazel). In 2020, I implemented [cached compilation](/cached-compilation-for-sbt) in sbt 1.x. [reibitto][reibitto] has reported that "what was once 7 minutes to compile everything now takes **15 seconds**." Others have also reported **2x ~ 5x** speedup. While this is promising, it's a bit clunky and it works only for the `compile` task. In March 2023, I jotted down [RFC-1: sbt cache ideas](/sbt-cache-ideas/) to outline the current issues and a solution design. Here are some of the problems:

- Problem 1: sbt 1.x implements remote caching for `compile`, and disk caching for some other tasks, but we would like a solution that custom tasks can participate
- Problem 2: sbt 1.x has separate mechanism for disk cache and remote cache, but we would like one mechanism that build user can switch between local or remote cache
- Problem 3: sbt 1.x used Ivy resolver as the cache abstration, but we'd like a more open design for remote cache backend

As my [december adventure 2023](/december-adventure-2023) project I decided to tackle the sbt 2.x remote cache feature in my free time. The proposal is on GitHub [#7464][7464]. This post explores the details of the change. **Note**: It shouldn't require too much of sbt internal knowledge, but the target audience is advanced since this is more of an extended PR description.

<!--more-->

### low-level foundation

In the abstract, we can think of a cached task as:

```scala
(In1, In2, In3, ...) => (A1 && Seq[Path])
```

If we saved the hash of inputs and the result somewhere, like on a disk, we can skip the evaluation of expensive tasks, and present the result instead. The result of a cached task is represented as an `ActionResult`:

```scala
import xsbti.HashedVirtualFileRef

class ActionResult[A1](a: A1, outs: Seq[HashedVirtualFileRef]):
  def value: A1 = a
  def outputs: Seq[HashedVirtualFileRef] = outs
  ....
end ActionResult
```

We'll come back to `HashedVirtualFileRef` later, but it carries a file name with some content hash. Using these, we can define the `cache` function as follows:

```scala
import sjsonnew.{ HashWriter, JsonFormat }
import xsbti.VirtualFile

object ActionCache:
  def cache[I: HashWriter, O: JsonFormat: ClassTag](
      key: I,
      codeContentHash: Digest,
      extraHash: Digest,
      tags: List[CacheLevelTag],
  )(
      action: I => (O, Seq[VirtualFile])
  )(
      config: BuildWideCacheConfiguration
  ): O =
    val input =
      Digest.sha256Hash(codeContentHash, extraHash, Digest.dummy(Hasher.hashUnsafe[I](key)))
    ....
end ActionCache
```

The type parameter `I` would typically be a tuple. The signature of the `action` function looks a bit odd, because it includes `Seq[VirtualFile]`. This is to capture file output effects during a task.

### automatic derivation of cacheable task

sbt's DSL is an Applicative `do`-notation, which translates

```scala
someKey := {
  name.value + version.value + "!"
}
```

into an Applicative `mapN` expression via macros:

```scala
someKey <<= i.mapN((wrap(name), wrap(version)), (q1: String, q2: String) => {
  q1 + q2 + "!"
})
```

Using Scala 3 macros, we can automatically derive a cacheable task by further wrapping the output:

```scala
someKey <<= i.mapN((wrap(name), wrap(version)), (q1: String, q2: String) => {
  ActionCache.cache[(String, String), String](
    key = (q1, q2),
    otherInputs = 0): input =>
      (q1 + q2 + "!", Nil))
})
```

For this to work, the input tuple must satisfy [`sjsonnew.HashWriter`][HashWriter], and the result type, for example `String`, must satisfy `JsonFormat`. One way to think about this is that we are constructing a [Merkle tree](https://en.wikipedia.org/wiki/Merkle_tree) out of the abstract syntax tree of your `build.sbt` and [pseudo case classes](/contraband-an-alternative-to-case-class/).

### cache backend

The following trait abstracts over a cache backend.

```scala
opaque type Digest = String

/**
 * An abstration of a remote or local cache store.
 */
trait ActionCacheStore:
  def put[A1: ClassTag: JsonFormat](
      actionDigest: Digest,
      value: A1,
      blobs: Seq[VirtualFile],
  ): ActionResult[A1]

  def get[A1: ClassTag: JsonFormat](input: Digest): Option[ActionResult[A1]]

  def putBlobs(blobs: Seq[VirtualFile]): Seq[HashedVirtualFileRef]

  def getBlobs(refs: Seq[HashedVirtualFileRef]): Seq[VirtualFile]

  def syncBlobs(refs: Seq[HashedVirtualFileRef], outputDirectory: Path): Seq[Path]
end ActionCacheStore
```

Hopefully the methods are self-explanatory, but this API is for someone who wants to implement a cache backend so understanding the detail isn't important. An interesting thing to note is that it only requires 5 methods. For the initial testing, I'm going to focus on a local disk cache.

Here's how the cache directory looks after running `pacakgeBin`, which is a cached task:

```bash
$ tree $HOME/Library/Caches/sbt/v2/
~/Library/Caches/sbt/v2/
├── ac
│   ├── sha256-d3ea49940f3ec7f983ddfe91f811161d2fee53c19ec58db224c789b63c5d759d
│   └── sha256-e2d1010d6ce5808902e35222ec91d340ae7ecb013ec7cb3b568c3b2c33c3ffa0
└── cas
    ├── sha256-02775d17841ec170a97b2abec01f56fb3e3949fefc8d69121e811f80c041cfb1
    ├── sha256-601ba6379aeed7fefd522d3a916b3750c35fe8cd02afe95a7be4960de1fbcfa7
    └── sha256-f824ffec2c48cbc5e4cdcaec71670983064312055d3e9cfcc1220d7f4f193027
```

The file content of `ac/sha256-d3ea49940f3ec7f983ddfe91f811161d2fee53c19ec58db224c789b63c5d759d` is:

```json
{"$fields":["value","outputFiles"],"value":"${OUT}/jvm/scala-3.3.1/hello/hello_3-0.1.0-SNAPSHOT.jar>sha256-f824ffec2c48cbc5e4cdcaec71670983064312055d3e9cfcc1220d7f4f193027","outputFiles":["${OUT}/jvm/scala-3.3.1/hello/hello_3-0.1.0-SNAPSHOT.jar>sha256-f824ffec2c48cbc5e4cdcaec71670983064312055d3e9cfcc1220d7f4f193027"]}
```

`cas/sha256-f824ffe...` is a JAR file:

```bash
$ unzip -l $HOME/Library/Caches/sbt/v2/cas/sha256-f824ffec2c48cbc5e4cdcaec71670983064312055d3e9cfcc1220d7f4f193027
Archive:  ~/Library/Caches/sbt/v2/cas/sha256-f824ffec2c48cbc5e4cdcaec71670983064312055d3e9cfcc1220d7f4f193027
  Length      Date    Time    Name
---------  ---------- -----   ----
      298  01-01-2010 00:00   META-INF/MANIFEST.MF
        0  01-01-2010 00:00   example/
      608  01-01-2010 00:00   example/Greeting.class
      363  01-01-2010 00:00   example/Greeting.tasty
....
```

### practical problems with caching

If caching were easy, it wouldn't be listed as one of the hardest problems in computer science along with making profits from open source (and off-by-one error).

#### serialization issues

First, caching is serialization-hard, i.e. at least as hard as the serialization problem. For sbt, a build tool that has existed in the current shape for 10+ years, this is going to be the biggest hurdle to cross. For instance, there's a datatype called `Attributed[A1]` that holds data `A1` with an arbitrary metadata key-value. Basic things like classpath are expressed using `Seq[Attributed[File]]`, which is used to associate a Zinc `Analysis` with classpath entries.

As long as we were executing tasks like `compile` in-memory, `Attributed[A1]`, which is effectively a `Map[String, Any]` worked ok. But in light of caching, we'd need `HashWriter` for inputs, and `JsonFormat` for cached values, which is not possible for `Any`. In this case, I've worked around this issue by creating `StringAttributeMap`.

#### file serialization issues

Caching is file-serialization-hard, i.e. at least as hard as serializing a file. `java.io.File` (or `Path`) is such a special beast that requires its own consideration, not because of technicality, but mostly because of our own assumptions of what it means. When we say a "file" it could actually mean:

1. relative path from a well-known location
2. a unique proof of a file, or a content hash
3. materialized actual file

When we use `java.io.File`, it's somewhat ambiguous what is meant by it from the above three. Technically speaking a `File` just means the file path, so we can deserialize just the filename such as `target/a/b.jar`. This will fail the downstream tasks if they assumed that `target/a/b.jar` would exist in the file system.

To disambiguate, `xsbti.VirtualFileRef` is used for just relative paths only; and `xsbti.VirtualFile` is used for materialized virtual files with contents. However, for the purpose of caching a list of files, neither is great. Having just the filename alone doesn't guarantee that the file will be the same, and carrying the entire content of the files is too inefficient in a JSON etc. Given that same JAR can be repeated within a build, it doesn't make sense to embed the contents when we need just a reference.

This is where the mysterious second option, a _unique proof_ of file comes in handy. One of key innovations of Bazel cache is the idea of content-addressable storage (CAS). You can think of a directory full of files whose filename is named using the content hash of the file. Now, by knowing the content hash, we can always materialize it into an actual file, but for the purpose of data we can address it using the content hash. Actually, we'd also need the name of the file as well, so in sbt 2.x I've added `HashedVirtualFileRef` to represent this:

```java
public interface HashedVirtualFileRef extends VirtualFileRef {
  String contentHashStr();
}
```

#### effect issues

Caching is IO-hard, if we generalized the file serialization issue to all side effects. We need to manage any side effects that the tasks perform that we care about, which might include displaying text on the console. We might also need to think about composition.

#### declaring the outputs

In sbt 2.x, I'm introducing a new function `Def.declareOutput`:

```scala
Def.declareOutput(out)
```

This would be called from within a task to declare a file output. In a typical build tool file creation is performed via side effects, and a task may generate many files, which the downstream tasks may or may not actually use. With a remote cached build tool, we need to declare the output so expected files are downloaded. Also note that some tasks like `compile` currently generate files, but do not have file as return type.

```scala
someKey := Def.cachedTask {
  val output = StringVirtualFile1("a.txt", "foo")
  Def.declareOutput(output)
  name.value + version.value + "!"
}
```

This becomes:

```scala
someKey <<= i.mapN((wrap(name), wrap(version)), (q1: String, q2: String) => {
  var o0 = _
  ActionCache.cache[(String, String), String](
    key = (q1, q2),
    otherInputs = 0): input =>
      var o1: VirtualFile = _
      val output = StringVirtualFile1("a.txt", "foo")
      o1 = output
      (q1 + q2 + "!", List(o1))
})
```

When we run the task for the first time, sbt evaluates `q1 + q2 + "!"`, but it'll also store `o1` into the CAS and calculate an `ActionResult`, which contains a list of `HashedVirtualFileRef`. During the second run, `ActionCache.cache(...)` can materialize it into a physical file and return a `VirtualFile` for it.

#### opting out of serialization

In the previous example, all input settings/tasks were assumed to be a cache key:

```scala
ActionCache.cache[(String, String), String](
  key = (q1, q2),
  ....
```

This is probably a decent default behavior, but in practice there are some keys that you'd want to exclude from the cache key. For example, `streams` key is used for logging, and is given a fresh value each time, which has no meaningful value for serialization. There's no reason to try to turn it into JSON.

I've added an annotation called `cacheLevel(...)` for this purpose:

```scala
@meta.getter
class cacheLevel(
    include: Array[CacheLevelTag],
) extends StaticAnnotation

enum CacheLevelTag:
  case Local
  case Remote
end CacheLevelTag
```

Now we can opt-out `streams` as follows:

```scala
@cacheLevel(include = Array.empty)
val streams = taskKey[TaskStreams]("Provides streams for logging and persisting data.")
  .withRank(DTask)
```

In general, we might want to exclude anything machine-specific or non-hermetic from the cache key when possible.

#### latency tradeoff issues

Caching is latency-tradeoff-hard. If the `compile` task generated 100 `.class` files, and `packageBin` created a `.jar`, cache hit of `compile` task then incurs 100 file read for a disk cache, and 100 file download for a remote cache. Given that a JAR file can approximate `.class` files, we should use JAR files for `compile` to reduce the file download chattiness.

<a id="hermeticity"></a>
#### hermeticity issues

Remote caching is hermecity-hard. The premise of remote cache is that the cached results are sharable across different machines. When we end up capturing machine-specific information unintentionally into the artifact, we could either end up with a growing cache size, low cache hit%, or a runtime error. This is called a hermeticity break.

Two common issues are capturing the absolute path via `java.io.File`, or the current timestamp. More subtle ones that I've seen are JVM bug that captures timezone of the machine, and GraalVM capturing the glibc version.

<a id="package-aggregation"></a>
#### package aggregation issue

Cache invalidation is package-aggregation hard. See [Analysis of Zinc](https://www.youtube.com/watch?v=h8ACmUHQ2jg) talk for more details. I just made up the name _package aggregation_ here, but the gist of the issue is that the more source files you aggregate into a subproject, the more inter-connected the subprojects become, and naïve invalidation of simply inverting the dependency graph would end up spreading the initial invalidation (code changes) to most of the monorepo like a wildfire.

Build tools deal with this issue in various ways:

- Make the subproject more granular. Like 1:1:1 Rule (one directory, one package, one target)
- Ignore transitive dependency, also known as strict deps (Bazel does this for Java)
- Track dependency at the method usage granularity (Zinc does this)
- Remove unused imports and library dependencies

Initially I'm going to implement the simple naïve invalidation, but we should leave a door open to iterate in this area. (Thanks Matthias Berndt for remind me about this)

### case study: packageBin task

The `pacakgeBin` task creates the JAR file of the class files. In general `package*` family of tasks are created using [`packageTaskSettings` and `packageTask` functions](https://github.com/sbt/sbt/blob/v1.9.7/main/src/main/scala/sbt/Defaults.scala#L1848-L1871) and [`Package` object](https://github.com/sbt/sbt/blob/v1.9.7/main-actions/src/main/scala/sbt/Package.scala). We can try turning `packageBin` into a cached task.

First, we need to make `PackageOption` serializable. I turned it into a Scala 3 enum, implemented `JsonFormat` for each cases, and then defined an union:

```scala
enum PackageOption:
  case JarManifest(m: Manifest)
  case MainClass(mainClassName: String)
  case ManifestAttributes(attributes: (Attributes.Name, String)*)
  case FixedTimestamp(value: Option[Long])

object PackageOption:
  ....

  given JsonFormat[PackageOption] = flatUnionFormat4[
    PackageOption,
    PackageOption.JarManifest,
    PackageOption.MainClass,
    PackageOption.ManifestAttributes,
    PackageOption.FixedTimestamp,
  ]("type")
end PackageOption
```

The `Package.Configuration` class was modified as follows:

```scala
// in sbt 1.x
final class Configuration(
  val sources: Seq[(File, String)],
  val jar: File,
  val options: Seq[PackageOption]
)

// in sbt 2.x
final class Configuration(
  val sources: Seq[(HashedVirtualFileRef, String)],
  val jar: VirtualFileRef,
  val options: Seq[PackageOption]
)
```

Note that we see `HashedVirtualFileRef` representing the input sources, and `VirtualFileRef` is used to specify the output file name. The action code to create a JAR file `Pkg.apply(...)` will return `VirtualFile` instead of `Unit`.

`packageBin` key in Keys.scala was changed to:

```scala
val packageBin = taskKey[HashedVirtualFileRef]("Produces a main artifact, such as a binary jar.").withRank(ATask)
```

and the new `packageTask` looks like this:

```scala
def packageTask: Initialize[Task[HashedVirtualFileRef]] =
  Def.cachedTask {
    val config = packageConfiguration.value
    val s = streams.value
    val converter = fileConverter.value
    val out = Pkg(
      config,
      converter,
      s.log,
      Pkg.timeFromConfiguration(config)
    )
    Def.declareOutput(out)
    out
  }
```

A subtle point I want to make is that in the above, I chose to use `HashedVirtualFileRef` instead of `VirtualFile` as the return type even though `out` is a `VirtualFile`. In fact it would not compile if the task key is changed to `Initialize[Task[VirtualFile]]`:

```scala
[error] -- [E172] Type Error: /user/xxx/sbt/main/src/main/scala/sbt/Defaults.scala:1979:5
[error] 1979 |    }
[error]      |     ^
[error]      |Cannot find JsonWriter or JsonFormat type class for xsbti.VirtualFile.
```

Recall `ac/sha256-d3ea49940f3ec7f983ddfe91f811161d2fee53c19ec58db224c789b63c5d759d` in disk cache:

```json
{"$fields":["value","outputFiles"],"value":"${OUT}/jvm/scala-3.3.1/hello/hello_3-0.1.0-SNAPSHOT.jar>sha256-f824ffec2c48cbc5e4cdcaec71670983064312055d3e9cfcc1220d7f4f193027","outputFiles":["${OUT}/jvm/scala-3.3.1/hello/hello_3-0.1.0-SNAPSHOT.jar>sha256-f824ffec2c48cbc5e4cdcaec71670983064312055d3e9cfcc1220d7f4f193027"]}
```

If the task's return type was `VirtualFile`, we'd have to serialize the entire file content in the above JSON. Instead, we're storing only the relative path along with its unique proof of the file, calculated using SHA-256: `"${OUT}/jvm/3.3.1/hello/scala-3.3.1/hello_3-0.1.0-SNAPSHOT.jar>farm64-b9c876a13587c8e2"`. The actual content is given to the CAS via `Def.declareOutput(out)`.

Once the disk cache is hydrated, even after `clean`, `packageBin` will now be able to quickly make a symbolic link to the disk cache, instead of zipping the inputs.

### case study: compile task

Now that `packageBin` is cached automatically, we can extend this idea to `compile` as well. One of the challenges, as mentioned above is the latency-tradeoff problem. In sbt 1.x, we can basically create as fine grained tasks as we want since it's used only to denote the chunk of work that are typed and can be parallelized. In sbt 2.x, we might need to be mindful about the network latencies (Something we should experimment). Thankfully we have JAR file that the compiler is already used to dealing with, so we can let `compile` generate a JAR instead of trying to cache all `*.class` files.

Here's a rough snippet of `compileIncremental`:

```scala
compileIncremental := (Def.cachedTask {
  val s = streams.value
  val ci = (compile / compileInputs).value
  val c = fileConverter.value
  // do the normal incremental compilation here:
  val analysisResult: CompileResult =
    BspCompileTask
      .compute(bspTargetIdentifier.value, thisProjectRef.value, configuration.value) {
        bspTask => compileIncrementalTaskImpl(bspTask, s, ci, ping, reporter)
      }
  val analysisOut = c.toVirtualFile(setup.cachePath())
  Def.declareOutput(analysisOut)

  // inline packageBin to create a JAR file
  val mappings = ....
  val pkgConfig = Pkg.Configuration(...)
  val out = Pkg(...)
  s.log.info(s"wrote $out")
  Def.declareOutput(out)
  analysisResult.hasModified() -> (out: HashedVirtualFileRef)
})
.tag(Tags.Compile, Tags.CPU)
.value,
```

Here's how we can use this:

```scala
$ sbt
[info] welcome to sbt 2.0.0-alpha8-SNAPSHOT (Azul Systems, Inc. Java 1.8.0_352)
[info] loading project definition from hello1/project
[info] compiling 1 Scala source to hello1/target/out/jvm/scala-3.3.1/hello1-build/classes ...
[info] wrote ${OUT}/jvm/scala-3.3.1/hello1-build/hello1-build-0.1.0-SNAPSHOT-noresources.jar
....
sbt:Hello> compile
[info] compiling 1 Scala source to hello1/target/out/jvm/scala-3.3.1/hello/classes ...
[info] wrote ${OUT}/jvm/scala-3.3.1/hello/hello_3-0.1.0-SNAPSHOT-noresources.jar
[success] Total time: 3 s
sbt:Hello> clean
[success] Total time: 0 s
sbt:Hello> compile
[success] Total time: 1 s
sbt:Hello> run
[info] running example.Hello
hello
[success] Total time: 1 s
sbt:Hello> exit
[info] shutting down sbt server
```

This shows that even after `clean`, which currently cleans the target directory, `compile` is cached. It's actually not an no-op because some of the dependent tasks are not yet cached, but it finished in 1s. We can also exit the sbt session and remove `target/` to be sure:

```bash
$ rm -rf project/target
$ rm -rf target
$ sbt
[info] welcome to sbt 2.0.0-alpha8-SNAPSHOT (Azul Systems, Inc. Java 1.8.0_352)
....
sbt:Hello> run
[info] running example.Hello
hello
[success] Total time: 2 s
sbt:Hello> exit
[info] shutting down sbt server
$ ls -l target/out/jvm/scala-3.3.1/hello/
$ ls -l target/out/jvm/scala-3.3.1/hello/
total 0
drwxr-xr-x  4 xxx  staff  128 Dec 27 03:44 classes/
lrwxr-xr-x  1 xxx  staff  113 Dec 27 03:44 hello_3-0.1.0-SNAPSHOT-noresources.jar@ -> /Users/xxx/Library/Caches/sbt/v2/cas/sha256-02775d17841ec170a97b2abec01f56fb3e3949fefc8d69121e811f80c041cfb1
lrwxr-xr-x  1 eed3si9n  staff  113 Dec 27 03:44 hello_3-0.1.0-SNAPSHOT.jar@ -> /Users/xxx/Library/Caches/sbt/v2/cas/sha256-f824ffec2c48cbc5e4cdcaec71670983064312055d3e9cfcc1220d7f4f193027
drwxr-xr-x  5 xxx  staff  160 Dec 27 03:44 streams/
drwxr-xr-x  3 xxx  staff   96 Dec 27 03:44 sync/
drwxr-xr-x  3 xxx  staff   96 Dec 27 03:44 update/
drwxr-xr-x  3 xxx  staff   96 Dec 27 03:44 zinc/
```

Again, `run` worked without invoking the Scala compiler. The reason why we have two JARs is that technically `compile` task does not include `src/main/resources/` contents. In sbt 1.x, that's the job of `copyResources` task, which is called by `products`.

Again, there's a tradeoff of task granularity. By sepearating compilation and resources, we can avoid uploading resource files into the cache when we make source changes. On the other hand, the separation requires double uploading when you want the product output, which for us is `packageBin`.

#### new Classpath type

As mentioned above, in sbt 1.x, classpaths were expressed using `Seq[Attributed[File]]`. `java.io.File` isn't suitable as cache inputs since it ends up capturing the absolute path and it's woefully unaware of the content changes. In sbt 2.x, the new `Classpath` is defined as follows:

```scala
type Classpath = Seq[Attributed[HashedVirtualFileRef]]
```

Note that `HashedVirtualFileRef` can always be turned back into `Path` given an instance of `FileConverter`, which is available via `fileConverter.value`. There's a Scala 3 extension method `files` that can be used to turn a classpath into a `Seq[Path]`:

```scala
given FileConverter = fileConverter.value
val cp = (Compile / dependencyClasspath).value.files
```

### summary

Based on [RFC-1: sbt cache ideas](/sbt-cache-ideas/), [#7464][7464] implements automatic cached task called `Def.cachedTask`:

```scala
someKey := Def.cachedTask {
  val output = StringVirtualFile1("a.txt", "foo")
  Def.declareOutput(output)
  name.value + version.value + "!"
}
```

This uses Scala 3 macro to automatically track the dependent tasks as cache keys, and serialize and deserialize the outputs. The requirement for the inputs is that they must implement [`sjsonnew.HashWriter`][HashWriter] a typeclass for a [Merkle tree](https://en.wikipedia.org/wiki/Merkle_tree). The result type must satisfy [`sjsonnew.JsonFormat`][JsonFormat].

To track files, sbt 2.x uses two types: `VirtualFile` and `HashedVirtualFileRef`. `VirtualFile` is used by the tasks for actual reading and writing, while `HashedVirtualFileRef` is used as a cache-friendly reference to files, including classpath-related tasks.

`Def.declareOutput(...)` is used to explicitly declare the file creation that is relevant to the task. For example, `compile` task may create `*.class` files, but they will not be cached. Instead a JAR file will be registered using `Def.declareOutput(...)`.

To put the mechanism to test, [#7464][7464] implements automatic caching for both `packageBin` and `compile` task.
