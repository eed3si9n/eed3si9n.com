---
title:       "Eval 0.4.0"
type:        story
date:        2026-09-30
url:         /eval-0.4.0
---

Eval 0.4.0 is released. [Eval](https://github.com/eed3si9n/eval) evaluates Scala 3 code. See <https://eed3si9n.com/eval/> for details.

Eval 0.4.0 adds Scala 3.9.0 support.

<!--more-->

### usage

#### build.sbt

```scala
scalaVersion := "3.9.0"
libraryDependencies += ("com.eed3si9n.eval" % "eval" % "0.4.0").cross(CrossVersion.full)
```

### usage

```scala
package example

import com.eed3si9n.eval.Eval

case class ServerConfig(port: Int)

@main def main(): Unit =
  val x = Eval[ServerConfig](
    "example.ServerConfig(port = 8080)")
  println(x.port)
```

```bash
$ sbt run
[info] [foo] compiling 1 Scala source to /private/tmp/foo/target/out/jvm/scala-3.9.0/foo/classes ...
[info] running (fork) example.main
8080
```
