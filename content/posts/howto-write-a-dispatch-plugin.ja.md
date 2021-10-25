---
title:       "Dispatch プラグインの書き方"
type:        story
date:        2013-05-11
changed:     2013-05-12
draft:       false
promote:     true
sticky:      false
url:         /ja/howto-write-a-dispatch-plugin
aliases:     [ /node/136 ]
tags:        [ "scala" ]
---

  [search]: https://dev.twitter.com/docs/api/1.1/get/search/tweets
  [tweets]: https://dev.twitter.com/docs/platform-objects/tweets
  [home_timeline]: https://dev.twitter.com/docs/api/1.1/get/statuses/home_timeline
  [users]: https://dev.twitter.com/docs/platform-objects/users
  [update]: https://dev.twitter.com/docs/api/1.1/post/statuses/update
  [100]: https://groups.google.com/d/msg/dispatch-scala/CEZg9H32kX8/KRFaLQPFqDQJ

Dispatch は Scala からネットへつなぐデファクトの方法であり続けてきた。昨今のノンブロッキングIO への流れと歩調を合わせて [@n8han](https://twitter.com/n8han) はライブラリを [Async Http Client](http://sonatype.github.io/async-http-client/)ベースのものに書きなおし、Reboot と呼んだ。後にこれは、Dispatch 0.9 としてリリースされる。さらに、独自の `Promise` を SIP-14 で標準化された `Future` に置き換えたものが Dispatch 0.10 だ。

Dispatch Classic 同様に Reboot でも web API をラッピングしたプラグインを作ることができる。本稿では、Classic で書かれたプラグインを移植しながら Dispatch 0.10 プラグインの書き方を解説していく。

![working on your own twitter bot?](http://eed3si9n.com/images/twitter_bot.png)

### repatch-twitter

他のプラグインとの名前の衝突を回避するために、僕のは dispatch-twitter ではなく repatch-twitter と呼ぶことにする。

### sbt

まずは sbt の設定から始める:

```bash
repatch-twitter/
  +- project/
  |    +- build.properties
  |    +- build.scala
  +- core/
       +- src/
            +- main/
                 +- scala/
                      +- requests.scala
                      +- ...
```


`build.properties` の中身:

```bash
sbt.version=0.12.3
```

`build.scala` の中身:

```scala
import sbt._

object Builds extends Build {
  import Keys._
  lazy val dispatchVersion = SettingKey[String]("x-dispatch-version")

  lazy val buildSettings = Defaults.defaultSettings ++ Seq(
    dispatchVersion := "0.10.0",
    version <<= dispatchVersion { dv => "dispatch" + dv + "_0.1.0-SNAPSHOT" },
    organization := "com.eed3si9n",
    scalaVersion := "2.10.1",
    libraryDependencies <++= (dispatchVersion) { (dv) => Seq(
      "net.databinder.dispatch" %% "dispatch-core" % dv,
      "net.databinder.dispatch" %% "dispatch-json4s-native" % dv
    )},
    libraryDependencies <+= (scalaVersion) {
      case "2.9.3" =>  "org.specs2" %% "specs2" % "1.12.4.1" % "test"
      case _ => "org.specs2" %% "specs2" % "1.15-SNAPSHOT" % "test"
    },
    crossScalaVersions := Seq("2.10.1"),
    resolvers += "sonatype-public" at "https://oss.sonatype.org/content/repositories/public"
  )
  lazy val coreSettings = buildSettings ++ Seq(
    name := "repatch-twitter-core"
  )

  lazy val root = Project("root", file("."),
    settings = buildSettings ++ Seq(name := "repatch-twitter")) aggregate(core)
  lazy val core = Project("core", file("core"), settings = coreSettings)
}

```

Dispatch 0.10.0 は SIP-14 Future を使うため、現行では Scala 2.10 もしくは 2.9.3 からのみ使うことができる。

### 大まかな考え

Dispatch プラグインが提供するものは主に二部に分かれる。第一部は `Req` 構築クラスだ。API エンドポイントやさまざまなパラメータを表すクラスや関数を提供することができる。認証方法を抽象化することも役に立つ。いずれにせよ最終的な目的は `Http` のインスタンスに渡す `Req` オブジェクトを作ることだ。

第二部は、レスポンス処理だ。パース用の関数群を提供するか、結果を表す case class を提供する方法がある。丸ごと省略して、アプリ開発者にレスポンスを処理してもらうこともできる。

### リクエスト

とりあえず、[`GET search/tweets`][search] をラッピングしてみよう。

まず、`Req => Req` を継承する `Method` を定義する。これは後で定義する認証ラッパーから `Req` オブジェクトを受け取って別の `Req` を返す:

```scala
package repatch.twitter.request

import dispatch._
import org.json4s._

trait Method extends (Req => Req) {
  def complete: Req => Req
  def apply(req: Req): Req = complete(req)
}
```

次に API エンドポイントを表す case class を定義する:

```scala
// https://api.twitter.com/1.1/search/tweets.json
case class Search(params: Map[String, String]) extends Method {
  def complete = _ / "search" / "tweets.json" <<? params
}
case object Search {
  def apply(q: String): Search = Search(Map("q" -> q))
}
```<!-- ?>> -->

### authentication wrapper

これを使うにはあと数ステップ必要だ。まず、実行時に API の呼び出しは全て OAuth アクセストークンを用いて署名される必要がある。

```scala
import oauth._
import com.ning.http.client.oauth._

/** AbstractClient is a function to wrap API operations */
trait AbstractClient extends (Method => Req) {
  def hostName = "api.twitter.com"
  def host = :/(hostName).secure / "1.1"
  def apply(method: Method): Req = method(host)  
}

// ConsumerKey(key: String, secret: String) 
// RequestToken(key: String, token: String) 
case class OAuthClient(consumer: ConsumerKey, token: RequestToken) extends AbstractClient {
  override def apply(method: Method): Req = method(host) sign(consumer, token)
}
```

`Method => Req` を継承する `OAuthClient` を一度だけ作成して、`Method` を渡すことで、`Req` を生成する。これはまた後で説明する。

次に考えなければいけないのはどうやって `ConsumerKey` と `RequestToken` を作るかだ。consumer key は [My applications](https://dev.twitter.com/apps) からアプリごとに発行することができる。

アプリのページの OAuth setting の項目に Consumer key とその secret そして、
Your access token の項目に Access token とその secret があるはずだ。今のところはこれを直接つかって `search/tweets` API を使ってみる。

core プロジェクトに切り替えてから Scala REPL を実行する:

```scala
scala> import dispatch._, Defaults._
import dispatch._
import Defaults._

scala> import com.ning.http.client.oauth._
import com.ning.http.client.oauth._

scala> import repatch.twitter.request._
import repatch.twitter.request._

scala> val consumer = new ConsumerKey("abcd", "secret")
consumer: com.ning.http.client.oauth.ConsumerKey = {Consumer key, key="abcd", secret="secret"}

scala> val accessToken = new RequestToken("xyz", "secret")
accessToken: com.ning.http.client.oauth.RequestToken = { key="xyz", secret="secret"}

scala> val client = OAuthClient(consumer, accessToken)
client: repatch.twitter.request.OAuthClient = <function1>

scala> val http = new Http
http: dispatch.Http = Http(com.ning.http.client.AsyncHttpClient@52f1234c)

scala> http(client(Search("#scala")) OK as.json4s.Json)
res0: dispatch.Future[org.json4s.JValue] = scala.concurrent.impl.Promise$DefaultPromise@346fbd9a

scala> res0()
res1: org.json4s.JValue = 
JObject(List((statuses,JArray(List(JObject(List((metadata,JObject(List((result_type,JString(recent)), (iso_language_code,JString(es))))), (created_at,JString(Mon May 06 00:46:14 +0000 2013)), (id,JInt(331208247845462016)), (id_str,JString(331208247845462016)), (text,JString(Emanuel Goette, alias Crespo: Migration Manager for #Scala http://t.co/bzr028uEwe)), (source,JString(<a href="http://twitter.com/tweetbutton" rel="nofollow">Tweet Button</a>)), (truncated,JBool(false)), (in_reply_to_status_id,JNull), (in_reply_to_status_id_str,JNull), (in_reply_to_user_id,JNull), (in_reply_to_user_id_str,JNull), (in_reply_to_screen_name,JNull), (user,JObject(List((id,JInt(121934271)), (id_str,JString(121934271)), (name,JString(Emanuel)), (screen_name,JString(emanuelpeg)), (...
```

ツイートが取得できた! だけど、これは自分のアクセストークンを使っているため、アプリのユーザのアクセストークンを取得する必要がある。

注意: sbt console と Disptch 0.10.0 を使っている場合、console を終了した時点で CPU の使用率が 100% のままになるという挙動がある。@n8han は[sbt console に特定の振る舞い][100]だと考えているみたいだ。現在の回避策は sbt そのものを終了することしかない。

### OAuth exchange

そこで、`OAuthExchange` が登場する:

```scala
trait TwitterEndpoints extends SomeEndpoints {
  def requestToken: String = "https://api.twitter.com/oauth/request_token"
  def accessToken: String = "https://api.twitter.com/oauth/access_token"
  def authorize: String = "https://api.twitter.com/oauth/authorize"
}

case class OAuthExchange(http: HttpExecutor, consumer: ConsumerKey, callback: String) extends
  SomeHttp with SomeConsumer with TwitterEndpoints with SomeCallback with Exchange {
}
```

まずはリクエストトークンを作って、ユーザにそのリクエストトークンをブラウザから認可してもらって、確認コードを使ってアクセストークンを取得するというのが大筋だ。ここでは、out-of-band 認可が必要なデスクトップアプリを開発していると仮定する。

```scala
scala> val exchange = OAuthExchange(http, consumer, "oob")
exchange: repatch.twitter.request.OAuthExchange = OAuthExchange(Http(com.ning.http.client.AsyncHttpClient@4293aa50),{Consumer key, key="abcd", secret="secret"},oob)

scala> val x = exchange.fetchRequestToken
x: scala.concurrent.Future[Either[String,com.ning.http.client.oauth.RequestToken]] = scala.concurrent.impl.Promise$DefaultPromise@45d45cb6

scala> val reqToken = x() match {
     |   case Right(t) => t
     |   case Left(s)  => sys.error(s)
     | }
reqToken: com.ning.http.client.oauth.RequestToken = { key="rxyz", secret="rsecret"}

scala> val authorizeUrl = exchange.signedAuthorize(reqToken)
authorizeUrl: String = https://api.twitter.com/oauth/authorize?oauth_token=rxyz&oauth_signature=xxxxx%3D
```

`authorizeUrl` をアプリユーザにブラウザで開いて、暗証番号を取得するもらう。

```scala
scala> val x2 = exchange.fetchAccessToken(reqToken, "1234567")
x2: scala.concurrent.Future[Either[String,com.ning.http.client.oauth.RequestToken]] = scala.concurrent.impl.Promise$DefaultPromise@5ae1b5e6

scala> val accessToken = x2() match {
     |   case Right(t) => t
     |   case Left(s)  => sys.error(s)
     | }
accessToken: com.ning.http.client.oauth.RequestToken = { key="xyz", secret="secret2"}

scala> val client = OAuthClient(consumer, accessToken)
client: repatch.twitter.request.OAuthClient = <function1>
```

次回使うために、アクセストークンはどこか安全な場所に保存する。用例の中にトークンが出てこないようにするために、properties ファイルから `OAuthClient` を作る `ProperitesClient` を定義しよう:

```scala
object ProperitesClient {
  def apply(props: Properties): OAuthClient = {
    val consumer = new ConsumerKey(props getProperty "repatch.twitter.consumerKey",
      props getProperty "repatch.twitter.consumerKeySecret")
    val token = new RequestToken(props getProperty "repatch.twitter.accessToken",
      props getProperty "repatch.twitter.accessTokenSecret")
    OAuthClient(consumer, token)
  }
  def apply(file: File): OAuthClient = {
    val props = new Properties()
    props load new FileInputStream(file)
    apply(props)
  }
}
```

これで consumer key と access token を properties ファイルに保存できるようになった:

```bash
repatch.twitter.consumerKey=abc
repatch.twitter.consumerKeySecret=secret
repatch.twitter.accessToken=xyz
repatch.twitter.accessTokenSecret=secret2
```

読み込むには以下のようにする:

```scala
scala> import dispatch._, Defaults._
import dispatch._
import Defaults._

scala> import repatch.twitter.request._
import repatch.twitter.request._

scala> val prop = new java.io.File(System.getProperty("user.home"), ".foo.properties")
prop: java.io.File = /Users/you/.foo.properties

scala> val client = PropertiesClient(prop)
client: repatch.twitter.request.OAuthClient = <function1>

scala> val http = new Http
```

OAuth はこれで十分。Dispatch の話に戻ろう。

アプリユーザに代わってリクエストを署名できるようになったので、これで最小限の役に立つプラグインができたと言える。

### クエリ・パラメータのサポート

[`GET search/tweets`][search] を見ると、渡すことができるたくさんのパラメータがあることに気付く。`Search` クラスからこれを設定できるようにしてみよう。

```scala
import java.util.Calendar
import java.text.SimpleDateFormat

trait Show[A] {
  def shows(a: A): String
}
object Show {
  def showA[A]: Show[A] = new Show[A] {
    def shows(a: A): String = a.toString 
  }
  implicit val stringShow  = showA[String]
  implicit val intShow     = showA[Int]
  implicit val bigIntShow  = showA[BigInt]
  implicit val booleanShow = showA[Boolean]
  private val yyyyMmDd = new SimpleDateFormat("yyyy-MM-dd")
  implicit val calendarShow: Show[Calendar] = new Show[Calendar] {
    def shows(a: Calendar): String = yyyyMmDd.format(a.getTime)
  }
}
```

上記は `Show` 型クラスでそれぞれの型をどう `String` として表示するかをコントロールできる。`Calendar` 意外は `toString` をそのまま使っている。

```scala
// https://api.twitter.com/1.1/search/tweets.json
case class Search(params: Map[String, String]) extends Method with Param[Search] {
  def complete = _ / "search" / "tweets.json" <<? params

  def param[A: Show](key: String)(value: A): Search =
    copy(params = params + (key -> implicitly[Show[A]].shows(value)))
  private def geocode0(unit: String) = (lat: Double, lon: Double, r: Double) =>
    param[String]("geocode")(List(lat, lon, r).mkString(",") + unit)
  val geocode_mi = geocode0("mi")
  val geocode  = geocode0("km")
  val lang     = 'lang[String]
  val locale   = 'locale[String]
  /**  mixed, recent, popular */
  val result_type = 'result_type[String]
  val count    = 'count[Int]
  val until    = 'until[Calendar]
  val since_id = 'since_id[BigInt]
  val max_id   = 'max_id[BigInt]
  val include_entities = 'include_entities[Boolean]
  val callback = 'callback[String]
}
case object Search {
  def apply(q: String): Search = Search(Map("q" -> q))
}

trait Param[R] {
  val params: Map[String, String]
  def param[A: Show](key: String)(value: A): R
  implicit class SymOp(sym: Symbol) {
    def apply[A: Show]: A => R = param(sym.name)_
  }
}
``` <!-- '?>> -->

これは dispatch-twitter の [`param`](https://github.com/n8han/dispatch-twitter/blob/a2dff17b7ba85b53e94dbfd4891430638de7a607/src/main/scala/Twitter.scala#L19) にヒントを得て作ったものだけど、型安全でさらに簡潔になっている。`Symbol` に `apply` メソッドを注入していて、そのシンボルの名前を `param` に部分適用している。結果として、`val lang = 'lang[String]` はポイント・フリー・スタイルで `String => Search` を定義する。

これを使って New York City から半径 10マイル内で "#scala" を含むツイートを 2つ検索してみよう:

```scala
scala> val x = http(client(Search("#scala").geocode_mi(40.7142, -74.0064, 10).count(2)) OK as.json4s.Json)
x: dispatch.Future[org.json4s.JValue] = scala.concurrent.impl.Promise$DefaultPromise@3252d2de

scala> val json = x()
json: org.json4s.JValue = 
JObject(List((statuses,JArray(List(JObject(List((metadata,JObject(List((result_type,JString(recent)), (iso_language_code,JString(en))))), (created_at,JString(Sun May 05 06:27:50 +0000 2013)), (id,JInt(330931826879234049)), (id_str,JString(330931826879234049)), (text,JString(Rocking the contravariance. Hard. #nerd #scala)), (source,JString(web)), (truncated,JBool(false)), (in_reply_to_status_id,JNull), (in_reply_to_status_id_str,JNull), (in_reply_to_user_id,JNull), (in_reply_to_user_id_str,JNull), (in_reply_to_screen_name,JNull), (user,JObject(List((id,JInt(716931690)), (id_str,JString(716931690)), (name,JString(Alex Lo)), (screen_name,JString(alexlo03)), (location,JString(New York, New York)), (description,JString(what?)), (url,JString(http://t.co/jMjRuK7h19))...
```

### レスポンス処理

次のステップは、返ってきた json をパースするための補助を提供することだ。この問題の解決には2つの意見がある。第一は、1つのフィールドのみをパースする関数をそれぞれのフィールドに対して提供する方法。第二は、いくつかのフィールドをパースして case class を作成するコンバータを提供することだ。Dispatch は両方の方法を同時に提供することもできる。

フィールド・パーサの利点はその柔軟性にある。特定のフィールドの集合に依存しないため、将来 API が他のフィールドを返し始めたとしても自然に対応することができる。逆に、難点は必要なフィールドをアプリ開発者で明示的に指定する必要があり、冗長になってしまうことだ。

case class コンバータの利点は利便性にある。case class を注文するだけで、パーシングは任せることができる。難点は、API が他のフィールドを追加した時にアプリ開発者が対応できないことと、22 フィールドの限界があることだ ([SI-7296](https://issues.scala-lang.org/browse/SI-7296) のことは分かっている)。

ハイブリッドとして両方を提供することで、典型的な用例ではアプリ開発者はまず case class を使って、不十分ならばフィールド・パーサにフォールバックするという方法も考えられる。

### フィールド・パーサ

また、基礎的な型クラスを定義することから始める。

```scala
package repatch.twitter.response

import dispatch._
import org.json4s._
import java.util.{Calendar, Locale}
import java.text.SimpleDateFormat

trait ReadJs[A] {
  import ReadJs.=>?
  val readJs: JValue =>? A
}
object ReadJs {
  type =>?[-A, +B] = PartialFunction[A, B]
  def readJs[A](pf: JValue =>? A): ReadJs[A] = new ReadJs[A] {
    val readJs = pf
  }
  implicit val listRead: ReadJs[List[JValue]] = readJs { case JArray(v) => v }
  implicit val objectRead: ReadJs[JObject]    = readJs { case JObject(v) => JObject(v) }
  implicit val bigIntRead: ReadJs[BigInt]     = readJs { case JInt(v) => v }
  implicit val intRead: ReadJs[Int]           = readJs { case JInt(v) => v.toInt }
  implicit val stringRead: ReadJs[String]     = readJs { case JString(v) => v }
  implicit val boolRead: ReadJs[Boolean]      = readJs { case JBool(v) => v }
  private val twitterFormat = new SimpleDateFormat("EEE MMM dd HH:mm:ss ZZZZZ yyyy", Locale.ENGLISH)
  twitterFormat.setLenient(true)
  implicit val calendarRead: ReadJs[Calendar] =
    readJs { case JString(v) =>
      val date = twitterFormat.parse(v)
      val c = new GregorianCalendar
      c.setTime(date)
      c
    }
}
```

これは json のパーシングを抽象化する。これを部品として使って、`Symbol` にメソッドを注入する。

```scala
object Search extends Parse {
  val statuses        = 'statuses.![List[JValue]]
  val search_metadata = 'search_metadata.![JObject]
}

trait Parse {
  def parse[A: ReadJs](js: JValue): Option[A] =
    implicitly[ReadJs[A]].readJs.lift(js)
  def parse_![A: ReadJs](js: JValue): A = parse(js).get
  def parseField[A: ReadJs](key: String)(js: JValue): Option[A] = parse[A](js \ key)
  def parseField_![A: ReadJs](key: String)(js: JValue): A = parseField(key)(js).get
  implicit class SymOp(sym: Symbol) {
    def apply[A: ReadJs]: JValue => Option[A] = parseField[A](sym.name)_
    def ![A: ReadJs]: JValue => A = parseField_![A](sym.name)_
  }
}
```

`response` パッケージ内にいるため、先ほどの `Search` とは別のオブジェクトであることに注意してほしい。上の例では `statuses` は `JValue => List[JValue]` の関数で、これもポイントフリーで定義されている。実際のツイートの内容をパースするにはもう 1段階踏み込んで [Tweets][tweets] を見る必要がある。

```scala
/** https://dev.twitter.com/docs/platform-objects/tweets 
 */
object Tweet extends Parse {
  val contributors   = 'contributors[List[JValue]]
  val coordinates    = 'coordinates[JObject]
  val created_at     = 'created_at.![Calendar]
  val current_user_retweet = 'current_user_retweet[JObject]
  val entities       = 'entities.![JObject]
  val favorite_count = 'favorite_count[Int]
  val favorited      = 'favorited[Boolean]
  val filtere_level  = 'filtere_level[String]
  val id             = 'id.![BigInt]
  val id_str         = 'id_str.![String]
  val in_reply_to_screen_name   = 'in_reply_to_screen_name[String]
  val in_reply_to_status_id     = 'in_reply_to_status_id[BigInt]
  val in_reply_to_status_id_str = 'in_reply_to_status_id_str[String]
  val in_reply_to_user_id       = 'in_reply_to_user_id[BigInt]
  val in_reply_to_user_id_str   = 'in_reply_to_user_id_str[String]
  val lang           = 'lang[String]
  val place          = 'place[JObject]
  val possibly_sensitive = 'possibly_sensitive[Boolean]
  val scopes         = 'scopes[JObject]
  val source         = 'source.![String]
  val retweet_count  = 'retweet_count.![Int]
  val retweeted      = 'retweeted.![Boolean]
  val text           = 'text.![String]
  val truncated      = 'truncated.![Boolean]
  val user           = 'user[JObject]
  val withheld_copyright    = 'withheld_copyright[Boolean]
  val withheld_in_countries = 'withheld_in_countries[List[JValue]]
  val withheld_scope        = 'withheld_scope[String]
}
```

以下がフィールド・パーサの使用例だ:

```scala
scala> {
         import repatch.twitter.response.Search._
         import repatch.twitter.response.Tweet._
         for {
           t <- statuses(json)
         } yield(id_str(t), text(t))
       }
res0: List[(String, String)] = List((330931826879234049,Rocking the contravariance. Hard. #nerd #scala), (330877539461500928,RT @mhamrah: Excellent article on structuring distributed systems with #rabbitmq. Thanks @heroku Scaling Out with #Scala and #Akka http://t…))
```

続いて、case class コンバータをみていく。

### case class コンバータ

適当に役立ちそうなフィールドを選定することから始める。

```scala
case class Tweet(
  id: BigInt,
  text: String,
  created_at: Calendar,
  user: Option[JObject],
  favorite_count: Option[Int],
  favorited: Option[Boolean],
  retweet_count: Int,
  retweeted: Boolean,
  truncated: Boolean,
  source: String,
  lang: Option[String],
  coordinates: Option[JObject],
  entities: JObject,
  in_reply_to_status_id: Option[BigInt],
  in_reply_to_user_id: Option[BigInt]
)
```

これで、大半のユースケースを満たすことができるはずだ。続いて、`JValue` をパースしてこの case class を作る `apply` を実装する。

```scala
/** https://dev.twitter.com/docs/platform-objects/tweets 
 */
object Tweet extends Parse {
  val contributors   = 'contributors[List[JValue]]
  ....

  def apply(js: JValue): Tweet = Tweet(
    id = id(js),
    text = text(js),
    created_at = created_at(js),
    user = user(js),
    favorite_count = favorite_count(js),
    favorited = favorited(js),
    retweet_count = retweet_count(js),
    retweeted = retweeted(js),
    truncated = truncated(js),
    source = source(js),
    lang = lang(js),
    coordinates = coordinates(js),
    entities = entities(js),
    in_reply_to_status_id = in_reply_to_status_id(js),
    in_reply_to_user_id = in_reply_to_user_id(js)   
  )
}
```

フィールド名が二度出てくるのがカッコ悪いけど、順序に気を使うより安全だ。

`Search` も case class 化する:

```scala
case class Search(
  statuses: List[Tweet],
  search_metadata: JObject
)

/** https://dev.twitter.com/docs/api/1.1/get/search/tweets
 */
object Search extends Parse {
  val statuses        = 'statuses.![List[JValue]]
  val search_metadata = 'search_metadata.![JObject]

  def apply(js: JValue): Search = Search(
    statuses = statuses(js) map {Tweet(_)},
    search_metadata = search_metadata(js)
  )
}
```

次がちょっと変わっている。`dispatch.as.repatch.twitter.response` パッケージの package object を定義する。これは、パッケージ名 `as` が `dispatch.as` に使われていて、その下のレスポンスコンバータを定義することが期待されているからだ。もうちょっと短くすることもできるけど、フルネームの `repatch.twitter.response` をつなげることにする。

```scala
package dispatch.as.repatch.twitter

package object response {
  import com.ning.http.client.Response    
  import repatch.twitter.{response => r}
  import dispatch.as.json4s.Json

  val Search: Response => r.Search = Json andThen r.Search.apply
}
```

何故こんなことをやっているのかはすぐに分かる。Search の呼び出しの例を覚えているだろうか? 結果を直接 case class に変換してみよう:

```scala
scala> val x2 = http(client(Search("#scala").geocode_mi(40.7142, -74.0064, 10).count(2)) OK
         as.repatch.twitter.response.Search)
x2: dispatch.Future[repatch.twitter.response.Search] = scala.concurrent.impl.Promise$DefaultPromise@6bc9806d

scala> val search = x2()
search: repatch.twitter.response.Search = Search(List(Tweet(330931826879234049,Rocking the contravariance. Hard. #nerd #scala,java.util.GregorianCalendar[time=1367735270000,areFieldsSet=true,areAllFieldsSet=true,lenient=true,zone=sun.util.calendar.ZoneInfo[id="America/New_York",offset=-18000000,dstSavings=3600000,useDaylight=true,transitions=235,lastRule=java.util.SimpleTimeZone[id=America/New_York,offset=-18000000,dstSavings=3600000,useDaylight=true,startYear=0,startMode=3,startMonth=2,startDay=8,startDayOfWeek=1,startTime=7200000,startTimeMode=0,endMode=3,endMonth=10,endDay=1,endDayOfWeek=1,endTime=7200000,endTimeMode=0]],firstDayOfWeek=1,minimalDaysInFirstWeek=1,ERA=1,YEAR=2013,MONTH=4,WEEK_OF_YEAR=19,WEEK_OF_MONTH=2,DAY_OF_MONTH=5,DAY_OF_YEAR=125,DAY_OF_WEEK=1,DAY_OF_WEEK_IN_MONTH=1...
```

見てのとおり、用例コードはこの方が簡略化された。だんだん使える形になってきた。

### Users

Tweet オブジェクトは [User][users] オブジェクトを埋め込んでいるため、これもフィールドパーサと case class を提供しよう。

```scala
case class User(
  id: BigInt,
  screen_name: String,
  created_at: Calendar,
  name: String,
  `protected`: Boolean,
  description: Option[String],
  location: Option[String],
  time_zone: Option[String],
  url: Option[String],
  verified: Boolean,
  statuses_count: Int,
  favourites_count: Int,
  followers_count: Int,
  friends_count: Int,
  default_profile: Boolean,
  default_profile_image: Boolean,
  profile_image_url: String,
  profile_image_url_https: String,
  lang: Option[String],
  entities: JObject
)

/** https://dev.twitter.com/docs/platform-objects/users
 */
object User extends Parse with CommonField {
  val contributors_enabled  = 'contributors_enabled.![Boolean]
  val default_profile       = 'default_profile.![Boolean]
  val default_profile_image = 'default_profile_image.![Boolean]
  val description           = 'description[String]
  val favourites_count      = 'favourites_count.![Int]
  ....

  def apply(js: JValue): User = User(
    id = id(js),
    screen_name = screen_name(js),
    created_at = created_at(js),
    name = name(js),
    `protected` = `protected`(js),
    ....
  )
}

trait CommonField { self: Parse =>
  val id                    = 'id.![BigInt]
  val id_str                = 'id_str.![String]
  val created_at            = 'created_at.![Calendar]
  val entities              = 'entities.![JObject]
  val lang                  = 'lang[String]
  val withheld_copyright    = 'withheld_copyright[Boolean]
  val withheld_in_countries = 'withheld_in_countries[List[JValue]]
  val withheld_scope        = 'withheld_scope[String]
}
```

`Tweet` の `user` フィールドを `User` に置き換える。

```scala
case class Tweet(
  id: BigInt,
  text: String,
  created_at: Calendar,
  user: Option[User],
  ....
)
```

### Statuses

`Tweet` と `User` がそろったことで、普通のタイムラインの取得もできるはずだ。[`GET statuses/home_timeline`][home_timeline] 参照。

```scala
object Status {
  /** See https://dev.twitter.com/docs/api/1.1/get/statuses/home_timeline.
   * Wraps https://api.twitter.com/1.1/statuses/home_timeline.json
   */ 
  def home_timeline: HomeTimeline = HomeTimeline()
  case class HomeTimeline(params: Map[String, String] = Map()) extends Method
      with Param[HomeTimeline] with CommonParam[HomeTimeline] {
    def complete = _ / "statuses" / "home_timeline.json" <<? params

    def param[A: Show](key: String)(value: A): HomeTimeline =
      copy(params = params + (key -> implicitly[Show[A]].shows(value)))
    val trim_user       = 'trim_user[Boolean]
    val exclude_replies = 'exclude_replies[Boolean]
    val contributor_details = 'contributor_details[Boolean]
    val include_entities = 'include_entities[Boolean]
  }
}

trait CommonParam[R] { self: Param[R] =>
  val count           = 'count[Int]
  val since_id        = 'since_id[BigInt]
  val max_id          = 'max_id[BigInt]
}
```<!--'?>> -->

これを使ってみよう:

```scala
scala> val x = http(client(Status.home_timeline.count(2)) OK as.json4s.Json)
x: dispatch.Future[org.json4s.JValue] = scala.concurrent.impl.Promise$DefaultPromise@42d2d985

scala> x()
res1: org.json4s.JValue = 
JArray(List(JObject(List((created_at,JString(Tue May 07 08:06:09 +0000 2013)), (id,JInt(...
```

これはツイートの配列を返すため、結果を `List[Tweet]` に変換することができる。`response` パッケージに以下を定義する:

```scala
object Tweets extends Parse {
  def apply(js: JValue): List[Tweet] =
    parse_![List[JValue]](js) map { x => Tweet(x) }
}
```

そしてこれがコンバータだ:

```scala
package object response {
  ....
  val Tweets: Response => List[response.Tweet] = Json andThen response.Tweets.apply
  val Statuses: Response => List[response.Tweet] = Tweets
  val Tweet: Response => response.Tweet = Json andThen response.Tweet.apply
  val Status: Response => response.Tweet = Tweet
}
```

これでタイムラインを取得できる。

```scala
scala> val x = http(client(Status.home_timeline) OK as.repatch.twitter.response.Tweets)
x: dispatch.Future[repatch.twitter.response.Statuses] = scala.concurrent.impl.Promise$DefaultPromise@41ad625a

scala> x()
res0: List[repatch.twitter.response.Tweet] = 
List(Tweet(331691122629951489,Partially applying a function that has an implicit parameter http://t.co/CwWQAkkBAN,....
```

### ツイートの送信

ツイートの送信も簡単だ。[`POST statuses/update`][update] 参照。

```scala
object Status {
  ...

  /** See https://dev.twitter.com/docs/api/1.1/post/statuses/update
   */
  def update(status: String): Update = Update(Map("status" -> status))
  case class Update(params: Map[String, String]) extends Method with Param[Update] {
    def complete = _ / "statuses" / "update.json" << params

    def param[A: Show](key: String)(value: A): Update =
      copy(params = params + (key -> implicitly[Show[A]].shows(value)))
    val in_reply_to_status_id = 'in_reply_to_status_id[BigInt]
    val lat             = 'lat[Double]
    val `long`          = 'long[Double]
    val place_id        = 'place_id[String]
    val display_coordinates = 'display_coordinates[Boolean]
    val trim_user       = 'trim_user[Boolean]
  }
}
```

以下が使用例だ。

```scala
scala> val x = http(client(Status.update("testing from REPL")) OK as.json4s.Json)
x: dispatch.Future[org.json4s.JValue] = scala.concurrent.impl.Promise$DefaultPromise@65056d18

scala> x()
res4: org.json4s.JValue = JObject(List((user,JObject(List((time_zone,JString(Eastern Time (US & Canada))), (created_at,JString(Fri Dec 22 15:19:02 +0000 2006)), (default_profile_image,JBool(false)), (name,JString(eugene yokota))...
```

友達が上のツイートに返信してくれた。

<blockquote class="twitter-tweet"><p>@<a href="https://twitter.com/eed3si9n">eed3si9n</a> working on your own twitter bot?</p>&mdash; Lord Omlette (@LordOmlette) <a href="https://twitter.com/LordOmlette/status/331722441514708992">May 7, 2013</a></blockquote>

これに返事を書いて、その結果を `Tweet` で返す。

```scala
scala> val timeline = http(client(Status.home_timeline) OK as.repatch.twitter.response.Tweets)
timeline: dispatch.Future[List[repatch.twitter.response.Tweet]] = scala.concurrent.impl.Promise$DefaultPromise@515b96e5

scala> val to = timeline() filter { t => t.text contains "@eed3si9n" } head
to: repatch.twitter.response.Tweet = Tweet(331722441514708992,@eed3si9n working on your own twitter bot?...

scala> val x2 = http(client(Status.update("@LordOmlette wrapping Twitter API for an async http lib")
         in_reply_to_status_id to.id ) OK as.repatch.twitter.response.Tweet)
x2: dispatch.Future[repatch.twitter.response.Tweet] = scala.concurrent.impl.Promise$DefaultPromise@1d57cae4

scala> x2()
res8: repatch.twitter.response.Tweet = Tweet(331776040668102656,@LordOmlette wrapping Twitter API for an async http lib...
```

### まとめ

Dispatch Reboot は、リクエスト構築とレスポンス処理という2つの関心の分離を促進する設計となっている。repatch-twitter では [`GET search/tweets`][search] リクエストの構築のためには `request.Search` case class を定義して、レスポンス処理のためには `response.Search` を定義した。リソースの種類ごとにシンボルを使った演算子を色々と定義する代わりに、新しい Dispatch は `dispatch.as*` 以下にコンバータを定義することで変換を行う。リスポンス処理がリクエスト構築と分離されているため、アプリ開発者はリクエスト側だけを使って生の json を自分でパースするという選択肢が常にある。

一般的に、アプリ開発者から見たプラグインの使い心地を考えることが大切だ。用例のコードは Dispatch やプラグインを知らない人が読んでも意味が通じるようにするべきだ。

一方、実装レベルではもっと自由度がある。だからと言って読めなくてもいいわけじゃないけど、もっと大胆なことをすることができる。例えば、`Symbol` に `apply[A]` を注入してミニ DSL のようなものを定義して、さらに Scalaz 風の型クラスを定義して読み書きを抽象化した。これは不慣れな人には不可解かもしれないが、メンテナンスしやすいようになっている。

なお、本稿で書かれたソースは github より [eed3si9n/repatch-twitter](https://github.com/eed3si9n/repatch-twitter) として公開されている。

<script async src="//platform.twitter.com/widgets.js" charset="utf-8"></script>
