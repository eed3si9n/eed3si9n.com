---
title: "intro to Scala 3 macros"
date: 2021-09-06
draft: false
url:         /intro-to-scala-3-macros
aliases:     [ /node/404 ]
tags:        [ "scala" ]
---

  [metaprogramming]: https://docs.scala-lang.org/scala3/reference/metaprogramming.html
  [macros]: https://docs.scala-lang.org/scala3/reference/metaprogramming/macros.html
  [reflection]: https://docs.scala-lang.org/scala3/reference/metaprogramming/reflection.html
  [Expecty]: https://github.com/eed3si9n/expecty
  [Quotes]: https://github.com/lampepfl/dotty/blob/3.0.2/library/src/scala/quoted/Quotes.scala
  [quoted_pattern]: https://docs.scala-lang.org/scala3/reference/metaprogramming/macros.html#pattern-matching-on-quoted-expressions

### Introduction

[Macro][macros] is a fun and powerful tool, but overuse of the macro could cause harm as well. Please enjoy macros responsibly.

What is macro? A common explanation given is that a macro is a program that is able to take code as an input and output code. While it's true, it might not immediately make sense since Scala programmers are often familiar with higher-order functions like (`map {...}`) and by-name parameter, which on the surface it might seem like it is passing a block of code around.

Here's an example code from [Expecty][Expecty], an assertion macro that I ported to Scala 3:

```scala
scala> import com.eed3si9n.expecty.Expecty.assert
import com.eed3si9n.expecty.Expecty.assert

scala> assert(person.say(word1, word2) == "pong pong")
java.lang.AssertionError: assertion failed

assert(person.say(word1, word2) == "pong pong")
       |      |   |      |      |
       |      |   ping   pong   false
       |      ping pong
       Person(Fred,42)

  at com.eed3si9n.expecty.Expecty$ExpectyListener.expressionRecorded(Expecty.scala:35)
  at com.eed3si9n.expecty.RecorderRuntime.recordExpression(RecorderRuntime.scala:39)
  ... 36 elided
```

Had I used by-name argument for `assert(...)`, I could control the timing of getting the result but all I'd get would be `false`. Instead with a macro, it's able to get the shape of source code `person.say(word1, word2) == "pong pong"`, and programmatically generate the error message that includes the code and each of the values in the expression. Someone could potentially write a code that does that using `Predef.assert(...)` too, but that would be very tedious to do. This still doesn't cover the full aspect of macros.

A compiler is often thought of as something that translates some source code into a machine code. While certainly that is an aspect of it, a compiler does many more things. Among them is type checking. In addition to generating bytecode (or JS) at the end, Scala compiler acts as a lightweight proof system to catch various things like typos, and making sure that the parameter types are expected. The Java virtual machine is almost completely unaware of the Scala type system. This loss of information is sometimes referred to as type erasure, like it's a bad thing, but this duality of type and runtime enables Scala to exist at all as a guest programming language on JVM, JS, and Native.

For Scala, macro gives us a way to take actions at compile-time, and thus a way to directly talk with Scala's type system. For example, I don't think there's an accurate code one can write to detect if a given type `A` is a case class at runtime. Using macros this can be written in 5 lines:

```scala
import scala.quoted.*

inline def isCaseClass[A]: Boolean = ${ isCaseClassImpl[A] }
private def isCaseClassImpl[A: Type](using qctx: Quotes) : Expr[Boolean] =
  import qctx.reflect.*
  val sym = TypeRepr.of[A].typeSymbol
  Expr(sym.isClassDef && sym.flags.is(Flags.Case))
```

In the above `${ isCaseClassImpl[A] }` is an example of Scala 3 macro, specifically known as splicing.

#### Quotes and Splices

[Macros][macros] explain that:

> Macros are built on two well-known fundamental operations: quotation and splicing. Quotation is expressed as `'{...}` for expressions and splicing is expressed as `${ ... }`.

