  [starlark]: https://github.com/bazelbuild/starlark
  [buildozer]: https://github.com/bazelbuild/buildtools/tree/master/buildozer

[Starlark][starlark] is a dialect of Python, originally designed as a configuration language for the Bazel build tool. Currently there are implementations in Go, Java, and Rust. As far as I know, the main Java implementation of Starlark has only been available as Bazel's source repo on GitHub.

Since it would be convenient to have a binary distribution, I've forked the repo, and published it as `"com.eed3si9n.starlark" % "starlark" % "4.2.1"` (`com.eed3si9n.starlark:starlark:4.2.1`) on Maven Central. The code is the same as Bazel 4.2.1.

### Starlark in the context of Bazel

Every build tool has a configuration language to set up the build definitons, like `Makefile` for make, `pom.xml` for Maven, `Rakefile` in Rake, and `build.sbt` for sbt. In Bazel, the targets are defined in a `BUILD` file using Starlark.

<code>
java_binary(
    name = "hello-bin",
    main_class = "com.example.Greeter",
    deps = [":hello-lib"],
)

java_library(
    name = "hello-lib",
    srcs = ["Greeter.java"],
)
</code>

In the above, what looks to be functions calls to `java_binary(...)` and `java_library(...)` represent targets, equivalent to a module or a subproject in other build tools. In addition to defining the targets, I could also declare some variables:

<code>
HELLO = "hello"

KAFKA_CROSS = [
  {"kafka": "2.6"},
  {"kafka": "2.7"},
  {"kafka": "2.8"},
  {"kafka": "3.0"},
]

java_binary(
    name = HELLO + "-bin",
    main_class = "com.example.Greeter",
    deps = [":hello-lib"],
)

java_library(
    name = HELLO + "-lib",
    srcs = ["Greeter.java"],
)
</code>

In that sense, at first Bazel may appear to be on the spectrum of Rake or sbt where build files are given the full power of a programming language. In sbt, the `build.sbt` language still have the access to the full classpath of the metabuild as well as the `sbt.IO` library. This allows the users to perform whatever side effect they want from a task or even a setting definition.

On the other hand, Starlark is not Python, and it does not come with the Python standard library. So in a sense, we can think of Starlark as Python minus the fabled included battery. In that sense, the actual `BUILD` files in Bazel behaves much closer to a declarative build defition like `pom.xml`, but with more human-readable syntax.

Also because the surface area of the `BUILD` syntax is relatively limited, it's common to manipulate the `BUILD` programmatically using a tool called [buildozer][buildozer].

### Making a Starlark-based DSL

Let's look into how we can define a Starlark-based DSL. This could be for Bazel-adjacent tooling (processing subset of `BUILD` files programmatically) or something like describing CI/CD process like GitHub Actions. As an example we will define `foo_binary` and `foo_library`.


#### build.sbt

<scala>
ThisBuild / scalaVersion := "2.13.6"
ThisBuild / version      := "0.1.0-SNAPSHOT"

val deps = new {
  val starlark = "com.eed3si9n.starlark" % "starlark" % "4.2.1"
}

lazy val root = (project in file("."))
  .settings(
    name := "starlark-example",
    libraryDependencies ++= List(deps.starlark),
  )
</scala>

#### Main.scala

As the example code I'll use Scala 2.13 here, but it should look similar in any JVM language. For Java, substitute `Unit` with `void`, and `AnyRef` with `Object`.

<scala>
package example

import com.google.common.collect.ImmutableMap
import net.starlark.java.annot.{ Param, StarlarkMethod }
import net.starlark.java.eval.{
  Module,
  Mutability,
  Starlark,
  StarlarkInt,
  StarlarkList,
  StarlarkSemantics,
  StarlarkThread,
}
import net.starlark.java.syntax.{ FileOptions, ParserInput }

object Main extends App {
  if (args.size < 1) {
    println("run BUILD.example")
    sys.exit(1)
  }
  val fileName = args(0)
  val input = ParserInput.readFile(fileName)
  val env = makeEnvironment
  val module = Module.withPredeclared(StarlarkSemantics.DEFAULT, env)
  withMutability(input.getFile) { mu =>
    val thread = new StarlarkThread(mu, StarlarkSemantics.DEFAULT)
    Starlark.execFile(input, FileOptions.DEFAULT, module, thread)
  }

  println(module.getGlobal("CALC"))

  // close mutability to freeze the values
  def withMutability(fileName: String)(f: Mutability => Unit): Unit = {
    val mu = Mutability.create(fileName)
    try {
      f(mu)
    } finally {
      mu.close()
    }
  }

  def makeEnvironment: ImmutableMap[String, AnyRef] = {
    val env = ImmutableMap.builder[String, AnyRef]()
    Starlark.addMethods(env, new Functions(), StarlarkSemantics.DEFAULT)
    env.build()
  }
}

