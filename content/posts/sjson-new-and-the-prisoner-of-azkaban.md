---
title:       "sjson-new and the prisoner of Azkaban"
type:        story
date:        2016-06-06
changed:     2021-09-13
draft:       false
promote:     true
sticky:      false
url:         /sjson-new-and-the-prisoner-of-azkaban
aliases:     [ /node/200 ]
tags:        [ "scala" ]
---

  [1]: http://eed3si9n.com/sjson-new
  [2]: http://eed3si9n.com/sjson-new-and-custom-codecs-using-llist
  [3]: https://github.com/eed3si9n/sjson-new/pull/1
  [protobuf]: https://developers.google.com/protocol-buffers/docs/encoding
  [ktosopl]: https://twitter.com/ktosopl
  [sbt-jmh]: https://github.com/ktoso/sbt-jmh
  [jmhsample]: https://github.com/ktoso/sbt-jmh/tree/v0.2.6/src/sbt-test/sbt-jmh/run/src/main/scala/org/openjdk/jmh/samples
  [murmur]: https://en.wikipedia.org/wiki/MurmurHash
  [xuweik]: https://twitter.com/xuwei_k
  [msgpack]: http://msgpack.org/
  [fommil]: https://twitter.com/fommil
  [travis]: https://travis-ci.org/eed3si9n/sjson-new/builds/135470040
  [slip28]: https://github.com/scala/slip/pull/28
  [scalajson]: https://github.com/mdedetrich/scala-json-ast
  [msgpackjava]: https://github.com/msgpack/msgpack-java

This is part 3 on the topic of sjson-new. See also [part 1][1] and [part 2][2].

Within the sbt code base there are a few places where the persisted data is in the order of hundreds of megabytes that I suspect it becomes a performance bottleneck, especially on machines without an SSD drive.
Naturally, my first instinct was to start reading up on the encoding of [Google Protocol Buffers][protobuf] to implement my own custom binary format.

<!--more-->

### microbenchmark using sbt-jmh

What I should've done first, is start benchmarking. Using [@ktosopl (Konrad Malawski)][ktosopl]'s [sbt-jmh][sbt-jmh], setting up a microbenchmark is easy. All you have to do is pop that plugin into your build. and create a subproject that enables `JmhPlugin`.

<scala>
lazy val benchmark = (project in file("benchmark")).
  dependsOn(supportSpray). // add other subprojects you want to test
  enablePlugins(JmhPlugin).
  settings(
    libraryDependencies ++= Seq(jawnSpray, lm),
    // sbt-jmh forks the run, so you would need these
    javaOptions in (Jmh, run) ++= Seq("-Xmx1G", "-Dfile.encoding=UTF8"),
    publish := {},
    publishLocal := {},
    PgpKeys.publishSigned := {}
  )
</scala>

One caveat is that you need to add `javaOptions in (Jmh, run)` because sbt-jmh uses forked `run`.

Then follow [some of the examples][jmhsample]. I created mine as an abstract class following the example of Jawn.

<scala>
package sjsonnew
package benchmark

import org.openjdk.jmh.annotations._
import java.util.concurrent.TimeUnit
import sbt.librarymanagement.ModuleID
import sbt.internal.librarymanagement.impl.DependencyBuilders
import java.io.File
import sbt.io.{ IO, Using }
import sbt.io.syntax._
import scala.util.Random

@State(Scope.Benchmark)
abstract class JsonBenchmark[J](converter: SupportConverter[J]) {
  @Benchmark
  @BenchmarkMode(Array(Mode.AverageTime))
  @OutputTimeUnit(TimeUnit.MILLISECONDS)
  def moduleId1SaveToFile: Unit = {
    import LibraryManagementProtocol._
    val js = converter.toJson(BenchmarkData.moduleIds)
    saveToFile(js.get, testFile)
  }

  @Benchmark
  @BenchmarkMode(Array(Mode.AverageTime))
  @OutputTimeUnit(TimeUnit.MILLISECONDS)
  def moduleId2LoadFromFile: Unit = {
    import LibraryManagementProtocol._
    val js = loadFromFile(testFile)
    converter.fromJson[Vector[ModuleID]](js)
  }

  def saveToFile(js: J, f: File): Unit
  def loadFromFile(f: File): J
  def testFile: File
}

