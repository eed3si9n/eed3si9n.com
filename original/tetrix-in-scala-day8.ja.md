  [day7]: http://eed3si9n.com/ja/tetrix-in-scala-day7

[昨日][day7]は tetrix を解くエージェントをアクターに組み込んでゲームを操作させた。これまでのゲームの手さばきは合理的だとも知的だとも言い難い。ヒューリスティックのペナルティが何度も 0.0 と評価されているのを見て 2つの疑惑が頭をもたげた。

第一に、`Drop` はいかなる場合でも良い選択ではないということだ。特に探索木が浅い状況では `Drop` を選択するのは早計だと思う。どうせ重力による `Tick` が下向きに動かしてくれるので、エージェントが `Drop` が最良の動作だと思った場合は無視することにした:

<scala>
  def receive = {
    case BestMove(s: GameState) =>
      val message = agent.bestMove(s)
      if (message != Drop) stageActor ! message
  }
</scala>

### バギーなペナルティ

第二の疑惑はペナルティの計算が何かおかしいということだ。テストを加えてみよう:

<scala>
    """penalize having gaps between the columns"""          ! utility4^
...
  def utility4 = {
    val s = newState(Seq(
      (0, 0), (0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6))
      map { Block(_, TKind) }, (10, 20), TKind :: TKind :: Nil)
    agent.utility(s) must_== -36.0 
  } and {
    val s = newState(Seq((1, 0), (1, 1), (2, 1), (2, 2))
    map { Block(_, ZKind) }, (10, 20), TKind :: TKind :: Nil)
    agent.utility(s) must_== -13.0
  }
</scala>

思った通り失敗する。

<code>
[error] x penalize having gaps between the columns
[error]    '-4.0' is not equal to '-13.0' (AgentSpec.scala:35)
</code>

REPL に入る前に、何度も同じ事を打ち込まなくてもいいように以下を `build.scala` に加える:

<scala>
initialCommands in console := """import com.eed3si9n.tetrix._
                                |import Stage._""".stripMargin
</scala>

再読み込みした後で sbt シェルから `console` と打って REPL を起動する:

<scala>
[info] 
import com.eed3si9n.tetrix._
import Stage._
Welcome to Scala version 2.9.2 (Java HotSpot(TM) 64-Bit Server VM, Java 1.6.0_33).
Type in expressions to have them evaluated.
Type :help for more information.

scala> move // タブキーを押す
moveLeft    moveRight 
</scala>

そう、REPL からはタブ補完まで使える。

<scala>
scala>     val s = newState(Seq((1, 0), (1, 1), (2, 1), (2, 2))
          map { Block(_, ZKind) }, (10, 20), TKind :: TKind :: Nil)
s: com.eed3si9n.tetrix.GameState = GameState(List(Block((1,0),ZKind), Block((1,1),ZKind), Block((2,1),ZKind), Block((2,2),ZKind), Block((4,18),TKind), Block((5,18),TKind), Block((6,18),TKind), Block((5,19),TKind)),(10,20),Piece((5.0,18.0),TKind,List((-1.0,0.0), (0.0,0.0), (1.0,0.0), (0.0,1.0))),Piece((2.0,1.0),TKind,List((-1.0,0.0), (0.0,0.0), (1.0,0.0), (0.0,1.0))),List(),ActiveStatus,0)

scala>     val heights = s.unload(s.currentPiece).blocks map {
             _.pos} groupBy {_._1} map { case (k, v) => (k, v.map({_._2}).max) }
heights: scala.collection.immutable.Map[Int,Int] = Map(1 -> 1, 2 -> 2)

scala>     val gaps = (0 to s.gridSize._1 - 2).toSeq map { x =>
             heights.getOrElse(x, 0) - heights.getOrElse(x + 1, 0) } filter {_ > 1}
gaps: scala.collection.immutable.IndexedSeq[Int] = Vector(2)
</scala>

Off-by-one エラーだ! 気付いたかな? 一番下の座標が `0` なのにデフォルトで `0` を返している。

あとそれから負の数もフィルター漏れしている。正しい `gap` はこれだ:

<scala>
scala>     val gaps = (0 to s.gridSize._1 - 2).toSeq map { x =>
             heights.getOrElse(x, -1) - heights.getOrElse(x + 1, -1) } filter {math.abs(_) > 1}
gaps: scala.collection.immutable.IndexedSeq[Int] = Vector(-2, 3)
</scala>

手で計算した -36.0 まで間違っていたためこのバグに気付かなかった。これで全てのテストが通るようになった:

<code>
[info] + penalize having gaps between the columns
</code>

少しは論理的になったけど、ペナルティは実際のゲームをスコアや正しいセットアップに導いていない気がする。まず、効用関数の報酬部分とペナルティ部分を分けてテストしやすいようにする。次に、高低差の代わりに高さそのものにペナルティを課してみよう。

<scala>
  "Penalty function should"                                 ^  
    """penalize having blocks stacked up high"""            ! penalty1^
