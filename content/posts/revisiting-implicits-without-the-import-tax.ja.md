---
title:       "再考「import 税のかからない implicit」"
type:        story
date:        2012-01-02
promote:     true
sticky:      false
url:         /ja/revisiting-implicits-without-import-tax
aliases:     [ /node/48 ]
---

  [1]: https://docs.google.com/present/view?id=dfqn4jb_106hq4mvbd8
  [2]: http://nescala.org/
  [3]: http://nescala.org/2011/
  [4]: http://vimeo.com/20308847
  [5]: https://twitter.com/#!/coda/status/93003343965851648
  [6]: https://twitter.com/#!/coda/status/93049114106920961
  [7]: http://www.scala-lang.org/docu/files/ScalaReference.pdf
  [8]: http://www.manning.com/suereth/

[Northeast Scala Symposium 2012][2] もあと数ヶ月という所だけど、2011年をまとめるという形で去年のシンポジウムでの発表の一つを再考してみたい。とにかく、nescala は次から次へとクオリティの高い発表があった。[これらの全ては、ここで見ることができる][3]。Daniel の関数型のデータ構造と Janas の Akka がそれぞれ一時間のキーノートがあったこともあり、Scala コミュニティーの中に FP とアクターという二つの潮流が形成されつつあることが印象に残った（Paul がアクターのメッセージの送信には参照透過性が無いと宣言したのもヒントだったかもしれない）。また、一年のその後の予兆とも言えた Mark の sbt 0.9 のプレゼンや Nermin による Scala のパフォーマンスに関する考察もあった。しかし、僕の中で直ちにコードを変更する必要に迫られような直接的なインパクトという意味で抜きん出た発表は Josh の発表だった: Implicits without the import tax: How to make clean APIs with implicits. （import 税のかからない implicit: implict を用いていかにクリーンな API を作るか）

- [ビデオ][4]
- [スライド][1]

## 暗黙のパラメータ解決

Josh の発表の大きな点は、暗黙のパラメータ (implicit parmeter) はいくつものレイヤーを順番に見ていくことで解決され、ワイルドカード `import` は高い優先順位を占めるため、ライブラリがそれを使ってしまうとユーザがそれをオーバーライドできなくなってしまうということだった。

このポストにおいて、implicit の解決優先順位を Scala Language Specification を読んだりコードで試していくことで探検していきたい。せっかちな人のために、最終的に導きだされた優先順位を以下に示した:

- 1) Implicits with type *T* defined in current scope. (relative weight: 3)
- 2) Less specific but compatible view of type *U* defined in current scope. (relative weight: 2)
- 2-b) Implicits with type *T* defined in current class *X*'s parent trait or class *X*<sub>2</sub>. (relative weight: 2)
 - 3-b) Implicits with type *T* defined in *X*<sub>2</sub>'s parent trait or class *X*<sub>3</sub>. (relative weight vs 2-b: 1)
- 2-c) Implicits with type *T* defined in outer scope, explicit imports, wildcard imports, and implicits in package object *Y*. (relative weight: 2)
 - 3-c) Implicits with type *T* defined in the package object's parent trait or class *Y*<sub>2</sub>. (relative weight vs 2-c: 1)
- 3-d) Less specific but compatible view of type *U* defined in parent trait or class *Z*. (relative weight: 1)
 - 4-d) Less specific but compatible view of type *U* defined in *Z*'s parent trait or class *Z*<sub>2</sub>. (relative weight vs 3-d: 0)
- 3-e) Less specific but compatible view of type *U* defined in outer scope, explicit imports, wildcard imports, and implicits in package object *W*. (relative weight: 1)
 - 4-e) Less specific but compatible view of type *U* defined in package object *W*'s parent class *W*<sub>2</sub>. (relative weight vs 3-e: 0)
- 5) Implicits with type *T* defined in the package object of *T*.
 - 6) Implicits with type *T* defined in the parent trait *Q*<sub>2</sub> of package object of *T*.
- 5) Implicits with type *T* defined in the companion object of *T*.
 - 6) Implicits with type *T* defined in companion object of *T*'s parent trait or class *T*<sub>2</sub>.
- 5) Implicits with type *T* defined in the companion object of type constructor *M[_]*.
 - 6) Implicits with type *T* defined in companion object of *M[_]*'s parent trait or class *M*<sub>2</sub>.
- 5) Implicits with type *T* defined in the companion object of type parameter *A*.
 - 6) Implicits with type *T* defined in companion object of *A*'s parent trait or class *A*<sub>2</sub>.
- 5) Implicits with type *T* defined in the companion object of compound parts *R*.
 - 6) Implicits with type *T* defined in companion object of *R*'s parent trait or class *R*<sub>2</sub>.
- 5) Implicits with type *T* defined in the companion object of outer type *p* for singleton types *p*`.type`.
 - 6) Implicits with type *T* defined in companion object of *p*'s parent trait or class *p*<sub>2</sub>.
- 5) Implicits with type *T* defined in the companion object of outer type *S* of type projections *S*`#`*U*.
 - 6) Implicits with type *T* defined in companion object of *S*'s parent trait or class *S*<sub>2</sub>.

### the Scala Language Specification

[the Scala Language Specification (pdf)][7] はこれに関して何を言っているだろうか? p. 106: 

> A method with `implicit` parameters can be applied to arguments just like a normal method. In this case the `implicit` label has no effect. However, if such a method misses arguments for its implicit parameters, such arguments will be automatically provided.

