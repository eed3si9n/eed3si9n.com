---
title:       "sbt 0.13.0 の変更点"
type:        story
date:        2013-07-24
changed:     2013-10-07
draft:       false
promote:     true
sticky:      false
url:         /ja/sbt-0130-changes
aliases:     [ /node/142 ]
tags:        [ "sbt" ]
---

  [#485]: https://github.com/sbt/sbt/issues/485
  [#554]: https://github.com/sbt/sbt/issues/554
  [#608]: https://github.com/sbt/sbt/issues/608
  [#609]: https://github.com/sbt/sbt/issues/609
  [#613]: https://github.com/sbt/sbt/issues/613
  [#665]: https://github.com/sbt/sbt/issues/665
  [#677]: https://github.com/sbt/sbt/issues/677
  [#697]: https://github.com/sbt/sbt/issues/697
  [#702]: https://github.com/sbt/sbt/issues/702
  [#709]: https://github.com/sbt/sbt/issues/709
  [#723]: https://github.com/sbt/sbt/issues/723
  [#735]: https://github.com/sbt/sbt/issues/735
  [#793]: https://github.com/sbt/sbt/issues/793
  [setup]: http://www.scala-sbt.org/0.13.0/docs/Getting-Started/Setup.html

## 概要

### 互換性に影響のある新機能、変更点、バグ修正

- sbt とビルド定義を Scala 2.10 に移行した。
- `project/plugins/` 内に置かれたプラグインの設定ファイルのサポートを廃止した。これは 0.11.2 より廃止予定になっていた。
- `set` コマンドにおいてセッティングの右辺項内のタブ補完を廃止した。新たに追加されたタスクマクロがこのタブ補完を不要にするからだ。
- キーの慣用的な書き方はこれよりキャメルケース camelCase のみとする。詳細は後ほど。
- Maven との互換性を正すため、テストのデフォルトの classifier を `tests` に修正した。
- グローバルなセッティングとプラグインのディレクトリをバージョン付けるようにした。デフォルトでは、グローバルセッティングは `~/.sbt/0.13/` に、グローバルプラグインは `~/.sbt/0.13/plugins/` に置かれる。`sbt.global.base` システムプロパティを使った明示的なオーバーライドは継続して適用される。([#735][#735])
- scalac にファイルを渡すときに sbt が行なっていた正規化 (canonicalization) を廃止した。([#723][#723])
- 各プロジェクトがそれぞれ固有の `target` ディレクトリを持つことを強制するようにした。
- 依存ライブラリの Scala バージョンをオーバーライドしないようにした。これによって個別の設定が異なる Scala バージョンに依存できるようになり、`scala-library` 以外の Scala 依存性を通常のライブラリ依存性と同じように扱えるようになった。しかし、これによってその他の `scala-library` 以外の Scala ライブラリが最終的に `scalaVersion` 以外のバージョンに解決される可能性も生まれた。
- Cygwin での JLine の設定が変更された。[Setup][setup] 参照。
- Windows 上での JLine と Ansi コードの振る舞いが改善された。CI サーバ内では `-Dsbt.log.format=false` を指定して明示的に Ansi コードを無効にする必要があるかもしれない。
- フォークされたテストや run がプロジェクトのベースディレクトリをカレント・ワーキング・ディレクトリとして用いるようにした。
- `compileInputs` は `Compile` ではなく `(Compile,compile)` 内で定義するようにした。
- テストの実行結果は [`Tests.Output`](http://www.scala-sbt.org/0.13.0/api/#sbt.Tests$$Output) になった。

### 新機能

- `boot.properties` 内のレポジトリをデフォルトのプロジェクトの resolver として用いる。`boot.properties` 内のレポジトリに `bootOnly` と書くことでデフォルトでプロジェクトに使用されないようにすることができる。 (Josh S., [#608][#608])
- .sbt ファイル内で `val` や `def` を書けるようにした。詳細は後ほど。
- .sbt ファイル内でプロジェクトを定義できるようにした。`Project` 型の `val` をビルドに追加することになる。詳細は後ほど。
- セッティング、タスク、およびインプット・タスクの新構文。詳細は後ほど。
- `autoAPIMappings := true` とすることで、依存ライブラリの外部 API scaladoc に自動的にリンクするようにした。これは Scala 2.10.1 を必要とし、`apiURL` を使って依存ライブラリの scaladoc の場所を指定する必要がある。`apiMappings` タスクを使って手動でマッピングを提供することもできる。
- スイッチコマンドを使って一時的に Scala ホームディレクトリを設定できるようにした: `++ scala-version=/path/to/scala/home`。 だたし、`scala-version` の部分は省略可能だが、マネージ依存性の解決に用いられる。
- `~/.m2/repository` に公開するための `publishM2` コマンドを追加した。([#485][#485])
- ルートプロジェクトが定義されていない場合は、全てのプロジェクトを集約するデフォルトのルートプロジェクトを用いる。([#697][#697])
- 複数のプロジェクトやコンフィギュレーションからタスクやセッティングを取得するための新しい API を追加した。[Getting values from multiple scopes](http://www.scala-sbt.org/0.13.0/docs/Detailed-Topics/Tasks.html#multiple-scopes)参照。
- テストフレームワークの機能をより良くサポートするためにテストインターフェイスを改善した。（詳細は）
- `export` コマンド
  - タスクの場合は、export ストリームの内容を表示する。慣例としては、タスクと等価のコマンドラインを表示する。例えば、`compile`、`doc`、`console` はそれらを実行する近似的なコマンドラインを表示する。
  - セッティングの場合は、ロガーを経由せずにセッティングの値を直接表示する。

### バグ修正

- 依存ライブラリの衝突を警告しないようにした。代わりに [conflict manager](http://www.scala-sbt.org/0.13.0/docs/Detailed-Topics/Library-Management.html#conflict-management) を設定する。([#709][#709])
- フォークされたテストを実行するときに Cleanup と Setup を実行するようにした。別の JVM で実行されるため、クラスローダは使うことができない。

### 改善点

- API 抽出フェーズを、`typer` フェーズではなく `picker` フェーズの後で実行することで typer の後にコンパイラプラグインを置けるようにした。(Adriaan M., [#609][#609])
- セッティングのソース内における位置を記録するようにした。`inspect` は定義された値に関わる全てのセッティングの位置を表示する。
- `Build.rootProject` 内にルートプロジェクトを明示的に指定できるようにした。
- キャッシュ情報を保存するためのディレクトリが必要なタスクは `stream` の `cacheDirectory` を使えるようになった。これは `cacheDirectory` セッティングに取って代わる。
- フォークされた `run` や `test` によって使われる環境変数が `envVars` によって設定できるようになった。これは `Task[Map[String,String]]` だ。([#665][#665])
- コンパイルに失敗した場合にクラスファイルを復旧するようにした。これはエラーがインクリメンタルコンピレーションの後ろの方の過程で発生しているが修正するには元の変更されたファイルを直す必要がある場合に役に立つ。
- デフォルトプロジェクトの自動生成ID を改善した。([#554][#554])
- scala コマンドによる余計なクラスローダを回避するためにフォークされた `run` は java コマンドを使うようにした。([#702][#702])
- `autoCompilerPlugins` が内部依存プロジェクト内で定義されたコンパイラプラグインを使えるようにした。ただし、プラグインのプロジェクトは `exportJars := true` を定義する必要がある。プラグインに依存するには `...dependsOn(... % Configurations.CompilerPlugin)` と書く。
- 非プライベートなテンプレートの親クラスを追跡することで、インクリメンタルコンピレーション時により少なく小さい中間ステップを必要とするようにした。
- インクリメンタルコンパイラによって抽出された API の内部構造をデバッグするためのユーティリティを追加した。(Grzegorz K., [#677][#677], [#793][#793])
- `consoleProject` はセッティングの値の取得とタスクの実行を統合した構文を提供する。[Console Project](http://www.scala-sbt.org/0.13.0/docs/Detailed-Topics/Console-Project.html) 参照。

### その他

- Eclipse ユーザの便宜のために sbt プロジェクト自体のソースのレイアウトをパッケージ名に沿ったものに変更した。(Grzegorz K., [#613][#613])

## 大きな変更点の詳細

### キャメルケースのキー名

これまでのキー名の書き方は、Scala の識別子はキャメルケースで、コマンドラインではハイフンでつなげた小文字という慣用だったが、これからは両方ともキャメルケースに統一する。既存のハイフン付けされたキー名に対してもキャメルケースを使うことができ、また既にあるタスクやセッティングに対しては継続してハイフン付けされた形式も受け付ける。しかし、タブ補完はキャメルケースのみを表示するようになる。

### 新しいキー定義メソッド

キーを定義するときに、キー名を二回書かなくても済む新しいメソッドが追加された:

```scala
val myTask = taskKey[Int]("myTask の説明文。(省略不可)")
```

キーの名前は `taskKey` マクロによって `val` の識別子から抜き出されるため、リフレクションや実行時のオーバーヘッドはかからない。説明文は省略不可であり、`taskKey` メソッドが小文字の `t` から始まることに注意。セッティングとインプットタスクのための類似メソッド `settingKey` と `inputKey` もある。

### タスク、セッティングのための新しい構文

好きな時に新しい構文に移行できるように、旧構文もちゃんとサポートされていることを言っておきたい。多少は非互換性があるかもしれないし、これらは避ける事ができないかもしれないが、既存のビルドがそのまま動作しない場合は是非報告して欲しい。

新しい構文は `:=`、`+=`、`++=` をマクロとして実装しており、この3つだけを必須の代入メソッドとするように設計されている。他のセッティングやタスクの値を参照するには、セッティングやタスクに対して `value` メソッドを呼び出す。このメソッドはコンパイル時にマクロによって削除され、タスクやセッティングの実装は旧構文に変換される。

例えば、以下に `scalaVersion` の値を使って `scala-reflect` を依存ライブラリとして宣言する具体例をみてみる:

```scala
libraryDependencies += "org.scala-lang" % "scala-reflect" % scalaVersion.value
```

この `value` メソッドは `:=`、`+=`、もしくは `++=` の呼び出しの中だけで使うことができる。これらのメソッド外でセッティングやタスクを構築するには `Def.task` や `Def.setting` を使う。以下に具体例で説明する。

```scala
val reflectDep = Def.setting { "org.scala-lang" % "scala-reflect" % scalaVersion.value }

libraryDependencies += reflectDep.value
```

類似のメソッドとして `Parser[T]`、`Initialize[Parser[T]]` (パーサを提供するセッティング)、そして `Initialize[State => Parser[T]]` (現在の `State` を基に `Parser[T]` を提供するセッティング) に `parsed` メソッドが定義されている。このメソッドを使ってユーザからのインプットを使ったインプットタスクを定義する。

```scala
myInputTask := {
     // 標準的な空文字区切り引数パーサを定義する。
   val args = Def.spaceDelimited("<args>").parsed
     // セッティングの値とタスクの結果を使ってみる:
   println("Project name: " + name.value)
   println("Classpath: " + (fullClasspath in Compile).value.map(_.file))
   println("Arguments:")
   for(arg <- args) println("  " + arg)
}
```

詳細は、[Input Tasks](http://www.scala-sbt.org/0.13.0/docs/Extending/Input-Tasks.html) 参照。

タスクの失敗を期待して、失敗時の例外を受け取るには、`value` の代わりに `failure` メソッドを使う。これは `Incomplete` 型の値を返し、これは例外をラップする。成否にかかわらずタスクの結果を取得するには `Result[T]` を返す `result` を使う。

動的なセッティングとタスク (`flatMap`) は身ぎれいにされた。`Def.taskDyn` と `Def.settingDyn` メソッドを使って定義することができる。これらはそれぞれタスクとセッティングを返すことを期待する。

### .sbt 形式の改善

.sbt ファイル内に `val` や `def` が書けるようになった。これらもセッティング同様に空行のルールに従う必要があるが、複数の定義をまとめて書くことができる。

```scala
val n = "widgets"
val o = "org.example"

name := n

organization := o
```

全ての定義はセッティングの前にコンパイルされるが、定義は全てまとめて書くのがベスト・プラクティスだろう。現行では、定義が見える範囲はそれが定義された .sbt ファイル内に制限されている。これらは今のところは `consoleProject` や `set` コマンドからも見ることができない。全ての .sbt ファイルから見えるようにするには `project/` 内で Scala ファイルを使う。

`Project` 型の val は `Build` に追加されるため、.sbt ファイルだけを用いてマルチプロジェクトビルドが定義できるようになった。具体例で説明しよう。

```scala
lazy val a = Project("a", file("a")).dependsOn(b)

lazy val b = Project("b", file("sub")).settings(
   version := "1.0"
)
```

今のところは、これらはルートプロジェクトの .sbt ファイルからのみ定義するべきだ。

`Project` を定義する略記法として `project` というマクロが提供されている。これは構築される `Project` が直接 `val` に代入されることを要求する。この `val` の名前がプロジェクトID とベースディレクトリとしても使われる。上の例は以下のようにも書ける:

```scala
lazy val a = project.dependsOn(b)

lazy val b = project in file("sub") settings(
  version := "1.0"
)
```

このマクロは Scala ファイル内からも使うことができる。

### 自動的に追加されるセッティングの制御

sbt は `Project.settings` フィールドで明示的に定義されたセッティング以外にもいくつかの場所からセッティングを読み込む。プラグイン、グローバルセッティング、そして .sbt ファイルなどだ。新たに追加された `Project.autoSettings` メソッドはこれらの出どころを設定して、プロジェクトに含めるか否か、どの順番かを制御することができる。

`Project.autoSettings` は `AddSettings`型の値の列を受け取る。`AddSettings` のインスタンスは `AddSettings` コンパニオンオブジェクト内のメソッドによって構築される。設定可能なのはユーザ毎のセッティング (例えば、`~/.sbt` からなど)、.sbt ファイルからのセッティング、そしてプラグインのセッテイング (プロジェクトレベルのみ) だ。これらのインスタンスが `autoSettings` に渡された順に `Project.settings` に明示的に提供されたセッティングに追加される。

.sbt ファイルに関しては、`AddSettings.defaultSbtFiles` が通常通りプロジェクトのベースディレクトリ内の全ての .sbt ファイルを追加する。代替として `AddSettings.sbtFiles` は `File` の列を受け取り、標準的な .sbt フォーマットに従って読み込まれる。相対的なファイルはプロジェクトのベースディレクトリに対して解決される。

`AddSettings.plugins` メソッドに `Plugin => Boolean` を渡すことでプラグインセッティングはプラグイン毎に含めることができる。ここで制御されるセッティングはプロジェクト毎での自動セッティングのみだ。ビルド毎のセッティングとグローバルセッティングは常に含まれる。プラグインが手動で追加することを必要とするセッティングは手動で追加される必要がある。

例えば、

```scala
import AddSettings._

lazy val root = Project("root", file(".")) autoSettings(
   userSettings, allPlugins, sbtFiles(file("explicit/a.txt"))
)

lazy val sub = Project("sub", file("Sub")) autoSettings(
   defaultSbtFiles, plugins(includePlugin)
)

def includePlugin(p: Plugin): Boolean =
   p.getClass.getName.startsWith("org.example.")
```

### Scala 依存性の解決

(`scala-library` や `scala-compiler` のような) Scala 依存性は通常の `update` タスクを用いて解決されるようになった。そのため、

1. sbt を実行するのに必要なもの以外は Scala の jar ファイル群をブートディレクトリにコピーしなくなった。
2. Scala の SNAPSHOT は普通の SNAPSHOT 同様の振る舞いをする。特に、`update` を実行することで動的リビジョンを再解決するようになった。
3. Scala の jar ファイル群は他の依存ライブラリと同じリポジトリや設定で解決されるようになった。
4. `scalaHome` が設定されている場合は Scala 依存性は `update` 経由では解決せず指定されたディレクトリから取得するようになった。
5. sbt のための Scala バージョンは、引き続きランチャのために設定されたリポジトリ経由で解決される。

sbt が `compile`、`console` などの Scala に基づいたタスクを実行するためには、これまで通りコンパイラ及びその依存ライブラリにアクセスする必要がある。そのため、Scala コンパイラの jar とその依存ライブラリ (`scala-reflect.jar` や `scala-library.jar` など) は `scala-tool` コンフィグレーションにて定義され解決される (`scalaHome` が定義されていなければ)。デフォルトでは、このコンフィグレーションと依存ライブラリは自動的に sbt によって追加される。これは依存ライブラリが `pom.xml` や `ivy.xml` で設定されていたとしても発生するため、プロジェクトで使われる Scala のバージョンがプロジェクトに設定された resolver から解決可能であることを必要とする。

コンパイル、REPL などの Scala タスクに使われる Scala コンパイラとライブラリを sbt がどこから取得するかを手動で設定する場合は以下のうち 1つを実行する:

1. `scalaHome` を設定して特定のディレクトリにある既存の Scala jar ファイル群を使う。`autoScalaLibrary` が `true` なら、ここで見つかった library の jar はアンマネージクラスパスに追加される。
2. `managedScalaInstance := false` に設定して、明示的に `scalaInstance` を定義する。これは `ScalaInstance` 型で、コンパイラ、ライブラリ、その他の Scala を構成する jar 群を定義する。`autoScalaLibrary` が `true` なら、定義された `ScalaInstance` からの library の jar がアンマネージクラスパスに追加される。

より詳しくは [Configuring Scala](http://www.scala-sbt.org/0.13.0/docs/Detailed-Topics/Configuring-Scala.html) 参照。
