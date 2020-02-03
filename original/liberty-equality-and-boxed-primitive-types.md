  [12]: https://scala-lang.org/files/archive/spec/2.13/12-the-scala-standard-library.html
  [pins]: https://www.artima.com/pins1ed/object-equality.html
  [6775]: https://www.scala-lang.org/old/node/6775.html
  [jls15]: https://docs.oracle.com/javase/specs/jls/se11/html/jls-15.html#jls-15.21.1
  [float]: https://en.wikipedia.org/wiki/Single-precision_floating-point_format#IEEE_754_single-precision_binary_floating-point_format:_binary32
  [10773]: https://github.com/scala/bug/issues/10773
  [7405]: https://github.com/scala/scala/pull/7405
  [rethinking]: https://groups.google.com/d/msg/scala-internals/MhIR30mYt-M/MHD0VHhMqoQJ
  [multiversal2016]: https://www.scala-lang.org/blog/2016/05/06/multiversal-equality.html
  [1246]: https://github.com/lampepfl/dotty/pull/1246
  [eql]: https://github.com/lampepfl/dotty/blob/0.21.0-RC1/library/src/scala/Eql.scala
  [dotty-multiversal]: https://dotty.epfl.ch/docs/reference/contextual/multiversal-equality.html
  [ordersky2017]: https://contributors.scala-lang.org/t/can-we-get-rid-of-cooperative-equality/1131
  [1223288074895024128]: https://twitter.com/eed3si9n/status/1223288074895024128
  [hoffmann]: https://twitter.com/jimseven/status/1219264997156704258
  [11551]: https://github.com/scala/bug/issues/11551
  [8117]: https://github.com/scala/scala/pull/8117
  [8120]: https://github.com/scala/scala/pull/8120
  [1135374786593468416]: https://twitter.com/not_xuwei_k/status/1135374786593468416

I want to understand how equality works in Scala. It's a complicated topic that's been going on for ten years.

### Scala Language Specification

The language spec provides some hints, although it does not have the full information. [Chapter 12][12] contains the definition of `Any` as follows:

<scala>
package scala
/** The universal root class */
abstract class Any {

  /** Defined equality; abstract here */
  def equals(that: Any): Boolean

  /** Semantic equality between values */
  final def == (that: Any): Boolean  =
    if (null eq this) null eq that else this equals that

  ....
}
</scala>

First thing to note is that both `equals` and `==` method are provided by `Any`, encompassing both the value types and reference types. This is often called *universal equality*. In Scala 2.x, this allows comparison of two completely unrelated types such as

<scala>
scala> 1 == "1"
         ^
       warning: comparing values of types Int and String using `==` will always yield false
res0: Boolean = false

scala> Option(1) == Option("1")
res1: Boolean = false
</scala>

Given that `==` is final, you might expect that the operator is strictly a symbolic alias of `equals` method. However, later in the [numeric value types] section it says:

> Comparison methods for equals (`==`), not-equals (`!=`), less-than (`<`), greater-than (`>`), less-than-or-equals (`<=`), greater-than-or-equals (`>=`), which each exist in 7 overloaded alternatives. Each alternative takes a parameter of some numeric value type. Its result type is type `Boolean`. The operation is evaluated by converting the receiver and its argument to their operation type and performing the given comparison operation of that type.

<scala>
package scala
abstract sealed class Int extends AnyVal {
  def == (that: Double): Boolean  // double equality
  def == (that: Float): Boolean   // float equality
  def == (that: Long): Boolean    // long equality
  def == (that: Int): Boolean     // int equality
  def == (that: Short): Boolean   // int equality
  def == (that: Byte): Boolean    // int equality
  def == (that: Char): Boolean    // int equality

  ....
}
</scala>

This gives a glimpse at the fact that `==` is not just a symbolic alias of `equals` since Scala can overload the operators.

### 2010 'spec for == and ##'

The best reference of Scala 2.x behavior I found was 'spec for == and ##' draft Paul Phillips sent to Martin Odersky and scala-internals list on April 13, 2010, then reposted to [== and equals][6775] in 2010.

Paul wrote:

> Here is a kind of off the top of my head attempt to spec out equality and hash codes. I don't really speak spec-ese but this is written in the pidgin spec-ese within my grasp. Does this look approximately correct? (Anyone else feel free to chime in on that point.) What if anything would you like me to do with it?
>
> #### Resolution of x == y
>
> - 1) Null values will not cause NPEs.
> - 2) Nothing is `==` to null except null.
> - 3) All objects must be `==` to themselves.
>
> The first three conditions are summarized in this initial expansion of 'x == y', which the compiler may or may not inline. All user-defined equals methods are responsible for preserving invariants 2 and 3.
>
> ```
> if (x eq y) true
> else if (x eq null) false
> else // remainder of algorithm
> ```
>
> - 4) If the static type of the left hand side allows for the possibility that it is a boxed or unboxed primitive numeric type (any of `Byte`, `Short`, `Int`, `Long`, `Float`, `Double`, or `Char`) then: go to step 5.
>
> If the static type definitively excludes those types, then: the result is `x.equals(y)`.
>
> - 5) If the static types of both operands are primitive types, then: the result is that of the primitive comparison, exactly as performed in java.
>
> If the static types are identical final types (for instance, both are `java.lang.Longs`) then the result is `x.equals(y)`.
>
> In all other cases, both operands are boxed if necessary and a method in `BoxesRunTime` is called. (The method will be semantically equivalent to `BoxesRunTime.equals`, but a different method may be chosen to avoid repeating the above tests.)

> #### BoxesRuntime.equals
>
> All of the preceding logic is preserved, and then it proceeds as follows, where 'x' remains the left hand side operand and 'y' the right.
>
> - 1) Runtime instance checks will be done to determine the types of the operands, with the following resolutions. (Resolutions represent the semantics, not necessarily the implementation.)
>   - 1a) If both sides of the comparison are boxed primitives, then they are unboxed and the primitive comparison is performed as in java.
>   - 1b) If 'x' is a class implementing the `scala.math.ScalaNumber` trait, then the result is `x.equals(y)`.
>   - 1c) If 'x' is a boxed primitive and 'y' is a class implementing the `scala.math.ScalaNumber` trait, then the result is `y.equals(x)`.
>   - 1d) Otherwise, the result is `x.equals(y)`.
>
> ....

The rest of the draft includes details about hash codes.

The notable points are:

- Reflexivity is specified.
- Unboxed primitive type equality is delegated to Java's primitive comparison.
- It tries to emulate unboxed primitive comparison even when boxed primitive types are given.

### Java Language Specification

Java Language Specification 15.21.1 defines [Numerical Equality Operators == and !=][jls15]. JLS says that the numeric types are widened to `double` if either lhs or rhs is a `double`, otherwise `float`, `long`, or `int`. Then it says it will follow IEEE 754 standard, including the fact that any comparison to `NaN` returns `false`.

Here's an example of `int` getting converted into `float`:

<java>
jshell> 1 == 1.0F
$1 ==> true
</java>

In Java, numerical equality applies only to the unboxed primitive types.

<java>
jshell> java.lang.Integer.valueOf(1).equals(java.lang.Float.valueOf(1.0f))
$2 ==> false
</java>

### cooperative equality

Scala emulates Java's widening even with boxed primitive types:

<scala>
scala> java.lang.Integer.valueOf(1) == java.lang.Float.valueOf(1.0f)
val res0: Boolean = true
</scala>

I am not sure who coined the term, but this behavior is called *cooperative equality*.

In Java, whenever two values are `equal`, `hashCode` is required to return the same integer. Since we can't change `hashCode` for the boxed primitives `##` method was created. Here's from Paul's draft again:

> The unification of primitives and boxed types in scala necessitates measures to preserve the equality contract: equal objects must have equal hash codes. To accomplish this a new method is introduced on `Any`:

<scala>
  def ##: Int
</scala>

> This method should be called in preference to `hashCode` by all scala software which consumes hashCodes.

Here's a demonstration of `hashCode` vs `##`:

<scala>
scala> 1.hashCode
res1: Int = 1

scala> 1.##
res2: Int = 1

scala> java.lang.Float.valueOf(1.0F).hashCode
res3: Int = 1065353216

scala> java.lang.Float.valueOf(1.0F).##
res4: Int = 1