> `implicit` が付きのパラメータを持ったメソッドは通常のメソッドと同様に適用することできる。その場合、`implicit` というラベルは特に効用を持たない。しかし、そのようなメソッドの暗黙のパラメータ (implicit parameter) に引数が渡されない場合は、引数は自動的に提供される。

これは、明示的に渡された引数が最高優先順位であることを記述している

> The actual arguments that are eligible to be passed to an implicit parameter of type *T* fall into two categories.

> 型*T* の暗黙のパラメータに渡すことのできる実引数 (actual argument) は、二つのカテゴリーに分類される。

二つのカテゴリーがある。

> First, eligible are all identifier *x* that can be accessed at the point of the method call without a preﬁx and that denote an implicit definition (§7.1) or an implicit parameter. An eligible identifier may thus be a local name, or a member of an enclosing template, or it may be have been made accessible without a preﬁx through an import clause (§4.7).




Category 1 is implicit parameters and implicit members in the local scope of the call site.

> If there are no eligible identifier under this rule, then, second, eligible are also all implicit members of some object that belongs to the implicit scope of the `implicit` parameter’s type, *T* .

Category 2 is implicit members of the implicit scope of type *T*. What's an implicit scope??

> The *implicit scope* of a type *T* consists of all companion modules (§5.4) of classes that are associated with the implicit parameter’s type. Here, we say a class *C* is *associated* with a type *T* , if it is a base class (§5.1.2) of some part of *T* . The *parts* of a type *T* are:
> 
> - if *T* is a compound type *T<sub>1</sub>* `with` ... `with` *T<sub>n</sub>*, the union of the parts of *T<sub>1</sub>*, ..., *T<sub>n</sub>*, as well as *T* itself,
> - if *T* is a parameterized type *S*`[`*T<sub>1</sub>*, ..., *T<sub>n</sub>*`]`, the union of the parts of *S* and *T<sub>1</sub>*, ..., *T<sub>n</sub>*,
> - if *T* is a singleton type *p*`.type`, the parts of the type of *p*,
> - if *T* is a type projection *S*`#`*U*, the parts of *S* as well as *T* itself,
> - in all other cases, just *T* itself

That's a lot of information, but the important thing is that an implicit scope consists only of companion objects, and that Category 2 is implicit members of those companion objects. Note that both the type constructor's companion object and the type parameters' companion object are included into implicit scope.

So far the spec has listed out details for Category 1 and 2, but not specific enough to derive the precedence.

> If there are several eligible arguments which match the implicit parameter’s type, a most specific one will be chosen using the rules of static overloading resolution (§6.26.3). If the parameter has a default argument and no implicit argument can be found the default argument is used.

We will look at the ordering for the static overloading resolution. But this passage also tells us about the lowest priority, which is the default argument.

## static overloading resolution

The rule is long and winding, so I'll excerpt　the main part:

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

The specific one wins if there are no inheritance; and being enclosed in a subtype wins given if there is no difference in type. Although it is not specified by the spec, there is a tie-breaking precedence order if multiple candidates of the same specificity are found.

If you're familiar with scalac code (I am not), there's Implicits.scala under nsc/typeckecker directory, which defines a method called `inferImplicit`. This calls `bestImplicit`, which says:

```scala
/** The result of the implicit search:
  * First search implicits visible in current context.
```

in the comment. This looks promising. After starting timer, it does:

```scala
var result = searchImplicit(context.implicitss, true)
```

this turns into:

```scala
new ImplicitComputation(implicitInfoss, util.HashSet[Name](128)) findBest()
```

this calls:

```scala
rankImplicits(eligible, Nil)
```

and `rankImplicits` calls itself recursively evaluating one `ImplicitInfo` at a time in `typedImplicit(i, true)`. Eventually `typedImplicit1` is called, but I have no idea how it's able to reject lower priority implicits.

## name binding precedence
According to Josh's talk, there is another precedence in play. The slide lists:

> Implicits defined in current scope (1)
> Explicit imports (2)
> Wildcard imports (3)
> Same scope in other files (4)

This is identical to what Scala Language Specification calls name binding precedence (p. 15):

> Bindings of different kinds have a precedence defined on them:
> 1. Definitions and declarations that are local, inherited, or made available by a package clause in the same compilation unit where the definition occurs have highest precedence.
> 2. Explicit imports have next highest precedence.
> 3. Wildcard imports have next highest precedence.
> 4. Definitions made available by a package clause not in the compilation unit where the definition occurs have lowest precedence.

It's not completely clear if the list is intended as a strict precedence order, but we should verify them.

### static monkey patching

Before all that, I want to bring up an awkward topic that is political correctness of the term "pimp". A discussion took place on twitter in July around Coda's [tweet][5] and its [revised version][6]:

> Refactored: plz don't use the "pimp" metaphor; it has unintended connotations which have offended and alienated potential Scala programmers.

Besides the whole hostile environment, I kind of agree we should replace the term because it's tied to a dated pop culture reference, which doesn't translate. Neither to foreign languages, education, nor to work cultures. As alternatives, I suggested "static monkey patching" and "method injection." So, I'll be using those terms. 

To take an example from Josh's talk, `Scala.Int` like `1` doesn't have `to` method, but Scala lets you write `1 to 2`. The compiler *injects* `to` method by implicitly converting it into an *injection class* `RichInt`.

### local declarations vs outer declarations

To demonstrate the implicit parameter resolution precedence I've come up with an example code:

