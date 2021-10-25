---
title:       "stricter Scala with -Yno-lub"
type:        story
date:        2015-09-30
draft:       false
promote:     true
sticky:      false
url:         /stricter-scala-with-ynolub
aliases:     [ /node/183 ]
tags:        [ "scala" ]
---

  [1]: http://days2011.scala-lang.org/sites/days2011/files/41.%20Effective%20Scala.pdf
  [2]: http://rapture.io/talks/inference/boston.html
  [lubSource]: https://github.com/scala/scala/blob/v2.11.7/src/reflect/scala/reflect/internal/tpe/GlbLubs.scala#L299-L300

For a flexible language like Scala, it's useful to think of subset of the programming language, like your own personal Good Parts, and opinionated style guides.

### setup

To try `-Yno-lub`, you can drop in the following sbt plugin to `project/ynolub.sbt`:

```scala
addSbtPlugin("com.eed3si9n" % "sbt-ynolub" % "0.2.0")
```

### lub

When Scala's type inferencer finds type `A` and type `B` to unify, it tries to calculate the lub (least upper bounds) of two types with regards to `<:<`. This process is sometimes called lubbing. Here are some of the examples:

```scala
scala> if (true) Some(1) else None
res0: Option[Int] = Some(1)

scala> if (true) List(1) else Nil
res1: List[Int] = List(1)
```

One idea I've been thinking about for a few years is that lubbing in its current form is not helpful. Here's a tweet from 2013:

<blockquote class="twitter-tweet" lang="en"><p lang="en" dir="ltr">are non-imported implicits and lubing useful in <a href="https://twitter.com/hashtag/scala?src=hash">#scala</a>? Map to List[Tuple2], Int to Double, Foo and Bar to Any. I&#39;d rather see errors</p>&mdash; eugene yokota (@eed3si9n) <a href="https://twitter.com/eed3si9n/status/405388934525775872">November 26, 2013</a></blockquote>
<script async src="//platform.twitter.com/widgets.js" charset="utf-8"></script>

This is in part due to the fact that the subtyping relationship described by `<:<` encodes many different things in Scala. By automatically lubbing, Scala will unify various things into an expression. Here are some examples:

```scala
scala> if (true) Right(1) else Left("1")
res2: ....

scala> 1 match { case 1 => Array(1); case n => Vector(n) }
res3: ....

scala> if (true) 1 else false
res4: ....

scala> 1 match { case 1 => 2; case n => None }
res5: ....

scala> if (true) Vector(1) else Range(1, 1)
res6: ....
```

Because of the universal top type `Any`, Scala will unify any two types together.

By the way, can you guess what the return types are?

```scala
scala> if (true) Right(1) else Left("1")
res2: Product with Serializable with scala.util.Either[String,Int] = Right(1)

scala> 1 match { case 1 => Array(1); case n => Vector(n) }
res3: java.io.Serializable = Array(1)

scala> if (true) 1 else false
res4: AnyVal = 1

scala> 1 match { case 1 => 2; case n => None }
res5: Any = 2

scala> if (true) Vector(1) else Range(1, 1)
res6: scala.collection.immutable.IndexedSeq[Int] with scala.collection.AbstractSeq[Int] with Serializable with scala.collection.CustomParallelizable[Int,scala.collection.parallel.immutable.ParSeq[Int] with Serializable{def seq: scala.collection.immutable.IndexedSeq[Int] with scala.collection.AbstractSeq[Int] with Serializable with scala.collection.CustomParallelizable[Int,scala.collection.parallel.immutable.ParSeq[Int] with Serializable]{def dropRight(n: Int): scala.collection.immutable.IndexedSeq[Int] with scala.collection.AbstractSeq[Int] with Serializable; def takeRight(n: Int): scala.collection.immutable.IndexedSeq[Int] with scala.collection.AbstractSeq[Int] with Serializable; def drop(n: Int): scala.collection.immutable.IndexedSeq[Int] with scala.collection.AbstractSeq[Int] with Se...
```

Above examples demonstrate that lubbing is hard to reason, and often surprising.

