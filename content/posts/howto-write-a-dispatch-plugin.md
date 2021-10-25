---
title:       "how to write a Dispatch plugin"
type:        story
date:        2013-05-11
changed:     2013-05-12
draft:       false
promote:     true
sticky:      false
url:         /howto-write-a-dispatch-plugin
aliases:     [ /node/135 ]
tags:        [ "scala" ]
---

  [search]: https://dev.twitter.com/docs/api/1.1/get/search/tweets
  [tweets]: https://dev.twitter.com/docs/platform-objects/tweets
  [home_timeline]: https://dev.twitter.com/docs/api/1.1/get/statuses/home_timeline
  [users]: https://dev.twitter.com/docs/platform-objects/users
  [update]: https://dev.twitter.com/docs/api/1.1/post/statuses/update
  [100]: https://groups.google.com/d/msg/dispatch-scala/CEZg9H32kX8/KRFaLQPFqDQJ

Dispatch has been the de facto library to get to the Internet from Scala. To keep in step with the recent move towards non-blocking IO, [@n8han](https://twitter.com/n8han) rewrote the library as Reboot based on [Async Http Client](http://sonatype.github.io/async-http-client/). This became Dispatch 0.9. Then Dispatch 0.10 came out to replace its own `Promise` type with the standarized SIP-14 `Future`.

As with Dispatch Classic, Reboot lets you write plugins to wrap around web APIs. In this post we'll port a plugin from Classic to explore how it works.

![working on your own twitter bot?](http://eed3si9n.com/images/twitter_bot.png)

<!--more-->

### repatch-twitter

To avoid naming collision with other potential plugins, I'm going to call mine repatch-twitter, instead of dispatch-twitter.

### sbt

First thing to do is to set up sbt:

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

The content of `build.properties`:

```bash
sbt.version=0.12.3
```

The content of `build.scala`:

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

Since Dispatch 0.10.0 uses SIP-14 Future, it's currently available only for Scala 2.10 and 2.9.3.

### general idea

There are mainly two parts to what a Dispatch plugin would provide. First part is `Req` building classes. You can provide classes or functions that represent API end points and various parameters. Another useful thing is to abstract authentication method. The eventual job is to create `Req` object that gets passed into an `Http` instance.

The second part is the response handler. You can either provide series of parsing functions, or define a case class that represents the results. You can omit this part, and let the app developer deal with the responses directly too.

### request wrapper

Let's try wrapping [`GET search/tweets`][search].

First, we'll define a `Method` by extending `Req => Req`. It will accept a `Req` object from authentication wrapper and return a `Req`:

```scala
package repatch.twitter.request

import dispatch._
import org.json4s._

trait Method extends (Req => Req) {
  def complete: Req => Req
  def apply(req: Req): Req = complete(req)
}
```

Now we'll define a case class that represents the API end point:

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

We need a few more steps to use this. First, during the runtime, each API call needs to be signed by an OAuth access token.

```scala
package repatch.twitter.request

import dispatch._
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

We'll create an `OAuthClient` once, which extends `Method => Req` and pass in a `Method` into it to generate a `Req`. We'll get back to this later.

Second thing we have to worry about is how we create `ConsumerKey` and `RequestToken`. The consumer key can be issued for your application by going to [My applications](https://dev.twitter.com/apps), and creating one.

The application page should show Consumer key and secret under OAuth settings, and Access token and secret under Your access token. For now we can use this to test the search/tweets API.

Start Scala REPL from sbt shell after switching to core project:

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

Looks like we got some tweets! But remember currently it's using access token on behalf of you, so we need a way of acquiring an access token for the app user.

Note: When using sbt console with Dispatch 0.10.0 causes CPU to get pegged at 100% when you quit out of the console. @n8han thinks [it's particular to sbt console][100]. The only workaround for now is to quit sbt.

### OAuth exchange

This is where `OAuthExchange` comes in:

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

The basic idea is to create a request token, let the user authorize the request token using the browser, and then retrieve the access token using the verification code. I'm going to assume we're developing a desktop application, which requires out-of-band authorization:

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

Now make the app user open the browser and open the `authorizeUrl` to retrieve the PIN.

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

You can save the access token somewhere safe to reuse it next time. To avoid dealing with tokens in the examples, let's define `ProperitesClient` that creates `OAuthClient` from a properties file:

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

Now we can write both consumer key and the access token in a properities file as follows:

```bash
repatch.twitter.consumerKey=abc
repatch.twitter.consumerKeySecret=secret
repatch.twitter.accessToken=xyz
repatch.twitter.accessTokenSecret=secret2
```

Here's how to load these up:

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

Enough about OAuth. Let's talk about Dispatch.

Now that we can sign requests on behalf of the app user, this could be considered a minimally useful plugin.

### providing query parameter support

Looking at [`GET search/tweets`][search], there are number of parameters we can pass in, so we can provide them as methods on `Search` class.

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

The above is a `Show` typeclass, which lets us control how to print each types as `String`. Except for `Calendar` I'm just using the default `toString`.

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

This is inspired by dispatch-twitter's [`param`](https://github.com/n8han/dispatch-twitter/blob/a2dff17b7ba85b53e94dbfd4891430638de7a607/src/main/scala/Twitter.scala#L19), but it's typesafe and more concise. I'm injecting `apply` method to `Symbol`, which then partially applies its name to `param`. As the result `val lang = 'lang[String]` defines `String => Search` point-free style.

Here's how we can use this to query two tweets about "#scala" in the 10 mile radius from New York City:

```scala
scala> val x = http(client(Search("#scala").geocode_mi(40.7142, -74.0064, 10).count(2)) OK as.json4s.Json)
x: dispatch.Future[org.json4s.JValue] = scala.concurrent.impl.Promise$DefaultPromise@3252d2de

scala> val json = x()
json: org.json4s.JValue = 
JObject(List((statuses,JArray(List(JObject(List((metadata,JObject(List((result_type,JString(recent)), (iso_language_code,JString(en))))), (created_at,JString(Sun May 05 06:27:50 +0000 2013)), (id,JInt(330931826879234049)), (id_str,JString(330931826879234049)), (text,JString(Rocking the contravariance. Hard. #nerd #scala)), (source,JString(web)), (truncated,JBool(false)), (in_reply_to_status_id,JNull), (in_reply_to_status_id_str,JNull), (in_reply_to_user_id,JNull), (in_reply_to_user_id_str,JNull), (in_reply_to_screen_name,JNull), (user,JObject(List((id,JInt(716931690)), (id_str,JString(716931690)), (name,JString(Alex Lo)), (screen_name,JString(alexlo03)), (location,JString(New York, New York)), (description,JString(what?)), (url,JString(http://t.co/jMjRuK7h19))...
```

### providing response parsing support

The next step is to provide parsing support for the returned json. There are two schools of thought on this issue. One way is to provide a set of functions that parses one field at a time. The other way is to provide converters that parse some of the known fields and create case classes. Dispatch allows both methods to be implemented side-by-side.

The benefit of field parser approach is the flexibility. Since it won't be tied to specific set of fields, it can seamlessly catch up to additional fields if API started returning more fields. The downside is that the app developer needs to specify the all fields she wants explicitly, which is more verbose.

The benefit of the case class converter approach is the convenience. Just ask for the case class, and parsing is taken care of. The downside is that it won't be able to keep up with API changes if it added more fields, and that there's 22 fields limitation. I'm aware of [SI-7296](https://issues.scala-lang.org/browse/SI-7296).

A hybrid approach is to provide both, so the app developer can try the case classes that might cover the typical uses, and fallback to field parser if it's not enough.

### field parser

Again, we'll start by defining a basic typeclass.

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

This lets me abstract json parsing. Using this as a building block, we can again enrich `Symbol` to inject methods into it:

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

Note that we are now in `response` package, so this is different `Search` object than before. In the above `statuses` is a function `JValue => List[JValue]` again defined in point-free style. To actually parse the content of a tweet, we need to go one step further and look at [Tweets][tweets].

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

Here's how we can use the field parsers:

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

Next, let's look into the case class converters.

### providing case class converter

We start with picking out useful fields and ordering them in some way that makes sense.

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

That should satisfy majority of the use cases. Next, implement an `apply` method that parses `JValue` into the case class.

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

It's tedious to repeat the field name twice, but it's better than making sure you get the order right.

We should make a case class for `Search` too:

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

Next is a bit weird. We're going to define a package object for `dispatch.as.repatch.twitter.response` package. This is because the package name `as` is used by `displatch.as`, which is where you're suppose to hang your response converters. We probably could get away with something shorter, I'm just going to append `repatch.twitter.response`.

```scala
package dispatch.as.repatch.twitter

package object response {
  import com.ning.http.client.Response    
  import repatch.twitter.{response => r}
  import dispatch.as.json4s.Json

  val Search: Response => r.Search = Json andThen r.Search.apply
}
```

This will make sense soon. Remember the search call? Now we can convert the result strait to a case class:

```scala
scala> val x2 = http(client(Search("#scala").geocode_mi(40.7142, -74.0064, 10).count(2)) OK
         as.repatch.twitter.response.Search)
x2: dispatch.Future[repatch.twitter.response.Search] = scala.concurrent.impl.Promise$DefaultPromise@6bc9806d

scala> val search = x2()
search: repatch.twitter.response.Search = Search(List(Tweet(330931826879234049,Rocking the contravariance. Hard. #nerd #scala,java.util.GregorianCalendar[time=1367735270000,areFieldsSet=true,areAllFieldsSet=true,lenient=true,zone=sun.util.calendar.ZoneInfo[id="America/New_York",offset=-18000000,dstSavings=3600000,useDaylight=true,transitions=235,lastRule=java.util.SimpleTimeZone[id=America/New_York,offset=-18000000,dstSavings=3600000,useDaylight=true,startYear=0,startMode=3,startMonth=2,startDay=8,startDayOfWeek=1,startTime=7200000,startTimeMode=0,endMode=3,endMonth=10,endDay=1,endDayOfWeek=1,endTime=7200000,endTimeMode=0]],firstDayOfWeek=1,minimalDaysInFirstWeek=1,ERA=1,YEAR=2013,MONTH=4,WEEK_OF_YEAR=19,WEEK_OF_MONTH=2,DAY_OF_MONTH=5,DAY_OF_YEAR=125,DAY_OF_WEEK=1,DAY_OF_WEEK_IN_MONTH=1...
```

As you can see, the usage code is simpler with this one. This is pretty much the idea.

### Users

Tweet object embeds [User][users] object, so let's create fields support and case classes for it too.

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

Replace `Tweet`'s `user` field with `User`.

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

Now that we have `Tweet` and `User`, we should be close to getting normal statuses. See [`GET statuses/home_timeline`][home_timeline].

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

Let's try using this:

```scala
scala> val x = http(client(Status.home_timeline.count(2)) OK as.json4s.Json)
x: dispatch.Future[org.json4s.JValue] = scala.concurrent.impl.Promise$DefaultPromise@42d2d985

scala> x()
res1: org.json4s.JValue = 
JArray(List(JObject(List((created_at,JString(Tue May 07 08:06:09 +0000 2013)), (id,JInt(...
```

Since this returns an array of tweets, we can convert the result into `List[Tweet]`. The following goes into `response` package:

```scala
object Tweets extends Parse {
  def apply(js: JValue): List[Tweet] =
    parse_![List[JValue]](js) map { x => Tweet(x) }
}
```

And here are the converters:

```scala
package object response {
  ....
  val Tweets: Response => List[response.Tweet] = Json andThen response.Tweets.apply
  val Statuses: Response => List[response.Tweet] = Tweets
  val Tweet: Response => response.Tweet = Json andThen response.Tweet.apply
  val Status: Response => response.Tweet = Tweet
}
```

We got the timelines.

```scala
scala> val x = http(client(Status.home_timeline) OK as.repatch.twitter.response.Tweets)
x: dispatch.Future[repatch.twitter.response.Statuses] = scala.concurrent.impl.Promise$DefaultPromise@41ad625a

scala> x()
res0: List[repatch.twitter.response.Tweet] = 
List(Tweet(331691122629951489,Partially applying a function that has an implicit parameter http://t.co/CwWQAkkBAN,....
```

### Sending tweets

Sending tweets is also simple. See [`POST statuses/update`][update].

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

Here's how to use it.

```scala
scala> val x = http(client(Status.update("testing from REPL")) OK as.json4s.Json)
x: dispatch.Future[org.json4s.JValue] = scala.concurrent.impl.Promise$DefaultPromise@65056d18

scala> x()
res4: org.json4s.JValue = JObject(List((user,JObject(List((time_zone,JString(Eastern Time (US & Canada))), (created_at,JString(Fri Dec 22 15:19:02 +0000 2006)), (default_profile_image,JBool(false)), (name,JString(eugene yokota))...
```

A friend replied to the above tweet.

<blockquote class="twitter-tweet"><p>@<a href="https://twitter.com/eed3si9n">eed3si9n</a> working on your own twitter bot?</p>&mdash; Lord Omlette (@LordOmlette) <a href="https://twitter.com/LordOmlette/status/331722441514708992">May 7, 2013</a></blockquote>

Let's send him a reply, but this time getting the result as a `Tweet`.

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

### summary

Dispatch Reboot by design encourages separating concerns, namely request building, and response processing. For repatch-twitter, we defined `request.Search` case class for building [`GET search/tweets`][search] requests, and `response.Search` for processing the response. Instead of defining various symbolic operators for each resource type, new Dispatch handles them by converters under defined under `dispatch.as.*` package. Because the response processing is separated from request building, the app developer can always opt to use just the request objects and fall back to raw json parsing.

In general, it's important to consider the user experience of the plugin from the app developer's point of view. The usage code should be readable even if the person is not familiar with Dispatch or your plugin.

On the other hand, the we have more freedom in the implementation. That doesn't mean it doesn't have to be readable, but you can be more daring. For example, we implemented mini DSL by injecting `apply[A]` method to `Symbol`, and abstracted reading and writing using Scalaz-like typeclass. This could be cryptic to read for the unacquainted, but easy to maintain.

The source written in this post is available on github as [eed3si9n/repatch-twitter](https://github.com/eed3si9n/repatch-twitter).

<script async src="//platform.twitter.com/widgets.js" charset="utf-8"></script>