```scala
trait CanFoo[A] {
  def foos(x: A): String
}

object Main {
  implicit val memberIntFoo = new CanFoo[Int] {
    def foos(x: Int) = "memberIntFoo:" + x.toString
  }
  
  def test(): String = {
    implicit val localIntFoo = new CanFoo[Int] {
      def foos(x: Int) = "localIntFoo:" + x.toString
    }

    foo(1)
  }
  
  def foo[A:CanFoo](x: A): String = implicitly[CanFoo[A]].foos(x)
}

println(Main.test)
```

`CanFoo` is the contract typeclass. Using the convention borrowing from `CanBuildFrom`, I am naming this prefixed with `Can`. Then two typeclass instances `memberIntFoo` and `localIntFoo` are defined, both implementing `foos` method. Using the convetion borrowing from sbinary/sjson, I am naming `foos` postfixed with `s`. This makes the method stand out in the code, since I wouldn't normally name a method with verb + `s`.

Run the test by calling:

    $ scala test.scala
    localIntFoo:1

`localIntFoo` wins. This cannot be explained by static loading resolution alone, because both of the typeclass instances implement typeclass for `Int` and neither of the enclosing object subtypes the other.

If in fact name binding precedence is in effect, that would be weird. The name binding precedence is for resolving a known identifier `x` to a particular variable `pkg.A.B.x` when some other variable `x` is also available in scope. This demonstrates a precedence not mentioned in Scala Language Specification or in Josh's talk:

- Implicits declared in current scope wins over implicits declared in outer scope.

### local declarations vs explicit imports

Now let's look at explicit imports.

```scala
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
```

    $ scala test.scala
    localIntFoo:1

Again, `localIntFoo` wins, but both of them implement typeclass for `Int`, and neither of the enclosing object subtypes the other.

- Implicits in current scope wins over explicitly imported implicits.

### explicit imports vs wildcard imports

Next, let's test the precedence order between the explicit and wildcard imports:

```scala
trait CanFoo[A] {
  def foos(x: A): String
}

object Def {
  val name = "importIntFoo"
  implicit val importIntFoo = new CanFoo[Int] {
    def foos(x: Int) = "importIntFoo:" + x.toString
  }
}

object WildDef {
  val name = "wildcardImportIntFoo"
  implicit val wildcardImportIntFoo = new CanFoo[Int] {
    def foos(x: Int) = "wildcardImportIntFoo:" + x.toString
  }
}

object Main {
  def test(): String = {
    import Def.{importIntFoo, name}
    import WildDef._
    
    println(name)
    foo(1)
  }
  
  def foo[A:CanFoo](x: A): String = implicitly[CanFoo[A]].foos(x)
}

println(Main.test)
```

    $ scala test.scala
    test.scala:28: error: ambiguous implicit values:
     both value importIntFoo in object Def of type => Object with this.CanFoo[Int]
     and value wildcardImportIntFoo in object WildDef of type => Object with this.CanFoo[Int]
     match expected type this.CanFoo[Int]
        foo(1)
           ^
    one error found

There's the discrepancy with the name binding precedence right there. `name` can be resolved correctly to `Def.name` within `test()`, but `importIntFoo` is not favored over `wildcardImportIntFoo`.

### wildcard imports vs package object

What about wildcard import and the package object?
For this we need a few files. First `main.scala`:

```scala
package p

trait CanFoo[A] {
  def foos(x: A): String
}

object Def {
  val name = "importIntFoo"
  implicit val importIntFoo = new CanFoo[Int] {
    def foos(x: Int) = "importIntFoo:" + x.toString
  }
}

object WildDef {
  val name = "wildcardImportIntFoo"
  implicit val wildcardImportIntFoo = new CanFoo[Int] {
    def foos(x: Int) = "wildcardImportIntFoo:" + x.toString
  }
}

object Main extends App {  
  def test(): String = {
    // implicit val localIntFoo = new CanFoo[Int] {
    //   def foos(x: Int) = "localIntFoo:" + x.toString
    // }
    // import Def.{importIntFoo, name}
    import WildDef._
    
    foo(1)
  }
  
  def foo[A:CanFoo](x: A): String = implicitly[CanFoo[A]].foos(x)
  println(test())
}
```

Then, second file `package.scala`:

```scala
package object p { 
  val name = "packageObjectIntFoo"
  implicit val packageObjectIntFoo = new CanFoo[Int] {
    def foos(x: Int) = "packageObjectIntFoo:" + x.toString
  }
}
```

Then compile this as follows:

    $ scalac package.scala main.scala 
    main.scala:29: error: ambiguous implicit values:
     both value packageObjectIntFoo in package p of type => Object with p.CanFoo[Int]
     and value wildcardImportIntFoo in object WildDef of type => Object with p.CanFoo[Int]
     match expected type p.CanFoo[Int]
        foo(1)
           ^
    one error found

Boom. Using package object *alone* does not push the precedence down the wildcard imports.

### explicit imports vs package object

How about explicit imports? Just comment out `import WildDef._`, and uncomment `import Def.{ImportIntFoo, name}`.

```scala
...

object Main extends App {  
  def test(): String = {
    // implicit val localIntFoo = new CanFoo[Int] {
    //   def foos(x: Int) = "localIntFoo:" + x.toString
    // }
    import Def.{importIntFoo, name}
    // import WildDef._
    
    foo(1)
  }
  
  def foo[A:CanFoo](x: A): String = implicitly[CanFoo[A]].foos(x)
  println(test())
}
```

    $ scalac package.scala main.scala 
    main.scala:29: error: ambiguous implicit values:
     both value packageObjectIntFoo in package p of type => Object with p.CanFoo[Int]
     and value importIntFoo in object Def of type => Object with p.CanFoo[Int]
     match expected type p.CanFoo[Int]
        foo(1)
           ^
    one error found

