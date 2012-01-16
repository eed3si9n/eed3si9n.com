  [1]: https://issues.scala-lang.org/browse/SI-5354
  [2]: http://www.scala-lang.org/node/212/distributions
  [3]: http://eed3si9n.com/revisiting-implicits-without-import-tax

Scala という言語は、僕の使ったことのある中では最もエレガントで、表現力に富み、一貫性があり、かつ実利的な言語の一つだと思う。パターンマッチングや統一形式アクセスの原則などはじめ、その筋の良さは枚挙にいとまがない。そして、Scala エコシステムと Scala コミュニティーはその言語をより強力なものにしている。

Scala 2.9.1 において、ローカルで宣言された implicit はインポートされたものよりも優先される。問題は、言語仕様にはそのような振る舞いは書かれていないことだ。僕の当初の仮説は、自分が言語仕様を正しく理解していないか、もしくは言語仕様に抜け穴があるかのどちらかだろうというものだった。とにかく、その仮説に基づいて暗黙のパラメータ解決の優先順位について[色々調べた結果を先週書いた][3]。「怪しい伝説」でもよく言われるように、全く予期していなかった結果が出てきたときが最も面白いものとなる。後で分かったのは、仮説の両方とも間違っていたということだ。

つまり、関連部分に関する僕の仕様の理解は正しく、仕様も正しいということだ。[SI-5354][1] によると、間違っていたのはコンパイラの実装だった。

> The reason why the second example [with locally declared implicits] slipped through is considerably more devious: When checking the `Foo.x` implicit, a CyclicReference error occurs which causes the alternative to be discarded.
>
> 2つ目の例 [訳注: ローカルで宣言された implicit] がすり抜けた理由は、かなりたちが悪い。`Foo.x` という implicit を検査するときに 
CyclicReference エラーが発生しており、その候補ごと捨てられてしまっているのだ。

別の言い方をすると、ローカルで宣言された implicit はバグにより優先されていたことになる。これは、master ブランチでは既に修正済みであり、[2.10 nightly][2] を使ってテストすることができる。

### ローカル宣言 vs 明示的なインポート

前回の記事から一つだけ例を使って検証してみる:

<scala>
trait CanFoo[A] {
  def foos(x: A): String
}

object Def {
  implicit val importIntFoo = new CanFoo[Int] {
    def foos(x: Int) = "importIntFoo:" + x.toString
  }
}

object Main {
  def test(): String = {
    implicit val localIntFoo = new CanFoo[Int] {
      def foos(x: Int) = "localIntFoo:" + x.toString
    }
    import Def.importIntFoo
    
    foo(1)
  }
  
  def foo[A:CanFoo](x: A): String = implicitly[CanFoo[A]].foos(x)
}

println(Main.test)
</scala>

2.9.1 の場合、

    $ scala test.scala
    localIntFoo:1

2.10 nightly の場合、

    $ scala test.scala
    test.scala:18: error: ambiguous implicit values:
     both value localIntFoo of type Object with this.CanFoo[Int]
     and value importIntFoo in object Def of type => Object with this.CanFoo[Int]
     match expected type this.CanFoo[Int]
        foo(1)
           ^
    one error found

## 暗黙のパラメータ解決優先順位

以下が「形式主義的に少しくだけた」暗黙のパラメータ解決優先順位の説明だ:

- 1) 現在の呼び出しスコープから見えている、ローカルの宣言、インポート、外側のスコープ、継承、もしくはパッケージオブジェクト由来の implicit で、プリフィックスなし (つまり、`foo.x` のようなピリオドを使わずに) でアクセス可能なもの。
- 2) 探している implicit の型に少しでも関係のある様々なコンパニオンオブジェクトやパッケージオブジェクトから成る**暗黙のスコープ** (implicit scope) (具体的には、型のパッケージオブジェクト、型そのもののコンパニオンオブジェクト、もしあれば型の型コンストラクタのコンパニオン、もしあれば型の型パラメータのコンパニオン、型の親型や親トレイトのコンパニオンなど)。

もし、どちらかのステージにおいて複数の implicit が見つかった場合は、静的オーバーロード解決の規則 (static overloading rules) を使って解決される。

## 静的オーバーロード解決の規則

このルールはだらだらと長いので、主な点だけ抜粋する:

> The *relative weight* of an alternative *A* over an alternative *B* is a number from 0 to 2, defined as the sum of
> - 1 if *A* is as specific as *B*, 0 otherwise, and
> - 1 if *A* is defined in a class or object which is derived from the class or object defining *B*, 0 otherwise.
>
> A class or object *C* is *derived* from a class or object *D* if one of the following holds:
> - *C* is a subclass of *D*, or
> - *C* is a companion object of a class derived from *D*, or 
> - *D* is a companion object of a class from which *C* is derived.
>
> An alternative *A* is more specific than an alternative *B* if the relative weight of *A* over *B* is greater than the relative weight of *B* over *A*.
>
> 候補 *A* の候補 *B* に対する**相対的な重み** (*relative weight*) は 0 から 2 という数値で表され、以下の和である
> - *A* が *B* と同様に特定 (as specific) である場合は 1、その他の場合は 0、それと
> - *A* が *B* を定義するクラスやオブジェクトから派生するクラスやオブジェクト内で定義されている場合は 1、その他の場合は 0
> 
> クラスもしくはオブジェクトの *C* は、以下の一点でも満たす場合にクラスもしくはオブジェクトの *D* から**派生した**という:
> - *C* は *D* のサブクラスである、もしくは
> - *C* は *D* から派生したクラスのコンパニオンオブジェクトである、もしくは
> - *D* はあるクラスのコンパニオンオブジェクトであり、そのクラスから *C* が派生している
>
> 候補 *A* の候補 *B* に対する相対的な重みが、*B* の *A* に対する相対的な重みよりも大きいとき、*A* は *B* に対してより特定 (more specific) であるという。

