---
title:       "ifdef in Scala via pre-typer processing"
type:        story
date:        2023-10-15
url:         /ifdef-in-scala-via-pre-typer-processing
tags:        [ "scala" ]
---

  [rpl]: https://web.mit.edu/rust-lang_v1.25/arch/amd64_ubuntu1404/share/doc/rust/html/book/first-edition/conditional-compilation.html

This is part 2 of implementing Rust's `cfg` attribute in Scala. In [part 1](/ifdef-macro-in-scala), I tried the annotation macro with a mixed result. I've implemented a version of `@ifdef` that works better.

### what does `cfg` attribute do?

[Rust Programming Language][rpl] says:

> Rust has a special attribute, `#[cfg]`, which allows you to compile code based on a flag passed to the compiler.

This lets us write unit test in the same source as the library code like this:

```rust
...

#[cfg(test)]
mod tests {
    #[test]
    fn some_test() {
        ...
    }
}
```

When I first heard about this, it sounded a bit absurd since I've never used languages that embeds tests into the `main` source code. But now that I've been working with Rust occasionally, I like the idea of being able to write the tests in the same source, especially for kind of code that can be exercised as functions. When it gets too messy, you can always split them out in `src/test/scala/` or `tests/` in Rust.

<!--more-->

### problem with 0.1.0 (annotation macro)

In [part 1](/ifdef-macro-in-scala), I tried the annotation macro with a mixed result. I tried to use annotation macro feature in earnest, but I don't think it's powerful enough to implement `@ifdef`.

- It worked better in Scala 2.x, but the product JARs still contained empty `ATest` class etc, so in that sense it was not good.
- It didn't work in Scala 3 since it required test libraries (like MUnit) during compilation, and it also left behind `extends munit.FunSuite`.

Later I've filed [dotty#18677](https://github.com/lampepfl/dotty/issues/18677). From the discussion, it seems like annotation macro, which works post-typer, is fundamentally not intended for removing classes and methods. In general, the approach Scala 3 takes with [metaprogramming](https://docs.scala-lang.org/scala3/reference/metaprogramming/index.html) is to first perform typechecking, and carry that context into user-defined quotations. For general macros, I think that's a great approach, but we also want something close to a code generator that can change the shape of the code.

## pre-typer processing

