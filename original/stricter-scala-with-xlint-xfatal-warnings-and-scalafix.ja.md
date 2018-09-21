  [1]: http://eed3si9n.com/ja/stricter-scala-with-ynolub

コンパイルする、さもなければコンパイルしない。警告などいらない。最近気に入っている Scala コンパイラのフラグは `"-Xlint"` と `"-Xfatal-warnings"` の 2つだ。

以下は、サブプロジェクトと共に使えるセッティングの例だ:

<scala>
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
    "-language:implicitConversions"
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
</scala>

### -Xlint とは?

`-Xlint` は色々なコンパイル警告を追加する。[@smogami](https://twitter.com/smogami)さんが [Scala Compiler Options](https://docs.scala-lang.org/overviews/compiler-options/index.html#Warning_Settings) というページをコントリビュートしてくれたので `-Xlint` が何をやっているのかを読めるようになった。

発動する警告の一例として、型引数が `Any` に推論されると警告する `-Xlint:infer-any` というのがある。

![contains](/images/compile-contains1.png)

### -Xfatal-warnings

警告が問題なのは、だいたい後回しにされて山積みになってしまうことだ。`-Xfatal-warnings` は警告をコンパイル・エラーにするので無視できなくなる。

### silencer を用いた警告の抑制

ただし、警告を回避不可能な場合もある。例えば、後方互換性のために deprecated なメソッドを使う必要があるかもしれない。特定の式だけで警告を抑制できればいいと思う。

2015年に Roman Janusz ([@rjghik](https://twitter.com/rjghik)) さんが [silencer](https://github.com/ghik/silencer) というコンパイラ・プラグインを書いていて、まさに警告の抑制を行っている。

<blockquote class="twitter-tweet" data-lang="en"><p lang="en" dir="ltr">Scala compiler plugin for warning suppression: <a href="https://t.co/iPT7AKDq1i">https://t.co/iPT7AKDq1i</a></p>&mdash; Roman Janusz (@rjghik) <a href="https://twitter.com/rjghik/status/588097382878949376?ref_src=twsrc%5Etfw">April 14, 2015</a></blockquote>

用例はこんな感じになる:

<scala>
import com.github.ghik.silencer.silent

@silent override lazy val ansiCodesSupported = delegate.ansiCodesSupported
</scala>

これで、この val の定義だけで全ての警告が抑制される。

### Scalafix を用いたカスタム linting

[Scalafix](https://scalacenter.github.io/scalafix/) はリファクタリングや linting のためのツールで、Scala Center の Ólafur ([@olafurpg](https://twitter.com/olafurpg)) さんらが作っている。名前が示すとおり自動的なコードの書き換えを得意とするが、最近は linting の用途も強調してきている。

Scalafix 0.8.0-RC1 が最近出てきて、Scalameta 4 を使うようになった (正確には 4.0.0-RC1 みたいだが):

<blockquote class="twitter-tweet" data-lang="en"><p lang="en" dir="ltr">Scalafix v0.8.0-RC1 is out with new documentation, improved sbt plugin, better semantic APIs, improved support for custom rules and more <a href="https://t.co/sEpy7U9diD">https://t.co/sEpy7U9diD</a></p>&mdash; Ólafur Páll Geirsson (@olafurpg) <a href="https://twitter.com/olafurpg/status/1042759375541161984?ref_src=twsrc%5Etfw">September 20, 2018</a>
</blockquote>

### scalafix-noinfer

Scalafix 以前のバージョンには特定の型推論を抑制する `NoInfer` というルールが付いてきていた。最近の開発過程でこれは `Disable` という別のルールに取り込まれたが、それは複雑になりすぎて Scalafix 本体には含まれなくなってしまった。かわりに、Scalafix 0.8 はプラグインエコシステムを作る道を選ぶみたいだ。
[-Yno-lub][1] が刺さらなかったので、`Disable` を代わりに使うのを楽しみにしていた。

仕方がないので、[scalafix-noinfer](https://github.com/eed3si9n/scalafix-noinfer) という Scalafix ルールを自分で実装した。以下に使う方法を解説する。

#### project/build.properties

<code>
sbt.version=1.2.3
</code>

#### project/plugins.scala

<scala>
addSbtPlugin("ch.epfl.scala" % "sbt-scalafix" % "0.8.0-RC1")
</scala>

#### build.sbt

<scala>
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
</scala>

#### .scalafix.conf

<code>
rules = [
  NoInfer
]
</code>

#### Main.scala

<scala>
package example

case class Address()

object Main extends App {
  List(Animal()).contains("1")
}
</scala>

#### scalafix-noinfer usage

sbt シェルから `scalafix` と打ち込む:

<code>
sbt:hello> scalafix
[info] Running scalafix on 2 Scala sources
[error] /Users/eed3si9n/work/quicktest/noinfer/Main.scala:7:3: error: [NoInfer.Serializable] Serializable was inferred, butit's forbidden by NoInfer
[error]   List(Animal()).contains("1")
[error]   ^^^^^^^^^^^^^^^^^^^^^^^
[error] (Compile / scalafix) scalafix.sbt.ScalafixFailed: LinterError
</code>

できた! `contains(...)` の悪い型推論をキャッチする `NoInfer` というルールが作動した。僕の意見としては、リストは `"1"` を含むことはありえないので、このコードで Scala が `java.io.Serializable` に lub するのはダメだと思っている。

デフォルトでは、このルールは `scala.Any`, `scala.AnyVal`, `java.io.Serializable`, `scala.Serializable`, `scala.Product` への型推論を禁止する。これは `.scalafix.conf` を使ってカスタマイズできる:

<code>
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
</code>

これで `scala.Predef.any2stringadd` をキャッチできるようになった:

<code>
[info] Running scalafix on 2 Scala sources
[error] /Users/eed3si9n/work/quicktest/noinfer/Main.scala:8:3: error: [NoInfer.any2stringadd] any2stringadd was inferred, but it's forbidden by NoInfer
[error]   Option(1) + "what"
[error]   ^^^^^^^^^
[error] (Compile / scalafix) scalafix.sbt.ScalafixFailed: LinterError
</code>

#### 今後の課題

まず最初に気付いたのは semanticdb の `targetroot` を移動できないということだ。これは、Scalafix を semantic なルールと一緒に使う場合は、JAR に semanticdb が含まれることを意味する。これは、オプトアウトできるべきだ。もっと探せば可能な方法が分かるのかもしれない。

scalafix-noinfer は前向きな進歩であり、Scala コンパイラをフォークするよりも実用的なものだが、[-Yno-lub][1] よりカバーしている範囲が狭い。

例えば、以下のコードを問題無く通している:

<scala>
object Main extends App {
  val x = if (true) 1 else false
  val y = 1 match { case 1 => Array(1); case n => Vector(n) }
}
</scala>

### まとめ

1. `-Xlint` と `-Xfatal-warnings` を併用してよくある間違いを取り締まることができる。
2. 何らかのコードだけを除外したい場合は `@silent` アノテーションを使う。
3. Scalafix は、カスタムルールによって拡張できる柔軟な linting を可能とする。
