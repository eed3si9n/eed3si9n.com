---
title:       "sudori part 2"
type:        story
date:        2021-08-01
draft:       false
promote:     true
sticky:      false
url:         /sudori-part2
aliases:     [ /node/400 ]
tags:        [ "sbt" ]
---

  [sudori]: https://github.com/eed3si9n/sudori
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
  [Selective]: https://eed3si9n.com/selective-functor-in-sbt
  [part1]: https://eed3si9n.com/sudori-part1
  [TypeTest]: http://dotty.epfl.ch/docs/reference/other-new-features/type-test.html
  [Lambda]: https://github.com/lampepfl/dotty/blob/3.0.1/library/src/scala/quoted/Quotes.scala#L1290
  [createFunction]: https://github.com/sbt/sbt/blob/v1.5.5/core-macros/src/main/scala/sbt/internal/util/appmacro/ContextUtil.scala#L234

I'm hacking on a small project called [sudori][sudori], an experimental sbt. The initial goal is to port the macro to Scala 3. It's an exercise to take the macro apart and see if we can build it from the ground up. This an advanced area of Scala 2 and 3, and I'm finding my way around by trial and error. This is part 2.

Reference:
- [Scala 3 Reference: Metaprogramming][metaprogramming]
- [sudori part 1][part1]

### Instance

When we think of the `build.sbt` macro, the first thing that comes to our mind is the Applicative do macro that it implements using `.value` even though some may not use those terms exactly. The main driver for this imperative-to-functional is in the companion object for an oddly named [Instance][Instance] class:

<scala>
/**
 * The separate hierarchy from Applicative/Monad is for two reasons.
 *
 * 1. The type constructor is represented as an abstract type because a TypeTag cannot represent a type constructor directly.
 * 2. The applicative interface is uncurried.
 */
trait Instance {
  type M[x]
  def app[K[L[x]], Z](in: K[M], f: K[Id] => Z)(implicit a: AList[K]): M[Z]
  def map[S, T](in: M[S], f: S => T): M[T]
  def pure[T](t: () => T): M[T]
}

trait MonadInstance extends Instance {
  def flatten[T](in: M[M[T]]): M[T]
}
</scala>

As noted in the Scaladoc, sbt also internally has its own `Applicative[_]` typeclass. At this point, we're not sure if the two reasons listed by Mark in [2012][1c22478edc] (circa Scala 2.10.0-M6) are still relevant. The macro looks like this:

<scala>
  def contImpl[T, N[_]](
      c: blackbox.Context,
      i: Instance with Singleton,
      convert: Convert,
      builder: TupleBuilder,
      linter: LinterDSL
  )(
      t: Either[c.Expr[T], c.Expr[i.M[T]]],
      inner: Transform[c.type, N]
  )(
      implicit tt: c.WeakTypeTag[T],
      nt: c.WeakTypeTag[N[T]],
      it: c.TypeTag[i.type]
  ): c.Expr[i.M[N[T]]] = ....
</scala>

To decode this signature, it might help to understand the internals of sbt.

### settings and tasks

I mentioned this in [Selective][Selective] post, but two hallmarks of functional programming are that it uses immutable data structure instead of mutation, and that it gives attention to when and how effects are handled.

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

`sbt.Task` is can be seen as a wrapper around side effect function `() => A`. However when we say "compile is a task." The task in this context is represented using `Initialize[Task[A]]`. They are settings of type `Task[A]`. In other words, we have a nested data type of execution plan and effects. We can rewrite the macro signature as follows:

<scala>
  def contImpl[A, Effect[_]](
      c: blackbox.Context,
      i: Instance & scala.Singleton,
      convert: Convert,
      builder: TupleBuilder,
      linter: LinterDSL
  )(
      t: Either[c.Expr[A], c.Expr[i.F[A]],
      inner: Transform[c.type, Effect]
  ): c.Expr[i.F[Effect[A]]] = ....
</scala>

So what's `t`? Why does it take an either? The answer is that it does Applicative-do when you pass `Left[c.Expr[A]]` and Monadic-do when you pass `Right[c.Expr[i.F[A]]]`. So it's a weird implementation detail to share this code. If you remember from [part 1][part1], `convert` here is a glorified partial function, which then can be used to search and replace some portions of a given abstract syntax tree.

### pure

Consider the following setting expression:

<scala>
someKey := { 1 }
</scala>

Assuming `someKey` is a setting, we need to construct `Initialize[Int]`. `contImpl` macro does this generically given an Applicative _instance_ for `Initialize`. Specifically in this case by calling `i.pure(...)`.

<scala>
// no inputs, so construct F[A] via Instance.pure or pure+flatten
def pure(body: Term): Expr[i.F[Effect[A]]] =
  def pure0[A1: Type](body: Expr[A1]): Expr[i.F[A1]] =
    '{
      $i
        .pure[A1] { () => $body }
        .asInstanceOf[i.F[A1]]
    }
  eitherTree match
    case Left(_) => pure0[Effect[A]](body.asExprOf[Effect[A]])
    case Right(_) =>
      flatten(pure0[i.F[Effect[A]]](body.asExprOf[i.F[Effect[A]]]))
</scala>

This looks to be a straightforward code to call `pure` function on `i`. However, this will fail as:

<code>
[error] -- [E007] Type Mismatch Error: sudori/core-macros/src/main/scala-3/sbt/internal/util/appmacro/Cont.scala:119:13
[error] 119 |            $i
[error]     |             ^
[error]     |  Found:    (i : sbt.internal.util.appmacro.MonadInstance & Singleton)
[error]     |  Required: quoted.Expr[Any]
[error] one error found
</code>

### Getting instance out of i.type

We need to splice `i` into the quoted code. One way would be to inline `i`, but then we won't be able to use `i` like `i.F` so that won't work. There's a technique to summon `i` here from a singleton type. A singleton type is a type with a single inhabitant written as `p.type` where `p` points to a term extending `AnyRef`.

Let's say we have `i.type`. First thing we do is obtain `Type[i.type]` by adding context bound `A: Type`. Next we can get `TypeRepr` for it as `TypeRepr[A]`, which provides type information during macro time. We can't just pattern match on `TypeRepr[A]` however. There's a new Scala 3 feature called [TypeTest][TypeTest] that can test types by using `unapply`.

<scala>
  def extractSingleton[A: Type]: Expr[A] =
    def termRef(r: TypeRepr)(using rtt: TypeTest[TypeRepr, TermRef]): Ref = r match
      case rtt(ref) => Ref.term(ref)
      case _        => sys.error(s"expected termRef but got $r")
    termRef(TypeRepr.of[A]).asExprOf[A]
</scala>

Back to `pure`, this can be used like this:

<scala>
// we can extract i out of i.type
val instance = extractSingleton[i.type]

// no inputs, so construct F[A] via Instance.pure or pure+flatten
def pure(body: Term): Expr[i.F[Effect[A]]] =
  def pure0[A1: Type](body: Expr[A1]): Expr[i.F[A1]] =
    '{
      $instance
        .pure[A1] { () => $body }
        .asInstanceOf[i.F[A1]]
    }
  eitherTree match
    case Left(_) => pure0[Effect[A]](body.asExprOf[Effect[A]])
    case Right(_) =>
      flatten(pure0[i.F[Effect[A]]](body.asExprOf[i.F[Effect[A]]]))
</scala>

### map

Consider the following setting expression:

<scala>
someKey := { name.value + "!" }
</scala>

This will expand to something like:

<scala>
someKey <<= i.map(wrap(name), (q1: String) => { q1 + "!" })
</scala>

### lambda expression

The interesting part is generating the lambda expression (anonymous function) `(q1) => { q1 + "!" }`. If we didn't care about the symbol for the lambda expression, then there's a shortcut function provided by Quote Reflection called [Lambda(...)][Lambda]:

<scala>
def makeLambdaImpl(expr: Expr[Unit])(using qctx: Quotes) =
  import qctx.reflect.*
  Lambda(
    owner = Symbol.spliceOwner,
    tpe = MethodType(List("x"))(_ => List(TypeRepr.of[Boolean]), _ => TypeRepr.of[String]),
    rhsFn = (sym, params0) => {
      val param = params0.head
      val toStr = Select.unique(Ref(param.symbol), "toString")
      toStr.appliedToNone
    }
  ).asExprOf[Boolean => String]
