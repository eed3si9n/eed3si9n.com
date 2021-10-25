---
title:       "モナドはフラクタルだ"
type:        story
date:        2014-10-20
changed:     2021-09-13
draft:       false
promote:     true
sticky:      false
url:         /ja/monads-are-fractals
aliases:     [ /node/176 ]
tags:        [ "fp" ]
---

Uppsala から帰ってくる途中、何となく思い出したのは同僚とのモナドの直観についての会話で、僕は酷い説明をした気がする。色々考えているうちに、ちょっとひらめきがあった。

![Sierpinski triangle](/images/200px-Sierpinski_triangle.png)

### モナドはフラクタルだ

上のフラクタルはシェルピンスキーの三角形と呼ばれるもので、僕がそらで描ける唯一のフラクタルだ。フラクタルとは自己相似的な構造で、上の三角形のように部分が全体の相似となっている (この場合は、親の三角形の半分のスケールの相似)。

モナドはフラクタルだ。モナディックなデータ構造があるとき、その値のいくつかを合成して同じデータ構造の新しい値を形成することができる。これがモナドがプログラミングに有用である理由であり、また多くの場面で登場する理由だ。

具体例で説明する:

```scala
scala> List(List(1), List(2, 3), List(4))
res0: List[List[Int]] = List(List(1), List(2, 3), List(4))
```

<!--more-->

上は `Int` の `List` の `List` だ。これは直観的に `Int` の `List` に押し潰す (crunch) することができる:

```scala
scala> List(1, 2, 3, 4)
res1: List[Int] = List(1, 2, 3, 4)
```

`1` から `List(1)` を作れるように、単一パラメータのコンストラクタである `unit: A => F[A]` も提供できる。これで `1` と `4` も `List(2, 3)` と一緒に押し潰せるようになった:

```scala
scala> List(List.apply(1), List(2, 3), List.apply(4))
res2: List[List[Int]] = List(List(1), List(2, 3), List(4))
```

この押し潰す作業は `join` とも呼ばれ、型シグネチャは `F[F[A]] => F[A]` だ。

### モノイド

この押し潰す作業は、モノイドを連想させる。モノイドは以下のように定義できる:

```scala
trait Monoid[A] {
  def mzero: A
  def mappend(a1: A, a2: A): A
}
```

モノイドを使って以下のような二項演算を抽象化できる:

```scala
scala> List(1, 2, 3, 4).foldLeft(0) { _ + _ }
res4: Int = 10

scala> List(1, 2, 3, 4).foldLeft(1) { _ * _ }
res5: Int = 24

scala> List(true, false, true, true).foldLeft(true) { _ && _ }
res6: Boolean = false

scala> List(true, false, true, true).foldLeft(false) { _ || _ }
res7: Boolean = true
```

ここで注目してほしいのが、データ型だけではモノイドを定義するには不十分であることだ。`(Int, +)` のペアになってモノイドを形成する。言い換えると、`Int` は加算に関してモノイドだ。これに話題に関しては https://twitter.com/jessitron/status/438432946383360000 も参照。

### `List` は `++` に関してモナド

`Int` の `List` の `List` を `Int` の `List` に押し潰すとき、`foldLeft` と `++` のようなことを行って `List[Int]` を作ってるであろうことは自明だ。

```scala
scala> List(List.apply(1), List(2, 3), List.apply(4)).foldLeft(List(): List[Int]) { _ ++ _ }
res8: List[Int] = List(1, 2, 3, 4)
```

だけども、他の定義であった可能性もありえる。例えば、合計値のリストを返すことができる。

```scala
scala> List(List.apply(1), List(2, 3), List.apply(4)).foldLeft(List(): List[Int]) { (acc, xs) => acc :+ xs.sum }
res9: List[Int] = List(1, 5, 4)
```

これはひねくれた例だけど、あるモナドがカプセル化する合成の意味論を考えるのは重要なことだ。

### じゃあ、`Option` は何に関するモナド?

`Option` もみてみよう。モナディックな押し潰しの型シグネチャは `F[F[A]] => F[A]` であるため、例として必要なのは `Option` のリストではなく、入れ子の `Option` だ。

```scala
scala> Some(None: Option[Int]): Option[Option[Int]]
res10: Option[Option[Int]] = Some(None)

scala> Some(Some(1): Option[Int]): Option[Option[Int]]
res11: Option[Option[Int]] = Some(Some(1))

scala> None: Option[Option[Int]]
res12: Option[Option[Int]] = None
```

