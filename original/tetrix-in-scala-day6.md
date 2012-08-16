  [day5]: http://eed3si9n.com/tetrix-in-scala-day5
  [russell]: http://aima.cs.berkeley.edu/

[Yesterday][day5] we improved the concurrent access of the game state by introducing a second actor. Now that we have a powerful tool to manage concurrency, we can venture out to somewhere new. Like taking over the mankind. One tetrix player at a time.

### Russell and Norvig

One of the reasons I picked CS major at my college was to learn about AI. It was quite disappointing that in the first few years none of my classes covered anything like AI. So during a summer co-op (internship) I decided to wake up early, go to Starbucks, and read a textbook smart colleges were using to teach AI. That's how I found Russell and Norvig's [Artificial Intelligence: A Modern Approach (AIMA)][russell].

The book was shocking. Instead of trying to create a human-like robot, it introduces a concept called agent, which *does* something rational.

> An **agent** is anything that can be viewed as perceiving its environment through sensors and acting upon that environment through actuators.

One of the structures of rational agent is a model-based, utility-based agent.

<code>
+-agent-------------------+   +-environment-+ 
|           Sensors      <=====             |
|   State <----+          |   |             |
|              |          |   |             |
| What if I do action A?  |   |             |
|              |          |   |             |
|   How happy will I be?  |   |             |
|              |          |   |             |
| Utility <----+          |   |             |
|              |          |   |             |
|  What should I do next? |   |             |
|              |          |   |             |
|           Actuators     =====>            |
+-------------------------+   +-------------+
</code>

> A utility function maps a state (or a sequence of states) onto a real number, which describes the associated degree of happiness.

Blows your mind, right? Using this structure, we can make a program that appears intelligent by constructing a state machine (done!), a utility function, and a tree searching algorithm. The data structure and graph theory can be useful after all.

### utility function

For a utility-based agent, construction of the utility function is the key. We will probably be tweak this going forward, but let's start with something simple. For now, I define that the happiness is not being dead, and the deleted lines. As passive as it sounds, tetrix is a game of not losing. On one-on-one tetrix, there isn't a clear definition of winning. You win by default when the opponent loses.

Let's describe this in a new spec:

<scala>
import org.specs2._

class AgentSpec extends Specification with StateExample { def is = sequential ^
  "This is a specification to check Agent"                  ^
                                                            p^
  "Utility function should"                                 ^
    """evaluate initial state as 0.0,"""                    ! utility1^
    """evaluate GameOver as -1000.0."""                     ! utility2^
                                                            end
  
  import com.eed3si9n.tetrix._

  val agent = new Agent

  def utility1 =
    agent.utility(s1) must_== 0.0 
  def utility2 =
    agent.utility(gameOverState) must_== -1000.0 
}
</scala>

Next we start `Agent` class and stub the `utility` method:

<scala>
package com.eed3si9n.tetrix

class Agent {
  def utility(state: GameState): Double = 0.0
}
</scala>

This fails the second example as expected:

<code>
[info] Utility function should
[info] + evaluate initial state as 0.0,
[error] x evaluate GameOver as -1000.0.
[error]    '0.0' is not equal to '-1000.0' (AgentSpec.scala:8)
</code>

Let's fix this:

<scala>
  def utility(state: GameState): Double =
    if (state.status == GameOver) -1000.0
    else 0.0
</scala>

All green. Nothing to refactor here.

### lines

Since my agent's happiness is defined by the lines it has deleted, we need to track that number. This goes into `StageSpec`:

<scala>
  "Deleting a full row should"                              ^
    """increment the line count."""                         ! line1^
...
  def line1 =
    (s3.lineCount must_== 0) and
    (Function.chain(Nil padTo (19, tick))(s3).
    lineCount must_== 1)
</scala>

Here's `GameState` with `lineCount`:

<scala>
case class GameState(blocks: Seq[Block], gridSize: (Int, Int),
    currentPiece: Piece, nextPiece: Piece, kinds: Seq[PieceKind],
    status: GameStatus, lineCount: Int) {
  def view: GameView = GameView(blocks, gridSize,
    currentPiece.current, (4, 4), nextPiece.current,
    status, lineCount)
}
</scala>

The test fails as expected:

<code>
[info] Deleting a full row should
[error] x increment the line count.
[error]    '0' is not equal to '1' (StageSpec.scala:91)
</code>

In `Stage` class, the only place full rows are deleted is in `clearFullRow` function called by `tick`:

<scala>
  private[this] lazy val clearFullRow: GameState => GameState =
    (s0: GameState) => {
    def isFullRow(i: Int, s: GameState): Boolean =
      (s.blocks filter {_.pos._2 == i} size) == s.gridSize._1
    @tailrec def tryRow(i: Int, s: GameState): GameState =
      if (i < 0) s 
      else if (isFullRow(i, s))
        tryRow(i - 1, s.copy(blocks = (s.blocks filter {_.pos._2 < i}) ++
          (s.blocks filter {_.pos._2 > i} map { b =>
            b.copy(pos = (b.pos._1, b.pos._2 - 1)) })))  
      else tryRow(i - 1, s)
    tryRow(s0.gridSize._2 - 1, s0)
  }
</scala>

It kind of looks scary, but we just have to realize that the line deletion is done using `s.copy(blocks = ...)`. We just need to add `lineCount` right afterwards:

<scala>
s.copy(blocks = ...,
  lineCount = s.lineCount + 1)
</scala>

This passes the test.

<code>
[info] Deleting a full row should
[info] + increment the line count.
</code>

We now need to incorporate this into the utility function.

<scala>
    """evaluate an active state by lineCount"""             ! utility3^
...
  def utility3 = {
    val s = Function.chain(Nil padTo (19, tick))(s3)
    agent.utility(s) must_== 1.0
  }
</scala>

This again fails as expected:

<code>
[error] x evaluate an active state by lineCount
[error]    '0.0' is not equal to '1.0' (AgentSpec.scala:9)
</code>

This is easy:

<scala>
  def utility(state: GameState): Double =
    if (state.status == GameOver) -1000.0
    else state.lineCount.toDouble
</scala>

### solving problems by searching

Now that our agent can find out how happy it is, it can turn an abtract issue of "not losing tetrix to a human" problem into tree searching problem. At any point in time, the agent and the scheduled timer can take one of the five actions we have been looking at:

<scala>
  def receive = {
    case MoveLeft  => updateState {moveLeft}
    case MoveRight => updateState {moveRight}
    case RotateCW  => updateState {rotateCW}
    case Tick      => updateState {tick}
    case Drop      => updateState {drop}
  }
</scala>

In other words, `bestMove` is a `GameState => StageMessage` function. What's with the tree? At the initial state `s0` (at time=0), the agent can take five actions: `MoveLeft`, `MoveRight` etc. The actions result in five states `s1`, `s2`, `s3`, `s4`, `s5` (at time=1). Each of the states then can branch into five more `s11`, `s12`, ..., `s55`. Draw this out, and we have a tree structure.

<code>
                                                  s0
                                                  |
        +--------------------+--------------------+-------...
        s1                   s2                   s3
        |                    |                    |
+---+---+---+---+    +---+---+---+---+    +---+---+---+---+ 
s11 s12 s13 s14 s15  s21 s22 s23 s24 s25  s31 s32 s33 s34 s35
</code>

The number of the nodes grows exponentially. `1 + 5 + 5^2`. For now, let's just start with one level.

Here's how we can contruct a test. Make a state named `s3`, which is one `Drop` action away from deleting a line. We tell the agent to pick a move, and it should select `Drop`. As a negative control, we also need some other state `s1`, which the agent can pick whatever action:

<scala>
  "Solver should"                                           ^
    """pick MoveLeft for s1"""                              ! solver1^
    """pick Drop for s3"""                                  ! solver2^
...
  def solver1 =
    agent.bestMove(s1) must_== MoveLeft
  def solver2 =
    agent.bestMove(s3) must_== Drop
</scala>

And here's a stub:

<scala>
  def bestMove(state: GameState): StageMessage = MoveLeft
</scala>

This fails the test as expected.

<code>
[info] Solver should
[info] + pick MoveLeft for s1
[error] x pick Drop for s3
[error]    'MoveLeft' is not equal to 'Drop' (AgentSpec.scala:13)
</code>

We'll get back to this tomorrow.

<code>
$ git fetch origin
$ git co day6 -b try/day6
$ sbt "project swing" run
</code>
