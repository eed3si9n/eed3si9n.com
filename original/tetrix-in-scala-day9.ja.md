  [day8]: http://eed3si9n.com/ja/tetrix-in-scala-day8

[昨日][day8]はヒューリスティック関数を直し、また現在のピースの 36 通りの可能な位置と向きを評価することで tetrix を解くエージェントが少しはましなゲームをプレイできるようにした。

### ストップウォッチ

あるコードの一部にかかる時間を測定するための関数を書いてみよう:

<scala>
  private[this] def stopWatch[A](name: String)(arg: => A): A = {
    val t0 = System.currentTimeMillis
    val retval: A = arg
    val t1 = System.currentTimeMillis
    println(name + " took " + (t1 - t0).toString + " ms")
    retval
  }
</scala>

これは以下のように使える:

<scala>
    stopWatch("bestMove") {
      // do something
    } // stopWatch
</scala>

出力はこうなる:

<code>
[info] Running com.tetrix.swing.Main 
[info] bestMove took 84 ms
[info] selected List(MoveLeft, MoveLeft, MoveLeft, MoveLeft) -0.3
[info] bestMove took 43 ms
[info] selected List(MoveLeft, MoveLeft, MoveLeft) -0.3
[info] bestMove took 24 ms
[info] selected List(MoveLeft, MoveLeft) -0.3
[info] bestMove took 22 ms
[info] selected List(MoveLeft) -0.3
[info] bestMove took 26 ms
[info] selected List() -0.3
[info] bestMove took 17 ms
[info] selected List() -0.3
[info] bestMove took 10 ms
[info] selected List() -0.3
[info] bestMove took 8 ms
[info] selected List() -0.3
[info] bestMove took 11 ms
[info] selected List() -0.3
[info] bestMove took 13 ms
[info] selected List() -0.3
</code>

JIT コンパイラが効いてくる初期は時間が短縮していって、あとはだいたい 10ミリ秒ぐらいに落ち着く。これでだいたいどれぐらいの時間を扱っているのかが分かった。

### 第二段階

探索木を 2つ目のピースに拡張すると大まかに 36倍の時間がかかることになる。360ミリ秒は悪くない。やってみよう:

<scala>
  def bestMove(s0: GameState): StageMessage = {
    var retval: Seq[StageMessage] = Nil 
    var current: Double = minUtility
    stopWatch("bestMove") {
      val nodes = actionSeqs(s0) map { seq =>
        val ms = seq ++ Seq(Drop)
        val s1 = Function.chain(ms map {toTrans})(s0)
        val u = utility(s1)
        if (u > current) {
          current = u
          retval = seq
        } // if
        SearchNode(s1, ms, u)
      }
      nodes foreach { node =>
        actionSeqs(node.state) foreach { seq =>
          val ms = seq ++ Seq(Drop)
          val s2 = Function.chain(ms map {toTrans})(node.state)
          val u = utility(s2)
          if (u > current) {
            current = u
            retval = node.actions ++ seq
          } // if
        }
      }
    } // stopWatch
    println("selected " + retval + " " + current.toString)
    retval.headOption getOrElse {Tick}
  }
</scala>

手筋が良くなってきている。思考時間は 12ミリ秒から 727ミリ秒ぐらいまで範囲があるけど、100 から 200ミリ秒ぐらいにだいたい収まっている。

<img src="/images/tetrix-in-scala-day9.png"/>

腕が上がってきたのでピースを落とさせてあげることにする:

<scala>
class AgentActor(stageActor: ActorRef) extends Actor {
  private[this] val agent = new Agent

  def receive = {
    case BestMove(s: GameState) =>
      val message = agent.bestMove(s)
      stageActor ! message
  }
}
</scala>

### ライン数

消したライン数を swing UI に表示しよう。

<scala>
    val unit = blockSize + blockMargin
    g drawString ("lines: " + view.lineCount.toString, 12 * unit, 7 * unit)
</scala>

これでエージェントに加える変更が性能の向上につながっているかを追跡しやすくなる。

<img src="/images/tetrix-in-scala-day9b.png"/>

### 虫歯

エージェントがゲームをプレイするのを見てて思うのが、虫歯を作るのを何とも思っていないということだ。埋まってないスポットの上に 1つまたは複数のブロックがある状態のことを虫歯と呼んでいる。

<code>
-fig 1----


      xxxx
xxxx x xxx 
x x xxxxxx 
----------
</code>

高さによるペナルティを回避するために、例えば凸凹の表面に I字のバーを垂直に落とすのではなく、平らに寝かせたりする。僕としては虫歯を最小化して以下のようにプレイしてほしい:

<code>
-fig 2-----

   x 
   x  xxxx
   x x xxx 
x xxxxxxxx 
----------
</code>

