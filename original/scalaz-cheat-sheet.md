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
### Tagged[A]
<scala>
sealed trait KiloGram
def KiloGram[A](a: A): A @@ KiloGram = Tag[A, KiloGram](a)
def f[A](mass: A @@ KiloGram): A @@ KiloGram
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
Monoid[List[Int]].zero assert_=== Nil
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
</scala>
</div>

</td>
<td width="50%" valign="top">


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
### Validation
<scala>
(1.success[String] |@| "boom".failure[Int] |@| "boom".failure[Int]) {_ |+| _ |+| _} assert_=== "boomboom".failure[Int]
(1.successNel[String] |@| "boom".failureNel[Int] |@| "boom".failureNel[Int]) {_ |+| _ |+| _} assert_=== NonEmptyList("boom", "boom").failure[Int]
</scala>
</div>

<div markdown="1" class="cheatsheet">
### Bind[F[_]] extends Apply[F]
<scala>
def bind[A, B](fa: F[A])(f: A => F[B]): F[B]
3.some flatMap { x => (x + 1).some } assert_=== 4.some
(3.some >>= { x => (x + 1).some }) assert_=== 4.some 
3.some >> 4.some assert_=== 4.some
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
</scala>
</div>

<div markdown="1" class="cheatsheet">
### Writer
<scala>
(for { x <- 1.set("log1"); _ <- "log2".tell } yield (x)).run assert_=== ("log1log2", 1)
import std.vector._
MonadWriter[Writer, Vector[String]].point(1).run assert_=== (Vector(), 1)
</scala>
</div>

<div markdown="1" class="cheatsheet">
### State
<scala>
state[List[Int], Int] { case x :: xs => (xs, x) }.run(1 :: Nil) assert_=== (Nil, 1)
(for { xs <- get[List[Int]]; _ <- put(xs.tail) } yield xs.head).run(1 :: Nil) assert_=== (Nil, 1)
</scala>
</div>

<div markdown="1" class="cheatsheet">
### \/
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
### note
<scala>
type Function1Int[A] = ({type l[A]=Function1[Int, A]})#l[A]
</scala>
</div>

</td>
</tr>
</table>
