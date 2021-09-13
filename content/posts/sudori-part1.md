---
title:       "sudori part 1"
type:        story
date:        2021-07-18
draft:       false
promote:     true
sticky:      false
url:         /sudori-part1
aliases:     [ /node/399 ]
tags:        [ "sbt" ]
---

  [Convert]: https://github.com/sbt/sbt/blob/v1.5.5/core-macros/src/main/scala/sbt/internal/util/appmacro/Convert.scala
  [metaprogramming]: http://dotty.epfl.ch/docs/reference/metaprogramming/toc.html
  [Enum]: http://dotty.epfl.ch/docs/reference/enums/adts.html
  [TypeProjection]: http://dotty.epfl.ch/docs/reference/dropped-features/type-projection.html
  [so-50043630]: https://stackoverflow.com/q/50043630/3827
  [Tree]: https://github.com/lampepfl/dotty/blob/3.0.1/library/src/scala/quoted/Quotes.scala#L255
  [Transformer]: https://github.com/scala/scala/blob/v2.13.6/src/reflect/scala/reflect/api/Trees.scala#L2563
  [TreeMap]: https://github.com/lampepfl/dotty/blob/3.0.1/library/src/scala/quoted/Quotes.scala#L4370
  [Type]: http://dotty.epfl.ch/docs/reference/metaprogramming/macros.html#types-for-quotations
  [statically-unknown]: https://docs.scala-lang.org/scala3/guides/macros/faq.html#how-do-i-summon-an-expression-for-statically-unknown-types

I'm hacking on a small project called sudori, an experimental sbt. The initial goal is to port the macro to Scala 3. It's an exercise to take the macro apart and see if we can build it from the ground up. This an advanced area of Scala 2 and 3, and I'm finding my way around by trial and error.

Reference:
- [Scala 3 Reference: Metaprogramming][metaprogramming]

### Convert

I think I've identified a basic part called [Convert][Convert], which doesn't really depend on anything.

<scala>
abstract class Convert {
  def apply[T: c.WeakTypeTag](c: blackbox.Context)(nme: String, in: c.Tree): Converted[c.type]

  ....
}
</scala>

This looks to be a glorified partial function that takes in a `Tree` and returns `Converted`, which is an abstract data type with a type parameter `[C <: blackbox.Context with Singleton]` like:

