  [day1]: http://eed3si9n.com/learning-scalaz-day1
  [tt]: http://learnyouahaskell.com/types-and-typeclasses

[Yesterday][day1] we reviewed a few basic typeclasses from Scalaz like `Equal` by using [Learn You a Haskell for Great Good][tt] as the guide. We also created our own `CanTruthy` typeclass.

### Functor

LYAHFGG:

> And now, we're going to take a look at the `Functor` typeclass, which is basically for things that can be mapped over.

Like the book let's look [how it's implemented](https://github.com/scalaz/scalaz/blob/scalaz-seven/core/src/main/scala/scalaz/Functor.scala):

<scala>
trait Functor[F[_]]  { self =>
  /** Lift `f` into `F` and apply to `F[A]`. */
  def map[A, B](fa: F[A])(f: A => B): F[B]

  ...
}
</scala>

Here are the [injected operators](https://github.com/scalaz/scalaz/blob/scalaz-seven/core/src/main/scala/scalaz/syntax/FunctorSyntax.scala) it enables:

<scala>
trait FunctorOps[F[_],A] extends Ops[F[A]] {
  implicit def F: Functor[F]
  ////
  import Leibniz.===

  final def map[B](f: A => B): F[B] = F.map(self)(f)
  
  ...
}
</scala>

So this defines `map` method, which accepts a function `A => B` and returns `F[B]`. We are quite familiar with `map` method for collections:

<scala>
scala> List(1, 2, 3) map {_ + 1}
res15: List[Int] = List(2, 3, 4)
</scala>

Scalaz defines `Functor` instances for `Tuple`s.

<scala>
scala> (1, 2, 3) map {_ + 1}
res28: (Int, Int, Int) = (1,2,4)
</scala>

### Function as Functors

Scala also defines `Functor` instance for `Function1`.

<scala>
scala> ((x: Int) => x + 1) map {_ * 7}
res30: Int => Int = <function1>

scala> res30(3)
res31: Int = 28
</scala>

This is interesting. Basically `map` gives us a way to compose functions, except the order is in reverse from `f compose g`! No wonder Scalaz provides `∘` as an alias of `map`. Another way of looking at `Function1` is that it's an infinite map from the domain to the range. Now let's skip the input and output stuff and go to [Functors, Applicative Functors and Monoids](http://learnyouahaskell.com/functors-applicative-functors-and-monoids).

> How are functions functors?
> ...
>
> What does the type `fmap :: (a -> b) -> (r -> a) -> (r -> b)` for this instance tell us? Well, we see that it takes a function from `a` to `b` and a function from `r` to `a` and returns a function from `r` to `b`. Does this remind you of anything? Yes! Function composition! 

Oh man, LYAHFGG came to the same conclusion as I did about the function composition. But wait..

<haskell>
ghci> fmap (*3) (+100) 1
303
ghci> (*3) . (+100) $ 1  
303 
</haskell>

In Haskell, the `fmap` seems to be working as the same order as `f compose g`. Let's check in Scala using the same numbers:

<scala>
scala> (((_: Int) * 3) map {_ + 100}) (1)
res40: Int = 103
</scala>

Something is not right. Let's compare the declaration of `fmap` and Scalaz's `map` operator:

<haskell>
fmap :: (a -> b) -> f a -> f b

</haskell>

and here's Scalaz:

<scala>
final def map[B](f: A => B): F[B] = F.map(self)(f)

</scala>

So the order is completely different. Since `map` here's an injected method of `F[A]`, the data structure to be mapped over comes first, then the function comes next. Let's see `List`:

<haskell>
ghci> fmap (*3) [1, 2, 3]
[3,6,9]
</haskell>

and

<scala>
scala> List(1, 2, 3) map {3*}
res41: List[Int] = List(3, 6, 9)
</scala>

The order is reversed here too.

> [We can think of `fmap` as] a function that takes a function and returns a new function that's just like the old one, only it takes a functor as a parameter and returns a functor as the result. It takes an `a -> b` function and returns a function `f a -> f b`. This is called *lifting* a function.

<haskell>
ghci> :t fmap (*2)  
fmap (*2) :: (Num a, Functor f) => f a -> f a  
ghci> :t fmap (replicate 3)  
fmap (replicate 3) :: (Functor f) => f a -> f [a]  
</haskell>

Are we going to miss out on this lifting goodness? It's not jumping out to me how to do this, so please let me know if you know.

Functor also enables some operators that overrides the values in the data structure like `>|`, `as`, `fpair`, `strengthL`, `strengthR`, and `void`:

<scala>
scala> List(1, 2, 3) >| "x"
res47: List[String] = List(x, x, x)

scala> List(1, 2, 3) as "x"
res48: List[String] = List(x, x, x)

scala> List(1, 2, 3).fpair
res49: List[(Int, Int)] = List((1,1), (2,2), (3,3))

scala> List(1, 2, 3).strengthL("x")
res50: List[(String, Int)] = List((x,1), (x,2), (x,3))

scala> List(1, 2, 3).strengthR("x")
res51: List[(Int, String)] = List((1,x), (2,x), (3,x))

scala> List(1, 2, 3).void
res52: List[Unit] = List((), (), ())
</scala>

### Applicative

LYAHFGG:

> So far, when we were mapping functions over functors, we usually mapped functions that take only one parameter. But what happens when we map a function like `*`, which takes two parameters, over a functor?

<scala>
scala> List(1, 2, 3, 4) map {(_: Int) * (_:Int)}
<console>:14: error: type mismatch;
 found   : (Int, Int) => Int
 required: Int => ?
              List(1, 2, 3, 4) map {(_: Int) * (_:Int)}
                                             ^
</scala>

Oops. We have to curry this:

<scala>
scala> List(1, 2, 3, 4) map {(_: Int) * (_:Int)}.curried
res11: List[Int => Int] = List(<function1>, <function1>, <function1>, <function1>)

scala> res11 map {_(9)}
res12: List[Int] = List(9, 18, 27, 36)
</scala>

LYAHFGG:

> Meet the `Applicative` typeclass. It lies in the `Control.Applicative` module and it defines two methods, `pure` and `<*>`. 

Let's see the contract for Scalaz's `Applicative`:

<scala>
trait Applicative[F[_]] extends Apply[F] with Pointed[F] { self =>
  ...
}
</scala>

So `Applicative` extends two other typeclasses `Pointed` and `Apply`, but itself does not introduce new contract methods. Let's look at `Pointed` first.

### Pointed

LYAHFGG:

> `pure` should take a value of any type and return an applicative value with that value inside it. ... A better way of thinking about `pure` would be to say that it takes a value and puts it in some sort of default (or pure) context—a minimal context that still yields that value.

<scala>
trait Pointed[F[_]] extends Functor[F] { self =>
  def point[A](a: => A): F[A]

  /** alias for `point` */
  def pure[A](a: => A): F[A] = point(a)
}
</scala>

Scalaz likes the name `point` instead of `pure`, and it seems like it's basically a constructor that takes value `A` and returns `F[A]`. It doesn't introduce an operator, but remember it extends `Functor` so we have `map` etc.

<scala>
scala> Pointed[List].point(1)
res14: List[Int] = List(1)

scala> Pointed[Option].point(1)
res15: Option[Int] = Some(1)

scala> Pointed[Option].point(1) map {_ + 2}
res16: Option[Int] = Some(3)

scala> Pointed[List].point(1) map {_ + 2}
res17: List[Int] = List(3)
</scala>

I can't really express it in words yet, but there's something cool about the fact that constructor is abstracted out.

### Apply

LYAHFGG:

> You can think of `<*>` as a sort of a beefed-up `fmap`. Whereas `fmap` takes a function and a functor and applies the function inside the functor value, `<*>` takes a functor that has a function in it and another functor and extracts that function from the first functor and then maps it over the second one. 

<scala>
trait Apply[F[_]] extends Functor[F] { self =>
  def ap[A,B](fa: => F[A])(f: => F[A => B]): F[B]
}
</scala>

Using `ap`, `Apply` enables `<*>`, `tuple`, `*>`, and `<*` operator.

<scala>
scala> 9.some <*> {(_: Int) + 3}.some
res20: Option[(Int, Int => Int)] = Some((9,<function1>))
</scala>

I was hoping for `Some(12)` here, but apparently Scalaz 7's `<*>` actually is a tuple creator that returns `None` if either side is `Nil`, `None`, or `Left`. `tuple` is just an alias.

<scala>
scala> 1.some <*> 2.some
res31: Option[(Int, Int)] = Some((1,2))

scala> none <*> 2.some
res32: Option[(Nothing, Int)] = None

scala> 1.some <*> none
res33: Option[(Int, Nothing)] = None
</scala>

`*>` and `<*` are variations that returns only the rhs or lhs.

<scala>
scala> 1.some <* 2.some
res35: Option[Int] = Some(1)

scala> none <* 2.some
res36: Option[Nothing] = None

scala> 1.some *> 2.some
res38: Option[Int] = Some(2)

scala> none *> 2.some
res39: Option[Int] = None
</scala>

### Option as Apply

Thanks, but what happened to the `<*>` that can extract functions out of containers, and apply the extracted values to it? Then it occured to me that I can just use `ap` for that:

<scala>
scala> Apply[Option].ap(9.some) {{(_: Int) + 3}.some}
res57: Option[Int] = Some(12)

scala> Apply[Option].ap(9.some, 3.some) {{(_: Int) + (_: Int)}.some}
res58: Option[Int] = Some(12)
</scala>

### Applicative Style

Anothing I found is a new notation that extracts values from containers and apply them to a single function:

<scala>
scala> ^(3.some, 5.some) {_ + _}
res59: Option[Int] = Some(8)

scala> ^(3.some, none: Option[Int]) {_ + _}
res60: Option[Int] = None
</scala>

This is actually useful because for one-function case, we no longer need to put it into the container. I am guessing that this is why Scalaz 7 does not introduce any operator from `Applicative` itself. Whatever the case, it seems like we no longer need `Pointed` or `<$>`.

### Lists as Apply

LYAHFGG:

> Lists (actually the list type constructor, `[]`) are applicative functors. What a surprise!

Let's see if we can use `Apply[List].ap` like `<*>`, and `^` like `<$>`:

<scala>
scala> Apply[List].ap(List(1, 2, 3)) {List((_: Int) * 0, (_: Int) + 100, (x: Int) => x * x)}
res61: List[Int] = List(0, 0, 0, 101, 102, 103, 1, 4, 9)

scala> Apply[List].ap(List(1, 2), List(3, 4)) {List((_: Int) + (_: Int), (_: Int) * (_: Int))}
res62: List[Int] = List(4, 5, 5, 6, 3, 4, 6, 8)

scala> ^(List("ha", "heh", "hmm"), List("?", "!", ".")) {_ + _}
res63: List[String] = List(ha?, ha!, ha., heh?, heh!, heh., hmm?, hmm!, hmm.)
</scala>

### Zip Lists

LYAHFGG:

> However, `[(+3),(*2)] <*> [1,2]` could also work in such a way that the first function in the left list gets applied to the first value in the right one, the second function gets applied to the second value, and so on. That would result in a list with two values, namely `[4,4]`. You could look at it as `[1 + 3, 2 * 2]`.

I did not find `ZipList` equivalent in Scalaz.

### Useful functions for Applicatives

LYAHFGG:

> `Control.Applicative` defines a function that's called `liftA2`, which has a type of

<haskell>
liftA2 :: (Applicative f) => (a -> b -> c) -> f a -> f b -> f c .
</haskell>

There's `Apply[F].lift2`:

<scala>
scala> Apply[Option].lift2((_: Int) :: (_: List[Int]))
res66: (Option[Int], Option[List[Int]]) => Option[List[Int]] = <function2>

scala> res66(3.some, List(4).some)
res67: Option[List[Int]] = Some(List(3, 4))
</scala>

LYAHFGG:

> Let's try implementing a function that takes a list of applicatives and returns an applicative that has a list as its result value. We'll call it `sequenceA`.

<haskell>
sequenceA :: (Applicative f) => [f a] -> f [a]  
sequenceA [] = pure []  
sequenceA (x:xs) = (:) <$> x <*> sequenceA xs  
</haskell>

Let's try implementing this in Scalaz!

<scala>
scala> def sequenceA[F[_]: Applicative, A]: List[F[A]] => F[List[A]] = {
         case Nil     => Pointed[F].point(Nil: List[A])
         case x :: xs => ^(x, sequenceA(xs)) {_ :: _} 
       }
<console>:16: error: type mismatch;
 found   : List[F[A]]
 required: scalaz.Applicative[?]
         case x :: xs => ^(x, sequenceA(xs)) {_ :: _} 
                                        ^

</scala>

This error message does not make sense. I am passing in `List[F[A]]`. Let's try making the implicit parameter more explicit.

<scala>
scala> def sequenceA[F[_], A](implicit ev: Applicative[F]): List[F[A]] => F[List[A]] = {
         case Nil     => Pointed[F].point(Nil: List[A])
         case x :: xs => ^(x, sequenceA(ev)(xs)) {_ :: _} 
       }
sequenceA: [F[_], A](implicit ev: scalaz.Applicative[F])List[F[A]] => F[List[A]]
</scala>

That compiled at least. Let's test it:

<scala>
scala> sequenceA(List(1.some, 2.some))
<console>:15: error: type mismatch;
 found   : List[Option[Int]]
 required: scalaz.Applicative[?]
              sequenceA(List(1.some, 2.some))
</scala>

It seems like we need to pass in the implicits explicitly here.

<scala>
scala> sequenceA(Applicative[Option])(List(1.some, 2.some))
res82: Option[List[Int]] = Some(List(1, 2))

scala> sequenceA(Applicative[Option])(List(3.some, none, 1.some))
res85: Option[List[Int]] = None

scala> sequenceA(Applicative[List])(List(List(1, 2, 3), List(4, 5, 6)))
res86: List[List[Int]] = List(List(1, 4), List(1, 5), List(1, 6), List(2, 4), List(2, 5), List(2, 6), List(3, 4), List(3, 5), List(3, 6))
</scala>

We got the right answers. What's interesting here is that we did end up needing `Pointed` after all, and `sequenceA` is generic in typeclassy way.

For `Function1` with `Int` fixed example, we have to unfortunately invoke a dark magic.

<scala>
scala> type Function1Int[A] = ({type l[A]=Function1[Int, A]})#l[A]
defined type alias Function1Int

scala> sequenceA(Applicative[Function1Int])(List((_: Int) + 3, (_: Int) + 2, (_: Int) + 1))
res1: Int => List[Int] = <function1>

scala> res1(3)
res2: List[Int] = List(6, 5, 4)
</scala>

It took us a while, but I am glad we got this far. We'll pick it up from here later.
