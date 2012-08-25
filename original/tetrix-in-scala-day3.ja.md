  [wall]: http://days2011.scala-lang.org/sites/days2011/files/41.%20Effective%20Scala.pdf
  [suereth]: http://marakana.com/s/video_nescala_keynote_effective_scala_with_josh_suereth,1093/index.html
  [suereth2]: http://manning.com/suereth/
  [eriksen]: http://twitter.github.com/effectivescala/
  [pins]: http://www.amazon.co.jp/dp/4844327453
  [amazon]: http://www.amazon.co.jp/dp/4798125415

今日のゴールは tetrix の基本機能を仕上げて取り敢えずプレイ可能な状態に持っていくことだ。

### REPL

コミュニティー内に Scala でのベスト・プラクティスを提唱している人たちがいる。

- Bill Venners と Dick Wall による Scala Days 2011 での講演 [Effective Scala][wall]
- Josh Suereth による NEScala 2011 での講演 [Effective Scala][suereth]
- Josh Suereth による本 [Scala in Depth][suereth2]
- Twitter社の Marius Eriksen によるページ [Effective Scala][eriksen]

[コップ本][pins]にも書いてあるような「不変性を推奨する」とか「null の代わりに None を使おう」というのは、予想される通り全員が言及している。中でも記憶に残ったのは Venners/Wall の「コレクションを知れ」と「関数やメソッドの戻り値型を常につけてみることを検討しよう」、そして最近だと Josh の「REPL で実験せよ」というものだ。

> 実験駆動開発 (experiment-driven development) では開発者である君が、テストやプロダクションのコードを書く前に、まずインタープリターや REPL で実験をする。

sbt シェルから `console` を実行することでプロジェクトのコードがクラスパスに追加された REPL に入ることができる。一番下の列を消去できるようにセットアップしてみよう:

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

### 列の消去

埋まった列を全てを消去するために、まず与えられた列のブロックが全て埋まっているかを判定する必要がある。

<scala>
scala> s.blocks filter {_.pos._2 == 0}
res1: Seq[com.eed3si9n.tetrix.Block] = List(Block((0,0),TKind), Block((1,0),TKind), Block((2,0),TKind), Block((3,0),TKind), Block((7,0),TKind), Block((8,0),TKind), Block((9,0),TKind), Block((4,0),TKind), Block((5,0),TKind), Block((6,0),TKind))
</scala>

`filter` を使って列0 だけ取り出せる。戻ってきた列のサイズを見れば全て埋まっているかが分かる。

<scala>
scala> def isFullRow(i: Int, s: GameState): Boolean =
     | (s.blocks filter {_.pos._2 == 0} size) == s.gridSize._1
isFullRow: (i: Int, s: com.eed3si9n.tetrix.GameState)Boolean

scala> isFullRow(0, s)
res2: Boolean = true
</scala>

次に、列の消去を考える。まず、`s.blocks` を現在の列の上と下に分ける。

<scala>
scala> s.blocks filter {_.pos._2 < 0}
res3: Seq[com.eed3si9n.tetrix.Block] = List()

scala> s.blocks filter {_.pos._2 > 0}
res4: Seq[com.eed3si9n.tetrix.Block] = List(Block((5,1),TKind))
</scala>

それから、消去される列の上のブロックをずらす必要がある。

<scala>
scala> s.blocks filter {_.pos._2 > 0} map { b =>
     | b.copy(pos = (b.pos._1, b.pos._2 - 1)) }
res5: Seq[com.eed3si9n.tetrix.Block] = List(Block((5,0),TKind))
</scala>

以下は `clearFullRow` の実装の一例だ:

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

REPL で実験したことをまとめて末尾再帰の関数に入れた。`tick` を更新してこれを取り込む。

<scala>
  val tick = transit(_.moveBy(0.0, -1.0),
    Function.chain(clearFullRow :: spawn :: Nil) )
</scala>

テストを走らせて確認する:

<code>
[info] Ticking the current piece should
[info] + change the blocks in the view,
[info] + or spawn a new piece when it hits something.
[info] + It should also clear out full rows.
</code>

列が消えるようになったので、ちょっと一息ついてゲームで遊んでみよう。

### ピースのストリーム

面白いが、T字のピースしか出てこないので少し単調だ。ピースをランダムに生成すればいいと反射的に考えるかもしれない。だけど、ランダム性は副作用を導入し、テストを難しくする。`Stage` や `GameState` に可変性を持ち込むのは避けたい。これを回避できる方法としてはゲームの状態にピースの無限列を置くことがある。テストの最中はハードコードされた `GameState` and `GameView` を入れておけばいい。

以下がが更新された `GameState` と `GameView` だ:

<scala>
case class GameView(blocks: Seq[Block], gridSize: (Int, Int),
  current: Seq[Block], next: Seq[Block])

case class GameState(blocks: Seq[Block], gridSize: (Int, Int),
    currentPiece: Piece, nextPiece: Piece, kinds: Seq[PieceKind]) {
  def view: GameView = GameView(blocks, gridSize,
    currentPiece.current, nextPiece.current)
}
</scala>

以下がスペックだ:

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

次のピースを `s.kinds.head` を用いて選び、以前に選択した `nextPiece` を `currentPiece` として使う。

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

テストを実行すると別の問題が明らかになる:

<code>
> test
[info] Compiling 1 Scala source to /Users/eed3si9n/work/tetrix.scala/library/target/scala-2.9.2/classes...
[error] Could not create an instance of StageSpec
[error]   caused by scala.MatchError: OKind (of class com.eed3si9n.tetrix.OKind$)
[error]   com.eed3si9n.tetrix.Piece$.apply(pieces.scala:38)
...
</code>

`TKind` に対するマッチしか実装しなかったため、`Piece` を `OKind` で初期化することができない。ローカル座標をもっと提供するだけでいい:

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

状態に `TKind` のリストを渡してスペックを直すことで全てのテストが成功するようになっった。以下が swing UI 向けのストリームとなる:

<scala>
  private[this] def randomStream(random: util.Random): Stream[PieceKind] =
    PieceKind(random.nextInt % 7) #:: randomStream(random)
</scala>

### 次のピース

ビューを使って次のピースを UI に公開できるようになった。

<scala>
  def onPaint(g: Graphics2D) {
    val view = ui.view
    drawBoard(g, (0, 0), view.gridSize, view.blocks, view.current)
    drawBoard(g, (12 * (blockSize + blockMargin), 0),
      view.miniGridSize, view.next, Nil) 
  }
</scala>

`drawBoard` は元の `onPaint` を抽出したものだ。

### 落下

ゲームを早めるのに現在のピースを他の何かに当たるまで落とせる機能がほしい。

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

これを実装する手軽な方法に `transit {_.moveBy(0.0, -1.0)}` を 20回呼び出して最後に `tick` を呼ぶというものがある。余分な `transit` の呼び出しは当たり判定後は無視される。

<scala>
  val drop: GameState => GameState = (s0: GameState) =>
    Function.chain((Nil padTo (s0.gridSize._2, transit {_.moveBy(0.0, -1.0)})) ++
      List(tick))(s0)
</scala>

テストは通過する:

<code>
[info] Dropping the current piece should
[info] + tick the piece until it hits something
</code>

### まとめ

これで現在のピースを動かし、回転させ、落下できるようになった。埋まった列は消去され、次に出てくるピースも見えるようになった。基本機能を仕上げるという目標は一応達成したと思う。

<img src="/images/tetrix-in-scala-day3.png"/>

いつもどおり、コードは github にある:

<code>
$ git fetch origin
$ git co day3 -b try/day3
$ sbt "project swing" run
</code>

[4日目](http://eed3si9n.com/ja/tetrix-in-scala-day4)へ続く。
