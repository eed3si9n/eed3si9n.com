  [day1]: http://eed3si9n.com/tetrix-in-scala-day1
  [collection]: http://docs.scala-lang.org/overviews/collections/trait-traversable.html

We have a failing test from [yesterday][day1], which is a cool way to end a day for a hobby project.

<code>
[info] Moving to the left the current piece should
[info] + change the blocks in the view,
[error] x as long as it doesn't hit the wall
[error]    '(0,0), (-1,17), (0,17), (1,17), (0,18)' doesn't contain in order '(0,0), (0,17), (1,17), (2,17), (1,18)' (StageSpec.scala:8)
</code>

Sometimes it takes five minutes just to catch yourself up to where you last left off and what needs to be done next. A failing test case is a way to tell your future self "hey, work on this next!"

### validation

Let's see the current implementation of `moveBy`:

<scala>
  private[this] def moveBy(delta: (Double, Double)): this.type = {
    val unloaded = unload(currentPiece, blocks)
    val moved = currentPiece.moveBy(delta)
    blocks = load(moved, unloaded)
    currentPiece = moved
    this
  }
</scala>

All we need here is a validation of `moved` by checking that all blocks in `moved.current` are within the bounds. [Scala collection library][collection] has `forall` method that does exactly that. No need for looping `if` statements:

<scala>
  private[this] def moveBy(delta: (Double, Double)): this.type = {
    validate(
        currentPiece.moveBy(delta),
        unload(currentPiece, blocks)) map { case (moved, unloaded) =>
      blocks = load(moved, unloaded)
      currentPiece = moved
    }
    this
  }
  private[this] def validate(p: Piece, bs: Seq[Block]): Option[(Piece, Seq[Block])] =
    if (p.current map {_.pos} forall inBounds) Some(p, bs)
    else None
  private[this] def inBounds(pos: (Int, Int)): Boolean =
    (pos._1 >= 0) && (pos._1 < size._1) && (pos._2 >= 0) && (pos._2 < size._2)
</scala>

This should pass the test:

<code>
[info] Moving to the left the current piece should
[info] + change the blocks in the view,
[info] + as long as it doesn't hit the wall
</code>

### rotation

Now that the piece can move, we should try rotation. Given the hard-coded initial state of having T piece at `(5, 17)` and a block at `(0, 0)`, here's the spec:

<scala>
  "Rotating the current piece should"                       ^
    """change the blocks in the view."""                    ! rotate1^

...

  def rotate1 =
    stage.rotateCW().view.blocks map {_.pos} must contain(
      (0, 0), (5, 18), (5, 17), (5, 16), (6, 17)
    ).only.inOrder
</scala>

This shouldn't even compile because `Stage` class doesn't have `rotateCW()` method yet.

