---
title: "incremental compilation of Scala 3"
date: 2025-10-12
type: story
url:  /incremental-compilation-of-scala3
tags: [ "scala" ]
---

  [23852]: https://github.com/scala/scala3/issues/23852
  [analysis]: https://www.youtube.com/watch?v=h8ACmUHQ2jg
  [24171]: https://github.com/scala/scala3/pull/24171

In this post, I want to look into the incremental compilation of Scala 3, or the apparent problem associated with it. The incremental compilation on Scala 2.12 or 2.13 has been fairly stable, but for some reason it's more fragile on Scala 3.x in my experience. We will investigate the cause and attempt to fix it as [scala/scala3#24171][24171].

<!--more-->

### a macro in Scala 2.13

As a baseline experiment, let's look into Scala 2.13 macro.
Here's a def macro called `Provider.foo(...)` that returns `0` if the argument is literally `0`, or forwards the argument to `Core.core(arg)` for non-zero:

```scala
package example

import scala.language.experimental.macros
import scala.reflect.macros.blackbox.Context

object Provider {
  def foo(arg: Int): Int = macro fooImpl
  def fooImpl(c: Context)(arg: c.Tree): c.Tree = {
    import c.universe._
    arg match {
      case q"0"  => q"0"
      case q"$a" => q"""Core.core($a)"""
    }
  }
}
```

and `Core` should look like:

```scala
package example

object Core {
  def core(arg: Int): Int = arg + 1
}
```

From another subproject, we can use the macro as follows:

```scala
package example

object Use {
  val x = Provider.foo(1)
}
```

All this should compile.

![inc1](/images/inc1.svg)

Next, we change `Core` as follows to break the function:

```scala
object Core {
  def core(arg: String): Int = arg.toInt + 1
}
```

Now when you `compile` from the sbt shell, the compilation fails (**successfully**):

```scala
[error] macro/usesite/Use.scala:4:24: type mismatch;
[error]  found   : Int(1)
[error]  required: String
[error]   val x = Provider.foo(1)
[error]                        ^
[error] one error found
[error] (usesite / Compile / compileIncremental) Compilation failed
```

![inc2](/images/inc2.svg)

This feels unremarkable, like water coming out of a tap, but if we think about it, it is remarkable that Zinc is able to detect that `object Use` requires recompilation since `Provider.foo(1)` generated a synthetic function call to `Core.core`, which now have changed its function signature since before.

### a macro in Scala 3.7.3

