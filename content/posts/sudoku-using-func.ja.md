---
title:       "Func を使った数独"
type:        story
date:        2012-12-05
changed:     2021-09-13
draft:       false
promote:     true
sticky:      false
url:         /ja/sudoku-using-func
aliases:     [ /node/128 ]
tags:        [ "scalaz" ]
---

> これは [Scalaz Advent Calendar 2012](http://partake.in/events/7211abc9-ebb8-4670-b912-3089dc5e0edd) 5日目の記事です。

12月の間中、日本の技術系ギークは日替わりでテーマに沿った記事を公開し、彼の国では「Advent Calendar」と呼ばれているらしい。去年の [Scala Advent Calendar 2011](http://partake.in/events/33870915-f25b-40b6-9456-b898b898d48b) で僕は Eric Torreborre さんが [The Essence of Iterator Pattern](http://etorreborre.blogspot.com/2011/06/essence-of-iterator-pattern.html) をカバーした記事を[翻訳](http://eed3si9n.com/ja/essence-of-iterator-pattern)した。これは日本人の関数型プログラミング記事好きを知った上である程度狙ったものだった。もう1つの利己的な動機は、記事を一語一語訳す過程において概念のいくつかは僕の頭にも染みこんでくれるんじゃないかという期待だった。振り返ってみると、両方の目的とも作戦成功だったと言える。Jeremy Gibbons さん、Bruno Oliveira さんそして Eric 両方の仕事のクオリティのお陰だ。これらの染み込んだ知識が今年に書いた独習 Scalaz シリーズの隠し味だったんじゃないかと思っている。

[独習 Scalaz 12日目](http://eed3si9n.com/ja/learning-scalaz-day12)でふれたとおり、Scalaz 7 の型クラスインスタンスには既に `product` と `compose` が含まれており、また [`Traverse`](https://github.com/scalaz/scalaz/blob/scalaz-seven/core/src/main/scala/scalaz/Traverse.scala) も定義されている。論文にある [word count の例題](https://github.com/scalaz/scalaz/blob/c0f74398fdbc4f804fa06429fb58db4a9d3aafb0/example/src/main/scala/scalaz/example/WordCount.scala) まである。僕が気づいたのは、値レベルでの合成が無いことだ。この論文の興味深い点の1つに「applicative functor の合成」があり、これはモジュール化プログラミング的なものを可能とする。

Gibbons と Oliveira の言う「applicative functor」は実は型クラスのインスタンスだけではなく、applicative 関数の合成も指している。これは論文からの以下の抜粋をみれば明らかだ:

```haskell
data (m ⊠ n) a = Prod { pfst :: m a, psnd :: n a }
(⊗) :: (Functor m, Functor n) ⇒ (a → m b) → (a → n b) → (a → (m ⊠ n) b)
(f ⊗ g) x = Prod(f x)(gx)
```

代数データ型の `⊠` は型レベルの積だが、中置関数の `⊗` は 2つの applicative 関数の値レベルの積で、`a → (m ⊠ n) ` という型の applicative 関数を返す。言い換えると、プログラマは applicative functor を返す関数を構築するだけよくて、型レベルでの合成は自動的に行われる。

### Func

`Func` は、値レベルでの applicative 関数の合成を提供しようと僕が試みたものだ。

```scala
scala> import scalaz._, Scalaz._, typelevel._
import scalaz._
import Scalaz._
import typelevel._

scala> val f = AppFuncU { (x: Int) => x + 1 }
f: scalaz.typelevel.Func[scalaz.Unapply[scalaz.Applicative,Int]{type M[X] = Int; type A = Int}#M,scalaz.Applicative,Int,Int] = scalaz.typelevel.FuncFunctions$$anon$12@3143369a

scala> val g = AppFuncU { (x: Int) => List(x, 5) }
g: scalaz.typelevel.Func[scalaz.Unapply[scalaz.Applicative,List[Int]]{type M[X] = List[X]; type A = Int}#M,scalaz.Applicative,Int,Int] = scalaz.typelevel.FuncFunctions$$anon$12@3106a3a2

scala> (f @&&& g) traverse List(1, 2, 3)
res0: scalaz.typelevel.TCCons[scalaz.Unapply[scalaz.Applicative,Int]{type M[X] = Int; type A = Int}#M,scalaz.typelevel.TCCons[scalaz.Unapply[scalaz.Applicative,List[Int]]{type M[X] = List[X]; type A = Int}#M,scalaz.typelevel.TCNil]]#Product[List[Int]] = GenericCons(9,GenericCons(List(List(1, 2, 3), List(1, 2, 5), List(1, 5, 3), List(1, 5, 5), List(5, 2, 3), List(5, 2, 5), List(5, 5, 3), List(5, 5, 5)),GenericNil()))
```

[`Kleisli`](https://github.com/scalaz/scalaz/blob/scalaz-seven/core/src/main/scala/scalaz/Kleisli.scala) 同様に、[`Func`](https://github.com/scalaz/scalaz/blob/scalaz-seven/typelevel/src/main/scala/scalaz/typelevel/Func.scala) は `A => F[B]` 関数を表す:

```scala
trait Func[F[_], TC[F[_]] <: Functor[F], A, B] { self =>
  def runA(a: A): F[B]
  implicit def TC: KTypeClass[TC]
  implicit def F: TC[F]
}
```

`runA` メソッドはこの関数を実行し、普通の関数の `apply` メソッドに相当する。

`Func` はまた別の `Func` を返す `productA` メソッド (シンボルを使ったエイリアスは `@&&&`) を実装する。`Func` の元の実装は `AppFunc` と呼ばれていて applicative functor に特化したものだった。Lars Hupel さん ([@larsr_h](https://twitter.com/larsr_h)) の提案で型クラスに対して多相的であるようにリファクタされ `Func` となった。

### scalaz-typelevel モジュール

コアモジュール内の個々の型クラスで実装されている `product` と `compose` メソッドはシグネチャを共有しないため、互いに独立している。例えば、`Functor` 下の `product` は `Functor[({type λ[α] = (F[α], G[α])})#λ]` を返すが、`Applicative` 下の `product` は `Applicative[({type λ[α] = (F[α], G[α])})#λ]` を返す。

scalaz-typelevel モジュールは型レベルのデータ構造 (あと readme によると型安全な printf) を提供する。僕が狙っているのは [`KTypeClass`](https://github.com/scalaz/scalaz/blob/scalaz-seven/typelevel/src/main/scala/scalaz/typelevel/KTypeClass.scala) で、これは `Functor` や `Applicative` のような、カインドが `* -> *` の型クラスの型クラスだ。その主な機能は `product` と `compose` メソッドだ:

```scala
trait KTypeClass[C[_[_]]] {
  def product[F[_], T <: TCList](FHead: C[F], FTail: C[T#Product]): C[TCCons[F, T]#Product]
  def compose[F[_], T <: TCList](FOuter: C[F], FInner: C[T#Composed]): C[TCCons[F, T]#Composed]
}
```

積のエンコードに `Tuple2` を使う代わりに、`KTypeClass` は `HList` を使って積をエンコードする。これもまた scalaz-typelevel モジュールに含まれている。全ての要素の中から1つの型しか保存することができない `List` に対して、`HList` は全ての要素の型を保存する。

```scala
scala> List(1, "string").head
res1: Any = 1

scala> (1 :: "string" :: HNil).head
res2: scalaz.Id.Id[Int] = 1
```

`Int` と `String` を許容するために、最初の `List` は `List[Any]` まで広げられたのに対して、`HList` は型をそのまま保存した。

### HListFunc

EIP をならって、僕の `Func` の実装は `@&&&` を使った 2つの関数の積しかサポートしていなかった。もし誰かが `@&&&` を連鎖したならば、`HList` の中に入れ子で `HList` が入ったものが返された。Lars は `HList` をそのまま伸ばせるようにするべきだと提案した。

数週間後に僕が思いついたのが `HList` を返す関数のラッパー `HListFunc` で、これは `Func` を継承する:

```scala
trait HListFunc[T <: TCList, TC[X[_]] <: Functor[X], A, B] extends Func[T#Product, TC, A, B] { self =>
  def ::[G[_]](g: Func[G, TC, A, B]) = g consA self
  private[scalaz] def Product: KTypeClass.WrappedProduct[TC, T]
  final def F = Product.instance
}
```

`HListFunc` の作成には2通りの方法がある。1つは、`AppFunc` などの特化された `Func` オブジェクトの `HNil` メソッドを呼ぶことだ:

```scala
scala> AppFunc.HNil
res7: scalaz.typelevel.HListFunc[scalaz.typelevel.TCNil,scalaz.Applicative,Nothing,Nothing] = scalaz.typelevel.FuncFunctions$$anon$6@1e525ac8

scala> AppFunc.HNil[Int, Int]
res8: scalaz.typelevel.HListFunc[scalaz.typelevel.TCNil,scalaz.Applicative,Int,Int] = scalaz.typelevel.FuncFunctions$$anon$6@6e8d1f6a

scala> res8.runA(0)
res9: scalaz.typelevel.TCNil#Product[Int] = GenericNil()
```

`HListFunc` を作る第2の方法は既存の `HListFunc` に対して `::` 演算子を使うことだ:

```scala
scala> AppFuncU { (x: Int) => x + 1 } :: AppFunc.HNil
res15: scalaz.typelevel.HListFunc[scalaz.typelevel.TCCons[scalaz.Unapply[scalaz.Applicative,Int]{type M[X] = Int; type A = Int}#M,scalaz.typelevel.TCNil],scalaz.Applicative,Int,Int] = scalaz.typelevel.Func$$anon$4@34f262c3
```

### Func 再び

`HListFunc` を使うことで `prodctA` (別名 `@&&&`) メソッドは以下のように実装できる:

```scala
  /** compose `A => F[B]` and `A => G[B]` into `A => F[B] :: G[B] :: HNil` */
  def productA[G[_]](g: Func[G, TC, A, B]) = consA(g consA hnilfunc[TC, A, B])
```

`Func` はまた `composeA` (シンボルを使ったエイリアスは `<<<@`) とその逆の `andThenA` (シンボルを使ったエイリアスは `@>>>`) も実装する:

```scala
scala> AppFuncU { (x: Int) => (x + 1).some } @>>> AppFuncU { (x: Int) => x + "!" }
res32: scalaz.typelevel.Func[[α]scalaz.Unapply[scalaz.Applicative,Option[Int]]{type M[X] = Option[X]; type A = Int}#M[scalaz.Unapply[scalaz.Applicative,String]{type M[X] = String; type A = String}#M[α]],scalaz.Applicative,Int,String] = scalaz.typelevel.Func$$anon$7@4fcb8010

scala> res32.runA(10)
res33: scalaz.Unapply[scalaz.Applicative,Option[Int]]{type M[X] = Option[X]; type A = Int}#M[scalaz.Unapply[scalaz.Applicative,String]{type M[X] = String; type A = String}#M[String]] = Some(11!)
```

## 数独

`Func` を使った applicative 合成を実際に使って説明する具体例として最初に思いついたのが数独の解法だ。ツールの長所と短所を洗い出すのに丁度いい複雑さだと思う。だからと言って、これが数独を解く最適な方法だと主張するつもりはない。

### 問題の読み込み

以下がオンラインで見つけた簡単な数独ファイルフォーマットの例だ:

    #C comment
    2..1.5..3
    .54...71.
    .1.2.3.8.
    6.28.73.4
    .........
    1.53.98.6
    .2.7.1.6.
    .81...24.
    7..4.2..1

`#` で始まる行はヘッダで、残りの行が問題を表す。問題を単純化するために、まずは 4x4 の数独から始める:

    #C comment
    .13.
    ...4
    ...1
    .24.

まずそれぞれのマスを以下に定義されるセルとして表す:

```scala
case class Cell(pos: (Int, Int), value: Option[Int])
```

ファイルを `Vector[Cell]` にパースするのは簡単だ。

```scala
object Reader {
  import scalaz._
  import Scalaz._

  def read(path: String): Vector[Cell] = read(new File(path))
  def read(file: File): Vector[Cell] = {
    val source = scala.io.Source.fromFile(file, "UTF-8")
    val lines = Vector(source.getLines.toSeq filterNot { x => x.isEmpty || (x startsWith "#") }: _*)
    lines.zipWithIndex flatMap { case (line, idx) =>
      val cs = Vector(line.toSeq: _*)
      (1 |-> lines.size) map { x =>
        Cell((x, idx + 1), cs(x - 1).toString.parseInt.toOption)
      }
    }
  }
}
```

REPL から確認することができる:

```scala
scala> import com.eed3si9n.sudoku._
import com.eed3si9n.sudoku._

scala> Reader.read("data/1.sdk")
res0: Vector[com.eed3si9n.sudoku.Cell] = Vector(Cell((1,1),None), Cell((2,1),Some(1)), Cell((3,1),Some(3)), Cell((4,1),None), Cell((1,2),None), Cell((2,2),None), Cell((3,2),None), Cell((4,2),Some(4)), Cell((1,3),None), Cell((2,3),None), Cell((3,3),None), Cell((4,3),Some(1)), Cell((1,4),None), Cell((2,4),Some(2)), Cell((3,4),Some(4)), Cell((4,4),None))
```

### 仕事の分割

ある特定のセル、例えば `(4, 1)`、に注目してどうやって数独を解くか考えてみよう。僕ならば、まず列を行をチェックして候補を消していって、次に 4つのセルから成るグループもチェックしてさらに候補を消してく。この戦略は簡単な問題になら使えそうだ。

上の戦略を別の見方をすると消去法ということだ。まず `Vector(1, 2, 3, 4)` から始めて、行、列、グループに対応した小さなマシンがチェックを行なって徐々に候補を消していく。これらの小さなマシンは `State` モナドとして実装できる。まず下準備:

```scala
scala> import scalaz._, Scalaz._, typelevel._
import scalaz._
import Scalaz._
import typelevel._

scala> import com.eed3si9n.sudoku._
import com.eed3si9n.sudoku._

scala> val game = Reader.read("data/1.sdk")
game: Vector[com.eed3si9n.sudoku.Cell] = Vector(Cell((1,1),None), Cell((2,1),Some(1)), ...
```

次に横向きのマシン:

```scala
scala>  def horizontalMachine(pos: (Int, Int)) = AppFuncU { cell: Cell =>
          for {
            xs <- get[Vector[Int]]
            _  <- put(if (pos._2 == cell.pos._2 && cell.value.isDefined) xs filter {_ != cell.value.get} 
                      else xs)
          } yield()
        }
horizontalMachine: (pos: (Int, Int))scalaz.typelevel.Func[scalaz.Unapply[scalaz.Applicative,scalaz.StateT[scalaz.Id.Id,Vector[Int],Unit]]{type M[X] = scalaz.StateT[scalaz.Id.Id,Vector[Int],X]; type A = Unit}#M,scalaz.Applicative,Cell,Unit]

scala> horizontalMachine((4, 1)) traverse game
res1: scalaz.Unapply[scalaz.Applicative,scalaz.StateT[scalaz.Id.Id,Vector[Int],Unit]]{type M[X] = scalaz.StateT[scalaz.Id.Id,Vector[Int],X]; type A = Unit}#M[Vector[Unit]] = scalaz.StateT$$anon$7@33d5157f

scala> res1 exec Vector(1, 2, 3, 4)
res2: scalaz.Id.Id[Vector[Int]] = Vector(2, 4)
```

2 と 4 以外は第1行にあるため、結果は妥当みたいだ。縦向きのマシンにも拡張する:

```scala
scala>  def verticalMachine(pos: (Int, Int)) = AppFuncU { cell: Cell =>
          for {
            xs <- get[Vector[Int]]
            _  <- put(if (pos._1 == cell.pos._1 && cell.value.isDefined) xs filter {_ != cell.value.get} 
                      else xs)
          } yield()
        }
verticalMachine: (pos: (Int, Int))scalaz.typelevel.Func[scalaz.Unapply[scalaz.Applicative,scalaz.StateT[scalaz.Id.Id,Vector[Int],Unit]]{type M[X] = scalaz.StateT[scalaz.Id.Id,Vector[Int],X]; type A = Unit}#M,scalaz.Applicative,com.eed3si9n.sudoku.Cell,Unit]

scala> verticalMachine((4, 1)) traverse game
res5: scalaz.Unapply[scalaz.Applicative,scalaz.StateT[scalaz.Id.Id,Vector[Int],Unit]]{type M[X] = scalaz.StateT[scalaz.Id.Id,Vector[Int],X]; type A = Unit}#M[Vector[Unit]] = scalaz.StateT$$anon$7@70a81b43

scala> res5 exec Vector(1, 2, 3, 4)
res6: scalaz.Id.Id[Vector[Int]] = Vector(2, 3)
```

`for` 内包表記の部分は以下のようにリファクタできる:

```scala
scala>  def buildMachine(predicate: Cell => Boolean) = AppFuncU { cell: Cell =>
          for {
            xs <- get[Vector[Int]]
            _  <- put(if (predicate(cell)) xs filter {_ != cell.value.get} 
                      else xs)
          } yield()
        }
buildMachine: (predicate: com.eed3si9n.sudoku.Cell => Boolean)scalaz.typelevel.Func[scalaz.Unapply[scalaz.Applicative,scalaz.StateT[scalaz.Id.Id,Vector[Int],Unit]]{type M[X] = scalaz.StateT[scalaz.Id.Id,Vector[Int],X]; type A = Unit}#M,scalaz.Applicative,com.eed3si9n.sudoku.Cell,Unit]

scala>  def verticallMachine(pos: (Int, Int)) =
          buildMachine { cell: Cell => pos._1 == cell.pos._1 && cell.value.isDefined }
verticallMachine: (pos: (Int, Int))scalaz.typelevel.Func[scalaz.Unapply[scalaz.Applicative,scalaz.StateT[scalaz.Id.Id,Vector[Int],Unit]]{type M[X] = scalaz.StateT[scalaz.Id.Id,Vector[Int],X]; type A = Unit}#M,scalaz.Applicative,com.eed3si9n.sudoku.Cell,Unit]
```

`buildMachine` を使って `groupMachine` も以下のように定義できる:

```scala
scala>  def groupMachine(pos: (Int, Int), n: Int) =
          buildMachine { cell: Cell =>
            ((pos._1 - 1) / n == (cell.pos._1 - 1) / n) &&
            ((pos._2 - 1) / n == (cell.pos._2 - 1) / n) &&
            cell.value.isDefined
          }
groupMachine: (pos: (Int, Int), n: Int)scalaz.typelevel.Func[scalaz.Unapply[scalaz.Applicative,scalaz.StateT[scalaz.Id.Id,Vector[Int],Unit]]{type M[X] = scalaz.StateT[scalaz.Id.Id,Vector[Int],X]; type A = Unit}#M,scalaz.Applicative,com.eed3si9n.sudoku.Cell,Unit]

scala> groupMachine((4, 1)) traverse game
res7: scalaz.Unapply[scalaz.Applicative,scalaz.StateT[scalaz.Id.Id,Vector[Int],Unit]]{type M[X] = scalaz.StateT[scalaz.Id.Id,Vector[Int],X]; type A = Unit}#M[Vector[Unit]] = scalaz.StateT$$anon$7@79f39896

scala> res7 exec Vector(1, 2, 3, 4)
res8: scalaz.Id.Id[Vector[Int]] = Vector(1, 2)
```

次に、3つのマシン全てを並列 (parallel) に実行したいとする。以下のように `HListFunc` を構築できる:

```scala
scala>  def threeMachines(pos: (Int, Int), n: Int) =
          horizontalMachine(pos) :: verticalMachine(pos) :: groupMachine(pos, n) :: AppFunc.HNil
threeMachines: ...
```

ここでの問題はこれが `HList` を返す `Func` を返すことだ。3つの要素とも同じ型なので `List` が欲しい。

### hlist の均質化

`HList` を何かに畳み込む場合は、以下のように `HFold` のサブタイプを定義する:

```scala
scala>  class Homogenize[T] extends HFold[Id, List[T]] {
          type Init = List[T]
          def init = Nil
          type Apply[E, A <: List[T]] = List[T]
          def apply[E, A <: List[T]](elem: E, acc: A) =
            (elem match {
              case x: T => x
            }) :: acc
        }
defined class Homogenize
```

これを使って `HListFunc` を `State` モナドのリストを返す `Func` に変換することができる:

```scala
scala>  def homogenize[M[_]: Applicative, T <: TCList, B](g: HListFunc[TCCons[M, T], Applicative, Cell, B]) =
          new Func[({type λ[α] = List[M[α]]})#λ, Applicative, Cell, B] {  
            def runA(c: Cell): List[M[B]] = {
              val xs = g.runA(c)
              xs.fold[Id, List[M[B]], Homogenize[M[B]]](new Homogenize)
            }
            def F = (Applicative[List] <<: Applicative[M] <<: TC.idCompose).instance
            def TC = g.TC
          }
homogenize: [M[_], T <: scalaz.typelevel.TCList, B](g: scalaz.typelevel.HListFunc[scalaz.typelevel.TCCons[M,T],scalaz.Applicative,com.eed3si9n.sudoku.Cell,B])(implicit evidence$1: scalaz.Applicative[M])scalaz.typelevel.Func[[α]List[M[α]],scalaz.Applicative,com.eed3si9n.sudoku.Cell,B]
```

さらにもう一歩進めて、`State` モナドのリストをリストの `State` モナドに変換することもできる:

```scala
scala>  def sequence[M[_]: Applicative, T <: TCList, B](g: HListFunc[TCCons[M, T], Applicative, Cell, B]) =
          new Func[M, Applicative, Cell, List[B]] {
            def runA(c: Cell): M[List[B]] = {
              val xs = g.runA(c)
              val list: List[M[B]] = xs.fold[Id, List[M[B]], Homogenize[M[B]]](new Homogenize)
              list.sequence
            }
            def F = Applicative[M]
            def TC = g.TC
          }
sequence: [M[_], T <: scalaz.typelevel.TCList, B](g: scalaz.typelevel.HListFunc[scalaz.typelevel.TCCons[M,T],scalaz.Applicative,com.eed3si9n.sudoku.Cell,B])(implicit evidence$1: scalaz.Applicative[M])scalaz.typelevel.Func[M,scalaz.Applicative,com.eed3si9n.sudoku.Cell,List[B]]
```

上記は `State` モナドを連鎖する。 `(4, 1)` で試してみよう:

```scala
scala> sequence(threeMachines((4, 1), 2)) traverse game
res10: scalaz.Unapply[scalaz.Applicative,scalaz.StateT[scalaz.Id.Id,Vector[Int],Unit]]{type M[X] = scalaz.StateT[scalaz.Id.Id,Vector[Int],X]; type A = Unit}#M[Vector[List[Unit]]] = scalaz.StateT$$anon$7@3fc1c1a6

scala> res10 exec Vector(1, 2, 3, 4)
res11: scalaz.Id.Id[Vector[Int]] = Vector(2)
```

これを `cellMachine` を呼ぶことにする:

```scala
object Solver {
  def solve(game: Vector[Cell]) {


  }
  def cellMachine(pos: (Int, Int), n: Int) =
    sequence(horizontalMachine(pos) :: verticalMachine(pos) :: groupMachine(pos, n) :: AppFunc.HNil)
  ...
}
```

### 全てのセルに対して実行する

ここまでの成果を見るために全ての空のセルに対して `cellMachine` を実行してみる:

```scala
object Solver {
  ...
  def runOnce(game: Vector[Cell]) {
    val css = game map { cell: Cell =>
      val cs = cell.value map { v =>
        Vector(v)
      } getOrElse {
        (cellMachine(cell.pos, 2) traverse game) exec Vector(1, 2, 3, 4)
      }
      if (cell.pos._1 == 1) println()
      print(cs.toString + " ") 
      cs
    }
  }
}
```

もう一度 `game` を書いておく:

    #C comment
    .13.
    ...4
    ...1
    .24.

`runOnce` を実行する:

```scala
scala> Solver.runOnce(game)

Vector(2, 4) Vector(1) Vector(3) Vector(2) 
Vector(2, 3) Vector(3) Vector(1, 2) Vector(4) 
Vector(3, 4) Vector(3, 4) Vector(2) Vector(1) 
Vector(1, 3) Vector(2) Vector(4) Vector(3) 
```

この情報を使って、新たな `Vector[Cell]` を返すことができる。まず `Cell` の定義を拡張して候補を保存できるようにする:

```scala
scala> case class Cell(pos: (Int, Int),
         value: Option[Int],
         cs: Vector[Int] = Vector())
defined class Cell
```

ベクトルを渡してまわる代わりに `Game` クラスも作ってしまおう:

```scala
case class Game(cells: Vector[Cell]) {
  import scalaz._
  import Scalaz._

  val n: Int = math.pow(cells.size, 0.5).round.toInt
  val sqrtn: Int = math.pow(n, 0.5).round.toInt
  val allValues = Vector((1 |-> n): _*)
  def apply(pos: (Int, Int)) = (cells.find {_.pos == pos}).get
  override def toString: String = {
    (allValues flatMap { y =>
      allValues flatMap { x =>
        val cell = apply((x, y))
        (cell.value map { x =>
        cell.value.toString
        } getOrElse {cell.cs.toString}) +
        (if (x == n) "\n"
        else " ")
      }
    }).mkString
  }
}
```

以下が更新された `runOnce` だ:

```scala
  def runOnce(game: Game): Game = {
    val (nonEmptyCells, emptyCells) = game.cells partition {_.value.isDefined}
    val solveCells = emptyCells map { cell =>
      val candidates = (cellMachine(cell.pos, game.n) traverse game.cells) exec game.allValues
      if (candidates.size == 1) cell.copy(value = candidates(0).some, cs = Vector())
      else cell.copy(value = none, cs = candidates)
    }
    game.copy(cells = nonEmptyCells ++ solveCells)
  }
```

`runOnce` を連続的に呼び出すことで、いくつかの問題は解けるようになった:

```scala
scala> Solver.runOnce(game)
res0: com.eed3si9n.sudoku.Game = 
Vector(2, 4) Some(1) Some(3) Some(2)
Vector(2, 3) Some(3) Vector(1, 2) Some(4)
Vector(3, 4) Vector(3, 4) Some(2) Some(1)
Vector(1, 3) Some(2) Some(4) Some(3)

scala> Solver.runOnce(res0)
res1: com.eed3si9n.sudoku.Game = 
Some(4) Some(1) Some(3) Some(2)
Some(2) Some(3) Some(1) Some(4)
Vector(3, 4) Some(4) Some(2) Some(1)
Some(1) Some(2) Some(4) Some(3)

scala> Solver.runOnce(res1)
res2: com.eed3si9n.sudoku.Game = 
Some(4) Some(1) Some(3) Some(2)
Some(2) Some(3) Some(1) Some(4)
Some(3) Some(4) Some(2) Some(1)
Some(1) Some(2) Some(4) Some(3)
```

### 全てのセルを並列に

何度もセルを走査するかわりに、マシンを並列に合成できるか試してみたい。

```scala
scala> val (nonEmptyCells, emptyCells) = game.cells partition {_.value.isDefined}
nonEmptyCells: ...
emptyCells: ...

scala> emptyCells.foldLeft[HListFunc[TCList, Applicative, Cell, List[Vector[Int]]]](AppFunc.HNil[Cell, List[Vector[Int]]]) { (acc, cell) => Solver.cellMachine(cell.pos, game.sqrtn) :: acc }
<console>:22: error: type mismatch;
 found   : scalaz.typelevel.HListFunc[scalaz.typelevel.TCNil,scalaz.Applicative,com.eed3si9n.sudoku.Cell,List[Vector[Int]]]
 required: scalaz.typelevel.HListFunc[scalaz.typelevel.TCList,scalaz.Applicative,com.eed3si9n.sudoku.Cell,List[Vector[Int]]]
Note: scalaz.typelevel.TCNil <: scalaz.typelevel.TCList, but trait HListFunc is invariant in type T.
You may wish to define T as +T instead. (SLS 4.5)
              emptyCells.foldLeft[HListFunc[TCList, Applicative, Cell, List[Vector[Int]]]](AppFunc.HNil[Cell, List[Vector[Int]]]) { (acc, cell) => Solver.cellMachine(cell.pos, game.sqrtn) :: acc }
                                                                                                       ^
```

`TCNil` が `TCList` より狭く、また `HListFunc` の型パラメータ `T` が不変であるため `foldLeft` は使うことができない。`HListFunc` には `HList` のような一般トレイトが無いため、`HList` を手作業で構築する羽目になった:

```scala
scala>    def foldCells(xs: Vector[Cell], game: Game): Vector[Cell] = {
            def f(cell: Cell) = Solver.cellMachine(cell.pos, game.sqrtn)
            def homogenize[M[_], B, T <: HList](xs: HCons[M[B], T]): List[M[B]] =
              xs.fold[Id, List[M[B]], Homogenize[M[B]]](new Homogenize)      
            val hnil = AppFunc.HNil[Cell, List[Unit]]
            val css = if (xs.isEmpty) Nil
              else if (xs.size === 1) homogenize((f(xs(0)) :: hnil) traverse game.cells) map {_ exec game.allValues}
              else if (xs.size === 2) homogenize((f(xs(1)) :: f(xs(0)) :: hnil) traverse game.cells) map {_ exec game.allValues}
              else if (xs.size === 3) homogenize((f(xs(2)) :: f(xs(1)) :: f(xs(0)) :: hnil) traverse game.cells) map {_ exec game.allValues}
              else if (xs.size === 4) homogenize((f(xs(3)) :: f(xs(2)) :: f(xs(1)) :: f(xs(0)) :: hnil) traverse game.cells) map {_ exec game.allValues}
              else sys.error("invalid")
            (xs zip css.reverse) map { case (cell, cs) =>
              cell.copy(cs = cs)
            }
          }
foldCells: (xs: Vector[com.eed3si9n.sudoku.Cell], game: com.eed3si9n.sudoku.Game)Vector[com.eed3si9n.sudoku.Cell]

scala> val cellsWithCs = Vector((emptyCells grouped 4).toSeq: _*) flatMap { g => foldCells(g, game) }
cellsWithCs: scala.collection.immutable.Vector[com.eed3si9n.sudoku.Cell] = Vector(Cell((1,1),None,Vector(2, 4)), Cell((4,1),None,Vector(2)), Cell((1,2),None,Vector(2, 3)), Cell((2,2),None,Vector(3)), Cell((3,2),None,Vector(1, 2)), Cell((1,3),None,Vector(3, 4)), Cell((2,3),None,Vector(3, 4)), Cell((3,3),None,Vector(2)), Cell((1,4),None,Vector(1, 3)), Cell((4,4),None,Vector(3)))
```

上記のコードは空のセルを 4つずつ走査する。

### 反復解法器 

問題が解けるまで `runOnce` を呼び出すことで解法を作る。

```scala
case class Game(cells: Vector[Cell]) {
  ...
  def isSolved: Boolean = cells forall {_.value.isDefined} 
}
```

以下が解法だ:

```scala
  def solve(game: Game) {
    def doLoop(g: Game) {
      println(g.toString)
      if (g.isSolved) println("solved")
      else {
        val g2 = runOnce(g)
        if (g == g2) sys.error("solver is stuck")
        else doLoop(g2)
      }
    }
    doLoop(game)
  }
```

簡単な問題ならこれでも解けることは既にみた:

```scala
scala> Solver.solve(game)
....

Some(4) Some(1) Some(3) Some(2)
Some(2) Some(3) Some(1) Some(4)
Some(3) Some(4) Some(2) Some(1)
Some(1) Some(2) Some(4) Some(3)

solved
```

普通の数独はもう少し思考が必要なものだ。例えば、以下を 3.sdk として保存する:

    #C comment
    47..6..59
    ...2.7...
    6.......8
    ..5.8.9..
    .1.7.6.8.
    ..8.4.2..
    8.......2
    ...6.3...
    92..5..16

sbt を使ってこれを `game` として REPL に読み込む:

```scala
initialCommands in console := """import scalaz._, Scalaz._, typelevel._
                                |import com.eed3si9n.sudoku._
                                |val game = com.eed3si9n.sudoku.Reader.read("data/3.sdk")""".stripMargin
```

以下が出力だ:

```scala
scala> Solver.solve(game)
Some(4) Some(7) Vector() Vector() Some(6) Vector() Vector() Some(5) Some(9)
Vector() Vector() Vector() Some(2) Vector() Some(7) Vector() Vector() Vector()
Some(6) Vector() Vector() Vector() Vector() Vector() Vector() Vector() Some(8)
Vector() Vector() Some(5) Vector() Some(8) Vector() Some(9) Vector() Vector()
Vector() Some(1) Vector() Some(7) Vector() Some(6) Vector() Some(8) Vector()
Vector() Vector() Some(8) Vector() Some(4) Vector() Some(2) Vector() Vector()
Some(8) Vector() Vector() Vector() Vector() Vector() Vector() Vector() Some(2)
Vector() Vector() Vector() Some(6) Vector() Some(3) Vector() Vector() Vector()
Some(9) Some(2) Vector() Vector() Some(5) Vector() Vector() Some(1) Some(6)

Some(4) Some(7) Vector(1, 2, 3) Vector(1, 3, 8) Some(6) Vector(1, 8) Vector(1, 3) Some(5) Some(9)
Vector(1, 3, 5) Vector(3, 5, 8, 9) Vector(1, 3, 9) Some(2) Vector(1, 3, 9) Some(7) Vector(1, 3, 4, 6) Vector(3, 4, 6) Vector(1, 3, 4)
Some(6) Vector(3, 5, 9) Vector(1, 2, 3, 9) Vector(1, 3, 4, 5, 9) Vector(1, 3, 9) Vector(1, 4, 5, 9) Vector(1, 3, 4, 7) Vector(2, 3, 4, 7) Some(8)
Vector(2, 3, 7) Vector(3, 4, 6) Some(5) Vector(1, 3) Some(8) Vector(1, 2) Some(9) Vector(3, 4, 6, 7) Vector(1, 3, 4, 7)
Vector(2, 3) Some(1) Vector(2, 3, 4, 9) Some(7) Vector(2, 3, 9) Some(6) Vector(3, 4, 5) Some(8) Vector(3, 4, 5)
Vector(3, 7) Vector(3, 6, 9) Some(8) Vector(1, 3, 5, 9) Some(4) Vector(1, 5, 9) Some(2) Vector(3, 6, 7) Vector(1, 3, 5, 7)
Some(8) Vector(3, 4, 5, 6) Vector(1, 3, 4, 6, 7) Vector(1, 4, 9) Vector(1, 7, 9) Vector(1, 4, 9) Vector(3, 4, 5, 7) Vector(3, 4, 7, 9) Some(2)
Vector(1, 5, 7) Vector(4, 5) Vector(1, 4, 7) Some(6) Vector(1, 2, 7, 9) Some(3) Vector(4, 5, 7, 8) Vector(4, 7, 9) Vector(4, 5, 7)
Some(9) Some(2) Vector(3, 4, 7) Vector(4, 8) Some(5) Vector(4, 8) Vector(3, 4, 7, 8) Some(1) Some(6)

java.lang.RuntimeException: solver is stuck
  at scala.sys.package$.error(package.scala:27)
  ....
```

### ユニークな候補

現在の実装は候補が単一の候補である場合のみ選択される。しかし、たとえセルに対して複数の候補があったとしてもその中の候補のうちの1つがグループや行内の他の候補には無いユニークなものであった場合は、当選とみなされるべきだ。

```scala
scala>  def buildEvalMachine(predicate: Cell => Boolean) = AppFuncU { cell: Cell =>
          for {
            xs <- get[Vector[Int]]
            _  <- put(if (predicate(cell)) xs diff cell.cs
                      else xs)
          } yield ()
        }
buildEvalMachine: (predicate: com.eed3si9n.sudoku.Cell => Boolean)scalaz.typelevel.Func[scalaz.Unapply[scalaz.Applicative,scalaz.StateT[scalaz.Id.Id,Vector[Int],Unit]]{type M[X] = scalaz.StateT[scalaz.Id.Id,Vector[Int],X]; type A = Unit}#M,scalaz.Applicative,com.eed3si9n.sudoku.Cell,Unit]

scala>  def horizEvalMachine(pos: (Int, Int)) =
          buildEvalMachine { cell: Cell => (cell.pos != pos) && (pos._2 == cell.pos._2) }
horizEvalMachine: (pos: (Int, Int))scalaz.typelevel.Func[scalaz.Unapply[scalaz.Applicative,scalaz.StateT[scalaz.Id.Id,Vector[Int],Unit]]{type M[X] = scalaz.StateT[scalaz.Id.Id,Vector[Int],X]; type A = Unit}#M,scalaz.Applicative,com.eed3si9n.sudoku.Cell,Unit]

scala> val cellsWithCs = Vector((emptyCells grouped 4).toSeq: _*) flatMap { g => foldCells(g, game) }
cellsWithCs: scala.collection.immutable.Vector[com.eed3si9n.sudoku.Cell] = Vector(Cell((3,1),None,Vector(1, 2, 3)), ...

scala> horizEvalMachine((3, 1)) traverse cellsWithCs
res8: scalaz.Unapply[scalaz.Applicative,scalaz.StateT[scalaz.Id.Id,Vector[Int],Unit]]{type M[X] = scalaz.StateT[scalaz.Id.Id,Vector[Int],X]; type A = Unit}#M[scala.collection.immutable.Vector[Unit]] = scalaz.StateT$$anon$7@5b06ad02

scala> res8 exec Vector(1, 2, 3)
res9: scalaz.Id.Id[Vector[Int]] = Vector(2)
```

これは良い例だ。`(3, 1)` の位置にあるセルは 3つの候補があったが、この論法を使って `2` に絞りこまれた。3つのマシン全てを並列して実行することができるはずだ。

```scala
  def evalMachine(pos: (Int, Int), n: Int) =
    horizEvalMachine(pos) :: vertEvalMachine(pos) :: groupEvalMachine(pos, n) :: AppFunc.HNil
```

この二次評価の仕組みを取り入れて候補を絞る:

```scala
  def runOnce(game: Game): Game = {
    val (nonEmptyCells, emptyCells) = game.cells partition {_.value.isDefined}
    def homogenize[M[_], B, T <: HList](xs: HCons[M[B], T]): List[M[B]] =
      xs.fold[Id, List[M[B]], Homogenize[M[B]]](new Homogenize) 
    def foldCells(xs: Vector[Cell], game: Game): Vector[Cell] =  ...
    val cellsWithCs = Vector((emptyCells grouped 4).toSeq: _*) flatMap { g => foldCells(g, game) }
    val cellsWithCs2: Vector[Cell] = cellsWithCs map { x =>
      val css = homogenize(evalMachine(x.pos, game.sqrtn) traverse cellsWithCs) map {_ exec x.cs}
      x.copy(cs = (css find {_.size == 1}) | x.cs)
    }
    val solveCells = cellsWithCs2 map { cell =>
      if (cell.cs.size == 1) cell.copy(value = cell.cs(0).some, cs = Vector())
      else cell
    }
    game.copy(cells = nonEmptyCells ++ solveCells)
  }
```

以下が前につまずいた問題を使った解法の出力だ:

```scala
scala> Solver.solve(game)
Some(4) Some(7) Vector() Vector() Some(6) Vector() Vector() Some(5) Some(9)
Vector() Vector() Vector() Some(2) Vector() Some(7) Vector() Vector() Vector()
Some(6) Vector() Vector() Vector() Vector() Vector() Vector() Vector() Some(8)
Vector() Vector() Some(5) Vector() Some(8) Vector() Some(9) Vector() Vector()
Vector() Some(1) Vector() Some(7) Vector() Some(6) Vector() Some(8) Vector()
Vector() Vector() Some(8) Vector() Some(4) Vector() Some(2) Vector() Vector()
Some(8) Vector() Vector() Vector() Vector() Vector() Vector() Vector() Some(2)
Vector() Vector() Vector() Some(6) Vector() Some(3) Vector() Vector() Vector()
Some(9) Some(2) Vector() Vector() Some(5) Vector() Vector() Some(1) Some(6)

Some(4) Some(7) Some(2) Vector(1, 3, 8) Some(6) Vector(1, 8) Vector(1, 3) Some(5) Some(9)
Vector(1, 3, 5) Some(8) Vector(1, 3, 9) Some(2) Vector(1, 3, 9) Some(7) Some(6) Vector(3, 4, 6) Vector(1, 3, 4)
Some(6) Vector(3, 5, 9) Vector(1, 2, 3, 9) Vector(1, 3, 4, 5, 9) Vector(1, 3, 9) Vector(1, 4, 5, 9) Vector(1, 3, 4, 7) Some(2) Some(8)
Vector(2, 3, 7) Vector(3, 4, 6) Some(5) Vector(1, 3) Some(8) Some(2) Some(9) Vector(3, 4, 6, 7) Vector(1, 3, 4, 7)
Vector(2, 3) Some(1) Vector(2, 3, 4, 9) Some(7) Vector(2, 3, 9) Some(6) Vector(3, 4, 5) Some(8) Vector(3, 4, 5)
Vector(3, 7) Vector(3, 6, 9) Some(8) Vector(1, 3, 5, 9) Some(4) Vector(1, 5, 9) Some(2) Vector(3, 6, 7) Vector(1, 3, 5, 7)
Some(8) Vector(3, 4, 5, 6) Some(6) Vector(1, 4, 9) Vector(1, 7, 9) Vector(1, 4, 9) Vector(3, 4, 5, 7) Vector(3, 4, 7, 9) Some(2)
Vector(1, 5, 7) Vector(4, 5) Vector(1, 4, 7) Some(6) Some(2) Some(3) Some(8) Vector(4, 7, 9) Vector(4, 5, 7)
Some(9) Some(2) Vector(3, 4, 7) Vector(4, 8) Some(5) Vector(4, 8) Vector(3, 4, 7, 8) Some(1) Some(6)

Some(4) Some(7) Some(2) Vector(1, 3, 8) Some(6) Vector(1, 8) Vector(1, 3) Some(5) Some(9)
Some(5) Some(8) Vector(1, 3, 9) Some(2) Vector(1, 3, 9) Some(7) Some(6) Vector(3, 4) Vector(1, 3, 4)
Some(6) Vector(3, 5, 9) Vector(1, 3, 9) Vector(1, 3, 4, 5, 9) Vector(1, 3, 9) Vector(1, 4, 5, 9) Some(7) Some(2) Some(8)
Vector(3, 7) Vector(3, 4, 6) Some(5) Vector(1, 3) Some(8) Some(2) Some(9) Vector(3, 4, 6, 7) Vector(1, 3, 4, 7)
Some(2) Some(1) Vector(3, 4, 9) Some(7) Vector(3, 9) Some(6) Vector(3, 4, 5) Some(8) Vector(3, 4, 5)
Vector(3, 7) Vector(3, 6, 9) Some(8) Vector(1, 3, 5, 9) Some(4) Vector(1, 5, 9) Some(2) Vector(3, 6, 7) Vector(1, 3, 5, 7)
Some(8) Vector(3, 4, 5) Some(6) Vector(1, 4, 9) Some(7) Vector(1, 4, 9) Vector(3, 4, 5, 7) Vector(3, 4, 7, 9) Some(2)
Vector(1, 5, 7) Vector(4, 5) Vector(1, 4, 7) Some(6) Some(2) Some(3) Some(8) Some(9) Vector(4, 5, 7)
Some(9) Some(2) Vector(3, 4, 7) Vector(4, 8) Some(5) Vector(4, 8) Vector(3, 4, 7) Some(1) Some(6)

Some(4) Some(7) Some(2) Vector(1, 3, 8) Some(6) Vector(1, 8) Some(1) Some(5) Some(9)
Some(5) Some(8) Vector(1, 3, 9) Some(2) Vector(1, 3, 9) Some(7) Some(6) Vector(3, 4) Vector(1, 3, 4)
Some(6) Vector(3, 9) Vector(1, 3, 9) Vector(1, 3, 4, 5, 9) Vector(1, 3, 9) Vector(1, 4, 5, 9) Some(7) Some(2) Some(8)
Vector(3, 7) Vector(3, 4, 6) Some(5) Vector(1, 3) Some(8) Some(2) Some(9) Vector(3, 4, 6, 7) Vector(1, 3, 4, 7)
Some(2) Some(1) Vector(3, 4, 9) Some(7) Vector(3, 9) Some(6) Vector(3, 4, 5) Some(8) Vector(3, 4, 5)
Vector(3, 7) Vector(3, 6, 9) Some(8) Vector(1, 3, 5, 9) Some(4) Vector(1, 5, 9) Some(2) Vector(3, 6, 7) Vector(1, 3, 5, 7)
Some(8) Vector(3, 4, 5) Some(6) Vector(1, 4, 9) Some(7) Vector(1, 4, 9) Vector(3, 4, 5) Vector(3, 4) Some(2)
Some(1) Vector(4, 5) Vector(1, 4, 7) Some(6) Some(2) Some(3) Some(8) Some(9) Some(7)
Some(9) Some(2) Some(7) Vector(4, 8) Some(5) Vector(4, 8) Vector(3, 4) Some(1) Some(6)

Some(4) Some(7) Some(2) Some(3) Some(6) Some(8) Some(1) Some(5) Some(9)
Some(5) Some(8) Vector(1, 3, 9) Some(2) Vector(1, 3, 9) Some(7) Some(6) Vector(3, 4) Vector(3, 4)
Some(6) Vector(3, 9) Vector(1, 3, 9) Vector(1, 3, 4, 5, 9) Vector(1, 3, 9) Vector(1, 4, 5, 9) Some(7) Some(2) Some(8)
Vector(3, 7) Vector(3, 4, 6) Some(5) Vector(1, 3) Some(8) Some(2) Some(9) Vector(3, 4, 6, 7) Vector(1, 3, 4)
Some(2) Some(1) Vector(3, 4, 9) Some(7) Vector(3, 9) Some(6) Vector(3, 4, 5) Some(8) Vector(3, 4, 5)
Vector(3, 7) Vector(3, 6, 9) Some(8) Vector(1, 3, 5, 9) Some(4) Vector(1, 5, 9) Some(2) Vector(3, 6, 7) Vector(1, 3, 5)
Some(8) Some(3) Some(6) Vector(1, 4, 9) Some(7) Vector(1, 4, 9) Some(5) Vector(3, 4) Some(2)
Some(1) Some(5) Some(4) Some(6) Some(2) Some(3) Some(8) Some(9) Some(7)
Some(9) Some(2) Some(7) Vector(4, 8) Some(5) Vector(4, 8) Some(3) Some(1) Some(6)

Some(4) Some(7) Some(2) Some(3) Some(6) Some(8) Some(1) Some(5) Some(9)
Some(5) Some(8) Vector(1, 3, 9) Some(2) Vector(1, 9) Some(7) Some(6) Vector(3, 4) Vector(3, 4)
Some(6) Some(9) Some(3) Vector(1, 4, 5, 9) Vector(1, 9) Vector(1, 4, 5, 9) Some(7) Some(2) Some(8)
Vector(3, 7) Some(4) Some(5) Some(1) Some(8) Some(2) Some(9) Vector(3, 4, 6, 7) Vector(1, 3, 4)
Some(2) Some(1) Vector(3, 9) Some(7) Some(3) Some(6) Some(4) Some(8) Some(5)
Vector(3, 7) Vector(6, 9) Some(8) Vector(1, 5, 9) Some(4) Vector(1, 5, 9) Some(2) Vector(3, 6, 7) Vector(1, 3, 5)
Some(8) Some(3) Some(6) Vector(1, 4, 9) Some(7) Vector(1, 4, 9) Some(5) Some(4) Some(2)
Some(1) Some(5) Some(4) Some(6) Some(2) Some(3) Some(8) Some(9) Some(7)
Some(9) Some(2) Some(7) Some(8) Some(5) Some(4) Some(3) Some(1) Some(6)

Some(4) Some(7) Some(2) Some(3) Some(6) Some(8) Some(1) Some(5) Some(9)
Some(5) Some(8) Some(1) Some(2) Some(9) Some(7) Some(6) Some(3) Some(4)
Some(6) Some(9) Some(3) Some(4) Some(1) Vector(1, 5) Some(7) Some(2) Some(8)
Vector(3, 7) Some(4) Some(5) Some(1) Some(8) Some(2) Some(9) Some(6) Some(3)
Some(2) Some(1) Some(9) Some(7) Some(3) Some(6) Some(4) Some(8) Some(5)
Vector(3, 7) Some(6) Some(8) Vector(5, 9) Some(4) Vector(5, 9) Some(2) Vector(3, 6, 7) Some(1)
Some(8) Some(3) Some(6) Some(9) Some(7) Some(1) Some(5) Some(4) Some(2)
Some(1) Some(5) Some(4) Some(6) Some(2) Some(3) Some(8) Some(9) Some(7)
Some(9) Some(2) Some(7) Some(8) Some(5) Some(4) Some(3) Some(1) Some(6)

Some(4) Some(7) Some(2) Some(3) Some(6) Some(8) Some(1) Some(5) Some(9)
Some(5) Some(8) Some(1) Some(2) Some(9) Some(7) Some(6) Some(3) Some(4)
Some(6) Some(9) Some(3) Some(4) Some(1) Some(5) Some(7) Some(2) Some(8)
Some(7) Some(4) Some(5) Some(1) Some(8) Some(2) Some(9) Some(6) Some(3)
Some(2) Some(1) Some(9) Some(7) Some(3) Some(6) Some(4) Some(8) Some(5)
Some(3) Some(6) Some(8) Some(5) Some(4) Some(9) Some(2) Some(7) Some(1)
Some(8) Some(3) Some(6) Some(9) Some(7) Some(1) Some(5) Some(4) Some(2)
Some(1) Some(5) Some(4) Some(6) Some(2) Some(3) Some(8) Some(9) Some(7)
Some(9) Some(2) Some(7) Some(8) Some(5) Some(4) Some(3) Some(1) Some(6)

solved
```

これでより難しい数独の問題も解けるようになった。

### aplicative 合成

Gibbons と Oliveira を引用すると:

> モナドは長い間プログラムのいくつかの側面をモジュール化するのに都合が良い抽象体だと考えられてきた。しかし、モナドの合成は難しいことが分かっており、それが便利さを制限している。モナド変換子は解の1つだが、これはプログラムがあらかじめモナド変換子を念頭に置いて書かれることを必要とする。applicative functor にはより豊富な合成演算子の代数系があり、多くの場合モナド変換子を置き換えることができる。

現在 Scalaz 7.0.0-M4 にて使うことのできる `Func` はそれらの合成演算子を導入する。`@&&&` と `::` 演算子は並列に applicative 関数を合成し (積ともいう)、`@>>>` 演算子は applicative 関数を逐次的に合成する。これらの合成は applicative 関数を返し、それはまた別の合成の一部となることができる。

全ての `Monad` は applicative だ。また、あらゆる `Monoid` も monoidal applicative として取り扱うことができる。(Naperian データ構造を zip することでも applicative が得られるらしいが、見たことが無い) 複数のモナドのインスタンスを取り扱う場合、それぞれのコンテキストを覚えておくのが難しくなってくる。applicative 合成は、特に強力な `traverse` メソッドを併せて使うことでこれを推理するのに便利な道具として使える。例えば、以下のコードは 3つの applicative 関数を並列に合成して 1つの `HListFunc` を返す。

```scala
  def evalMachine(pos: (Int, Int), n: Int) =
    horizEvalMachine(pos) :: vertEvalMachine(pos) :: groupEvalMachine(pos, n) :: AppFunc.HNil
```

次に、`evalMachine((3, 1), game.sqrtn) traverse cellsWithCs` を呼び出すことで `cellsWithCs` を1回走査しただけで `State` モナドの `HList` を得ることができる:

```scala
scala> Solver.evalMachine((3, 1), game.sqrtn) traverse cellsWithCs
res1: scalaz.typelevel.TCCons[scalaz.Unapply[scalaz.Applicative,scalaz.StateT[scalaz.Id.Id,Vector[Int],Unit]]{type M[X] = scalaz.StateT[scalaz.Id.Id,Vector[Int],X]; type A = Unit}#M,scalaz.typelevel.TCCons[scalaz.Unapply[scalaz.Applicative,scalaz.StateT[scalaz.Id.Id,Vector[Int],Unit]]{type M[X] = scalaz.StateT[scalaz.Id.Id,Vector[Int],X]; type A = Unit}#M,scalaz.typelevel.TCCons[scalaz.Unapply[scalaz.Applicative,scalaz.StateT[scalaz.Id.Id,Vector[Int],Unit]]{type M[X] = scalaz.StateT[scalaz.Id.Id,Vector[Int],X]; type A = Unit}#M,scalaz.typelevel.TCNil]]]#Product[scala.collection.immutable.Vector[Unit]] = GenericCons(scalaz.StateT$$anon$7@273cf345,GenericCons(scalaz.StateT$$anon$7@12874b23,GenericCons(scalaz.StateT$$anon$7@7055f055,GenericNil())))
```

それはあたかもそれぞれの評価マシンが独立して `cellsWithCs` を走査したかのようだ。3つの要素全てが同じ型を含むため、これは普通のリストへと変換することができる:

```scala
scala> homogenize(res1)
res2: List[scalaz.Unapply[scalaz.Applicative,scalaz.StateT[scalaz.Id.Id,Vector[Int],Unit]]{type M[X] = scalaz.StateT[scalaz.Id.Id,Vector[Int],X]; type A = Unit}#M[scala.collection.immutable.Vector[Unit]]] = List(scalaz.StateT$$anon$7@273cf345, scalaz.StateT$$anon$7@12874b23, scalaz.StateT$$anon$7@7055f055)
```

あとは、`State` モナドを別々に評価してもいいし、`sequence` を呼んでモナドのリストをリストのモナドに変換してもいい。大切なのは個々のマシンがいかにモジュール化されているかということだ。それぞれが独立して実行されることが期待されているため、いくつかの簡単なタスクに専念することができる。

### 今後の課題

現行の実装では、リストのような別のソースから `HListFunc` を生成することができなかった。これは `HListFunc` のそれぞれが中に格納している要素によって型が変わってしまうためだ。`HList` はこの問題に対して `HList` という共通トレイトを提供して回避している。`HListFunc` は `Func` を直接継承せずに暗黙に変換できるようにすればいいのかもしれない。

あともう1つみておく価値があるのは関数の非同期処理だ。ここまでみてきた並列合成はあくまで意味論的な並列であって、実際の処理は逐次的に実行される。[抽象的な Future](http://www.precog.com/blog-precog-2/entry/the-abstract-future) みたいなものと組み合わせることで、他のコアに負荷を分散できるかもしれない。

### ソース

- [eed3si9n/sudoku.scala](https://github.com/eed3si9n/sudoku.scala)
