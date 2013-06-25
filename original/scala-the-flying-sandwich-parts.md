JavaScript existed since 1995 long before 'JavaScript: The Good Parts' (2008), jQuery (2006), and V8 (2008) happened. The interesting thing about Douglas Crockford's 'The Good Parts' is that unlike the other additive work, it's a book about subtracting features from the language.

I've been thinking about exploring a subset of Scala in a wonderland setting without the "real world" constraints such as Java familiarity and interoperability. If using Scala as an alternative Java is acceptable, why not try using it as an alternative functional programming language? Another point of this thought experiment is to see some of the duplicate constructs can be reduced. In this article, I'm not interested in finding out the idiomatic way, or calling something good or bad. I'm calling this The Flying Sandwich Parts (TFSP).

## values

> What talk you of the posy or the value?
> — William Shakespeare, _Merchant of Venice_

The Scala Language Specification describes a value as follows:

> A value definition `val x: T = e` defines `x` as a name of the value that results from the evaluation of `e`.

In TFSP, do not omit the type annotation `T` inside the body of traits and classes. Local values within a function can be defined using type inference. This makes sure that the types checked at the function level.

### lazy vals

The order in which the values are defined is critical when using plain vals. Referencing the values prior to initialization will cause `NullPointerException` at the runtime. By annotating the values as `lazy`, initialization can be delayed until the name is first referenced.

<scala>
  implicit val m: MachineModule = new MachineModule {
    val left: State => State   = buildTrans(pm.moveBy((-1, 0)))
    lazy val buildTrans: (Piece => Piece) => State => State = f => s0 => {
      // ....
    }
  }
</scala>

In the above, `buildTrans` is marked as `lazy`, since it's referenced by `left` that is defined earlier.

### pattern definition

When pattern matching appears in the left hand side of a value definition, it deconstructs date types using extractors.

<scala>
val x :: xs = list
</scala>

### avoid vars

In TFSP, the use of variables is discouraged.

## expressions

In Scala, most syntacic constructs return a value, which is nice.

### literals

In Scala, there are literals for integer numbers, floating point numbers, characters, booleans, symbols, and strings.

### no nulls

In TFSP, nulls are not allowed. Use `Option[A]` instead.

### infix operations

In Scala, a method call can be written as an infix operation.

### no postfix

In TFSP, postfix operations are not allowed.

### if expressions

In Scala, `if-else` syntax returns a value. Always provide an `else` clause.

<scala>
scala> val x = 1
x: Int = 1

scala> :paste
// Entering paste mode (ctrl-D to finish)

if (x > 1) x
else 0

res1: Int = 0
</scala>

### for comprehensions

In Scala, `for` can be used as for comprehensions with `yield` and for loops without `yield`. Always provide an `yield`. There's a minor syntactic difference based on parentheses or curly braces. In TFSP, always use curly braces.

<scala>
scala> for {
         x <- 1 to 10
       } yield x + 1
res2: scala.collection.immutable.IndexedSeq[Int] = Vector(2, 3, 4, 5, 6, 7, 8, 9, 10, 11)
</scala>

### prefer `Either[A, B]` over expceptions

TFSP prefers `Either[A, B]` or similar data types that encodes failure over throwing exceptions.

## case class

> Thy case, dear friend, Shall be my precedent
> — William Shakespeare, _The Tempest_

Case classes in Scala is a good way of emulating algebraic data types. Each case class would correspond to a constructor of an ADT, and the ADT itself would be represented by a sealed trait.

<scala>
scala> :paste
// Entering paste mode (ctrl-D to finish)

sealed trait Tree
case class Empty() extends Tree
case class Leaf(x: Int) extends Tree
case class Node(left: Tree, right: Tree) extends Tree

// Exiting paste mode, now interpreting.
</scala>

Under the hood, case classes are classes with automatically implemented `equals`, `toString`, `hashcode`, and `copy`. In addition, their companion objects automatically implement `apply` and `unapply`. 

### pattern matching

We can use pattern matching to decontruct the case classes:

<scala>
scala> val badDepth: Tree => Int = {
         case Leaf(_)    => 1
         case Node(l, r) => 1 + math.max(depth(l), depth(r))
       }
