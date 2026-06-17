---
title: "sbt 2.0.0"
type: story
date: 2026-06-16
url: /ja/sbt-2.0.0
tags: [ "sbt" ]
---

sbt プロジェクトを代表して sbt 2.0.0 のリリースをアナウンスします。sbt 2.0 は、Scala 3 と Bazel 互換なキャッシュ・システムに基づいた新しい sbt メジャー・バージョンの系列です。

sbt 2.x は引き続き Semantic Versioning に準拠してリリースされるので、プラグインは 2.x系ずっと動作することが期待されいます。是非使ってみて、不具合などがあれば報告をお願いします。

<!--more-->

### sbt 2.0 の主な機能

- sbt 2.x は、ビルド定義やプラグインは Scala 3.8.4 を採用するため、**JDK 17** 以上を必要とする。sbt 1.x 並びに 2.x は、Scala 2.x と 3.x の両方をビルドすることが可能。
- 起動の高速化のため、sbtn (native-image のクライアント) をデフォルトで使用。
- コモン・セッティング。`build.sbt` に直書きされたセッティングは、ルートプロジェクトだけではなく、全てのサブプロジェクトに追加され、これまで `ThisBuild` が受け持ってきた役目を果たすことができる。
- 差分テスト。test は、テスト結果をキャッシュする差分テストへと変更された。
- Bazel 互換かつローカル/リモート兼用のキャッシュシステム。`compile` と `test` の両方ともキャッシュ化タスクへと書き換えられた。
- project matrix。sbt 1.x からプラグインで使用可能だった project matrix が本体に取り込まれ、並列クロスビルドができるようになった。
- sbt 2.x は統一スラッシュ構文を拡張してサブプロジェクトのクエリを可能とする。
- クライアントサイド・ラン。
- クライアントサイド REPL。
- 新しいドキュメンテーション

