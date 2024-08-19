---
title:       "sudori part 4"
type:        story
date:        2024-08-18
draft:       false
url:         /sudori-part4
tags:        [ "sbt" ]
---

  [part3]: /sudori-part3
  [sbt-remote-cache]: /sbt-remote-cache
  [sbt-remote-cache-with-bazel-compat]: /sbt-remote-cache-with-bazel-compat
  [7621]: https://github.com/sbt/sbt/pull/7621

This is a blog post on sbt 2.x development, continuing from [sudori part3][part3], [sbt 2.x remote cache][sbt-remote-cache], and [sbt 2.x remote cache with Bazel compatibility][sbt-remote-cache-with-bazel-compat]. I work on sbt 2.x in my own time with collaboration with the Scala Center. These posts are extended PR descriptions to share the features that will come to the future version of sbt, hopefully.

### August 2024 status quo

Since April, 2024, we have had Bazel-compatible remote cache capability. The implementation currently supports file output as a cached side effect. In other words, even if we start from a fresh machine, if the remote cache is hydrated, we can download JAR files from the cache instead of running the compiler.

In practice, however, we actually need to support arbitrary number of files in a directory to support incremental compilation. There are other potentially other avenues too, but I think supporting directory is the safe next step.

#### file directory problem

Caching of a file directory hits on a number of caching issues outlined in the [sbt 2.x remote cache][sbt-remote-cache] post:

1. A file directory can just be a relative path, a unique proof of the directory, or a materialized actual directory in the file system
2. An actual file directory may contain an arbitrary number of files
3. We don't want to make too many network calls to cache a directory

### declaring the outputs