Still does not work.

### local declarations vs package object

Finally, let's test if local declarations can win over the definitions made available by package object. Uncomment `LocalIntFoo` as follows:

```scala
package p

trait CanFoo[A] {
  def foos(x: A): String
}

object Main extends App {  
  def test(): String = {
    implicit val localIntFoo = new CanFoo[Int] {
      def foos(x: Int) = "localIntFoo:" + x.toString
    }
    
    foo(1)
  }
  
  def foo[A:CanFoo](x: A): String = implicitly[CanFoo[A]].foos(x)
  println(test())
}
```

`package.scala` is not changed:

```scala
package object p { 
  val name = "packageObjectIntFoo"
  implicit val packageObjectIntFoo = new CanFoo[Int] {
    def foos(x: Int) = "packageObjectIntFoo:" + x.toString
  }
}
```

    $ scalac package.scala main.scala 
    
This actually compiles, so run it as follows:

    $ scala -cp . p.Main
    localIntFoo:1
    
So if we compare the implicit values of the *same specificity*, then the list looks more like this:

1. Implicits defined in current scope
2. Implicits defined in outer scope, explicit imports, wildcard imports, implicits in package object

## static overloading resolution, again

Remember, this is just a tie breaker, and the Scala Language Specification specifies that the static overloading resolution be used to resolve implicit parameters. We should look into this too.

There are two ways a particular eligible argument A can be *more specific* than an alternative B.
- *A* is "*as specific as*" *B*, but *B* isn't "*as specific as*" *A*. (specificity clause 1)
- If the enclosing class or object of *A* is subtype of *B*'s enclosing class or object. (specificity clause 2)

The formal definition of "*as specific as*" is in the Scala Language Specification. For methods, it means that arguments *p<sub>1</sub>, ... p<sub>n</sub>* for *A* can be applied also to *B*, it's as specific. This could be demonstrated using view bound like this:

```scala
trait Bar {
  def bar: String
}

def bar[A <% Bar](x: A): String = x.bar
```

This gets expanded as

```scala
def bar[A](x: A)(implicit ev: Function1[A, Bar]): String = ev(x).bar
```

so the same implicit parameter resolution needs to happen, except `ev` is a parameterized type.

### Function1[Int, Bar] vs Function1[Any, Bar]

Here we have two views to convert `Any` and `Int` into a `Bar` loaded into the local scope. 

```scala
trait Bar {
  def bar: String
}

object Main {
  def test(): String = {
    implicit def localAnyToBar(x: Any) = new Bar { def bar = "localAnyToBar:" + x.toString }
    implicit def localIntToBar(x: Int) = new Bar { def bar = "localIntToBar:" + x.toString }
      
    bar(1)
  }
  
  def bar[A <% Bar](x: A): String = x.bar
}

println(Main.test)
```

    $ scala test.scala
    localIntToBar:1

As expected, `localIntToBar` wins over `localAnyToBar` because it's the most specific based on specificity clause 1.

### object vs parent object

Next, let's see if the how inheritance hierarchy affects the precedence.

```scala
trait CanFoo[A] {
  def foos(x: A): String
}
object Def {
  implicit val importIntFoo = new CanFoo[Int] {
    def foos(x: Int) = "importIntFoo:" + x.toString
  }
}
object ExtendedDef extends Def {
  implicit val extendedImportIntFoo = new CanFoo[Int] {
    def foos(x: Int) = "extendedImportIntFoo:" + x.toString
  }
}

object Main {
  def test(): String = {
    import Def.importIntFoo
    import ExtendedDef.extendedImportIntFoo
    
    foo(1)
  }
  
  def foo[A:CanFoo](x: A): String = implicitly[CanFoo[A]].foos(x)
}

println(Main.test)
```

    $ scala test.scala
    test.scala:20: error: ambiguous implicit values:
     both value importIntFoo in object Def of type => Object with this.CanFoo[Int]
     and value extendedImportIntFoo in object ExtendedDef of type => Object with this.CanFoo[Int]
     match expected type this.CanFoo[Int]
        foo(1)
           ^
    one error found

It almost seems as if `ExtendedDef` is not recognized as a subtype of `Def`. (I am guessing this is a scala bug)

### object vs parent trait

Let's make that clearer for the compiler by introducing a trait.

```scala
trait CanFoo[A] {
  def foos(x: A): String
}
trait Super {
  implicit lazy val importIntFoo = new CanFoo[Int] {
    def foos(x: Int) = "importIntFoo:" + x.toString
  }
}
object Def extends Super {}
object ExtendedDef extends Super {
  implicit val extendedImportIntFoo = new CanFoo[Int] {
    def foos(x: Int) = "extendedImportIntFoo:" + x.toString
  }
}

object Main {
  def test(): String = {
    import Def.importIntFoo
    import ExtendedDef.extendedImportIntFoo
    
    foo(1)
  }
  
  def foo[A:CanFoo](x: A): String = implicitly[CanFoo[A]].foos(x)
}

println(Main.test)
```

    $ scala test.scala
    extendedImportIntFoo:1

So here, as expected, `extendedImportIntFoo` wins over `importIntFoo` declared in the parent trait based on specificity clause 2.

### outer scope vs parent trait

As a variant, we should verify that the rule applies for members of an object vs members of parent trait.

