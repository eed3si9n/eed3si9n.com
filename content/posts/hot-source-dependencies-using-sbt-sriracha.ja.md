---
title:       "sbt-sriracha を用いたホットなソース依存"
type:        story
date:        2018-05-20
changed:     2019-04-06
draft:       false
promote:     true
sticky:      false
url:         /ja/hot-source-dependencies-using-sbt-sriracha
aliases:     [ /node/261 ]
tags:        [ "sbt" ]
---

ソース依存性はかなり前から sbt に存在するが、あまりドキュメント化されていない機能の一つだ。

### immutable なソース依存

以下のようにして scopt コマンドラインパーシングライブラリの最新のコミットへのソース依存を宣言できる。

<scala>
lazy val scoptJVMRef = ProjectRef(uri("git://github.com/scopt/scopt.git#c744bc48393e21092795059aa925fe50729fe62b"), "scoptJVM")

ThisBuild / organization := "com.example"
ThisBuild / scalaVersion := "2.12.2"

lazy val root = (project in file("."))
  .dependsOn(scoptJVMRef)
  .settings(
    name := "Hello world"
  )
</scala>

sbt を起動して `compile` を走らせると、sbt は自動的に scopt/scopt をステージング・ディレクトリにクローンして、ビルドをつなぎ合わせる。

そのため sbt バージョンが互換である必要があり、また、要らないトリガープラグインが混入する可能性があることにも注意してほしい。

もう一つの制約は、最初のクローンの後はステージング・ディレクトリが更新されないことだ。

### ハイブリッド依存性

僕が代わりにほしいのはハイブリッド依存性で複数のリポジトリをつなぎ合わせて、コードを書いてテストを走らせることができるが、公開時には Maven のバイナリ依存性となるものだ。

これを実現するために sbt-sriracha という実験的なプラグインを書いた。`project/plugins.sbt` に以下を追加する:

<scala>
addSbtPlugin("com.eed3si9n" % "sbt-sriracha" % "0.1.0")
</scala>

すると以下のように書けるようになる:

<scala>
lazy val scoptJVMRef = ProjectRef(workspaceDirectory / "scopt", "scoptJVM")
lazy val scoptJVMLib = "com.github.scopt" %% "scopt" % "3.7.0"

lazy val root = (project in file("."))
  .sourceDependency(scoptJVMRef, scoptJVMLib)
  .settings(
    name := "Hello world"
  )
</scala>

デフォルトでは、これは普通のバイナリ依存性を用いる。`libraryDependency` セッティングを使ってそれを確認できる:

<code>
$ sbt
sbt:helloworld> libraryDependencies
[info] * org.scala-lang:scala-library:2.12.6
[info] * com.github.scopt:scopt:3.7.0
</code>

ソースモードに切り替えるには sbt を `-Dsbt.sourcemode=true` と共に実行する:

<code>
$ sbt -Dsbt.sourcemode=true
[info] Loading settings from build.sbt ...
[error] java.lang.RuntimeException: Invalid build URI (no handler available): file:///Users/eed3si9n/workspace/scopt/
....
</code>

`workspaceDirectory / "scopt"` に妥当なビルドが無かったのでビルドの読み込みに失敗した。scopt/scopt を `$HOME/workspace` 以下にチェックアウトして、再試行する。

<code>
$ cd $HOME/workspace
$ git clone https://github.com/scopt/scopt
</code>

これで `sbt -Dsbt.sourcemode=true` が走るようになったはずで、`internalDependencyClasspath` は scopt を含むはずだ。

<code>
$ sbt -Dsbt.sourcemode=true
sbt:helloworld> show internalDependencyClasspath
[info] Compiling 2 Scala sources to /Users/eed3si9n/workspace/scopt/jvm/target/scala-2.12/classes ...
[info] Done compiling.
[info] * Attributed(/Users/eed3si9n/workspace/scopt/jvm/target/scala-2.12/classes)
[info] * Attributed(/Users/eed3si9n/work/hellotest/someProject/target/scala-2.12/classes)
</code>

### Scala 2.13.0-M4 を試す

このようなセットアップをする一つの動機として 2.13.0-M4 などの Scala バージョンを上流の依存性がまだ公開されてない段階で使ってみたいというのがある。例えば、これを書いている時点で 2.13.0-M4 用の scopt は公開されていないが `sbt.sourcemode=true` を使うことで `++2.13.0-M4!` を呼べる。