ビューの場合は、もし候補のビュー *A* が *B* と同様に特定である場合、*B* に対して相対的な重み 1 が与えれる。

もし *A* が、*B* を定義する何かを派生するクラスの中で定義されていた場合は、さらに相対的な重みに 1 が加えられる。

## 輸入税の回避 (without the import tax)

優先順位に対する誤解を解いた所で、import を使わない API を設計したい場合にどこで implicit を定義できるかをおさらいしよう。

> 訳注: 元ネタは 2011年の Northeast Scala Symposium 2011 で Josh が発表した Implicits without the import tax: How to make clean APIs with implicits (import 税のかからない implicit: implict を用いていかにクリーンな API を作るか)。この発表で書かれている内容を言語仕様という視点から検証しようと先週試みたが失敗したので、本稿はその訂正版にあたる。

ユーザに任意のパッケージやクラス内でコード書いてもらって、かつ `import` を使わない場合は、カテゴリー1 (現行のスコープに載っている implicit) は避けるべきだ。

一方、カテゴリー2 (暗黙のスコープ) は好きに使える。

### 型T (もしくはその部分の) コンパニオンオブジェクト

関連する型の (この場合は型コンストラクタ) のコンパニオンオブジェクトに置くことをまず考えてみる:

<scala>
package foopkg

trait CanFoo[A] {
  def foos(x: A): String
}
object CanFoo {
  implicit val companionIntFoo = new CanFoo[Int] {
    def foos(x: Int) = "companionIntFoo:" + x.toString
  }
}  
object `package` {
  def foo[A:CanFoo](x: A): String = implicitly[CanFoo[A]].foos(x)
}
</scala>

これは一切の import 文を使わずに `foopkg.foo(1)` として呼び出すことができる。

### 型T のパッケージオブジェクト

`foopkg` のパッケージオブジェクトの親トレイトに置くことを次に考えてみる。

<scala>
package foopkg

trait CanFoo[A] {
  def foos(x: A): String
}
trait Implicit {
  implicit lazy val intFoo = new CanFoo[Int] {
    def foos(x: Int) = "intFoo:" + x.toString
  }
}
object `package` extends Implicit {
  def foo[A:CanFoo](x: A): String = implicitly[CanFoo[A]].foos(x)
}
</scala>

implicit をトレイトに置くことで複数 implicit がある場合に一ヶ所にまとめることができる。また、後にユーザが再利用したい場合に使いやすくなる。これをパッケージオブジェクトにミックスインすることで暗黙のスコープ上に搭載する。

## 静的モンキーパッチング

implicit の使い方で人気があるのが静的モンキーパッチングだ。

> 訳注: これも先週の記事からのネタだけど、"pimp" という差別的で、翻訳できない時代遅れのポップカルチャーネタの用語の代わりに別案として、"static monkey patching" (静的モンキーパッチング) と "method injection" (メソッドインジェクション) という用語を勝手に使っている。
> 具体例を出すと、`1` のような `Scala.Int` は `to` メソッドを持たないが、Scala は `1 to 2` と書かせてくれる。コンパイラは、`Int` を `RichInt` という**インジェクションクラス** (injection class) に暗黙に変換することで `to` メソッドを**注入** (inject) している、みたいな使いかたができる。

ここでは、`String` を大文字にして `"!!"` を追加する `yell` メソッドの静的モンキーパッチングを考えてみる。正式な用語では、これは**ビュー**と呼ばれる:

> A *view* from type *S* to type *T* is defined by an implicit value which has function type *S=>T* or *(=>S)=>T* or by a method convertible to a value of that type.
>
> 型*S* から 型*T* への**ビュー**は、*S=>T* もしくは *(=>S)=>T* という関数型を持つ暗黙の値もしくはそれらの型に変換可能なメソッドと定義される。

<scala>
package yeller

case class YellerString(s: String) {
  def yell: String = s.toUpperCase + "!!"
}
trait Implicit {
  implicit def stringToYellerString(s: String): YellerString = YellerString(s)
}
object `package` extends Implicit
</scala>

しかし、残念なことに `"foo".yell` は `yeller` パッケージの外では動作しない。これはコンパイラが暗黙の変換が可能であることを知らされていないためだ。これを回避するには、`import yeller._` を呼んでカテゴリー1 (現行のスコープに載っている implicit) に斬り込んでいくことになる。

<scala>
object Main extends App {
  import yeller._
  println("banana".yell)
}
</scala>

import が一つにまとまっているため、そう悪くはない。

### ユーザのパッケージオブジェクト

import を無くすことはできないだろうか? カテゴリー1 内で使えるのはユーザのパッケージオブジェクトだ。そこに、`Implicit` トレイトをミックスインできる:

<scala>
package userpkg

object `package` extends yeller.Implicit
object Main extends App {
  println("banana".yell)
}
</scala>

これで `BANANA!!` と import 無しで表示できた。

## まとめ

2.9.1 の動作から僕が導きだした結論とは全く逆に、複数の implicit の解決には「現行スコープ」のための特殊ルールなんてものは無かった。そこにあるのは、カテゴリー1、カテゴリー2、そして静的オーバーロード解決の規則だけだ。