```scala
trait CanFoo[A] {
  def foos(x: A): String
}
trait Super {
  implicit lazy val superIntFoo = new CanFoo[Int] {
    def foos(x: Int) = "superIntFoo:" + x.toString
  }
}
object Main extends Super {
  implicit val memberIntFoo = new CanFoo[Int] {
    def foos(x: Int) = "memberIntFoo:" + x.toString
  }
  
  def test(): String = {
    foo(1)
  }
  
  def foo[A:CanFoo](x: A): String = implicitly[CanFoo[A]].foos(x)
}

println(Main.test)
```

As expected, `memberIntFoo` wins over `superIntFoo`:

    $ scala test.scala
    memberIntFoo:1

## summary of precedences thus far

To summarize precedence rules in Category 1 that we have seen so far,

- Implicits defined in current scope wins over explicit imports, wildcard imports, and implicits in package object. (current scope clause)
- Implicit view that takes more specific parameter type A wins over another view B. (specificity clause 1)
- Implicit A defined in a subtype wins over an alternative B defined in a parent trait or class. (specificity clause 2)

The natural question is which rule wins, if they are at odds with each other.

### local view vs imported more specific view

This is like setting up a A-or-B dilemma to the compiler to see which rule it picks. We know it likes specific views like `localIntToBar`. We also know it likes local over imported. What if we have less specific local view and a more specific imported view?

```scala
trait Bar {
  def bar: String
}

object Def {
  implicit def importedIntToBar(x: Int) = new Bar { def bar = "importedIntToBar:" + x.toString }
}

object Main {
  def test(): String = {
    import Def.importedIntToBar
    implicit def localAnyToBar(x: Any) = new Bar { def bar = "localAnyToBar:" + x.toString }
    
    bar(1)
  }
  
  def bar[A <% Bar](x: A): String = x.bar
}

println(Main.test)
```

    $ scala test.scala
    test.scala:38: error: ambiguous implicit values:
     both method localAnyToBar of type (x: Any)Object with this.Bar
     and method importedIntToBar in object Def of type (x: Int)Object with this.Bar
     match expected type Int => this.Bar
        bar(1)
           ^
    one error found

The compiler says it can't choose between current scope clause and specificity clause 1!

Current scope clause and specificity clause 2 cannot be put at odds with each other. The fact that one implicit is declared in current scope makes it impossible for it to be the parent trait of an object that encloses another implicit.

### local view vs parent trait

We can still put specificity clause 1 and 2 at odds with each other.

```scala
trait Bar {
  def bar: String
}
trait Super {
  implicit def importIntToBar(x: Int) = new Bar { def bar = "importIntToBar:" + x.toString }
}
object Def extends Super {}
object ExtendedDef extends Super {
  implicit def extendedImportAnyToBar(x: Any) = new Bar { def bar = "extendedImportAnyToBar:" + x.toString }
}

object Main {
  def test(): String = {
    import Def.importIntToBar
    import ExtendedDef.extendedImportAnyToBar
    
    bar(1)
  }
  
  def bar[A <% Bar](x: A): String = x.bar
}

println(Main.test)
```

Again, the compiler cannot choose between those two rules:

    $ scala test.scala
    test.scala:17: error: ambiguous implicit values:
     both method importIntToBar in trait Super of type (x: Int)Object with this.Bar
     and method extendedImportAnyToBar in object ExtendedDef of type (x: Any)Object with this.Bar
     match expected type Int => this.Bar
        bar(1)
           ^
    one error found

This behavior is actually described in the part of Scala Language Specification that I quoted earlier:

> The *relative weight* of an alternative *A* over an alternative *B* is a number from 0 to 2, defined as the sum of...

The above implies that *relative weight* can be 1 vs 1 coming from different clause. What's going on here, I think, is that Josh has discovered the third clause of the specificity rule.

- Implicit view that takes more specific parameter type A wins over another view B. (specificity clause 1)
- Implicit A defined in a subtype wins over an alternative B defined in a parent trait or class. (specificity clause 2)
- Implicits defined in current scope wins over implicits defined in outer scope, explicit imports, wildcard imports, and implicits in package object. (specificity clause 3)

## precedence for Category 1

The following is my attempt to merge the rules into a single list:

- 1) Implicits with type *T* defined in current scope. (relative weight: 3)
- 2) Less specific but compatible view of type *U* defined in current scope. (relative weight: 2)
- 2-b) Implicits with type *T* defined in current class *X*'s parent trait or class *X*<sub>2</sub>. (relative weight: 2)
 - 3-b) Implicits with type *T* defined in *X*<sub>2</sub>'s parent trait or class *X*<sub>3</sub>. (relative weight vs 2-b: 1)
- 2-c) Implicits with type *T* defined in outer scope, explicit imports, wildcard imports, and implicits in package object *Y*. (relative weight: 2)
 - 3-c) Implicits with type *T* defined in the package object's parent trait or class *Y*<sub>2</sub>. (relative weight vs 2-c: 1)
- 3-d) Less specific but compatible view of type *U* defined in parent trait or class *Z*. (relative weight: 1)
 - 4-d) Less specific but compatible view of type *U* defined in *Z*'s parent trait or class *Z*<sub>2</sub>. (relative weight vs 3-d: 0)
- 3-e) Less specific but compatible view of type *U* defined in outer scope, explicit imports, wildcard imports, and implicits in package object *W*. (relative weight: 1)
 - 4-e) Less specific but compatible view of type *U* defined in package object *W*'s parent class *W*<sub>2</sub>. (relative weight vs 3-e: 0)

