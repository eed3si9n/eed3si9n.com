  [1]: https://github.com/sbt/sbt/blob/541375cde65635a7d2c6132d1ed96aaaefb38466/util/collection/src/main/scala/sbt/Settings.scala#L414
  [2]: https://github.com/sbt/sbt/blob/541375cde65635a7d2c6132d1ed96aaaefb38466/main/settings/src/main/scala/sbt/Structure.scala#L116
  [3]: https://github.com/sbt/sbt/blob/541375cde65635a7d2c6132d1ed96aaaefb38466/main/settings/src/main/scala/sbt/Structure.scala#L138
  [4]: https://github.com/sbt/sbt/blob/541375cde65635a7d2c6132d1ed96aaaefb38466/main/settings/src/main/scala/sbt/std/InputWrapper.scala#L93
  [5]: http://www.scala-sbt.org/0.13.0/docs/Extending/Plugins-Best-Practices.html
  [6]: https://github.com/sbt/sbt-assembly
  [7]: https://github.com/sbt/sbt-assembly/blob/dcbc1a41faa5baa26c048993ca4e6ce280b96946/src/main/scala/sbtassembly/Plugin.scala#L360
  [8]: http://www.scala-sbt.org/0.13.0/docs/Getting-Started/Scopes.html
  [8ja]: http://scalajp.github.io/sbt-getting-started-guide-ja/scope/
  [9]: http://stackoverflow.com/questions/18611316
  [10]: http://stackoverflow.com/questions/19201509
  [11]: https://github.com/akka/akka/blob/e05d30aeaacdb99ea25718bb5de6118fbb37f3ae/project/Unidoc.scala
  [12]: https://github.com/sbt/sbt-unidoc
  [13]: http://www.scala-sbt.org/0.13.0/docs/Detailed-Topics/Tasks.html#getting-values-from-multiple-scopes
  [202]: https://github.com/sbt/sbt/issues/202

警告: この sbt についての覚え書きは中級ユーザ向けだ。

### セッティングシステム

sbt 0.12 同様に sbt 0.13 の中心にあるのはセッティングシステムだ。[Settings.scala][1] を見てみよう:

<scala>
trait Init[Scope] {
  ...

  final case class ScopedKey[T](
    scope: Scope,
    key: AttributeKey[T]) extends KeyedInitialize[T] {
    ...
  }

  sealed trait Initialize[T] {
    def dependencies: Seq[ScopedKey[_]]
    def evaluate(map: Settings[Scope]): T
    ...
  }

  sealed class Setting[T] private[Init](
    val key: ScopedKey[T], 
    val init: Initialize[T], 
    val pos: SourcePosition) extends SettingsDefinition {
    ...
  }
}
</scala>

`pos` を無視すると、型 `T` のセッティングは、型が `ScopedKey[T]` である左辺項 `key` と型が `Initialize[T]` である右辺項 `init` によって構成される。

### 第一次元

便宜的に `ScopedKey[T]` は、現在のプロジェクトなどのデフォルトのコンテキストにスコープ付けされた `SettingKey[T]` や `TaskKey[T]` だと考えることができる。すると残るのは `Initialize[T]` だけで、これは依存キーの列と何らか方法で `T` へと評価される能力を持っている。`Initialized[T]` に直接作用するのはキーに実装されている `<<=` 演算子だ。[Structure.scala][2] 参照:

<scala>
sealed trait DefinableSetting[T] {
  final def <<= (app: Initialize[T]): Setting[T] = 
    macro std.TaskMacro.settingAssignPosition[T]
  ...
}
</scala>

名前から推測して、このマクロは `pos` を代入しているのだと思う。sbt 0.12 においてはキーのタプルにモンキーパッチされた `apply` や `map` メソッドによって `Initialize[T]` が構築された。sbt 0.13 ではスマートな `:=` 演算子を使うことができる。[Structure.scala][3] 参照:

<scala>
sealed trait DefinableTask[T] {
  def := (v: T): Setting[Task[T]] = 
    macro std.TaskMacro.taskAssignMacroImpl[T]
}
</scala>

素の `:=` 演算子は型が `T` の引数を受け取り `Setting[T]` もしくは `Setting[Task[T]]` のインスタンスを返す。そのインスタンスの内部には `Initialize[T]` が作られたと予想できる。マクロに渡されたコードの中でキーが `value` メソッドを呼び出すと、自動的に式全体が `<<=` 式へと変換される。

<scala>
name := {
  organization.value + "-" + baseDirectory.value.getName
}
</scala>

は

