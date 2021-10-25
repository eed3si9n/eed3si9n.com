---
title:       "Gigahorse 0.2.0"
type:        story
date:        2017-01-09
draft:       false
promote:     true
sticky:      false
url:         /gigahorse-020
aliases:     [ /node/209 ]
tags:        [ "scala" ]
---

  [AHC]: https://github.com/AsyncHttpClient/async-http-client
  [akkahttp]: http://doc.akka.io/docs/akka-http/current/scala.html
  [@alexdupre]: https://github.com/alexdupre
  [@eed3si9n]: https://github.com/eed3si9n
  [12]: https://github.com/eed3si9n/gigahorse/pull/12
  [15]: https://github.com/eed3si9n/gigahorse/pull/15
  [16]: https://github.com/eed3si9n/gigahorse/pull/16
  [963]: https://github.com/AsyncHttpClient/async-http-client/pull/963
  [sbtb_reactivestreams]: https://www.youtube.com/watch?v=xY088mskCwE
  [1]: http://eed3si9n.com/gigahorse/

Gigahorse 0.2.0 is now released. The new change is that it abstracts over two backends. [@alexdupre][@alexdupre] contributed migration from AHC 1.9 to AHC 2.0, which is based on Netty 4 in [#12][12].

In addition, there's now an experimental Akka HTTP support that I added. [#15][15]

Please see [Gigahorse docs][1] for the details.

<!--more-->

### using functions

Continuing from Gigahorse 0.1.x, the bread and butter function for Gigahorse remains to be `http.run(r, f)`, which transforms the response object to `A`:

```scala
val f = http.run(r, Gigahorse.asString andThen {_.take(60)})
```

What was called `Response` class is now renamed to `FullResponse`. A `FullResponse` represents a response that has already retrieved the entire body contents in-memory.

### Async processing with Reactive Stream

When the content is relatively small, retreiving everything first might be ok, but for things like downloading files, we would want to process the content by chunks as we receive them.

```scala
scala> import gigahorse._, support.asynchttpclient.Gigahorse
scala> import scala.concurrent._, duration._
scala> import ExecutionContext.Implicits._
scala> import java.io.File

scala> Gigahorse.withHttp(Gigahorse.config) { http =>
         val file = new File(new File("target"), "Google_2015_logo.svg")
         val r = Gigahorse.url("https://upload.wikimedia.org/wikipedia/commons/2/2f/Google_2015_logo.svg")
         val f = http.download(r, file)
         Await.result(f, 120.seconds)
       }
res0: java.io.File = target/Google_2015_logo.svg
```

Thanks to Lightbend implementing Reactive Stream on both Akka HTTP and AHC [#963][963], Gigahorse can abstract over both backends as Reactive Stream of byte or String stream.
The stream processing is provided using `http.runStream(r, f)`.

```scala
  /** Runs the request and return a Future of A. */
  def runStream[A](request: Request, f: StreamResponse => Future[A]): Future[A]
```

Note that the function takes a `StreamResponse` instead of a `FullResponse`. Unlike the `FullResponse`, it does not have the body contents received yet.

Instead, `StreamResponse` can create `Stream[A]` that will retrieve the parts on-demand. As a starting point, Gigahorse provides `Gigahorse.asByteStream` and `Gigahorse.asStringStream`.

```scala
import org.reactivestreams.Publisher
import scala.concurrent.Future

abstract class Stream[A] {
  /**
   * @return The underlying Stream object.
   */
  def underlying[A]

  def toPublisher: Publisher[A]

  /** Runs f on each element received to the stream. */
  def foreach(f: A => Unit): Future[Unit]

  /** Runs f on each element received to the stream with its previous output. */
  def fold[B](zero: B)(f: (B, A) => B): Future[B]

  /** Similar to fold but uses first element as zero element. */
  def reduce(f: (A, A) => A): Future[A]
}
```

Using this, we can process stream at relative ease. For example, `download` is implementing as follows:

```scala
  def download(request: Request, file: File): Future[File] =
    runStream(request, asFile(file))

....

import java.nio.ByteBuffer
import java.nio.charset.Charset
import java.io.{ File, FileOutputStream }
import scala.concurrent.Future

object DownloadHandler {
  /** Function from `StreamResponse` to `Future[File]` */
  def asFile(file: File): StreamResponse => Future[File] = (response: StreamResponse) =>
    {
      val stream = response.byteBuffers
      val out = new FileOutputStream(file).getChannel
      stream.fold(file)((acc, bb) => {
        out.write(bb)
        acc
      })
    }
}
```

`stream.fold` will write into the `FileOutputStream` as the parts arrive.

### Newline delimited stream

Here’s another example, this time using Akka HTTP. Suppose we are running `$ python -m SimpleHTTPServer 8000`, which serves the current directory over port 8000, and let’s say we want to take README.markdown and print each line:

```scala
scala> import gigahorse._, support.akkahttp.Gigahorse
scala> import scala.concurrent._, duration._

scala> Gigahorse.withHttp(Gigahorse.config) { http =>
         val r = Gigahorse.url("http://localhost:8000/README.markdown").get
         val f = http.runStream(r, Gigahorse.asStringStream andThen { xs =>
           xs.foreach { s => println(s) }
         })
         Await.result(f, 120.seconds)
       }
Gigahorse
==========

Gigahorse is an HTTP client for Scala with Async Http Client or Lightbend Akka HTTP underneath.
....
```

It worked. This could be used for process an infinite stream of JSON.

### about Reactive Streams

To learn about Reactive Streams, head over to Konrad's [Reactive Streams][sbtb_reactivestreams] talk.
