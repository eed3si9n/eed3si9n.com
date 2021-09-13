---
title:       "型クラスによる XML データバインディング"
type:        story
date:        2010-12-07
draft:       false
promote:     true
sticky:      false
url:         /ja/typeclass-based-xml-data-binding
tags:        [ "scala", "scalaxb" ]
---

結局の所，scalaxb のユーザはエンティティ・オブジェクトが表現する現実の問題に興味があるのであって，それがどう XML に永続化されるかといったことではない．だから，いつかデータバインディングの実装をシングルトン/コンパニオン・オブジェクトから追い出さなければいけないことは分かっていた．つい最近までデータバインディングの実装は以下のように生成されていた:

<scala>
object Address extends rt.ElemNameParser[Address] {
  val targetNamespace = "http://www.example.com/IPO"

  def parser(node: scala.xml.Node): Parser[Address] =
    ...

  def toXML(__obj: Address, __namespace: String, __elementLabel: String, __scope: scala.xml.NamespaceBinding): scala.xml.NodeSeq =
    ...
}
</scala>

つまり，scalaxb は `Address` そのものとは関係の無い XML データバインディングのために一等地をハイジャックしてしまったのだ．

### adapter
まず最初に以下のような adapter オブジェクトに追い出すことを考えた:

<scala>
object DefaultXMLAdapter {
  object AddressAdapter extends rt.ElemNameParser[Address] {
    val targetNamespace = "http://www.example.com/IPO"

    def parser(node: scala.xml.Node): Parser[Address] =
      ...

    def toXML(__obj: Address, __namespace: String, __elementLabel: String, __scope: scala.xml.NamespaceBinding): scala.xml.NodeSeq =
      ...
  }
}</scala>

この方法にはいくつかの問題がある．まず，scalaxb のランタイムである `DataRecord` が，今まではコンパニオン・オブジェクトの暗黙性を使ってたどっていた `toXML` にたどり着けないということだ．コンパニオン・オブジェクトの興味深い一面として「コンパイラは，暗黙 (implicit) の定義を変換元の型と変換先の型のコンパニオン・オブジェクトにも探しにいく」(Programming in Scala, p. 441) というものがある．

第二の問題は，アイデンティティー問題だ．ユーザのコードの邪魔にならないようにしようとしているのに，`Address` オブジェクトのためには `DefeaultXMLAdapter.AddressAdapter`，`Item` のためには `DefeaultXMLAdapter.ItemAdapter`などと，　かえって目に障るものを導入してしまった．ユーザが知っている必要があるのは `Address` が XML に変換できるという事実だけあって，それがどう行われているかというのは余計な詳細でしかない．

第三の問題として，拡張性の問題がある．例えば，`Address` を定義する `ipo.xsd` と，`Address` を使う `purchaseReport`要素を定義する `report.xsd` の二つのスキーマがあるとする．問題は，`report.DefaultXMLAdapter.PurchaseReportAdapter` は `ipo.DefaultXMLAdapter.AddressAdapter` を参照するため，`ipo.DefaultXMLAdapter` を拡張してカスタムのデータバインディングをすることができないということだ．

### 型クラス
abstract factory パターンなど，他にも回避方法があるのかもしれないが，David MacIver 氏 (@DRMacIver), Debasish Ghosh 氏 (@debasishg), Jason Zaugg 氏 (@retronym) のような人々の活動のお陰で，より良い方法を見つけることができた．