One evidence that lubbing is a problem is the prevailing "best practice" of annotating the return type of methods or implicit values. The first places I've heard it probably was Dick and Bill's [talk][1] at Scala Days 2011. It's a good advice, but like many patterns and best practices, isn't it working around the problem of the language? We have no idea what the type inferencer is going to do with lubbing, so we are putting a check on each method.

When something is performed automatically, the outcome should be safe and predictable. Also, the above examples indicates that the matter of unifying type `A` and type `B` could involve a matter of taste in terms of thinking what two types are comparable.

Let's start from the top. `Right(1)` and `Left("1")`. Should these be compared together? I think it makes sense to support algebraic data types somehow. What I am not sure if how they should be encoded. The current return type of `Product with Serializable with scala.util.Either[String,Int]` is not desirable for sure.

Next up, `Array(1)` and `Vector(n)`. Personally speaking, I consider two different datatypes to be different things, and should not be unified automatically. Both of them might implement some common trait or typeclass, but that doesn't mean that I want to unify them in an if-expression, pattern matching, or for-comprehension.

Next, `1` and `false`. Again, I don't think these types should be compared in the same expression. Note that I am not advocating against the existence of `Seq` trait or `AnyVal` trait. I just don't think `1` and `false` should be lubbed into `AnyVal`.

The example of `2` and `None` emulates someone forgetting to wrap `2` in `Some(...)`. It demonstrates that lubbing can defeat the purpose of having static type checking.

The last example is from Jon Pretty's [Demystifying Type Inference][2] talk.

### where lubs can show up

So far I've used if-expression and pattern matching as the examples, but lubbing can show up in other places. Jon's talk highlights that constructing datatypes like `List` can cause lubbing.

```scala
scala> List(Array(1), Vector(2))
res7: List[java.io.Serializable] = List(Array(1), Vector(2))

scala> List(1, false)
res8: List[AnyVal] = List(1, false)

scala> List(1, None)
res9: List[Any] = List(1, None)
```

Another way of looking at it is that this is calling `List.apply[A](1, None)`, and the compiler needs to infer what `A` is. Here's a simpler function to demonstrate this point:

```scala
scala> def first[A](a1: A, a2: A): A = a1
first: [A](a1: A, a2: A)A

scala> first(Array(1), Vector(2))
res10: java.io.Serializable = Array(1)

scala> first(1, false)
res11: AnyVal = 1
```

There's also the entire topic of numeric widening:

```scala
scala> List(1, 1L)
res12: List[Long] = List(1, 1)

scala> 1 :: List(1L)
res13: List[AnyVal] = List(1, 1)
```

### doing less

I have a limited experience working with TypeScript, but I was delighted how thin the wrapping felt when using it. It does add static type checking and type inference, but generally one could guess what JavaScript it will emit. Some things do not compile, and you help out the compiler.

For example, it prevents the unification of `Number` and `Boolean`:

    var x = function() {
      if (true) return 1
      else return false
    }

This results to:

    No best common type exists among return expressions.

If I really want to, I need to cast them to `any` manually, which I like:

    var x = function() {
      if (true) return <any>1
      else return <any>false
    }

I've been thinking about the idea of Scala compiler flag called `-Yno-lub` that turns off lubbing. For a while, I'd bring this up at post-conference socializing or on a bus when I get to sit next to someone from Scala team. Most recently, Seth encouraged me to start at the grass root, and give talks and write a blog post.

Since Scala World 2015 was coming up, I thought it would be a fun thing to show at the Sunday Unconference. To try it out, see the instruction at the beginning of this page. The sbt plugin will rewire your build to will use my hacked 2.11 build of Scala compiler along with the `-Yno-lub`.

### -Yno-lub

Getting the proof of concept up and running was surprisingly simple because when I grepped for the word `lub`, I quickly found a function that's named just [that][lubSource]:

```scala
    /** The least upper bound wrt <:< of a list of types */
    protected[internal] def lub(ts: List[Type], depth: Depth): Type = ....
```

I could add some lines like this. What could go wrong?:

```scala
    val res =
      if (noLub) checkSameTypes(ts)
      else lub0(ts)
```

