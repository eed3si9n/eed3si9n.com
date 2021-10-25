---
title:       "sjson-new"
type:        story
date:        2016-04-04
changed:     2021-09-13
draft:       false
promote:     true
sticky:      false
url:         /ja/sjson-new
aliases:     [ /node/195 ]
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

### 背景

ソフトウェアプロジェクトを考える面白い方法の一つとして、文学的な解析があると思う。つまり、実際のコードの字面を追うだけじゃなくて、誰が、いつ、何故 (どういった問題を解決するために) どのようにして (何の影響を受けて) 書いたのかを考察することだ。そういった意味では、Scala エコシステムにおいては JSON ライブラリほど豊かなジャンルは他に無いのではないだろうか。

2008年12月に [Programming in Scala][pins] の初版が出て、JSON はパーサ・コンビネータの一例として出てきて、JSON パーサが 10行ぐらいのコードで書けることを示した:

```scala
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
```

同年の一ヶ月前に [Real World Haskell](http://book.realworldhaskell.org/) という本も出てて、これも JSON ライブラリを例をして使った ([Chapter 5. Writing a library: working with JSON data][rwh5])。これは JSON データが `JValue` と呼ばれる代数的データ型によって記述できることを解説した:

<haskell>
data JValue = JString String
            | JNumber Double
            | JBool Bool
            | JNull
            | JObject [(String, JValue)]
            | JArray [JValue]
              deriving (Eq, Ord, Show)
</haskell>

この考え方は僕たちのエコシステムに大きな影響を与えた。

翌2009年の 3月に Jorge Ortiz さんが Dispatch ライブラリに[コントリビュート][3]した `JsonParser` と `JsValue` の実装を見ると、両方の概念が反映されているのが分かる。

2009年の 6月には Joni Freeman さんが [literaljson][1] という JSON ライブラリを作って、それも `JValue` を case class でエンコードしている。8月11日に Joni さんはこのプロジェクトを当時優勢だった web フレームワークの Lift に[コントリビュート][2]して、`lift-json` として知られるようになる。この実装は再び分離して後に Json4s となる。

2010年に、Debasish Ghosh さんは型クラスに関するブログ記事シリーズを書いた。その一つが [sjson: Now offers Type Class based JSON Serialization in Scala][ghosh] で、sbinary の影響を受けて、JSON のための型クラスベースのシリアライゼーションを実装した。sjson は型クラスのインターフェイスとインスタンスは提供したけども、AST としては dispatch-json を使用した。これは、型クラスは後付けできるという Debasish の論を例示するものだった。

2011年には、(spray で知られる) Mathias さんが Dispatch の JSON AST、sjson の型クラス、さらに独自の JSON PEG パーサを実装して [spray-json][spray-json] を作った。同様に、Play 2.0 が [Scala のための JSON サポート][4]を追加した当初は Dispatch AST と sjson から出発して、その数日以内には独自の AST と[型クラス][5]を追加している。

2012年から2013年にかけて [Argonaut][Argonaut] の開発が活発に行われ、純粋関数型で非常に機能が充実した JSON ライブラリができあがった。

同じく 2012年から 2014年の時期に Erik Osheim さんが複数のバックエンドをサポートする高性能パーサ [Jawn][Jawn] を書いた。Jawn のコアはファサード (façade) と呼ばれる抽象インターフェイスに対して書かれているが、Jawn は別に様々な JSON AST に対するアダプターも提供している。

2014年に Jon Pretty さんは [Rapture JSON][Rapture JSON] モジュールを追加した。Jon は Jawn の性能とバックエンド独立性の価値にかなり早い時期に気付いた人で、Rapture JSON も同様にバックエンド独立で様々な JSON の操作機能を提供する。

2015年に Travis Brown さんが Argonaut をフォークして、Cats、Jawn、Shapeless との統合も提供する [Circe][circe] を立ち上げた。

### sjson-new

Scala プログラマの週末の嗜みとして、僕も一つ [sjson-new][sjson-new] という JSON ライブラリを書いてみた。
sjson-new は型クラスベースの JSON コーデックライブラリで、Jawn のための wit[^1] だ。つまり、複数のバックエンドに対して sjson的なコーデックを提供することを目指している。

コードは　spray-json を元にしているが、データの扱いに関しての考え方は Scala Pickling の方に近い。Pickling と違って、sjson-new-core はマクロとか普通のパターンマッチング以外での実行時リフレクションなどは一切使っていない。

Json4s-AST と使う場合:

```scala
libraryDependencies += "com.eed3si9n" %%  "sjson-new-json4s" % "0.1.0"
```

Spray と使う場合:

```scala
libraryDependencies += "com.eed3si9n" %%  "sjson-new-spray" % "0.1.0"
```

sjson-new を使うには、まず `Converter` オブジェクトを探す必要がある。`sjsonnew.support.XYZ.Converter` の `XYZ` 部分を `json4s` か `spray` に置き換えてほしい。REPL から使ってみよう:

```scala
scala> import sjsonnew.support.spray.Converter
import sjsonnew.support.spray.Converter

scala> import sjsonnew.BasicJsonProtocol._
import sjsonnew.BasicJsonProtocol._

scala> Converter.toJson[Int](42)
res0: scala.util.Try[spray.json.JsValue] = Success(42)

scala> Converter.fromJson[Int](res0.get)
res1: scala.util.Try[Int] = Success(42)
```

どのように実装されているだろうか? 普通の JSON コーデックは、何らかの型 `A` を受け取ってそれを `JValue` にエンコードする。sjson-new の `JsonWriter` 型クラスの `write` メソッドは 2つ追加でパラメータを受け取る:

```scala
@implicitNotFound(msg = "Cannot find JsonWriter or JsonFormat type class for ${A}")
trait JsonWriter[A] {
  def write[J](obj: A, builder: Builder[J], facade: Facade[J]): Unit
}
```

`obj` はエンコードしたいオブジェクト。`builder` は、sjson-new が中間値を追加できる可変のデータ構造だ。`StringBuilder` とか `ListBuffer` みたいなものだと考えてほしい。`facade` は JSON AST を抽象化したものだ。このファサードの実装は Jawn に似ているけども、これは値の抽出も行えるように拡張してある。

実用できるようになるまでにはカスタムコーデックを簡単に定義できるようにする必要がある。それができれば、ある JSON AST から別のに移行するためのブリッジとなると思う。

[^1]: 訳注: Jawn は、joint から転化した Philadelphia のスラングで場所、物、人など何でも指す言葉。wit は「cheesesteak サンドイッチに炒め玉ねぎを乗せるオーダー」という意味の言葉で、Philadelphia での "with" の訛り。
