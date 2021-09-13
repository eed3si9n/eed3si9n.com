---
title:       "初めての Scala マクロ"
type:        story
date:        2012-08-01
changed:     2012-08-06
draft:       false
promote:     true
sticky:      false
url:         /ja/scala-macros-getting-started
aliases:     [ /node/61 ]
---


  [1]: https://github.com/scala/scala/blob/master/src/compiler/scala/tools/nsc/settings/ScalaSettings.scala
  [2]: http://eed3si9n.com/ja/metaprogramming-in-scala-210
  [3]: http://scalamacros.org/documentation/specification.html
  [4]: http://scalamacros.org/documentation/reference.html
  [5]: http://groups.google.com/group/scala-user
  [6]: https://github.com/slick/slick
  [7]: https://github.com/retronym/macrocosm
  [8]: https://github.com/pniederw/expecty
  [9]: https://github.com/scala/scala/tree/master/test/files/run

> Scala マクロの作者 Eugene Burmako さんが管理する [scalamacros.org](http://scalamacros.org/) から ["Getting started"](http://scalamacros.org/documentation/gettingstarted.html) を翻訳しました。翻訳の公開は本人より許諾済みです。翻訳の間違い等があれば遠慮なくご指摘ください。

Eugene Burmako 著
2012年7月31日 e.e d3si9n 訳

## 1. Scala 2.10 を入手する

マクロは 2.10.0-M3 以降の Scala で出荷されている。現行のマイルストーンである 2.10.0-M6 などのマクロが入ったコンパイラを直接[ダウンロード](http://www.scala-lang.org/downloads)するか、Maven や sbt などから参照する。好きな方法を使っていい。

> 訳注: sbt 0.11.3 を使ったプロジェクトを github に用意したので、

    git clone -b ja https://github.com/eed3si9n/scalamacros-getting-started.git

> でセットアップできる。

## 2. マクロを書く

`Macros.scala` というファイルを作って以下のコードをペーストする (関連する API やインフラなどマクロシステムに大切なことが書かれているのでコメントもしっかり読んでほしい)。

<scala>
import scala.reflect.makro.Context
import collection.mutable.ListBuffer
import collection.mutable.Stack

object Macros {
  // マクロ定義のシグネチャは好きなパラメータを受け取る普通の関数と同じだ。
  // しかし、本文は実装への参照のみとなる。
  def printf(format: String, params: Any*): Unit = macro printf_impl

  // マクロ実装のシグネチャはマクロ定義のものと対応する必要がある。
  // 一見複雑に見えるが、心配する必要はない。
  // もしコンパイラが不満なら、エラーメッセージで必要なシグネチャを教えてくれる。
  def printf_impl(c: Context)(format: c.Expr[String],
    params: c.Expr[Any]*): c.Expr[Unit] = {
    
    // コンパイラ API は scala.reflect.makro.Context を通じて公開されている。
    // その最も重要な部分であるリフレクション API は
    // c.universe よりアクセスすることができる。
    // 頻繁に使われるものの多くが含まれているため、
    // import c.universe._ をインポートするのが慣例だ。
    import c.universe._

    // まず、渡された format 文字列をパースする。
    // マクロはコンパイル時に動作するため、値ではなく構文木に作用する。
    // そのため、このマクロに渡される format パラメータは
    // コンパイル時のリテラルであり、
    // java.lang.String 型のオブジェクトではない。
    // これはまた、以下のコードでは printf("%d" + "%d", ...) では
    // 動作しないことを意味する。
    // なぜならこの場合は format は文字リテラルではなく 
    // 2つの文字リテラルの連結を表す AST となるからだ。
    // 任意のもので動作するようにこのマクロを改良するのは読者への練習問題としよう。
    val Literal(Constant(s_format: String)) = format.tree

    // ここからコンパイラに突入する。
    // すぐ下のコードでは一時的な val を作ってフォーマットされる式を事前に計算する。
    // 動的な Scala コードの生成に関してより詳しく知りたい場合は以下のスライドを参照:
    // http://eed3si9n.com/ja/metaprogramming-in-scala-210
    val evals = ListBuffer[ValDef]()
    def precompute(value: Tree, tpe: Type): Ident = {
      val freshName = newTermName(c.fresh("eval$"))
      evals += ValDef(Modifiers(), freshName, TypeTree(tpe), value)
      Ident(freshName)
    }

    // ここはありがちな AST に対する操作で、特に難しいことは行なっていない。
    // マクロのパラメータから構文木を抽出し、分解/解析して変換する。
    // Int と String に対応する Scala 型を手に入れている方法に注意してほしい。
    // これはコアとなるごく一部の型ではうまくいくが、
    // ほとんどの場合は自分で型を作る必要がある。
    // 型に関しての詳細も上記のスライド参照。
    val paramsStack = Stack[Tree]((params map (_.tree)): _*)
    val refs = s_format.split("(?<=%[\\w%])|(?=%[\\w%])") map {
      case "%d" => precompute(paramsStack.pop, typeOf[Int])
      case "%s" => precompute(paramsStack.pop, typeOf[String])
      case "%%" => Literal(Constant("%"))
      case part => Literal(Constant(part))
    }

    // そして最後に生成したコードの全てを Block へと組み合わせる。
    // 注目してほしいのは reify の呼び出しだ。
    // AST を手っ取り早く作成する方法を提供している。
    // reify の詳細はドキュメンテーションを参照してほしい。
    val stats = evals ++ refs.map(ref => reify(print(c.Expr[Any](ref).splice)).tree)
    c.Expr[Unit](Block(stats.toList, Literal(Constant(()))))
  }
}
</scala>

## 3. マクロをコンパイルする

準備はできた? `scalac Macros.scala` と打ち込んでみよう。

<code>
$ scalac Macros.scala
Macros.scala:8: error: macro definition needs to be enabled
by making the implicit value language.experimental.macros visible.
This can be achieved by adding the import clause 'import language.experimental.macros'
or by setting the compiler option -language:experimental.macros.
See the Scala docs for value scala.language.experimental.macros for a discussion
why the feature needs to be explicitly enabled.
  def printf(format: String, params: Any*): Unit = macro printf_impl
      ^
one error found
</code>

ちょっと待った! マクロは実験的な高度機能だとされているので、明示的にスイッチを入れる必要がある。
これはファイル単位で `import language.experimental.macros` と書くか、コンパイル単位で `-language:experimental.macros` スイッチを渡すことで行われる。

<code>
$ scalac -language:experimental.macros Macros.scala
<scalac has exited with code 0>
</code>

> 訳注: sbt プロジェクトをクローンした場合は、sbt を起動して、

    > project library
    > compile

> と打ち込む。コンパイラスイッチは既に入れてあるので、コンパイルは通るはず。

## 4. マクロを使う

`Test.scala` という名前のファイルを作って以下のコードをペーストする。(マクロを使うには、インポートして普通の関数同様に呼び出すだけでいい。簡単だよね?):

<scala>
object Test extends App {
  import Macros._
  printf("hello %s!", "world")
}
</scala>

コンパイルして、走らせてみよう。

<code>
$ scalac Test.scala
<scalac has exited with code 0>

$ scala Test
hello world!
</code>

ちゃんと動いてるみたいだ! `-Ymacro-debug-lite` というコンパイラフラグを付けて中の動作をみてみよう ([ScalaSettings.scala][1] には他にもマクロ関連のフラグが定義されているから、試してほしい)。

<scala>
$ scalac -Ymacro-debug-lite Test.scala
typechecking macro expansion Macros.printf("hello %s!", "world") at
source-C:/Projects/Kepler/sandbox\Test.scala,line-3,offset=52
{
  val eval$1: String = "world";
  scala.this.Predef.println("hello ");
  scala.this.Predef.println(eval$1);
  scala.this.Predef.println("!");
  ()
}
Block(List(
ValDef(Modifiers(), newTermName("eval$1"), TypeTree().setType(String), Literal(Constant("world"))),
Apply(
  Select(Select(This(newTypeName("scala")), newTermName("Predef")), newTermName("println")),
  List(Literal(Constant("hello")))),
Apply(
  Select(Select(This(newTypeName("scala")), newTermName("Predef")), newTermName("println")),
  List(Ident(newTermName("eval$1")))),
Apply(
  Select(Select(This(newTypeName("scala")), newTermName("Predef")), newTermName("println")),
  List(Literal(Constant("!"))))),
Literal(Constant(())))
</scala>

`-Ymacro-debug-lite` を使うとマクロ展開によって生成されたコードが擬似 Scala 形式と生の AST 形式で表示される。両者にはそれぞれ利点がある。前者は見た目で解析するのに便利で、後者はより細かいデバッギングに欠かすことができない。

> 訳注: sbt プロジェクトをクローンした場合は、sbt から

    > project app
    > run

> と打ち込む。

## 5. 大切な注意

まず、前のセクションでのコード例に `-language:experimental.macros` が付いていなかったことに注意して欲しい。これは、マクロの定義だけがフラグで隠されていてマクロの呼び出しには制限が無いからだ。

もう一つマクロに関して大切なのは、別コンパイルという概念だ。コンパイラがマクロ展開を実行するときに、マクロ実装を実行可能な形式として必要とするためだ。このため、マクロ実装は主なのコンパイルの前にコンパイルしておく必要がある。さもなくば、以下のようなエラーを見ることになる:

<code>
$ scalac -language:experimental.macros Macros.scala Test.scala
Test.scala:3: error: macro implementation not found: printf (the most common reason for that is that
you cannot use macro implementations in the same compilation run that defines them)
pointing to the output of the first phase
  printf("hello %s!", "world")
        ^
one error found
</code>

更に言うと、もしクラスパスに以前にコンパイルされた古いバージョンのマクロがあった場合は、マクロ実装とマクロの使用が一緒にコンパイルされることでコンパイラは古いバージョンのマクロを呼び出すことになる。これは `NoClassDefFoundException`、`AbstractMethodError` その他のエラーとなりうる。そのため、意図してかなり特殊な事をやっている場合以外は別コンパイルをするべきだ。

最後にもう一つだけ。もしマクロが捕捉されなかった例外を投げた場合はどうなるだろう? 例えば、無効なインプットを渡してマクロをクラッシュさせてみよう:

<code>
$ scalac -language:experimental.macros Macros.scala
<scalac has exited with code 0>

$ scala
Welcome to Scala version 2.10.0-20120428-232041-e6d5d22d28 (Java HotSpot(TM) 64-Bit Server VM, Java 1.6.0_25).
Type in expressions to have them evaluated.
Type :help for more information.

scala> import Macros._
import Macros._

scala> printf("hello %s!")
<console>:11: error: exception during macro expansion:
java.util.NoSuchElementException: head of empty list
        at scala.collection.immutable.Nil$.head(List.scala:318)
        at scala.collection.immutable.Nil$.head(List.scala:315)
        at scala.collection.mutable.Stack.pop(Stack.scala:140)
        at Macros$$anonfun$1.apply(Macros.scala:49)
        at Macros$$anonfun$1.apply(Macros.scala:47)
        at scala.collection.TraversableLike$$anonfun$map$1.apply(TraversableLike.scala:237)
        at scala.collection.TraversableLike$$anonfun$map$1.apply(TraversableLike.scala:237)
        at scala.collection.IndexedSeqOptimized$class.foreach(IndexedSeqOptimized.scala:34)
        at scala.collection.mutable.ArrayOps.foreach(ArrayOps.scala:39)
        at scala.collection.TraversableLike$class.map(TraversableLike.scala:237)
        at scala.collection.mutable.ArrayOps.map(ArrayOps.scala:39)
        at Macros$.printf_impl(Macros.scala:47)

              printf("hello %s!")
                    ^
</code>

特に劇的な結果にはならなかった。コンパイラは行儀の悪いマクロから自身を守る機構を持っているため、関連部のスタックトレースを表示してエラーを表示する。

> 訳注: sbt プロジェクトをクローンした場合は、sbt から

    > project app
    > console

> と打ち込むことで REPL に入る。

## 6. FAQ

よかったら[ドキュメンテーション][2]にも目を通してほしい。

それらの文書から以下のテクニックを習得することができる:
- 生成したいコードに対応する構文木の作り方 (ヒント: [リフレクションのセッション][2])
- ジェネリックなマクロの書き方 (ヒント: [仕様書][3]の例を見てみよう)
- カスタム警告やエラーの表示 (ヒント: [レファレンス][4]の FrontEnds API を見てみよう)
- 型安全で簡潔な構文木の合成 (ヒント: また[仕様書][3]だ。「スプライシング」の項を参照。)

もしもつまづいたり、不明な点があれば僕らはいつでも助けたいと思ってる。
[メーリングリスト][5]で質問するか、dev@scalamacros.org に連絡して欲しい。

## 7. 他の例

Scala マクロは、既に何人ものアーリーアダプターがいる。コミュニティが積極的に関わってくれたお陰で僕らは素早くプロトタイプを行なうことができたし、結果としてお手本として使えるコードがいくつかできた:

- [SLICK][6]: Typesafe と EPFL の共同で開発されている Scala の言語統合接続キットで、マクロを用いることでデータベースのクエリエンジンへの透過的なフロントエンドを提供する。
- [Macrocosm][7]: Jason Zaugg の遊び場。面白いアサーション、ロガー、正規表現やバイナリリテラルのコンパイル時検査、最適化された foreach など、大変興味深い!
- [Expecty][8]: Groovy や Spock などでパワーアサーションとして知られるものを Scala に持ち込む。式を構成するサブ式の値を表示する。
- あとは僕らが書いた[ユニットテスト][9]も参考になるかもしれない。あんまり説明は無いけども、意外な局面で使われるマクロを色々探っている (implicit マクロとか)。
