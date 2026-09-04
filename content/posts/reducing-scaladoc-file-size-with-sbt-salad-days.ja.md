---
title: "sbt-salad-days を用いた scaladoc ファイルサイズの縮小"
type: story
date: 2026-06-20
url: /ja/reducing-scaladoc-file-size-with-sbt-salad-days
tags: [ "sbt" ]
---

数日前に Maven Central Repository が [Maven Central 公開制限](https://central.sonatype.org/publish/maven-central-publishing-limits/)を仮導入した。この背景は Brian Fox さんの [Open Publishing, Commercial Scale](https://www.sonatype.com/blog/open-publishing-commercial-scale) にまとめられている:

> オープンソースなプロジェクトのメンテナが普通にリリースをしているのは問題無い。しかし、大規模な商用団体が Maven Central を SDK、エージェント、自動生成クライアント、統合モジュール、その他の商用ソフトのコンポーネントの末端分配チャンネルとして使っているのは別問題だ。

ということで、高容量を必要とする商用団体は Maven Central Publisher Pro に移行、オープンソースのプロジェクトはリリースのサイズを削減するか、例外審査の申請をしてくれということらしい。

今これを書いている時点では、ファイルサイズの仮制限は月あたり 80 MB となっている。

これを発端として、Scala ライブラリメンテナの多くが同時に気付かされたのが Scala 3 が生成する Scaladoc のファイルのサイズが異様に大きく、バイトコードの JAR より大きい。`unzip -l` で覗いてみると、Scaladoc JAR の中にフォントとか [VirtusLab/Inkuire](https://github.com/VirtusLab/Inkuire) 検索エンジンみたいなものが入っていて、ファイルサイズが都合 2.5 MB 以上となっている:

```
   203030  01-01-2010 00:00   webfonts/fa-solid-900.eot
   309828  01-01-2010 00:00   fonts/Inter-Regular.ttf
   314712  01-01-2010 00:00   fonts/Inter-Medium.ttf
   315756  01-01-2010 00:00   fonts/Inter-SemiBold.ttf
   316100  01-01-2010 00:00   fonts/Inter-Bold.ttf
   370523  01-01-2010 00:00   scripts/scaladoc-scalajs.js
   747545  01-01-2010 00:00   webfonts/fa-brands-400.svg
   918991  01-01-2010 00:00   webfonts/fa-solid-900.svg
   939517  01-01-2010 00:00   scripts/inkuire.js
```

当座のしのぎとして、全部のフォントと `scripts/inkuire.js` を削除するプラグインを sbt 1.x と 2.x系の両方で作った:

```scala
addSbtPlugin("com.eed3si9n" % "sbt-salad-days" % "0.2.0")
```

これで、小さい Scaladoc なら 420 KB まで削減した:

```bash
$ ls -lh /private/tmp/aaa/target/scala-3.3.8/aaa_3-0.1.0-SNAPSHOT-javadoc.jar
420K /private/tmp/aaa/target/scala-3.3.8/aaa_3-0.1.0-SNAPSHOT-javadoc.jar
```

<https://repo1.maven.org/maven2/com/eed3si9n/sbt-salad-days_sbt2_3/0.1.0/> 自身の Scaladoc も 420 KB だ。


### 更新: 2026-06-23

sbt-salad-days を 0.2.0 に更新して、Scala 2.x の scaladoc からもフォントファイルを削除するようにした。

### 訳註

[salad days](https://www.merriam-webster.com/dictionary/salad%20days) というのは、古くからある英語の言い回しで、野菜と青かったというのをかけて「青春時代」という意味だが、アメリカ英語では「振り返って見ればあの頃が全盛期だった」みたいなポジティブな意味でも使われることも多い。毎日サラダを食べればダイエットになるという意味じゃないが、誤用で敢えて付けた名前。

### 参考文献

- [Open Publishing, Commercial Scale](https://www.sonatype.com/blog/open-publishing-commercial-scale), Brian Fox
- [Maven Central Publishing Limits](https://central.sonatype.org/publish/maven-central-publishing-limits/)
- [sbt-salad-days](https://github.com/sbt/sbt-salad-days)
- 実際の修正案に関する議論は [scala3#26387](https://github.com/scala/scala3/issues/26387) 'Scaladoc impact on deployments size' 参照。
