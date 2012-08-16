  [akka]: http://doc.akka.io/docs/akka/2.0.2/intro/getting-started-first-scala.html
  [amazon]: http://www.amazon.co.jp/dp/4798125415
  [amazon2]: http://www.amazon.co.jp/exec/obidos/ASIN/4797337206/tyano-22/

ここ数日かけて tetrix をゼロから実装してきた。初めに僕はこのゲームを使って新しい考え方とかを試してみるという話をした。既に Scala で tetrix は一度書いたことがあるから Scala だけじゃ僕にとっては目新しいものではない。今回 tetrix を使って考えてみたかったのは並行処理 (concurrency) の取り扱いだ。

### 並行処理

Goetz の Java Concurrency in Practice ([Java並行処理プログラミング][amazon2]) を引用すると:

> スレッドセーフなコードを書くということは、その本質において、**状態**、特に**共有された可変状態**へのアクセスを管理することにある。

調度良いことに、僕達は既に tetrix の中身をリファクタリングして、それぞれの操作はある `GameState` から別の状態への遷移関数であるように書き換えた。以下に簡易化した `AbstractUI` を見てみる:

<scala>
package com.eed3si9n.tetrix

class AbstractUI {
  import Stage._
  import java.{util => ju}
  
  private[this] var state = newState(...)
  private[this] val timer = new ju.Timer
  timer.scheduleAtFixedRate(new ju.TimerTask {
    def run { state = tick(state) }
  }, 0, 1000)
  def left() {
    state = moveLeft(state)
  }
  def right() {
    state = moveRight(state)
  }
  def view: GameView = state.view
}
</scala>

タイマーは `tick(state)` を呼び出して `state` を変更し、プレーヤーもまた `moveLeft(state)` や `moveRight(state)` を呼び出して `state` を変更することができる。これは教科書に出てくるようなスレッド・アンセーフな例だ。以下にタイマースレッドと swing のイベントディスパッチスレッドの不幸な実行例を見てみる:

<code>
タイマースレッド: 共有された state を読み込む。現在のピースは (5, 18) にある
イベントスレッド: 共有された state を読み込む。現在のピースは (5, 18) にある
タイマースレッド: tick() 関数を呼び出す
タイマースレッド: tick() は現在のピースが (5, 17) にある新しい状態を返す
イベントスレッド: moveLeft() 関数を呼び出す
イベントスレッド: moveLeft() は現在のピースが (4, 18) にある新しい状態を返す
イベントスレッド: 新しい状態を共有された state に書き込む。現在のピースは (4, 18) にある
タイマースレッド: 新しい状態を共有された state に書き込む。現在のピースは (5, 17) にある
</code>

プレーヤーから見ると、左への動きが完全に無視されたか、もしくはピースが一瞬 `(4, 18)` から `(5, 17)` へ斜めへジャンプしたように見える。これが競合状態だ。

### synchronized

この場合、各タスクが短命で、かつシンプルな可変性のため、`state` に同期をかけるだけでうまくいくかもしれない。

<scala>
package com.eed3si9n.tetrix

class AbstractUI {
  import Stage._
  import java.{util => ju}
  
  private[this] var state = newState(...)
  private[this] val timer = new ju.Timer
  timer.scheduleAtFixedRate(new ju.TimerTask {
    def run { updateState {tick} }
  }, 0, 1000)
  def left()  = updateState {moveLeft}
  def right() = updateState {moveRight}
  def view: GameView = state.view
  private[this] def updateState(trans: GameState => GameState) {
    synchronized {
      state = trans(state)
    }
  }
}
</scala>

`synchronized` 節を用いることで、`state` の読み込みと書き込みが atomic に行われることが保証される。この方法はもし可変性が広範囲に渡っていたり、バックグラウンドでの長期のタスクが必要な場合は実用的じゃないかもしれない。

### akka

並行性を管理するもう一つの方法は Akka アクターのようなメッセージパッシングフレームワークを用いることだ。アクターの入門としては英語だと [Getting Started Tutorial (Scala): First Chapter][akka]のチュートリアルをたどっていくだけでアクターが書けるようになる。日本語だと [Scala 逆引きレシピ][amazon]の第9章「175: Akkaで並行処理を行いたい」などが参考になる。

まず `"akka-actor"` を sbt に追加する:

<scala>
    resolvers ++= Seq(
      "sonatype-public" at "https://oss.sonatype.org/content/repositories/public",
      "Typesafe Repository" at "http://repo.typesafe.com/typesafe/releases/")

...

  lazy val library = Project("library", file("library"),
    settings = buildSettings ++ Seq(
      libraryDependencies ++= Seq(
        "org.specs2" %% "specs2" % "1.12" % "test",
        "com.typesafe.akka" % "akka-actor" % "2.0.2")
    ))
</scala>

次に actors.scala を始めて、メッセージ型を定義する。

<scala>
sealed trait StageMessage
case object MoveLeft extends StageMessage
case object MoveRight extends StageMessage
case object RotateCW extends StageMessage
case object Tick extends StageMessage
case object Drop extends StageMessage
case object View extends StageMessage
</scala>