<scala>
name <<= (organization, baseDirectory) { (o, b) =>
  o + "-" + b  
}
</scala>

へと展開される。便利なのは `:=` がセッティングとタスクの両方に使えることだ。

<scala>
val startServer = taskKey[Unit]("start server.")
val integrationTest = taskKey[Unit]("integration test.")

integrationTest := {
  val x = startServer.value
  println("do something")
}

startServer := {
  println("start")
}
</scala>

`start.value` は実行時に評価され、キーに関連付けられた値が返される。このようなタスク間の依存性は Ant の他のビルドツールにも見ることができる。これが sbt における第一の次元だ。

`:=` が少し崩れてくるのはタスクを他の場所で定義しようとした場合だ。

<scala>
val orgBaseDirName = {
  organization.value + "-" + baseDirectory.value.getName
}

name := orgBaseDirName
</scala>

これを読み込むと以下のエラーが返ってくる:

<code>
build.sbt:14: error: `value` can only be used within a task or setting macro, such as :=, +=, ++=, Def.task, or Def.setting.
  organization.value + "-" + baseDirectory.value.getName
               ^
</code>

ブロックを適切なマクロで包囲するためには以下のように書かなくてはいけない:

<scala>
val orgBaseDirName: Def.Initialize[String] = Def.setting {
  organization.value + "-" + baseDirectory.value.getName
}

name := orgBaseDirName
</scala>

`orgBaseDirName` の型注釈は必要ないが、この型をハッキリと知っておくことは役に立つ。次のエラーメッセージを見ても驚かないはずだ:

<code>
build.sbt:17: error: type mismatch;
 found   : sbt.Def.Initialize[String]
 required: String
name := orgBaseDirName
        ^
[error] Type error in expression
</code>

`:=` は `String` を期待しているので、`Initialize[String]` を評価する必要がある。興味深いことに `value` メソッドはここでも動作する。`value` メソッドは `MacroValue[T]` にて定義されている。[InputWrapper.scala][4]　参照:

<scala>
sealed abstract class MacroValue[T] {
  @compileTimeOnly("`value` can only be used within a task or setting macro, such as :=, +=, ++=, Def.task, or Def.setting.")
  def value: T = macro InputWrapper.valueMacroImpl[T]
}
</scala>

暗黙の型変換が定義されていて、匿名の `Initialize[T]` インスタンスやセッティングキー (実はキーも `Initialize[T]` だ) に `value` メソッドが注入される。

### タスク毎のセッティング

