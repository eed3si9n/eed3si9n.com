---
title:       "how to see the trees using the Scala compilers"
type:        story
date:        2024-07-06
url:         /trees
tags:        [ "scala" ]
---

Here's a memo on how to show trees using the Scala compilers. While this likely won't be relevant for normal usage of Scala, having the direct knowledge of the tree can be useful when developing tooling or during metaprogramming.

## Scala 2.13.14

Let's use the following example:

```scala
package example

object Main extends App {
  println("hello")
}
```

Here's how you can show the AST using Scala 2.13.14:

```bash
$ sdk install scala 2.13.14
$ sdk use scala 2.13.14
$ scalac --version
Scala compiler version 2.13.14 -- Copyright 2002-2024, LAMP/EPFL and Lightbend, Inc.
$ scalac -Vprint:parser,typer -Ystop-after:typer -Yprint-trees:format Hello.scala
```

<!--more-->

The output looks like this:

```scala
[[syntax trees at end of parser]]// Scala source: Hello.scala
PackageDef(
  "example"
  ModuleDef(
    0
    "Main"
    Template(
      "App" // parents
      ValDef(
        private
        "_"
        <tpt>
        <empty>
      )
      // 2 statements
      DefDef(
        0
        "<init>"
        []
        List(Nil)
        <tpt>
        Block(
          Apply(
            super."<init>"
            Nil
          )
          ()
        )
      )
      Apply(
        "println"
        "hello"
      )
    )
  )
)


[[syntax trees at end of typer]]// Scala source: Hello.scala
PackageDef(
  "example" // final package example, tree.tpe=example.type
  ModuleDef( // object Main in package example
    <module>
    "Main"
    Template( // val <local Main>: <notype> in object Main, tree.tpe=example.Main.type
      "java.lang.Object", "scala.App" // parents
      ValDef(
        private
        "_"
        <tpt>
        <empty>
      )
      // 2 statements
      DefDef( // def <init>(): example.Main.type in object Main
        <method>
        "<init>"
        []
        List(Nil)
        <tpt> // tree.tpe=example.Main.type
        Block( // tree.tpe=Unit
          Apply( // def <init>(): Object in class Object, tree.tpe=Object
            Main.super."<init>" // def <init>(): Object in class Object, tree.tpe=(): Object
            Nil
          )
          ()
        )
      )
      Apply( // def println(x: Any): Unit in object Predef, tree.tpe=Unit
        "scala"."Predef"."println" // def println(x: Any): Unit in object Predef, tree.tpe=(x: Any): Unit
        "hello"
      )
    )
  )
)
```