Note that I was not able to make it into a linear list. Something from higher precedence may not be able to beat some other things categorized in lower precedence because the relative weight may not affect transitively. For example, defining anything in the parent trait drops precedence compared to local or member scope due to specificity clause 2; similarly, defining implicits in the package object drops precedence compared to the local scope; however, implicits defined in the parent trait and parent trait of a package object are in the same precedence because being in the package object (or its parent trait) cancels out the effect of going out to the parent trait of the current object.

## implicit scope

Given that no candidates were found in Category 1, compiler moves on to Category 2, which is called *implicit scope*.

> The *implicit scope* of a type *T* consists of all companion modules (§5.4) of classes that are associated with the implicit parameter’s type. Here, we say a class *C* is *associated* with a type *T* , if it is a base class (§5.1.2) of some part of *T* .

### implicits in current package object vs implicits in T's companion object

We can't use `Int` so I am making `Automobile` class. To demonstrate that the lower precedence of the implicit scope, we should pick something lower from the local scope like an implicit declared in a package object. Here's in `main.scala`:

```scala
package p

trait CanFoo[A] {
  def foos(x: A): String
}

case class Automobile() {}
object Automobile {
  implicit val companionAutomobileFoo = new CanFoo[Automobile] {
    def foos(x: Automobile) = "companionAutomobileFoo:" + x.toString
  }
}

object Main extends App {  
  def test(): String = {    
    foo(Automobile())
  }
  
  def foo[A:CanFoo](x: A): String = implicitly[CanFoo[A]].foos(x)
  println(test())
}
```

And here's `package.scala`:
```scala
package p

object `package` {
  val name = "packageObjectAutomobileFoo"
  implicit val packageObjectAutomobileFoo = new CanFoo[Automobile] {
    def foos(x: Automobile) = "packageObjectAutomobileFoo:" + x.toString
  }
}
```

    $ scalac package.scala main.scala 
    $ scala -cp . p.Main
    packageObjectAutomobileFoo:Automobile()

`packageObjectAutomobileFoo` wins over `companionAutomobileFoo` as expected.

### T's companion object vs companion object of T's parent trait

How about the precedence between the companion objects? We can define `Vehicle` as a parent trait of `Automobile` as follows:

```scala
trait CanFoo[A] {
  def foos(x: A): String
}

trait Vehicle {}
object Vehicle {
  implicit val vehicleAutomobileFoo = new CanFoo[Automobile] {
    def foos(x: Automobile) = "vehicleAutomobileFoo:" + x.toString
  }
}

case class Automobile() extends Vehicle {}
object Automobile {
  implicit val companionAutomobileFoo = new CanFoo[Automobile] {
    def foos(x: Automobile) = "companionAutomobileFoo:" + x.toString
  }
}

object Main {
  def test(): String = {
    foo(Automobile())
  }
  
  def foo[A:CanFoo](x: A): String = implicitly[CanFoo[A]].foos(x)
}

println(Main.test)
```

Although `Automobile` trait and `Vehicle` trait have inheritance relationship, the companion classes do not. However, the rules of static overloading resolution have this covered. Recall:

> A class or object *C* is *derived* from a class or object *D* if one of the following holds:
> - *C* is a subclass of *D*, or
> - *C* is a companion object of a class derived from *D*, or 
> - *D* is a companion object of a class from which *C* is derived.

Thus by power vested by specificity clause 2, `companionAutomobileFoo` rightly wins over `vehicleAutomobileFoo`:

    $ scala test.scala
    companionAutomobileFoo:Automobile()

### T's package object

There's another implicit scope the specification does not mention, which is the package object of type *T*. This is not to be confused with the package object of the current scope (user's scope). Suppose we have `main.scala`:

```scala
object Main extends App {  
  def test(): String = {    
    p.foo(p.Automobile())
  }
  
  println(test())
}
```

And `package.scala`:

```scala
package p

object `package` {
  implicit val packageObjectAutomobileFoo = new CanFoo[Automobile] {
    def foos(x: Automobile) = "packageObjectAutomobileFoo:" + x.toString
  }
  
  def foo[A:CanFoo](x: A): String = implicitly[CanFoo[A]].foos(x)
}

trait CanFoo[A] {
  def foos(x: A): String
}

case class Automobile() {}
object Automobile {
}
```

This compiles and runs as follows:

    $ scalac package.scala main.scala 
    $ scala -cp . Main
    packageObjectAutomobileFoo:Automobile()

Josh was definitely aware of this one since it's mentioned as "Package Object (yours)".

### T's package object vs T's companion object

We can now load in an implicit into *T*'s companion object to find out the precedence between the two.

```scala
package p

object `package` {
  implicit val packageObjectAutomobileFoo = new CanFoo[Automobile] {
    def foos(x: Automobile) = "packageObjectAutomobileFoo:" + x.toString
  }
  
  def foo[A:CanFoo](x: A): String = implicitly[CanFoo[A]].foos(x)
}

trait CanFoo[A] {
  def foos(x: A): String
}

case class Automobile() {}
object Automobile {
  implicit val companionAutomobileFoo = new CanFoo[Automobile] {
    def foos(x: Automobile) = "companionAutomobileFoo:" + x.toString
  }
}
```

    $ scalac package.scala main.scala 
    main.scala:3: error: ambiguous implicit values:
     both value companionAutomobileFoo in object Automobile of type => Object with p.CanFoo[p.Automobile]
     and value packageObjectAutomobileFoo in package p of type => Object with p.CanFoo[p.Automobile]
     match expected type p.CanFoo[p.Automobile]
        p.foo(p.Automobile())
             ^
    one error found

