  [day6]: http://eed3si9n.com/tetrix-in-scala-day6

[昨日][day6]から tetrix を解く AI という新たな問題に取り組みはじめた。Russell と Norvig は合理的なエージェントの構造がステートマシン、効用関数、木探索アルゴリズムから構成できるという洞察を与えてくれた。僕らにあるのは最初の 2つと失敗しているテストだ:

<code>
[info] Solver should
[info] + pick MoveLeft for s1
[error] x pick Drop for s3
[error]    'MoveLeft' is not equal to 'Drop' (AgentSpec.scala:13)
</code>

まず既に知っていること、つまり可能な動きとそれに対応した状態遷移関数を書きだしておく必要がある。

<scala>
  private[this] val possibleMoves: Seq[StageMessage] =
    Seq(MoveLeft, MoveRight, RotateCW, Tick, Drop)
  private[this] def toTrans(message: StageMessage): GameState => GameState =
    message match {
      case MoveLeft  => moveLeft
      case MoveRight => moveRight
      case RotateCW  => rotateCW
      case Tick      => tick
      case Drop      => drop 
    }
</scala>

「アクションAを実行するとどうなるだろう?」を実装するためには、`possibleMoves`, `toTrans`, それと渡された `s0` を使って次の状態をシミュレートする。`utility` 関数を使って幸せさを計算して、効用を最大化する動きを選べばいい。

<scala>
  def bestMove(s0: GameState): StageMessage = {
    var retval: StageMessage = MoveLeft 
    var current: Double = minUtility
    possibleMoves foreach { move =>
      val u = utility(toTrans(move)(s0))
      if (u > current) {
        current = u
        retval = move 
      } // if
    }
    retval
  }
</scala>

実装が手続き型になったしまったが、メソッドの中なので問題ない。これでソルバーの最初のバージョンができた。エージェントがズルをするのを防ぐため、エージェントアクターに `BestMove(s)` メッセージを送る `GameMasterActor` を作る必要がある:

<scala>
sealed trait AgentMessage
case class BestMove(s: GameState) extends AgentMessage
</scala>

これがアクターの実装だ:

<scala>
class AgentActor(stageActor: ActorRef) extends Actor {
  private[this] val agent = new Agent

  def receive = {
    case BestMove(s: GameState) =>
      val message = agent.bestMove(s)
      println("selected " + message)
      stageActor ! message
  }
}

class GameMasterActor(stateActor: ActorRef, agentActor: ActorRef) extends Actor {
  def receive = {
    case Tick => 
      val s = getState
      if (s.status != GameOver) {
        agentActor ! BestMove(getState)
      } 
  }
  private[this] def getState: GameState = {
    val future = (stateActor ? GetState)(1 second).mapTo[GameState]
    Await.result(future, 1 second)
  } 
}
</scala>

これは意外なほどシンプルだが強力だ。最良の動きを計算する理由は実際にその動きをすることなので、エージェントアクターは `stageActor` に直接送信している。組み立ててみよう:

<scala>
  private[this] val system = ActorSystem("TetrixSystem")
  private[this] val stateActor = system.actorOf(Props(new StateActor(
    initialState)), name = "stateActor")
  private[this] val playerActor = system.actorOf(Props(new StageActor(
    stateActor)), name = "playerActor")
  private[this] val agentActor = system.actorOf(Props(new AgentActor(
    playerActor)), name = "agentActor")
  private[this] val masterActor = system.actorOf(Props(new GameMasterActor(
    stateActor, agentActor)), name = "masterActor")
  private[this] val tickTimer = system.scheduler.schedule(
    0 millisecond, 700 millisecond, playerActor, Tick)
  private[this] val masterTickTimer = system.scheduler.schedule(
    0 millisecond, 700 millisecond, masterActor, Tick)
</scala>

### 動いた!

swing UI を起動すると、エージェントがゲームを乗っ取って tetrix を解きはじめる!:

<code>
[info] Running com.tetrix.swing.Main 
[info] selected MoveLeft
[info] selected MoveLeft
[info] selected MoveLeft
[info] selected MoveLeft
[info] selected MoveLeft
[info] selected MoveLeft
[info] selected MoveLeft
[info] selected MoveLeft
[info] selected MoveLeft
[info] selected MoveLeft
[info] selected MoveLeft
[info] selected MoveLeft
[info] selected MoveLeft
...
</code>

<img src="/images/tetrix-in-scala-day7.png"/>

頭が悪すぎる!