<scala>
  final case class Success[C <: blackbox.Context with Singleton](
      tree: C#Tree,
      finalTransform: C#Tree => C#Tree
  ) extends Converted[C] {
    def isSuccess = true
    def transform(f: C#Tree => C#Tree): Converted[C] = Success(f(tree), finalTransform)
  }
</scala>

This is typical of older Scala 2 macro implementation to directly deal with `Tree`, or Abstract Syntax Tree (AST) in this fashion, but Scala 3 has much nicer higher level [metaprogramming][metaprogramming] faciliy like `inline`, so it's recommended to start with those first.

In this case, I want to port the existing macros so I'm directly jumping to quote reflection, which feels a lot like Scala 2 macros.

#### Enums

Defining an [enum][Enum] looks like this:

<scala>
import scala.quoted.*

enum Converted[C <: Quotes]:
  case Success() extends Converted[C]
  case Failure() extends Converted[C]
  case NotApplicable() extends Converted[C]
end Converted
</scala>

Unlike sealed trait and case classes, the methods under the ADT would also go into `enum`:

<scala>
import scala.quoted.*

enum Converted[C <: Quotes]:
  def isSuccess: Boolean = this match
    case Success() => true
    case _         => false

  case Success() extends Converted[C]
  case Failure() extends Converted[C]
  case NotApplicable() extends Converted[C]
end Converted
</scala>

This makes sense, as we can now think of `Success()` vs `Failure()` as different values of `Converted[C]` type.

#### Type projection is gone

Scala 3 dropped general [type projection][TypeProjection] `C#A`. So this is going to be a challenge because `Success` actually takes two parameters `C#Tree` and `C#Tree => C#Tree`. There's a stackoverflow question [What does Dotty offer to replace type projections?][so-50043630].

One solution that is suggested is path-dependent type. In our case, quote reflection's [Tree][Tree] hangs under `qctx.reflection` like `qctx.reflection.Tree`, so this is likely the way to go.

So now `Success` and `Failure` looks like this:

<scala>
enum Converted[C <: Quotes](val qctx: C):
  def isSuccess: Boolean = this match
    case _: Success[C] => true
    case _             => false

  case Success(override val qctx: C)(
      val tree: qctx.reflect.Term,
      val finalTransform: qctx.reflect.Term => qctx.reflect.Term)
    extends Converted[C](qctx)

  case Failure(override val qctx: C)(
      val position: qctx.reflect.Position,
      val message: String)
    extends Converted[C](qctx)
end Converted
</scala>

Theses cases have multiple parameters so we can use `qctx.reflect.Term` from `qctx` in the first parameter list. Now the more difficult part is implementing the `transform` method.

<scala>
enum Converted[C <: Quotes](val qctx: C):
  def isSuccess: Boolean = this match
    case _: Success[C] => true
    case _             => false

  def transform(f: qctx.reflect.Term => qctx.reflect.Term): Converted[C] = this match
    case x: Failure[C]       => Failure(x.qctx)(x.position, x.message)
    case x: Success[C] if x.qctx == qctx =>
      Success(x.qctx)(
        f(x.tree.asInstanceOf[qctx.reflect.Term]).asInstanceOf[x.qctx.reflect.Term],
        x.finalTransform)
    case x: NotApplicable[C] => x
    case x                   => sys.error(s"Unknown case $x")

end Converted
</scala>

`transform` applies the function `f` to the tree stored in `Success(...)`, but I don't know if there's a way to tell the compiler that `qctx` used in `transform` is the same value as the one captured in `Success(...)`.

#### Cake trait

There is a way to remove this ugly casting, and that is to define an outer trait.

<scala>
trait Convert[C <: Quotes & Singleton](val qctx: C):
  import qctx.reflect.*
  given qctx.type = qctx

  ....

end Convert
</scala>

Now within the `Convert` trait, `Term` would always mean `qctx.reflex.Term`. I'm not actually sure if creating type parameter `C` is useful if we're not using `C`.

<scala>
trait Convert[C <: Quotes & Singleton](val qctx: C):
  import qctx.reflect.*
  given qctx.type = qctx

  def convert[A: Type](nme: String, in: Term): Converted

  object Converted:
    def success(tree: Term) = Converted.Success(tree, Types.idFun)

  enum Converted:
    def isSuccess: Boolean = this match
      case Success(_, _) => true
      case _             => false

    def transform(f: Term => Term): Converted = this match
      case Success(tree, finalTransform) => Success(f(tree), finalTransform)
      case x: Failure       => x
      case x: NotApplicable => x

    case Success(tree: Term, finalTransform: Term => Term) extends Converted
    case Failure(position: Position, message: String) extends Converted
    case NotApplicable() extends Converted
  end Converted
end Convert
</scala>

The implementation becomes simpler and shorter too. The drawback is that now `Converted` becomes a nested type of `Convert`, so we might have to deal with path-dependent type later to use it.

Before we go too far, I want to make sure that this trait is composable. First, let's check that a function inside `Convert` can pass `Term` to another function in another module. This is to check that we're not trapped in path-dependency specific to this `qctx` only. Consider a module like this:

<scala>
object SomeModule:
  def something(using qctx0: Quotes)(tree: qctx0.reflect.Term): qctx0.reflect.Term =
    tree

end SomeModule
</scala>

Here's how we can call `SomeModule.something`:

<scala>
trait Convert[C <: Quotes & Singleton](override val qctx: C):
  import qctx.reflect.*
  given qctx.type = qctx

  def test(term: Term): Term =
    SomeModule.something(term)

  ....
</scala>

This compiled without casting, so this is looking good. This is the purpose for the `given` instance for `qctx.type` so we don't have to pass around it explicitly. Another way of composing this Cake trait is to stack it with another trait:

<scala>
import scala.quoted.*

trait ContextUtil[C <: Quotes & Singleton](val qctx: C):
  import qctx.reflect.*
  given qctx.type = qctx

  def something1(tree: Term): Term =
    tree
end ContextUtil
</scala>

We can make `Convert` extend `ContextUtil` to reduce common functions:

<scala>
trait Convert[C <: Quotes & Singleton](override val qctx: C) extends ContextUtil[C]:
  import qctx.reflect.*

  def test(term: Term): Term =
    something1(term)

  ....
</scala>

This too compiles without casting, which is good.

#### TreeMap

A common pattern in a macro is to traverse the passed in abstract syntax tree (AST), and convert specific parts under some condition. This traversal is often called "tree walking." This traversal and conversion is so common there's an API for this.

In Scala 2, this is done by extending [Transformer][Transformer]. In Scala 3, it's called [TreeMap][TreeMap]. It's a cute name, but it might be confusing with `scala.collection.immutable.TreeMap`. To use the `TreeMap`, you have to read the implementation and pick which method to override. You might think `transformTree` at first, but the likely one you'd want is `transformTerm`.

<scala>
  def transformWrappers(
    tree: Term,
    subWrapper: (String, Type[_], Term, Term) => Converted
  ): Term =
    // the main tree transformer that replaces calls to InputWrapper.wrap(x) with
    //  plain Idents that reference the actual input value
    object appTransformer extends TreeMap:
      override def transformTerm(tree: Term)(owner: Symbol): Term =
        tree match
          case Apply(TypeApply(Select(_, nme), targ :: Nil), qual :: Nil) =>
            subWrapper(nme, targ.tpe.asType, qual, tree) match
              case Converted.Success(tree, finalTransform) =>
                finalTransform(tree)
              case Converted.Failure(position, message) =>
                report.error(message, position)
                sys.error("macro error: " + message)
              case _ =>
                super.transformTerm(tree)(owner)
          case _ =>
            super.transformTerm(tree)(owner)
    end appTransformer
    appTransformer.transformTerm(tree)(Symbol.spliceOwner)
</scala>

#### Example convert

Here's an example convert:

<scala>
  final val WrapInitName = "wrapInit"
  final val WrapInitTaskName = "wrapInitTask"

  class InputInitConvert[C <: Quotes & Singleton](override val qctx: C) extends Convert[C](qctx):
    import qctx.reflect.*
    def convert[A: Type](nme: String, in: Term): Converted =
      nme match
        case WrapInitName     => Converted.success(in)
        case WrapInitTaskName => Converted.Failure(in.pos, initTaskErrorMessage)
        case _                => Converted.NotApplicable()

    private def initTaskErrorMessage = "Internal sbt error: initialize+task wrapper not split"
  end InputInitConvert
</scala>

This is similar to an actual convert used in sbt that matches `wrapInit` method. Using this, we can define a macro that would substitite `ConvertTest.wrapInit(1)` with `2`.

<scala>
  inline def someMacro(inline expr: Boolean): Boolean =
    ${ someMacroImpl('expr) }

  def someMacroImpl(expr: Expr[Boolean])(using qctx0: Quotes) =
    val convert1: Convert[qctx.type] = new InputInitConvert(qctx)
    import convert1.qctx.reflect.*
    def substitute(name: String, tpe: Type[_], qual: Term, replace: Term) =
      convert1.convert[Boolean](name, qual) transform { (tree: Term) =>
        '{ 2 }.asTerm
      }
    convert1.transformWrappers(expr.asTerm, substitute).asExprOf[Boolean]
</scala>

We can test this using Verify as follows:

<scala>
import verify.*
import ConvertTestMacro._

object ConvertTest extends BasicTestSuite:
  test("convert") {
    assert(someMacro(ConvertTest.wrapInit(1) == 2))
  }

  def wrapInit[A](a: A): Int = 2
end ConvertTest
</scala>

There are two layers of filtering going on here. First, the `TreeMap` we defined called `appTransformer` only looks at invocations of generic function with a single parameter. Next, `convert1` only considers `wrapInit` as the successful method name.

#### Reified Type and turning it back into a type

Some interesting bits about the tree walking is that we have the type information of the tree at this point. The type argument of `wrapInit[A](...)` is passed in as `TypeApply(...)` tree. This is then turned into `Type[_]` data structure using `targ.tpe.asType`. [Type[T]][Type] is described as "non-erased representation of type `T`."

So that's passed into the `substitute` function as `Type[_]`. Since this is grabbing any `wrapInit[A](...)`, we can't be more specific than `Type[_]`. But we would like to unmarshal this as `T` that we can use. There's a related question in Scala 3 macro FAQ called [How do I summon an expression for statically unknown types?][statically-unknown]

<scala>
val tpe: Type[_] = ...
tpe match
  // (1) Use `a` as the name of the unknown type and (2) bring a given `Type[a]` into scope
  case '[a] => Expr.summon[a]
</scala>

This is pretty cool. Using this technique, we can implement `addType(...)` to wrap `A` into `Option[A]`.

<scala>
  inline def someMacro(inline expr: Boolean): Boolean =
    ${ someMacroImpl('expr) }

  def someMacroImpl(expr: Expr[Boolean])(using qctx0: Quotes) =
    val convert1: Convert[qctx.type] = new InputInitConvert(qctx)
    import convert1.qctx.reflect.*
    def addTypeCon(tpe: Type[_], qual: Term, selection: Term): Term =
      tpe match
        case '[a] =>
          '{
            Option[a](${selection.asExprOf[a]})
          }.asTerm
    def substitute(name: String, tpe: Type[_], qual: Term, replace: Term) =
      convert1.convert[Boolean](name, qual) transform { (tree: Term) =>
        addTypeCon(tpe, tree, replace)
      }
    convert1.transformWrappers(expr.asTerm, substitute).asExprOf[Boolean]
</scala>

This can be tested as follows:

<scala>
object ConvertTest extends BasicTestSuite:
  test("convert") {
    assert(someMacro(ConvertTest.wrapInit(1).toString == "Some(2)"))
  }

  def wrapInit[A](a: A): Int = 2
end ConvertTest
</scala>

In other words, we now have a macro that would rewrite `ConvertTest.wrapInit(1)`, which returns `2` into `Option(2)`. This type of wrapping values with a type constructor is exactly what happens within `build.sbt`.

### sudori

The word ketchup is said to derive from Hokkien word 膎汁 (kôe-chiap or kê-chiap) from southern coastal China, meaning fish sauce, which re-entered China from Vietnam in 1700s. Through trade, fish sauce also became popular in Britain where it eventually became mushroom paste. In 1800s, Americans started making it with tomatoes. In a sense, it's interesting how Cantonese dish such as sweet and sour pork incorporates ketchup into the recipe. Often made with bell peppers and pineapple and written as 咕嚕肉 (gūlōuyuhk) in Cantonese, "gulou" symbolizes the sound of rumbling stomach. In Japan, this dish is called 酢豚 (subuta), or vinegar pork, and is one of bacronyms for sbt. 酢鶏 (sudori), or vinegar chicken, is a variant of subuta substituting pork with chicken.

### Summary

- Quotes reflection provides manipulation of the tree
- It's difficult to keep the path-dependent type consistent. Cake trait can help.
- Use TreeMap for tree walking
- Type information can be represented as `Type[T]`, and quoted back in