The entry point for macros are the only time we would see top-level splicing like `${ isCaseClassImpl[A] }`. Normally `${ ... }` appear inside of a quoted expression `'{ ... }`.

> If `e` is an expression, then `'{e}` represents the typed abstract syntax tree representing e. If `T` is a type, then `Type.of[T]` represents the type structure representing `T`. The precise definitions of "typed abstract syntax tree" or "type-structure" do not matter for now, the terms are used only to give some intuition. Conversely, `${e}` evaluates the expression e, which must yield a typed abstract syntax tree or type structure, and embeds the result as an expression (respectively, type) in the enclosing program.
>
> Quotations can have spliced parts in them; in this case the embedded splices are evaluated and embedded as part of the formation of the quotation.

So the general process is that we will capture either the term-level parameters or types, and return a typed abtract syntax tree called `Expr[A]`.

### Quotes Reflection API

The Quotes Reflection API (or Reflection API) to programmatically create types and terms are available under the quotation context `Quotes` trait.

**Note**: At first Reflection API looks more familiar, and it is useful, but part of learning Scala 3 macro is learning to use less of it, and use better syntactic facility, like plain quoting and matching on quotes, which we will cover later.

Reflection API is partly documented as [Reflection][reflection], but normally I keep [Quotes.scala][Quotes] open in a browser to learn from the source.

> With `quoted.Expr` and `quoted.Type` we can compute code but also analyze code by inspecting the ASTs. Macros provide the guarantee that the generation of code will be type-correct. Using quote reflection will break these guarantees and may fail at macro expansion time, hence additional explicit checks must be done.
>
> To provide reflection capabilities in macros we need to add an implicit parameter of type `scala.quoted.Quotes` and import `quotes.reflect.*` from it in the scope where it is used.

Reflection API introduces a rich family of types such as `Tree`, `TypeRepr`, `Symbol`, and other miscellaneous API points.

<code>
+- Tree -+- PackageClause
         |
         +- Statement -+- Import
         |             +- Export
         |             +- Definition --+- ClassDef
         |             |               +- TypeDef
         |             |               +- DefDef
         |             |               +- ValDef
         |             |
         |             +- Term --------+- Ref -+- Ident -+- Wildcard
         |                             |       +- Select
         |                             +- Apply
         |                             +- Block
....
         +- TypeTree ----+- Inferred
....
+- ParamClause -+- TypeParamClause
                +- TermParamClause
+- TypeRepr -+- NamedType -+- TermRef
             |             +- TypeRef
             +- ConstantType
....
+- Selector -+- SimpleSelector
....
+- Signature
+- Position
+- SourceFile
+- Constant -+- BooleanConstant
             +- ByteConstant
....
+- Symbol
+- Flags
</code>

To isolate the macros and the Scala 3 compiler implementation, the API is given as a set of abstract type, method extension over the abstract type, a `val` representing a companion object, and a trait desciribing the API of the companion object.

#### Tree

A `Tree` represents abstract syntax tree, or the shape of the source code understood by the Scala compiler. This includes definitions like `val ...` and `Term` like function calls. In macros, we tend to work more with `Term`, but there are some useful extension methods made available to all `Tree` subtypes. Here's the API in `Quotes.scala`. Skip over to `TreeMethods` for the list of extension methods.

```scala
/** Tree representing code written in the source */
type Tree <: AnyRef

/** Module object of `type Tree`  */
val Tree: TreeModule

/** Methods of the module object `val Tree` */
trait TreeModule { this: Tree.type => }

/** Makes extension methods on `Tree` available without any imports */
given TreeMethods: TreeMethods

/** Extension methods of `Tree` */
trait TreeMethods {

  extension (self: Tree)
    /** Position in the source code */
    def pos: Position

    /** Symbol of defined or referred by this tree */
    def symbol: Symbol

    /** Shows the tree as String */
    def show(using Printer[Tree]): String

    /** Does this tree represent a valid expression? */
    def isExpr: Boolean

    /** Convert this tree to an `quoted.Expr[Any]` if the tree is a valid expression or throws */
    def asExpr: Expr[Any]
  end extension

  /** Convert this tree to an `quoted.Expr[T]` if the tree is a valid expression or throws */
  extension (self: Tree)
    def asExprOf[T](using Type[T]): Expr[T]

  extension [ThisTree <: Tree](self: ThisTree)
    /** Changes the owner of the symbols in the tree */
    def changeOwner(newOwner: Symbol): ThisTree
  end extension

}
```

