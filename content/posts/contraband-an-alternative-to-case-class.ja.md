---
title:       "Contraband、case class の代替案"
type:        story
date:        2017-03-06
draft:       false
promote:     true
sticky:      false
url:         /ja/contraband-an-alternative-to-case-class
aliases:     [ /node/214 ]
tags:        [ "scala" ]
---

しばらく考えている疑問がいくつかある:

- データや API はどう書かれるべきだろうか?
- そのデータは Java や Scala ではどう表現されるべきか?
- そのデータは JSON などのワイヤーフォーマットにどう変換することができるか?
- そのデータをどうやってバイナリ互換性を崩さずに進化させることができるか?

### case class の限界

Scala でデータ型を表現する慣用的な方法は sealed trait と case class だが、バイナリ互換性を保ったままフィールドを追加することができない。簡単な `Greeting` という case class を例に取って、それがどのようなクラスとコンパニオンオブジェクトに展開されるか考察してみよう:

<scala>
package com.example

class Greeting(name: String) {
  override def equals(o: Any): Boolean = ???
  override def hashCode: Int = ???
  override def toString: String = ???
  def copy(name: String = name): Greeting = ???
}
object Greeting {
  def apply(name: String): Greeting = ???
  def unapply(v: Greeting): Option[String] = ???
}
</scala>

次に、`x` という新しいフィールドを追加する:

<scala>
package com.example

class Greeting(name: String, x: Int) {
  override def equals(o: Any): Boolean = ???
  override def hashCode: Int = ???
  override def toString: String = ???
  def copy(name: String = name, x: Int = x): Greeting = ???
}
object Greeting {
  def apply(name: String): Greeting = ???
  def unapply(v: Greeting): Option[(String, Int)] = ???
}
</scala>

見て分かる通り、`copy` メソッドと `unapply` メソッドはバイナリ互換性を崩す。

