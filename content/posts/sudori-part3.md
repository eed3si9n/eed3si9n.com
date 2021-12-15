---
title:       "sudori part 3"
type:        story
date:        2021-11-12
draft:       false
url:         /sudori-part3
tags:        [ "sbt" ]
---

  [sudori]: https://github.com/eed3si9n/sudori
  [part1]: /sudori-part1
  [part2]: /sudori-part2
  [intro-to-macros]: /intro-to-scala-3-macros/
  [metaprogramming]: http://dotty.epfl.ch/docs/reference/metaprogramming/toc.html
  [Enum]: http://dotty.epfl.ch/docs/reference/enums/adts.html
  [TypeProjection]: http://dotty.epfl.ch/docs/reference/dropped-features/type-projection.html
  [so-50043630]: https://stackoverflow.com/q/50043630/3827
  [Tree]: https://github.com/lampepfl/dotty/blob/3.0.1/library/src/scala/quoted/Quotes.scala#L255
  [Transformer]: https://github.com/scala/scala/blob/v2.13.6/src/reflect/scala/reflect/api/Trees.scala#L2563
  [TreeMap]: https://github.com/lampepfl/dotty/blob/3.0.1/library/src/scala/quoted/Quotes.scala#L4370
  [Type]: http://dotty.epfl.ch/docs/reference/metaprogramming/macros.html#types-for-quotations
  [statically-unknown]: https://docs.scala-lang.org/scala3/guides/macros/faq.html#how-do-i-summon-an-expression-for-statically-unknown-types
  [Instance]: https://github.com/sbt/sbt/blob/v1.5.5/core-macros/src/main/scala/sbt/internal/util/appmacro/Instance.scala
  [1c22478edc]: https://github.com/sbt/sbt-zero-thirteen/commit/1c22478edcad5b083330445317d3ef28f3fa3ef2
  [Selective]: /selective-functor-in-sbt
  [TypeTest]: http://dotty.epfl.ch/docs/reference/other-new-features/type-test.html
  [Lambda]: https://github.com/lampepfl/dotty/blob/3.0.1/library/src/scala/quoted/Quotes.scala#L1290
  [createFunction]: https://github.com/sbt/sbt/blob/v1.5.5/core-macros/src/main/scala/sbt/internal/util/appmacro/ContextUtil.scala#L234
  [ow18g7]: https://www.reddit.com/r/scala/comments/ow18g7/sudori_part_2/h7d3bpb/
  [Bazzucchi]: https://www.scala-lang.org/2021/02/26/tuples-bring-generic-programming-to-scala-3.html
  [Tuple]: https://github.com/lampepfl/dotty/blob/3.1.0/library/src/scala/Tuple.scala
  [Tuples]: https://github.com/lampepfl/dotty/blob/3.1.0/library/src/scala/runtime/Tuples.scala
  [TLPS8a]: https://apocalisp.wordpress.com/2010/11/01/type-level-programming-in-scala-part-8a-klist%c2%a0motivation/
  [TLPS8b]: https://apocalisp.wordpress.com/2010/11/03/type-level-programming-in-scala-part-8b-klist%C2%A0basics/
  [TLPS8c]: https://apocalisp.wordpress.com/2010/11/15/type-level-programming-in-scala-part-8c-klist%C2%A0zipwith/

I'm hacking on a small project called [sudori][sudori], an experimental sbt. The initial goal is to port the macro to Scala 3. It's an exercise to take the macro apart and see if we can build it from the ground up. This an advanced area of Scala 2 and 3, and I'm finding my way around by trial and error. This is part 3.

It's been a while since I wrote [part 2][part2], but in between I've written [intro to Scala 3 macros][intro-to-macros], which is sort of a sudori prequel.

### a letter from a reader

After part 2, I got a very helpful [comment][ow18g7] from Guillaume Martres, an EFPL Scala team member.

- The compiler should automatically look for `TypeTest`
- Capturing vars in lambdas is probably worse than traversing a tree twice
- `null.asInstanceOf[A]` can give us a zero of type `A`

### map, take 2