探索木が浅すぎるため効用関数の違いが出てくる所まで到達していないからだ。デフォルトで `MoveLeft` を選択している。最初のオプションは探索木を深くしてより多くの動作をみることだ。いずれは取り組む必要があるけど、結局は問題全般の解決にはならない。第一に、ノード数は指数関数的に増えることを思い出してほしい。第二に、確実に分かっているピースが 2つしかないという問題がある。

### ヒューリスティック関数

作戦B はヒューリスティック関数を導入することだ。

> *h(n)* = ノード *n* からゴールのノードまでの最も安価なコースにかかるコストの見積り

正確には僕らにはゴールとなるノードが無いため、この用語は当てはまらないかもしれないけど、概要としては現状を近似化して木探索を正しい方向につついてやることだ。この場合は、悪い陣形に対するペナルティを作ると考えることができる。例えば、列と列の間に 2つ以上の高さの差があることに対してペナルティを加えよう。差を自乗してペナルティが段階的に厳しくなっていくようにする。

<scala>
    """penalize having gaps between the columns"""          ! utility4^
...
  def utility4 = {
    val s = newState(Seq(
      (0, 0), (0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6))
      map { Block(_, TKind) }, (10, 20), TKind :: TKind :: Nil)
    agent.utility(s) must_== -36.0
  }
</scala>

期待通りテストは失敗する:

<code>
[info] Utility function should
[info] + evaluate initial state as 0.0,
[info] + evaluate GameOver as -1000.0,
[info] + evaluate an active state by lineCount
[error] x penalize having gaps between the columns
[error]    '0.0' is not equal to '-36.0' (AgentSpec.scala:10)
</code>

これは REPL を使って解いてみよう。sbt から `console` と打ち込む。

<scala>
Welcome to Scala version 2.9.2 (Java HotSpot(TM) 64-Bit Server VM, Java 1.6.0_33).
Type in expressions to have them evaluated.
Type :help for more information.

scala> import com.eed3si9n.tetrix._
import com.eed3si9n.tetrix._

scala> import Stage._
import Stage._

scala> val s = newState(Seq(
         (0, 0), (0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6))
         map { Block(_, TKind) }, (10, 20), TKind :: TKind :: Nil)
s: com.eed3si9n.tetrix.GameState = GameState(List(Block((0,0),TKind), Block((0,1),TKind), Block((0,2),TKind), Block((0,3),TKind), Block((0,4),TKind), Block((0,5),TKind), Block((0,6),TKind), Block((4,18),TKind), Block((5,18),TKind), Block((6,18),TKind), Block((5,19),TKind)),(10,20),Piece((5.0,18.0),TKind,List((-1.0,0.0), (0.0,0.0), (1.0,0.0), (0.0,1.0))),Piece((2.0,1.0),TKind,List((-1.0,0.0), (0.0,0.0), (1.0,0.0), (0.0,1.0))),List(),ActiveStatus,0)

scala> s.blocks map {_.pos} groupBy {_._1}
res0: scala.collection.immutable.Map[Int,Seq[(Int, Int)]] = Map(5 -> List((5,18), (5,19)), 4 -> List((4,18)), 6 -> List((6,18)), 0 -> List((0,0), (0,1), (0,2), (0,3), (0,4), (0,5), (0,6)))
</scala>

これはまずい。現在のピースが `s.blocks` に入り込んでいる。`unload` は `Stage` オブジェクト内のプレイベートなメソッドだ。`GameState` クラスにリファクタリングしてみる:

<scala>
case class GameState(blocks: Seq[Block], gridSize: (Int, Int),
    currentPiece: Piece, nextPiece: Piece, kinds: Seq[PieceKind],
    status: GameStatus, lineCount: Int) {
  def view: GameView = ...
  def unload(p: Piece): GameState = {
    val currentPoss = p.current map {_.pos}
    this.copy(blocks = blocks filterNot { currentPoss contains _.pos })
  }
  def load(p: Piece): GameState =
    this.copy(blocks = blocks ++ p.current)
}
</scala>

`Stage` を調整すると今のテスト意外は全て通過した。REPL に戻ろう:

<scala>
... 上に同じ ...

scala> s.unload(s.currentPiece)
res0: com.eed3si9n.tetrix.GameState = GameState(List(Block((0,0),TKind), Block((0,1),TKind), Block((0,2),TKind), Block((0,3),TKind), Block((0,4),TKind), Block((0,5),TKind), Block((0,6),TKind)),(10,20),Piece((5.0,18.0),TKind,List((-1.0,0.0), (0.0,0.0), (1.0,0.0), (0.0,1.0))),Piece((2.0,1.0),TKind,List((-1.0,0.0), (0.0,0.0), (1.0,0.0), (0.0,1.0))),List(),ActiveStatus,0)

