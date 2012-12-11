> This is the 5th entry of [Scalaz Advent Calencar 2012](http://partake.in/events/7211abc9-ebb8-4670-b912-3089dc5e0edd).

During the months of December, tech-savvy geeks in Japan take turns to post themed blog articles, known as the "Advent Calendar". For last year's [Scala Advent Calendar 2011](http://partake.in/events/33870915-f25b-40b6-9456-b898b898d48b) I [translated](http://eed3si9n.com/ja/essence-of-iterator-pattern) Eric Torreborre's post covering [The Essence of Iterator Pattern](http://etorreborre.blogspot.com/2011/06/essence-of-iterator-pattern.html). It was somewhat of a calculated move, knowing Japanese fondness for functional programming articles. Another selfish motive was that some of the concept would seep in to my thickness as I was translating the post word by word. In hindsight, both goals were achieved handsomely thanks to the quality of both Jeremy Gibbons, Bruno Oliveira and Eric's work. This seeped in knowledge was probably the secret sauce behind the learning Scalaz series that I worked on this year.

As covered in [learning Scalaz day 12](http://eed3si9n.com/learning-scalaz-day12) Scalaz 7 already included `product` and `compose` methods in typeclass instances as well as [`Traverse`](https://github.com/scalaz/scalaz/blob/scalaz-seven/core/src/main/scala/scalaz/Traverse.scala). It even has [the word count example](https://github.com/scalaz/scalaz/blob/c0f74398fdbc4f804fa06429fb58db4a9d3aafb0/example/src/main/scala/scalaz/example/WordCount.scala) from the paper. What I realized missing was the value-level composition. One of the interesting points from the paper was "composition of applicative functors," which enables a kind of modular  programming.

By "applicative functors" Gibbons and Oliveira actually mean composition of applicative functions, not just the typeclass instances. This is evident in the following snippet from the paper:

<haskell>
data (m ⊠ n) a = Prod { pfst :: m a, psnd :: n a }
(⊗) :: (Functor m, Functor n) ⇒ (a → m b) → (a → n b) → (a → (m ⊠ n) b)
(f ⊗ g) x = Prod(f x)(gx)
</haskell>

The algebraic data type `⊠` is the type-level product, while the infix function `⊗` is the value-level product of two applicative functions, which returns applicative function of type `a → (m ⊠ n) `. In other words, the programmer would construct functions that return an applicative functor, and the type-level compositions are done automatically.

### Func

`Func` is my attempt to provide value-level composition of applicative functions.

<scala>
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
</scala>

Similar to [`Kleisli`](https://github.com/scalaz/scalaz/blob/scalaz-seven/core/src/main/scala/scalaz/Kleisli.scala), [`Func`](https://github.com/scalaz/scalaz/blob/scalaz-seven/typelevel/src/main/scala/scalaz/typelevel/Func.scala) represents a function `A => F[B]`:

<scala>
trait Func[F[_], TC[F[_]] <: Functor[F], A, B] { self =>
  def runA(a: A): F[B]
  implicit def TC: KTypeClass[TC]
  implicit def F: TC[F]
}
</scala>

The `runA` method runs the function, similar to `apply` method.

`Func` also implements `productA` method (symbolic alias `@&&&`), which returns another `Func`. The original implementation of `Func` was called `AppFunc` and it was specialized to applicative functors. Per suggestion by Lars Hupel ([@larsr_h](https://twitter.com/larsr_h)) it was refactored to be `Func` that is generic over typeclass.

### scalaz-typelevel module

The `product` and `compose` methods implemented at individual typeclass in core module are independent from each other since they do not share the same signature. For example, `product` under `Functor` returns `Functor[({type λ[α] = (F[α], G[α])})#λ]`, and `product` under `Applicative` returns `Applicative[({type λ[α] = (F[α], G[α])})#λ]`.

The scalaz-typelevel module contains type-level data structure (and also type-safe printf according to the readme). What I am after is [`KTypeClass`](https://github.com/scalaz/scalaz/blob/scalaz-seven/typelevel/src/main/scala/scalaz/typelevel/KTypeClass.scala), which is a typeclass of typeclasses with kind `* -> *` like `Functor` and `Applicative`. Its main feature is generic `product` and `compose` methods:

<scala>
trait KTypeClass[C[_[_]]] {
  def product[F[_], T <: TCList](FHead: C[F], FTail: C[T#Product]): C[TCCons[F, T]#Product]
  def compose[F[_], T <: TCList](FOuter: C[F], FInner: C[T#Composed]): C[TCCons[F, T]#Composed]
}
</scala>

Instead of using `Tuple2` to encode products, `KTypeClass` uses an `HList` to encode products. This is also included in scalaz-typelvel module. Unlike a `List` that is limited to preserving one type for all elements, `HList` preserves all types of the elements:

<scala>
scala> List(1, "string").head
res1: Any = 1

scala> (1 :: "string" :: HNil).head
res2: scalaz.Id.Id[Int] = 1
</scala>

To accommodate both `Int` and `String` the first `List` was widened to `List[Any]` while `HList` preserved the type.

### HListFunc

Following EIP, my implmenetation of `Func` only supported product of two functions using `@&&&` operator. If someone were to chain `@&&&`, it would nest an `HList` within an `HList`. Lars suggested that we should be able to grow the `HList` instead.

After a few weeks I've come up with `HListFunc`, a wrapper function that returns an `HList`, which extends `Func`:

<scala>
trait HListFunc[T <: TCList, TC[X[_]] <: Functor[X], A, B] extends Func[T#Product, TC, A, B] { self =>
  def ::[G[_]](g: Func[G, TC, A, B]) = g consA self
  private[scalaz] def Product: KTypeClass.WrappedProduct[TC, T]
  final def F = Product.instance
}
</scala>

There are two ways of creating an `HListFunc`. First, is to call `HNil` method under one of the specialized `Func` objects such as `AppFunc`:

<scala>
scala> AppFunc.HNil
res7: scalaz.typelevel.HListFunc[scalaz.typelevel.TCNil,scalaz.Applicative,Nothing,Nothing] = scalaz.typelevel.FuncFunctions$$anon$6@1e525ac8

scala> AppFunc.HNil[Int, Int]
res8: scalaz.typelevel.HListFunc[scalaz.typelevel.TCNil,scalaz.Applicative,Int,Int] = scalaz.typelevel.FuncFunctions$$anon$6@6e8d1f6a

scala> res8.runA(0)
res9: scalaz.typelevel.TCNil#Product[Int] = GenericNil()
</scala>

The second way of creating an `HListFunc` is to use `::` operator on an existing `HListFunc`:

<scala>
scala> AppFuncU { (x: Int) => x + 1 } :: AppFunc.HNil
res15: scalaz.typelevel.HListFunc[scalaz.typelevel.TCCons[scalaz.Unapply[scalaz.Applicative,Int]{type M[X] = Int; type A = Int}#M,scalaz.typelevel.TCNil],scalaz.Applicative,Int,Int] = scalaz.typelevel.Func$$anon$4@34f262c3
</scala>

### Func again

Using `HListFunc` the `productA` (or `@&&&`) method is implemented as follows:

<scala>
  /** compose `A => F[B]` and `A => G[B]` into `A => F[B] :: G[B] :: HNil` */
  def productA[G[_]](g: Func[G, TC, A, B]) = consA(g consA hnilfunc[TC, A, B])
</scala>

`Func` also implements `composeA` method with symbolic alias `<<<@`, and its flip `andThenA` method with symbolic alias `@>>>`:

<scala>
scala> AppFuncU { (x: Int) => (x + 1).some } @>>> AppFuncU { (x: Int) => x + "!" }
res32: scalaz.typelevel.Func[[α]scalaz.Unapply[scalaz.Applicative,Option[Int]]{type M[X] = Option[X]; type A = Int}#M[scalaz.Unapply[scalaz.Applicative,String]{type M[X] = String; type A = String}#M[α]],scalaz.Applicative,Int,String] = scalaz.typelevel.Func$$anon$7@4fcb8010

scala> res32.runA(10)
res33: scalaz.Unapply[scalaz.Applicative,Option[Int]]{type M[X] = Option[X]; type A = Int}#M[scalaz.Unapply[scalaz.Applicative,String]{type M[X] = String; type A = String}#M[String]] = Some(11!)
</scala>

## sudoku

The first thing that came to my mind to demonstrate applicative composition using `Func` was writing a sudoku solver. It should be complex enough to bring out some of the strength and weakness of the tool. It may not be the best way to solve sudoku.

### reading a puzzle

Here's an example of simple sudoku file format I found online:

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

Lines starting with `#` are headers, and the rest of the lines denote a puzzle. For the sake of simplicity I am going first solve the following 4x4 sudoku first:

    #C comment
    .13.
    ...4
    ...1
    .24.

We can represent each spot as a cell defined as follows:

<scala>
case class Cell(pos: (Int, Int), value: Option[Int])
</scala>

Parsing a file into `Vector[Cell]` is trivial.

<scala>
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
</scala>

We can confirm this from the REPL:

<scala>
scala> import com.eed3si9n.sudoku._
import com.eed3si9n.sudoku._

scala> Reader.read("data/1.sdk")
res0: Vector[com.eed3si9n.sudoku.Cell] = Vector(Cell((1,1),None), Cell((2,1),Some(1)), Cell((3,1),Some(3)), Cell((4,1),None), Cell((1,2),None), Cell((2,2),None), Cell((3,2),None), Cell((4,2),Some(4)), Cell((1,3),None), Cell((2,3),None), Cell((3,3),None), Cell((4,3),Some(1)), Cell((1,4),None), Cell((2,4),Some(2)), Cell((3,4),Some(4)), Cell((4,4),None))
</scala>

### splitting the work

Focusing on a particular cell, for example `(4, 1)`, how would one go about solving sudoku? I would check the column and row to eliminate possible candidates, and then check the cell's four-cell group to eliminate further candidates. This strategy works for easier puzzles.

Another way of looking at the above strategy is the process of elimination. We start out with `Vector(1, 2, 3, 4)` and each small machine can check for a row, a column, or a group, gradually eliminating the candidates. These small machines can be implemented as a `State` monad. First here's the setup:

<scala>
scala> import scalaz._, Scalaz._, typelevel._
import scalaz._
import Scalaz._
import typelevel._

scala> import com.eed3si9n.sudoku._
import com.eed3si9n.sudoku._

scala> val game = Reader.read("data/1.sdk")
game: Vector[com.eed3si9n.sudoku.Cell] = Vector(Cell((1,1),None), Cell((2,1),Some(1)), ...
</scala>

Next, here's the horizontal machine:

<scala>
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
</scala>

The result seems to be consistent with the game since all numbers except 2 and 4 are present in the first row. We can expand this logic to the vertical machine:

<scala>

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
</scala>

`for` comprehension part can be refactored out as follows:

<scala>
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
</scala>

Using `buildMachine`, we can define `groupMachine` as follows:

<scala>
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
</scala>

Next, we would like to run all three machines in parallel. We can construct `HListFunc` as follows:

<scala>
scala>  def threeMachines(pos: (Int, Int), n: Int) =
          horizontalMachine(pos) :: verticalMachine(pos) :: groupMachine(pos, n) :: AppFunc.HNil
threeMachines: ...
</scala>

The problem here is that this now returns a `Func` that returns an `HList`. We would like a `List` instead since all three elements contain the same type.

### homogenizing hlist

To fold an hlist into something we would define a `HFold` subtype as follows:

<scala>
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
</scala>

By using this, we can now turn `HListFunc` into a `Func` that returns a list of state monads:

<scala>
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
</scala>

Then we can go even further by turning the list of state monad into a state monad of a list:

<scala>
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
</scala>

The above should chain the state monads together. Let's try it for `(4, 1)`:

<scala>
scala> sequence(threeMachines((4, 1), 2)) traverse game
res10: scalaz.Unapply[scalaz.Applicative,scalaz.StateT[scalaz.Id.Id,Vector[Int],Unit]]{type M[X] = scalaz.StateT[scalaz.Id.Id,Vector[Int],X]; type A = Unit}#M[Vector[List[Unit]]] = scalaz.StateT$$anon$7@3fc1c1a6

scala> res10 exec Vector(1, 2, 3, 4)
res11: scalaz.Id.Id[Vector[Int]] = Vector(2)
</scala>

Let's call this a `cellMachine`:

<scala>
object Solver {
  def solve(game: Vector[Cell]) {


  }
  def cellMachine(pos: (Int, Int), n: Int) =
    sequence(horizontalMachine(pos) :: verticalMachine(pos) :: groupMachine(pos, n) :: AppFunc.HNil)
  ...
}
</scala>

### running for all cells

We can now run the `cellMachine` for all empty cells to see the progress so far:

<scala>
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
</scala>

Here's `game` again:

    #C comment
    .13.
    ...4
    ...1
    .24.

Let's run `runOnce`:

<scala>
scala> Solver.runOnce(game)

Vector(2, 4) Vector(1) Vector(3) Vector(2) 
Vector(2, 3) Vector(3) Vector(1, 2) Vector(4) 
Vector(3, 4) Vector(3, 4) Vector(2) Vector(1) 
Vector(1, 3) Vector(2) Vector(4) Vector(3) 
</scala>

Using this information, we can now return a new `Vector[Cell]`. First, let's expand the definition of `Cell` to store potential candidates:

<scala>
scala> case class Cell(pos: (Int, Int),
         value: Option[Int],
         cs: Vector[Int] = Vector())
defined class Cell
</scala>

Also we should probably create a `Game` class instead of passing vectors around:

<scala>
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
</scala>

Here's the updated `runOnce`:

<scala>
  def runOnce(game: Game): Game = {
    val (nonEmptyCells, emptyCells) = game.cells partition {_.value.isDefined}
    val solveCells = emptyCells map { cell =>
      val candidates = (cellMachine(cell.pos, game.n) traverse game.cells) exec game.allValues
      if (candidates.size == 1) cell.copy(value = candidates(0).some, cs = Vector())
      else cell.copy(value = none, cs = candidates)
    }
    game.copy(cells = nonEmptyCells ++ solveCells)
  }
</scala>

By calling `runOnce` repeatedly we are now able to solve some problems:

<scala>
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
</scala>

### all cells in parallel

Instead of traversing multiple times, let's see if we can compose machines in parallel.

<scala>
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
</scala>

We cannot use `foldLeft` because the type `TCNil` is narrower than `TCList`, and type parameter `T` of `HListFunc` is invariant. Since `HListFunc` doesn't have a general trait like `HList`, I am going to resort to constructing `HList` manually:

<scala>
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
</scala>

The above code traverses 4 empty cells at a time.

### iterating solver 

Let's implement the solver by calling `runOnce` until the game is solved.

<scala>
case class Game(cells: Vector[Cell]) {
  ...
  def isSolved: Boolean = cells forall {_.value.isDefined} 
}
</scala>

Here's the solver:

<scala>
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
</scala>

We already saw that this solves easy games:

<scala>
scala> Solver.solve(game)
....

Some(4) Some(1) Some(3) Some(2)
Some(2) Some(3) Some(1) Some(4)
Some(3) Some(4) Some(2) Some(1)
Some(1) Some(2) Some(4) Some(3)

solved
</scala>

Normally a game of sudoku requires a bit more thinking. For example, save the following as 3.sdk:

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

Using sbt we can load this file as `game` in REPL:

<scala>
initialCommands in console := """import scalaz._, Scalaz._, typelevel._
                                |import com.eed3si9n.sudoku._
                                |val game = com.eed3si9n.sudoku.Reader.read("data/3.sdk")""".stripMargin
</scala>

Here's the output:

<scala>
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
</scala>

### unique candidate

The current implementation selects a candidate when it's the only candidate. But even for a cell that has multiple candidates, if one of the candidates is unique among any of the peers, it should also be considered eligible.

<scala>
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
</scala>

This is a nice example. The cell in position `(3, 1)` started with three candidates, but it got narrowed down to `2` using this logic. We should be able to run all three machines in parallel.

<scala>
  def evalMachine(pos: (Int, Int), n: Int) =
    horizEvalMachine(pos) :: vertEvalMachine(pos) :: groupEvalMachine(pos, n) :: AppFunc.HNil
</scala>

Now we can incorporate this secondary evaluation to narrow down the candidates:

<scala>
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
</scala>

Here's the solver output for the game that got stuck previously:

<scala>
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
</scala>

This is able to solve more difficult sudoku puzzles.

### aplicative composition

To quote Gibbons and Oliveira:

> Monads have long been acknowledged as a good abstraction for modularising certain aspects of programs. However, composing monads is known to be difficult, limiting their usefulness. One solution is to use monad transformers, but this requires programs to be designed initially with monad transformers in mind. Applicative functors have a richer algebra of composition operators, which can often replace the use of monad transformers.

`Func` that is currently available in Scalaz 7.0.0-M4 introduces such composition operators. `@&&&` and `::` operator compose applicative functions in parallel (also known as product), while `@>>>` operator composes applicative functions in sequence. These compositions return applicative functions, which in turn could also be part of further compositions.

All `Monad`s are applicative. Any `Monoid` can also be treated as a monoidal applicative. (Zipping together Naperian data structure gives applicative too, but I haven't seen one.) When dealing with multiple instances of monads, keeping each context straight in your head can get complicated. Applicative compositions can be used to reason about them, especially combined with the mighty `traverse` method. For example, the following composes three applicative functions in parallel and returns a single `HListFunc`.

<scala>
  def evalMachine(pos: (Int, Int), n: Int) =
    horizEvalMachine(pos) :: vertEvalMachine(pos) :: groupEvalMachine(pos, n) :: AppFunc.HNil
</scala>

Next by calling `evalMachine((3, 1), game.sqrtn) traverse cellsWithCs` in a single traversal over `cellsWithCs` it produces an hlist of state monads:

<scala>
scala> Solver.evalMachine((3, 1), game.sqrtn) traverse cellsWithCs
res1: scalaz.typelevel.TCCons[scalaz.Unapply[scalaz.Applicative,scalaz.StateT[scalaz.Id.Id,Vector[Int],Unit]]{type M[X] = scalaz.StateT[scalaz.Id.Id,Vector[Int],X]; type A = Unit}#M,scalaz.typelevel.TCCons[scalaz.Unapply[scalaz.Applicative,scalaz.StateT[scalaz.Id.Id,Vector[Int],Unit]]{type M[X] = scalaz.StateT[scalaz.Id.Id,Vector[Int],X]; type A = Unit}#M,scalaz.typelevel.TCCons[scalaz.Unapply[scalaz.Applicative,scalaz.StateT[scalaz.Id.Id,Vector[Int],Unit]]{type M[X] = scalaz.StateT[scalaz.Id.Id,Vector[Int],X]; type A = Unit}#M,scalaz.typelevel.TCNil]]]#Product[scala.collection.immutable.Vector[Unit]] = GenericCons(scalaz.StateT$$anon$7@273cf345,GenericCons(scalaz.StateT$$anon$7@12874b23,GenericCons(scalaz.StateT$$anon$7@7055f055,GenericNil())))
</scala>

It's as if each evaluation machine traversed `cellsWithCs` independently. Since all three elements contain the same type, I can convert it into a plain list:

<scala>
scala> homogenize(res1)
res2: List[scalaz.Unapply[scalaz.Applicative,scalaz.StateT[scalaz.Id.Id,Vector[Int],Unit]]{type M[X] = scalaz.StateT[scalaz.Id.Id,Vector[Int],X]; type A = Unit}#M[scala.collection.immutable.Vector[Unit]]] = List(scalaz.StateT$$anon$7@273cf345, scalaz.StateT$$anon$7@12874b23, scalaz.StateT$$anon$7@7055f055)
</scala>

From here we can simply evaluate the state monad individually to get the evaluations, or call `sequence` to turn the list of monads into a monad of list. What's important is how modular individual machines are. Since they are expected to run independently, they can focus on a few simple tasks.

### future works

With the current implementation, I could not find how to generate `HListFunc` from other sources like a list. This is due to the fact that each `HListFunc` has a unique type depending on the item that it stores. HList works around this issue by providing the common `HList` trait. Perhaps `HListFunc` should be implicitly convertible to `Func` instead of directly extending it.

Another area worth looking into is asynchronous processing of the functions. The parallel composition we've discussed so far are parallel in semantics, but the actual processing has been done sequentially. By combining something like [the abstract future](http://www.precog.com/blog-precog-2/entry/the-abstract-future), it might be possible to distribute load off to other cores.

### source

- [eed3si9n/sudoku.scala](https://github.com/eed3si9n/sudoku.scala)
