---
title:       "Scala Implicits: 型クラス、襲来"
type:        story
date:        2010-11-03
changed:     2011-02-22
draft:       false
promote:     true
sticky:      false
url:         /ja/scala-implicits-type-classes
aliases:     [ /node/15 ]
---
<!--break-->
> Debasish Ghosh さん ([@debasishg](http://twitter.com/debasishg)) の "[Scala Implicits : Type Classes Here I Come](http://debasishg.blogspot.com/2010/06/scala-implicits-type-classes-here-i.html)" を翻訳しました．
> 元記事はこちら: [http://debasishg.blogspot.com/2010/06/scala-implicits-type-classes-here-i.html](http://debasishg.blogspot.com/2010/06/scala-implicits-type-classes-here-i.html)
> (翻訳の公開は本人より許諾済みです)
> 翻訳の間違い等があれば遠慮なくご指摘ください．

先日 Twitter 上で [Daniel](http://dcsobral.blogspot.com/) と Scala での型クラスについて論議していると，突然このトピックに関する書きかけだった記事を発見した．これを読んでもあなたは特に目新しい事を発見するわけではないが，型クラスに基づいた思考はあなたの設計の幅に価値を与えることができると思う．この記事を書き始めたのはしばらく前に[設計の直交性についての記事 (原文)](http://debasishg.blogspot.com/2010/01/case-for-orthogonality-in-design.html)を公開したときのことだ．

まずは GoF の Adapter  パターンから始めよう．[委譲型の Adapter](http://ja.wikipedia.org/wiki/Adapter_%E3%83%91%E3%82%BF%E3%83%BC%E3%83%B3#.E5.A7.94.E8.AD.B2.E3.82.92.E5.88.A9.E7.94.A8.E3.81.97.E3.81.9FAdapter) はよく勧められる合成(composition)というテクニック用いて抽象体(abstraction)[^1]どうしをバインドする．

設計の直交性のときと同じ例を使うと，

```scala
case class Address(no: Int, street: String, city: String, 
  state: String, zip: String)
```

これを `LabelMaker` というインターフェイスに適合させたいとする．つまり，我々は `Address` オブジェクトを `LabelMaker` として使いたい．

```scala
trait LabelMaker[T] {
  def toLabel(value: T): String
}
```

インターフェイス変換を行うアダプターは...

```scala
// Adapter クラス
case class AddressLabelMaker extends LabelMaker[Address] {
  def toLabel(address: Address) = {
    import address._
    "%d %s, %s, %s - %s".format(no, street, city, state, zip)
  }
}

// この Adapter は Address オブジェクトに LabelMaker のインターフェイスを提供する．
AddressLabelMaker().toLabel(Address(100, "Monroe Street", "Denver", "CO", "80231"))
```

さて，上の設計で我々が副次的に導入してしまった複雑さはなんだろう？

クライアントの立場から見ると，関心の的は元の抽象体である `Address` から，それをラップする Adapter クラスの `AddressLabelMaker` に移動してしまった．これは `Address` オブジェクトのアイデンティティ喪失[^2](identity crisis)を引き起こす．ラッパーを使ったイディオムでよくある問題だ．つまり，アダプトされる側のアイデンティティが Adapter のアイデンティティの中に埋もれてしまうのだ．さらに，ここで大胆にもアダプトされる側のクラスを他のクラスの集約メンバー (aggregate member) に使うとすると，明らかに Adapter の合成イディオムは崩壊してしまう．

*結論*: 委譲型の Adapter は合成することができない．[継承型の Adapter パターン](http://ja.wikipedia.org/wiki/Adapter_%E3%83%91%E3%82%BF%E3%83%BC%E3%83%B3#.E7.B6.99.E6.89.BF.E3.82.92.E5.88.A9.E7.94.A8.E3.81.97.E3.81.9FAdapter)は，初めから継承による配線がなされており，設計全体がいっそう硬直になりで結合度(coupling)が高いという意味でより有害だ．

### 型クラス登場
上記の Adapter パターンでは，アダプトされる側が Adapter にラップされアイデンティティを喪失してしまうことが分かった．ここで別の方法を使ってクライアントの用法の中から Adapter のインスタンスを抽象的に抜き出すことができないか試してみよう．型クラスはまさにこのような抽象物の合成(composition of abstraction)を提供する．言語の型システムがコンパイル時に適当な Adapter インスタンスを選んでくれるため，ユーザは明示的にアダプトされる側のクラスを使ってコードを書くことができる．

例えばこの `printLabel` 関数を見てほしい．これは一つの引数を取り，我々が提供する `LabelMaker` を用いてラベルを出力する...

```scala
def printLabel[T](t: T)(lm: LabelMaker[T]) = lm.toLabel(t)
```

これに `Address` のラベルを作らさせるには，それを実行する Adapter を定義する必要がある．Scala には object 構文による first-class なモジュールのサポートがある．`Address` を `LabelMaker` に変換するモジュールを定義してみよう．

```scala
object LabelMaker {
  implicit object AddressLabelMaker extends LabelMaker[Address] {
    def toLabel(address: Address): String = {
      import address._
      "%d %s, %s, %s - %s".format(no, street, city, state, zip)
    }
  }
}
```

この Adapter は `implicit` 修飾子付きの object であることに注意してほしい．これは何をするかというと，構文スコープ(lexical scope)内に適当なものを探すことができた場合に暗黙の(implicit)パラメータにコンパイラが渡してくれるというものだ．そのためには `printLabel` 関数の `LabelMaker` パラメータも `implicit` 宣言しなければいけない．

```scala
def printLabel[T](t: T)(implicit lm: LabelMaker[T]) = lm.toLabel(t)
```

これを Scala 2.8 の [context bound 構文](http://blog.takeda-soft.jp/blog/show/396)で書くと，implicit パラメータを匿名にすることができる...

```scala
def printLabel[T: LabelMaker](t: T) = implicitly[LabelMaker[T]].toLabel(t)
```

我々は implicit パラメータには何も提供せず，context bound 構文を用いることでコンパイラは自動的に直近の構文スコープから適当なインスタンスを選んで渡してくれる．上記の例では `implicit object AddressLabelMaker` があなたが `printLabel` を呼び出すメソッドのスコープに入っていなくてはいけない．適当なインスタンスが見つからない場合は文句を言う．つまり，コンパイル時に失敗するため，邪悪な実行時のエラー無しということだ．スゴくないだろうか．

早速 `Address` からラベルを作ってみよう...

```scala
printLabel(Address(100, "Monroe Street", "Denver", "CO", "80231"))
```

委譲型の Adapter にあったようなクライアントコードにおける副次的な複雑さは無くなり，抽象体は明示的に定義されており，ラベルの出力が必要なものにのみクラスが提供されている．それだけでなく，設計全体の表層部分を構成する様々な抽象体を見れば，モジュール性が浮かびがってくるだろう．クライアントは型クラスの定義のみに対してコードを書き，型クラスのインスタンスはコンパイラ**のみ**の目に触れるよう抽象化されている．

### Haskell ならどうする？
ここまで一言も Haskell に触れずに型クラスについて論じてきた．ここで改めて上の設計が Haskell の純粋関数型プログラミングの世界にどうあてはまるか見てみよう．

`LabelMaker` は型クラスだ．これを Haskell で定義すると...

<haskell>
class LabelMaker a where
    toLabel :: a -> String
</haskell>

これは Scala の `trait LabelMaker` に対応する．

`Address` を `LabelMaker` に変換したい．`Address` のための型クラスのインスタンスは以下のようになる...

<haskell>
instance LabelMaker Address where
    toLabel (Address h s c st z) = show(h) ++ " " ++ s ++ "," ++ c ++ "," ++ st ++ "-" ++ z
</haskell>

これは Scala の `implicit object AddressLabelMaker` の定義に対応する．Scala のモジュールのサポートは Haskell には無い機能だ．

ちなみにレコード構文を使った `Address` の定義は以下のとおり...

<haskell>
type HouseNo = Int
type Street = String
type City = String
type State = String
type Zip = String

data Address = Address {
      houseNo        :: HouseNo
    , street         :: Street
    , city           :: City
    , state          :: State
    , zip            :: Zip
    }
</haskell>

これで型クラスを使って `String` を生成する `printLabel` を定義することができる...

<haskell>
printLabel :: (LabelMaker a) => a -> String
printLabel a = toLabel(a)
</haskell>

これは Scala の `printLabel` に対応する．

### 考察
型クラスのインスタンスの定義を見ると Scala の実装に比べて Haskell の方がかなりスッキリしてることに注意してほしい．Scala のここでの冗長さには理由があり，Haskell の定義に比べて確かな利点がある．Scala の場合はインスタンスを明示的に `AddressLabelMaker` と名付けたが，Haskell でのインスタンスは匿名である．Haskell コンパイラはグローバル名前空間のディクショナリを見て適合するインスタンスを探し出す．Scala の場合はこの検索がメソッドが呼び出されるスコープの中でローカルに実行される．さらに，Scala でのインスタンスが明示的に命名されているため別のインスタンスをスコープ上に注入することができ，それが implicit パラメータに渡されるようになる．上の例で言うと，`Address` のためにラベルを特殊な方法で出力する型クラスの別のインスタンスがほしいとする...

```scala
object SpecialLabelMaker {
  implicit object AddressLabelMaker extends LabelMaker[Address] {
    def toLabel(address: Address): String = {
      import address._
      "[%d %s, %s, %s - %s]".format(no, street, city, state, zip)
    }
  }
}
```

普通のインスタンスの代わりにこの特殊なインスタンスをスコープに取り込めば，特殊な方法で住所のラベルを生成することができる...

```scala
import SpecialLabelMaker._
printLabel(Address(100, "Monroe Street", "Denver", "CO", "80231"))
```

これは Haskell には無い機能だ．

### Scala と Haskell の型クラス

型クラスはアダプトされる側の型が実装しなければいけないコントラクト(契約)を定義する．多くの人が型クラスを Java や他の言語における interface と同義だと誤解している．interface ではサブクラスによる多態性に焦点がおかれるのに対し，型クラスではパラメトリックな多相性に焦点が移る．全く関係の無い型がそれぞれに型クラスが公開するコントラクトを実装していくのだ．

型クラスの実装には二つの側面がある:
1. インスタンスが実装する必要のあるコントラクトを定義する
2. 言語が提供する静的型検査に基づいて適当なインスタンスの選択を行う

Haskell は class 構文を用いて (1) を実装するが，ここでのクラスはオブジェクト指向プログラミングで我々が慣れ親しんだ概念とは全く別のものだ．Scala では trait と object による trait の拡張を使ってこの機能を実装した．

前述の通り，Haskell はグローバルなディクショナリを用いて (2) を実装するが，Scala はメソッド呼び出し直近のスコープを検索することで行われる．これにより，ローカルスコープにインスタンスを取り込むことで，インスタンスを選択することができ，Scala によりいっそうの柔軟性を与えている．

[^1]: 訳注: abstraction を抽象体と訳した．実装に対する概念としての「構造と振る舞いから本質的な部分を抜き出したもの」だ．ここではモジュール性やコンポーネントにおける外部インターフェイスや API に近い意味で使われており，必ずしも Java やその他の言語における抽象クラスである必要はなく，C のヘッダファイルなど関数群も抽象体と考えることができる．
[^2]: 訳注: identity crisis をアイデンティティ喪失と訳した．ちょっと大げさなのではないかと一見思われるかもしれないが，Adapter などのラッパーがオブジェクト本来のアイデンティティを奪ってしまう問題をアイデンティティ問題と表現することは，一部の界隈では一般的に行われている．最近だと Clojure が [expression problem](http://www.daimi.au.dk/~madst/tool/papers/expression.txt) への解決方法として提示したプロトコルという機構の[解説記事](http://formpluslogic.blogspot.com/2010/08/clojure-protocols-and-expression.html)や[プレゼンテーション pdf](http://strangeloop2010.com/talk/presentation_file/14491/Houser-ClojureExpressionProblem.pdf)のなかでラッパーの欠点としてアイデンティティ問題が挙げられている．この expression problem というのが実は肝で，既にある型に対して再コンパイル無しで，静的型安全性を保ったまま，型に新たなケースを追加したり型に対する関数を追加できるかという問題だ．型クラスはまさにこの expression problem への解法となる．Microsoft の [expression problem に関する C9 lecture](http://channel9.msdn.com/Shows/Going+Deep/C9-Lectures-Dr-Ralf-Laemmel-Advanced-Functional-Programming-The-Expression-Problem) でもやっぱり型クラスだよね，と言っている．ラッパーのアイデンティティ問題に関しては，1993年の[別々に開発したコンポーネントをどうつなぐかという論文](http://citeseerx.ist.psu.edu/viewdoc/summary?doi=10.1.1.52.7371)などでも言われている．
