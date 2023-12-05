---
title: "sbt remote cache (work in progress)"
type: story
date: 2023-12-03
url: /sbt-remote-cache
---

**status**: draft

Among various [ideas for sbt 2.x](/sbt-2.0-ideas), I've been specially been interested in the remote cache feature, and in particular beyond caching `compile`. As part of [december adventure 2023](/december-adventure-2023), which is about making small progress, I'm going to release this post in draft state, and update it as I go.

### intro

In a codebase shared by a team, or a CI, we end up building the same code individually on our own machines. Furthermore, we end up testing the same exact tests and executing exact same tasks. A remote cache, or a cloud build system, can speed up builds dramatically by sharing build results ([Mokhov 2018][build-system]).

I was able to bolt on the [cached compilation](/cached-compilation-for-sbt) for `compile` during sbt 1.x, and while shows promises, there are more to be desired. [RFC-1](/sbt-cache-ideas/) outlines them as:

1. Easier caching for tasks
2. Opt-in to remote cache tasks
3. Open design for remote cache implementation

This post explores the details for sbt 2.x.

### low-level foundation

The result of a cached task will be represented with an `ActionValue`:

```scala
import xsbti.HashedVirtualFileRef

class ActionValue[A1](a: A1, outs: Seq[HashedVirtualFileRef]):
  def value: A1 = a
  def outputs: Seq[HashedVirtualFileRef] = outs
  ....
end ActionValue
```

We'll come back to `HashedVirtualFileRef`, but it carries a file name with some content hash. Using these, we can define a basic cache function as follows:

```scala
import sjsonnew.{ HashWriter, JsonFormat }
import xsbti.VirtualFile

object ActionCache:
  def cache[I: HashWriter, O: JsonFormat: ClassTag](key: I, otherInputs: Long)(
      action: I => (O, Seq[VirtualFile])
  ): ActionValue[O] =
    ...
end ActionCache
```

`I` would typically be a tuple, and `HashWriter` is a typeclass to create a hash string. The signature of `action` function looks a bit odd, because it includes `Seq[VirtualFile]`. This is to capture file output effects during a task.

### automatic derivation of cacheable task

sbt's DSL is an Applicative `do`-notation, which translates

```scala
someKey := {
  name.value + version.value + "!"
}
```

into something like:

```scala
someKey <<= i.mapN((wrap(name), wrap(version)), (q1: String, q2: String) => {
  q1 + q2 + "!"
})
```

We can automatically derive a cacheable task by further wrapping the output:

```scala
someKey <<= i.mapN((wrap(name), wrap(version)), (q1: String, q2: String) => {
  ActionCache.cache[(String, String), String](
    key = (q1, q2),
    otherInputs = 0): input =>
      (q1 + q2 + "!", Nil))
})
```

For this to work, `(String, String)` must satisfy `HashWriter`, and `String` must satisfy `JsonFormat`.

### practical problems with caching

If caching was easy, it wouldn't be listed as one of hardest problems in computer science along with making profits from open source (and off-by-one error).

#### serialization issues

First, caching is serialization-hard, i.e. at least as hard as serialization problem. For sbt, a build tool that has existed in the current shape for 10+ years, this is going to be one of the biggest hurdle to cross. For instance, there's a datatype called `Attributed[A1]` that holds data `A1` with an arbitrary metadata key-value. Basic things like classpath is expressed using `Seq[Attributed[File]]`, which is used to associate a Zinc `Analysis` with classpath entries.

As long as we were executing tasks like compilation in-memory, `Attributed[A1]`, which is effectively a `Map[String, Any]` worked ok. But in light of caching, we'd need `HashWriter` for inputs, and `JsonFormat` for cached values, which is not possible for `Any`. In this particular case, I've worked around the issue by creating `StringAttributeMap`.

#### file serialization issues

Caching is file-serialization-hard, i.e. at least as hard of serializing a file. `java.io.File` (or `Path`) is such a special beast that requires its own consideration, not because of technicality, but mostly because of our own assumptions of what it means. When we say "file" it could actually mean:

1. relative path from a well-known location
2. a unique proof of a file, or a content hash
3. materialized actual file

When we use `java.io.File`, it's somewhat ambiguous that is meant by it from the above three. Technically speaking `File` just means the file path, so when we cache it we can deserialize just the file name `target/a/b.jar`. This will fail the downstream tasks if they assumed that `target/a/b.jar` would exist in the file system.

To disambiguate, `xsbti.VirtualFileRef` is used for just relative paths only; and `xsbti.VirtualFile` is used for materialized virtual file with contents. When we think of a list of files in terms of caching, neither is great. Having just the file name alone doesn't guarantee that the file will be the same, and carrying the entire content of the files is too inefficient in a JSON etc.

This is where the mysterious second option, a unique proof of file comes in handy. One of key innovations of Bazel cache is the idea of content-addressable storage (CAS). You can think of a directory full of files whose file name is named using the content hash of the file. Now, by knowing the content hash, we can always materialize it into an actual file, but for the purpose of data we can address it using the content hash. Actually, we'd also need the name of the file as well, so in sbt 2.x I've added `HashedVirtualFileRef` to represent this:

```java
public interface HashedVirtualFileRef extends VirtualFileRef {
  String contentHashStr();
}
```

#### effect issues

Caching is IO-hard, if we generalize the file serialization issue. We need to manage any side effects that the tasks performs that we care about, which might include displaying text on console. We might also need to think about composition.

#### granularity issues

Cache invalidation is latency-tradeoff-hard. If `compile` tasks generates 100 `.class` files, and `packageBin` creates a `.jar`, cache invalidation of `compile` task then incurs 100 file read for a disk cache, and 100 file download for a remote cache. Given that a JAR file can approximate `.class` files, we should consider using JAR files for `compile` to reduce the file download chattiness.

### declaring the outputs

I'm introducing a new function `Def.declareOutput` in sbt 2.x:

```scala
Def.declareOutput(out)
```

This would be called from within a task to declare file outputs. In a typical build tool file creation is performed via side effects, and a task may generate many files, which the downstream tasks may or may not actually use. With a remote cached build tool, we need to declare the output so necessary files are downloaded. Note that some tasks like `compile` currently generates files, but do not have file as return type.

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

When this run for the first time, we'll evaluate `q1 + q2 + "!"`, but we'll also store `o1` into the CAS and calculate `ActionValue`, which contains a list of `HashedVirtualFileRef`. During the second run, `ActionCache.cache(...)` can materialize it into a physical file and return a `VirtualFile` for it.

### cache backend

The following trait abstracts over a cache backend.

```scala
class ActionInput(hash: String):
  def inputHash: String = hash
  ....
end ActionInput

/**
 * An abstration of a remote or local cache store.
 */
trait ActionCacheStore:
  def put[A1: ClassTag: JsonFormat](
      key: ActionInput,
      value: A1,
      blobs: Seq[VirtualFile],
  ): ActionValue[A1]

  def get[A1: ClassTag: JsonFormat](key: ActionInput): Option[ActionValue[A1]]

  def putBlobs(blobs: Seq[VirtualFile]): Seq[HashedVirtualFileRef]

  def getBlobs(refs: Seq[HashedVirtualFileRef]): Seq[VirtualFile]

  def syncBlobs(refs: Seq[HashedVirtualFileRef], outputDirectory: Path): Seq[Path]
end ActionCacheStore
```

Initially, I'm going to test using a disk cache.

  [build-system]: https://www.microsoft.com/en-us/research/uploads/prod/2018/03/build-systems.pdf