</scala>

### lambda expansion problem

This presents a problem because to create a lambda expression we'd have to know the list of parameters upfront listed in `MethodType(...)`. In sbt 1.x macro, currently it uses `transformWrappers(...)` and walk the tree to figure out whether we need to create a lambda expression, and if so how many parameters we need. The substitution function also needs to know the `val`, which requires a function symbol to the lambda expression.

sbt 1.x goes through a bunch of casting to create [an anonymous function value][createFunction], creating `Function(...)` tree, and assigning the symbol. As far as I know, none of these techniques would translate to Scala 3 unless we can somehow cast into the internal API. Two workarounds that I can think of are:

- Walk the tree twice
- Move the `val` out of lambda

Walking the tree twice would let us create lambda expressions immutably, but that could add some performance penalty. So for now, we can try the second way, which is to move the `val` out of lambda, and turn it into `var`. You might be repulsed by the use of `var`, which is an instinct we develop as Scala programmers. `var` is normally discouraged because shared mutable state makes the program difficult to reason about. In this case, we won't expose the `var` to outside, and it will be assigning exactly once before use, so we can think of it as a minor implemtation detail of the macro.

Here's an example. In sbt 1.x let's say we are generating something like:

<scala>
someKey <<= i.map(wrap(name), (q1: String) => { q1 + "!" })
</scala>

The workaround would be to generate:

<scala>
someKey <<= {
  // step 1: when name.value is found, declare a var and add it to input list
  var q1: String = _

  // step 3: because there's single input, map is chosen, which requires a lambda
  // expression with a single parameter accepting p1: String
  i.map(wrap(name), (p1: String) => {
    // step 4: assign p1 value to q1 placeholder
    q1 = p1

    q1 + "!" // step 2: name.value is replaced with ref to q1
  })
}
</scala>

As long as the name `q1` is unique within the scope this should be safe. So the implementation splits into the four steps outlined above as comments:

1. when `name.value` is found, declare a `var` and add it to `input` list
2. `name.value` is replaced with ref to `q1`
3. because there's single input, `map` is chosen, which then requires a lambda expression with a single parameter accepting `p1: String`
4. assign `p1` value to `q1` placeholder

Here's how we can perform steps 1 and 2:

<scala>
def subToProxy(tpe: TypeRepr, qual: Term, selection: Term): Term =
  val vd = freshValDef(Symbol.spliceOwner, tpe)
  inputs = Input(tpe, qual, vd) :: inputs
  tpe.asType match
    case '[a] =>
      Typed(Ref(vd.symbol), TypeTree.of[a])

def substitute(name: String, tpe: TypeRepr, qual: Term, replace: Term) =
  convert[A](name, qual) transform { (tree: Term) =>
    subToProxy(tpe, tree, replace)
  }
val tx = transformWrappers(expr.asTerm, substitute)
</scala>

Steps 3 and 4:

<scala>
def genMap(body: Term, input: Input): Expr[i.F[Effect[A]]] =
  def genMap0[A1: Type](body: Expr[A1], input: Input): Expr[i.F[A1]] =
    input.tpe.asType match
      case '[a] =>
        val tpe = MethodType(List("$p0"))(_ => List(TypeRepr.of[a]), _ => TypeRepr.of[A1])
        val lambda = Lambda(
          owner = Symbol.spliceOwner,
          tpe = tpe,
          rhsFn = (sym, params) => {
            val param = params.head.asInstanceOf[Term]
            Block(
              // $q1 = $p0
              List(Assign(Ref(input.local.symbol), param)),
              body.asTerm
            )
          }
        ).asExprOf[a => A1]
        val expr = input.expr.asExprOf[i.F[a]]
        Typed(
          Block(
            // this contains var $q1 = ...
            List(input.local),
            '{
              val _i = $instance
              _i
                .map[a, A1]($expr.asInstanceOf[_i.F[a]], $lambda)
            }.asTerm
          ),
          TypeTree.of[i.F[A1]]
        ).asExprOf[i.F[A1]]
  eitherTree match
    case Left(_) =>
      genMap0[Effect[A]](body.asExprOf[Effect[A]], input)
    case Right(_) =>
      flatten(genMap0[i.F[Effect[A]]](body.asExprOf[i.F[Effect[A]]], input))
