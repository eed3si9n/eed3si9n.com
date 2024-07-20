---
title:       "ifdef 0.3.0: conditional compilation in Scala"
type:        story
date:        2024-07-20
url:         /ifdef-0.3.0-conditional-compilation-in-scala
tags:        [ "scala" ]
---

  [@eed3si9n]: https://github.com/eed3si9n
  [@uosis]: https://github.com/uosis
  [sip-nn-conditional]: https://github.com/scala/docs.scala-lang/pull/1541/files?short_path=0952117#diff-0952117606ef631d9a0a01c4190bc8878ca024d270a9dd519350d038a3290cc1

`@ifdef` is a Scala compiler plugin that impelements conditional compilation in Scala. ifdef 0.3.0 supports Scala.JS and Scala Native.

| Scala Version | JVM | JS (1.x) |  Native (0.5.x) |
| ------------- | :-: | :------: | :---------: |
| 3.x           | ✅  |   ✅     |    ✅     |
| 2.13.x        | ✅  |   ✅     |     ✅      |
| 2.12.x        | ✅  |   ✅     |     ✅      |

<!--more-->

### setup

Put this in `project/plugins.sbt`:

```scala
addSbtPlugin("com.eed3si9n.ifdef" % "sbt-ifdef" % "0.3.0")
```

Source is available at https://github.com/eed3si9n/ifdef

## conditional compilation

Rust defines [_conditional source code_](https://doc.rust-lang.org/reference/conditional-compilation.html) to be:

> code that may or may not be considered a part of the source code depending on certain conditions

`ifDefDeclations` are names or key-value pairs that are either set or unset to control the condition. Two declarations that are configured in sbt-ifdef 0.3.0 by default are:

1. build configuration names: `compile`, `test`
2. scalaBinaryVersion: `scalaBinaryVersion:3`

but you can use your imagination to expand to other axes that may have previously required different directories to cross build.

### in-source unit tests

One use of conditional compilation found in Rust is embedding unit tests into the library code as follows:

```scala
package example

import com.eed3si9n.ifdef.ifdef

class A:
  def foo: Int = 42
end A

@ifdef("test")
class ATest extends munit.FunSuite:
  test("foo"):
    val actual = new A().foo
    val expected = 42
    assertEquals(actual, expected)
end ATest
```

For many of the unit tests, I think this would be useful rather than splitting tests into different source code.

### Scala cross building

Here's an example of using `@ifdef` and `@ifndef` with `scalaBinaryVersion`:

```scala
package example

import com.eed3si9n.ifdef.{ ifdef, ifndef }
import java.util.{ Map => JMap }

class A {
  @ifdef("scalaBinaryVersion:2.12")
  def convertMapToScala[K, V](jmap: JMap[K, V]): Map[K, V] = {
    // -Xsource:3 lets us use * in Scala 2.12. nice
    import scala.collection.JavaConverters.*
    Map.empty ++ jmap.asScala
  }

  @ifndef("scalaBinaryVersion:2.12")
  def convertMapToScala[K, V](jmap: JMap[K, V]): Map[K, V] = {
    import scala.jdk.CollectionConverters.*
    Map.empty.concat(jmap.asScala)
  }
}
```

The above is the same example Stefan Zeiger used in the now-closed [SIP-NN Language support for conditional compilation][sip-nn-conditional] proposal. The example also demonstrates that in the above `@ifdef` and `@ifndef` are processed prior to the _typer_ phase, otherwise the code will fail to compile on Scala 2.12 because it is unaware of `scala.jdk.CollectionConverters.*`.

## new in 0.3.0

- Scala.JS support by [@uosis][@uosis] in [#2](https://github.com/eed3si9n/ifdef/pull/2)
- Scala Native support by [@eed3si9n][@eed3si9n] in [#3](https://github.com/eed3si9n/ifdef/pull/3)
- Fixes duplicate `scalacOptions` by [@eed3si9n][@eed3si9n] in [#4](https://github.com/eed3si9n/ifdef/pull/4)

### Reference

- [ifdef in Scala via pre-typer processing](/ifdef-in-scala-via-pre-typer-processing) (ifdef 0.2.0)
- [ifdef macro in Scala](/ifdef-macro-in-scala) (ifdef 0.1.0)
