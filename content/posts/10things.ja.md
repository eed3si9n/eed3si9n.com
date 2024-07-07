---
title:       "僕が Scala 3 が好きな 10 の理由"
type:        story
date:        2024-06-24
url:         /ja/10things
tags:        [ "scala" ]
---

  [pins15]: https://www.artima.com/pins1ed/case-classes-and-pattern-matching.html#15.1
  [wadler1998]: https://homepages.inf.ed.ac.uk/wadler/papers/expression/expression.txt
  [shapeless-guide]: https://books.underscore.io/shapeless-guide/shapeless-guide.html#sec:poly

何で Scala 3 をそんなに推すのかと聞かれることがあるので、リスト形式で書き出してみた。順は特に無し。これは僕が Scala 3 をどう書いているかとか、将来どう書きたいのかみたいな個人的な好みに基づいているので、それは注意してほしい。

<!--more-->

<a id="enums-and-gadt"></a>
### 1. enum (と GADT)

Scala 3 で [enum](https://docs.scala-lang.org/scala3/book/types-adts-gadts.html) が追加され、これは `case class` のアップグレード版だと考えることができる。ボーナスとして、これは GADT も扱うことができる。

<div class="admonition note">

**case** に関する備考:<br>
一旦 Scala 2 に戻るが、`case class` の **case** がどこから来たのか考察した人はいるのだろうか? 一つの説としては、`case` は C 言語とか Java の `switch` 文の流れをくんでいて、既に予約語なのでそれを使ったと考えることもできる。

もう1つの由来として僕が提案したいのは 1998 年に Philip Wadler さんが `java-genericity@galileo.East.Sun.COM`、`odersky@cis.unisa.edu.au`、その他宛に送った [The expression problem][wadler1998] というメールだ。(Wadler さんは Haskell の作者として有名だが、当時は Odersky 先生らと Java のジェネリックス機能の追加に関わっていた):

> 「式問題」Expression Problem は古くからある問題への新しい名前だ。データ型を **cases** (場合分け) によって定義して、既存のコードを再コンパイルしたり静的型安全性を損なうことなく (例、キャストは禁止)、新しい **case** を追加したり、そのデータ型に関する新しい関数を定義できるようにすることが課題だ。

これは、1998年当時から「case」という名詞が、あるデータ型の型レベルの場合分けを表すのに使われていたことの証左だ。この観点から見ると、case class は型レベルの case を定義する方法を提供していると考えることができる。しかし、Scala 2.x においては case が型へと漏れてしまっているのが、よろしくない。
</div>

`Some(...)` や `None` などの　Scala 2.x の case class では、項が `Some[A]` や `None` と型付けされてしまう。これは、項を `Option[A]` として取り扱い場合、不便だ。

Scala 3 の列挙型 enum においても、`case` は再び型レベルの case を定義するのに使われるが、項は `NewOption[A]` と型付けされる:

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

僕が sbt 2.x で `enum` をどう使うかという例は[酢鶏、パート1](/ja/sudori-part1/)を参照。

GADT というのは、case が具象型を捕捉できるという意味だ。例えば、`Option[A]` は、`A` に何が入っているかが分かっていない。2つの整数を足すことができるミニ言語を例に GADT を定義する:

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
### 2. opaque 型

Scala 3 は (通常 opaque 型と呼ばれる) [`opaque` 型エイリアス](https://docs.scala-lang.org/scala3/reference/other-new-features/opaques.html)を導入し、これはオーバーヘッド無く新しい型を定義することができる。恐らく数値型を包むのが想定される用法だが、僕は `String` とか普通の型も包むのが好きだ。

例えば、[sbt 2.x リモートキャッシュ](/ja/sbt-remote-cache/)ではハッシュ・ダイジェストを表す opaque 型を定義した:

```scala
opaque type Digest = String

object Digest:
  def apply(s: String): Digest =
    validateString(s)
    s

  def validateString(s: String): Unit = ()
end Digest
```

これは、内部構造を隠蔽した new type 的なものを手軽に作ることができる。

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

注意: 吉田さんが以前言っていたのは値クラス同様 Scala 3 の opaque 型は JVM レベルでは隠蔽されていない。そのため、バイナリ互換性の維持が必要になる場合はその点を注意しなければならない。

<a id="inline"></a>
### 3. inline

Scala 2.x でも `@inline` というのがあったが、これは言語概念というよりはオプティマイザのための指示みたいなもので使うのが難しかった。一方 Scala 3 は、インライン化が保証される正規の `inline` を導入した。

`inline` は以下の文脈で現れることができる:

- [`inline def`](https://docs.scala-lang.org/scala3/reference/metaprogramming/inline.html#inline-definitions-1)
- [`inline` パラメータ](https://docs.scala-lang.org/scala3/reference/metaprogramming/inline.html#inline-definitions-1)
- [`inline val`](https://docs.scala-lang.org/scala3/reference/metaprogramming/inline.html#inline-definitions-1)
- [`transparent inline def`](https://docs.scala-lang.org/scala3/reference/metaprogramming/inline.html#transparent-inline-methods-1)
- [`inline if`](https://docs.scala-lang.org/scala3/reference/metaprogramming/inline.html#inline-conditionals-1)
- [`inline match`](https://docs.scala-lang.org/scala3/reference/metaprogramming/inline.html)

以下は sbt 2.x のコードで `inline def` を使った実例:

```scala
inline def ~=(inline f: A1 => A1): Setting[Task[A1]] =
  transform(f)

def transform(f: A1 => A1): Setting[Task[A1]] =
  set(scopedKey(_ map f))
```

上の例では、`transform` というメソッドに対して `~=` というシンボリックなエイリアスを提供した。ユーザが `~=` を呼び出すとき、これはコンパイル時に `transform(...)` に完全に置き換えられるという仕組みだ。

`inline` をパラメータに付けた場合:

> これは、`inline def` の本文内においてパラメータ変数が実際の引数によってインライン化されることを意味する。inline パラメータは名前呼び出しパラメータと同じ呼び出し意味論を持つが、引数にコードの重複を許す。

inline 条件は定数式をコンパイル時に評価するなんてことをまでやっている。`inline` がコンパイル時に処理されることが分かっているため、Scala 2.x ではマクロが必要だったような検査やトリックは `inline` と普通の関数によって書けるものも結構あるはずだ。

<a id="macros"></a>
### 4. マクロ

Scala 2.x でのマクロシステムは、後付けで作られた実験的機能でコンパイラの内部をライブラリ作者に晒すものだった。Scala 3 になって[マクロ](https://docs.scala-lang.org/scala3/guides/macros/macros.html)は正規の機能として認められ、メンテナンス性や機能のパワーの調整を入念に考察したことが伺われる仕上がりになっている。手前味噌になるが、[Scala 3 マクロ入門](/ja/intro-to-scala-3-macros/)も書いたので、オフィシャルのドキュメンテーションの補足になればいいかなと思う。

Scala 3 はハイジェニック (hygienic、健全) なマクロで、これはシステムが意図しない名前衝突を避けるようになっていることを意味する。以下に、コンパイル時に 1 を足すマクロを例に解説する:

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

上では、クォートされたコードが `x` という名前の変数を導入している。コンパイル時に、マクロシステムはこの変数を適当な名前に置換して、`addOneX(1)`　が呼ばれた先で `x` という別の名前の変数を間違えて捕捉しないようになっている。

マクロシステムのもう 1つの用法は、型システムと話すことだ。「型システムと話す」ことは「リフレクション」と呼ばれるが、「リフレクション」と聞いただけで、実行時に文字列によってメソッドをアクセスすると言った Java のリフレクションを思い浮かべる人が多い。Scala 3 のリフレクションはコンパイル時に行われ、コードを使って型システムにクエリしたり、コード生成を行う。

以下は `TypeRepr` と型シンボルを使って、ある型が `case class` かどうかを判定する例だ:

```scala
import scala.quoted.*

inline def isCaseClass[A]: Boolean = ${ isCaseClassImpl[A] }
private def isCaseClassImpl[A: Type](using qctx: Quotes) : Expr[Boolean] =
  import qctx.reflect.*
  val sym = TypeRepr.of[A].typeSymbol
  Expr(sym.isClassDef && sym.flags.is(Flags.Case))
```

マクロの用法の多くは、大抵何らかのコード生成だが、クォートシステムは Scala のコードを使ってそれを行うことができる。以下は、sbt 2.x が条件タスク (`if` 式から構成されるタスクは [Selective functor](/ja/selective-functor-in-sbt/) として扱われる) を処理する例だ:

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

ユーザは `if` 式かその他の式を渡すが、それがどちらなのかのチェックはパターンマッチで行われている。Scala 2.x のマクロでは、これらの作業は往々にして抽象構文木の走査が必要だった。

<a id="then"></a>
### 5. then

少し軽めな話題として、シンタックスの話をしよう。Object Pascal をしばらくやっていたので、Scala 3 の `if` 式が括弧無しで書けるようになったのは嬉しく思う。恐らく 1972年頃、C言語あたりが `if` 条件を括弧に入れ始めて、C++ と Java がそれに倣ったが、歴史的にはこれが亜流だと思う。

Algol 60、Pascal、ML 系列の言語 (SML, F#)、Haskell などは全て:

```haskell
if condition then expression1 else expression2
```

という構文を使う。

Scala 3 は[新しい制御構文](https://docs.scala-lang.org/scala3/reference/other-new-features/control-syntax.html)を導入し、これは `then` を使った `if` 式も含まれる。僕が 2018 に書いた [The state of then](https://contributors.scala-lang.org/t/the-state-of-then/1638) も参照。

Python、Rust、Swift といった今どきの言語も条件に括弧を必要としないが、`then` も採用していない。if の括弧を `then` で置き換えるたびに、これが Pascal/ML 系言語としての Scala の本来の姿だと笑みがこぼれてしまう。

1つ不満を言わせてもらうならば、以下が許されることだ:

```scala
scala> val x = 1
val x: Int = 1

scala> if x > 1 then 2
```

これを `val` に代入することすらできてしまう:

```scala
scala> val y = if x > 1 then 2

scala> y == (())
val res0: Boolean = true
```

`if` は文ではなく式のはずなので、`else ()` と書く必要があっても `else` 節は省略不可能にしてほしい。いや、`then` 節と `else` 節の型が一致することも強制してほしい。

<a id="polymorphic-function"></a>
### 6. ポリモーフィック関数

Scala 2.x でもパラメトリック関数 `makeList` や `head` は以下のように実装できる:

```scala
scala> def makeList[A1](a: A1): List[A1] = List(a)
def makeList[A1](a: A1): List[A1]

scala> def head[A1](xs: List[A1]): A1 = xs.head
def head[A1](xs: List[A1]): A1

scala> head(makeList(1))
val res1: Int = 1
```

しかし、これを `val` に保持するにはどうすればいいだろうか? どのような型を持つだろう? この概念は rank-n ポリモーフィズムとも呼ばれ、関数型プログラミングでたびたび登場する。例えば、[FunctionK](/herding-cats/ja/FunctionK.html) 参照。Scala 3 は[ポリモーフィック関数](https://docs.scala-lang.org/scala3/reference/new-types/polymorphic-function-types.html)とそれに対応したポリモーフィック関数型を導入したため、ポリ関数を渡して回ることができる。

```scala
scala> val makeList = [a] => (a: a) => List(a)
val makeList: [a] => (a: a) => List[a] = Lambda$7541/473366824@60b21dcd

scala> val head = [a] => (xs: List[a]) => xs.head
val head: [a] => (xs: List[a]) => a = Lambda$7542/1517955069@5ecdd9b

scala> head(makeList(1))
val res0: Int = 1
```

Miles Sabin さんのような人たちが 10年ぐらいこういうことをやり続けてきてたという背景がある。例えば、Dave Gurnell さんが書いた「The Type Astronaut's Guide to Shapeless」というガイドの [Functional operations on HLists][shapeless-guide] セクション参照。Scala 3 によって「型宇宙飛行士」的アイディアが一次創作に入ってきたのは嬉しい。

<a id="tuples"></a>
### 7. タプル

アリティーと言えば (Shapeless はアリティーを抽象化する)、Scala 3 ではタプルがアリティー・ジェネリックな能力を獲得した。詳細は [Tuple.scala](https://github.com/scala/scala3/blob/3.3.3/library/src/scala/Tuple.scala) とか Vincenzo Bazzucchi さんの [Tuples bring generic programming to Scala 3](https://www.scala-lang.org/2021/02/26/tuples-bring-generic-programming-to-scala-3.html) が参考になる:

> Scala 3 ではタプルは、新しい演算、型安全性の向上、より少ない制約と、ジェネリックプログラミングの基礎となるデータ構造の Heterogeneous Lists (HLists) への方向性を示す能力を得た。

内部構造的には Scala 3 のタプルは 2.13 のタプルと変わらない ([scala.runtime.Tuples.cons](https://github.com/scala/scala3/blob/3.3.3/library/src/scala/runtime/Tuples.scala) 参照) が、コンパイル時には型システムはタプルは `A1 *: A2 *: A3 *: Tuple.EmptyTuple` といった形になっているフリをさせてくれる。

[マッチ型](https://docs.scala-lang.org/scala3/reference/new-types/match-types.html)とポリモーフィック関数を使うことで、タプリ型を走査したり合成したりできる。

[Functional operations on HLists][shapeless-guide] での例を実装できるか試してみよう:

```scala
scala> (10, "hello", true).size
val res0: Int = 3

scala> type R = Tuple.Size[Int *: String *: Boolean *: EmptyTuple]
// defined alias type R = 3
```

より実用的なのは、個々の型を `IO[a]` みたいなエフェクト型で包むことだ。ここでは `Option[a]` で代用する:

```scala
scala> val makeOption: [a] => a => Option[a] = [a] => (a: a) => Option(a)
val makeOption: [a] => (x$1: a) => Option[a] = Lambda$7806/239970257@2435a640

scala> (10, "hello", true).map(makeOption)
val res0: (Option[Int], Option[String], Option[Boolean]) = (Some(10),Some(hello),Some(true))

scala> type R = Tuple.Map[Int *: String *: Boolean *: EmptyTuple, Option]
// defined alias type R = (Option[Int], Option[String], Option[Boolean])
```

これは結構良いのではと思う。sbt 2.x の内部構造とこれがどう関連するかは [sudori part 3](/sudori-part3/) 参照。

<a id="extension-methods"></a>
### 8. 拡張メソッド

Scala 3 は[拡張メソッド](https://docs.scala-lang.org/scala3/reference/contextual/extension-methods.html)を導入して、これは既に型が定義された後で型にメソッドを追加することができる。これは Scala 2.x における implicit class に似ているが、拡張メソッドになってからか気のせいか思ったよりよく使うようななった。

例えば、sbt 1.x のコードでは、`Initialize[A]` とか `Task[A]` が別のレイヤーで定義されているために、`.value` メソッドは implicit で注入されるマクロで実装される。sbt 2.x も同様の制約があるが、拡張メソッドと `inline` を使うことで実装はかなり簡単になった:

```scala
extension [A1](inline in: Initialize[A1])
  inline def value: A1 = InputWrapper.`wrapInit_\u2603\u2603`[A1](in)
```

<a id="scala-2.13-interop"></a>
### 9. Scala 2.13 相互運用

Scala 3.x の面白い側面の 1つに 3.x 系はずっと後方互換であることと、[Scala 2.13 系のエコシステムと相互運用](https://docs.scala-lang.org/scala3/guides/migration/compatibility-intro.html)しているという点がある。実際、標準ライブラリは Scala 2.13 のものを流用している。言い方を変えると、コレクションライブラリの書き換えなどランタイムの変更点は Scala 2.13 として前倒しでリリースしたと考えることもできる。

Scala 3 に飛び乗ってしまえばこれらはあんまり考えなくてもいいが、Scala 3 への移行を検討している会社などがあると、Scala 3 での実行時の振る舞いがほぼ同じであるというのは安心感があることだと思う。相互運用があることで、アプリ開発者の人たちは Scala 3.x に徐々に移行するということができる。

<a id="optional-braces"></a>
### 10. 中括弧省略構文

Scala 3 は[中括弧省略構文](https://docs.scala-lang.org/scala3/reference/other-new-features/indentation.html)を導入して、多くの `{` と `}` が `:` と文字の字下げで置き換えられるようになった。これは、完全に自由にオプトインできる構文の変更にも関わらず恐らく最も物議を醸した変更点だ。

個人的には、この新しい構文は気に入っている。定義の構文は好きだし、`match` その他が中括弧が要らなくなるのも好きだし、関数の本文に中括弧が要らなくなるもの好きだし、"fewer braces" と呼ばれる新しいラムダ構文も好きだ。可能な場合は、基本的に中括弧省略構文を選んでいる:

```scala
def toActionResult(ar: XActionResult): ActionResult =
  val outs = ar.getOutputFilesList.asScala.toVector.map: out =>
    val d = toDigest(out.getDigest())
    HashedVirtualFileRef.of(out.getPath(), d.contentHashStr, d.sizeBytes)
  ActionResult(outs, storeName, ar.getExitCode())
```

僭越ながら助言をするならば、もっと押して半角スペース2文字でインデントすることをほとんどの場所で強制するのと、[オフサイド・ルール](https://ja.wikipedia.org/wiki/%E3%82%AA%E3%83%95%E3%82%B5%E3%82%A4%E3%83%89%E3%83%AB%E3%83%BC%E3%83%AB)を強制してほしい。例えば、以下のような関数定義は Python 3 ではエラーとなる:

```python
>>> def foo():
      x = 1
        y = 2
  File "<stdin>", line 3
    y = 2
IndentationError: unexpected indent
```

Scala 3 ではこれが許されている:

```scala
scala> def foo: Int =
         val x = 1
           val y = 2
         x + y
```

こういう書き方が禁止されればより良いが、前述の通り、僕は Scala 3 インデント構文のファンだ。

<a id="union-types"></a>
### 選外佳作: ユニオン型

Scala 3 は[ユニオン型](https://docs.scala-lang.org/scala3/reference/new-types/union-types-spec.html)を追加した。ユニオン型が入るのを楽しみにしていたが、実際の所はまだ実用していない。

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

いい感じじゃないかなと思う。しかし、以下のようなコードはどうかなと思う:

```scala
scala> val hmmm = if true then "bar" else Option("baz")
val hmmm: String | Option[String] = bar
```

LUB を作らなくなったのはいいが、`String` と `Option[String]` の間に意味のある親が無いのだからコンパイラ・エラーにした方が分かりやすいと思うのだが。

<a id="multiversal-equality"></a>
### 選外佳作: 多元的等価性

素の状態の Scala 2.x は等価性がザルで、コンパイルを失敗するべき比較不能な状況でも 2つの値を比較してしまうことで悪名高い。Scala 3 ではその対策として[多元的等価性](https://docs.scala-lang.org/scala3/book/ca-multiversal-equality.html)が導入されたが、デフォルトでは使われていない。

```scala
scala> Option(1) == Option("foo")
val res0: Boolean = false
```

多元的等価性は以下のようにして有効化できる:

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

多少言いたいこともあるが、全般的により厳格な等価性は Scala にとって大きな一歩だ。この話題に関しては[自由、平等、ボックス化されたプリミティブ型](https://2020.scalamatsuri.org/ja/proposals/J20)も参照。

<a id="typeclass-derivation"></a>
### 選外佳作: 型クラスの自動導出

Scala 3 は、面白いことに[型クラスの自動導出](https://docs.scala-lang.org/scala3/reference/contextual/derivation.html)を導入した。これは詳しいことをちゃんと見てないので、努力目標的な「いいね」だ。

上のコードの例で、使ったばっかりではある:

```scala
scala> given optionEq[A1, A2](using ev: CanEqual[A1, A2]): CanEqual[Option[A1], Option[A2]] = CanEqual.derived
```

導出の部分も実装すると面白いと思う。

<a id="user-land-compilation-error"></a>
### 選外佳作: ユーザーランドでのコンパイル・エラー

マイグレーションの警告やエラーを表示するために、僕は前から[ユーザランドでのコンパイラ・エラー](/ja/user-land-compiler-warnings-in-scala)があるといいと言ってきた。Scala 2.x だと、エラーメッセージを表示するためにエラーを投げるだけのシンプルなマクロを書いてたりする。Scala 3 は [`scala.compiletime` モジュール](https://docs.scala-lang.org/scala3/guides/macros/compiletime.html)を追加したので、比較的簡単にこれが実装できる:

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

より多くの人がこれを使って「不正な状態を表現不可能」とできればいいと思っている。

### まとめ

Scala 3.x は、2021年以来 Scala 言語の現行バージョンだ。Scala 2.x を使ったことがある人は、慣れ親しんだ概念は全部 Scala 3 にあることが分かると思う。次の段階へと進もうと思うと、Scala 3.x はより安全で表現力の高いコードを書くための道具がそろっている。