</scala>

The unit test looks like this:

<scala>
package sbt.internal

import sbt.internal.util.appmacro.*
import verify.*
import ContTestMacro.*

object ContTest extends BasicTestSuite:
  test("pure") {
    assert(contMapNMacro[Int](12) == List(12))
  }

  test("getMap") {
    assert(contMapNMacro[Int](ContTest.wrapInit(List(1)) + 1).toString == "List(2)")
  }

  // This compiles away
  def wrapInit[A](a: List[A]): A = ???
end ContTest
</scala>

Here I'm using `List` datatype as the `Functor` to test this.

### freshValDef

There's a detail I glossed over in the above, which is:

<scala>
val vd = freshValDef(Symbol.spliceOwner, tpe)
</scala>

Defining a `val` or `var` can be done like this:

<scala>
def freshValDef(parent: Symbol, tpe: TypeRepr): ValDef =
  tpe.asType match
    case '[a] =>
      val sym =
        Symbol.newVal(parent, freshName("q"), tpe, Flags.Mutable, Symbol.noSymbol)
      ValDef(sym, rhs = Option('{ 0 }.asTerm))

private var counter: Int = -1
def freshName(prefix: String): String =
  counter = counter + 1
  s"$$${prefix}${counter}"
</scala>

The problem is that I'm hardcoding the right-hand side to be `0`.

### Zero

There are probably multiple ways to initialize a `var` with a zero-equivalent value, but probably a more straightforward way would be to define a typeclass called `Zero[A]`:

<scala>
package sbt.internal.util.appmacro

trait Zero[A]:
  def zero: A

object Zero extends LowPriorityZero:
  private[appmacro] def mk[A](a: A): Zero[A] = new Zero:
    def zero: A = a

  given Zero[Byte] = Zero.mk(0: Byte)
  given Zero[Char] = Zero.mk(0: Char)
  given Zero[Short] = Zero.mk(0: Short)
  given Zero[Int] = Zero.mk(0)
  given Zero[Long] = Zero.mk(0L)
  given Zero[Float] = Zero.mk(0f)
  given Zero[Double] = Zero.mk(0.0)
  given Zero[Boolean] = Zero.mk(false)
  given Zero[Unit] = Zero.mk((): Unit)
  given Zero[String] = Zero.mk("")

class LowPriorityZero:
  given [A]: Zero[A] = Zero.mk(null.asInstanceOf[A])
</scala>

This will have a given instance for all types. There's a convenient way to defer the summon invocation called `summonInline[A]`.

<scala>
/**
 * Constructs a new, synthetic, local var with type `tpe`, a unique name, initialized to
 * zero-equivalent (Zero[A]), and owned by `parent`.
 */
def freshValDef(parent: Symbol, tpe: TypeRepr): ValDef =
  tpe.asType match
    case '[a] =>
      val sym =
        Symbol.newVal(
          parent,
          freshName("q"),
          tpe,
          Flags.Mutable | Flags.Synthetic,
          Symbol.noSymbol
        )
      ValDef(sym, rhs = Option('{ summonInline[Zero[a]].zero }.asTerm))
</scala>

This would codegen:

<scala>
var q1: String = summon[Zero[String]].zero
</scala>

### Summary

- `contImpl` macro implements both Applicative-do and Monadic-do. It does so by first scanning the abstract syntax tree for `key.value`. When there are none, it calls `pure(...)` and `map(...)` when there is exactly one.
- To pass the Instance instance `i` to macro and back to the generated code, it uses `Singleton` type `i.type`, which internally holds on to the symbol of `i`.
- Quotes API provides a convenient way to generating lambda expression, but it must know the exact type of the parameters. This means we can't gradually expand the definition of the lambda expression as we walk the tree. To workaround this, we will use `var` one scope outside of the lambda expression.
- We defined `Zero` typeclass and summon a value for it to initialize the `var`s.
