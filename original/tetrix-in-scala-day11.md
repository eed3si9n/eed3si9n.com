  [day10]: http://eed3si9n.com/tetrix-in-scala-day10

[Yesterday][day10] we've written a test harness to automate scripted games to tune various components of the heuristic function. The overall performance improved from 7 +/- 2 lines to 34 +/- 18, almost 5x improvement.

### HAL moment

I decided to watch a game through on the swing UI, since I had been script testing mostly. From the beginning I could feel the improvement of the game quality as it was able to manage the blocks lows, and kept deleting the lines. After it went past 60 lines, it made a few mistakes and the blocks started to stack up to maybe 10th row, but nothing unmanagable. Then, all of a sudden, the agent started droping the piece. One after another.

It was as if the agent suddently gave up the game. Later during the day I realized that likely it had reached a timeout in one of the actors.

### variable thinking cycle

Instead of telling the agent to think at a regular interval, let's let it think as long as it wants to. To be fair to human response time, let's throttle an action to around 3 per second.

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

In order to slow down the game a bit, let's substitute `Drop` for a `Tick` also:

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

To prevent the agent from taking too long time to think, let's cap it to 1000 ms.

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

### man vs machine

Now that the agent is tuned, the next logical step is to play against the human. Let's set up two stage actors with identical initial state. One controlled by the player, and the other controlled by the agent.

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

Currently `view` returns only one view. We should modify this to return a pair.

<scala>
  def views: (GameView, GameView) =
    (Await.result((stateActor1 ? GetView).mapTo[GameView], timeout.duration),
    Await.result((stateActor2 ? GetView).mapTo[GameView], timeout.duration))
</scala>

Next, the swing UI need to render both the views.

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

Since `drawBoard` was refactored out, this was simple.

<img src="/images/tetrix-in-scala-day11.png"/>

We can let `GameMasterActor` be the referee and determine the winner if the other loses.

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

We need to display the status on the UI:

<scala>
      case Victory =>
        g drawString ("you win!", offset._1, offset._2 + 8 * unit)
</scala>

And this is how it looks:

<img src="/images/tetrix-in-scala-day11b.png"/>

### attacks

Currently two players are just playing side by side. Let's introduce attacks. Whenever a player deletes two or more lines in an action, some of the blocks should show up at the bottom of the opponent's grid on the next spawn cycle.

Let's spec the stage first:

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

Stub it out:

<scala>
val notifyAttack: GameState => GameState = (s0: GameState) => s0
</scala>

The test fails as expected:

<scala>
[info] Attacks should
[error] x increment the pending attack count,
[error]    '0' is not equal to '1' (StageSpec.scala:35)
[error] x and change the blocks in the view on a tick.
[error]    '(0,0), (4,17), (5,17), (6,17), (5,18)' doesn't contain in order '(1,0), (4,17), (5,17), (6,17), (5,18)' (StageSpec.scala:36)
</scala>

Here's the first part:

<scala>
  val notifyAttack: GameState => GameState = (s0: GameState) =>
    s0.copy(pendingAttacks = s0.pendingAttacks + 1)
</scala>

The second `attack` function looks similar to `clearFullRow`:

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

This is added to ticking process as follows:

<scala>
  val tick = transit(_.moveBy(0.0, -1.0),
    Function.chain(clearFullRow :: attack :: spawn :: Nil) )
</scala>

All tests pass:

<code>
[info] Attacks should
[info] + increment the pending attack count,
[info] + and change the blocks in the view on spawn.
</code>

Next, we'll use `StageActor`s to notify each other's attacks. We can let the stage report the number of lines deleted in the last tick as `lastDeleted`:

<scala>
case class GameState(blocks: Seq[Block], gridSize: (Int, Int),
    currentPiece: Piece, nextPiece: Piece, kinds: Seq[PieceKind],
    status: GameStatus = ActiveStatus,
    lineCount: Int = 0, lastDeleted: Int = 0,
    pendingAttacks: Int = 0) {...}
</scala>

Add a new message type `Attack` and implement notificaton in `StageActor`:

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

This creates attacks when 2 or more lines are deleted. Here's an example:

<img src="/images/tetrix-in-scala-day11c.png"/>

The I bar is going to eliminate bottom 4 rows, creating 3 attacks.

<img src="/images/tetrix-in-scala-day11d.png"/>

We'll pick it up from here tomorrow.

<code>
$ git fetch origin
$ git co day11 -b try/day11
$ sbt "project swing" run
</code>
