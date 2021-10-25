---
title:       "Scala 3 マクロ入門"
date: 2021-09-06
type:        story
draft: false
url:         /ja/intro-to-scala-3-macros
aliases:     [ /node/405 ]
tags:        [ "scala" ]
---

  [metaprogramming]: https://docs.scala-lang.org/scala3/reference/metaprogramming.html
  [macros]: https://docs.scala-lang.org/scala3/reference/metaprogramming/macros.html
  [reflection]: https://docs.scala-lang.org/scala3/reference/metaprogramming/reflection.html
  [Expecty]: https://github.com/eed3si9n/expecty
  [Quotes]: https://github.com/lampepfl/dotty/blob/3.0.2/library/src/scala/quoted/Quotes.scala
  [quoted_pattern]: https://docs.scala-lang.org/scala3/reference/metaprogramming/macros.html#pattern-matching-on-quoted-expressions

### はじめに

[マクロ][macros]は楽しくかつ強力なツールだが、使いすぎは害もある。責任を持って適度にマクロを楽しんでほしい。

マクロとは何だろうか? よくある説明はマクロはコードを入力として受け取り、コードを出力するプログラムだとされる。それ自体は正しいが、`map {...}` のような高階関数や名前渡しパラメータのように一見コードのブロックを渡して回っている機能に親しんでいる Scala プログラマには「コードを入力として受け取る」の意味が一見分かりづらいかもしれない。

以下は、僕が Scala 3 にも移植した [Expecty][Expecty] という assersion マクロの用例だ:

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

例えば `assert(...)` で名前渡しの引数を使ったとしたら、その値を得るタイミングは制御できるが `false` しか得ることができない。一方マクロでは、`person.say(word1, word2) == "pong pong"` というソースコードの形そのものを受け取り、全ての式の評価値を含んだエラーメッセージを自動生成するということができる。頑張って書こうと思えば `Predef.assert(...)` を使っても手でこのようなエラーメッセージを書くことができるが、非常に退屈な作業となる。マクロの全貌はこれだけでは無い。

よくありがちな考え方としてコンパイラはソースコードをマシンコードへと翻訳するものだとものがある。確かにそういう側面もあるが、コンパイラは他にも多くの事を行っている。型検査 (type checking) はそのうちの一つだ。バイトコード (や JS) を最後に生成する他に、Scala コンパイラはライトウェイトな証明システムとして振る舞い、タイポや引数の型合わせなど様々なエラーを事前にキャッチする。Java の仮想機械は、Scala の型システムが何を行っているかをほとんど知らない。この情報のロスは、何か悪いことかのように型消去とも呼ばれるが、この型とランタイムという二元性によって Scala が JVM、JS、Native 上にゲスト・プログラミング言語として存在することができる。

Scala において、マクロはコンパイル時にアクションを取る方法を提供してくれ、これは Scala の型システムと直接話すことができるホットラインだ。具体例で説明すると、型 `A` があるとき、ランタイム上からこれが case class であるかを正確に確認する方法は無いと思う。マクロを使うとこれが 5行で書ける:

```scala
import scala.quoted.*

inline def isCaseClass[A]: Boolean = ${ isCaseClassImpl[A] }
private def isCaseClassImpl[A: Type](using qctx: Quotes) : Expr[Boolean] =
  import qctx.reflect.*
  val sym = TypeRepr.of[A].typeSymbol
  Expr(sym.isClassDef && sym.flags.is(Flags.Case))
```

上記の `${ isCaseClassImpl[A] }` は Scala 3 マクロの一例で、スプライスと呼ばれる。

#### クォートとスプライス

公式ドキュメントの [Macros][macros] の説明では:

> Macro はクォートとスプライスという 2つの基礎的な演算から成り立っている。式のクォートは `'{...}` と書かれ、スプライスは `${...}` と書かれる。

クォートは「引用する」、スプライスは「縄などを継ぎ合わせる」というという意味で、「式をクォートする」というふうに動詞として使われる。マクロのエントリーポイントのみでは例外的にトップレベルで `${ isCaseClassImpl[A] }` のようにスプライスが出てくる。通常は `${...}` はクォート式 `'{ ... }` の中に現れる。

