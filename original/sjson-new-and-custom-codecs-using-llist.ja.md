  [1]: http://eed3si9n.com/ja/sjson-new
  [2]: http://2016.flatmap.no/
  [3]: http://event.scaladays.org/scaladays-nyc-2016
  [4]: https://vimeo.com/165837504

2ヶ月ぐらい前に [sjson-new][1] について書いた。週末にまたちょっといじってみたので、ここに報告する。
前回は Scala エコシステムにおける JSON ライブラリの家系をたどって、複数バックエンドに対応し、かつ型クラスベースの JSON コーデックライブラリという概念を導入した。課題は、カスタムコーデックを簡単に定義できるようにする必要があるということだった。

### 私家版 shapeless

4月に書いたのと先週までの間に [flatMap(Oslo) 2016][2] と [Scala Days New York 2016][3] という 2つのカンファレンスがあった。残念ながら、僕は flatMap の方には行けなかったけども、Daniel Spiewak さんの "Roll Your Own Shapeless" (「私家版 Shapeless のすゝめ」) というトークを New York で聞けた。[flatMap 版][4]の方が完全版でそれは vimeo にも出てるので、是非チェックしてみてほしい。

sbt の内部では、sbinary を用いたキャッシングに HList が用いられてたりする:

<scala>
implicit def mavenCacheToHL = (m: MavenCache) => m.name :+: m.rootFile.getAbsolutePath :+: HNil
implicit def mavenRToHL = (m: MavenRepository) => m.name :+: m.root :+: HNil
...
</scala>

そういう影響もあって、HList とか Shapeless の `LabelledGeneric` みたいなのがあれば JSON object を表す中間値としていいのではないかと思っていたので、Daniel のトークには最後に背中を押してもらった気がする。

本稿では、HList の目的を特化した LList というものを紹介する。

### LList

sjson-new には **LList** というデータ型があって、これは labelled heterogeneous list、ラベル付された多型リストだ。
標準ライブラリについてくる `List[A]` は、`A` という同じ型しか格納することができない。標準の `List[A]` と違って、LList はセルごとに異なる型の値を格納でき、またラベルも格納することができる。このため、LList はそれぞれ独自の型を持つ。REPL で見てみよう:

<scala>
scala> import sjsonnew._, LList.:+:
import sjsonnew._
import LList.$colon$plus$colon

scala> import BasicJsonProtocol._
import BasicJsonProtocol._

scala> val x = ("name", "A") :+: ("value", 1) :+: LNil
x: sjsonnew.LList.:+:[String,sjsonnew.LList.:+:[Int,sjsonnew.LNil]] = (name, A) :+: (value, 1) :+: LNil

scala> val y: String :+: Int :+: LNil = x
y: sjsonnew.LList.:+:[String,sjsonnew.LList.:+:[Int,sjsonnew.LNil]] = (name, A) :+: (value, 1) :+: LNil
</scala>

`x` の長い型の名前の中に `String` と `Int` が書かれているのが分かるだろうか。`y` の例が示すように、`String :+: Int :+: LNil` は同じ型の略記法だ。

`BasicJsonProtocol` は全ての LList の値を JSON オブジェクトに変換することができる。

### isomorphism を使ったカスタムコーデック

LList は JSON object に変換可能なので、あとはカスタムの型から LList に行ったり来たりできるようになればいいだけだ。この概念は isomorphism (同型射) と呼ばれる。

<scala>
scala> import sjsonnew._, LList.:+:
import sjsonnew._
import LList.$colon$plus$colon

scala> import BasicJsonProtocol._
import BasicJsonProtocol._

scala> case class Person(name: String, value: Int)
defined class Person

scala> implicit val personIso = LList.iso(
         { p: Person => ("name", p.name) :+: ("value", p.value) :+: LNil },
         { in: String :+: Int :+: LNil => Person(in.head, in.tail.head) })
personIso: sjsonnew.IsoLList.Aux[Person,sjsonnew.LList.:+:[String,sjsonnew.LList.:+:[Int,sjsonnew.LNil]]] = sjsonnew.IsoLList$$anon$1@4140e9d0
</scala>

上のような implicit 値を `Person` が*ある* LList と同型である「証明」として使って、sjson-new はここから `JsonFormat` を導出することができる。

<scala>
scala> import sjsonnew.support.spray.Converter
import sjsonnew.support.spray.Converter

scala> Converter.toJson[Person](Person("A", 1))
res0: scala.util.Try[spray.json.JsValue] = Success({"name":"A","value":1})
</scala>

見てのとおり、`Person("A", 1)` は `{"name":"A","value":1}` にエンコードすることができた。

