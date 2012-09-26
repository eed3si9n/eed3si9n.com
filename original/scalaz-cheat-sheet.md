<table width="100%" class="cheatsheet">
<tr>
<td width="50%" valign="top">
<div markdown="1" class="cheatsheet">
### Equal[A]
<scala>
def equal(a1: A, a2: A): Boolean
(1 === 2) assert_=== false
(2 =/= 1) assert_=== true
</scala>
</div>

<div markdown="1" class="cheatsheet">
### Order[A]
<scala>
def order(x: A, y: A): Ordering
1.0 ?|? 2.0 assert_=== Ordering.LT
1.0 lt 2.0 assert_=== true
1.0 gt 2.0 assert_=== false
1.0 lte 2.0 assert_=== true
1.0 gte 2.0 assert_=== false
1.0 max 2.0 assert_=== 2.0
1.0 min 2.0 assert_=== 1.0
</scala>
</div>

<div markdown="1" class="cheatsheet">
### Show[A]
<scala>
def show(f: A): Cord
1.0.show assert_=== Cord("1.0")
1.0.shows assert_=== "1.0"
1.0.print assert_=== ()
1.0.println assert_=== ()
</scala>
</div>

<div markdown="1" class="cheatsheet">
### Enum[A] extends Order[A]
<scala>
def pred(a: A): A
def succ(a: A): A
1.0 |-> 2.0 assert_=== List(1.0, 2.0)
1.0 |--> (2, 5) assert_=== List(1.0, 3.0, 5.0)
// |=>/|==>/from/fromStep return EphemeralStream[A]
(1.0 |=> 2.0).toList assert_=== List(1.0, 2.0)
(1.0 |==> (2, 5)).toList assert_=== List(1.0, 3.0, 5.0)
(1.0.from take 2).toList assert_=== List(1.0, 2.0)
((1.0 fromStep 2) take 2).toList assert_=== List(1.0, 3.0)
1.0.pred assert_=== 0.0
1.0.predx assert_=== Some(0.0)
1.0.succ assert_=== 2.0
1.0.succx assert_=== Some(2.0)
1.0 -+- 1 assert_=== 2.0
1.0 --- 1 assert_=== 0.0
Enum[Int].min assert_=== Some(-2147483648)
Enum[Int].max assert_=== Some(2147483647)
</scala>
</div>

<div markdown="1" class="cheatsheet">
### Semigroup[A]
<scala>
def append(a1: A, a2: => A): A
List(1, 2) |+| List(3) assert_=== List(1, 2, 3)
List(1, 2) mappend List(3) assert_=== List(1, 2, 3)
1 |+| 2 assert_=== 3
(Tags.Multiplication(2) |+| Tags.Multiplication(3): Int) assert_=== 6
// Tags.Disjunction (||), Tags.Conjunction (&&)
(Tags.Disjunction(true) |+| Tags.Disjunction(false): Boolean) assert_=== true
(Tags.Conjunction(true) |+| Tags.Conjunction(false): Boolean) assert_=== false
(Ordering.LT: Ordering) |+| (Ordering.GT: Ordering) assert_=== Ordering.LT
(none: Option[String]) |+| "andy".some assert_=== "andy".some
(Tags.First('a'.some) |+| Tags.First('b'.some): Option[Char]) assert_=== 'a'.some
(Tags.Last('a'.some) |+| Tags.Last(none: Option[Char]): Option[Char]) assert_=== 'a'.some
</scala>
</div>

<div markdown="1" class="cheatsheet">
### Monoid[A] extends Semigroup[A]
<scala>
def zero: A
mzero[List[Int]] assert_=== Nil
</scala>
</div>

<div markdown="1" class="cheatsheet">
### Functor[F[_]]
<scala>
def map[A, B](fa: F[A])(f: A => B): F[B]
List(1, 2, 3) map {_ + 1} assert_=== List(2, 3, 4)
List(1, 2, 3) ∘ {_ + 1} assert_=== List(2, 3, 4)
List(1, 2, 3) >| "x" assert_=== List("x", "x", "x")
List(1, 2, 3) as "x" assert_=== List("x", "x", "x")
List(1, 2, 3).fpair assert_=== List((1,1), (2,2), (3,3))
List(1, 2, 3).strengthL("x") assert_=== List(("x",1), ("x",2), ("x",3))
List(1, 2, 3).strengthR("x") assert_=== List((1,"x"), (2,"x"), (3,"x"))
List(1, 2, 3).void assert_=== List((), (), ())
Functor[List].lift {(_: Int) * 2} (List(1, 2, 3)) assert_=== List(2, 4, 6)
</scala>
</div>

