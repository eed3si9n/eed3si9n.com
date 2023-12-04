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

`HashedVirtualFileRef` represents a virtual file name with some content hash.

Using these, we can define a basic cache function as follows:

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

### declaring the outputs

I'm planning to introduce a new function `Def.declareOutput` in sbt 2.x:

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
