  [day4]: http://eed3si9n.com/tetrix-in-scala-day4

[昨日][day4]はゲームの状態への並行処理を管理するために Akka アクターを入れた。抽象 UI を見てみよう:

<scala>
package com.eed3si9n.tetrix

class AbstractUI {
  // skipping imports...
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

### ロックしすぎ

振り返ってみると上の実装は良いものとは言えない。プログラムが「恥ずかしいほど直列」なものになってしまっているからだ。以前の `synchronized` を使った実装では swing UI がビューを一秒間に 10回問い合わせることができた。この実装でも同じことが行われているけど、他のメッセージと同じメールボックスに入ったため、一つでも演算が 100 ミリ秒以上かかるとメールボックスが溢れてしまう可能性がある。

理想的にはゲームの状態は、新しい状態が上書きされるその瞬間まではロックをかけるべきではない。プレーヤーによる操作とスケジュールされた時計は常に非互換であるので、今のところはこれらを一つづつ処理するのは理にかなっていると思う。

2つ目のアクターのメッセージ型を定義しよう:

<scala>
sealed trait StateMessage
case object GetState extends StateMessage
case case SetState(s: GameState) extends StateMessage
case object GetView extends StateMessage
</scala>

このアクターの実装は単純なものだ:

<scala>
class StateActor(s0: GameState) extends Actor {
  private[this] var state: GameState = s0
  
  def receive = {
    case GetState    => sender ! state
    case SetState(s) => state = s
    case GetView     => sender ! state.view
  }
}
</scala>

次に、`StageActor` を `StateActor` に基いて書き換える必要がある。

<scala>
class StageActor(stateActor: ActorRef) extends Actor {
  import Stage._

  def receive = {
    case MoveLeft  => updateState {moveLeft}
    case MoveRight => updateState {moveRight}
    case RotateCW  => updateState {rotateCW}
    case Tick      => updateState {tick}
    case Drop      => updateState {drop}
  }

  private[this] def updateState(trans: GameState => GameState) {
    val future = (stateActor ? GetState)(1 second).mapTo[GameState]
    val s1 = Await.result(future, 1 second)
    val s2 = trans(s1)
    stateActor ! SetState(s2)
  }
}
</scala>

最後に抽象UI を少し変えて `stateActor` を作成する:

<scala>
package com.eed3si9n.tetrix

class AbstractUI {
  // skipping imports...
  implicit val timeout = Timeout(100 millisecond)

  private[this] val initialState = Stage.newState(Block((0, 0), TKind) :: Nil,
    randomStream(new util.Random))
  private[this] val system = ActorSystem("TetrixSystem")
  private[this] val stateActor = system.actorOf(Props(new StateActor(
    initialState)), name = "stateActor")
  private[this] val playerActor = system.actorOf(Props(new StageActor(
    stateActor)), name = "playerActor")
  private[this] val timer = system.scheduler.schedule(
    0 millisecond, 700 millisecond, playerActor, Tick)
  private[this] def randomStream(random: util.Random): Stream[PieceKind] =
    PieceKind(random.nextInt % 7) #:: randomStream(random)

  def left()  { playerActor ! MoveLeft }
  def right() { playerActor ! MoveRight }
  def up()    { playerActor ! RotateCW }
  def down()  { playerActor ! Tick }
  def space() { playerActor ! Drop }
  def view: GameView =
    Await.result((stateActor ? GetView).mapTo[GameView], timeout.duration)
}
</scala>

タイマーの時計とプレーヤーのによるピースの移動の並行処理は引き続き `playerActor` によって保護される。しかし、これで swing UI は他の処理を待たずに好きなだけビューを読み込めるようになった。

### グリッドのサイズ

何度かプレイしてみると、新しいピースの転送ポイントが低いため実質のサイズが 10x20 よりもずっと小さくなっていることに気付いた。これを回避するにはグリッドのサイズを上に伸ばして、下の 20行だけ swing UI で表示するようにすればいいと思う。数字を変えたくないのでスペックでは 10x20 のままとする。`newState` が `gridSize` を受け取るようにする:

<scala>
  def newState(blocks: Seq[Block], gridSize: (Int, Int),
      kinds: Seq[PieceKind]): GameState = ...
</scala>

あとの変更は swing UI だ。表示用に短くした `gridSize` を渡す:

<scala>
    drawBoard(g, (0, 0), (10, 20), view.blocks, view.current)
    drawBoard(g, (12 * (blockSize + blockMargin), 0),
      view.miniGridSize, view.next, Nil)
</scala>

次に範囲内のブロックだけに filter をかける:

<scala>
    def drawBlocks {
      g setColor bluishEvenLigher
      blocks filter {_.pos._2 < gridSize._2} foreach { b =>
        g fill buildRect(b.pos) }
    }
    def drawCurrent {
      g setColor bluishSilver
      current filter {_.pos._2 < gridSize._2} foreach { b =>
        g fill buildRect(b.pos) }
    }
</scala>

これで新しく転送されたピースはグリッドの上端から忍び寄ってくる。

<img src="/images/tetrix-in-scala-day5.png"/>

いつもどおり、コードは github にある:

<code>
$ git fetch origin
$ git co day5 -b try/day5
$ sbt "project swing" run
</code>