sbt の第二の次元はキーのタスクスコープ付けだ。タスクスコープは以前からあったものだけど sbt のプラグインコミュニティーがキーをどのように活用すべきかということを模索してるうちに顕著なものとなってきた。[Brian (@bmc)](https://github.com/bmc)、 [Doug (@softprops)](https://github.com/softprops)、 [Josh (@jsuereth)](https://github.com/jsuereth)、 そして sbt 作者の [Mark (@harrah)](https://github.com/harrah) と並んで僕もわずかながらこのプロセスに貢献した。多くの ML への投稿や irc チャットから出てきたのが以下のものだ:

- [Plugins Best Practices][5]
- [sbt/sbt#202: Task-scoped keys][202]

[sbt/sbt-assembly][6] を具体例として見ると、`jarName` は以下のようにカスタマイズされる:

<scala>
import AssemblyKeys._

assemblySettings

jarName in assembly := "something.jar"
</scala>

これは特定のセッティングのビルド定義内での影響を制限することができる便利な概念だ。もう一つ例をみてみよう:

<scala>
import AssemblyKeys._

assemblySettings

test in assembly := {}
</scala>

`assembly` タスクは fat jar を作る前にデフォルトでは `test` タスクを実行するが、上記の設定によってビルドユーザはその振る舞いを無効化した。実際に何が行われているかと言うと、`assembly` タスクは `test` タスクには直接依存しないように書かれている。代わりに、それは `assembly::test` タスクに依存している。[Plugin.scala][7] 参照:

<scala>
private def assemblyTask(key: TaskKey[File]): Initialize[Task[File]] = Def.task {
  val t = (test in key).value
  val s = (streams in key).value
  Assembly((outputPath in key).value, (assemblyOption in key).value,
    (packageOptions in key).value, (assembledMappings in key).value,
    s.cacheDirectory, s.log)
}

lazy val baseAssemblySettings: Seq[sbt.Def.Setting[_]] = Seq(
  assembly := assemblyTask(assembly).value,
  ...
  test in assembly := (test in Test).value,
  ...
}
</scala>

`test` キーを `assembly` タスクにスコープ付けすることで、sbt-assembly はビルドユーザが拡張できるポイントを提供している。

### コンフィギュレーション

コンフィギュレーションは sbt の第三の次元で、あまりよく理解されていないものだ。始める sbt の[スコープ][8ja]では以下のように定義されている:

> コンフィギュレーション（configuration）は、ビルドの種類を定義し、独自のクラスパス、ソース、生成パッケージなどをもつことができる。 コンフィギュレーションの概念は、sbt が マネージ依存性 に使っている Ivy と、[MavenScopes](http://maven.apache.org/guides/introduction/introduction-to-dependency-mechanism.html#Dependency_Scope) に由来する。

肝心な点はコンフィギュレーションは独自のクラスパスとソースを持つということだ。デフォルトのコンフィギュレーション以外でもっとも広く使われているものに `Test` がある。これは独自のソースコードとライブラリを持っている良い例だ。

キーをコンフィギュレーションにスコープ付けする普通の構文は Scala だと `key in Test` で、シェルからだと `test:key` だ。マネージライブラリは少し変わっていて `%` を使って `libraryDependencies` のコンフィギュレーションを表す。

<scala>
libraryDependencies += "org.specs2" %% "specs2" % "2.2.3" % "test"
</scala>

`% "test"` は `% "test->default"` の略で、依存ライブラリの `Compile` アーティファクトを落としてきてこのプロジェクトの `Test` コンフィギュレーションに入れる。

比較的簡単にカスタムのコンフィギュレーションを定義することはできる。だけど、セッティングの木構造を正しく定義するには少しコツがいる。StackOverflow で僕が答えた sbt 関連の質問のいくつかは、コンフィギュレーションをどう設定するかという問題を解くことに転化した。

例えば [sbt-assembly を用いて異なる外部依存ライブラリを用いた複数の実行可能 jar を作る方法][9]を見てみよう。以下が僕が投稿した `build.sbt` だ:

<scala>
import AssemblyKeys._

val Dispatch10 = config("dispatch10") extend(Compile)
val TestDispatch10 = config("testdispatch10") extend(Dispatch10)
val Dispatch11 = config("dispatch11") extend(Compile)
val TestDispatch11 = config("testdispatch11") extend(Dispatch11)

val root = project.in(file(".")).
  configs(Dispatch10, TestDispatch10, Dispatch11, TestDispatch11).
  settings( 
    name := "helloworld",
    organization := "com.eed3si9n",
    scalaVersion := "2.10.2",
    compile in Test := inc.Analysis.Empty,
    compile in Compile := inc.Analysis.Empty,
    libraryDependencies ++= Seq(
      "net.databinder.dispatch" %% "dispatch-core" % "0.10.0" % "dispatch10", 
      "net.databinder.dispatch" %% "dispatch-core" % "0.11.0" % "dispatch11",
      "org.specs2" %% "specs2" % "2.2" % "testdispatch10",
      "org.specs2" %% "specs2" % "2.2" % "testdispatch11",
      "com.github.scopt" %% "scopt" % "3.0.0"
    )
  ).
  settings(inConfig(Dispatch10)(Defaults.configSettings ++ baseAssemblySettings ++ Seq(
    sources := (sources in Compile).value,
    resources := (resources in Compile).value,
    internalDependencyClasspath := Nil,
    test := (test in TestDispatch10).value,
    test in assembly := test.value,
    assemblyDirectory in assembly := cacheDirectory.value / "assembly-dispatch10",
    jarName in assembly := name.value + "-assembly-dispatch10_" + version.value + ".jar"
  )): _*).
  settings(inConfig(TestDispatch10)(Defaults.testSettings ++ Seq(
    sources := (sources in Test).value,
    resources := (resources in Test).value,
    internalDependencyClasspath := Seq((classDirectory in Dispatch10).value).classpath
  )): _*).
  settings(inConfig(Dispatch11)(Defaults.configSettings ++ baseAssemblySettings ++ Seq(
    sources := (sources in Compile).value,
    resources := (resources in Compile).value,
    internalDependencyClasspath := Nil,
    test := (test in TestDispatch11).value,
    test in assembly := test.value,
    assemblyDirectory in assembly := cacheDirectory.value / "assembly-dispatch11",
    jarName in assembly := name.value + "-assembly-dispatch11_" + version.value + ".jar"
  )): _*).
  settings(inConfig(TestDispatch11)(Defaults.testSettings ++ Seq(
    sources := (sources in Test).value,
    resources := (resources in Test).value,
    internalDependencyClasspath := Seq((classDirectory in Dispatch11).value).classpath
  )): _*)
</scala>

同一のメインとテストのソースを使って上記のビルドは Dispatch 0.10 と 0.11 を使う複数のコンフィギュレーションを設定する。`dispatch10:assembly` を実行すると Dispatch 0.10 を用いた fat jar を作り、`dispatch11:assembly` を実行すると Dispatch 0.11 を用いた fat jar を作る。これは sbt-assembly がコンフィギュレーション中立な設計になっていることで可能となった。

コンフィギュレーションを使ったもう一つの例は[scalariform を使って sbt ビルドファイルを自動的にフォーマットするには?][10] という質問だ。以下が `scalariform.sbt` だ:

<scala>
import scalariform.formatter.preferences._
import ScalariformKeys._

lazy val BuildConfig = config("build") extend Compile
lazy val BuildSbtConfig = config("buildsbt") extend Compile

noConfigScalariformSettings

inConfig(BuildConfig)(configScalariformSettings)

inConfig(BuildSbtConfig)(configScalariformSettings)

scalaSource in BuildConfig := baseDirectory.value / "project"

scalaSource in BuildSbtConfig := baseDirectory.value

includeFilter in (BuildConfig, format) := ("*.scala": FileFilter)

includeFilter in (BuildSbtConfig, format) := ("*.sbt": FileFilter)

format in BuildConfig := {
  val x = (format in BuildSbtConfig).value
  (format in BuildConfig).value
}

preferences := preferences.value.
  setPreference(AlignSingleLineCaseStatements, true).
  setPreference(AlignParameters, true)
</scala>

`build:scalariformFormat` を実行すると、`**.sbt` と `project/**.scala` にマッチするファイルがフォーマットされる。これも sbt-scalariform がコンフィギュレーション中立なお陰で可能となった。だけど、`sources` の代わりに `includeFilter` を使っているせいで一つの仕事をするのに二つのコンフィギュレーションを作る必要があった。

### ScopeFilter

Akka プロジェクトに知る人ぞ知る [Unidoc.scala][11] というファイルがある。これは `unidoc` タスクを定義してビルドで定義される全プロジェクトのソースコードを集約して、それに対して Scaladoc を実行する。ビルドを小さなサブプロジェクトにモジュール化しているプロジェクトにとって非常に便利なものだ。

当然僕がやったのはこのコードを拝借してきて [sbt-unidoc][12] というプラグインにすることだった。ところが数週間前 [@inkytonik](https://github.com/inkytonik) にこの `unidoc` を `Test` コンフィギュレーションに対して実行したいと言われた。散々コンフィギュレーション中立性が云々と言ってきたのに、このざまだ。

複数のプロジェクトやコンフィギュレーションからのソースの集約を実装する段階になって、sbt 0.13 で追加された ScopeFilter という逸品に巡りあった。詳細は [Getting values from multiple scopes][13] に書かれている。

> 複数のスコープから値を取得する式の一般形は:
>
>     <setting-or-task>.all(<scope-filter>).value
>
> `all` メソッドはタスクとセッテイングに暗黙に加えられる。

以下が全てのソースを集約する例だ:

<scala>
val filter = ScopeFilter(inProjects(core, util), inConfigurations(Compile))
// each sources definition is of type Seq[File],
//   giving us a Seq[Seq[File]] that we then flatten to Seq[File]
val allSources: Seq[Seq[File]] = sources.all(filter).value
allSources.flatten
</scala>

sbt-unidoc を修正するためにはユーザが再配線できるように `ProjectFilter` と `ConfigurationFilter` それぞれのセッティングを作るだけいい。プロジェクトを除外する例:

<scala>
val root = (project in file(".")).
  settings(commonSettings: _*).
  settings(unidocSettings: _*).
  settings(
    name := "foo",
    unidocProjectFilter in (ScalaUnidoc, unidoc) := inAnyProject -- inProjects(app)
  ).
  aggregate(library, app)
</scala>

複数のコンフィギュレーションを加える例:

<scala>
val root = (project in file(".")).
  settings(commonSettings: _*).
  settings(unidocSettings: _*).
  settings(
    name := "foo",
    unidocConfigurationFilter in (TestScalaUnidoc, unidoc) := inConfigurations(Compile, Test),
  ).
  aggregate(library, app)
</scala>

内部では、`sources` の `all` を呼び出している:

<scala>
val f = (unidocScopeFilter in unidoc).value
sources.all(f)
</scala>

sbt の第四の次元はプロジェクトで、僕たちは第三と第四次元空間内を移動する乗り物を手にしたことになる。どこに行くかは僕たち次第だ。
