
  [meta]: http://scalamacros.org/talks/2012-04-28-MetaprogrammingInScala210.pdf
  [sausage]: http://skillsmatter.com/podcast/scala/scalac-internals
  [trees]: https://github.com/scala/scala/blob/master/src/library/scala/reflect/base/Trees.scala
  [trees2]: https://github.com/scala/scala/blob/master/src/reflect/scala/reflect/api/Trees.scala
  [scalasettings]: https://github.com/scala/scala/blob/master/src/compiler/scala/tools/nsc/settings/ScalaSettings.scala
  [symbols]: https://github.com/scala/scala/blob/master/src/library/scala/reflect/base/Symbols.scala
  [symbols2]: https://github.com/scala/scala/blob/master/src/reflect/scala/reflect/api/Symbols.scala
  [types]: https://github.com/scala/scala/blob/master/src/library/scala/reflect/base/Types.scala
  [types2]: https://github.com/scala/scala/blob/master/src/reflect/scala/reflect/api/Types.scala
  [reflection]: https://docs.google.com/document/d/1Z1VhhNPplbUpaZPIYdc0_EUv5RiGQ2X4oqp0i-vz1qw/edit
  [11020746]: http://stackoverflow.com/questions/11020746/get-companion-object-instance-with-new-scala-reflection-api
  [5z5V9bJFa9g]: https://groups.google.com/forum/?fromgroups#!msg/scala-internals/5z5V9bJFa9g/IzcEk5YiYcgJ
  [json]: http://dcsobral.blogspot.ch/2012/07/json-serialization-with-reflection-in.html
  [universe]: https://github.com/scala/scala/blob/master/src/reflect/scala/reflect/api/Universe.scala

> Scala マクロの作者 Eugene Burmako さんによるリフレクション API に関する発表のスライド、["Metaprogramming in Scala 2.10"][meta] を翻訳しました。翻訳の公開は本人より許諾済みです。翻訳の間違い等があれば遠慮なくご指摘ください。

2012年4月28日 Eugene Burmako 著
2012年8月5日 e.e d3si9n 訳

## はじめに

#### メタプログラミング

> メタプログラミングとは、他のプログラムや自身をデータとして書いたり操作するコンピュータプログラムを書くこと。　—Wikipedia

#### コンパイラ

問: どうやってメタプログラミングを可能にすることができだろう?

答: コンパイラよりもプログラムに関してデータを持つ者がいるだろうか?

プログラマにコンパイラを公開しよう。

#### リフレクション

2.10 ではプログラムに関するデータをリフレクション API として公開する。

この API は、scala-library.jar (インターフェイス)、scala-reflect.jar (実装)、scala-compiler.jar (実行時コンパイル) にまたがっている。

#### Martin の方が詳しい

先日行われた Martin Odersky 先生による講演にてリフレクション API の設計が詳しく説明されている:

- [http://channel9.msdn.com/Lang-NEXT-2012/Reflection-and-Compilers]([http://channel9.msdn.com/Lang-NEXT-2012/Reflection-and-Compilers])

#### 実習

今日は、いくつかの具体例を通してリフレクション API の基礎を習い、またどうやって更に多くの情報を得られるかを習う。

#### マクロ

問: ちょっと! マクロはどうなってるの?

答: マクロの核となるのはリフレクションであり、リフレクションがマクロを API として提供し、リフレクションがマクロを可能とする。今日はまずリフレクションを理解することに焦点を当てる。マクロは小さな後付けにすぎない。

マクロ、その哲学と応用に関しては、Scala Days での講演を参考にしてほしい:

- [http://eed3si9n.com/ja/scala-macros-scaladays2012](http://eed3si9n.com/ja/scala-macros-scaladays2012)

## リフレクション

#### コアとなるデータ構造

- 構文木 (`Tree`)
- シンボル (`Symbol`)
- 型 (`Type`)

<code>
$ scalac -Xshow-phases
phase name id description
---------- -- -----------
    parser  1 ソースを AST へとパースし、簡単な糖衣構文展開 (desugaring) を行う。
     namer  2 名前を解決し、シンボルを名前付けされた構文木へと関連付ける。
     typer  4 メインコース: 構文木を型付けする。
   pickler  7 シンボルテーブルをシリアライズする。
</code>

できる限り分かりやすくこれらの概念の説明をするつもりだが、Paul Phillips 以上の説明は恐らく誰にもできない。
[Inside the Sausage Factory][sausage] という講演は絶対に見ておいたほうがいい。

### 構文木 (`Tree`)

短命で、ほぼ不変 (immutable) で、ほぼ普通の case class だ。

<scala>
Apply(Ident("println"), List(Literal(Constant("hi!"))))
</scala>

公開されている構文木の完全なリストはここにある: [scala/reflect/base/Trees.scala][trees]。ついでに、関連する [scala/reflect/api/Trees.scala][trees2] も見ておこう。なぜ base と api に分かれているかって? 前者は標準ライブラリに含まれているが、後者は scala-reflect.jar を必要とするからだ。

#### 学び方を学ぶ

- `-Xprint:parser` (素の構文木; naked tree)
- `-Xprint:typer` (型付けされた構文木; typed tree)
- `-Yshow-trees` とその仲間
- `ru.showRaw(ru.reify(...)) // ru は scala.reflect.runtime.universe の略だ`
- `showRaw` の省略可能なパラメータも調べてみよう!

問: これらのコンパイラフラグはどこから持ってきたの?

答: [scala/tools/nsc/settings/ScalaSettings.scala][scalasettings].

#### `-Yshow-trees`

<code>
// -Yshow-trees-stringified と
// -Yshow-trees-compact もそれぞれ試してみよう
// (あと両方同時に試してみてもいい!)

$ scalac -Xprint:parser -Yshow-trees HelloWorld.scala
[[syntax trees at end of parser]]// Scala source:
    HelloWorld.scala
PackageDef(
  "<empty>"
  ModuleDef(
    0
    "Test"
    Template(
      "App" // parents
      ValDef(
        private
        "_"
        <tpt>
        <empty>
      )
      ...
</code>

#### `showRaw`

<code>
// ru は scala.reflect.runtime.universe の略だ。

scala> ru.reify{ object Test { println("Hello World!") } }
res0: reflect.runtime.universe.Expr[Unit] = ...
scala> ru.showRaw(res0.tree)
res1: String = Block(List(ModuleDef(
  Modifiers(),
  newTermName("Test"),
  Template(List(Ident(newTypeName("AnyRef"))), List(
   DefDef(Modifiers(), newTermName("<init>"), List(),
       List(List()), TypeTree(),
       Block(List(Apply(Select(Super(This(newTypeName("")),
       newTypeName("")), newTermName("<init>")),
       List())), Literal(Constant(())))),
   Apply(Select(Select(This(newTypeName("scala")),
       newTermName("Predef")), newTermName("println")),
       List(Literal(Constant("Hello World!")))))))),
Literal(Constant(())))
</code>

### シンボル (`Symbol`)

定義や参照を定義にリンクする。長命で、可変 (mutable) だ。
[scala/reflect/base/Symbols.scala][symbols] と [scala/reflect/api/Symbols.scala][symbols2] にて宣言されている。

<scala>
def foo[T: TypeTag](x: Any) = x.asInstanceOf[T]
foo[Long](42)
</scala>

`foo`, `T`, `x` はそれぞれシンボルを導入する (`T` は実は 2つの異なるシンボルを作るが、それはまた別の話になる)。`DefDef`、`TypeDef`、`ValDef` - これらは全て `DefTree` のサブタイプだ。

`TypeTag`, `x`, `T`, `Foo`, `Long` はシンボルを参照する。これらは全て `RefTree` のサブタイプである `Ident` で表される。

シンボルは長命であるため、`Int` への参照は (構文木からでも型からでも) 全て同じシンボルのインスタンスを指す。

#### 学び方を学ぶ

- `-Xprint:namer` か `-Xprint:typer`
- `-uniqid`
- `symbol.kind` と `-Yshow-symkinds`
- `:type -v`
- `showRaw(tree, printIds = true, printKinds = true)`

シンボルを自分で作るのは止めよう。とにかくダメ。Namer に任せる。マクロの場合は素の構文木を作成して、あとは Typer に任せるのがほとんどだ。しかし、場合によっては避けられないこともある: http://stackoverflow.com/questions/11208790

#### `-uniqid` と `-Yshow-symkinds`

<code>
$ cat Foo.scala
def foo[T: TypeTag](x: Any) = x.asInstanceOf[T]
foo[Long](42)

// この表示にある事実が隠されている!
$ scalac -Xprint:typer -uniqid -Yshow-symkinds Foo.scala
[[syntax trees at end of typer]]// Scala source: Foo.scala
def foo#8339#METH
  [T#8340#TPE >: Nothing#4658#CLS <: Any#4657#CLS]
  (x#9529#VAL: Any#4657#CLS)
  (implicit evidence$1#9530#VAL:
      TypeTag#7861#TPE[T#8341#TPE#SKO])
  : T#8340#TPE =
  x#9529#VAL.asInstanceOf#6023#METH[T#8341#TPE#SKO];
Test#14#MODC.this.foo#8339#METH[Long#1641#CLS](42)
(scala#29#PK.reflect#2514#PK.‘package‘#3414#PKO
.mirror#3463#GET.TypeTag#10351#MOD.Long#10361#GET)
</code>

#### `:type -v`

構文木で使われているシンボルの見つけ方を見たわけだけど、シンボルは型にも使われている。

Paul のお陰で型を検査する簡単な方法がある。後のスライドで REPL から使えるおまじないを具体例を使って説明する。

2.10.0-M5 からは (`scala.reflect.runtime.universe` と全てのマクロコンテキストユニバース、つまり全てのユニバースで定義されている) `showRaw` を使って型の生の構造を表示することもできる。

### 型 (`type`)

不変、長命、で時としてキャッシュされているケースクラスで、[scala/reflect/base/Types.scala][types] と [scala/reflect/api/Types.scala][types2] で宣言されている。

豊かな Scala 型システムに関する全ての情報を保持する: メンバ、型引数、高カインド、パス依存性、型消去 (erasure)、など

#### 学び方を学ぶ

- `-Xprint:typer`
- `-Xprint-types`
- `:type -v`
- `showRaw(type, printIds = true, printKinds = true)`
- `-explaintypes`

#### `-Xprint-types`

`-Xprint-types` は構文木の表示を変えるもう一つのオプションだ。これは特に変わったことはしないので、次のもっとスゴいのを見てみよう。

#### `:type -v`

<code>
scala> :type -v def impl[T: c.TypeTag](c: Context) = ???
// 型のシグネチャ
[T](c: scala.reflect.makro.Context)(implicit evidence$1:
    c.TypeTag[T])Nothing
// 内部の型構造
PolyType(
  typeParams = List(TypeParam(T))
  resultType = MethodType(
    params = List(TermSymbol(c: ...))
    resultType = MethodType(
      params = List(TermSymbol(implicit evidence$1: ...))
      resultType = TypeRef(
        TypeSymbol(final abstract class Nothing)
      )
    )
  )
)
</code>

#### `showRaw` (2.10.0-M5 以降のみ)

<code>
scala> object O {
  def impl[T: c.TypeTag](c: Context) = ???
}
defined module O
scala> val meth = ru.reify(O).staticTpe.typeSymbol.
  typeSignature.member(newTermName("impl"))
meth: reflect.runtime.universe.Symbol = method impl
scala> println(showRaw(meth.typeSignature))
PolyType(
  List(newTypeName("T")),
  MethodType(List(newTermName("c")),
    MethodType(List(newTermName("evidence$1")),
     TypeRef(ThisType(scala), scala.Nothing, List()))))
</code>

#### `-explaintypes`

<code>
>cat Test.scala
class Foo { class Bar; def bar(x: Bar) = ??? }
object Test extends App {
  val foo1 = new Foo
  val foo2 = new Foo
  foo2.bar(new foo1.Bar)
}
// 不適合な型の説明を表示する
>scalac -explaintypes Test.scala
Test.foo1.Bar <: Test.foo2.Bar?
  Test.foo1.type <: Test.foo2.type?
    Test.foo1.type = Test.foo2.type?
    false
false false
Test.scala:6: error: type mismatch;
...
</code>

#### 全体像

- 構文木 (`Tree`) は Parser によって素 (naked) で作られる。
- (AST として表される) 定義と参照の両方のシンボルとも Namer によって与えれれる (`tree.symbol`)。
- シンボルを作成する時に Namer は補助オブジェクトしてシンボルの型を計算できる遅延サンクも作る (`symbol.info`)。
- Typer は構文木を検査して、関連付けられたシンボルを使って構文木を変換して型を割り当てる (`tree.tpe`)。
- すぐ後に Picker が起動して到達可能なシンボルとその型を `ScalaSignature` アノテーションに直列化する。

## ユニバース

ユニバース (universe) は、構文木、シンボル、そしてそれらの型をまとめた環境だ。

- コンパイラ (`scala.tools.nsc.Global`) はユニバースだ。
- リフレクションランタイム (`scala.reflect.runtime.universe`) もユニバースだ。
- マクロコンテキスト (`scala.reflect.makro.Context`) はユニバースへの参照を保持する。

#### ミラー

ミラーはシンボルテーブルを抽象化する。

それぞれのユニバースは複数のミラーを持ち、同じ親ユニバース内でシンボルを共有することができる。詳細は [Scala Reflection][reflection] 参照。

- コンパイラは独自の *.class パーサを使ってピクルス (pickle) からシンボルを読み込む。コンパイラはミラーを一つだけ持ち、これは `rootMirror` と呼ばれる。
- リフレクションに使われるミラーは Java リフレクションを用いて `ScalaSignature` を読み込み、パースする。クラスローダごとにそれに対応した独自の `ru.runtimeMirror` が作られる。
- マクロコンテキストはコンパイラのシンボルテーブルを参照する。

#### エントリーポイント

ユニバースの用例はシナリオによって異なる。

- REPL の `:power` モードからコンパイラのユニバース (通称 `global`) をいじることができる。
- 実行時のリフレクションとして利用する場合は、通常 `Mirror` インターフェイス (例えば、`scala.reflect.runtime.currentMirror`) を経由して、`cm.reflect` を取得してそこからフィールドを get/set したり、メソッドを呼び出したりできる。これに関しては [Stackoverflow][11020746] を参照。
- マクロコンテキストからは、`c.universe` をインポートして、インポートされたファクトリから構文木や型を作る (シンボルは自分で作らないって覚えてるよね?)

#### パス依存性

少し変わった点が一つあって、それは全てのユニバース関連の構造物 (訳注: 構文木、シンボル、型) は、それぞれのユニバースにパス依存しているということだ。例えば、以下に表示された型が `reflect.runtime.universe` でプリフィックスされていることに注意してほしい。

<code>
scala> ru.reify(2.toString)
res0: reflect.runtime.universe.Expr[String] =
    Expr[String](2.toString())
</code>

実行時のリフレクションを行う場合は、単に `scala.reflect.runtime.universe._` をインポートしてしまおう。通常は実行時のユニバースは一つしかないからだ。

しかし、マクロはもう少し複雑だ。ユニバースの構造物を、例えばヘルパー関数などに、渡したい場合はユニバースを一緒に連れて歩く必要がある。もしくは、[この scala-internal での議論][5z5V9bJFa9g]で説明されたテクニックを使う。

## デモ

#### メンバーのインスペクト

<scala>
scala> import scala.reflect.runtime.{universe => ru}
import scala.reflect.runtime.{universe=>ru}
scala> trait X { def foo: String }
defined trait X
scala> ru.typeOf[X]
res0: reflect.runtime.universe.Type = X
scala> res0.members
res1: Iterable[reflect.runtime.universe.Symbol] =
    List(method $asInstanceOf, method $isInstanceOf, method synchronized, method ##, method !=,
    method ==, method ne, method eq, constructor Object, method notifyAll, method notify, method clone,
    method getClass, method hashCode, method toString, method equals, method wait, method wait, method wait,
    method finalize, method asInstanceOf, method isInstanceOf, method !=, method ==, method foo)
</scala>

#### メンバーの解析と呼び出し

Daniel Sobral さんのリフレクションに関するシリーズがこの点を網羅している: [JSON serialization with reflection in Scala][json]

#### 型消去を討つ

<scala>
scala> def foo[T](x: T) = x.getClass
foo: [T](x: T)Class[_ <: T]
scala> foo(List(1, 2, 3))
res0: Class[_ <: List[Int]] = class
    scala.collection.immutable.$colon$colon
scala> def foo[T: ru.TypeTag](x: T) = ru.typeOf[T]
foo: [T](x: T)(implicit evidence$1: ru.TypeTag[T])ru.Type
scala> foo(List(1, 2, 3))
res1: reflect.runtime.universe.Type = List[Int]
</scala>

#### 実行時にコンパイルする

<scala>
import scala.reflect.runtime.universe._
import scala.tools.reflect.ToolBox
val tree = Apply(Select(Literal(Constant(40)),
    newTermName("$plus")), List(Literal(Constant(2))))
val cm = ru.runtimeMirror(getClass.getClassLoader)
println(cm.mkToolBox().runExpr(tree))
</scala>

ツールボックス (`ToolBox`) は完全なコンパイラだ (`scala.tools.reflect.ToolBox` を使うには `scala-compiler.jar` をクラスパスに通す必要がある)。普通のコンパイラと違って、Java リフレクションを用いてシンボルテーブルを取得する。この Java リフレクションは抽象化されミラーにて提供される。

ツールボックスは入力される AST をラッピングし、(Parser フェーズを飛ばして) Namer にフェーズをセットしてメモリ内のディレクトリにてコンパイルを実行する。

コンパイルが完了すると、ツールボックスはクラスローダを起動して、コードを読み込み実行する。

## マクロ

上の例では実行時のユニバース (`scala.reflect.runtime.universe`) を使ってプログラム構造をリフレクションを実行した。

全く同じ事をコンパイル時に行うこともできる。ユニバースは既にあるし (コンパイラそのものだ)、API もある (マクロコンテキスト内の `scala.reflect.api.Universe` だ)。

コンパイラにコンパイル時に呼んでほしいと頼むだけだ (現在の実装ではマクロの適用によって起動され、`macro` キーワードがフックとなる)。

これで、終わり。

#### いや、本当に

マクロに関しては、それだけ。

## まとめ

- 2.10 ではプログラムに関してコンパイラが持つ全ての情報にアクセスできる (正確には、ほぼ全ての情報)。
- この情報には構文木、シンボル、型が含まれる。それとアノテーションも。あと、位置情報 (position) も。他にも、[色々][universe]。
- 実行時にリフレクションを実行 (`scala.reflect.runtime.universe`) してもいいし、コンパイル時に実行してもいい (マクロ)。

#### 現在の状況

もう待つ必要は無い。

Scala の 2.10.0-M3 以降にリフレクションとマクロが含まれている。

#### ありがとう!

eugene.burmako@epfl.ch