scala> 1.0F.##
res5: Int = 1
</scala>

The conversion to boxed primitive types happens transparently in Scala when a numeric type is upcasted to `Any`.

<scala>
scala> (1: Any)
res6: Any = 1

scala> (1: Any).getClass
res7: Class[_] = class java.lang.Integer

scala> (1: Any) == (1.0F: Any)
res8: Boolean = true
</scala>

This allows `Int` and `Float` to unify in Scala collections:

<scala>
scala> Set(1, 1.0f, "foo")
val res9: Set[Any] = Set(1, foo)
</scala>

However it won't work for Java collection:

<scala>
scala> import scala.jdk.CollectionConverters._
import scala.jdk.CollectionConverters._

scala> new java.util.HashSet(List(1, 1.0f, "foo").asJava)
res10: java.util.HashSet[Any] = [1.0, 1, foo]
</scala>

### narrowness of Float

The details of `Float` type is described in the Wikipedia entry [IEEE 754 single-precision binary floating-point format: binary32][float]. The 32 bits in `float` breaks down as follows:

- 1 bit for sign
- 8 bits for exponents ranging from -126 to 127 (all zeros and all ones reserved)
- 23 bits represents 24 bits of signicand ranging from 1 to 16777215

The resulting floating-point number is `sign * 2^(exponent) * signicand`.

Note that `int` stores 32 bits of integers (or 31 bit for positives) but the float can express 23 bits accurately. This could lead to a rounding error by 1 for any integer above 0xFFFFFF (16777215).

<java>
jshell> 16777216 == 16777217F
$2 ==> true
</java>

As the `int` becomes larger, you can get more ridiculous results:

<java>
jshell> 2147483584F == 2147483647
$3 ==> true
</java>

This will break the `##` contract for Scala as well.

<scala>
scala> 16777217 == 16777217F
res7: Boolean = true

scala> 16777217.## == 16777217F.##
res8: Boolean = false
</scala>

