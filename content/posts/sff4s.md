---
title:       "sff4s: simple future facade for Scala"
type:        story
date:        2011-08-29
changed:     2012-01-16
draft:       false
promote:     true
sticky:      false
url:         /sff4s
aliases:     [ /node/39 ]
---

I wish there was a common super trait for various future implementations in the standard library, so I can express the concept without tying the code to a specific platform stack. I am not sure if there are others who feel the same, but I think it would be useful for library authors. That's my motivation of writing [sff4s](https://github.com/eed3si9n/sff4s).

what is future?
---------------
You've probably come across the notion before but let's go over it quickly. A future value (also known as promise) represents an incomplete calculation.

- a future value represents incomplete calculation.

That's the explanation often given, but not very useful. What's implied here, is that the calculation is going on in the background. It could be on your computer in another thread, it could be on some server, or maybe it's been queued and hasn't started yet. But the idea is that the calculation is taking place somewhere outside of your current flow of control.

- the calculation happens elsewhere.

Another aspect of a future value, is that you are able to eventually get hold of the calculated result. In Scala, this requires an explicit step of calling something like `def apply()`. In case the calculation is not complete, it will block. In other words, you will wait till the result comes back (or time out).

- the calculation result can be obtained from a future value.

So initially, when the future value is declared the calculation result may or may not exist yet, and at some point in time hopefully, a result arrives and changes the internal structure of the object, which is called "resolving" the future value. This is a bit creepy because not too many things in programming construct changes its state on its own.

- there's a backdoor to resolve the calculation result.

So far we've described the simplest form of future value. In reality there are other features added to make it more useful, but it's still good enough. Let's see some usage:

```scala
val factory = sff4s.impl.ActorsFuture
val f = factory future {
  Thread.sleep(1000)
  1
}
f() // => This blocks for 1 second and returns 1
```

Don't worry about the details, but see the behavior of the last line. The act of retrieving the calculation result is sometimes called "forcing." So the minimal API would look like this.

Future v0.1
```scala
abstract class Future[+A] {
  /** blocks indefinitely to force the calculation result */
  def apply(): A
}
```

There are several implementations of future values available in Scala, but they are all written from the ground up. If there were a common trait like the above, I can write stack independent code.

is it here yet?
---------------
Future v0.1 is too inconvenient because the only thing it can would block till the calculation result comes back. Might as well not use future if we have to wait for it. So another thing that all future value provides is a non-blocking way to check if the result is ready for retrieval. This is called `isDone`, `isSet`, `isDefined`, `isCompleted` depending on the implementation, but they all mean the same thing. For now I like `def isDefined: Boolean` because then I can think of Future conceptually as an `Option` variable.

- non-blocking way to check if the calculation result is ready.

Future v0.2
```scala
abstract class Future[+A] {
  def apply(): A
  
  /** checks if the result ready */
  def isDefined: Boolean
}
```

timeout
-------
Another common feature is the ability to block for finite duration of time. This could be `def apply(timeoutInMsec: Long)`. If the calculation does not come back in the designated amount of time `TimeoutException` would be thrown.

- block for finite duration of time to force the result.

Future v0.3
```scala
abstract class Future[+A] {
  def apply(): A
  
  def apply(timeoutInMsec: Long): A
  
  def isDefined: Boolean
}
```

This feels minimal, but it's at least usable at this state.

event callback
--------------
So the problem with the timeout approach is that these operations could take a long time to complete and you'd rather not manage a bunch of loops polling for the results to come back. A simpler solution is to pass in a callback closure, so the future can call you when the calculation result is ready. Now we are talking asynchronously. I'm using `def onSuccess(f: A => Unit): Future[A]` from twitter's future. Let's look at the usage code:

```scala
f onSuccess { value =>
  println(value) // => prints "1"
}
```

Thanks to call-by-name, Scala does not execute the block of code right way.
Also note that it just adds an event handler to the future value, but it does not change the calculated value itself.

error handling
--------------
I guess it's obvious we are going to talk about failures since the last event callback was named `onSuccess`. Before that recall a point from earlier section: the calculation happens elsewhere. So let's say it's happening in a background thread, and some exception gets thrown. What then? Should it throw the exception in the middle of your current flow of control? Probably not. It's like the proverbial tree falling. What happens is that all exceptions are captured into an internal state, and is replayed when the value is forced by `apply()`.

The idiomatic way of expressing this notion is `Either` in Scala. Since the parameterized type `Future[A]` doesn't say what kind of errors it could potentially throw, I picked `Either[Throwable, A]`.

- any error during the calculation is captured into a state.

This opens up a way for error handling callback `def onFailure(rescueException: Throwable => Unit): Future[A]`. In terms of implementation, both `onSuccess` and `onFailure` is a specific variation of general callback called `def respond(k: Either[Throwable, A] => Unit): Future[A]`.

- event callback can notify when the result is ready (success or fail).

Since the error state is captured as `Either`, the forcing is implemented as `def get: Either[Throwable, A]`, and `apply()` just called it as follows:

```scala
def apply(): A = get.fold(throw _, x => x)
```

Future v0.4:
```scala
abstract class Future[+A] {
  def apply(): A = get.fold(throw _, x => x)
  def apply(timeoutInMsec: Long): A = get(timeoutInMsec).fold(throw _, x => x)
  
  def isDefined: Boolean
    
  /** forces calculation result */
  def get: Either[Throwable, A]
  def get(timeoutInMsec: Long): Either[Throwable, A]
  
  def value : Option[Either[Throwable, A]] =
    if (isDefined) Some(get)
    else None  
  
  /** invoke callback when the calculation is ready */
  def respond(k: Either[Throwable, A] => Unit): Future[A]  
  
  def onSuccess(f: A => Unit): Future[A] =
    respond {
      case Right(value) => f(value)
      case _ =>
    }
    
  def onFailure(rescueException: Throwable => Unit): Future[A] =
    respond {
      case Left(e) => rescueException(e)
      case _ =>
    }
}
```

