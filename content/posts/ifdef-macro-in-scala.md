---
title:       "ifdef macro in Scala"
type:        story
date:        2023-10-12
url:         /ifdef-macro-in-scala
tags:        [ "scala" ]
---

**Update 2023-10-15**: There's now a better 0.2.0 that I implemented via [pre-typer processing](/ifdef-in-scala-via-pre-typer-processing/).

Rust has an interesting feature called `cfg` attribute, which is aware of the build configuration at the language level. This lets us write unit test in the same source as the library code like this:

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

I implemented an **experimental** `@ifdef` macro that does something similar.

<!--more-->

```scala
import com.eed3si9n.ifdef.ifdef

class A {
  def foo: Int = 42
}

@ifdef("test")
class ATest extends munit.FunSuite {
  test("hello") {
    val actual = new A().foo
    val expected = 43
    assertEquals(actual, expected)
  }
}
```

### prior discussions

Back in 2019, Stefan Zeiger wrote up [scala-dev#640](https://github.com/scala/scala-dev/issues/640) and [a SIP draft](https://github.com/scala/docs.scala-lang/pull/1541), but it sort of got killed in immediate feedback from the community before it could take off. Some of the criticisms were that it might break IDEs, or it might increase the cognitive load.

It's possible that those feedback would still apply. But personally, if we limit to just writing test in the same source, it feels like a doable idea.

### prior works: enableIf.scala

Update: Back in 2016 Atry (Yang Bo) has implemented [ThoughtWorksInc/enableIf.scala](https://github.com/ThoughtWorksInc/enableIf.scala). Thanks Yoshida-san for the ping.

```scala
import com.thoughtworks.enableIf

@enableIf(scala.util.Properties.versionNumberString.startsWith("2.10."))
implicit class FlatMapForTailRec[A](underlying: TailRec[A]) {
  final def flatMap[B](f: A => TailRec[B]): TailRec[B] = {
    tailcall(f(underlying.result))
  }
}
```

This seems to cover cross build usages, and more.

## details

### macro annotation

In short `@ifdef(...)` is a macro annotation that annotates class definitions. During the `Compile` compilation, it will try to blank out the class definition, and during the `Test` compilation, it will keep the class.

```scala
object IfDefMacro {
  private final val macroSetting = "com.eed3si9n.ifdef.declare:"
  def impl(c: whitebox.Context)(annottees: c.Expr[Any]*): c.Expr[Any] = {
    import c.universe._
    ....
    val arg = extractAnnotationArg(c.macroApplication)
    annottees.map(_.tree) match {
      case (decl: ClassDef) :: Nil =>
        if (keys(arg)) c.Expr(decl)
        else {
          val className = extractClassName(decl)
          c.Expr(q"""
            private class $className
          """)
        }
      case _ => c.abort(c.enclosingPosition, "invalid annottee")
    }
  }
}
```

### passing information to the macro

To drive the logic, we need to somehow pass information to the running macro during compilation. We can do this using `-Xmacro-settings` scalac options, so I wrote an sbt plugin that will pass `test` during `Test` compilation:

```scala
Test / ifDefDeclations += "test",
Test / scalacOptions ++= {
  val sv = scalaVersion.value
  val decls = (Test / ifDefDeclations).value
  toMacroSettings(sv, decls.toList)
},

....

  def toMacroSettings(sv: String, decls: List[String]): List[String] = {
    if (sv.startsWith("2."))
      decls.flatMap { decl =>
        List("-Xmacro-settings", s"$macroSetting$decl")
      }
    else
      decls.flatMap { decl =>
        List(s"-Xmacro-settings:$macroSetting$decl")
      }
  }
```

and we can pick this up at the macro side as follows:

```scala
val keys = (c.settings.collect {
  case x if x.startsWith(macroSetting) => x.drop(macroSetting.size)
}).toSet
```

and in Scala 3:

```scala
val keys = (CompilationInfo.XmacroSettings.collect:
  case x if x.startsWith(macroSetting) => x.drop(macroSetting.size)
).toSet
```

### demo (Scala 2.13)

Here's the demo of the initial snippet that I showed.

```bash
sbt:ifdef root> app/compile
[info] compiling 1 Scala source to ifdef/app/target/scala-2.13/classes ...
[success] Total time: 2 s
sbt:ifdef root> app/test
[info] compiling 1 Scala source to ifdef/app/target/scala-2.13/test-classes ...
ATest:
==> X ATest.hello  0.059s munit.ComparisonFailException: /Users/eed3si9n/work/ifdef/app/app.scala:14
13:    val expected = 43
14:    assertEquals(actual, expected)
15:  }
values are not the same
=> Obtained
42
=> Diff (- obtained, + expected)
-42
+43
    at munit.FunSuite.assertEquals(FunSuite.scala:11)
    at ATest.$anonfun$new$1(app.scala:14)
[error] Failed: Total 1, Failed 1, Errors 0, Passed 0
[error] Failed tests:
[error]   ATest
[error] (app / Test / test) sbt.TestsFailedException: Tests unsuccessful
[error] Total time: 2 s
```

Next, we want to verify that `ATest.class` is blanked out:

```java
$ javap -cp app/target/scala-2.13/classes ATest
Compiled from "app.scala"
public class ATest {
  public ATest();
}
```

It seems like `private` didn't actually work here.

### demo (Scala 3)

I've also tried to implement equivalent macro annotation in Scala 3. Macro annotation in general is still experimental, but it's good to excercise it while it's active. First, the macro seems to run after the typer, so you need to add the test dependencies as `Provided`, which is not great.

```scala
libraryDependencies += "org.scalameta" %% "munit" % "0.7.29" % Provided,
```

There's also something weird with the generated bytecode:

```java
$ javap -cp app/target/scala-3.4.0-RC1-bin-20231010-7dc9798-NIGHTLY/classes/ example.ATest
Compiled from "app.scala"
public class example.ATest extends munit.FunSuite {
  public example.ATest();
}
```

Note the `extends munit.FunSuite` on the Compile configuration's `ATest`. Not something I expected, and I'm guessing it's a bug, or I did something wrong.

Update: I've filed [dotty#18677](https://github.com/lampepfl/dotty/issues/18677). Jamie replied:

> I think in this case the tree doesn't matter because the class symbol never changed

Nicolas agreed:

> @bishabosha is correct.
>
> Nevertheless, in this case, there might be an argument to be made to allow the addition of parents in the same way we can add new methods to that class. Such an addition to the spec would need to be examined in detail. This is probably not something that would be available in the first iteration of macro annotation but added later as an extension to the spec.

### discussion

Set aside some of the details, I think being able to write test in the same source is good.

Given the current limitation of leaving `ATest` classes in the `Compile` JAR etc, I'd caution against using it for public libraries, but this might be acceptable for in-house usages.

I haven't tried, but this general mechanism probably could be extended to support cross building on the same source as well, which I think was more controvertial usage. By supporting only `class` to be annotated with `@ifdef`, hopefully we can keep it not too messy.

### setup

Put this in `project/plugins.sbt`:

```scala
addSbtPlugin("com.eed3si9n.ifdef" % "sbt-ifdef" % "0.1.0")
```

Source is available at https://github.com/eed3si9n/ifdef

**Update 2023-10-15**: There's now a better 0.2.0 that I implemented via [pre-typer processing](/ifdef-in-scala-via-pre-typer-processing/). Please try that instead.

## summary

- `@ifdef` is an **experimental** macro that implements conditional compilation.
- It kind of works in Scala 2.x, but the test class would leak to the product JARs as public classes due to the limitation of macro annotation.
- It's worse in Scala 3.x where parent class reference to `munit` etc is left behind.
- At this point, it's not recommended for public libraries, but in-house usages might be ok.
