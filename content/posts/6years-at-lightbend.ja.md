---
title:       "Lightbend での6年"
type:        story
date:        2020-04-08
changed:     2020-04-09
draft:       false
promote:     true
sticky:      false
url:         /ja/6years-at-lightbend
aliases:     [ /node/324 ]
---

  [1]: https://www.lightbend.com/blog/preview-of-upcoming-sbt-10-features-read-about-the-new-plugins
  [2075]: https://github.com/sbt/sbt/pull/2075
  [road]: https://www.slideshare.net/EugeneYokota/road-to-sbt-10-paved-with-server
  [sphere2017]: https://www.slideshare.net/EugeneYokota/the-state-of-sbt-013-sbt-server-and-sbt-10-scalasphere-ver
  [days2018]: https://www.slideshare.net/EugeneYokota/sbt-1
  [tapad2018]: https://engineering.tapad.com/scala-spree-nyc-a-community-effort-open-sourcing-live-tapad-4844eaf6ebc0
  [berlin2018]: https://www.lightbend.com/blog/berlin-scala-spree
  [orchestration]: https://developer.lightbend.com/docs/lightbend-orchestration/current/
  [6315]: https://github.com/scala/scala/pull/6315
  [6711]: https://github.com/scala/scala/pull/6711
  [native]: https://github.com/sbt/sbt-native-packager/releases/tag/v1.3.16
  [orchestration171]: https://www.lightbend.com/blog/released-lightbend-orchestration-171-and-sbt-native-packager-1318
  [lausanne2019]: https://scaladays.org/2019/lausanne/schedule/sbt-core-concepts
  [sphere2019]: https://www.youtube.com/watch?v=h8ACmUHQ2jg
  [zinc712]: https://github.com/sbt/zinc/pull/712

2014年3月に Lightbend社 (当時 Typesafe社) に入社した。信じられないような 6年の後、2020年4月7日をもって退職となった。Lightbend、パートナー各社、顧客、そしてカンファレンスなどで出会った色んな人とつながりを持ったり一緒に作業する機会をもらえたのは感謝している。振り返ると COVID-19前の時代でヨーロッパ、アジア、北米などを数ヶ月ごとに飛び回ってカンファレンスに出たり社内合宿を行っていたのが現実離れして感じる。

以下は過去6年の簡単な振り返りだ。

### 2014

Scala を趣味で始めたのは 2009年の終わり頃なので、2014年の時点では 4年ぐらいは書いていたのではないか。丁度「独習 Scalaz」が終わって、関連するネタで最初の nescala のトークを行った。10個ぐらいの sbt プラグインを作って、Stackoverflow でも良く活動してた。

3月に Lightbend社のツーリングチーム (当時は Typesafe社「Q課」) に入社した。当時のメンバーは Josh Sereth と Toni Cunei。Josh と sbt のメンテをするのは確かに仕事の分担だけども、仕事は戦略もしくは、難関というか、学びの多い顧客ドリブンなものが大半だった。入社した直後に顧客先に国内線で飛んで、Apache Ivy のコードを読んだりプロファイリングしたりしたのを覚えている。最初は面食らったが、すぐに sbt の中ではライブラリ依存性周りが最も慣れようになった。

2014年5月には sbt のバージョン番号を 0.13.2 から 0.13.5 と飛ばして sbt 1.x シリーズの[テクノロジーレビュー][1]とした。必要な機能を実験的に導入していくことで sbt 1.x との差が大きくなり過ぎないようにするというアイディアだった。

sbt 0.13.6 になって、未解決の依存性のエラーを足りない依存性の木で表示したり、eviction warning、`updateOptions` での `withLatestSnapshots` など僕が追加したライブラリ依存性周りの機能が出てくるようになる。

2014年後半には Q課は Typesafe Reactive Platform v1 のためのインフラ作りを行った。これは Toni が実装した Dbuild を元にした商用配布パッケージだ。

### 2015

2015年3月、Josh と一緒に僕の最初の Scala Days のトーク ['The road to sbt 1.0 is paved with server'][road] を行った。当時の僕から見ると Josh には sbt に関する無限の知見に富んでいるように見えた。

その夏 Josh が退職した。そのため僕が sbt のリードということになったわけだが最初はぎこちないものだった。sbt 0.13.9 を振り返ってみると僕のコントリビューションは、Maven Central の SNAPSHOT の解決を[修正する][2075]といったライブラリ依存性周りが多い。

一方 Reactive Platform は実用され始めていた。

### 2016

2016年には僕はツーリングチーム (当時は Reactive Platform チーム) のテックリードとなった。Reactive Platform v2 を立ち上げ、それはデベロッパーが普通に行っている流れに沿うものを目指した。これらのアイディアはブダペストなどで実際に合っての議論や社内ハッカソンから生まれたものだ。

