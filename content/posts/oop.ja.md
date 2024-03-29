---
title:       "オブジェクト指向プログラミングとは何か?"
type:        story
date:        2013-09-18
changed:     2021-09-13
draft:       false
promote:     true
sticky:      false
url:         /ja/oop
aliases:     [ /node/145 ]
---

  [1]: http://www.purl.org/stefan_ram/pub/doc_kay_oop_en
  [2]: http://mumble.net/~jar/articles/oo.html
  [3]: http://staff.um.edu.mt/jskl1/talk.html#Data
  [5]: http://docs.selflanguage.org/4.4/langref.html
  [6]: http://docs.oracle.com/javase/1.5.0/docs/guide/language/autoboxing.html

oop はどう定義されるべきだろうか?

## 純粋オブジェクト指向プログラミング

純粋オブジェクト指向プログラミングは以下のように定義できる:

> オブジェクトを使ったプログラミング。

オブジェクトとは何か?

> 他のオブジェクトへの参照を保持し、事前にリストアップされたメッセージを受信することができ、他のオブジェクトや自分自身にメッセージを送信することができるアトムで、他には何もしない。メッセージは名前とオブジェクトへの参照のリストから構成される。

これでおしまい。言い回しは僕が考えたものだけど、アイディアはオブジェクト指向という言葉を作った張本人 [Alan Kay][1] (2003) からのものだ。これ以外は、直接 oop に関係無いか、実装上の詳細だ。

<!--more-->

この定義から導き出せるものを考えてみよう。

まずは名前空間だ。C の関数と違ってメッセージ (別名メソッド) はオブジェクトごとに名前空間を持つ。これによって名前の衝突を気にせずに名前を定義できるようになる。

第二は、メッセージの有限性だ。プログラマは、あるオブジェクトがどのようなメッセージを受信する可能性があるかを正確に知ることができる。これによって IDE はプログラマを補助して、利用可能なメッセージを表示することができる。

これは文化的なものかもしれないけど、オブジェクトは現実にある実体や概念のメタファーとして設計される。

最後に、異なる種類のオブジェクトが同一のメッセージに対して異なる反応を取る事ができるため、多態的な振る舞いが可能となる。

### 動的ディスパッチ

メッセージパッシングを TaPL での Pierce 流に言うと、**複数の表現**となる。つまり、**抽象データ型**では単一の振る舞いの実装のみを持つのに対して、同一のメッセージに返信する2つのオブジェクトがあるとき、それらは別々の表現を用いることができるということだ。ある特定のオブジェクトが実行時にメッセージ名を検索する処理は**動的ディスパッチ**と呼ばれる。これは oop が「全ての物に対する極端な遅延束縛 (late-binding)」だと言った Kay の主張と一致する。しかし、複数の表現だけではオブジェクトの閉じた性質をカバーできない。例えば、動的ディスパッチは CLOS の多重ディスパッチや Haskell の型クラスも含むだろうが、これらは開いている。

Jonathan Rees のリストで言うと [Sum-of-product-of-function pattern][2] が関連する。

## 純粋さ

ある特定のプログラミング言語やスタイルの純粋さは上記の定義 (オブジェクトとメッセージパッシング) からどれだけ外れているかによって決めることができる。別の言い方をすると:

- 全てはオブジェクトである (Everything is an object)
- メッセージの送信しかしない (All you can do is send a message)

### 全てはオブジェクトである

以下にプログラミング言語をざっくり調査してみた。(注意: 歴史マニアではないので、詳細は間違っているかもしれない。誰が最初に何をしたかはあんまり本筋と関係ないが。)

- [Simula 67][3] は値型 (Integer, Short Integer, Real, Long Real, Boolean, Character) と参照型 (Object Reference と Text) を区別する。
- Smalltalk-80 では、数やクラスを含む全てがオブジェクトだ。
- C++ (1979) は C の値型の意味論を保持するため、`int` はオブジェクトではない。
- Eiffel (1986) は INTEGER を含む全ての型をクラスに統一する。
- [Self][5] (1987) は全てがオブジェクトであるだけでなく、クラスという概念を取っ払った革新的な言語だ。
- Python (1990) と Ruby (1993) の両方とも全てはオブジェクトだ。
- Java (1995) は 7つのデータ型 (byte, short, int, long, float, double, boolean, char) をプリミティブ型扱いするが、J2SE 5.0 (2004) より[ボックス化][6]をサポートする。
- Scala のデータ型の実行時の意味論は Java と同じだが、値クラスと暗黙の型変換によってユーザ定義のボックス化を可能とする。

### メッセージの送信しかしない 

メッセージパッシングにおいては Smalltalk-80 がパイオニアだと言えるだろう。また、言語が非オブジェクトの値を含んでいる場合、全てをメッセージパッシングだけで実現するのは難しいだろう。

