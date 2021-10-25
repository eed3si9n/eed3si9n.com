---
title:       "Gigahorse 0.3.0"
type:        story
date:        2017-04-27
changed:     2021-09-13
draft:       false
promote:     true
sticky:      false
url:         /ja/gigahorse-030
aliases:     [ /node/224 ]
---
  [okhttp]: http://square.github.io/okhttp/

Gigahorse 0.3.0 をリリースした。Gigahorse が何かは[ドキュメンテーション](http://eed3si9n.com/gigahorse/ja/)をみてほしい。

### OkHttp サポート

0.3.0 は [Square OkHttp][okhttp] サポートを追加する。 Gigahorse-OkHttp は Scala 2.10, 2.11, 2.12 向けにクロスビルドされている。

JavaDoc によると、`OkHttpClient` のインスタンスは close しなくてもいいらしい。

```scala
scala> import gigahorse._, support.okhttp.Gigahorse
import gigahorse._
import support.okhttp.Gigahorse

scala> import scala.concurrent._, duration._
import scala.concurrent._
import duration._

scala> val http = Gigahorse.http(Gigahorse.config) // don't have to close
http: gigahorse.HttpClient = gigahorse.support.okhttp.OkhClient@23b48158
```

<!--more-->

ただし、レスポンスオブジェクトのボディコンテンツを消費しない場合は**必ず** close する必要がある。
通常はボディコンテンツは `Gigahorse.asString` などのメソッドで消費される。
そういう意味では Akka HTTP の設計に似ているかもしれない。

```scala
scala> val r = Gigahorse.url("http://api.duckduckgo.com").get.
     |           addQueryString(
     |             "q" -> "1 + 1",
     |             "format" -> "json"
     |           )
r: gigahorse.Request = Request(http://api.duckduckgo.com, GET, EmptyBody(), Map(), Map(q -> List(1 + 1), format -> List(json)), None, None, None, None, None, None)

scala> val f = http.run(r, { res: FullResponse =>
     |   res.close() // must close if you don't consume the body
     |   1
     | })
f: scala.concurrent.Future[Int] = Future(<not completed>)

scala> Await.result(f, 120.seconds)
res0: Int = 1
```

OkHttp はボディのストリームや Reactive stream のサポートが無いため、それが必要ならば Akka HTTP 版か AHC 版の Gigahorse を使ってほしい。

### Shaded AHC 2.0

Gigahorse は AHC 2.0 をシェーディングするようようになった。

