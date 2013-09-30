  [1]: http://www.purl.org/stefan_ram/pub/doc_kay_oop_en
  [2]: http://mumble.net/~jar/articles/oo.html
  [3]: http://staff.um.edu.mt/jskl1/talk.html#Data
  [5]: http://docs.selflanguage.org/4.4/langref.html
  [6]: http://docs.oracle.com/javase/1.5.0/docs/guide/language/autoboxing.html

How do you define oop?

## purely object-oriented programming

Purely object-oriented programming is defined to be:

> programming with objects.

What's an object?

> It is an atom that can hold references to other objects, receive predefined list of messages, and send messages to other objects and itself; and nothing else. A message consists of a name and a list of reference to objects.

This is it. The wording is mine, but the idea is from [Alan Kay][1] (2003), the guy who coined the term object-oriented programming. Anything else is either not directly tied to oop or an implementation detail.

What implications can we derive from the definition?

First is the namespacing. Unlike C's functions, messages (or methods) are namespaced to each objects. This allows programmers to define names without worrying about conflicts.

Second is the finiteness of the messages. Programmers know exactly what kind of messages an object is expected to receive. This allows IDE to aid the programmers by displaying what messages are available.

This could be a cultural thing, an object is designed as a metaphor of real-life entities or concepts.

Finally, the fact that different kinds of object is able to react to the same message in different ways enables polymorphic behavior.

### dynamic dispatch

In TaPL, Pierce describes the message passing as _multiple representations_. As opposed to _abstract data type_, which consists of a single implementation of the behavior, two objects responding to the same set of messages may use different representations. The process of looking up the message name at runtime for the particular object is called _dynamic dispatch_. This is consistent with Kay's claim that oop is about "extreme late-binding of all things." However, multiple representation alone would not cover the closed nature of an object. Dynamic dispatch would include CLOS's multiple dispatch system or Haskell's type class, which are both open.

In Jonathan Rees's list [Sum-of-product-of-function pattern][2] would be similar.

## purity

The purity of a particular programming language or style can be determined by how much it deviates from the above definition: objects and message passing. In other words:

- Everything is an object.
- All you can do is send a message.

### everything is an object

Here's an informal survey of programming languages. (Disclaimer: I'm not a history buff, so I might get some details wrong. It's almost irrelevant who did what first anyways.)

- [Simula 67][3] distinguishes value types (Integer, Short Integer, Real, Long Real, Boolean, Character) and reference types (Object Reference and Text).
- In Smalltalk-80, everything is an object, including numbers and classes. 
- C++ (1979) preserves semantics of value types from C, so `int`s are not objects.
- Eiffel (1986) unifies all types to classes, including INTEGER.
- [Self][5] (1987) is unique because not only everything is an object, it rids of the concept of classes. 
- In both Python (1990) and Ruby (1993) everything is an object.
- Java (1995) treats seven data types (byte, short, int, long, float, double, boolean, char) as primitive data type but supports [boxing][6] since J2SE 5.0 (2004).
- The runtime semantics of the data types in Scala is the same as Java, but it allows user-defined boxing through value class and implicit conversion.

### all you can do is send a message

In terms of message passing, Smalltalk-80 was the pioneer. Also, if the language contained values that are non-objects, it's hard to achieve everything using just message passing.

- Simula 67 exposes fields to outside with protection mechanism.
- Except for a few literals to create objects, syntax for declaring and assigning variables, most of the Smalltalk-80's syntax is expressed as message passing, including `1 + 2`, creating a new object, and control flows like (`x ifTrue: ...`). 
- C++ does the same as Simulta 67. C++ does add operator overloading, which allows user-defined types to define infix operators.
- With Eiffel, Bertrand Meyer formalizes Uniform Access Principle, and thereby merges the boundary between fields and methods.
- Self uses message passing to access slots, which includes methods, so `1 + 2` is message passing. In Self, assignment is done through message passing as well.
- Scala adopts Uniform Access Principle. Scala also allows any method that takes parameters to be written in infix style, so `1 + 2` is message passing.

Then there is a host of languages that implement actor model.

## actor model

