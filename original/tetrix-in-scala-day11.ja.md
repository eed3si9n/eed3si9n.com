  [day10]: http://eed3si9n.com/ja/tetrix-in-scala-day10

[昨日][day10]はヒューリスティック関数の色々な部分を調整するためにゲームをスクリプトから自動化するテストハーネスを書いた。最終的にはパフォーマンスを 7 +/- 2 ラインから 34 +/- 8 ラインまで約5倍引き上げることができた。

### HAL 的な瞬間

スクリプトテストばっかりだったので、swing UI のゲームを最後まで見ることにした。ラインを次々と消しながらブロックを低めに押さえていて、ゲームのクオリティーが向上してきたことは初めから感じられた。だいたい 60 ラインぐらいを超えた所でいくつかのミスでブロックが 10 段ぐらいまで積まれてきたが、扱いきれないというほどでは無いと思った。ところが突然のようにピースをドロップし始めた。一つづつ次々と。

エージェントはゲームを放棄したかのようにみえた。後になって気付いたのはアクターのどこかでタイムアウトが生じたせいだろうということだった。

### 可変長思考サイクル

エージェントに定期的に思考するように命令するのではなく、好きなだけ考えさせてあげることにする。人の反射速度と比べてフェアなように取れるアクションは秒あたり 3つぐらいに制限する。

<scala>
sealed trait GameMasterMessage
case object Start

class GameMasterActor(stateActor: ActorRef, agentActor: ActorRef) extends Actor {
  def receive = {
    case Start => loop 
  }
  private[this] def loop {
    val minActionTime = 337
    var s = getState
    while (s.status != GameOver) {
      val t0 = System.currentTimeMillis
      agentActor ! BestMove(getState)
      val t1 = System.currentTimeMillis
      if (t1 - t0 < minActionTime) Thread.sleep(minActionTime - (t1 - t0))
      s = getState
    }
  }
  private[this] def getState: GameState = {
    val future = (stateActor ? GetState)(1 second).mapTo[GameState]
    Await.result(future, 1 second)
  } 
}
</scala>

ゲームのペースを抑えるため、`Drop` は `Tick` に置換する:

<scala>
class AgentActor(stageActor: ActorRef) extends Actor {
  private[this] val agent = new Agent

  def receive = {
    case BestMove(s: GameState) =>
      val message = agent.bestMove(s)
      if (message == Drop) stageActor ! Tick
      else stageActor ! message
  }
}
</scala>

あまりに長考するとエージェントに損なので 1000 ms ぐらいで止めておく:

<scala>
  val maxThinkTime = 1000
  val t0 = System.currentTimeMillis
  ...
  nodes foreach { node =>
    if (System.currentTimeMillis - t0 < maxThinkTime)
      actionSeqs(node.state) foreach { seq =>
        ...
      }
    else ()
  }
</scala>

### 人対マシン

エージェントの調整ができたので、当然次のステップは人間相手にプレイすることだ。同一の初期状態から 2つのステージアクターを用意しよう。一つはプレーヤにより制御され、もう一つはエージェントにより制御される。

<scala>
  private[this] val initialState = Stage.newState(Nil,
    (10, 23), Stage.randomStream(new util.Random))
  private[this] val system = ActorSystem("TetrixSystem")
  private[this] val stateActor1 = system.actorOf(Props(new StateActor(
    initialState)), name = "stateActor1")
  private[this] val stageActor1 = system.actorOf(Props(new StageActor(
    stateActor1)), name = "stageActor1")
  private[this] val stateActor2 = system.actorOf(Props(new StateActor(
    initialState)), name = "stateActor2")
  private[this] val stageActor2 = system.actorOf(Props(new StageActor(
    stateActor2)), name = "stageActor2")
  private[this] val agentActor = system.actorOf(Props(new AgentActor(
    stageActor2)), name = "agentActor")
  private[this] val masterActor = system.actorOf(Props(new GameMasterActor(
    stateActor2, agentActor)), name = "masterActor")
  private[this] val tickTimer1 = system.scheduler.schedule(
    0 millisecond, 701 millisecond, stageActor1, Tick)
  private[this] val tickTimer2 = system.scheduler.schedule(
    0 millisecond, 701 millisecond, stageActor2, Tick)
  
  masterActor ! Start

  def left()  { stageActor1 ! MoveLeft }
  def right() { stageActor1 ! MoveRight }
  def up()    { stageActor1 ! RotateCW }
  def down()  { stageActor1 ! Tick }
  def space() { stageActor1 ! Drop }