> `e` が式の場合、`'{e}` は e の型付けされた抽象構文木を表す。`T` が型の場合、`Type.of[T]` は `T` の型構造を表す。「型付けされた抽象構文木」や「型構造」の正確な定義は一旦置いておいて、直感をつかむための用語だと思ってほしい。逆に、`${e}` は式 e は型付けされた抽象構文木へと評価されることが期待され、その結果は式 (もしくは型) として直近のプログラムへと埋め込まれる。
>
> クォートの中にはスプライスされたパーツを含むことができる。その場合、埋め込まれたスプライスはクォートの形成の一環として評価される。

というわけで、一般的なプロセスとしては、項レベルのパラメータもしくは型を捕獲して、`Expr[A]` と呼ばれる型付けされた抽象構文木を返す形となる。

### Quotes Reflection API

型や項をコードで作ることができる Quotes Reflection API はクォートコンテキストである `Quotes` trait 以下に公開されている。

**注意**: 最初は Reflection API が馴染みがあるように見えて、実際に便利なのだが、Scala 3 マクロを学ぶ過程は使わなくても良いときには Reflection を使わずに素のクォートやクォートのパターンマッチなど構文的な (syntactic) な機能を使うことを学ぶことでもある。

Reflection API は一部 [Reflection][reflection] にドキュメント化されているが、僕は [Quotes.scala][Quotes] をブラウザで開いてソースを直接読んでいる。

> `quoted.Expr` と `quoted.Type` を用いることでコードを作るだけではなく、AST を検査してコードの分析を行うことができる。マクロは生成されるコードが型安全であることを保証する。Quote Reflection を使うとこれらの保証が無くなるため、マクロ展開時に失敗する可能性があり、追加で明示的なチェックを行う必要がある。
>
> マクロにリフレクション能力を提供するためには、`scala.quoted.Quotes` 型の givens パラメータを追加して、使用するスコープ内で `quotes.reflect.*` を import する必要がある。

Reflection API は `Type`、`TypeRepr`、`Symbol` といった豊富な型ファミリー、そして他にも色々な API を導入する。

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

マクロと Scala 3 コンパイラ実装を隔離させるために API は抽象型、その抽象型への拡張メソッド、コンパニオンオブジェクトを表す `val`、そしてコンパニオンオブジェクトの API を記述する trait の集合というパターンとなっている。

#### Tree

`Tree` は、Scala コンパイラが理解した形でのソースコードの形を表し、これは抽象構文木と呼ばれる。これは `val ...` といった定義そして関数呼び出しといった**項** (`Term`) を含む。マクロでは、`Term` を扱うことが多いが、`Tree` のサブ型全般に提供される拡張メソッドの中にも有用なものがあるので、それを見ていく。以下が `Quotes.scala` からの API だ。拡張メソッドが定義されているのは `TreeMethods` なのでそこまで読み飛ばす。

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

以下は `show` の使い方だ:

```scala
package com.eed3si9n.macroexample

import scala.quoted.*

inline def showTree[A](inline a: A): String = ${showTreeImpl[A]('{ a })}

def showTreeImpl[A: Type](a: Expr[A])(using Quotes): Expr[String] =
  import quotes.reflect.*
  Expr(a.asTerm.show)
```

これは以下のように使える:

```scala
scala> import com.eed3si9n.macroexample.*

scala> showTree(List(1).map(x => x + 1))
val res0: String = scala.List.apply[scala.Int](1).map[scala.Int](((x: scala.Int) => x.+(1)))
```

型推論の結果を見たりするのに多少役立つかもしれないが、僕が見たかったのは任意のコードの木構造だ。

#### Printer

AST の構造を見るには `Printer.TreeStructure.show(...)` を使う:

```scala
package com.eed3si9n.macroexample

import scala.quoted.*

inline def showTree[A](inline a: A): String = ${showTreeImpl[A]('{ a })}

def showTreeImpl[A: Type](a: Expr[A])(using Quotes): Expr[String] =
  import quotes.reflect.*
  Expr(Printer.TreeStructure.show(a.asTerm))
```

仕切り直し:

```scala
scala> import com.eed3si9n.macroexample.*

scala> showTree(List(1).map(x => x + 1))
val res0: String = Inlined(None, Nil, Apply(TypeApply(Select(Apply(TypeApply(Select(Ident("List"), "apply"), List(Inferred())), List(Typed(Repeated(List(Literal(IntConstant(1))), Inferred()), Inferred()))), "map"), List(Inferred())), List(Block(List(DefDef("$anonfun", List(TermParamClause(List(ValDef("x", Inferred(), None)))), Inferred(), Some(Apply(Select(Ident("x"), "+"), List(Literal(IntConstant(1))))))), Closure(Ident("$anonfun"), None)))))
```