`Int` の `Option` の `Option` を `Int` の `Option` に押し潰すコードを考えてみた。

```scala
scala> (Some(None: Option[Int]): Option[Option[Int]]).foldLeft(None: Option[Int]) { (_, _)._2 }
res20: Option[Int] = None

scala> (Some(Some(1): Option[Int]): Option[Option[Int]]).foldLeft(None: Option[Int]) { (_, _)._2 }
res21: Option[Int] = Some(1)

scala> (None: Option[Option[Int]]).foldLeft(None: Option[Int]) { (_, _)._2 }
res22: Option[Int] = None
```

というわけで、`Option` は `_2` に関するモナドであるみたいだ。実装を見て自明か分からないけども、失敗を表す `None` を伝搬させるというのが基本的な考えだ。

### モナド則は?

これまでの所 `join` と `unit` の 2つの関数が出てきたけども、もう1つ `map` も必要になる。

- `join: F[F[A]] => F[A]`
- `unit: A => F[A]`
- `map: F[A] => (A => B) => F[B]`

`List[List[List[Int]]]` があるとき、一番外から潰していくか、中から潰していくかで結合律が書ける。以下の例は Functional Programming in Scala の補足ノートから抜粋した:

```scala
scala> val xs: List[List[List[Int]]] = List(List(List(1,2), List(3,4)), List(List(5,6), List(7,8)))
xs: List[List[List[Int]]] = List(List(List(1, 2), List(3, 4)), List(List(5, 6), List(7, 8)))

scala> val ys1 = xs.flatten
ys1: List[List[Int]] = List(List(1, 2), List(3, 4), List(5, 6), List(7, 8))

scala> val ys2 = xs map {_.flatten}
ys2: List[List[Int]] = List(List(1, 2, 3, 4), List(5, 6, 7, 8))

scala> ys1.flatten
res30: List[Int] = List(1, 2, 3, 4, 5, 6, 7, 8)

scala> ys2.flatten
res31: List[Int] = List(1, 2, 3, 4, 5, 6, 7, 8)
```

これは以下のように一般化できる:

```scala
join(join(m)) assert_=== join(map(m)(join))
```

単位元も補足ノートから:

```scala
join(unit(m)) assert_=== m
join(map(m)(unit)) assert_=== m
```

これは `flatMap` を使わなくてもモナドを定義できることを証明する。だけど実際のコードでモナドを扱うときは `for` 内包表記を使って `flatMap` を連鎖する形になることが多い。`flatMap` は `map` と `join` を合わせたものだと考えられる。

### `State` モナド

純粋な関数型のスタイルで書いていると頻出するパターンに何らかの状態を表す値を引き回すというものがある。

```scala
val (d0, _) = Tetrix.init()
val (d1, _) = Tetrix.nextBlock(d0)
val (d2, moved0) = Tetrix.moveBlock(d1, LEFT)
val (d3, moved1) =
  if (moved0) Tetrix.moveBlock(d2, LEFT)
  else (d2, moved0)
```

この状態オブジェクトを渡すのがボイラープレート化して、状態遷移を関数化して合成しようとすると間違いやすいポイントとなる。`State` モナドはこの状態遷移 `S => (S, A)` をカプセル化したモナドだ。

`Tetrix.nextBlock` と `Tetrix.moveBlock` 関数が `State[GameSate, A]` を返すように書き換えると、上のコードはこういうふうに書けるようになる:

```scala
def nextLL: State[GameState, Boolean] = for {
  _      <- Tetrix.nextBlock
  moved0 <- Tetrix.moveBlock(LEFT)
  moved1 <- if (moved0) Tetrix.moveBlock(LEFT)
            else State.state(moved0)
} yield moved1
nextLL.eval(Tetrix.init())
```

`State` モナドを知らない人が見たら何をやってるのか分からないため、このように `for` 内包表記で書けるようになるのが良いことなのかはちょっと断言しかねる。だけど、`d0`、`d1`、`d2`... というような値を渡すのを自動化した型があるのは良いことだろう。

ここで注目してほしいのは、`State` モナドも `List` のようにフラクタルであることだ。`moveBlock` 関数は `State` を返して、`for` 内包表記は `State` の `State` だ。上の例だと、`moveBlock` を 2回呼んでいるのを外に出すことができる:

```scala
def leftLeft: State[GameState, Boolean] = for {
  moved0 <- Tetrix.moveBlock(LEFT)
  moved1 <- if (moved0) Tetrix.moveBlock(LEFT)
            else State.state(moved0)
} yield moved1
def nextLL: State[GameState, Boolean] = for {
  _     <- Tetrix.nextBlock
  moved <- leftLeft
} yield moved
nextLL.eval(Tetrix.init())
```

