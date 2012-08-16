  [wall]: http://days2011.scala-lang.org/sites/days2011/files/41.%20Effective%20Scala.pdf
  [suereth]: http://marakana.com/s/video_nescala_keynote_effective_scala_with_josh_suereth,1093/index.html
  [suereth2]: http://manning.com/suereth/
  [eriksen]: http://twitter.github.com/effectivescala/
  [pins]: http://www.artima.com/shop/programming_in_scala_2ed

Today's goal is to finish up the basic feature of Tetrix so it's playable.

### REPL

A few people in the community is coming up with best practices in Scala.

- [Effective Scala][wall] talk at Scala Days 2011 by Bill Venners and Dick Wall
- [Effective Scala][suereth] talk at NEScala 2012 by Josh Suereth 
- [Scala in Depth][suereth2] book by Josh Suereth 
- [Effective Scala][eriksen] page by Marius Eriksen at Twitter

As you would expect all of them mention to "Favor Immutability" and "Use None instead of null" like [Programming in Scala][pins] book. Some of the notable ones are "Know Your Collections" and "Consider Always Providing Return Types on Functions and Methods" by Venners/Wall, and more recently "Experiment in the REPL" by Josh.

> Experiment-driven development is where you, the developer, first spend some time experimenting with a live interpreter or REPL before writing tests or production code.

From the sbt shell, you can run `console` to get into the RELP which automatically loads your code into the classpath. Let's try to create the setup for clearing the bottom row:

<scala>
> console

Welcome to Scala version 2.9.2 (Java HotSpot(TM) 64-Bit Server VM, Java 1.6.0_33).
Type in expressions to have them evaluated.
Type :help for more information.

scala> import com.eed3si9n.tetrix._
import com.eed3si9n.tetrix._

scala> import Stage._
import Stage._

scala> val s3 = newState(Seq(
     |     (0, 0), (1, 0), (2, 0), (3, 0), (7, 0), (8, 0), (9, 0))
     |   map { Block(_, TKind) })
s3: com.eed3si9n.tetrix.GameState = GameState(List(Block((0,0),TKind), Block((1,0),TKind), Block((2,0),TKind), Block((3,0),TKind), Block((7,0),TKind), Block((8,0),TKind), Block((9,0),TKind), Block((4,17),TKind), Block((5,17),TKind), Block((6,17),TKind), Block((5,18),TKind)),(10,20),Piece((5.0,17.0),TKind,List((-1.0,0.0), (0.0,0.0), (1.0,0.0), (0.0,1.0))))

scala> val s = Function.chain(Nil padTo (17, tick))(s3)
s: com.eed3si9n.tetrix.GameState = GameState(List(Block((0,0),TKind), Block((1,0),TKind), Block((2,0),TKind), Block((3,0),TKind), Block((7,0),TKind), Block((8,0),TKind), Block((9,0),TKind), Block((4,0),TKind), Block((5,0),TKind), Block((6,0),TKind), Block((5,1),TKind)),(10,20),Piece((5.0,0.0),TKind,List((-1.0,0.0), (0.0,0.0), (1.0,0.0), (0.0,1.0))))
</scala>

### clearing rows

To clear all full rows, let's first figure out if a given row is full.

<scala>
scala> s.blocks filter {_.pos._2 == 0}
res1: Seq[com.eed3si9n.tetrix.Block] = List(Block((0,0),TKind), Block((1,0),TKind), Block((2,0),TKind), Block((3,0),TKind), Block((7,0),TKind), Block((8,0),TKind), Block((9,0),TKind), Block((4,0),TKind), Block((5,0),TKind), Block((6,0),TKind))
</scala>

We can `filter` to just row 0. We can count the size of the returned sequence to see if it's full.

<scala>
scala> def isFullRow(i: Int, s: GameState): Boolean =
     | (s.blocks filter {_.pos._2 == 0} size) == s.gridSize._1
isFullRow: (i: Int, s: com.eed3si9n.tetrix.GameState)Boolean

scala> isFullRow(0, s)
res2: Boolean = true
</scala>

Next let's figure out how to clear out the row. We can first split the `s.blocks` into parts above and below the current row.

<scala>
scala> s.blocks filter {_.pos._2 < 0}
res3: Seq[com.eed3si9n.tetrix.Block] = List()

scala> s.blocks filter {_.pos._2 > 0}
res4: Seq[com.eed3si9n.tetrix.Block] = List(Block((5,1),TKind))
</scala>

Next, we need to shift all the blocks down for ones above the cleared row.

<scala>
scala> s.blocks filter {_.pos._2 > 0} map { b =>
     | b.copy(pos = (b.pos._1, b.pos._2 - 1)) }
res5: Seq[com.eed3si9n.tetrix.Block] = List(Block((5,0),TKind))
</scala>

Here's an implementation of `clearFullRow`:

<scala>
  import scala.annotation.tailrec

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

It puts together what we experimented in the REPL and wraps it in a tail recursive function. Here's the updated `tick` function to incorporate this:

<scala>
  val tick = transit(_.moveBy(0.0, -1.0),
    Function.chain(clearFullRow :: spawn :: Nil) )
</scala>

We can now run the tests to check:

<code>
[info] Ticking the current piece should
[info] + change the blocks in the view,
[info] + or spawn a new piece when it hits something.
[info] + It should also clear out full rows.
</code>

Now that the rows clear, we can take some break by playing the game.

### stream of pieces