scala> s.unload(s.currentPiece).blocks map {_.pos} groupBy {_._1}
res1: scala.collection.immutable.Map[Int,Seq[(Int, Int)]] = Map(0 -> List((0,0), (0,1), (0,2), (0,3), (0,4), (0,5), (0,6)))

scala> val heights = s.unload(s.currentPiece).blocks map {_.pos} groupBy {_._1} map { case (k, v) => (k, v.map({_._2}).max) }
heights: scala.collection.immutable.Map[Int,Int] = Map(0 -> 6)

scala> heights.getOrElse(1, 0)
res6: Int = 0

scala> (0 to s.gridSize._1 - 2)
res7: scala.collection.immutable.Range.Inclusive = Range(0, 1, 2, 3, 4, 5, 6, 7, 8)

scala> val gaps = (0 to s.gridSize._1 - 2).toSeq map { x => heights.getOrElse(x, 0) - heights.getOrElse(x + 1, 0) }
gaps: scala.collection.immutable.IndexedSeq[Int] = Vector(6, 0, 0, 0, 0, 0, 0, 0, 0)

scala> val gaps = (0 to s.gridSize._1 - 2).toSeq map { x => heights.getOrElse(x, 0) - heights.getOrElse(x + 1, 0) } filter {_ > 1}
gaps: scala.collection.immutable.IndexedSeq[Int] = Vector(6)

scala> gaps map {x => x * x} sum
res5: Int = 36
</scala>

実際には上にあるよりも多くの打ち間違いや実験を行った。だけど、何をやってるかは分ってもらえると思う。REPL を使って段階的に演算をつなげていくことで式を構築することができる。答が得られたらそれをエディタにコピペすればいい:

<scala>
  def utility(state: GameState): Double =
    if (state.status == GameOver) minUtility
    else state.lineCount.toDouble - penalty(state)
  private[this] def penalty(s: GameState): Double = {
    val heights = s.unload(s.currentPiece).blocks map {_.pos} groupBy {
      _._1} map { case (k, v) => (k, v.size) }
    val gaps = (0 to s.gridSize._1 - 2).toSeq map { x =>
      heights.getOrElse(x, 0) - heights.getOrElse(x + 1, 0) } filter {_ > 1}
    gaps map {x => x * x} sum
  }
</scala>

テストは通過するようになった。

<code>
[info] Utility function should
[info] + evaluate initial state as 0.0,
[info] + evaluate GameOver as -1000.0,
[info] + evaluate an active state by lineCount
[info] + penalize having gaps between the columns
</code>

現在のソルバーにはもう一つ問題がある。`Drop` 以外は現在のピースが空中に浮かんでいるため評価の対象にならないということだ。これを解決するには既に落ちていなければ `Drop` を後ろに追加すればいい。これはまず実装を変えてみてどのテストが失敗するかみてみよう:

<scala>
  def bestMove(s0: GameState): StageMessage = {
    var retval: StageMessage = MoveLeft 
    var current: Double = minUtility
    possibleMoves foreach { move =>
      val ms = 
        if (move == Drop) move :: Nil
        else move :: Drop :: Nil 
      val u = utility(Function.chain(ms map {toTrans})(s0))
      if (u > current) {
        current = u
        retval = move 
      } // if
    }
    retval
  }
</scala>

`Function.chain` を使った遷移関数の合成が再び出てきた。じゃあ、テストを走らせてみよう。

<code>
[info] Solver should
[info] + pick MoveLeft for s1
[error] x pick Drop for s3
[error]    'Tick' is not equal to 'Drop' (AgentSpec.scala:14)
</code>

これは驚くことではない。`Drop` を最後に追加したため、`Tick` と `Drop` の違いが無くなったというだけだ。スペックを緩和して直す:

<scala>
  def solver2 =
    agent.bestMove(s3) must beOneOf(Drop, Tick)
</scala>

これでエージェントは `MoveLeft` 以外の動作も選びはじめたけども、まだグリッドの左にかなり偏っている。

<img src="/images/tetrix-in-scala-day7b.png"/>

探索木を深くすればましになってくれると思う。続きはまた[明日](http://eed3si9n.com/ja/tetrix-in-scala-day8)。

<code>
$ git fetch origin
$ git co day7 -b try/day7
$ sbt "project swing" run
</code>
