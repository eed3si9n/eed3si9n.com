---
title:       "sbt cache ideas"
type:        story
date:        2023-03-19
url:         sbt-cache-ideas
tags:        [ "sbt" ]
---

In [sbt 2.0 ideas](/sbt-2.0-ideas) I wrote:

> idea 6: more disk cache and remote cache
>
> Extending the idea of cached compilation in sbt 1.4.0, we should generalize the mechanism so any task can participate in the remote caching.

Here are some more concrete ideas for caching.

## problem space

To summarize the general problem space, currently setting up disk caching for tasks is a manual work, so it's under-utilized. Remote caching is limited to [cached compilation](/cached-compilation-for-sbt/).

Generally we would like:
1. Easier caching for tasks
2. Participation to remote cache
3. Open design for remote cache implementation

### caching in abstract

In the abstract we can think of cache as:

```scala
(A1, A2, A3, ...) => (Seq[Path] && B1)
```

Why is `Seq[Path]` so special? We need to treat files completely differently because, let's say you created a text file for each cached output `B1` and it says `foo/Hello.jar` that's good, but that's not good enough for a build tool. Because we need the actual file to exist on disk to perform other tasks.

So really, what we need to encode is the notion "output of file". If you think about sbt tasks like `update` or `compile`, the return type of these tasks are *reports* about the dependency or source graph, but it's expected that the file creation has also taken place as side effect.

## one cache pipeline, multiple backends

What's neat about Bazel is that the caching mechanism is abstracted away from the plugin authors.

Let's say the caching code looks something like this:

```scala
(A1, A2, A3, ...) =>
  val inputHash = hash((a1, a2, a3, ...) + other_inputs)
  getCachedAction(inputHash) match {
    case Some(ac) =>
      retrieveBlobs(ac.outputs)
      (ac.outputs, ac.value)
    case None     =>
      val ac = doActual()
      sendBlobs(ac.outputs)
      putCachedAction(inputHash, ac)
      (ac.outputs, ac.value)
  }
```

We can create multiple cache backend that could implement `getCachedAction(inputHash)`, `retrieveBlobs(outputs)`, etc.

### disk cache

The basic caching setup would be to use the local cache. This would replace the per-task caching that's done in sbt 1.x.

1. `getCachedAction` can check if the correspondng result file exists or not, and the content could be a text file.
2. `retrieveBlobs` can't just rely on the file name, since the content may change over time. Bazel uses content-addressable storage (CAS) to keep track of the hash of the files.

### remote caching: HTTP

As a starter, plain HTTP server could be a starting point for remote cache. A good thing is that's easy to set up, the downside is that reading and writing one file at a time is slow.

In any case, we can use some URL scheme like:

```
http://example.com/cache/ac/30c6172189093a9d0a4cf1fbfa79632b
http://example.com/cache/cas/3b8e48b651b51e2e03b6575347c64e6f
```

1. `getCachedAction` would be `GET` on `ac/...`
2. `retrieveBlobs` would also be series of `GET` per file
3. `sendBlobs` would be a series of `PUT` per file
4. `putCachedAction` would be `PUT` on `ac/...`

### remote caching: others

Using these as starting points, people can implement their own remote caching that are more suited to their environment.

## participating in the cache system

It depends how well it works, but it would be nice if a plain task automatically can participate in the caching system.

```scala
foo := {
  val s = streams.value
  s.log.info("hi")
  SomethingReport()
}
```

If it's implemented this way, then it would also mean that we won't execute any side effects when the cache is available (locally or remotely), unless we also design to track them explicitly.

We'd also need some opt-out:

```scala
foo := Def.uncachedTask {
  SomethingReport()
}
```

### declaring the outputs

As mentioned above, sbt tasks like `update` and `compile` do not directly have `Seq[Path]` as the return type. This means we would need a new mechanism to declare the outputs:

```scala
foo := {
  doSomething(target.value / "a.jar")
  declareOutput(target.value / "a.jar")
  SomethingReport()
}
```

This should let the macro know which files needs to be tracked as outputs for caching.

### other inputs

If you look at the example task again:

```scala
foo := {
  doSomething(target.value / "a.jar")
  declareOutput(target.value / "a.jar")
  SomethingReport()
}
```

interestingly, the only other task it's referencing here is `target`. This means that we would need a way to keep track of available declarations and classpath as part of the cache.

In addition, the shape of the source code also need to be part of the input hash. In Scala 3, this would likely use `Expr#show`.

## feedback

I created a discussion thread <https://github.com/sbt/sbt/discussions/7180> on GitHub. Let me know what you think there.