The incremental compilation on Scala 3.x seems more fragile, sometimes running into `NoSuchMethodError`, which normally does not happen on the Scala 2.x side. There has been several reports, but one recent one submitted to scala/scala3 by OlegYch is [Macro usage is not invalidated #23852][23852]. This report points to the possibiliy that macro handling might be related to the issue.

On the surface, the reported bug has a similar structure as the example above. Instead of `Core`, he changes a class named `Dep`:

```scala
// before
class Dep()

// after
class Dep(dep1: Dep1)
```

Using Scala 3.7.3, the change does **not** invalidate the following use site:

```scala
import com.softwaremill.macwire.*

object Use extends App {
  try {
    val d = wire[Dep]
    val d1 = wire[Dep1]
    val d2 = wire[Dep2]
  } catch {
    case e: Throwable =>
      e.printStackTrace()
      sys.exit(-1)
  }
}
```

In other words, the incremental compilation **succeeds incorrectly**. We call this under-compilation.
This results in an runtime error:

```scala
[error] java.lang.NoSuchMethodError: Dep: method <init>()V not found
[error]   at Use$.<clinit>(Use.scala:12)
[error]   at Use.main(Use.scala)
```

The expected behavior was to catch the breakage of `Dep` at compile-time, but instead this turned into a runtime error. The macro is SoftwareMill's MacWire, so that's different from the simple example. However, the same exact `scripted` test works for Scala 2.13.17.

### custom phases of Zinc

Where could the difference between Scala 2.13 and Scala 3.x coming from?
Besides the fact that Scala 3.x has a different mechanism for metaprogramming, it also has its own implemetation of the _compiler bridge_. The compiler bridge is the adaptation layer between Zinc the Scala compilers, and one of the functionality is to inject custom phases needed for incremental compilation.

For the purpose of fixing this issue, we don't have to unpack the details of incremental compilation, beyond the fact that we need to register member-reference relationship between the use site (like `Use`) and the generated code (like `Core` and `Dep`). See [Analysis of Zinc][analysis] talk if you're interested in more details.

In Scala 2.13, `xsbt-dependency` phase is injected by Zinc after `xsbti-api` phase, which in turn is injected after the typer phase. In Scala 2.13, the macros are expanded as part of the typer phase. This means, that on Scala 2.13, Zinc see the code post-macro-expansion.

Scala 3 team has in-sourced the compiler bridge into scala/scala3, so unlike Scala 2.12 etc, there is a published binary for the compiler bridge on Maven Central. On one hand this is reasonable, but this also means that the incremental behavior cannot be fixed without releasing a new version of Scala 3. According to [Compiler.scala](https://github.com/scala/scala3/blob/3.7.3/compiler/src/dotty/tools/dotc/Compiler.scala), Scala 3 puts `sbt-deps` after the typer. However, in Scala 3, inlining and macro expansion happens much later in the phase. This means that at the point of dependency tracking, Scala 3 compiler might see quoted code, but not the raw expanded trees. This might explain why the incremental is less accurate.

### fixing the sbt-deps phase

There are two things we should try:

1. Inject `sbt-deps` after the inlining phase
2. Walk the `Inlined(...)` node

First one is easy:

```diff
--- a/compiler/src/dotty/tools/dotc/Compiler.scala
+++ b/compiler/src/dotty/tools/dotc/Compiler.scala
@@ -48,6 +47,7 @@ class Compiler {
     ....
     List(new Inlining) ::           // Inline and execute macros
+    List(new sbt.ExtractDependencies) :: // Sends information on classes' dependencies to sbt via callbacks
```

Second one is actually not too bad either:

```diff
--- a/compiler/src/dotty/tools/dotc/sbt/ExtractDependencies.scala
+++ b/compiler/src/dotty/tools/dotc/sbt/ExtractDependencies.scala
@@ -227,10 +227,12 @@ private class ExtractDependenciesCollector(rec: DependencyRecorder) extends tpd.
     }

     tree match {
-      case tree: Inlined if !tree.inlinedFromOuterScope =>
+      case tree: Inlined =>
         // The inlined call is normally ignored by TreeTraverser but we need to
         // record it as a dependency
-        traverse(tree.call)
+        if !tree.inlinedFromOuterScope then
+          traverse(tree.call)
+        traverseChildren(tree)
```

We can do some `println(...)` debugging to make sure that `Dep` class's constructor is captured:

```scala
traverse(Select(New(TypeTree[TypeRef(ThisType(TypeRef(NoPrefix,module class <empty>)),class Dep)]),<init>))
```

Since `Select(...)` is a member reference, it will be registered to Zinc. We can confirm this fix by publishing the `scala3-sbt-bridge-bootstrapped/publishLocalBin` etc locally, and running Oleg's test again using Scala 3.7.4-RC1-bin-SNAPSHOT:

```scala
[info] [error] -- Error: /private/var/.../Components.scala:5:16
[info] [error] 5 |    val d = wire[Dep]
[info] [error]   |            ^^^^^^^^^
[info] [error]   |            Cannot find a value of type: [Dep1]
[info] [warn] two warnings found
[info] [error] one error found
[info] [error] (Compile / compileIncremental) Compilation failed
```

This shows that the use site was correctly invalidated, and failed to compile (successfully).

### summary

Zinc needs to track the member-reference dependencies between Scala symbols to invalidate correct set of code for the incremental compilation.
The incremental compilation seems to have regressed in Scala 3, especially when macros are used. This could be explained by the fact that the dependency tracking happens in the Scala 3 compiler bridge prior to the macro expansion at the use site.

The diff discussed in this post is sent in as [scala/scala3#24171][24171], but likely it would require more tweaks to land it on the compiler. After sending the PR, I also noticed that Jan Chyb had sent in [scala/scala3#23900](https://github.com/scala/scala3/pull/23900).