If the description of purely object-oriented programming sounds similar to actor model, it's no coincident. One of the languages that influenced Alan Kay's Smalltalk-71 was Planner created by Carl Hewitt (Kay also lists Sketchpad, Simula, Wirth's Euler and LISP). Hewitt apparently didn't like how complex message passing was implemented in Smalltalk-71 or Smalltalk-72. In 1973 he wrote 'A Universal Modular Actor Formalism for Artificial Intelligence' providing mathematical model for concurrent computation, influenced in part by physics, LISP, and Smalltalk.

For our purpose, actor model can be seen as an early branch of pure oop that still preserves the original idea.

## component-based programming

Another concept of programming that is often intermixed with oop is component-based programming (or modular programming). We can define component-based programming to be:

> programming with components.

What's a component?

> A component (or module) is a set of related operations or data that is exposed only through its interfaces.

The focus of component-based programming is on engineering. It's about separating concerns, and aiming higher quality of software by managing complexity. It tries to encapsulate the implementation details such that each component can be used without understanding the details, and can be maintained and substituted without reworking the entire system. The components are often said to be reusable and independent, which translates roughly to being composable.

Modularity is an orthognal concept from programs being procedural, functional, or object-oriented. One can write modular programs with many languages and toolsets in however degree of modularity they support. In order to allow standard libraries to be linked as binary files, many compiled languages like C support separately compiled components. There have been number of standarization of components such as CORBA, COM, and OSGi.

### encapsulation

TaPL associates  _encapsulation_ (hiding internal representation) and _interface subtyping_ (interface contains only names) with oop.

It seems to me that languages like C++ and Java approach oop as an implementation of component-based system at the language level, which explains the emphasis on encapsulation and the presence of various protection mechanism.

### static typing and components

In statically typed languages, having interface subtyping is useful for checking that a particular group of code adheres to a certain spec at compile-time. With C's struct, one could define a type that holds other data:

    struct AddressT {
      string name;
      string street;
      string city;
    };

By including operation/message declarations in the interface, we can expand the scope of the static type from what it has to what it can do.

    trait Queue[A] {
      def enqueue(a: A): Unit
      def dequeue: A
    }

This also means that what we can expect from a variable `x` has improved to capability-based. GoF's 'Design Pattern', saying "Program to an interface, not an implementation", is not talking about oop, it's talking about component-based programming.

If we apply the concept to larger scale, like a library, we get to COM and OSGi where a library is split into two parts: API and implementation. Let's say your library would publish foo-api-1.0.jar and foo-impl-1.0.2.jar. When you release 1.0.3 with bug fixes, it's guaranteed to be binary compatible with 1.0.2.

## mutability

Whether to include mutability as the core attribute of an object is debatable. As oop was originally inspired by physics, it's natural to consider them to be mutable like a molecule or a biological cell. However, one could construct useful system of objects that is completely immutable.

One such example is algebra. For example, `1 * 2` could be rewritten as `1.*(2)`, which sends a message `*(2)` to the object `1`, which then returns a reference to another object `2`. We can define vector algebra `Vector(1, 1) * 2`, where the same message `*(2)` is interpretted in a different way.

## class-based programming

Simula 67 (1967) is a class-based language. Alan Kay extracted message passing style out of Simula, coined the term oop, and created Smalltalk-71 and Smalltalk-72. For performance reasons, Smalltalk-76 adopted inheritance model. Inspired also by Simula, Bjarne Stroustrup implemented C++ in 1979 as an extension to C language with Classes.

When Stroustrup wrote 'The C++ Programming Language', he redefines oop to mean the ability to express the distinction between "the properties of a specific kind of shape" (like a circle) and "the general properties of every shape."

> Languages with constructs that allow this distinction to be expressed and used support object-oriented programming. Other languages don’t.
> The inheritance mechanism (borrowed for C++ from Simula) provides a solution.

This includes the ability to declare methods (virtual functions). Upon close reading, you realize that the text itself does not equate oop with inheritance.

### what TaPL says

TaPL associates _inheritance_ with oop as a means of reusing the implemention of the behaviors among the object that share parts of their interfaces.

Another aspect TaPL lists is _open recursion_ as a feature offered by most class-based programming language. Take Stroustrup's `Shape` and `Circle` as example. Suppose there's a method named `drawAtZero` implemented in `Shape` class as follows:

    def drawAtZero(): Unit = {
      this.moveTo(0.0, 0.0)
      this.draw()
    }

When `this.moveTo(0.0, 0.0)` and `this.draw()` are called, the reference `this` is late-bound. Since dynamic dispatching looks up the implementation of `draw` at the runtime anyway, it doesn't seem significant to me.

## GUI and oop

The rise (and gradual fall) of oop may be coinciding with that of graphical user interface (GUI) systems. The concept of pure oop first materialized in Smalltalk, which is closely tied to graphical Smalltalk environment. One can argue that the hierarchical nature of the GUI libraries and GUI application suited oop. 

A GUI application is concurrent in its nature. The OS is constantly drawing the controls as the user glides the mouse around. When the mouse is clicked, your code is invoked. In the hindsight we know that closures can describe events, but I can see how inheritance could be sold as a mechanism of defining a GUI window by extending `Form` class. By using message passing it can send `setVisible(false)` to buttons, text fields, and other windows.

## fp and oop

### transparency

It's often said that oop is not referentially transparent. That's true for mutable states in general, and especially so with concurrent context like actors. Is that so bad? I don't know. I'm a fan of fp, and I like the idea of building expressions rather than stacking side effects. But I don't think the fundamental concept of message passing is completely at odds with fp. Being able to say `Vector(1, 1) * 2` is oop, and that's transparent.

### human side

To me, what fp brings to the table is the abstraction of the computation. Something like:

    Vector(1, 2, 3) map { _ * 2 }

or

    (1.successNel[String] |@| "boom".failureNel[Int]) {_ |+| _} 

are better way of expressing the logic than the procedural alternative.

On the other hand, what oop brings to the table is a way of mapping the problem domain in a code. It's more about programmer-world interaction, and less about code-computer. At that level, it's mostly about how objects relate to each other.