これで関数的に合成できる小さい命令形のプログラム群を作ることができる。`for` の意味論は一つに限られることにも注意してほしい。

### `StateT` モナド変換子

上の例では `moveBlock` は `State[GameState, Boolean]` を返す。`false` を返した場合はブロックが壁か別のブロックに当たったということで、その続きのアクションは中断される。「if `true` do something」というのは命令形プログラミングのマントラのようなものだ。これは、関数型プログラミングではコードの臭い (code smell) でもある。恐らく `Option[A]` を使ったほうがいいからだ。`State` と `Option` を同時に使うには `StateT` を使うことができる。これで全ての状態遷移は `Option` に包まれることになる。

`nextBlock` は現行のブロックを x 座標 1 に移動して、0 より左に移動させると失敗するとする。

```scala
scala> import scalaz._, Scalaz._
import scalaz._
import Scalaz._

scala> :paste
// Entering paste mode (ctrl-D to finish)

type StateTOption[S, A] = StateT[Option, S, A]
object StateTOption extends StateTInstances with StateTFunctions {
  def apply[S, A](f: S => Option[(S, A)]) = StateT[Option, S, A] { s =>
    f(s)
  }
}
case class GameState(blockPos: Int)
sealed trait Direction
case object LEFT extends Direction
case object RIGHT extends Direction
case object DOWN extends Direction
object Tetrix {
  def nextBlock = StateTOption[GameState, Unit] { s =>
    Some(s.copy(blockPos = 1), ())
  }
  def moveBlock(dir: Direction) = StateTOption[GameState, Unit] { s =>
    dir match {
      case LEFT  => 
        if (s.blockPos == 0) None
        else Some((s.copy(blockPos = s.blockPos - 1), ()))
      case RIGHT => Some((s.copy(blockPos = s.blockPos + 1), ()))
      case DOWN  => Some((s, ()))
    }
  }
}

// Exiting paste mode, now interpreting.

scala> def leftLeft: StateTOption[GameState, Unit] = for {
         _ <- Tetrix.moveBlock(LEFT)
         _ <- Tetrix.moveBlock(LEFT)
       } yield ()
leftLeft: StateTOption[GameState,Unit]

scala> def nextLL: StateTOption[GameState, Unit] = for {
         _ <- Tetrix.nextBlock
         _ <- leftLeft
       } yield ()
nextLL: StateTOption[GameState,Unit]

scala> nextLL.eval(GameState(0))
res0: Option[Unit] = None

scala> def nextRLL: StateTOption[GameState, Unit] = for {
         _ <- Tetrix.nextBlock
         _ <- Tetrix.moveBlock(RIGHT)
         _ <- leftLeft
       } yield ()
nextRLL: StateTOption[GameState,Unit]

scala> nextRLL.eval(GameState(0))
res1: Option[Unit] = Some(())
```

上は左-左が失敗して、右-左-左が成功したことを示している。この簡単な例ではモナドはきれいに積まさったけども、これは複雑になることもある。

### モナドとしての scopt

飛行機の中でもう1つ考えていたのが、コマンドラインパーサーである scopt のことだ。scopt の弱点として指摘されていることに生成されるパーサーが合成不可能であることがある。

考えてみると、scopt は `State` と同じものだ。何ならの設定 case class を最初に渡して、いくつかの遷移を経て最後にまた設定オブジェクトが返ってくる。これは scopt をモナド化した場合の仮想コードだ:

```scala
val parser = {
  val builder = scopt.OptionParser.builder[Config]("scopt")
  import builder._  
  for {
    _ <- head("scopt", "3.x")
    _ <- opt[Int]('f', "foo") action { (x, c) => c.copy(foo = x) }
    _ <- arg[File]("<source>") action { (x, c) => c.copy(source = x) }
    _ <- arg[File]("<targets>...") unbounded() action { (x, c) => c.copy(targets = c.targets :+ x) }
  } yield ()
}
parser.parse("--foo a.txt b.txt c.txt", Config()) match {
  case Some(c) => 
  caes None    => 
}
```

もしも `parser` の型が `OptionParser[Unit]` ならば、`opt[Int]` も `OptionParser[A]` となる。これで、いくつかのオプションをサブパーサーに外出しして再利用することができる。ただし、`Config` も再利用できるならばという仮定付きだけど。

