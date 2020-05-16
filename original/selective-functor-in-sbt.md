  [Mokhov2018]: https://www.microsoft.com/en-us/research/uploads/prod/2018/03/build-systems.pdf
  [Mokhov2019]: https://www.staff.ncl.ac.uk/andrey.mokhov/selective-functors.pdf
  [Birchall]: https://github.com/cb372/cats-selective/blob/a1f4c0e19a1a90b5b27dd502f5a83f35dbec477d/core/src/main/scala/cats/Selective.scala
  [core]: https://www.youtube.com/watch?v=-shamsTC7rQ
  [core_matsuri]: https://www.youtube.com/watch?v=mY7zu21Cceg
  [Hood2018]: https://youtu.be/s_3qLMSGHkI?t=631

In [sbt core concepts][core] talks I've been calling sbt a casually functional build tool. Two hallmarks of functional programming is that it uses immutable data structure instead of mutation, and that it gives attention to when and how effects are handled.

### settings and tasks

From this perspective, we can think of setting expressions and tasks to be those two things:

- Settings form an immutable graph in a build.
- Tasks represent effects.

Anonymous settings are represented using `Initialize[A]`, which looks like this:

<scala>
  sealed trait Initialize[A] {
    def dependencies: Seq[ScopedKey[_]]
    def evaluate(build: BuildStructure): A // approx
    ....
  }
</scala>

Named settings are represented with `Setting` class:

<scala>
  sealed class Setting[A] private[Init] (
      val key: ScopedKey[A],
      val init: Initialize[A],
      val pos: SourcePosition
  ) ....
</scala>

`sbt.Task` is can be seen as a wrapper around side effect function `() => A`. However when we say "compile is a task." The task in this context is represented using `Initialize[Task[A]]`. They are settings of type `Task[A]`.

We can confirm this by looking at the return type of `Def.task`, which is `Def.Initialize[Task[A]]`.

### Applicative composition

`Def.task` is a macro that encodes Applicative composition of tasks (`Def.Initialize[Task[A]]`s). Consider the following tasks `task1`, `task2`, and `task3`:

<scala>
lazy val task1 = taskKey[Int]("")
lazy val task2 = taskKey[Int]("")
lazy val task3 = taskKey[Int]("")

task1 := 1
task2 := 2

task3 := {
  val t1 = task1.value
  val t2 = task2.value
  t1 + t2
}
</scala>

If we write this out using tuple syntax, it looks like:

<scala>
task3 := ((task1, task2) map { case (t1, t2) =>
  t1 + t2
}).value
</scala>

This gives us a few information.

- `task1` and `task2` both happen-before `task3`
- `task1` and `task2` are causally independent form each other

This allows the task scheduler to run `task1` and `task2` in parallel if the CPU cores are available. In addition sbt can introspect the graph and provide display the task dependencies:

<code>
sbt:selective> inspect tree task3
[info] task3 = Task[Int]
[info]   +-task1 = Task[Int]
[info]   +-task2 = Task[Int]
</code>

It sometimes helps to do a thought experiment to visualize things. Ignoring pandemic for now, let's say a relative is flying in and picking them up would take 1~2 hours. You also want to make a nice dinner, and say that takes 2h too. If you have a partner, one can do the airport run and the other person can do the cooking to utilize time. In the end, you both need the dinner cooked and the relative picked up to start the dinner.

### Monadic composition

What if we want use the result from a task to decide which task to run next? In sbt, we can use `Def.taskDyn` for this.

<scala>
lazy val condition = taskKey[Boolean]("")
lazy val trueAction = taskKey[Unit]("")
lazy val falseAction = taskKey[Unit]("")
lazy val foo = taskKey[Unit]("")

condition := true
trueAction := { println("true") }
falseAction := { println("false") }

foo := (Def.taskDyn {
  val c = condition.value
  if (c) trueAction
  else falseAction
}).value
</scala>

If we write expand the macro, it would look like this:

<scala>
foo := (condition flatMap { c =>
  if (c) trueAction
  else falseAction
}).value
</scala>

This is more powerful from the point of view of the build author. But there are some drawbacks.

1. `foo` is blocked on `condition` task. This is exactly what we wanted, but it also means we could lose some parallelism because of it.
2. We lose the ability to introspect the task graph.