例えば sbt 0.13.13 は、Jim Powers の `templateResolver` というアイディアと Giter8 を組み合わせて僕が `sbt new` コマンドを実装して、旧来の Activator テンプレートをリプレースした。sbt 1.x を念頭に置いて古い sbt 0.12 からの演算子の廃止勧告なども行った。ツーリングチームは他に Toni と Jim Powers が実装したブラウザベースのプロジェクトスターターを含む Tech Hub の立ち上げも行った。

### 2017

2017年2月に ScalaSphere にて Dale Wijnand と僕で ['The state of sbt 0.13, sbt server, and sbt 1.0'][sphere2017] というトークを行った。このトークで提案されたアイディアとしては sbt を io、util、librarymanagement、Zinc、そして sbt という複数のリポジトリに分け、疎結合なモジュールとしてプラグイン・エコシステムに多くを晒さずに実装を進化させることを目論んだ。もう一つの動機としては、モジュール化して分けて考えることで各モジュール単体での理解が進むと思った。

このトークの後プラグインの作者が Scala 2.10 をサポートしなくてもいいようにと開発のペースが上がって 2017年8月には sbt 1.0.0 がリリースされた。

### 2018

sbt 1.x はセマンティックバージョニングを採用したため、バグ修正はパッチで早めに出るが新機能は sbt 1.1.0、1.2.0、といった形でまとめて出るようになった。2018年1月に出た sbt 1.1.0 を僕は統合スラッシュ構文や sbt サーバなど本当は sbt 1.0 に入れたかったけども安定性を優先して切られた機能が一気に入ったので「ディレクターズ・カット」と呼んだ。

Dale と僕で Scala Days New York と Berlin で [sbt 1 のトーク][days2018]を行う傍ら、[Tapad社主催の Scala Spree NYC][tapad2018]、Zalando社・Scala Center 共催の [Berlin Scala Spree][berlin2018] などにも顔を出してコントリビュータを増やす努力も行った。これらの試みがうまくいったのかは分からないがこの辺りの時期から Ethan Atkins が多くのコントリビューションを出してくれるようになった。

2018年は僕が個人的な時間に scala/scala に対して pull request を送り始めた年でもある。例えば [#6315][6315] (`any2stringadd` の廃止勧告)、[#6711][6711] (タイポ修正のサジェスト) などがある。

2018年後半はツーリングチームが [Lightbend Orchestration][orchestration] を引き継いだ。これは Reactive Platform のアプリケーションを Kubernetes 上にデプロイするためのツール群として始まったプロジェクトだ。Tim Moore その他の落ち着いたガイダンスと共に、僕たちはデプロイ先を絞って (第一候補として OpenShift が選ばれた)、統合テスト用に社内共用の OpenShift クラスターを立ち上げ、徐々にデベロッパーが普通に行っている流れに沿うものに移行することで事態の収拾を図った。これは、Kubernetes とそのエコシステムが Akka Clustering にどう関わるのかといったことを手早く習う必要があったので非常に勉強になった。

### 2019

2019年も引き続き Lightbend Orchestration。OpenShift との互換性を上げるための試みは [sbt-native-packager 1.3.16][native] としてリリースされ、[Lightbend Orchestration 1.7.1][orchestration171] は最後のリリースとなり軟着陸に成功した。

3月は Scala (コンパイラ) チームへ移転した。僕の主な担当はビルドツールや Zinc まわりのままだったけども、Scala チームと一緒に話し合うことで何を改善するべきなのかのフレッシュな視点を得ることができた。9月には Coursier が統合され、super shell が入り、Ethan Atkins によるレイヤー化されたクラスローダと改善されたファイル監視機能の付いた sbt 1.3.0 がリリースされた。

2019年後半は顧客との共同作業で Zinc の改善を行うことに焦点を移した。差分コンパイルの内部についておさらいする必要があった。この時の勉強を元に [Analysis of Zinc][sphere2019] というトークを行った。

### 2020

そしていよいよ 2020年だ。COVID-19 の感染を予防するための「社会距離戦略」以外のことだと、2020年は主に Zinc 関連の作業が多かったと思う。Scala のツール群で僕がずっと欲しかったのはビルドを純粋関数扱いして複数のマシン間でも共有するという機能だ。これはコンパイルや差分コンパイルで使われるロジックが絶対パスを持つ `java.io.File` ことによって妨げられている。[zinc#712][zinc712] はファイルパスをバーチャル化することでマシン独立なものに変換することができる。

### 次のステップ

義務付けられた自宅休養だと思って少し休みながら色々考えてみたい。
その後で、次のビッグプロブレムを解決するための新しいチーム探しを始めると思う。これからも宜しくお願いします。
