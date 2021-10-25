---
title:       "Expecty を用いた power assert を復活させる"
type:        story
date:        2018-05-28
changed:     2018-05-29
draft:       false
promote:     true
sticky:      false
url:         /ja/power-assert-with-expecty
aliases:     [ /node/263 ]
---

  [sbt-sriracha]: http://eed3si9n.com/ja/hot-source-dependencies-using-sbt-sriracha
  [g2009]: http://groovy-lang.org/releasenotes/groovy-1.7.html#Groovy17releasenotes-PowerAsserts
  [rpower]: https://github.com/k-tsj/power_assert
  [jspower]: https://github.com/power-assert-js/power-assert
  [rspower]: https://github.com/gifnksm/power-assert-rs
  [expecty]: https://github.com/pniederw/expecty
  [expecty2]: https://github.com/eed3si9n/expecty
  [10]: https://github.com/pniederw/expecty/pull/10
  [14]: https://github.com/monix/minitest/pull/14
  [minitest]: https://github.com/monix/minitest
  [pp2012]: https://groups.google.com/d/msg/scala-language/Z4ByvmQESJ0/SaFj7QBproYJ
  [2]: https://gist.github.com/paulp/3019862

先週は [sbt-sriracha を用いたソース依存][sbt-sriracha]をテストに使う方法を紹介した。今週は Expecty を使って power assert をする方法を見ていく。