求めていたのは、これ。注意としては、この木のエンコードは Scala 3.x を通じて安定してるか分からないので、詳細にべったり依存するのは安全では無い可能性があるので、`unapply` 抽出子を使ったほうがいいと思う (これに関して互換性が保証するのかしないのかは僕は知らない)。しかし、コンパイラが構築したものと自分が人工的に構築したものを比べるツールとしてこれは役立つと思う。

#### Literal

通常は `Literal(...)` の木をこのように作る必要はあんまり無いが、基礎となる木なので、単独で説明を始めやすい:

```scala
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
```

抽象型の `type Literal` は `Literal` 木を表し、`LiteralModule` は、コンパニオンオブジェクト `Literal` を記述する。ここでは、`apply(...)`、`copy(...)`、`unapply(...)` を提供しているのが分かる。

これを使って、`Int` リテラルを受け取ってコンパイル時に 1を加算する `addOne(...)` マクロを実装できるはずだ。これは単に `n + 1` を返すのとは違うことに注意してほしい。`n + 1` は実行時に計算する。僕たちがやりたいのは、`1` を渡すと `*.class` が計算無しで `2` を含んでいることだ。

```scala
package com.eed3si9n.macroexample

import scala.quoted.*

inline def addOne_bad(inline x: Int): Int = ${addOne_badImpl('{x})}

def addOne_badImpl(x: Expr[Int])(using Quotes): Expr[Int] =
  import quotes.reflect.*
  x.asTerm match
    case Inlined(_, _, Literal(IntConstant(n))) =>
      Literal(IntConstant(n + 1)).asExprOf[Int]
```

これは意味無く冗長な書き方になっている。

#### FromExpr 型クラス

`Int` を含む、`FromExpr` 型クラスのインスタンスを形成する型の場合は、`Expr` の拡張メソッドである `.value` を使った方が簡単だ。`value` は以下のように定義される:

```scala
def value(using FromExpr[T]): Option[T] =
  given Quotes = Quotes.this
  summon[FromExpr[T]].unapply(self)
```

同様に、`Expr` を `Expr.apply(...)` を使って構築できる `ToExpr` 型クラスがある。

そのため、これらと `.value` の兄弟である `.valueOrError` を使うことで `addOne(...)` は 1行マクロとして書き換える事ができる:

```scala
package com.eed3si9n.macroexample

import scala.quoted.*

inline def addOne(inline x: Int): Int = ${addOneImpl('{x})}

def addOneImpl(x: Expr[Int])(using Quotes): Expr[Int] =
  Expr(x.valueOrError + 1)
```

こっちの方がシンプルであるだけじゃなく、Reflection API を使っていないのでより型安全だというのもポイントだ。

#### Position

マクロ機能のデモとして、`Position` も見ていこう。`Position` はソースコード内での位置を表し、ファイル名や行数などを保持する。

以下は `Source.line` 関数の実装だ。

```scala
package com.eed3si9n.macroexample

import scala.quoted.*

object Source:
  inline def line: Int = ${lineImpl()}
  def lineImpl()(using Quotes): Expr[Int] =
    import quotes.reflect.*
    val pos = Position.ofMacroExpansion
    Expr(pos.startLine + 1)
end Source
```

これは以下のように使うことができる:

```scala
package com.eed3si9n.macroexample

object PositionTest extends verify.BasicTestSuite:
  test("testLine") {
    assert(Source.line == 5)
  }
end PositionTest
```

#### Apply

実践的なマクロのほとんどはメソッドの呼び出しに関わると思うので `Apply` も見ていこう。`addOne` の結果を `List` で返すマクロの例だ。

```scala
package com.eed3si9n.macroexample

import scala.quoted.*

inline def addOneList(inline x: Int): List[Int] = ${addOneListImpl('{x})}

def addOneListImpl(x: Expr[Int])(using Quotes): Expr[List[Int]] =
  val inner = Expr(x.valueOrError + 1)
  '{ List($inner) }
```

手でゴリゴリ `Apply(...)` 木を作るのでは無く、普通の Scala を使って `List(...)` 呼び出しを書いて、中に式をスプライスして、それを丸っと `'{ ... }` でクォートすることができた。`List(...)` メソッドと言っても実際には `_root_.scala.collection.immutable.List.apply[Int](...)` みたいな形になることを考慮すると、それを正確に記述するだけで面倒な作業となるので、これは非常に便利だ。