最初の 4列に注目して高さによるペナルティを計算してみよう。

<scala>
scala> val fig1 = math.sqrt(List(2, 2, 2, 2) map { x => x * x } sum)
fig1: Double = 4.0

scala> val fig2 = math.sqrt(List(1, 0, 4, 1) map { x => x * x } sum)
fig2: Double = 4.242640687119285
</scala>

予想通り fig1 の方がペナルティが低くなる。別のブロックを覆っている全てのブロックに対しても、高さ*高さのべナルティを課そう。新しいペナルティは以下のとおり:

<scala>
scala> val fig1b = math.sqrt(List(2, 2, 2, 2, 2, 2) map { x => x * x } sum)
fig1b: Double = 4.898979485566356

scala> val fig2b = math.sqrt(List(1, 0, 4, 1) map { x => x * x } sum)
fig2b: Double = 4.242640687119285
</scala>

今回は fig2 の方が優先される。スペックに書いてみよう:

<scala>
  def penalty2 = {
    val s = newState(Seq(
      (0, 0), (2, 0), (0, 1), (1, 1), (2, 1), (3, 1))
      map { Block(_, TKind) }, (10, 20), TKind :: TKind :: Nil)
    agent.penalty(s) must beCloseTo(4.89, 0.01) 
  }
</scala>

期待通りテストは失敗する:

<code>
[info] Penalty function should
[info] + penalize having blocks stacked up high
[error] x penalize having blocks covering other blocks
[error]    4.0 is not close to 4.89 +/- 0.01 (AgentSpec.scala:13)
</code>

REPL を使って実装する:

<scala>
scala>     val s = newState(Seq(
             (0, 0), (2, 0), (0, 1), (1, 1), (2, 1), (3, 1))
             map { Block(_, TKind) }, (10, 20), TKind :: TKind :: Nil)
s: com.eed3si9n.tetrix.GameState = GameState(List(Block((0,0),TKind), Block((2,0),TKind), Block((0,1),TKind), Block((1,1),TKind), Block((2,1),TKind), Block((3,1),TKind), Block((4,18),TKind), Block((5,18),TKind), Block((6,18),TKind), Block((5,19),TKind)),(10,20),Piece((5.0,18.0),TKind,List((-1.0,0.0), (0.0,0.0), (1.0,0.0), (0.0,1.0))),Piece((2.0,1.0),TKind,List((-1.0,0.0), (0.0,0.0), (1.0,0.0), (0.0,1.0))),List(),ActiveStatus,0)

scala> val groupedByX = s.unload(s.currentPiece).blocks map {_.pos} groupBy {_._1}
groupedByX: scala.collection.immutable.Map[Int,Seq[(Int, Int)]] = Map(3 -> List((3,1)), 1 -> List((1,1)), 2 -> List((2,0), (2,1)), 0 -> List((0,0), (0,1)))

scala> groupedByX map { case (k, vs) => vs.map(_._2).sorted.zipWithIndex }
res14: scala.collection.immutable.Iterable[Seq[(Int, Int)]] = List(List((1,0)), List((1,0)), List((0,0), (1,1)), List((0,0), (1,1)))

scala> groupedByX map { case (k, vs) => vs.map(_._2).sorted.zipWithIndex.dropWhile(x => x._1 == x._2) }
res15: scala.collection.immutable.Iterable[Seq[(Int, Int)]] = List(List((1,0)), List((1,0)), List(), List())

scala> val coverups = groupedByX flatMap { case (k, vs) => vs.map(_._2).sorted.zipWithIndex.dropWhile(x => x._1 == x._2).map(_._1 + 1) }
coverups: scala.collection.immutable.Iterable[Int] = List(2, 2)
</scala>

できあがった `penalty` だ:

<scala>
  def penalty(s: GameState): Double = {
    val groupedByX = s.unload(s.currentPiece).blocks map {_.pos} groupBy {_._1}
    val heights = groupedByX map { case (k, v) => v.map({_._2 + 1}).max }
    val coverups = groupedByX flatMap { case (k, vs) => 
      vs.map(_._2).sorted.zipWithIndex.dropWhile(x => x._1 == x._2).map(_._1 + 1) }
    math.sqrt( (heights ++ coverups) map { x => x * x } sum)
  }
</scala>

これでテストが通る:

<scala>
[info] Penalty function should
[info] + penalize having blocks stacked up high
[info] + penalize having blocks covering other blocks
</scala>

ゲームをプレイさせてみよう:

<img src="/images/tetrix-in-scala-day9c.png"/>

虫歯の回避はうまくいったが、効きすぎているかもしれない。明日に段差のペナルティを再び導入する必要があるかもしれない。

<code>
$ git fetch origin
$ git co day9 -b try/day9
$ sbt "project swing" run
</code>
