---
title:       "sjson-new and custom codecs using LList"
type:        story
date:        2016-05-24
changed:     2016-05-25
draft:       false
promote:     true
sticky:      false
url:         /sjson-new-and-custom-codecs-using-llist
aliases:     [ /node/198 ]
tags:        [ "scala" ]
---

  [1]: http://eed3si9n.com/sjson-new
  [2]: http://2016.flatmap.no/
  [3]: http://event.scaladays.org/scaladays-nyc-2016
  [4]: https://vimeo.com/165837504

Two months ago, I wrote about [sjson-new][1]. I was working on that again over the weekend, so here's the update.
In the earlier post, I've introduced the family tree of JSON libraries in Scala ecosystem, the notion of backend independent, typeclass based JSON codec library. I concluded that we need some easy way of defining a custom codec for it to be usable.

### roll your own shapeless

In between the April post and the last weekend, there were [flatMap(Oslo) 2016][2] and [Scala Days New York 2016][3]. Unfortunately I wasn't able to attend flatMap, but I was able to catch Daniel Spiewak's "Roll Your Own Shapeless" talk in New York. The full [flatMap version][4] is available on vimeo, so I recommend you check it out.

sbt internally uses HList for caching using sbinary:

```scala
implicit def mavenCacheToHL = (m: MavenCache) => m.name :*: m.rootFile.getAbsolutePath :*: HNil
implicit def mavenRToHL = (m: MavenRepository) => m.name :*: m.root :*: HNil
...
```

and I've been thinking something like an HList or Shapeless's `LabelledGeneric` would be a good intermediate datatype to represent JSON object, so Daniel's talk became the last push on my back.
In this post, I will introduce a special purpose HList called LList.

### LList

sjson-new comes with a datatype called **LList**, which stands for labelled heterogeneous list.
`List[A]` that comes with the Standard Library can only store values of one type, namely `A`. Unlike the standard `List[A]`, LList can store values of different types per cell, and it can also store a label per cell. Because of this reason, each LList has its own type. Here's how it looks in the REPL:

```scala
scala> import sjsonnew._, LList.:*:
import sjsonnew._
import LList.$colon$plus$colon

scala> import BasicJsonProtocol._
import BasicJsonProtocol._

scala> val x = ("name", "A") :*: ("value", 1) :*: LNil
x: sjsonnew.LList.:*:[String,sjsonnew.LList.:*:[Int,sjsonnew.LNil]] = (name, A) :*: (value, 1) :*: LNil

scala> val y: String :*: Int :*: LNil = x
y: sjsonnew.LList.:*:[String,sjsonnew.LList.:*:[Int,sjsonnew.LNil]] = (name, A) :*: (value, 1) :*: LNil
```

Can you find `String` and `Int` mentioned in that long type name of `x`? `String :*: Int :*: LNil` is a short form of writing that as demonstrated by `y`.

`BasicJsonProtocol` is able to convert all LList values into a JSON object.

### custom codecs as isomorphism

Because LList is able to turn itself into a JSON object, all we need now is a way to going back and forth between your custom type and an LList. This notion is called isomorphism.

```scala
scala> import sjsonnew._, LList.:*:
import sjsonnew._
import LList.$colon$plus$colon

scala> import BasicJsonProtocol._
import BasicJsonProtocol._

scala> case class Person(name: String, value: Int)
defined class Person

scala> implicit val personIso = LList.iso(
         { p: Person => ("name", p.name) :*: ("value", p.value) :*: LNil },
         { in: String :*: Int :*: LNil => Person(in.head, in.tail.head) })
personIso: sjsonnew.IsoLList.Aux[Person,sjsonnew.LList.:*:[String,sjsonnew.LList.:*:[Int,sjsonnew.LNil]]] = sjsonnew.IsoLList$$anon$1@4140e9d0
```

We can use the implicit value as a proof that `Person` is isomorphic to an LList, and sjson-new can then use that to derive a `JsonFormat`.