しかしながら、メソッド呼び出しは頻出なので `Term` 全般に対して専用の拡張メソッドが提供されている。

```scala
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
```

1 を加算して、`toString` を呼び出すというおかしなマクロを書いてみよう:

```scala
package com.eed3si9n.macroexample

import scala.quoted.*

inline def addOneToString(inline x: Int): String = ${addOneToStringImpl('{x})}

def addOneToStringImpl(x: Expr[Int])(using Quotes): Expr[String] =
  import quotes.reflect.*
  val inner = Literal(IntConstant(x.valueOrError + 1))
  Select.unique(inner, "toString").appliedToNone.asExprOf[String]
```

#### Select

`Select` もメジャーだ。上記では、`Select.unique(term, <method name>)` として登場した。

`Select` はオーバーロードされたメソッドを区別するための関数が色々あったりする。

#### ValDef

`ValDef` は `val` 定義を表す。

クォートを使って `val x` を定義して、その参照を返すマクロは以下のように書ける:

```scala
package com.eed3si9n.macroexample

import scala.quoted.*

inline def addOneX(inline x: Int): Int = ${addOneXImpl('{x})}

def addOneXImpl(x: Expr[Int])(using Quotes): Expr[Int] =
  val rhs = Expr(x.valueOrError + 1)
  '{
    val x = $rhs
    x
  }
```

何らかの理由でこれをコードを使ってやりたいとする。まずは新しい `val` のためのシンボルを作る必要がある。そのためには、`TypoeRepr` と `Flags` も必要になる。

```scala
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
```

#### Symbol と Ref

便宜的にシンボルはクラス、`val`、型といったものへの正確な名前だと考えることができる。
シンボルは `val` などの実体を定義するときに作られ、後で `val` を参照したいときに使うことができる。本物のコンパイラは `import` や入れ子になったブロックなども考慮して名前を正しいシンボルに解決するが、僕たちは既にシンボルを持っているので `Ref(sym)` と書くことができる。

#### TypeRepr

`TypeRepr` はマクロ時における型と型関連の演算を表す。実行時には型情報は消去されるため、マクロを使うことで Scala の型情報を直接取り扱うことができる。

型 `A` が case class かどうかを検査するコードは `TypeRepr` がどう取得されるかを見れる良い例だ。

```scala
import scala.quoted.*

inline def isCaseClass[A]: Boolean = ${ isCaseClassImpl[A] }

private def isCaseClassImpl[A: Type](using qctx: Quotes) : Expr[Boolean] =
  import qctx.reflect.*
  val sym = TypeRepr.of[A].typeSymbol
  Expr(sym.isClassDef && sym.flags.is(Flags.Case))
```

以下が `TypeRepr` API だ。

```scala
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
```

`TypeRepr` の拡張メソッドを使ってみよう。以下は 2つの型が等しいかを比べるマクロだ:

```scala
package com.eed3si9n.macroexample

import scala.quoted.*

inline def typeEq[A1, A2]: Boolean = ${ typeEqImpl[A1, A2] }

def typeEqImpl[A1: Type, A2: Type](using Quotes): Expr[Boolean] =
  import quotes.reflect.*
  Expr(TypeRepr.of[A1] =:= TypeRepr.of[A2])
```

`typeEq` は以下のように使うことができる:

```scala
scala> import com.eed3si9n.macroexample.*

scala> typeEq[scala.Predef.String, java.lang.String]
val res0: Boolean = true

scala> typeEq[Int, java.lang.Integer]
val res1: Boolean = false
```

#### AppliedType

型消去で無くなる情報の 1つに `List[Int]` といったパラメータ化された型の型パラメータがある。`TypeRepr` の情報を型適用の部分に分解するのは少しトリッキーだ。

`TypeTest[TypeRepr, AppliedType]` を使うことも可能だが、コンパイラがマジックを使って通常のパターンマッチと同じように書けるようになっている。型パラメータの名前を返すマクロは以下のように書ける。

```scala
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
```

これはこのように使える:

```scala
scala> import com.eed3si9n.macroexample.*

scala> paramInfo[List[Int]]
val res0: List[String] = List(scala.Int)

scala> paramInfo[Int]
val res1: List[String] = List()
```

#### 抽出子としての Select

これまでの所マクロには `1` みたいな素の値を渡して来た。マクロに関数の呼び出しを渡して、関数呼び出しを操作することで少しひねったマクロを書くことができる。