There are lots of interesting flags covered under `-V` and `-Y`, which are documented as [Verbose settings](https://docs.scala-lang.org/overviews/compiler-options/#Verbose_Settings) and [Private settings](https://docs.scala-lang.org/overviews/compiler-options/#Private_Settings).

### -Vprint-types

For example, here's how to print the inferred types:

```bash
$ scalac -Vprint:parser,typer -Ystop-after:typer -Yprint-trees:text -Vprint-types Hello.scala
```

```scala
[[syntax trees at end of                    parser]] // Hello.scala
package example{<null>} {
  object Main extends App {
    def <init>() = {
      super{<null>}.<init>{<null>}();
      (){<null>}
    }{<null>};
    println{<null>}("hello"{<null>}){<null>}
  }
}

[[syntax trees at end of                     typer]] // Hello.scala
package example{example.type} {
  object Main extends AnyRef with App {
    def <init>(): example.Main.type = {
      Main.super{example.Main.type}.<init>{(): Object}(){Object};
      (){Unit}
    }{Unit};
    scala.Predef.println{(x: Any): Unit}("hello"{String("hello")}){Unit}
  }
}
```

### -Yprint-trees:diff

Here's how to show the difference between the parser phase and the typer phase:

```bash
$ scalac -Vprint:parser,typer -Ystop-after:typer -Yprint-trees:diff Hello.scala
```

```scala

[[syntax trees at end of                     typer]] // Hello.scala
--- parser
+++ typer
@@ -1,8 +1,8 @@
 package example {
-  object Main extends App {
-    def <init>() = {
-      super.<init>();
+  object Main extends AnyRef with App {
+    def <init>(): example.Main.type = {
+      Main.super.<init>();
       ()
     };
-    println("hello")
+    scala.Predef.println("hello")
   }
```

### -Vprint-pos

Here's how to print the positions:

```bash
$ scalac -Vprint:parser,typer -Ystop-after:typer -Yprint-trees:text -Vprint-pos Hello.scala
```

```scala
[[syntax trees at end of                    parser]] // Hello.scala
[0:63]package [8:15]example {
  [17:63]object Main extends [29:63][37:40]App {
    [29]def <init>() = [29]{
      [NoPosition][NoPosition][NoPosition]super.<init>();
      [29]()
    };
    [45:61][45:52]println([53:60]"hello")
  }
}

[[syntax trees at end of                     typer]] // Hello.scala
[0:63]package [8:15]example {
  [17:63]object Main extends [29:63][37]AnyRef with [37:40]<type: [37:40]scala.App> {
    [37]def <init>(): [29]example.Main.type = [37]{
      [37][37][37]Main.super.<init>();
      [29]()
    };
    [45:61][45:52]scala.Predef.println([53:60]"hello")
  }
}
```

## Scala 3.4.2

Let's also try this with Scala 3.x:

```scala
package example

@main def hello() = println("Hello")
```

```bash
$ sdk install scala 3.4.2
$ sdk use scala 3.4.2
$ scalac --version
Scala compiler version 3.4.2 -- Copyright 2002-2024, LAMP/EPFL
$ scalac -Vprint:parser,typer -Ystop-after:typer -Yplain-printer Hello.scala
```

Here's the output:

```scala
[[syntax trees at end of                    parser]] // Hello.scala
PackageDef(Ident(example), List(
  DefDef(hello, List(List()), TypeTree(),
    Apply(Ident(println), List(Literal("Hello"))))
))

[[syntax trees at end of                     typer]] // Hello.scala
PackageDef(Ident(example), List(
  ValDef(Hello$package, Ident(Hello$package$),
    Apply(Select(New(Ident(Hello$package$)), <init>), List())),
  TypeDef(Hello$package$,
    Template(DefDef(<init>, List(List()), TypeTree(), Thicket(List())),
      List(Apply(Select(New(TypeTree()), <init>), List())),
      ValDef(_, SingletonTypeTree(Ident(Hello$package)), Thicket(List())), List(
      DefDef(hello, List(List()), TypeTree(),
        Apply(Ident(println), List(Literal("Hello"))))
    ))
  ),
  TypeDef(hello,
    Template(DefDef(<init>, List(List()), TypeTree(), Thicket(List())),
      List(Apply(Select(New(TypeTree()), <init>), List())),
      ValDef(_, Thicket(List()), Thicket(List())), List(
      DefDef(main, List(List(ValDef(args, TypeTree(), Thicket(List())))),
        TypeTree(),
        Try(Apply(Ident(hello), List()),
          List(
            CaseDef(Bind(error, Typed(Ident(_), TypeTree())), Thicket(List()),
              Apply(Ident(showError), List(Ident(error))))
          ),
        Thicket(List()))
      )
    ))
  )
))
```

Here are the `-Y` flags related to printing:

```bash
$ scalac -Y 2>&1 | rg "print|show"
....
          -Ycc-print-setup  Used in conjunction with captureChecking language
                            import, print trees after cc.Setup phase
        -Yexplain-lowlevel  When explaining type errors, show types at a lower
           -Yplain-printer  Pretty-print using a plain printer.
             -Yprint-debug  When printing trees, print some extra information
      -Yprint-debug-owners  When printing trees, print owners of definitions.
             -Yprint-level  print nesting levels of symbols and type variables.
               -Yprint-pos  Show tree positions.
          -Yprint-pos-syms  Show symbol definitions positions.
              -Yprint-syms  When printing trees print info in symbols instead of
             -Yprint-tasty  Prints the generated TASTY to stdout.
       -Yshow-print-errors  Don't suppress exceptions thrown during tree
                            printing.
  -Yshow-suppressed-errors  Also show follow-on errors and warnings that are
           -Yshow-tree-ids  Uniquely tag all tree nodes in debugging output.
         -Yshow-var-bounds  Print type variables with their bounds.
      -Ytest-pickler-check  Self-test for pickling -print-tasty output; should
```

### -Ypring-debug

Here's how to print the inferred types in Scala 3.x:

```bash
$ scalac -Vprint:parser,typer -Ystop-after:typer -Yprint-debug Hello.scala
```

```scala
$ scalac -Vprint:typer -Ystop-after:typer -Yprint-debug Hello.scala
[[syntax trees at end of                     typer]] // Hello.scala
package <root>.this.example {
  final lazy module val Hello$package: example.this.Hello$package$ =
    new example.this.Hello$package$.<init>()
  final module class Hello$package$() extends Object.<init>() {
    this: example.this.Hello$package.type =>
    @main def hello(): scala.this.Unit(inf) = scala.this.Predef.println("Hello")
    }
  final class hello() extends Object.<init>() {
    <static> def main(args: scala.this.Array[String]): scala.this.Unit =
      try Hello$package$.this.hello() catch
        {
          case error @ _:CommandLineParser$.this.ParseError =>
            CommandLineParser$.this.showError(error)
        }
  }
}
```

### -Yprint-pos

Here's how to print the positions in Scala 3.x:

```bash
$ scalac -Vprint:parser,typer -Ystop-after:typer -Yprint-pos Hello.scala
```

```scala
[[syntax trees at end of                    parser]] // Hello.scala
package example@<Hello.scala:1> {
  @main@<Hello.scala:3> def hello() =
    println@<Hello.scala:3>("Hello"@<Hello.scala:3>)@<Hello.scala:3>@<
    Hello.scala:3>
}@<Hello.scala:1>

[[syntax trees at end of                     typer]] // Hello.scala
package example@<Hello.scala:1> {
  final lazy module val Hello$package: example.Hello$package@<Hello.scala:3> =
    new example.Hello$package@<Hello.scala:3>@<Hello.scala:3>@<Hello.scala:3>()@
      <Hello.scala:3>
  @<Hello.scala:3>
  final module class Hello$package() extends Object@<Hello.scala:3>@<
    Hello.scala:3>()@<Hello.scala:3> {
    this: example.Hello$package@<Hello.scala:3>.type@<Hello.scala:3> =>
    @main def hello(): Unit =
      println@<Hello.scala:3>("Hello"@<Hello.scala:3>)@<Hello.scala:3>@<
      Hello.scala:3>
  }@<Hello.scala:3>
  final class hello() extends Object@<Hello.scala:3>@<Hello.scala:3>()@<
    Hello.scala:3> {
    <static> def main(args: Array[String]@<Hello.scala:3>): Unit =
      try example.hello@<Hello.scala:3>()@<Hello.scala:3> catch
        {
          case
            error @
              _@<Hello.scala:3> :scala.util.CommandLineParser.ParseError@<
                Hello.scala:3>
            @<Hello.scala:3>
           =>
            scala.util.CommandLineParser.showError@<Hello.scala:3>(
              error@<Hello.scala:3>)@<Hello.scala:3>
          @<Hello.scala:3>
        }
      @<Hello.scala:3>
    @<Hello.scala:3>
  }@<Hello.scala:3>
}@<Hello.scala:1>
```

### Printer

We can show the tree programmatically using Scala 3 macros as well. Here's `build.sbt`:

```scala
ThisBuild / scalaVersion := "3.4.2"
```

then:

```scala
$ sbt console
scala> import scala.quoted.*

scala> def showTreeImpl[A: Type](a: Expr[A])(using Quotes): Expr[String] =
         import quotes.reflect.*
         Expr(Printer.TreeStructure.show(a.asTerm))

scala> inline def showTree[A](inline a: A): String = ${showTreeImpl[A]('{ a })}

scala> showTree(List(1).map(x => x + 1))

val res0: String = Inlined(None, Nil, Apply(TypeApply(Select(Apply(TypeApply(Select(Ident("List"), "apply"), List(Inferred())), List(Typed(Repeated(List(Literal(IntConstant(1))), Inferred()), Inferred()))), "map"), List(Inferred())), List(Block(List(DefDef("$anonfun", List(TermParamClause(List(ValDef("x", Inferred(), None)))), Inferred(), Some(Apply(Select(Ident("x"), "+"), List(Literal(IntConstant(1))))))), Closure(Ident("$anonfun"), None)))))
```

## bonus: Scalameta

Yoshida-san created [scalameta-ast](https://xuwei-k.github.io/scalameta-ast/), which can show the tree for Scalameta, which could be helpful when creating a Scalafix rule.

For example, the tree for the the following Scala 3.x code:

```scala
package example

@main def hello() = println("Hello")
```

is:

```scala
Source(
  List(
    Pkg(
      Term.Name("example"),
      List(
        Defn.Def(
          List(
            Mod.Annot(
              Init(
                Type.Name("main"),
                Name(""),
                Nil
              )
            )
          ),
          Term.Name("hello"),
          Nil,
          List(List()),
          None,
          Term.Apply(
            Term.Name("println"),
            List(Lit.String("Hello"))
          )
        )
      )
    )
  )
)
```

## summary

There are compiler flags on Scala 2.x and 3.x to print out the abstract syntax tree of the Scala source code under compilation. This shows the direct interpretation of how the compiler is processing the source code, and additionally it could show useful information such as the type info and positions.

Generally speaking current Scala 2.13.14 tends to use `-V` flags, while Scala 3.4.2 tends to use `-Y` flags, however these are private flags that are subject to change from one release to the other.
