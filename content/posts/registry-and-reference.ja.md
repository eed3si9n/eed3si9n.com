---
title:       "registry and reference パターン"
type:        story
date:        2016-07-03
changed:     2016-07-04
draft:       false
promote:     true
sticky:      false
url:         /ja/registry-and-reference
aliases:     [ /node/203 ]
---

  [fowler]: http://martinfowler.com/eaaCatalog/registry.html

ここ最近考えている「パターン」があって、オブジェクトを永続化/シリアライゼーションするみたいな状況で出てくる。

問題提起として、以下のような case class を考えてみてほしい:

```scala
scala> case class User(name: String, parents: List[User])
defined class User

scala> val alice = User("Alice", Nil)
alice: User = User(Alice,List())

scala> val bob = User("Bob", alice :: Nil)
bob: User = User(Bob,List(User(Alice,List())))

scala> val charles = User("Charles", bob :: Nil)
charles: User = User(Charles,List(User(Bob,List(User(Alice,List())))))

scala> val users = List(alice, bob, charles)
users: List[User] = List(User(Alice,List()), User(Bob,List(User(Alice,List()))),
  User(Charles,List(User(Bob,List(User(Alice,List()))))))
```

注目してほしいのは `parents` という他のユーザを参照するリストを保持してることだ。
次に、`users` リストを JSON に変換したいとする。

<code>
[{ "name": "Alice", "parents": [] },
{ "name": "Bob",
  "parents": [{ "name": "Alice", "parents": [] }] },
{ "name": "Charles",
  "parents": [{ "name": "Bob", "parents": [{ "name": "Alice", "parents": [] }] }] }]
</code>

この方法だと複数の問題点がある。まず、JSON の表記として効率が悪いし JSON データとして期待される自然な感じではないことだ。次に、これを case class に変換しなおしたときにオブジェクトのグラフごとインスタンス化する必要があって、それも非効率だし、望ましくない状況が多いと思う。

データが関数値などを保持しているとさらに厄介なことになってくる。

### registry and reference パターン

この対策として考えているものを僕は registry and reference パターンと呼んでいる。基本的な考えとしては、予め 3人のユーザを registry (登記所) に登録して、JSON は以下のような内容で伝達する:

<code>
["Alice", "Bob", "Charles"]
</code>

ググってみると Martin Fowler 先生も [Registry パターン][fowler]と呼んでいるみたいだ。彼のモデルだと Registry は以下の 2つのメソッドを含む:

- getPerson(id)
- addPerson(Person)

僕がやりたいのは任意のデータ型とその参照というペアに対して動作するデータ構造を作ることだ。

### 用例

実装に入る前に使ってみるとどうなのかをみてみよう。

```scala
scala> case class UserRef(name: String)
defined class UserRef
```

まずは `User` のための適当な参照型を定義する必要がある。これは、値に対するアドレスシステムで ID や URL のようなものと考えるといいと思う。

```scala
scala> implicit val userReg = Registerable[User, UserRef](u => UserRef(u.name))
userReg: sbt.Registerable.Aux[User,UserRef] = sbt.Registerable$$anon$1@69154910
```

次に、一ユーザからどのようにして `UserRef` を作成するのかを教える必要がある。

```scala
scala> val aliceRef: UserRef = Registry[User].append(alice)
aliceRef: UserRef = UserRef(Alice)
```

`alice` を `Registry[User]` に追加すると、Alice への参照値が返ってくる。

```scala
scala> val bobRef: UserRef = Registry[User].append(bob)
bobRef: UserRef = UserRef(Bob)

scala> val charlesRef: UserRef = Registry[User].append(charles)
charlesRef: UserRef = UserRef(Charles)

scala> val xs = List(aliceRef, bobRef, charlesRef)
xs: List[UserRef] = List(UserRef(Alice), UserRef(Bob), UserRef(Charles))
```

実際の `User` の代わりに `UserRef` を使うようにする。例えば、ユーザのリストを表現するには `List[UserRef]` を使う。そうすると `xs` は `["Alice", "Bob", "Charles"]` というふうに永続化できる。

僕たちが必要なのは値への参照であって、その値がどう構築されたかは特にいらない場合がよくある。例えばユーザのリストは都心から 30km 以内に住んでいるユーザのリストであるかもしれない。その場合、ユーザのアイデンティティさえ分かればいい。

別の見方をすると、これはある種の間接性 (indirection) を提供していると考えられる。前述のとおり URL はその良い例だ。

参照値を実際の `User` に変換するには registry を参照すればいい:

```scala
scala> val users = xs map { x => Registry[User].get(x).get }
users: List[User] = List(User(Alice,List()), User(Bob,List(User(Alice,List()))), User(Charles,List(User(Bob,List(User(Alice,List()))))))
```

`Registry` は `Map` のように振舞っていて、与えられたデータ型に対してその参照型しか受け付けないことに注目してほしい。間違って `Int` を渡すとコンパイル時にエラーになる。