具体例で説明すると、まずは `echo` というダミー関数を作る:

```scala
import scala.annotation.compileTimeOnly

object Dummy:
  @compileTimeOnly("echo can only be used in lines macro")
  def echo(line: String): String = ???
end Dummy
```

次に、`Dummy.echo(...)` を入力された値と行番号を前置したものに置換する `Source.lines(...)` マクロを実装できる。

```scala
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
```

これは以下のようにテストできる:

```scala
package com.eed3si9n.macroexample

object LinesTest extends verify.BasicTestSuite:
  test("lines") {
    assert(Source.lines_bad(List(
      "foo",
      Dummy.echo("bar"),
    )) == List(
      "foo",
      "7: bar"
    ))
  }
end LinesTest
```

#### 抽出子としてのクォート

上の例では `List(...)` 適用式の引数を抽出するのにかなり頑張っている。これはクォートを抽出子として用いることで改善できる。これは [quoted patterns][quoted_pattern] として公式ドキュメントに書いてある。

> Scala がパターンを期待する位置に `'{ ... }` パターンを置くことができる。


`Dummy.echo(...)` を置換する `lines(...)` マクロの改善版は以下のようになる。

```scala
package com.eed3si9n.macroexample

import scala.annotation.compileTimeOnly
import scala.quoted.*

object Source:
  inline def lines(inline xs: List[String]): List[String] = ${linesImpl('{ xs })}

  def linesImpl(xs: Expr[List[String]])(using Quotes): Expr[List[String]] =
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
```

`Dummy.echo` メソッドの面倒なシンボル照会も無くすことができた。

#### 型のスプライス

一旦 `TypeRepr` に戻る。`TypeRepr` を使って型を構築して、それを生成されるコードにスプライスするというパターンが出てくる。

`a: A` と `String` の 2つのパラメータを受け取って、2つ目のパラメータが `"String"` ならば `Either[String, A]` を宣言して、もしも `"List[String]"` ならば `Either[List[String], A]` を作るマクロを作ってみよう。その Either を使うためには `flatMap` してゼロじゃないかをチェックする。

```scala
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
```

つまり、マクロ内で型情報を扱うときは `TypeRepr[_]` を召喚 (summon) するが、Scala コードにスプライスし直すときは `Type[_]` を作る必要がある。使ってみよう:

```scala
scala> import com.eed3si9n.macroexample.*

scala> right(1, "String")
val res0: String = Right(1)

scala> right(0, "String")
val res1: String = Left(empty not allowed)

scala> right[String](null, "List[String]")
val res2: String = Left(List(empty not allowed))
```

あと、これは入力と出力は関数のシグネチャによって定義済みだが、入力によって内部実装で別の型を作っている例だ。

### Restligeist マクロ

Restligeist マクロ、つまり地縛霊マクロは直ちに失敗するマクロだ。API を廃止した後でマイグレーションのためのメッセージを表示させるというユースケースがある。Scala 3 だとこのようなユーザランドでのコンパイルエラーが一行で書ける。

```scala
package com.eed3si9n.macroexample

object SomeDSL:
  inline def <<=[A](inline a: A): Option[A] =
    compiletime.error("<<= is removed; migrated to := instead")
end SomeDSL
```

使う側だとこのような感じに見える:

```scala
scala> import com.eed3si9n.macroexample.*

scala> SomeDSL.<<=((1, "foo"))
-- Error:
1 |SomeDSL.<<=((1, "foo"))
  |^^^^^^^^^^^^^^^^^^^^^^^
  |<<= is removed; migrated to := instead
```

### まとめ

Scala 3 のマクロは、Scala 構文そのものを使ってソースコードの形を操作したり、型システムと直接対話できるなど、今までと異なるレベルのプログラミング能力を引き出すことができる。可能な場合は、プログラムを使って AST を構築する (Quote) Reflection API を避け、Scala 構文を使ってクォートされるコードを構築する事が推奨される。

プログラム的な柔軟性を必要とする場合は、Reflection API が `Tree`、`Symbol`、`TypeRepr` といった豊富な型ファミリーを提供する。これは一部 [Reflection][reflection] としてドキュメント化されているが、現時点では [Quotes.scala][Quotes] を読むのが最も便利な情報源だ。

クォートをパターンマッチで使う方が全般的に型安全であり、マクロが現行 Scala バージョンの実装に特定の `Tree` 実装に決め打ちになってしまうことを回避できる可能性もある。