Thus, package object has the same precedence as the companion object of *T*.

### companion objects of T's type constructor vs companion objects of T's type parameter

Notable associated types of type *T* are the companions for its type constructors and type parameters.
For implicit parameters like `CanFoo`, the companion object for `CanFoo` becomes relevant as well as `Automobile` object.
For implicit views, `Function1` object comes into the scope as well as the companion object of `From` and `To` class.

```scala
trait CanFoo[A] {
  def foos(x: A): String
}

object CanFoo {
  implicit val canFooAutomobileFoo = new CanFoo[Automobile] {
    def foos(x: Automobile) = "canFooAutomobileFoo:" + x.toString
  }
}

case class Automobile()
object Automobile {
  implicit val companionAutomobileFoo = new CanFoo[Automobile] {
    def foos(x: Automobile) = "companionAutomobileFoo:" + x.toString
  }
}

object Main {
  def test(): String = {
    foo(Automobile())
  }
  
  def foo[A:CanFoo](x: A): String = implicitly[CanFoo[A]].foos(x)
}

println(Main.test)
```

    $ scala test.scala
    test.scala:30: error: ambiguous implicit values:
     both value companionAutomobileFoo in object Automobile of type => Object with this.CanFoo[this.Automobile]
     and value canFooAutomobileFoo in object CanFoo of type => Object with this.CanFoo[this.Automobile]
     match expected type this.CanFoo[this.Automobile]
        foo(Automobile())
           ^
    one error found

As it turns out, the compiler treats type constructor and type parameter equally.

Here are the other *parts* of types:

> - if *T* is a compound type *T<sub>1</sub>* `with` ... `with` *T<sub>n</sub>*, the union of the parts of *T<sub>1</sub>*, ..., *T<sub>n</sub>*, as well as *T* itself,
> - if *T* is a parameterized type *S*`[`*T<sub>1</sub>*, ..., *T<sub>n</sub>*`]`, the union of the parts of *S* and *T<sub>1</sub>*, ..., *T<sub>n</sub>*,
> - if *T* is a singleton type *p*`.type`, the parts of the type of *p*,
> - if *T* is a type projection *S*`#`*U*, the parts of *S* as well as *T* itself,
> - in all other cases, just *T* itself

## implicit parameter resolution precedence

Since Category 2 will always have lower precedence than Category 1, we can just append it after the list as follows:

- 1) Implicits with type *T* defined in current scope. (relative weight: 3)
- 2) Less specific but compatible view of type *U* defined in current scope. (relative weight: 2)
- 2-b) Implicits with type *T* defined in current class *X*'s parent trait or class *X*<sub>2</sub>. (relative weight: 2)
 - 3-b) Implicits with type *T* defined in *X*<sub>2</sub>'s parent trait or class *X*<sub>3</sub>. (relative weight vs 2-b: 1)
- 2-c) Implicits with type *T* defined in outer scope, explicit imports, wildcard imports, and implicits in package object *Y*. (relative weight: 2)
 - 3-c) Implicits with type *T* defined in the package object's parent trait or class *Y*<sub>2</sub>. (relative weight vs 2-c: 1)
- 3-d) Less specific but compatible view of type *U* defined in parent trait or class *Z*. (relative weight: 1)
 - 4-d) Less specific but compatible view of type *U* defined in *Z*'s parent trait or class *Z*<sub>2</sub>. (relative weight vs 3-d: 0)
- 3-e) Less specific but compatible view of type *U* defined in outer scope, explicit imports, wildcard imports, and implicits in package object *W*. (relative weight: 1)
 - 4-e) Less specific but compatible view of type *U* defined in package object *W*'s parent class *W*<sub>2</sub>. (relative weight vs 3-e: 0)
- 5) Implicits with type *T* defined in the package object of *T*.
 - 6) Implicits with type *T* defined in the parent trait *Q*<sub>2</sub> of package object of *T*.
- 5) Implicits with type *T* defined in the companion object of *T*.
 - 6) Implicits with type *T* defined in companion object of *T*'s parent trait or class *T*<sub>2</sub>.
- 5) Implicits with type *T* defined in the companion object of type constructor *M[_]*.
 - 6) Implicits with type *T* defined in companion object of *M[_]*'s parent trait or class *M*<sub>2</sub>.
- 5) Implicits with type *T* defined in the companion object of type parameter *A*.
 - 6) Implicits with type *T* defined in companion object of *A*'s parent trait or class *A*<sub>2</sub>.
- 5) Implicits with type *T* defined in the companion object of compound parts *R*.
 - 6) Implicits with type *T* defined in companion object of *R*'s parent trait or class *R*<sub>2</sub>.
- 5) Implicits with type *T* defined in the companion object of outer type *p* for singleton types *p*`.type`.
 - 6) Implicits with type *T* defined in companion object of *p*'s parent trait or class *p*<sub>2</sub>.
- 5) Implicits with type *T* defined in the companion object of outer type *S* of type projections *S*`#`*U*.
 - 6) Implicits with type *T* defined in companion object of *S*'s parent trait or class *S*<sub>2</sub>.

This looks somewhat different from Josh's list, but it really doesn't take away the significance of his talk. Until "Implicits without the import tax" no one thought about using the other levels for the libraries! We should all buy him beer and [buy his book][8].

### OO and typeclass pattern

There's an interesting aspect of Scala's typeclass pattern that's often overlooked. That is the OO aspect of it.

