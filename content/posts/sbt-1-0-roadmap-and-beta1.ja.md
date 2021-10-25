---
title:       "sbt 1.0 ロードマップと beta-1"
type:        story
date:        2017-04-18
draft:       false
promote:     true
sticky:      false
url:         /ja/sbt-1-0-roadmap-and-beta1
aliases:     [ /node/238 ]
tags:        [ "sbt" ]
---

  [migratingsbt]: http://www.scala-sbt.org/0.13/docs/Migrating-from-sbt-012x.html
  [jdk9support]: http://developer.lightbend.com/blog/2017-04-10-sbt-01315-JDK9-support-and-offline-installation/
  [feedback1]: https://contributors.scala-lang.org/t/asking-for-your-feedback-on-sbt-scala-center-announcement/738
  [sbt-migration-rewrites]: https://github.com/scalacenter/sbt-migration-rewrites
  [beta1tgz]: https://github.com/sbt/sbt/releases/download/v1.0.0-M5/sbt-1.0.0-M5.tgz

> Lightbend の技術系ブログ Tech Hub blog に [sbt 1.0 roadmap and beta-1](http://developer.lightbend.com/blog/2017-04-18-sbt-1-0-roadmap-and-beta1/) という記事書いたので、訳しました。

[@eed3si9n](https://twitter.com/eed3si9n) 著

sbt 1.0 はかれこれ数年間制作中という状態が続いていて、コミュニティーの中には「もう出ないのでは」という懐疑派がいてもおかしくない。そのような懸念は以下の論点によって払拭できると思っている:

- 本来 1.0 に予定していた (AutoPlugin や Dotty サポートのような) 機能はすでにテクノロジー・プレビューとして 0.13 系にてリリースされている。
- 1.0 に予定されていた機能のうち、より意欲的なものは延期または機能を縮小して 1.0 が早期に実現できるようにした。（キャッシュ化されたコンパイルや Ivy の置き換えなど）
- sbt 1.0 はベーパーウェアではない。最新だと [1.0.0-M5][beta1tgz] などマイルストーンが出ていて、今すぐ試すことができる。

そのため、2017年夏までに sbt 1.0 プランを実現可能だと思っている。

### ハイライト

sbt 1.0 は、向こう数年間続く安定版であることと、sbt 0.13 系からのスムーズな移行が可能であることを目標とする。[sbt 0.12 スタイルの演算子や Build トレイト][migratingsbt]は削除される。本来 1.0 に予定していた機能はすでにテクノロジー・プレビューとして 0.13.x シリーズにてリリースされている。

sbt 1.0 における利点をまとめると:

- ビルド定義やプラグインに Scala 2.12 が使えるようになる
- 大規模コードベースにおいて高速化が見込まれる新インクリメンタルコンパイラ、Zinc 1
- 今後の IDE 統合の改善の下地となる sbt server

### タイミング

sbt 1.0.0-M5 は最初のベータ版である。残っている課題のうち重要なものは:

- Zinc 1 や librarymanagement API といった各モジュール API の最終化。
- build.sbt DSL のうち今後セマンティクスが変更される予定の構文に対するガードの実装。
- 古いビルドからの自動的マイグレーションを補助するためのツールの実装。
- よく使われている sbt plugin が移行できるかの検証。
- メジャーなコミュニティープロジェクトが sbt 1.0 に移行できるかの検証。

これらの課題のうち解法が不明なものは特に無いので、今後数ヶ月内で十分実現可能だ。beta-2 を一ヶ月後、そして RC版を 6月にリリースする予定だ。

- 2017-04-18:  sbt 1.0.0-M5 "beta-1"
- 2017-05-18:  sbt 1.0.0-M6 "beta-2"
- 2017年6月:  sbt 1.0.0-RC1
- 2017年7月:  sbt 1.0.0

sbt 1.0 をリリースするのを協力してみたい人は、以下の項目がコミュニティーの参加を必要としているので参考にしてほしい:

- sbt 1.0 マイルストーンに対する sbt プラグインのテストと移植。
- コミュニティープロジェクトを使った sbt 1.0 マイルストーンやマイルストーンツールのテスト。

### テクノロジー・プレビューとしての sbt 0.13.5+

2014年3月に sbt チームは sbt 0.13.5 を「sbt 1 のためのテクノロジー・プレビュー」と名付け、sbt 0.13.0 と後方互換性を保ったまま新機能を追加し始めた。テクノロジー・プレビューは、sbt 0.13 系から新しいアイディアを実験的に導入することで sbt 1.0 へのジャンプを軽減することを目的としている。以下は過去 3年間のうちに追加された機能のいくつかだ:

- AutoPlugin
- Name hashing インクリメンタル・コンパラ
- 自然な空白処理
- Cached dependency resolution
- 設定可能なコンパイラブリッジと Dotty サポート
- 0.12.x スタイルの DSL の撤廃
- sbt new コマンド
- [予備としての JDK 9 サポート][jdk9support]

他にもバイナリ互換性が無い新機能がいくつか sbt 1.0 にて新しく導入される。

### Scala 2.12

sbt 1.0 では、ビルド定義とプラグインのエコシステムは Scala 2.12 によって作られる。バイナリ互換性を崩せるチャンスなので、最新の安定版 Scala を採用する。これによって最新のライブラリやツール群を使うことができるためプラグイン・エコシステムにも好影響があるはずだ。

### モジュール化と Zinc インクリメンタル・コンパイラ

sbt 1.0 はコードベースを sbt/sbt、sbt/zinc、sbt/librarymanagement, sbt/io というふうに複数の別リポジトリに分ける。モジュール化の目標は何が API で何が実装なのかを明確にすることと、コードのサイズを減らすことだ。

sbt 0.13 のコードの大まかに言って半分ぐらいのコードがインクリメンタル・コンパイラ周りで、それは sbt だけじゃなくて Scala ツール郡全般に影響があるものだ。Lightbend の Tooling Team として、このインクリメンタル・コンパイラを別に分けることで他のビルドツールの作者も開発に参加したり利用できるようにした。このインクリメンタル・コンパイラを Zinc 1 と呼ぶ。sbt/zinc-contrib Gitter チャンネルでは既に Lightbend、Scala Center、VirtusLab、Twitter 各社のエンジニアが日々アイディアやコードを交換している。

Library management も sbt/sbt から分かれたもう一つのモジュールだ。これは Ivy の実装を直接 sbt プラグインに露出させないことを目的としている。それによって将来的に依存性解決を改善したり、別の実装に入れ替えることができるからだ。

### Zinc 1: クラスベース name hashing

(Lightbend社との契約で) Grzegorz Kossakowski 氏によって導入された Zinc 1 の目玉機能としてクラスベース name hashing があり、これは大規模なプロジェクトおいて差分コンパイルが高速化することが見込まれている。

Zinc 1 の name hashing はコード間の依存性を、ソースファイルではなくクラスというレベルで追跡するようになる。GitHub issue [sbt/sbt#1104](https://github.com/sbt/sbt/issues/1104) にていくつかプロジェクトの既存のクラスに一つのメソッドを追加した場合の差分コンパイルの比較が行われている:

```bash
ScalaTest   AndHaveWord class:          Before 49s, After 4s (12x)
Specs2      OptionResultMatcher class:  Before 48s, After 1s (48x)
scala/scala Platform class:             Before 59s, After 15s (3.9x)
scala/scala MatchCodeGen class:         Before 48s, After 17s (2.8x)
```

クラスがどう整理されているかなどの色々な条件に依存するが、だいたい 3x ~ 40x の改善が見られている。この高速化の理由はクラスとソースファイルの関係を分けることで、より少ない数のソースファイルをコンパイルしているという単純なものだ。例えば、scala/scala の Platfrom クラスにメソッドを追加した例だと sbt 0.13 の name hashing だと 72 個のソースをコンパイルしていたが、Zinc は 6個しかコンパイルしない。

### sbt server: ツール統合のための JSON API

sbt 1.0 は新しい server コマンドを含み、これは IDE やその他のツールがビルドに対して JSON API を用いてセッティングのクエリを行ったり、コマンド実行を行ったりできる。sbt 0.13 のインタラクティブ・シェルが shell というコマンドで実装されていたように、server も人間とネットワークの両方の入力を待つだけのコマンドだ。ユーザ側から見ると、サーバ機能による影響はあんまり心配しなくてもいい。

2016年の 3月にサーバ機能の[仕切り直し](http://eed3si9n.com/ja/sbt-server-reboot)が行われ、可能な限り小さい機能にすることにした。JetBrain で IntelliJ の sbt インターフェイスを担当する @jastice さんなどとの協力で機能を決めていった。sbt 1.0 は当初欲しかった全ての機能は入らないが、長期的にはこれが IDE と sbt エコシステムとの連携の改善につながることを願っている。例えば、IDE 側から compile タスクを呼び出して、コンパイラの警告を JSON のイベントとして受け取ることができる:

```bash
{"type":"xsbti.Problem","message":{"category":"","severity":"Warn","message":"a pure expression does nothing in statement position; you may be omitting necessary parentheses","position":{"line":2,"lineContent":"  1","offset":29,"pointer":2,"pointerSpace":"  ","sourcePath":"/tmp/hello/Hello.scala","sourceFile":"file:/tmp/hello/Hello.scala"}},"level":"warn"}
```

他に関連する機能としてプログラムをバックグラウンドで実行する `bgRun` タスクが追加された。これに対してテストを行うことなどを想定している。

### sbt 0.13 からの sbt 1.0 プラグインのクロスビルド

複数の Scala バージョンに対してクロスビルドが可能であるように、sbt 0.13 に居ながらにして sbt 1.0 プラグインへのクロスビルドを行うことが可能だ。これは一つのプラグインづつ移植できるため便利な機能だ。

1. プラグインは別のワーキング・ディレクトリにクローンする。
2. プラグインがライブラリに依存する場合、Scala 2.12 のアーティファクトがあるかを確認する。
3. 最新の sbt 0.13.15 を使う。
4. プラグインに以下のセッティングを追加する:

```scala
scalaVersion := "2.12.2",
sbtVersion in Global := "1.0.0-M5",
scalaCompilerBridgeSource :=
  ("org.scala-sbt" % "compiler-interface" % "0.13.15" % "component").sources
```

最後のステップは今後 @jrudolph さんの sbt-cross-building によって簡略化されるはずだ。
プラグインを移行していて何らかの問題に遭遇したら、[GitHub issue](https://github.com/sbt/sbt/issues) に報告してほしい。

### 削除される機能

sbt 1.0 は以下の機能を削除する:

- AutoPlugin じゃない sbt.Plugin trait。AutoPlugin に移行してください。AutoPlugin の方が設定が簡単だし、他のプラグインとも合わせやすいからだ。
- sbt 0.12 スタイルの Build trait (sbt 0.13.12 で廃止勧告) は削除される。[build.sbt に移行してください](http://www.scala-sbt.org/0.13/docs/Migrating-from-sbt-012x.html#Migrating+from+the+Build+trait)。AutoPlugin と Build trait は相性が良くなく、マルチプロジェクト build.sbt によって機能は大体置き換えられている。
- sbt 0.12 スタイルのキー依存性演算子である `<<=`、 `<+=`、 `<++=` は削除される。[:=、 +=、 ++= に移行してください](http://www.scala-sbt.org/0.13/docs/Migrating-from-sbt-012x.html#Migrating+simple+expressions)。古い演算子は多くのユーザにとって混乱のもととなっていて、0.13 のドキュメンテーションからも前から外されていて、sbt 0.13.13 でも廃止勧告が出ている。
- Scala 2.9 とそれ以前の Scala に対するのサポートは無くなる。Scala 2.10 では 2.10.2 以上、Scala 2.11 では 2.11.2 以上を必要とする。(最新版を推奨する)

これらの変更に対しては Scala Center の協力で[自動マイグレーション・ツール][sbt-migration-rewrites]が提供される。

### ご感想をお待ちしております

このロードマップに対して、質問やフィードバックがあれば今後二週間以内に [Asking for your feedback on sbt + Scala Center announcement][feedback1] に是非コメントして欲しい。日本語の場合は、本稿のコメント欄にお願いします。
