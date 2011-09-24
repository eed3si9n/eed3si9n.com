future の実装には様々なものがあるけど、標準ライブラリの中に共通の親 trait があれば、特定のプラットフォームスタックにコードを依存させずにこの概念を表現できるのにと思っていた。そう思う人が他にもいるかは分からないけど、ライブラリの作者なんかには役に立つんじゃないかな。取り敢えずこれが、[sff4s](https://github.com/eed3si9n/sff4s) を書いた動機だ。

future って何?
-------------
多分名前ぐらいは聞いたことあるかもしれないけど、一応おさらいしよう。future値（promise とも呼ばれる）は未完の計算を表現する。

- future値は未完の計算を表現する。

これがよく使われる説明だけど、それだけでは分からない。ここで言外に含まれているのは、その計算は裏で行われているということだ。それは同じコンピュータ内の別のスレッドか、別のサーバの中かもしれないし、行列待ちでまだ計算は始まってさえいないかもしれない。とにかく、計算は現在の制御フローの外で行われているということだ。

- 計算はどこか別の所で行われる。

future値のもう一つの側面は、そのうちに計算結果を得られるということだ。Scala の場合は `def apply()` を呼び出すなどの明示的なステップを要する。計算が未完の場合は、ブロック(block)する。つまり、計算結果が得られるまで待たされる（もしくはタイムアウトする）。

- future値から計算結果を得ることができる。

最初に future値が宣言された時には計算結果は有るかもしれないし、まだ無いかもしれない。うまくいけば、ある時点で結果が到着し、オブジェクトの内部構造が変更される。これを、future値を「解決」(resolve)したという。勝手に状態が変わるものというのはプログラミングではあまり見かけないので、少し不気味ではある。

- 計算結果を解決するための裏口がある。

これまでで、最も単純な形の future値を記述した。実際に役に立つには他の機能も必要だけど、これでも使えないことはない。ちょっと使用例をみてみよう:

<scala>
val factory = sff4s.impl.ActorsFuture
val f = factory future {
  Thread.sleep(1000)
  1
}
f() // => これは 1秒間ブロックした後で 1 を返す</scala>

細かい事は気にしないで、最後の一行の振る舞いだけ見てほしい。このように、計算結果を取得することを、強要(forcing)するともいう。最小限の API は以下のようになる。

Future v0.1
<scala>
abstract class Future[+A] {
  /** 計算結果を強要して無期限にブロックする */
  def apply(): A
}</scala>

Scala から使用可能な future値の実装にはいくつかあるけど、どれも一から書かれてる。上のような共通な親クラスがあれば、特定のライブラリに依存しないコードを書くことができる。

まだ来ない?
---------
Future v0.1 に対して唯一できる事が計算結果が戻ってくるまでブロックしてしまうので、あまりにも不便だ。待つことしかできないから future を使わないほうがいい。そのため、全ての future値が提供するもう一つの機能として、計算結果の用意ができたかを確かめるノンブロッキング(non-blocking)な方法がある。これは実装によって `isDone`、`isSet`、`isDefined`、`isCompleted` などと呼ばれているが、全て同じ意味だ。今のところ、僕の好みとしては `def isDefined: Boolean` がいいと思う。future を概念的に `Option` の変数として考えることができるからだ。

- 計算結果が用意できたかを確かめるノンブロッキングな方法。

Future v0.2
<scala>
abstract class Future[+A] {
  def apply(): A
  
  /** 計算結果が用意できたかを確かめる */
  def isDefined: Boolean
}</scala>

タイムアウト
----------
もう一つのよくある機能としては、有限の時間だけブロックするというものがある。例えば、これは、`def apply(timeoutInMsec: Long)` と書くことができる。指定された時間内に計算が返ってこなければ、`TimeoutException` が投げられる。

- 計算結果を強要するために有限の時間だけブロックする。

Future v0.3
<scala>
abstract class Future[+A] {
  def apply(): A
  
  def apply(timeoutInMsec: Long): A
  
  def isDefined: Boolean
}</scala>

まだ最小限という感じだけど、この状態で使い始めることができる。

イベントコールバック
-----------------
タイムアウトというのは方法として根本的な問題がある。裏で行われている演算が長時間に渡った場合、計算結果を待つためにいくつものループを管理しなくてはいけないということだ。より単純なのは、コールバックのためのクロージャを渡しておいて、計算結果の用意ができた時点で future値に呼び出してもらうという方法だ。いよいよ話が非同期になったきた。twitter の future で使われている `def onSuccess(f: A => Unit): Future[A]` を採用した。使用例を見てみよう:

<scala>
f onSuccess { value =>
  println(value) // => "1" と表示する
}
</scala>

名前渡し(call-by-name)のお陰で Scala は上のブロックのコードを直ちには実行しない。
また、future値にイベントハンドラが追加されるだけで、計算値そのものは変わらないことに注意。

エラー処理
--------
上のイベントコールバックが `onSuccess` と名付けられることから、次の話題が計算の失敗であることは予想できたかもしれない。その前に、最初の節でのポイントを思い出してほしい: 計算はどこか別の所で行われる。例えば、バックグラウンドのスレッド上で実行されているとして、何らかの例外が投げられたとする。どうすればいい？現在の制御フロー中にいきなり例外を投げ込むべきだろうか。多分、違う。哲学問答に、「誰もいない森の中で木が倒れるとき、音がするだろうか」というものがあるが、それに近いものがある。何が起こるかと言うと、全ての例外は内部状態内に捕捉されて、計算値が `apply()` によって強要される時に再現される。

この概念の、Scala での慣例的な表現は `Either` だ。パラメータ付き型の `Future[A]` はどのようなエラーが潜在的に投げられるかを表さないため、僕は `Either[Throwable, A]` とした。

- 計算中の全てのエラーは内部状態に捕捉される。

これにより、エラー処理のコールバックである `def onFailure(rescueException: Throwable => Unit): Future[A]` が可能となる。実装上は、`onSuccess` も `onFailure` もより一般的なコールバックである `def respond(k: Either[Throwable, A] => Unit): Future[A]` の特殊形とみなすことができる。

- イベントコールバックは計算結果の用意ができた時点で（成功しても失敗しても）通知することができる。

エラー状態が `Either` として捕捉されるため、強要は `def get: Either[Throwable, A]` として実装され、`apply()` はそれを以下のように呼び出すことにした:

<scala>def apply(): A = get.fold(throw _, x => x)
</scala>

Future v0.4:
<scala>
abstract class Future[+A] {
  def apply(): A = get.fold(throw _, x => x)
  def apply(timeoutInMsec: Long): A = get(timeoutInMsec).fold(throw _, x => x)
  
  def isDefined: Boolean
    
  /** forces calculation result */
  def get: Either[Throwable, A]
  def get(timeoutInMsec: Long): Either[Throwable, A]
  
  def value : Option[Either[Throwable, A]] =
    if (isDefined) Some(get)
    else None  
  
  /** 計算結果の用意できたらコールバックを呼び出す */
  def respond(k: Either[Throwable, A] => Unit): Future[A]  
  
  def onSuccess(f: A => Unit): Future[A] =
    respond {
      case Right(value) => f(value)
      case _ =>
    }
    
  def onFailure(rescueException: Throwable => Unit): Future[A] =
    respond {
      case Left(e) => rescueException(e)
      case _ =>
    }
}
</scala>

だんだん良くなってきた。事実、これらの機能は既に [`java.util.concurrent.Future`][3] で提供されている基本機能を追い越しているため、独自の実装を提供する必要があった。

モナド連鎖
--------
これで（やっと）実際の future を使った話をする下地が整った。これまでは、計算結果を取り出す話ばっかりをしたきたが、それは未来値というよりは現在値だ。計算値の用意ができる前に future値を用いて別の future値を計算する方が面白いことができる。[ある物の値から別の物を計算する][6]... モナドだろ、これは。使用例に進む!

<scala>
val g = f map { _ + 1 }
</scala>

さっき打ち込んだばっかりだから `f()` がどう解決するかを知っているが、知らないフリをしよう。つまり、ここに未知の `Future[Int]` があるとする。その値がなんであろうと、1 を加える。これは、また別の未知の future値となる。何らかの理由で `f` が失敗した場合、`Option` を `map` するときのように、全体が失敗する。

これらを for 式から使うこともできる:

<scala>
val xFuture = factory future {1}
val yFuture = factory future {2}

for {
  x <- xFuture
  y <- yFuture
} {
  println(x + y) // => prints "3"
}
</scala>

長くなるので、これらのシグネチャだけを書きだす。
<scala>
  def foreach(f: A => Unit)
  def flatMap[B](f: A => Future[B]): Future[B]
  def map[B](f: A => B): Future[B]
  def filter(p: A => Boolean): Future[A]
</scala>

select と join
--------------
twitter の Future からもう二つ面白いメソッド `select(other)` と `join(other)` を追加した。
`select` (別名 `or`) はもう一つの `Future` を引数にとり、最初に成功したものを返す。

同様に、`join` も別の `Future` を引数に取り、一つの `Future` に組み合わせる。

Future v0.5:
<scala>
abstract class Future[+A] {
  def apply(): A = get.fold(throw _, x => x)
  def apply(timeoutInMsec: Long): A = get(timeoutInMsec).fold(throw _, x => x)
  def isDefined: Boolean
  def get: Either[Throwable, A]
  def get(timeoutInMsec: Long): Either[Throwable, A]
  def value : Option[Either[Throwable, A]] =
    if (isDefined) Some(get)
    else None  
  def respond(k: Either[Throwable, A] => Unit): Future[A]  
  def onSuccess(f: A => Unit): Future[A] =
    respond {
      case Right(value) => f(value)
      case _ =>
    }
  def onFailure(rescueException: Throwable => Unit): Future[A] =
    respond {
      case Left(e) => rescueException(e)
      case _ =>
    }
  
  def foreach(f: A => Unit)
  def flatMap[B](f: A => Future[B]): Future[B]
  def map[B](f: A => B): Future[B]
  def filter(p: A => Boolean): Future[A]
  
  def select[U >: A](other: Future[U]): Future[U]
  def or[U >: A](other: Future[U]): Future[U] = select(other)
  def join[B](other: Future[B]): Future[(A, B)] 
}
</scala>

これで使いやすい future値の抽象体ができあがった。

消費者と生産者
------------
future値がどのようにして作られるかの話をする前に、少しその背景に関する話をする。
future値は未完の計算を表現する。この計算は最初にコンシューマ（consumer、消費者）によってリクエストされ、プロデューサ（producer、生産者）によって解決される。別の言い方をすると、コンシューマの視点からはだいたいの点において read-only な値だけど、プロデューサ側からは書き込み可能なデータ構造である必要があるということだ。これまでに定義した `Future` は前者だ。

これは異なるシステムの違いによる。大まかに言うと、[`java.util.concurrency.Future`][2]、[`actors.Future`][3]、[`akka.dispatch.Future`][4] はユーザが始動した計算を別の CPU コアか別のマシンに外注するのに使われる。これらのシステムでは解決ステップは API には隠蔽されており、内部で自動的に行われる。

一方、[`com.twitter.util.Future`][5] は並行計算の機構を提供しないため、コンシューマとプロデューサの両者を演じる必要がある。逆に言うと、プロデューサ側を好きなようにコントロールすることができると考えることもできる。

発送員
-----
sff4s は上記の四つの future 実装に対するディスパッチャ（dispatcher、発送員）オブジェクトを提供する。これは内部システムに計算を発送（dispatch）する `future` メソッドを定義する。最初の使用例をもう一度みてみよう:

<scala>
val factory = sff4s.impl.ActorsFuture
val f = factory future {
  Thread.sleep(1000)
  1
}</scala>

これは内部で [`scala.acotors.Futures`][7] の `future` メソッドをによりブロックの計算を発送している。
ここで注意が必要なのは `sff4s.impl.TwitterUtilFuture` の `future` メソッドは、`ActorsFuture` のような非同期な振る舞いを期待しているとガッカリする結果となるということだ。

暗黙の変換
--------
ディスパッチャは、ネイティブな future値からラッピングされたものに変える暗黙の変換（implicit converter）も実装する。

<scala>
import factory._
val native = scala.actors.Futures future {5}
val w: sff4s.Future[Int] = native
w() // => This blocks for the futures result (and eventually returns 5)
</scala>

感想とか
------
sff4s はここ数日で書いたものなので、今後バグフィクスや変更があるかもしれない。ご意見、感想など、待ってます。

  [1]: https://github.com/twitter/util/blob/master/util-core/src/main/scala/com/twitter/util/Future.scala
  [2]: http://www.scala-lang.org/api/current/scala/actors/Future.html
  [3]: http://download.oracle.com/javase/6/docs/api/java/util/concurrent/Future.html
  [4]: http://akka.io/api/akka/1.1/akka/dispatch/Future.html
  [5]: http://twitter.github.com/util/util-core/target/site/doc/main/api/com/twitter/util/Future.html
  [6]: http://eed3si9n.com/ja/monads-are-not-metaphors
  [7]: http://www.scala-lang.org/api/current/scala/actors/Futures$.html