class Functions {
  @StarlarkMethod(
      name = "foo_library",
      parameters = Array(
        new Param(name = "name", named = true),
        new Param(name = "srcs", named = true, defaultValue = "[]"),
        new Param(name = "deps", named = true, defaultValue = "[]"),
      ),
      doc = "Defines a foo_library target.")
  def fooLibrary(name: String, srcs: StarlarkList[String], deps: StarlarkList[String]): Unit = ()

  @StarlarkMethod(
      name = "foo_binary",
      parameters = Array(
        new Param(name = "name", named = true),
        new Param(name = "main_class", named = true),
        new Param(name = "srcs", named = true, defaultValue = "[]"),
        new Param(name = "deps", named = true, defaultValue = "[]"),
      ),
      doc = "Defines a foo_library target.")
  def fooBinary(name: String, main_class: String, srcs: StarlarkList[String], deps: StarlarkList[String]): Unit = ()
}
</scala>

#### BUILD.example

Now we can interpret a `BUILD.example` file:

<code>
HELLO = "hello"

KAFKA_CROSS = [
  {"kafka": "2.6"},
  {"kafka": "2.7"},
  {"kafka": "2.8"},
  {"kafka": "3.0"},
]

CALC = 1 + 1

foo_binary(
    name = HELLO + "-bin",
    main_class = "com.example.Greeter",
)

foo_library(
    name = HELLO + "-lib",
)
</code>

Now if you type `run BUILD.example` from the sbt shell, you should see:

<code>
sbt:starlark-example> run BUILD.example
[info] compiling 1 Scala source to /Users/eed3si9n/work/starlark-example/target/scala-2.13/classes ...
[info] running example.Main BUILD.example
2
</code>

This is because we're looking to see if there's been a variable named `CALC`:

<scala>
  println(module.getGlobal("CALC"))
</scala>

In other words, we've just calculated `1 + 1` using Starlark.

### Collect build definition as a side effect

Since we're interested in `foo_library` than the result of `CALC`, let's collect them as a side effect of the function bindings.

<scala>
package example

import com.google.common.collect.ImmutableMap
import net.starlark.java.annot.{ Param, StarlarkMethod }
import net.starlark.java.eval.{
  Module,
  Mutability,
  Starlark,
  StarlarkInt,
  StarlarkList,
  StarlarkSemantics,
  StarlarkThread,
}
import net.starlark.java.syntax.{ FileOptions, ParserInput }
import scala.collection.mutable.ListBuffer

object Main extends App {
  if (args.size < 1) {
    println("run BUILD.example")
    sys.exit(1)
  }
  val fileName = args(0)
  val input = ParserInput.readFile(fileName)
  val buf = ListBuffer.empty[Definition]
  val env = makeEnvironment(buf)
  val module = Module.withPredeclared(StarlarkSemantics.DEFAULT, env)
  withMutability(input.getFile) { mu =>
    val thread = new StarlarkThread(mu, StarlarkSemantics.DEFAULT)
    Starlark.execFile(input, FileOptions.DEFAULT, module, thread)
  }
  val defs = buf.toList
  println(defs.mkString("\n"))

  // close mutability to freeze the values
  def withMutability(fileName: String)(f: Mutability => Unit): Unit = {
    val mu = Mutability.create(fileName)
    try {
      f(mu)
    } finally {
      mu.close()
    }
  }

  def makeEnvironment(buf: ListBuffer[Definition]): ImmutableMap[String, AnyRef] = {
    val env = ImmutableMap.builder[String, AnyRef]()
    Starlark.addMethods(env, new Functions(buf), StarlarkSemantics.DEFAULT)
    env.build()
  }
}

sealed trait Definition
object Definition {
  case class FooLibraryDef(
    name: String,
    srcs: List[String],
    deps: List[String]) extends Definition
  case class FooBinaryDef(
    name: String,
    main_class: String,
    srcs: List[String],
    deps: List[String]) extends Definition  
}

class Functions(buf: ListBuffer[Definition]) {
  @StarlarkMethod(
      name = "foo_library",
      parameters = Array(
        new Param(name = "name", named = true),
        new Param(name = "srcs", named = true, defaultValue = "[]"),
        new Param(name = "deps", named = true, defaultValue = "[]"),
      ),
      doc = "Defines a foo_library target.")
  def fooLibrary(name: String, srcs: StarlarkList[String], deps: StarlarkList[String]): Unit =
    buf += Definition.FooLibraryDef(
      name = name,
      srcs = srcs.toArray.toList.asInstanceOf[List[String]],
      deps = deps.toArray.toList.asInstanceOf[List[String]],
    )

  @StarlarkMethod(
      name = "foo_binary",
      parameters = Array(
        new Param(name = "name", named = true),
        new Param(name = "main_class", named = true),
        new Param(name = "srcs", named = true, defaultValue = "[]"),
        new Param(name = "deps", named = true, defaultValue = "[]"),
      ),
      doc = "Defines a foo_library target.")
  def fooBinary(name: String, main_class: String, srcs: StarlarkList[String], deps: StarlarkList[String]): Unit =
    buf += Definition.FooBinaryDef(
      name = name,
      main_class = main_class,
      srcs = srcs.toArray.toList.asInstanceOf[List[String]],
      deps = deps.toArray.toList.asInstanceOf[List[String]],
    )
}
</scala>

