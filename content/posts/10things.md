---
title:       "ten things I like about Scala 3"
type:        story
date:        2024-06-24
url:         /10things
tags:        [ "scala" ]
---

  [pins15]: https://www.artima.com/pins1ed/case-classes-and-pattern-matching.html#15.1
  [wadler1998]: https://homepages.inf.ed.ac.uk/wadler/papers/expression/expression.txt
  [shapeless-guide]: https://books.underscore.io/shapeless-guide/shapeless-guide.html#sec:poly

I am sometimes asked what I like so much about Scala 3, so here's a list in no particular order. Note that this is based on my personal taste informed by how I use Scala 3, and how I'd like to use Scala 3 more.

> I hate it when you make me laugh,<br>
> even worse when you make me cry<br>
> I hate it when you're not around and the fact that you didn't call<br>
> but mostly I hate the way I don't hate you,<br>
> not even close,<br>
> not even a little bit,<br>
> not even at all
>
> — _from [10 things I hate about you](https://poppoetry.substack.com/p/10-things-i-hate-about-you)_

<a id="enums-and-gadt"></a>
### 1. Enums (and GADT)

Scala 3 added [enums](https://docs.scala-lang.org/scala3/book/types-adts-gadts.html), which is an upgraded version of `case class`es. Bonus point: it can express GADT.

<div class="admonition note">

An aside about **case**:<br>
Going back to Scala 2 for a moment, has anyone wondered where the term *case* came from for `case class`es? One theory might be that `case` tracks back from the `switch` statement in languages like C and Java, and it's already a reserved word.

Another origin I might suggest is a 1998 email Philip Wadler called [The expression problem][wadler1998] (Wadler was involved in Java generics along with Martin) sent to `java-genericity@galileo.East.Sun.COM`, `odersky@cis.unisa.edu.au`, among others:

> The Expression Problem is a new name for an old problem.  The goal is
to define a datatype by **cases**, where one can add new **cases** to the
datatype and new functions over the datatype, without recompiling
existing code, and while retaining static type safety (e.g., no
casts).

This shows that back in 1998 "case" was used as a noun to indicate a typelevel branch of a datatype. In this view, a case class provides the users a way to define a typelevel case. However, Scala 2.x's case leaks to the type, which is not great.
</div>

In Scala 2.x case classes, like `Some(...)` and `None` cases, the values are also typed as `Some[A]` and `None` respectively. This is often not convenient since at the typelevel, we'd want to treat them as `Option[A]`.

With Scala 3 enums, `case`s are again used to define typelevel cases, and the values are statically typed to `NewOption[A]`:

```scala
scala> enum NewOption[+A]:
         case Some(value: A) extends NewOption[A]
         case None extends NewOption[Nothing]

// defined class NewOption

scala> NewOption.Some(1)
val res0: NewOption[Int] = Some(1)

scala> NewOption.Some(1) == NewOption.Some(1)
val res1: Boolean = true

scala> NewOption.Some(1) == NewOption.None
val res2: Boolean = false

scala> NewOption.None
val res3: NewOption[Nothing] = None

scala> List(NewOption.Some(1))
val res4: List[NewOption[Int]] = List(Some(1))
```

See also [sudori part 1](/sudori-part1/) for an example of where I use `enum` for sbt 2.x.

GADT means that the case can capture concrete types. For example, `Option[A]` doesn't really know anything about specifics of what goes in `A`. Here's a mini language that can express sum of two integers:

```scala
scala> enum MiniExpr[A]:
         case Bool(b: Boolean) extends MiniExpr[Boolean]
         case I32(i: Int) extends MiniExpr[Int]
         case Sum(a: MiniExpr[Int], b: MiniExpr[Int]) extends MiniExpr[Int]

// defined class MiniExpr

scala> MiniExpr.I32(1)
val res0: MiniExpr[Int] = I32(1)

scala> MiniExpr.Sum(MiniExpr.I32(1), MiniExpr.I32(1))
val res1: MiniExpr[Int] = Sum(I32(1),I32(1))

scala> MiniExpr.Sum(MiniExpr.I32(1), MiniExpr.Bool(false))
-- [E007] Type Mismatch Error: -------------------------------------------------
1 |MiniExpr.Sum(MiniExpr.I32(1), MiniExpr.Bool(false))
  |                              ^^^^^^^^^^^^^^^^^^^^
  |                              Found:    MiniExpr.Bool
  |                              Required: MiniExpr[Int]
  |
  | longer explanation available when compiling with `-explain`
1 error found
```

<a id="opaque-types"></a>
### 2. Opaque types

Scala 3 added [`opaque` type aliases](https://docs.scala-lang.org/scala3/reference/other-new-features/opaques.html) (commonly called "opaque types"), which create a new type without overhead. It probably makes the most sense to wrap numeric types, but I like using it to wrap `String` as well.

For example, in [sbt 2.x remote cache](/sbt-remote-cache/), I define an opaque type representing hash digests:

```scala
opaque type Digest = String

object Digest:
  def apply(s: String): Digest =
    validateString(s)
    s

  def validateString(s: String): Unit = ()
end Digest
```

This creates a lightweight way of defining a new type that hides the internal representation.

```scala
scala> def something(d: Digest): Unit = ()
def something(d: X.Digest): Unit

scala> something("foo")
-- [E007] Type Mismatch Error: -------------------------------------------------
1 |something("foo")
  |          ^^^^^
  |          Found:    ("foo" : String)
  |          Required: X.Digest
  |
  | longer explanation available when compiling with `-explain`
1 error found
```

Note: Yoshida-san noted that, similar to value class, opaque types in Scala 3 aren't concealed at the JVM level. So if you want to maintain binary compatibility, you have to keep that in mind.

<a id="inline"></a>
### 3. Inline

Scala 2.x also had `@inline`, but it was more of a directive to the optimizer than a language construct, so it was difficult to use. On the other hand, Scala 3 adds a proper `inline`, which is guaranteed to inline.

The `inline` can appear as:
- [`inline def`](https://docs.scala-lang.org/scala3/reference/metaprogramming/inline.html#inline-definitions-1)
- [`inline` parameter](https://docs.scala-lang.org/scala3/reference/metaprogramming/inline.html#inline-definitions-1)
- [`inline val`](https://docs.scala-lang.org/scala3/reference/metaprogramming/inline.html#inline-definitions-1)
- [`transparent inline def`](https://docs.scala-lang.org/scala3/reference/metaprogramming/inline.html#transparent-inline-methods-1)
- [`inline if`](https://docs.scala-lang.org/scala3/reference/metaprogramming/inline.html#inline-conditionals-1)
- [`inline match`](https://docs.scala-lang.org/scala3/reference/metaprogramming/inline.html)

Here's a real-life example of an `inline def` from sbt 2.x code base:

```scala
inline def ~=(inline f: A1 => A1): Setting[Task[A1]] =
  transform(f)

def transform(f: A1 => A1): Setting[Task[A1]] =
  set(scopedKey(_ map f))
```

In the above, we want to provide a symbolic alias called `~=` for another method called `transform`. When the user calls `~=`, this should completely compile away and will be replaced with `transform(...)`.

`inline` parameter means:

> This means that actual arguments to these parameters will be inlined in the body of the `inline def`. inline parameters have call semantics equivalent to by-name parameters but allow for duplication of the code in the argument.

Inline condition even evaluates constant expression at the compile-time. Since we know that `inline` will be processed at compile-time, some of the checks and trick that previously required Scala 2.x macros can now be written as a plain function with `inline`.

<a id="macros"></a>
### 4. Macros

In Scala 2.x, the macro system was bolted on as an experimental feature that mostly exposed the guts of the compiler to library authors. With Scala 3, [macros](https://docs.scala-lang.org/scala3/guides/macros/macros.html) are recognized as a legitimate feature, and given many considerations around maintainability and gradual knobs of power. I've written [intro to Scala 3 macros](/intro-to-scala-3-macros/), which hopefully should be a helpful supplementary to the official docs.

In general Scala 3 macro is hygienic, which means that the system prevents unintentional name clashes. Consider a macro that adds 1 at compile-time:

```scala
import scala.quoted.*

inline def addOneX(inline x: Int): Int = ${addOneXImpl('{x})}

def addOneXImpl(x: Expr[Int])(using Quotes): Expr[Int] =
  val rhs = Expr(x.valueOrError + 1)
  '{
    val x = $rhs
    x
  }
```

In the above, the quoted code introduced a variable named `x`. During compilation, the macro system would automatically mangle the variable, so it doesn't accidentally end up capturing another variable named `x` if `addOneX(1)` is called in some code.

Another use of the macro system is the ability to talk to the type system. "Talking to the type system" is called _reflection_, but when people hear _reflection_ they imagine Java's runtime reflection where you end up accessing methods by string. Scala 3's reflection happens at compile-time, and you use code to query the type system or generate code.

Here's an example of using `TypeRepr` and type symbol to check if a _type_ is a `case class`:

```scala
import scala.quoted.*

inline def isCaseClass[A]: Boolean = ${ isCaseClassImpl[A] }
private def isCaseClassImpl[A: Type](using qctx: Quotes) : Expr[Boolean] =
  import qctx.reflect.*
  val sym = TypeRepr.of[A].typeSymbol
  Expr(sym.isClassDef && sym.flags.is(Flags.Case))
```

Most use cases of a macro would be some sort of code generation, and the quote system basically allows you to use actual Scala code. Here's how sbt 2.x handles conditional tasks (a task that consists of an `if` expression is treated as [Selective functor](/selective-functor-in-sbt/)).

```scala
inline def task[A1](inline a1: A1): Def.Initialize[Task[A1]] =
  ${ TaskMacro.taskMacroImpl[A1]('a1) }

def taskMacroImpl[A1: Type](a: Expr[A1])(using
    qctx: Quotes
): Expr[Initialize[Task[A1]]] =
  a match
    case '{ if $cond then $thenp else $elsep } => taskIfImpl[A1](a)
    case _ =>
      val convert1 = new FullConvert(qctx, 0)
      convert1.contMapN[A1, F, Id](a, convert1.appExpr, None)

def taskIfImpl[A1: Type](expr: Expr[A1])(using
    qctx: Quotes
): Expr[Initialize[Task[A1]]] =
  import qctx.reflect.*
  val convert1 = new FullConvert(qctx, 1000)
  expr match
    case '{ if $cond then $thenp else $elsep } =>
      '{
        Def.ifS[A1](Def.task($cond))(Def.task[A1]($thenp))(Def.task[A1]($elsep))
      }
    case _ =>
      report.errorAndAbort(s"Def.taskIf(...) must contain if expression but found ${expr.asTerm}")
```

The end user would pass in either an `if` expression or something else in `Def.task { ... }`, and check is done using pattern matching. With Scala 2.x macros, these operations often required traversing into the abstract syntax tree structure.

<a id="then"></a>
### 5. then

On a more lighter-hearted note, let's talk about syntax. As someone who coded Object Pascal for a while, I'm happy that in Scala 3 the `if` expression can be written without parenthesis. Likely around 1972, programming language C started putting parenthesis around the `if` condition, and subsequently C++ and Java followed. However, this is more of an anomaly than the rule.

Algol 60, Pascal, ML family of languages (SML, F#), and Haskell all use:

```haskell
if condition then expression1 else expression2
```

Scala 3 introduced [new control syntax](https://docs.scala-lang.org/scala3/reference/other-new-features/control-syntax.html), including `then`-style if expression. See also [The state of then](https://contributors.scala-lang.org/t/the-state-of-then/1638) post I wrote in 2018.

None of the modern languages like Python, Rust, and Swift require parenthesis around the condition, although none of them use `then` either. Whenever I can replace parethesis with a `then`, it makes me smile since it makes the language feel like what Scala should've always looked as a Pascal/ML family of language.

One complaint I have about it is that the following is allowed:

```scala
scala> val x = 1
val x: Int = 1

scala> if x > 1 then 2
```

You can even assign that to a `val`:

```scala
scala> val y = if x > 1 then 2

scala> y == (())
val res0: Boolean = true
```

`if` is supposed to be an expression, so I'd require the `else` clause, even if it's `else ()`. I'd also require the types of `then` clause and `else` clause to be the same actually.

<a id="polymorphic-function"></a>
### 6. Polymorphic function

Even with Scala 2.x, we can implement parametric functions `makeList` and `head` as follows:

```scala
scala> def makeList[A1](a: A1): List[A1] = List(a)
def makeList[A1](a: A1): List[A1]

scala> def head[A1](xs: List[A1]): A1 = xs.head
def head[A1](xs: List[A1]): A1

scala> head(makeList(1))
val res1: Int = 1
```

What if we wanted to store that into a `val` instead? What would its type be? This notion, sometimes called rank-n polymorphism, is a useful concept that's been popping up in functional programming. See for example [FunctionK](/herding-cats/FunctionK.html). Scala 3 added [polymorphic function](https://docs.scala-lang.org/scala3/reference/new-types/polymorphic-function-types.html) and corresponding polymorphic function type, so poly function can be passed around.

```scala
scala> val makeList = [a] => (a: a) => List(a)
val makeList: [a] => (a: a) => List[a] = Lambda$7541/473366824@60b21dcd

scala> val head = [a] => (xs: List[a]) => xs.head
val head: [a] => (xs: List[a]) => a = Lambda$7542/1517955069@5ecdd9b

scala> head(makeList(1))
val res0: Int = 1
```

People like Miles Sabin have been eating these for breakfast for the last 10 years. See [Functional operations on HLists][shapeless-guide] section of 'The Type Astronaut's Guide to Shapeless' by Dave Gurnell. Now Scala 3 has adopted these "type astronaut" ideas into the canon, which makes me happy.

<a id="tuples"></a>
### 7. Tuples

Speaking of arity (Shapeless abstracts over arity), in Scala 3, tuples gained arity-generic capabilities. For details see [Tuple.scala](https://github.com/scala/scala3/blob/3.3.3/library/src/scala/Tuple.scala) and Vincenzo Bazzucchi's [Tuples bring generic programming to Scala 3](https://www.scala-lang.org/2021/02/26/tuples-bring-generic-programming-to-scala-3.html) post:

> In Scala 3, tuples gain power thanks to new operations, additional type safety and fewer restrictions, pointing in the direction of a construct called Heterogeneous Lists (HLists), one of the core data structures in generic programming.

So internally Scala 3 tuples are still the same as Scala 2.13 tuples (see [scala.runtime.Tuples.cons](https://github.com/scala/scala3/blob/3.3.3/library/src/scala/runtime/Tuples.scala)) but at compile-time the type system lets us pretend that a tuple is constructed as `A1 *: A2 *: A3 *: Tuple.EmptyTuple`.

Using [match types](https://docs.scala-lang.org/scala3/reference/new-types/match-types.html) and polymorphic functions, we can traverse into the tuple type or compose it.

Let's see if we can implement some examples from [Functional operations on HLists][shapeless-guide]:

```scala
scala> (10, "hello", true).size
val res0: Int = 3

scala> type R = Tuple.Size[Int *: String *: Boolean *: EmptyTuple]
// defined alias type R = 3
```

A more useful thing would be to wrap each type into an effect type like `IO[a]`. Let's use `Option[a]` for now:

```scala
scala> val makeOption: [a] => a => Option[a] = [a] => (a: a) => Option(a)
val makeOption: [a] => (x$1: a) => Option[a] = Lambda$7806/239970257@2435a640

scala> (10, "hello", true).map(makeOption)
val res0: (Option[Int], Option[String], Option[Boolean]) = (Some(10),Some(hello),Some(true))

scala> type R = Tuple.Map[Int *: String *: Boolean *: EmptyTuple, Option]
// defined alias type R = (Option[Int], Option[String], Option[Boolean])
```

I think this is pretty cool. [sudori part 3](/sudori-part3/) goes into how this relates to sbt 2.x's internals.

<a id="extension-methods"></a>
### 8. Extension methods

Scala 3 added [extension methods](https://docs.scala-lang.org/scala3/reference/contextual/extension-methods.html), which allows methods to be added to a type after a type is already defined. This is somewhat analogous to the implicit classes in Scala 2.x, but I feel like I end up using extension methods more often than I expected.

For example, in sbt 1.x code base `.value` method is implemented as a macro that is injected via implicits because `Initialize[A]`, `Task[A]` etc are defined at different layers. With sbt 2.x, the same constraint applies but with extension methods and `inline` the implementation is much simpler:

```scala
extension [A1](inline in: Initialize[A1])
  inline def value: A1 = InputWrapper.`wrapInit_\u2603\u2603`[A1](in)
```

<a id="scala-2.13-interop"></a>
### 9. Scala 2.13 interop

An interesting aspect of Scala 3.x is that it is backward compatible throughout 3.x series, and it's [interoperable with the Scala 2.13 ecosystem](https://docs.scala-lang.org/scala3/guides/migration/compatibility-intro.html). In fact, its standard library that of Scala 2.13. Or put another way, it has front-loaded any runtime changes into Scala 2.13, like the collection library rewrites.

This becomes less of a concern once you have made the leap to Scala 3, but for companies assessing the migration to Scala 3, it should be a relief that the runtime semantics of Scala 3 would mostly stay the same. The interop also allows gradual migration to Scala 3.x for application developers.

<a id="optional-braces"></a>
### 10. Optional braces syntax

Scala 3 introduced [optional braces](https://docs.scala-lang.org/scala3/reference/other-new-features/indentation.html), which allows many of the `{` and `}` to be replaced with `:` indentation instead. This was probably the most controversial change, even though it was totally an opt-in syntax change.

Personally, I really like the new syntax. I like the new definition syntax, I like `match` etc not needing braces, I like the function body not needing braces, and I also like the "fewer braces" lambda syntax as well. When possible, I usually opt for the braceless syntax:

```scala
def toActionResult(ar: XActionResult): ActionResult =
  val outs = ar.getOutputFilesList.asScala.toVector.map: out =>
    val d = toDigest(out.getDigest())
    HashedVirtualFileRef.of(out.getPath(), d.contentHashStr, d.sizeBytes)
  ActionResult(outs, storeName, ar.getExitCode())
```

If I may suggest something, I'd ask it to go harder by enforcing two-whitespace indentations in most places, and enforcing the [off-side rule](https://en.wikipedia.org/wiki/Off-side_rule). For example, Python 3 errors when defining a following function:

```python
>>> def foo():
      x = 1
        y = 2
  File "<stdin>", line 3
    y = 2
IndentationError: unexpected indent
```

In Scala 3, the following is allowed:

```scala
scala> def foo: Int =
         val x = 1
           val y = 2
         x + y
```

It would be nice if that were not allowed, but as I've noted, overall I'm a fan of the indentation syntax in Scala 3.

<a id="union-types"></a>
### honorable mention: Union types

Scala 3 added [union types](https://docs.scala-lang.org/scala3/reference/new-types/union-types-spec.html). I was kind of excited about the union type, but in practice I haven't used it yet.

```scala
scala> type OSIOI = Option[String] | Int | Option[Int]
// defined alias type OSIOI = Option[String] | Int | Option[Int]

scala> def foo(o: OSIOI): Option[String] =
         o match
           case None            => None
           case i: Int          => Some(i.toString)
           case Some(i: Int)    => Some(i.toString)
           case Some(s: String) => Some(s)

def foo(o: OSIOI): Option[String]

scala> foo(1)
val res1: Option[String] = Some(1)

scala> foo(Some("foo"))
val res2: Option[String] = Some(foo)
```

This does look neat. What I'm not so sure about is the following:

```scala
scala> val hmmm = if true then "bar" else Option("baz")
val hmmm: String | Option[String] = bar
```

It's great that we're no longer constructing a LUB, but even in this case, wouldn't it make more sense to error out since there are no sensible common parents between `String` and `Option[String]`?

<a id="multiversal-equality"></a>
### honorable mention: Multiversal equality

Scala 2 out of the box is notoriously loose about its equality, comparing two uncomparable values instead of failing to compile. Scala 3 added [multiversal equality](https://docs.scala-lang.org/scala3/book/ca-multiversal-equality.html) to counter this, but the feature is not enabled by default.

```scala
scala> Option(1) == Option("foo")
val res0: Boolean = false
```

Multiversal equality can be enabled with:

```scala
Compile / scalacOptions += "-language:strictEquality"
```

```scala
scala> given optionEq[A1, A2](using ev: CanEqual[A1, A2]): CanEqual[Option[A1], Option[A2]] = CanEqual.derived
def optionEq
  [A1, A2](using ev: CanEqual[A1, A2]): CanEqual[Option[A1], Option[A2]]

scala> Option(1) == Option("foo")
-- [E172] Type Error: ----------------------------------------------------------
1 |Option(1) == Option("foo")
  |^^^^^^^^^^^^^^^^^^^^^^^^^^
  |Values of types Option[Int] and Option[String] cannot be compared with == or !=.
  |I found:
  |
  |    optionEq[A1, A2](/* missing */summon[CanEqual[A1, A2]])
  |
  |But no implicit values were found that match type CanEqual[A1, A2].
1 error found

scala> Option(1) == Option(2)
val res0: Boolean = false
```

There are some minor qualms about it, but overall I think strict equality is a huge step for Scala. See also [liberty, equality, and boxed primitive types](/liberty-equality-and-boxed-primitive-types/) on this topic.

<a id="typeclass-derivation"></a>
### honorable mention: typeclass derivation

Scala 3 added support for [typeclass derivation](https://docs.scala-lang.org/scala3/reference/contextual/derivation.html), which is cool. I haven't had a chance to dig into this, so this is more of an aspirational like.

I did just *use it* in the above example:

```scala
scala> given optionEq[A1, A2](using ev: CanEqual[A1, A2]): CanEqual[Option[A1], Option[A2]] = CanEqual.derived
```

It would be fun to implement the derivation part as well.

<a id="user-land-compilation-error"></a>
### honorable mention: User-land compilation error

For displaying migration warnings and error messages, I've been advocating for [user-land compiler errors](/user-land-compiler-warnings-in-scala). In Scala 2.x, I define a simple macro that throws and error to display the error message. Scala 3 added [`scala.compiletime` module](https://docs.scala-lang.org/scala3/guides/macros/compiletime.html), which makes it relatively easy to implement:

```scala
scala> class SomeDSL[A1](a: A1):
         inline def <<=[A2](inline a2: A2): Option[A2] =
           compiletime.error("<<= is removed; migrate to := instead")
       end SomeDSL
// defined class SomeDSL

scala> SomeDSL(1) <<= 2
-- Error: ----------------------------------------------------------------------
1 |SomeDSL(1) <<= 2
  |^^^^^^^^^^^^^^^^
  |<<= is removed; migrate to := instead
1 error found
```

I hope more people would use this feature to _make illegal states unrepresentable_.

### summary

Scala 3.x is the current version of the Scala language that first came out in 2021. For those who have used Scala 2.x, they should find familar concepts all there in Scala 3. When you're ready to dig in, Scala 3.x offers more tools to write safe and expressive code.
