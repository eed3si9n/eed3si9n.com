---
title:       "sbt 0.13.15 リリースノート"
type:        story
date:        2017-03-12
changed:     2017-04-10
draft:       false
promote:     true
sticky:      false
url:         /ja/sbt-0.13.15
aliases:     [ "/node/215", "/ja/sbt-01315" ]
tags:        [ "sbt" ]
---

### 互換性に影響のある新機能、変更点、バグ修正

- sbt 0.13.14 は Maven のバージョンレンジをできる限り取り除く。詳細は後ほど。

### 改善点

- 予備として JDK 9 との互換性を追加した。この機能は 0.13.14 以降のネイティブパッケージを必要とする。 [#2951][2951]/[143][143] by [@retronym][@retronym]
- オフライン・インストール用に "local-preloaded" レポジトリを追加する。詳細は後ほど。
- ウォーミングアップされた JVM に留まるように、バッチモードで sbt を実行すると `[ENTER]` を押して shell に切り替えるよう通知するようにした。 [#2987][2987]/[#2996][2996] by [@dwijnand][@dwijnand]
- `.taskValue` を使わずに `sourceGenerators += Def.task { ... }` と書けるようにするために `Append` のインスタンスを追加した。 [#2943][2943] by [@eed3si9n][@eed3si9n]
- JUnitXmlTestsListener が生成する XML が無視、スキップ、保留状態のテストにそれぞれフラグを立てるようにした。 [#2198][2198]/[#2854][2854] by [@ashleymercer][@ashleymercer]
- プロジェクトが Dotty を使ってコンパイルしていると検知した場合に、自動的に `scalaCompilerBridgeSource` を設定して、Dotty プロジェクトのボイラープレートを軽減するようにした。ただし、sbt における Dotty サポートは現在実験的であり、正式にはサポートされていないことに注意。詳細は [dotty.epfl.ch][dotty] 参照。 [#2902][2902] by [@smarter][@smarter]
- sbt new のレファレンス実装である Giter8 を 0.7.2 にアップデートした。

### バグ修正

- `.triggeredBy`、`.storeAs` などが　`:=` と `.value` マクロと動作しない問題の修正。 [#1444][1444]/[#2908][2908] by [@dwijnand][@dwijnand]
- JLine を更新して、Windows から Ctrl-C が動作しない問題の修正。 [#1855][1855] by [@eed3si9n][@eed3si9n]
- ビルドレベルのキーの処理を誤っていた 0.13.11 から 0.13.13 のリグレッションの修正。 [#2851][2851]/[#2460][2460] by [@eed3si9n][@eed3si9n]
- `Compile` を継承しないコンフィギュレーションにおいても Scala バージョンの強制を行っていた sbt 0.13.12 におけるリグレッションの修正。 [#2827][2827]/[#2786][2786] by [@eed3si9n][@eed3si9n]
- スクリプトモードにおいてクォーテーションが無視されていたことの修正。 [#2551][2551] by [@ekrich][@ekrich]
- Ivy がときおり IllegalStateException になることの修正。 [#2827][2827]/[#2015][2015] by [@eed3si9n][@eed3si9n]
- sourceFile が null のときに NPE がでることの修正。 [#2766][2766] by [@avdv][@avdv]

### Maven のバージョンレンジの改善

以前は、依存性解決 (Ivy) が `[1.3.0,)` といった Maven のバージョンレンジを見つけると Internet に行って最新のバージョンを探しに行っていた。これは、**範囲の条件を満たすライブラリがビルド内にあったとしても**最終的なバージョンが経年変化するという驚くべき振る舞いをしていた。

sbt 0.13.14 以降は、可能な限り Maven のバージョンレンジをその下限値に置換することで、もしも条件を満たすバージョンが依存性グラフ内にあった場合はそれが使われるようにした。この振る舞いは `-Dsbt.modversionrange=false` JVM フラグによって無効化することができる。

[#2954][2954] by [@eed3si9n][@eed3si9n]

### オフライン・インストール

sbt 0.13.14 は、"local-preloaded-ivy" と "local-preloaded" という 2つの新しいレポジトリを追加して、それらは両方とも `~/.sbt/preloaded/` を参照する。このレポジトリは sbt のアーティファクトを予め積み込む (preload) ことを目的としており、これによって sbt のインストールに Internet へのアクセスが必要無くなった。

また、依存性解決が local-preloaded 向けになるため初回起動時の起動時間が向上される。

[#2993][2993]/[#145][145] by [@eed3si9n][@eed3si9n]

### 備考

アップデートに際してプロジェクト定義の更新は必要無く、sbt 0.13.{x|x<14} から公開されたプラグインも継続して動作するはずだ。

旧演算子の廃止勧告に関しては [Migrating from sbt 0.12.x](http://www.scala-sbt.org/0.13/docs/Migrating-from-sbt-012x.html) 参照。

この場をお借りしてコントリビューターの皆さんにお礼を言いたい。`git shortlog -sn --no-merges v0.13.13..0.13` によると sbt 0.13.13 以降 10人のコントリビューターにより (merge を除く) 42コミットがあった。敬称略 Dale Wijnand, Eugene Yokota,  Guillaume Martres, Jason Zaugg, Petro Verkhogliad, Eric Richardson, Claudio Bley, Haochi Chen, Paul Draper, Ashley Mercer. Thank you!

  [143]: https://github.com/sbt/sbt-launcher-package/pull/143
  [145]: https://github.com/sbt/sbt-launcher-package/pull/145
  [2766]: https://github.com/sbt/sbt/issues/2766
  [1855]: https://github.com/sbt/sbt/issues/1855
  [1466]: https://github.com/sbt/sbt/issues/1466
  [2786]: https://github.com/sbt/sbt/issues/2786
  [2827]: https://github.com/sbt/sbt/pull/2827
  [2828]: https://github.com/sbt/sbt/pull/2828
  [2551]: https://github.com/sbt/sbt/issues/2551
  [2987]: https://github.com/sbt/sbt/issues/2987
  [2996]: https://github.com/sbt/sbt/pull/2996
  [2851]: https://github.com/sbt/sbt/issues/2851
  [2460]: https://github.com/sbt/sbt/issues/2460
  [2951]: https://github.com/sbt/sbt/pull/2951
  [2954]: https://github.com/sbt/sbt/issues/2954
  [2015]: https://github.com/sbt/sbt/issues/2015
  [2827]: https://github.com/sbt/sbt/pull/2827
  [2198]: https://github.com/sbt/sbt/issues/2198
  [2854]: https://github.com/sbt/sbt/pull/2854
  [1444]: https://github.com/sbt/sbt/issues/1444
  [2908]: https://github.com/sbt/sbt/pull/2908
  [2902]: https://github.com/sbt/sbt/pull/2902
  [2993]: https://github.com/sbt/sbt/pull/2993
  [2943]: https://github.com/sbt/sbt/pull/2943
  [@eed3si9n]: https://github.com/eed3si9n
  [@dwijnand]: https://github.com/dwijnand
  [@Duhemm]: https://github.com/Duhemm
  [@avdv]: https://github.com/avdv
  [@ekrich]: https://github.com/ekrich
  [@retronym]: https://github.com/retronym
  [@ashleymercer]: https://github.com/ashleymercer
  [dotty]: http://dotty.epfl.ch/
  [@smarter]: https://github.com/smarter
