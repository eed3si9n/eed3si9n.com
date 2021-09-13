---
title:       "sbt 1.3.12"
type:        story
date:        2020-05-31
draft:       false
promote:     true
sticky:      false
url:         /ja/sbt-1.3.12
aliases:     [ /node/342 ]
---

  [5583]: https://github.com/sbt/sbt/pull/5583
  [ivy39]: https://github.com/sbt/ivy/pull/39
  [5059]: https://github.com/sbt/sbt/issues/5059
  [5512]: https://github.com/sbt/sbt/pull/5512
  [5497]: https://github.com/sbt/sbt/issues/5497
  [5535]: https://github.com/sbt/sbt/pull/5535
  [5537]: https://github.com/sbt/sbt/pull/5537
  [5540]: https://github.com/sbt/sbt/pull/5540
  [5563]: https://github.com/sbt/sbt/pull/5563
  [5580]: https://github.com/sbt/sbt/pull/5580
  [launcher75]: https://github.com/sbt/launcher/pull/75
  [@itviewer]: https://github.com/itviewer
  [@eed3si9n]: https://github.com/eed3si9n
  [@retronym]: https://github.com/retronym
  [@drocsid]: https://github.com/drocsid
  [@bjaglin]: https://github.com/bjaglin
  [@dwijnand]: https://github.com/dwijnand

sbt 1.3.12 パッチリリースをアナウンスする。リリースノートの完全版はここにある - https://github.com/sbt/sbt/releases/tag/v1.3.12 。

特に Scala Center にお礼を言いたい。バグ報告、pull request レビュー、コントリビューションがちゃんと正しい所に行くかなどメンテ活動を行うにはある程度時間がかかるが、5月中の sbt のメンテ活動は Scala Center がスポンサーしてくれた。Daryja さん始め Scala Center のメンバーは皆気軽に共同作業しやすい人たちだ。

### sbt 1.3.11 からの変更点

sbt 1.3.11 で launcher 統合周りにリグレッションがあり、`repositories` ファイルが無視されるという形のバグが出た。sbt 1.3.12 はそれを修正する。 [#5583][5583]

### アップグレード方法

通常は `project/build.properties` を

```
sbt.version=1.3.12
```

と書き換えるだけで ok だ。しかし、リリースにスクリプトの修正が含まれている場合もあり、また全ての JAR ファイルが予め入った `*.(zip|tgz|msi)` を使ったほうが初回の依存性解決が速くなるためインストーラーを使ったインストールを推奨する。インストーラーは SDKMAN などに公開される。

```
sdk upgrade sbt
```

#### Homebrew に関する注意

Homebrew のメンテナはもっと brew 依存性を使いたいという理由で JDK 13 への依存性を追加した [brew#50649](https://github.com/Homebrew/homebrew-core/issues/50649)。そのため、PATH が通っている `java` が JDK 8 や 11 であっても sbt が JDK 13 で実行されるようになってしまう。

`sbt` が JDK 13 で実行するのを回避するには [jEnv](https://www.jenv.be/) をインストールするか、[SDKMAN](https://sdkman.io/) に乗り換える必要がある。

### 主な変更点

sbt 1.3.12 は lm-coursier を [2.0.0-RC6-4](https://github.com/coursier/sbt-coursier/releases/tag/v2.0.0-RC6-4) へとアップグレードし、これはキャッシュの場所としての `$HOME/.coursier/cache` ディレクトリを廃止して、OS に特定のディレクトリを使うようになる:

- macOS は `$HOME/Library/Caches/Coursier/v1`
- Windows は `%LOCALAPPDATA%\Coursier\Cache\v1`
- Linux その他は `$HOME/.cache/coursier/v1`

その他:

- Apache Ivy が HTTP リダイレクト処理を行うように変更した [ivy#39][ivy39] / [#5059][5059] by [@itviewer][@itviewer]
- sbt-giter8-resolver 0.12.0 へと更新した。これは `project/build.properties` を用いた [`giter8.version` サポート](http://eed3si9n.com/giter8-0.12.0)を導入する。  [#5537][5537] by [@drocsid][@drocsid]

### 参加

sbt 1.3.12 は Scala Center + 7名のコントリビューターにより作られた。Eugene Yokota (eed3si9n), Alexandre Archambault, Brice Jaglin, Colin Williams, Dale Wijnand, Jason Zaugg, and Xinjun Ma。この場をお借りしてコントリビューターの皆さんにお礼を言いたい。

他にも sbt や Zinc 1 を使ったり、バグ報告したり、ドキュメンテーションを改善したり、ビルドを移植したり、プラグインを移植したり、pull request を送ったりレビューをするなどして sbt を改善してくれている皆さんにも感謝。

sbt を手伝ってみたいなという人は興味次第色々方法がある。[Contributing](https://github.com/sbt/sbt/blob/develop/CONTRIBUTING.md)、["help wanted"](https://github.com/sbt/sbt/issues?q=is%3Aissue+is%3Aopen+label%3A%22help+wanted%22)、["good first issue"](https://github.com/sbt/sbt/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22) などが出発地点になると思う。