<code>
[error] /Users/eed3si9n/work/tetrix.scala/library/src/test/scala/StageSpec.scala:33: value rorateCCW is not a member of com.eed3si9n.tetrix.Stage
[error]     stage.rotateCW().view.blocks map {_.pos} must contain(
[error]           ^
[error] one error found
[error] (library/test:compile) Compilation failed
</code>

Stub it out:

<scala>
  def rotateCW() = this
</scala>

and we're back to a failing test case.

First, we implement the rotation at the piece level:

<scala>
  def rotateBy(theta: Double): Piece = {
    val c = math.cos(theta)
    val s = math.sin(theta)
    def roundToHalf(v: (Double, Double)): (Double, Double) =
      (math.round(v._1 * 2.0) * 0.5, math.round(v._2 * 2.0) * 0.5)
    copy(locals = locals map { case(x, y) => (x * c - y * s, x * s + y * c) } map roundToHalf)
  }
</scala>

And then we copy-paste (!) the `moveBy` method and make it into `rotateBy`:

<scala>
  def rotateCW() = rotateBy(-math.Pi / 2.0)
  private[this] def rotateBy(theta: Double): this.type = {
    validate(
        currentPiece.rotateBy(theta),
        unload(currentPiece, blocks)) map { case (moved, unloaded) =>
      blocks = load(moved, unloaded)
      currentPiece = moved
    }
    this
  }
</scala>

This now passes the test:

<code>
[info] Rotating the current piece should
[info] + change the blocks in the view.
</code>

## refactoring

Red, green, and refactor. Let's fix the copy-pasted `rotateBy`. We can extract out common parts by simply accepting a function `Piece => Piece`:

<scala>
  def moveLeft() = transformPiece(_.moveBy(-1.0, 0.0))
  def moveRight() = transformPiece(_.moveBy(1.0, 0.0))
  def rotateCW() = transformPiece(_.rotateBy(-math.Pi / 2.0))
  private[this] def transformPiece(trans: Piece => Piece): this.type = {
    validate(
        trans(currentPiece),
        unload(currentPiece, blocks)) map { case (moved, unloaded) =>
      blocks = load(moved, unloaded)
      currentPiece = moved
    }
    this
  }
</scala>

This gets rid of the `moveBy` and `rotateBy` in a single shot! Run the tests again to make sure we didn't break anything.

<code>
[info] Passed: : Total 4, Failed 0, Errors 0, Passed 4, Skipped 0
</code>

### functional refactoring

`Stage` class is shaping up to be a nice class, but I really don't like the fact that it has two `var`s in it. Let's kick out the states into its own class so we can make `Stage` stateless.

<scala>
case class GameState(blocks: Seq[Block], gridSize: (Int, Int), currentPiece: Piece) {
  def view: GameView = GameView(blocks, gridSize, currentPiece.current)
}
</scala>

Let's define a `newState` method to start a new state:

<scala>
  def newState(blocks: Seq[Block]): GameState = {
    val size = (10, 20)
    def dropOffPos = (size._1 / 2.0, size._2 - 3.0)
    val p = Piece(dropOffPos, TKind)
    GameState(blocks ++ p.current, size, p)
  }
</scala>

We can now think of each "moves" as transition from one state to another instead of calling methods on an object. We can tweak the `transformPiece` to generate transition functions:

<scala>
  val moveLeft  = transit { _.moveBy(-1.0, 0.0) }
  val moveRight = transit { _.moveBy(1.0, 0.0) }
  val rotateCW  = transit { _.rotateBy(-math.Pi / 2.0) }
  private[this] def transit(trans: Piece => Piece): GameState => GameState =
    (s: GameState) => validate(s.copy(
        blocks = unload(s.currentPiece, s.blocks),
        currentPiece = trans(s.currentPiece))) map { case x =>
      x.copy(blocks = load(x.currentPiece, x.blocks))
    } getOrElse {s}
  private[this] def validate(s: GameState): Option[GameState] = {
    val size = s.gridSize
    def inBounds(pos: (Int, Int)): Boolean =
      (pos._1 >= 0) && (pos._1 < size._1) && (pos._2 >= 0) && (pos._2 < size._2)
    if (s.currentPiece.current map {_.pos} forall inBounds) Some(s)
    else None
  }
</scala>

This feels more functional style. The type signature makes sure that `transit` does in fact return a state transition function. Now that `Stage` is stateless, we can turn it into a singleton object.

The specs needs a few modification:

<scala>
  import com.eed3si9n.tetrix._
  import Stage._
  val s1 = newState(Block((0, 0), TKind) :: Nil)
  def left1 =
    moveLeft(s1).blocks map {_.pos} must contain(
      (0, 0), (3, 17), (4, 17), (5, 17), (4, 18)
    ).only.inOrder
  def leftWall1 = sys.error("hmmm")
    // stage.moveLeft().moveLeft().moveLeft().moveLeft().moveLeft().
    //  view.blocks map {_.pos} must contain(
    //  (0, 0), (0, 17), (1, 17), (2, 17), (1, 18)
    // ).only.inOrder
  def right1 =
    moveRight(s1).blocks map {_.pos} must contain(
      (0, 0), (5, 17), (6, 17), (7, 17), (6, 18)
    ).only.inOrder
  def rotate1 =
    rotateCW(s1).blocks map {_.pos} must contain(
      (0, 0), (5, 18), (5, 17), (5, 16), (6, 17)
    ).only.inOrder
</scala>

The mutable implementation of `moveLeft` returned `this` so we were able to chain them. How should we handle `leftWall1`? Instead of methods, we now have pure functions. These can be composed using `Function.chain`:

<scala>
  def leftWall1 =
    Function.chain(moveLeft :: moveLeft :: moveLeft :: moveLeft :: moveLeft :: Nil)(s1).
      blocks map {_.pos} must contain(
      (0, 0), (0, 17), (1, 17), (2, 17), (1, 18)
    ).only.inOrder
</scala>

`Function.chain` takes a `Seq[A => A]` and turns it into an `A => A` function. We are essentially treating a tiny part of the code as data.

### collision detection

For 3D games, you could write a whole book on real-time collision detection. Using Scala collection, we can write one for Tetrix in one line. Let's describe the scenario in specs:

<scala>
  val s2 = newState(Block((3, 17), TKind) :: Nil)
  def leftHit1 =
    moveLeft(s2).blocks map {_.pos} must contain(
      (3, 17), (4, 17), (5, 17), (6, 17), (5, 18)
    ).only.inOrder
</scala>

This fails as expected:

<code>
[error] x or another block in the grid.
[error]    '(3,17), (3,17), (4,17), (5,17), (4,18)' doesn't contain in order '(3,17), (4,17), (5,17), (6,17), (5,18)' (StageSpec.scala:9)
</code>

Here's the updated `validate` method:

<scala>
  private[this] def validate(s: GameState): Option[GameState] = {
    val size = s.gridSize
    def inBounds(pos: (Int, Int)): Boolean =
      (pos._1 >= 0) && (pos._1 < size._1) && (pos._2 >= 0) && (pos._2 < size._2)
    val currentPoss = s.currentPiece.current map {_.pos}
    if ((currentPoss forall inBounds) && 
      (s.blocks map {_.pos} intersect currentPoss).isEmpty) Some(s)
    else None
  }
</scala>

### tick

We have `moveLeft` and `moveRight`, but no `moveDown`. This is because downward movement needs to do more. Once it detects collision agaist the floor or another block, the current piece freezes at its place and a new piece gets dropped in.

First, the movement:

<scala>
  "Ticking the current piece should"                        ^
    """change the blocks in the view."""                    ! tick1^ 

...

  def tick1 =
    tick(s1).blocks map {_.pos} must contain(
      (0, 0), (4, 16), (5, 16), (6, 16), (5, 17)
    ).only.inOrder
</scala>

To get this test passed we can implement `tick` as using `moveBy`:

<scala>
  val tick      = transit { _.moveBy(0.0, -1.0) }
</scala>

Next, the new piece:

<scala>

      """or spawn a new piece when it hits something"""       ! tick2^

...

  def tick2 =
    Function.chain(Nil padTo (18, tick))(s1).
    blocks map {_.pos} must contain(
      (0, 0), (4, 0), (5, 0), (6, 0), (5, 1),
      (4, 17), (5, 17), (6, 17), (5, 18)
    ).only.inOrder
</scala>

The `transit` method already knows the validity of the modified state. Currently it's just returning the old state using `getOrElse`. All we have to do is put some actions in there.

<scala>
  private[this] def transit(trans: Piece => Piece,
      onFail: GameState => GameState = identity): GameState => GameState =
    (s: GameState) => validate(s.copy(
        blocks = unload(s.currentPiece, s.blocks),
        currentPiece = trans(s.currentPiece))) map { case x =>
      x.copy(blocks = load(x.currentPiece, x.blocks))
    } getOrElse {onFail(s)}
</scala>

Unless `onFail` is passed in, it uses `identity` function. Here's the `tick`:

<scala>
  val tick = transit(_.moveBy(0.0, -1.0), spawn)
  
  private[this] def spawn(s: GameState): GameState = {
    def dropOffPos = (s.gridSize._1 / 2.0, s.gridSize._2 - 3.0)
    val p = Piece(dropOffPos, TKind)
    s.copy(blocks = s.blocks ++ p.current,
      currentPiece = p)
  }
</scala>

Let's see if this passes the test:

<code>
[info] Ticking the current piece should
[info] + change the blocks in the view,
[info] + or spawn a new piece when it hits something
</code>

### timer

Let's hook `tick` up to the down arrow key and a timer in the abstract UI:

<scala>
  import java.{util => ju}

  private[this] val timer = new ju.Timer
  timer.scheduleAtFixedRate(new ju.TimerTask {
    def run { state = tick(state) }
  }, 0, 1000) 

  ...

  def down() {
    state = tick(state)
  }
</scala>

This will move the current piece on its own. But since the swing UI doesn't know about it, so it won't get rendered. We can add another timer to repaint the `mainPanel` 10 fps to fix this issue:

<scala>
    val timer = new SwingTimer(100, new AbstractAction() {
      def actionPerformed(e: java.awt.event.ActionEvent) { repaint }
    })
    timer.start
</scala>

<img src="/images/tetrix-in-scala-day2.png"/>

### bottom line

The obvious issue here is that the bottom row is not clearing. Here's a spec that should test this:

<scala>
    """It should also clear out full rows."""               ! tick3^

...

  val s3 = newState(Seq(
      (0, 0), (1, 0), (2, 0), (3, 0), (7, 0), (8, 0), (9, 0))
    map { Block(_, TKind) })
  def tick3 =
  Function.chain(Nil padTo (18, tick))(s3).
    blocks map {_.pos} must contain(
      (5, 0), (4, 17), (5, 17), (6, 17), (5, 18)
    ).only.inOrder 
</scala>

We'll get back to this tomorrow.

<code>
$ git fetch origin
$ git co day2 -b try/day2
$ sbt "project swing" run
</code>
