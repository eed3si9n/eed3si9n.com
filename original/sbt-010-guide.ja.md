最近になってやっと sbt 0.10 に取り組み始めたが、手始めにプラグインの移植をすることにした。これはちゃんとしたチュートリアではないし、事実関係を誤認していることも多々あると思うけど、これから sbt 0.10 を始める人やプラグインを書こうと思ってる人には役に立つ内容になったと思う。

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
sbt 0.10 に深みを与えているのが、`settings` のエントリーのそれぞれが別のキーへの依存性を宣言できるということにある（僕が「キー」と言う時は、設定値とタスクという意味だが、分かってくれたと思う）。
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

## 基本的な概念 (スコープ、別名コンフィグレーション)
`settings` のもう一つの興味深い側面は、エントリーと宣言された依存性の両者がコンフィグレーションの中にスコープする (scope) ことができることだ。意味不明？
例えば、テストを走らせた後で実行可能な jar ファイルを作成する `assembly` というタスクを定義するとする。プラグインの定義では、こんな感じになる:
    
<scala>val assembly = TaskKey[Unit]("assembly")

lazy val assemblySettings: Seq[sbt.Project.Setting[_]] = Seq(
  assembly <<= (test in Test) map { _ =>
    // do something
  }
)</scala>

上記のコードの、`test in Test` がスコープ付きキー (scoped key) の例だ。シェルからは `test:test` として呼び出すことができる。

これではユーザは `test in Test` への依存性から抜け出せないと見ることもできる。これを直すには独自の `Assembly` という名前のスコープを作ればいい。

<scala>val Assembly = config("assembly")
val assembly = TaskKey[Unit]("assembly")

lazy val assemblySettings: Seq[sbt.Project.Setting[_]] = Seq(
  assembly <<= (test in Assembly) map { _ =>
    // do something
  },
  test in Assembly <<= (test in Test) map { x => x }
)</scala>

もし、なんらかの理由でユーザがテストを走らせたくなければ、本家の `test` タスクに影響を与えずに `test in Assembly` をオーバーライドすることができる。この機能はとても役に立つものなので、キーの列を自動的にスコープに入れる `inConfig` という簡易記法を、Mark は提供してくれた。あと、毎回 `map { x => x}` というパターンが出てくるのがカッコ悪いなと思ったいた所、Mark が `identity` と書けるよ、とメーリングリストで教えてくれた。上記のコードは以下のように書きなおすことができる:
	
<scala>val Assembly = config("assembly")
val assembly = TaskKey[Unit]("assembly")

lazy val assemblySettings: Seq[sbt.Project.Setting[_]] = inConfig(Assembly)(Seq(
  assembly <<= (test) map { _ =>
    // do something
  },
  test <<= (test in Test).identity
)) ++
Seq(
  assembly <<= (assembly in Assembly).identity
)</scala>

このスコープによって全てのメソッドとフィールドにプレフィックスを付ける必要がなくなり、一般的なキー名を再利用することを推奨する形になっている。

**更新 (2011月9月16日)**:
sbt はプラグインの全てのメンバをワイルドカードでインポートしてしまう。名前の衝突を避けるため、Josh Suereth は回避策のパターンを考案し、[SBT and Plugin design][27] にて公開した。以下にそれを改良したものを示す:

<scala>val assembly = TaskKey[Unit]("assembly")
  
class Assembly {}  
object Assembly extends Assembly {
  val Config = config("assembly")
  implicit def toConfigKey(x: Assembly): ConfigKey = ConfigKey(Config.name)
  
  lazy settings: Seq[sbt.Project.Setting[_]] = inConfig(Config)(Seq(
    assembly <<= (test) map { _ =>
      // do something
    },
    test <<= (test in Test).identity
  )) ++
  Seq(
    assembly <<= (assembly in Config).identity
  ) 
}</scala>

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
- [eed3si9n/sbt-assembly][16]
- [softprops/coffeescripted-sbt][15]
- [siasia/xsbt-web-plugin][19]
- [Proguard.scala][17]
- [ijuma/sbt-idea][20]
- [jsuereth/xsbt-ghpages-plugin][28]

## 0.7 からの小さな変更点を覚える
このガイドを書く動機となったのは、[codahale/assembly-sbt][23] を [eed3si9n/sbt-assembly][16] として sbt 0.10 に移植する際につまずいた細々とした名前の変更やその他の変更点だ。以下にこの二つのプラグインを並べて変更点を見ていきたい。

### バージョン番号
ビフォー (build.properties にて):
<scala>project.version=0.1.1
</scala>

アフター (build.sbt にて):
<scala>posterousNotesVersion := "0.4"

version <<= (sbtVersion, posterousNotesVersion) { (sv, nv) => "sbt" + sv + "_" + nv }</scala>