...
  def penalty1 = {
    val s = newState(Seq(
      (0, 0), (0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6))
      map { Block(_, TKind) }, (10, 20), TKind :: TKind :: Nil)
    agent.penalty(s) must_== 49.0 
  } and {
    val s = newState(Seq((1, 0))
    map { Block(_, ZKind) }, (10, 20), TKind :: TKind :: Nil)
    agent.penalty(s) must_== 1.0
  }
</scala>

これが新しい `penalty` だ:

<scala>
  def penalty(s: GameState): Double = {
    val heights = s.unload(s.currentPiece).blocks map {
      _.pos} groupBy {_._1} map { case (k, v) => v.map({_._2 + 1}).max }
    heights map { x => x * x } sum
  }
</scala>

報酬とペナルティのバランスも調整したい。現在はペナルティの回避に比べてラインを消すインセンティブが少なすぎる。

<scala>
  def utility(state: GameState): Double =
    if (state.status == GameOver) minUtility
    else reward(state) - penalty(state) / 10.0
</scala>

以下のゲームではやっと一つのラインを消すことができた:

<img src="/images/tetrix-in-scala-day8.png"/>

### 探索木の刈り込み

> **刈り込み** (pruning) を用いることで最終的な選択肢に違いの出ない探索木の部分を無視することができる。

制御無しでは探索木は指数関数的に大きくなっていくため、この概念はここでも当てはまる。

1. `Drop` と `Tick` を抜くことで分岐数を 5 から 3 に減らせる。既に現在のピースを落とすことを仮定しているため、あとは `s0` も `Drop` 付きで評価すればいいだけだ。
2. 次に、現在のピースの 4つの全ての向きを事前に分岐させることで `RotateCW` も消える。ほとんどの場合は `RotateCW :: MoveLeft :: RotateCW :: Drop :: Nil` と `RotateCW :: RotateCW :: MoveLeft :: Drop :: Nil` は同じ状態に到達する。
3. 現在のピースを可能なかぎり左に寄せることで `MoveLeft` も抜くことができる。

ピースは 4つの向きと 9つの x位置を取ることができる。つまり、指数関数的な木の探索はこれで 36 という定数サイズで近似化できる。

`PieceKind` に基いて可能な向きの数を列挙する:

<scala>
  private[this] def orientation(kind: PieceKind): Int = {
    case IKind => 2
    case JKind => 4
    case LKind => 4
    case OKind => 1
    case SKind => 2
    case TKind => 4
    case ZKind => 2
  }
</scala>

次に、REPL を使って、ある状態からエージェントが何回右か左かに動かせるかを計算する。

<scala>
scala> val s = newState(Nil, (10, 20), TKind :: TKind :: Nil)
s: com.eed3si9n.tetrix.GameState = GameState(List(Block((4,18),TKind), Block((5,18),TKind), Block((6,18),TKind), Block((5,19),TKind)),(10,20),Piece((5.0,18.0),TKind,List((-1.0,0.0), (0.0,0.0), (1.0,0.0), (0.0,1.0))),Piece((2.0,1.0),TKind,List((-1.0,0.0), (0.0,0.0), (1.0,0.0), (0.0,1.0))),List(),ActiveStatus,0)

scala> import scala.annotation.tailrec
import scala.annotation.tailrec

scala> @tailrec def leftLimit(n: Int, s: GameState): Int = {
          val next = moveLeft(s)
          if (next.currentPiece.pos == s.currentPiece.pos) n
          else leftLimit(n + 1, next)
       }
leftLimit: (n: Int, s: com.eed3si9n.tetrix.GameState)Int

scala> leftLimit(0, s)
res1: Int = 4
</scala>

右の分も同じに作って、`sideLimit` メソッドの完成だ:

<scala>
  private[this] def sideLimit(s0: GameState): (Int, Int) = {
    @tailrec def leftLimit(n: Int, s: GameState): Int = {
      val next = moveLeft(s)
      if (next.currentPiece.pos == s.currentPiece.pos) n
      else leftLimit(n + 1, next)
    }
    @tailrec def rightLimit(n: Int, s: GameState): Int = {
      val next = moveRight(s)
      if (next.currentPiece.pos == s.currentPiece.pos) n
      else rightLimit(n + 1, next)
    }
    (leftLimit(0, s0), rightLimit(0, s0))
  }
</scala>

これで `actionSeqs` を作る準備が整った:

<scala>
  "ActionSeqs function should"                              ^  
    """list out potential action sequences"""               ! actionSeqs1^
...
  def actionSeqs1 = {
    val s = newState(Nil, (10, 20), TKind :: TKind :: Nil)
    val seqs = agent.actionSeqs(s)
    seqs.size must_== 32
  }
</scala>

スタブする:

<scala>
  def actionSeqs(s0: GameState): Seq[Seq[StageMessage]] = Nil
</scala>

予想通りテストは失敗する:

<code>
[info] ActionSeqs function should
[error] x list out potential action sequences
[error]    '0' is not equal to '32' (AgentSpec.scala:15)
</code>

これが実装となる:

<scala>
  def actionSeqs(s0: GameState): Seq[Seq[StageMessage]] = {
    val rotationSeqs: Seq[Seq[StageMessage]] =
      (0 to orientation(s0.currentPiece.kind) - 1).toSeq map { x =>
        Nil padTo (x, RotateCW)
      }
    val translationSeqs: Seq[Seq[StageMessage]] =
      sideLimit(s0) match {
        case (l, r) =>
          ((1 to l).toSeq map { x =>
            Nil padTo (x, MoveLeft)
          }) ++
          Seq(Nil) ++
          ((1 to r).toSeq map { x =>
            Nil padTo (x, MoveRight)
          })
      }
    for {
      r <- rotationSeqs
      t <- translationSeqs
    } yield r ++ t
  }
</scala>

REPL でアウトプットを見てみる:

<scala>
scala> val s = newState(Nil, (10, 20), TKind :: TKind :: Nil)
s: com.eed3si9n.tetrix.GameState = GameState(List(Block((4,18),TKind), Block((5,18),TKind), Block((6,18),TKind), Block((5,19),TKind)),(10,20),Piece((5.0,18.0),TKind,List((-1.0,0.0), (0.0,0.0), (1.0,0.0), (0.0,1.0))),Piece((2.0,1.0),TKind,List((-1.0,0.0), (0.0,0.0), (1.0,0.0), (0.0,1.0))),List(),ActiveStatus,0)

scala> val agent = new Agent
agent: com.eed3si9n.tetrix.Agent = com.eed3si9n.tetrix.Agent@649f7367

scala> agent.actionSeqs(s)
res0: Seq[Seq[com.eed3si9n.tetrix.StageMessage]] = Vector(List(MoveLeft), List(MoveLeft, MoveLeft), List(MoveLeft, MoveLeft, MoveLeft), List(MoveLeft, MoveLeft, MoveLeft, MoveLeft), List(), List(MoveRight), List(MoveRight, MoveRight), List(MoveRight, MoveRight, MoveRight), List(RotateCW, MoveLeft), List(RotateCW, MoveLeft, MoveLeft), List(RotateCW, MoveLeft, MoveLeft, MoveLeft), List(RotateCW, MoveLeft, MoveLeft, MoveLeft, MoveLeft), List(RotateCW), List(RotateCW, MoveRight), List(RotateCW, MoveRight, MoveRight), List(RotateCW, MoveRight, MoveRight, MoveRight), List(RotateCW, RotateCW, MoveLeft), List(RotateCW, RotateCW, MoveLeft, MoveLeft), List(RotateCW, RotateCW, MoveLeft, MoveLeft, MoveLeft), List(RotateCW, RotateCW, MoveLeft, MoveLeft, MoveLeft, MoveLeft), List(RotateCW, RotateCW),...
</scala>

アクション列の一つに、現在の状態を評価する `List()` があることに注意してほしい。全てのテストが通る:

<code>
[info] ActionSeqs function should
[info] + list out potential action sequences
</code>

`actionSeqs` を使って `bestMove` を書き換えよう:

<scala>
  def bestMove(s0: GameState): StageMessage = {
    var retval: Seq[StageMessage] = Nil 
    var current: Double = minUtility
    actionSeqs(s0) foreach { seq =>
      val ms = seq ++ Seq(Drop)
      val u = utility(Function.chain(ms map {toTrans})(s0))
      if (u > current) {
        current = u
        retval = seq
      } // if
    }
    println("selected " + retval + " " + current.toString)
    retval.headOption getOrElse {Tick}
  }
</scala>

スペックを加えよう。例えば `(0, 8)` にだけ一つ穴を開けておいて、解くのには回転が何回かと `MoveRight` が何個も必要な状態はどうだろう? 以前のエージェントだと多分解けなかったはずの問題だ。

<scala>
  "Solver should"                                           ^
    """pick MoveLeft for s1"""                              ! solver1^
    """pick Drop for s3"""                                  ! solver2^
    """pick RotateCW for s5"""                              ! solver3^
...
  def s5 = newState(Seq(
      (0, 0), (1, 0), (2, 0), (3, 0), (4, 0), (5, 0), (6, 0),
      (7, 0), (9, 0))
    map { Block(_, TKind) }, (10, 20), ttt)
  def solver3 =
    agent.bestMove(s5) must_== RotateCW
</scala>

オールグリーン。次に、swing UI を走らせてみよう。

<img src="/images/tetrix-in-scala-day8b.png"/>

<code>
[info] selected List(RotateCW, MoveLeft, MoveLeft, MoveLeft, MoveLeft) 1.4316304877998318
[info] selected List(MoveLeft, MoveLeft, MoveLeft, MoveLeft) 1.4316304877998318
[info] selected List(MoveLeft, MoveLeft, MoveLeft) 1.4316304877998318
[info] selected List(MoveLeft, MoveLeft) 1.4316304877998318
[info] selected List() 1.4108824377664941
</code>

動作がまだ近視眼的だけど、合理性の鱗片が見えてきたと思う。続きはまた明日。

<code>
$ git fetch origin
$ git co day8 -b try/day8
$ sbt "project swing" run
</code>
