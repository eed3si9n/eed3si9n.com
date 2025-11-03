---
title:       "Expecty 0.17.1"
type:        story
date:        2025-11-03
url:         /expecty-0.17.1
tags:        [ "scala" ]
---

Expecty 0.17.1 is released. Expecty brings power assert (or power assertion) to Scala. It was originally implemented by Peter Niederwieser who implemented the original power assertion [Spock](http://spockframework.org/) in Groovy. It had gone dormant for a while, and I forked it in [2018](https://eed3si9n.com/power-assert-with-expecty/), and started publishing it against modern build matrix like Scala 2.12, 2.13, 3.x, JVM, JS, and Native.

<!--more-->

### power assertion

An example of a power assertion looks something like the following:

```scala
scala> assert(person.age * 2 == 73, "age is not right")
java.lang.AssertionError: assertion failed: age is not right

assert(person.age * 2 == 73, "age is not right")
       |      |   |   |
       |      42  84  false
       Person(Fred,42)

  at com.eed3si9n.expecty.Expecty$ExpectyListener.expressionRecorded(Expecty.scala:35)
  at com.eed3si9n.expecty.RecorderRuntime.recordExpression(RecorderRuntime.scala:39)
  ... 36 elided
```

In short, it calls `toString` to all the symbols in the expression, which is often useful in identifying where the problem is coming from when the assertion doesn't hold.

### The Java problem

There's been a long standing bug [#59](https://github.com/eed3si9n/expecty/issues/59), which says that the macro doesn't work on Scala 3 when Java enum is involved, for example,

```scala
assert(Status.Error == Status.Error)
```

caused

```scala
Caused by: Exception in thread main: java.lang.ClassNotFoundException: sbt.testing.Status$
```

This is likely caused by Expecty trying to print out the `toString()` value for the `Status` companion object, but Java doesn't have a companion object `Status$`.

The actual fix was a few lines of patch in [#219](https://github.com/eed3si9n/expecty/pull/219).

```scala
      case sel @ Select(x, y) =>
        if !x.symbol.flags.is(Flags.Package) && !isJavaEnum(x.symbol)
          && !sel.symbol.flags.is(Flags.JavaStatic)
        then Select.copy(expr)(recordAllValues(runtime, x), y)
        else expr

....

  private def isJavaEnum(sym: Symbol): Boolean =
    sym.flags.is(Flags.Enum) && sym.flags.is(Flags.JavaDefined)
```

Due to the nature of the code, this macro is somewhat low-level even though it's in Scala 3.x. Expecty 0.17.1 hopefully fixes `assert(...)` for Java enums and Java static method handling.