Because this cuts out most of the lubbing logic, a potential side benefit of `-Yno-lub` could be that it could lead to reduction in compilation time.

This was good enough for the examples we've seen above. Here's the result:

```scala
scala> if (true) Right(1) else Left("1")
<console>:12: error: same types expected: scala.util.Right[Nothing,Int] and scala.util.Left[String,Nothing]
       if (true) Right(1) else Left("1")
       ^

scala> if (true) (Right(1): Either[String, Int]) else (Left("1"): Either[String, Int])
res1: Either[String,Int] = Right(1)

scala> 1 match { case 1 => Array(1); case n => Vector(n) }
<console>:12: error: same types expected: Array[Int] and scala.collection.immutable.Vector[Int]
       1 match { case 1 => Array(1); case n => Vector(n) }
         ^

scala> if (true) 1 else false
<console>:12: error: same types expected: Int and Boolean
       if (true) 1 else false
       ^

scala> 1 match { case 1 => 2; case n => None }
<console>:12: error: same types expected: Int and None.type
       1 match { case 1 => 2; case n => None }
         ^
```

As you can see, `Right(1)` and `Left("1")` case will now require type annotation to compile. The same goes for `None` and `Nil`:

```scala
scala> if (true) Some(1) else None
<console>:12: error: same types expected: Some[Int] and None.type
       if (true) Some(1) else None
       ^

scala> if (true) List(1) else Nil
<console>:12: error: same types expected: List[Int] and scala.collection.immutable.Nil.type
       if (true) List(1) else Nil
       ^
```

This is similar to algebraic data type encoding issue. It's a bit annoying to annotate all `Nil`s, but I'd be willing to deal with it.

### "real-world" issues and workarounds

Here are some of the issues that I ran into when trying to use `-Yno-lub`.

#### unification with the `Nothing` type

One of the things I took for granted was the unification with the `Nothing` type. Consider:

```scala
scala> if (true) 1 else sys.error("boom")
```

This is an unification of `Int` and `Nothing`. Strictly speaking, we should not allow it, but I've decided to make a compromise here since throwing an exception is an opt-in act by the programmer.

#### unification of existential types

Here's another one that I had to work around:

```scala
scala> def something(clazz: Class[_]): List[Class[_]] = {
         if (true) List(clazz)
         else clazz :: something(clazz.getSuperclass)
       }
<console>:13: error: same types expected: Class[_] and Class[_$1]
         else clazz :: something(clazz.getSuperclass)
                    ^
```

The first and second `Class[_]` is not considered the same type, but semantically they cover the same terms. To "fix" this, I had to go into the `TypeComparers` and add the following case:

```scala
  // @pre: at least one argument contains existentials
  private def sameExistentialTypes(tp1: Type, tp2: Type): Boolean = (
    try {
      skolemizationLevel += 1
      (tp1.skolemizeExistential.normalize, tp2.skolemizeExistential.normalize) match {
        case (sk1: TypeRef, sk2: TypeRef) =>
          equalSymsAndPrefixes(sk1.sym, sk1.pre, sk2.sym, sk2.pre) &&
            (isSameHKTypes(sk1, sk2) ||
              ((sk1.args corresponds sk2.args) (isComparableSkolemType)))
        case _ => false
      }
    } finally {
      skolemizationLevel -= 1
    }
  )
  // this comparison intentionally ignores the name of the symbol.
  private def isComparableSkolemType(tp1: Type, tp2: Type): Boolean =
    (tp1, tp2) match {
      case (sk1: TypeRef, sk2: TypeRef) =>
        sk1.sym.info =:= sk2.sym.info &&
          sk1.pre =:= sk2.pre
      case _ => false
    }

....

  private def isSameType1(tp1: Type, tp2: Type): Boolean = typeRelationPreCheck(tp1, tp2) match {
    case state if state.isKnown                                  => state.booleanValue
    case _ if typeHasAnnotations(tp1) || typeHasAnnotations(tp2) => sameAnnotatedTypes(tp1, tp2)
    case _ if containsExistential(tp1) || containsExistential(tp2) => sameExistentialTypes(tp1, tp2)
    case _                                                       => isSameType2(tp1, tp2)
  }
```

