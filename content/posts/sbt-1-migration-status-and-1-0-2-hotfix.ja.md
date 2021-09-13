---
title:       "sbt 1 マイグレーション状況報告と 1.0.2 hotfix"
type:        story
date:        2017-09-20
draft:       false
promote:     true
sticky:      false
url:         /ja/sbt-1-migration-status-and-1-0-2-hotfix
aliases:     [ /node/237 ]
tags:        [ "sbt" ]
---

> Lightbend の技術系ブログ Tech Hub blog に [sbt 1 migration status and 1.0.2 hotfix](https://developer.lightbend.com/blog/2017-09-19-sbt-1-migration-status-and-1-0-2-hotfix) という記事書いたので、訳しました。

[@eed3si9n](https://twitter.com/eed3si9n) 著

こんにちは。sbt 1.0.0 リリース後に何があったかのレポートだ。

僕たちの sbt 1 へのマイグレーションのプランは以下のようになっている:

- sbt 1.0.0 をリリースする。
- コミュニティーの皆さんと一緒にプラグインを全部移行させる。
- バグを修正する。
- ライブラリのビルドを移行させる。

### プラグインの移行

プラグインの移植の進捗を追跡するために、[知られているプラグインの一覧](https://github.com/sbt/sbt/wiki/sbt-1.x-plugin-migration)を作って GitHub star 順にソートした。これは、ドキュメンテーションをスクリーンスクレイピングしたのを元に、手動でも色々追加してある。ここに書かれた 258個のプラグインは新しいのや古いのも混ざっていて、sbt プラグインエコシステムの裾野の広さがよく分かる。

本日付では、一覧のうち 70個のプラグインが「リリース済み」となっていて、他にもプラグイン作者やアクティブなユーザによって移行途上の様々なステージにあるものが色々ある。中でも吉田さん ([xuwei-k](https://github.com/xuwei-k)) は、複数箇所に同時に存在するかのような勢いで多くのプラグインの移植作業を行っていた。以下は僕が見つけた範囲:

- https://github.com/scalikejdbc/scalikejdbc/pull/714 
- https://github.com/thesamet/sbt-protoc/pull/30
- https://github.com/sbt/sbt-unidoc/pull/42
- https://github.com/ktoso/sbt-jmh/pull/121
- https://github.com/xuwei-k/sbt-class-diagram/ 
- https://github.com/rtimush/sbt-updates/pull/75
- https://github.com/sbt/sbt-dirty-money/pull/12
- https://github.com/sbt/sbt-site/pull/107
- https://github.com/sbt/sbt-ghpages/releases/tag/v0.6.2 
- https://github.com/sbt/sbt-multi-jvm/pull/34
- https://github.com/sbt/sbt-testng/issues/19
- https://github.com/sbt/sbt-onejar/pull/34

ありがとうございます!

### sbt hotfix 1.0.2

あと、sbt 1.0.2 をリリースしたこともアナウンスします。これは sbt 1.0.x シリーズの hotfix で、バグ修正にフォーカスを当てたバイナリ互換リリースだ。

- ターミナルの echo 問題の修正。 [#3507][3507] by [@kczulko][@kczulko]
- `deliver` タスクの修正、および名前的に改善した `makeIvyXml` というタスクの追加。 [#3487][3487] by [@cunei][@cunei]
- 廃止勧告が出ていた `OkUrlFactory` のリプレースとコネクションのリークの修正。 [lm#164][lm164] by [@dpratt][@dpratt]
- セッティングキーに対して DSL チェッカーが偽陽性を出していたことの再修正。 [#3513][3513] by [@dwijnand][@dwijnand]
- `run` と `bgRun` がクラスパスのディレクトリ内の変更を検知していなかったことの修正。 [#3517][3517] by [@dwijnand][@dwijnand]
- `++` を修正して `crossScalaVersion` が変更されないようにした。 [#3495][3495]/[#3526][3526] by [@dwijnand][@dwijnand]
- sbt server がメッセージを逃すのを修正した。 [#3523][3523] by [@guillaumebort][@guillaumebort]
- `consoleProject` の再修正。 [zinc#386][zinc386] by [@dwijnand][@dwijnand]
- `sbt.gigahorse` という JVM フラグを追加して、Gigahorse が内部で使われるか否かを指定できるようにした。これは、`repositories` オーバーライドと併用したときに発生する `JavaNetAuthenticator` の NPE のための回避策だ。 [lm#167][lm167] by [@cunei][@cunei]
- `sbt.server.autostart` という JVM フラグを追加して、sbt shell を起動した時に sbt server が自動スタートするか否かを指定できるようにした。手動でスタートさせるための、`startServer` コマンドも追加した。 by [@eed3si9n][@eed3si9n]
- 未使用の import 警告の修正。 [#3533][3533] by [@razvan-panda][@razvan-panda]

sbt や Zinc 1 を実際に使ったり、バグ報告、ドキュメンテーションの改善、プラグインを移行したり、pull request を送ってくれた皆さん、ありがとうございました! 

sbt、zinc、librarymanagement、website で実行した `git shortlog -sn --no-merges v1.0.1..v1.0.2` によると、このリリースは 19人のコントリビュータによって提供された: Dale Wijnand, Eugene Yokota, Kenji Yoshida (xuwei-k), Toni Cunei, David Pratt, Karol Cz (kczulko), Amanj Sherwany, Emanuele Blanco, Eric Peters, Guillaume Bort, James Roper, Joost de Vries, Marko Elezovic, Martynas Mickevičius, Michael Stringer, Răzvan Flavius Panda, Peter Vlugter, Philippus Baalman, and Wiesław Popielarski. Thank you!

### ライブラリの移行はまだこれから

多くのメジャーなプラグインが移行され、早期に発見されたバグが修正されたことで、ライブラリ・エコシステムの移行を開始する機運が高まっている。

弊社の Toni Cunei は Dbuild を更新して sbt 1 で Community Build をビルドできる準備を進めている。これがうまくけば、焼き立ての sbt を使ってライブラリをビルドすることで sbt を検証するといったことができるかもしれない。

### sbtfix

sbt 1 マイグレーションに関連して、期待できる進展として、Scala Center の Ólafur Geirsson さんによる [Scalafix 0.5.0](https://scala-lang.org/blog/2017/09/11/scalafix-v0.5.html) のアナウンスがあって、その中で sbt の古いスタイルの演算子を新しい DSL に書き換える新機能が含まれていた。

### 参加

sbt を手伝ってみたいと興味があれば、好みによって色々な方法があると思う。

- プラグインやライブラリを sbt 1 へと移行させる。
- バグを見つけたら報告する。
- バグの修正を送る。
- ドキュメンテーションの更新。

他にもアイディアがあれば、[sbt-contrib](https://gitter.im/sbt/sbt-contrib) で声をかけてください。

  [@dwijnand]: https://github.com/dwijnand
  [@cunei]: https://github.com/cunei
  [@eed3si9n]: https://github.com/eed3si9n
  [@dpratt]: https://github.com/dpratt
  [@kczulko]: https://github.com/kczulko
  [@razvan-panda]: https://github.com/razvan-panda
  [@guillaumebort]: https://github.com/guillaumebort
  [3487]: https://github.com/sbt/sbt/pull/3487
  [lm164]: https://github.com/sbt/librarymanagement/pull/164
  [3495]: https://github.com/sbt/sbt/issues/3495
  [3526]: https://github.com/sbt/sbt/pull/3526
  [3513]: https://github.com/sbt/sbt/pull/3513
  [3517]: https://github.com/sbt/sbt/pull/3517
  [3507]: https://github.com/sbt/sbt/pull/3507
  [3533]: https://github.com/sbt/sbt/pull/3533
  [3523]: https://github.com/sbt/sbt/pull/3523
  [zinc386]: https://github.com/sbt/zinc/pull/386
  [lm167]: https://github.com/sbt/librarymanagement/pull/167
