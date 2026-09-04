---
title: "Maven Central 公開制限例外審査のすすめ"
type: story
date: 2026-09-02
url: /ja/maven-central-publishing-limits
tags: [ "sbt" ]
---

普通に有志の人が公開しているオープンソースプロジェクトが Maven Central の公開制限を上回っている場合は、例外審査を申請するべきだと思う。

<!--more-->

### これまでの経緯

2026年6月に Maven Central Repository が [Maven Central 公開制限](https://central.sonatype.org/publish/maven-central-publishing-limits/)が**仮導入**された。この背景は Brian Fox さんの [Open Publishing, Commercial Scale](https://www.sonatype.com/blog/open-publishing-commercial-scale) にまとめられている:

> オープンソースなプロジェクトのメンテナが普通にリリースをしているのは問題無い。しかし、大規模な商用団体が Maven Central を SDK、エージェント、自動生成クライアント、統合モジュール、その他の商用ソフトのコンポーネントの末端分配チャンネルとして使っているのは別問題だ。

6月の当初に気付いたのは Scaladoc の JAR にフォントが入っていることで不必要に大きいことで、その対策として [sbt-salad-days](/ja/reducing-scaladoc-file-size-with-sbt-salad-days) というプラグインでファイルサイズを縮小したり、フォント関連のプルリクが [Scala 3](https://github.com/scala/scala3/pull/26393) や [Scala 2.x](https://github.com/scala/scala/pull/11265) に送られたりしている。これで不必要にファイルサイズが大きくなっていた対策は取れた。

2026年9月現在、Maven Central の月当たりの公開制限は:

- ファイルサイズの合計: 80 MB
- ファイル数の合計: 1000個
- リリース回数: 7回

となっている。Sonatype社は、これらの値は 90パーセンタイルから導出したという説明をしているが、どの値を取っても普通にアクティブなプロジェクトなら足りなくなるはずだと思う。吉田さんの [Scalaでのcross buildとmaven centralのpublish制限](https://xuwei-k.hatenablog.com/entry/2026/09/02/134937)にも書かれているが、アーティファクト 1つに対して 16個のファイルが必要となるので、ライブラリを複数のサブプロジェクトに分けたり、複数のプラットフォーム向けにクロスビルドすると 1000個のファイルぐらいすぐ超えてしまう。

ここで今一度 [Open Publishing, Commercial Scale](https://www.sonatype.com/blog/open-publishing-commercial-scale) を読むと、Sonatype社が問題視しているのは善意で無料提供されているコモンズ (共同資産) を一部の商用団体が商用ソフトの配布や CIインフラとして濫用していることであることが書かれている。

> Second, legitimate open source projects with unusual publishing patterns may request an exemption for review.
>
> (不必要な公開を回避する努力をした) 次に、正当なオープンソースプロジェクトが統計より外れた公開パターンがある場合は、例外審査を申請することができる。

公開制限の本運用が 8月11日に開始される予定だったが、10月1日まで延期されため、本運用まで一ヶ月の猶予がある。

### 有志オープンソース・プロジェクトの公開

有志の人たちが非商用目的で公開しているオープンソースプロジェクトが公開制限を上回っている場合は [Community Open Source Publishing](https://central.sonatype.org/publish/maven-central-publishing-limits/#community-open-source-publishing) を参照するよう書かれている。

Usage Center を見て、プロジェクトの通常の公開パターンでも制限を上回る場合は `central-support@sonatype.com` に連絡して例外審査を申請するべきだ。含める情報は以下の通り:

1. Namespace (名前空間)
2. Organization (団体名)
3. Description of the project (プロジェクトの簡単な説明)
3. Explanation of the publishing pattern (公開パターンの説明)
4. Whether the usage is sustained, occasional, or related to a specific event such as a security fix (使用パターンが継続的、断続的、もしくはセキュリティ修正などによる臨時なものか)
5. Reason higher limits or an exemption are needed (より高い限度もしくは適用除外が必要な理由)

メールそのものの定型は以下の通り:

```
Hi Sonatype team,

Thank you for your continuous support of the open source community on JVM.
I'm <自分のフルネーム>, a maintainer of <自分のプロジェクト名>.

I am writing to request for increased release monthly quota. Here are the requested info:

1. Namespace: <com.example>
2. Organization: <自分のプロジェクト> is primarily maintained by the community effort.
3. Description of the project: <プロジェクトの簡単な説明>
4. Explanation of the publishing: <公開パターンの説明>
5. Whether the usage is sustained, occasional, or related to a specific event: <使用パターンが継続的、断続的、もしくはセキュリティ修正などによる臨時なものか>
6. Reason higher limits or an exemption are needed: <より高い限度もしくは適用除外が必要な理由>

<敬具>,
<自分のフルネーム>
```

全員が全く同じ文面で申請をしてきたら、怪しまれて申請が通らなくなると思うので、独自の内容を考えて Google Translate などで英訳してみよう。

- 「プロジェクトの簡単な説明」の部分は何々をするライブラリですという他に、何年に始まったプロジェクトで、何とかの分野で採用されているみたいな情報を入れることをお勧めする。
- 「公開パターンの説明」は、だいたい月に何回ぐらいリリースを行っていて、リリース毎に何個のファイルが公開されるみたいな情報が求められているのだと思う。
- 「使用パターンが継続的、断続的、もしくはセキュリティ修正などによる臨時なものか」継続的に、毎月ファイル数が超過する場合は、The usage is sustained because `<理由>`、といるふうになると思う。
- 「より高い限度もしくは適用除外が必要な理由」。非商用のオープンソースプロジェクトで、他のプロジェクトの役に立っているからみたいな内容で。
- 「敬具」。メールの結びで、Best、Best regards、Sincerely、Thank you in advance、Take care、Looking forward to your response とか色々あるうちから好きなものを選ぶ。

sbt は、普通のオープンソースプロジェクトだが、リリースのサイズもファイル数も大幅に公開制限を超過するので、6月の時点ですぐに例外審査の申請を行って、二ヶ月経った 8月になって公開制限の引き上げを承認してもらった。
