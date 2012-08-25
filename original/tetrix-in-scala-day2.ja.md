  [day1]: http://eed3si9n.com/tetrix-in-scala-day1
  [collection]: http://scalajp.github.com/scala-collections-doc-ja/collections_3.html
  [amazon]: http://www.amazon.co.jp/dp/4798125415

今日は、[昨日][day1]からの続きで失敗しているテストがある。これは、趣味のプロジェクトの場合は一日の作業を終えるのに便利な方法だ。

<code>
[info] Moving to the left the current piece should
[info] + change the blocks in the view,
[error] x as long as it doesn't hit the wall
[error]    '(0,0), (-1,17), (0,17), (1,17), (0,18)' doesn't contain in order '(0,0), (0,17), (1,17), (2,17), (1,18)' (StageSpec.scala:8)
</code>

最後に自分が何をやっていて、次に何をするべきなのかを探るのに 5分以上かかってしまうこともある。失敗しているテストは未来の自分へ「次にやるのはこれ!」とメッセージを残しておくようなものだ。

### 検証

まず現行の `moveBy` の実装をみてみよう:

<scala>
  private[this] def moveBy(delta: (Double, Double)): this.type = {
    val unloaded = unload(currentPiece, blocks)
    val moved = currentPiece.moveBy(delta)
    blocks = load(moved, unloaded)
    currentPiece = moved
    this
  }
</scala>

`moved` を検証して `moved.current`内の全てのブロックが範囲内に収まってるかをチェックするだけでいい。[Scala コレクションライブラリ][collection] にある `forall` メソッドが正にこの用途にあっている。[Scala 逆引きレシピ][amazon]だと、「118: List の要素が条件を満たすか調べたい」が参考になる。`if` 文をループさせるようなことはここでは必要ない:

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

これでテストはパスするはずだ:

<code>
[info] Moving to the left the current piece should
[info] + change the blocks in the view,
[info] + as long as it doesn't hit the wall
</code>

### 回転

ピースが動くようになった所で、回転もやってみよう。初期位置 `(5, 17)` にある T字のピースと `(0, 0)` にあるブロックというハードコードされた初期状態を仮定すると、以下のようなスペックとなる:

<scala>
  "Rotating the current piece should"                       ^
    """change the blocks in the view."""                    ! rotate1^

...

  def rotate1 =
    stage.rotateCW().view.blocks map {_.pos} must contain(
      (0, 0), (5, 18), (5, 17), (5, 16), (6, 17)
    ).only.inOrder
</scala>

`Stage` クラスには `rorateCW()` メソッドがまだないため、これはコンパイルさえしないはずだ。