<div markdown="1" class="cheatsheet">
### Pointed[F[_]] extends Functor[F]
<scala>
def point[A](a: => A): F[A]
1.point[List] assert_=== List(1)
1.η[List] assert_=== List(1)
</scala>
</div>

<div markdown="1" class="cheatsheet">
### Apply[F[_]] extends Functor[F]
<scala>
def ap[A,B](fa: => F[A])(f: => F[A => B]): F[B]
1.some <*> {(_: Int) + 2}.some assert_=== Some(3) // except in 7.0.0-M3
1.some <*> { 2.some <*> {(_: Int) + (_: Int)}.curried.some } assert_=== 3.some
1.some <* 2.some assert_=== 1.some
1.some *> 2.some assert_=== 2.some
Apply[Option].ap(9.some) {{(_: Int) + 3}.some} assert_=== 12.some
Apply[List].lift2 {(_: Int) * (_: Int)} (List(1, 2), List(3, 4)) assert_=== List(3, 4, 6, 8)
(3.some |@| 5.some) {_ + _} assert_=== 8.some
// ^(3.some, 5.some) {_ + _} assert_=== 8.some
</scala>
</div>

<div markdown="1" class="cheatsheet">
### Applicative[F[_]] extends Apply[F] with Pointed[F]
<scala>
// no contract function
</scala>
</div>

<div markdown="1" class="cheatsheet">
### Product/Composition
<scala>
(Applicative[Option] product Applicative[List]).point(0) assert_=== (0.some, List(0))
(Applicative[Option] compose Applicative[List]).point(0) assert_=== List(0).some
</scala>
</div>

<div markdown="1" class="cheatsheet">
### Bind[F[_]] extends Apply[F]
<scala>
def bind[A, B](fa: F[A])(f: A => F[B]): F[B]
3.some flatMap { x => (x + 1).some } assert_=== 4.some
(3.some >>= { x => (x + 1).some }) assert_=== 4.some 
3.some >> 4.some assert_=== 4.some
List(List(1, 2), List(3, 4)).join assert_=== List(1, 2, 3, 4)
</scala>
</div>

<div markdown="1" class="cheatsheet">
### Monad[F[_]] extends Applicative[F] with Bind[F]
<scala>
// no contract function
// failed pattern matching produces None
(for {(x :: xs) <- "".toList.some} yield x) assert_=== none
(for { n <- List(1, 2); ch <- List('a', 'b') } yield (n, ch)) assert_=== List((1, 'a'), (1, 'b'), (2, 'a'), (2, 'b'))
(for { a <- (_: Int) * 2; b <- (_: Int) + 10 } yield a + b)(3) assert_=== 19
List(1, 2) filterM { x => List(true, false) } assert_=== List(List(1, 2), List(1), List(2), List())
</scala>
</div>

<div markdown="1" class="cheatsheet">
### Plus[F[_]]
<scala>
def plus[A](a: F[A], b: => F[A]): F[A]
List(1, 2) <+> List(3, 4) assert_=== List(1, 2, 3, 4)
</scala>
</div>

<div markdown="1" class="cheatsheet">
### PlusEmpty[F[_]] extends Plus[F]
<scala>
def empty[A]: F[A]
(PlusEmpty[List].empty: List[Int]) assert_=== Nil
</scala>
</div>

<div markdown="1" class="cheatsheet">
### ApplicativePlus[F[_]] extends Applicative[F] with PlusEmpty[F]
<scala>
// no contract function
</scala>
</div>

<div markdown="1" class="cheatsheet">
### MonadPlus[F[_]] extends Monad[F] with ApplicativePlus[F]
<scala>
// no contract function
List(1, 2, 3) filter {_ > 2} assert_=== List(3)
</scala>
</div>

