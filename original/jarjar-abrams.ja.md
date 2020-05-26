[Jar Jar Abrams](https://github.com/eed3si9n/jarjar-abrams) は、Java ライブラリをシェーディングするユーティリティである Jar Jar Links の**実験的** Scala 拡張だ。

ライブラリ作者にとって他のライブラリは諸刃の剣だ。他のライブラリを使うことは作業の二重化を避け、他のライブラリを使いたくないというのはダブルスタンダードと言われかねない。しかし、その一方で、ライブラリを追加する度にそれはユーザ側にすると間接的依存性が追加されたことになり、衝突が起こる可能性も上がることになる。これは単一のプログラム内において 1つのバージョンのライブラリしか持てないことにもよる。

このような衝突はプログラムがランタイムやフレームワーク上で実行される場合によく起こる。sbt プラグインがその例だ。Spark もそう。1つの緩和策として間接的ライブラリを自分のパッケージの中にシェーディングするという方法がある。2004年に herbyderby (Chris Nokleberg) さんは [Jar Jar Links](https://code.google.com/archive/p/jarjar/) というライブラリを再パッケージ化するツールを作った。

2015年に Wu Xiang さんが Jar Jar Links を使ったシェーディングのサポートを [sbt-assembly](https://github.com/sbt/sbt-assembly) に[追加](https://github.com/sbt/sbt-assembly/pull/162)した。これは前向きな一歩だったが、課題も残っていた。問題の 1つは Scala コンパイラは ScalaSignature 情報を `*.class` ファイルに埋め込むが、Jar Jar がそのことを知らないことだ。2020年になって [Simacan](https://simacan.com/)社の Jeroen ter Voorde さんが ScalaSignature の変換を [sbt-assembly#393](https://github.com/sbt/sbt-assembly/pull/393) にて実装した。sbt 以外でもこれは役に立つかもしれないので、独立したライブラリに抜き出した。これが Jar Jar Abrams だ。

### core API

コアには `shadeDirectory` 関数を実装する `Shader` オブジェクトがある。

<scala>
package com.eed3si9n.jarjarabrams

object Shader {
  def shadeDirectory(
      rules: Seq[ShadeRule],
      dir: Path,
      mappings: Seq[(Path, String)],
      verbose: Boolean
  ): Unit = ...
}
</scala>

この関数は、`dir` が JAR ファイルを展開したディレクトリであることを期待する。

### sbt-jarjar-abrams

用例のデモとして、1つのライブラリづつシェーディングする sbt プラグインを作った。

以下を `project/plugins.sbt` に追加する:

<scala>
addSbtPlugin("com.eed3si9n.jarjarabrams" % "sbt-jarjar-abrams" % "0.1.0")
</scala>

`build.sbt` はこのようになる:

<scala>
ThisBuild / version := "0.1.0-SNAPSHOT"
ThisBuild / organization := "com.example"
ThisBuild / scalaVersion := "2.12.11"

lazy val shadedJawn = project
  .enablePlugins(JarjarAbramsPlugin)
  .settings(
    name := "shaded-jawn",
    jarjarLibraryDependency := "org.typelevel" %% "jawn-parser" % "1.0.0",
    jarjarShadeRules += ShadeRuleBuilder.moveUnder("org.typelevel", "shaded")
  )

lazy val use = project
  .dependsOn(shadedJawn)
</scala>

jawn-parser は `shaded` パッケージ以下にシェーディングされた。REPL を使って確認できる:

<scala>
sbt:jarjar> use/console
[info] Starting scala interpreter...
Welcome to Scala 2.12.11 (OpenJDK 64-Bit Server VM, Java 1.8.0_232).
Type in expressions for evaluation. Or try :help.

scala> shaded.org.typelevel.jawn.Facade
res0: shaded.org.typelevel.jawn.Facade.type = shaded.org.typelevel.jawn.Facade$@131cedd
</scala>

元の依存性グラフを真似することで複数のシェーディングライブラリを積み上げることも可能だ:

<scala>
ThisBuild / organization := "com.example"
ThisBuild / scalaVersion := "2.12.11"

lazy val shadedJawn = project
  .enablePlugins(JarjarAbramsPlugin)
  .settings(
    name := "shaded-jawn",
    jarjarLibraryDependency := "org.typelevel" %% "jawn-parser" % "1.0.0",
    jarjarShadeRules += ShadeRuleBuilder.moveUnder("org.typelevel", "shaded")
  )

lazy val shadedJawnAst = project
  .enablePlugins(JarjarAbramsPlugin)
  .dependsOn(shadedJawn)
  .settings(
    name := "shaded-jawn-ast",
    jarjarLibraryDependency := "org.typelevel" %% "jawn-ast" % "1.0.0",
    jarjarShadeRules += ShadeRuleBuilder.moveUnder("org.typelevel", "shaded")
  )

lazy val use = project
  .dependsOn(shadedJawnAst)
</scala>

REPL から使ってみる:

<scala>
sbt:jarjar> use/console
[info] Starting scala interpreter...
Welcome to Scala 2.12.11 (OpenJDK 64-Bit Server VM, Java 1.8.0_232).
Type in expressions for evaluation. Or try :help.

scala> shaded.org.typelevel.jawn.ast.JParser.parseUnsafe("""{ "x": 10 }""")
res0: shaded.org.typelevel.jawn.ast.JValue = {"x":10}
</scala>

### 自己責任

もう一度注意しておきたいのは、これは実験的であるということだ。多くのライブラリは config ファイルなどの Jar Jar Abrams が変換しない実行時の振る舞いに依存する。

これを使って sbt の間接的ライブラリをシェーディングで追い出すことで sbt プラグイン作者が自由に別のバージョンを選べるようになるので、うまくいけば良いなと思っている。