So far we have only been looking at the flexibility at point of invocation of the typeclassed function, such as `foo(1)`. The fact that we have callsite binding, and it's not fixed to some global instances is great. But still, the problem with callsite binding, is that it's bound at the callsite. If I may introduce a bad analogy, this is similar to a phone number. You give a group of people a phone for each person, and tell them that if something bad happens, call 911. And depending on the context of the emergency, the local authority responds in a different way. So far so good. The problem happens when people start calling each other, and find out about the emergency indirectly. They are all trained to call 911, which is great, but they no longer have the context, so the local authority end up sending the wrong team.

When would such a situation occur in Scala? Serialization of structured data is one example. Given the following schema

    <xs:complexType name="Address">
      <xs:sequence>
        <xs:element name="name"   type="xs:string"/>
        <xs:element name="street" type="xs:string"/>
        <xs:element name="city"   type="xs:string"/>
      </xs:sequence>
    </xs:complexType>

scalaxb can generate two things. First, a case class:

```scala
case class Address(name: String,
  street: String,
  city: String)
```

Second, a typeclass instance to write the case class out to XML (it does parsing too, but we'll focus on writing):

```scala
package ipo

object `package` extends XMLProtocol { }

trait XMLProtocol extends scalaxb.XMLStandardTypes {
  implicit lazy val IpoAddressFormat: scalaxb.XMLFormat[ipo.Address] = new DefaultIpoAddressFormat {}

  trait DefaultIpoAddressFormat extends scalaxb.ElemNameParser[ipo.Address] {
    val targetNamespace: Option[String] = Some("http://www.example.com/IPO")
    override def typeName: Option[String] = Some("Address")

    def writesChildNodes(__obj: ipo.Address, __scope: scala.xml.NamespaceBinding): Seq[scala.xml.Node] =
      Seq.concat(scalaxb.toXML[String](__obj.name, None, Some("name"), __scope, false),
        scalaxb.toXML[String](__obj.street, None, Some("street"), __scope, false),
        scalaxb.toXML[String](__obj.city, None, Some("city"), __scope, false))
  }
}
```

This typeclass instance can be consumed using `scalaxb.toXML` function as follows:

```scala
scalaxb.toXML[ipo.Address](ipo.Address("name", "street", "city"), None, Some("address"), scope, false)
```

For normal usage, there's no `import` statement involved here. This is because everything is loaded up via the parent trait of the package object of type *T*, one of the lowest precedences.

Also note `scalaxb.toXML` is used within the typeclass instance for `Address`. For a big schema, there could be hundreds if not thousands of those. Now, suppose you want to customize the way `String` is serialized by adding `"foo"` at the end.

Here's the first attempt:

```scala
implicit val stringXMLFormat: XMLFormat[String] = new XMLFormat[String] {
  def writes(obj: String, namespace: Option[String], elementLabel: Option[String],
      scope: scala.xml.NamespaceBinding, typeAttribute: Boolean): scala.xml.NodeSeq =
    Helper.stringToXML(obj + "foo", namespace, elementLabel, scope)
}

scalaxb.toXML[ipo.Address](ipo.Address("name", "street", "city"), None, Some("address"), scope, false)
```

This does not work because at the callsite of `scalaxb.toXML[Address](...)`, only the typeclass instance for `XMLFormat[Address]` is bound. To expand out the implicit statements:

```scala
scalaxb.toXML[ipo.Address](ipo.Address("name", "street", "city"), None, Some("address"), scope, false)(
  ipo.IpoAddressFormat)
```

Internally, `ipo.IpoAddressFormat` is bound to `ipo.__StringXMLFormat`, which it inherits from `scalaxb.XMLStandardTypes`. So the goal is to make `IpoAddressFormat` somehow use our own custom instance of `XMLFormat[String]`. Here's the solution:

```scala
val customProtocol = new ipo.XMLProtocol {
  override lazy val __StringXMLFormat: XMLFormat[String] = new XMLFormat[String] {
    def writes(obj: String, namespace: Option[String], elementLabel: Option[String],
        scope: scala.xml.NamespaceBinding, typeAttribute: Boolean): scala.xml.NodeSeq =
      Helper.stringToXML(obj + "foo", namespace, elementLabel, scope)
  }
}
import customProtocol.IpoAddressFormat

scalaxb.toXML[ipo.Address](ipo.Address("name", "street", "city"), None, Some("address"), scope, false)
```

This will rewire all callsite bound typeclass instances to our `toXML[String](...)` calls. Again, let's see how this is expanded by the compiler:

```scala
scalaxb.toXML[ipo.Address](ipo.Address("name", "street", "city"), None, Some("address"), scope, false)(
  customProtocol.IpoAddressFormat)
```

We've covered that Category 1 wins over anything in Category 2, so `customProtocol.IpoAddressFormat` (explicit import) trumps `ipo.IpoAddressFormat` (the parent trait *Q*<sub>2</sub> of package object of *T*). Internal to `customProtocol.IpoAddressFormat`, its callsite is bound to a lazy implicit value `customProtocol.__StringXMLFormat`. So this means that the signature is known, but the actual value is not initialized yet! This allows `customProtocol` to override the lazy value and late bind the typeclass instance.

Typeclass pattern is useful when you want to extend a type without using class inheritance. But by combining it with OO, we gain typeclass instances that could be late bound outside of the callsite.

### feedback

I don't claim to know this material perfectly. In fact, my motivation to write this up is to get more feedback for the correct knowledge. Please comment!