データバインディングとシリアライゼーション(直列化)にはちょっとしたニュアンスの違いがあるが，両方とも [expression problem](http://www.daimi.au.dk/~madst/tool/papers/expression.txt) という問題の例だ:
> 既にあるデータ型に対して再コンパイル無しで，静的型安全性を保ったまま，型に新たなケースを追加したり型に対する関数を追加できるかという問題だ．

Haskell の型クラスと呼ばれる機構はこの expression problem をエレガントに解決することができる．[Real World Haskell](http://book.realworldhaskell.org/read/using-typeclasses.html): 
> 型クラスは，データ型によって異なる実装を持つことができる関数のセットを定義する．

確かに，一見大したことないように見えるかもしれない．データ型を行として，関数のセット (型クラス) を列とする表があるとする:
<table border=1>
  <tr><th></th><th> def readsXML(node: NodeSeq): A </th><th> def doSomethingCrazy(obj: A) </th></tr>
  <tr><td>Address</td><td>○</td><td></td></tr>
  <tr><td>PurchaseOrderReport</td><td>○</td><td>○</td></tr>
  <tr><td>Shape</td><td></td><td>○</td></tr>
  <tr><td>Int</td><td>○</td><td></td></tr>
</table>

表で ○ が付いている所は，データ型に対する型クラスのインスタンスが実装されていると思ってほしい．もしこの機構が Scala にあれば，任意の無関係なクラスに対してはたらく関数のセットを追加できるということになる．ここでは継承や trait mix-in は使われていないため，`Int` のような組み込み型にも同様に動作することに注意してほしい．型クラスの Scala での実装の詳細は Debasish氏の型クラス三部作を参照してほしい:

- [Scala Implicits: 型クラス襲来](http://eed3si9n.com/ja/scala-implicits-type-classes) ([原文](http://debasishg.blogspot.com/2010/06/scala-implicits-type-classes-here-i.html))
- [Scala 型クラスへのリファクタリング](http://eed3si9n.com/ja/refactoring-into-scala-type-classes) ([原文](http://debasishg.blogspot.com/2010/07/refactoring-into-scala-type-classes.html))
- [sjson: Scala の型クラスによる JSON シリアライゼーション](http://eed3si9n.com/ja/sjson-type-class-based-json) ([原文](http://debasishg.blogspot.com/2010/07/sjson-now-offers-type-class-based-json.html))

### 型クラスによる XML データバインディング
scalaxb は二つの型クラスを定義する:

<scala>
trait CanReadXML[A] {
  def reads(seq: scala.xml.NodeSeq): Either[String, A]
}

trait CanWriteXML[A] {
  def writes(obj: A, namespace: Option[String], elementLabel: Option[String],
      scope: NamespaceBinding, typeAttribute: Boolean): NodeSeq
}

trait XMLFormat[A] extends CanWriteXML[A] with CanReadXML[A]
</scala>

型クラスの名前をつけるのに，Scala 2.8 コレクションの `CanBuildFrom` の慣例にならった．
メソッドを `def apply` と名付けるのは混乱の元だと思ったので，[sbinary](http://code.google.com/p/sbinary/wiki/IntroductionToSBinary)　の `def reads` と `def writes` の慣例にならった．

このような名前は型クラスが XML の読み書きの能力を示すものであることを，少しは分り易くすると思う．直接人間が食用することには適してないこともなんとなく気づいてほしい．直接呼び出すのではなく，以下のように，`scalaxb.Scalaxb` モジュールに定義された関数を通して呼んでほしい:

<scala>
import scalaxb._
import Scalaxb._
import ipo._
import DefaultXMLProtocol._

val subject = <shipTo xmlns="http://www.example.com/IPO">
  <name>Foo</name>
  <street>1537 Paper Street</street>
  <city>Wilmington</city>
</shipTo>

val shipTo = fromXML[Address](subject)
val document = toXML[Address](shipTo.copy(name = "Bar"), "foo", defaultScope)
</scala>

ここで，`scalaxb.Scalaxb` モジュールの `fromXML` と `toXML` を見てみよう:

<scala>
object Scalaxb {
  def fromXML[A](seq: NodeSeq)(implicit format: XMLFormat[A]): A =
    format.reads(seq) match {
      case Right(a) => a
      case Left(a) => error(a)
    }

  def toXML[A](obj: A, namespace: Option[String],
      elementLabel: Option[String],
      scope: scala.xml.NamespaceBinding,
      typeAttribute: Boolean = false)(implicit format: CanWriteXML[A]): scala.xml.NodeSeq =
    format.writes(obj, namespace, elementLabel, scope, typeAttribute)
  def toXML[A](obj: A, elementLabel: String,
      scope: scala.xml.NamespaceBinding)(implicit format: CanWriteXML[A]): scala.xml.NodeSeq =
    toXML(obj, None, Some(elementLabel), scope, false)
}
</scala>

`fromXML` の肝は暗黙 (implicit) のパラメータである `format` だ．Scala コンパイラは，呼び出し場所 (call site) の直近の構文スコープから `XMLFormat` の型クラスインスタンスを探し出す．同様に，`toXML` は `CanWriteXML` の型クラスインスタンスをローカルスコープ内に必要とする．どのようにして暗黙の値 (implicit value) をローカルスコープに載せるのだろう？ `import` 文を呼び出し，暗黙の値が一つの識別子で参照できるようにするだけだ．上記の使用例のコードだと，`import DefaultXMLProtocol._` がそれにあたる．

scalaxb は case class と，それらの case class と XML を変換し，逆変換できる型クラスのインスタンスを生成する．
`Address` を拡張して，もう一つの複合型の `USAddress` を定義しよう:

    <xs:schema targetNamespace="http://www.example.com/IPO"
            xmlns="http://www.example.com/IPO"
            xmlns:xs="http://www.w3.org/2001/XMLSchema"
            xmlns:ipo="http://www.example.com/IPO">
      <xs:complexType name="Address">
        <xs:sequence>
          <xs:element name="name"   type="xs:string"/>
          <xs:element name="street" type="xs:string"/>
          <xs:element name="city"   type="xs:string"/>
        </xs:sequence>
      </xs:complexType>

      <xs:complexType name="USAddress">
        <xs:complexContent>
          <xs:extension base="ipo:Address">
            <xs:sequence>
              <xs:element name="state" type="xs:string"/>
              <xs:element name="zip"   type="xs:positiveInteger"/>
            </xs:sequence>
          </xs:extension>
        </xs:complexContent>
      </xs:complexType>
    </xs:schema>

scalaxb を `-p ipo` オプションを付けて呼ぶと，三つの Scala ソースが生成される．最初は usaddress.scala だ:

<scala>
// Generated by <a href="http://scalaxb.org/">scalaxb</a>.
package ipo

trait Addressable {
  val name: String
  val street: String
  val city: String
}


case class Address(name: String,
  street: String,
  city: String) extends Addressable


case class USAddress(name: String,
  street: String,
  city: String,
  state: String,
  zip: Int) extends Addressable
</scala>

見ての通り，XML 関連のロジックは一切無い．
次に，XML 変換のための，`XMLProtocol` という trait にラップされた型クラスコントラクトと，型クラスインスタンスが定義された `xmlprotocol.scala` が生成される．

<scala>
// Generated by <a href="http://scalaxb.org/">scalaxb</a>.
package ipo
    
/**
usage:
import scalaxb._
import Scalaxb._
import ipo._
import DefaultXMLProtocol._

val obj = fromXML[Foo](node)
val document = toXML[Foo](obj, "foo", defaultScope)
**/
trait XMLProtocol extends scalaxb.XMLStandardTypes {
  implicit lazy val IpoAddressableFormat: scalaxb.XMLFormat[ipo.Addressable] = 
    buildIpoAddressableFormat
  def buildIpoAddressableFormat: scalaxb.XMLFormat[ipo.Addressable]

  implicit lazy val IpoAddressFormat: scalaxb.XMLFormat[ipo.Address] = 
    buildIpoAddressFormat
  def buildIpoAddressFormat: scalaxb.XMLFormat[ipo.Address]

  implicit lazy val IpoUSAddressFormat: scalaxb.XMLFormat[ipo.USAddress] = 
    buildIpoUSAddressFormat
  def buildIpoUSAddressFormat: scalaxb.XMLFormat[ipo.USAddress]

  
}

object DefaultXMLProtocol extends DefaultXMLProtocol with scalaxb.DefaultXMLStandardTypes {
  import scalaxb.Scalaxb._
  val defaultScope = toScope(None -> "http://www.example.com/IPO",
    Some("ipo") -> "http://www.example.com/IPO",
    Some("xsi") -> "http://www.w3.org/2001/XMLSchema-instance")  
}

trait DefaultXMLProtocol extends XMLProtocol {
  import scalaxb.Scalaxb._

  override def buildIpoAddressableFormat = new DefaultIpoAddressableFormat {}
  trait DefaultIpoAddressableFormat extends scalaxb.XMLFormat[ipo.Addressable] {
    val targetNamespace: Option[String] = Some("http://www.example.com/IPO")
    def reads(seq: scala.xml.NodeSeq): Either[String, ipo.Addressable] = seq match {
      case node: scala.xml.Node =>     
        scalaxb.Helper.instanceType(node) match {
          case (targetNamespace, Some("USAddress")) => Right(fromXML[ipo.USAddress](node))
          case _ => Right(fromXML[ipo.Address](node))
        }
      case _ => Left("reads failed: seq must be scala.xml.Node")  
    }
    
    def writes(__obj: ipo.Addressable, __namespace: Option[String],
        __elementLabel: Option[String], __scope: scala.xml.NamespaceBinding,
        __typeAttribute: Boolean): scala.xml.NodeSeq = __obj match {
      case x: ipo.USAddress => toXML[ipo.USAddress](x, __namespace, __elementLabel, __scope, true)
      case x: ipo.Address => toXML[ipo.Address](x, __namespace, __elementLabel, __scope, false)
    }
  }

  override def buildIpoAddressFormat = new DefaultIpoAddressFormat {}
  trait DefaultIpoAddressFormat extends scalaxb.ElemNameParser[ipo.Address] {
    val targetNamespace: Option[String] = Some("http://www.example.com/IPO")
    
    override def typeName: Option[String] = Some("Address")

    def parser(node: scala.xml.Node): Parser[ipo.Address] =
      (scalaxb.ElemName(targetNamespace, "name")) ~ 
      (scalaxb.ElemName(targetNamespace, "street")) ~ 
      (scalaxb.ElemName(targetNamespace, "city")) ^^
      { case p1 ~ p2 ~ p3 =>
      ipo.Address(fromXML[String](p1),
        fromXML[String](p2),
        fromXML[String](p3)) }
    
    def writesChildNodes(__obj: ipo.Address,
        __scope: scala.xml.NamespaceBinding): Seq[scala.xml.Node] =
      Seq.concat(toXML[String](__obj.name, None, Some("name"), __scope, false),
        toXML[String](__obj.street, None, Some("street"), __scope, false),
        toXML[String](__obj.city, None, Some("city"), __scope, false))

  }

  override def buildIpoUSAddressFormat = new DefaultIpoUSAddressFormat {}
  trait DefaultIpoUSAddressFormat extends scalaxb.ElemNameParser[ipo.USAddress] {
    val targetNamespace: Option[String] = Some("http://www.example.com/IPO")
    
    override def typeName: Option[String] = Some("USAddress")

    def parser(node: scala.xml.Node): Parser[ipo.USAddress] =
      (scalaxb.ElemName(targetNamespace, "name")) ~ 
      (scalaxb.ElemName(targetNamespace, "street")) ~ 
      (scalaxb.ElemName(targetNamespace, "city")) ~ 
      (scalaxb.ElemName(targetNamespace, "state")) ~ 
      (scalaxb.ElemName(targetNamespace, "zip")) ^^
      { case p1 ~ p2 ~ p3 ~ p4 ~ p5 =>
      ipo.USAddress(fromXML[String](p1),
        fromXML[String](p2),
        fromXML[String](p3),
        fromXML[String](p4),
        fromXML[Int](p5)) }
    
    def writesChildNodes(__obj: ipo.USAddress,
        __scope: scala.xml.NamespaceBinding): Seq[scala.xml.Node] =
      Seq.concat(toXML[String](__obj.name, None, Some("name"), __scope, false),
        toXML[String](__obj.street, None, Some("street"), __scope, false),
        toXML[String](__obj.city, None, Some("city"), __scope, false),
        toXML[String](__obj.state, None, Some("state"), __scope, false),
        toXML[Int](__obj.zip, None, Some("zip"), __scope, false))

  }


}
</scala>

最後に，scalaxb は `scalaxb.Scalaxb' モジュールや他の補助クラスを定義する `scalaxb.scala` を生成する．

型クラスは adapter パターンのアイデンティティー問題を解決するだけでなく，XML データバインディングをカスタマイズするための拡張ポイントを提供し，拡張問題も解決することができた．暗黙のパラメータに基づいているため，`DataRecord` もコンパニオン・オブジェクトのツテに頼らずに型クラスインスタンスを利用できる．

生成されたコードのユーザの側から見ると，case class の他に知る必要があるのは `fromXML` と `toXML` だけだ:

<scala>
import scalaxb._
import Scalaxb._
import ipo._
import DefaultXMLProtocol._

val subject = <shipTo xmlns="http://www.example.com/IPO">
  <name>Foo</name>
  <street>1537 Paper Street</street>
  <city>Wilmington</city>
</shipTo>

val shipTo = fromXML[Address](subject)
val document = toXML[Address](shipTo.copy(name = "Bar"), "foo", defaultScope)
</scala>
