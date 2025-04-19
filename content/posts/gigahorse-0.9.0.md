---
title:       "Gigahorse 0.9.0"
type:        story
date:        2025-04-19
url:         /gigahorse-0.9.0
tags: ["scala"]
---

Gigahorse 0.9.0 is released. Gigahorse is an HTTP client for Scala that I started in 2016, with multiple backend support: Apache HttpClient 5.x, AsyncHttpClient 2.12.x, OkHttp 3.x, and Pekko HTTP 1.x.

Gigahorse 0.9.0 is JDK 8 compatible. See [documentation](/gigahorse/) for more details on Gigahorse itself.

### multipart/form-data support

Gigahorse 0.9.0 adds [multipart/form-data](https://www.ietf.org/rfc/rfc2388.txt) upload support on all backends.

This is generally useful for uploading files.

```bash
sbt:gigahorse> commonTest/bgRun
[info] running gigahorsetest.TestApp
Server(List(SocketBinding(64312,0.0.0.0)), ...)

sbt:gigahorse> ++3.3.5
sbt:gigahorse> apacheHttp/console
```

```scala
Welcome to Scala 3.3.5 (1.8.0_402, Java OpenJDK 64-Bit Server VM).
Type in expressions for evaluation. Or try :help.

scala> import gigahorse.*, support.apachehttp.Gigahorse

scala> import scala.concurrent.*, duration.*

scala> val http = Gigahorse.http(Gigahorse.config)
val http: gigahorse.HttpClient = gigahorse.support.apachehttp.ApacheHttpClient@11a48c6b

scala> val r = Gigahorse.url("http://127.0.0.1:64312/multipart").post(
         MultipartFormBody(
           FormPart("a", "aaa", "text/plain"),
           FormPart("a.json", new java.io.File("common-test/src/main/resources/a.json"), "application/json"),
         )
       )
val r: gigahorse.Request = Request(http://127.0.0.1:64312/multipart, ....)

scala> val f = http.run(r, Gigahorse.asString)
val f: scala.concurrent.Future[String] = Future(<not completed>)

scala> Await.result(f, 120.seconds)
val res3: String = {
  "a": null
}
aaa

scala> http.close()

scala> :q
```

### Update AsyncHttpClient to 2.12.4

Gigahorse 0.9.0 updates the AsyncHttpClient backend to the latest 2.12.4, which is the latest 2.x as of writing. There are AsyncHttpClient 3.x as well, but it seems to have dropped the streaming API, so I'm staying on 2.x for now.

AsyncHttpClient 2.12.4 internally uses Netty 4.1.60.Final, but Gigahorse 0.9.0 shades both AsyncHttpClient and Netty.

### Update to Pekko HTTP

Gigahorse has had experimental Akka HTTP backend. Gigahorse 0.9.0 updates this to Pekko HTTP.