<console>:13: warning: match may not be exhaustive.
It would fail on the following input: Empty()
       val badDepth: Tree => Int = {
                                   ^
badDepth: Tree => Int = <function1>
</scala>

Because the trait is sealed, the compiler can help us in exhastiveness.

<scala>
scala> val depth: Tree => Int = {
         case Empty()    => 0
         case Leaf(_)    => 1
         case Node(l, r) => 1 + math.max(depth(l), depth(r))
       }
depth: Tree => Int = <function1>

scala> depth(Node(Empty(), Leaf(1)))
res5: Int = 2
</scala>

### no methods in case classes

In TFSP, case classes will not have methods. More on this in the next section.

## modular programming

Both modern object-oriented and functional programming are trying to claim the concept of modularity, but neither objects nor functions are intrinsitcally modular. The key aspect of the object is associating verbs together with nouns, and mapping them as metaphors to the human world. The key aspect of the function is mapping values to another, and treating the mapping also as a value.

Modularity is about defining cohesive modules that are loosely-coupled, and it's rooted in more engineering than mathematics. In modular programming, modules communicate via interfaces indirectly. This enables encapsulation of the modules, and ultimately the substitutability of the modules.

### traits

In Scala, defining typeclasses with trait would be the most flexible way of implementing the modules. First, the typeclass contract would be defined with a trait that only declares function signatures.

<scala>
scala> trait TreeModule {
         val depth: Tree => Int
       }
defined trait TreeModule
</scala>

Next, we can define another trait to implement the typeclass as follows:

<scala>
scala> trait TreeInstance {
         val resolveTreeModule: Unit => TreeModule = { case () =>
           implicitly[TreeModule]
         }
         implicit val treeModule: TreeModule = new TreeModule {
           val depth: Tree => Int = {
             case Empty()    => 0
             case Leaf(_)    => 1
             case Node(l, r) => 1 + math.max(depth(l), depth(r))
           }
         }
       }
defined trait TreeInstance
</scala>

### refined types (object literal)

The way the default instance of `TreeModule` was defined is an example of an anonymous type with refinement, or a refined type for short. Since the type doesn't have a name, any fields that are defined in the type should be hidden from the outside except for `depth`.

<scala>
scala> val treeModule2: TreeModule = new TreeModule {
         val depth: Tree => Int = { case _ => 0 }
         val foo = 2
       }
treeModule2: TreeModule = $anon$1@79c4cc17

scala> treeModule2.foo
<console>:11: error: value foo is not a member of TreeModule
              treeModule2.foo
                          ^
</scala>

### prefer imports over implicit scopes

In Scala there are several ways of enabling `TreeModule`. One way is to create an object of `TreeInstance`, and importing all the fields under it to load them into the scope. TFSP prefers explicitly importing the implicit values over implicit scopes. This reduces the need of companion object.

Here's how we can use `TreeModule`:

<scala>
scala> {
         val allInstances = new TreeInstance {}
         import allInstances._
         val m = resolveTreeModule()
         m.depth(Empty())
       }
res1: Int = 0
</scala>

The implementation of the `depth` function is completely substitutable, because the data that deals with it is separated from the module and because `TreeModule` is abstract.

### prefer traits over classes

TFSP prefers traits over classes. Except for working with external libraries, there shouldn't be a need for plain classes.

## functions

> Faith, I must leave thee, love, and shortly too.
> My operant powers their functions leave to do.
> — William Shakespeare, _Hamlet_

Scala has first-class functions, which are functions that can be treated like values. Having first-class functions enables higher-order functions, which is useful. What's interesting is the number of ways you can end up with a function in Scala.

### case functions (partial function literal)

In Scala, a sequence of cases defines an anonymous partial function. I'm going to call this a _case function_ since "pattern matching anonymous function" is too long.

<scala>
scala> type =>?[A, R] = PartialFunction[A, R]
defined type alias $eq$greater$qmark

scala> val f: Tree =>? Int = {
         case Empty() => 0
       }
f: =>?[Tree,Int] = <function1>
</scala>

Since `PartialFunction` extends `Function1`, a case function can appear in any place where a function is expected.

### function literal

In Scala, a function may take multiple parameters, or it could be curried as a function that takes only one parameter and returns another function. In TFSP, curried functions will be the default style unless it makes sense to pass tuples.

<scala>
scala> val add: Int => Int => Int = x => y => x + y
add: Int => (Int => Int) = <function1>
</scala>

This makes partial application the default behavior.

<scala>
scala> val add3 = add(3)
add3: Int => Int = <function1>

scala> add3(1)
res5: Int = 4
</scala>

### no placeholder syntax

In TFSP, the anonymous functions using placeholder syntax such as `(_: Int) + 1`, will not be allowed. As fun as it is, removing it would reduce the numbers of way a function can be created.

### prefer functions over defs

In Scala, def methods can exist side-by-side with the first-class functions. TFSP prefers the first-class functions over defs. This is because functions should be able to fulfil the def method's tasks in many cases. An exception is defining functions with type parameters or implicit parameters.

### no overloading

In TFSP, method overloads are not allowed.

## polymorphism

In Scala, polymorphism can be achieved via both subtyping and typeclasses.

### prefer typeclasses over subtyping

TFSP prefers ad-hoc polymorphism using typeclasses over subtyping. Typeclasses offer greater flexibility since the behavior can be added to existing data types without recompilation.

For example, we can generalize the `TreeModule` as `Depth[A]` that supports both `List[Int]` and `Tree`.

<scala>
trait Depth[A] {
  val depth: A => Int
}
trait DepthInstances {
  def resolveDepth[A: Depth](): Depth[A] = implicitly[Depth[A]]
  implicit val treeDepth: Depth[Tree] = new Depth[Tree] {
    val depth: Tree => Int = {
      case Empty()    => 0
      case Leaf(_)    => 1
      case Node(l, r) => 1 + math.max(depth(l), depth(r))
    }
  }
  implicit val listDepth: Depth[List[Int]] = new Depth[List[Int]] {
    val depth: List[Int] => Int = {
      case xs => xs.size
    }
  }
}
</scala>

### context-bound type parameters

To take advantage of the `Depth` typeclass, define a def method with a context-bound type parameter.

<scala>
scala> {
         val allInstances = new DepthInstances {}
         import allInstances._
         def halfDepth[A: Depth](a: A): Int =
           resolveDepth[A].depth(a) / 2
         halfDepth(List(1, 2, 3, 4))
       }
res2: Int = 2
</scala>

### modular dependencies

I've mentioned that in modular programming, modules must communicate indirectly through interfaces. So far we have only seen one module. How can we desribe a module that depends on another one? Cake pattern is a popular technique of doing this, but we can do something similar using implicit functions.

Suppose we have two modules `MainModule` and `ColorModule`.

<scala>
import swing._
import java.awt.{Color => AWTColor}

trait MainModule {
  val mainFrame: Unit => Frame
}

trait ColorModule {
  val background: AWTColor
}
</scala>

I would like to define a `MainModule` instance that depends on a `ColorModule`.

<scala>
trait MainInstance {
  def resolveMainModule(x: Unit)(implicit cm: ColorModule,
    f: ColorModule => MainModule): MainModule = f(cm)
  implicit val toMainModule: ColorModule => MainModule = cm =>
    new MainModule {
      // use cm to define MainModule
    }
}
</scala>

A `MainModule` can be instantiated normally.

<scala>
scala> {
         val allInstances = new MainInstance with ColorInstance {}
         import allInstances._
         val m = resolveMainModule()
         m.mainFrame()
       }
res1: scala.swing.Frame = ...
</scala>

### avoid variance

In Scala, a type parameter can be annotated as covariant or contravariant to indicate how the type constructor behaves with respect to subtyping. Since TFSP avoids subtyping altogether, variance annotation should also be avoided.

## method injection (enriched class)

In Scala, an existing type may be wrapped implicitly to inject method that did not exist in the original type. If it is desirable to have methods on data types, using method injection allows us to emulate methods without compromising modularity.

The technique of injecting methods using typeclass was inspired by Scalaz 7's implementation.

<scala>
scala> :paste
// Entering paste mode (ctrl-D to finish)

trait DepthOps[A] {
  val self: A
  val m: Depth[A]
  def depth: Int = m.depth(self)
}
trait ToDepthOps {
  implicit def toDepthOps[A: Depth](a: A): DepthOps[A] = new DepthOps[A] {
    val self: A = a
    val m: Depth[A] = implicitly[Depth[A]]
  }
}

// Exiting paste mode, now interpreting.
</scala>

Here's how we can inject `depth` method to all data types that supports `Depth` typeclass.

<scala>
scala> {
         val allInstances = new DepthInstances {}
         import allInstances._
         val ops = new ToDepthOps {}
         import ops._
         List(1, 2, 3, 4).depth
       }
res4: Int = 4
</scala>

## case study: Tetrix

I've been listing the language constructs from Scala, but it's hard to see just how different or useful this subset is without writing some code. Naturally, [Tetrix](https://github.com/eed3si9n/tetrix.tfsp) came to my mind as the test program.

### MainModule

First, `MainModule` was defined to wrap the Swing UI.

<scala>
import swing._

trait MainModule {
  val mainFrame: Unit => Frame
}
</scala>

`MainModule` depends on two other modules called `ColorModule` and `MachineModule`. Here's how the dependencies are set up:

<scala>
trait MainInstance {
  def resolveMainModule(x: Unit)(implicit cm: ColorModule,
    mm: MachineModule,
    f: ColorModule => MachineModule => MainModule): MainModule = f(cm)(mm)
  implicit val toMainModule: ColorModule => MachineModule => MainModule =
    cm => mm => new MainModule {
      // ...
    }
}
</scala>

This is used by application trait that I had to extend from `SimpleSwingApplication`:

<scala>
object Main extends TetrixApp {}
trait TetrixApp extends SimpleSwingApplication {
  val allInstances = new MainInstance with ColorInstance
    with MachineInstance with PieceInstance {}
  import allInstances._
  implicit val machine: MachineModule = MachineModule()
  val main: MainModule = MainModule()
  lazy val top: Frame = main.mainFrame()
}
</scala>

### ColorModule

`ColorModule` determines the color setting used in the application.

<scala>
trait ColorModule {
  val background: AWTColor
  val foreground: AWTColor
}
trait ColorInstance {
  val resolveColorModule: Unit => ColorModule = { case () =>
    implicitly[ColorModule]
  }
  implicit val colorModule: ColorModule = new ColorModule {
    val background = new AWTColor(210, 255, 255) // bluishSilver
    val foreground = new AWTColor(79, 130, 130)  // bluishLigherGray
  }
}
</scala>

This is the module in its entirety. It is a bit of overhead to express just two fields, but the point is to demonstrate that these settings can be configured to something else after the fact.

![before](/images/scala-tfsp1.png)

For example, we can define a new instance of `ColorModule` by extending the default instance:

<scala>
trait CustomColorInstance extends ColorInstance {
  implicit val customColorModule: ColorModule = new ColorModule {
    val background = new AWTColor(255, 255, 255) // white
    val foreground = new AWTColor(0, 0, 0)  // black
  } 
}
</scala>

This can be loaded into the implicit search space as follows:

<scala>
trait TetrixApp extends SimpleSwingApplication {
  val allInstances = new MainInstance with ColorInstance
    with MachineInstance with PieceInstance
    with CustomColorInstance {}
  import allInstances._
  implicit val machine: MachineModule = resolveMachineModule()
  val main: MainModule = resolveMainModule()
  lazy val top: Frame = main.mainFrame()
}
</scala>

![after](/images/scala-tfsp2.png)

Now the blocks are rendered in another color configuration. This alternative setup can be defined in another jar without recompiling the first jar. 

### MachineModule

`MachineModule` represents the state machine of the game. First, I defined a case classes as follows:

<scala>
import scala.collection.concurrent.TrieMap

// this is mutable
case class Machine(stateMap: TrieMap[Unit, State])

case class State(current: Piece, gridSize: (Int, Int),
  blocks: Seq[Block])

case class Block(pos: (Int, Int))
</scala>

`Machine` keeps current `State` in a concurrent `Map`. Currently `MachineModule` defines the following functions:

<scala>
trait MachineModule {
  val init: Unit => Machine
  val state: Machine => State
  val transition: Machine => (State => State) => Machine
  val left: State => State
  val right: State => State
  val rotate: State => State
}
trait MachineInstance {
  def resolveMachineModule(x: Unit)(implicit pm: PieceModule,
    f: PieceModule => MachineModule): MachineModule = f(pm)
  implicit val toMachineModule: PieceModule => MachineModule = pm =>
    new MachineModule {
      // ...
    }
}
</scala>

This module depends on another module called `PieceModule`, so module instance is defined as the implicit function `toMachineModule`. Since implicit parameters are resolved at the call-site, `PieceModule` can be substituted to an alternative instance at the top-level application.

The state machine is implemented as follows:

<scala>
    val state: Machine => State = { case m =>
      m.stateMap(())
    }
    val transition: Machine => (State => State) => Machine = m => f => {
      val s0 = state(m)
      val s1 = f(s0)
      m.stateMap replace((), s0, s1)
      m
    }
</scala>

As you can see, all functions are implemented as curried function values. Here is an example that takes advantage of the currying.

<scala>
    val left: State => State   = buildTrans(pm.moveBy((-1, 0)))
    val right: State => State  = buildTrans(pm.moveBy((1, 0)))
    val rotate: State => State = buildTrans(pm.rotateBy(-Math.PI / 2.0))
    lazy val buildTrans: (Piece => Piece) => State => State = f => s0 => {
      val p0 = s0.current
      val p = f(p0)
      val u = unload(p0)(s0)
      load(p)(u) getOrElse s0
    }
</scala>

`buildTrans` is a function that takes `Piece` transformation function, and the initial `State` and returns another `State`. By applying only the first parameter, it can be also seen as a function that returns `State => State` function. 

### PieceModule

`PieceModule` describes the movements of the pieces. For example, `moveBy` used in `left` and `right` is implemented as follows:

<scala>
    val moveBy: Tuple2[Int, Int] => Piece => Piece = {
      case (deltaX, deltaY) => p0 =>
        val (x0, y0) = p0.pos
        p0.copy(pos = (x0 + deltaX, y0 + deltaY))
    }
</scala>

### observations

Actually writing code using TFSP, even for a toy project, gave me a better understanding of the subset. The implementation of the modular dependency, for instance, went through several iterations of try-and-error to be able to substitute arbitrary modules correctly.

Overall, I am pleasantly surprised that this subset seems usable thus far. I did not complete Tetrix, but since I got to the point where I could move the block around with collision detection, I figure it's just matter of spending more time.

Except for a few `def apply`s, all functions were defined using `val`. This did not cause troubles for the most part. The only thing I had to watch out for was the initialization order, which I wouldn't need to worry if I were using `def` methods. The initialization issue can go away if we always used `lazy val`s.

Some of the functions that return a mutable object was implemented as `Unit => X`, like `val init: Unit => Machine`. This results in `init` and `init()` having different semantics, which is not common in idiomatic Scala.

Giving up placeholder sytanx for anonymous functions resulted in parameter named having throw-away names. This is a tradeoff for reducing the syntactic constructs for functions.

The differentiating aspect of TFSP is the modularity. Without relying on heavy subtyping, TFSP can define modules that are loosely coupled. It's also interesting that TFSP achieves encapsulation without marking any functions `private`. Other dependency injection solutions like Cake pattern and SubCut probably could achieve these things too.

## summary

Since Scala allows wide spectrum of style, it's useful to ponder your own subset to see where you fit in. One use of the subset is to write majority of the code in it, and treat the rest of Scala as FFI to talk to other libraries and Java.

Here's the summary of TFSP:

- separate data into case classes
- define behaviors as typeclasses using traits
- use imports to load implicits
- define functions using case functions and curried function values

The first two points can be found in some of the functional- or modular- oriented code bases. TFSP just applies them strictly to everything possible.

The last two points would be considered diversion from normal Scala. But, in a way it's the parts that feels awkward if one reviewed the language with fresh eyes. For example, it's a bit odd to have two notions of functions: first-class functions that can appear anywhere, and methods that has implicit passing of `this`. If possible, it's natural to unify them towards `val`. The implicit scope via companion object is another oddity that's great if you understand it, but the idea of tying things together based on names feels a bit like magic.

We will be landing shortly to Newark Liberty International Airport. The weather forecast is sunny, at 72°F or 22°C. Please make sure your seat backs and tray tables are in their idiomatic positions. On behalf of the crew, I’d like to thank you for joining us on the flying sandwich.
