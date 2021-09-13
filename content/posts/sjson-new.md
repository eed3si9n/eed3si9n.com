---
title:       "sjson-new"
type:        story
date:        2016-04-04
changed:     2021-09-13
draft:       false
promote:     true
sticky:      false
url:         /sjson-new
aliases:     [ /node/194 ]
tags:        [ "scala" ]
---

  [1]: https://github.com/jonifreeman/literaljson
  [2]: https://github.com/lift/lift/commit/eca4bf99b807b05de600fe1ad454153c0b6477a5
  [3]: https://github.com/dispatch/dispatch/commit/41edb939baa5c6edb4378c1bd8e1d2f10f3350f2
  [4]: https://github.com/playframework/playframework/commit/63448578b15dcc7bf4806878c7b3aa4c74193af6
  [5]: https://github.com/playframework/playframework/commit/d292fd30dfd6534bb87f37e56577832063608205
  [pins]: https://www.artima.com/pins1ed/
  [rwh5]: http://book.realworldhaskell.org/read/writing-a-library-working-with-json-data.html
  [ghosh]: http://debasishg.blogspot.com/2010/07/sjson-now-offers-type-class-based-json.html
  [spray-json]: https://github.com/spray/spray-json
  [Argonaut]: http://argonaut.io/
  [circe]: http://circe.io
  [Jawn]: https://github.com/non/jawn
  [Rapture JSON]: http://rapture.io/mod/json
  [sjson-new]: https://github.com/eed3si9n/sjson-new

### background

One of the fun way of thinking about software projects is literary analysis. Instead of the actual source code, think of who wrote it when and why (what problem does it solve), and how it's written (what influenced it).
Within the Scala ecosystem, not too many genre are as rich as the JSON libraries.

In December 2008, the first edition of [Programming in Scala][pins] came out, which used JSON as an example in the context of parser combinator, and showed that JSON parser can be written in 10 lines of code:

<scala>
import scala.util.parsing.combinator._
class JSON extends JavaTokenParsers {
  def value : Parser[Any] = obj | arr |
                            stringLiteral |
                            floatingPointNumber |
                            "null" | "true" | "false"
  def obj   : Parser[Any] = "{"~repsep(member, ",")~"}"
  def arr   : Parser[Any] = "["~repsep(value, ",")~"]"
  def member: Parser[Any] = stringLiteral~":"~value
}
</scala>

A month earlier in 2008, the book [Real World Haskell](http://book.realworldhaskell.org/) came out, and also used JSON library as an example: [Chapter 5. Writing a library: working with JSON data][rwh5]. This explained how JSON data can be described using an algebraic data type called `JValue`:

<haskell>
data JValue = JString String
            | JNumber Double
            | JBool Bool
            | JNull
            | JObject [(String, JValue)]
            | JArray [JValue]
              deriving (Eq, Ord, Show)
</haskell>

This notion became influential to our ecosystem.

In March of 2009 Jorge Ortiz [contributed][3] `JsonParser` and `JsValue` implementation to Dispatch library that you can see the influence from both the notions.

In June of 2009 Joni Freeman started a JSON library called [literaljson][1] that encodes `JValue`s using case classes.
On Aug 11, 2009, Joni [contributed][2] his work to then the dominating web framework Lift, and came to be known as `lift-json`. This implementation later becomes Json4s.

In 2010, Debasish Ghosh wrote series of blog posts on typeclasses. One of them is titled [sjson: Now offers Type Class based JSON Serialization in Scala][ghosh], where he mentions sbinary as an influence, and implemented typeclass-based serialization for JSON. sjson provided the typeclass interface and some instances, but uses dispatch-json as the AST, which demonstrates his point that typeclass can be added on after the fact.

In 2011, Mathias (known for spray), split out JSON AST from Dispatch, typclasses from sjson, and added his own PEG parser for JSON, and created [spray-json][spray-json]. Similarly, when Play 2.0 added the [initial JSON support for Scala][4] it was initially based on Dispatch AST and sjson, but it quickly added its own AST and [typeclasses][5].

Around 2012 through 2013 is when a lot of the development happens in [Argonaut][Argonaut], purely functional JSON parser and library that's very feature-rich.

Also around 2012 through 2014 time frame, Erik Osheim wrote [Jawn][Jawn], a performant JSON parser that's backend-indepent. Jawn core is written against an abtrast interface called façade; and in addition Jawn provides support shims for various JSON ASTs.

In 2014 Jon Pretty added [Rapture JSON][Rapture JSON]. I think Jon was one of the first to recognize the value of Jawn both the performance and the backend-independent aspect of it. Rapture JSON is also backend-independent, and provides many features around manipulating JSON.

In 2015 Travis Brown forked Argonaut to make [Circe][circe], using Cats, Jawn, and Shapeless.

### sjson-new

As a favorite weekend activity for the Scala programmers, I wrote my own JSON library called [sjson-new][sjson-new].
sjson-new is a typeclass based JSON codec library, or wit for that Jawn. In other words, it aims to provide sjson-like codec facility in a backend independent way.

In terms of the codebase I based it off of spray-json, but conceptually it's close to Scala Pickling in the way it deals with data. Unlike Pickling, however, sjson-new-core is free of macros and runtime reflection beyond normal pattern matching.

Here's how to use with Json4s-AST:

<scala>
libraryDependencies += "com.eed3si9n" %%  "sjson-new-json4s" % "0.1.0"
</scala>

Here's how to use with Spray:

<scala>
libraryDependencies += "com.eed3si9n" %%  "sjson-new-spray" % "0.1.0"
</scala>

To use sjson-new, you first need to get the hold of the `Converter` object, which is at `sjsonnew.support.XYZ.Converter` where `XYZ` could be `json4s` or `spray`. Here's how it looks from the REPL:

<scala>
scala> import sjsonnew.support.spray.Converter
import sjsonnew.support.spray.Converter

scala> import sjsonnew.BasicJsonProtocol._
import sjsonnew.BasicJsonProtocol._

scala> Converter.toJson[Int](42)
res0: scala.util.Try[spray.json.JsValue] = Success(42)

scala> Converter.fromJson[Int](res0.get)
res1: scala.util.Try[Int] = Success(42)
</scala>

How is this implemented? Normally a JSON codec would take some type `A` and encode it into a `JValue`. sjson-new's takes two additional parameter to `write` method on the `JsonWriter` typeclass:

<scala>
@implicitNotFound(msg = "Cannot find JsonWriter or JsonFormat type class for ${A}")
trait JsonWriter[A] {
  def write[J](obj: A, builder: Builder[J], facade: Facade[J]): Unit
}
</scala>

`obj` is the object you want to encode. `builder` is a mutable data structure that sjson-new can append intermediate values into. Think of it as `StringBuilder` or `ListBuffer`. `facade` is the abtraction to the underlying JSON AST. The facade implementation is similar to that of Jawn, except this one also does value extraction.

I still need to work on some easy way of defining a custom codec it to be usable. Once that's done I think this would provide a bridge toward migrating from one JSON AST to another.
