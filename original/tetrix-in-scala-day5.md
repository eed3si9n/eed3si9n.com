  [day4]: http://eed3si9n.com/tetrix-in-scala-day4

[Yesterday][day4] we put in an Akka actor to manage concurrent access to the game state. Let's look at the abstract UI again:

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

### too much locking 

Looking back, the above implementation does not look good. I've turned the program into embarrassingly serial one. In the previous implementation using `synchronized` the swing UI was able to query for a view 10 times a second. It continues to do so with this implementation, but because it's now in the same mailbox as other messages, it could flood the mailbox if any operation takes longer than 100 milisecond.

Ideally, the game state should not be locked until the very moment the new state is being written to it. Because the user operation and the scheduled ticking is never compatible, processing one of them at a time I think is ok for now.

Let's design the second actor by defining the message types:

<scala>
sealed trait StateMessage
case object GetState extends StateMessage
case case SetState(s: GameState) extends StateMessage
case object GetView extends StateMessage
</scala>

The actor implementation should be straight forward:

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

Next we need to rewrite the `StageActor` based on `StateActor`.

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

We need to update the abstract UI slightly to create `stateActor`:

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

The concurrency of timer ticking and the player moving the current piece left continues to be protected using `playerActor`. However, now the swing UI can access the view frequently without waiting on the others.

### size of the grid

After playing a few times, I noticed that the effective size of the grid is much smaller than 10x20 because how low the spawning point is. To work around this, we should expand the grid size vertically, but display only the lower 20 rows at least for the swing UI. I'll keep the specs to be 10x20 so I don't have to change all the numbers. `newState` should accept gridSize`:

<scala>
  def newState(blocks: Seq[Block], gridSize: (Int, Int),
      kinds: Seq[PieceKind]): GameState = ...
</scala>

Now, mostly the change is at swing UI. Pass in chopped off `gridSize` for rendering:

<scala>
    drawBoard(g, (0, 0), (10, 20), view.blocks, view.current)
    drawBoard(g, (12 * (blockSize + blockMargin), 0),
      view.miniGridSize, view.next, Nil)
</scala>

Next, filter to only the blocks within the range:

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

Now the newly spawned piece creeps from the top edge of the grid.

<img src="/images/tetrix-in-scala-day5.png"/>

As always, the code's up on github:

<code>
$ git fetch origin
$ git co day5 -b try/day5
$ sbt "project swing" run
</code>