Here's an example of using `show`:

```scala
package com.eed3si9n.macroexample

import scala.quoted.*

inline def showTree[A](inline a: A): String = ${showTreeImpl[A]('{ a })}

def showTreeImpl[A: Type](a: Expr[A])(using Quotes): Expr[String] =
  import quotes.reflect.*
  Expr(a.asTerm.show)
```

This can be used as follows:

```scala
scala> import com.eed3si9n.macroexample.*

scala> showTree(List(1).map(x => x + 1))
val res0: String = scala.List.apply[scala.Int](1).map[scala.Int](((x: scala.Int) => x.+(1)))
```

It might be interesting to see the inferred types fully spelled out, but often times what I'm looking for is the tree structure of the given code.

#### Printer

To see the structure of AST, we can use `Printer.TreeStructure.show(...)`:

<scala>
package com.eed3si9n.macroexample

import scala.quoted.*

inline def showTree[A](inline a: A): String = ${showTreeImpl[A]('{ a })}

def showTreeImpl[A: Type](a: Expr[A])(using Quotes): Expr[String] =
  import quotes.reflect.*
  Expr(Printer.TreeStructure.show(a.asTerm))
</scala>

Let's try again:

<scala>
scala> import com.eed3si9n.macroexample.*

scala> showTree(List(1).map(x => x + 1))
val res0: String = Inlined(None, Nil, Apply(TypeApply(Select(Apply(TypeApply(Select(Ident("List"), "apply"), List(Inferred())), List(Typed(Repeated(List(Literal(IntConstant(1))), Inferred()), Inferred()))), "map"), List(Inferred())), List(Block(List(DefDef("$anonfun", List(TermParamClause(List(ValDef("x", Inferred(), None)))), Inferred(), Some(Apply(Select(Ident("x"), "+"), List(Literal(IntConstant(1))))))), Closure(Ident("$anonfun"), None)))))
</scala>

Yes. This is the stuff. Note that this tree encoding may or may not be stable across Scala 3.x versions, so it might be safe not to rely too much on the exact details, and use the provided `unapply` extractors (I don't know if there's been a promise one way or the other). But this is useful tool to have to compare what the compiler would construct against what you need to construct synthetically.

#### Literal

We don't typically need to construct `Literal(...)` tree in this way, but since it's the foundational tree, it's easier to explain on its own:

<scala>
/** `TypeTest` that allows testing at runtime in a pattern match if a `Tree` is a `Literal` */
given LiteralTypeTest: TypeTest[Tree, Literal]

/** Tree representing a literal value in the source code */
type Literal <: Term

/** Module object of `type Literal`  */
val Literal: LiteralModule

/** Methods of the module object `val Literal` */
trait LiteralModule { this: Literal.type =>

  /** Create a literal constant */
  def apply(constant: Constant): Literal

  def copy(original: Tree)(constant: Constant): Literal

  /** Matches a literal constant */
  def unapply(x: Literal): Some[Constant]
}

/** Makes extension methods on `Literal` available without any imports */
given LiteralMethods: LiteralMethods

/** Extension methods of `Literal` */
trait LiteralMethods:
  extension (self: Literal)
    /** Value of this literal */
    def constant: Constant
  end extension
end LiteralMethods
</scala>

The abstract type `type Literal` represents the `Literal` tree, and `LiteralModule` describes the companion object `Literal`. Here we see that it provides `apply(...)`, `copy(...)`, and `unapply(...)`.

Using this, we should be able implement `addOne(...)` macro that takes an `Int` literal and inlines with that number plus one at compile-time. Note that this is different from returning `n + 1`. `n + 1` would compute that at runtime. What we want is for the `*.class` to contain `2` if we passed in `1` so there's no calculation.

<scala>
package com.eed3si9n.macroexample

import scala.quoted.*

inline def addOne_bad(inline x: Int): Int = ${addOne_badImpl('{x})}

def addOne_badImpl(x: Expr[Int])(using Quotes): Expr[Int] =
  import quotes.reflect.*
  x.asTerm match
    case Inlined(_, _, Literal(IntConstant(n))) =>
      Literal(IntConstant(n + 1)).asExprOf[Int]
</scala>

This looks too verbose without much benefit.

#### FromExpr typeclass

For any types that form `FromExpr` typeclass instance, such as `Int`, it would be easier to use `.value` extension method on `Expr`, which is defined as follows:

<scala>
def value(using FromExpr[T]): Option[T] =
  given Quotes = Quotes.this
  summon[FromExpr[T]].unapply(self)
</scala>

Similarly, there's `ToExpr` typeclass that can use `Expr.apply(...)` to construct `Expr` easier.

So, using these and `.value`'s sibling `.valueOrError`, `addOne(...)` macro can be written as one-liner macro:

<scala>
package com.eed3si9n.macroexample

import scala.quoted.*

inline def addOne(inline x: Int): Int = ${addOneImpl('{x})}

def addOneImpl(x: Expr[Int])(using Quotes): Expr[Int] =
  Expr(x.valueOrError + 1)
</scala>

Not only is this simpler, we're not using Reflection API, so it's more typesafe.

#### Position

As another demonstration of a feature available to macros, let's look into `Position`. `Position` represents a position in the source code, like file names and line number.

Here's a macro that implements `Source.line` function.

<scala>
package com.eed3si9n.macroexample

import scala.quoted.*

object Source:
  inline def line: Int = ${lineImpl()}
  def lineImpl()(using Quotes): Expr[Int] =
    import quotes.reflect.*
    val pos = Position.ofMacroExpansion
    Expr(pos.startLine + 1)
end Source
</scala>

This can be used like this:

<scala>
package com.eed3si9n.macroexample

object PositionTest extends verify.BasicTestSuite:
  test("testLine") {
    assert(Source.line == 5)
  }
end PositionTest
</scala>

#### Apply

Most practical macros would involve method invocations, so let's look at `Apply`. Here's an example of a macro that returns `addOne` result in a `List`.

<scala>
package com.eed3si9n.macroexample

import scala.quoted.*

inline def addOneList(inline x: Int): List[Int] = ${addOneListImpl('{x})}

def addOneListImpl(x: Expr[Int])(using Quotes): Expr[List[Int]] =
  val inner = Expr(x.valueOrError + 1)
  '{ List($inner) }
</scala>

Instead of manually creating `Apply(...)` tree, we used plain Scala to write the `List(...)` invocation, splice the inner expression in, and quote the whole thing using `'{ ... }`. This is really nice because accurately describing `List(...)` method is tedious, considering that it's actually `_root_.scala.collection.immutable.List.apply[Int](...)`.

In general however, method invocation comes up fairly frequently so there are a few convenient extension methods on all `Term`.

<scala>
/** A unary apply node with given argument: `tree(arg)` */
def appliedTo(arg: Term): Term

/** An apply node with given arguments: `tree(arg, args0, ..., argsN)` */
def appliedTo(arg: Term, args: Term*): Term

/** An apply node with given argument list `tree(args(0), ..., args(args.length - 1))` */
def appliedToArgs(args: List[Term]): Apply

/** The current tree applied to given argument lists:
*  `tree (argss(0)) ... (argss(argss.length -1))`
*/
def appliedToArgss(argss: List[List[Term]]): Term

/** The current tree applied to (): `tree()` */
def appliedToNone: Apply
</scala>

Here's a silly macro that adds one and then calls `toString` method.

<scala>
package com.eed3si9n.macroexample

import scala.quoted.*

inline def addOneToString(inline x: Int): String = ${addOneToStringImpl('{x})}

def addOneToStringImpl(x: Expr[Int])(using Quotes): Expr[String] =
  import quotes.reflect.*
  val inner = Literal(IntConstant(x.valueOrError + 1))
  Select.unique(inner, "toString").appliedToNone.asExprOf[String]
</scala>

#### Select

`Select` is also pretty major. In the above we used `Select.unique(term, <method name>)`.

`Select` has a bunch of functions under it to disambiguate overloaded methods.

#### ValDef

`ValDef` represents a `val` definition.

We can define a value `x` and return a reference to it using quotes as follows:

<scala>
package com.eed3si9n.macroexample

import scala.quoted.*

inline def addOneX(inline x: Int): Int = ${addOneXImpl('{x})}

def addOneXImpl(x: Expr[Int])(using Quotes): Expr[Int] =
  val rhs = Expr(x.valueOrError + 1)
  '{
    val x = $rhs
    x
  }
</scala>

But let's say for some reason you want to do this programmatically. First you need to create a symbol for the new `val`. For that you'd need `TypeRepr` and `Flags`.

<scala>
inline def addOneXv2(inline x: Int): Int = ${addOneXv2Impl('{x})}

def addOneXv2Impl(x: Expr[Int])(using Quotes): Expr[Int] =
  import quotes.reflect.*
  val rhs = Expr(x.valueOrError + 1)
  val sym = Symbol.newVal(
    Symbol.spliceOwner,
    "x",
    TypeRepr.of[Int],
    Flags.EmptyFlags,
    Symbol.noSymbol,
  )
  val vd = ValDef(sym, Some(rhs.asTerm))
  Block(
    List(vd),
    Ref(sym)
  ).asExprOf[Int]
</scala>

#### Symbol and Ref

We can think of symbol as an accurate name to things like classes, `val`, and types.
Symbols are created when we define entities like `val`, and we can later use that to reference the `val`. The real compiler would go through `import` and nested blocks and eventually resolve to the correct symbol, but we can skip the whole process and use `Ref(sym)`.

#### TypeRepr

`TypeRepr` represents types and type-related operations in macro-time. Because type information is erased at runtime, using macro gives us the ability to directly handle Scala's type information.

The example of checking if a given type `A` is a case class or not is a good example of obtaining `TypeRepr`.

<scala>
import scala.quoted.*

inline def isCaseClass[A]: Boolean = ${ isCaseClassImpl[A] }

private def isCaseClassImpl[A: Type](using qctx: Quotes) : Expr[Boolean] =
  import qctx.reflect.*
  val sym = TypeRepr.of[A].typeSymbol
  Expr(sym.isClassDef && sym.flags.is(Flags.Case))
</scala>

Here's the `TypeRepr` API.

<scala>
/** A type, type constructors, type bounds or NoPrefix */
type TypeRepr

/** Module object of `type TypeRepr`  */
val TypeRepr: TypeReprModule

/** Methods of the module object `val TypeRepr` */
trait TypeReprModule { this: TypeRepr.type =>
  /** Returns the type or kind (TypeRepr) of T */
  def of[T <: AnyKind](using Type[T]): TypeRepr

  /** Returns the type constructor of the runtime (erased) class */
  def typeConstructorOf(clazz: Class[?]): TypeRepr
}

/** Makes extension methods on `TypeRepr` available without any imports */
given TypeReprMethods: TypeReprMethods

/** Extension methods of `TypeRepr` */
trait TypeReprMethods {
  extension (self: TypeRepr)

    /** Shows the type as a String */
    def show(using Printer[TypeRepr]): String

    /** Convert this `TypeRepr` to an `Type[?]` */
    def asType: Type[?]

    /** Is `self` type the same as `that` type?
    *  This is the case iff `self <:< that` and `that <:< self`.
    */
    def =:=(that: TypeRepr): Boolean

    /** Is this type a subtype of that type? */
    def <:<(that: TypeRepr): Boolean

    /** Widen from singleton type to its underlying non-singleton
     *  base type by applying one or more `underlying` dereferences,
     *  Also go from => T to T.
     *  Identity for all other types. Example:
     *
     *  class Outer { class C ; val x: C }
     *  def o: Outer
     *  <o.x.type>.widen = o.C
     */
    def widen: TypeRepr

    /** Widen from TermRef to its underlying non-termref
     *  base type, while also skipping ByName types.
     */
    def widenTermRefByName: TypeRepr

    /** Widen from ByName type to its result type. */
    def widenByName: TypeRepr

    /** Follow aliases, annotated types until type is no longer alias type, annotated type. */
    def dealias: TypeRepr

    /** A simplified version of this type which is equivalent wrt =:= to this type.
    *  Reduces typerefs, applied match types, and and or types.
    */
    def simplified: TypeRepr

    def classSymbol: Option[Symbol]
    def typeSymbol: Symbol
    def termSymbol: Symbol
    def isSingleton: Boolean
    def memberType(member: Symbol): TypeRepr

    /** The base classes of this type with the class itself as first element. */
    def baseClasses: List[Symbol]

    /** The least type instance of given class which is a super-type
    *  of this type.  Example:
    *  {{{
    *    class D[T]
    *    class C extends p.D[Int]
    *    ThisType(C).baseType(D) = p.D[Int]
    * }}}
    */
    def baseType(cls: Symbol): TypeRepr

    /** Is this type an instance of a non-bottom subclass of the given class `cls`? */
    def derivesFrom(cls: Symbol): Boolean

    /** Is this type a function type?
    *
    *  @return true if the dealiased type of `self` without refinement is `FunctionN[T1, T2, ..., Tn]`
    *
    *  @note The function
    *
    *     - returns true for `given Int => Int` and `erased Int => Int`
    *     - returns false for `List[Int]`, despite that `List[Int] <:< Int => Int`.
    */
    def isFunctionType: Boolean

    /** Is this type an context function type?
    *
    *  @see `isFunctionType`
    */
    def isContextFunctionType: Boolean

    /** Is this type an erased function type?
    *
    *  @see `isFunctionType`
    */
    def isErasedFunctionType: Boolean

    /** Is this type a dependent function type?
    *
    *  @see `isFunctionType`
    */
    def isDependentFunctionType: Boolean

    /** The type <this . sym>, reduced if possible */
    def select(sym: Symbol): TypeRepr

    /** The current type applied to given type arguments: `this[targ]` */
    def appliedTo(targ: TypeRepr): TypeRepr

    /** The current type applied to given type arguments: `this[targ0, ..., targN]` */
    def appliedTo(targs: List[TypeRepr]): TypeRepr

  end extension
}
</scala>

Let's try using some of the extension methods under `TypeRepr`. Here's a macro to check if two types are equal:

<scala>
package com.eed3si9n.macroexample

import scala.quoted.*

inline def typeEq[A1, A2]: Boolean = ${ typeEqImpl[A1, A2] }

def typeEqImpl[A1: Type, A2: Type](using Quotes): Expr[Boolean] =
  import quotes.reflect.*
  Expr(TypeRepr.of[A1] =:= TypeRepr.of[A2])
</scala>

`typeEq` can be used as follows:

<scala>
scala> import com.eed3si9n.macroexample.*

scala> typeEq[scala.Predef.String, java.lang.String]
val res0: Boolean = true

scala> typeEq[Int, java.lang.Integer]
val res1: Boolean = false
</scala>

#### AppliedType

One of the information that is erased is type parameters in a parameterized type like `List[Int]`. The tricky part is deconstructing the `TypeRepr` information into the type application parts.

We can use `TypeTest[TypeRepr, AppliedType]`, but the compiler performs some magic so we can write it as a normal pattern matching. Here's a macro to return the type parameter names.

<scala>
package com.eed3si9n.macroexample

import scala.quoted.*
import scala.reflect.*

inline def paramInfo[A]: List[String] = ${paramInfoImpl[A]}

def paramInfoImpl[A: Type](using Quotes): Expr[List[String]] =
  import quotes.reflect.*
  val tpe = TypeRepr.of[A]
  val targs = tpe.widenTermRefByName.dealias match
    case AppliedType(_, args) => args
    case _                    => Nil
  Expr(targs.map(_.show))
</scala>

This can be used like this:

<scala>
scala> import com.eed3si9n.macroexample.*

scala> paramInfo[List[Int]]
val res0: List[String] = List(scala.Int)

scala> paramInfo[Int]
val res1: List[String] = List()
</scala>

#### Select as extractor

Thus far we have been using plain values like `1` to pass to the macros. We can make this more creative by passing function calls into a macro that manipulates the function call.

For example we can create a dummy function `echo`:

<scala>
import scala.annotation.compileTimeOnly

object Dummy:
  @compileTimeOnly("echo can only be used in lines macro")
  def echo(line: String): String = ???
end Dummy
</scala>

We can implement `Source.lines(...)` macro that will substitute `Dummy.echo(...)` with the input prepended by the line number.

<scala>
package com.eed3si9n.macroexample

import scala.annotation.compileTimeOnly
import scala.quoted.*

object Source:
  inline def lines_bad(inline xs: List[String]): List[String] = ${lines_badImpl('{ xs })}

  def lines_badImpl(xs: Expr[List[String]])(using Quotes): Expr[List[String]] =
    import quotes.reflect.*
    val dummySym = Symbol.requiredModule("com.eed3si9n.macroexample.Dummy")
    xs match
      case ListApply(args) =>
        val args2 = args map { arg =>
          arg.asTerm match
            case a @ Apply(Select(qual, "echo"), List(Literal(StringConstant(str)))) if qual.symbol == dummySym =>
              val pos = a.pos
              Expr(s"${pos.startLine + 1}: $str")
            case _ => arg
        }
        '{ List(${ Varargs[String](args2.toList) }: _*) }

  // bad example. see below for quoted pattern.
  object ListApply:
    def unapply(expr: Expr[List[String]])(using Quotes): Option[Seq[Expr[String]]] =
      import quotes.reflect.*
      def rec(tree: Term): Option[Seq[Expr[String]]] =
        tree match
          case Inlined(_, _, e) => rec(e)
          case Block(Nil, e)    => rec(e)
          case Typed(e, _)      => rec(e)
          case Apply(TypeApply(Select(obj, "apply"), _), List(e)) if obj.symbol.name == "List" => rec(e)
          case Repeated(elems, _) => Some(elems.map(_.asExprOf[String]))
      rec(expr.asTerm)
  end ListApply

end Source

object Dummy:
  @compileTimeOnly("echo can only be used in lines macro")
  def echo(line: String): String = ???
end Dummy
</scala>

This is tested as follows:

<scala>
package com.eed3si9n.macroexample

object LinesTest extends verify.BasicTestSuite:
  test("lines") {
    assert(Source.lines(List(
      "foo",
      Dummy.echo("bar"),
    )) == List(
      "foo",
      "7: bar"
    ))
  }
end LinesTest
</scala>

#### Quotes as extractor

In the above, I'm doing a lot of work just to extract the argument of `List(...)` apply expression. We can improve this by using quotes as extractor instead. This is documented as [quoted patterns][quoted_pattern].

> Patterns `'{ ... }` can be placed in any location where Scala expects a pattern.

Here's an improved version of `lines(...)` macro that substitutes `Dummy.echo(...)`.

<scala>
package com.eed3si9n.macroexample

import scala.annotation.compileTimeOnly
import scala.quoted.*

object Source:
  inline def linesv2(inline xs: List[String]): List[String] = ${linesv2Impl('{ xs })}

  def linesv2Impl(xs: Expr[List[String]])(using Quotes): Expr[List[String]] =
    import quotes.reflect.*
    xs match
      case '{ List[String]($vargs*) } =>
        vargs match
          case Varargs(args) =>
            val args2 = args map { arg =>
              arg match
                case '{ Dummy.echo($str) } =>
                  val pos = arg.asTerm.pos
                  Expr(s"${pos.startLine + 1}: ${ str.valueOrError }")
                case _ => arg
            }
            '{ List(${ Varargs[String](args2.toList) }: _*) }
end Source

object Dummy:
  @compileTimeOnly("echo can only be used in lines macro")
  def echo(line: String): String = ???
end Dummy
</scala>

Note that we were able to remove the awkward symbol lookup for `Dummy.echo` method as well.

#### Splicing a type in

Going back to `TypeRepr`, there's a common pattern where you want to construct some type using `TypeRepr`, and you want to splice that back into the generated code.

Let's create a macro that takes two parameters `a: A` and `String`, and if the second parameter is `"String"` declare an `Either[String, A]`, and if the second parameter is `"List[String]"`, make `Either[List[String], A]`. We can then do some operation on top like `flatMap` to check if the value is zero.

<scala>
package com.eed3si9n.macroexample

import scala.quoted.*

inline def right[A](inline a: A, inline which: String): String =
  ${ rightImpl[A]('{ a }, '{ which }) }

def rightImpl[A: Type](a: Expr[A], which: Expr[String])(using Quotes): Expr[String] =
  import quotes.reflect.*
  val w = which.valueOrError
  val leftTpe = w match
    case "String"       => TypeRepr.of[String]
    case "List[String]" => TypeRepr.of[List[String]]
  val msg = w match
    case "String"       => Expr("empty not allowed")
    case "List[String]" => Expr(List("empty not allowed"))
  leftTpe.asType match
    case '[l] =>
      '{
        val e0: Either[l, A] = Right[l, A]($a)
        val e1 = e0 flatMap { x =>
          if x == null.asInstanceOf[A] then Left[l, A]($msg.asInstanceOf[l])
          else Right(x)
        }
        e1.toString
      }
</scala>

In other words, when we need to manipulate type information within a macro we summon `TypeRepr[_]`, but when it's time to splice a type back into the Scala code, we need to create `Type[_]`. Here's how we can use this:

<scala>
scala> import com.eed3si9n.macroexample.*

scala> right(1, "String")
val res0: String = Right(1)

scala> right(0, "String")
val res1: String = Left(empty not allowed)

scala> right[String](null, "List[String]")
val res2: String = Left(List(empty not allowed))
</scala>

Also this is an example of a macro where the input and output are pre-determined by the function signature, but the internal implementation create different types depending on the input.

### Restligeist macro

Restligeist macro is a macro that immediately fails. One use case is displaying a migration message for a removed API. In Scala 3, it's a one-liner to cause a user-land compilation error:

<scala>
package com.eed3si9n.macroexample

object SomeDSL:
  inline def <<=[A](inline a: A): Option[A] =
    compiletime.error("<<= is removed; migrated to := instead")
end SomeDSL
</scala>

Here's how it would look using it:

<scala>
scala> import com.eed3si9n.macroexample.*

scala> SomeDSL.<<=((1, "foo"))
-- Error:
1 |SomeDSL.<<=((1, "foo"))
  |^^^^^^^^^^^^^^^^^^^^^^^
  |<<= is removed; migrated to := instead
</scala>

### Summary

Macros in Scala 3 brings out a different level of capability in programming, which is to manipulate the shape of source code using Scala syntax itself, and also to directly interact with the type system. Where possible, we should opt to use the Scala syntax to construct the quoted code instead of programmatically constructing the AST via (Quote) Reflection API.

If we need more programmatic flexibility, Reflection API provides a rich family of types like `Tree`, `Symbol`, and `TypeRepr`. This is partly documented as [Reflection][reflection], but at this point, the most useful source of information is [Quotes.scala][Quotes].

Using quotes as pattern matching is generally more type safe, and we might also be able to avoid the macro getting hardcoded to the specific `Tree` implementation of the Scala version we're using.
