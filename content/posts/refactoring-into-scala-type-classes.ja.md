---
title:       "Scala 型クラスへのリファクタリング"
type:        story
date:        2010-11-03
changed:     2010-11-06
draft:       false
promote:     true
sticky:      false
url:         /ja/refactoring-into-scala-type-classes
aliases:     [ /node/16 ]

# Summary:
# 二週間ほど前に Scala の暗黙の(implicit)パラメータを用いた[型クラスの実装](http://eed3si9n.com/ja/scala-implicits-type-classes)について書いた．型クラスはある抽象体(abstraction)についての直交した関心事を，抽象体そのものに直接組み込むことなくモデル化することができる．これでコアな抽象体から余計なものを取り去って，別々の独立したクラス構造に変えていくことができる．最近 [Akka](http://akkasource.org/) actor のシリアライゼーションをリファクタリングして型クラスの恩恵に関する実地的な知見を得ることができたので，ここに報告したい．
# 

---
<!--break-->
> Debasish Ghosh さん ([@debasishg](http://twitter.com/debasishg)) の "[Refactoring into Scala Type Classes](http://debasishg.blogspot.com/2010/07/refactoring-into-scala-type-classes.html)" を翻訳しました．
> 元記事はこちら: [http://debasishg.blogspot.com/2010/07/refactoring-into-scala-type-classes.html](http://debasishg.blogspot.com/2010/07/refactoring-into-scala-type-classes.html)
> (翻訳の公開は本人より許諾済みです)
> 翻訳の間違い等があれば遠慮なくご指摘ください．

二週間ほど前に Scala の暗黙の(implicit)パラメータを用いた[型クラスの実装](http://eed3si9n.com/ja/scala-implicits-type-classes)について書いた．型クラスはある抽象体(abstraction)についての直交した関心事を，抽象体そのものに直接組み込むことなくモデル化することができる．これでコアな抽象体から余計なものを取り去って，別々の独立したクラス構造に変えていくことができる．最近 [Akka](http://akkasource.org/) actor のシリアライゼーションをリファクタリングして型クラスの恩恵に関する実地的な知見を得ることができたので，ここに報告したい．

### 最初は継承と trait でうまくいくと思った...
... しかし，それは長続きしなかった．Jonas Boner と筆者の間で actor のシリアライゼーションに関して面白い論議があり，以下のような設計が生まれた ...

<scala>trait SerializableActor extends Actor 
trait StatelessSerializableActor extends SerializableActor

trait StatefulSerializerSerializableActor extends SerializableActor {
  val serializer: Serializer
  //..
}

trait StatefulWrappedSerializableActor extends SerializableActor {
  def toBinary: Array[Byte]
  def fromBinary(bytes: Array[Byte])
}

// .. 以下続く
</scala>

このような trait はシリアライゼーションという関心事をコアな actor の実装と結合(couple)させすぎてしまう．様々なシリアライズ可能な actor があるため，良いクラス名が足りなくなってきていた．GoF本が教えてくれる知恵の一つにインターフェイスを用いたクラスの命名に困るとしたら，間違ったことをやっている，というものがある．関心事をより意味のある方法で分割する別のやり方を探ろう．

### 型クラスだ
コアの actor 抽象体からシリアライゼーションに関するコードを抜き出し，別の型クラスにした．

<scala>/**
 * Actor 直列化のための型クラス定義
 */
trait FromBinary[T <: Actor] {
  def fromBinary(bytes: Array[Byte], act: T): T
}

trait ToBinary[T <: Actor] {
  def toBinary(t: T): Array[Byte]
}

// クライアントはそれぞれの Actor のための Format[] を実装する必要がある
trait Format[T <: Actor] extends FromBinary[T] with ToBinary[T]
</scala>

actor をシリアライズ可能にするためにクライアントが実装する必要がある `FromBinary[T <: Actor]` と `ToBinary[T <: Actor]` という二つの型クラスを定義した．これをさらに `Format[T <: Actor]` という二つを合わせた trait に組み合わせた．

次に，これらの型クラスを使って actor をシリアライズするための API を公開するモジュールを定義した．

<scala>/**
 * Actor 直列化のためのモジュール
 */
object ActorSerialization {

  def fromBinary[T <: Actor](bytes: Array[Byte])
    (implicit format: Format[T]): ActorRef = //..

  def toBinary[T <: Actor](a: ActorRef)
    (implicit format: Format[T]): Array[Byte] = //..

  //.. 実装
}</scala>

これらの型クラスは Scala コンパイラにより直近の構文スコープより探し出され，暗黙の引数として暗黙の(implicit)パラメータに渡されることに注目してほしい．以上の戦略を試すテストケースを考えてみよう...

カプセル化された状態を保持した actor を考える．特殊な actor クラスから継承するというような副次的な複雑さが無くなっていることに注目してほしい...

<scala>class MyActor extends Actor {
  var count = 0

  def receive = {
    case "hello" =>
      count = count + 1
      self.reply("world " + count)
  }
}</scala>

そして，クライアントはプロトコルバッファを使ってシリアライゼーションの型クラスを実装して，それを Scala モジュールとして公開するとする...

<scala>object BinaryFormatMyActor {
  implicit object MyActorFormat extends Format[MyActor] {
    def fromBinary(bytes: Array[Byte], act: MyActor) = {
      val p = Serializer.Protobuf
                        .fromBinary(bytes, Some(classOf[ProtobufProtocol.Counter]))
                        .asInstanceOf[ProtobufProtocol.Counter]
      act.count = p.getCount
      act
    }
    def toBinary(ac: MyActor) =
      ProtobufProtocol.Counter.newBuilder.setCount(ac.count).build.toByteArray
  }
}</scala>

上記の型クラスの実装を利用するテストコードはこうなる...

<scala>import ActorSerialization._
import BinaryFormatMyActor._

val actor1 = actorOf[MyActor].start
(actor1 !! "hello").getOrElse("_") should equal("world 1")
(actor1 !! "hello").getOrElse("_") should equal("world 2")

val bytes = toBinary(actor1)
val actor2 = fromBinary(bytes)
actor2.start
(actor2 !! "hello").getOrElse("_") should equal("world 3")</scala>

actor の内部状態は `toBinary` によって正しくシリアライズされ，次に Actor の内部状態にデシリアライズされている．

このリファクタリングによりコアの actor の実装からシリアライゼーションという関心事を別の抽象体に追い出すことでかなりスッキリさせることができた．クライアントのコードはクライアントの actor の定義が actor の状態がシリアライズされる詳細を含めなくてもいいという意味においてスッキリしたと言えるだろう．Scala の暗黙の引数と実行可能なモジュールという機能がこのような型クラスに基づいた実装を可能とした．