<code>
sbt:selective> inspect tree foo
[info] foo = Task[Unit]
[info]   +-condition = Task[Boolean]
[info]   +-Global / settingsData = Task[sbt.internal.util.Settings[sbt.Scope]]
</code>

Note that `trueAction` and `falseAction` are missing from the inspect tree result.

To avoid this problem, we would need to move the `if` condition into the implementation of the task itself. This is not always desirable when we are trying to compose tasks. I've heard this tention of Applicative and Monad composition in the context of the build tools discussed in ScalaSphere 2018 [Incrementalism and Inference in Build Tools][Hood2018] talk by Stu Hood. Looking back, he was citing Andrey Mokhov's [Build Systems à la Carte][Mokhov2018] paper.

Going back to the dinner example, let's say it's your cousin. You want to ask him if he's ok with pasta at home or go to a Moroccan restaurant otherwise. Either case, we can't start cooking until he arrives from the airport. This is the tradeoff between flexibility and parallelism. We certainly can't do 2h roasting.

### Selective applicative functor

In April 2019, Dale told me about [Build Systems à la Carte][Mokhov2018] and [Selective applicative functor][Mokhov2019] paper also by Andrey Mokhov. I've never heard of `Selective`, and was curious how its benefit can be translated to sbt.

Here's `Selective` as defined in Chris Birchall's [cats-selective][Birchall]:

<scala>
trait Selective[F[_]] {
  def select[A, B](fab: F[Either[A, B]])(fn: F[A => B]): F[B]
  
  ...
}
</scala>

The semantics is that if `fab` contains `Right(b)` it returns as-is, and applies `fn` when it contains `Left(a)`, all in the context of `F[_]`. Using this as a building block, Mokhov shows that we can encode `if` functor. (See [cats-selective][Birchall]):

<scala>
trait Selective[F[_]] {
  def select[A, B](fab: F[Either[A, B]])(fn: F[A => B]): F[B]
  def branch[A, B, C](x: F[Either[A, B]])(l: F[A => C])(r: F[B => C]): F[C] = ...
  def ifS[A](x: F[Boolean])(t: F[A])(e: F[A]): F[A] = ....
}
</scala>

The paper claims that the benefit of `Selective` is that we can express conditional task without giving up inspect. How is this possible?

The key is that `Selective` can be implemented in two different ways based on `Monad` or on `Applicative`, which gives different properties. This seems a bit unusual, but it's in the paper as well:

> One can implement `select` using monads in a straightforward manner ...

<scala>
// This is Scala implementation from cats-selective
def selectM[F[_]](implicit M: Monad[F]): Selective[F] =
  new Selective[F] {
    def select[A, B](fab: F[Either[A, B]])(fn: F[A => B]): F[B] =
      fab.flatMap {
        case Right(b) => M.pure(b)
        case Left(a)  => fn.map(_(a))
      }
  }
</scala>

> One can also implement a function with the type signature of `select` using applicative functors, but it will always execute the effects associated with the second argument, rendering any conditional execution of effects impossible...

<scala>
// This is Scala implementation
def selectA[F[_]](implicit Ap: Applicative[F]): Selective[F] =
  new Selective[F] {
    def select[A, B](fab: F[Either[A, B]])(fn: F[A => B]): F[B] =
      (fab, fn) mapN { case (ab, n) =>
        ab match {
          case Right(b) => Ap.pure(b)
          case Left(a)  => n(a)
        }
      }
  }
</scala>

> While `selectM` is useful for conditional execution of effects, `selectA` is useful for static analysis.

Going back to the dinner example, Selective is like beging ready for either chicken or vegetarian burger. Your cousin can pick from the two, and we won't start cooking until he's arrived but we'll know ahead of time for shopping.

### Selective composition of tasks

Here's how we can implement `foo` task using `Selective`:

<scala>
foo := (Def.ifS(condition)(trueAction)(falseAction)).value,
</scala>

Let's try running this:

<scala>
sbt:selective> foo
true
</scala>

It seems to work. How would `inspect` run?

<scala>
sbt:selective> inspect tree foo
[info] foo = Task[Unit]
[info]   +-condition = Task[Boolean]
[info]   +-falseAction = Task[Unit]
[info]   +-trueAction = Task[Unit]
</scala>

