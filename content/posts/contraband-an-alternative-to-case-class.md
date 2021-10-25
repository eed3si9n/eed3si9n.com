---
title:       "Contraband, an alternative to case class"
type:        story
date:        2017-03-06
draft:       false
promote:     true
sticky:      false
url:         /contraband-an-alternative-to-case-class
aliases:     [ /node/213 ]
tags:        [ "scala" ]
---

Here are a few questions I've been thinking about:

- How should I express data or API?
- How should the data be represented in Java or Scala?
- How do I convert the data into wire formats such as JSON?
- How do I evolve the data without breaking binary compatibility?

### limitation of case class

The sealed trait and case class is the idiomatic way to represent datatypes in Scala, but it's impossible to add fields in binary compatible way. Take for example a simple case class `Greeting`, and see how it would expand into a class and a companion object:

```scala
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
```

Next, add a new field `x`:

```scala
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
```

As you can see, both `copy` method and `unapply` method breaks the binary compatibility.

To workaround this, some of the sbt code handrolls pseudo case class such as [UpdateOptions](https://github.com/sbt/sbt/blob/v0.13.13/ivy/src/main/scala/sbt/UpdateOptions.scala).

### Contraband

[GraphQL](http://graphql.org/) is a query language for JSON API, developed by Facebook.
I've made a dialect of GraphQL's schema language, and called it Contraband. There's an sbt plugin that can generate pseudo-case class targeting either Java or Scala. This was previously called sbt-datatype, which Martin Duhem and I worked on last year.

In Contraband, the `Greeting` example would look like this:

```scala
package com.example
@target(Scala)

type Greeting {
  name: String
}
```

This would generate:

```scala
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
```

Instead of `copy`, you would use `withName("foo")`. Also note that GraphQL/Contraband's `String` would map to Scala's `Option[String]`. This is also similar in Protocol Buffer v3 where a singular field means zero-or-one.

### evolving the data

Let's see how we can evolve this data. Here's how we add a new field `x`.

```scala
package com.example
@target(Scala)

type Greeting {
  name: String @since("0.0.0")
  x: Int @since("0.1.0")
}
```

In Contraband, we can denote each field with a version name using `@since`.

This would generate:

```scala
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
```

I've omitted `equals`, `hashCode`, `toString`, and `withName` from above.
The point here is that overloads of `apply` is generated as of version 0.0.0 and 0.1.0.

### JSON codec generation

Adding `JsonCodecPlugin` to the subproject will generate sjson-new JSON codes for the Contraband types.

```scala
lazy val root = (project in file("."))
  .enablePlugins(ContrabandPlugin, JsonCodecPlugin)
  .settings(
    scalaVersion := "2.12.1",
    libraryDependencies += "com.eed3si9n" %% "sjson-new-scalajson" % "0.7.1"
  )
```

[sjson-new](http://eed3si9n.com/sjson-new) is a codec toolkit that lets you define a code that supports Sray JSON’s AST, SLIP-28 Scala JSON, and MessagePack as the backend.

Here are a few more things to specify in the schema:

```scala
package com.example
@target(Scala)
@codecPackage("com.example.codec")
@codecTypeField("type")
@fullCodec("CustomJsonProtocol")

type Greeting {
  name: String @since("0.0.0")
  x: Int @since("0.1.0")
}
```

This will generate `GreetingFormat` trait that can be used as backend-independent JSON codec. Here's a REPL session that demonstrates `Greeting`-to-JSON roundtrip.

```scala
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
```

For now the target language is Java and Scala only, but given that Contraband is a dialect of GraphQL, it might be able to reuse some of the tooling to cross over to other languages as well if there are interests.

More details about Contraband are available in [Contraband docs](http://www.scala-sbt.org/contraband/).
