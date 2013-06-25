JavaScript が作られたのは 1995年のことだから、『JavaScript: The Good Parts』(2008年)、jQuery (2006年)、V8 (2008年) などが登場するよりもかなり前に作られたことになる。jQuery と V8 が加算的な貢献であるのに対して、Douglas Crockford 氏の『The Good Parts』が面白いのは、言語から機能を引き算した本であることだと思う。

ここ最近、もし Scala をリアルワールドな制約である Java 的な親しみやすさや互換性を無視してワンダーランド的な設定でサブセットを作ったらどうなるだろうかと考えている。Scala を Java の代替として使う事が許されるなら、関数型プログラミング言語の代替として使ってもいいじゃないかと思う。この思考実験のもう一つの試みは、Scala の構文の中で重複しているものを減らすことだ。本稿では、慣用的な用法が何かを考えたり、何かに対して良し悪しの判定を下すことには興味は無い。これは空飛ぶサンドイッチのパーツ (The Flying Sandwich Parts; TFSP) と呼ぶことにする。

## 値

> What talk you of the posy or the value?
> — William Shakespeare, _Merchant of Venice_

Scala 言語仕様は値を以下のように定義する:

> 値定義 `val x : T = e` は、`e` の評価から得られる値の名前として `x` を定義します。

TFSP においては、トレイトやクラスの本文内では型注釈 `T` の省略を禁止する。関数内のローカルの値は型推論を使って定義してもよい。これによって関数レベルにおいて型検査が行われることが保証される。

### 遅延評価値

素の val を使って値を定義すると、定義した順番に気を使う必要がある。初期化する前に値を参照してしまうと実行時に `NullPointerException` が発生してしまう。値を `lazy` だと書くことで最初に参照されるまで初期化を遅延することができる。

<scala>
  implicit val m: MachineModule = new MachineModule {
    val left: State => State   = buildTrans(pm.moveBy((-1, 0)))
    lazy val buildTrans: (Piece => Piece) => State => State = f => s0 => {
      // ....
    }
  }
</scala>

上の例では、`left` が後にくる `buildTrans` を参照しているため、 `buildTrans` を `lazy` だと定義した。

### パターン定義

パターンマッチが値定義の左辺項にくると、抽出子を使ったデータ型の分解が行われる。

<scala>
val x :: xs = list
</scala>

### var を避ける

TFSP においては、変数を使うことは非推奨とする。

## 式

Scala のほとんどの構文は何らかの値を返すため、便利だ。

### リテラル

Scala においては、整数、浮動小数点数、文字、ブーリアン、シンボル、そして文字列のリテラルがある。

### null の禁止

TFSP においては、null を使うことを禁止する。代わりに `Option[A]` を使う。

### 中置記法

Scala においては、メソッドの呼び出しを中置記法で書くことができる。

### 後置記法の禁止

TFSP においては、後置記法を禁止する。

### if 式

Scala においては、`if-else` 構文は値を返す。TFSP においては、常に `else` 節を書く。

<scala>
scala> val x = 1
x: Int = 1

scala> :paste
// Entering paste mode (ctrl-D to finish)

if (x > 1) x
else 0

res1: Int = 0
</scala>

### for 内包表記

Scala において、`for` は `yield` と共に使うと for 内包表記になり、`yield` を使わないと for ループになる。TFSP においては、常に `yield` を書く。丸括弧か波括弧によって微妙に構文が異なる。TFSP においては、常に波括弧を使う。

<scala>
scala> for {
         x <- 1 to 10
       } yield x + 1
res2: scala.collection.immutable.IndexedSeq[Int] = Vector(2, 3, 4, 5, 6, 7, 8, 9, 10, 11)
</scala>

### 例外よりも `Either[A, B]`

TFSP は例外よりも `Either[A, B]` その他の失敗をエンコードするデータ型を使うことを推奨する。

## case class

> Thy case, dear friend, Shall be my precedent
> — William Shakespeare, _The Tempest_

Scala の case class は代数的データ型をエミュレートするのに便利な方法だ。個々の case class は ADT のコンストラクタに相当し、AST そのものは sealed trait を使って表す。

