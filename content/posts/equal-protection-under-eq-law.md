---
title:       "equal protection under Eq law"
type:        story
date:        2020-02-10
draft:       false
promote:     true
sticky:      false
url:         /equal-protection-under-eq-law
aliases:     [ /node/316 ]
tags:        [ "scala" ]
summary:
  The relationship given to `Int` and `Long` should be exactly the same as the relationship third-party library like Spire can write `UInt` or `Rational` with the first-class numeric types.

  - We should make `1 == 1L` an error under `strictEquality`

  - We should allow custom types to participate in constant expression conversion using `FromDigits`
---

  [1]: http://eed3si9n.com/liberty-equality-and-boxed-primitive-types
  [2]: https://groups.google.com/d/msg/spire-math/ZShEBKuMKT4/CuEA1Sb-nB8J
  [dotty-multiversal]: https://dotty.epfl.ch/docs/reference/contextual/multiversal-equality.html
  [dotty-constant]: https://dotty.epfl.ch/docs/reference/dropped-features/weak-conformance-spec.html
  [dotty-weak]: https://dotty.epfl.ch/docs/reference/dropped-features/weak-conformance.html
  [lubbing]: http://eed3si9n.com/stricter-scala-with-ynolub

Recently I wrote [liberty, equality, and boxed primitive types][1] as a writeup of how equality works in Scala. This is a part 2 of that.

### expression problem

A language designer walks into a bar. The person finds a table where two other language designers are comiserating with each other.

- "Our language does integer additon, and it does integer addition well" first one says.
- He continues "There's a pull request of someone sending in `**` operator. We are concerned that this will destablize the code base."
- The second language designer adds "That's not all. There's another pull request of someone adding `UInt`! How will it support addition with `Int`?"

The bar freezes. The person who joined turns back to the camera and says:

- "Hi, my name is Philip Wadler, and you must implement these features as library, without recompiling existing code, and without using casting. This is the expression problem."

The above is how I visualize the expression problem. Typeclass allows datatypes to acquire capabilities as an add-on, and provides a solution to the expression problem. In Scala 2.x typeclass and generic operators can be expressed as implicits. Scala 3.x splits these concepts as `given` instances and extension methods.

```scala
scala> trait Powerable[A]
         def pow(a: A, b: A): A
      
       given Powerable[Int]
         def pow(a: Int, b: Int): Int =
           var temp = 1
           if b >= 0 then for i <- 1 to b do temp = temp * a
           else sys.error(s"$b must be 0 or greater")
           temp
      
       def [A: Powerable](a: A) ** (b: A): A =
         summon[Powerable[A]].pow(a, b)
      
// defined trait Powerable
// defined object given_Powerable_Int
def **[A](a: A)(b: A)(implicit evidence$1: Powerable[A]): A

scala> 1 ** 0
val res0: Int = 1

scala> 2 ** 2
val res1: Int = 4
```

This ability to extend the language after the fact is one of the fundamental aspects to a modern statically typed language.

### cooperative equality and Spire

As we saw in [the last post][1]:

- Scala overloads unboxed primitive `==` comparisons, and it outsources the implementation to Java, which by Java Language Specification widens comparisons between different unboxed types such as `1L == 1` or `1F == 1`.
- To maintaintain the transparent boxing from unboxed `Int` to boxed `java.lang.Integer`, Scala emulates the widening semantics for `==` operator and `##`, which uses `Int` hashCode for `Float`, `Double` etc.

Both the unboxed and boxed aspects of the cooperative equality makes a closed-word assumption where no one else can implement number types.

Spire runs into this issue. In 2014, Bill Venners [reported][2]:

> I also noticed that `==` is overloaded in some places, leading to apparent inconsistencies, like:

```scala
scala> import spire.math._
import spire.math._

scala> val u = UInt(3)
u: spire.math.UInt = 3

scala> u == 3
res6: Boolean = true

scala> 3 == u
<console>:12: warning: comparing values of types Int and spire.math.UInt using `==' will always yield false
              3 == u
                ^