```scala
scala> import sjsonnew.support.spray.Converter
import sjsonnew.support.spray.Converter

scala> Converter.toJson[Person](Person("A", 1))
res0: scala.util.Try[spray.json.JsValue] = Success({"name":"A","value":1})
```

As you can see, `Person("A", 1)` was encoded as `{"name":"A","value":1}`.

### encoding ADT as union of types

Suppose now that we have an algebraic datatype represented by a sealed trait. There's a function to compose the `JsonFormat` called `unionFormat2`, `unionFormat3`, ...

```scala
scala> import sjsonnew._, LList.:*:
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
  { p: Person => ("name", p.name) :*: ("value", p.value) :*: LNil },
  { in: String :*: Int :*: LNil => Person(in.head, in.tail.head) })
implicit val organizationIso = LList.iso(
  { o: Organization => ("name", o.name) :*: ("value", o.value) :*: LNil },
  { in: String :*: Int :*: LNil => Organization(in.head, in.tail.head) })
implicit val ContactFormat = unionFormat2[Contact, Person, Organization]

// Exiting paste mode, now interpreting.

scala> import sjsonnew.support.spray.Converter
import sjsonnew.support.spray.Converter

scala> Converter.toJson[Contact](Organization("Company", 2))
res0: scala.util.Try[spray.json.JsValue] = Success({"value":{"name":"Company","value":2},"type":"Organization"})
```

The `unionFormatN[U, A1, A2, ...]` functions assume that type `U` is the sealed parent trait of the passed in types. In the JSON object this is encoded by putting the simple type name (just the class name portion) into `type` field. I am using Java reflection to retrieve the runtime class name.

### lower-level API: Builder and Unbuilder

If you want to drop down to a more lower level JSON writing, for example, to encode something as JString, sjon-new offers Builder and Unbuilder. This is a procedural style API, and it's closer to the AST. For instance, `IntJsonFormat` is defined as follows:

```scala
implicit object IntJsonFormat extends JsonFormat[Int] {
  def write[J](x: Int, builder: Builder[J]): Unit =
    builder.writeInt(x)
  def read[J](js: J, unbuilder: Unbuilder[J]): Int =
    unbuilder.readInt(js)
}
```

`Builder` provides other `writeX` methods to write primitive values. `Unbuilder` on the other hand provides `readX` methods.

`BasicJsonProtocol` already provides encoding for standard collections like `List[A]`, but you might want to encode your own type using JSON array. To write a JSON array, use `beginArray()`, `writeX` methods, and `endArray()`. The builder internally tracks the states, so it won't let you end an array if you haven't started one.

To write a JSON object, you can use the LList isomorphism as described above, or use `beginObject()`, pairs of `addField("...")` and `writeX` methods, and `endObject()`. Here's an example codec of the same case class `Person` using Builder/Unbuilder:

```scala
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
```

The other one was three lines of iso, but this is 25 lines of code. Since it doesn't create LList, it might run faster.

### sjson-new 0.4.0

The features described in this post is available in 0.2.0 and above. Here's how to use with Json4s-AST:

```scala
// To use sjson-new with Spray JSON
libraryDependencies += "com.eed3si9n" %%  "sjson-new-spray" % "0.4.0"

// To use sjson-new with Scala JSON
libraryDependencies += "com.eed3si9n" %%  "sjson-new-scalajson" % "0.4.0"

// To use sjson-new with MessagePack
libraryDependencies += "com.eed3si9n" %%  "sjson-new-msgpack" % "0.4.0"
```

Thus far, no macros are used, and the use of reflection is limited to pattern matching and retrieving class names.

### notes

- In [the earlier version](https://github.com/eed3si9n/eed3si9n.com/commit/856e48123b29a7f496eb4c867d227039e33f13be) of this post I used `:+:` as the LList cons, but Dale pointed out to me that `:+:` is used for coproduct in Shapeless, so I switched to `:*:` in 0.3.0.
- Updated code examples according to 0.4.0.
