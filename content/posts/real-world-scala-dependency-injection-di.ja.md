---
title:       "実戦での Scala: Cake パターンを用いた Dependency Injection (DI) "
type:        story
date:        2011-04-23
changed:     2011-04-24
draft:       false
promote:     true
sticky:      false
url:         /ja/real-world-scala-dependency-injection-di
aliases:     [ /node/31 ]
---

> Akka の作者として益々注目を集めている [Jonas Bonér](http://jonasboner.com/) が 2008年に書いた "[Real-World Scala: Dependency Injection (DI)](http://jonasboner.com/2008/10/06/real-world-scala-dependency-injection-di.html)" を翻訳しました。翻訳の公開は本人より許諾済みです。翻訳の間違い等があれば遠慮なくご指摘ください。

2008年10月6日 Jonas Bonér 著
2011年4月22日 eed3si9n 訳

さて、実戦での Scala シリーズ第二弾の今回は、Scala を用いた [Depenency Injection (DI)](http://kakutani.com/trans/fowler/injection.html) の実装をみていきたい。Scala は、備わっている言語機構だけを用いても何通りかの DI を実現できる非常に豊かでディープな言語だが、必要に応じて既存の Java DI フレームワークを使うこともできる。

[Triental](http://www.triental.com/) では、一つの戦略に落ち着くまで三つの異なる方法を試した。以下のように話を進めていく。まず、現行の DI の実現方法を詳しく説明した後で、試した他の方法も簡単にカバーする。

## Cake パターンを用いる
私たちが用いている現行の戦略は、いわゆる Cake パターンに基づいている。このパターンは、Martin Odersky の論文 [Scalable Component Abstractions](http://lamp.epfl.ch/~odersky/papers/ScalableComponent.pdf) において、Ordersky と彼のチームが Scala のコンパイラを構成した方法として最初に発表された。このパターンがどのようにして DI を実現するのかということを日本語で説明する事を試みるよりも、（私たちの実際に使っているコードに大まかに基づいた）愚直なサンプルコードをみてみよう。

注意:
順を追って、最終バージョンに向けてリファクタリングしながら説明していくので、最終バージョンを読んで理解するまでは、「ダメじゃん!」と叫ぶのは待ってほしい（もちろん、読了後にどうしてもと言うなら批判、賞賛、意見、アイディアなどを送ってもいい）。また、このサンプルコードは、このようなサンプルの例にもれず、非常に複雑な方法で取るに足りない事を行っているようにみえるが、我慢して大規模システムでの実際のサービスを想像して、どのように応用できるかを想像して欲しい。

まずは、`UserRepository` (DAO、Data Access Object) を実装しよう。

<scala>
// 実際の永続化は何もしていなくて、画面にユーザを表示するだけのダミー。 
class UserRepository {  
  def authenticate(user: User): User = {   
    println("authenticating user: " + user)  
    user  
   }  
  def create(user: User) = println("creating user: " + user)  
  def delete(user: User) = println("deleting user: " + user)  
}</scala>

trait インターフェイスとその実装に分けて実装することもできたが、話を簡単にするために、敢えてここではそうしなかった。

次に、ユーザサービスを作成しよう（これも、単にリポジトリへ委譲するだけのダミーだ）。

<scala>
class UserService {  
  def authenticate(username: String, password: String): User =   
    userRepository.authenticate(new User(username, password))    
  
  def create(username: String, password: String) =   
    userRepository.create(new User(username, password))  
  
  def delete(user: User) =    
    userRepository.delete(user)  
}</scala>

ここで `UserRepository` のインスタンスが参照されている。これが、インジェクト (inject、注入)[^1] されて欲しい依存オブジェクトだ。

  [^1]: 訳注: 依存性を注入することを、「インジェクトする」というのは、[Inversion of Control コンテナと Dependency Injection パターン](http://kakutani.com/trans/fowler/injection.html#InversionOfControl) のかくたに氏の訳にならった。

面白くなるのはここからだ。`UserRepository` を包囲 trait でラッピングして、そこでユーザリポジトリのインスタンスを生成してみよう。

<scala>
trait UserRepositoryComponent {  
  val userRepository = new UserRepository  
  class UserRepository {  
    def authenticate(user: User): User = {   
      println("authenticating user: " + user)  
      user  
    }  
    def create(user: User) = println("creating user: " + user)  
    def delete(user: User) = println("deleting user: " + user)  
  }  
}</scala>

これによってリポジトリのコンポーネント名前空間が作成される。どうしてかって？　続きを読んでくれれば、この名前空間がどう役立つのかすぐに説明する。

まず、このリポジトリの利用者である `UserService` に注目してほしい。`userRepository` インスタンスを `UserService` にインジェクトしてほしいという事を宣言するためには、まず上でリポジトリでしたことを繰り返す。つまり、包囲（名前空間） trait でラッピングする。そして、[自分型アノテーション (self-type annotation)](http://www.scala-lang.org/node/124) を用いて `UserRepository` への依存性を宣言する。こう書くとややこしそうだが、コードを見ればそうでもない。

<scala>
// 自分型アノテーションを用いてこのコンポーネントの依存性、
// この場合 UserRepositoryComponent を宣言する。
trait UserServiceComponent { this: UserRepositoryComponent =>  
  val userService = new UserService    
  class UserService {  
    def authenticate(username: String, password: String): User =   
      userRepository.authenticate(username, password)    
    def create(username: String, password: String) =   
      userRepository.create(new User(username, password))  
    def delete(user: User) = userRepository.delete(user)  
  }  
}</scala>

自分型アノテーションとはここの部分だ:

<scala>
this: UserRepositoryComponent =>  </scala>

複数の依存性を宣言するには以下のように記述する:

<scala>
this: Foo with Bar with Baz =>  </scala>

これで、`UserRepository` の依存性の宣言をすることができた。残りは、実際の配線だ。

そのためには異なる名前空間を一つのアプリケーション（もしくは、レジストリ）名前空間に合併させるだけだ。これは全てのコンポーネントから構成されるレジストリ・オブジェクトを作成することで達成される。その時に全ての配線は自動的に行われる。

<scala>
object ComponentRegistry extends  
  UserServiceComponent with  
  UserRepositoryComponent  </scala>

この方法の美点として、全ての配線が静的に型付けされていることが挙げられる。例えば、依存性の宣言が欠けていたり、誤字があったり、何かが間違っていれば、それはコンパイルエラーとなる。また、これはとても高速だ。

もう一つの美点は、（全ての依存性は `val` で宣言されているため）全てが不変 (immutable) であるということだ。

アプリケーションを使用するためには、レジストリ・オブジェクトから「最上位」サービスを取り出すだけでいい。（Guice や Spring 同様に）他の依存性は自動的に配線が行われる。

<scala>
val userService = ComponentRegistry.userService  
...  
val user = userService.authenticate(..)   </scala>

順調かな？

いや、ちょっと。ダメじゃん、これ。

サービスの実装と作成が密結合だし、配線構成 (wiring configuration) はコードのアチコチに散らばってるし、ガチガチに硬直すぎる。

直しましょう。

サービスを包囲（名前空間）trait 内でインスタンスを生成せずに、抽象メンバーに変更する。

<scala>
trait UserRepositoryComponent {  
  val userRepository: UserRepository  
  
  class UserRepository {  
    ...  
  }  
}   </scala>

<scala>
trait UserServiceComponent {   
  this: UserRepositoryComponent =>   
  
  val userService: UserService    
  
  class UserService {  
    ...   
  }  
}</scala>

これで、サービスのインスタンスの生成（と設定）を `ComponentRegistry` モジュールに移すことができる。

<scala>
object ComponentRegistry extends   
  UserServiceComponent with   
  UserRepositoryComponent   
{  
  val userRepository = new UserRepository  
  val userService = new UserService  
}  </scala>

こうすることで、実際のコンポーネントのインスタンスの生成とその配線を単一の構成オブジェクト (configuration object) に抽象化することができた。

ここで巧妙なのが、サービスの異なる実装に切り替えることができることだ（もし、インターフェイス trait と複数の実装があればの話だが）。しかし、さらに興味深いのは trait の組み合わせにより複数の「世界」もしくは「環境」を構成できることだ。

具体例で説明するために、ここで単体テストのための「テスト環境」を作成する。

実際のサービスのインスタンスを生成する代わりに、それぞれに対してモックオブジェクト (mock) を作成することにする。また、ここでは、「世界」を trait に変更する（何故かは、すぐに説明する）。

<scala>
trait TestingEnvironment extends  
  UserServiceComponent with  
  UserRepositoryComponent with   
  org.specs.mock.JMocker  
{  
  val userRepository = mock(classOf[UserRepository])  
  val userService = mock(classOf[UserService])  
}   </scala>

ここでは、モックオブジェクトを作成しただけではなく、作成されたモックオブジェクトは宣言された依存性へと結合されている。

次が、面白い所だ。全てのモックオブジェクトを持つ `TestEnvironment` を mix in して単体テストを作成してみよう。

<scala>
class UserServiceSuite extends TestNGSuite with TestEnvironment {  
  
  @Test { val groups=Array("unit") }  
  def authenticateUser = {  
  
    // 新たにクリーンな (非モックの) UserService を作成する。   
    // (依存オブジェクトの userRepository はモックだ)  
    val userService = new UserService  
  
    // モック呼び出しを記録する 
    expect {  
      val user = new User("test", "test")  
      one(userRepository).authenticate(user) willReturn user  
    }  
      
    ... // authentication メソッドをテストする  
  }  
    
  ...  
}  </scala>

この例で全て言い尽くしたが、これも必要に応じて構成できるコンポーネントの一例にすぎない。

## 他の方法

Scala で DI を行う他の方法もみていこう。この記事は既に長くなってきているので、それぞれのテクニックに関しては簡単に流していくが、理解するのには十分だと思う。以下の例に関しては、簡単に理解して比較できるように同一のダミープログラムを使用した（Scala User メーリングリストで見つけたものだ）。全ての例は Scala インタープリタに貼りつけて試すことができる。

## 構造的部分型を用いる

少し前に Jamie Webb により Scala User メーリングリストに投稿された次のテクニックは[構造的部分型 (structural typing)](http://d.hatena.ne.jp/yuroyoro/20110126/1296044588) を用いる。この方法は結構好きだ。エレガントで、不変で、型安全だ。

<scala>
// =======================  
// サービスインターフェイス  
trait OnOffDevice {  
  def on: Unit  
  def off: Unit  
}  
trait SensorDevice {  
  def isCoffeePresent: Boolean  
}  
  
// =======================  
// サービス実装
class Heater extends OnOffDevice {  
  def on = println("heater.on")  
  def off = println("heater.off")  
}  
class PotSensor extends SensorDevice {  
  def isCoffeePresent = true  
}  
  
// =======================  
// 構造的部分型を用いて二つの依存オブジェクトへの
// 依存性を宣言したサービス 
class Warmer(env: {  
  val potSensor: SensorDevice  
  val heater: OnOffDevice  
}) {  
  def trigger = {  
    if (env.potSensor.isCoffeePresent) env.heater.on  
    else env.heater.off  
  }  
}  
  
class Client(env : { val warmer: Warmer }) {  
  env.warmer.trigger  
}  
  
// =======================  
// 構成モジュールにおいてサービスのインスタンスを生成する 
object Config {  
  lazy val potSensor = new PotSensor  
  lazy val heater = new Heater  
  lazy val warmer = new Warmer(this) // this is where injection happens  
}  
  
new Client(Config)  </scala>

## 暗黙の (implicit) パラメータを用いる

この方法は単純明快だ。しかし、実際の配線 (暗黙の値を import する)　が散らばってて、アプリケーションのコードとからまっているのは好みではない。

<scala>
// =======================  
// サービスインターフェイス
trait OnOffDevice {  
  def on: Unit  
  def off: Unit  
}  
trait SensorDevice {  
  def isCoffeePresent: Boolean  
}  
  
// =======================  
// サービス実装
class Heater extends OnOffDevice {  
  def on = println("heater.on")  
  def off = println("heater.off")  
}  
class PotSensor extends SensorDevice {  
  def isCoffeePresent = true  
}  
  
// =======================  
// 二つの依存オブジェクトへの依存性を宣言したサービス  
class Warmer(  
  implicit val sensor: SensorDevice,   
  implicit val onOff: OnOffDevice) {  
  
  def trigger = {  
    if (sensor.isCoffeePresent) onOff.on  
    else onOff.off  
  }  
}  
  
// =======================  
// モジュール内でサービスのインスタンスを生成する 
object Services {  
  implicit val potSensor = new PotSensor  
  implicit val heater = new Heater  
}  
  
// ======================= 
// 構文スコープにサービスを import することで暗黙のパラメータに
// 依存オブジェクトが渡され配線が自動的に行われる
import Services._  
  
val warmer = new Warmer  
warmer.trigger  </scala>

## Google Guice を用いる

Scala は単体の DI フレームワークとも相性が良く、初期には我々は [Google Guice](http://code.google.com/p/google-guice/) を使っていた。Guice は色々は方法で使うことができるが、Jan Kriesten が教えてくれた `ServiceInjector` という巧妙な方法を紹介しよう。

<scala>
// =======================  
// サービスインターフェイス
trait OnOffDevice {  
  def on: Unit  
  def off: Unit  
}  
trait SensorDevice {  
  def isCoffeePresent: Boolean  
}  
trait IWarmer {  
  def trigger  
}  
trait Client  
  
// =======================  
// サービス実装  
class Heater extends OnOffDevice {  
  def on = println("heater.on")  
  def off = println("heater.off")  
}  
class PotSensor extends SensorDevice {  
  def isCoffeePresent = true  
}  
class @Inject Warmer(  
  val potSensor: SensorDevice,   
  val heater: OnOffDevice)   
  extends IWarmer {  
  
  def trigger = {  
    if (potSensor.isCoffeePresent) heater.on  
    else heater.off  
  }  
}  
  
// =======================  
// クライアント  
class @Inject Client(val warmer: Warmer) extends Client {  
  warmer.trigger  
}  
  
// =======================  
// インターフェイスに対する実装の設定を定義する
// Guice の構成クラス
class DependencyModule extends Module {  
  def configure(binder: Binder) = {  
    binder.bind(classOf[OnOffDevice]).to(classOf[Heater])  
    binder.bind(classOf[SensorDevice]).to(classOf[PotSensor])  
    binder.bind(classOf[IWarmer]).to(classOf[Warmer])  
    binder.bind(classOf[Client]).to(classOf[MyClient])  
  }  
}  
  
// =======================  
// 使用例: val bean = new Bean with ServiceInjector  
trait ServiceInjector {  
  ServiceInjector.inject(this)  
}  
  
// ヘルパー・コンパニオン・オブジェクト   
object ServiceInjector {  
  private val injector = Guice.createInjector(  
    Array[Module](new DependencyModule))  
  def inject(obj: AnyRef) = injector.injectMembers(obj)  
}  

// =======================
// インスタンスの生成時に ServiceInjector trait を
// mix in して依存オブジェクトをインジェクトする  
val client = new MyClient with ServiceInjector  
  
println(client)  </scala>

以上で、この記事で書く予定だったことは書き終えた。言語にそなわった抽象化や、単体の DI フレームワークなど、Scala における DI の方法を理解するのに役立っただろうか。どれがうまくいくかは、その時の状況や、要求仕様、そして好みによる。

おまけに、他の DI 戦略と比較し易いように、後半の例の Cake パターンのバージョンを示した。注意して欲しいのが、この素朴な例だけで他の方法と比べると、Cake パターンは包囲（名前空間）trait のせいで必要以上に複雑に見えるが、複数のコンポーネントによる複雑な依存性が出てくる些細ではない例においてその効果を発揮することだ。

<scala>
// =======================  
// サービスインターフェイス
trait OnOffDeviceComponent {  
  val onOff: OnOffDevice  
  trait OnOffDevice {  
    def on: Unit  
    def off: Unit  
  }  
}  
trait SensorDeviceComponent {  
  val sensor: SensorDevice  
  trait SensorDevice {  
    def isCoffeePresent: Boolean  
  }  
}  
  
// =======================  
// サービス実装  
trait OnOffDeviceComponentImpl extends OnOffDeviceComponent {  
  class Heater extends OnOffDevice {  
    def on = println("heater.on")  
    def off = println("heater.off")  
  }  
}  
trait SensorDeviceComponentImpl extends SensorDeviceComponent {  
  class PotSensor extends SensorDevice {  
    def isCoffeePresent = true  
  }  
}  
// =======================  
// 二つの依存オブジェクトへの依存性を宣言したサービス 
trait WarmerComponentImpl {  
  this: SensorDeviceComponent with OnOffDeviceComponent =>  
  class Warmer {  
    def trigger = {  
      if (sensor.isCoffeePresent) onOff.on  
      else onOff.off  
    }  
  }  
}  
  
// =======================  
// モジュール内でサービスのインスタンスを生成する 
object ComponentRegistry extends  
  OnOffDeviceComponentImpl with  
  SensorDeviceComponentImpl with  
  WarmerComponentImpl {  
  
  val onOff = new Heater  
  val sensor = new PotSensor  
  val warmer = new Warmer  
}  
  
// =======================  
val warmer = ComponentRegistry.warmer  
warmer.trigger  </scala>
