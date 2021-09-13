---
title:       "Gigahorse 0.1.0"
type:        story
date:        2016-07-29
changed:     2016-08-02
draft:       false
promote:     true
sticky:      false
url:         /gigahorse-010
aliases:     [ /node/204 ]
---

  [1]: http://eed3si9n.com/gigahorse/
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
  [stacking]: http://eed3si9n.com/herding-cats/stacking-future-and-either.html
  [thegigahorse]: http://madmax.wikia.com/wiki/The_Gigahorse

> Update: please use Gigahorse 0.1.1

Gigahorse 0.1.0 is now released. It is an HTTP client for Scala with Async Http Client underneath. Please see [Gigahorse docs][1] for the details. Here's an example snippet to get the feel of the library.

```scala
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
```

<!--more-->

### background

There's a constant need for HTTP client library. Looking around for Dispatch Reboot replacement, I couldn't find something that doesn't pull in extra dependencies beyond AHC, so I decided to port Play's [WS API][ws]. Because I didn't want to require JDK 8, I've intentionally picked AHC 1.9, but hopefully AHC 2.0 version will follow up eventually.
WS API is one of the hardened libraries by Lightbend engineers, so it made sense as a good starting point. This is true especially around sensible default values and secure defaults in [@wsargent][@wsargent]'s [SSL Config][sslconfig]. The fluent style API also seems to be popular too.

### sbt-datatype 0.2.3

The immutable datatypes used in Gigahorse are generated using [sbt-datatype][datatype], which is a pseudo case class generator that I designed and implemented together with [@Duhemm][@Duhemm]. It uses Avro-like schema like this:

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

and it generates pseudo case classes that's growable over time. Using the `since` field, it can generate multiple `apply` constructor, and it does not generate `unapply` or expose `copy` because they can not grow in binary compatible way. Instead it generates fluent style method:

<scala>
  def withConnectTimeout(connectTimeout: scala.concurrent.duration.Duration): Config = {
    copy(connectTimeout = connectTimeout)
  }
</scala>

This also motivated us to add a few features such as `extra` field to hand-code convenience functions, for example to do `Some(...)` wrapping:

<scala>
  def withAuth(auth: Realm): Config = copy(authOpt = Some(auth))
</scala>

### using functions

The API design of Gigahorse is also influenced by that of [Dispatch Reboot][dispatch] by [@n8han][@n8han]. In particular, Dispatch uses function `Response => A` to transform the response from the beginning, while with WS API, you would map over the returned `Future`. Gigahorse allows both styles, but the docs emphasizes the `http.run(r, f)`:

<scala>
val f = http.run(r, Gigahorse.asString andThen {_.take(60)})
</scala>

### using Either

Another influence from Dispatch is lifting of `Future[A]` to `Future[Either[Throwable, A]]`. To avoid LGPL, I didn't look at the implementation, but Dispatch adds extention method `either` on `Future` using implicits that does that.
I wanted to avoid implicits here, so instead I created a hacky solution called `FutureLifter` that looks like this:

<scala>
val f = http.run(r, Gigahorse.asEither map { Gigahorse.asString })
</scala>

`asEither` kind of feels like a function, but in addition to mapping to `Right(...)` it also does `recoverWith(...)` to `Left(...)`. This is fine, but you also would end up with multiple `Future[Either[Throwable, A]]`, so you might need Cats ([Stacking Future and Either][stacking]), Scalaz, and/or [@wheaties][@wheaties]'s [AutoLift][AutoLift] to compose them sanely.

### naming

<img src="/images/gigahorse-800.jpeg">

Gigahorse is named after [the custon vehicle][thegigahorse] driven by Immortan Joe in Mad Max Fury Road. I was thinking around the concept of modified stock cars of the moonshine runners. That lead me to the post-apocalyptic rat rod mayhem that is Mad Max Fury Road, which I've seen multiple times. The fact that it has two working Big Block V8 mortors felt right for this project.

### summary

Gigahorse is a new HTTP client for Scala, but it's based on the foundation of existing works like [AHC][AHC]. Let me know if you try it.