In my opinion, we should treat Float type as 24 bit integer, and Double as 53 bit integer when it comes to widening. I've reported this as [Weak conformance to Float and Double are incorrect #10773][10773]. There's also an open PR by Guillaume [Deprecate numeric conversions that lose precision #7405][7405].

### NaN

Since this comes up in the discussion of equality, I should note that the comparison with `java.lang.Double.NaN` would always return `false`. An easy way to cause NaN is dividing `0.0` by `0`. The most surprising thing about NaN comparison is that the NaN itself does not `==` NaN:

<scala>
scala> 0.0 / 0
res9: Double = NaN

scala> 1.0 == (0.0 / 0)
res10: Boolean = false

scala> (0.0 / 0) == (0.0 / 0)
res11: Boolean = false
</scala>

In other words, Java or Scala's `==` is not reflexive when NaN is involved.

### Eq typeclass

Around 2010 was also the time when some of the Scala users started to adopt `===` operators introduced by Scalaz library. This bought in the concept of typeclass-based equality used in Haskell.

<scala>
trait Equal[A] { self =>
  def equal(a1: A, a2: A): Boolean
}
</scala>

This was later copied by libraries like ScalaTest and Cats.

<scala>
scala> 1 === 1
res4: Boolean = true
scala> 1 === "foo"
<console>:37: error: type mismatch;
 found   : String("foo")
 required: Int
       1 === "foo"
             ^
</scala>

I personally think this is a significant improvement over the universal equality since it's fairly common to miss the comparison of wrong types during refactoring. But the invariance also creates a fundamental issue with the way Scala 2.x defines data types through subclass inheritance. For example `Some(1)` and `None` would need to be upcasted to `Option[Int]`.

### 2011 'Rethinking equality'

Martin Ordersky was well aware of `===`. In May 2011 he sent a proposal titled ['Rethinking equality'][rethinking]:

> Now that 2.9 is almost out the door, we have the luxury to think of what could come next. One thing I would like to address is equality. The current version did not age well; the longer one looks at it, the uglier it gets. In particular it is a great impediment for DSL design. Witness the recent popularity of `===` as an alternative equality operator. I previously thought we were stuck with Java-like universal equality for backwards compatibility reasons. But there might be a workable way out of that morass. It works in three steps, which would coincide with the next three major revisions of Scala (yes, sometimes progress has to be slow!)

- Step 1: Introduce invariant `areEqual` `@inline def areEqual[T](x: T, y: T)(implicit eq: Equals[T]) = eq.eql(x, y)`. `==` would use `areEqual` if it typechecks, otherwise it falls back to universal equality.
- Step 2: `x == y` uses `areEqual` either lhs `A1` or rhs `A2` has `Equals` instance.
- Step 3: `x == y` becomes equivalent to `areEqual`.

This 2011 proposal went dormant quickly, but it's noteworthy since Martin did eventually change equality for Scala 3.x (Dotty).

### 2016 'Multiversal equality for Scala'

In May of 2016 Martin proposed [Multiversal equality for Scala][multiversal2016] with [dotty#1246][1246].

Here's the definition of [Eql][eql]:

<scala>
/** A marker trait indicating that values of type `L` can be compared to values of type `R`. */
@implicitNotFound("Values of types ${L} and ${R} cannot be compared with == or !=")
sealed trait Eql[-L, -R]

object Eql {
  /** A universal `Eql` instance. */
  object derived extends Eql[Any, Any]

  /** A fall-back instance to compare values of any types.
   *  Even though this method is not declared as given, the compiler will
   *  synthesize implicit arguments as solutions to `Eql[T, U]` queries if
   *  the rules of multiversal equality require it.
   */
  def eqlAny[L, R]: Eql[L, R] = derived

  // Instances of `Eql` for common Java types
  implicit def eqlNumber   : Eql[Number, Number] = derived
  implicit def eqlString   : Eql[String, String] = derived

  // The next three definitions can go into the companion objects of classes
  // Seq, Set, and Proxy. For now they are here in order not to have to touch the
  // source code of these classes
  implicit def eqlSeq[T, U](implicit eq: Eql[T, U]): Eql[GenSeq[T], GenSeq[U]] = derived
  implicit def eqlSet[T, U](implicit eq: Eql[T, U]): Eql[Set[T], Set[U]] = derived

  // true asymmetry, modeling the (somewhat problematic) nature of equals on Proxies
  implicit def eqlProxy    : Eql[Proxy, AnyRef]  = derived
}
</scala>

As noted in the comment as well as the Dotty documentation for [Multiversal Equality][dotty-multiversal]:

> Even though `eqlAny` is not declared a given instance, the compiler will still construct an `eqlAny` instance as answer to an implicit search for the type `Eql[L, R]`, unless `L` or `R` have `Eql` given instances defined on them, or the language feature `strictEquality` is enabled.

<scala>
scala> class Box[A](a: A)
// defined class Box

scala> new Box(1) == new Box("1")
val res1: Boolean = false

scala> {
     |   import scala.language.strictEquality
     |   new Box(1) == new Box("1")
     | }
3 |  new Box(1) == new Box("1")
  |  ^^^^^^^^^^^^^^^^^^^^^^^^^^
  | Values of types Box[Int] and Box[String] cannot be compared with == or !=
</scala>

The documentation for [Multiversal Equality][dotty-multiversal] also shows how `Eql` instances can be derived automatically!

<scala>
scala> class Box[A](a: A) derives Eql
// defined class Box
</scala>

### reevaluation of cooperative equality

In September 2017, about a year after the multiversal equality proposal, Martin posted ['Can we get rid of cooperative equality?'][ordersky2017] on Contributors forum. In there he says that cooperative equality makes the data structure in Scala slower than the equivalent data structures in Java, and that the equality in Scala is complicated. The responses to the thread made by Jason Zaugg, Sébastien Doeraene and other major contributors to Scala makes this a interesting read into understanding the tradeoffs of cooperative equality.

Jason Zaugg wrote:

> My intuition is the ability to use primitives as type arguments sends a signal that `Some[Long](x) == Some[Int](y)` is morally equivalent to `x == y`. In Java, you’d have to explicitly use the box type as the type argument.

Sébastien Doeraene wrote:

> If `1 == 1L` is true, then I strongly believe that `(1: Any) == (1L: Any)`. However, nothing says that `1 == 1L` needs to be true! We can instead make it false, or, even better, a compile error.

I thought Oliver Ruebenacker wrote the best summary:

> Basically, since Java primitives behave differently from Java boxed numbers, we can't have comparisons between different numeric types that satisfy all three of these:
>
> (1) Scala unboxed numbers behave like Java primitives
> (2) Scala boxed numbers behave like Java boxed numbers
> (3) Scala unboxed numbers behave like Scala boxed numbers
>
> It is difficult to have good JVM performance unless Scala numbers behave like Java numbers. Scala boxed and unboxed being different sounds insane.
>
> The only sane and efficient option seems to be, as has been suggested, to deprecate comparisons between different numeric types and instead require conversion to larger types, like `Long` and `Double`. Since these days almost every platform is 64 bit, `Long` and `Double` are natively efficient.

Requiring explicit conversion to `Double` when comparing `Int` and `Double` sounds like a good tradeoff to me too, and it sounds consistent with the direction we are already taking with the multiversal equality.

### warning for 1L equal 1

During 2.13.0 RC3, Kenji Yoshida reported [#11551][11551] showing that `Set` was broken under `++` operation. He also sent a fix [#8117][8117], which was a one liner change from:

<scala>
-        if (originalHash == element0UnimprovedHash && element0.equals(element)) {
+        if (originalHash == element0UnimprovedHash && element0 == element) {
</scala>

On Twitter he also [suggested][1135374786593468416] that we should warn about calling `equals` or `hashCode` on non-AnyRef. I've sent a PR [#8120][8120] so that the following would cause a warning:

<scala>
[info] Running (fork) scala.tools.nsc.MainGenericRunner -usejavacp
Welcome to Scala 2.13.0-pre-db58db9 (OpenJDK 64-Bit Server VM, Java 1.8.0_232).
Type in expressions for evaluation. Or try :help.

scala> def check[A](a1: A, a2: A): Boolean = a1.equals(a2)
                                                      ^
       warning: comparing values of types A and A using `equals` is unsafe due to cooperative equality; use `==` instead
check: [A](a1: A, a2: A)Boolean
</scala>

A few days ago I posted [a poll][1223288074895024128]:

> Using Scala 2.13.1 or Dotty 0.21.0-RC1 what is the result of the following expression?
>
> ((1L == 1) == (1L equals 1)) -> (2147483584F == 2147483647)
>
> - (false, false)
> - (false, true)
> - (true, false)
> - (true, true)

Thanks to all 56 people who participated the poll. The results were

<code>
(false, false)  16.1%
(false, true)   30.4%
(true, false)   35.7%
(true, true)    17.9%
</code>

My intent of the poll was to survey the awareness of cooperative equality among the Twitter users. Before that I want to mention [James Hoffmann's video about high humidity coffee stroage][hoffmann]. To test if high humidity affects the flavor of coffee, he conducts triangle test where samples X, Y, and Y are given blindly, and the first test it trying to pick out X, and then determine which one is better. If I simply posted a poll with true / false, just from the fact alone people would know there's something suspicious. It's not perfect, but I though adding one extra bit would make the poll better.

The first part is about cooperative equality, whereas the second part is about narrowness of 24 bit signicand. By summing the total we can say that 46.5% got the cooperative equality part right, and 48.3% got the Float rounding right. A random chance would get 50% so it's hard to know what percentage of people knows for sure.

### summary

Here is some summary.

- Scala 2.x uses universal equality which allows comparison of `Int` and `String`. Dotty introduces "multiversal" `strictEquality` that works similar to `Eq` typeclass.
- Currently both Scala 2.x and Dotty use Java's `==` to compare unboxed primitive types. This mixes comparison of `Int` with `Float` and `Double` etc.
- `Float` is narrower than `Int`, and `Double` is narrower than `Long`.
- Because Scala transparently boxes `Int` into `java.lang.Integer` as `(1: Any)`, it implements cooperative equality for `==` and `##`, but not for `equals` and `hashCode`, which emulates widening for boxed primitive types. Many people are unaware of this behavior, and this could lead to surprising bugs if people believed that `equals` is same as `==`.
- We might be able to remove cooperative equality if we are willing to make unboxed primitive comparison of different types `1L == 1` an error.
