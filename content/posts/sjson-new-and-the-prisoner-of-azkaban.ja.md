---
title:       "sjson-new とアズカバンの囚人"
type:        story
date:        2016-06-06
changed:     2021-09-13
draft:       false
promote:     true
sticky:      false
url:         /ja/sjson-new-and-the-prisoner-of-azkaban
aliases:     [ /node/201 ]
tags:        [ "scala" ]
---

  [1]: http://eed3si9n.com/ja/sjson-new
  [2]: http://eed3si9n.com/ja/sjson-new-and-custom-codecs-using-llist
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

本稿は sjson-new に関する第3部だ。[パート1][1]、[パート2][2]も是非読んでみてほしい。

sbt のコード内にはデータ永続化が数百メガバイトのオーダーに達している部分がいくつかあって、特にマシンに SSD が積まれていない場合は性能ボトルネックになる疑いがあるんじゃないかと思っている。
当然、最初に飛びついたのは [Google Protocol Buffers][protobuf] のエンコーディングを参考に独自のバイナリフォーマットを実装することだった。

### sbt-jmh を用いたマイクロベンチマーク

僕がまずやるべきだったのは、ベンチマークを取ることだ。[@ktosopl (Konrad Malawski)][ktosopl]君の [sbt-jmh][sbt-jmh] を使うとマイクロベンチマークは簡単に作ることができる。ビルドにプラグインを入れて、`JmhPlugin` を有効化したサブプロジェクトを定義するだけだ。

```scala
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
```

一つ注意が必要なのは sbt-jmh はフォークした `run` を使っているので、`javaOptions in (Jmh, run)` の設定が必要なことだ。

あとは[例][jmhsample]にならってベンチマークを定義していくだけだ。僕は Jawn の真似をして abstract class にしてみた。

```scala
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
```

これで同条件下で JSON バックエンドを比較できるようになった。当然、ハードウェアやデータの質など性能の絶対値を左右するパラメータは大量にあるんだけども、大雑把な比較はできるはずだ。

ベンチマークは以下のように実行する:

```scala
> jmh:run -i 10 -wi 3 -f1 -t1
```

これは、

- 10 iterations (反復)
- 3 warmup iterations (ウォームアップ)
- 1 fork (フォーク)
- 1 thread (スレッド)

という意味だ。実行し終わると、以下のように結果が表示される:

```bash
[info] Benchmark                                     Mode  Cnt   Score    Error  Units
[info] SprayBenchmark.moduleId1SaveToFile            avgt   10  26.884 ± 27.383  ms/op
[info] SprayBenchmark.moduleId2LoadFromFile          avgt   10  37.435 ± 63.106  ms/op
```

### 独自バイナリフォーマット

先ほど言った通り、僕が初めに*するべき*だったのはベンチマークなんだけども、僕が実際にやったことは Google Protocol Buffers と Apache Avro にインスパイヤされた新しいバイナリフォーマットを作ることだった。コードは [Binary Mode][3] を参照。

具体例で説明すると、`150: Int` のバイナリメッセージはこうなる:

```bash
01 00 00 00 AC 02
----------- -----
tag
```

最初の4バイトはタグを表す。タグの最初のバイトはワイヤタイプを表し、残りの 3バイトはフィールド名のハッシュに使われる。`AC 02` は protobuf 同様に 150 を ZigZag encoding の varint で表したものだ。これは、整数の値が小さければ少ないバイト数で表現できるという特徴がある。

`"Hello"` のバイナリメッセージはこうなっている:

```bash
07 00 00 00 05 48 65 6C 6C 6F
----------- -- --------------
tag         len
```

String のワイヤタイプは `07` で、次が文字のバイト数、UTF-8 で表現された String というふうになっている。

`Map("a" -> 1, "b" -> 2)` のバイナリメッセージはこうなっている:

```bash
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
```

- `01 96 44 87` は `a: Int` のタグだ。`01` は `Int` のワイヤタイプで、`96 44 87` は `"a"` の [murmurhash][murmur] から導出される。
- `02` は 1 の ZigZag エンコーディング。
- `01 41 F9 E8` は `b: Int` のタグ。
- `04` は 2 の ZigZag エンコーディング。
- 3つ目のタグ `0A 00 00 00` はフィールド名テーブルのワイヤタイプを表す。
- `0C` はこのテーブルのバイト数 (12) を unsigned varint でエンコードしたもの。
- 最初のタグのエントリー。`01 61` は `"a"` をバイト数を最初につけた String でエンコードしたもの。
- 2つ目のタグのエントリー。`01 62` は `"b"` をバイト数を最初につけた String でエンコードしたもの。

