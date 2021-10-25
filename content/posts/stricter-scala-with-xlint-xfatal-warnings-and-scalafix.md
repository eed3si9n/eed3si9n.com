---
title:       "stricter Scala with -Xlint, -Xfatal-warnings, and Scalafix"
type:        story
date:        2018-09-20
changed:     2021-09-13
draft:       false
promote:     true
sticky:      false
url:         /stricter-scala-with-xlint-xfatal-warnings-and-scalafix
aliases:     [ /node/273, "/compile-or-not-compile" ]
tags:        [ "scala" ]
---

  [1]: http://eed3si9n.com/stricter-scala-with-ynolub

Compile, or compile not. There's no warning. Two of my favorite Scala compiler flags lately are `"-Xlint"` and `"-Xfatal-warnings"`.
Here is an example setting that can be used with subprojects:

```scala
ThisBuild / organization := "com.example"
ThisBuild / version      := "0.1.0-SNAPSHOT"
ThisBuild / scalaVersion := "2.12.6"

lazy val commonSettings = List(
  scalacOptions ++= Seq(
    "-encoding", "utf8",
    "-deprecation",
    "-unchecked",
    "-Xlint",
    "-feature",
    "-language:existentials",
    "-language:experimental.macros",
    "-language:higherKinds",
    "-language:implicitConversions",
    "-Ypartial-unification",
    "-Yrangepos",
  ),
  scalacOptions ++= (scalaVersion.value match {
    case VersionNumber(Seq(2, 12, _*), _, _) =>
      List("-Xfatal-warnings")
    case _ => Nil
  }),
  Compile / console / scalacOptions --= Seq("-deprecation", "-Xfatal-warnings", "-Xlint")
)

lazy val foo = (project in file("foo"))
  .settings(
    commonSettings,
    name := "foo",  
  )
```

### what's -Xlint?