It's fun, but the game is somewhat predictable because it keeps giving us Ts. The first impulse may be to generate pieces randomly. But randomness introduces side-effect, which makes it hard to test. We don't want mutability in `Stage` or `GameState`. One way to work around this is by keeping an infinite sequence of pieces in the game state. During the testing we can pass in a hard-coded `Seq[PieceKind]`.

Here are the updated `GameState` and `GameView`:

<scala>
case class GameView(blocks: Seq[Block], gridSize: (Int, Int),
  current: Seq[Block], next: Seq[Block])

case class GameState(blocks: Seq[Block], gridSize: (Int, Int),
    currentPiece: Piece, nextPiece: Piece, kinds: Seq[PieceKind]) {
  def view: GameView = GameView(blocks, gridSize,
    currentPiece.current, nextPiece.current)
}
</scala>

Here's the spec:

<scala>
  "The current piece should"                                ^
    """be initialized to the first element in the state.""" ! init1^

...

  val s4 = newState(Nil, OKind :: Nil)
  def init1 =
    (s4.currentPiece.kind must_== OKind) and
    (s4.blocks map {_.pos} must contain(
      (4, 17), (5, 17), (4, 18), (5, 18)
    ).only.inOrder)
</scala>

We'll pick the next piece using `s.kinds.head`, and we'll use the previously picked `nextPiece` as the `currentPiece`.

<scala>
  private[this] lazy val spawn: GameState => GameState =
    (s: GameState) => {
    def dropOffPos = (s.gridSize._1 / 2.0, s.gridSize._2 - 3.0)
    val next = Piece((2, 1), s.kinds.head)
    val p = s.nextPiece.copy(pos = dropOffPos)
    s.copy(blocks = s.blocks ++ p.current,
      currentPiece = p, nextPiece = next, kinds = s.kinds.tail)
  }
</scala>

Running the test reveals another problem:

<code>
> test
[info] Compiling 1 Scala source to /Users/eed3si9n/work/tetrix.scala/library/target/scala-2.9.2/classes...
[error] Could not create an instance of StageSpec
[error]   caused by scala.MatchError: OKind (of class com.eed3si9n.tetrix.OKind$)
[error]   com.eed3si9n.tetrix.Piece$.apply(pieces.scala:38)
...
</code>

A `Piece` can't be initialized for `OKind` because we only implemented match for `TKind`. We just have to provide more local coordinates:

<scala>
case object PieceKind {
  def apply(x: Int): PieceKind = x match {
    case 0 => IKind
    case 1 => JKind
    case 2 => LKind
    case 3 => OKind
    case 4 => SKind
    case 5 => TKind
    case _ => ZKind
  } 
}

...

case object Piece {
  def apply(pos: (Double, Double), kind: PieceKind): Piece =
    Piece(pos, kind, kind match {
      case IKind => Seq((-1.5, 0.0), (-0.5, 0.0), (0.5, 0.0), (1.5, 0.0))      
      case JKind => Seq((-1.0, 0.5), (0.0, 0.5), (1.0, 0.5), (1.0, -0.5))
      case LKind => Seq((-1.0, 0.5), (0.0, 0.5), (1.0, 0.5), (-1.0, -0.5))
      case OKind => Seq((-0.5, 0.5), (0.5, 0.5), (-0.5, -0.5), (0.5, -0.5))
      case SKind => Seq((0.0, 0.5), (1.0, 0.5), (-1.0, -0.5), (0.0, -0.5))
      case TKind => Seq((-1.0, 0.0), (0.0, 0.0), (1.0, 0.0), (0.0, 1.0))
      case ZKind => Seq((-1.0, 0.5), (0.0, 0.5), (0.0, -0.5), (1.0, -0.5))
    })
}
</scala>

After fixing the specs by passing in a list of `TKind`s to states, all the tests pass. Here's the random stream for swing UI:

<scala>
  private[this] def randomStream(random: util.Random): Stream[PieceKind] =
    PieceKind(random.nextInt % 7) #:: randomStream(random)
</scala>

### next piece

We can now work on exposing the next piece to the UI via view.

<scala>
  def onPaint(g: Graphics2D) {
    val view = ui.view
    drawBoard(g, (0, 0), view.gridSize, view.blocks, view.current)
    drawBoard(g, (12 * (blockSize + blockMargin), 0),
      view.miniGridSize, view.next, Nil) 
  }
</scala>

`drawBoard` is extracted version of what was originally in `onPaint`.

### drop

To speed up the game, the user should be able to drop the current piece until it hits something.

<scala>
  "Dropping the current piece should"                       ^
    """tick the piece until it hits something"""            ! drop1^

...

  def drop1 =
    drop(s1).blocks map {_.pos} must contain(
      (0, 0), (4, 0), (5, 0), (6, 0), (5, 1),
      (4, 18), (5, 18), (6, 18), (5, 19)
    ).only.inOrder
</scala>

One way to implement this is to call `transit {_.moveBy(0.0, -1.0)}` 20 times, and then call `tick` at the end. The extra `transit` calls after hitting something would just be ignored.

<scala>
  val drop: GameState => GameState = (s0: GameState) =>
    Function.chain((Nil padTo (s0.gridSize._2, transit {_.moveBy(0.0, -1.0)})) ++
      List(tick))(s0)
</scala>

This passes the test:

<code>
[info] Dropping the current piece should
[info] + tick the piece until it hits something
</code>

### summary

The current piece now moves, rotates, and drops. The full rows are cleared, and the next pieces are visible. I say the goal of finishing up the basic feature is met.

<img src="/images/tetrix-in-scala-day3.png"/>

As always, the code's up on github:

<code>
$ git fetch origin
$ git co day3 -b try/day3
$ sbt "project swing" run
</code>
