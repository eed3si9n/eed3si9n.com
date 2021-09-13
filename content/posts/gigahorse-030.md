---
title:       "Gigahorse 0.3.0"
type:        story
date:        2017-04-27
changed:     2021-09-13
draft:       false
promote:     true
sticky:      false
url:         /gigahorse-030
aliases:     [ /node/223 ]
---

  [okhttp]: http://square.github.io/okhttp/

Gigahorse 0.3.0 is now released. See [documentation](http://eed3si9n.com/gigahorse/) on what it is.

### OkHttp support

0.3.0 adds [Square OkHttp][okhttp] support. Gigahorse-OkHttp is availble for Scala 2.10, 2.11, and 2.12.

According to the JavaDoc you actually don't have to close the `OkHttpClient` instance.

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

However, you **must** close the response object if you don't consume the body contents.
Normally you'd consume the body content as `Gigahorse.asString` or something like that.
In that sense, the design is similar to Akka HTTP.

<scala>
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
</scala>

OkHttp also does not provide streaming body or Reactive stream support, so if you need that check out Akka HTTP-backed or AHC-backed Gigahorse.

### Shaded AHC 2.0

Gigahorse now shades AHC 2.0.
