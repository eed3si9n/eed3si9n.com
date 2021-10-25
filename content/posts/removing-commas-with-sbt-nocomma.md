---
title:       "removing commas with sbt-nocomma"
type:        story
date:        2018-02-03
changed:     2018-09-29
draft:       false
promote:     true
sticky:      false
url:         /removing-commas-with-sbt-nocomma
aliases:     [ /node/252 ]
tags:        [ "scala" ]
---

  [1]: https://gitter.im/scala/slip?at=57abcaf6d7087a017faa822a
  [@Ichoran]: https://github.com/Ichoran
  [@swachter]: https://github.com/swachter
  [comma]: https://contributors.scala-lang.org/t/comma-inference/1521

### August, 2016

During the [SIP-27 trailing commas](https://github.com/scala/docs.scala-lang/pull/533) discussion, one of the thoughts that came to my mind was unifiying some of the commas with semicolons, and take advantage of the semicolon inference.

[Aug 10 2016 20:46][1]:

<img src='/images/nocomma1.png' alt="it might be interesting to consider allowing semicolons as vararg separator, and thereby allowing them to be infered as @Ichoran is suggesting">

This doesn't actually work. [@Ichoran][@Ichoran] kindly pointed out an example:

```scala
Seq(
  a
  b
  c
)
```

This is interpreted to be `Seq(a.b(c))` in Scala today.

### January, 2018

Recently [@swachter][@swachter] opened a thread called [Comma inference][comma] that reminded me of this topic:

> Scala has a well known mechanism called “semicolon inference”. I wonder if a similar mechanism may be useful for parameter and argument lists which could then be called “comma inference”.

Here's my response:

> I don’t think Scala (the spec as well as us users) can handle more than one punctuation inference, but there might be some tricks you could try.
>
> You have to get past the parser, so you need a legal “shape” of Scala. For example,

```scala
scala> List({
       1
       2
       3
       })
res1: List[Int] = List(3)
```

> The above is still legal Scala. The curly brace gets parsed into `Block` datatype in the compiler. It might be possible to define a macro that takes vararg `Int*` as argument, and when `Block` is passed, expands each statements as an argument.

In other words, instead of pursuing a language change, I'm suggesting that we can first experiment by rewriting trees. By using blocks `{ ... }` we can get around the infix problem pointed out by Rex.

```scala
scala> :paste
// Entering paste mode (ctrl-D to finish)

class A { def b(c: Int) = c + 1 }
lazy val a = new A
lazy val b = 2
lazy val c = 3

// Exiting paste mode, now interpreting.

defined class A
a: A = <lazy>
b: Int = <lazy>
c: Int = <lazy>

scala> Seq(
         a
         b
         c
       )
res0: Seq[Int] = List(4)

scala> Seq({
         a
         b
         c
       })
res1: Seq[Int] = List(3)
```

The first is interpretted to be `a.b(c)` whereas the second is `a; b; c`.

### removing commas in general

Let's implement the macro that would then transform `{ ... }` into a `Vector`. Here's a generic version:

```scala
package example

import scala.language.experimental.macros
import scala.reflect.macros.blackbox.Context

object NoComma {
  def nocomma[A](a: A): Vector[A] = macro nocommaImpl[A]

  def nocommaImpl[A: c.WeakTypeTag](c: Context)(a: c.Expr[A]) : c.Expr[Vector[A]] = {
    import c.universe._
    val items: List[Tree] = a.tree match {
      case Block(stats, x) => stats ::: List(x)
      case x               => List(x)
    }
    c.Expr[Vector[A]](
      Apply(Select(reify(Vector).tree, TermName("apply")), items))
  }
}
```

Here's how you can use it:

```scala
scala> import example.NoComma.nocomma
import example.NoComma.nocomma

scala> :paste
// Entering paste mode (ctrl-D to finish)

lazy val a = 1
lazy val b = 2
lazy val c = 3

// Exiting paste mode, now interpreting.

a: Int = <lazy>
b: Int = <lazy>
c: Int = <lazy>

scala> nocomma {
         a
         b
         c
       }
res0: Vector[Int] = Vector(1, 2, 3)
```

Using type inferencing, it will automatically pick the last item `c`'s type, which is `Int`. This may or may not be sufficient depending on your use case.

### removing commas from build.sbt

One thing I miss about bare build.sbt notation like

    name := "something"
    version := "0.1.0"

is its lack of commas at the end of each line.

We can hardcode `nocomma` macro specifically to `Setting[_]` as follows:

```scala
package sbtnocomma

import sbt._
import scala.language.experimental.macros
import scala.reflect.macros.blackbox.Context

object NoComma {
  def nocomma(a: Setting[_]): Vector[Setting[_]] = macro nocommaImpl

  def nocommaImpl(c: Context)(a: c.Expr[Setting[_]]) : c.Expr[Vector[Setting[_]]] = {
    import c.universe._
    val items: List[Tree] = a.tree match {
      case Block(stats, x) => stats ::: List(x)
      case x               => List(x)
    }
    c.Expr[Vector[Setting[_]]](
      Apply(Select(reify(Vector).tree, TermName("apply")), items))
  }
}
```

Published as sbt-nocomma, we can use this macro as follows:

```scala
import Dependencies._

ThisBuild / organization := "com.example"
ThisBuild / scalaVersion := "2.12.7"
ThisBuild / version      := "0.1.0-SNAPSHOT"

lazy val root = (project in file("."))
  .settings(nocomma {
    name := "Hello"

    // comment works
    libraryDependencies += scalaTest % Test

    scalacOptions ++= List(
      "-encoding", "utf8", "-deprecation", "-unchecked", "-Xlint"
    )
    Compile / scalacOptions += "-Xfatal-warnings"
    Compile / console / scalacOptions --= Seq("-deprecation", "-Xfatal-warnings", "-Xlint")
  })
```

Because we hardcoded the type to `Setting[_]`, it will catch things at loading time if you put `println(...)` or something:

<code>
/Users/xxx/hello/build.sbt:14: error: type mismatch;
 found   : Unit
 required: sbt.Setting[?]
    (which expands to)  sbt.Def.Setting[?]
    println("hello")
           ^
[error] sbt.compiler.EvalException: Type error in expression
[error] sbt.compiler.EvalException: Type error in expression
[error] Use 'last' for the full log.
Project loading failed: (r)etry, (q)uit, (l)ast, or (i)gnore?
</code>

### setup

To try this yourself, add the following to `project/plugins.sbt` using sbt 1.x:

```scala
addSbtPlugin("com.eed3si9n" % "sbt-nocomma" % "0.1.0")
```
