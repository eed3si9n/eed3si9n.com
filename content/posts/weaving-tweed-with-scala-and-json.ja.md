---
title:       "Scala と Json で tweed を織る"
type:        story
date:        2011-01-03
draft:       false
promote:     true
sticky:      false
url:         /ja/weaving-tweed-with-scala-and-json
aliases:     [ /node/29 ]
---

> 次々とヤバいコードを紡ぎ出し NY Scala シーンの中心的存在であり続ける [@n8han](http://twitter.com/n8han) が二年前に書いた "[Weaving tweed with Scala and Json](http://technically.us/code/x/weaving-tweed-with-scala-and-json/)" を翻訳しました。翻訳の公開は本人より許諾済みです。翻訳の間違い等があれば遠慮なくご指摘ください。

2009年5月27日 n8han 著
2011年1月2日 eed3si9n 訳

**抽出子**は、Programming in Scala の 24章にのみ記述されている Scala の秘密機能で、この春の大ヒットだ。今までは皆 `case Some(thing) => kerpow(thing)` で満足だったのが、今では抽出子を書けなければ #scala freenode にも入れてもらえない。ズルをすれば Scala チャンネルの硬派な常連たちは君のコンピュータをハックして驚くほど馬鹿げたドールハウスを連続再生して（ただし混浴シャワーシーンを除く）、番組の「アクティブ」のように意味のあるタイピングを諦めなければいけない。

> 訳注。以下 Draco より抜粋
> ロッサム・コーポレーションは人間の人格、経験をすべて消し、新しい人格を植え付ける技術を開発した。彼らはこの技術を用いて、戦闘用の人形アクティブを生み出した。
> 人形たちはドールハウスという施設で生活している。誰かの人格を移植され、任務に挑む。
アクティブの一人、エコーは記憶のリライト中にエラーが起こり、完全には記憶が消されていなかった。

## この抽出子はちょっとチクっとしますからね

命からがら逃げ出した僕は抽出子をありとあらゆる状況に適用するよう努めた。例えば、JavaScript インタプリタが理解できるお洒落な文字列、Json オブジェクトだ。抽出子を使えば `case` 構文でこのように処理することができる:

    import dispatch.json.Js
    val echo = Js("""{"acting": "無表情で前を見ている"}""")
    object Echo extends Js { val acting = 'acting ? str }
    echo match {
      case Echo.acting(hmm) => hmm
      case _ => "pshaw"
    }

    res0: String = staring blankly ahead

[`Symbol`](http://www.scala-lang.org/api/current/scala/Symbol.html) `'acting` に対して `?` を呼び出すことで抽出子が作成される。`Symbol` には `?` メソッドはないが暗黙の変換でそれをもつオブジェクトに変換されている。Echo　はいつも演技してるということが分かっているので、この抽出子を使って直接代入することもできる:

    val Echo.acting(a) = echo

    a: String = 無表情で前を見ている

意地悪w。なにはともあれ、これで Scala の機能を使って Json データを抽出することができた。 抽出子はインプット全体を処理するかしないかの二択しかないことが欠点となるかもしれないが、これは抽出子の `unapply` は `apply` を逆にしたものだからだ。実際の所はどうか知らないけど、多分どこかの pdf に書かれているのだろう。同じオブジェクトから異なるものを簡潔に抽出できるコードを書けるわけだから、別にどうでもいい。

だけど、抽出子だけが Json のデータを取得する手段ではない。再利用可能な抽出子を作らずに、名前と型が分かっているフィールドからデータを読み出したいこともある。それにも! ちゃんと! 解決策がある!

    import Js._
    ('acting ! str)(echo)

    res0: String = staring blankly ahead

内部ではこれは Jorge Ortiz によって書かれたカッコいい [`JsonParser`](https://github.com/n8han/Databinder-Dispatch/blob/master/json/src/main/scala/dispatch/Json.scala) を使っている。その上に乗っている抽出インターフェイスは今のところご機嫌だが、具体的な使用例としては ScalaTest specs を参照してほしい。

## 140 文字なら間違いなし
Twitter は、Tim O’Reilly の自尊心を成層圏から地球低軌道に持ち上げるという最終目的を持った羽付き[^1]の繊細なメッセージシステムだ。この度この目的が達成されたので、すぐに Twitter は君が Facebook で避けていたヤツらによって乗っられるだろう。このうつりゆくユーザランドの春の中で、Twitter はクエリーして下さいと言わんばかりな、とてもチャーミングな HTTP インターフェイスを持っている。クエリーしよう。

一緒に試すには、羽を持たない Scala ビルダである [simple-build-tool](http://code.google.com/p/simple-build-tool/) が必要だ。新しいバージョン 0.4 は、最初に使ったときにビルダ自身とコンパイルに使いたい任意のバージョンの Scala をダウンロードしてくれる[カッコいい分散ローダー](http://code.google.com/p/simple-build-tool/wiki/Loader)を持っている。[セットアップの手順](http://code.google.com/p/simple-build-tool/wiki/Setup)にしたがって `sbt` をパスに入れてほしい。

> 訳注: `sbt` で正しく日本語を表示させるには、起動スクリプトに `-Dfile.encoding=UTF-8` を加える必要がある。

次に [Databinder Dispatch](http://dispatch.databinder.net/) をチェックアウトする:

    git clone https://github.com/n8han/Databinder-Dispatch.git
    cd dispatch
    sbt                         # 色々ダウンロードして、sbt コンソールに入る
    update                      # Ivy、依存ライブラリ取ってきて
    project Dispatch HTTP JSON  # Dispatch HTTP JSON プロジェクトに切り替え
	console                     # Scala コンソール始動
    import dispatch._
    import Http._
    Http("http://video.foxjapan.com/tv/dollhouse/introduction" >>> System.out )

    [悲劇]


Dispatch を使った HTTP のコミュニケーションは簡単で面白い! だけど、[それはもう知ってるし](http://technically.us/code/x/pour-some-sugar-on-httpclient/)、Dispatch の中古 Json インターフェイスを使って[CouchDB にも接続した](http://technically.us/code/x/sling-shot/)。ここで新品でゴージャスな API を見てほしい:

    import dispatch.json.Js._
	import dispatch.json.JsHttp._
    val st = :/("search.twitter.com")
    Http(st / "search.json?q=dollhouse%20gratuitous" ># {
      'results ! list } ) map { 'text ! str }

    res2: List[String] = List(More character development and less gratuitous [...]

魔法の `>#` 演算子は、君をどの識別子もタイプするだけ手に入れることができる Json王に変える! （もしくは、`JsValue => T` の関数を受け取る）グローバルな超インフレーションが発生するかドルが崩壊するまでは `$` はこの演算にピッタリだ。[訳注: 原文でこの部分は `$` 演算子となっているが、諸般の事情[^2]により現在は `>#` に変更されている。] 

## 雨ときどき restful API ラッパー

降ってくるのは、クラウドから（ため息）。　[ちょっと積もってるんだけど](https://github.com/n8han/Databinder-Dispatch)。さぁ寄った、寄った! NYTimes、CouchDB, Twitter API もあるよ! すぐ飽きて別のことやり始めたので、API の呼び出しの一部しかマップしてないよ! （こういうのが好きで拡張したい方は、fork して [format-patch](mailto:nathan@technically.us) してね。）以下に、Dispatch の Twitter インターフェイスを使った非知的生命体の探査を示す:

    import dispatch.twitter._
    Http(Search("#dollhouse gratuitous").results) map Status.text
    
    res4: List[String] = List(More character development and less gratuitous [...]

ヤバい。もうちょっとマジメな事に使ってみよう:

    val User.followers_count(fc) = Http(User("timoreilly").show)
    
    fc: BigDecimal = この人は愛されすぎているためヒープスペース不足エラー!!!

スゴすぎ。

## case class の計算機以外の用法

Scala に対する批判の一つとして（実際にはこれは神聖なる言語に対する批判ではなく、その言語を使う我ら下々のプログラマへの批判であるわけだが）慣例が定まっていないため皆が好き勝手に色々な方法で使っているというのがある。ちょうど僕らの親の世代が 60年代から 70年代にかけて色々なドラッグを試していたように。これは、これでいい事なんじゃないかと思う、クリエイティブで。関数型言語の原理に大きく影響を受けた Scala を書く人もいれば、動的言語で人気になったウンザリするような DSL で腹を肥やしている人もいる（*ゴホゴホ*）。しかし、汎用的なプログラミングインターフェイスを Scala で書くならば、最大限に理解されやすく、時を経ても古くならず、もっとも重要なのだがセクシーな方法で書くことを目指すべきだ。言語に組み込まれている機構を最大限に利用することが、これを実現する最も確実な方法だとここに主張したい。もし安っぽく見え始めたら Odersky のせいにすればいいからだ。

そのため、Dispatch の Json 抽出は、暗黙に*関数*オブジェクトに変換することができる抽出子オブジェクトによって行われる。これらの演算を実装するコードが臭くても（そういうこともある!）、だいたいの構造に則ったアプリケーション側のコードを壊さずに通常は修正できる。

実際に、CouchDB-to-web アプリケーションである **Sling** サーバで HTML をツギハギした方法は、[紹介の記事](http://technically.us/code/x/sling-shot/)を書いた時点では、率直に言うと恥ずかしいものだった。（コードが一切引用されてないのはそのためだ。）Scala コード内に直接 XML を置けるのは素晴らしいが、それだけではタグがからまるのを防ぐことが出来ない。それには [テンプレート case class](http://technically.us/git?p=sling.git;a=blob;f=src/main/scala/sling/Press.scala;h=6bc191af2f58e8de2c56f1e6e1831a22099d0fdc;hb=HEAD#l10) が必要だ。

    trait Press { val html: Elem }

    case class Page(content: Content) extends Press {
      val html =
        <html xmlns="http://www.w3.org/1999/xhtml">
          <head>
            <link rel="stylesheet" href="/css/blueprint/screen.css" type="text/css" media="screen, projection" />
            <link rel="stylesheet" href="/css/blueprint/print.css" type="text/css" media="print" /> 
            <link rel="stylesheet" href="style.css" type="text/css" media="screen, projection" /> 
            { content.head }
          </head>
          <body>
            { content.body }
          </body>
        </html>
    }
    trait Content { def head: NodeSeq; def body: Elem }

次に好きな `Content` の実装を定義する。case class を使うことで、テンプレートの様々なレベルが処理する情報を簡単に渡すことができる。以下に、[その具体例](http://technically.us/git?p=sling.git;a=blob;f=src/main/scala/sling/App.scala;h=bd97c9782bcce328edacc3225f2dc5a13b017e02;hb=HEAD#l115)として Sling の編集ページの示す

    Page(EditDocument(TOC(couched, id, "?edit"), 
      EntityUtils.toString(entity, UTF8)
    )).html

表示ページはこれ

    Page(ShowDocument(TOC(couched, id, ""), md, tweedy)).html

もし気になるなら、値 `tweedy` の　Twitter の検索語とその結果を含む可能性がある `Option[(String, List[JsValue])]` 型だ。このアプリが web に sling している CouchDB Json　オブジェクトが "tweed" (tweet-feed) という文字列を含む場合のみ値を持つ。検索結果のツイートは本文の後ろに現れる: 雨雫に名前をつけるだけでいい、クラウドに浮かぶ即席フォーラムの出来上がりだ! [表示はこうなっている](http://technically.us/git?p=sling.git;a=blob;f=src/main/scala/sling/Press.scala;h=6bc191af2f58e8de2c56f1e6e1831a22099d0fdc;hb=HEAD#l63):

    <h3>{ tweed } tweed</h3>
    <ul class="tweed"> {
      js map { js =>
        val Search.text(text) = js
        val Search.from_user(from) = js
        val Search.created_at(time) = js
        val Search.id(id) = js
        val from_pg = "http://twitter.com/" + from
        <li>
          <a href={ from_pg }>{ from }</a>:
          { Unparsed(text) }
          <div>
            <em> { time.replace(" +0000", "") } </em>
            <a href={ "http://twitter.com/home?" + Http ? Map(
                "status" -> ("@" + from + " " + tweed + " "),
                "in_reply_to_status_id" -> id, "in_reply_to" -> from
              ) }>Reply</a>
            <a href={ from_pg + "/statuses/" + id }>View Tweet</a>
          </div>
        </li>
      }
    } </ul>
    <p>
      <a href={ "http://search.twitter.com/search?" + Http ? Map("q" -> tweed) }>
        See all Twitter Search results for { tweed }
      </a>
    </p>

ツイートの「ループ」を見つけられるだろうか。`map` だ。テンプレート言語が `NodeSeq` の場合は `map` でループする。実際、概念的には、Wicket の `ListView` とこれは大差ない。当初は戸惑ったが、多くのテンプレートスクリプト言語が漫然と `for` ループを使っていることから発展した両者を歓迎したい。HTML を周回して表示しているのではく、データ構造を投射しているのだ。つまり、予測可能なのだ!

## 話だけなら

いや、この狂気の沙汰は作動中だ。`#spde` タグを含むツイートを表示する [Spde → Talk](http://technically.us/spde/Talk) を見れば分かる。これは、フォーラムやメーリングリストを運営するよりもずっと簡単だ。誰かが spam したければ、それは Twitter の問題だからだ。（ゴメンね、al3x。）

[コメントに関しては既に試したヤツがいて](http://dsandler.org/wp/archives/2009/03/15/twitter-comments-results)、これは完全にクライアント側だけのコードで実現されている。`Sling` の実装はサーバ側で実行されており、ETag 付けされているのでサーバを無駄に走らせる事はしない。有効期間が 10分に設定されているので、その間は Sling サーバを邪魔することなく Apache の `mod_cache_disk` から提供される。もし誰かが再読込（`max-age=0` の要求）を押すと、キャッシュは Sling に GET するので、Twitter に新しい検索結果があるかを問い合わせ、CouchDB を `IfNoneMatch` で呼び出す。何も変更されていなければ、304 Not Modified を返す。これは ETag が、コンテンツの鮮度を測るのに必要な情報の全てを含んだ構成になっていることにより実現されている。

    curl -I http://technically.us/spde/Talk
    ...
    ETag: "2165687990|#spde|1340833486" 

真ん中の要素がメモリとして振る舞う。ドールハウスにもこういうのを導入してみてはどうだろう。

## 徒歩ツアー

1. [#spde について話す。](http://technically.us/spde/Talk)
2. [simple-build-tool](http://code.google.com/p/simple-build-tool/wiki/Setup) をセットアップする — 電池は箱の中!
3. [Databinder Dispatch を git する。](http://dispatch.databinder.net/Download)
4. [コンソールから Dispatch を使って](http://dispatch.databinder.net/Stdout_Walkthrough) クラウドで遊ぶ。
5. 迷子になったら [specs](https://github.com/n8han/Databinder-Dispatch/blob/master/http/src/test/scala/HttpSpec.scala) を見る。

[^1]: 訳注: fluttering は「落ち着かない」が unflappable は「動じない」という意味だが、fluttering の本来の意味は「羽をパタパタさせる」つまり「さえずる鳥」という意味の Twitter は羽をパタパタさせ simple-build-tool は羽を持たないことに掛けている。flap とは「羽ばたく」という意味。
[^2]: 残念なことに、識別子の `$` は有効であるにも関わらず Scala では禁止されているため、スイスからの攻撃を避けるため `>#` に変えなければいけなかった。

