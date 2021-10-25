---
title:       "sbt 0.12.0 の変更点"
type:        story
date:        2012-06-08
changed:     2013-10-07
draft:       false
promote:     true
sticky:      false
url:         /ja/sbt-0120-changes
aliases:     [ /node/57 ]
tags:        [ "sbt" ]
---

  [#274]: https://github.com/harrah/xsbt/issues/274
  [#304]: https://github.com/harrah/xsbt/issues/304
  [#315]: https://github.com/harrah/xsbt/issues/315
  [#327]: https://github.com/harrah/xsbt/issues/327
  [#335]: https://github.com/harrah/xsbt/issues/335
  [#393]: https://github.com/harrah/xsbt/issues/393
  [#396]: https://github.com/harrah/xsbt/issues/396
  [#380]: https://github.com/harrah/xsbt/issues/380
  [#389]: https://github.com/harrah/xsbt/issues/389
  [#388]: https://github.com/harrah/xsbt/issues/388
  [#387]: https://github.com/harrah/xsbt/issues/387
  [#386]: https://github.com/harrah/xsbt/issues/386
  [#378]: https://github.com/harrah/xsbt/issues/378
  [#377]: https://github.com/harrah/xsbt/issues/377
  [#368]: https://github.com/harrah/xsbt/issues/368
  [#394]: https://github.com/harrah/xsbt/issues/394
  [#369]: https://github.com/harrah/xsbt/issues/369
  [#403]: https://github.com/harrah/xsbt/issues/403
  [#412]: https://github.com/harrah/xsbt/issues/412
  [#415]: https://github.com/harrah/xsbt/issues/415
  [#420]: https://github.com/harrah/xsbt/issues/420
  [#462]: https://github.com/harrah/xsbt/pull/462
  [#472]: https://github.com/harrah/xsbt/pull/472
  [Launcher]: https://github.com/harrah/xsbt/wiki/Launcher

> ついに final がリリースされた、sbt 0.12.0 の[変更点](https://github.com/harrah/xsbt/wiki/ChangeSummary_0.12.0)を訳しました。
> バイナリバージョンという概念が導入されることで、Scala 2.9.0 で入ったけどあまり活用されていない Scala の後方バイナリ互換性がより正面に出てくるキッカケとなると思います。

## 互換性に影響のある新機能、バグ修正、その他の変更点

 * Scala 2.10 以降の Scala 及び sbt プラグインのクロスバージョン規約の変更。 (詳細は[以下の項目](#cross_building) )
 * 直接実行された場合、強制的に <code>update</code> を実行するようにした。 [#335][#335]
 * sbt プラグインリポジトリがプラグインとプラグインの定義にデフォルトで加わった。 [#380][#380]
 * プラグイン設定ディレクトリの優先順位。 (詳細は[以下の項目](#plugin_dir) )
 * ソース依存性の修正。 (詳細は[以下の項目](#source_dependencies) )
 * 集約がより柔軟になった。 (詳細は[以下の項目](#aggregation) )
 * タスク軸の構文が <code>key(for task)</code> から <code>task::key</code> へと変更された。 (詳細は[以下の項目](#task_axis) )
 * sbt の organization が <code>org.scala-sbt</code> へと変更された。(元は、org.scala-tools.sbt) 特に、scripted プラグインのユーザはこの影響を受ける。
 * <code>artifactName</code> の型が <code>(ScalaVersion, ModuleID, Artifact) => String</code> となった。
 * <code>javacOptions</code> がタスクとなった。
 * <code>session save</code> は <code>build.sbt</code> 内の設定を（適切な時に）上書きするようにした。[#369][#369]
 
## 新機能

 * テストのフォークのサポート。 [#415][#415]
 * <code>test-quick</code>。 ([#393][#393])
 * リポジトリ設定のグローバルなオーバライドをサポートした。 [#472][#472]
 * 再コンパイルをせずに unchecked と deprecation の警告を表示する <code>print-warnings</code> タスクを追加した。(Scala 2.10+ のみ)
 * Ivy 設定ファイルを URL から読み込めるようにした。
 * <code>projects add/remove <URI></code> で一時的に他のビルドと作業できるようになった。
 * 並列実行の制御の改善。 (詳細は[以下の項目](#parallel_execution) )
 * <code>inspect tree <key></code> で <code>inspect</code> を再帰的に呼べるようになった。[#274][#274]

## バグ修正

 * 再帰的にディレクトリを削除するときに、シンボリックリンクが指す先のコンテンツを削除しないようにした。
 * Java ソースの親の検知の修正。
 * `update-sbt-classifiers` で用いられる resolver の修正。[#304][#304]
 * プラグインの自動インポートの修正。[#412][#412] 
 * 引数のクオート [#396][#396]
 * Ctrl+Z で停止した後 JLine を正しくリセットするようにした。(Unix のみ) [#394][#394]
 
## 改善点

 * ランチャーが 0.7.0 以降全ての sbt を起動できるようになった。
 * スタックトレースが抑制された場合、`last` を呼ぶようにより洗練されたヒントが表示されるようになった。
 * Java 7 の Redirect.INHERIT を用いて子プロセスの入力ストリームを継承するようになった。 [#462][#462], [#327][#327] これでインタラクティブなプログラムをフォークした場合に起こる問題が解決されるはず。 (@vigdorchik)
 * <code>help</code> と <code>task</code> コマンドの様々な改善、および新たな <code>settings</code> コマンド。[#315][#315]
 * jsch バージョンを 0.1.46 へと更新。 [#403][#403]
 * JLine バージョンを 1.0 へと変更。 (詳細は[以下の項目](#jline) )
 * その他の修正および機能改善: [#368][#368], [#377][#377], [#378][#378], [#386][#386], [#387][#387], [#388][#388], [#389][#389]

## 実験的、もしくは開発途中

 * 差分コンパイルを組み込むための API。このインターフェイスは今後変更する可能性があるが、既に [scala-maven-plugin のブランチ](https://github.com/davidB/scala-maven-plugin/tree/feature/sbt-inc)で利用されている。
 * Scala コンパイラの常駐の実験的サポート。 sbt に <code>-Dsbt.resident.limit=n</code> を渡すことで設定を行う。<code>n</code> は常駐させるコンパイラの最大数。
 * [新サイト](http://www.scala-sbt.org/)の [howto](http://www.scala-sbt.org/howto.html) ページを読みやすくした。

## 大きな変更の詳細点

<a id="plugin_dir"/>
## プラグインの設定ディレクトリ

0.11.0 においてプラグインの設定ディレクトリは <code>project/plugins/</code> からただの <code>project/</code> へと移行し、<code>project/plugins/</code> は非推奨となった。0.11.2 において非推奨のメッセージが表示されたが、全ての 0.11.x においては旧スタイルの <code>project/plugins/</code> が新しいスタイルよりも高い優先された。0.12.0 では新しいスタイルが優先される。旧スタイルのサポートは 0.13.0 が出るまで廃止されない。

  1. 理想的には、プロジェクトは設定の衝突がないことを保証すべきだ。両方のスタイルがサポートされているため、設定に衝突がある場合の振る舞いのみが変更されることになる。
  2. 実際にこれが起こりえる状況としては、古いブランチから新しいブランチに切り替えた場合に空の <code>project/plugins/</code> が残ってしまい何も設定が無いにも関わらず旧スタイルが使われてしまうということがある。
  3. そのため、この変更は飽くまで新スタイルへ移行中のプロジェクトのための改善であり、他のプロジェクトには気付かれないことを意図している。

<a id="jline"/>
## JLine

JLine 1.0 への移行。これはいくつかの顕著な修正を含む比較的新しいリリースだが、見たところ今まで使われていた 0.9.94 とバイナリ互換がある。具体的には、

  1. Unix 上で stty へフォークしたストリームを正しく閉じる。
  2. Linux での Delete キーへの対応。これが実際に動作するかは各自確認して欲しい。
  3. 行の折り返しが正しくなっているように思える。

<a id="task_axis"/>
## タスク軸のパーシング

セッティングやタスクのタスク軸のパーシングに関して重要な変更が行われた。 [#202](https://github.com/harrah/xsbt/issues/202)

  1. 0.12 以前の構文は <code>{build}project/config:key(for task)</code> だった。
  2. 提案され（採用された）0.12 からの構文は <code>{build}project/config:task::key</code> だ。
  3. タスク軸をキーの前に移動することで特にプラグインからの（タブ補完を用いた）キーの発見が容易にする。
  4. 旧構文はサポートされない予定だ。理想的は非推奨に一度すべきだが、その実装に手間がかかりすぎる。

<a id="aggregation"/>
## 集約

集約がより柔軟になった。これは過去にメーリングリストで議論されたのと同様の方向だ:

  1. 0.12 以前は、セッティングは現行プロジェクトに基づいてパースされ、全く同様のセッティングのみが集約された。
  2. タブ補完は集約を考慮に入れていなかった。
  3. これは、セッティングもしくはタスクが現行プロジェクトに無かった場合は集約されたプロジェクトにそのセッティング/タスクがあったとしてもパーシングが失敗することになった。
  4. また、現行プロジェクトに compile:package があり、集約されたプロジェクトに *:package があり、ユーザが (コンフィギュレーション無しで) <code>package</code> を実行した場合 (compile:package じゃないため) *:package が集約されたプロジェクトで実行されなかった。
  5. 0.12 ではこのような状況において集約されたセッティングが選択されるようになった。具体的には、
    1. <code>root</code> というプロジェクトが子プロジェクトの <code>sub</code> を集約すると仮定する。
    2. <code>root</code> は <code>*:package</code> を定義する。
    3. <code>sub</code> は <code>compile:package</code> と <code>compile:package</code> を定義する。
    4. <code>root/package</code> を実行すると <code>root/*:package</code> と <code>sub/compile:package</code> が実行される。
    5. <code>root/compile</code> を実行すると <code>sub/compile:compile</code> が実行される。
  6. この変更点はタスク軸のパーシングの変更に依存する。

<a id="parallel_execution"/>
## 並列実行

並列実行の細かい制御がサポートされる。詳細は [Parallel Execution](https://github.com/harrah/xsbt/wiki/Parallel-Execution) 参照。

  1. デフォルトの振る舞いは、<code>parallelExecution</code> のセッティングも含め以前と同じ。
  2. このシステムの新しい機能は実験段階だと考えるべき。
  3. そのため <code>parallelExecution</code> は現段階では非推奨ではない。

<a id="source_dependencies"/>
## ソース依存性

[#329](https://github.com/harrah/xsbt/issues/329) に対する修正が含まれた。この修正により前プロジェクトに渡ってプラグイン一つにつき唯一のバージョンのみが読み込まれることが保証されるようになった。これは、二部に分かれる。

  1. プラグインのバージョンは最初に読み込んだビルドに確定する。特に、(sbt が起動した) ルートのビルドで使われたプラグインのバージョンは依存性により使われるものよりも常に優先される。
  2. 全てのビルドのプラグインは同一のクラスローダにより読み込まれる。

さらに Sanjin のパッチにより hg と svn の URI へのサポートが追加された。

  1. sbt は <code>svn</code> もしくは <code>svn+ssh</code> から始まる URI を subversion を用いて取得する。省略可能なフラグメントにより特定のリビジョンを指定できる。
  2. Mercurial は特定のスキームを持たないため、sbt は Mercurial のリポジトリの URI に <code>hg:</code> をプレフィックスとして付けることを要求する。
  3. <code>.git</code> で終わる URI の処理が修正された。

<a id="cross_building"/>
## クロスビルド

Scala のバージョン 2.10 シリーズと sbt のバージョン 0.12 シリーズ以降に関して、クロスバージョンのサフィックスがメジャー番号とマイナー番号のみに短縮された。具体的には、普通のライブラリだと <code>sbinary_2.10</code>、sbt プラグインだと <code>sbt-plugin_2.10_0.12</code> のようになる。これは Scala と sbt がその中間リリースにおいて前方互換性と後方互換性を維持することを前提とする。

  1. これは待ちわびていた変更だが、これはオープンソースプロジェクト作者の皆が Scala 2.10 向けのものを公開する前に 0.12 に切り替えるか、ビルドのクロスバージョンのサフィックスを適宜変更することを必要とする。
  2. 0.12 を用いて Scala 2.10 向けのライブラリを公開するには、0.12.0 が Scala 2.10 よりも前にリリースされることが求められる。
  3. 同時に、sbt 0.12.0 が Scala 2.10.0 向けに公開されなければ 0.12.x シリーズに渡って Scala 2.9.x を使わなければいけないことになる。
  4. バイナリバージョン (binary version) という新しい概念を導入する。これはフルバージョン (full version) 文字列のサブセットで、バイナリ互換性を表す。つまり、同じバイナリバージョンはバイナリ互換性を意味する。以前の sbt の振る舞いに合わせて 2.10 以前の全ての Scala バージョンはフルバージョンをもってバイナリバージョンとする。Scala 2.10 以降はバイナリバージョンは <code><major>.<minor></code> だ。
  5. 公開されるアーティファクトのクロスバージョンの振る舞いは <code>crossVersion</code> セッティングで設定される。<code>ModuleID</code> に対して <code>cross</code> メソッドを用いるか、今まで通りの依存性構築子である %% を用いて依存ライブラリごとに設定を変えることができる。デフォルトでは、単一の % を使った場合は依存性のクロスバージョンは無効にされ、%% を使った場合は Scala のバイナリバージョンを用いる。
  7. <code>artifactName</code> 関数は第一引数として <code>ScalaVersion</code> を受け取るようになった。型は <code>(ScalaVersion, ModuleID, Artifact) => String</code> となった。<code>ScalaVersion</code> は Scala のフルバージョン (例: 2.10.0) とバイナリバージョン (例： 2.10) を保持する。
  8. Indrajit により追加された柔軟なバージョンのマッピングが <code>cross</code> メソッドに追加され、複数の引数を取る %% の変種は非推奨となった。以下に具体例で説明する。

以下は等価だ:

```scala
"a" % "b" % "1.0"
"a" % "b" % "1.0" cross CrossVersion.Disabled
```

以下は等価だ:

```scala
"a" %% "b" % "1.0"
"a" % "b" % "1.0" cross CrossVersion.binary
```

これは、Scala のバイナリバージョンの代わりにフルバージョンを使う:

```scala
"a" % "b" % "1.0" cross CrossVersion.full
```

これは Scala のバイナリバージョンを元にカスタム関数を使って Scala バージョンを決定する:

```scala
"a" % "b" % "1.0" cross CrossVersion.binaryMapped {
  case "2.9.1" => "2.9.0" // 2.10 以前なのでバイナリ==フル
  case x => x
}
```

これは Scala のフルバージョンを元にカスタム関数を使って Scala バージョンを決定する:

```scala
"a" % "b" % "1.0" cross CrossVersion.fullMapped {
  case "2.9.1" => "2.9.0"
  case x => x
}
```

全ての Scala バージョンに対して公開されていない依存ライブラリを用いてクロスビルドするときにカスタム関数を使うことができる。バイナリバージョンに移行することで、この機能の必要性が徐々に減っていくはずだ。

## グローバルなリポジトリ設定

リポジトリ設定のグローバルなオーバライドをサポートした。 [#472][#472] <code>[repositories]</code> 項目を <code>~/.sbt/repositoreies</code> に書いて、sbt に <code>-Dsbt.override.build.repos=true</code> を渡すことでリポジトリを定義する。([Launcher] のページを参照) ランチャーが sbt と Scala を取得し、sbt がプロジェクトの依存性を取得するのにファイルで指定されたリポジトリが使われるようになる。 

## test-quick

<code>test-quick</code> ([#393][#393]) は引数で指定されたテスト（引数がない場合は全てのテスト）のうち以下の条件を一つでも満たすものを実行する:
  1. まだ実行されていない。
  2. 前回実行時に失敗した。
  3. 最後に成功した後で間接的にでも依存するコードが再コンパイルされた場合。

## 引数のクォート

引数のクォート [#396][#396]。

 1. <code>> command "空白 のある 引数\n エスケープは解釈される"</code>
 2. <code>> command """空白 のある 引数\n エスケープは解釈されない"""</code>
 3. 最初のリテラルは Windows のパス記号であるバックスラッシュをエスケープ (<code>\\</code>) する必要があることに注意。2つ目のリテラルを使えばその必要は無い。
 4. バッチモードから使う場合は、ダブルクオートそのものをシェルからエスケープする必要がある。