- Simula 67 は保護機構付きでフィールドを外部に公開する。
- オブジェクトを作成するためのいくつかのリテラルと変数宣言と代入の構文を除くほとんどの Smalltalk-80 の構文はメッセージパッシングによって表される。これには `1 + 2`、新しいオブジェクトの作成、`x ifTrue: ...` にような制御機構も含む。
- C++ は Simula 67 と同様。ただし、C++ は演算子オーバーロードを追加し、ユーザ定義型に中置演算子を定義することができる。
- Eiffel において Bertrand Meyer は統一形式アクセスの原則 (Uniform Access Principle) を形式化して、フィールドとメソッドの境界を溶けこませた。
- Self はメッセージパッシングを用いてスロットをアクセスする。このスロットはメソッドも含み、`1 + 2` はメッセージパッシングだ。また、代入もメッセージによって行われる。
- Scala は統一形式アクセスの原則を採用した。Scala はまた、パラメータを取る全てのメソッドを中置記法で書けるようにしたため、`1 + 2` はメッセージパッシングだ。

さらに、アクターモデルを実装する諸言語がある。

## アクターモデル

もし純粋オブジェクト指向プログラミングの説明がアクターモデルに似てると思ったら、それは偶然ではない。Alan Kay の Smalltalk-71 に影響を与えた言語に Carl Hewitt の Planner がある (Kay は Sketchpad、 Simula、 Wirth の Euler、そして LISP も挙げている)。話によると Hewitt は Smalltalk-71 や Smalltalk-72 のメッセージパッシングの実装が複雑であることが好まなかったらしい。1973年に Hewitt は並行計算の数学モデルを提供する 'A Universal Modular Actor Formalism for Artificial Intelligence' を書き、影響として物理学、LISP、Smalltalk を挙げた。

本稿の目的としてはアクターモデルは純粋オブジェクト指向の元からの考えを残す初期の系統だとみなすことができる。

## コンポーネントベースプログラミング

プログラミングの概念でよく oop と混同されがちなものにコンポーネントベースプログラミング (別名モジュラープログラミング) がある。コンポーネントベースプログラミングは以下のように定義できる:

> コンポーネントを使ったプログラミング。

コンポーネントとは何か?

> コンポーネント (別名モジュール) とは関連する演算もしくはデータの集合で、インターフェイスを経由することによってのみ公開される。

コンポーネントベースプログラミングの焦点は工学にある。関心事の分離 (separation of concerns) して複雑さを管理することによってソフトウェアの品質を向上させることを目的とする。実装の詳細をカプセル化することで、それぞれのコンポーネントをその詳細を理解せずに利用したり、システム全体を書き直さずに部品だけを修正したり置き換えたりできるようになる。コンポーネントはよく再利用可能で独立だと言われ、これは大まかに合成可能性だと考えることができる。

モジュール性はプログラムが手続き型、関数型、もしくはオブジェクト指向であることとは直交した概念だ。どの言語やツールセットを使っても、それらが許す範囲でモジュール性のあるプログラムを書くことができる。標準ライブラリをバイナリファイルとしてリンクできるように多くの C のようなコンパイラ言語は分割コンパイルをサポートする。CORMA、COM、OSGi など過去に多くのコンポーネントの標準化の試みがある。

### カプセル化

TaPL は**カプセル化** (内部表現の隠蔽) と**インターフェイスの部分型付け** (interface subtyping; インターフェイスは名前のみを持つ) を oop の特徴として挙げている。

C++ や Java のような言語は oop をコンポーネントベースなシステムの一実装として扱っている気がする。そう考えると、カプセル化や様々な保護機構の存在に説明がつく。

### 静的型付けとコンポーネント

静的に型付けされた言語ではインターフェイスの部分型付けがあるとある特定のコードのグループが何らかの仕様に沿っていることをコンパイル時に検査できるという利点がある。C の構造体だと、他のデータを持つ型を定義することはできる:

    struct AddressT {
      string name;
      string street;
      string city;
    };

インターフェイスに演算 (もしくはメッセージ) の宣言を含むことで静的型の守備範囲を「何を持つか」から「何ができるか」にまで広げることができる。

    trait Queue[A] {
      def enqueue(a: A): Unit
      def dequeue: A
    }

これによって、ある変数 `x` があるとき、その変数に対する期待も能力ベースのものに向上したと言えるだろう。GoF の 'Design Pattern' が「実装ではなく、インターフェイスに対してプログラムせよ」というときそれは oop ではなくコンポーネントベースプログラミングの話をしているといえる。

