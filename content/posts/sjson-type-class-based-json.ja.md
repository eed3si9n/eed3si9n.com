---
title:       "sjson: Scala の型クラスによる JSON シリアライゼーション"
type:        story
date:        2010-11-06
changed:     2010-11-07
draft:       false
promote:     true
sticky:      false
url:         /ja/sjson-type-class-based-json
aliases:     [ /node/17 ]

# Summary:
# ver 0.7 より [sjson](http://github.com/debasishg/sjson) は元のものに加えリフレクションを使わない JSON シリアライゼーションプロトコルを用意した．これはユーザが任意のオブジェクトから JSON へシリアル化する自分のプロトコルを規定できるようになった．[リフレクションによる JSON シリアライゼーション](https://github.com/debasishg/sjson/wiki/reflection-based-json-serialization)ではアノテーションで行っていたものをカスタムプロトコルを自分で実装することで実現することができる．
# 

---
<!--break-->
> Debasish Ghosh さん ([@debasishg](http://twitter.com/debasishg)) の "[sjson: Now offers Type Class based JSON Serialization in Scala](http://debasishg.blogspot.com/2010/07/sjson-now-offers-type-class-based-json.html)" を翻訳しました．
> 元記事はこちら: [http://debasishg.blogspot.com/2010/07/sjson-now-offers-type-class-based-json.html](http://debasishg.blogspot.com/2010/07/sjson-now-offers-type-class-based-json.html)
> (翻訳の公開は本人より許諾済みです)
> 翻訳の間違い等があれば遠慮なくご指摘ください

長い間 [sjson](http://github.com/debasishg/sjson) のシリアライゼーション API はリフレクションに依存するものだった．この方法の長所としては，縁の下ではリフレクションによる実装が頑張っていても API は使いやすくすることができたということだ．

しかし，JSON 構造と Scala のオブジェクトでは型情報の豊かさに大きな違いがあることを忘れてはいけない．Scala から JSON にいくときに何らかの形で型情報をシリアライゼーションプロトコルの一部として保存しないかぎり，可逆変換させるのは場合によってはとてもトリッキーで難しいことになる．特に JVM では type erasure のせいで JSON構造にシリアル化した Scala オブジェクトの中には元に戻すのがほぼ不可能なものもあるだろう．

ver 0.7 より [sjson](http://github.com/debasishg/sjson) は元のものに加えリフレクションを使わない JSON シリアライゼーションプロトコルを用意した．これはユーザが任意のオブジェクトから JSON へシリアル化する自分のプロトコルを規定できるようになった．[リフレクションによる JSON シリアライゼーション](https://github.com/debasishg/sjson/wiki/reflection-based-json-serialization)ではアノテーションで行っていたものをカスタムプロトコルを自分で実装することで実現することができる．

sjons の型クラスによるシリアライゼーションは David MacIver による素晴らしい [sbinary](http://code.google.com/p/sbinary/wiki/IntroductionToSBinary) (現在は Mark Harrah により[メンテ](http://github.com/harrah/sbinary)されいる) にインスパイアされており，同じプロトコルを使いまた実装レベルでも色々と盗ませてもらった．

型クラスの基礎的概念への入門，Scala での実装，そして型クラスを使ったシリアライゼーションプロトコルが Scala でどう設計できるかについては，数週間前に書いた以下の blog 記事を参照してほしい:

- [Scala Implicits: 型クラス襲来](http://eed3si9n.com/ja/scala-implicits-type-classes)
- [Scala 型クラスへのリファクタリング](http://eed3si9n.com/ja/refactoring-into-scala-type-classes)

### 組み込み型の JSON シリアライゼーション

これは sjson でデフォルトのシリアライゼーションプロトコルを使った REPL セッションの一例だ...

```scala
scala> import sjson.json._
import sjson.json._

scala> import DefaultProtocol._
import DefaultProtocol._

scala> val str = "debasish"
str: java.lang.String = debasish

scala> import JsonSerialization._
import JsonSerialization._

scala> tojson(str)
res0: dispatch.json.JsValue = "debasish"

scala> fromjson[String](res0)
res1: String = debasish
```

ここで Scala のジェネリックなデータ型である `List` を考える．デフォルトのプロトコルはこのように動く...

```scala
scala> val list = List(10, 12, 14, 18)
list: List[Int] = List(10, 12, 14, 18)

scala> tojson(list)
res2: dispatch.json.JsValue = [10, 12, 14, 18]

scala> fromjson[List[Int]](res2)
res3: List[Int] = List(10, 12, 14, 18)
```

### 任意のクラスとカスタムプロトコル

前節では型クラスを用いたデフォルトプロトコルが標準データ型のシリアライゼーションに使われることをみた．あなた独自のクラスがある場合は，JSON シリアライゼーションのためのカスタムプロトコルを定義することができる．

例えば，`Person` という抽象体を定義する Scala の case class を考えてみよう．しかし，これをどうやって JSON にシリアル化してまた戻すのかを見る前に，まずは sjson の*ジェネリックなシリアライゼーションプロトコル*を見てみよう:

```scala
trait Writes[T] {
  def writes(o: T): JsValue
}

trait Reads[T] {
  def reads(json: JsValue): T
}

trait Format[T] extends Writes[T] with Reads[T]
```

`Format[]` はシリアライゼーションのためのコントラクト(契約)を規定する型クラスだ．あなた独自の抽象体のためには，それに対する `Format[]` 型クラスの実装を提供する必要がある．何らかの Scala モジュールの中で実際に `Person` に対する型クラスを実装してみよう．Scala の型クラスを使った設計について復習すると，モジュールは言語が提供する静的型検査によって適当なインスタンスを選択することを可能としている．これは Haskell には真似できない．

```scala
object Protocols {
  // 人を表す抽象体
  case class Person(lastName: String, firstName: String, age: Int)

  // 人のシリアライゼーションのためのプロトコルの定義
  object PersonProtocol extends DefaultProtocol {
    import dispatch.json._
    import JsonSerialization._

    implicit object PersonFormat extends Format[Person] {
      def reads(json: JsValue): Person = json match {
        case JsObject(m) =>
          Person(fromjson[String](m(JsString("lastName"))), 
            fromjson[String](m(JsString("firstName"))), fromjson[Int](m(JsString("age"))))
        case _ => throw new RuntimeException("JsObject expected")
      }

      def writes(p: Person): JsValue =
        JsObject(List(
          (tojson("lastName").asInstanceOf[JsString], tojson(p.lastName)), 
          (tojson("firstName").asInstanceOf[JsString], tojson(p.firstName)), 
          (tojson("age").asInstanceOf[JsString], tojson(p.age)) ))
    }
  }
}
```

プロトコルの実装に Nathan Hamblen による [dispatch-json](http://github.com/n8han/Databinder-Dispatch/tree/master/json/) ライブラリが使われていることに注目してほしい．基本的には `writes` と `reads` というメソッドが `Person` オブジェクトがどのように JSON シリアル化するのかということを規定している．Scala REPL を起ち上げてどう動くか見てみよう:

```scala
scala> import sjson.json._
import sjson.json._

scala> import Protocols._
import Protocols._

scala> import PersonProtocol._
import PersonProtocol._

scala> val p = Person("ghosh", "debasish", 20)
p: sjson.json.Protocols.Person = Person(ghosh,debasish,20)

scala> import JsonSerialization._
import JsonSerialization._

scala> tojson[Person](p)         
res1: dispatch.json.JsValue = {"lastName" : "ghosh", "firstName" : "debasish", "age" : 20}

scala> fromjson[Person](res1)
res2: sjson.json.Protocols.Person = Person(ghosh,debasish,20)
```

これでオブジェクトの JSON構造へシリアル化して，またオブジェクトに戻すことができた．`tojson` と `fromjson` というメソッドは型クラス `Format` を*暗黙*(implicit)のパラメータとして利用する．この二つのメソッドを定義する Scala モジュールはこのようになっている:

```scala
object JsonSerialization {
  def tojson[T](o: T)(implicit tjs: Writes[T]): JsValue = {
    tjs.writes(o)
  }

  def fromjson[T](json: JsValue)(implicit fjs: Reads[T]): T = {
    fjs.reads(json)
  }
}
```

### 冗長すぎ?

確かに独自のクラスのためにはあなたが色々とプロトコルを定義しなければならない．もし case class を使っているならば，sjson は冗長性を一気に取り去ることができる魔法の呪文を用意した．またしても Scala の型システムによる会心の一撃．

case class のみに使える簡潔な API を使ってどのようにして独自のクラスのためのプロトコルに拡張できるかを見てみよう．REPL のセッションだ...

```scala
scala> case class Shop(store: String, item: String, price: Int)
defined class Shop

scala> object ShopProtocol extends DefaultProtocol {
     |   implicit val ShopFormat: Format[Shop] = 
     |       asProduct3("store", "item", "price")(Shop)(Shop.unapply(_).get)
     |   }
defined module ShopProtocol

scala> import ShopProtocol._
import ShopProtocol._

scala> val shop = Shop("Shoppers Stop", "dress material", 1000)
shop: Shop = Shop(Shoppers Stop,dress material,1000)

scala> import JsonSerialization._
import JsonSerialization._

scala> tojson(shop)
res4: dispatch.json.JsValue = {"store" : "Shoppers Stop", "item" : "dress material", "price" : 1000}

scala> fromjson[Shop](res4)
res5: Shop = Shop(Shoppers Stop,dress material,1000)
```

`asProduct3` メソッドが裏で何をやっているのか興味がある人は是非ソースを見てほしい．