As you can see, we are gradually getting sucked into the deeper ends.

#### code generation by case classes

Here's something you might not have expected:

```scala
scala> case class Movie(name: String, year: Int)
<console>:11: error: same types expected: None.type and Some[(String, Int)]
       case class Movie(name: String, year: Int)
                  ^
```

There's a useful compiler flag called `-Xprint:typer` to find out what's going on:

```scala
    case <synthetic> def unapply(x$0: Movie): Option[(String, Int)] = if (x$0.==(null))
      scala.this.None
    else
      Some.apply[(String, Int)](scala.Tuple2.apply[String, Int](x$0.name, x$0.year));
```

The generated code for `unapply` now needs type annotation. The same goes for `productElement`, which needs to be widened into `Any` manually:

```scala
    <synthetic> def productElement(x$1: Int): Any = x$1 match {
      case 0 => Movie.this.name
      case 1 => Movie.this.year
      case _ => throw new IndexOutOfBoundsException(x$1.toString())
    };
```

I've worked around that one too, but this spells a grim prospect of various generated code getting snagged by the newly introduced strictness.

#### code generation by if-clause

Another code generation:

```scala
scala> if (true) "1"
<console>:12: error: same types expected: String and Unit
       if (true) "1"
       ^
```

I haven't worked around this issue in the compiler since we can fix it ourselves:

```scala
scala> if (true) { "1"; () }
```

There may be more issues, but now it's able to compile more code than before.

### encoding algebraic data types

The open issue is the encoding of the algebraic data types.

#### wrapping it with function

One way to workaround it in the user land is to provide wrappers that annotates the leaf values to the parent trait.

```scala
scala> def nil[A]: List[A] = (Nil: List[A])
nil: [A]=> List[A]

scala> if (true) List(1) else nil[Int]
res14: List[Int] = List(1)
```

This approach has a nice side benefit of being able to use typeclasses for `List[A]` for `Eq` etc.

#### sum type

But, if we could add first-class support in Scala, how would it look like?
One idea might be treating `Either[A1, A2]` as a sum type of `Left[A1]` and `Right[A2]`.

```scala
package object collection {
  type Either[A1, A2] = Left[A1] | Right[A2]
}
```

I don't know if this works, because we'd want to put implementation in `Either[A1, A2]`.

#### type restriction

Perhaps there should be a special syntax to denote the leaf types being part of a sum type:

```scala
sealed trait Either[A1, A2] {
  def a1: A1
  def a2: A2
  def leftOption: Option[A1] =
    this match {
      case Left(a1) => (Some(a1): Option[A1])
      case Right(_) => (None: Option[A1])
    }
  def rightOption: Option[A2] =
    this match {
      case Left(_)   => (None: Option[A1])
      case Right(a2) => (Some(a2): Option[A2])
    }
  def isLeft: Boolean =
    this match {
      case Left(_)  => true
      case Right(_) => false
    }
  def isRight: Boolean = !isLeft
  def map[B](f: A2 => B): Either[A1, B] =
    this match {
      case Left(a1)  => Left(a1)
      case Right(a2) => Right(f(a2))
    }
}
final case class Left[A1](a1: A1) restricts Either[A1, Nothing]
final case class Right[A2](a2: A2) restricts Either[Nothing, A2]
```

This imaginary restriction type is a special kind of subtype that is not allowed to introduce any new fields besides that ones captured by the constructor. This could be used to tell the compiler that it's ok to infer `Either[A1, A2]`. By not allowing any implementation on the restricted types, hopefully we can distinguish `Vector` extending `Seq` vs straightforward algebraic data types.

### summary

Because Scala encodes various things using subtyping, the result of the type inference by means of calculating the lub of type `A` and type `B` is often unpredictable, and unhelpful. The boundary of which two types should be considered comparable could also be subjective. `-Yno-lub` is an experimental flag to experience Scala with weaker type inferencing, where two types are requires to be identical. The challenges remain on various code generation unaware of this flag and on encoding of algebraic data types.