</scala>

現在の `view` は 1つのビューしか返さないため、ペアを返すように変更する。

<scala>
  def views: (GameView, GameView) =
    (Await.result((stateActor1 ? GetView).mapTo[GameView], timeout.duration),
    Await.result((stateActor2 ? GetView).mapTo[GameView], timeout.duration))
</scala>

次に swing UI が両方のビューを描画できるようにする。

<scala>
  def onPaint(g: Graphics2D) {
    val (view1, view2) = ui.views
    val unit = blockSize + blockMargin
    val xOffset = mainPanelSize.width / 2
    drawBoard(g, (0, 0), (10, 20), view1.blocks, view1.current)
    drawBoard(g, (12 * unit, 0), view1.miniGridSize, view1.next, Nil)
    drawStatus(g, (12 * unit, 0), view1)
    drawBoard(g, (xOffset, 0), (10, 20), view2.blocks, view2.current)
    drawBoard(g, (12 * unit + xOffset, 0), view2.miniGridSize, view2.next, Nil)
    drawStatus(g, (12 * unit + xOffset, 0), view2)
  }
  def drawStatus(g: Graphics2D, offset: (Int, Int), view: GameView) {
    val unit = blockSize + blockMargin
    g setColor bluishSilver
    view.status match {
      case GameOver =>
        g drawString ("game over", offset._1, offset._2 + 8 * unit)
      case _ => // do nothing
    }
    g drawString ("lines: " + view.lineCount.toString, offset._1, offset._2 + 7 * unit)
  }
</scala>

既に `drawBoard` がリファクタ済みだったため、思ったより簡単だった。


<img src="/images/tetrix-in-scala-day11.png"/>

`GameMasterActor` にレフェリーになってもらってどちらかが負けた時点で勝者も決定するようにする。

<scala>
case object Victory extends GameStatus
...

class GameMasterActor(stateActor1: ActorRef, stateActor2: ActorRef,
    agentActor: ActorRef) extends Actor {
  ...

  private[this] def getStatesAndJudge: (GameState, GameState) = {
    var s1 = getState1
    var s2 = getState2
    if (s1.status == GameOver && s2.status != Victory) {
      stateActor2 ! SetState(s2.copy(status = Victory))
      s2 = getState2
    }
    if (s1.status != Victory && s2.status == GameOver) {
      stateActor1 ! SetState(s1.copy(status = Victory))
      s1 = getState1
    }
    (s1, s2)
  }
}
</scala>

ステータスを UI に表示しよう:

<scala>
      case Victory =>
        g drawString ("you win!", offset._1, offset._2 + 8 * unit)
</scala>

こんな感じになる:

<img src="/images/tetrix-in-scala-day11b.png"/>

### 攻撃

今は二人のプレーヤが隣あってゲームをしているのと変りない。攻撃を導入しよう。どちらかのプレーヤが 2つ以上のラインを消した場合は、相手の次の転送サイクルの時点でグリッドの最下行にいくつかのブロックを加える。

ステージのスペックに記述しよう:

<scala>
  "Attacks should"                                          ^
    """increment the pending attack count,"""               ! attack1^
    """and change the blocks in the view on spawn."""       ! attack2^
...
  def attack1 =
    notifyAttack(s1).pendingAttacks must_== 1
  def attack2 =
    Function.chain(notifyAttack :: drop :: Nil)(s1).blocks map {_.pos} must contain(
      (0, 1), (4, 1), (5, 1), (6, 1), (5, 2),
      (4, 18), (5, 18), (6, 18), (5, 19)
    )
</scala>