対策として、sbt のコードでは [UpdateOptions](https://github.com/sbt/sbt/blob/v0.13.13/ivy/src/main/scala/sbt/UpdateOptions.scala) というような擬似 case class を手書きで書いたりしている。

### Contraband

[GraphQL](http://graphql.org/) は Facebook社が開発した JSON API のためのクエリ言語だ。
その GraphQL のスキーマ言語の派生言語を作って Contraband という名前を付けた。sbt プラグインから Java と Scala 向けに擬似 case class を生成できるようになっている。これは以前は sbt-datatype と呼ばれていたもので、去年 Martin Duhem 君と僕が開発していた。

Contraband では `Greeting` の例は以下のように書ける:

<scala>
package com.example
@target(Scala)

type Greeting {
  name: String
}
</scala>

これは以下のようなコードを生成する:

<scala>
// DO NOT EDIT MANUALLY
package com.example
final class Greeting private (
  val name: Option[String]) extends Serializable {

  override def equals(o: Any): Boolean = o match {
    case x: Greeting => (this.name == x.name)
    case _ => false
  }
  override def hashCode: Int = {
    37 * (17 + name.##)
  }
  override def toString: String = {
    "Greeting(" + name + ")"
  }
  protected[this] def copy(name: Option[String] = name): Greeting = {
    new Greeting(name)
  }
  def withName(name: Option[String]): Greeting = {
    copy(name = name)
  }
  def withName(name: String): Greeting = {
    copy(name = Option(name))
  }
}
object Greeting {
  def apply(name: Option[String]): Greeting = new Greeting(name)
  def apply(name: String): Greeting = new Greeting(Option(name))
}
</scala>

`copy` の代わりに `withName("foo")` を使う。GraphQL/Contraband での `String` は、Scala の `Option[String]` に対応することにも注意してほしい。これは Protocol Buffer v3 の単一フィールドが「ゼロ個か1個」の意味を持つのと似ている。

### データの進化

データをどう進化できるかみていく。新しいフィールド `x` を追加するとこうなる。

<scala>
package com.example
@target(Scala)

type Greeting {
  name: String @since("0.0.0")
  x: Int @since("0.1.0")
}
</scala>

Contraband では `@since` を使ってフィールドにバージョン名を併記できる。

これは以下を生成する:

<scala>
// DO NOT EDIT MANUALLY
package com.example
final class Greeting private (
  val name: Option[String],
  val x: Option[Int]) extends Serializable {
  private def this(name: Option[String]) = this(name, None)
  ....

  def withX(x: Option[Int]): Greeting = {
    copy(x = x)
  }
  def withX(x: Int): Greeting = {
    copy(x = Option(x))
  }
}
object Greeting {
  def apply(name: Option[String]): Greeting = new Greeting(name, None)
  def apply(name: String): Greeting = new Greeting(Option(name), None)
  def apply(name: Option[String], x: Option[Int]): Greeting = new Greeting(name, x)
  def apply(name: String, x: Int): Greeting = new Greeting(Option(name), Option(x))
}
</scala>

簡単のため `equals`、`hashCode`、`toString`、`withName` などは上から省いた。
バージョン 0.0.0 と 0.1.0 それぞれに対応した `apply` のオーバーロードが生成されることがポイントだ。

### JSON コーデックの生成

JsonCodecPlugin をサブプロジェクトに追加することで Contraband 型に対する sjson-new の JSON コーデックが生成される。

<scala>
lazy val root = (project in file("."))
  .enablePlugins(ContrabandPlugin, JsonCodecPlugin)
  .settings(
    scalaVersion := "2.12.1",
    libraryDependencies += "com.eed3si9n" %% "sjson-new-scalajson" % "0.7.1"
  )
</scala>

[sjson-new](http://eed3si9n.com/ja/sjson-new) はコーデック・ツールキットで、一つのコーデック定義から Spray JSON の AST、SLIP-28 Scala JSON、MessagePack と複数のバックエンドをサポートすることができる。

スキーマにもういくつか項目を指定してやる:

<scala>
package com.example
@target(Scala)
@codecPackage("com.example.codec")
@codecTypeField("type")
@fullCodec("CustomJsonProtocol")

type Greeting {
  name: String @since("0.0.0")
  x: Int @since("0.1.0")
}
</scala>

ここからバックエンド独立な JSON コーデックとして使うことができる `GreetingFormat` trait が生成される。`Greeting` から JSON に変換して、また戻ってくるラウンドトリップを REPL でデモするとこうなる。

<scala>
scala> import sjsonnew.support.scalajson.unsafe.{ Converter, CompactPrinter, Parser }
import sjsonnew.support.scalajson.unsafe.{Converter, CompactPrinter, Parser}

scala> import com.example.codec.CustomJsonProtocol._
import com.example.codec.CustomJsonProtocol._

scala> import com.example.Greeting
import com.example.Greeting

scala> val g = Greeting("Bob")
g: com.example.Greeting = Greeting(Some(Bob), None)

scala> val j = Converter.toJsonUnsafe(g)
j: scala.json.ast.unsafe.JValue = JObject([Lscala.json.ast.unsafe.JField;@25667024)

scala> val s = CompactPrinter(j)
s: String = {"name":"Bob"}

scala> val x = Parser.parseUnsafe(s)
x: scala.json.ast.unsafe.JValue = JObject([Lscala.json.ast.unsafe.JField;@372115ef)

scala> val h = Converter.fromJsonUnsafe[Greeting](x)
h: com.example.Greeting = Greeting(Some(Bob), None)

scala> assert(g == h)
</scala>

今の所対象言語は Java と Scala のみだけど、Contraband は GraphQL の派生言語なので、興味がある人は既存のツールを再利用するなどして他の言語への対応も試してみることができるかもしれない。

Contraband に関する詳細は [Contraband ドキュメンテーション](http://www.scala-sbt.org/contraband/ja/)を参照してほしい。
