Woke up early yesterday, so I started skimming [@xuwei_k](https://twitter.com/xuwei_k)'s `override` blog post. The topic was so intriguing, I got out of the bed and started translating it as the [curious case of putting override modifier when overriding an abstract method in Scala](http://eed3si9n.com/curious-case-of-putting-override-modifier). In there he describes the conundrum of providing the default instances to typeclasses by using Scalaz codebase as an example.

Here's a simplified representation of the problem:

<scala>
trait Functor {
  def map: String
}
trait Traverse extends Functor {
  override def map: String = "meh"
}
sealed trait OneOrFunctor extends Functor {
  override def map: String = "better"
}
sealed trait OneOrTraverse extends OneOrFunctor with Traverse {
}
object OneOr {
  def OneOrFunctor: Functor = new OneOrFunctor {}
  def OneOrTraverse: Traverse = new OneOrTraverse {}
}
</scala>

To test this you can run:

<scala>
scala> OneOr.OneOrTraverse.map
res0: String = meh
</scala>

`OneOr.OneOrTraverse.map` expected to see `"better"`, but `map`'s implementation is masked inadvertently by the default instance provided by `Traverse`.

@xuwei_k asked if there has been prior works on whether to put `override` or not when overriding an abstract method, so let's see if we can find some. Since Scala integrates (or complects) typeclass instances definitions with term space and uses inheritance to specify ordering, what we are dealing with has more to do with modular programming than functional programming. The general topic of mixin order is called *class linearization*. Most of the material discussed in this post is available in Programming in Scala, 2nd ed.

## class linearization lemma

@xuwei_k's `override` conundrum can be restated as a following lemma:

- Given traits `OneOrFunctor` and `Traverse`, can we forbid class linearization such that `Traverse` comes after `OneOrFunctor`?

### abstract override

Scala provides [*stackable* traits][Venners], which are intended to modify the behavior of a class, as opposed to normal traits which act as an interface. To make a trait stackable, you extend from a class or a trait and add `abstract override` modifiers to the methods. The purpose of this modifier is to give access to `super` from the method body, which is normally not accessible since `super` for traits are dynamically bound.

<scala>
scala> :paste
// Entering paste mode (ctrl-D to finish)

abstract class Functor {
  def map: String
}
sealed trait OneOrFunctor extends Functor {
  override def map: String = super.map
}

error: method map in class Functor is accessed from super. It may not be abstract unless it is overridden by a member declared `abstract' and `override'
         override def map: String = super.map
                                          ^
</scala>

Because it needs access to `super`, a stackable trait can only be mixed in *after* a concrete implementation is available. This could be used to constrain the mixin order, or class linearization.

<scala>
scala> :paste
// Entering paste mode (ctrl-D to finish)

trait Functor {
  def map: String
}
trait Traverse extends Functor {
  override def map: String = "meh"
}
sealed trait OneOrFunctor extends Functor {
  abstract override def map: String = "better"
}
sealed trait OneOrTraverse extends OneOrFunctor with Traverse {
}
object OneOr {
  // def OneOrFunctor: Functor = new OneOrFunctor {}
  def OneOrTraverse: Traverse = new OneOrTraverse {}
}

error: overriding method map in trait OneOrFunctor of type => String;
 method map in trait Traverse of type => String needs `abstract override' modifiers
       sealed trait OneOrTraverse extends OneOrFunctor with Traverse {
                    ^
</scala>

Since `OneOrFunctor` is now stackable, it requires the contrete implementation of `map` to exist before it could be mixed in. Correcting the order to `extends Traverse with OneOrFunctor` will compile successfully.

There are several issues with this approach. First, it breaks `OneOr.OneOrFunctor` because there's no concrete `map` coming from `Traverse` for that instance. Second, depending on the existence of `Traverse`'s concrete implementation seems like a bad design.

### abstract class

If controlling `OneOrFunctor` does sort of work, we might also be able to force `Traverse` to come earlier. Figuratively speaking, what we want is some kind of a wall that separetes API classes from implementation classes:

<scala>
sealed trait OneOrTraverse extends Traverse with !WALL! with OneOrFunctor {
}
</scala>

One of the invariance enforced by linearization rules is that the hierachical order of classes must be preserved. This typically forces abtract classes to latter positions in the linearization. For example, we can define both `Functor` and `Traverse` as abtract classes:

<scala>
abstract class Functor {
  def map: String
}
abstract class Traverse extends Functor {
  override def map: String = "meh"
}
sealed trait OneOrFunctor extends Functor {
  override def map: String = "better"
}
sealed trait OneOrTraverse extends OneOrFunctor with Traverse {
}
object OneOr {
  def OneOrFunctor: Functor = new OneOrFunctor {}
  def OneOrTraverse: Traverse = new OneOrTraverse {}
}

error: class Traverse needs to be a trait to be mixed in
       sealed trait OneOrTraverse extends OneOrFunctor with Traverse {
                                                            ^
</scala>

This sort of works. Since `OneOrFunctor` starts the trait mixin phase or the chain, `Traverse` is no longer allowed to join in. However, the downside to this particular implementation is that we are now going to force all Scalaz typeclasses to be in one big tree. That's missing the point of typeclasses/traits. For instance, in reality `Traverse` extends both `Functor` and `Foldable`:

<scala>
abstract class Functor {
  def map: String
}
abstract class Foldable {
  def foldMap: String
}
abstract class Traverse extends Functor with Foldable {
  override def map: String = "meh"
  override def foldMap: String = "meh"
}

error: class Foldable needs to be a trait to be mixed in
       abstract class Traverse extends Functor with Foldable {
                                                    ^
</scala>

### final

@yasushia's comment reminded me about using `final` modifier to preventing `OneOrFunctor`'s `map` from being overridden.

<scala>
trait Functor {
  def map: String
}
trait Traverse extends Functor {
  override def map: String = "meh"
}
sealed trait OneOrFunctor extends Functor {
  final override def map: String = "better"
}
sealed trait OneOrTraverse extends OneOrFunctor with Traverse {
}
object OneOr {
  def OneOrFunctor: Functor = new OneOrFunctor {}
  def OneOrTraverse: Traverse = new OneOrTraverse {}
}

error: overriding method map in trait OneOrFunctor of type => String;
 method map in trait Traverse of type => String cannot override final member
       sealed trait OneOrTraverse extends OneOrFunctor with Traverse {
                    ^
</scala>

Works as expected. This could be used in many cases as a good solution. The downside is that since it's final, the implementation can no longer be overridden.

### patronus type

Another idea I had is to use an abtract type member as a guard in a way similar to phantom type. Because type overriding follows linearization, if we narrow the abtract type, it could act the wall.

<scala>
trait Interface {
  type Guard
}
trait Functor extends Interface {
  def map: String
  override type Guard <: Interface
}
trait Traverse extends Functor {
  override def map: String = "meh"
  override type Guard <: Interface
}
trait Implementation extends Interface {
  override type Guard <: Implementation
}
sealed trait OneOrFunctor extends Functor with Implementation {
  override def map: String = "better"
}
sealed trait OneOrTraverse extends OneOrFunctor with Traverse {
}
object OneOr {
  def OneOrFunctor: Functor = new OneOrFunctor {}
  def OneOrTraverse: Traverse = new OneOrTraverse {}
}

error: overriding type Guard in trait Implementation with bounds <: Implementation;
 type Guard in trait Traverse with bounds <: Interface has incompatible type
       sealed trait OneOrTraverse extends OneOrFunctor with Traverse {
                    ^
</scala>

This is promising. Let's see if putting `Traverse` earlier is going to make it compile.

<scala>
trait Interface {
  type Guard
}
trait Functor extends Interface {
  def map: String
  override type Guard <: Interface
}
trait Traverse extends Functor {
  override def map: String = "meh"
  override type Guard <: Interface
}
trait Implementation extends Interface {
  override type Guard <: Implementation
}
sealed trait OneOrFunctor extends Functor with Implementation {
  override def map: String = "better"
}
sealed trait OneOrTraverse extends Traverse with OneOrFunctor {
}
object OneOr {
  def OneOrFunctor: Functor = new OneOrFunctor {}
  def OneOrTraverse: Traverse = new OneOrTraverse {}
}

// Exiting paste mode, now interpreting.

defined trait Interface
defined trait Functor
defined trait Traverse
defined trait Implementation
defined trait OneOrFunctor
defined trait OneOrTraverse
defined module OneOr

scala> OneOr.OneOrTraverse.map
res0: String = better
</scala>

It says `"better"`, so this is good! It does require all typeclasses to override `type Guard`, but it should be erased away during the runtime. I'm calling this typelevel guardian a *patronus type* if there's no name for it yet.

### references

- M. Odersky and M. Zenger. [Scalable Component Abstractions (pdf)](http://www.scala-lang.org/old/sites/default/files/odersky/ScalableComponent.pdf). In  OOPSLA 2005, 2005.
- J. McBeath. [Scala Class Linearization](http://jim-mcbeath.blogspot.com/2009/08/scala-class-linearization.html). 2009.
- B. Venners. [Scala's Stackable Trait Pattern][Venners]. 2009.
- T. Nurkiewicz. [Scala traits implementation and interoperability. Part II: Traits linearization](http://java.dzone.com/articles/scala-traits-implementation-0). 2013.

[Venners]: http://www.artima.com/scalazine/articles/stackable_trait_pattern.html