`inspect` works too.

Here's the implementation of `selectITask` in `Def`:

<scala>
  private[sbt] def selectITask[A, B](
      fab: Initialize[Task[Either[A, B]]],
      fin: Initialize[Task[A => B]]
  ): Initialize[Task[B]] =
    fab.zipWith(fin)((ab, in) => TaskExtra.select(ab, in))
</scala>

`fab.zipWith(fin)` is using Applicative semantics at the `Initialize[_]` layer. `TaskExtra.select(...)` is defined as follows:

<scala>
  def select[A, B](fab: Task[Either[A, B]], f: Task[A => B]): Task[B] =
    Task(newInfo(fab.info), new Selected[A, B](fab, f))
</scala>

At the construction, we're just capturing the effect and not doing anything. Right when the task engine is about to schedule this task, I reencode the `Selected` into a Monadic composition:

<scala>
  private[sbt] def asFlatMapped: FlatMapped[B, K] = {
    val f: Either[A, B] => Task[B] = {
      case Right(b) => std.TaskExtra.task(b)
      case Left(a)  => std.TaskExtra.singleInputTask(fin).map(_(a))
    }
    FlatMapped[B, K](fab, {
      f compose std.TaskExtra.successM
    }, ml)
  }
</scala>

In other words, the setting layer is composed applicatively, and the task layer is composed monadically to take advantage of both of the aspects of `Selective`.

### some use cases

We can try substituting some usages of `Def.taskDyn` using `Def.ifS`. Here's `dependencyResolutionTask`: 

<scala>
def dependencyResolutionTask: Def.Initialize[Task[DependencyResolution]] =
  Def.taskDyn {
    if (useCoursier.value) {
      Def.task { CoursierDependencyResolution(csrConfiguration.value) }
    } else
      Def.task {
        IvyDependencyResolution(ivyConfiguration.value, CustomHttp.okhttpClient.value)
      }
  }
</scala>

This prevents `dependencyResolution` task from getting inspected:

<code>
sbt:selective> inspect tree dependencyResolution
[info] dependencyResolution = Task[sbt.librarymanagement.DependencyResolution]
[info]   +-Global / settingsData = Task[sbt.internal.util.Settings[sbt.Scope]]
[info]   +-Global / useCoursier = true
</code>

We can rewrite `dependencyResolutionTask` as follows:

<scala>
def dependencyResolutionTask: Def.Initialize[Task[DependencyResolution]] =
  Def.ifS(useCoursier.toTask)(Def.task { CoursierDependencyResolution(csrConfiguration.value) })(
    Def.task { IvyDependencyResolution(ivyConfiguration.value, CustomHttp.okhttpClient.value) }
  )
</scala>

<code>
sbt:selective> inspect tree dependencyResolution
[info] dependencyResolution = Task[sbt.librarymanagement.DependencyResolution]
[info]   +-csrConfiguration = Task[lmcoursier.CoursierConfiguration]
[info]   | +-allCredentials = Task[scala.collection.Seq[sbt.librarymanagement.ivy.Credentials]]
[info]   | | +-Global / credentials = Task[scala.collection.Seq[sbt.librarymanagement.ivy.Credentials]]
[info]   | | +-allCredentials / streams = Task[sbt.std.TaskStreams[sbt.internal.util.Init$ScopedKey[_ <: Any]]]
[info]   | | | +-Global / streamsManager = Task[sbt.std.Streams[sbt.internal.util.Init$ScopedKey[_ <: Any]]]
[info]   | | |
[info]   | | +-credentials = Task[scala.collection.Seq[sbt.librarymanagement.ivy.Credentials]]
[info]   | |
....
</code>

Let's try another example.

<scala>
def publishTask(config: TaskKey[PublishConfiguration]): Initialize[Task[Unit]] =
  Def.taskDyn {
    val s = streams.value
    val skp = (publish / skip).value
    val ref = thisProjectRef.value
    if (skp) Def.task { s.log.debug(s"Skipping publish* for ${ref.project}") } else
      Def.task { IvyActions.publish(ivyModule.value, config.value, s.log) }
  } tag (Tags.Publish, Tags.Network)
</scala>

In this case we're using `Def.taskDyn` to skip the underlying publish task if `publish / skip` is true.

