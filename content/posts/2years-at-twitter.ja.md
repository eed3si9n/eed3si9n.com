---
title:       "Twitter での 2年"
type:        story
date:        2022-11-20
url:         2years-at-twitter
---

  [pants]: https://www.pantsbuild.org/
  [google2015]: https://blog.bazel.build/2015/09/01/beta-release.html
  [bazel]: https://bazel.build/
  [twitter2020]: https://groups.google.com/g/pants-devel/c/PHVIbVDLhx8/m/LpSKIP5cAwAJ
  [borja]: https://www.youtube.com/watch?v=0l9u-FIaGrQ
  [yi]: https://www.linkedin.com/in/yidcheng/
  [twitter2015]: https://www.youtube.com/watch?v=IWuAWOApn8w
  [ity]: https://www.linkedin.com/in/ikaul/
  [shane]: https://www.linkedin.com/in/shanedelmore/
  [olaf]: https://www.linkedin.com/in/olafurpg/
  [scoot]: https://github.com/twitter/scoot
  [multiversion]: https://github.com/twitter/bazel-multiversion
  [cached-resolution]: https://www.scala-sbt.org/1.x/docs/Cached-Resolution.html
  [bucket]: https://github.com/twitter/bazel-multiversion/pull/4
  [henry]: https://www.linkedin.com/in/henry-fuller-48344496/
  [SC2021]: https://scala.epfl.ch/minutes/2021/02/04/february-4-2021.html
  [angela]: https://www.linkedin.com/in/angela-guardia/
  [martin]: https://www.linkedin.com/in/martinduhem
  [82]: https://github.com/twitter/bazel-multiversion/pull/82
  [bazelcon2021]: https://www.youtube.com/watch?v=fm6YbBLLlYo
  [katya]: https://www.linkedin.com/in/ekaterina-tyurina-134537126/
  [adam]: https://www.linkedin.com/in/adammsinger/
  [scalamatsuri2020]: https://2020.scalamatsuri.org/en/program
  [hackathon]: https://eed3si9n.com/virtualizing-hackathon-at-scalamatsuri2020/
  [diego]: https://www.linkedin.com/in/diegopuppin/
  [ahs]: https://www.linkedin.com/in/schakaki/
  [liana]: https://www.linkedin.com/in/lianabakradze/
  [rules_jvm_export]: https://github.com/twitter/bazel-multiversion/tree/main/rules_jvm_export
  [10]: https://github.com/twitter-incubator/classpath-verifier/pull/10
  [shrinker]: https://github.com/scalacenter/classpath-shrinker/blob/17ca3a968ad8be409063e61176c8cf7dfdd399bf/plugin/src/main/scala/io/github/retronym/classpathshrinker/ClassPathShrinker.scala
  [113]: https://github.com/twitter/bazel-multiversion/pull/113
  [nagesh]: https://www.linkedin.com/in/nagesh-nayudu-ab51bb3/
  [david]: https://www.linkedin.com/in/david-b-rahn/
  [ioana]: https://www.linkedin.com/in/ioanabalas/
  [talha]: https://www.linkedin.com/in/talha-p/
  [scalaschool]: https://twitter.github.io/scala_school/
  [scalding]: https://github.com/twitter/scalding/wiki/Type-safe-api-reference
  [scalaatscala]: https://www.youtube.com/watch?v=Jfd7c1Bfl10
  [effective]: https://twitter.github.io/effectivescala/
  [scio]: https://spotify.github.io/scio/
  [scalacenter]: https://scala.epfl.ch/donate.html

僕は Twitter社の Build/Bazel Migration チームでスタッフ・エンジニアとして勤務していた。信じられないような 2年の後、2022年11月17日をもって実質退職となった。Twitter社は、切磋琢磨、多様性、そして Flock を構成する全ての人に対して溢れ出る優しさというかなり特別な文化を持った職場だった。これを間近で経験して、その一員となる機会を得たことに感謝している。(Flock は「鳥の群れ」の意で、社内での Twitter社の通称)

以下は過去2年の簡単な振り返りだ。尚本稿での情報は、既に公開されているトークやデータに基づいている。

### EE Build チーム

