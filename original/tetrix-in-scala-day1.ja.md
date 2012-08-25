  [day0]: http://eed3si9n.com/ja/tetrix-in-scala-day0
  [amazon]: http://www.amazon.co.jp/dp/4798125415

[昨日][day0]はゲームの状態を `String` で近似化したけど、これを改善しよう。

### ゲームのモデル化

画面には 10x20 のグリッドがほしい。現在のピースのみが異なる色で表示されてほしい。次のピースを表示するウィンドウについては後で考える。ピースの種類は case object で表現できる:

<scala>
sealed trait PieceKind
case object IKind extends PieceKind
case object JKind extends PieceKind
case object LKind extends PieceKind
case object OKind extends PieceKind
case object SKind extends PieceKind
case object TKind extends PieceKind
case object ZKind extends PieceKind
</scala>

それぞれのブロックは case class で表せる:

<scala>
case class Block(pos: (Int, Int), kind: PieceKind)
</scala>

現在のピースとグリッドの両方とも `Seq[Block]` で表現できる。

<scala>
case class GameView(blocks: Seq[Block], gridSize: (Int, Int), current: Seq[Block])
</scala>

これで `AbstractUI` が `GameView` のインスタンスを返すように変更できる。

<scala>
  def view: GameView =
    GameView(
      Seq(Block((5, 5), TKind), Block((6, 5), TKind), Block((7, 5), TKind), Block((6, 6), TKind), Block((0, 0), TKind)),
      (10, 20),
      Seq(Block((5, 5), TKind), Block((6, 5), TKind), Block((7, 5), TKind), Block((6, 6), TKind)))
</scala>

### ゲームの描画

これはゲームの描画を改善するのに十分な情報だ。

<scala>
  def onPaint(g: Graphics2D) {
    val view = ui.view

    def buildRect(pos: (Int, Int)): Rectangle =
      new Rectangle(pos._1 * (blockSize + blockMargin),
        (view.gridSize._2 - pos._2 - 1) * (blockSize + blockMargin),
        blockSize, blockSize)
    def drawEmptyGrid {
      g setColor bluishLigherGray
      for {
        x <- 0 to view.gridSize._1 - 1
        y <- 0 to view.gridSize._2 - 2
        val pos = (x, y)
      } g draw buildRect(pos)      
    }
    def drawBlocks {
      g setColor bluishEvenLigher
      view.blocks foreach { b => g fill buildRect(b.pos) }
    }
    def drawCurrent {
      g setColor bluishSilver
      view.current foreach { b => g fill buildRect(b.pos) }
    }
    drawEmptyGrid
    drawBlocks
    drawCurrent
  }
</scala>

ゲームの状態が可視化できたところで、次は振る舞いも実装してみよう。

### ステージ

現在のピースを表すのにブロックの列よりもいい方法が必要だ。`Piece` クラスは現在位置を `(Double, Double)` で保持して `current` をローカル座標系から算出する。

<scala>
case class Piece(pos: (Double, Double), kind: PieceKind, locals: Seq[(Double, Double)]) {
  def current: Seq[Block] =
    locals map { case (x, y) => 
      Block((math.floor(x + pos._1).toInt, math.floor(y + pos._2).toInt), kind)
    }
}
case object Piece {
  def apply(pos: (Double, Double), kind: PieceKind): Piece =
    kind match {
      case TKind => Piece(pos, kind, Seq((-1.0, 0.0), (0.0, 0.0), (1.0, 0.0), (0.0, 1.0)))
    }
}
</scala>

これを使ってゲームの世界の物理系を司る `Stage` を定義できる。

<scala>
package com.eed3si9n.tetrix

class Stage(size: (Int, Int)) {
  private[this] def dropOffPos = (size._1 / 2.0, size._2 - 3.0)
  private[this] var currentPiece = Piece(dropOffPos, TKind)
  private[this] var blocks = Block((0, 0), TKind) +: currentPiece.current
  def view: GameView = GameView(blocks, size, currentPiece.current)
}
</scala>

現在のピースを移動させるには、まずそれをグリッドから外に出して (unload)、新しい位置に移動し、グリッドに再読み込みする。

`Piece` クラスの `moveBy` はこうなる:

<scala>
  def moveBy(delta: (Double, Double)): Piece =
    copy(pos = (pos._1 + delta._1, pos._2 + delta._2))
</scala>

これが unload と load だ:

<scala>
class Stage(size: (Int, Int)) {
  ...

  def moveLeft() = moveBy(-1.0, 0.0)
  def moveRight() = moveBy(1.0, 0.0)
  private[this] def moveBy(delta: (Double, Double)): this.type = {
    val unloaded = unload(currentPiece, blocks)
    val moved = currentPiece.moveBy(delta)
    blocks = load(moved, unloaded)
    currentPiece = moved
    this
  }
  private[this] def unload(p: Piece, bs: Seq[Block]): Seq[Block] = {
    val currentPoss = p.current map {_.pos}
    bs filterNot { currentPoss contains _.pos  }
  }
  private[this] def load(p: Piece, bs: Seq[Block]): Seq[Block] =
    bs ++ p.current
}
</scala>

### つなげる

ステージを抽象UI につなげてみよう:

<scala>
package com.eed3si9n.tetrix

class AbstractUI {
  private[this] val stage = new Stage((10, 20))
  def left() {
    stage.moveLeft()
  }
  def right() {
    stage.moveRight()
  }
  def up() {
  }
  def down() {
  }
  def space() {
  }
  def view: GameView = stage.view
}
</scala>

これで swing UI を起動するとピースが移動するのが確認できるはずだ。

<img src="/images/tetrix-in-scala-day1.png"/>

### specs2

先に進む前に、そろそろスペックが必要だ。UI を使ったゲームをテストするのは容易じゃないけど、出入力をデータ構造として定義したので、それほど難しくない。[Scala 逆引きレシピ][amazon]だと、「221: Specs2でテストケースを記述したい」と「222: Specs2で実行結果を検証したい」が参考になる。

最新の spec2 を `library` プロジェクトに追加する:

<scala>
  lazy val library = Project("library", file("library"),
    settings = buildSettings ++ Seq(
      libraryDependencies += "org.specs2" %% "specs2" % "1.12" % "test"
    ))
</scala>

以下が現在のピースを移動するスペック:

<scala>
import org.specs2._

class StageSpec extends Specification { def is = sequential  ^
  "This is a specification to check Stage"                   ^
                                                             p^
  "Moving to the left the current piece should"              ^
    """change the blocks in the view."""                     ! left1^
                                                             p^
  "Moving to the right the current piece should"             ^
    """change the blocks in the view."""                     ! right1^
                                                             end
  
  import com.eed3si9n.tetrix._
  def stage = new Stage((10, 20))
  def left1 =
    stage.moveLeft().view.blocks map {_.pos} must contain(
      (0, 0), (3, 17), (4, 17), (5, 17), (4, 18)
    ).inOrder
  def right1 =
    stage.moveRight().view.blocks map {_.pos} must contain(
      (0, 0), (5, 17), (6, 17), (7, 17), (6, 18)
    ).inOrder
}
</scala>

### bdd

スペックができたところで「テストファースト」のコーディングも試そう。ピースの初期座標が `(5, 17)` のとき、`moveLeft` を 4回呼ぶと壁に当たるはずだ。後続の `moveLeft` は無視するべきだ。

以下が左壁に当てるスペック:

<scala>
  "Moving to the left the current piece should"              ^
    """change the blocks in the view,"""                     ! left1^
    """as long as it doesn't hit the wall"""                 ! leftWall1^

...

  def leftWall1 =
    stage.moveLeft().moveLeft().moveLeft().moveLeft().moveLeft().
      view.blocks map {_.pos} must contain(
      (0, 0), (0, 17), (1, 17), (2, 17), (1, 18)
    ).inOrder
</scala>

期待通り、テストは失敗した:

<code>
[info] Moving to the left the current piece should
[info] + change the blocks in the view,
[error] x as long as it doesn't hit the wall
[error]    '(0,0), (-1,17), (0,17), (1,17), (0,18)' doesn't contain in order '(0,0), (0,17), (1,17), (2,17), (1,18)' (StageSpec.scala:8)
</code>

続きはまた[明日](http://eed3si9n.com/ja/tetrix-in-scala-day2)。

<code>
$ git fetch origin
$ git co day1 -b try/day1
$ sbt "project swing" run
</code>
