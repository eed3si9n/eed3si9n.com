---
title:       "Gigahorse 0.8.0"
type:        story
date:        2025-04-14
url:         /gigahorse-0.8.0
tags: ["scala"]
---

Gigahorse 0.8.0 is released. Gigahorse is an HTTP client for Scala that I started in 2016, with multiple backend support. See [documentation](/gigahorse/) for more details on Gigahorse itself.

<!--more-->

Gigahorse 0.8.0 features Apache HttpComponent HttpClient 5.x, replacing the now deprecated HttpAsyncClient 4.x.

```scala
scala> import gigahorse.*, support.apachehttp.Gigahorse

scala> import scala.concurrent.*, duration.*

scala> val http = Gigahorse.http(Gigahorse.config)
val http: gigahorse.HttpClient = gigahorse.support.apachehttp.ApacheHttpClient@6e571cd9

scala> val r = Gigahorse.url("https://api.frankfurter.dev/v1/latest").get.addQueryString("base" -> "USD")
val r: gigahorse.Request = Request(https://api.frankfurter.dev/v1/latest, GET, EmptyBody(), Map(), Map(base -> List(USD)), None, None, None, None, None, None)

scala> val f = http.run(r, Gigahorse.asString)
SLF4J: Failed to load class "org.slf4j.impl.StaticLoggerBinder".
SLF4J: Defaulting to no-operation (NOP) logger implementation
SLF4J: See http://www.slf4j.org/codes.html#StaticLoggerBinder for further details.
val f: scala.concurrent.Future[String] = Future(<not completed>)

scala> Await.result(f, 120.seconds)
val res0: String = {"amount":1.0,"base":"USD","date":"2025-04-11","rates":{"AUD":1.6042,"BGN":1.7238,"BRL":5.831,"CAD":1.3869,"CHF":0.81544,"CNY":7.2994,"CZK":22.164,"DKK":6.5816,"EUR":0.88137,"GBP":0.76395,"HKD":7.7552,"HUF":360.39,"IDR":16855,"ILS":3.7209,"INR":86.09,"ISK":128.06,"JPY":142.84,"KRW":1431.68,"MXN":20.38,"MYR":4.4225,"NOK":10.665,"NZD":1.7254,"PHP":57.065,"PLN":3.7857,"RON":4.3872,"SEK":9.8006,"SGD":1.3213,"THB":33.555,"TRY":38.058,"ZAR":19.2834}}

scala> http.close()
```

Another feature of 0.8.0 is that it's compatible with JDK 8, which doesn't seem to be the case for Dispatch or sttp currently.