メッセージを処理するための `StageActor` を定義する。

<scala>
class StageActor(s0: GameState) extends Actor {
  import Stage._

  private[this] var state: GameState = s0

  def receive = {
    case MoveLeft  => state = moveLeft(state)
    case MoveRight => state = moveRight(state)
    case RotateCW  => state = rotateCW(state)
    case Tick      => state = tick(state)
    case Drop      => state = drop(state)
    case View      => sender ! state.view
  }
}
</scala>

これで抽象UI を再配線して内部で Akka アクターを使うように書き換えることができる:

<scala>
package com.eed3si9n.tetrix

class AbstractUI {
  import akka.actor._
  import akka.pattern.ask
  import akka.util.duration._
  import akka.util.Timeout
  import akka.dispatch.{Future, Await}
  import scala.collection.immutable.Stream
  implicit val timeout = Timeout(1 second)

  private[this] val initialState = Stage.newState(Block((0, 0), TKind) :: Nil,
    randomStream(new util.Random))
  private[this] val system = ActorSystem("TetrixSystem")
  private[this] val playerActor = system.actorOf(Props(new StageActor(
    initialState)), name = "playerActor")
  private[this] val timer = system.scheduler.schedule(
    0 millisecond, 1000 millisecond, playerActor, Tick)
  private[this] def randomStream(random: util.Random): Stream[PieceKind] =
    PieceKind(random.nextInt % 7) #:: randomStream(random)

  def left()  { playerActor ! MoveLeft }
  def right() { playerActor ! MoveRight }
  def up()    { playerActor ! RotateCW }
  def down()  { playerActor ! Tick }
  def space() { playerActor ! Drop }
  def view: GameView =
    Await.result((playerActor ? View).mapTo[GameView], timeout.duration)
}
</scala>

これで可変性は `playerActor` で保護され、これは一度に一つづつのメッセージを取り扱うことが保証されている。また、タイマーがスケジュールに置き換えられたことにも注意してほしい。全般的に、メッセージパッシングを使うことで並行処理における振る舞いをより手軽に推論できるようになったと思う。

### ゲームステータス

小さくてもいいから何か機能も追加しよう。新しいピースの転送処理の時に既存のブロックに対する当たり判定が行われていない。もし新しいピースに当たりが検知された場合はゲームは終了するべきだ。以下がスペックになる:

<scala>
  "Spawning a new piece should"                             ^
    """end the game it hits something."""                   ! spawn1^

...

  def spawn1 =
    Function.chain(Nil padTo (10, drop))(s1).status must_==
    GameOver
</scala>

コンパイルが通るように `GameStatus` トレイトから定義していく:

<scala>
sealed trait GameStatus
case object ActiveStatus extends GameStatus
case object GameOver extends GameStatus
</scala>

これを `GameStatus` に追加すると期待通りテストが失敗するようになった:

<code>
[info] Spawning a new piece should
[error] x end the game it hits something.
[error]    'ActiveStatus' is not equal to 'GameOver' (StageSpec.scala:29)
</code>

`spawn` の現行の実装は `nextPiece` を当たり判定無しで取り込んでいる:

<scala>
  private[this] lazy val spawn: GameState => GameState =
    (s: GameState) => {
    def dropOffPos = (s.gridSize._1 / 2.0, s.gridSize._2 - 2.0)
    val next = Piece((2, 1), s.kinds.head)
    val p = s.nextPiece.copy(pos = dropOffPos)
    s.copy(blocks = s.blocks ++ p.current,
      currentPiece = p, nextPiece = next, kinds = s.kinds.tail)
  }
</scala>

ピースを取り込む前に検証に通そう。

<scala>
  private[this] lazy val spawn: GameState => GameState =
    (s: GameState) => {
    def dropOffPos = (s.gridSize._1 / 2.0, s.gridSize._2 - 2.0)
    val s1 = s.copy(blocks = s.blocks,
      currentPiece = s.nextPiece.copy(pos = dropOffPos),
      nextPiece = Piece((2, 1), s.kinds.head),
      kinds = s.kinds.tail)
    validate(s1) map { case x =>
      x.copy(blocks = load(x.currentPiece, x.blocks))
    } getOrElse {
      s1.copy(blocks = load(s1.currentPiece, s1.blocks), status = GameOver)
    }
  }
</scala>

次に、ステータスが `GameOver` のときは状態遷移を禁止する:

<scala>
  private[this] def transit(trans: Piece => Piece,
      onFail: GameState => GameState = identity): GameState => GameState =
    (s: GameState) => s.status match {
      case ActiveStatus =>
        // do transition  
      case _ => s
    }
</scala>

プレーヤにも一言言っておく。

<scala>
    view.status match {
      case GameOver =>
        g setColor bluishSilver
        g drawString ("game over",
          12 * (blockSize + blockMargin), 7 * (blockSize + blockMargin))
      case _ => // do nothing
    }
</scala>

<img src="/images/tetrix-in-scala-day4.png"/>

いつもどおり、コードは github にある:

<code>
$ git fetch origin
$ git co day4 -b try/day4
$ sbt "project swing" run
</code>