power assert (もしくは power assertion) は `assert(...)` 関数の変種で、自動的に詳細なエラーメッセージを表示してくれる。これは、Peter Niederwieser ([@pniederw](https://twitter.com/pniederw)) さんがまず [Spock](http://spockframework.org/) のために実装して、2009 年に [Groovy 1.7][g2009] に取り込まれた。power assert は [Ruby][rpower]、[JavaScript][jspower]、[Rust][rspower] など他の言語にも広まっている。

### 従来の assert 文

例えとして `a * b` を考える。従来の `assert` を使った場合以下のように書く:

```scala
scala> assert(a * b == 7, s"a = $a; b = $b; a * b = ${a * b}")
java.lang.AssertionError: assertion failed: a = 1; b = 3; a * b = 3
```

ごちゃごちゃと全部の変数への検査をログやエラーメッセージに書くといったことが往々にして行われる。

### Expecty

Scala には、なんと Peter Niederwieser さん本人が 2012年ごろに書いた [Expecty][expecty] というミニライブラリがあって、power assert を実装する。これは、良い知らせであり、悪い知らせでもある。それがあるということそのものは良いことだ。部分的に悪いのは、オリジナルの Expecty は 2014年以降更新されておらず、多分 Gradle をビルドに使っているためクロスパブリッシュの慣例を採用していない。また、GitHub をリポジトリとして使うという昔たまにやってる人がいたねっていうあれをやっている。つまり、放置された状態にあるみたいだ。

僕は Expecty を試してみたかったので、[eed3si9n/expecty][expecty2] にフォークして、sbt ビルドを追加して、コードが Scala 2.10、2.11、2.12、2.13.0-M4 で動作するようにパッチを当てて、上流に[プルリクを還元][10]した後でパッケージ名を変更して、Maven Central に公開した:

```scala
libraryDependencies += "com.eed3si9n.expecty" %% "expecty" % "0.11.0" % Test
```

Scala.JS か Scala Native の場合は:

```scala
libraryDependencies += "com.eed3si9n.expecty" %%% "expecty" % "0.11.0" % Test
```

以下のように使うことができる:

```scala
scala> import com.eed3si9n.expecty.Expecty.assert
import com.eed3si9n.expecty.Expecty.assert

scala> assert(a * b == 7)
java.lang.AssertionError:

assert(a * b == 7)
       | | | |
       1 3 3 false

  at com.eed3si9n.expecty.Expecty$ExpectyListener.expressionRecorded(Expecty.scala:25)
  at com.eed3si9n.expecty.RecorderRuntime.recordExpression(RecorderRuntime.scala:34)
  ... 38 elide
```

上のように、ナイスなエラーメッセージが自動的に得られる。

ScalaTest を使っている人は、この機能は [DiagrammedAssertions](https://gist.github.com/bvenners/6b52677e801683df8d0a) として取り込まれている。

### 2.13.0-M4 のための Minitest

[Minitest][minitest] はライトウェイトなテストフレームワークで、`test("...") {}`、`setup`、`teardown` 以外は何も無いという昔の JUnit みたいなフレームワークだ。これが便利なのは Scala.JS 版も出ていることだ。しかし、これを書いている時点では ScalaCheck の Scala 2.13.0-M4 版が出ていないせいで Minitest も出ていない。

[小さなパッチ][14]を当てて僕は Minitest をローカル環境で走らせることができた。これを `$HOME/workspace` に置いて [sbt-sriracha][sbt-sriracha] を使うだけでいい:

```scala
val minitestJVMRef = ProjectRef(IO.toURI(workspaceDirectory / "minitest"), "minitestJVM")
val minitestJVMLib = "io.monix" %% "minitest" % "2.1.1"

lazy val scoptJVM = scopt.jvm.enablePlugins(SiteScaladocPlugin)
  .sourceDependency(minitestJVMRef % Test, minitestJVMLib % Test)
  .settings(
    testFrameworks += new TestFramework("minitest.runner.Framework")
  )
```

Scala 2.13.0-M4 用のバイナリ版が出てくれば、この面倒なカラクリを消して普通に `libraryDependencies` に移行すればいい。

### Minitest + Expecty

Minitest と Expecty を組み合わせるのは簡単だ。まずは、Expecty fork をビルドに追加する:

```scala
val minitestJVMRef = ProjectRef(IO.toURI(workspaceDirectory / "minitest"), "minitestJVM")
val minitestJVMLib = "io.monix" %% "minitest" % "2.1.1"

lazy val scoptJVM = scopt.jvm.enablePlugins(SiteScaladocPlugin)
  .sourceDependency(minitestJVMRef % Test, minitestJVMLib % Test)
  .settings(
    libraryDependencies += "com.eed3si9n.expecty" %% "expecty" % "0.11.0" % Test,
    testFrameworks += new TestFramework("minitest.runner.Framework")
  )
```

次に、以下のように trait を定義する:

```scala
import com.eed3si9n.expecty.Expecty

trait PowerAssertions {
  lazy val assert: Expecty = new Expecty()
}
```

テストは以下のように書ける:

```scala
import minitest._

object ImmutableParserSpec extends SimpleTestSuite with PowerAssertions {
  test("int parser should parse 1") {
    intParser("--foo", "1")
    intParser("--foo:1")
  }

  val intParser1 = new scopt.OptionParser[Config]("scopt") {
    override def showUsageOnError = true
    head("scopt", "3.x")
    opt[Int]('f', "foo").action( (x, c) => c.copy(intValue = x) )
    help("help")
  }
  def intParser(args: String*): Unit = {
    val result = intParser1.parse(args.toSeq, Config())
    assert(result.get.intValue == 1)
  }

  ....
}
```

値を 1 から 2 へ変えて、どう失敗するか見てみよう。

```scala
[info] - int parser should parse 1 *** FAILED ***
[info]   AssertionError:
[info]
[info]   assert(result.get.intValue == 2)
[info]          |      |   |        |
[info]          |      |   1        false
[info]          |      Config(false,1,0,,0.0,false,false,0.0,http://localhost,0 days,,,,List(),ChampHashMap(),List(),)
[info]          Some(Config(false,1,0,,0.0,false,false,0.0,http://localhost,0 days,,,,List(),ChampHashMap(),List(),))
[info]     com.eed3si9n.expecty.Expecty$ExpectyListener.expressionRecorded(Expecty.scala:25)
[info]     com.eed3si9n.expecty.RecorderRuntime.recordExpression(RecorderRuntime.scala:34)
[info]     ImmutableParserSpec$.intParser(ImmutableParserSpec.scala:258)
[info]     ImmutableParserSpec$.$anonfun$new$3(ImmutableParserSpec.scala:18)
[info]     minitest.SimpleTestSuite.$anonfun$test$1(SimpleTestSuite.scala:27)
[info]     minitest.api.TestSpec$.$anonfun$sync$1(TestSpec.scala:51)
[info]     minitest.api.TestSpec.apply(TestSpec.scala:27)
[info]     minitest.api.Properties.$anonfun$iterator$2(Properties.scala:38)
[info]     minitest.api.TestSpec.apply(TestSpec.scala:27)
[info]     minitest.runner.Task.loop$1(Task.scala:40)
[info]     minitest.runner.Task.$anonfun$execute$1(Task.scala:47)
[info]     scala.concurrent.Future.$anonfun$flatMap$1(Future.scala:259)
[info]     scala.concurrent.impl.Promise.$anonfun$transformWith$1(Promise.scala:37)
[info]     scala.concurrent.impl.CallbackRunnable.run(Promise.scala:60)
[info]     java.util.concurrent.ForkJoinTask$RunnableExecuteAction.exec(ForkJoinTask.java:1402)
[info]     java.util.concurrent.ForkJoinTask.doExec(ForkJoinTask.java:289)
[info]     java.util.concurrent.ForkJoinPool$WorkQueue.runTask(ForkJoinPool.java:1056)
[info]     java.util.concurrent.ForkJoinPool.runWorker(ForkJoinPool.java:1692)
[info]     java.util.concurrent.ForkJoinWorkerThread.run(ForkJoinWorkerThread.java:157)
```

これは面白い。

### power assert をもっと使おう

`assert(...)` 関数は、メインのコード、テストなど幅広い場面で使われる便利なツールだ。
power assert は完全にはテストフレームワークの代替とはならないが、従来の scripted や partest といったテストにパワーを与えてくれるんじゃないかと思っている。

2012年に Paul Phillips さんは scala-language メーリングリストに [表現力の高い assertion: 史上最高のもの][pp2012] という投稿をしている:

> 僕は、長いこと assert で便利なことができる言語のことを羨ましく思ってきた。そしてマクロが現れた...
>
> 僕は Peter Niederwieser の [expecty][expecty] を assert/assume/require のシグネチャーで使えるように調整して、それを使ってコンパイラをビルドした。[見てくれ!][2] この世と来世を合わせても、これよりも良いものを挙げることは君にはできないだろう。

### まとめ

- Expecty は Scala に power assert を持ち込む。
- sbt-sriracha を使うと 2.13.0-M4 版が公開される前に Minitest を使うことができる。
- Minitest と Expecty は合成可能である。
