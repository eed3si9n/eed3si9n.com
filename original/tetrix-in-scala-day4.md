  [akka]: http://doc.akka.io/docs/akka/2.0.2/intro/getting-started-first-scala.html

In the last few days, we implemented tetrix from the ground up. In the beginning I mentioned that I use this game to explore new ways of thinking. Since I had already implemented tetrix once in Scala, Scala alone really isn't anything new for me. The actual topic I wanted to think about using tetrix is the handling of concurrency.

### concurrency

To quote Goetz's Java Concurrency in Practice,

> Writing thread-safe code is, at its core, about managing access to _state_, and in particular to _shared, mutable state_.

Conveniently we have refactored the inner working of tetrix so each operation is written as transition function from one `GameState` to another. Here's a simplified version of `AbstractUI`:

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

The timer modifies `state` by calling `tick(state)`, and the player can also modify it by calling `moveLeft(state)` or `moveRight(state)`. This is a textbook example of a thread-unsafe code. Here's an unlucky run of the timer thread and swing's event dispatch thread:

<code>
timer thread: reads shared state. current piece at (5, 18)
event thread: reads shared state. current piece at (5, 18)
timer thread: calls tick() function
timer thread: tick() returns a new state whose current piece is at (5, 17)
event thread: calls moveLeft() function
event thread: moveLeft() returns a new state whose current piece is at (4, 18)
event thread: writes the new state into shared state. current piece at (4, 18)
timer thread: writes the new state into shared state. current piece at (5, 17)
</code>

When the player sees this, either it would look like the left move was completely ignored, or witness the piece jumping diagnally from `(4, 18)` to `(5, 17)`. This is a race condition.

### synchronized

In this case, because each tasks are short-lived, and because the mutability is simple, we probably could get away with synchronizing on `state`.

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

Using the `synchronized` clause, reading of `state` and writing of `state` is now guaranteed to happen atomically. This approach may not be practical if mutability is spread out more widely, or if background execution of tasks are required.

### akka

Another way of managing concurrency is to use message passing framework like Akka actor. See [Getting Started Tutorial (Scala): First Chapter][akka] for an intro to actors. We can follow the steps in the tutorial.

First, add `"akka-actor"` to sbt:

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

Next, create actors.scala and define message types.

<scala>
sealed trait StageMessage
case object MoveLeft extends StageMessage
case object MoveRight extends StageMessage
case object RotateCW extends StageMessage
case object Tick extends StageMessage
case object Drop extends StageMessage
case object View extends StageMessage
</scala>

Then create `StageActor` to handle the messages. 

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

We can now rewire the abstract UI to use an Akka actor internally:

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

The mutation is now wrapped inside `playerActor`, which is guaranteed to handle messages one at a time. Also, note that the timer is replaced with a schedule. Overall, the message passing allows us to reason about concurrent behavior in a resonable way.

### game status

Let's implement a small feature too. During the spawning process collision against existing blocks are not checked. If the new piece collides, it should end the game. Here's the spec:

<scala>
  "Spawning a new piece should"                             ^
    """end the game it hits something."""                   ! spawn1^

...

  def spawn1 =
    Function.chain(Nil padTo (10, drop))(s1).status must_==
    GameOver
</scala>

Let's define `GameStatus` trait:

<scala>
sealed trait GameStatus
case object ActiveStatus extends GameStatus
case object GameOver extends GameStatus
</scala>

The test fails as expected after adding it to the `GameStatus`:

<code>
[info] Spawning a new piece should
[error] x end the game it hits something.
[error]    'ActiveStatus' is not equal to 'GameOver' (StageSpec.scala:29)
</code>

Current implementation of `spawn` is loading `nextPiece` without checking for collision:

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

All we have to do is validate the piece before loading it in.

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

Next, reject state transition during `GameOver` status:

<scala>
  private[this] def transit(trans: Piece => Piece,
      onFail: GameState => GameState = identity): GameState => GameState =
    (s: GameState) => s.status match {
      case ActiveStatus =>
        // do transition  
      case _ => s
    }
</scala>

Let's rub it into the player.

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

As always, the code's up on github:

<code>
$ git fetch origin
$ git co day4 -b try/day4
$ sbt "project swing" run
</code>

Continue to [day 5](http://eed3si9n.com/tetrix-in-scala-day5).