まず、Build チームの任務を解説しなくてはいけないと思う。公開されているデータを引用すると、2020年頃でも弊社には約 2000人のエンジニアが在籍して、モノリポだけでも手書きのコードが約2千万行 (生成コードを含めるとその 10倍) あり、その多くが Scala だが、Python、Java その他の言語の大規模なコードがあった。コードそのものの規模は一旦置いておいても、チームの数も多いので、日々変わっていくコードの変化量も高速なものとなった。コードベースの規模として Twitter社は比類が無いわけでは無い。しかし、この規模となると他のエンジニアが普通にコードを書くことを可能とすることを目的としたエンジニア + マネージャから構成される部署が必要となり、特化した JVM、カスタム化した `git`、ビルド・ツール、CI などを管理する。その部署は、Engineering Effectiveness (「エンジニアリング効率化課」) と呼ばれた。

EE Build チームは、社内で Source と呼ばれていたモノリポを「製品」として持っていた。2020年までは、このチームは [Pants][pants] という独自のビルド・ツールを開発していて、これは Google社の Blaze という内部ビルドシステムの影響受け、Twitter社の開発環境と開発速度に合わせて初期 2010年代からの Scala 言語サポートなどの豊富な機能を追加したビルド・ツールだ。[2015][google2015]年になって Google社は Blaze のオープンソース版である [Bazel][bazel] (読みは「ベーゼル」) を発表し、近年は多くの会社がプラグインや周辺ツールを提供する活発なビルド・ツールに育ってきている。2020年の4月に Build チームは、Pants から Bazel へ移行することを[発表][twitter2020]した。

大規模コードベースに関わったことが無ければビルド・ツールを採用するのにエンジニアから構成されるチームが必要とされる理由は自明では無いかもしれない。誤解を恐れずに簡略化すると、2020年当時の Bazel はビルド・ツールというよりは「ビルド・ツールを作るためのツールキット」に近かった。理由は色々あるが、1つは Google社内ではデプロイ周りなどで別のツールが既にあったという事と、Pants の豊富な機能と共に進化していった 約2千万行のコードがあるという事もある。このような成り行きで、Build チームは、Bazel へ移行することで期待される高速化を失うことなく豊富な機能を再実装し、Twitter を実装するサービス群やデータジョブを実際に移行することを目的とした Bazel Migration チームとなった。

全社を一気に混乱させるリスクのあるいわゆる「ビッグバン・マイグレーション」を避けて、マクロレベルで Pants エミュレーション・レイヤを作って、`BUILD` ファイルが [Pants と Bazel の両方][borja]から読み込むことができるというユニークな方法を採用した。これは、実行時速度を犠牲とすること無い段階的採用を可能とした。

### 2020

僕が Twitter社 Build/Bazel Migration チームに入社したのは 2020年の8月で、ワクチンも出る前の新型コロナウイルス・パンデミックの真最中だった。世界は在宅勤務の現実ようやく順応しかけていたが、僕は 2011年から在宅勤務してきていたので慣れたいた。1週間目は Flight School で、社内のインストラクターや上級エンジニアによって技術スタックや社内のカルチャーなどのレクチャーが一週間行われる社員研修だった。

Build チームは、異動がありつつ常時約12名を籍に持ち、あとは派遣コンサル数名、関連チームからも数名借りるということをやっていた。僕は比較的小さめなチームでしか働いたことがなかったので、最初は多すぎで慣れなかった。だから、最初の数週間は [Yi Cheng][yi]さんがチームにオンボードするのを助けてくれたことを覚えている。Yi はチームの柱的存在で、Pants系の質問なら全ての答えを知っていて、真っ先に人を助けるタイプで、上下左右の両方向の様々なチームとのインターフェイスも行っていた。

当時でも僕は約10年の Scala歴を持っていたので、新入りとしては珍しい感じだった。最初の数週間で、Pants 用の内部リモート・キャッシュサービスである buildcache に Bazel のサポートを改修させた (buildcache の詳細は [2015年の Scala at Twitter][twitter2015] 参照)。言ってしまうと Bazel としては最適化されたソリューションでは無いが、悪くない出先だった。

次に、当時ロンドンにいて Build チームの Tech Lead だった [Ity Kaul][ity]さんと話した。チーム内で最も社での経歴が長く、ランクも最上だった彼女はワークストリームの整理とそれらの進捗の管理に忙しかった。1-on-1 (「ワンオンワン」25分間の個人ミーティング。上司部下に限らず、エンジニア同士、上司のその上司などと2週間に1回、四半期に1回など様々なタイミングで個人ミーティングが行われる。) で、僕ができることで戦略的に最も面白い問題は何かと聞いてみた所、マルチバース問題 (「多元宇宙問題」) について教えてくれた。