To recap the lambda expansion problem, to create a lambda expression we have to know the list of parameters upfront listed in `MethodType(...)`. This means that we can't create a placeholder symbol and mutably grow a lambda expression we do in sbt 1.x. Two workarounds that I proposed were:

- Walk the tree twice
- Move the `val` out of lambda

This shows up in the context of rewriting setting macro into `map` etc:

```scala
someKey := { name.value + "!" }
```

This will expand to something like:

```scala
someKey <<= i.map(wrap(name), (q1: String) => { q1 + "!" })
```

The general strategy would be:

1. walk the tree once and collect all occurrences of `x.value` into `inputs`
2. when there's a single input, we'll know to generate `map` with a lambda expression with a single parameter accepting `q1: String`
3. walk the tree second time to replace all occurrences of `x.value` with a reference to a parameter

Here's how we can perform step 1:

```scala
import scala.collection.mutable.ListBuffer

val inputBuf = ListBuffer[Input]()

// Called when transforming the tree to add an input.
//  For `qual` of type F[A], and a `selection` qual.value.
def record(name: String, tpe: TypeRepr, qual: Term, replace: Term) =
  convert[A](name, qual) transform { (tree: Term) =>
    inputBuf += Input(tpe, qual, freshName("q"))
    replace
  }
val tx = transformWrappers(expr.asTerm, record)
```

See [sudori part 1][part1] on `transformWrappers` for details, but in this case it does the matching on `x.value`. The branching in step 2 looks like this:

```scala
def makeApp(body: Term, inputs: List[Input]): Expr[i.F[Effect[A]]] = inputs match
  case Nil      => pure(body)
  case x :: Nil => genMap(body, x)
  case xs       => ???

val tr = makeApp(inner(tx), inputBuf.toList)
```

The lambda creation part of `genMap` looks like this:

```scala
val lambda = Lambda(
  owner = Symbol.spliceOwner,
  tpe = tpe,
  rhsFn = (sym, params) => {
    val param = params.head.asInstanceOf[Term]
    // Called when transforming the tree to add an input.
    //  For `qual` of type F[A], and a `selection` qual.value,
    //  the call is addType(Type A, Tree qual)
    // The result is a Tree representing a reference to
    //  the bound value of the input.
    def substitute(name: String, tpe: TypeRepr, qual: Term, replace: Term) =
      convert[A](name, qual) transform { (tree: Term) =>
        typed[a](Ref(param.symbol))
      }
    transformWrappers(body.asTerm.changeOwner(sym), substitute)
  }
).asExprOf[a => A1]
```

Note `transformWrappers(...)` is called again, this time with `substitute` instead of `record`. Since we no longer need to initialize a `var`, we no longer need `Zero` typeclass or `null.asInstanceOf[A]` either.

### mapN

Consider the following setting expression:

```scala
someKey := {
  name.value + version.value + "!"
}
```

This will expand to something like:

```scala
someKey <<= i.mapN((wrap(name), wrap(version)), (q1: String, q2: String) => {
  q1 + q2 + "!"
})
```

This is the core feature and the tricky part of `build.sbt` settings macro. For one thing, `mapN` would have to be polymorphic in some way because a setting block in `build.sbt` could contain an arbitrary number of `x.value`, and when this macro was written for sbt 0.13, Scala 2.10 still had tuple 22 limitation. In sbt 0.13, `mapN` was defined as follows:

```scala
def app[K[L[x]], Z](in: K[M], f: K[Id] => Z)(implicit a: AList[K]): M[Z]
```

### AList

To abstract the arity problem, Mark Harrah created a typeclass called `AList` in 2012.

