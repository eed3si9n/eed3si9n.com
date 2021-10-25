---
title:       "sbt 1.4.1"
type:        story
date:        2020-10-19
draft:       false
promote:     true
sticky:      false
url:         /ja/sbt-1.4.1
aliases:     [ /node/363 ]
---

sbt 1.4.1 パッチリリースをアナウンスする。リリースノートの完全版はここにある - https://github.com/sbt/sbt/releases/tag/v1.4.1

### アップグレード方法

**公式 sbt ランチャー**を SDKMAN か <https://www.scala-sbt.org/download.html> からダウンロードしてくる。このインストーラーには `sbtn` のバイナリが含まれている。

次に、使いたいビルドの `project/build.properties` ファイルに以下のように書く:

```bash
sbt.version=1.4.1
```

この機構によって使いたいビルドにだけ sbt 1.4.1 が使えるようになっている。

### 主な変更点

- [@eatkins][@eatkins] さんによる read line とか文字処理まわりの様々な変更。例えば、`sbt new` で文字がエコーされてこない問題など。
- Scala.JS での Scala 2.13-3.0 サンドイッチの修正 [#5984][5984] by [@xuwei-k][@xuwei-k]
- `shellPrompt` とか `release*` キーなど build lint 時の警告の修正 [#5983][5983]/[#5991][5991] by [@xirc][@xirc] and [@eed3si9n][@eed3si9n]
- `plugins` コマンドの出力をサブプロジェクトで分けるようにした改善 [#5932][5932] by [@aaabramov][@aaabramov]

その他は https://github.com/sbt/sbt/releases/tag/v1.4.1 を参照

### 参加

sbt 1.4.1 は 9名のコントリビューターにより作られた。 Ethan Atkins, Eugene Yokota (eed3si9n), Adrien Piquerez, Kenji Yoshida (xuwei-k), Nader Ghanbari, Taichi Yamakawa, Andrii Abramov, Guillaume Martres, Regis Desgroppes。この場をお借りしてコントリビューターの皆さんにお礼を言いたい。また、これらのコントリのいくつかは ScalaMatsuri 2020 中の[ハッカソン][1]にて行われた。

他にも sbt や Zinc 1 を使ったり、バグ報告したり、ドキュメンテーションを改善したり、ビルドを移植したり、プラグインを移植したり、pull request を送ったりレビューをするなどして sbt を改善してくれている皆さんにも感謝。

sbt を手伝ってみたいなという人は興味次第色々方法がある。[Contributing](https://github.com/sbt/sbt/blob/develop/CONTRIBUTING.md)、["help wanted"](https://github.com/sbt/sbt/issues?q=is%3Aissue+is%3Aopen+label%3A%22help+wanted%22)、["good first issue"](https://github.com/sbt/sbt/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22) などが出発地点になると思う。

  [1]: https://eed3si9n.com/ja/virtualizing-hackathon-at-scalamatsuri2020
  [5930]: https://github.com/sbt/sbt/pull/5930
  [5946]: https://github.com/sbt/sbt/pull/5946
  [5945]: https://github.com/sbt/sbt/pull/5945
  [5947]: https://github.com/sbt/sbt/pull/5947
  [5961]: https://github.com/sbt/sbt/pull/5961
  [5960]: https://github.com/sbt/sbt/pull/5960
  [5966]: https://github.com/sbt/sbt/pull/5966
  [5954]: https://github.com/sbt/sbt/pull/5954
  [5948]: https://github.com/sbt/sbt/pull/5948
  [5964]: https://github.com/sbt/sbt/pull/5964
  [5967]: https://github.com/sbt/sbt/pull/5967
  [5950]: https://github.com/sbt/sbt/issues/5950
  [5932]: https://github.com/sbt/sbt/pull/5932
  [5972]: https://github.com/sbt/sbt/pull/5972
  [5973]: https://github.com/sbt/sbt/pull/5973
  [5975]: https://github.com/sbt/sbt/pull/5975
  [5984]: https://github.com/sbt/sbt/pull/5984
  [5983]: https://github.com/sbt/sbt/pull/5983
  [5981]: https://github.com/sbt/sbt/pull/5981
  [5991]: https://github.com/sbt/sbt/pull/5991
  [5990]: https://github.com/sbt/sbt/pull/5990
  [zinc931]: https://github.com/sbt/zinc/pull/931
  [zinc934]: https://github.com/sbt/zinc/pull/934
  [@adpi2]: https://github.com/adpi2
  [@eed3si9n]: https://github.com/eed3si9n
  [@eatkins]: https://github.com/eatkins
  [@xuwei-k]: https://github.com/xuwei-k
  [@rdesgroppes]: https://github.com/rdesgroppes
  [@naderghanbari]: https://github.com/naderghanbari
  [@aaabramov]: https://github.com/aaabramov
  [@xirc]: https://github.com/xirc
  [@smarter]: https://github.com/smarter