大まかな方針としては JSON オブジェクトと同様の柔軟性を保持して、新しいフィールドを簡単に追加できるようなバイナリメッセージにした。ただし、JSON のようにフィールド名を毎回書き出すのは無駄が多いと思ったので、高速なハッシュアルゴリズムを使ってフィールド名を 24 bit に圧縮した。ハッシュ衝突の可能性もあるが、それはエンコーディング時に検出できると思う。

とりあえず自分に pull request を送ってみたけども、[@xuwei-k (吉田さん)][xuweik] のリアクションは「なんで MessagePack 使わないの?」というものだった。

### MessagePack サポート

独自バイナリフォーマットを実装した後だったので、[MessagePack][msgpack] のサポートは結構あっさりできた。
MessagePack は最初のタグの部分にかなり色々な情報を乗せているので、例えば `null` とかは 1 バイトで表現できる。

ただし、僕は [msgpack-java][msgpackjava] をバックエンドに使ったので、C++ 実装の msgpack とは性能などが異なるかもしれない。

### gzipped Spray JSON

[@fommil (Sam Halliday さん)][fommil] に言われていたのは、gzip した Spray JSON の方が下手なバイナリフォーマットよりも性能出るということだった。土台は整ったので、早速比較してみよう。[Travis CI][travis] でのベンチマーク結果はこうなった:

```bash
[info] Benchmark                                     Mode  Cnt    Score     Error  Units
[info] BinaryBenchmark.moduleId1SaveToFile           avgt   10  152.395 ± 140.531  ms/op
[info] BinaryBenchmark.moduleId2LoadFromFile         avgt   10   82.070 ±  22.701  ms/op
[info] GzipSprayBenchmark.moduleId1SaveToFile        avgt   10   60.115 ±  60.010  ms/op
[info] GzipSprayBenchmark.moduleId2LoadFromFile      avgt   10   39.847 ±   5.957  ms/op
[info] MessagePackBenchmark.moduleId1SaveToFile      avgt   10   48.141 ±   7.782  ms/op
[info] MessagePackBenchmark.moduleId2LoadFromFile    avgt   10   90.794 ±  21.501  ms/op
[info] SprayBenchmark.moduleId1SaveToFile            avgt   10   32.879 ±   6.607  ms/op
[info] SprayBenchmark.moduleId2LoadFromFile          avgt   10   40.074 ±  14.096  ms/op
```

データの保存と読み込み両方で、僕の独自バイナリフォーマットは一番性能が悪い (234ms)。
保存と読み込みの合計で見ると、Jawn を使った素の Spray JSON が一番 (72ms) で、次が gzipped Spray JSON (99ms)、そして MessagePack (138ms) という順になっている。

ファイルのサイズを比較すると、Spray JSON は 1.4 MB、gzipped Spray JSON は 123 KB、MessgePack は 1.2 MB、そして独自バイナリメッセージは 896 KB という結果となった。テストデータはかなり繰り返しが多いものだったので圧縮率が良すぎる結果となったかもしれないけども、約 40% の時間ペナルティーで 1/10 のファイルサイズになったのは注目に値する。これは特に SSD ドライブの付いていないマシンで効いてくる可能性がある。

### Scala JSON サポート

sjson-new を書き始めた動機の一つとして [SLIP-28][slip28] Scala JSON AST への移行パスを提供するというものがあった。

Scala JSON を進めている中心人物である Matthew de Detrich さんが [Scala JSON AST][scalajson] のマイルストーンを `"org.mdedetrich" %% "scala-json-ast" % "1.0.0-M1"` として公開したので、実際に使ってみれるようになった。パーサーも pretty printer も無いので、パーサーは Matthew さんの Jawn フォークから、pretty printer は Spray から拝借してきた。結構簡単に Scala JSON の "unsafe" AST へのサポートを実装することができた。

各データ型に対して `JsonFormat` を提供するのが一番面倒な所だ。それが済めば、sjson-new は、追加の作業を一切せずに同じプロトコルを異なるバックエンドに再利用することができる。以下が[ベンチマーク][travis]の結果だ:

<s>
Jawn を用いた Scala JSON (63ms) は Spray JSON (72ms) よりも 12% 高速にデータのラウンドトリップしていることが分かる。同様の傾向が gzipped Scala JSON (90ms) と gzipped Spray JSON (99ms) でも見られる。性能の向上は多分 "unsafe" AST が `Array` を使っているのに対して、Spray JSON が `Vector` を使っていることから来ているのかもしれない。
</s>

**訂正**: 上記の結果は僕のバグのせいだと思う。最近の結果だとこうなっている:

```bash
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
```

Jawn を用いた Scala JSON (72ms) は Spray JSON (65ms) よりも 9%
遅くデータのラウンドトリップしていることが分かる。同様の傾向が gzipped Scala JSON (86ms) と gzipped Spray JSON (77ms) でも見られる。

ファイルサイズは全く同一だった。両方とも Spray JSON の compact printer の実装に由来しているので、驚くことではない。

### JNothing をエミュレートする

Protocol Buffers といったバイナリプロトコルから学べることはある:

> For any non-repeated fields in proto3, or `optional` fields in proto2, the encoded message may or may not have a key-value pair with that tag number.
>
> In proto3, repeated fields are packed by default. These function like repeated fields, but are encoded differently. A packed repeated field containing zero elements does not appear in the encoded message.

> proto3 での非多値フィールド、もしくは proto2 での `optional` なフィールドは、エンコードされたメッセージ内にタグ番号に対応したキーと値のペアが現れない可能性がある。
>
> proto3 では、多値フィールドはデフォルトで packed である。これらは多値フィールド同様に機能するが、異なる方法でエンコードされる。0個の要素を持つ packed な多値フィールドはエンコードされたメッセージに現れない。

これらの技法は JSON フォーマットにも応用できる。`Option[A]` や何らかのコレクションをフィールドとして持ち、デフォルト値が `None` や空であるデータ型はたくさんある。それらの空のフィールドを JSON オブジェクトに含めない利点がいくつか考えられる。

第一に、読み込み側がより寛容になるため、スキーマのある程度の進化が可能になる。JSON にフィールドが無ければ、代わりに何らかのデフォルトの値が用いられるようになるからだ。第二に、それらのフィールド名を含めなくてもよくなるので JSON オブジェクトのサイズが小さくなる。

Lift JSON や Json4s には `JNothing` という値の欠如を表すものがあったけども、最近の傾向だと `Option[J]` を使うのが良いとされているみたいだ。そのため、`JsonReader` を変えて `J` の代わりに `Option[J]` を受け取るようにする必要がある。以下は変更後の `Int` の `JsonFormat` だ:

```scala
  implicit object IntJsonFormat extends JsonFormat[Int] {
    def write[J](x: Int, builder: Builder[J]): Unit =
      builder.writeInt(x)
    def read[J](jsOpt: Option[J], unbuilder: Unbuilder[J]): Int =
      jsOpt match {
        case Some(js) => unbuilder.readInt(js)
        case None     => 0
      }
  }
```

これで読み込み側は改善した。次に、`JsonWriter` に `def addField[J](name: String, obj: A, builder: Builder[J]): Unit` というメソッドを追加した。これで、フォーマット側で JSON フィールドの作成を省くことができるようになる。使ってみよう:

```scala
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
```

見てのとおり、`Person("Bob", None)` の JSON 表記は `None` の値のフィールドを含まないようになった。

### sjson-new 0.4.0

独自バイナリフォーマットを作るよりも gzip を使ったほうが高速で、ファイルサイズも小さくて、多分信頼性も高いので独自バイナリは 0.4.0 に含めなかった。本稿で紹介したその他の機能は 0.4.0 に入っているので試してみてほしい:

```scala
// To use sjson-new with Spray JSON
libraryDependencies += "com.eed3si9n" %%  "sjson-new-spray" % "0.4.0"

// To use sjson-new with Scala JSON
libraryDependencies += "com.eed3si9n" %%  "sjson-new-scalajson" % "0.4.0"

// To use sjson-new with MessagePack
libraryDependencies += "com.eed3si9n" %%  "sjson-new-msgpack" % "0.4.0"
```