<scala>
def publishTask(config: TaskKey[PublishConfiguration]): Initialize[Task[Unit]] =
  Def.ifS((publish / skip).toTask)(Def.task {
    val s = streams.value
    val ref = thisProjectRef.value
    s.log.debug(s"Skipping publish* for ${ref.project}")
  })(Def.task {
    val s = streams.value
    IvyActions.publish(ivyModule.value, config.value, s.log)
  }) tag (Tags.Publish, Tags.Network)
</scala>

This should work as before, and we get `inspect` back.

### code as data

`Def.ifS` works as expected, but `Def.ifS(...)(...)(...)` looks a bit alien in Scala. In Scala it's more idiomatic to express if conditions using `if`. We can encode this by providing a simple def-macro called `Def.taskIf(...)`.

We can pass in either an `if`-expression or a block ending in an `if`, and then hoist the contents into `Def.ifS(...)(...)(...)`. Let's see how the example usages become:

<scala>
def dependencyResolutionTask: Def.Initialize[Task[DependencyResolution]] =
  Def.taskIf {
    if (useCoursier.value) Def.task { CoursierDependencyResolution(csrConfiguration.value) }
    else Def.task { IvyDependencyResolution(ivyConfiguration.value, CustomHttp.okhttpClient.value) }
  }

def publishTask(config: TaskKey[PublishConfiguration]): Initialize[Task[Unit]] =
  Def.taskIf {
    if ((publish / skip).value)
      Def.task {
        val s = streams.value
        val ref = thisProjectRef.value
        s.log.debug(s"Skipping publish* for ${ref.project}")
      }
    else
      Def.task {
        val s = streams.value
        IvyActions.publish(ivyModule.value, config.value, s.log)
      }
  } tag (Tags.Publish, Tags.Network)
</scala>

This would require some documentation to explain what's going on, but I think it's more approachable than `Def.ifS(...)(...)(...)`.

### more thoughts on Selective

In this post I focused on `ifS` combinator since that seems like a good entry point, but [Selective applicative functor][Mokhov2019] offers other combinators too.

<scala>
trait Selective[F[_]] {
  def select[A, B](fab: F[Either[A, B]])(fn: F[A => B]): F[B]
  def branch[A, B, C](x: F[Either[A, B]])(l: F[A => C])(r: F[B => C]): F[C] = ...
  def ifS[A](x: F[Boolean])(t: F[A])(e: F[A]): F[A] = ...
  def whenS[A](fbool: F[Boolean])(fa: F[Unit]): F[Unit] = ...
  def bindBool[A](fbool: F[Boolean])(f: Boolean => F[A]): F[A] = ...
  def fromMaybeS[A](fa: F[A])(fm: F[Option[A]]): F[A] = ...
  def orS(fbool: F[Boolean])(fa: F[Boolean]): F[Boolean] = ...
  def andS(fbool: F[Boolean])(fa: F[Boolean]): F[Boolean] = ...
  def anyS[G[_]: Foldable, A](test: A => F[Boolean])(ga: G[A]): Eval[F[Boolean]] = ...
  def allS[G[_]: Foldable, A](test: A => F[Boolean])(ga: G[A]): Eval[F[Boolean]] = ...
}
</scala>

I think `branch` is interesting. Internal to sbt, we abstract over arity using an interface called `AList[X[F[A]]]` when dealing with `Applicative`. Thinking along the line, `Either[A, B]` can be thought of the opposite of `Tuple2[A, B]`. In other words, `Either[A, B]` can be a building block toward handling Coproduct of `A1`, `A2`, `A3`...

In Scala, a related syntax here might be pattern match:

<scala>
something match {
  case pattern1 => Def.task { ... }
  case pattern2 => Def.task { ... }
  case pattern3 => Def.task { ... }
}
</scala>

If we had that, if-expression can be encoded on top of that.

### summary

Selective functor can facilitate conditional execution of tasks while keeping the ability to run `inspect` command.

Selective composition can be implemented in sbt as `Def.taskIf` macro:

<scala>
Def.taskIf {
  if (Boolean) Def.task { ... }
  else Def.task { ... }
}
</scala>

PR to sbt is [sbt/sbt#5558](https://github.com/sbt/sbt/pull/5558).
