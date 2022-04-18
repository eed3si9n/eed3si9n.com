---
title:       "Eval 0.1.0"
type:        story
date:        2022-03-28
url:         /eval
---

  [eval]: https://github.com/eed3si9n/eval
  [embedding]: https://web.archive.org/web/20111020090514/http://suereth.blogspot.com/2009/04/embedding-scala-interpreter.html
  [util-eval]: https://github.com/twitter/util/tree/version-1.3.0#eval
  [td1992165]: https://web.archive.org/web/20100826033843/http://scala-programming-language.1934581.n4.nabble.com/Compiler-API-td1992165.html

I released Eval 0.1.0. [Eval][eval] evaluates Scala 3 code. It's a Scala 3 port of `Eval` class used in sbt.

```scala
package example

import com.eed3si9n.eval.Eval
import com.eed3si9n.eval.EvalReporter
import java.nio.file.Paths

@main def main(): Unit =
  val eval = Eval(
    backingDir = Paths.get("/tmp/classes"),
    mkReporter = () => EvalReporter.store
  )
  val result = eval.evalInfer("2")
  println(result.tpe)
  println(result.getValue(this.getClass.getClassLoader))
```

The above prints:

```
Int
2
```

<!--more-->

You can also pass in the expected type:

```scala
package example

import com.eed3si9n.eval.Eval
import com.eed3si9n.eval.EvalReporter
import java.nio.file.Paths

@main def main(): Unit =
  val eval = Eval(
    backingDir = Paths.get("/tmp/classes"),
    mkReporter = () => EvalReporter.store
  )
  val result = eval.eval("2", Some("scala.Long"))
  println(result.tpe)
  println(result.getValue(this.getClass.getClassLoader))
```

The above prints:

```
Long
2
```

There's also a macro that takes a type parameter, and would return a value in that type:

```scala
package example

import com.eed3si9n.eval.Eval

case class ServerConfig(port: Int)

@main def main(): Unit =
  val x = Eval[ServerConfig](
    "example.ServerConfig(port = 8080)")
  println(x.port)

```

The above prints:

```
8080
```

### background

Around the time when I started Scala in 2009 or 2010, there was an idea of implementing evaluator for Scala code, passing some code as String, which then would evaluate the return some value.

Two examples that pop into my mind are:

- Josh's [Embedding the Scala Interpreter][embedding] (2009)
- Twitter's [util-eval][util-eval] (2010)
- util-eval mentions ["Compiler API"][td1992165] thread (2007)

Since DSL was initially thought to be one of the strengths of Scala, this makes sense. Another use promoted by util-eval, which is now deprecated, was using Scala code to represent configurations.

Scala 2 Reflection API was added later in the history of Scala 2, which includes Toolbox to allow type this of operation, but sbt that was created also during the early era never moved to using it, partly because it was doing mutable operation to fake the position.
