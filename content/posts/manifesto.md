---
title:       "Scala 3 Manifesto 0.1.0"
type:        story
date:        2024-10-14
url:         /manifesto
tags:        [ "scala" ]
---

I released Scala 3 Manifesto, a small library to reimplement `scala.reflect.Manifest` in Scala 3.

Programming languages operate at two levels. First, the material level where bits and bytes are moved to take actions. Second, there is a higher, spiritual level that describes the material level. The first level is the runtime. The second level is the compile-time. Scala programs are written using `val` terms that are typed, but at the JVM bytecode, JS, or Native, the variables turn into something different, often more general. For example, a variable typed to `List[Int]` becomes `List[AnyRef]` at runtime.

### Example of Scala 2.x Manifest

In Scala 2.x, `scala.reflect.Manifest` provides a mechanism to materialize the spiritual (type) information into the runtime. This is called _reification_.

```scala
// BAD EXAMPLE in Scala 2.12.20

package example

object Hello extends App {
  println(foo(List("hi")))

  def foo(xs: Any): String =
    xs match {
      case xs: List[Int]    => "xs is List[Int]"
      case xs: List[String] => "xs is List[String]"
      case xs               => "xs is unknown"
    }
}
```

If you run the code using Scala 2.12.20, you get:

```scala
sbt:foo> run
[info] running example.Hello
xs is List[Int]
```

This is because the pattern match runs at runtime, and `List[Int]` and `List[String]` are not distinguished. We can fix this by capturing the type information of `List("hi")`:

```scala
package example

import scala.reflect.Manifest

object Hello extends App {
  println(foo(List("hi")))

  def foo[A1: Manifest](xs: A1): String = {
    val m = implicitly[Manifest[A1]]
    val mli = implicitly[Manifest[List[Int]]]
    val mls = implicitly[Manifest[List[String]]]
    xs match {
      case xs: List[Int]    if m == mli => "xs is List[Int]"
      case xs: List[String] if m == mls => "xs is List[String]"
    }
  }
}
```

This will print:

```scala
sbt:foo> run
[info] running example.Hello
xs is List[String]
```

`Manifest` provides `typeArguments` method to traverse into the type parameters. Generally `Manifest` provides a lightweight interface for metaprogramming without going into the macros.

#### Scala 3 problem

In Scala 3 `Manifest` still works, but it shows a deprecation warning:

```
[warn] -- Deprecation Warning: src/main/scala/Hello.scala:6:25 -------
[warn] 6 |  println(foo(List("hi")))
[warn]   |                         ^
[warn]   |Compiler synthesis of Manifest and OptManifest is deprecated, instead
[warn]   |replace with the type `scala.reflect.ClassTag[List[String]]`.
[warn]   |Alternatively, consider using the new metaprogramming features of Scala 3,
[warn]   |see https://docs.scala-lang.org/scala3/reference/metaprogramming.html
```

`ClassTag` doesn't seem to capture the type information:

```scala
// BAD EXAMPLE in Scala 3.5.1

package example

import scala.reflect.ClassTag

@main def hello(): Unit =
  println(foo(List("hi"))) // xs is List[Int]

def foo[A1: ClassTag](xs: A1): String =
  val m = summon[ClassTag[A1]]
  val mli = summon[ClassTag[List[Int]]]
  val mls = summon[ClassTag[List[String]]]
  xs match
    case xs: List[Int]    if m == mli => "xs is List[Int]"
    case xs: List[String] if m == mls => "xs is List[String]"
```

```
sbt:foo> run
[info] running example.hello
xs is List[Int]
```

### Manifesto 0.1.0

```scala
scalaVersion := "3.5.1"
Compile / scalacOptions += "-deprecation"
libraryDependencies += "com.eed3si9n.manifesto" %% "manifesto" % "0.1.0"
```

Manifesto is a small library that implements `Manifesto[A1]`, which can be used as a replacement of `Manifest[A1]` in certain use cases:

```scala
package example

import com.eed3si9n.manifesto.Manifesto

@main def hello(): Unit =
  println(foo(List("hi"))) // xs is List[String]

def foo[A1: Manifesto](xs: A1): String =
  val m = Manifesto[A1]
  val mli = Manifesto[List[Int]]
  val mls = Manifesto[List[String]]
  xs match
    case xs: List[Int]    if m == mli => "xs is List[Int]"
    case xs: List[String] if m == mls => "xs is List[String]"
```

This works as expected:

```
sbt:foo> run
[info] running example.hello
xs is List[String]
```

`Manifesto` provides `typeArguments` method, which returns a list of `Manifesto`s:

```scala
package example

import com.eed3si9n.manifesto.Manifesto

@main def hello(): Unit =
  println(bar(List("hi"))) // java.lang.String

def bar[A1: Manifesto](xs: A1): String =
  val m = Manifesto[A1]
  m.typeArguments(0).show
```

### Details

Manifesto is a tree-shaped data structure:

```scala
trait Manifesto[A1]:
  def typeCon: String
  def typeArguments: List[Manifesto[?]]
  def isSingleton: Boolean
  override def toString(): String = show
  def show: String =
    if typeArguments.isEmpty then typeCon
    else s"""$typeCon[${typeArguments.mkString(",")}]"""
  ....
end Manifesto

object Manifesto:
  def apply[A1: Manifesto]: Manifesto[A1] = summon[Manifesto[A1]]
  inline given [A1]: Manifesto[A1] = Derivation.derived[A1]
end Manifesto
```

The [derivation code](https://github.com/eed3si9n/manifesto/blob/main/src/main/scala/com/eed3si9n/manifesto/Derivation.scala) is a relatively simple Scala 3 macro that traverses over the `TypeRepr`. `TypeRepr` provides access to the type information during compile-time. So we can retreieve the class name at each level, and recursively creates `Manifesto` structure.

`Manifest` provides more features, but for my own use case having this information allows me to cross build with both Scala 2.x and 3.x with a minimum shim.
