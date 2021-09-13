---
title:       "keeping promise in sbt"
type:        story
date:        2020-05-12
draft:       false
promote:     true
sticky:      false
url:         /promise-in-sbt
aliases:     [ /node/333 ]
tags:        [ "sbt" ]
---

build.sbt is a DSL for defining a task graph to be used for automatic parallel processing. The message passing among the tasks are expressed using `something.value` macro, which encodes Applicative composition `(task1, task2) mapN { case (t1, t2) => .... }`.

One mechanism I've been thinking about is allowing some long-running `task1` to communicate with `task2` midway.

![promise](/images/promise-01.png)

Normally, we would break down `task1` into two subtasks. But it might not be as straight-forward to implement such thing. For example, how would be tell Zinc to compile something halfway, and resume later? Or tell Coursier to resolve, but fetch later?

As a starting point, we could think of a solution where `task1` generates some JSON file, and `task2` can try to wait until the file appears, and read from it. We can improve this by replacing JSON file with a concurrent data structure, such as `Promise[A]`. Still there's the complication of waiting. sbt limits the number of tasks that would run in parallel, and it would be wasteful to use a slot for waiting. Daniel's [Thread Pools](https://gist.github.com/djspiewak/46b543800958cf61af6efa8e072bfd5c) post is informative in this regard. What we have is a blocking IO polling that won't do any work.

### Def.promise

I've implemented a wrapper around `scala.concurrent.Promise` called `Def.promise`. Here's an example usage:

<scala>
val midpoint = taskKey[PromiseWrap[Int]]("")
val longRunning = taskKey[Unit]("")
val task2 = taskKey[Unit]("don't call this from shell")
val joinTwo = taskKey[Unit]("")

// Global / concurrentRestrictions := Seq(Tags.limitAll(1))

lazy val root = (project in file("."))
  .settings(
    name := "promise",
    midpoint := Def.promise[Int],
    longRunning := {
      val p = midpoint.value
      val st = streams.value
      st.log.info("start")
      Thread.sleep(1000)
      p.success(5)
      Thread.sleep(1000)
      st.log.info("end")
    },
    task2 := {
      val st = streams.value
      val x = midpoint.await.value
      st.log.info(s"got $x in the middle")
    },
    joinTwo := {
      val x = longRunning.value
      val y = task2.value
    }
  )
</scala>

First, we create a `PromiseWrap[Int]` task called `midpoint`. This is still a task because we need a fresh promise for each command invocation. Next we have `longRunning` task, which completes the promise halfway. `task2` depends on `midpoint.await.value`. This means that sbt's task scheduler won't start `task2` until `midpoint` promise is completed.

To run both `longRunning` and `task2` together, we define `joinTwo` task. This runs as follows:

<code>
sbt:promise> joinTwo
[info] start
[info] got 5 in the middle
[info] end
</code>

As you can see above, we were able to run both tasks in parallel while letting `longRunning` task pass message to `task2`.

**Warning**: If you call `task2` from the shell, it will be blocked forever and will not return. You'd have to Ctrl-C to cancel out of it.

### summary

`Def.promise` [sbt/sbt#5552](https://github.com/sbt/sbt/pull/5552) is a draft proposal to allow long-running tasks to pass message to another task. One of the potential use case for this is pipelining of subproject compilations.