In [sbt/sbt#7621][7621], I'm introducing a new output called `Def.declareOutputDirectory`:

```scala
Def.declareOutputDirectory(dir)
```

This would be called from within a task to declare a directory output. This is different from the return type of tasks. For example, the `compile` task returns an `Analysis`, but it generates `*.class` files on the side, which downstream tasks expects to be there in some agreed-upon directory. Declaration makes this process a bit more explicit. Here's an example usaga:

```scala
import sjsonnew.BasicJsonProtocol.given

lazy val someKey = taskKey[Int]("")

someKey := (Def.cachedTask {
  val conv = fileConverter.value
  val dir = target.value / "foo"
  IO.write(dir / "bar.txt", "1")
  val vf = conv.toVirtualFile(dir.toPath())
  Def.declareOutputDirectory(vf)
  1
}).value
```

#### setting up NativeLink cache

[NativeLink][nativelink] is a relatively new Bazel remote execution backend implementated in Rust with emphasis on performance. It's open source, and also has NativeLink Cloud, available for free trial, which my friend Adam Singer has been telling me about.

1. To enable remote caching, add `addRemoteCachePlugin` to `project/plugins.sbt`.
2. From <https://app.nativelink.com/>, go to Quickstart and take note of the URLs and `--remote_header`.
3. Create a file called `$HOME/.sbt/nativelink_credential.txt` and put in the API key:

```
x-nativelink-api-key=*******
```

The sbt 2.x configuration would look like this:

```scala
Global / remoteCache := Some(uri("grpcs://something.build-faster.nativelink.net"))
Global / remoteCacheHeaders += IO.read(BuildPaths.defaultGlobalBase / "nativelink_credential.txt").trim
```

See [sbt 2.x remote cache with Bazel compatibility][sbt-remote-cache-with-bazel-compat] for other remote cache solutions.

#### running the task

Given the setup, we can now try running the `someKey` task:

```scala
> someKey
[success] elapsed time: 1 s, cache 0%, 1 onsite task
> exit
```

Next, we want to wipe out the local cache, and see if we can recover the directory:

```bash
$ rmtrash $HOME/Library/Caches/sbt/v2/ && rmtrash target
$ sbt
> someKey
[success] elapsed time: 1 s, cache 100%, 1 remote cache hit
> exit
$ tree target/out/jvm/scala-3.4.2/dirtest/
target/out/jvm/scala-3.4.2/dirtest/
├── aaa
│   └── bbb.txt -> $HOME/Library/Caches/sbt/v2/cas/sha256-6b86b273ff34fce19d6b804eff5a3f5747ada4eaa22f1d49c01e52ddb7875b4b-1
└── aaa.sbtdir.zip -> $HOME/Library/Caches/sbt/v2/cas/sha256-b8e8af292865273d51e6ab681d52cc2410cd6e4d33aa563f6e691b8cd3c6e665-904
$ cat target/out/jvm/scala-3.4.2/dirtest/aaa/bbb.txt
1
```

This shows that `aaa` directory was recovered from the remote cache.

### Implementation details

In short, I've emulated the directory caching by actually creating a `.zip` file called `aaa.sbtdir.zip` and caching the zip file instead. This allows us to deal with a concrete file that can be hashed for caching and reuse the same mechanism as `Def.declareOutput`.

#### macro expansion of outputs

Before going into the directories, let's recap how a cached task works with an output. Supposed we have something like the follows:

```scala
Def.cachedTask {
  val vf = StringVirtualFile1("a.txt", "foo")
  Def.declareOutput(vf)
  name.value + version.value + "!"
}
```

In the macro, this expands to the following function calls:

```scala
i.mapN((wrap(name), wrap(version)), (q1: String, q2: String) => {
  var o1: VirtualFile = _
  ActionCache.cache[(String, String), String](
    key = (q1, q2),
    otherInputs = 0): input =>
      val vf = StringVirtualFile1("a.txt", "foo")
      o1 = vf
      InternalActionResult(q1 + q2 + "!", List(o1))
})
```

Note how `Def.declareOutput(vf)` expands into three different places:

1. declaration of a synthetic variable `var o1: VirtualFile`
2. `Def.declareOutput(vf)` becomes simple assignment `o1 = vf`
3. Later, `o1` is passed into `InternalActionResult`, which is passed into `ActionCache.cache`.

What I did for `Dec.declareOutputDirectory` is mostly the same:

1. declaration of a synthetic variable `var o1`
2. `Def.declareOutputDirectory(vf)` becomes assignment `o1 = ActionCache.packageDirectory(vf)`
3. Later, `o1` is passed into `InternalActionResult`, which is passed into `ActionCache.cache`.

Inside of the `ActionCache.packageDirectory` we can create a zip file.

#### acting on the effect

So far all we have is a zip file caching. Next, I've included a manifest file in the zip:

```bash
$ unzip -p target/out/jvm/scala-3.4.2/dirtest/aaa.sbtdir.zip sbtdir_manifest.json | jq
{
  "version": "0.1.0",
  "outputFiles": [
    "${OUT}/jvm/scala-3.4.2/dirtest/aaa/bbb.txt>sha256-6b86b273ff34fce19d6b804eff5a3f5747ada4eaa22f1d49c01e52ddb7875b4b/1"
  ]
}
```

This lists all the items in the directory and their content hashes. When sbt comes across an output whose name ends with `.sbtdir.zip`, it will open this manifest file, compare the SHA-256 hash against the existing files and sync it using the disk cache. This means that if we come across the same item more than once, which we will during compilation etc, we will cache it once centrally rather than overwriting it each time.

### case study: compile task

Previous implementation of the `compile` task in [sbt 2.x remote cache][sbt-remote-cache] was based on the idea of creating a JAR file minus the resource files. Going back to using directory makes the implementation simpler:

```scala
val analysisResult = Retry(compileIncrementalTaskImpl(bspTask, s, ci, ping))
....

val dir = ci.options.classesDirectory
val vfDir = c.toVirtualFile(dir)
val packedDir = Def.declareOutputDirectory(vfDir)
(analysisResult.hasModified(), vfDir: VirtualFileRef, packedDir: HashedVirtualFileRef)
```

Since this would upload a `zip` file, effectively it would be similar to creating a JAR file, except we now have individual files unzipped in a machine-independent fashion.

#### beware the hermeticity breakage

The `compile` task example reminds me of a potential pitfall with `Def.declareOutputDirectory` when used with `Def.cachedTask(...)`, which is that if we're not careful, we could end up breaking the hermeticity. Specifically in this case, we could end up reusing an old, incorrect cache.

This is because `VirtualFileRef` that represents the directory name will not contain the hash information of the content, which does not contain enough information to invalidate the downstream tasks. For example, if a cached task `foo` produces a directory and passes it to another cached task `bar`, passing `VirtualFileRef` alone will not be a sufficient cache.

```scala
// bad
foo := (Def.cachedTask {
  val dir = target.value / "foo"
  ....
  val vfDir = c.toVirtualFile(dir)
  Def.declareOutputDirectory(vfDir)
  vfDir // returning VirtualFileRef may not be safe here
}).value

bar := (Def.cachedTask {
  val vfDir = foo.value
  ....
}).value
```

To workaround this, `Def.declareOutputDirectory` returns `VirtualFile` for the synthetic zip file, which does contain the hash, and should be able to invalidate the downstream.

```scala
// good
foo := (Def.cachedTask {
  val dir = target.value / "foo"
  ....
  val vfDir = c.toVirtualFile(dir)
  val packedDir = Def.declareOutputDirectory(vfDir)
  (vfDir, packedDir)
}).value

bar := (Def.cachedTask {
  val (vfDir, _) = foo.value
  ....
}).value
```

### summary

In [sbt/sbt#7621][7621] introduces a new output called `Def.declareOutputDirectory(...)` that can produce arbitrary number of files from a cached task. The intent of the output is to port sbt 1.x tasks, such as incremental compilation easily.

This internally produces a zip file, and any Bazel remote cache implementations should support this feature. However, special care must be taken to pass a directory to other cached tasks to avoid breaking hermeticity.

----

### Donate to Scala Center

Scala Center is a non-profit center at EPFL to support education and open source. Please consider [donating](https://scala.epfl.ch/donate.html) to them, and publicly tweet/toot at @eed3si9n and @scala_lang when you do (I don't work for them, but we maintain sbt together).