<div markdown="1" class="cheatsheet">
### Foldable[F[_]]
<scala>
def foldMap[A,B](fa: F[A])(f: A => B)(implicit F: Monoid[B]): B
def foldRight[A, B](fa: F[A], z: => B)(f: (A, => B) => B): B
List(1, 2, 3).foldRight (0) {_ + _} assert_=== 6
List(1, 2, 3).foldLeft (0) {_ + _} assert_=== 6
(List(1, 2, 3) foldMap {Tags.Multiplication}: Int) assert_=== 6
List(1, 2, 3).foldLeftM(0) { (acc, x) => (acc + x).some } assert_=== 6.some
</scala>
</div>

<div markdown="1" class="cheatsheet">
### Traverse[F[_]] extends Functor[F] with Foldable[F]
<scala>
def traverseImpl[G[_]:Applicative,A,B](fa: F[A])(f: A => G[B]): G[F[B]]
List(1, 2, 3) traverse { x => (x > 0) option (x + 1) } assert_=== List(2, 3, 4).some
List(1, 2, 3) traverseU {_ + 1} assert_=== 9
List(1.some, 2.some).sequence assert_=== List(1, 2).some
1.success[String].leaf.sequenceU map {_.drawTree} assert_=== "1\n".success[String]
</scala>
</div>

<div markdown="1" class="cheatsheet">
### Length[F[_]] 
<scala>
def length[A](fa: F[A]): Int
List(1, 2, 3).length assert_=== 3
</scala>
</div>

<div markdown="1" class="cheatsheet">
### Index[F[_]]
<scala>
def index[A](fa: F[A], i: Int): Option[A]
List(1, 2, 3) index 2 assert_=== 3.some
List(1, 2, 3) index 3 assert_=== none
</scala>
</div>

<div markdown="1" class="cheatsheet">
### ArrId[=>:[_, _]]
<scala>
def id[A]: A =>: A
</scala>
</div>

<div markdown="1" class="cheatsheet">
### Compose[=>:[_, _]]
<scala>
def compose[A, B, C](f: B =>: C, g: A =>: B): (A =>: C)
val f1 = (_:Int) + 1
val f2 = (_:Int) * 100
(f1 >>> f2)(2) assert_=== 300
(f1 <<< f2)(2) assert_=== 201
</scala>
</div>

<div markdown="1" class="cheatsheet">
### Category[=>:[_, _]] extends ArrId[=>:] with Compose[=>:]
<scala>
// no contract function
</scala>
</div>

<div markdown="1" class="cheatsheet">
### Arrow[=>:[_, _]] extends Category[=>:]
<scala>
def arr[A, B](f: A => B): A =>: B
def first[A, B, C](f: (A =>: B)): ((A, C) =>: (B, C))
val f1 = (_:Int) + 1
val f2 = (_:Int) * 100
(f1 *** f2)(1, 2) assert_=== (2, 200)
(f1 &&& f2)(1) assert_=== (2,100)
</scala>
</div>