`-Xlint` enables a bunch of compiler warnings. [@smogami](https://twitter.com/smogami) contributed a page called [Scala Compiler Options](https://docs.scala-lang.org/overviews/compiler-options/index.html#Warning_Settings) so we can now read what's in `-Xlint`.

One of them, for instance is `-Xlint:infer-any`, which warns when a type argument is inferred to be `Any`.

![contains](/images/compile-contains1.png)

### -Xfatal-warnings

The problem with warnings is that it often gets postponed and then it piles up. `-Xfatal-warnings` promotes the warnings to compiler error, so it cannot be ignored.

### suppress warnings with silencer

There are situations where warnings are unavoidable. For example, you might need to use a deprecated method for backward compatibility reason. It would be nice if we can suppress warnings for a specific expression.

In 2015 Roman Janusz ([@rjghik](https://twitter.com/rjghik)) wrote a compiler plugin called [silencer](https://github.com/ghik/silencer) that does exactly that.

<blockquote class="twitter-tweet" data-lang="en"><p lang="en" dir="ltr">Scala compiler plugin for warning suppression: <a href="https://t.co/iPT7AKDq1i">https://t.co/iPT7AKDq1i</a></p>&mdash; Roman Janusz (@rjghik) <a href="https://twitter.com/rjghik/status/588097382878949376?ref_src=twsrc%5Etfw">April 14, 2015</a></blockquote>

The usage looks like this:

```scala
import com.github.ghik.silencer.silent

@silent override lazy val ansiCodesSupported = delegate.ansiCodesSupported
```

This supresses all warnings for the definition.

### custom linting using Scalafix

[Scalafix](https://scalacenter.github.io/scalafix/) is a refactoring and linting tool created by Ólafur ([@olafurpg](https://twitter.com/olafurpg)) and others at Scala Center. As the name suggest, it's good at automated rewrite of code, but recently there's been more emphasis on using it for linting purpose.

Scalafix 0.8.0-RC1 that came out recently uses Scalameta 4 (well 4.0.0-RC1 to be specific):

<blockquote class="twitter-tweet" data-lang="en"><p lang="en" dir="ltr">Scalafix v0.8.0-RC1 is out with new documentation, improved sbt plugin, better semantic APIs, improved support for custom rules and more <a href="https://t.co/sEpy7U9diD">https://t.co/sEpy7U9diD</a></p>&mdash; Ólafur Páll Geirsson (@olafurpg) <a href="https://twitter.com/olafurpg/status/1042759375541161984?ref_src=twsrc%5Etfw">September 20, 2018</a>
</blockquote>

### scalafix-noinfer

Previous version of Scalafix shipped with a rule to suppress specific type inference called `NoInfer`. During recent development it got absorbed by another rule called `Disable`, which eventually got too complex to be included into Scalafix itself. Instead, Scalafix 0.8 seems to be pursuing the plugin ecosystem route.
Since [-Yno-lub][1] hasn't picked up traction, and I was looking forward to `Disable`.

So I implemented a Scalafix rule called [scalafix-noinfer](https://github.com/eed3si9n/scalafix-noinfer) myself. Here's how to use it.

#### project/build.properties

```bash
sbt.version=1.2.3
```

#### project/plugins.scala

```scala
addSbtPlugin("ch.epfl.scala" % "sbt-scalafix" % "0.8.0-RC1")
```

#### build.sbt

```scala
ThisBuild / organization := "com.example"
ThisBuild / version      := "0.1.0-SNAPSHOT"
ThisBuild / scalaVersion := "2.12.6"

// Scalafix plugin
ThisBuild / scalafixDependencies +=
  "com.eed3si9n.fix" %% "scalafix-noinfer" % "0.1.0-M1"

lazy val root = (project in file(".")).
  settings(
    name := "hello",
    addCompilerPlugin(scalafixSemanticdb),
    scalacOptions ++= List(
      "-Yrangepos",
      "-P:semanticdb:synthetics:on",

      // you can add the options from the above here too
    ),
    // Compile / scalacOptions += {
    //   val t = crossTarget.value / "meta"
    //   s"-P:semanticdb:targetroot:$t"
    // },
    // Test / scalacOptions += {
    //   val t = crossTarget.value / "test-meta"
    //   s"-P:semanticdb:targetroot:$t"
    // }
  )
```

#### .scalafix.conf

```bash
rules = [
  NoInfer
]
```

#### Main.scala

```scala
package example

case class Address()

object Main extends App {
  List(Animal()).contains("1")
}
```

#### scalafix-noinfer usage

From sbt shell type `scalafix`:

```bash
sbt:hello> scalafix
[info] Running scalafix on 2 Scala sources
[error] /Users/eed3si9n/work/quicktest/noinfer/Main.scala:7:3: error: [NoInfer.Serializable] Serializable was inferred, butit's forbidden by NoInfer
[error]   List(Animal()).contains("1")
[error]   ^^^^^^^^^^^^^^^^^^^^^^^
[error] (Compile / scalafix) scalafix.sbt.ScalafixFailed: LinterError
```

Yes! So now we have `NoInfer` rule that's catching bad type inference in `contains(...)`. In my opinion, it doesn't make sense for Scala to lub to `java.io.Serializable` since the list would never contain `"1"`.

By default this rule forbids the inference of `scala.Any`, `scala.AnyVal`, `java.io.Serializable`, `scala.Serializable`, and `scala.Product`. You can customize this using `.scalafix.conf` as follows:

```bash
rules = [
  NoInfer
]
NoInfer.disabledTypes = [
  scala.Any,
  scala.AnyVal,
  scala.Serializable,
  java.io.Serializable,
  scala.Product,
  scala.Predef.any2stringadd
]
```

Now this will catch `scala.Predef.any2stringadd`:

```bash
[info] Running scalafix on 2 Scala sources
[error] /Users/eed3si9n/work/quicktest/noinfer/Main.scala:8:3: error: [NoInfer.any2stringadd] any2stringadd was inferred, but it's forbidden by NoInfer
[error]   Option(1) + "what"
[error]   ^^^^^^^^^
[error] (Compile / scalafix) scalafix.sbt.ScalafixFailed: LinterError
```

#### challenges

First issue that I noticed is that I can't seem to move the `targetroot` of semanticdb. This means semanticdb will be shipped with your JAR if you use Scalafix with semantic rules. I should be able to opt out of this. Maybe I need to dig deeper to find out how.

scalafix-noinfer is a progress forward, and it's more usable than a forked Scala compiler, but it's not as thorough as [-Yno-lub][1].
For instance, it seems to be perfectly ok with the following:

```scala
object Main extends App {
  val x = if (true) 1 else false
  val y = 1 match { case 1 => Array(1); case n => Vector(n) }
}
```

### summary

1. `-Xlint` and `-Xfatal-warnings` provide stronger enforcement against common mistakes.
2. When we need to bail out some code, we can use `@silent` annotation.
3. Scalafix allows flexible linting that can be extended through custom rules.
