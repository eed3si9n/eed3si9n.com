  [1]: http://eed3si9n.com/gigahorse/ja/
  [AHC]: https://github.com/AsyncHttpClient/async-http-client
  [akkahttp]: http://doc.akka.io/docs/akka-http/current/scala.html
  [@alexdupre]: https://github.com/alexdupre
  [@eed3si9n]: https://github.com/eed3si9n
  [12]: https://github.com/eed3si9n/gigahorse/pull/12
  [15]: https://github.com/eed3si9n/gigahorse/pull/15
  [16]: https://github.com/eed3si9n/gigahorse/pull/16
  [963]: https://github.com/AsyncHttpClient/async-http-client/pull/963
  [sbtb_reactivestreams]: https://www.youtube.com/watch?v=xY088mskCwE

Gigahorse 0.2.0 をリリースした。新機能は 2つのバックエンドを選べるようになったことだ。
[@alexdupre][@alexdupre] さんが AHC 1.9 から Netty 4 ベースの AHC 2.0 への移行をコントリビュートしてくれた。[#12][12]

さらに、[#15][15] で僕が実験的な Akka HTTP サポートを追加した。

詳しくは [Gigahorse ドキュメント][1]を参照してほしい。

### 関数を使う

Gigahorse 0.1.x から引き続き Gigahorse の基本の関数は、レスポンスオブジェクトを `A` に変換する `http.run(r, f)` だ。

<scala>
val f = http.run(r, Gigahorse.asString andThen {_.take(60)})
</scala>

今まで `Response` クラスと呼んでいたものは `FullResponse` に改名された。`FullResponse` は、ボディーコンテンツの全てをメモリ上に受け取ったレスポンスを表す。

### Reactive Stream を用いた非同期処理

コンテンツが比較的小さい場合はそれでもいいかもしれないが、 例えばファイルをダウンロードする場合などはコンテンツの チャンクを受け取り次第に処理していきたい。

<scala>
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
</scala>

Lightbend が Akka HTTP と AHC [#963][963] の両方に Reactive Stream を実装してくれているお陰で、Gigahorse は両方のバックエンドを byte や String の Reactive Stream として抽象化することができる。ストリーム処理は、`http.runStream(r, f)` を使う

<scala>
  /** Runs the request and return a Future of A. */
  def runStream[A](request: Request, f: StreamResponse => Future[A]): Future[A]
</scala>

ここで注目してほしいのは、関数が `FullResponse` ではなくて `StreamResponse` を受け取ることだ。`FullResponse` と違って、`StreamResponse` はボディーコンテンツをまだ受け取っていない。

その代わりに `StreamResponse` は、コンテンツのパーツをオンデマンドで受け取る `Stream[A]` を作ることができる。 出発点として、Gigahorse は `Gigahorse.asByteStream` と `Gigahorse.asStringStream` を提供する。

<scala>
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
</scala>

これを使えば比較的簡単にストリーム処理を行うことができる。 例えば、download は以下のように実装されている。

<scala>
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
</scala>

`stream.fold` はパーツが届くと `FileOutputStream` に書き込んでいる。

### 改行区切りのストリーム

Akka HTTP を使った例もみてみる。 `$ python -m SimpleHTTPServer 8000` を実行してカレントディレクトリを 8000番ポートでサーブしているとして、 README.markdown の各行を表示したい。

<scala>
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
</scala>

うまくいった。これは JSON が入った無限ストリームを処理するのに使える。

### Reactive Streams について

Reactive Stream に関しては、Konrad 君による [Reactive Streams][sbtb_reactivestreams] の解説が詳しい。