### 型の直和としての ADT

sealed trait を使った代数的データ型があるとする。`JsonFormat` を合成するために、`unionFormat2`, `unionFormat3`, ... という関数を用意した。

<scala>
scala> import sjsonnew._, LList.:+:
import sjsonnew._
import LList.$colon$plus$colon

scala> import BasicJsonProtocol._
import BasicJsonProtocol._

scala> :paste
// Entering paste mode (ctrl-D to finish)

sealed trait Contact
case class Person(name: String, value: Int) extends Contact
case class Organization(name: String, value: Int) extends Contact

implicit val personIso = LList.iso(
  { p: Person => ("name", p.name) :+: ("value", p.value) :+: LNil },
  { in: String :+: Int :+: LNil => Person(in.head, in.tail.head) })
implicit val organizationIso = LList.iso(
  { o: Organization => ("name", o.name) :+: ("value", o.value) :+: LNil },
  { in: String :+: Int :+: LNil => Organization(in.head, in.tail.head) })
implicit val ContactFormat = unionFormat2[Contact, Person, Organization]

// Exiting paste mode, now interpreting.

scala> import sjsonnew.support.spray.Converter
import sjsonnew.support.spray.Converter

scala> Converter.toJson[Contact](Organization("Company", 2))
res0: scala.util.Try[spray.json.JsValue] = Success({"value":{"name":"Company","value":2},"type":"Organization"})
</scala>


`unionFormatN[U, A1, A2, ...]` 関数は、型 `U` が sealed な親 trait であることを前提としている。JSON object 中では、これは簡単な型名 (クラス名の部分だけ) を `type` というフィールドに書くことでエンコードしている。実行時クラス名を取得するのに Java リフレクションを使った。

### 低レベル API: Builder と Unbuilder

例えば JString を使ったエンコードを行いたいなど、もっと低レベルな JSON 書き出しを支援するために、sjson-new は Builder と Unbuilder というものを提供する。これは命令型スタイルの API で、より AST に近い。例えば、`IntJsonFormat` はこのように定義されている:

<scala>
implicit object IntJsonFormat extends JsonFormat[Int] {
  def write[J](x: Int, builder: Builder[J]): Unit =
    builder.writeInt(x)
  def read[J](js: J, unbuilder: Unbuilder[J]): Int =
    unbuilder.readInt(js)
}
</scala>

`Builder` はプリミティブ値を書き出すための `writeX` メソッド群を提供する。一方 `Unbuilder` は、`readX` メソッド群を提供する。

`BasicJsonProtocol` は既に `List[A]` などの標準コレクションのエンコーディングを提供するけども、独自の型を JSON array にエンコードしたいかもしれない。JSON array を書くには、`beginArray()` を呼び、`writeX` メソッド群を使って、最後に `endArray()` を呼ぶ。Builder は内部で状態を保持しているので、array を開始してないのに終了できないようになっている。

JSON object を書き出すには、上記のように LList への isomorphism を使うか、`beginObject()` を呼び、`addField("...")` と `writeX` メソッド群をペアで呼んで、最後に `endObject()` を呼ぶ。先ほど見た `Person` case class のカスタムコーデックを Builder/Unbuilder を直接使って定義するとこうなる:

<scala>
implicit object PersonFormat extends JsonFormat[Person] {
  def write[J](x: Person, builder: Builder[J]): Unit = {
    builder.beginObject()
    builder.addField("name")
    builder.writeString(x.name)
    builder.addField("value")
    builder.writeInt(x.value)
    builder.endObject()
  }
  def read[J](js: J, unbuilder: Unbuilder[J]): Person = {
    unbuilder.beginObject(js)
    val name = unbuilder.lookupField("name") match {
      case Some(x) => unbuilder.readString(x)
      case _       => deserializationError(s"Missing field: name")
    }
    val value = unbuilder.lookupField("value") match {
      case Some(x) => unbuilder.readInt(x)
      case _       => 0
    }
    unbuilder.endObject()
    Person(name, value)
  }
}
</scala>

さっきのは 3行だったけど、これは 25行になった。LList を作らない分速くはなるかもしれない。

### sjson-new 0.2.0

本稿で紹介した機能は 0.2.0 に入っている。Json4s-AST と使う場合は:

<scala>
libraryDependencies += "com.eed3si9n" %%  "sjson-new-json4s" % "0.2.0"
</scala>

Spray と使う場合は:

<scala>
libraryDependencies += "com.eed3si9n" %%  "sjson-new-spray" % "0.2.0"
</scala>

今の所マクロは一切使用してなくて、リフレクションもパターンマッチングとクラス名の取得に限られている。
