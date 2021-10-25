---
title:       "typeclass-based XML data binding"
type:        story
date:        2010-12-07
draft:       false
promote:     true
sticky:      false
url:         /typeclass-based-xml-data-binding
tags:        [ "scala", "scalaxb" ]
---

Ultimately, the users of scalaxb are interested the real problems that the entity objects express, not how they persist into XML. That's why I knew I eventually had to vacate the singleton/companion object of the case class to implement the data binding. Until recently it has been generating the data binding implementation as follows:

```scala
object Address extends rt.ElemNameParser[Address] {
  val targetNamespace = "http://www.example.com/IPO"
 
  def parser(node: scala.xml.Node): Parser[Address] =
    ...
 
  def toXML(__obj: Address, __namespace: String, __elementLabel: String, __scope: scala.xml.NamespaceBinding): scala.xml.NodeSeq =
    ...
}
```

Now scalaxb has hijacked the prime real estate for the purpose of XML data binding, which has little to with `Address`.

### adapter
The first thing I thought was to move them into another adapter object, which I imagined it to be something like this:

```scala
object DefaultXMLAdapter {
  object AddressAdapter extends rt.ElemNameParser[Address] {
    val targetNamespace = "http://www.example.com/IPO"
 
    def parser(node: scala.xml.Node): Parser[Address] =
      ...
 
    def toXML(__obj: Address, __namespace: String, __elementLabel: String, __scope: scala.xml.NamespaceBinding): scala.xml.NodeSeq =
      ...
  }
}
```

There are several issues with this approach. One of problems is that scalaxb's runtime `DataRecord` can no longer get to `toXML`, which was relying on implicitness of the companion object. An interesting aspect of the companion object is that the "the compiler will also look for implicit definitions in the companion object of the source or expected target types of the conversion." (Programming in Scala, p. 441)

Second issue is the identity problem. I am trying to get out of the user's way of coding, and now I end up introducing `DefeaultXMLAdapter.AddressAdapter` for data binding `Address` object, `DefeaultXMLAdapter.ItemAdapter` for `Item`, and so on, which is in their face. All the user has to know is that they can get from `Address` to XML, not the unnecessary details.

Third issue is the extensibility problem. Suppose I had two schemas `ipo.xsd` that defines `Address` and `report.xsd` that defines `purchaseReport` element that uses `Address` within it. The problem is now `report.DefaultXMLAdapter.PurchaseReportAdapter` references `ipo.DefaultXMLAdapter.AddressAdapter.` This means I will not be able to extend `ipo.DefaultXMLAdapter` to do some custom data binding.

### typeclass
There are probably workarounds like using abstract factory pattern to deal with the above problems, but I found a better approach thanks to works of people like David MacIver (@DRMacIver), Debasish Ghosh (@debasishg), Jason Zaugg (@retronym), etc.

Although there are slight difference in nuance between data binding and serialization, they both exemplify a problem known as [expression problem](http://www.daimi.au.dk/~madst/tool/papers/expression.txt):
> The goal is to define a datatype by cases, where one can add new cases to the 
> datatype and new functions over the datatype, without recompiling existing code,
> and while retaining static type safety (e.g., no casts).

A mechanism in Haskell known as typeclass solves the expression problem elegantly.
[Real World Haskell](http://book.realworldhaskell.org/read/using-typeclasses.html): 
> Typeclasses define a set of functions that can have different implementations depending on the type of data they are given.

I know. It doesn't sound all that impressive. Think of a table with data types as rows, and set of functions (typeclasses) as columns:
<table border=1>
  <tr><th></th><th> def readsXML(node: NodeSeq): A </th><th> def doSomethingCrazy(obj: A) </th></tr>
  <tr><td>Address</td><td>yes</td><td></td></tr>
  <tr><td>PurchaseOrderReport</td><td>yes</td><td>yes</td></tr>
  <tr><td>Shape</td><td></td><td>yes</td></tr>
  <tr><td>Int</td><td>yes</td><td></td></tr>
</table>

Where it's marked `yes` in the table, pretend that a *typeclass instance* is implemented for the data type. If I had this mechanism in Scala, I could add a set of functions over arbitrary and unrelated classes. Notice there is no inheritance or trait mix-ins involved here, so it works equally well for built-in types like `Int`. See Debasish's typeclass trilogy for more details on how to implement typeclasses in Scala:

- [Scala Implicits : Type Classes Here I Come](http://debasishg.blogspot.com/2010/06/scala-implicits-type-classes-here-i.html)
- [Refactoring into Scala Type Classes](http://debasishg.blogspot.com/2010/07/refactoring-into-scala-type-classes.html)
- [sjson: Now offers Type Class based JSON Serialization in Scala](http://debasishg.blogspot.com/2010/07/sjson-now-offers-type-class-based-json.html)

### typeclass-based XML data binding
scalaxb defines two typeclasses:
```scala
trait CanReadXML[A] {
  def reads(seq: scala.xml.NodeSeq): Either[String, A]
}

trait CanWriteXML[A] {
  def writes(obj: A, namespace: Option[String], elementLabel: Option[String],
      scope: NamespaceBinding, typeAttribute: Boolean): NodeSeq
}

trait XMLFormat[A] extends CanWriteXML[A] with CanReadXML[A]
```

I adopted the Scala 2.8 collection's `CanBuildFrom` naming convention to name the typeclasses.
Naming the methods to be `def apply` is confusing in my opinion, so I adopted [sbinary](http://code.google.com/p/sbinary/wiki/IntroductionToSBinary)'s `def reads` and `def writes` convention.

The names make it clearer that these typeclasses indicate the ability to read or write XML. Hopefully people would also sense that they are not intended for human consumption. Instead of directly calling them, you are expected to call the functions defined in `scalaxb.Scalaxb` module as follows:

```scala
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
```

Let's look into the definitions of `fromXML` and `toXML` in `scalaxb.Scalaxb` module:

```scala
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
```

The key part in `fromXML` is the implicit parameter `format`. Scala compiler will pick up a typeclass instance of `XMLFormat` from the enclosing lexical scope of the call site. Similarly, `toXML` requires a typeclass instance of `CanWriteXML` in the local scope. How would you load the implicit values on the local scope? All you have to do is call `import` so a single identifier can address the implicit value. In the above usage code, ```scala
import DefaultXMLProtocol._``` is where this happens.

scalaxb now generates the case classes and typeclass instances, which enables the case classes to convert to and from XML. Let's add another complex type called `USAddress`, which extends `Address`:

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

Running scalaxb with `-p ipo` option, it generates three Scala sources. The first is usaddress.scala:

```scala
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
```
  
As you can see the above is free of XML-related logic.
Next, it generates `xmlprotocol.scala`, which defines the typeclass contracts wrapped up in a  trait called `XMLProtocol` and typeclass instances to convert XML into case classes.

```scala
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
```

Finally, scalaxb generates `scalaxb.scala`, which defines `scalaxb.Scalaxb` module and other helper classes.

Not only the typeclasses solves identity problem of the adapter, it also solves the extensibility problem by providing extension points if one wishes to customize XML data binding. Since it is based on implicit parameters, `DataRecord` can get to the typeclass instances without going through the companion object hoops.

As a user of the generated code, all you have to know is `fromXML` and `toXML` besides the case classes:

```scala
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
```