この概念を広げていって、ライブラリにあてはめると COM や OSGi のようにライブラリが API と実装の2部分に分かれることになる。例えば foo-api-1.0.jar と foo-impl-1.0.2.jar を公開するとして、後ほど 1.0.3 をバグ修正のためにリリースするときこれが 1.0.2 とバイナリ互換であることを保証できるようになる。

## 可変性

オブジェクトの本質的な属性として可変性を含めるかは話が分かれるところだろう。oop が元は物理学に影響を受けたことを考えると、分子や細胞のように可変だと考えるのが自然だろう。しかし、完全に不可変でも役に立つオブジェクトの体系を構築することも可能だ。

代数が良い例だ。例えば `1 * 2` は `1.*(2)` と書き換えることができ、これは `1` というオブジェクトに `*(2)` というメッセージを送信して、`2` というオブジェクトへの参照を返す。ここで、同じメッセージの `*(2)` が異なる方法で解釈されるベクトル代数 `Vector(1, 1) * 2` を定義することもできる。

## クラスベースプログラミング

Simula 67 (1967) はクラスベースのプログラミング言語だ。Alan Kay は Simula からメッセージパッシングという概念を抽出してオブジェクト指向という言葉を作り、Smalltalk-71 と Smalltalk-72 を作った。パフォーマンス上の理由から Smalltalk-76 は継承モデルを採用した。Bjarne Stroustrup もまた Simula から影響を受け、1979年に C にクラスを拡張したものとして C++ を実装した。

Stroustrup が 'The C++ Programming Language' を書いた時点で彼は oop を「全ての形状の一般的な性質」と「ある特定の形状の性質」(例えば円) の違いを表現できる能力と再定義した。

> この区別を表現し利用することを許すような構造物を持つ言語は、オブジェクト指向をサポートしている。他の言語はそうではない。
> (Simula から C++ に借用した) 継承メカニズムが、その解を提供する。

これにはメソッド (仮想関数) を定義できる能力を含む。気をつけて読み返してみると字面では oop と継承を等価とは扱っていないことが分かる。

### TaPL は何と言っているか

TaPL はインターフェイスを共有するオブジェクトが振る舞いの実装を再利用する手段として**継承**を oop の特徴に挙げている。

もう一つが**オープンな再帰** (open recursion) で、クラスベースなプログラミング言語のほとんどが持つ機能だとしている。Stroustrup の `Shape` と `Circle` を具体例として説明しよう。例えば `drawAtZero` というメソッドが `Shape` クラスで以下のように実装されているとする:

    def drawAtZero(): Unit = {
      this.moveTo(0.0, 0.0)
      this.draw()
    }

`this.moveTo(0.0, 0.0)` と `this.draw()` が呼び出される時、`this` という参照は遅延束縛 (late-bound) されている。動的ディスパッチによって `draw` の実装は実行時に検索されるため、特に重大なことでも無いような気がする。

## GUI と oop

oop の発展 (そして緩やかな衰退) は GUI システムのそれと一致していると考えることはできないだろうか。純粋オブジェクト指向の概念がよって初めて具現化された Smalltalk はグラフィカルな Smalltalk 環境と深く結びついている。GUI ライブラリや GUI アプリケーションの階層的な性質が oop に適していたと考えられる。

また、GUI アプリケーションは本質的に並行なものだ。ユーザがマウスを動かしてる間も OS は常にコントロールを描画している。マウスがクリックされて書いたコードが呼び出される。クロージャを使ってイベントを記述できることはあと知恵で分かっているが、`Form` クラスを拡張して独自の GUI ウィンドウを定義できる方法として継承という機構が売り込まれたとしても頷ける。そしてメッセージパッシングを使って `setVisible(false)` などとボタン、テキストフィールド、や他のウィンドウに送信することができる。

## fp と oop

### 透過性

よく言われるのが oop が参照透過では無いということだ。それは可変なもの全般に言えることで、特にアクターのような並行なコンテクストだとそうだろう。これがそんなに悪いことだろうか? 僕には分からない。僕は関数型が好きで、副作用を積み上げるよりも式を構築していく方が好みだ。だけど、メッセージパッシングという基本的な考えが fp と真っ向から対立してるわけでは無いと思う。`Vector(1, 1) * 2` と書くことができるもの oop であり、これは透過だ。

### ヒューマンサイド

僕にとって関数型がもたらすのは計算の抽象化だ。例えば、

    Vector(1, 2, 3) map { _ * 2 }

とか

    (1.successNel[String] |@| "boom".failureNel[Int]) {_ |+| _} 

と書けるのは手続き型で書き下すよりも意図をより良く表現できている。

一方、オブジェクト指向がもたらすのは問題のドメインをコードに落としこむ方法だと思う。これはプログラマと世界の間のインタラクションのことであって、コードとコンピュータ間のことではない。ドメインのレベルで考えると、大切なのはオブジェクト同士がどう関係しているのかということだからだ。