```scala
/**
 * An abstraction over a higher-order type constructor `K[x[y]]` with the purpose of abstracting
 * over heterogeneous sequences like `KList` and `TupleN` with elements with a common type
 * constructor as well as homogeneous sequences `Seq[M[T]]`.
 */
trait AList[K[F[x]]] {
  def transform[F1[_], F2[_]](value: K[F1], f: F1 ~> F2): K[F2]

  def traverse[F1[_], F2[_], P[_]](value: K[F1], f: F1 ~> (F2 ∙ P)#l)(implicit np: Applicative[F2]): F2[K[P]]

  def foldr[F1[_], A](value: K[F1], f: (F1[_], A) => A, init: A): A

  def toList[F1[_]](value: K[F1]): List[F1[_]] =
    foldr[F1, List[F1[_]]](value, _ :: _, Nil)

  def apply[F1[_], C](value: K[F1], f: K[Id] => C)(implicit a: Applicative[F1]): F1[C] =
    a.map(f, traverse[F1, F1, Id](value, idK[F1])(a))
}
```

If I were to guess what "A" stands for here, it would be _arity-generic_. Given an arbitrary effect type `F[_]`, `AList` holds on to them (`F[A1]`, `F[A2]`, etc) and fold them up if needed. There an instance of `AList` for empty, single, `Tuple2[A1, A2]`, `Tuple3[A1, A2, A3]`, `Tuple11`, and a data structure called `KList`, which is an `HList` that only holds on to `F[a]`.

Mark wrote a series of blog posts on `KList` on Apocalisp in 2010:

- [Type-Level Programming in Scala, Part 8a: KList motivation][TLPS8a]
- [Type-Level Programming in Scala, Part 8b: KList basics][TLPS8b]
- [Type-Level Programming in Scala, Part 8c: KList ZipWith][TLPS8c]

> One use of KList and the `transform` and `down` methods from 8b is to implement methods like `zipWith` for arbitrary tuple lengths. 

I think `zipWith` is what we'd call `mapN` today. Fast forward to Scala 3, we might not need to create this abstraction because the built-in `Tuple` has improved.

### Tuple

For an introduction to `Tuple`'s arity-generic capability, see Vincenzo Bazzucchi's [Tuples bring generic programming to Scala 3][Bazzucchi]:

> In Scala 3, tuples gain power thanks to new operations, additional type safety and fewer restrictions, pointing in the direction of a construct called Heterogeneous Lists (HLists), one of the core data structures in generic programming.
>
> ... Scala 3 introduces types `*:`, `EmptyTuple` and `NonEmptyTuple` but also methods `head` and `tail` which allow us to define recursive operations on tuples.

For more detailed understanding of what's going on under the hood, [Tuple][Tuple] and [runtime.Tuples][Tuples] are interesting reads. The key feature is that it lets us pretend as if tuples are constructed as nested pairs, even though internally it is using traditional `Tuple2`, `Tuple3`, etc.

As an example of arity-generic operation, `.map` is interesting.

```scala
scala> (1, "foo").map([A] => (a: A) => Option(a))
val res0: Option[Int] *: Option[String] *: EmptyTuple = (Some(1),Some(foo))

scala> (1, "foo", false).map([A] => (a: A) => Option(a))
val res1: Option[Int] *: Option[String] *: Option[Boolean] *: EmptyTuple = (Some(1),Some(foo),Some(false))
```

Here we see that `.map()` accepts a poly function, and returns `(Option[Int], Option[String])` for the first and `(Option[Int], Option[String], Option[Boolean])` for the next. The type signature of `.map` looks like this:

```scala
inline def map[F[_]](f: [t] => t => F[t]): Tuple.Map[this.type, F]
```

where `Tuple.Map` is a match type defined as follows:

```scala
/** Converts a tuple `(T1, ..., Tn)` to `(F[T1], ..., F[Tn])` */
type Map[Tup <: Tuple, F[_ <: Union[Tup]]] <: Tuple = Tup match {
  case EmptyTuple => EmptyTuple
  case h *: t => F[h] *: Map[t, F]
}
```

This `Tuple.Map` is for all intents and purposes same as Mark's `KList`.

### TupleUtil (AList for Tuple.Map)

If we can provide an implementation similar to `AList` for `Tuple.Map`, then that would give us somewhat direct translation of `app`.

#### traverse

For the purpose of this macro, I think the `traverse` in `AList` can be simplified to:

```scala
trait TupleUtil:
  ....

  def traverse[F1[_], F2[_]: Applicative, Tup <: Tuple](
      value: Tuple.Map[Tup, F1],
      f: [a] => F1[a] => F2[a]
  ): F2[Tup]
end TupleUtil
```