We can implement conditional compilation, if we operate pre-typer. The Scala compiler, either Scala 2.x or 3.x, consists of series of [phases](https://dotty.epfl.ch/docs/contributing/architecture/phases.html). You can see the list of phases by running `scalac -Xshow-phases`. Scala 3, for instance has over a hundred phases:

```
$ scalac -Xshow-phases
             phase name  description
             ----------  -----------
                 parser  scan and parse sources
                  typer  type the trees
   checkUnusedPostTyper  check for unused elements
       inlinedPositions  check inlined positions
               sbt-deps  sends information on classes' dependencies to sbt
      extractSemanticDB  extract info into .semanticdb files
              posttyper  additional checks and cleanups after type checking
          prepjsinterop  additional checks and transformations for Scala.js
                sbt-api  sends a representation of the API of classes to sbt
            SetRootTree  set the rootTreeOrProvider on class symbols
                pickler  generates TASTy info
               inlining  inline and execute macros
           postInlining  add mirror support for inlined code
checkUnusedPostInlining  check for unused elements
                staging  check staging levels and heal staged types
               splicing  splicing
... 99 more phases ...
               genBCode  generate JVM bytecode
```

The first phase, parser, converts the Scala text into untyped abstract syntax tree `untpd.Tree`. The second phase, typer, does the typechecking and creates typed abstract syntax tree `tpd.Tree`. We can think of typechecking to be where we do typo checking. If your code uses some external library code without import etc this is where it would fail.

So if we wanted to remove classes and methods during `Compile/compile`, we need to do so _before_ typer gets to our test code. This is somewhat analogous to code generation at build tool level, Scalafix's syntactic rewrite, and what I wanted to do with [treehugger.scala](https://eed3si9n.com/treehugger/) in 2012, except it would be part of the compilation. Scala compiler makes it easy to inject custom phases.

### pre-typer processing in Scala 3

The boilderplate for a pre-typer plugin looks like this in Scala 3:

```scala
package com.eed3si9n.ifdef.ifdefplugin

import dotty.tools.dotc.CompilationUnit
import dotty.tools.dotc.core.Contexts.Context
import dotty.tools.dotc.plugins.{ PluginPhase, StandardPlugin }
import dotty.tools.dotc.parsing.Parser

class IfDefPlugin extends StandardPlugin:
  val name: String = "ifdef"
  override val description: String = "ifdef preprocessor"
  def init(options: List[String]): List[PluginPhase] =
    (new IfDefPhase) :: Nil
end IfDefPlugin

class IfDefPhase extends PluginPhase:
  val phaseName = "ifDef"
  override def runsAfter: Set[String] = Set(Parser.name)
  override def runOn(units: List[CompilationUnit])(using ctx: Context): List[CompilationUnit] =
    val unitContexts =
      for unit <- units
      yield ctx.fresh.setPhase(this.start).setCompilationUnit(unit)
    unitContexts.foreach(preprocess(using _))
    unitContexts.map(_.compilationUnit)

  def preprocess(using ctx: Context): Unit =
    val unit = ctx.compilationUnit
    try
      if !unit.suspended then
        // todo: implement M
        unit.untpdTree = (new M).transform(unit.untpdTree)
    catch case _: CompilationUnit.SuspendException => ()
end IfDefPhase
```

Next, we need to implement `M` that walks the untyped AST, and transforms it to a new tree. Since it's a common operation in compiler, there's a data structure called `TreeMap` to help us with this. We will be using a variant called [`UntypedTreeMap`](https://github.com/lampepfl/dotty/blob/3.3.1/compiler/src/dotty/tools/dotc/ast/untpd.scala#L679).

### UntypedTreeMap

To transform an untyped tree, we override the `transform` method, and make sure that any cases we don't handle fall back to `super.transform`.

```scala
class M extends UntypedTreeMap:
  val eval = IfDefExpr.eval(keys)
  override def transform(tree: Tree)(using Context): Tree =
    tree match
      case tree: DefTree => transformDefn(tree.mods.annotations)(tree)
      case _             => super.transform(tree)

  // transform any definitions, includinng classes and `def`s
  def transformDefn(annots: List[Tree])(tree: Tree)(using Context): Tree =
    annots.iterator.map(extractAnnotation).collectFirst {
      case Some(expr) =>
        if eval(expr) then super.transform(tree)
        else EmptyTree
    }.getOrElse(super.transform(tree))
```

An enhancement I've made for ifdef 0.2.0 is that it can handle any definitions, including `class` and `def`.

### demo (Scala 3.3.0)

```scala
import com.eed3si9n.ifdef.ifdef

class A:
  def foo: Int = 42

@ifdef("test")
class ATest extends munit.FunSuite:
  test("foo"):
    val actual = new A().foo
    val expected = 43
    assertEquals(actual, expected)
```

Here are results of compiling and testing the code:

```bash
sbt:ifdef root> app/compile
[info] compiling 1 Scala source to ifdef/app/target/scala-3.3.0/classes ...
[success] Total time: 5 s
sbt:ifdef root> app/test
[info] compiling 1 Scala source to ifdef/app/target/scala-3.3.0/test-classes ...
ATest:
==> X ATest.foo  0.052s munit.ComparisonFailException: ifdef/app/app.scala:26
25:    val expected = 43
26:    assertEquals(actual, expected)
values are not the same
....
sbt:ifdef root> exit
$ ls app/target/scala-3.3.0/classes
A.class  A.tasty
```

This shows that `app/compile` will ignore `munit.FunSuite`, but `app/test` will see it. Note that we no longer have the `*.class` file for `ATest`! This is an improvement over the previous attempt.

### demo (Scala 2.13)

The same plugin can be implemented Scala 2.x as well, and here are the results:

```bash
sbt:ifdef root> app/scalaVersion
[info] 2.13.12
sbt:ifdef root> app/compile
[info] compiling 1 Scala source to app/target/scala-2.13/classes ...
[success] Total time: 1 s
$ ls app/target/scala-2.13/classes
A.class
```

Also missing `ATest.class`, which is great.

## ifndef

To implement if-else, in 0.2.0 I've also implemented `@ifndef(...)`.

```scala
  val IfDefName = Names.termName("ifdef").toTypeName
  val IfNDefName = Names.termName("ifndef").toTypeName
  def extractAnnotation(annot: Tree)(using ctx: Context): Option[IfDefExpr] =
    annot match
      case Apply(Select(New(Ident(IfDefName)), _), List(arg)) =>
        Some(IfDefExpr.IfDef(extractLiteral(arg)))
      case Apply(Select(New(Ident(IfNDefName)), _), List(arg)) =>
        Some(IfDefExpr.IfNDef(extractLiteral(arg)))
      case _ => None

  def extractLiteral(arg: Tree): String =
    arg match
      case Literal(Constant(x)) => x.toString
      case _                    => sys.error(s"invalid arg $arg")

enum IfDefExpr:
  case IfDef(arg: String)
  case IfNDef(arg: String)

object IfDefExpr:
  def eval(env: Set[String])(expr: IfDefExpr): Boolean =
    expr match
      case IfDefExpr.IfDef(arg)  => env(arg)
      case IfDefExpr.IfNDef(arg) => !env(arg)
end IfDefExpr
```

To the compiler, annotations look like function calls in the shape of `new ifndef()("test")`. `extractAnnotation` pattern matches to the shape and returns an option of enum.

### ifndef usage

Here's a simple demo of conditional compilation of `def`, and using `@ifndef`:

```scala
import com.eed3si9n.ifdef.{ ifdef, ifndef }

class A:
  @ifdef("compile")
  def bar: Int = 1

  @ifndef("compile")
  def bar: Int = 2

@ifdef("test")
class ATest extends munit.FunSuite:
  test("bar"):
    val actual = new A().bar
    val expected = 2
    assertEquals(actual, expected)
```

It would probably be more useful for situations where we have more than two options, but this shows that we can do if-else pre-typer processing at compile-time, without causing compilation errors.

## Scala cross building

One example that often comes for conditional compilation for Scala is cross building that we already do using sbt. We can lift sbt settings like `scalaBinaryVersion` as `ifDefDeclarations` as follows:

```scala
ifDefDeclarations ++= {
  val sbv = scalaBinaryVersion.value
  List(
    configuration.value.name,
    s"scalaBinaryVersion:$sbv",
  )
},
```

### Scala cross building usage

Combining with `@ifndef`, here we can define a method for Scala 3.x and 2.x separately:

```scala
import com.eed3si9n.ifdef.{ ifdef, ifndef }

class A {
  @ifdef("scalaBinaryVersion:3")
  def foo: String = "3"

  @ifndef("scalaBinaryVersion:3")
  def foo: String = "2.x"
}

@ifdef("test")
class ATest extends munit.FunSuite {
  test("foo") {
    val actual = new A().foo
    assert(Set("3", "2.x")(actual))
  }
}
```

## IDE integration

One of the concerns of using compiler plugins is that tooling is going to suffer. I think this is a valid concern, but that could apply to any form of metaprogramming essentially. An interesting aspect of pre-typer processing is that we can modify the code _before_ tooling phases, such as sbt-deps and SemanticDB generation, so it's possible that we have less impact. We can check.

### IntelliJ Scala plugin 2023.2.27

I used the default sbt import with the option to build using sbt shell checked, but it didn't seem to work.

![image1](/images/ifdef_intellij.png)

In the above, we see that the class annotated `@ifdef("test")` with causing errors.

### Metals 1.0.1

Metals on VS Code seems to be ok with the annotation. It even recognizes the `@ifdef("test")` as actual test:

![image2](/images/ifdef_metals1.png)

I didn't do anything special to import the project other than using sbt as the build server.

## setup

Put this in `project/plugins.sbt`:

```scala
addSbtPlugin("com.eed3si9n.ifdef" % "sbt-ifdef" % "0.2.0")
```

Source is available at https://github.com/eed3si9n/ifdef

Note that the sbt plugin adds the following dependencies to your subprojects:

```scala
libraryDependencies += "com.eed3si9n.ifdef" %% "ifdef-annotation" % ifDefVersion % Provided,
libraryDependencies += compilerPlugin("com.eed3si9n.ifdef" %% "ifdef-plugin" % ifDefVersion),
```

This does leak to the POM as:

```xml
<dependency>
    <groupId>com.eed3si9n.ifdef</groupId>
    <artifactId>ifdef-annotation_2.13</artifactId>
    <version>0.2.0</version>
    <scope>provided</scope>
</dependency>
```

But it shouldn't affect the dependency graph, since provided will be ignored.

## summary

- `@ifdef` is an experimental annotation that implemented via pre-typer processing.
- Unlike 0.1.0 using annotation macros, pre-typer processing is capable of removing classes and methods from the final compilation results.
- ifdef 0.2.0 is capable of annotating any definitions including `def`.
- ifdef 0.2.0 adds supports for negation `@ifndef`.
- ifdef 0.2.0 also surfaces sbt's `scalaBinaryVersion` setting, which enables cross building using the same source file.