詳細は [sbt 2.0 の変更点](https://www.scala-sbt.org/2.x/docs/ja/changes/sbt-2.0-change-summary.html)参照。

### アップグレード方法

sbt 2.0.0 以降の公式 sbt ランナーを SDKMAN もしくは <https://github.com/sbt/sbt/releases/tag/v2.0.0> からダウンロードして `sbt` シェルスクリプト、ランチャー、および sbtn をアップグレードする。ランナーは任意のバージョンの sbt を起動できる。

実際にビルドが使用する sbt のバージョンは `project/build.properties` ファイルによって管理される:

```bash
sbt.version=2.0.0
```

この機構によって、使いたいビルドにだけ sbt 2.0.0 を使うことができる。

### ドキュメンテーションのローカリゼーション

[sbt 2.x ドキュメンテーション (英語版)](https://www.scala-sbt.org/2.x/docs/en/index.html) は、[Diátaxis](https://diataxis.fr/) というドキュメンテーションを 4種類に分けて考えるという方法論に基づいている。

ほとんどのページはローカライズされており、例えば [why sbt exists](https://www.scala-sbt.org/2.x/docs/en/guide/why-sbt-exists.html) (英語版) は、[sbt の存在理由](https://www.scala-sbt.org/2.x/docs/ja/guide/why-sbt-exists.html) (日本語版) と[sbt 的存在理由](https://www.scala-sbt.org/2.x/docs/zh-cn/guide/why-sbt-exists.html) (中国語、簡体字) に翻訳されている。ドキュメンテーション関連のコントリビューションも歓迎する。

### プラグイン・エコシステムの移行

[プラグインのクロスビルド協力お願い](https://github.com/sbt/sbt/wiki/sbt-2.x-plugin-migration)の wiki ページは現在、sbt 1.x系と 2.x系の両方にクロスビルドすることで移行中のプラグインが数十個書かれている。マイグレーション・キャンペーンに抜けているものがあれば報告してほしい。

### 参加

僕は sbt 開発は今のところ業務外の自分の時間で行っていて、Scala Center 関係者の Anatolii Kmetiuk さん (新メンテナ)、Adrien Piquerez さん (卒業)、および Kenji Yoshida (吉田憲治) さん、Jerry Tan さん、Matthias Kurz さん (Play メンテナ)、Billy Autrey さんなどの多くの有志の方々に協力してもらっている。

sbt 2.0.0 は、sbt 1.x系の開発、プラグインの移行などを含めると大勢のコントリビューターの協力によって開発されたが、`git shortlog -sn --no-merges 00eba85d98c854527125ae1655b5332c19b5afd8...733bcfb23997930915b563e7d27b1a1f6c0490da --not 1.11.x` と `git shortlog -sn --group=author --group=trailer:co-authored-by --no-merges 242bd18d30c418620024d089b587f6d263d34247...v2.0.0 --not 1.12.x` によると、新規のコミットは以下のとおり (敬称略):

```
545 Eugene Yokota (eed3si9n)
217 Kenji Yoshida (xuwei-k)
146 Adrien Piquerez
51  Jerry Tan (friendseeker)
37  MkDev11
34  bitloi
30  Scala Steward
21  calm329
16  Anatolii Kmetiuk
15  dependabot[bot]
14  Yasuhiro Tatsuno
13  E.G
11  Pandaman
10  João Ferreira
9   Anton Sviridov
9   Brian Hotopp
8   Aleksandra Zdrojowa
7   Dream
7   GlobalStar117
7   Matt Dziuban
5   Dairus
4   Martin Duhem
4   john0030710
3   Angel98518
3   Brice Jaglin
3   Li Haoyi
3   gayanMatch
2   Ali Rashid
2   Billy Autrey
2   BitToby
2   Damian Reeves
2   Daniil Sivak
2   Dmitrii Naumenko
2   Douglas Ma
2   Frank S. Thomas
2   Jame4u
2   Josh Soref
2   Kamil Podsiadło
2   Marco Zühlke
2   Matthew de Detrich
2   Matthias Kurz
2   Michał Pawlik
2   Miguel Vilá
2   NeedmeFordev
2   Pluto
2   Renzo
2   Rikito Taniguchi
2   SID
2   Satoshi Dev
2   byteforge
2   circlecrystalin
2   it-education-md
1   Albert Meltzer
1   Deborah Funmilola Olaboye
1   Eve
1   Francluob
1   Guillaume Massé
1   Hamza Remmal
1   Hugo van Rijswijk
1   Idan Ben-Zvi
1   Jakub Kozłowski
1   James Roper
1   Karl Yngve Lervåg
1   Lazz
1   Lukas Rytz
1   Nikita Vilunov
1   OlegYch
1   Pegasus
1   Rex Kerr
1   Roberto Tyley
1   Saber
1   SalesforcePeak
1   SlowBrainDude
1   Zainab Ali
1   bohdansolovie
1   chrisrock1124
1   corevibe555
1   dev-miro26
1   dive2tech
1   fireXtract
1   kijuky
1   nathanlao
```

この場をお借りしてコントリビューターの皆さんにお礼を言いたい。他にも sbt や Zinc を使ったり、バグ報告したり、ドキュメンテーションを改善したり、ビルドを移植したり、プルリクエストをレビューをするなどして sbt を改善してくれている皆さんにも感謝。

sbt を手伝ってみたいなという人は興味次第色々方法がある。[Contributing](https://github.com/sbt/sbt/blob/develop/CONTRIBUTING.md)、["help wanted"](https://github.com/sbt/sbt/issues?q=is%3Aissue+is%3Aopen+label%3A%22help+wanted%22)、["good first issue"](https://github.com/sbt/sbt/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22) などが出発地点になると思う。

----

### Scala Days でのトーク

Scala Days 2025 にて sbt 2.0 の発表を行った ([英語動画](https://www.youtube.com/watch?v=GM2ywMb4z7A), [資料](https://www.slideshare.net/slideshow/sbt-2-0-go-big-scala-days-2025-edition/282592302))。

### Scala Center への募金

Scala Center は、教育とオープンソースを支援する EPFL に所属する非営利団だ。

- [Scala Center 募金キャンペーン](https://scala-lang.org/blog/2023/09/11/scala-center-fundraising.html)

  [migration]: https://www.scala-sbt.org/2.x/docs/en/changes/migrating-from-sbt-1.x.html
  [@eed3si9n]: https://github.com/eed3si9n
  [@anatoliykmetyuk]: https://github.com/anatoliykmetyuk
  [@adpi2]: https://github.com/adpi2
  [@xuwei-k]: https://github.com/xuwei-k
  [@bitloi]: https://github.com/bitloi
  [@eureka0928]: https://github.com/eureka0928
  [@tanishiking]: https://github.com/tanishiking
  [@bittoby]: https://github.com/bittoby
  [@mkurz]: https://github.com/mkurz
  [@zainab-ali]: https://github.com/zainab-ali
  [@arashi01]: https://github.com/arashi01
  [@lihaoyi]: https://github.com/lihaoyi
  [@BrianHotopp]: https://github.com/BrianHotopp