```scala
scala> val bad = Registry[User].get(0)
<console>:15: error: inferred type arguments [Int] do not conform to method get's type parameter bounds [B <: userReg.R]
       val bad = Registry[User].get(0)
                                ^
<console>:15: error: type mismatch;
 found   : Int(0)
 required: B
       val bad = Registry[User].get(0)
                                    ^
```

### 実装

実装は 2つの部分から構成されている。まずは `Registerable`:

```scala
trait Registerable[A] {
  type R
  def toRef(a: A): R
}

object Registerable {
  type Aux[A0, R0] = Registerable[A0] {
    type R = R0
  }
  def apply[A, R0](toRef0: A => R0): Aux[A, R0] = new Registerable[A] {
    type R = R0
    def toRef(a: A): R = toRef0(a)
  }
}
```

データ型 `A` とその参照型 `R` が必要なので、型クラスのインスタンスは 2つの型パラメータを受け付ける。
ただし、このインスタンスを照会するときは `A` だけで探したい。これを実現するために、ここでは `Aux` 型という Miles Sabin さんが shapeless で使って流行り始めたテクニックを使っている。

次が `Registry` で、基本的には可変な並行 TrieMap のラッパーだ。

```scala
import scala.collection.concurrent.TrieMap

object Registry {
  private val registries: TrieMap[Registerable[_], Registry[_, _]] = TrieMap.empty
  def apply[A](implicit ev: Registerable[A]): Registry[A, ev.R] =
    registries.getOrElseUpdate(ev, new Registry[A, ev.R](ev)).
      asInstanceOf[Registry[A, ev.R]]
}

class Registry[A, R](ev: Registerable.Aux[A, R]) {
  private val registered: TrieMap[R, A] = TrieMap.empty
  def get[B <: R](ref: B): Option[A] =
    registered.get(ref)

  def append(value: A): R = {
    val key = ev.toRef(value)
    if (!registered.contains(key)) {
      registered(key) = value
    }
    key
  }
}
```

だいたい普通だけども、ちょっと変わっているのが `def get` で、これは型制約 `B <: R` の付いた型パラメータ `B` を受け取る。
代わりに `B =:= R` を implicit な証明として受け取ることも可能だけど、`B <: R` にしておくと `R` のサブタイプも受け付けることができる。

この実装だと値は全てメモリーに保持するので、大量に値を追加するのには向いていない。

### これってグローバルオブジェクトでは?

予め警告しておくと、この registry パターンというのは、基本的にはグローバルオブジェクトを美化したものだということだ。
registry は必ずしもグローバルにする必要は無いけども、何らかの形で以下のようなタイミングという概念が入ってくるのは避けられないと思う。

1. 使われる全ての値を registry に登録する。
2. 得られた参照値を使って JSON などに永続化できるようになる。

電線の受け取り側でも同じことを繰り返す必要がある。

1. 何らかの方法で使われる全ての値を探しだして、全て registry に登録する。
2. JSON などから参照値を抽出する。
3. 参照値を値に変換する。

値の追加と参照値の使用が交互に何回も現れてくると状況は複雑になるだろう。

グローバルオブジェクトっていうのは理想的では無いけども、永続化が難しい物を永続化しなくてはいけない状況においては役立つものじゃないかと思っている。その良い例が `String => String` みたいな関数値だ。sbt の内部実装では何かを表現するのに柔軟性のために関数値のラッパーを用いることがある。これらの永続化は難しいし、多分実際の関数を永続化する必要は無いと思う。

`ModuleID` を例にみてみよう。これはビルドユーザも定義する頻出するデータ型だ。

```scala
final case class ModuleID(organization: String, name: String, revision: String,
  configurations: Option[String] = None, ....
  crossVersion: CrossVersion = CrossVersion.Disabled)
```

この `ModuleID` のフィールドに `CrossVersion` 型というものがある。これは sealed trait でその子型として関数ラッパーの `Binary` というものを持つ:

```scala
  final class Binary(val remapVersion: String => String) extends CrossVersion {
    override def toString = "Binary"
  }
```

`String => String` を永続化するが不可能だと合意できるならば、すなわち `ModuleID` も依存性グラフも永続化することは不可能だということになる。依存性グラフを永続化するために sbt 0.13 が現在何をやっているかと言うと、JSON に永続化する時点で関数値は捨てられている。 (永続化された `ModuleID` は `UpdateReport` にだけ出てきて実際の依存性解決には使われていないので大丈夫なはず。)

registry and reference パターンを使うことで、例えば `String` の名前を持つ `CrossVersionRef` という参照型を定義して、定義済みの値以外での特殊なロジックが欲しいビルドユーザはそれに名前を付けることを強制することができる。もし `ModuleID` に `CrossVersionRef` が使われていれば、`ModuleID` の安全な JSON への永続化に一歩近づくと思う。

### 等価性

等価性の検査は隣接したトピックだ。永続化可能な参照値は等価性の検査も簡単にできる。

### まとめ

内部構造や関数といった永続化するのが難しいものを永続化したい状況が出てくる。registry and reference パターンはその対策を提示するが、初期化が複雑になるといった別の問題も導入することになる。

`Registry` は内部で `TrieMap` を使った registry の実装で、型クラスを使うことで与えられたデータ型 `A` に対する参照型を決定することができる。