### `Free` モナド

`Free` モナドほどフラクタルを意識させられるモナドは他には無いと思う。`List` も `Option` もフラクタルなんだけど、`Free` はモナドを提供する側がナノテクのモノマーを作るのに関わっていて、それが反復されることで勝手に巨大な構造に積み上がっていく。
例えば、`Tuple2[A, Next]` を使うことで `Free` はリスト状のモナドを形成することができる。`Tuple2[A, Next]` の `Next` の所に別の `Tuple2[A, Next]` を入れて `Tuple2[A, Tuple2[A, Next]]` にするというのを繰り返していくわけだ。

結果としてフラクタルであること以外には余計なコンテキストを持たないデータ構造を得ることができる。それを分解して、何らかの有用な作業をするのはこっちの責任となる。この方法はモナド変換子を使うようよりもシンプルである可能性がある。

```scala
scala> import scalaz._, Scalaz._
import scalaz._
import Scalaz._

scala> :paste
// Entering paste mode (ctrl-D to finish)

case class GameState(blockPos: Int)
sealed trait Direction
case object LEFT extends Direction
case object RIGHT extends Direction
case object DOWN extends Direction

sealed trait Tetrix[Next]
object Tetrix {
  case class NextBlock[Next](next: Next) extends Tetrix[Next]
  case class MoveBlock[Next](dir: Direction, next: Next) extends Tetrix[Next]  
  implicit val gameCommandFunctor: Functor[Tetrix] = new Functor[Tetrix] {
    def map[A, B](fa: Tetrix[A])(f: A => B): Tetrix[B] = fa match {
        case n: NextBlock[A] => NextBlock(f(n.next))
        case m: MoveBlock[A] => MoveBlock(m.dir, f(m.next))
      }
    }
  def nextBlock: Free[Tetrix, Unit] = Free.liftF[Tetrix, Unit](NextBlock(()))
  def moveBlock(dir: Direction): Free[Tetrix, Unit] =
    Free.liftF[Tetrix, Unit](MoveBlock(dir, ()))

  def eval(s: GameState, cs: Free[Tetrix, Unit]): Option[Unit] =
    cs.resume.fold({
      case NextBlock(next) =>
        eval(s.copy(blockPos = 1), next)
      case MoveBlock(dir, next) =>
        dir match {
          case LEFT  => 
            if (s.blockPos == 0) None
            else eval(s.copy(blockPos = s.blockPos - 1), next)
          case RIGHT => eval(s.copy(blockPos = s.blockPos + 1), next)
          case DOWN  => eval(s, next)
        }
    },
    { r: Unit => Some(()) })
}

// Exiting paste mode, now interpreting.

scala> def leftLeft: Free[Tetrix, Unit] = for {
         _ <- Tetrix.moveBlock(LEFT)
         _ <- Tetrix.moveBlock(LEFT)
       } yield ()
leftLeft: scalaz.Free[Tetrix,Unit]

scala> def nextLL: Free[Tetrix, Unit] = for {
         _ <- Tetrix.nextBlock
         _ <- leftLeft
       } yield ()
nextLL: scalaz.Free[Tetrix,Unit]

scala> Tetrix.eval(GameState(0), nextLL)
res0: Option[Unit] = None

scala> def nextRLL: Free[Tetrix, Unit] = for {
         _ <- Tetrix.nextBlock
         _ <- Tetrix.moveBlock(RIGHT)
         _ <- leftLeft
       } yield ()
nextRLL: scalaz.Free[Tetrix,Unit]

scala> Tetrix.eval(GameState(0), nextRLL)
res1: Option[Unit] = Some(())
```

型シグネチャを除けば、プログラムの部分のコードは `StateTOption` を使ったものを全く同一のものだ。
コンテキストの実装はこっちの責任となるというのはトレードオフだけども、最初にセットアップした後は型が複雑化しないという利点がある。

### まとめ

モナドはフラクタルのような自己相似的な構造で、それは関数 `join: F[F[A]] => F[A]` で表すことができる。この特性によってモナディックな値を合成してより大きなモナディックな値を形成することができる。モノイドの `mappend` 同様に、`join` も追加の意味論をカプセル化することができる　(例としては `Option` や `State` など)。もしも自己反復的な構造を見つけたら、それはモナドであるかもしれないと考えてみてほしい。
モナディックな型の合成はモナド変換子によって可能ではあるが、複雑であることで悪名が高い。モナディックな DSL を提供する代替案として `Free` を使うという方法もある。
