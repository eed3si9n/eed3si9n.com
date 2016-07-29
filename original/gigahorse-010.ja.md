  [1]: http://eed3si9n.com/gigahorse/ja/
  [AHC]: https://github.com/AsyncHttpClient/async-http-client/tree/1.9.x
  [netty]: http://netty.io
  [sslconfig]: https://github.com/typesafehub/ssl-config
  [config]: https://github.com/typesafehub/config
  [ws]: https://www.playframework.com/documentation/2.5.x/ScalaWS
  [dispatch]: http://dispatch.databinder.net/Dispatch.html
  [datatype]: http://www.scala-sbt.org/0.13/docs/Datatype.html
  [@wsargent]: https://github.com/wsargent
  [@n8han]: https://github.com/n8han
  [@Duhemm]: https://github.com/Duhemm
  [@wheaties]: https://github.com/wheaties
  [AutoLift]: https://github.com/wheaties/AutoLifts
  [stacking]: http://eed3si9n.com/herding-cats/ja/stacking-future-and-either.html
  [thegigahorse]: http://madmax.wikia.com/wiki/The_Gigahorse

Gigahorse 0.1.0 をリリースした。これは Scala のための HTTP クライアントで、内部にAsync Http Client を使っている。詳しくは [Gigahorse ドキュメント]を書いたので、それを参照してほしい。ライブラリがどういう感じなのかを例でみるとこんな感じだ。

<scala>
scala> import gigahorse._
scala> import scala.concurrent._, duration._
scala> Gigahorse.withHttp(Gigahorse.config) { http =>
         val r = Gigahorse.url("http://api.duckduckgo.com").get.
           addQueryString(
             "q" -> "1 + 1",
             "format" -> "json"
           )
         val f = http.run(r, Gigahorse.asString andThen {_.take(60)})
         Await.result(f, 120.seconds)
       }
</scala>

### 背景

HTTP クライアントライブラリが必要になる場面は常にある。Dispatch Reboot の代替を探してみて、AHC 以外に他の依存ライブラリを引っ張ってこないものが見つからなかったので、Play の [WS API][ws] を移植することにした。
JDK 8 をシステム要件にしたくなかったので敢えて AHC 1.9 を選んだが、そのうち AHC 2.0 版も出てくると思う。
WS API は Lightbend のエンジニアが堅牢化してきたライブラリなので、出発点として妥当なものだと思う。これが顕著なのは実用的なデフォルト値と [@wsargent][@wsargent] の [SSL Config][sslconfig] のセキュアなデフォルト設定だ。また、fluent スタイルの API も人気が高い。

### sbt-datatype 0.2.3

Gigahorse で使われている immutable なデータ型は [sbt-datatype][datatype] を用いて生成されている。これは僕が設計して [@Duhemm][@Duhemm] と一緒に実装した擬似 case class 生成を行うもので、Avro みたいなスキーマを使う:

    {
      "name": "Config",
      "namespace": "gigahorse",
      "type": "record",
      "target": "Scala",
      "fields": [
        {
          "name": "connectTimeout",
          "type": "scala.concurrent.duration.Duration",
          "doc": [
            "The maximum time an `HttpClient` can wait when connecting to a remote host. (Default: 120s)"
          ],
          "default": "ConfigDefaults.defaultConnectTimeout",
          "since": "0.1.0"
        },
        ....
      ]
    }

擬似 case class を使う理由は、バイナリ互換を保ったまま API の変更を行うようにするためだ。これを growable と言ったりする。`since` フィールドを使うことで複数の `apply` コンストラクタを生成することができる。また、バイナリ互換の無い `unapply` は生成せず、`copy` も内部では使っているが外部には公開していない。`copy` の代わりに fluent スタイルのメソッドを生成する:

<scala>
  def withConnectTimeout(connectTimeout: scala.concurrent.duration.Duration): Config = {
    copy(connectTimeout = connectTimeout)
  }
</scala>

使ってみていくつか追加の機能を付ける必要があって、その一つは手書きで便利関数を追加できる `extra` というフィールドだ。例えばこれを使って `Some(...)` のラッピングを行う:

<scala>
  def withAuth(auth: Realm): Config = copy(authOpt = Some(auth))
</scala>

### 関数を使う

Gigahorse の API 設計は [@n8han][@n8han] の [Dispatch Reboot][dispatch] にも影響を受けている。具体的には、Dispatch は `Response => A` 関数を使って初っ端からレスポンスを変換することができるが、WS API は返ってきた `Future` に map をかける必要がある。Gigahorse はどちらのスタイルも使えるけども、ドキュメントは `http.run(r, f)` を強調して書かれている:

<scala>
val f = http.run(r, Gigahorse.asString andThen {_.take(60)})
</scala>

### Either を使う

`Future[A]` から `Future[Either[Throwable, A]]` への持ち上げ (lifting) も Dispatch からの影響だと言える。LGPL を回避するために実装は見てないけども、Dispatch は `Future` に implicit で `either` という拡張メソッドを付けている。
僕は implicit をここでは使いたくなかったので、`FutureLifter` というちょっと雑な方法を考えた:

<scala>
val f = http.run(r, Gigahorse.asEither map { Gigahorse.asString })
</scala>

`asEither` はなんとなく関数っぽく見えるけど、`Right(...)` に map するだけじゃなくて `Left(...)` に `recoverWith(...)` するという作業もしている。それはそれでいいんだけども、複数の `Future[Either[Throwable, A]]` を合成することになると結局 Cats ([Future と Either の積み上げ][stacking]) とか Scalaz とか [@wheaties][@wheaties] の [AutoLift][AutoLift] が必要になるんじゃないかと思う。

### 名前の由来

<img src="/images/gigahorse-800.jpeg">

Gigahorse という名前は Mad Max Fury Road で Immortan Joe が乗っている[カスタム車][thegigahorse]に由来する。禁酒法時代に moonshine runner と呼ばれる運び屋が乗っていた見た目は普通の改造車をまずコンセプトとして考えていた。そこから、連想で複数回観た世界破滅後のラットロッド讃歌である Mad Max Fury Road に行き着いた。実際に稼働する Big Block V8 エンジンが 2つも付いているというのもこのプロジェクトに合っていると思った。

### まとめ

Gigahorse　は Scala のための新しい HTTP クライアントだけども、[AHC][AHC] などの既存のプロジェクトの先行研究に乗っかっている。使ってみたら、是非教えてほしい。