<code>
$ sbt -Dsbt.sourcemode=true
sbt:helloworld> ++2.13.0-M4!
[info] Forcing Scala version to 2.13.0-M4 on all projects.
[info] Reapplying settings...

sbt:helloworld> console
[info] Starting scala interpreter...
Welcome to Scala 2.13.0-M4 (Java HotSpot(TM) 64-Bit Server VM, Java 1.8.0_171).
Type in expressions for evaluation. Or try :help.

scala> val parser = new scopt.OptionParser[Unit]("scopt") {}
parser: scopt.OptionParser[Unit] = $anon$1@28e39e04
</code>

### ソース依存を使ったテスト

ソース依存の面白い応用としてテストフレームワークが挙げられる。ライブラリをメンテしていて、Scala バージョン (もしくは Scala.JS native のバージョンも?) が上がった後すぐに自分のライブラリを公開したいんだけども、テストフレームワークが出てきていない状態だと、ソース依存性を使うことでテストが通るか確認できるようになる。

Scala.JS と native版もあり、かつこれを書いている時点では 2.13.0-M4 版が出ていない µTest がこの実験を行う良い候補かもしれない。ソース依存性を使えば良いわけだし、通常はテストは publish しないものだ。

µTest はまだ sbt 0.13 なので 1.1.5 に更新して、2.13.0-M4 に上げるための[吉田さん](https://github.com/lihaoyi/utest/pull/163)のプルリクと[自分のもの](https://github.com/lihaoyi/utest/pull/167)を合わせたブランチを作った。

`project/plugins.sbt` に以下を追加する:

<scala>
addSbtPlugin("com.eed3si9n" % "sbt-sriracha" % "0.1.0")
</scala>

sbt-sriracha を使って、µTest へのハイブリッド依存性は以下のように定義できる:

<scala>
lazy val utestJVMRef = ProjectRef(uri("git://github.com/eed3si9n/utest.git#5b19f47c"), "utestJVM")
lazy val utestJVMLib = "com.lihaoyi" %% "utest" % "0.6.4"

lazy val root = (project in file("."))
  .sourceDependency(utestJVMRef % Test, utestJVMLib % Test)
  .settings(
    name := "Hello world",
    testFrameworks += new TestFramework("utest.runner.Framework"),
  )
</scala>

これらの変更によって改造版の µTest を Scala 2.13.0-M4 上で走らせられるようになった。

<code>
$ sbt -Dsbt.sourcemode=true
sbt:helloworld> ++2.13.0-M4!
sbt:helloworld> test
-------------------------------- Running Tests --------------------------------
X foo.HelloTests.test1 28ms
  utest.AssertionError: assert(a + b == 7)
  a: Int = 1
  b: Int = 3
    utest.asserts.Asserts$.assertImpl(Asserts.scala:114)
    foo.HelloTests$.$anonfun$tests$2(Test.scala:10)
[info] Tests: 1, Passed: 0, Failed: 1
[error] Failed tests:
[error]   foo.HelloTests
[error] (Test / test) sbt.TestsFailedException: Tests unsuccessful
</code>

µTest をさらにいじりたければ `utestJVMRef` を `ProjectRef(IO.toURI(workspaceDirectory / "utest"), "utestJVM")` に置き換える。

### 更新: Scala 2.13.0-RC1

Scala 2.13.0-RC1 だと以下のようになる:

<scala>
lazy val utestVersion = "0.6.6"
lazy val utestJVMRef = ProjectRef(uri("git://github.com/eed3si9n/utest.git#79950544"), "utestJVM")
lazy val utestJVMLib = "com.lihaoyi" %% "utest" % utestVersion
lazy val utestJSRef = ProjectRef(uri("git://github.com/eed3si9n/utest.git#79950544"), "utestJS")
lazy val utestJSLib = "com.lihaoyi" %% "utest_sjs0.6" % utestVersion
</scala>

### まとめ

- sbt はソース依存性を使うことができる
- sbt-sriracha はソースとバイナリのハイブリッド依存性のための `addSourceDependency(...)` を追加する
- これによって単一リポジトリをエミュレートしたり、上流のライブラリやテストフレームワークを擬態することができる