It's looking better. In fact these features are already beyond the basics provided by [`java.util.concurrent.Future`][3], I had to supply my own implementation.

monadic chaining
----------------
We can (finally) talk about doing something with actual future. So far we've discussed getting the calculation result out, but that's still present value. A cooler thing would be to actually use the future value before it's available and calculate another future value. [Using the value from one thing to compute another thing][6]... it must be a monad. Usage code!

```scala
val g = f map { _ + 1 }
```

We kind of know what `f()` is going to resolve to because we typed it in, but pretend you don't for now. So here we have an unknown `Future[Int]`. Whatever the value is, add 1 to it. This becomes another unknown future value. If `f` for some reason failed, now the whole thing would fail too, just like mapping `Option`.

We can also put these into for expression:

```scala
val xFuture = factory future {1}
val yFuture = factory future {2}

for {
  x <- xFuture
  y <- yFuture
} {
  println(x + y) // => prints "3"
}
```

Let me just write out the signature of these
```scala
  def foreach(f: A => Unit)
  def flatMap[B](f: A => Future[B]): Future[B]
  def map[B](f: A => B): Future[B]
  def filter(p: A => Boolean): Future[A]
```

select and join
---------------
I've also added two more interesting methods taken from twitter's Future, called `select(other)` and `join(other)`.
`select` (also known as `or`) takes another `Future` as a parameter, and returns the first one to succeed.

Similarly, `join` takes another `Future` as a parameter, and combines it into one `Future`.

Future v0.5:
```scala
abstract class Future[+A] {
  def apply(): A = get.fold(throw _, x => x)
  def apply(timeoutInMsec: Long): A = get(timeoutInMsec).fold(throw _, x => x)
  def isDefined: Boolean
  def get: Either[Throwable, A]
  def get(timeoutInMsec: Long): Either[Throwable, A]
  def value : Option[Either[Throwable, A]] =
    if (isDefined) Some(get)
    else None  
  def respond(k: Either[Throwable, A] => Unit): Future[A]  
  def onSuccess(f: A => Unit): Future[A] =
    respond {
      case Right(value) => f(value)
      case _ =>
    }
  def onFailure(rescueException: Throwable => Unit): Future[A] =
    respond {
      case Left(e) => rescueException(e)
      case _ =>
    }
  
  def foreach(f: A => Unit)
  def flatMap[B](f: A => Future[B]): Future[B]
  def map[B](f: A => B): Future[B]
  def filter(p: A => Boolean): Future[A]
  
  def select[U >: A](other: Future[U]): Future[U]
  def or[U >: A](other: Future[U]): Future[U] = select(other)
  def join[B](other: Future[B]): Future[(A, B)] 
}
```

Now we have a decent abstraction of a future value.

consumer and producer
---------------------
Before we get into how to create a future value, I'd like to set things up by discussing the background.
Future values represent incomplete calculations. The calculation is first requested by a consumer, and is later resolved by a producer. In other words, future value is mostly a read-only value from the consumer's perspective, but it needs to be a writable data structure for the producer. `Future` we've defined so far is a former one.

This has something to do with difference in different systems' usage. For the most part, [`java.util.concurrency.Future`][2], [`actors.Future`][3], and [`akka.dispatch.Future`][4] are there for offloading user-driven calculations to another CPU core or  machine. For these systems, resolution step is opaque to the API. It just happens internally.

On the other hand, [`com.twitter.util.Future`][5] does not provide concurrency mechanism, and you are responsible for playing both consumer and the producer. In other words, you have the control over what goes on in the producer side.

dispatcher
----------
sff4s provides dispatcher objects for the four future implementations mentioned above. They define `future` method which dispatches calculation to the underlying system. Recall the first usage code:

```scala
val factory = sff4s.impl.ActorsFuture
val f = factory future {
  Thread.sleep(1000)
  1
}
```

This internally calls [`scala.acotors.Futures`][7]' `future` method to dispatch the block.
Note `sff4s.impl.TwitterUtilFuture`'s `future` method would result to unimpressive result if you're expecting asynchronous behavior like that of `ActorsFuture`.

implicit conversion
-------------------
The dispatchers also implement implicit converters to turn a native future value into a wrapped one.

```scala
import factory._
val native = scala.actors.Futures future {5}
val w: sff4s.Future[Int] = native
w() // => This blocks for the futures result (and eventually returns 5)
```

feedbacks?
----------
I just wrote sff4s in the last several days, so there may be some bug fixes and changes down the line.
Let me know what you think.

  [1]: https://github.com/twitter/util/blob/master/util-core/src/main/scala/com/twitter/util/Future.scala
  [2]: http://www.scala-lang.org/api/current/scala/actors/Future.html
  [3]: http://download.oracle.com/javase/6/docs/api/java/util/concurrent/Future.html
  [4]: http://akka.io/api/akka/1.1/akka/dispatch/Future.html
  [5]: http://twitter.github.com/util/util-core/target/site/doc/main/api/com/twitter/util/Future.html
  [6]: http://www.codecommit.com/blog/ruby/monads-are-not-metaphors
  [7]: http://www.scala-lang.org/api/current/scala/actors/Futures$.html
