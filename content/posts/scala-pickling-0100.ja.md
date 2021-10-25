---
title:       "Scala Pickling 0.10.0"
type:        story
date:        2015-02-07
draft:       false
promote:     true
sticky:      false
url:         /ja/scala-pickling-0100
aliases:     [ /node/177 ]
tags:        [ "scala" ]
---

  [Kennedy]: http://research.microsoft.com/pubs/64036/picklercombinators.pdf
  [Miller]: http://infoscience.epfl.ch/record/187787/files/oopsla-pickling_1.pdf
  [Pickling]: https://github.com/scala/pickling
  [1]: http://docs.oracle.com/javase/7/docs/api/java/io/Serializable.html

> [pickling 0.10.0](http://notes.implicit.ly/post/110275857699/pickling-0-10-0) として implicit.ly に投稿したものを訳しました。
> 最近コミッター権をもらいましたが、Pickling の 90% 以上は Eugene Burmako、Heather Miller、Philipp Haller によって書かれています。

Scala Pickling は、Scala のための自動シリアライゼーション・フレームワークで、0.10.0 が初の安定版となる。Pickling は高速で、ボイラープレート (冗長なお決まりコード) 無しで書くことができ、ユーザ側で (バイナリや JSON などの) シリアライゼーション・フォーマットを簡単に差し替えることができる。また、0.10.x シリーズ中はバイナリ互換性とフォーマットの互換性の両方を保つ予定だ。

## Pickling を短くまとめると

ある任意の値、例えば　`Person("foo", 20)` を pickle する (シリアライズ化を保存食に喩えて、漬物に「漬ける」と言う) とき、以下の 2つのものが必要になる:

1. 与えられた型 `Person` の [pickler コンビネータ][Kennedy]
2. pickle フォーマット

`Pickler[A]` は `A` を**エントリー**、**フィールド**、**コレクション**といった抽象的なものに分解することを担当する。プリミティブな pickler を合成して複合的な pickler を作ることができるため、コンビネータと呼ばれている。一方 `PickleFormat` は**フィールド**などの抽象的な概念をバイナリやテキストといった形に具現化する。

## Defaults モード

以下は基本形である `Defaults` モードの使用例だ。

```scala
scala> import scala.pickling.Defaults._, scala.pickling.json._
scala> case class Person(name: String, age: Int)

scala> val pkl = Person("foo", 20).pickle
pkl: pickling.json.pickleFormat.PickleType =
JSONPickle({
  "$type": "Person",
  "name": "foo",
  "age": 20
})

scala> val person = pkl.unpickle[Person]
person: Person = Person(foo,20)
```

この `Defaults` モードは、プリミティブ pickler 群から `Pickler[Person]` をコンパイル時に自動的に導出する!
コードが静的に生成されるため、文字列の操作などもインライン化して高速化している。(同じくスキーマを使わない [Java serialization や Kryo に比べても速い][Miller])

ここで注目してほしいのは、`Pickler[A]` は型クラスであるため、`Person` クラスを改変して [Serializable][1]のようなものを継承するといったことをせずに追加導入することができることだ。

## カスタム・プロトコル・スタック

Pickling 0.10.0 からの新機能として pickler、演算子、フォーマットが別々の trait として提供されるようになったため、サードパーティーのライブラリ側が好みで積み上げてカスタム・モードを提供することができるようになった。例えば、プリミティブ型と `Apple` だけを pickle したくて、自動的な pickler コンビネータの導出はして欲しくないとする。以下が、カスタム・モードになる:

```scala
scala> case class Apple(kind: String)
scala> val appleProtocol = {
         import scala.pickling._
         new pickler.PrimitivePicklers with pickler.RefPicklers
             with json.JsonFormats {
           // Manually generate pickler for Apple
           implicit val applePickler = PicklerUnpickler.generate[Apple]
           // Don't fall back to runtime picklers
           implicit val so = static.StaticOnly
           // Provide custom functions
           def toJsonString[A: Pickler](a: A): String =
             functions.pickle(a).value
           def fromJsonString[A: Unpickler](s: String): A =
             functions.unpickle[A](json.JSONPickle(s))
         }
       }
```

ユーザ側はこのように使う:

```scala
scala> import appleProtocol._

scala> toJsonString(Apple("honeycrisp"))
res0: String =
{
  "$type": "Apple",
  "kind": "honeycrisp"
}
```

より詳しくは以下の資料を参照

- Github プロジェクト: https://github.com/scala/pickling
- Scala Days 2013 talk: http://www.parleys.com/play/51c3799fe4b0d38b54f4625a/chapter0/about
- Pickler Combinators. Kennedy, 2004: http://research.microsoft.com/en-us/um/people/akenn/fun/picklercombinators.pdf
- Instant Pickles: Generating Object-Oriented Pickler Combinators for Fast and Extensible Serialization. Miller, Haller, Burmako, and Odersky, 2013: http://infoscience.epfl.ch/record/187787/files/oopsla-pickling_1.pdf