The instance looks like this:

```scala
object TupleUtil:
  def nil[Tup <: Tuple] = EmptyTuple.asInstanceOf[Tup]

  lazy val tuple: TupleUtil = new TupleUtil {
    override def traverse[F1[_], F2[_]: Applicative, Tup <: Tuple](
        value: Tuple.Map[Tup, F1],
        f: [a] => F1[a] => F2[a]
    ): F2[Tup] =
      val F2 = summon[Applicative[F2]]
      value match
        case _: Tuple.Map[EmptyTuple, F1] => F2.pure(nil[Tup])
        case (head: F1[x] @unchecked) *: (tail: Tuple.Map[Tail[Tup], F1] @unchecked) =>
          val tt = traverse[F1, F2, Tail[Tup]](tail, f)
          val g = (t: Tail[Tup]) => (h: x) => (h *: t).asInstanceOf[Tup]
          F2.apply[x, Tup](F2.map(g, tt), f(head))

  }
end TupleUtil
```

The only weird thing I'm doing above is that using `@unchecked` to tell the compiler that `Tuple.Map[Tupe, F1]` is same thing as `F1[x] *: Tuple.Map[Tail[Tup], F1]`.

`traverse` is so versatile people have been saying "The answer is traverse" since 2014:

<blockquote class="twitter-tweet"><p lang="en" dir="ltr">Are you trying to do &lt;don&#39;t even tell me&gt; with a list of disjunctions? The answer is traverse. It&#39;s always traverse. You&#39;re welcome. <a href="https://twitter.com/hashtag/scalaz?src=hash&amp;ref_src=twsrc%5Etfw">#scalaz</a></p>&mdash; 🔥 Tpol Chico (@tpolecat) <a href="https://twitter.com/tpolecat/status/541111126155489280?ref_src=twsrc%5Etfw">December 6, 2014</a></blockquote> <script async src="https://platform.twitter.com/widgets.js" charset="utf-8"></script>

In our case, given a tuple of `(F1[A1], F1[A2], F1[A3], ...)`, `traverse` converts into `F2[(A1, A2, A3)]`. In other words, it's able to make the relationship between `F1` and tuple inside out. One quintessential usage of this idea is `Future.sequence` where `List[Future[A]]` becomes `List[Future[A]]`, except in this case we have a heterogenous list.

#### TupleUtil#mapN

Once we have `traverse`, `mapN` can be implemented on top of that.

```scala
def idPoly[F1[_]] = [a] => (p: F1[a]) => p

def mapN[F1[_]: Applicative, A, Tup <: Tuple](value: Tuple.Map[Tup, F1], f: Tup => A): F1[A] =
  summon[Applicative[F1]].map(f, traverse[F1, F1, Tup](value, idPoly[F1]))
```

Here's how the test looks like:

```scala
test("mapN") {
  val tuple = (
    Future {
      println("started 1")
      Thread.sleep(100)
      1
    },
    Future {
      println("started 2")
      Thread.sleep(100)
      "foo"
    },
  )
  val f = (arg: (Int, String)) => arg._1.toString + "|" + arg._2
  val actual = tupleUtil.mapN[Future, String, (Int, String)](tuple, f)
  val result = Await.result(actual, Duration.Inf)
  assert(
    result.toString == "1|foo"
  )
}
```

In this example `mapN` is used to run two futures in parallel and aggregate the result.

### Constructing tuples

Now that we've figured out `mapN`, let's look into creating tuples programmatically using the list of `Input` we've collected.

To make a tuple, `Expr` provides a convenient API to do so, which automatically creates a tuple using the right runtime class:

```scala
Expr.ofTupleFromSeq(inputs.map(_.term.asExpr))
```

Note that these `input#term` do not contain `A`, but `i.F[A]` instead, so the tuple of inputs would be `Tuple.Map[(A1, A2, ...), i.F]`.

### genMapN

