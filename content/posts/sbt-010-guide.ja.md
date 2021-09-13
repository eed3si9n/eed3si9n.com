---
title:       "非公式 sbt 0.10 ガイド v2.0"
type:        story
date:        2011-09-25
changed:     2013-10-07
draft:       false
promote:     true
sticky:      false
url:         /ja/sbt-010-guide
aliases:     [ /node/36 ]
tags:        [ "sbt" ]
---

> ## version 2.0
> 2011年6月19日に最初のバージョンを書いた時点での僕の動機は、運良く Mark による sbt 0.10 のデモを二回も生で見れたことに触発されて（最初は [northeast scala][29]、次に [scala days 2011][30]）、sbt 0.7 から 0.10 へと皆が移行するのを手助けしたかったからだった。プラグインがそろっていなければビルドユーザが 0.10 に移行できないため、プラグインが移行への大きな妨げになるというのが大方の考えだった。そこで僕が取った戦略は、無いプラグインは自分で移植して、つまずいたらメーリングリストで質問して、結果をここでまとめるというものだった。それにより、多くのポジティブな反応があったし、数人を 0.10 へ移行する手助けにもなったと思う。だけど、後ほど明らかになったのは、僕の sbt 0.10 に関する理解は完全なものではなく、時として全く間違っており誤解を与えるものだったということだ。文責は僕にあるが、古い内容をそのまま残しておくのではなく、[github][32] に push して、新しいバージョンを作って、前へ進むことにした。プラグインの作成に関する最新の知識は [Plugins Best Practices][31] にまとめられており、大部分は [Brian](https://github.com/bmc) と [Josh](https://github.com/jsuereth)、ちょこっとだけ僕により書かれている。

## 慌てるな (don't panic)
さっき 0.7 の世界から着陸したばっかりの君。sbt 0.10 があまりにも違うのでビックリすることだと思う。ゆっくり時間をかけて概念を理解すれば、必ず分かるようになるし、sbt 0.10 の事がきっと大好きになることを約束する。

## 三つの表現
sbt 0.10 とやり取りするのに三つの方法があるため、最初は混乱するかもしれない。

1. sbt 0.10 を起動時に現れるシェル。
2. `build.sbt` や `settings` 列に入る Quick Configurations DSL。
3. 普通の Scala コード、別名 Full Configuration。

それぞれの表現は別々の使用モデルに最適化している。sbt を単にプロジェクトをビルドするのに使っている場合は、ほとんどの時間を `publish-local` などのコマンドを使って、シェルの中で過ごすだろう。次にライブラリの依存性など基本的な設定の変更を行いたい場合、`build.sbt` の Quick Configurations DSL に移行する。最後に、サブプロジェクトを定義したり、プラグインを書く場合には、Full Configuration を使うことで Scala のパワーを発揮することができる。

## 基本概念 (key-value)
sbt 0.10 の心臓部と言えるのは `settings` と呼ばれる key-value テーブルだ。例えば、プロジェクト名は `name` という設定値 (setting) に格納されていて、シェルからは `name` として呼び出すことができる:

    > name          
    [info] helloworld

面白いのが、この `settings` は静的なプロジェクトの設定だけではなくタスクも格納するということだ。タスクの例としては、`publishLocal` があり、これはシェルからは `publish-local` として呼び出すことができる:

    > publish-local
    [info] Packaging /Users/eed3si9n/work/helloworld/target/scala-2.8.1.final/helloworld_2.8.1-0.1-sources.jar ...
    ....

0.7 では、このようなタスクは `publishLocalAction` のような `Task` オブジェクトを返すメソッドと、依存関係を宣言する `lazy val` の組み合わせで宣言されていた。タスクの振る舞いを変更するには、メソッドをオーバーライドし、例えば jar ファイルをパッケージする等、タスクの振る舞いを再利用するには直接メソッドを呼び出すというのがこれまでのやり方だった。

0.10 では、設定値もタスクも単に `settings` 列のエントリーにすぎない。

<scala>val name = SettingKey[String]("name", "Name.")
...
val publishLocal = TaskKey[Unit]("publish-local", "Publishes artifacts to the local repository.")</scala>

設定値もタスクもキー名で呼ばれるので、プラグインを書く場合は、キー名とお近づきになっておくのがポイントだ。 [Key.scala][1] が組み込みのキーを定義する。

## 設定値 vs タスク
最初のうちは、設定値とタスクの違いを知ることはあまり重要ではない。
設定値は副作用のない静的な値で、定数か他の設定値にのみ依存する。言い方を変えると、これらの値はキャッシュすることができ、プロジェクトを再読込するまでは値は変わらない。

一方タスクはファイルシステムのような外部ソースに依存することができ、ディレクトリの削除といった副作用を伴うこともある。

## 基本的な概念 (依存性)
sbt 0.10 に深みを与えているのが、`settings` のエントリーのそれぞれが別のキーへの依存性（dependencies、"deps" とも略す）を宣言できるということにある（僕が「キー」と言う時は、設定値とタスクという意味だが、分かってくれたと思う）。
例えば、`publishLocalConfiguration` の依存性は以下のように宣言されている:

<scala>publishLocalConfiguration <<= (packagedArtifacts, deliverLocal, ivyLoggingLevel) map {
	(arts, ivyFile, level) => publishConfig(arts, Some(ivyFile), logging = level )
},</scala>

上記は sbt 0.10 の Quick Configuration DSL の一例だ。これは、`publishLocalConfiguration` から `packagedArtifacts`、`deliverLocal`、と `ivyLoggingLevel` への依存性を宣言し、依存したキーからの値を用いて `publishConfig` を呼び出すことで値を計算している。さらに、全てのキーをクラス継承なしに `build.sbt` の中で任意の値に配線することができる。

また、`inspect` コマンドを用いて、シェルの中から設定値やタスクの依存性をみることができる:

    > inspect publish-local
    [info] Task
    [info] Description:
    [info] 	Publishes artifacts to the local repository.
    [info] Provided by:
    [info] 	{file:/Users/eed3si9n/work/helloworld/}default/*:publish-local
    [info] Dependencies:
    [info] 	{file:/Users/eed3si9n/work/helloworld/}default/*:ivy-module
    [info] 	{file:/Users/eed3si9n/work/helloworld/}default/*:publish-local-configuration
    [info] 	{file:/Users/eed3si9n/work/helloworld/}default/*:streams(for publish-local)
    [info] Delegates:
    [info] 	{file:/Users/eed3si9n/work/helloworld/}default/*:publish-local
    [info] 	{file:/Users/eed3si9n/work/helloworld/}/*:publish-local    

## 基本的な概念 (コンフィギュレーション)
`settings` のもう一つの興味深い側面は、エントリーと宣言された依存性の両者がコンフィギュレーションの中にスコープする (scope) ことができることだ。

<scala>libraryDependencies ++= Seq(
  "org.specs2" %% "specs2" % "1.6.1" % "test",
  "org.specs2" %% "specs2-scalaz-core" % "6.0.1" % "test"
)</scala>

上のコードは `"test"` へのスコープ付き依存性だが、`"test"` は `"test->compile"` の略だ。これは、このプロジェクトの `"test"` コンフィギュレーションは specs2 が `"compile"` コンフィギュレーションのもとで公開する成果物に依存していることを表す。

では、コンフィギュレーションとは何なのだろうか？これは、Maven のスコープや Ivy のコンフィギュレーションから借用した概念で、プロジェクトが異なるファイルや依存性を持った別のモードになりえるということだ。デフォルトのコンフィギュレーションである `"compile"`、`"test"`、`"runtime"` はその良い例だ。例えば、`test` タスクを走らせたとき、sbt が `src/test/*` と `src/main/*` の両者からソースを引っ張ってきて、また `"test"` とスコープ付きされた依存性と素の依存性の両方も引っ張ってくることを期待すると思う。

これがどうやって実現されているかみてみよう。`inspect test` 走らせると、デフォルトの `test` タスクは `test:test` に委譲されていることが分かる。

    > inspect test        
    [info] Task: Unit
    [info] Description:
    [info] 	Executes all tests.
    [info] Provided by:
    [info] 	{file:/Users/eed3si9n/work/helloworld/}default-b65acd/test:test
    ...

`test:test` はコンフィギュレーション付きのキーのシェルにおける表記の一例だ。Quick Config DSL においては、`test in Test` と書かれる。キーの依存性を `executeTests in Test` 経由でたどっていくと、探していた `compile in Test` が見つかる。`compile in Test` が面白いのは、依存する設定値を含め、これは普通の `compile` と全く同様に配線されていることだ。唯一の違いは `Test` コンフィギュレーションを使っていることだけだ。例えば、ソースコードの違いをみてみよう:

    > show test:sources
    [info] List(/Users/eed3si9n/work/helloworld/src/test/scala/hellospec.scala)
    
    > show compile:sources
    [info] List(/Users/eed3si9n/work/helloworld/src/main/scala/hello.scala)

さて、`test` は、そもそもどうやって `test:test` に委譲したのだろう。コンフィギュレーションの付かないキーがシェルに渡されると、sbt はまず `Global` コンフィギュレーションを見にいき、次にプロジェクトの `configurations` で指定された順序でコンフィギュレーションを見にいく。デフォルトで、この順序は `Seq(Compile, Runtime, Test, Provided, Optional)` だ。

## 基本的な概念 (プロジェクト)
sbt を build.sbt だけで立ち上げると、自動的にデフォルトプロジェクトの中に置かれる。Full Configuration を使うことで、sbt は一つのビルド下で複数のモジュールを管理することができる。また、これによりサブモジュール間の依存性なども宣言することもできる。

<scala>object FooBuild extends Build {
   lazy val root = Project("root", file("."), settings = buildSettings) aggregate(library, jetty)
   lazy val library = Project("library", file("library"))
   lazy val jetty = Project("foo-jetty", file("jetty")) dependsOn(library)
}</scala>

シェルからは `project` コマンドを使ってプロジェクトを切り替える:

    root> project library
    library> compile
    ...

これは、`compile` タスクが現プロジェクトにスコープ付けされていることを例示する。

## 基本的な概念 (スコープ)
これまでで、コンフィギュレーションとプロジェクトの二つのスコープをみてきた。一般的に、スコープはキーに何らかの文脈を与え、キーやキー間の関係を再利用することを促進する。例えば、プロジェクトやコンフィギュレーションに関わらず `compile` は `sources` に依存する。

sbt では合計四つの軸（axis）のスコープがあり、それらはプロジェクト、コンフィギュレーション、タスク、およびエクストラだ。ただし、エクストラ軸は現在の所未使用なので、実質プロジェクト、コンフィギュレーション、タスクの三軸だ。そう、タスクをつかってスコープ付けをすることができる！過去に僕は、コンフィギュレーションを使ったスコープ機構を一押ししてきたが、メーリングリストでの議論などを通じ、プラグインはコンフィギュレーション中立性を目指すべきで、タスク特定の設定値のスコープ付けに使うには間違った軸だという理解に達した。スコープ付けはプラグインのメインのタスクに設定値をスコープ付けすることが現在推奨されている。（[Plugins Best Practices][31] 参照）

例えば、テストを走らせた後で実行可能な jar ファイルを作成する assembly というタスクを定義するとする。プラグインの定義では、こんな感じになる:
 
<scala>val assembly = TaskKey[File]("assembly")

lazy val baseAssemblySettings: Seq[sbt.Project.Setting[_]] = Seq(
  assembly <<= (test in Test) map { _ =>
    // do something
  }
)</scala>

これではユーザは `test in Test` への依存性から抜け出せないと見ることもできる。これを直すには、`test` を `assembly` タスクの下にスコープ付けすればいい。

<scala>val assembly = TaskKey[File]("assembly")

lazy val baseAssemblySettings: Seq[sbt.Project.Setting[_]] = Seq(
  assembly <<= (test in assembly) map { _ =>
    // do something
  },
  test in assembly <<= (test in Test).identity
)</scala>

もし、なんらかの理由でユーザがテストを走らせたくなければ、本家の `test` タスクに影響を与えずに `test in assembly` を再配線することができる。

<scala>test in assembly := {}
</scala>

## スコープの変更
上記の通り、キーは四つの軸においてスコープ付けすることができる。だけど、ただ `sources` と言ったときはどのコンフィギュレーションにいるのだろう？答は `Scope.ThisScope` で、これは `Scope(This, This, This, This)` と定義されている。`This` という値はスコープ付けされていないことを表す。

`compile` のようなコンフィギュレーション中立な設定値のチェインを作ることで、複数のコンフィギュレーション間でそれを再利用できる。例のため  `Default.configTasks` を簡略化したものを以下に示す:

<scala>lazy val baseCompileSettings = Seq(
  compile <<= (compileInputs) map { i => Compiler(i) },
  compileInputs <<= (dependencyClasspath, sources) map { (cp, srcs) =>
    Compiler.inputs(classpath, srcs)
  }
)</scala>

大切なのは、上のどのキーもコンフィギュレーション軸でスコープ付けされていないということだ。sbt は強力なユーティリティ関数 `inConfig(conf: Configuration)(ss: Seq[Setting[_]])` を提供し、これは設定値のシーケンス `ss` のうち、が既にコンフィギュレーションにスコープ付けされていないものだけを `conf` にスコープ付けするというスグレモノだ。例えば、

<scala>inConfig(Compile)(baseCompileSettings)
</scala>

これは以下と等価だ

<scala>lazy val compileSettings = Seq(
  compile in Compile <<= (compileInputs in Compile) map { i => Compiler(i) },
  compileInputs in Compile <<= (dependencyClasspath in Compile, sources in Compile) map { (cp, srcs) =>
    Compiler.inputs(classpath, srcs)
  }
)</scala>

同様に、この設定値を `Test` にも配線できる:

<scala>inConfig(Test)(baseCompileSettings)
</scala>

<a name="per-task-keys"></a>
## キーをタスクの下にスコープ付けするときの注意 (sbt 0.12+ では必要ない)

[この項は削除した](https://github.com/eed3si9n/eed3si9n.com/commit/89453f8b41527bed175cbd14afb42c8aa024e2bb)。

## ドキュメントとソースを読む
[公式の wiki][2] は役に立つ情報満載だ。ちょっと散漫な気もするが、欲しい情報が分かっていれば大抵見つけることが出来る。以下に役に立つページへのリンクを載せる:
- [Migrating from SBT 0.7.x to 0.10.x][8]
- [Settings][3]
- [Basic Configuration][4]
- [Full Configuration][11]
- [Library Management][5]
- [Plugins][9]
- [Task Basics][6]
- [Common Tasks][7]
- [Mapping Files][10]

例を見たいときは、ソースが一番良い例であることが多い。Scala X-Ray と scaladocs を活用することで、次々とソースを読むことができる。
- [SXR Documentation][21]
- [API Documentation][22]

メーリングリストで [型の海で漂流している][12]と題されたスレッドで Mark は三つのソースに言及している:
- [Default.scala][13] (「全ての組み込みの設定値はここで定義されている。」)
- [Keys.scala][1] (「キーは Keys にあり。」)
- [Structure.scala][14] (「これら（暗黙の変換）の多くは、Structure.scala 内の Scope で定義されている。」)

## プラグインを読む
プラグインを書き始めるとき、[他の人が書いたプラグインのソース][18]を読むと色々トリックを習うことができる。以下に僕が読んだものを挙げる:
- [sbt/sbt-assembly][16]
- [softprops/coffeescripted-sbt][15]
- [siasia/xsbt-web-plugin][19]
- [Proguard.scala][17]
- [ijuma/sbt-idea][20]
- [jsuereth/xsbt-ghpages-plugin][28]

## 0.7 からの小さな変更点を覚える
このガイドを書く動機となったのは、[codahale/assembly-sbt][23] を [eed3si9n/sbt-assembly][16] として sbt 0.10 に移植する際につまずいた細々とした名前の変更やその他の変更点だ。以下にこの二つのプラグインを並べて変更点を見ていきたい。

### バージョン番号
0.7 (build.properties にて):
<scala>project.version=0.1.1
</scala>

0.10 のプラグイン (build.sbt にて):
<scala>posterousNotesVersion := "0.4"

version <<= (sbtVersion, posterousNotesVersion) { (sv, nv) => "sbt" + sv + "_" + nv }</scala>

ソースパッケージとして配布されていた 0.7 プラグインと違い、0.10 プラグインはバイナリとしてパッケージされる。これにより特定の sbt のバージョンへの依存性が出てくるようになった。これまでのところ 0.10.0 と 0.10.1 が出ているけど、0.10.0 を使ってコンパイルされたプラグインは 0.10.1 では動作しない。回避策として、上記のバージョン番号規約を採用している。

0.11 (build.sbt にて):
<scala>version := "0.4"
</scala>

0.11 は RC しか今のところ出ていないが、これはアーティファクト名を自動改変することでバージョン番号問題を解決する。

### スーパークラス
ビフォー:
<scala>package assembly

trait AssemblyBuilder extends BasicScalaProject {
</scala>

アフター:
<scala>package sbtassembly

object Plugin extends sbt.Plugin { 
</scala>

この変更は、細かいけど sbt 0.10 におけるプラグインの立ち位置を示す大切なものだ。0.7 では、プラグインはプロジェクトのオブジェクトにミックスインするトレイトだった（is-a、つまり継承関係）。一方 0.10 では、プラグインはプロジェクトの実行環境に読み込まれるライブラリだ（has-a、つまり集約関係）。

### 設定値のありか
ビフォー:<br>
trait の中。

アフター:
<scala>
  ...
  lazy val assemblySettings: Seq[sbt.Project.Setting[_]] = inConfig(Runtime)(baseAssemblySettings)
  lazy val baseAssemblySettings: Seq[sbt.Project.Setting[_]] = Seq(
    ...
  )</scala>

オーバーライド可能なメソッドを定義する代わりに、プラグインでは後からユーザが `seq(...)` で読み込める `sbt.Project.Setting[_]` 列を作る。こうすることで、ビルドの作者はプラグインの設定値を読み込むかどうかをプロジェクトごとに決めることができる。唯一の例外としては、グローバルなコマンドを定義する場合で、そのときは `settings` をオーバーライドする。

### オーバーライドされることを想定した設定値
ビフォー:
<scala>  def assemblyJarName = name + "-assembly-" + this.version + ".jar"
</scala>

アフター:
<scala>  object AssemblyKeys {
    lazy val jarName           = SettingKey[String]("assembly-jar-name")
  }

  import AssemblyKeys._   
  lazy val baseAssemblySettings: Seq[sbt.Project.Setting[_]] = Seq(
    jarName in assembly <<= (name, version) { (name, version) => name + "-assembly-" + version + ".jar" },
    ...
  )
</scala>

`baseAssemblySettings` の中に他のキー (`name` と `version`) への依存性を宣言したエントリーを定義する。Quick Configuration DSL は、このペアに対して[`apply`][24] を injected method として加えるため、直後に関数値を渡すことで `jarName` キーの値を計算することができる。`AssemblyKeys` に入れることで、この設定値は `assembly` というプレフィックス無しで `jarName` と名付けることができる。build.sbt からは `AssemblyKeys.jarName` 、もしくは `AssemblyKeys._` をファイルの先頭で　import した後 `jarName` として呼び出す。
  
### Quick Configuration DSL の静的型は `Initialize[A]`
ビフォー:
<scala>  def assemblyTask(...)

  lazy val assembly = assemblyTask(...) dependsOn(test) describedAs("Builds an optimized, single-file deployable JAR.")</scala>

アフター:
<scala>  object AssemblyKeys {
    val assembly = TaskKey[File]("assembly", "Builds a single-file deployable jar.")
  }
  
  import AssemblyKeys._ 
  private def assemblyTask: Initialize[Task[File]] = 
    (test in assembly, ...) map { (t, ...) =>
    }
  
  lazy val baseAssemblySettings: Seq[sbt.Project.Setting[_]] = Seq(
    assembly <<= assemblyTask,
    ...
  )
</scala>

全てを `baseAssemblySettings` を詰め込むこともできるが、それはすぐに散らかってしまう。Keith Irwin 氏の [coffeescripted-sbt][15] の実装を真似て僕もコードを整理してみた。

### `outputPath` は `target` であり、`Path` は `sbt.File` だ
ビフォー:
<scala>  def assemblyOutputPath = outputPath / assemblyJarName
</scala>

アフター:
<scala>  object AssemblyKeys {
    val outputPath        = SettingKey[File]("assembly-output-path")
  }
  
  import AssemblyKeys._
  lazy val baseAssemblySettings: Seq[sbt.Project.Setting[_]] = Seq(
    outputPath in assembly <<= (target in assembly, jarName in assembly) { (t, s) => t / s },
    ...
  )</scala>

以前 `outputPath` と呼ばれていたものは、今は `target: SettingKey[File]` と呼ばれるキーだ。

`sbt.File` は `java.io.File` の別名 (alias) であり、それは暗黙に `sbt.RichFile` に変換され、これは 0.7 における `Path` のかわりとなる。ただ `dir: File` と言うだけで、`dir / name` と書くことができる。

### `runClasspath` は `fullClasspath in Runtime`
ビフォー:
<scala>  def assemblyClasspath = runClasspath
</scala>

アフター:
<scala>  lazy val baseAssemblySettings: Seq[sbt.Project.Setting[_]] = Seq(
    fullClasspath in assembly <<= fullClasspath or (fullClasspath in Runtime).identity,
    ...
  )</scala>
  
### 既存のキーを再利用する
ビフォー:
<scala>  def assemblyClasspath = runClasspath
</scala>

アフター:
<scala>  lazy val baseAssemblySettings: Seq[sbt.Project.Setting[_]] = Seq(
    fullClasspath in assembly <<= fullClasspath or (fullClasspath in Runtime).identity,
    ...
  )</scala>

`fullClasspath in Assembly` は `fullClasspath in Runtime` からの初期値が与えられているが、もしユーザが望めば、フックメソッドを定義することなく後からオーバーライドすることができる。便利だよね？

### クラスパスの型は `Pathfinder` ではなく、`Classpath` 
ビフォー:
<scala>  classpath: Pathfinder
</scala>

アフター:
<scala>  classpath: Classpath
</scala>

### オーバーライドされることを想定した関数
ビフォー:
<scala>  def assemblyExclude(base: PathFinder) =
    (base / "META-INF" ** "*") --- 
      (base / "META-INF" / "services" ** "*") ---
      (base / "META-INF" / "maven" ** "*")</scala>
      
アフター:
<scala>  val excludedFiles     = SettingKey[Seq[File] => Seq[File]]("excluded-files")  

  private def assemblyExcludedFiles(base: Seq[File]): Seq[File] =
    ((base / "META-INF" ** "*") ---
      (base / "META-INF" / "services" ** "*") ---
      (base / "META-INF" / "maven" ** "*")).get
      
  lazy val baseAssemblySettings: Seq[sbt.Project.Setting[_]] = Seq(
    excludedFiles in assembly := assemblyExcludedFiles _,
    ...
  )</scala>

これは少し複雑だ。sbt 0.10 は振る舞いをオーバーライドをするのに継承関係に頼らなくなったから、このメソッドを key-value の `baseAssemblySettings` のもとで管理する必要がある。Scala では、メソッドを変数に代入するには関数値に変更する必要があるから、`assemblyExcludedFiles _` と書く。この関数値の型は `Seq[File] => Seq[File]` だ。

### `Pathfinder` よりも `Seq[File]` を選ぶ
ビフォー:
<scala>  base: PathFinder
</scala>

アフター:
<scala>  base: Seq[File]
</scala>

`Seq[File]` は暗黙に `Pathfinder` に変換することができ、0.10 では拡張のために露出しているメソッドでは標準の Scala 型の `File` や `Seq[File]` を使うことが好まれる。

### `##` はファイルマッピングにより実現される
ビフォー:
<scala>  val base = (Path.lazyPathFinder(tempDir :: directories) ##)
  (descendents(base, "*") --- exclude(base)).get</scala>
  
アフター:
<scala>  val base = tempDir +: directories
  val descendants = ((base ** (-DirectoryFilter)) --- exclude(base)).get
  descendants x relativeTo(base)</scala>

詳細は[ファイルのマッピング][25]を参照。
> `package`、`packageSrc`、や `packageDoc` のようなタスクは入力ファイルから成果物のアーティファクト (jar) 内でのパスへのマッピングを受け取る。

`x` メソッドを用いてマッピングを生成することができる。

### `FileUtilities` は `IO`
ビフォー:
<scala>  FileUtilities.clean(assemblyConflictingFiles(tempDir), true, log)
</scala>

アフター:
<scala>  IO.delete(conflicting(Seq(tempDir)))
</scala>

この名前の変更に関しては、最初分からなかったので、メーリングリストに聞いて親切な誰かに教えてもらった。[API Documentation][22] のコンパニオンオブジェクトを眺めて他にも面白いメソッドが見つかるか試してみると面白いだろう。

### `packageTask` は `Package`
ビフォー:
<scala>  packageTask(...)
</scala>

アフター:
<scala>  Package(config, cacheDir, s.log)
</scala>

### `streams` から `logger` を取得する
ビフォー:
<scala>  log.info("Including %s".format(jarName))
</scala>

アフター:
<scala>  (streams) map { (s) =>
    val log = s.log 
    log.info("Including %s".format(jarName))
  }</scala>

[基本的なタスク][6]より:
> sbt 0.10 より登場したタスクごとのロガーは、Streams と呼ばれる、より一般的なタスク特定データのためのシステムの一部だ。これは、タスクごとにスタックトレースやログの冗長さを調節したり、タスクの最後のログを呼び出すことができる。

## メーリングリストを検索し、メーリングリストに聞く
[simple-build-tool メーリングリスト][26]は役に立つ情報で満載だ。かなりの確率で他の誰かが同じ問題で困ったことがあるはずだから、まずはリストを検索してみよう（検索結果は新しいものが先にくるようにソートするのがお勧め）。

それでも困った場合は、恥ずかしがらずにメーリングリストに聞いてみよう。誰かが役に立つ情報を教えてくれるはずだ。

## thx
長い文をここまで読んでくれて、ありがとう。これを読んで誰かの時間の節約になればと思っている。繰り返すが、僕は sbt 0.10 の専門家ではないから、半分ぐらいは間違っているかもしれない。迷ったら、公式のドキュメントか専門家に聞いて欲しい。

  [1]: http://harrah.github.com/xsbt/latest/sxr/Keys.scala.html
  [2]: https://github.com/harrah/xsbt/wiki
  [3]: https://github.com/harrah/xsbt/wiki/Settings
  [4]: https://github.com/harrah/xsbt/wiki/Basic-Configuration
  [5]: https://github.com/harrah/xsbt/wiki/Library-Management
  [6]: https://github.com/harrah/xsbt/wiki/Tasks
  [7]: https://github.com/harrah/xsbt/wiki/Common-Tasks
  [8]: https://github.com/harrah/xsbt/wiki/Migrating-from-SBT-0.7.x-to-0.10.x
  [9]: https://github.com/harrah/xsbt/wiki/Plugins
  [10]: https://github.com/harrah/xsbt/wiki/Mapping-Files
  [11]: https://github.com/harrah/xsbt/wiki/Full-Configuration
  [12]: https://groups.google.com/group/simple-build-tool/browse_thread/thread/d2a842c8182c99d5#msg_660cd082183f6dc3
  [13]: http://harrah.github.com/xsbt/latest/sxr/Defaults.scala.html
  [14]: http://harrah.github.com/xsbt/latest/sxr/Structure.scala.html
  [15]: https://github.com/softprops/coffeescripted-sbt/blob/master/src/main/scala/coffeescript.scala
  [16]: https://github.com/sbt/sbt-assembly/blob/master/src/main/scala/sbtassembly/Plugin.scala
  [17]: https://github.com/harrah/xsbt/blob/0.10/project/Proguard.scala
  [18]: https://github.com/harrah/xsbt/wiki/sbt-0.10-plugins-list
  [19]: https://github.com/siasia/xsbt-web-plugin/blob/master/src/main/scala/WebPlugin.scala
  [20]: https://github.com/ijuma/sbt-idea/blob/sbt-0.10/src/main/scala/org/sbtidea/SbtIdeaPlugin.scala
  [21]: http://harrah.github.com/xsbt/latest/sxr/index.html
  [22]: http://harrah.github.com/xsbt/latest/api/index.html
  [23]: https://github.com/codahale/assembly-sbt/blob/development/src/main/scala/assembly/AssemblyBuilder.scala
  [24]: https://github.com/harrah/xsbt/blob/0.10/main/Structure.scala#L432
  [25]: https://github.com/harrah/xsbt/wiki/Mapping-Files
  [26]: http://groups.google.com/group/simple-build-tool
  [27]: http://suereth.blogspot.com/2011/09/sbt-and-plugin-design.html
  [28]: https://github.com/jsuereth/xsbt-ghpages-plugin
  [29]: http://vimeo.com/20263617
  [30]: http://days2011.scala-lang.org/node/138/285
  [31]: https://github.com/harrah/xsbt/wiki/Plugins-Best-Practices
  [32]: https://github.com/eed3si9n/eed3si9n.com/blob/master/original/sbt-010-guide.ja.md
  [33]: https://github.com/harrah/xsbt/wiki/Inspecting-Settings
  [34]: https://github.com/harrah/xsbt/issues/202
  