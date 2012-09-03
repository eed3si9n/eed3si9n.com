<table width="100%" class="cheatsheet">
<tr>
<td width="50%" valign="top">
<div markdown="1" class="cheatsheet">
### Equal[A]
<scala>
def equal(a1: A, a2: A): Boolean
(1 === 2) assert_=== false
(2 /== 1) assert_=== true
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
Pointed[List].point(1) assert_=== List(1)
</scala>
</div>

<div markdown="1" class="cheatsheet">
### Apply[F[_]] extends Functor[F]
<scala>
def ap[A,B](fa: => F[A])(f: => F[A => B]): F[B]
1.some <*> 2.some assert_=== Some((1,2))
none <*> 2.some assert_=== None
1.some <* 2.some assert_=== Some(1)
1.some *> 2.some assert_=== Some(2)
Apply[Option].ap(9.some) {{(_: Int) + 3}.some} assert_=== Some(12)
Apply[List].lift2 {(_: Int) * (_: Int)} (List(1, 2), List(3, 4)) assert_=== List(3, 4, 6, 8)
^(3.some, 5.some) {_ + _} assert_=== Some(8)
</scala>
</div>

<div markdown="1" class="cheatsheet">
### Applicative[F[_]] extends Apply[F] with Pointed[F]
<scala>
// no contract function
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