To generate `mapN` we end up using the raw Reflection API to manipulate the trees directly. This is because we need to pass `br.inputTupleTypeRepr` as a type parameter, but when you convert it into `asType`, I couldn't quite convince the compiler that it satisfies `<: Tuple`.

```scala
def genMapN(body: Term, inputs: List[Input]): Expr[i.F[Effect[A]]] =
  def genMapN0[A1: Type](body: Expr[A1]): Expr[i.F[A1]] =
    val br = makeTuple(inputs)
    val lambdaTpe =
      MethodType(List("$p0"))(_ => List(br.inputTupleTypeRepr), _ => TypeRepr.of[A1])
    val lambda = ....
    val tupleMapRepr = TypeRepr
      .of[Tuple.Map]
      .appliedTo(List(br.inputTupleTypeRepr, TypeRepr.of[i.F]))
    tupleMapRepr.asType match
      case '[tupleMap] =>
        Select
          .unique(instance.asTerm, "mapN")
          .appliedToTypes(List(br.inputTupleTypeRepr, TypeRepr.of[A1]))
          .appliedToArgs(List(typed[tupleMap](br.tupleExpr.asTerm), lambda))
          .asExprOf[i.F[A1]]

  eitherTree match
    case Left(_) =>
      genMapN0[Effect[A]](body.asExprOf[Effect[A]])
    case Right(_) =>
      flatten(genMapN0[i.F[Effect[A]]](body.asExprOf[i.F[Effect[A]]]))
```

The lambda part looks like this:

```scala
val lambdaTpe =
  MethodType(List("$p0"))(_ => List(br.inputTupleTypeRepr), _ => TypeRepr.of[A1])
val lambda = Lambda(
  owner = Symbol.spliceOwner,
  tpe = lambdaTpe,
  rhsFn = (sym, params) => {
    val p0 = params.head.asInstanceOf[Term]
    def substitute(name: String, tpe: TypeRepr, qual: Term, replace: Term) =
      convert[A](name, qual) transform { (tree: Term) =>
        val idx = inputs.indexWhere(input => input.term == qual)
        Select
          .unique(Ref(p0.symbol), "apply")
          .appliedToTypes(List(br.inputTupleTypeRepr))
          .appliedToArgs(List(Literal(IntConstant(idx))))
      }
    transformWrappers(body.asTerm.changeOwner(sym), substitute, sym)
  }
)
```

This constructs a lambda expression that takes a tuple as input and returns `Effect[A]`. Inside the lambda expression, we use `transformWrappers` to substitute `wrapInit(...)` with `$p0(idx)`.

Overall, this can be used as follows:

```scala
test("getMapN") {
  val actual = contMapNMacro[Int]({
    val x = ContTest.wrapInit(List(1))
    val y = ContTest.wrapInit(List(2))
    x + y + 3
  })
  assert(actual == List(6))
}

// This compiles away
def wrapInit[A](a: List[A]): A = ???
```

One of the key points is `.changeOwner(sym)` is called on `body.asTerm` so the symbols like `val x` and `val y` are re-owned by the lambda. For instance, the above example would expand as follows:

```scala
instance.mapN((wrapInit(List(1)), wrapInit(List(2))), ($p0: (Int, Int)) => {
  val x = $p0(0)
  val y = $p0(1)
  x + y + 3
})
```

With this macro, we now have Applicative do, which automatically lifts imperative code into parallel task processing code. This is analogous to async/await, but implemented as a user-land feature using a macro.

### Summary

- `contImpl` macro implements both Applicative-do and Monadic-do. It does so by first scanning the abstract syntax tree for `key.value`. When there are none, it calls `pure(...)`, `map(...)` when there is exactly one, and `mapN(...)` when there are multiple inputs.
- Polyfunction (rank-n polymorphism) enables `traverse` on a structured tuple of `(F1[A1], F1[A2], F1[A3])`.

### Reference

- [Scala 3 Reference: Metaprogramming][metaprogramming]
- [intro to Scala 3 macros][intro-to-macros]
- [sudori part 1][part1]
- [sudori part 2][part2]
- [Tuples bring generic programming to Scala 3][Tuples]
