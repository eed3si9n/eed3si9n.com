---
title:       "sbt プラグインをテストする"
type:        story
date:        2011-09-18
changed:     2014-07-20
draft:       false
promote:     true
sticky:      false
url:         /ja/testing-sbt-plugins
aliases:     [ /node/42 ]
tags:        [ "sbt" ]
---

テストの話をしよう。一度プラグインを書いてしまうと、どうしても長期的なものになってしまう。新しい機能を加え続ける（もしくはバグを直し続ける）ためにはテストを書くのが合理的だ。だけど、ビルドツールのプラグインのテストなんてどうやって書けばいいんだろう？もちろん飛ぶんだよ。

## scripted test framework
sbt は、[scripted test framework](http://code.google.com/p/simple-build-tool/wiki/ChangeDetectionAndTesting#Scripts) というものが付いてきて、ビルドの筋書きをスクリプトに書くことができる。これは、もともと 変更の自動検知や、部分コンパイルなどの複雑な状況下で sbt 自体をテストするために書かれたものだ:

  > ここで、仮に B.scala を削除するが、A.scala には変更を加えないものとする。ここで、再コンパイルすると、A から参照される B が存在しないために、エラーが得られるはずだ。
  > [中略 (非常に複雑なことが書いてある)]
  >
  > scripted test framework は、sbt が以上に書かれたようなケースを的確に処理しているかを確認するために使われている。

正確には、このフレームワークは [siasia として知られる Artyom Olshevskiy 氏](https://github.com/siasia)により移植された scripted-plugin 経由で利用可能だが、これは正式なコードベースに取り込まれている。

## ステップ 1: snapshot
scripted-plugin はプラグインをローカルに publish するため、まずは version を **-SNAPSHOT** なものに設定しよう。

## ステップ 2: scripted-plugin
次に、scripted-plugin をプラグインのビルドに加える。`project/scripted.sbt`:

    libraryDependencies <+= (sbtVersion) { sv =>
      "org.scala-sbt" % "scripted-plugin" % sv
    }

以下を `scripted.sbt` に加える:

    ScriptedPlugin.scriptedSettings

    scriptedLaunchOpts := { scriptedLaunchOpts.value ++
      Seq("-Xmx1024M", "-XX:MaxPermSize=256M", "-Dplugin.version=" + version.value)
    }

    scriptedBufferLog := false

## ステップ 3: `src/sbt-test`
`src/sbt-test/<テストグループ>/<テスト名>` というディレクトリ構造を作る。とりあえず、`src/sbt-test/<プラグイン名>/simple` から始めるとする。

ここがポイントなんだけど、`simple` 下にビルドを作成する。プラグインを使った普通のビルド。手動でテストするために、いくつか既にあると思うけど。以下に、`build.sbt` の例を示す:

<scala>import AssemblyKeys._

version := "0.1"

scalaVersion := "2.10.2"

assemblySettings

jarName in assembly := "foo.jar"</scala>

これが、`project/plugins.sbt`:

<scala>{
  val pluginVersion = System.getProperty("plugin.version")
  if(pluginVersion == null)
    throw new RuntimeException("""|The system property 'plugin.version' is not defined.
                                  |Specify this property using the scriptedLaunchOpts -D.""".stripMargin)
  else addSbtPlugin("com.eed3si9n" % "sbt-assembly" % pluginVersion)
}
</scala>

これは [JamesEarlDouglas/xsbt-web-plugin@feabb2][6] から拝借してきた技で、これで scripted テストに version を渡すことができる。

他に、`src/main/scala/hello.scala` も用意した:

<scala>object Main extends App {
  println("hello")
}</scala>

## ステップ 4: スクリプトを書く
次に、好きな筋書きを記述したスクリプトを、テストビルドのルート下に置いた `test` というファイルに書く。

<code># ファイルが作成されたかを確認
> assembly
$ exists target/scala-2.10/foo.jar</code>

スクリプトの文法は [ChangeDetectionAndTesting][1] に記述されている通りだけど、以下に解説しよう:
1. **`#`** は一行コメントを開始する
2. **`>`** `name` はタスクを sbt に送信する（そして結果が成功したかをテストする）
3. **`$`** `name arg*` はファイルコマンドを実行する（そして結果が成功したかをテストする）
4. **`->`** `name` タスクを sbt に送信するが、失敗することを期待する
5. **`-$`** `name arg*` ファイルコマンドを実行するが、失敗することを期待する

ファイルコマンドは以下のとおり:

- **`touch`** `path+` は、ファイルを作成するかタイムスタンプを更新する
- **`delete`** `path+` は、ファイルを削除する
- **`exists`** `path+` は、ファイルが存在するか確認する
- **`mkdir`** `path+` は、ディレクトリを作成する
- **`absent`** `path+` は、はファイルが存在しないことを確認する
- **`newer`** `source target` は、`source` の方が新しいことを確認する
- **`pause`** は、enter が押されるまで待つ
- **`sleep`** `time` は、スリープする
- **`exec`** `command args*` は、別のプロセスでコマンドを実行する
- **`copy-file`** `fromPath toPath` は、ファイルをコピーする
- **`copy`** `fromPath+ toDir` は、パスを相対構造を保ったまま `toDir` 下にコピーする
- **`copy-flat`** `fromPath+ toDir` は、パスをフラットに `toDir` 下にコピーする

ということで、僕のスクリプトは、`assembly` タスクを実行して、`foo.jar` が作成されたかをチェックする。もっと複雑なテストは後ほど。

## ステップ 5: スクリプトを実行する
スクリプトを実行するためには、プラグインのプロジェクトに戻って、以下を実行する:

<code>> scripted
</code>

これはテストビルドをテンポラリディレクトリにコピーして、`test` スクリプトを実行する。もし全て順調にいけば、まず `publish-local` の様子が表示され、以下のようなものが表示される:

    Running sbt-assembly / simple
    [success] Total time: 18 s, completed Sep 17, 2011 3:00:58 AM

## ステップ 6: カスタムアサーション

ファイルコマンドは便利だけど、実際のコンテンツをテストしないため、それだけでは不十分だ。コンテンツをテストする簡単な方法は、テストビルドにカスタムのタスクを実装してしまうことだ。

上記の hello プロジェクトを例に取ると、生成された jar が "hello" と表示するかを確認したいとする。`sbt.Process` を用いて jar を走らせることができる。失敗を表すには、単にエラーを投げればいい。以下に `build.sbt` を示す:
<scala>import AssemblyKeys._

version := "0.1"

scalaVersion := "2.10.2"

assemblySettings

jarName in assembly := "foo.jar"

TaskKey[Unit]("check") <<= (crossTarget) map { (crossTarget) =>
  val process = sbt.Process("java", Seq("-jar", (crossTarget / "foo.jar").toString))
  val out = (process!!)
  if (out.trim != "bye") error("unexpected output: " + out)
  ()
}
</scala>

ここでは、テストが失敗するのを確認するため、わざと "bye" とマッチするかテストしている。
空行を入れると、ブロックの終わりだと解釈されるので気をつけよう。

これが `test`:

<code># ファイルが作成されたかを確認
> assembly
$ exists target/foo.jar

# hello って言うか確認
> check</code>


`scripted` を走らせると、意図通りテストは失敗する:

<code>[info] [error] {file:/private/var/folders/Ab/AbC1EFghIj4LMNOPqrStUV+++XX/-Tmp-/sbt_cdd1b3c4/simple/}default-0314bd/*:check: unexpected output: hello
[info] [error] Total time: 0 s, completed Sep 21, 2011 8:43:03 PM
[error] x sbt-assembly / simple
[error]    {line 6}  Command failed: check failed
[error] {file:/Users/foo/work/sbt-assembly/}default-373f46/*:scripted: sbt-assembly / simple failed
[error] Total time: 14 s, completed Sep 21, 2011 8:00:00 PM
</code>

テストビルド間でアサーションを再利用したい場合は、full configuration を用いて、カスタムのビルドクラスを継承することができる。

## ステップ 7: テストをテストする
慣れるまでは、テスト自体がちゃんと振る舞うのに少し時間がかかるかもしれない。ここで使える便利なテクニックがいくつある。

まず最初に試すべきなのは、ログバッファリングを切ることだ。

<code>> set scriptedBufferLog := false
</code> 

これにより、例えばテンポラリディレクトリの場所などが分かるようになる:

<code>[info] [info] Set current project to default-c6500b (in build file:/private/var/folders/Ab/AbC1EFghIj4LMNOPqrStUV+++XX/-Tmp-/sbt_8d950687/simple/project/plugins/)
...
</code>

テスト中にテンポラリディレクトリを見たいような状況があるかもしれない。`test` スクリプトに以下の一行を加えると、scripted はエンターキーを押すまで一時停止する:

<code>$ pause
</code>

もしうまくいかなくて、 `sbt/sbt-test/sbt-foo/simple` から直接 `sbt` を実行しようと思っているなら、それは止めたほうがいい。Mark がコメント欄で教えてくれた通り、正しいやり方はディレクトリごと別の場所にコピーしてから走らせることだ。

## ステップ 8: インスパイアされる
sbt プロジェクト下には文字通り [100+ の scripted テストがある][3]。色々眺めてみて、インスパイアされよう。

例えば、以下に by-name と呼ばれるものを示す:

<code>> compile

# change => Int to Function0
$ copy-file changes/A.scala A.scala

# Both A.scala and B.scala need to be recompiled because the type has changed
-> compile</code>

[xsbt-web-plugin][4] や [sbt-assemlby][5] にも scripted テストがある。

これでおしまい！プラグインをテストしてみた経験などを聞かせて下さい！

  [1]: http://code.google.com/p/simple-build-tool/wiki/ChangeDetectionAndTesting#Scripts
  [2]: https://github.com/siasia
  [3]: https://github.com/sbt/sbt/tree/0.13/sbt/src/sbt-test
  [4]: https://github.com/JamesEarlDouglas/xsbt-web-plugin/tree/master/src/sbt-test
  [5]: https://github.com/sbt/sbt-assembly/tree/master/src/sbt-test/sbt-assembly
  [6]: https://github.com/JamesEarlDouglas/xsbt-web-plugin/commit/feabb2eb554940d9b28049bd0618b6a790d9e141

