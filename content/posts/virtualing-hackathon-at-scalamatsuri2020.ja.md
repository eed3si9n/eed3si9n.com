---
title:       "ScalaMatsuri 2020 におけるハッカソンの仮想化"
type:        story
date:        2020-10-19
draft:       false
promote:     true
sticky:      false
url:         /ja/virtualizing-hackathon-at-scalamatsuri2020
aliases:     [ /node/361 ]
tags:        [ "scala" ]
---

本稿は ScalaMatsuri Day 2 アンカンファレンスで OSS ハッカソンを仮想化したことのレポートだ。誰かがアンカンファレンスのトピックとして提案したらしく、僕は朝会でファシリテーターとして申し出ただけなので事前準備は特に無し。元々は 4時間 (JST 正午 - 4pm、EDT 11pm - 3am) で枠をもらったが、うまく回ったのでコーヒーブレイクの後も数時間続いた。

アンカンファレンスをやるときにいつも強調してるのは「二本足の法則」で:

> いつでも自分にとってその場からの「学び」や自分から場への「貢献」が無いなと感じた場合: 自分の二本足を使って別の場へ移動すること

オンラインのアンカンファレンスで、複数のセッションが行われているので別のトークを見るために抜けたり途中から参加することは自由であることを事前に伝えた。

### 使ったもの

- Zoom Meeting
- Discord
- Google Docs

主なコミュニケーションは ScalaMatsuri が用意していた Zoom Meeting を使った。これで異なる参加者が自分の画面を共有したり質問をしたりできる。潜在的な問題としては、全員が他の人全員を聞こえる状態になるので、複数のグループが同時にペアプログラムをしたいといった状況には向かない。