なので 9月にはマルチバースを数え続けた。マルチバースとは、例えば `{ A: 1.0, B: 2.0 }` といったライブラリ依存性のバージョン番号の集合のことだ。Pants は、コマンド実行毎に Coursier を呼び出すため、ターゲットごとに異なるライブラリのバージョンを持つことになる。Bazel は、one-version (モノバージョンとも) なビルド・ツールとして知られていたので、問題空間がどれくらいのものなのかに関心があった。
Python を使って分散スコアを適当に作り、分散スコアを最小化する軸を探していく反復アルゴリズムを書いた。地下鉄の路線図みたいな絵が出来あがった。偶発的に数千以上のマルチバースがあったが、メジャーバージョンでクラスター化すると数十ぐらいに収まるみたいだった。

この間、知り合いのエンジニアの人たちは Slack の DM に入ってきて、僕がどうしてるかチェックしてくれたり、作業中の面白いものを共有してくれたり、仕事の要領を教えてくれたりした。その中でも 2名抜き出てる人たちは社内 Scala チームの [Shane Delmore][shane]さんと [Ólafur Geirsson][olaf]さんだ。僕が自分のラップトップを使って遅々と数千のターゲットに対して Pants コマンドを実行してるのを見て、Shane は [scoot][scoot] という Mesos 上で数千のビルドを同時実行できる CI インフラで実行してくれた。

Olaf は、その後 [bazel-multiversion][multiversion] となるもののプロトタイプを書いていた。当時、どのレイヤーで Coursier の依存性解決を実行するべきかという議論が内部であって、外部ライブラリを表す `jar_library` と Pants や sbt のように末端ターゲットである `scala_binary` レベルで走らせるべきという 2派があった。

11月頃には、僕が 3rdparty/jvm (JVM上の外部ライブラリのサポート) のドライバーとなり、社内での 3rdparty/jvm ロードマップを書いた。僕の事を知らない人もいると思うので自己紹介すると、僕は sbt という Scala コミュニティーで主に使われるビルド・ツールのリードをしばらくやっていて、sbt において [cached resolution][cached-resolution]、eviction warning、[`versionScheme`](/sbt-1.4.0) など関連する機能の設計と実装を行ってきた。そのような経験とマルチバースの調査で得られたデータ基づいて、バージョン番号を Semantic Version で[バケット化][bucket]することから始めた。

Python側では、[Henry Fuller][henry]さんが 3rdparty/python のマイグレーションと Bazel 上の Python サポート戦略を担当していた。

個人でのサイドプロジェクトとしては、10月に多くのスタッフの仲間と一緒に [ScalaMatsuri 2020][scalamatsuri2020] のオーガナイズにお手伝いした。僕が担当したセッションの 1つとして[仮想化したハッカソン][hackathon]を行い、参加者が Scala コンパイラや sbt などに pull request を送るお手伝いをした。

11月は、[Weehawken-Lang1](/weehawken-lang1) というミニ・チャリティーイベントを開催して Scala における等価性の話をした。

### 2021

2021年の2月に、[Scala Center 顧問会議][SC2021]の Twitter代表に就任した。