Now if you `run BUILD.example`, you should see the following output:

<scala>
sbt:starlark-example> run BUILD.example
[info] compiling 1 Scala source to /Users/eed3si9n/work/starlark-example/target/scala-2.13/classes ...
[info] running example.Main BUILD.example
FooBinaryDef(hello-bin,com.example.Greeter,List(),List())
FooLibraryDef(hello-lib,List(),List())
</scala>

What you do with this collected information is up to the application.

### Checking the typo

Let's say there's a typo in the `BUILD.example` file. Let's see how Starlark handles that. We can mispell `name` as `nam` or something:

<code>
foo_library(
    nam = HELLO + "-lib",
)
</code>

Here's the output:

<scala>
sbt:starlark-example> run BUILD.example
[info] running example.Main BUILD.example
[error] (run-main-30) Traceback (most recent call last):
[error]   File "BUILD.example", line 17, column 12, in <toplevel>
[error]     foo_library(
[error] Error in foo_library: foo_library() got unexpected keyword argument 'nam' (did you mean 'name'?)
[error] Traceback (most recent call last):
[error]   File "BUILD.example", line 17, column 12, in <toplevel>
[error]     foo_library(
[error] Error in foo_library: foo_library() got unexpected keyword argument 'nam' (did you mean 'name'?)
[error]   at net.starlark.java.eval.Starlark.errorf(Starlark.java:652)
[error]   at net.starlark.java.eval.BuiltinFunction.getArgumentVector(BuiltinFunction.java:227)
[error]   at net.starlark.java.eval.BuiltinFunction.fastcall(BuiltinFunction.java:76)
[error]   at net.starlark.java.eval.Starlark.fastcall(Starlark.java:606)
[error]   at net.starlark.java.eval.Eval.evalCall(Eval.java:641)
[error]   at net.starlark.java.eval.Eval.eval(Eval.java:460)
[error]   at net.starlark.java.eval.Eval.execReturn(Eval.java:242)
[error]   at net.starlark.java.eval.Eval.exec(Eval.java:279)
[error]   at net.starlark.java.eval.Eval.execStatements(Eval.java:81)
[error]   at net.starlark.java.eval.Eval.execFunctionBody(Eval.java:65)
[error]   at net.starlark.java.eval.StarlarkFunction.fastcall(StarlarkFunction.java:160)
[error]   at net.starlark.java.eval.Starlark.fastcall(Starlark.java:606)
[error]   at net.starlark.java.eval.Starlark.execFileProgram(Starlark.java:863)
[error]   at net.starlark.java.eval.Starlark.execFile(Starlark.java:835)
[error]   at example.Main$.$anonfun$new$1(Main.scala:29)
[error]   at example.Main$.$anonfun$new$1$adapted(Main.scala:27)
[error]   at example.Main$.withMutability(Main.scala:38)
[error]   at example.Main$.delayedEndpoint$example$Main$1(Main.scala:27)
[error]   at example.Main$delayedInit$body.apply(Main.scala:17)
[error]   at scala.Function0.apply$mcV$sp(Function0.scala:39)
[error]   at scala.Function0.apply$mcV$sp$(Function0.scala:39)
[error]   at scala.runtime.AbstractFunction0.apply$mcV$sp(AbstractFunction0.scala:17)
[error]   at scala.App.$anonfun$main$1(App.scala:76)
[error]   at scala.App.$anonfun$main$1$adapted(App.scala:76)
[error]   at scala.collection.IterableOnceOps.foreach(IterableOnce.scala:563)
[error]   at scala.collection.IterableOnceOps.foreach$(IterableOnce.scala:561)
[error]   at scala.collection.AbstractIterable.foreach(Iterable.scala:919)
[error]   at scala.App.main(App.scala:76)
[error]   at scala.App.main$(App.scala:74)
[error]   at example.Main$.main(Main.scala:17)
[error]   at example.Main.main(Main.scala)
[error]   at sun.reflect.NativeMethodAccessorImpl.invoke0(Native Method)
[error]   at sun.reflect.NativeMethodAccessorImpl.invoke(NativeMethodAccessorImpl.java:62)
[error]   at sun.reflect.DelegatingMethodAccessorImpl.invoke(DelegatingMethodAccessorImpl.java:43)
[error]   at java.lang.reflect.Method.invoke(Method.java:498)
</scala>

The stacktrace is showing up beause we're not handling the exception, but the syntax error of Starlark portion is pretty good. "(did you mean 'name'?)" for a named parameter is something not even Scala 3 would offer:

<scala>
scala> List(1, 2, 3).contains(elen = 1)
-- Error:
1 |List(1, 2, 3).contains(elen = 1)
  |                       ^^^^^^^^
  |method contains in class List: (elem: A1): Boolean does not have a parameter elen
</scala>

### Summary

- Starlark is a is a dialect of Python, designed as a configuration language for Bazel.
- Starlark 4.2.1 is available on Maven Central, and can be used from Scala or Java to create a custom DSL with typo checks but no other side effects.