object BenchmarkData extends DependencyBuilders {
  lazy val moduleIds = listOfModuleIds(20000)
  def listOfModuleIds(n: Int): Vector[ModuleID] =
    (1 to n).toVector map { x =>
      "com.example" % s"foo$x" % randomVersion
    }
  private val rand = new Random(1L)
  def randomVersion: String =
    s"${rand.nextInt % 10}.${rand.nextInt % 10}.${rand.nextInt % 10}"
}

class SprayBenchmark extends JsonBenchmark[spray.json.JsValue](
  sjsonnew.support.spray.Converter) {
  import spray.json._
  lazy val testFile: File = file("target") / "test-spray.json"
  def saveToFile(js: JsValue, f: File): Unit =
    IO.write(f, CompactPrinter(js), IO.utf8)
  def loadFromFile(f: File): JsValue =
    jawn.support.spray.Parser.parseFromFile(f).get
}
</scala>

This will let me compare different JSON backends under the same condition. Of course, there are many other parameters such as the hardware and the quality of the data that affects the performance metrics, but this should give me a ballpark idea.

The benchmarks are executed as follows:

<scala>
> jmh:run -i 10 -wi 3 -f1 -t1
</scala>

This means:

- 10 iterations
- 3 warmup iterations
- 1 fork
- 1 thread

At the end, you get an output like this:

<code>
[info] Benchmark                                     Mode  Cnt   Score    Error  Units
[info] SprayBenchmark.moduleId1SaveToFile            avgt   10  26.884 ± 27.383  ms/op
[info] SprayBenchmark.moduleId2LoadFromFile          avgt   10  37.435 ± 63.106  ms/op
</code>

### custom binary format

Like I said benchmarking is where I should've started. Instead what I did was creating a new binary format that's inspired by Google Protocol Buffers and Apache Avro. See [Binary Mode][3] for the code.

Here is the binary message for `150: Int`:

<code>
01 00 00 00 AC 02
----------- -----
tag
</code>

The first four bytes represent a tag. The first byte of the tag represents the wiretype, and reset of three bytes are used for the hash of field name. `AC 02` is the ZigZag encoding of varint same as protobuf. This encoding uses fewer bytes for smaller values of integers.

Here's the binary message for `"Hello"`:

<code>
07 00 00 00 05 48 65 6C 6C 6F
----------- -- --------------
tag         len
</code>

The wiretype for String is `07`, and the content is length-delimited UTF-8 String.

Here's the binary message for `Map("a" -> 1, "b" -> 2)`:

<code>
01 96 44 87 02
----------- --
01 41 F9 E8 04
----------- --
0A 00 00 00 0C
----------- --
01 96 44 87 01 61
----------- -- --
01 41 F9 E8 01 62
----------- -- --
</code>

- The first tag `01 96 44 87` is for `a: Int`. `01` is the wiretype for `Int` and `96 44 87` is derived from the [murmurhash][murmur] of `"a"`.
- `02` is the ZigZag encoding of 1
- The second tag `01 41 F9 E8` is for `b: Int`
- `04` is the ZigZag encoding of 2
- The third tag `0A 00 00 00` is for the field name table
- `0C` is the number of bytes (12) in this table, encoded as unsigned varint
- Entry for the first tag. `01 61` is length-delimited String for `"a"`
- Entry for the second tag. `01 62` is length-delimited String for `"b"`

The idea behind this is that I wanted the binary message to retain the flexibility of JSON object where a datatype can be evolved over time by adding new fields. At the same time, carrying around the field names for each entry seems wasteful, so here I'm using a fast hashing algorithm to shrink the field names into 24 bits. This is subject to hash collisions, but that's something I could detect during encoding.

When I pushed this pull request out, [@xuwei-k (Yoshida-san)][xuweik]'s reaction was "why aren't you using MessagePack?"

### MessagePack support

After implementing my own binary format, it didn't take too long to implement [MessagePack][msgpack] support.
MessagePack packs a whole a lot more into the initial tag byte so things like `null` can be expressed in a single byte.

Note that I've used [msgpack-java][msgpackjava] as the backend, so the performance might be different from the C++ implementation of msgpack.

### gzipped Spray JSON

[@fommil (Sam Halliday)][fommil] had also told me that gzipped Spray JSON gets a better performance than binary formats. Now that we have the harness, we can compare head to head. Here's the benchmark result using [Travis CI][travis]:

<code>
[info] Benchmark                                     Mode  Cnt    Score     Error  Units
[info] BinaryBenchmark.moduleId1SaveToFile           avgt   10  152.395 ± 140.531  ms/op
[info] BinaryBenchmark.moduleId2LoadFromFile         avgt   10   82.070 ±  22.701  ms/op
[info] GzipSprayBenchmark.moduleId1SaveToFile        avgt   10   60.115 ±  60.010  ms/op
[info] GzipSprayBenchmark.moduleId2LoadFromFile      avgt   10   39.847 ±   5.957  ms/op
[info] MessagePackBenchmark.moduleId1SaveToFile      avgt   10   48.141 ±   7.782  ms/op
[info] MessagePackBenchmark.moduleId2LoadFromFile    avgt   10   90.794 ±  21.501  ms/op
[info] SprayBenchmark.moduleId1SaveToFile            avgt   10   32.879 ±   6.607  ms/op
[info] SprayBenchmark.moduleId2LoadFromFile          avgt   10   40.074 ±  14.096  ms/op
</code>

Both for saving and loading, the custom binary format is doing the worst in terms of time (234ms).
If you combine the saving and loading timing, overall plain Spray JSON using Jawn does the best (72ms), gzipped Spray JSON next (99ms), and then MessagePack (138ms).

In terms of the file size, Spray JSON is 1.4 MB, gzipped Spray JSON is 123 KB, MessgePack is 1.2 MB, and the custon binary message is 896 KB. Because the test data had a lot of repetition, it might have compressed too well, but still we get 1/10 of the file size for around 40% penalty in time. This is worth considering especially for machines that does not have SSD drives.

### Scala JSON support

One of the motivations for me to write sjson-new to begin with was providing a transition path to use [SLIP-28][slip28] Scala JSON AST.

The principal driver behind Scala JSON, Matthew de Detrich, has published a milestone for [Scala JSON AST][scalajson] under `"org.mdedetrich" %% "scala-json-ast" % "1.0.0-M1"`, so we can start trying it out. It doesn't include neither parser nor a pretty printer so I've brought Jawn facade in from Mathew's Jawn fork and a pretty printer from Spray. Without too much work, I was able to provide support for Scala JSON's "unsafe" AST.

The most tedious part is providing the `JsonFormat` for each datatype. But once that part is done, sjson-new can reuse the same protocol across different backends with no additional work. Here's [the benchmark result][travis]:

<s>
This shows that Scala JSON using Jawn (63ms) is round tripping 12% faster than Spray JSON using Jawn (72ms). Similar trend continues for gzipped Scala JSON using Jawn (90ms) and gzipped Spray JSON using Jawn (99ms). The performance boost is likely coming from the use of `Array` in the "unsafe" AST compared to `Vector` in Spray JSON.
</s>

**Edit**: The above result was likely because of my bug. More recent result looks like this:

<code>
[info] Benchmark                                     Mode  Cnt   Score   Error  Units
[info] GzipScalaJsonBenchmark.moduleId1SaveToFile    avgt   10  43.528 ± 4.601  ms/op
[info] GzipScalaJsonBenchmark.moduleId2LoadFromFile  avgt   10  43.678 ± 2.873  ms/op
[info] GzipSprayBenchmark.moduleId1SaveToFile        avgt   10  42.768 ± 2.806  ms/op
[info] GzipSprayBenchmark.moduleId2LoadFromFile      avgt   10  35.995 ± 2.718  ms/op
[info] MessagePackBenchmark.moduleId1SaveToFile      avgt   10  48.509 ± 6.870  ms/op
[info] MessagePackBenchmark.moduleId2LoadFromFile    avgt   10  71.310 ± 6.126  ms/op
[info] ScalaJsonBenchmark.moduleId1SaveToFile        avgt   10  31.169 ± 4.301  ms/op
[info] ScalaJsonBenchmark.moduleId2LoadFromFile      avgt   10  40.558 ± 2.958  ms/op
[info] SprayBenchmark.moduleId1SaveToFile            avgt   10  34.160 ± 3.802  ms/op
[info] SprayBenchmark.moduleId2LoadFromFile          avgt   10  31.524 ± 3.403  ms/op
</code>

