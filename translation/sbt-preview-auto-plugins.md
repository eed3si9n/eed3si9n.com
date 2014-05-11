  [1]: Preview of upcoming sbt 1.0 features: Read about the new plugins - See more at: https://typesafe.com/blog/preview-of-upcoming-sbt-10-features-read-about-the-new-plugins
  [2]: https://twitter.com/eed3si9n

> [Preview of upcoming sbt 1.0 features: Read about the new plugins][1] を訳しました。

著 @eed3s9n, @jsuereth

sbt に変化が訪れようとしている。sbt 1.0 へ向けて sbt の原理である自動化 (automation)、インタラクション (interaction)、統合化 (integration) の全面において改善がみられる予定だ。1.0 の二大機能と目されているのは auto plugin と「ビルドサーバとしての sbt」の 2つだ。

今後の数ヶ月にわたって sbt チームは sbt 0.13 コードベース上にこれらの機能を追加したプリビュー版をリリースする。これらのプリビュー版によって、sbt 1.0 の仕様が固まる前にコミュニティーからのフィードバックを得たり、新しい設計方針や理念そして新機能を促進することを目的としている。

長い間 sbt を支えてきた Mark Harrah  がビルド以外のことをするために旅立っていったことを残念ながら報告しなければならない。しかし、Typesafe のビルドツールチームである Antonio Cunei、Josh Suereth に新たなメンバー Eugene Yokota ([@eed3si9n][2]) が sbt の techlonogy lead の一人として参加することを歓迎したい。

本稿では、今回できあがった auto plugin 機能を紹介する。これは sbt 0.13.5-M2 リリースに含まれる。

## プラグイン・エコシステム

sbt の最大の強みとしてプラグイン・エコシステムを挙げることができる。プラグインはビルド定義と全く同じように動くため、sbt を習うことはそのままプラグインを書くのを習うことにつながっていく。sbt プラグインの多様性はこの基本的なコンセプトの力強さを物語っているだろう。中でも Play Framework と Activator の二つは抜き出ている。これらは sbt の上にで作られていてインタラクティブな開発エクスペリエンスを提供しているからだ。

sbt チームとして、auto plugin 機能を含む 0.13.5-M2 リリースをここにアナウンスしたい。これは、sbt 1.0 に追加される予定の新機能を現行の sbt とバイナリ互換性を保ったままで先取りすることができるテクノロジープリビュー版だ。

## Auto plugin

auto plugin は従来の sbt プラグインと同じはたらきをする: 新しいタスク、セッティング、コマンドをプロジェクトのビルド定義に加えることができる。主な違いは、タスクやセッティングの追加方法に関してもう前と比べてもうちょっと意見を持つ (opinionated) ことで、ユーザがプラグインを制御したり、プラグイン作者が新しい機能を追加するのを簡易化している。

### デフォルトセッティングも auto plugin だ

sbt 0.13.5 よりデフォルトのセッティングも 3つの auto plugin により提供される:

- CorePlugin (コアの sbt的概念を導入する)
- IvyPluin (依存性の管理)
- JvmPlugin (Scala や Java プロジェクトのコンパイル機能)

これらは sbt がデフォルトで提供するセッティングのコア・レイヤーだ。新しい auto plugin 機構によってどのレイヤーが有効化されるかまでユーザが直接コントロールすることができる。auto plugin 機構をより詳しく見ていこう。

### projectSettings と buildSettings

これまでは、ビルドにプラグインを含むのは二段階のプロセスが必要だった。

1. `project/plugins.sbt` にプラグインを追加する。
2. `build.sbt` もしくは `project.build.scala` 内にプラグイン特有のセッティングを追加する。

auto plugin を使った場合、プラグインが提供するセッテイング (例えば `assemblySettings`) は直接 `projectSettings` メソッドによって提供される。以下は `hello` というコマンドを sbt プロジェクトに追加するプラグインの具体例だ:

<scala>
package sbthello

import sbt._
import Keys._
object HelloPlugin extends AutoPlugin {
  override lazy val projectSettings = Seq(commands += helloCommand)
  lazy val helloCommand =
    Command.command("hello") { (state: State) =>
      println("Hi!")
      state
    }
}
</scala>

もしプラグインがビルドのレベル (つまり `in ThisBuild`) でセッティングを追加したい場合は `buildSettings` メソッド、グローバルなレベル (`in Global`) で追加したい場合は `globalSetings` メソッドを使う。これらのレベルでの自動化はプラグインを自動的にビルドに追加するのに便利だけども、ユーザはこれらのプラグインがどのように追加されるかを制御できない。より柔軟な方法を見てみよう。

### addPlugins

`HelloPlugin` を有効化させるにはこれまで通り sbt-hello に対する依存性を `project/plugins.sbt` 内にて宣言する必要がある:

<scala>
addSbtPlugin("com.example" % "sbt-hello" % "0.1.0")
</scala>

次に、`build.sbt` 内にセッテイング列を追加する代わりに、プロジェクトに対して `addPlugins` メソッドを呼び出す:

<scala>
(project in file(".")).addPlugins(HelloPlugin)
</scala>

これによってルートプロジェクトのセッティング列に `HelloPlugin.projectSettings` が追加される。

### プラグインの依存性

従来のプラグインが既存のプラグインの機能を再利用したい場合は、そのプラグインをライブラリ依存性として引っ張ってきた後、 (1) 依存プラグインのセッティング列を自分のセッティング列に加える、もしくは (2) ビルドユーザに対してセッティング列を正しい順序で追加するように指示を出す必要があった。これは、アプリケーション内のプラグインの数が増えるほど複雑になり、また間違いも起こりやすくなる。

auto plugin の主な目標はこのセッティング依存性の問題を軽減することにある。auto plugin は他の auto plugin に依存することができ、また依存するセッティングが正しい順序で読み込まれることを保証する。

