---
title:       "Scala でのクラス線形化 (mixin 順序) の制約"
type:        story
date:        2013-12-22
draft:       false
promote:     true
sticky:      false
url:         /ja/constraining-class-linearization-in-Scala
aliases:     [ /node/155 ]
tags:        [ "scala" ]
---

昨日は、何故か早朝に目が覚めて [@xuwei_k](https://twitter.com/xuwei_k)氏の[Scalaで抽象メソッドをoverrideする際にoverride修飾子を付けるべきかどうかの是非](http://d.hatena.ne.jp/xuwei/20131220/1387509706)を流し読みしていた。この話題は面白すぎたので、飛び起きてすぐに[英訳](http://eed3si9n.com/curious-case-of-putting-override-modifier)してしまった。Scalaz で遭遇したコードを例にして型クラスのデフォルトインスタンスを提供することの微妙なジレンマを解説している。

以下に問題を簡略化したコード例を示す:

<scala>
trait Functor {
  def map: String
}
trait Traverse extends Functor {
  override def map: String = "meh"
}
sealed trait OneOrFunctor extends Functor {
  override def map: String = "better"
}
sealed trait OneOrTraverse extends OneOrFunctor with Traverse {
}
object OneOr {
  def OneOrFunctor: Functor = new OneOrFunctor {}
  def OneOrTraverse: Traverse = new OneOrTraverse {}
}
</scala>

これをテストするには以下を実行する:

<scala>
scala> OneOr.OneOrTraverse.map
res0: String = meh
</scala>

`OneOr.OneOrTraverse.map` は `"better"` を期待しているけども、`map` の実装は意図せずに `Traverse` のデフォルトインスタンスによって乗っ取られてしまった。

@xuwei_k氏は抽象メソッドのオーバーライド時に `override` 修飾子を付けるか否かの先行研究があるか聞いているので、考えてみよう。Scala は型クラスのインスタンス定義を項の空間と統合 (見方によってはコンプレクト) して、順序は継承関係によって指定されるので、関数型プログラミングというよりはモジュラープログラミングの話になる。Mixin 順序全般に関するトピックは**クラス線形化** (class linearization) と呼ばれる。本稿で取り上げる内容はだいたいコップ本第二版にも書いてあることだと思う。

## クラス線形化の補題

@xuwei_k氏の `override` のジレンマは以下の補題として言い換える事ができる:

- trait `OneOrFunctor` と `Traverse` があるとき、`Traverse` が `OneOrFunctor` の後にくるようなクラス線形化を禁止することができるか?

### abstract override

普通の trait はインターフェイスのような役割をするのに対して、Scala は [*stackable* traits][Venners] を提供して、これはクラスの振る舞いを変更する。trait を stackable にするには、まずクラスか trait から継承して、メソッドに `abstract override` という修飾子を付ける。この修飾子の目的は、メソッド本文内から `super` へのアクセスを可能とすることだ。trait の `super` は動的に束縛されるため、通常はアクセスすることができない。

<scala>
scala> :paste
// Entering paste mode (ctrl-D to finish)

abstract class Functor {
  def map: String
}
sealed trait OneOrFunctor extends Functor {
  override def map: String = super.map
}

error: method map in class Functor is accessed from super. It may not be abstract unless it is overridden by a member declared `abstract' and `override'
         override def map: String = super.map
                                          ^
</scala>

`super` にアクセスする必要があるため、stackable trait は具象実装が出てきた**後で**のみ mix in することができる。これを使って mixin の順序、つまりクラス線形化に制約を設けることができるかもしれない。

<scala>
scala> :paste
// Entering paste mode (ctrl-D to finish)

trait Functor {
  def map: String
}
trait Traverse extends Functor {
  override def map: String = "meh"
}
sealed trait OneOrFunctor extends Functor {
  abstract override def map: String = "better"
}
sealed trait OneOrTraverse extends OneOrFunctor with Traverse {
}
object OneOr {
  // def OneOrFunctor: Functor = new OneOrFunctor {}
  def OneOrTraverse: Traverse = new OneOrTraverse {}
}

error: overriding method map in trait OneOrFunctor of type => String;
 method map in trait Traverse of type => String needs `abstract override' modifiers
       sealed trait OneOrTraverse extends OneOrFunctor with Traverse {
                    ^
</scala>

`OneOrFunctor` は stackable であるため、mixin できる前に `map` の実装を必要とする。順序を `extends Traverse with OneOrFunctor` に直すことでコンパイルに成功する。

この方法にはいくつか問題がある。第一に、`Traverse` から `map` の実装をもらわない場合の `OneOr.OneOrFunctor` が壊れる。第二に、`Traverse` が実装を提供していることに依存することそのものが筋の悪い設計だと言える。

### abstract class

`OneOrFunctor` を制御することが一応できたということは、`Traverse` が早めに来るにように強制することもできるかもしれない。喩えると、API クラスと実装クラスを分ける「壁」のようなものが欲しい。

<scala>
sealed trait OneOrTraverse extends Traverse with !壁! with OneOrFunctor {
}
</scala>

線形化のルールで強制される不変条件の一つにクラスの階層順序は保存されなければいけないというものがある。これは典型的には抽象クラスを線形化の後の方へ押すことになる。例えば、`Functor` と `Traverse` を抽象クラスとして定義できる:

<scala>
abstract class Functor {
  def map: String
}
abstract class Traverse extends Functor {
  override def map: String = "meh"
}
sealed trait OneOrFunctor extends Functor {
  override def map: String = "better"
}
sealed trait OneOrTraverse extends OneOrFunctor with Traverse {
}
object OneOr {
  def OneOrFunctor: Functor = new OneOrFunctor {}
  def OneOrTraverse: Traverse = new OneOrTraverse {}
}

error: class Traverse needs to be a trait to be mixed in
       sealed trait OneOrTraverse extends OneOrFunctor with Traverse {
                                                            ^
</scala>

うまくいった。`OneOrFunctor` が trait mixin フェーズを開始するため、`Traverse` の参加は禁止されることになった。しかし、この特定の実装の欠点は Scalaz の全ての型クラスを大きな木構造に強制する必要があることだ。それでは型クラスの意味が無い。例えば、現実では `Traverse` は `Functor` と `Foldable` を継承する:

<scala>
abstract class Functor {
  def map: String
}
abstract class Foldable {
  def foldMap: String
}
abstract class Traverse extends Functor with Foldable {
  override def map: String = "meh"
  override def foldMap: String = "meh"
}

error: class Foldable needs to be a trait to be mixed in
       abstract class Traverse extends Functor with Foldable {
                                                    ^
</scala>

### final

[@yasushia](https://twitter.com/yasushia)氏のツイートで `final` 修飾子を使えばのオーバーライドを防げることを思い出した。これは一度試ししたけどうまくいかなかったような気がするがもう一度やってみる。

<scala>
trait Functor {
  def map: String
}
trait Traverse extends Functor {
  override def map: String = "meh"
}
sealed trait OneOrFunctor extends Functor {
  final override def map: String = "better"
}
sealed trait OneOrTraverse extends OneOrFunctor with Traverse {
}
object OneOr {
  def OneOrFunctor: Functor = new OneOrFunctor {}
  def OneOrTraverse: Traverse = new OneOrTraverse {}
}

error: overriding method map in trait OneOrFunctor of type => String;
 method map in trait Traverse of type => String cannot override final member
       sealed trait OneOrTraverse extends OneOrFunctor with Traverse {
                    ^
</scala>

あっさりうまくいった。多くの場合はこの方法でいけるかもしれない。欠点としては final なのでこれ以上実装側でオーバーライドできないということだ。

### patronus type

もう一つ思いついた方法があって、抽象型メンバーを使って phantom type のようにガードとして使えないかということだ。型のオーバーライドも線形化に従うため、壁として機能してくれるかもしれない。

<scala>
trait Interface {
  type Guard
}
trait Functor extends Interface {
  def map: String
  override type Guard <: Interface
}
trait Traverse extends Functor {
  override def map: String = "meh"
  override type Guard <: Interface
}
trait Implementation extends Interface {
  override type Guard <: Implementation
}
sealed trait OneOrFunctor extends Functor with Implementation {
  override def map: String = "better"
}
sealed trait OneOrTraverse extends OneOrFunctor with Traverse {
}
object OneOr {
  def OneOrFunctor: Functor = new OneOrFunctor {}
  def OneOrTraverse: Traverse = new OneOrTraverse {}
}

error: overriding type Guard in trait Implementation with bounds <: Implementation;
 type Guard in trait Traverse with bounds <: Interface has incompatible type
       sealed trait OneOrTraverse extends OneOrFunctor with Traverse {
                    ^
</scala>

これは、ひょっとしていけるかもしれない。`Traverse` が先にくるように直してコンパイルが通るかも試してみよう。

<scala>
trait Interface {
  type Guard
}
trait Functor extends Interface {
  def map: String
  override type Guard <: Interface
}
trait Traverse extends Functor {
  override def map: String = "meh"
  override type Guard <: Interface
}
trait Implementation extends Interface {
  override type Guard <: Implementation
}
sealed trait OneOrFunctor extends Functor with Implementation {
  override def map: String = "better"
}
sealed trait OneOrTraverse extends Traverse with OneOrFunctor {
}
object OneOr {
  def OneOrFunctor: Functor = new OneOrFunctor {}
  def OneOrTraverse: Traverse = new OneOrTraverse {}
}

// Exiting paste mode, now interpreting.

defined trait Interface
defined trait Functor
defined trait Traverse
defined trait Implementation
defined trait OneOrFunctor
defined trait OneOrTraverse
defined module OneOr

scala> OneOr.OneOrTraverse.map
res0: String = better
</scala>

`"better"` が表示されたので、うまくいった! 全ての型クラスが `type Guard` をオーバーライドする必要があるけども、これは実行時に型消去されるはずだ。もし既に名前が無いならば型レベルの守護霊を *patronus type* と呼ぶことにする。

### 参考文献

- M. Odersky and M. Zenger. [Scalable Component Abstractions (pdf)](http://www.scala-lang.org/old/sites/default/files/odersky/ScalableComponent.pdf). In  OOPSLA 2005, 2005.
- J. McBeath. [Scala Class Linearization](http://jim-mcbeath.blogspot.com/2009/08/scala-class-linearization.html). 2009.
- B. Venners. [Scala's Stackable Trait Pattern][Venners]. 2009.
- T Nurkiewicz. [Scala traits implementation and interoperability. Part II: Traits linearization](http://java.dzone.com/articles/scala-traits-implementation-0). 2013.

[Venners]: http://www.artima.com/scalazine/articles/stackable_trait_pattern.html