ソースパッケージとして配布されていた 0.7 プラグインと違い、0.10 プラグインはバイナリとしてパッケージされる。これにより特定の sbt のバージョンへの依存性が出てくるようになった。これまでのところ 0.10.0 と 0.10.1 が出ているけど、0.10.0 を使ってコンパイルされたプラグインは 0.10.1 では動作しない。回避策として、上記のバージョン番号規約を採用している。これは、将来的にちゃんとした対策がなされるはずなので、今後も注意していく必要がある。

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
  lazy val settings: Seq[sbt.Project.Setting[_]] = inConfig(Config)(Seq(
    ...
  ))</scala>

オーバーライド可能なメソッドを定義する代わりに、プラグインでは後からユーザが `seq(...)` で読み込める `sbt.Project.Setting[_]` 列を作る。こうすることで、ビルドの作者はプラグインの設定値を読み込むかどうかをプロジェクトごとに決めることができる。唯一の例外としては、グローバルなコマンドを定義する場合で、そのときは `settings` をオーバーライドする。

### オーバーライドされることを想定した設定値
ビフォー:
<scala>  def assemblyJarName = name + "-assembly-" + this.version + ".jar"
</scala>

アフター:
<scala>object Assembly extends Assembly {
  ...
  lazy val jarName           = SettingKey[String]("jar-name") in Config
  ...
  lazy val settings: Seq[sbt.Project.Setting[_]] = inConfig(Config)(Seq(
    jarName <<= (name, version) { (name, version) => name + "-assembly-" + version + ".jar" },
    ...
  ))
}</scala>

`settings` の中に他のキー (`name` と `version`) への依存性を宣言したエントリーを定義する。Quick Configuration DSL は、このペアに対して[`apply`][24] を injected method として加えるため、直後に関数値を渡すことで `jarName` キーの値を計算することができる。スコープとモジュール性のおかげで、この設定値は `assembly` というプレフィックス無しで `jarName` と名付けることができる。これは `Assembly` オブジェクトにラッピングされているため、build.sbt からは `Assembly.jarName` として呼び出す。
  
### Quick Configuration DSL の静的型は `Initialize[A]`
ビフォー:
<scala>  def assemblyTask(...)

  lazy val assembly = assemblyTask(...) dependsOn(test) describedAs("Builds an optimized, single-file deployable JAR.")</scala>

アフター:
<scala>  val assembly = TaskKey[File]("assembly", "Builds a single-file deployable jar.")
  ...
  private def assemblyTask: Initialize[Task[File]] = 
    (test, ...) map { (t, ...) =>
    }
  
  lazy val settings: Seq[sbt.Project.Setting[_]] = inConfig(Config)(Seq(
    assembly <<= assemblyTask,
    ...
  ))  
</scala>

全てを `settings` を詰め込むこともできるが、それはすぐに散らかってしまう。Keith Irwin 氏の [coffeescripted-sbt][15] の実装を真似て僕もコードを整理してみた。

### `outputPath` は `target` であり、`Path` は `sbt.File` だ
ビフォー:
<scala>  def assemblyOutputPath = outputPath / assemblyJarName
</scala>

アフター:
<scala>  val outputPath        = SettingKey[File]("output-path")
  ...
  lazy val settings: Seq[sbt.Project.Setting[_]] = inConfig(Config)(Seq(
    outputPath <<= (target, jarName) { (t, s) => t / s },
    ...
  ))</scala>

以前 `outputPath` と呼ばれていたものは、今は `target: SettingKey[File]` と呼ばれるキーだ。

`sbt.File` は `java.io.File` の別名 (alias) であり、それは暗黙に `sbt.RichFile` に変換され、これは 0.7 における `Path` のかわりとなる。ただ `dir: File` と言うだけで、`dir / name` と書くことができる。

### `runClasspath` は `fullClasspath in Runtime`
ビフォー:
<scala>  def assemblyClasspath = runClasspath
</scala>

アフター:
<scala>  lazy val settings: Seq[sbt.Project.Setting[_]] = inConfig(Config)(Seq(
    fullClasspath <<= (fullClasspath in Runtime).identity,
    ...
  ))</scala>
  
### 既存のキーを再利用する
ビフォー:
<scala>  def assemblyClasspath = runClasspath
</scala>

アフター:
<scala>  lazy val settings: Seq[sbt.Project.Setting[_]] = inConfig(Config)(Seq(
    fullClasspath <<= (fullClasspath in Runtime).identity,
    ...
  ))</scala>

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
      
  lazy val settings: Seq[sbt.Project.Setting[_]] = inConfig(Config)(Seq(
    excludedFiles := assemblyExcludedFiles _,
    ...
  ))</scala>

これは少し複雑だ。sbt 0.10 は振る舞いをオーバーライドをするのに継承関係に頼らなくなったから、このメソッドを key-value の `settings` のもとで管理する必要がある。Scala では、メソッドを変数に代入するには関数値に変更する必要があるから、`assemblyExcludedFiles _` と書く。この関数値の型は `Seq[File] => Seq[File]` だ。

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
  [16]: https://github.com/eed3si9n/sbt-assembly/blob/sbt0.10/src/main/scala/assembly/AssemblyPlugin.scala
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
