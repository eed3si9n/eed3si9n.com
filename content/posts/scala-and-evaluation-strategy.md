---
title:       "Scala and Evaluation Strategy"
type:        story
date:        2009-10-21
changed:     2010-11-05
draft:       false
promote:     true
sticky:      false
url:         /scala-and-evaluation-strategy
aliases:     [ /node/3 ]
tags:        [ "scala" ]
---

Once you use any technology to a significant extent, you understand its strength and shortcomings. I've probably written tens of thousands of lines of code in Delphi or C++, Java and C# too to some extent. I've depended on those languages, but gripe about them too. The new language obviously has the advantage of just being new. Since I haven't written anything significant in Scala besides Tetris, I haven't hit the shortcomings yet.

<!--more-->

No doubt there are some quirkiness, but everything about Scala makes sense. It sort of reminds me of C++ in the sense that the half of what people consider the language is implemented as library, and the actual language syntax provides extension points so that such libraries can be implemented. So, in C++, third party can create classes that feels and acts like built-in data types by using operator overloading, friend functions, copy constructors, and stream library, etc. It also meant that it has a steep learning curve just to write a class that act in native way. In my case, I've only started to understand the language after taking several lectures at college, reading Deitel and Deitel from cover to cover, reading Effective C++, and reading and writing lots of code.

In contrast to C++, Java took a refreshing approach by taking away all that extensibility stuff, and providing bare bones in exchange of garbage collector, cross-platform virtual machine, and concurrency monitor. Initially Java didn't have generics. Some may not be aware of <code type="java">synchronized</code> keyword, but people usually quickly get Java. The simplicity of Java the language and its familiarity helped spread it from academia to enterprise and mobile phones. Scheme is simple too, in the sense that it has few parts, but it's alien from C++ or any practical usage.

Enough about them. The one of the amazing features of Scala is by-name parameters. Here's from <a href="http://www.scala-lang.org/docu/files/ScalaReference.pdf">the language spec</a>:

> Syntax:
> `ParamType	::= '=>' Type`
>
> The type of a value parameter may be prefixed by =>, e.g. x: => T. The type of such a parameter is then the parameterless method type => T . This indicates that the corresponding argument is not evaluated at the point of function application, but instead is evaluated at each use within the function. That is, the argument is evaluated using call-by-name.
>
> Example4.6.1 The declaration

```scala
def whileLoop (cond: => Boolean) (stat: => Unit): Unit
```

> indicates that both parameters of whileLoop are evaluated using call-by-name.

What does this all mean, and how do you call it?

```scala
var i = 0
whileLoop(i < 10) {
  println(i)
  i += 1
} // whileLoop
```

given sufficient implementation of `whileLoop`, the above code produces the expected output of

```scala
scala> whileLoop(i < 10) {
     |   println(i)
     |   i += 1
     | } // whileLoop
0
1
2
3
4
5
6
7
8
9
```

This is not a normal method invocation you've seen in C++ or Java. This is not even lazy evaluation. In a normal invocation, `i < 10` would evaluate to `true` because 0 < 10 and it'll forever execute the block, even if we accept that the code between curly braces somehow passed itself into `whileLoop`, which is a feature we've seen in language like Ruby, which gets it from Smalltalk. For both parameters of `whileLoop`, a function value is generated and passed into the `whileLoop` method. In other words, `(cond: => Boolean)` is a syntactic sugar that automatically generates `(() => i < 10)` out of `(i < 10)`, which effectively mimics the delay of evaluation until it's applied later.

I was wondering what's the general term for this concept is. According to Wikipedia, the concept of determining when to evaluate an expression is named <a href="http://en.wikipedia.org/wiki/Evaluation_strategy">evaluation strategy</a>, and this one is called <q>call by name</q>:

> In call-by-name evaluation, the arguments to functions are not evaluated at all — rather, function arguments are substituted directly into the function body using capture-avoiding substitution. If the argument is not used in the evaluation of the function, it is never evaluated; if the argument is used several times, it is re-evaluated each time.

Another genius of the Scala is the idea of infix operator notation. It's a notation, not an operator. In a way, there are no operators; they are all methods, and methods that take arguments are all operators too. Well, technically there are still operators because of precedence and associativity issues, but basically anyone can create a method that acts like operators. For example, `1 + 2` is a syntactic sugar for <scala>(1).+(2)</scala>.

All of these extension points allows libraries to implement feature that feels as if it's a native, built-in feature. A prime example is the combinator parser feature, which Scala ships with. According to Programming in Scala, here's the definition of `~` and `|` as a method of class `Parser`:

<scala>
def ~ (q: => Parser[T]) = new Parser[T~U] {
  def apply(in: Input) = p(in) match {
    case Success(x, in1) =>
      q(in1) match {
        case Success(y, in2) => Success(new ~(x, y), in2)
        case failure => failure
      }
    case failure => failure
  }
}

def | (q: => Parser[T]) = new Parser[T] {
  def apply(in: Input) = p(in) match {
    case s1 @ Success(_, _) => s1
    case failure => q(in)
  }
}
</scala>

The details seem complicated, but the point is that the parameters are using by-name parameters because it's preceded by `=>`. Now a parser can be written as follows:

<scala>
def parens = floatingPointNumber | "("~parens~")"
</scala>

This is the Scala magic. By delaying the evaluation till the very end, `parens` allows itself to be self-referential. It's tricky, yet from the user of the combinator parser, it feels natural. This is the way of writing out a grammar in BNF. Using just the cards dealt to everybody else, Scala demonstrates a great example of language extension that feels like it's part of the language. There's of course the pattern matching that's happening here, but by-name parameter essentially enables metaprogramming on Scala, treating Scala code itself as chunks of code, or a sequence of symbols.
