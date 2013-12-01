  [1]: https://groups.google.com/d/msg/simple-build-tool/1c7unObqjJ8/3Wr30wMWKwEJ
  [1001]: https://github.com/sbt/sbt/issues/1001

In this post, I will discuss the execution semantics and task sequencing in sbt 0.13. First we will cover the background, and then I will introduce a new experimental plugin `sbt-sequential` that adds sequential tasks.

## background

Mark said:

> The sbt model is to have your side effects be local to your task so that as long as dependencies are satisfied, the task can be executed whenever. The win is parallel by default and enabling faster builds in practice.

In other words, with sbt, the build definitions only define the dependencies between the tasks. The timing at which these tasks are triggered is automatically calculated by sbt. To understand this, we should first look at the execution semantics of a Scala code with side effects.

### serial execution

<scala>
class Test {
  def startServer(): Unit = {
    println("starting...")
    Thread.sleep(500)
  }
  def stopServer(): Unit = {
    println("stopping...")
    Thread.sleep(500)
  }
  def numberTask: Int = 1
  
  def integrationTest0(): Int = {
    val n = numberTask
    startServer()
    println("testing...")
    Thread.sleep(1000)
    stopServer()
    n
  }
}
</scala>

When someone calls `integrationTest0()` method, the code is executed in the exact order in which it is written. First `numberTask` is called, then `startServer()` is called, which takes 0.5 seconds to run. While it's running, the control is blocked until it returns. Then `println("testing...")` is called, and so on. Such execution with no switching of orders or overlap in execution is called *serial execution*.

### serializable execution

A program execution whose outcome is equivalent to that of a serial execution is said to be *serializable*. You can also say that such an execution is *semantically equivalent* to serial execution, or *as-if serial*.

For example, in `integrationTest0` method, `val n = numberTask` can be moved to after `startServer()` without changing the overall result. Moreover, the execution of `startServer()` can be interleaved with the execution `numberTask` (execute concurrently) without changing the outcome:

<scala>
class Test {
  def startServer(): Unit = {
    println("starting...")
    Thread.sleep(500)
  }
  def stopServer(): Unit = {
    println("stopping...")
    Thread.sleep(500)
  }
  def numberTask: Int = 1
  
  def integrationTest1(): Int = {
    startServer()
    val n = numberTask
    println("testing...")
    Thread.sleep(1000)
    stopServer()
    n
  }
}
</scala>

### concurrent execution

Here's how one might write a similar build definition using sbt. 

<scala>
val startServer = taskKey[Unit]("start server")
val stopServer = taskKey[Unit]("stop server")
val numberTask = taskKey[Int]("number task")
val integrationTest2 = taskKey[Int]("integration test")

startServer := {
  println("starting...")
  Thread.sleep(500)
}

stopServer := {
  println("stopping...")
  Thread.sleep(500)
}

numberTask := 1

integrationTest2 := {
  val n = numberTask.value
  startServer.value
  println("testing...")
  Thread.sleep(1000)
  stopServer.value
  n
}
</scala>

It looks ok, except the program execution is concurrent and out-of-order. In the above, `startServer`, `numberTask`, and `stopServer` tasks are executed in a concurrent context in the beginning of the task.  The execution may or may not happen in parallel, but the ordering is not guaranteed. The rest of the Scala code is executed when the dependent tasks come back. In sbt, one would try to construct task dependency graph instead of writing in imperative style, so this concurrent execution is normally not a problem.

### andFinally and doFinally

However, time and time again, the topic of sequencing tasks has come up in the mailing list, StackOverflow, conferences, and podcasts. Here are some of the samplings:

- [Sequential chaining operators for Initialize](https://groups.google.com/d/msg/simple-build-tool/Yg17YxQ2su0/NCjwZx6IAIwJ)
- [FYI found the way how to create wrapper for stb.Task[Unit] without dependsOn](https://groups.google.com/d/msg/simple-build-tool/7CMIQTCQdOY/u_uxTy0bWgMJ)
- [Concurrency semantics (aka task sequencing) in 0.13 syntax][1]

The current solution in sbt for sequencing tasks is to use normal task dependency `task.value` (or `dependsOn`). For cleanup sbt also provides `andFinally` and `doFinally`.

`andFinally` creates a new task by appending an arbitrary Scala block at the end:

<scala>
lazy val integrationTestBody = Def.task {
  startServer.value
  val n = 1
  Thread.sleep(2000)
  n
}

lazy val integrationTestImpl = integrationTestBody andFinally {
  println("stop")
  IO.delete(file("server.txt"))
}

integrationTest3 := integrationTestImpl.value
</scala> 

If the cleanup code is a task, there's `doFinally`:

<scala>
lazy val integrationTestBody = Def.task {
  startServer.value
  val n = 1
  Thread.sleep(2000)
  n
}

integrationTest4 <<= (integrationTestBody, stopServer) { (body, stop) =>
  body doFinally stop
}
</scala>

### addCommandAlias

If the objective is to run several tasks in a row as if it were typed in from the shell, sbt provides `addCommandAlias`, which defines a convenient alias for a group of commands. The following could be added to `build.sbt`:

<scala>
addCommandAlias("sts", ";startServer;test;stopServer")
</scala>

You then type `sts` from the sbt shell and it would issue the said tasks one after the other.

One of the above links was a post by me on the old sbt mailing list, and it was recently mentioned an interesting discussion on github [Make it easier to control the sequencing of Tasks (#1001)][1001].

## sbt-sequential

sbt-sequential is an implmenetation of "sequential" macro I outlined in the [ML thread][1] and [#1001][1001]. (At the time of proposing, I didn't think just how complicated it would be to write such a macro.)

sbt-sequential injects `sequentialTask[T](t: T)` method to `sbt.Def` object, which enables sequential tasks. For instance, the above `integrationTest2` can be rewritten as follows:

<scala>
val startServer = taskKey[Unit]("start server")
val stopServer = taskKey[Unit]("stop server")
val numberTask = taskKey[Int]("number task")
val integrationTest5 = taskKey[Int]("integration test")

startServer := {
  println("starting...")
  Thread.sleep(500)
}

stopServer := {
  println("stopping...")
  Thread.sleep(500)
}

numberTask := 1

val integrationTestImpl = Def.sequentialTask {
  val n = numberTask.value
  startServer.value
  println("testing...")
  Thread.sleep(1000)
  stopServer.value
  n
}

integrationTest5 := integrationTestImpl.value
</scala>

The execution ordering of `integrationTest5` emulates serial execution. In this particular example, the observed outcome of the side effects should be identical to that of serial execution. Unlike plain tasks, the execution is blocked after each line.

This is achieved by automatically transforming the code passed to `Def.sequentialTask` block (that's what macros in general do). The transformation wraps each line in an artificial task, and then flatMaps them all to execute them in sequence.

### task dependencies

`Def.sequentialTask` keeps the task dependencies intact. It will not introduce new dependencies between the tasks referenced in the block, and more importantly, it will not remove prior depedencies among them.

If for some reason `startServer` task depended on `stopServer` task for example, `stopServer` will be executed before `startServer`, and executed only once.

### granularity of serialization

In a programming language with serial semantics, there's usually an explicit left-to-right ordering of the expressions. For example, if you called a function `f` with three arguments like `f(arg0, arg1, arg2)`, `arg0` is evaluated first.

Because sbt-sequential wraps each line, or the top-level expressions to be exact, it does not attempt to serialize the sub expressions. In other words, if there were `f(arg0.value, arg1.value, arg2.value)`, all tasks are executed in parallel. To work around this, you need to define vals.

### flatMap

The implementation of macro was inspired by Mark's comment in [#1001][1001]:

> Implementing sequence is straightforward, you just need `flatMap` (or `taskDyn`) just like with futures:

<scala>
def sequence(tasks: List[Initialize[Task[Unit]]]): Initialize[Task[Unit]] =
  tasks match {
    case Nil => Def.task{ () }
    case x :: xs => Def.taskDyn { val _ = x.value; sequence(xs) }
  }
</scala>

More explanation of `taskDyn` can be found at [Dynamic Computations with Def.taskDyn](https://github.com/sbt/sbt/blob/818f4f96fb4885adf8bbd2f43c2c1341022d22b2/src/sphinx/Detailed-Topics/Tasks.rst#dynamic-computations-with-deftaskdyn):

> It can be useful to use the result of a task to determine the next tasks to evaluate. This is done using `Def.taskDyn`. The result of `taskDyn` is called a dynamic task because it introduces dependencies at runtime. 

### expanded code

The expanded code conceptually looks like this:

<scala>
// before
val integrationTestImpl = Def.sequentialTask {
  val n = numberTask.value
  startServer.value
  println("testing...")
  Thread.sleep(1000)
  stopServer.value
  n
}

// after
val integrationTestImpl: Def.Initialize[Task[Int]] = {
  var v0: Int = 0
  val t0 = Def.task { v0 = startServer.value; () }
  val t1 = Def.taskDyn { val _ = t0.value; Def.task { startServer.value; () } }
  val t2 = Def.taskDyn { val _ = t1.value; Def.task { println("testing..."); () } }
  val t3 = Def.taskDyn { val _ = t2.value; Def.task { Thread.sleep(1000); () } }
  val t4 = Def.taskDyn { val _ = t3.value; Def.task { stopServer.value; () } }
  Def.taskDyn { val _ = t4.value; Def.task { v0 } }
}
</scala>

As you can see, the code looks similar to Mark's `sequence` using `Def.taskDyn`. The difference is that I'm able to mix in plain Scala code, and also keep the type `Def.Initialize[Task[Int]]` at the end.

I also had to convert `val n` into `var v0` so it could be referenced from both `t0` and the last `Def.taskDyn`.

To debug the macro exapansion quickly, I've added `Def.debugSequentialTask`. This rewrites the code, and then it throws the result as an exception. Try it to see further macro expansions.

### summary

sbt's task dependency graph allows us to create flexible build definitions that runs in a concurrent execution ordering. While it works fine in most cases, occasionally we would like to execute tasks in a blocking, sequential order.

sbt-sequential adds `Def.sequentialTask` which automatically expands tasks and Scala code to series of flatMaps. Given the nature of this macro, it may not work for complex code, but it is able to fire and block independent tasks and Scala code in order.
