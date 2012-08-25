  [day5]: http://eed3si9n.com/tetrix-in-scala-day5
  [russell]: http://aima.cs.berkeley.edu/
  [amazon2]: http://www.amazon.co.jp/dp/4320122151

[昨日][day5]は 2つ目のアクターを導入することでゲームの状態へのアクセスの並行処理を改善した。並行処理を司る強力なツールを手に僕達は新しい旅に出ることができる。例えば人類の制覇だ。tetrix プレーヤーひとりづつ。

### Russell と Norvig

大学で計算機科学を専攻に選んだ理由の一つが AI について習うことだった。しかし、実際始まってみると最初の数年間の講義では一切 AI のようなものが出て来なかったのでかなりガッカリした。そこである夏の産学連携 (co-op) インターンシップのときに早起きしてスターバックスに行き、頭の良さそうな大学で AI を教えるのに使っている教科書を読んでみることに決めた。そうして見つけたのが Russell と Norvig の [Artificial Intelligence: A Modern Approach (AIMA)][russell]だ (邦訳は[エージェントアプローチ人工知能 第2版][amazon2])。

衝撃的な本だった。人間のようなロボットを作ろうとするのではなく、合理的に**行動**するエージェントという概念を導入した。

> **エージェント**とは、センサを用いてその環境を認識し、アクチュエータを用いて環境に対して行動を取ることができる全てのものだ。

合理的エージェントの構造の一つにモデルベース、効用ベースエージェントというものがある。

<code>
+-エージェント--------------+   +-環境-+ 
|           センサ        <=====     |
|     状態 <----+          |   |     |
|              |          |   |     |
|   アクションAを実行すると   |   |     |
|   どうなるだろう?         |    |     |
|              |          |   |     |
| どれだけ幸せになれるだろう?  |   |     |
|              |          |   |     |
|     効用 <----+          |   |     |
|              |          |   |     |
|  次に何をするべきだろう?    |   |     |
|              |          |   |     |
|        アクチュエータ      =====>    |
+-------------------------+   +-----+
</code>

> 効用関数 (utility function) は状態 (もしくは一連の状態の列) を関連する幸せさの度合いを表す実数に投射する。

ガツンと来ない? この構造によれば知的にみえるプログラムを構築するのに必要なものはステートマシン (できた!)、効用関数、それから木探索アルゴリズムだけだ。結局データ構造やグラフ理論の講義が役に立つということだ。

### 効用関数

効用ベースのエージェントの場合は、効用関数の作り方が鍵となる。多分今後いじっていく事になるけどまずはシンプルなものから始めよう。今のところは、幸せさは死んでいないことと、消したラインだと定義する。消極的に聞こえるかもしれないけど、tetrix は負けない事を競うゲームだ。1対1 の tetrix では明確な勝利の定義は無い。対戦相手が負けることでデフォルトとして勝者が決まる。

新しいスペックを作ってこれを記述してみよう:

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

次に `Agent` クラスを始めて `utility` メソッドをスタブする:

<scala>
package com.eed3si9n.tetrix

class Agent {
  def utility(state: GameState): Double = 0.0
}
</scala>

期待通り 2つ目の例で失敗する:

<code>
[info] Utility function should
[info] + evaluate initial state as 0.0,
[error] x evaluate GameOver as -1000.0.
[error]    '0.0' is not equal to '-1000.0' (AgentSpec.scala:8)
</code>

直そう:

<scala>
  def utility(state: GameState): Double =
    if (state.status == GameOver) -1000.0
    else 0.0
</scala>

オールグリーン。特にリファクタリングするものも無い。

### ライン

僕らのエージェントの幸せさは消したラインだと定義されているため、その数を覚えておく必要がある。これは `StageSpec` に入る:

<scala>
  "Deleting a full row should"                              ^
    """increment the line count."""                         ! line1^
...
  def line1 =
    (s3.lineCount must_== 0) and
    (Function.chain(Nil padTo (19, tick))(s3).
    lineCount must_== 1)
</scala>

`GameState` に `lineCount` を加えたもの:

<scala>
case class GameState(blocks: Seq[Block], gridSize: (Int, Int),
    currentPiece: Piece, nextPiece: Piece, kinds: Seq[PieceKind],
    status: GameStatus, lineCount: Int) {
  def view: GameView = GameView(blocks, gridSize,
    currentPiece.current, (4, 4), nextPiece.current,
    status, lineCount)
}
</scala>

期待通りテストは失敗:

<code>
[info] Deleting a full row should
[error] x increment the line count.
[error]    '0' is not equal to '1' (StageSpec.scala:91)
</code>

`Stage` クラスにおいて、埋まった行が消されているのは `tick` から呼ばれている `clearFullRow` 関数のみだ:

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

ちょっと見た目が怖いけど、実際のラインの消去が行われいるのが `s.copy(blocks = ...)` だと気づくだけでいい。その直後に `lineCount` を付けるだけだ:

<scala>
s.copy(blocks = ...,
  lineCount = s.lineCount + 1)
</scala>

これでテストは通った:

<code>
[info] Deleting a full row should
[info] + increment the line count.
</code>

これを効用関数に組み込む。

<scala>
    """evaluate an active state by lineCount"""             ! utility3^
...
  def utility3 = {
    val s = Function.chain(Nil padTo (19, tick))(s3)
    agent.utility(s) must_== 1.0
  }
</scala>

再び期待通りテストが失敗する:

<code>
[error] x evaluate an active state by lineCount
[error]    '0.0' is not equal to '1.0' (AgentSpec.scala:9)
</code>

これは簡単だ:

<scala>
  def utility(state: GameState): Double =
    if (state.status == GameOver) -1000.0
    else state.lineCount.toDouble
</scala>

### 探索による問題解決

僕らのエージェントがどれだけ幸せかが分かるようになった所で、「人間だけには tetrix に負けない」という抽象的な問題を木の探索という問題に変えることができた。どの時点においても、エージェントとスケジュールされたタイマーは今まで何度も見た 5つのうち 1つのアクションを取ることができる:

<scala>
  def receive = {
    case MoveLeft  => updateState {moveLeft}
    case MoveRight => updateState {moveRight}
    case RotateCW  => updateState {rotateCW}
    case Tick      => updateState {tick}
    case Drop      => updateState {drop}
  }
</scala>

言い換えると、`bestMove` とは `GameState => StageMessage` の関数だ。これが木とどう関係あるって? 初期状態 `s0` (time=0 とする) において、エージェントは 5つのアクションを取れる: `MoveLeft`, `MoveRight`, etc。これらのアクションは 5つの状態 `s1`, `s2`, `s3`, `s4`, `s5` (time=1 とする) を生み出す。さらに、それぞれの状態はまた 5つに `s11`, `s12`, ..., `s55` と分岐する。これを絵に描くと木構造が見えてくる。

<code>
                                                  s0
                                                  |
        +--------------------+--------------------+-------...
        s1                   s2                   s3
        |                    |                    |
+---+---+---+---+    +---+---+---+---+    +---+---+---+---+ 
s11 s12 s13 s14 s15  s21 s22 s23 s24 s25  s31 s32 s33 s34 s35
</code>

ノード数は指数関数的に増える。`1 + 5 + 5^2`。まずは 1段階から始めよう。

テストは以下のように構築する。まず `s3` という名前の `Drop` アクションをするだけでラインが一つ消える状態を用意する。エージェントにアクションを選ばせると `Drop` を選択するべきだ。陰性対照として、もう一つ別の状態 `s1` を用意する。これは特にどのアクションを選んでもいい:

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

以下がスタブだ:

<scala>
  def bestMove(state: GameState): StageMessage = MoveLeft
</scala>

期待通りテストは失敗する。

<code>
[info] Solver should
[info] + pick MoveLeft for s1
[error] x pick Drop for s3
[error]    'MoveLeft' is not equal to 'Drop' (AgentSpec.scala:13)
</code>

続きはまた[明日](http://eed3si9n.com/ja/tetrix-in-scala-day7)。

<code>
$ git fetch origin
$ git co day6 -b try/day6
$ sbt "project swing" run
</code>
