  [1]: https://issues.scala-lang.org/browse/SI-5354
  [2]: http://www.scala-lang.org/node/212/distributions
  [3]: http://eed3si9n.com/revisiting-implicits-without-import-tax

Scala the language is one of the most elegant, expressive, consistent, and pragmatic languages. From pattern matching to the uniform access principle, it got so many things right. And Scala the ecosystem and Scala the community only makes it better.

In Scala 2.9.1, locally declared implicits are preferred over imported ones. The problem is that the spec does not cover such behavior. My original hypothesis was that either I did not understand the spec correctly, or the spec was wrong. Based on the assumptions, I set out to explore [the implicits resolution precedence last week][3]. Like MythBusters say, the best kind of result is when you get something totally unexpected. It turns out that both of the hypotheses were wrong.

My understanding of the relevant part of the spec was correct, *and* spec was correct as well. According to [SI-5354][1], what's wrong was the compiler implementation:

> The reason why the second example [with locally declared implicits] slipped through is considerably more devious: When checking the `Foo.x` implicit, a CyclicReference error occurs which causes the alternative to be discarded.

In other words, the fact that locally declared implicits were being prioritized was due to a bug. This has been corrected in the master branch and can be tested using a [2.10 nightly][2].

### local declarations vs explicit imports

I'm only going to check one example from the last post:

<scala>
trait CanFoo[A] {
  def foos(x: A): String
}

object Def {
  implicit val importIntFoo = new CanFoo[Int] {
    def foos(x: Int) = "importIntFoo:" + x.toString
  }
}

object Main {
  def test(): String = {
    implicit val localIntFoo = new CanFoo[Int] {
      def foos(x: Int) = "localIntFoo:" + x.toString
    }
    import Def.importIntFoo
    
    foo(1)
  }
  
  def foo[A:CanFoo](x: A): String = implicitly[CanFoo[A]].foos(x)
}

println(Main.test)
</scala>

With 2.9.1,

    $ scala test.scala
    localIntFoo:1

With 2.10 nightly,

    $ scala test.scala
    test.scala:18: error: ambiguous implicit values:
     both value localIntFoo of type Object with this.CanFoo[Int]
     and value importIntFoo in object Def of type => Object with this.CanFoo[Int]
     match expected type this.CanFoo[Int]
        foo(1)
           ^
    one error found

## (correct) implicit parameter precedence

Here's the corrected implicit parameter precedence in "slightly less formalistic" explanation:

- 1) implicits visible to current invocation scope via local declaration, imports, outer scope, inheritance, package object that are accessible without prefix.
- 2) *implicit scope*, which contains all sort of companion objects and package object that bear some relation to the implicit's type which we search for (i.e. package object of the type, companion object of the type itself, of its type constructor if any, of its parameters if any, and also of its supertype and supertraits).

If at either stage we find more than one implicit, static overloading rule is used to resolve it.

## static overloading rules

> The *relative weight* of an alternative *A* over an alternative *B* is a number from 0 to 2, defined as the sum of
> - 1 if *A* is as specific as *B*, 0 otherwise, and
> - 1 if *A* is defined in a class or object which is derived from the class or object defining *B*, 0 otherwise.
>
> A class or object *C* is *derived* from a class or object *D* if one of the following holds:
> - *C* is a subclass of *D*, or
> - *C* is a companion object of a class derived from *D*, or 
> - *D* is a companion object of a class from which *C* is derived.
>
> An alternative *A* is more specific than an alternative *B* if the relative weight of *A* over *B* is greater than the relative weight of *B* over *A*.

For views, if *A* is as specific view as *B*, *A* gets a relative weight of 1 over *B*.

If *A* is defined in a derived class in which *B* is defined, *A* gets another relative weight.

## without the import tax

Now that we have cleared out the precedence, let's review where we can define our implicits to design an API without the import tax.

Category 1 (implicits loaded to current scope) should be avoided if you want to let your user write their code in arbitrary packages and classes and want to avoid `import`.

On the other hand, the entire Category 2 (*implicit scope*) is wide open.

### companion object of type T (or its part)

The first place to consider is the companion object of an associated type (in this case a type constructor):

<scala>
package foopkg

trait CanFoo[A] {
  def foos(x: A): String
}
object CanFoo {
  implicit val companionIntFoo = new CanFoo[Int] {
    def foos(x: Int) = "companionIntFoo:" + x.toString
  }
}  
object `package` {
  def foo[A:CanFoo](x: A): String = implicitly[CanFoo[A]].foos(x)
}
</scala>

Now, this can be invoked as `foopkg.foo(1)` without any import statement.

### package object of type T

Another place to consider is the parent trait of package object for `foopkg`.

<scala>
package foopkg

trait CanFoo[A] {
  def foos(x: A): String
}
trait Implicit {
  implicit lazy val intFoo = new CanFoo[Int] {
    def foos(x: Int) = "intFoo:" + x.toString
  }
}
object `package` extends Implicit {
  def foo[A:CanFoo](x: A): String = implicitly[CanFoo[A]].foos(x)
}
</scala>

Placing implicits into a trait consolidates them into one place, and gives opportunity for the user to reuse them if needed. Mixing it into the package object loads them into the implicit scope.

## static monkey patching

A popular use of implicits is for static monkey patching. For example, we can add `yell` method to `String`, which makes it upper case and appends `"!!"`. The technical term for this is called *view*:

> A *view* from type *S* to type *T* is defined by an implicit value which has function type *S=>T* or *(=>S)=>T* or by a method convertible to a value of that type.

<scala>
package yeller

case class YellerString(s: String) {
  def yell: String = s.toUpperCase + "!!"
}
trait Implicit {
  implicit def stringToYellerString(s: String): YellerString = YellerString(s)
}
object `package` extends Implicit
</scala>

Unfortunately, however, `"foo".yell` won't work outside of `yeller` package because the compiler doesn't know about possible the implicit conversion. One workaround is to break into Category 1 (implicits loaded to current scope) by calling `import yeller._`:

<scala>
object Main extends App {
  import yeller._
  println("banana".yell)
}
</scala>

This is not bad since the import is consolidated into one thing.

### user's package object

Can we get rid of the import statement? Another place in Category 1 is the user's package object, to which they can mixin `Implicit` trait:

<scala>
package userpkg

object `package` extends yeller.Implicit
object Main extends App {
  println("banana".yell)
}
</scala>

This prints out `BANANA!!` successfully without an import.

## summary

Contrary to the conclusion I arrived by observing 2.9.1, there is no such thing as "current scope clause" while resolving multiple implicits. There are only Category 1, Category 2, and static overloading resolution.
