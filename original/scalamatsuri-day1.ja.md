日本での Scala カンファレンスも今年で二年目だ。今年は [ScalaMatsuri](http://scalamatsuri.org/) と名前を変えて仕切り直し。300枚のチケットは売り切れ、招待講演者やスポンサー招待枠などを入れたら当日はもっといたかもしれない。アメーバブログやオンライン広告サービスなどを事業とする CyberAgent さんのオフィスを会場としてお借りした。

1日目のトップバッターは小田好先生こと Martin Odersky 先生 ([@ordersky](https://twitter.com/odersky)) の「Scala 進化論」。多くの人が小田好先生の講演を楽しみにしていたので、朝から満員に近かったと思う。僕が出席したセッションは、拙作の [closed-captioning](https://github.com/eed3si9n/closed-captioning) を使って和英、英和のテキスト翻訳を打ち込むのに忙しかった。一日目翻訳チームの他のメンバーは、[@cbirchall](https://twitter.com/cbirchall)、 [@cdepillabout](https://twitter.com/cdepillabout)、 [@okapies](https://twitter.com/okapies)、 [@oe_uia](oe_uia)。

次に僕が「sbt、傾向と対策」を日本語で話した。mkdir helloworld から始めて、sbt の最初のステップから、continuous testing までの流れのデモから始めた。次に、基礎コンセプト、0.13.6 で入る新機能である HTTPS デフォルト、consolidated resolution、eviction warning を紹介して、最後に「サーバとしての sbt」とさらなる性能の改善という将来の展望でシメた。LinkedIn社のプレスチームから、LinkedIn が
sbt の性能改善の仕事をスポンサーしてもらってることを話してもいい許可をもらってきたので、今回機能改善に関して公の場でお礼できたのは良かったと思う。

Activator と sbt に関して質問があった。Activator の 3つの用例ということで以下のように回答した:
- トレーニング・セッションなどにおける USBドライブなどによる Typesafe スタックのオフライン配布
- 新ユーザの out-of-the-box エクスペリエンス (箱を開けてすぐ遊べること) の改善
- ユーザがコードを打ち込みながら使えるチュートリアルをホストするプラットフォーム

sbt サーバに関しては、IntelliJ などの他のツールとの連携、と将来的な remote compilation などの可能性ができること両方について好反応を得た。

Jon Pretty ([@propensive](https://twitter.com/propensive)) さんの 'Fifty Rapture One-Liners in Forty Minutes' という講演。リソースの読み書きを抽象化することに焦点を絞ったライブラリみたいで、オンラインから色々読み込んで、生の状態の読み込み (slurp) や case class への落とし込みをするみたいだ。enrich-my-library、マクロ、dynamics などユーザ・フレンドリーな Json 処理のために言語のトリックを多用している。バックエンドの json ライブラリが選べるようになっているのは好印象。

唐揚げ弁当が美味しかったので、正直スポンサー LTセッションはあんまり覚えてないけど、皆が「面接しに来て下さい」と言っていたのが印象に残った。

元 LinkedIn社 Play チームのリードをやっていた Yevgeniy (Jim) Brikman ([@brikis98](https://twitter.com/brikis98)) さんの 'Node.js vs Play Framework'。2つの web framework を比較するときに使うスコアカード方式を紹介していて、単なる性能の比較だけじゃなくて、メンテナンス性、学習曲線、コード量のスケーラビリティなど様々な比較を行っていた。Node.js が勝つものもあれば、Play が勝つものもあったけど、全体的に両者の立ち位置が分かるバランスのとれた解析だったと思う。
Scala の他の web framework と比較して Play はどうかという質問があったけど、Jim の回答は、LinkedIn 社は全てのフレームワークを評価したが、Play は他を大きく引き離してリードしていて、特に非同期処理が優れているということだった。

TIS の前出 祐吾さん ([@yugolf](https://twitter.com/yugolf)) の「SIerに立ちはだかるScalaの壁に進化型ジェネレータで挑む」というセッション。Play と Slick を使って Rails の scaffold のようなことをやるという話。業務系のビジネスアプリにはこういうツールがそろってくると便利だと思う。

Databricks社の Aaron Davidson さんの 'Building a Unified "Big Data" Pipeline in Apache Spark'。Databricks社のまだリリースされていない、ブラウザ上の REPL からクラスタ情報をグラフとして表示するサービスのデモがあった。内容としては、tweet から Spark Stream を作って、テキストだけを Spark SQL を使って抽出して、k-平均法でクラスタ化して言語を自動検出するという感じだったと思う。ブラウザ上のグラフは皆感心していた。

次のセッションは、コーヒータイムと「Typesafe presents 業務ユーザ懇談会」。業務ユーザ向けに opt-in で Typesafe に関する説明をさせてもらった。

コーヒー休憩の後は、Twitter社の丹羽 善将さん ([@niw](https://twitter.com/niw)) による 'Getting started with Scaling, Storm, and Summingbird'。どういう背景でこういうツールが出てきたという話は面白いものだった。リアルタイムでツイート毎秒を計算することを可能とするんだけど、その一つの例として「バルスの呪い」が出てきた。毎年、日本テレビが宮﨑駿の「天空の城ラピュタ」を放送して、主人公たちが破壊の呪文を唱えると同時に視聴者が一斉に「バルス」とツイートするのは日本ではよく知られた現象だ。これは海外でも報道されていて、去年の Wall Street Journal では以下のように紹介されている:

> 2011年に「ラピュタ」が放映された際、「バルス」は毎秒2万5088回ツイートされ、最高記録を達成。しかし、今年の正月、3万3388回ツイートされた「あけおめ」に記録を塗り替えられた。

神戸大学の宋 剛秀さん ([@TakehideSoh](https://twitter.com/TakehideSoh)) の英語での 'Scarab: SAT-based Constraint Programming System in Scala' という発表。おそらく、唯一の学術的な発表だったけど、個人的にはこれが一番来た。Scarab は、最先端の CSP (制約充足問題) ソルバーと SAT 技法に対して表現力の高い DSL を提供する。僕が Ivy の依存性解決の性能に取り組んできてて、この eviction と exclusion 付きのグラフの解決が制約充足問題として表現できるのではと言われているので、身近に感じる問題だった。例えば、Eclipse のプラグイン依存性の解決には SAT4j が使われていたりする。宋さんを後で捕まえて、自分の問題も SAT でいけるかと話してみた所、氏も研究には実際にある問題があると面白いと話に乗ってもらえた。

ドワンゴモバイル社の藤村 拓也さん ([@tlync](https://twitter.com/tlync)) の「国技と Scala」。ドワンゴ社と日本相撲協会には長年の付き合いがあるらしく、正式モバイルアプリの作成を委託されたらしい。面白かったのは、ドメイン駆動設計 (DDD) を真面目にやっていて、相撲用語である *banzuke* などが英語化されずにモデルレイヤーに出てきていたことだ。

Marverick社の [@todesking](https://twitter.com/todesking)さんによる、「Ruby から Scalaへ」。Ruby の構文と、Scala の構文を比較して列挙していた。要点としては、両言語とも異なる方向から来ているけれども、コードを書く面白さを重視していることと、関数型とオブジェクト指向をブレンドすることで高い表現性を実現しているという共通点があるということみたいだ。 

1日目の最後には、サプライズで照明を落として、全員がハッピーバースデーを歌いながら、前日に誕生日だった小田好先生にケーキを渡すという一幕があった。

<blockquote class="twitter-tweet" lang="ja"><p>In some part of the world it is still <a href="https://twitter.com/odersky">@odersky</a>&#39;s birthday, so he gets a cake! <a href="https://twitter.com/hashtag/ScalaMatsuri?src=hash">#ScalaMatsuri</a> 

<img src="https://pbs.twimg.com/media/Bw2MFy0CIAAcfkK.jpg">

<!-- a href="http://t.co/cLal8xODiG">pic.twitter.com/cLal8xODiG</a -->

</p>&mdash; Jon Pretty (@propensive) <a href="https://twitter.com/propensive/status/508216380785557504">2014, September 6th</a></blockquote>
<script async src="//platform.twitter.com/widgets.js" charset="utf-8"></script>

このツイートが二重で面白いのは、@propensive が *Cake pattern* という用語の発祥であろうと言われていることだ。その後は、皆ビール、おつまみ、寿司、ピザなどを食べながら、楽しい時を過ごした。

2日目は、(準備委員会で僕がプッシュした) 本邦初の　Scala アンカンファレンスが行われ、1日目同様、またはそれ以上にお祭り的な盛り上がりをみせた。ScalaMatsuri のスタッフとしてお手伝いできたことを誇りに思う。また、改めてスポンサー各社に大いに感謝したい。海外から講演者を招待したり、寿司が出てくる豪華な内容となったのはスポンサー各社のお陰だ。仕事で Scala を書いてみたいと思っている人は是非[求人情報](http://scalamatsuri.org/ja/jobs/index.html)をチェックしてほしい。