<code>
[error] /Users/eed3si9n/work/tetrix.scala/library/src/test/scala/StageSpec.scala:33: value rorateCCW is not a member of com.eed3si9n.tetrix.Stage
[error]     stage.rotateCW().view.blocks map {_.pos} must contain(
[error]           ^
[error] one error found
[error] (library/test:compile) Compilation failed
</code>

最低限コンパイルは通るようにスタブを作る:

<scala>
  def rotateCW() = this
</scala>

これでまたテストが失敗するようになった。

まず、ピースの回転を実装する:

<scala>
  def rotateBy(theta: Double): Piece = {
    val c = math.cos(theta)
    val s = math.sin(theta)
    def roundToHalf(v: (Double, Double)): (Double, Double) =
      (math.round(v._1 * 2.0) * 0.5, math.round(v._2 * 2.0) * 0.5)
    copy(locals = locals map { case(x, y) => (x * c - y * s, x * s + y * c) } map roundToHalf)
  }
</scala>

次に、`moveBy` メソッドをコピペ (!) して `rotateBy` に変える:

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

テストは通過した:

<code>
[info] Rotating the current piece should
[info] + change the blocks in the view.
</code>

## リファクタリング

レッド、グリーン、リファクター。コピペした `rotateBy` を直そう。`Piece => Piece` の関数を受け取れば二つのメソッドの共通部分を抽出することができる。[Scala 逆引きレシピ][amazon]だと、「053: 関数を定義したい」、「054: 関数を引数として渡したい」が参考になる:

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

これで一発で `moveBy` と `rotateBy` を無くすことができた! テストを再び実行して何も壊れなかったかを確認する。

<code>
[info] Passed: : Total 4, Failed 0, Errors 0, Passed 4, Skipped 0
</code>

### 関数型へのリファクタリング

`Stage` クラスはだんだんいい形に仕上がってきてるが、二つの `var` があるのが気に入らない。状態はそれを保持する独自のクラスに追い出して `Stage` はステートレスにしよう。

<scala>
case class GameState(blocks: Seq[Block], gridSize: (Int, Int), currentPiece: Piece) {
  def view: GameView = GameView(blocks, gridSize, currentPiece.current)
}
</scala>

新しい状態を作るための `newState` メソッドを定義する:

<scala>
  def newState(blocks: Seq[Block]): GameState = {
    val size = (10, 20)
    def dropOffPos = (size._1 / 2.0, size._2 - 3.0)
    val p = Piece(dropOffPos, TKind)
    GameState(blocks ++ p.current, size, p)
  }
</scala>

それぞれの「動作」をオブジェクトへのメソッドの呼び出しと考える代わりに、一つの状態から別の状態への遷移だと考えることができる。`transformPiece` に一工夫して遷移関数を生成してみよう:

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

これで少し関数型な感じがするようになった。`transit` か実際に状態遷移関数を返しているかは型シグネチャが保証する。`Stage` がステートレスになったところで、これをシングルトンオブジェクトに変えることができる。

合わせてスペックも変更する:

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

可変実装の `moveLeft` は `this` を返したため連鎖 (chain) させることができた。新しい実装ではどうやって `leftWall1` を処理すればいいだろう? メソッドの代わりに純粋関数がある。これらは `Function.chain` を使って合成できる:

<scala>
  def leftWall1 =
    Function.chain(moveLeft :: moveLeft :: moveLeft :: moveLeft :: moveLeft :: Nil)(s1).
      blocks map {_.pos} must contain(
      (0, 0), (0, 17), (1, 17), (2, 17), (1, 18)
    ).only.inOrder
</scala>

`Function.chain` は `Seq[A => A]` を受け取って `A => A` の関数に変える。僕達は、この小さい部分だけだけど、コードの一部をデータ扱いしていると考えることができる。

### 当たり判定

3D ゲームだとリアルタイムでの当たり判定だけで本が一冊書ける。2D の落ちゲーの場合は Scala コレクションを使うと一行で書ける。シナリオをスペックで記述してみよう:

<scala>
  val s2 = newState(Block((3, 17), TKind) :: Nil)
  def leftHit1 =
    moveLeft(s2).blocks map {_.pos} must contain(
      (3, 17), (4, 17), (5, 17), (6, 17), (5, 18)
    ).only.inOrder
</scala>

これは期待通り失敗してくれる:

<code>
[error] x or another block in the grid.
[error]    '(3,17), (3,17), (4,17), (5,17), (4,18)' doesn't contain in order '(3,17), (4,17), (5,17), (6,17), (5,18)' (StageSpec.scala:9)
</code>

これが当たり判定を加えた `validate` メソッドだ:

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

### 時計

`moveLeft` と `moveRight` があるが、`moveDown` が無い。これは下向きの動きが他にもすることがあるからだ。床か別のブロックに当たり判定が出た場合は、現在のピースが固まって、新しいピースが送り込まれる。

まずは、動きから:

<scala>
  "Ticking the current piece should"                        ^
    """change the blocks in the view."""                    ! tick1^ 

...

  def tick1 =
    tick(s1).blocks map {_.pos} must contain(
      (0, 0), (4, 16), (5, 16), (6, 16), (5, 17)
    ).only.inOrder
</scala>

取り敢えずテストが通過するように `moveBy` を使って `tick` を実装する:

<scala>
  val tick      = transit { _.moveBy(0.0, -1.0) }
</scala>

次に、新しいピースの転送:

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

`transit` メソッドは既に変更された状態の妥当性を知ってる。現在は `getOrElse` を使って古い状態を返しているだけだけど、そこで別のアクションを実行すればいい。

<scala>
  private[this] def transit(trans: Piece => Piece,
      onFail: GameState => GameState = identity): GameState => GameState =
    (s: GameState) => validate(s.copy(
        blocks = unload(s.currentPiece, s.blocks),
        currentPiece = trans(s.currentPiece))) map { case x =>
      x.copy(blocks = load(x.currentPiece, x.blocks))
    } getOrElse {onFail(s)}
</scala>

`onFail` が渡されなければ `identity` 関数が用いられる。以下が `tick` だ:

<scala>
  val tick = transit(_.moveBy(0.0, -1.0), spawn)
  
  private[this] def spawn(s: GameState): GameState = {
    def dropOffPos = (s.gridSize._1 / 2.0, s.gridSize._2 - 3.0)
    val p = Piece(dropOffPos, TKind)
    s.copy(blocks = s.blocks ++ p.current,
      currentPiece = p)
  }
</scala>

テストを通過したか確認する:

<code>
[info] Ticking the current piece should
[info] + change the blocks in the view,
[info] + or spawn a new piece when it hits something
</code>

### タイマー

抽象UI の中で `tick` を下矢印キーとタイマーに配線しよう:

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

これで現在のピースが勝手に動くようになったけど、swing UI はそのことを知らないので描画はされない。`mainPanel` を 10 fps で再描画するタイマーを加えてこの問題を直す:

<scala>
    val timer = new SwingTimer(100, new AbstractAction() {
      def actionPerformed(e: java.awt.event.ActionEvent) { repaint }
    })
    timer.start
</scala>

<img src="/images/tetrix-in-scala-day2.png"/>

### 最後に

明らかな問題は一番下の列が消えていないことだ。以下のスペックでテストできると思う:

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

続きはまた[明日](http://eed3si9n.com/ja/tetrix-in-scala-day3)。

<code>
$ git fetch origin
$ git co day2 -b try/day2
$ sbt "project swing" run
</code>