<div markdown="1" class="cheatsheet">
### Unapply[TC[`_`[`_`]], MA]
<scala>
type M[_]
type A
def TC: TC[M]
def apply(ma: MA): M[A]
implicitly[Unapply[Applicative, Int => Int]].TC.point(0).asInstanceOf[Int => Int](10) assert_=== Applicative[({type l[x]=Function1[Int, x]})#l].point(0)(10)
List(1, 2, 3) traverseU {(x: Int) => {(_:Int) + x}} apply 1 assert_=== List(2, 3, 4) // traverse won't work
</scala>
</div>

</td>

<!-- data types -->
<td width="50%" valign="top">
<div markdown="1" class="cheatsheet">
### Boolean
<scala>
false /\ true assert_=== false // &&
false \/ true assert_=== true // ||
(1 < 10) option 1 assert_=== 1.some
(1 > 10)? 1 | 2 assert_=== 2
(1 > 10)?? {List(1)} assert_=== Nil
</scala>
</div>

<div markdown="1" class="cheatsheet">
### Option
<scala>
1.some assert_=== Some(1)
none[Int] assert_=== (None: Option[Int])
1.some? 'x' | 'y' assert_=== 'x'
1.some | 2 assert_=== 1 // getOrElse
</scala>
</div>

<div markdown="1" class="cheatsheet">
### Id[+A] = A
<scala>
// no contract function
1 + 2 + 3 |> {_ * 6}
1 visit { case x@(2|3) => List(x * 2) }
</scala>
</div>

<div markdown="1" class="cheatsheet">
### Tagged[A]
<scala>
sealed trait KiloGram
def KiloGram[A](a: A): A @@ KiloGram = Tag[A, KiloGram](a)
def f[A](mass: A @@ KiloGram): A @@ KiloGram
</scala>
</div>

<div markdown="1" class="cheatsheet">
### Tree[A]/TreeLoc[A]
<scala>
val tree = 'A'.node('B'.leaf, 'C'.node('D'.leaf), 'E'.leaf)
(tree.loc.getChild(2) >>= {_.getChild(1)} >>= {_.getLabel.some}) assert_=== 'D'.some
(tree.loc.getChild(2) map {_.modifyLabel({_ => 'Z'})}).get.toTree.drawTree assert_=== 'A'.node('B'.leaf, 'Z'.node('D'.leaf), 'E'.leaf).drawTree
</scala>
</div>

<div markdown="1" class="cheatsheet">
### Stream[A]/Zipper[A]
<scala>
(Stream(1, 2, 3, 4).toZipper >>= {_.next} >>= {_.focus.some}) assert_=== 2.some
(Stream(1, 2, 3, 4).zipperEnd >>= {_.previous} >>= {_.focus.some}) assert_=== 3.some
(for { z <- Stream(1, 2, 3, 4).toZipper; n1 <- z.next } yield { n1.modify {_ => 7} }) map { _.toStream.toList } getOrElse Nil assert_=== List(1, 7, 3, 4)
unfold(3) { x => (x =/= 0) option (x, x - 1) }.toList assert_=== List(3, 2, 1)
</scala>
</div>

<div markdown="1" class="cheatsheet">
### DList[A]
<scala>
DList.unfoldr(3, { (x: Int) => (x =/= 0) option (x, x - 1) }).toList assert_=== List(3, 2, 1)
</scala>
</div>

<div markdown="1" class="cheatsheet">
### Lens[A, B] = LensT[Id, A, B]
<scala>
val t0 = Turtle(Point(0.0, 0.0), 0.0)
val t1 = Turtle(Point(1.0, 0.0), 0.0)
val turtlePosition = Lens.lensu[Turtle, Point] (
  (a, value) => a.copy(position = value),
  _.position)
val pointX = Lens.lensu[Point, Double] (
  (a, value) => a.copy(x = value),
  _.x)
val turtleX = turtlePosition >=> pointX
turtleX.get(t0) assert_=== 0.0
turtleX.set(t0, 5.0) assert_=== Turtle(Point(5.0, 0.0), 0.0)
turtleX.mod(_ + 1.0, t0) assert_=== t1
t0 |> (turtleX =>= {_ + 1.0}) assert_=== t1
(for { x <- turtleX %= {_ + 1.0} } yield x) exec t0 assert_=== t1
(for { x <- turtleX := 5.0 } yield x) exec t0 assert_=== Turtle(Point(5.0, 0.0), 0.0)
(for { x <- turtleX += 1.0 } yield x) exec t0 assert_=== t1
</scala>
</div>

<div markdown="1" class="cheatsheet">
### Validation[+E, +A]
<scala>
(1.success[String] |@| "boom".failure[Int] |@| "boom".failure[Int]) {_ |+| _ |+| _} assert_=== "boomboom".failure[Int]
(1.successNel[String] |@| "boom".failureNel[Int] |@| "boom".failureNel[Int]) {_ |+| _ |+| _} assert_=== NonEmptyList("boom", "boom").failure[Int]
"1".parseInt.toOption assert_=== 1.some
</scala>
</div>

<div markdown="1" class="cheatsheet">
### Writer[+W, +A] = WriterT[Id, W, A]
<scala>
(for { x <- 1.set("log1"); _ <- "log2".tell } yield (x)).run assert_=== ("log1log2", 1)
import std.vector._
MonadWriter[Writer, Vector[String]].point(1).run assert_=== (Vector(), 1)
</scala>
</div>

<div markdown="1" class="cheatsheet">
### \/[+A, +B]
<scala>
1.right[String].isRight assert_=== true
1.right[String].isLeft assert_=== false
1.right[String] | 0 assert_=== 1  // getOrElse
("boom".left ||| 2.right) assert_=== 2.right // orElse
("boom".left[Int] >>= { x => (x + 1).right }) assert_=== "boom".left[Int]
(for { e1 <- 1.right; e2 <- "boom".left[Int] } yield (e1 |+| e2)) assert_=== "boom".left[Int]
</scala>
</div>

<div markdown="1" class="cheatsheet">
### Kleisli[M[+_], -A, +B]
<scala>
val k1 = Kleisli { (x: Int) => (x + 1).some }
val k2 = Kleisli { (x: Int) => (x * 100).some }
(4.some >>= k1 compose k2) assert_=== 401.some
(4.some >>= k1 <=< k2) assert_=== 401.some
(4.some >>= k1 andThen k2) assert_=== 500.some
(4.some >>= k1 >=> k2) assert_=== 500.some
</scala>
</div>

<div markdown="1" class="cheatsheet">
### Reader[E, A] = Kleisli[Id, E, A]
<scala>
Reader { (_: Int) + 1 }
</scala>
</div>

<div markdown="1" class="cheatsheet">
### trait Memo[K, V]
<scala>
val memoizedFib: Int => Int = Memo.mutableHashMapMemo {
  case 0 => 0
  case 1 => 1
  case n => memoizedFib(n - 2) + memoizedFib(n - 1)
}
</scala>
</div>

<div markdown="1" class="cheatsheet">
### State[S, +A] = StateT[Id, S, A]
<scala>
State[List[Int], Int] { case x :: xs => (xs, x) }.run(1 :: Nil) assert_=== (Nil, 1)
(for {
  xs <- get[List[Int]]
  _ <- put(xs.tail)
} yield xs.head).run(1 :: Nil) assert_=== (Nil, 1)
</scala>
</div>

<div markdown="1" class="cheatsheet">
### ST[S, A]/STRef[S, A]/STArray[S, A]
<scala>
import scalaz._, Scalaz._, effect._, ST._
type ForallST[A] = Forall[({type l[x] = ST[x, A]})#l]
def e1[S]: ST[S, Int] = for {
  x <- newVar[S](0)
  _ <- x mod {_ + 1}
  r <- x.read
} yield r
runST(new ForallST[Int] { def apply[S] = e1[S] }) assert_=== 1
def e2[S]: ST[S, ImmutableArray[Boolean]] = for {
  arr <- newArr[S, Boolean](3, true)
  x <- arr.read(0)
  _ <- arr.write(0, !x)
  r <- arr.freeze
} yield r
runST(new ForallST[ImmutableArray[Boolean]] { def apply[S] = e2[S] })(0) assert_=== false
</scala>
</div>

<div markdown="1" class="cheatsheet">
### IO[+A]
<scala>
import scalaz._, Scalaz._, effect._, IO._
val action1 = for {
  x <- readLn
  _ <- putStrLn("Hello, " + x + "!")
} yield ()
action1.unsafePerformIO
</scala>
</div>

<div markdown="1" class="cheatsheet">
### IterateeT[E, F[`_`], A]/EnumeratorT[O, I, F[`_`]]
<scala>
import scalaz._, Scalaz._, iteratee._, Iteratee._
(length[Int, Id] &= enumerate(Stream(1, 2, 3))).run assert_=== 3
(length[scalaz.effect.IoExceptionOr[Char], IO] &= enumReader[IO](new BufferedReader(new FileReader("./README.md")))).run.unsafePerformIO
</scala>
</div>

<div markdown="1" class="cheatsheet">
### Imports
<scala>
import scalaz._ // imports type names
import scalaz.Id.Id // imports Id type alias
import scalaz.std.option._ // imports instances, converters, and functions related to `Option`
import scalaz.std.AllInstances._ // imports instances and converters related to standard types
import scalaz.std.AllFunctions._ // imports functions related to standard types
import scalaz.syntax.monad._ // injects operators to Monad
import scalaz.syntax.all._ // injects operators to all typeclasses and Scalaz data types
import scalaz.syntax.std.boolean._ // injects operators to Boolean
import scalaz.syntax.std.all._ // injects operators to all standard types
import scalaz._, Scalaz._ // all the above
</scala>
</div>

<div markdown="1" class="cheatsheet">
### Note
<scala>
type Function1Int[A] = ({type l[x]=Function1[Int, x]})#l[A]
type Function1Int[A] = Function1[Int, A]
</scala>
</div>

</td>
</tr>
</table>
