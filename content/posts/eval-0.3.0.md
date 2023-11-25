---
title:       "Eval 0.3.0"
type:        story
date:        2023-11-25
url:         /eval-0.3.0
---

I released Eval 0.3.0 for Scala 3.3.1. [Eval](https://github.com/eed3si9n/eval) evaluates Scala 3 code. See <https://eed3si9n.com/eval/> for details.

<!--more-->

### usage

#### build.sbt

```scala
ThisBuild / scalaVersion := "3.3.1"
libraryDependencies += ("com.eed3si9n.eval" % "eval" % "0.3.0").cross(CrossVersion.full)
Compile / fork := true
```

#### Main.scala

```scala
package example

import com.eed3si9n.eval.Eval

case class ServerConfig(port: Int)

@main def main(): Unit =
  val x = Eval[ServerConfig](
    "example.ServerConfig(port = 8080)")
  println(x.port)
```

#### run

```
sbt:eval> run
[info] compiling 1 Scala source to target/scala-3.3.1/classes ...
[info] running (fork) example.main
[info] 8080
```

This shows that the string `example.ServerConfig(port = 8080)` was evaluated as a Scala code, and became available to the `main` function as an instantiated case class.
