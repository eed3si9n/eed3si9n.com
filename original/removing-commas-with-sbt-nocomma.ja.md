  [1]: https://gitter.im/scala/slip?at=57abcaf6d7087a017faa822a
  [@Ichoran]: https://github.com/Ichoran
  [@swachter]: https://github.com/swachter
  [comma]: https://contributors.scala-lang.org/t/comma-inference/1521

### 2016年8月

[SIP-27 末尾のカンマ (trailing commas)](https://github.com/scala/docs.scala-lang/pull/533) に関するディスカッションのときに思いついたのは一部のカンマの用法をセミコロンと統一できれば、セミコロン推論を流用することができるんじゃないかということだ。

[Aug 10 2016 20:46][1]:

<img src='/images/nocomma1.png' alt="it might be interesting to consider allowing semicolons as vararg separator, and thereby allowing them to be infered as @Ichoran is suggesting">

特に可変長引数 (vararg) の区切り文字としてセミコロンを許せば便利そうだ。しかし、実際にはそれはうまくいかない。[@Ichoran][@Ichoran] さんが具体例を用いて指摘してくれた:

<scala>
Seq(
  a
  b
  c
)
</scala>

これは現状の Scala では `Seq(a.b(c))` と解釈される。

### 2018年1月

最近 [@swachter][@swachter] さんが [Comma inference][comma] というスレッドを立てたので、再びこの話題のことを思い出した。

> Scala には「セミコロン推論」というよく知られた機構があるが、パラメータや引数のリストに同様の機構を「コンマ推論」として導入できれば便利ではないだろうか。

僕のこれに対する返答は:

> Scala (言語仕様としても我々ユーザとしても) は 1つ以上の句読点推論を取り扱うのは難しいと思うが、試す価値のあるトリックはあるかもしれない。
>
> パーサーを通過する必要があるので、Scala として合法な「形」(shape) がまず必要になる。例えば、

<scala>
scala> List({
       1
       2
       3
       })
res1: List[Int] = List(3)
</scala>

> 以上は合法な Scala だ。中括弧はコンパイラの中では `Block` データ型としてパースされる。可変長 `Int*` の引数を受け取って、もし `Block` が渡された場合には各ステートメントを展開するマクロを定義することは可能かもしれない。

つまり、言語の変更を目指すかわりに、構文木の書き換えを試してみることを提案したい。ブロック `{ ... }` を使うことで Rex さんが指摘してくれた問題も回避できる。

<scala>
scala> :paste
// Entering paste mode (ctrl-D to finish)

class A { def b(c: Int) = c + 1 }
lazy val a = new A
lazy val b = 2
lazy val c = 3

// Exiting paste mode, now interpreting.

defined class A
a: A = <lazy>
b: Int = <lazy>
c: Int = <lazy>

scala> Seq(
         a
         b
         c
       )
res0: Seq[Int] = List(4)

scala> Seq({
         a
         b
         c
       })
res1: Seq[Int] = List(3)
</scala>

最初のものは `a.b(c)` と解釈されるが、2番目のものは `a; b; c` となる。

### 汎用的なコンマの消去

さっそく `{ ... }` を `Vector` に変換するマクロを実装してみよう。これはジェネリックなバージョンだ:

<scala>
package example

import scala.language.experimental.macros
import scala.reflect.macros.blackbox.Context

object NoComma {
  def nocomma[A](a: A): Vector[A] = macro nocommaImpl[A]

  def nocommaImpl[A: c.WeakTypeTag](c: Context)(a: c.Expr[A]) : c.Expr[Vector[A]] = {
    import c.universe._
    val items: List[Tree] = a.tree match {
      case Block(stats, x) => stats ::: List(x)
      case x               => List(x)
    }
    c.Expr[Vector[A]](
      Apply(Select(reify(Vector).tree, TermName("apply")), items))
  }
}
</scala>

以下の様に使うことができる:

<scala>
scala> import example.NoComma.nocomma
import example.NoComma.nocomma

scala> :paste
// Entering paste mode (ctrl-D to finish)

lazy val a = 1
lazy val b = 2
lazy val c = 3

// Exiting paste mode, now interpreting.

a: Int = <lazy>
b: Int = <lazy>
c: Int = <lazy>

scala> nocomma {
         a
         b
         c
       }
res0: Vector[Int] = Vector(1, 2, 3)
</scala>

型推論により自動的に最後の要素 `c` の型、つまり `Int` が選ばれる。用法によっては、これで十分な場合とそうじゃない場合がある。

### build.sbt からのカンマの消去

bare build.sbt 記法で良かったなと思うことがあって、それは末尾にいちいちカンマを書かなくてもいいことだ:

    name := "something"
    version := "0.1.0"

以下のようにして `nocomma` マクロを `Setting[_]` 専用に決め打ちする:

<scala>
package sbtnocomma

import sbt._
import scala.language.experimental.macros
import scala.reflect.macros.blackbox.Context

object NoComma {
  def nocomma(a: Setting[_]): Vector[Setting[_]] = macro nocommaImpl

  def nocommaImpl(c: Context)(a: c.Expr[Setting[_]]) : c.Expr[Vector[Setting[_]]] = {
    import c.universe._
    val items: List[Tree] = a.tree match {
      case Block(stats, x) => stats ::: List(x)
      case x               => List(x)
    }
    c.Expr[Vector[Setting[_]]](
      Apply(Select(reify(Vector).tree, TermName("apply")), items))
  }
}
</scala>

これを sbt-nocomma として公開したので、このマクロは以下のように使うことができる:

<scala>
import Dependencies._

ThisBuild / organization := "com.example"
ThisBuild / scalaVersion := "2.12.7"
ThisBuild / version      := "0.1.0-SNAPSHOT"

lazy val root = (project in file("."))
  .settings(nocomma {
    name := "Hello"

    // comment works
    libraryDependencies += scalaTest % Test

    scalacOptions ++= List(
      "-encoding", "utf8", "-deprecation", "-unchecked", "-Xlint"
    )
    Compile / scalacOptions += "-Xfatal-warnings"
    Compile / console / scalacOptions --= Seq("-deprecation", "-Xfatal-warnings", "-Xlint")
  })
</scala>

`Setting[_]` に決め打ちしたおかげで、例えば `println(...)` みたいなものがまぎれ込んでも読み込み時にキャッチできる:

<code>
/Users/xxx/hello/build.sbt:14: error: type mismatch;
 found   : Unit
 required: sbt.Setting[?]
    (which expands to)  sbt.Def.Setting[?]
    println("hello")
           ^
[error] sbt.compiler.EvalException: Type error in expression
[error] sbt.compiler.EvalException: Type error in expression
[error] Use 'last' for the full log.
Project loading failed: (r)etry, (q)uit, (l)ast, or (i)gnore?
</code>

### セットアップ

試してみたい人は、sbt 1.x を使って `project/plugins.sbt` に以下を追加する:

<scala>
addSbtPlugin("com.eed3si9n" % "sbt-nocomma" % "0.1.0")
</scala>