<scala>
scala> :paste
// Entering paste mode (ctrl-D to finish)

sealed trait Tree
case class Empty() extends Tree
case class Leaf(x: Int) extends Tree
case class Node(left: Tree, right: Tree) extends Tree

// Exiting paste mode, now interpreting.
</scala>

内部では、case class は自動的に `equals`、`toString`、`hashcode`、`copy` メソッドを実装する。さらに、コンパニオンオブジェクトは `apply` と `unapply` を自動的に実装する。

### パターンマッチ

パターンマッチを使って case class を分解することができる:

<scala>
scala> val badDepth: Tree => Int = {
         case Leaf(_)    => 1
         case Node(l, r) => 1 + math.max(depth(l), depth(r))
       }
<console>:13: warning: match may not be exhaustive.
It would fail on the following input: Empty()
       val badDepth: Tree => Int = {
                                   ^
badDepth: Tree => Int = <function1>
</scala>

trait は sealed であるため、パターンマッチの完全性をコンパイラがチェックしてくれる。

<scala>
scala> val depth: Tree => Int = {
         case Empty()    => 0
         case Leaf(_)    => 1
         case Node(l, r) => 1 + math.max(depth(l), depth(r))
       }
depth: Tree => Int = <function1>

scala> depth(Node(Empty(), Leaf(1)))
res5: Int = 2
</scala>

### case class 内のメソッドの禁止

TFSP においては、case class 内にメソッドを定義することを禁止する。これは次の節で説明する。

## モジュラープログラミング

現代的なオブジェクト指向プログラミングと関数型プログラミングの両方がモジュール性という概念を謳っているが、オブジェクトと関数のどちらにも内在的にモジュール性があるわけではない。オブジェクトの主な側面は動詞と名詞を関連付けて、人間世界へのメタファーへと投射することにある。関数の主な側面は値同士を関連付け、さらに関連そのものも値として取り扱うことにある。

モジュール性は凝集度が高く疎結合なモジュールを定義することが肝であり、その根底には数学よりも工学がある。モジュラープログラミングにおいては、モジュール間のコミュニケーションはインターフェイスを経由して間接的に行われる。これがモジュールのカプセル化を可能とし、究極的にはモジュールの置換性を可能とする。

### trait

Scala では、trait を使った型クラスを定義することが最も柔軟なモジュールの実装方法だ。まず、型クラスのコントラクトを関数のシグネチャのみを宣言する trait によって定義する。

<scala>
scala> trait TreeModule {
         val depth: Tree => Int
       }
defined trait TreeModule
</scala>

次に、型クラスのインスタンスを実装する別の trait を以下のように定義する:

<scala>
scala> trait TreeInstance {
         val resolveTreeModule: Unit => TreeModule = { case () =>
           implicitly[TreeModule]
         }
         implicit val treeModule: TreeModule = new TreeModule {
           val depth: Tree => Int = {
             case Empty()    => 0
             case Leaf(_)    => 1
             case Node(l, r) => 1 + math.max(depth(l), depth(r))
           }
         }
       }
defined trait TreeInstance
</scala>

### 細別型 (オブジェクトリテラル)

`TreeModule` のデフォルトのインスタンスを定義した方法は細別付きの無名型、略して細別型の例だ。この型は名前を持たないため、型内で定義される `depth` 以外のフィールドは全て外部から隠蔽される。

<scala>
scala> val treeModule2: TreeModule = new TreeModule {
         val depth: Tree => Int = { case _ => 0 }
         val foo = 2
       }
treeModule2: TreeModule = $anon$1@79c4cc17

scala> treeModule2.foo
<console>:11: error: value foo is not a member of TreeModule
              treeModule2.foo
                          ^
</scala>

### 暗黙のスコープよりも import

Scala には `TreeModule` を使えるようにする方法がいくつかある。一つの方法は `TreeInstance` のオブジェクトを作って、その全フィールドをスコープ内に import することだ。TFSP は暗黙のスコープを使わずに明示的に暗黙の値を import することを推奨する。これによってコンパニオン・オブジェクトの必要性が減るはずだ。

`TreeModule` は以下のようにして使う:

<scala>
scala> {
         val allInstances = new TreeInstance {}
         import allInstances._
         val m = resolveTreeModule()
         m.depth(Empty())
       }
res1: Int = 0
</scala>

モジュールが取り扱うデータ型は外に出してあり、`TreeModule` は抽象的であるため、`depth` 関数の実装は完全に置換可能だ。

### クラスよりも trait

TFSP はクラスよりも trait を推奨する。外部ライブラリへの橋渡し以外の目的では素のクラスは必要無いはずだ。

## 関数

> Faith, I must leave thee, love, and shortly too.
> My operant powers their functions leave to do.
> — William Shakespeare, _Hamlet_

Scala には第一級関数、つまり値として扱うことのできる関数がある。第一級関数があることで、高階関数が可能となり便利だ。興味深いのは、最終的に関数になりうるものが Scala には何通りもあることだ。

### case 関数 (部分関数リテラル)

Scala において、case を並べることで無名部分関数を定義できる。「パターンマッチング無名関数」は長すぎるので、ここでは **case 関数** と呼ぶ。

<scala>
scala> type =>?[A, R] = PartialFunction[A, R]
defined type alias $eq$greater$qmark

scala> val f: Tree =>? Int = {
         case Empty() => 0
       }
f: =>?[Tree,Int] = <function1>
</scala>

`PartialFunction` は `Function1` を継承するため、case 関数は関数が期待される全ての所で使うことできる。

### 関数リテラル

Scala において、関数は複数のパラメータを取るか、カリー化することでただ一つのパラメータのみを受け取り別の関数を返すように書くことができる。TFSP においては、タプルを渡すことが好ましい場合を除いてカリー化された関数をデフォルトのスタイルとする。

<scala>
scala> val add: Int => Int => Int = x => y => x + y
add: Int => (Int => Int) = <function1>
</scala>

これによって部分適用がデフォルトの振る舞いとなる。

<scala>
scala> val add3 = add(3)
add3: Int => Int = <function1>

scala> add3(1)
res5: Int = 4
</scala>

### プレースホルダー構文の禁止

TFSP においては、`(_: Int) + 1` のようなプレースホルダー構文を使った無名関数を禁止する。書いてて面白いのは確かだけど、取り除くことで関数を定義する方法が一つ減る。

### def よりも関数を使う

Scala においては def を使ったメソッドと第一級関数が一緒に共存している。TFSP は def よりも第一級関数を推奨する。これは、多くの場合関数が def メソッドの役割を代替できるからだ。例外としては型パラメータもしくは暗黙のパラメータを受け取る関数の定義がある。

### オーバーロードの禁止

TFSP においては、オーバーロードを禁止する。

## 多相性

Scala において多相性はサブタイプ化と型クラスの両方によって実現することができる。

### サブタイプ化よりも型クラス

TFSP はサブタイプ化よりも型クラスを使ったアドホック多相を推奨する。型クラスはコンパイル無しで既存のデータ型に振る舞いを追加できるためより高い柔軟性を提供する。

例えば、`TreeModule` を `Depth[A]` と一般化して `List[Int]` と `Tree` の両方をサポートすることができる。

<scala>
trait Depth[A] {
  val depth: A => Int
}
trait DepthInstances {
  def resolveDepth[A: Depth](): Depth[A] = implicitly[Depth[A]]
  implicit val treeDepth: Depth[Tree] = new Depth[Tree] {
    val depth: Tree => Int = {
      case Empty()    => 0
      case Leaf(_)    => 1
      case Node(l, r) => 1 + math.max(depth(l), depth(r))
    }
  }
  implicit val listDepth: Depth[List[Int]] = new Depth[List[Int]] {
    val depth: List[Int] => Int = {
      case xs => xs.size
    }
  }
}
</scala>

### context-bound 型パラメータ

`Depth` 型クラスを利用するためには、context-bound な型パラメータを受け取る def メソッドを定義する。

<scala>
scala> {
         val allInstances = new DepthInstances {}
         import allInstances._
         def halfDepth[A: Depth](a: A): Int =
           resolveDepth[A].depth(a) / 2
         halfDepth(List(1, 2, 3, 4))
       }
res2: Int = 2
</scala>

### モジュール間の依存性

モジュラープログラミングにおいては、モジュール間のコミュニケーションはインターフェイスを用いて間接的に行われると言った。これまでの所一つのモジュールしか見ていない。別のモジュールに依存するモジュールをどう表すことができるだろう。Cake パターンは人気のテクニックの一つだが、暗黙の関数を使うことで似たことができる。

ここで `MainModule` と `ColorModule` という2つのモジュールを考える。

<scala>
import swing._
import java.awt.{Color => AWTColor}

trait MainModule {
  val mainFrame: Unit => Frame
}

trait ColorModule {
  val background: AWTColor
}
</scala>

`ColorModule` に依存した `MainModule` を定義したい。

<scala>
trait MainInstance {
  def resolveMainModule(x: Unit)(implicit cm: ColorModule,
    f: ColorModule => MainModule): MainModule = f(cm)
  implicit val toMainModule: ColorModule => MainModule = cm =>
    new MainModule {
      // use cm to define MainModule
    }
}
</scala>

`MainModule` は普通にインスタンス化することができる。

<scala>
scala> {
         val allInstances = new MainInstance with ColorInstance {}
         import allInstances._
         val m = resolveMainModule()
         m.mainFrame()
       }
res1: scala.swing.Frame = ...
</scala>

### 変位指定を避ける

Scala において、型パラメータを共変か反変に指定することで型コンストラクタがサブタイプに関してどのように振る舞うかを決めることができる。TFSP はサブタイプ化そのものを避けるため、変位指定も避けるべきだ。

## メソッドの注入 (エンリッチクラス)

Scala において、既存の型を暗黙にラッピングして元の型に無かったメソッドを注入することができる。データ型にメソッドがあることが必要な場合は、メソッド注入を使うことでモジュール性を妥協せずにメソッドを模倣できる。

型クラスをつかったメソッド注入のテクニックは Scalaz 7 の実装に倣った。

<scala>
scala> :paste
// Entering paste mode (ctrl-D to finish)

trait DepthOps[A] {
  val self: A
  val m: Depth[A]
  def depth: Int = m.depth(self)
}
trait ToDepthOps {
  implicit def toDepthOps[A: Depth](a: A): DepthOps[A] = new DepthOps[A] {
    val self: A = a
    val m: Depth[A] = implicitly[Depth[A]]
  }
}

// Exiting paste mode, now interpreting.
</scala>

以下のようにして `Depth` 型クラスをサポートする全てのデータ型に対して `depth` メソッドを注入する。

<scala>
scala> {
         val allInstances = new DepthInstances {}
         import allInstances._
         val ops = new ToDepthOps {}
         import ops._
         List(1, 2, 3, 4).depth
       }
res4: Int = 4
</scala>

## ケーススタディ: Tetrix

Scala の構文を並べてきたが、このサブセットがどれほど変わっているのか、または便利なのかは実際にコードを書いてみないと分かりづらい。当然テストプログラムには [Tetrix](https://github.com/eed3si9n/tetrix.tfsp) を使う。

### MainModule

まず、Swing UI をラッピングするために `MainModule` を定義する。

<scala>
import swing._

trait MainModule {
  val mainFrame: Unit => Frame
}
</scala>

`MainModule` は `ColorModule` と `MachineModule` という2つのモジュールに依存する。依存性は以下のように書かれる:

<scala>
trait MainInstance {
  def resolveMainModule(x: Unit)(implicit cm: ColorModule,
    mm: MachineModule,
    f: ColorModule => MachineModule => MainModule): MainModule = f(cm)(mm)
  implicit val toMainModule: ColorModule => MachineModule => MainModule =
    cm => mm => new MainModule {
      // ...
    }
}
</scala>

`SimpleSwingApplication` を継承する必要があったので、アプリ用の trait を定義して、そこから `MainModule` を使う:

<scala>
object Main extends TetrixApp {}
trait TetrixApp extends SimpleSwingApplication {
  val allInstances = new MainInstance with ColorInstance
    with MachineInstance with PieceInstance {}
  import allInstances._
  implicit val machine: MachineModule = MachineModule()
  val main: MainModule = MainModule()
  lazy val top: Frame = main.mainFrame()
}
</scala>

### ColorModule

`ColorModule` はアプリで使われる色の設定を決定する。

<scala>
trait ColorModule {
  val background: AWTColor
  val foreground: AWTColor
}
trait ColorInstance {
  val resolveColorModule: Unit => ColorModule = { case () =>
    implicitly[ColorModule]
  }
  implicit val colorModule: ColorModule = new ColorModule {
    val background = new AWTColor(210, 255, 255) // bluishSilver
    val foreground = new AWTColor(79, 130, 130)  // bluishLigherGray
  }
}
</scala>

これがモジュールの全てだ。2つのフィールドのためだけにオーバーヘッドが有り過ぎると思うかもしれないが、これはアプリが出来上がった後から設定を差し替えられることを説明するために入れた。

![before](/images/scala-tfsp1.png)

例えば、`ColorModule` の新しいインスタンスをデフォルトのインスタンスを継承して以下のように定義できる:

<scala>
trait CustomColorInstance extends ColorInstance {
  implicit val colorModule: ColorModule = new ColorModule {
    val background = new AWTColor(255, 255, 255) // white
    val foreground = new AWTColor(0, 0, 0)  // black
  } 
}
</scala>

これは以下のように implicit の検索空間に入れることができる:

<scala>
trait TetrixApp extends SimpleSwingApplication {
  val allInstances = new MainInstance with ColorInstance
    with MachineInstance with PieceInstance
    with CustomColorInstance {}
  import allInstances._
  implicit val machine: MachineModule = resolveMachineModule()
  val main: MainModule = resolveMainModule()
  lazy val top: Frame = main.mainFrame()
}
</scala>

![after](/images/scala-tfsp2.png)

これでブロックが別の色で描画されるようになった。この代替設定は最初の jar を再コンパイルせずに別の jar に入れることもできる。

### MachineModule

`MachineModule` はゲームの状態機械を表す。まず、以下のように case class を定義した。

<scala>
import scala.collection.concurrent.TrieMap

// this is mutable
case class Machine(stateMap: TrieMap[Unit, State])

case class State(current: Piece, gridSize: (Int, Int),
  blocks: Seq[Block])

case class Block(pos: (Int, Int))
</scala>

`Machine` は現在の `State` を並行マップに保持する。今のところ `MachineModule` は以下の関数を定義する:

<scala>
trait MachineModule {
  val init: Unit => Machine
  val state: Machine => State
  val transition: Machine => (State => State) => Machine
  val left: State => State
  val right: State => State
  val rotate: State => State
}
trait MachineInstance {
  def resolveMachineModule(x: Unit)(implicit pm: PieceModule,
    f: PieceModule => MachineModule): MachineModule = f(pm)
  implicit val toMachineModule: PieceModule => MachineModule = pm =>
    new MachineModule {
      // ...
    }
}
</scala>

このモジュールは `PieceModule` という別のモジュールに依存するため、モジュールのインスタンスは暗黙の関数 `toMachineModule` として定義される。暗黙のパラメータはコールサイトにおいて解決されるため、`PieceModule` のインスタンスはトップレベルのアプリにおいて置換することができる。

状態機会は以下のように実装される。

<scala>
    val state: Machine => State = { case m =>
      m.stateMap(())
    }
    val transition: Machine => (State => State) => Machine = m => f => {
      val s0 = state(m)
      val s1 = f(s0)
      m.stateMap replace((), s0, s1)
      m
    }
</scala>

見てのとおり、全ての関数はカリー化された関数値として実装されている。以下にこのカリー化を利用した例を挙げる。

<scala>
    val left: State => State   = buildTrans(pm.moveBy((-1, 0)))
    val right: State => State  = buildTrans(pm.moveBy((1, 0)))
    val rotate: State => State = buildTrans(pm.rotateBy(-Math.PI / 2.0))
    lazy val buildTrans: (Piece => Piece) => State => State = f => s0 => {
      val p0 = s0.current
      val p = f(p0)
      val u = unload(p0)(s0)
      load(p)(u) getOrElse s0
    }
</scala>

`buildTrans` は `Piece` の変換関数と初期 `State` を受け取って別の `State` を返す関数だ。最初のパラメータのみを適用することで `State => State` 関数を返す関数だと考えることもできる。

### PieceModule

`PieceModule` はピースの動きを記述する。例えば、`left` や `right` で使われている `moveBy` は以下のように実装される:

<scala>
    val moveBy: Tuple2[Int, Int] => Piece => Piece = {
      case (deltaX, deltaY) => p0 =>
        val (x0, y0) = p0.pos
        p0.copy(pos = (x0 + deltaX, y0 + deltaY))
    }
</scala>

### 観察

オモチャのプロジェクトだとしても実際に TFSP を使ってコードを書くことでこのサブセットの理解が深まった。例えば、モジュールの依存性はきちんと任意のモジュールを置換できるまで試行錯誤を繰り返した。

全体としては、今のところ思ったよりも使えそうなので驚いている。ブロックを動かして壁との当たり判定できるところまで書けたので、残りは時間の問題だと思ったので Tetrix は完成させなかった。

いくつかの `def apply` を除いて全ての関数は `val` を使って定義した。これによる問題はだいたいにおいては無かった。唯一注意する必要があったのは、`def` メソッドを使っていたら注意する必要の無い初期化の順番だ。常に `lazy val` を使うようにすれば初期化問題は解決するだろう。

関数のいくつかは可変オブジェクトを返すため、`val init: Unit => Machine` のように `Unit => X` として実装した。これにより `init` と `init()` で意味が異なるようになり、これも一般の Scala では一般的ではない。

無名関数のプレースホルダー構文を手放したことでパラメータに名前をつけることが必要になった。関数を作る構文を減らすことによるトレードオフだと言える。

TFSP の特長はモジュール性だ。サブタイプ化に依存することなく TFSP は疎結合なモジュールを定義することができる。どの関数も `private` と書かずに TFSP がカプセル化を実現していることも面白いと思う。ただ、Cake パターンや SubCut のような他の依存性注入のソルーションもこれは実現できるだろう。

## まとめ

Scala は幅広いスタイルを包容する言語なので、独自サブセットを考えることは自分の立ち位置を考えるのに役立つ。サブセットの使い方の一つとしては、コードの大部分をそれで書いて、Scala の残りは他のライブラリや Java と話すための FFI 扱いしてしまうことだ。

TFSP をまとめてみる:

- データは case class に分ける
- 振る舞いは trait を用いた型クラスとして定義する
- implicit の読み込みには import を使う
- case 関数とカリー化された関数値を使って関数を定義する

最初の2点は関数型、もしくはモジュラーなコードベースなら既にそうなっているプロジェクトとあると思う。TFSP はより厳密に可能なもの全てにそれを採用しているだけだ。

後の2点は多分普通の Scala から外れたものだと考えられるだろう。だけど、これは言語仕様を新言語を見る目で再考してみるとぎこちないと思われる点でもある。例えば、関数にどこにでも現れることができる第一級関数と暗黙に `this` を渡すメソッドという 2つの概念があるのは少し変だと思う。もし可能ならば、`val` に統一するほうが自然じゃないだろうか。コンパニオン・オブジェクトを使った暗黙のスコープというアレも、理解できれば素晴らしいものだが、名前に基いて何かがつながっているという時点で少し魔法な感じがする。

間もなく飛行機はニューアーク・リバティー国際空港に向けて着陸体制にはいります。現地の天気は晴れ、気温は 22度。ご使用中のテーブル、お座席の背が慣用的な位置にあるかもう一度お確かめ下さい。本日は空飛ぶサンドイッチをご利用下さいましてありがとうございました。
