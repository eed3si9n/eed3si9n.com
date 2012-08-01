  [SLICK]: https://github.com/slick/slick

> マクロの作者として今注目を浴びている Eugene Burmako さんと、マクロを使って言語統合されたデータベース接続行うライブラリ SLICK の作者である Jan Christopher Vogt さんが今年の Scala Days で行った発表のスライドを翻訳しました。翻訳の公開は本人より許諾済みです。翻訳の間違い等があれば遠慮なくご指摘ください。

2012年4月18日 Eugene Burmako、Jan Christopher Vogt 著
2012年7月30日 e.e d3si9n 訳

## Scala マクロ

(頭をおかしくせずに) コンパイラを拡張する権限を開発者に与える!

これはコンパイル時に以下を行う:
- 検査
- 処理
- AST 変換
- コード生成
- ランタイムへの AST の配備

> 訳注: Scala マクロは 2.10 より導入されるコンパイル時にコードを置換する機構だ。これにより今までボイラープレートが必要だったものを自動生成できるようになるなど、より高い表現力を手にすることができる。

## 実装

コンパイル時のメタプログラミングは長い間 Lisp にあったわけだから、簡単に実装できるはずだよね?

## 難点

構文 (syntax) と型 (type) を持った言語で同図像性 (homoiconicity) を実現するのは難しい。

健全じゃない (non-hygienic) のは悪だが、健全 (hygienic) であると仕様が必要以上に複雑になる。

準クォート (quasiquotation) が無ければ AST の操作は耐え難いものとなるが、新しいコンセプトがまた増えることになる。

> 訳注: 同図像性 (homoiconicity) とは、データとコードが深く関連しているか同一であることを意味する。例えば Scheme で hello world を書くと `(display "Hello, World!\n")` だが、このコードをデータとして表すと

    '(display "Hello, World!\n")

> となる。リストの前に `'` を付けてデータ扱いすることをクォートする (quote) という。
>
> 健全なマクロ (hygienic macro) とは、変数捕捉を許さないマクロを指す。変数捕捉とはマクロが人工的に導入した変数が既存の変数を隠してしまうことを指す。
>
> 準クォート (quasiquote) とは、データの一部にコードを混ぜ込める仕組み。例えば Scheme で 

    `(list ,(+ 1 2) 4)

> と書くと、<code>(list 3 4)</code> と評価される。これは上記の `'` を使ったクォートに似ているが、コンマ (`,`) から始まる式だけが普通に評価されている。これをアンクォート (unquote) するという。さらに、

    `(list ,@(list 1 2) 4)

> と書くと、<code>(list 1 2 4)</code> と評価される。リストを普通に評価してその結果を継ぎ足していることからスプライシング (splicing) と呼ばれる。

## 美しさ

Martin Odersky 先生は懐疑的だった:

「美しいほどシンプルだと我々が納得できなければ、Scala には入らない。」

Martin を説得したのはこれだ。

## 猫

<img src="/images/scala-macros-cats.jpg"/>

コンパイル時AST変換

## エッセンス

Scala リフレクションはコンパイラの cake の一切れを提供する。インフラは既に整っている。

マクロは単に `(Tree*, Type*) => Tree` の関数にすぎない。

健全さ (hygiene) はマクロ側で実装すればいい。そうすることで、ミニマルでかつ柔軟であることができる。

## ユースケース: SLICK

[SLICK][SLICK] という実例を使って実際のマクロの動きを見ていく。

## SLICK の概要

<img src="/images/scala-macros-slick-overview.png"/>

## SLICK でのマクロ

<img src="/images/scala-macros-macros-in-slick.png"/>

## マクロの本体

<img src="/images/scala-macros-macro-body.png"/>

## マクロ展開の結果

<img src="/images/scala-macros-macro-expansion.png"/>

## コンパイラ内での応用

- コンパイラフェーズ (LiftCode) を無くすことができた。
- 80% のソリューション (マニフェスト) を 99% のソリューション (型タグ) に変えることができた。
- アラカルト形式でのマニフェスト - Implicit.scala にハードコードする代わりに、いくつかのマクロになった (独自の実装を書くことができる!)
- アイディア: SourceLocations、SourceContexts、コンパイラとコンパイラ環境に対する静的な制限。

## 既にある実用例

- [SLICK][SLICK]
- [Macrocosm](https://github.com/retronym/macrocosm)
- Scalatex
- [Expecty](https://github.com/pniederw/expecty)
- [Scalaxy](https://github.com/ochafik/Scalaxy)
- アイディア: [射を用いたプロシージャ型付け](http://www.slideshare.net/akuklev/scala-circuitries)、レンズの生成、[ACP DSL](http://days2012.scala-lang.org/sites/days2012/files/vandelft_subscript.pdf)、オーバーヘッドの無いモック

## 今後の課題

- 生成されたコードのデバッグ
- 型指定のないマクロ (untyped macros)
- 型マクロ (type macros)
- マクロアノテーション
- コンパイラをマクロで置き換える

## 今後の課題

- 生成されたコードのデバッグ
- 型指定のないマクロ (untyped macros)
- 型マクロ (type macros)
- マクロアノテーション
- <s>コンパイラをマクロで置き換える</s>

最後のは冗談だって!

## ありがとう!

質問とその答えはここに:

- http://scalamacros.org/
