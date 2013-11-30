> 一見普通の演算でもいかに高速化できるかをいつも考えて発表してる奇才 Eiríkr Åsheim ([@d6](https://twitter.com/d6)) さんの ["How to use Spire's Ops macros in your own project"](http://typelevel.org/blog/2013/10/13/spires-ops-macros.html) を翻訳しました。いつも気さくに話しかけてくれるフレンドリーでいいやつです。翻訳の公開は本人より許諾済みです。

2013年10月13日 Eiríkr Åsheim 著
2013年11月20日 e.e d3si9n 訳

### Spire の Ops マクロとは何か?

Spire の型クラスは `+` や `*` といった基礎的な演算子を抽象化する。普通これらの演算は非常に速い。そのため、ちょっとでも余計な事
(例えば、boxing やオブジェクトの割り当てなど) を演算ごとにやってしまうと、ジェネリック化したコードは直接呼び出したものと比べて遅いものになってしまう。

効率的かつジェネリックな数値プログラミングが Spire の存在意義だ。不必要なオブジェクト割り当てを回避するために僕たちはいくつかの Ops マクロを用意した。本稿ではその仕組みと、君のコードからそれらのマクロを使う方法を解説する。

### 通常の型クラスを用いた暗黙の演算子の仕組み

Scala で型クラスを用いる場合、通常は暗黙の変換に頼ることでジェネリックな型に演算子を「追加」する。(訳注: いわゆる Enrich my library パターンだ)

以下に具体例で説明すると、`A` はジェネリックな型、`Ordering` は型クラスで、`>` が暗黙の演算子となる。`foo1` はプログラマが書くコードで、`foo4` は implicit が解決されて、糖衣構文が展開された後のものだ。

<scala>
import scala.math.Ordering
import Ordering.Implicits._

def foo1[A: Ordering](x: A, y: A): A =
  x > y

def foo2[A](x: A, y: A)(implicit ev: Ordering[A]): A =
  x > y

def foo3[A](x: A, y: A)(implicit ev: Ordering[A]): A =
  infixOrderingOps[A](x)(ev) > y

def foo4[A](x: A, y: A)(implicit ev: Ordering[A]): A =
  new ev.Ops(x) > y
</scala>

(実はこれは微妙に間違っている。`foo4` への展開は実行時に `infixOrderingOps` が呼ばれるまでは行われないが、これから説明することの要点となる。)

`>` を呼び出すたびに `ev.Ops` インスタンスをインスタンス化していることに気付いただろうか。これは多くの場合大したこと無いけども、(例えば100万回とか) 多くの回数呼び出せば 、通常何の気も無しに呼び出せるものの割に意外と大きな無駄になる。

これは以下のように回避できる:

<scala>
def bar[A](x: A, y: A)(implicit ev: Ordering[A]): A =
  ev.gt(x, y)
</scala>

`ev` パラメータが実際に呼び出したいメソッド (`gt`) を持つため、`ev.Ops` をインスタンス化する代わりにこのコードは `ev.gt` を直接呼び出す。だけど、この方法は見た目が良くない。以下の 2つのメソッドを比べてみよう:

<scala>
def qux1[A: Field](x: A, y: A): A =
  ((x pow 2) + (y pow 2)).sqrt

def qux2[A](x: A, y: A)(implicit ev: Field[A]): A =
  ev.sqrt(ev.plus(ev.pow(x, 2), ev.pow(y, 2)))
</scala>

2つ目のメソッドがすぐに読み解けなくても不思議じゃない。

この時点では、クリーンで読みやすいコード (`qux1`) もしくはオブジェクト割り当てを回避した防御的コードの (`qux2`) のどちらか 1つを選ぶしかないようだ。多くのプログラマはただ単にどちらかを選んで (多分読みやすい方) 日常に戻る。

しかし、この問題は Spire の根幹に関わるため、僕たちはもう少し何か良い方法が無いか考えてみた。

### 二兎追って二兎とも得る

implicit の解決後に "nice" なコードと "fast" なコードがどうなるかを比較するためにもう一つの具体例をみてみよう:

<scala>
def niceBefore[A: Ring](x: A, y: A): A =
  (x + y) * z

def niceAfter[A](x: A, y: A)(implicit ev: Ring[A]): A =
  new RingOps(new RingOps(x)(ev).+(y))(ev).*(z)

def fast[A](x: A, y: A)(implicit ev: Ring[A]): A =
  ev.times(ev.plus(x, y), z)
</scala>

見てのとおり、`niceAfter` と `fast` はかなり似通っている。以下の方法で `niceAfter` から `fast` へ変換できないだろか。

1. シンボルを使った演算子の適切な名前を見つける。この場合、`+` は `plus` となり、`*` は `times` となる。
2. オブジェクトのインスタンス化とメソッドの呼び出しを書き換えて、`x` と `y` を `ev` のメソッドに渡すようにする。この場合、`new Ops(x)(ev).foo(y)` は `ev.foo(x, y)` となる。

この変換が Spires の Ops マクロがやっていることの要点だ。

### Ops マクロの使い方

マクロを使うには Scala 2.10+ のプロジェクトである必要がある。

Spire の Ops マクロを使うには、`spire-macros` パッケージに依存する必要がある。sbt を使っている場合、以下を `build.sbt` に追加することでできる:

<scala>
libraryDependencies += "org.spire-math" %% "spire-macros" % "0.6.1"
</scala>

この他に、ops クラスを宣言した場で以下のようにマクロ機能を有効にする必要がある:

<scala>
import scala.language.experimental.macros
</scala>

### 具体例

サイズを持つものを抽象化する型クラス `Sized` を考える。`Char`、`Map`、そして `List` に対する型クラスインスタンスがコンパニオンオブジェクトにて提供される。もちろんユーザが独自のインスタンスを提供することも可能だ。

コード:

<scala>
trait Sized[A] {
  def size(a: A): Int
  def isEmpty(a: A): Boolean = size(a) == 0
  def nonEmpty(a: A): Boolean = !isEmpty(a)
  def sizeCompare(x: A, y: A): Int = size(x) compare size(y)
}

object Sized {
  implicit val charSized = new Sized[Char] {
    def size(a: Char): Int = a.toInt
  }

  implicit def mapSized[K, V] = new Sized[Map[K, V]] {
    def size(a: Map[K, V]): Int = a.size
  }

  implicit def listSized[A] = new Sized[List[A]] {
    def size(a: List[A]): Int = a.length
    override def isEmpty(a: List[A]): Boolean = a.isEmpty
    override def sizeCompare(x: List[A], y: List[A]): Int = (x, y) match {
      case (Nil, Nil) => 0
      case (Nil, _) => -1
      case (_, Nil) => 1
      case (_ :: xt, _ :: yt) => sizeCompare(xt, yt)
    }
  }
}
</scala>

(リストの長さを計算するのは O(n) 演算なので `Sized[List[A]]` の実装はいくつかの「デフォルト」の実装をオーバーライドして効率化していることに注意。)

implicit のインスタンス `Sized[A]` が入手可能であるとき、これらのメソッドをジェネリックな型 `A` から直接呼び出したい。Spire の　Ops マクロを使って `SizedOps` クラスを定義してみよう:

<scala>
import spire.macrosk.Ops
import scala.language.experimental.macros

object Implicits {
  implicit class SizedOps[A: Sized](lhs: A) {
    def size(): Int = macro Ops.unop[Int]
    def isEmpty(): Boolean = macro Ops.unop[Boolean]
    def nonEmpty(): Boolean = macro Ops.unop[Boolean]
    def sizeCompare(rhs: A): Int = macro Ops.binop[A, Int]
  }
}
</scala>

これだけだ!

この型クラスの使用例はこのようになる:

<scala>
import Implicits._

def findSmallest[A: Sized](as: Iterable[A]): A =
  as.reduceLeft { (x, y) =>
    if ((x sizeCompare y) < 0) x else y
  }

def compact[A: Sized](as: Vector[A]): Vector[A] =
  as.filter(_.nonEmpty)

def totalSize[A: Sized](as: Seq[A]): Int =
  as.foldLeft(0)(_ + _.size)
</scala>

悪くないよね?

### 但し書き

当然、但し書きがついてくる。

まず、implicit クラスは**必ず**上の例のようなパラメータ名をつける必要がある。`SizedOps` のコンストラクタパラメータは**必ず** `lhs` と呼ばれなければならず、(もしあれば) メソッドのパラメータは**必ず** `rhs` と呼ばれなければならない。また、一項演算子 (`size` のようにパラメータを取らないメソッド) は**必ず**括弧を持たなければならない。

コンストラクタやメソッドに複数のパラメータがある場合、このマクロはどう処理するかって? 処理しないよ。今の所そういうクラスをサポートする局面には出くわしてこなかったけども、Spire の Ops マクロを拡張して他の形をサポートするのも多分難しくないと思う。

これらのルールを破ったり、クラスが間違った形だった場合は、君のコードはコンパイルに失敗する。だから心配する必要は無い。逆に言うと、コンパイルが通ればうまくいったということだ。

### シンボルを使った名前

上の例ではメソッド呼び出しを書き換えてオブジェクト割り当てを回避したけども、シンボルを使った演算子をメソッドに書き換えることはできるだろうか?

以下が `*` から `times` に関連付けた例だ:

<scala>
trait CanMultiply[A] {
  def times(x: A, y: A): A
}

object Implicits {
  implicit class MultiplyOps[A: CanMultiply](lhs: A) {
    def *(rhs: A): A = macro Ops.binop[A, A]
  }
}

object Example {
  import Implicits._

  def gak[A: CanMultiply](a: A, as: List[A]): A =
    as.foldLeft(a)(_ * _)
  }
}
</scala>

現在 Ops マクロには多くの (だけど Spire に特定の) シンボルから名前への関連付けがある。しかし、君のプロジェクトでは別の名前 (または別のシンボル) を使いたいと思うかもしれない。どうしたらいいだろう?

今の所は、諦めるしか無い。Spire 0.7.0 においては独自の関連付けを使えるようにする予定だ。これがあれば、シンボルを使った暗黙の演算子を多用する他のライブラリ (例えば Scalaz など) もこのマクロを容易に使えるようになるはずだ。

### その他の備考

Ops マクロが specialization とどう関わってくるのかが気になっているかもしれない。幸い、マクロの展開は specialization フェーズの前に起こる。そのため、心配する必要は無い! 型クラスが specialized されたもので、implicit の呼び出し元が specialized な (つまり非ジェネリックな) コンテキストであれば、その結果も specialized な呼び出しとなる。

(だたし Scala の specialized を使いこなすのはトリッキーなので、別のブログポストを要する話題だ。型クラスが Scala の中では最も簡単に正しく特化できる構造の一つであることがせめてもの救いだ。)

マクロはコンパイル時に評価されるため、もしもマクロに問題があればそれはコンパイル時に気付くということだ。Ops マクロは多くのプロジェクトの役に立つことを僕たちは期待するけども、もともと Spire 向けに設計されたものなので使ってみたら問題を見つけたり、新機能が必要だったりすることもあるかもしれない。

もしこれらのマクロを採用してもらえたならば、是非感想を[聞かせてほしい](https://groups.google.com/forum/#!forum/spire-math)。何か問題があれば [issue](https://github.com/non/spire/issues) へ、またバグ修正 (もしくは新機能) を書いたなら遠慮無く [pull req](https://github.com/non/spire/pulls) を送ってほしい!

### まとめ

抽象化にコストが伴うと言われることに慣れてしまった。だから、頭の中で「これはジェネリックにする価値があるだろうか? この糖衣構文を使う余裕があるだろうか? このコードの実行時の痛手はどうだろう?」というそろばん勘定を行う。長年これをやっていると、コードは美しいか速いかの二者択一で、それを両立させることはできないと思い込んでしまうようになる。

暗黙のオブジェクトのインスタンス化を無くすことで、Spire の Ops マクロは抽象化の可能性を引き上げることができた。これによって性能を犠牲にすることなく自由に型クラスを使えるようになるからだ。直接計算とジェネリックな計算の性能のギャップを狭め、また Scala において可能な限りの範囲でジェネリックな型や型クラスを使うことを推奨するのが僕たちの目標だ。