res7: Boolean = false
```

Erik Osheim's reply says:

> It turns out that value classes in Scala get the worst of both worlds right now. They can't participate in the built-in "universal equality" (since they can only extend universal traits) so they don't have any mechanism for making (`1 == x`) evaluate to true, even if the value class "wraps" the value `1`.

### multiversal equality's limitation

[Multiversal Equality][dotty-multiversal] in Dotty will not resolve this discrimination against custom number types either because unlike a normal typeclass `Eql` has no implementation:

```scala
@implicitNotFound("Values of types ${L} and ${R} cannot be compared with == or !=")
sealed trait Eql[-L, -R]
```

This means that `Int`'s `==` operator will still be used even if we introduce a given instance for `Eql[Int, UInt]`.

### let's remove equality between Int and Long

Starting from Scala 3.x, the user can opt-into `strictEquality` where `Int` will no longer equal with types like `String`, but `Long` and `Int` will be compared because of there's a `Eql[Number, Number]` instance for built-in numbers.

```scala
sbt:dotty-simple> console

scala> import scala.language.strictEquality

scala> 1 == "1"
1 |1 == "1"
  |^^^^^^^^
  |Values of types Int and String cannot be compared with == or !=

scala> val oneI = 1; val oneL = 1L; oneI == oneL
val oneI: Int = 1
val oneL: Long = 1
val res1: Boolean = true
```

For the sake of consistency, we should remove this given instance. Removing the Java-like comparison would also open the door for removing the need for cooperative equality in boxed primitive types in the future. In the non-cooperative world, `UInt` and `Int` could just fail to be compared:

```scala
scala> class UInt(val signed: Int) extends AnyVal
      
       object UInt
         final def apply(n: Int): UInt = new UInt(n)

// defined class UInt
// defined object UInt

scala> UInt(3) == 3
1 |UInt(3) == 3
  |^^^^^^^^^^^^
  |Values of types UInt and Int cannot be compared with == or !=

scala> 3 == UInt(3)
1 |3 == UInt(3)
  |^^^^^^^^^^^^
  |Values of types Int and UInt cannot be compared with == or !=
```

### constant expression

Dotty [dropped weak conformance][dotty-weak] and introduced [constant expression][dotty-constant] feature.

> Dotty drops the general notion of weak conformance, and instead keeps one rule: Int literals are adapted to other numeric types if necessary.

`Int` constant widening or narrowing happens in one of the tree expressions:

> - the elements of a vararg parameter, or
> - the alternatives of an if-then-else or match expression, or
> - the body and catch results of a try expression,

This seems like a somewhat ad-hoc fix for bad cases of [lubbing][lubbing]. For example it won't work once it's nested into Option:

```scala
scala> List(Option(1), Option(1L))
val res2: List[Option[Int | Long]] = List(Some(1), Some(1))
```

Using `FromDigits` we can coerce `Int` literal into `UInt`, but it doesn't seem to participate into the constant expression conversion:

```scala
scala> import scala.util.FromDigits

scala> given FromDigits[UInt]
     |   def fromDigits(digits: String): UInt = UInt(digits.toLong.toInt)
// defined object given_FromDigits_UInt

scala> (3: UInt)
val res3: UInt = 3

scala> List(3, 3: UInt)
val res4: List[AnyVal] = List(3, rs$line$3$UInt@3)

scala> List(3.0, 3)
val res5: List[Double] = List(3.0, 3.0)
```

It seems unfair that `UInt` cannot participate in the vararg conversion.

### FromDigits typeclass for ==?

If constant conversion could be based on the `FromDigits` typeclass, I wonder if this be used for `==` as opposed to the cooperative equality. In other words, an expression like this would be an error:

```scala
scala> val oneI = 1; val oneL = 1L; oneI == oneL
```

but

```scala
scala> 1 == 1L
```

can be converted into

```scala
scala> (1: Long) == 1L
```

This could be a way of retaining `1 == 1L` without creating second-class numeric types. However, this could quickly get out of hand:

```scala
scala> Option(1) == Option(1L)
1 |Option(1) == Option(1L)
  |^^^^^^^^^^^^^^^^^^^^^^^
  |Values of types Option[Int] and Option[Long] cannot be compared with == or !=
```

So extending constant expression conversion to `==` would probably be a bad idea.

### summary

The relationship given to `Int` and `Long` should be exactly the same as the relationship third-party library like Spire can write `UInt` or `Rational` with the first-class numeric types.

- We should make `1 == 1L` an error under `strictEquality`
- We should allow custom types to participate in constant expression conversion using `FromDigits`