テキストベースのコミュニケーションとしては Discord を使った。Discord はリンクを共有したり、質問をしたりにも使う。僕たちはやらなかったが、Discord のボイスチャンネルを使って[画面の共有](https://support.discord.com/hc/en-us/articles/360040816151-Share-your-screen-with-Go-Live-Screen-Share)も可能なのでプロジェクト毎にボイスチャンネル分かれるという使う方もできると思う。

プロジェクトと GitHub issue の列挙、どの作業をしたりのかのサインアップには Google Doc 一枚を使った。

### 流れ

- メンターをできるプロジェクトメンテナの人が参加してるかを聞く
- プロジェクトメンテナは他の人が手を付けやすい good first な GitHub issue を Google doc に書いて、Zoom でその簡単な説明をする。
- 参加者は issue の隣に自分の名前を書いてサインアップする (ペアで一つの issue に取り組むことも可)
- プロジェクトメンテナは単体テストと統合テスト (scala/scala だと partest、sbt/sbt だと scripted) の走らせ方を解説
- 自分も共同作業する場合はプロジェクトメンテナはもっとチャレンジングなタスクを提案してもいい
- 人の出入りがあるので、上記をリピート
- 基本的にはミュートしてハック
- ファシリテーターは、皆が作業するものがあるかどうかの確認を定期的に行う
- 誰かがタスクを完了したら成功でも失敗でも Zoom で軽く発表する。(参加者が多い場合はこれは1日の最後にやってもいい)

### scala/scala

Scala のコンパイラや標準ライブラリが開発される scala/scala にコントリビュートに興味がある人が多かった。明らかなバグ修正じゃない場合は scala/scala へのプルリクは数ヶ月放置されたりする可能性もある旨を注意した。

面白いことにアサインされた最初の issue は参加していた @exoego さんがエンバグしたものみたいだったので渋谷さんとペアで見ていただきました。

- Mitsuhiro Shibuya さん (@mshibuya) は [Fix ArrayBuffer incorrectly reporting the upper bound in IndexOutOfBoundsException #9249][9249] を送りました
- Kazuhiro Sera さん (@seratch) を [WIP: Add a regression test for issue #10134 #9250][9250] を送りました
- 瀬良さんは [Fix #12065 by adding scaladocs][9251] も送りました
- Taisuke Oe さん (@taisukeoe) は [tailrec doesn't mind recursive calls to supertypes in branches #11989][11989] を調査中
- TAKAHASHI Osamu さん (@zerosum) は [Scaladoc member permalinks now get us to destination, not to neighbors #9252][9252] を送りました

役に立つかもしれないリンク:
- https://github.com/scala/scala/blob/2.13.x/CONTRIBUTING.md#junit
- https://github.com/scala/scala/blob/2.13.x/CONTRIBUTING.md#partest
- https://docs.scala-lang.org/ja/overviews/reflection/symbols-trees-types.html

### sbt

good first な issue を考えるのはどのプロジェクトでも実は難しかったりする。簡単すぎる場合もあれば、一見簡単に見えて一日じゃ直すのが不可能なバグであったりする可能性もある。sbt に関しては、最近出た sbt 1.4.0 新機能周りのバグ修正を提案した。

- Kenji Yoshida さん　(@xuwei-k) は自主的に [bumped up Dotty versions used in scripted tests #5982][5982] を送りました
- 吉田さんは [Scala-2-dependsOn-Scala-3 feature with Scala.js #5984][5984] も修正しました
- Taichi Yamakawa さん (@xirc) は [build linting warning about shellPrompt key #5983][5983] を送りました
- Yamakawa さんは [Use `lint***Filter` instead of `***LintKeys` for more reliable tests #5985][5985] も送りました
- Eugene Yokota (@eed3si9n) は [Try to workaround "a pure expression does nothing" warning #5981][5981] の作業をしました

### sbt-gpg

- Mitsuhiro Shibuya さん (@mshibuya) [gpg コマンドの出力が stderr のロクレベルが error でミスリーディング #181][181] なのを修正しました

### Airframe

メンテナの Taro Saito さん (@xerial) が参加してて Scala Steward だと Scalafmt のバージョンを上げたあと scalafmt を走らせないので PR が止まっててそれを誰か手動で直してくれないかというリクエストがありました。

- TAKAHASHI Osamu さんが (@zerosum) [update scalafmt-core to 2.7.5 #1323][1323] を送りました

### Scala Steward

TATSUNO Yasuhiro さん (@exoego) は大本の原因を直そうと Scala Steward 本体へチャレンジ。

- TATSUNO Yasuhiro さん　(@exoego) は [Run scalafmt when upgrading scalafmt (opt-in) #1673][1673] を送りました

### まとめ

今後レビューなどが入って引き続き作業が必要なものもあると思うが、皆で 12ぐらいのプルリクを送ることができ、うまくいったと思う。当然誰かが 1日で作業できるよりも多くの作業量だ。そういう意味では、このようなハッカソン的なイベントを行うことは issue を見つけて、有志の人が集まれる場があれば多大な戦力倍増となると思う。

GitHub issue の話をしたりコードを書いたりというコンテキストを通じて、もう何年も知っている Scala プログラマーと楽しい時を過ごせ、今まで話したこと無かった人とも話せたのは良かった。誰もコード書かなかったら機能しなかったセッションなので、参加してくださった皆さんありがとうごさいます。

  [9249]: https://github.com/scala/scala/pull/9249
  [9250]: https://github.com/scala/scala/pull/9250
  [9251]: https://github.com/scala/scala/pull/9251
  [9252]: https://github.com/scala/scala/pull/9252
  [11989]: https://github.com/scala/bug/issues/11989
  [5982]: https://github.com/sbt/sbt/pull/5982
  [5984]: https://github.com/sbt/sbt/pull/5984
  [5985]: https://github.com/sbt/sbt/pull/5985
  [5981]: https://github.com/sbt/sbt/pull/5981
  [1323]: https://github.com/wvlet/airframe/pull/1323
  [1673]: https://github.com/scala-steward-org/scala-steward/pull/1673
  [181]: https://github.com/sbt/sbt-pgp/pull/181