スタブする:

<scala>
val notifyAttack: GameState => GameState = (s0: GameState) => s0
</scala>

期待通りテストは失敗する:

<scala>
[info] Attacks should
[error] x increment the pending attack count,
[error]    '0' is not equal to '1' (StageSpec.scala:35)
[error] x and change the blocks in the view on a tick.
[error]    '(0,0), (4,17), (5,17), (6,17), (5,18)' doesn't contain in order '(1,0), (4,17), (5,17), (6,17), (5,18)' (StageSpec.scala:36)
</scala>

これが最初の部分:

<scala>
  val notifyAttack: GameState => GameState = (s0: GameState) =>
    s0.copy(pendingAttacks = s0.pendingAttacks + 1)
</scala>

`attack` 関数は `clearFullRow` に似た形になる:

<scala>
  val attackRandom = new util.Random(0L)
  private[this] lazy val attack: GameState => GameState =
    (s0: GameState) => {
    def attackRow(s: GameState): Seq[Block] =
      (0 to s.gridSize._1 - 1).toSeq flatMap { x =>
        if (attackRandom.nextBoolean) Some(Block((x, 0), TKind))
        else None
      }
    @tailrec def tryAttack(s: GameState): GameState =
      if (s.pendingAttacks < 1) s
      else tryAttack(s.copy(
          blocks = (s.blocks map { b => b.copy(pos = (b.pos._1, b.pos._2 + 1)) } filter {
            _.pos._2 < s.gridSize._2 }) ++ attackRow(s),
          pendingAttacks = s.pendingAttacks - 1
        ))
    tryAttack(s0)
  }
</scala>

これは以下のように `tick` に組み込まれる:

<scala>
  val tick = transit(_.moveBy(0.0, -1.0),
    Function.chain(clearFullRow :: attack :: spawn :: Nil) )
</scala>

これでテストは通るようになった:

<code>
[info] Attacks should
[info] + increment the pending attack count,
[info] + and change the blocks in the view on spawn.
</code>

次に `StageActor` を使ってお互いの攻撃を通知する。最後の `tick` で何行のラインが消されたかを `lastDeleted` として報告する:

<scala>
case class GameState(blocks: Seq[Block], gridSize: (Int, Int),
    currentPiece: Piece, nextPiece: Piece, kinds: Seq[PieceKind],
    status: GameStatus = ActiveStatus,
    lineCount: Int = 0, lastDeleted: Int = 0,
    pendingAttacks: Int = 0) {...}
</scala>

新しいメッセージ型の `Attack` を加えて、`StageActor` で通知を実装しよう:

<scala>
case object Attack extends StageMessage

class StageActor(stateActor: ActorRef) extends Actor {
  import Stage._

  def receive = {
    case MoveLeft  => updateState {moveLeft}
    case MoveRight => updateState {moveRight}
    case RotateCW  => updateState {rotateCW}
    case Tick      => updateState {tick}
    case Drop      => updateState {drop}
    case Attack    => updateState {notifyAttack}
  }
  private[this] def opponent: ActorRef =
    if (self.path.name == "stageActor1") context.actorFor("/stageActor2")
    else context.actorFor("/stageActor1")
  private[this] def updateState(trans: GameState => GameState) {
    val future = (stateActor ? GetState)(1 second).mapTo[GameState]
    val s1 = Await.result(future, 1 second)
    val s2 = trans(s1)
    stateActor ! SetState(s2)
    (0 to s2.lastDeleted - 2) foreach { i =>
      opponent ! Attack
    }
  }
}
</scala>

これで 2行以上のラインが消されると攻撃が行われるようになった。以下に例を見てみる:

<img src="/images/tetrix-in-scala-day11c.png"/>

I字のバーが下の 4行を消して、3回の攻撃を行う。

<img src="/images/tetrix-in-scala-day11d.png"/>

続きはまた[明日](http://eed3si9n.com/ja/tetrix-in-scala-day12)。

<code>
$ git fetch origin
$ git co day11 -b try/day11
$ sbt "project swing" run
</code>
