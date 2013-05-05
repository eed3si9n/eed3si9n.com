もう一ヶ月経つけど 2013年3月1日に日本に一時帰国して「Scala Conference in Japan 2013」に出席した。そういう名前のカンファレンス。

### ポッドキャストから

ある日 (2012年6月2日だけど) Scala Days 2012 で録音された Scala Types を聞いていると誰かが (@timperrett さん) "I would love to see Scala Days in Asia. We had two in Europe now. It would be wicked to have it in China or Japan, or somewhere like that." と言っていたので、[その趣旨を Twitter で伝えた](https://twitter.com/eed3si9n_ja/status/208622426806960128):

> 今 Scala Days 2012 で録音された Scala Types を聴いてたら、開催地が欧米圏に偏ってるから次あたり日本とかアジア圏なんてどうだろうって話が出てた。コミュニティが声出せば誘致もありえるかも

会話が始まると [@jsuereth](https://twitter.com/jsuereth/status/208708052134789123) がすぐに支持の声を上げてくれた:

> @kmizu @eed3si9n_ja If you guys manage to get a Scala conference somewhere in asia, I'll be there!

> @kmizu @eed3si9n_ja 君らがアジアのどっかに Scala カンファレンス呼び込めたら、オレは行くからな!

そして多くの人のサポートと共に @kmizu さんが、国内初の大規模な Scala カンファレンスとして「Scala Conference in Japan」を立ち上げた。

### 背景

日本の Scala コミュニティと英語ベースの本流のコミュニティの両方をしばらく追ってる身として、僕はある種の不安を感じてきた。2つのコミュニティの間のギャップが徐々に広がってきてて、いわゆるガラパゴス化に似た状況になるんじゃないかという不安だ。

この隔たりは言語バリアによるものだろうというのが僕の最初の仮定だった。だから著名なブログ記事とか正式文書とかが出てくるたびに翻訳した。Scalaz について書いたときも2言語で同時に書いた。しかし、時が経つにつれ、他にも何か理由があるんじゃないかという疑惑が徐々に頭をもたげてきた。

Scala は最初から拡張性の高い言語として設計されていて、ツールやアイディアを提供することでコミュニティの中に Scala エコシステムを一緒に改善してるという自負がある。あたかも共同で所有しているような感覚だ。海の向こうからは、その匂いがしない。なにか文化的な理由もあるのだろうか。

日本が遅れているというわけでは決して無い。東京にある Scala のグループは[100回目の勉強会](http://partake.in/events/615caa8e-dac4-405a-98a9-c8cc067b1ed9)を開いた。Scala に関する本も[9冊](http://www.scala-lang.org/node/959)出版されている。高校生が毎日 Scalaz の型クラスを解説した [advent calendar](http://partake.in/events/4b3afdc8-e4ec-4010-b8ec-31b89210dda0) もあった。日本には頭のいい奴がたくさんいる。だからこそ、日本の外にほとんどその活動が見えてこないのが不安になってくる。

### 巨人の肩

国際的な Scala のカンファレンスにするためには、多くの講演が英語で行われることは分かっていた。勝手に自分で決めた翻訳担当として、他の日本の言語コミュニティがどうやってカンファレンスをやってるのかを調べてみた。

- [YAPC::Asia Tokyo](http://yapcasia.org/2012/talk/)
- [RubyKaigi](http://rubykaigi.org/2011/en/schedule/grid)

そして日が近づいてくると Typesafe社の人たちが 4人も招待されることが分かった。「オレは行くからな!」と言った Josh も来るらしい。

### 翻訳チーム

アメリカに住んでいて、スタッフミーティングに一回も顔を出さなかった僕は、当然の事ながらアウトサイダーだった。しかし、一度日本に飛ぶことを決めてしまうと、運良く翻訳チームのリーダーの一人にさせてもらうことができた。もう一人のリーダーは最強に日本語が流暢で、ユーモアもあふれる Chris Birchall さん (@cbirchall) で、彼は既にカンファレンスのウェブサイトの翻訳などをやっていた。

Perl と Ruby の両方から拝借して、スライドの字幕とライブ翻訳の両方をやってみることを提案した。事前にスライドが見れれば用語を予習しておくこともできる。以下が字幕を加えたスライドのいくつかだ:

- [Jonas Bonér: Scaling software with akka](http://www.slideshare.net/scalaconfjp/scaling-software-with-akka)
- [Joshua Suereth: Coding in Style](http://www.slideshare.net/scalaconfjp/coding-in-style)
- [Jamie Allen: Effective Actors](http://www.slideshare.net/shinolajla/effective-actors-japanesesub)

クリスさんと僕以外にも岡本さん (@okapies) と鹿島さん (@k4200jp) も翻訳とレビューのプロセスに参加した。日本語のスライドもいくつか翻訳したけど、多くは発表者が自分で英語のスライドを用意した。字幕が技術的に正しいのは当然として、表現が堅くなりすぎないように気をつけた。

### closed-captioning

文字ベースのライブ翻訳というと多くの人は Twitter を使えばいいと思うだろう。それはそれで多分それほど悪いアイディアではないと思うけど、Ruby の人たちは大きいフォントで Word に書き込んだり、聴衆からのツイートと IRC からのメッセージを集約する専用のアプリを開発したのに気付いた。

何故 Ruby の人たちはわざわざ IRC を使うソフトを書いたんだろうか? 僕の仮説は機敏さ、API リミットの回避、そしてメッセージの優先順位のためだと思う。ハッシュタグ検索に基づいたツイートは遅いし、多分信頼性が高く無い。仮にそれがうまくいっても、3時間中に 127回しかツイートできない。翻訳したスライドには 70ページ以上あったものもある。3時間あれば、85秒に一回つぶやけば 127を超える可能性がある。

Ruby の kaigi_subscreen を使う代わりに、週末をかけて [closed-captioning](https://github.com/eed3si9n/closed-captioning) というクローンを作ることにした。これは、バックエンドに Akka を使った Unfiltered の websocket サーバで、内部で Twitter クライアントと IRC ロボットをアクターとして走らせている。

![closed-captioning](https://raw.github.com/eed3si9n/closed-captioning/master/screenshot.png)

このシステムはうまくいって、クリスさんと僕のライブ翻訳は即座に表示して、たまに聴衆からのツイートを mix in することができた。最初は聴きとって、翻訳して、タイプするというスピードに慣れなくて色々訳し抜けた所もあった。段々と慣れてきた所でシメの James Roper さんの [All work no Play doesn't scale](http://prezi.com/vtmxbxmpiroy/all-work-no-play-doesnt-scale/) となった。このスライドは 2枚だけで、残りの40分間は口頭で解説を入れながら IntelliJ IDEA を駆使してライブコーディングをするという伝説的な講演となった。

### LT

トークに登壇するつもりは無かったけど、せっかく日本に行くんだからということで、ランチタイム中の LT に申し込んでみた。コミュニティー分断化の問題についてポジティブに語ってみたかった。

- [脱お客様: pull req の送り方](http://eed3si9n.com/scalaconfjp2013/)

形式論に入る前に、コミュティーを中心とした開発のソフトな部分の説明にも時間をさいて、それは「愛<span style="color:#FF1385">♥</span>を示す」という表現をした。Twitter で掛け声をかけたり、信頼関係を築いたり、といったことだ。

### people

招待されたゲストと同じホテルに泊まったので、Typesafe の人たちと一緒に時間を過ごすことができた。朝にカプチーノを飲みながら色んなことを話したり。あと、Jamie さんが子供の頃東京に住んでいたみたいで、僕たちがいた近所も覚えていたみたいだ。

あの場所にいて、Java時代から名前は知っている人とか普段からツイートしてる人と顔を合わせることができたことが僕にとっての最も貴重な体験だった。女性の参加者がほとんどいなかったのは悲しかった。カンファレンスを一回開いたことによって全ての問題が解決するはずはないんだけど、Scala Conference in Japan 2013 は多くの人を集めて、高揚させ、アイディアを共有できたことで大きなステップを踏み出したと言える。カンファレンスの出席者が僕らの TL に出てくるのもそう遠くない先だと希望を持っている。
