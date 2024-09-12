---
title:       "RFC-4: persistent worker"
type:        story
date:        2024-09-10
draft:       false
url:         /rfc-4-persistent-worker
tags:        [ "sbt" ]
---

 [persistent_worker_spec]: https://bazel.build/remote/creating
 [JSON-RPC]: https://www.jsonrpc.org/
 [ForkMain]: https://github.com/sbt/sbt/blob/v1.10.1/testing/agent/src/main/java/sbt/ForkMain.java

- Author: Eugene Yokota
- Date: 2024-09-10
- Status: **Review**

See [RFC-2](/sbt-2.0-rfc-process) for the process. In [sbt 2.0 ideas](/sbt-2.0-ideas) I wrote:

> **idea 5: BSP support + persistent workers**
>
> To preventing blocking the sbt server, we should consider shipping off long-running tasks to persistent workers, similar to today’s `fork` or `bgRun`. The candidate tasks are `run`, `test`, and `console`, but `compile` could be one too.

I mostly had Bazel's [persistent worker specification][persistent_worker_spec] in my mind.

<!--more-->

## problem space

While task processing is processed in parallel, sbt fundamentally processes one command at a time, much like any other build tool that might run from the command line. This design has been serviceable during the early years.

- BSP responsiveness issue: Since the idea of sbt server has been proposed to handle requests from both human users and IDEs, we've known that blocking on all commands were inconvenient. While `test` runs, sbt cannot respond to Metals, which results in Metals shutting down sbt.
- JIT vs stability: This is a good segue into the process emulation that sbt 1.x performs. Instead of shelling out a new JVM each time, sbt 1.x creates a sandbox classloader for `test` and `run` and runs in the same JVM as the sbt process. This has the benefit of caching the HotSpot JITing. On the other hand, letting test run in the same JVM process causes various complication such as memory leak.

## persistent worker

I propose creating a generic persistent worker that can handle `run`, `test`, and `console` etc borrowing from Bazel's [persistent worker specification][persistent_worker_spec]. Similar to [ForkMain][ForkMain], a persistent worker is a command-line application, potentially written in Scala or Java.

A persistent worker upholds a few requirements:

1. It reads work requests from its stdin.
2. It writes work responses (and only work responses to its stdout.
3. It accepts the `--persistent_worker` flag.

Let's use [JSON-RPC](https://www.jsonrpc.org/).

### work request

A work request is a [JSON-RPC][JSON-RPC] call whose method can be `sbt/test`, `sbt/run` etc.

```json
{
  "jsonrpc": "2.0",
  "method": "sbt/test",
  "params": {
    "args": [],
    "classpath": [
      { "path": "/tmp/sandbox/coursier/scala-library.jar", "digest": "ab234aaaccc"},
      { "path": "/tmp/sandbox/jvm/scala-3.3.3/a/a.jar", "digest": "fdk3e2ml23d"},
      { "path": "/tmp/sandbox/jvm/scala-3.3.3/b/b.jar", "digest": "1fwqd4qdd" }
    ],
    "classLoaderLayeringStrategy": "AllLibraryJars"
  },
  "id": 12
}
```

The above is a hypothetical example with hypothetical list of parameters sbt server might pass to a persistent worker. This should contain all information needed for the test to run.

### work response

To sending back stdout, let's define `notify/stout` method as follows:

```json
{
  "jsonrpc": "2.0",
  "method": "notify/stdout",
  "params": {
    "value": "some test result\n",
    "ref": 12
  },
  "id": 15
}
```

The above shows that the stdout notification is for the id 12. Once the test succeeds we return the JSON-RPC result as `0`:

```json
{
  "jsonrpc": "2.0",
  "result": 0,
  "id": 12
}
```

### --persistent_worker

The persistent worker shuts down after processing a single after the test is done. When `--persistent_worker` is passed, the program stays up until it's shutdown.

### interaction with sbt client programs

sbt clients, either the traditional `sbt` or `sbt --client` should print out the `notify/stdout` to the stdout.

### the benefit of this approach

1. sbt server is no longer blocked on tests.
2. Test code is forked out into a different JVM.
3. We can keep the warmed classloaders.

## virtualized run

`sbt/general` request looks similar to the `sbt/test`:

```json
{
  "jsonrpc": "2.0",
  "method": "sbt/general",
  "params": {
    "args": [],
    "classpath": [
      { "path": "/tmp/sandbox/coursier/scala-library.jar", "digest": "ab234aaaccc"},
      { "path": "/tmp/sandbox/jvm/scala-3.3.3/a/a.jar", "digest": "fdk3e2ml23d"},
      { "path": "/tmp/sandbox/jvm/scala-3.3.3/b/b.jar", "digest": "1fwqd4qdd" }
    ],
    "classLoaderLayeringStrategy": "AllLibraryJars",
    "mainClass": "example.Main",
    "connectStdout": true,
    "connectStdin": true
  },
  "id": 16
}
```

The complication is that `stdin` would be emulated using JSON notification:

```json
{
  "jsonrpc": "2.0",
  "method": "notify/stdin",
  "params": {
    "value": "hi",
    "ref": 16
  },
  "id": 18
}
```

We can study `sbt --client` implementation to see how console was virtualized.

### difficulty

As I mentioned, we already have forking as well process emulation for `test` and `run`, so the implementation should hopefully be fairly straightforward to replicate one of them.

### persistent worker as a plugin task isolation

I've introduced `sbt/general` as a mechanism to offload user's program from the sbt process, but we can also envision doing the same for plugin tasks as well.

For example, if we want sbt-assembly to offload to a persistent worker, we can implement a command-line app that performs the `assembly` task, and pass all needed information via `sbt/general`:

```json
{
  "jsonrpc": "2.0",
  "method": "sbt/general",
  "params": {
    "args": ["@/tmp/sandbox/param.json"],
    "classpath": [
      { "path": "/tmp/sandbox/coursier/scala-library.jar", "digest": "ab234aaaccc"},
      { "path": "/tmp/sandbox/jvm/scala-2.12.19/com/eed3si9n/assembly.jar", "digest": "1122e2ml23d"}
    ],
    "inputs": [
      { "path": "/tmp/sandbox/jvm/scala-3.3.3/a/a.jar", "digest": "1fwqd4qdd" },
      { "path": "/tmp/sandbox/param.json", "digest": "e45feb34" }
    ],
    "outputs": [
      { "path": "/tmp/sandbox/output.jar" }
    ],
    "classLoaderLayeringStrategy": "AllLibraryJars",
    "mainClass": "com.eed3si9n.AssemblyMain",
    "connectStdout": false,
    "connectStdin": false
  },
  "id": 18
}
```

Note that the app just needs run on JVM, and it can use any Scala version, like Scala 2.12.19. This is a technique we actually used during sbt 0.13 to run Scalafix. See [downloading and running app on the side with sbt-sidedish](/sbt-sidedish).

### impact to the build users

The impact to the build users is hopefully minimal. They can keep writing test like they were as they did in sbt 1.x.

### use by other tools?

Some of the common operations among build tools like creating assembly or publishing to Maven Central could be implemented using `sbt/general`. This could open up a possibility of a common plugin mechanism.

### concurrency

Similar to forked tests, we could consider having multiple persistent workers, and each worker handling multiple concurrent tests or tasks. This is something we can tune as needed.

## feedback

I created a discussion thread <https://github.com/sbt/sbt/discussions/7653>.