例えば、`SbtLessPlugin` と `SbtCoffeeScriptPlugin` という 2つのプラグインがあるとして、それぞれが `SbtJsTaskPlugin`、 `SbtWebPlugin`、 `JvmPlugin` に依存するとする。手動で全てのプラグインを有効化する代わりに、プロジェクトは以下のように `SbtLessPlugin` と `SbtCoffeeScriptPlugin` を有効化するだけでいい:

<scala>
(project in file(".")).addPlugins(SbtLessPlugin, SbtCoffeeScriptPlugin)
</scala>

これだけでプラグインのセッティング列を正しい順序で読み込んでくれる。肝心な所はビルド定義に好きなプラグインを書いておけば後は sbt 任せでいいということだ。

auto plugin がどのようにセッティングの依存性を定義しているのかを具体例で見ていこう:

<scala>
package sbtless

import sbt._
import Keys._

object SbtLessPlugin extends AutoPlugin {
  override def requires = SbtJsTaskPlugin
  override lazy val projectSettings = ...
}
</scala>

`requires` メソッドは `Plugins` 型の戻り値を返して、これは依存性リストを表す DSL となっている。`requires` メソッドは以下の 3つの値を取りうる:

- `empty` (依存性プラグインを持たない。これがデフォルト)
- 他の auto plugin
- `&&` 演算子 (複数の依存性の定義)

### 連鎖プラグイン

プラグイン依存性によって複数の絡みあったプラグインを取り扱うときに生じる問題の多くが解決されるけども、ビルドユーザは手動で `project/plugins.sbt` と一つひとつのプロジェクトに追加する必要がある。auto plugin は、`trigger` メソッドを使うことによって依存性を全て満たした時点で自動的に有効化させることができる。

例えば、ビルドにコマンドを自動的に追加する連鎖プラグイン (triggered plugin) を書きたいとする。そのためには、`requires` メソッドが (デフォルトのまま) `empty` を返すようにして、`trigger` メソッドをオーバーライドして `allRequirements` を返すようにする。

<scala>
package sbthello

import sbt._
import Keys._

object HelloPlugin2 extends AutoPlugin {
  override def trigger = allRequirements
  override lazy val buildSettings = Seq(commands += helloCommand)
  lazy val helloCommand =
    Command.command("hello") { (state: State) =>
      println("Hi!")
      state
    }
}
</scala>

ビルドユーザはこのプラグインを `project/plugins.sbt` に含める必要はあるけども、`build.sbt` には何も書かなくてもよくなった。この機構は依存性のあるプラグインだとさらに面白くなる。 `SbtLessPlugin` を書き換えて連鎖プラグインにしよう:

<scala>
package sbtless

import sbt._
import Keys._

object SbtLessPlugin extends AutoPlugin {
  override def trigger = allRequirements
  override def requires = SbtJsTaskPlugin
  override lazy val projectSettings = ...
}
</scala>

`PlayScala` プラグイン (多分知ってると思うけど、Play framework は sbt プラグインだ) は、`SbtJsTaskPlugin` を依存プラグインの一つとして挙げている。そのため、`build.sbt` に以下のように書くだけで `SbtLessPlugin` からのセッティング列が `PlayScala` からのセッティング列の後のどこかに自動的に追加されるようになる:

<scala>
(project in file(".")).addPlugins(PlayScala)
</scala>

この機構によってプラグインが既存のプラグインを、暗黙に、しかし正しく機能拡張することができる。ビルドユーザが順序付けを考える手間から解放されるため、プラグイン作者はより自由で強力なプラグインを書くことが可能になるはずだ。

### autoImport による import の制御

セッティングなどの追加の他に従来の `sbt.Plugin` が提供していたものとして、`build.sbt` DSL 内で使えるメソッド、値、や型がある。デフォルトで `sbt.Plugin` を継承したクラスの全てのメンバは自動的に import される。これによって名前空間の衝突が生じる可能性があり、sbt プラグインの作者同士で実装を `sbt.Plugin` の外に書くといった回避策の規約ができたりした。

auto plugin は、これを是正して `*.sbt` に公開する名前は明示的に指定するようにした。これは `AutoImport` のインスタンス内に `autoImport` というメンバを提供することで行う。具体例で説明する:

<scala>
package sbthello

import sbt._
import Keys._

object HelloPlugin3 extends AutoPlugin {
  object autoImport {
    val greeting = settingKey[String]("greeting")
  }
  import autoImport._

  override def trigger = allRequirements
  override lazy val buildSettings = Seq(
    greeting := "Hi!"
    commands += helloCommand)

  lazy val helloCommand =
    Command.command("hello") { (state: State) =>
      println(greeting.value)
      state
    }
}
</scala>

この hello plugin は `greeting` というキーを `build.sbt` に提供して、import 無しで直接参照できるようになっている。ビルドユーザはプラグインの完全なパスを含んで `sbthello.HelloPlugin3.x` というふうに書くことでプラグインのオブジェクトを使うことができる。だけども、デフォルトでは `autoImport` という名前のついたフィールド (`val`、`lazy val` もしくは `object`) のみを wildcard import する。

## まとめ

自動化、インタラクション、統合の改善、そしてより良いユーザ・エクスペリエンスを提供することが sbt の進化への道で、auto plugin は次の一歩となる。これらの新しいプラグインは以前のプラグインにあった問題を解決し、ビルド内でのデバッグの改善やより柔軟な制御への布石ともなる。

sbt チームはこれらの変更点が sbt プラグイン・エコシステム及び関連する Play Framework などのプロダクトをより強力なものとすることを願っている。質問やアイディアがあれば、是非 sbt-dev リストにてコメントして欲しい。それでは、また次回まで。