偶然だが、丁度その前日に JFrog社が Bintray のサービス終了をアナウンスした。Scala Center、VirtusLab社、Lightbend社とも共同で、sbt のプラグイン・エコシステムの安全な管理とビルド意味論の持続を目的としてタスクフォースを組んだ。幸い JFrog社が [open source スポンサーシップ](https://jfrog.com/open-source/)を提供してくれたので sbt のプラグイン群やインストーラーは Scala Center にライセンスされたクラウド・ホストな Artifactory のインスタンスに僕が[移すことができた](/ja/sbt-1.5.1)。このような臨時のセキュリティ・パッチを除くと、僕が Twitter社に在籍していた間は基本的に sbt の作業は週末にだけ行ってきた。

3月には [Angela Guardia][angela]さんが Build/Bazel Migration チームに入社して、[Martin Duhem][martin]さんと共に 3rdparty/jvm ワークストリームに参加した。データに基づいた情報を使って 3rdparty/jvm のグラフを調整したいというアイディアが僕たちにはあったので、Angela は bazel-multiversion の [YAML 出力][82] を実装して、毎晩走る Jenkins ジョブで JARファイル衝突検知用のリンターを実行して、ログ集計をするということを実現した。衝突検知をリンターで行うということは Bazelcon で僕が発表した [Resolving Twitter's 3rdparty/jvm with bazel-multiversion][bazelcon2021] でも紹介した。

6月には、rules_scala の `collect_jars` フェーズをカスタム化して末端ターゲットレベルで自動的に衝突を解決する実装を行った。僕のトークではこれは「tertiary resolution」(3次解決) と呼んだ（ちなみに Bazelcon 2022 においてこれをさらに発展させた凄いトークが Airbnb社によって発表された）。

Bazel互換のターゲット数が増えるにつれ、buildcache のスケーラビリティ問題に色々はまり始めていた。確かこの時期に [Ekaterina (Katya) Tyurina][katya]さんが buildcache のスケーラビリティの壁について詳細な分析レポートを書いて、TCPバッファーの割り当てや、hermecity (「ビルド密閉性」)が壊れている可能性を指摘した。

少し方向性を変えて、第3四半期にはデータ処理ジョブのための Bazel サポートの設計と実装を行う「Scalding の夏」という workstream を立ち上げた。これによって、デプロイ・パイプラインやデータ・プラットフォームを持つ異なるチームと話す機会ができた。そこで僕が気づいてしまったのは、社内の他の人たちに対して僕たちが製品として提供しているのは Pants でも Bazel でも無く「ビルド」であって、スムーズにマイグレーションを行うには drop-in リプレース (「差し込むだけで良い互換製品」) が必要ということだった。そのため、僕は `bazel` シェル・スクリプトを使った `bazel bundle` という、Pants互換のデプロイ・イメージを生成する拡張コマンドを実装して、それを使って Scalding の Bazel サポートを実装した。

Flock の中では、チーム間で結構流動的にエンジニアの異動があった。様々なチームを渡り歩いてきたスケボー乗りのスタッフ・エンジニア [Adam Singer][adam]さんが Scala チームに入ってきて、すぐに Bazel Migration チームの重要なワークストリームのリード役を務めるようになった。彼は自宅に大きいデスクトップマシンを持っていて全ての JUnit ターゲットを連続的に走らせてどこで Bazel の互換性が壊れるかを探すということをやっていた。さらに、プロファイラー・ツール周りに慣れていて、色々な問題を検知していた。例えば、action cache がプラットフォーム依存であるために Mac のラップトップ上からリモート・キャッシュをうまく利用できないという問題を指摘したのは彼だったと思う。これは、現在も続いている Bazel の課題の 1つだ。ダベりの時間で一番面白い話をしてくるのも Adam だった。

また、Bazel の全社採用への準備体制として内部ドキュメンテーション・サイト「go/bazel」の立ち上げをリードして、チュートリアルやトラブル対策ガイドなどをそろえ、また社内研修用に Pants と Bazel の違いを解説する「Bazel at Twitter」講座も作成した。

12月の一連の log4j 脆弱性修正に追随して、内部の依存性のパッチを行ったり、臨時に sbt 1.5.x シリーズのパッチを行ったりもした。

また、2021年には「Eugene は 1年前の採用時に明らかに間違ったレベル付けをされた。面接プロセスにおいて業界内における経歴は十分に理解されたり、評価されていなかった、(以下略)」という理由でスタッフ・エンジニアに昇格させてもらった ([David Rahn][david]さん、ありがとうございます!)。この Staff Engineer というのは、シリコンバレー企業での役職名の1つで、シニアエンジニアの 1段上だ。昔は管理職になるしか昇格の方法が無かったが、中年でも技術畑でキャリアを積みたい人向けに各社に段階制が作られた。雰囲気としては、チームの枠組みを超えたシステム設計を行うのが Staff Engineer で、部署に数名居て実験的な事を行ったりする Principal Engineer という人たちがさらにその上のランクとしている。

### 2022

Engineering Effectiveness 課とそれ以外の Products や Revenue といった部署の関係を少し解説しよう。初めて [Yi][yi] とか [Ity][ity] が、社内の他のチームの事を「カスタマー」と言っているのを聞いたときは違和感があったが、後になってそれらのチームはモノリポとしての製品を提供する Build チームを「雇った」ということに納得した。それらのチームは自由に他のビルド・システムを採用することができるからだ（モバイル・アプリは実際そうしていた）。そのうち、僕も他のチームが EE のカスタマーであるという意識に慣れていった。

Build チームは、一週間続くオンコールの当番があった。主な責務は通常の業務時間内に JIRA 経由でカスタマー・サポートを提供することだ。当初は、多くのチケットが Pants の質問で、カスタマーのアシストをするのに他のチームメイトの助けを必要としたが、Pants の知識を得るごとに慣れてきて、質問が Bazel マイグレーション関連になってくると、Build チームとして良いカスタマー・サポートを提供できることが楽しくなってきた。

オンコールの責務には Source モノリポの障害対応も含まれた。アメリカのタイムゾーンに住んでる事情もあって、僕と [Yi][yi] によく回ってきて、CI パイプラインや buildcache の障害があった場合にはメモリ使用や Maven XML ファイルのキャッシュ等をデバッグして、後日には事後検討報告書を書いた。

インフラ・レベルでの課題の 1つとして IDEのサポートが残っていた。2022年の2月には、IntelliJ IDEA インポートにからんだ、間接的依存性が反映されないなどの内部コードの問題をいくつか調査した。

2月には末端ターゲットにおける exclude 機能をまたしても `collect_jars` フェーズを使って実装して、使用方法のドキュメンテーションも書いた。

3月の社内 Hack Week では、Bazel Hack Week を企画して、Bazel を使ってもらったり、残っていた Pants 機能を実装してもらったりした。Hack Week 中に shading 機能や Node.JS サポートがプロトタイプされ、Bazel互換 % も向上した。その辺りから、会話も実際にデプロイしたマイグレーション% に移っていったと思う。

数名のメンバーが抜けたが、Bazel Migration はプロジェクトとしてまだ乗っていたので、経験値が高めのメンバーもチームに参加してきた。

- メディアチームからは、[Diego Puppin][diego]さんが移籍してきて、Node.JS その他のワークストリームを引っ張っていった。
- Meta社から [Adam Hani Schakaki][ahs]さんが入ってきて、ワークフローのマイグレーションに参加したが、[Talha Pathan][talha]さんというインターン生の指導も行って、夏の間に Golang のサポートを実装してしまった。Adam は Python のコードのレビューに詳しいコメントをバシバシ書いてくれて、非常に勉強になった。
- JetBrains社から [Liana Bakradze][liana]さんが入社した。最初はマイグレーションのメトリック追跡の改善を行って、後ほどは二重ビルドを減らすために Bazel のみのビルドを行うことを目的とした Pants 廃止ワークストリームをリードした。

5月には `scala_library` rule のターゲットごとの strcit-deps 機能を実装した。これに限らず Pants はターゲットごとに設定を切り替えられるのに、通常の Bazel だとそれができないという場面が結構あった。僕が実装したもう1つ例だと、Protobuf の生成をするのにターゲットごとに `protoc_version` を切り替えるというものがあった。これは、Hadoop が protobuf-java 2.x 系を必要とするので、Scalding ジョブの移行のための大きなブレークスルーとなった。

また、Scala、Thrift、Java のターゲットのためのパブリッシュ機能を実装した。これは [rules_jvm_export][rules_jvm_export] としてオープンソース化した。rules_jvm_export は、ターゲットの依存性に合わせて正しい POM ファイルを作ることを目指している。

もう 1つ僕が関わっていたのはターゲット・レベルでのデッド・コード分析だ。未使用の JAR ファイルを検知するために JVM の呼び出しグラフを使った [classpath-verifier#10][10] を実装し、また、Scalac プラグインである [ClassPathShrinker][shrinker] の移植も行った。デッド・コード分析の目的は大規模ターゲットのビルド時間の削減を目的としている。

11月となると、大部分のラップトップ使用とデプロイの多くは Bazel へと移行していた。しかし、いくつかの効率化の課題は残っていて、最後の数日でも僕たちは効率改善を行っていた。僕の最後の phab (社内での pull request の名前)は、コードフリーズが解けた後で、Coursier CVE対策を行った [bazel-multiversion][113] へと更新するものだった。

振り返って見ると、自分のキャリアの中でも最も実りの多い 2年間だった気がする。この地盤となったのは「ゆとりの極み」とも言われる Twitter社のカルチャーによって培われたワーク/ライフ・バランスと、Engineering Effectiveness のリーダー陣である [Nagesh Nayudu][nagesh]さんや、Build/Bazel Migration チームのマネージャー [David Rahn][david]さんと [Ioana Balas][ioana]さんが心理的安全を担保してくれたことに尽きる。僕がやりたいことが正に職場が僕にやって欲しいことであるという意味において、僕は Engineering Effectiveness のミッションにビジネス・アラインメントを見つけることができた。僕は、Nagesh や David との 1-on-1 をいつも楽しみにしてて、自分のアイディアを共有したり、彼らの高台からの視点から学んだりした。また、David や他のシニアメンバーを信頼できたから難題でも飛び込んでいくことができた。この OneTeam という熱気を僕は忘れることはないと思う。

### Twitter社における Scala

公開されていないことは書けないが、Twitter社は Scala に関してかなりバランスの良いスタンスを取っていて、Scala 言語の豊富な機能を全て捨てた「ベター Java」でも無ければ、行き過ぎで「Worse Haskell」(もしくは愛情を込めて Type Astronaut 「型の宇宙飛行士」)でも無い。多くのエンジニアがいるという理由もあって、Twitter社のコードベースはその中庸をいっている:

- 不変性 (immutability) を推奨
- Scala のコレクション・ライブラリを使う
- 暗黙の変換は避ける
- `com.twitter.util.Future` を用いて、並行性を型で表す

この哲学は [Scala School][scalaschool]、[Effective Scala][effective]、[Scalding][scalding] ドキュメンテーション、[Scala at Scale at Twitter (2016)][scalaatscala] などからも分かると思う。Twitter社はローカル化されたスケジューラを持ち、キャンセル可能な独自 Future 実装を Scala 2.10 が fork/join を使ったものを 2013年にリリースするずっと前から持っていた事に注意。

Scala のことをあまり知らない人向けに少し説明すると、Scala の標準ライブラリはコレクション・ライブラリを含み、JVM における基本的なデータ構造である配列やリスト、`Map` (ディクショナリ)のエレガントな変換を可能とし、Java のような命令形言語だと数行の定形を要するコードを簡潔に書くことができる。

主要となった他の言語のどれよりも Scala はライブラリ作者に言語そのものを拡張して独自の方言を定義したり (これはドメイン特化言語 DSL と呼ばれる)、既存の Java ライブラリを包み込んでより良いデベロッパー・エクスペリエンスを提供することを可能とする。[Scalding][scalding] はこの最たる例で、Java だと1ページ分埋まるようなお決まりコードを書かなければならないような Hadoop ジョブを Scala だと数行で書けるようになる。この考え方は Spotify社のような他社にも受け継がれて、彼らは Dataflow 上に [Scio][scio] を作成していたりする。

Twitter社は、フェアかつ多様性のある職場を作ることに努力してきて、性別や人種といった軸もそうだが、様々なスキルの背景を持ったひとが集まってきていた。博士号を持ったエキスパートもいれば、プログラマとしてキャリアを始めたばっかりの人たちもいた。別の言い方をすると、数千のエンジニアがいたとしたら、数百以上の女性が Scala のコードを書いていた計算となる。彼女らがどこかへ行ってしまうとすると、それだけ多様性が失われてことが悔やまれる。

### Scala Center への募金

[Scala Center をサポートしよう][scalacenter]。

経済状況が下向きになると企業系のスポンサーは出資を渋るようになるかもしれないが、個人プログラマがカンパして[Scala Center をサポートする][scalacenter]ことができる。現在のアメリカはインフレが 8% あり、新オーナーが気前よく現金化してくれた持ち株の価値もどんどん下がっていくだろう。

僕たちは数千人もいるんだから、全員が RSU か退職金の 3% でも分けることができれば、Scala Center としては相当の額が集まるはずだ。元 Tweep としては、Scala エコシステムと、Scala の仕事相場が継続してくれることに利己的な価値があるわけだし、CVE の修正を行ったりワークショップやカンファレンスの運営を行う Scala Center に対して今後 Twitter社 がサポートを続けるかは不明な感じだ。

### 次のステップ

僕はモノリポを Bazel へと移行させるために Twitter社に入社して、多くの人と協力して、その目的は達成することができ、今僕たちは出ていく所だ。新オーナーは僕たちのしばらくの冬休みの出資してくれると考えることができる。また辣油を作ったり、ブログを書いたりできれば良いかなと思っている。

その後で、次のビッグプロブレムを解決するための新しいチーム探しを始めると思う。これからも宜しくお願いします。

