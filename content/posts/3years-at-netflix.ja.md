---
title: "Netflix での 3年"
type: story
date: 2026-07-21
url: /ja/3years-at-netflix
---

2023年1月に Netflix のパーソナリゼーションとリコメンデーション部のツーリングチームに入社した。3年半の勤務の後、2026年7月13日をもって退職した。AI for Member Systems と AI Platform という 2つの素晴らしい部署に参加して、Netflix社の切磋琢磨と多様性という[カルチャー][1]を身を持って体験できたことを感謝している。

<!--more-->

### AIMS (AI for Member Systems)

AIMS は、レコメンデーションだけではなく、パーソナリゼーション、検索、発見、メッセージングなどのアルゴリズムを受け持つ研究者、エンジニア、データサイエンティスト、マネージャから構成される横断型な部署だ。このグループがやっていることは、以下の公開されているトークや記事などから垣間見ることができる:

- [Recommending for Long-Term Member Satisfaction at Netflix](https://netflixtechblog.com/recommending-for-long-term-member-satisfaction-at-netflix-ac15cada49ef) (2024)
- [Foundation Model for Personalized Recommendation](https://netflixtechblog.com/foundation-model-for-personalized-recommendation-1a0bd8e02d39) (2025)
- [How Netflix Built a Single Model for Search & Recommendations](https://www.youtube.com/watch?v=mf1EeqkMbdk) (2026)

[カルチャーメモ][1]の第一原則は「ドリームチーム」で、AIMS と AIP で毎日それを実感していた。周りにいたほとんどの人が、学術的または実務的な経験に裏打ちされた、特定分野での深い専門知識を持っていた。全員が専門家であるミーティングでに座るのは最初は気後れするものだが、自分にも会話に持ち込める専門性があると気づく瞬間が訪れる。何百人もの意欲的な専門家チームプレイヤーに Slack でメッセージを送れることが、Netflix で働く一番楽しい部分だ。

### 2023年

僕が AIMS の PTR (Productivity, Tooling, and Reliability; 生産性、ツーリング、信頼性) チームに加わった 2023年はちょうど、グループ内の複数のアルゴリズムリポジトリを多言語対応の Bazel 「モノリポ」に統合している最中だった。入社二週間目には、その移行を主導していたエンジニアが退職してしまった。そのため、チームは自分を含む 1.5人で担当することになった。

[カルチャーメモ][1]の第二原則は「プロセスよりも人」、かつては「自由と責任」と呼ばれていたものだ。トップダウンの意思決定ではなく、チームや個人が自分たちの仕事について自ら判断を下す裁量を与えられている。グループが会社の他の部分とは異なるビルドツールを採用したのは、この裁量を行使した一例であり、それによって CI を50倍高速化できた。

さまざまなデプロイ構成に慣れた後、僕が最初に提案したことの一つが、Bazel でのクロスビルドのセットアップであり、これにより Python ML ライブラリや Scala のバージョンなどを段階的、かつ効率的に移行できるようになった。

3月にはスイスのローザンヌで Scala Center が開催した [Scala Tooling Summit](https://www.scala-lang.org/blog/2023/04/11/march-2023-scala-tooling-summit.html) にも参加させてもらって、Bazel や sbt 2 などについて議論した。このサミットから生まれた興味深い成果の一つが、actionable diagnosis 機能だった。これはコンパイラが構造化された編集提案を IDE に送り返せるようにするものだ。

チームはその年を通じて拡大し、オンコール体制も徐々に改善していった。

### 2024/2025年

チームが大きくなったことで、CI/CD にとどまらず、AIMS 内のより広範な ML生産性向上の取り組みに着手できるようになった。2024年から2025年にかけては、研究者・エンジニアのグループと共に、MLパイプライン向けの宣言型設定システムの構築に取り組んだ。

これは本番パイプラインで直接作業する機会となり、大きな学びの場となった。

[カルチャーメモ][1]の第三原則は「Uncomfortably Exciting (怖いぐらいワクワクする)」であり、Google 創設者の Larry Page が講演で言った「世界を変えるということは常に居心地の悪いほどワクワクする仕事に取り組むことだと」いう考えを反映している。安全地帯に落ち着くのではなく、Netflix はチームや個人に「戦略的な賭け」への大きな挑戦を促す。

### 2025/2026年

2025年半ば、PTR チームは、Netflix社内の AI・MLプラットフォームを受け持つ AIP (AI Platform) 部に転属した。パーソナライゼーションパイプラインは既に、GPU トレーニングを提供する [training platform](https://www.youtube.com/watch?v=nPHYclgj81c) のような AIP のコンポーネントに依存していた。

AIPでは、ビルド関連および信頼性関連の仕事に戻った。AIMS 向けの新しい AIP スタックの導入、MLインテグレーションテストの自動検出、より高速なビルドファイル生成、組織での SLO導入などだ。

### 次のステップ

まず、これまでの年月で私と一緒に働き、指導してくれた AIMS と AIP の皆さんに感謝したい。

サイドプロジェクトとして、Scala Center や他の有志のコミュニティ人たちと協力しながら、個人の時間を使ってsbt 2に取り組んできた。ちょうど [2.0 をリリースした](https://www.scala-lang.org/blog/2026/06/29/sbt2.html)矢先で、まだやるべきタスクのバックログが残っている。今のところの計画は、スケートボード、オープンソース、[Scala Days 2026](https://scaladays.org/)、そして [BazelCon](https://events.linuxfoundation.org/bazelcon/) など。

その後で、次のビッグプロブレムを解決するための新しいチーム探しを始めるかもしれない。これからも宜しくお願いします。

  [1]: https://jobs.netflix.com/culture