This shows that Scala JSON using Jawn (71ms) is round tripping 9% slower than Spray JSON using Jawn (65ms). Similar trend continues for gzipped Scala JSON using Jawn (86ms) and gzipped Spray JSON using Jawn (77ms).

The file sizes are identical, which should be no surprise since they are both based on the Spray JSON's compact printer.

### emulating JNothing

There's still something we can learn from the binary protocols like Protocol Buffers:

> For any non-repeated fields in proto3, or `optional` fields in proto2, the encoded message may or may not have a key-value pair with that tag number.
>
> In proto3, repeated fields are packed by default. These function like repeated fields, but are encoded differently. A packed repeated field containing zero elements does not appear in the encoded message.

These techniques can be applied to JSON format as well. There are a lot of datatypes that has `Option[A]` fields, or some collection fields that default to `None` or empty value. Not including those empty fields into JSON object has several benefits.

First, this should allow some evolution of the schema because the reading side becomes more permissive. When JSON is missing a field, it will now fill in some default value. Second, this will make the size of JSON object smaller since we won't need to include field names for them.

Lift JSON/Json4s has a notion called `JNothing` that expresses a lack of value, but I think the modern thinking is to use `Option[J]` instead. This means changing `JsonReader` so it accepts `Option[J]` instead of `J`. Here's the modified `JsonFormat` for `Int`:

<scala>
  implicit object IntJsonFormat extends JsonFormat[Int] {
    def write[J](x: Int, builder: Builder[J]): Unit =
      builder.writeInt(x)
    def read[J](jsOpt: Option[J], unbuilder: Unbuilder[J]): Int =
      jsOpt match {
        case Some(js) => unbuilder.readInt(js)
        case None     => 0
      }
  }
</scala>

This covers the reading part. Next I added `def addField[J](name: String, obj: A, builder: Builder[J]): Unit` method to the `JsonWriter`. This allows the format to optionally omit the creation of a JSON field. Let's try using this:

<scala>
scala> import sjsonnew._, BasicJsonProtocol._
import sjsonnew._
import BasicJsonProtocol._

scala> case class Person(name: String, opt: Option[Int])
defined class Person

scala> :paste
// Entering paste mode (ctrl-D to finish)

implicit object PersonFormat extends JsonFormat[Person] {
  def write[J](x: Person, builder: Builder[J]): Unit = {
    builder.beginObject()
    builder.addField("name", x.name)
    builder.addField("value", x.opt)
    builder.endObject()
  }
  def read[J](jsOpt: Option[J], unbuilder: Unbuilder[J]): Person =
    jsOpt match {
      case Some(js) =>
        unbuilder.beginObject(js)
        val name = unbuilder.readField[String]("name")
        val opt = unbuilder.readField[Option[Int]]("opt")
        unbuilder.endObject()
        Person(name, opt)
      case None =>
        deserializationError("Expected JsObject but found None")
    }
}

// Exiting paste mode, now interpreting.

defined object PersonFormat

scala> import sjsonnew.support.scalajson.unsafe.{ Converter, CompactPrinter }
import sjsonnew.support.scalajson.unsafe.{Converter, CompactPrinter}

scala> Converter.toJson(Person("Bob", None))
res1: scala.util.Try[scala.json.ast.unsafe.JValue] = Success(JObject([Lscala.json.ast.unsafe.JField;@7cb6ea15))

scala> CompactPrinter(res1.get)
res2: String = {"name":"Bob"}

scala> Converter.fromJson[Person](res1.get)
res3: scala.util.Try[Person] = Success(Person(Bob,None))
</scala>

As you can see, the JSON representation for `Person("Bob", None)` does not include the field for `None` value.

### sjson-new 0.4.0

Since gzipping is faster, smaller, and likely more reliable than rolling out my own binary format, I've decided to not include that into 0.4.0. If you want to try the feature described in this post other than that, here's 0.4.0:

<scala>
// To use sjson-new with Spray JSON
libraryDependencies += "com.eed3si9n" %%  "sjson-new-spray" % "0.4.0"

// To use sjson-new with Scala JSON
libraryDependencies += "com.eed3si9n" %%  "sjson-new-scalajson" % "0.4.0"

// To use sjson-new with MessagePack
libraryDependencies += "com.eed3si9n" %%  "sjson-new-msgpack" % "0.4.0"
</scala>
