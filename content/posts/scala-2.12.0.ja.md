---
title:       "Scala 2.12.0 リリースノート"
type:        story
date:        2016-11-04
draft:       false
promote:     true
sticky:      false
url:         /ja/scala-2.12.0
aliases:     [ /node/208 ]
tags:        [ "scala" ]
---

> 昨日リリースされたばかりの [Scala 2.12.0](http://www.scala-lang.org/news/2.12.0) のリリースノートを翻訳しました。
> Lightbend 社 Scala チームのコンパイラ魂を感じ取れる、マニアな内容になっています。

Scala 2.12.0 がリリースされました!

Scala 2.12 コンパイラは Java 8 から使えるようになった新しい VM 機能を利用するために、完全なオーバーホールが行われた。

- トレイトは、デフォルトメソッド付きの[インターフェイスに直にコンパイルされる](#trait-compiles-to-an-interface)。これはバイナリ互換性と Java との相互運用性を向上させる。
- Scala と Java 8 の相互運用 (interop) という点では、関数を受け取るメソッドが両方向からもラムダ構文で呼び出せるようになったので関数型なコードにおいても改善した。Scala 標準ライブラリの `FunctionN` クラス群は、Single Abstract Method (SAM) 型となり、全ての [SAM型](#lambda-syntax-for-sam-types)は、型検査からコード生成におけるまで統一的に取り扱われる (クラスファイルは生成されず、代わりに `invokedynamic` が用いられる)。

<!--more-->

もう一つの新機能としては強力な[新オプティマイザ](#new-optimizer)がある。以前より多くの (実質的に) final なメソッドがインライン化されるようになり、これにはオブジェクトやトレイト内で定義されるメソッドも含む。さらに、クロージャ割り当て、デッドコード、box/unbox のペアなどがより効率的に削除されるようになった。

このリリース以降の 2.12.x リリースは完全にバイナリ互換性を保つ。このリリースは 2.12.0-RC2 と同一である。

Scala 2.12 において使える[オープンソースライブラリのリスト](https://github.com/scala/make-release-notes/blob/2.12.x/projects-2.12.md)はどんどん伸びている!

我々の[ロードマップ](https://github.com/scala/scala/milestones)では、2016年内に以下のリリースを予定している: 2.12.1 はすぐ (11月末) に出る予定で、2.12.0 における既知の (しかし稀な) 問題を修正する。2.11.9 は 12月末で、2.11.x 最後のリリースとなる予定だ。数週間後に、我々 Lightbend の Scala チームが 2.13 のプランを発表する予定だ。

## 既知の問題

このリリースには[既知の問題](https://issues.scala-lang.org/browse/SI-10009?jql=project%20%3D%20SI%20AND%20affectedVersion%20%3D%20%22Scala%202.12.0%22)がいくつかあり、これは 11月末予定の 2.12.1 で修正される。

トレイトをコンパイルするのにデフォルトメソッドを多用したため、Scala アプリケーションのスタートアップ時間の性能デグレードが見られる。走り始めてからの性能デグレは我々が見た限りでは観測されていない。

このデグレは 2.12.0-RC (およびファイナル版) においては、具象メソッドをトレイトから継承するクラス内において転送メソッドを生成することによって回避しようとしたが、[JVM のスタートアップ性能が改善した代わりにバイトコードのサイズが増加](https://github.com/scala/scala/pull/5429)する結果となった。

なんらかの性能デグレードに気付いた場合は、必ず連絡してほしい。2.12.x 期間中これからもバイトコードの調整を続けて JVM からベストな性能を引き出すことを続けていきたい。

将来の 2.12.x リリースにおいて取り組む予定のもの:

- [SI-9824](https://issues.scala-lang.org/browse/SI-9824): 並列コレクションが REPL やオブジェクトの初期化 (initializer) 時にデッドロックを起こしやすい。

## Scala の取得

### Java 8 ランタイム

Java 8 プラットフォームの最近のバージョンを、[OpenJDK](http://openjdk.java.net/install/) もしくは [Oracle](http://www.oracle.com/technetwork/java/javase/downloads/index.html) からインストールする。Java 8 互換のランタイムであればどれでもいい。将来的には、Java 9 に関しても何らかのサポートを行う予定だ。完全な Java 9 サポートは 2.13 ロードマップにて検討される。

### ビルドツール

[sbt 0.13.13](http://www.scala-sbt.org/download.html) を使うことを推奨する。既存のプロジェクトの `scalaVersion` セッティングを上げるか、`sbt new scala/scala-seed.g8` を用いて新しいプロジェクトを始める。[new コマンドを使ったテンプレートのサポート](https://github.com/sbt/sbt/pull/2705)と[より高速なコンパイル](https://github.com/sbt/sbt/pull/2754)、[その他色々](http://www.scala-sbt.org/0.13/docs/sbt-0.13-Tech-Previews.html#sbt+0.13.13)を含む sbt 0.13.13 にアップグレードすることを強く推奨する。

[scala-seed リポジトリ](https://github.com/scala/scala-seed.g8)に行って、この [giter8 テンプレート](https://github.com/foundweekends/giter8) に 2.12 の好きな機能の例を追加して欲しい!

Scala は、ant、[maven](http://docs.scala-lang.org/tutorials/scala-with-maven.html)、[gradle](https://docs.gradle.org/current/userguide/scala_plugin.html) からも動作する。[scala-lang.org](http://scala-lang.org/download/2.12.0.html) からディストリビューションをダウンロードしたり、[Maven Central](http://search.maven.org/#search%7Cga%7C1%7Cg%3A%22org.scala-lang%22%20AND%20v%3A%222.12.0%22) から JAR を取得することも可能だ。

## コントリビューター

バグを報告したり、ドキュメンテーションを改善したり、フォーラムや勉強会で他の人を手伝ってあげたり、pull request を送ったり、レビューするなど様々形で Scala の改善に協力してくれた皆さんにお礼を言いたい! 皆さん素晴らしい。

Scala 2.12.0 は、[約 600本受け取った pull request](https://github.com/scala/scala/pulls?utf8=%E2%9C%93&q=is%3Apr%20label%3A2.12%20)の中から [500 本以上](https://github.com/scala/scala/pulls?utf8=%E2%9C%93&q=is%3Amerged%20label%3A2.12%20)をマージした結果だ。過去二年の [2.12.x に対するコントリビューション](https://github.com/scala/scala/graphs/contributors?from=2014-11-01&to=2016-10-29&type=c)は、Lightbend 社の Scala チーム ([lrytz](https://github.com/lrytz), [retronym](https://github.com/retronym), [adriaanm](https://github.com/adriaanm), [SethTisue](https://github.com/SethTisue), [szeiger](https://github.com/szeiger))、コミュニティー全般、および EPFL でおおよそ 64:32:4 の比に分かれた。

トレイト、ラムダ、lazy val のエンコーディングは EPFL の Dotty チームとの協調体制で開発された。

## バイナリ互換性

Scala 2.10 以来、Scala のマイナーリリース間はバイナリ互換を保っている。我々は[この方針](http://docs.scala-lang.org/overviews/core/binary-compatibility-of-scala-releases.html)を 2.12.x においても継続する。

クロスビルドを容易にするために Scala 2.11 と Scala 2.12 は大体においてソース互換であるが、**バイナリ**互換は保たない。これにより、Scala コンパイラと標準ライブラリを改善することを可能とする。

## Scala 2.12 概要

Scala 2.12 の主たるテーマは Java 8 の新機能を最適な形で利用することだ (そのため、生成されたコードは Java 8 のランタイムを必要とする)。

  - トレイト ([#5003](https://github.com/scala/scala/pull/5003)) と関数は、Java 8 でそれらに対応するものにコンパイルされるようなった。そのため、コンパイラはトレイト実装クラス (`T$class.class`) や匿名関数クラス (`C$$anonfun$1.class`) といったものを生成する必要が無くなった。
  - Single Abstract Method 型と Scala に組み込みの関数値の型を型検査からバックエンドまで統一的に取り扱うようにした ([#4971](https://github.com/scala/scala/pull/4971))。
  - 関数のコンパイル以外の他の言語機能においても `invokedynamic` を使うことでより自然なエンコーディングを行うようになった ([#4896](https://github.com/scala/scala/pull/4896))。
  - GenBCode バックエンド ([#4814](https://github.com/scala/scala/pull/4814), [#4838](https://github.com/scala/scala/pull/4838)) に標準化して、デフォルトでフラットなクラスパス実装を使うようにした ([#5057](https://github.com/scala/scala/pull/5057))。
  - オプティマイザは 2.12 用に完全にオーバーホールされた。

トレイトとラムダの新しいエンコーディングによってJAR のサイズが著しく小さくなった。例えば、scalatest 3.0.0 は 2.11.8 と比較して 9.9MB から 6.7MB になった。

リフレクションなどの実験的な API や以下に挙げる互換性の無い変更点を除き、2.11.x において廃止勧告警告が出ない状態でコンパイルするコードは 2.12.x においてもコンパイルすることが期待される。もし、[以下](#breaking-changes)に挙げられていない非互換性を見つけた場合は、是非[報告](https://issues.scala-lang.org)してほしい。

ソース互換性があるため、多くの sbt ビルドにおけるクロスビルドは 1行を変えるだけで済む。もし必要ならば sbt は、[特定のバージョン用のソースディレクトリ](http://www.scala-sbt.org/0.13/docs/sbt-0.13-Tech-Previews.html#Cross-version+support+for+Scala+sources)もデフォルトで提供する。

### 新言語機能

次のセクションは新機能と Scala 2.12 における互換性のない変更点をより詳しく解説する。より技術的な詳細や途中の議論に興味があれば、このリリースでの[特筆すべき pull request](https://github.com/scala/scala/pulls?utf8=%E2%9C%93&q=%20is%3Amerged%20label%3A2.12%20label%3Arelease-notes%20) の全リストを参考にしてほしい。

#### トレイトはインターフェイスにコンパイルされる

Java 8 からはインターフェイス内に具象メソッドを使えるため、Scala 2.12 はトレイトを単一のインターフェイスのクラスファイルにコンパイルできるようになった。以前は、トレイトはインターフェイスとメソッドの実装を保持するたのクラス (`T$class.class`) によって表現されていた。

注意すべきなのは、コンパイラがかなり裏で魔法を行っていることには変わらないので、トレイトが Java によって実装されるには細心の注意を払う必要がある。短くまとめると、トレイトが子クラスによって以下のことを行う場合は人工コード (synthetic code) を必要とする: フィールドの定義 (`val` や `var`、ただし結果型無しの `final val` つまり定数は ok)、super の呼び出し、本文内の初期化文、クラスの継承、線形化に頼って正しい super を探す実装。

#### SAM型に対するラムダ構文

Scala 2.12 の型検査は、関数リテラルを標準ライブラリの `FunctionN` 型の他に Single Abstract Method (SAM) 型に対する妥当な式としても容認するようになった。これは Scala から Java 8 に対して書かれたライブラリを呼び出す場面で便利になる。REPL でコード例を見ると:

    scala> val runRunnable: Runnable = () => println("Run!")
    runRunnable: Runnable = $$Lambda$1073/754978432@7cf283e1

    scala> runRunnable.run()
    Run!

ここで注意するべきなのは、ラムダ式のみが SAM 型のインスタンスに変換され、任意の `FunctionN` 型の式が変換されるわけではないことだ:

    scala> val f = () => println("Faster!")

    scala> val fasterRunnable: Runnable = f
    <console>:12: error: type mismatch;
     found   : () => Unit
     required: Runnable

言語仕様に [SAM 変換のための完全な要求仕様](http://www.scala-lang.org/files/archive/spec/2.12/06-expressions.html#sam-conversion) が書かれている。

デフォルトメソッドを使用することで Scala に組み込みの `FunctionN` トレイトは SAM インターフェイスにコンパイルされる。これによって Java 側から Java のラムダ構文を用いて Scala の関数を作ることができる:

    public class A {
      scala.Function1<String, String> f = s -> s.trim();
    }

specialize な関数クラスもまた SAM インターフェイスで、`scala.runtime.java8` パッケージに入っている。

型検査を改善して、呼び出されるメソッドがオーバーロードされていてもラムダ式のパラメータ型を省略できようにした ([#5307](https://github.com/scala/scala/pull/5307) 参照)。以下のコード例ではコンパイラはラムダを型検査してパラメータ型 `Int` を推論する:

    scala> trait MyFun { def apply(x: Int): String }

    scala> object T {
         |   def m(f: Int => String) = 0
         |   def m(f: MyFun) = 1
         | }

    scala> T.m(x => x.toString)
    res0: Int = 0

ここで注意するべきなのは、両方のメソッドも適用可能で、オーバーロード解決は `Function1` の引数型の方を選択することだ。この規約の[詳細は以下に解説する](#sam-conversion-in-overloading-resolution)。

#### ラムダに対する Java 8 スタイルのバイトコード

Scala 2.12 は、関数から Java 8 と同様のスタイルのバイトコードを出力し、それは標準ライブラリからの `FunctionN` クラスを対象としようがユーザ定義の Single Abstract Method (SAM) 型であろうと同様だ。

それぞれのラムダに対してコンパイラはラムダ本文を含むメソッドを生成して、JDK の `LambdaMetaFactory` を用いてこのクロージャ用のライトウェイトなクラスを作る `invokedynamic` を出力する。ただし、以下の状況では匿名関数クラスがコンパイル時に生成されることに注意してほしい:

  - SAM型がシンプルなインターフェイスではなく、例えば抽象クラスやフィールドを持つトレイトである場合 ([#4971](https://github.com/scala/scala/pull/4971)参照)。
  - 抽象メソッドが specialized である場合。ただし、`LambdaMetaFactory` を使って specialized なバリアントをインスタンス化することが可能な `scala.FunctionN` を除く。([#4971](https://github.com/scala/scala/pull/4971)参照)
  - 関数リテラルがコンストラクタや super の呼び出し内で定義されている場合。 ([#3616](https://github.com/scala/scala/pull/3616))

Scala 2.11 と比較して、この方式はほとんどの場合においてコンパイラはクロージャごとに匿名クラスを生成しなくてもいいという利点がある。

この `invokedynamic` のためのバックエンドサポートはマクロ作者にも公開されていて、[このテストケース](https://github.com/scala/scala/blob/v2.12.0/test/files/run/indy-via-macro-with-dynamic-args/macro_1.scala)で例示されている。

#### 型コンストラクタの推論に対する部分的ユニフィケーション

`-Ypartial-unification` フラグを用いてコンパイルすることで型コンストラクタの推論に部分的ユニフィケーションが追加され、悪名高い [SI-2712](https://issues.scala-lang.org/browse/SI-2712) 問題が解決される。この[実装](https://github.com/scala/scala/pull/5102)をコントリビュートし ([2.11.9 にもバックポートしてくれた](https://github.com/scala/scala/pull/5343)) [Miles Sabin さん](https://github.com/milessabin)に感謝したい!

また、[この機能の素晴らしい解説](https://gist.github.com/djspiewak/7a81a395c461fd3a09a6941d4cd040f2)を書いてくれた Daniel Spiewak さんも言及するべきだ。

現在のところは、`-Xexperimental` ではなく `-Ypartial-unification` を使うことを推奨する。`-Xexperimental` は、将来の Scala リリースに含まれないいくつかの予期しない機能を有効化するためだ。

#### ローカルな lazy val の新しい表現とロック範囲

ローカルな lazy val やオブジェクト (メソッド内で定義されるもののこと) はより効率的な表現となる ([#5294](https://github.com/scala/scala/pull/5294) と [#5374](https://github.com/scala/scala/pull/5374) で実装された)。

Scala 2.11 では、ローカルな lazy val は 2つのヒープに割り当てられたオブジェクトとしてエンコードされていて (値のために 1つと、初期化されたかのフラグでもう1つ)、初期化はそれを取り囲むクラスのインスタンスを用いて同期化されていた。2.12 より導入された[ラムダの表現](#java-8-style-bytecode-for-lambdas)はラムダ本文を取り囲むクラスのメソッドとして出力するため、このエンコーディングではラムダ本文内で定義される lazy val やオブジェクトがデッドロックを起こす可能性がある。

これは、値と初期化フラグの両方を保持する単一の値をヒープに割り当て、それを初期化ロックとして使用することで修正された。Dotty では既に同様の実装がなされていた。

#### Scala.js のための型推論の改善

[ラムダパラメータに関する型推論の改善](#lambda-syntax-for-sam-types)は `js.Function` にも恩恵をもたらす。例えば、`(now: Double)` を明示的に指定せずに以下のように書けるようになる:

    dom.window.requestAnimationFrame { now => // inferred as Double
      ...
    }

また、[オーバーライドされた `val` に対する推論の改善](#inferred-types-for-fields)は、匿名オブジェクトを含む JS トレイトを Scala.js によって定義する場合に実装しやすくなる。具体例で説明する:

    @ScalaJSDefined
    trait SomeOptions extends js.Object {
      val width: Double | String // 例えば "300px"
    }
    val options = new SomeOptions {
      val width = 200 // 型推論された Double | String に対して Int から暗黙の変換が行われた
    }

### ツール周りの改善

#### 新しいバックエンド

Scala 2.12 は GenBCode バックエンドに標準化され、これは直接 Scala のコンパイラ構文木からバイトコードを出力するためより高速にコードの出力が行われる。これに対して、以前のバックエンドは ICode と呼ばれる中間表現を用いていた。旧型のバックエンドである GenASM と GenIcode は削除された ([#4814](https://github.com/scala/scala/pull/4814), [#4838](https://github.com/scala/scala/pull/4838))。

#### 新しいオプティマイザ

GenBCode バックエンドは新しいインライナーとバイトコードオプティマイザを含む。このオプティマイザは `-opt` コンパイラオプションを用いて設定することが可能だ。デフォルトでは、メソッドから到達不能なコードのみを削除する。`-opt:help` オプションを使って、オプティマイザに指定可能なオプションの一覧を見ることができる。

以下の最適化がある:

- final メソッドのインライン化。これは、オブジェクト内で定義されたメソッドや、トレイト内で定義された final メソッドを含む。
- クロージャが割り当てられて、同じメソッド内で呼び出された場合、そのクロージャ呼び出しは対応するラムダ本文メソッドへの呼び出し置換される。
- デッドコードの削除と、いくつかのクリーナップ最適化。
- box/unbox 削除 [#4858](https://github.com/scala/scala/pull/4858): メソッド内で定義され、そのまま抜け出さずにメソッド内のみ使用されるプリミティブ型のボックス化やタプルは削除される。

具体例で説明すると、以下のコード

    def f(a: Int, b: Boolean) = (a, b) match {
      case (0, true) => -1
      case _ if a < 0 => -a
      case _ => a
    }

は `-opt:l:method` フラグを付けてコンパイルすると以下のバイトコードを生成する ([cfr](http://www.benf.org/other/cfr/) を用いて逆コンパイルした):

    public int f(int a, boolean b) {
      int n = 0 == a && true == b ? -1 : (a < 0 ? - a : a);
      return n;
    }

オプティマイザはインライン化もサポートする (デフォルトでは無効になっている)。`-opt:l:project` フラグは現在コンパイル中のソースファイルのコードをインライン化し、`-opt:l:classpath` はコンパイラのクラスパスに通っているライブラリのコードのインライン化を有効にする。[`@inline`](http://www.scala-lang.org/files/archive/api/2.12.0/scala/inline.html) でマークされたメソッドの他は、高階メソッドの関数引数がラムダもしくは呼び出し側のパラメータである場合にインライン化される。

ここで注意するべきなのは:

  - sbt の差分コンパイルはインライン化によって導入された依存性を追跡しないためインライン化はプロダクションのビルドにおいてのみ有効化することを推奨する。
  - クラスパスからのコードをインライン化する場合は、コンパイル時と実行時で全ての依存ライブラリが同一のバージョンであることを保証する必要がある。
  - Maven Central に公開するためのライブラリをビルドしている場合は、依存ライブラリからのコードをインライン化するべきではない。あなたのライブラリのユーザは、クラスパスに別のバージョンの間接依存するライブラリを持っている可能性があり、その場合にはバイナリ互換性が崩れるからだ。

Scala のディストリビューションは `-opt:l:classpath` を付けてビルドされており、これは Scala コンパイラの性能を最適化しない場合と比較して約5% 改善する。([JMH-ベースのベンチマーク](https://github.com/scala/compiler-benchmark/blob/master/compilation/src/main/scala/scala/tools/nsc/ScalacBenchmark.scala)によって hot と cold の両方の状態において計測された)

GenBCode バックエンドと新オプティマイザの実装は、Miguel Garcia さんによる先行研究に基いている。

#### Scaladoc ルックアンドフィールのオーバーホール

Scaladoc のアウトプットは、より魅力的で、モダンで、使いやすいものとなった。[Scala Standard Library API](http://www.scala-lang.org/api/2.12.0) をみてほしい。

この取り組みを率先してくれた [Felix Mulder](https://github.com/felixmulder)さん、ありがとう。

#### Scaladoc は Java ソースにも対応

これは [SI-4826](https://issues.scala-lang.org/browse/SI-4826) を修正して、Scala と Java の両方のソースを使用するプロジェクトのドキュメンテーションを簡易化する。[Jakob Odersky](https://github.com/jodersky)さん、コントリビューションありがとう!

この機能はデフォルトで有効化されているが、以下の方法で無効化できる:

    scalacOptions in (Compile, doc) += "-no-java-comments"

巨大な Javadoc コメントを含むプロジェクトは Javadoc スキャナがスタックオーバーフローを起こす場合があるが、これは [2.12.1](https://github.com/scala/scala/pull/5469) にて修正される。

#### Scala シェル ([REPL](https://en.wikipedia.org/wiki/Read%E2%80%93eval%E2%80%93print_loop))

Scala のインタラクティブ・シェルにいくつかのカッコいい機能が追加された。試すには、コマンドライン上から `scala` スクリプトを起動するか、sbt から `console` タスクを使う。もしも色が好きならば (嫌いな人はいない!)、`scala -Dscala.color` を使うことができる。これは、[デフォルトで有効化される](https://github.com/scala/scala-dev/issues/256)予定だ。

2.11.8 以降より、REPL は Scala IDE や ENSIME と同じタブ補完のロジックを用いており、使い勝手が飛躍的に向上した。ヒントやコツに関して[pull request の記述](https://github.com/scala/scala/pull/4725)を参照してほしい。

#### Scala をビルドする sbt

Scala 本体は完全に sbt によってビルドされ、テストされ、publish されるようになった! これによって、コンパイラや標準ライブラリの開発に参加するのがより簡単になった。必要なのは JDK 8 と sbt のみで、ant や環境変数の設定や、シェルスクリプトなどはいらなくなった。普通の sbt プロジェクト同様に Scala を[ビルド、テスト、publish、して使用する](https://github.com/scala/scala/blob/2.12.x/README.md#using-the-sbt-build)ことが可能になった。Scala によって Scala をビルドするという再帰的な構造のため、IntelliJ は sbt のビルドを直接インポートするとはまだできない。`intellij` タスクを使って、プロジェクト・ファイルを生成することができるようにした。

### ライブラリの改善

#### Either は右バイアスになった

`Either` は `map`、`flatMap`、 `contains`、 `toOption` などといった演算をサポートするようなり、これらは右側に作用する。今後にリリースにおいて、`.left` メソッドと `.right` メソッドが廃止され `.swap` に取って代わられる可能性がある。
この変更は現在のコードとソース互換だ (ただし、拡張メソッドとの衝突を除く)。

この変更点によって [cats](http://typelevel.org/cats/) などのライブラリは `Either` に標準化することができた。

[Simon Ochsenreither](https://github.com/soc) さん、コントリビューションありがとう。

#### Future の改善

Scala 2.12 では数々の `scala.concurrent.Future` の改善が行われた。詳細は Viktor Klang さんの[このブログシリーズ](https://github.com/viktorklang/blog)を参照してほしい。

#### scala-java8-compat

[Scala のための Java 8 互換モジュール](https://github.com/scala/scala-java8-compat)も Scala 2.12 に向けてオーバーホールが行われた。Java 8 の SAM と Scala の関数の相互乗り入れは言語に組み込まれたが、このモジュールは Java 8 SAM を取り扱う際に便利なものを追加で提供する。Java 8 ストリームに対するサポートも Scala 2.12 開発中に追加された。このモジュールのリリースは Scala 2.11 と Scala 2.12 の両方に対して行われている。

### 他の変更点と廃止勧告

  - [可変 TreeMap](http://www.scala-lang.org/files/archive/api/2.12.0/scala/collection/mutable/TreeMap.html) の実装が追加された ([#4504](https://github.com/scala/scala/pull/4504))。
  - [ListSet](http://www.scala-lang.org/files/archive/api/2.12.0/scala/collection/immutable/ListSet.html) と [ListMap](http://www.scala-lang.org/files/archive/api/2.12.0/scala/collection/immutable/ListMap.html) は、挿入順の走査を保証し (2.11.x において走査は逆順だった)、また性能も改善した ([#5103](https://github.com/scala/scala/pull/5103))。
  - [`@deprecatedInheritance`](http://www.scala-lang.org/files/archive/api/2.12.0/scala/deprecatedInheritance.html) と [`@deprecatedOverriding`](http://www.scala-lang.org/files/archive/api/2.12.0/scala/deprecatedOverriding.html) が公開され、ライブラリ作者が使えるようになった。
  - `@hideImplicitConversion` という Scaladoc のアノテーションによってどの暗黙の変換が隠されるかをカスタマイズできるようになった ([#4952](https://github.com/scala/scala/pull/4952))。
  - `@shortDescription` という Scaladoc のアノテーションによってエンティティーページにおけるメソッドの概要をカスタマイズできるようになった ([#4991](https://github.com/scala/scala/pull/4991))。
  - Scala と Java のコレクション型の暗黙の変換を行う JavaConversion は廃止勧告となった。[JavaConverters](http://www.scala-lang.org/files/archive/api/2.12.0/scala/collection/JavaConverters$.html) を用いて、明示的に `.asJava` / `.asScala` と変換することを推奨する。
  - ゼロ引数のメソッドのイータ展開 (メソッドから関数値への変換) は、予期しない振る舞いを起こすことから廃止勧告となった ([#5327](https://github.com/scala/scala/pull/5327))。
  - Scala 標準ライブラリは、`sun.misc.Unsafe` を[一切](https://github.com/scala/scala/pull/4443)[参照](https://github.com/scala/scala/pull/4712)しなくなり、また forkjoin ライブラリのフォークも[含まなくなった](https://github.com/scala/scala/pull/4629)。
  - パターンマッチャーの網羅性の解析が改善された ([#4919](https://github.com/scala/scala/pull/4919))。
  - パラメータ名を [JEP-118](http://openjdk.java.net/jeps/118)準拠で出力するようになったため、Java ツールや Java リフレクションから使うことができるようになった。

<a id="breaking-changes"></a>
## 互換性の無い変更点

### オブジェクト初期化ロックとラムダ

Scala 2.11 においてラムダの本文は、コンパイル時に生成される匿名関数クラスの `apply` メソッド内にあった。2.12 の新しいラムダエンコーディングはラムダ本文を取り囲むクラス (enclosing class) のメソッドの一つとして持ち上げる。そのため、ラムダの呼び出しは、取り囲むクラスを間接的に経由するため今まで無かったデッドロックを生む原因となる。

例えば、以下のコード

    import scala.concurrent._
    import scala.concurrent.duration._
    import ExecutionContext.Implicits.global
    object O { Await.result(Future(1), 5.seconds) }

は (簡易的に) 以下のようにコンパイルされる:

    public final class O$ {
      public static O$ MODULE$;
      public static final int $anonfun$new$1() { return 1; }
      public static { new O$(); }
      private O$() {
        MODULE$ = this;
        Await.result(Future.apply(LambdaMetaFactory(Function0, $anonfun$new$1)), DurationInt(5).seconds);
      }
    }

初めてのへの `O` アクセスは、`O$` クラスを初期化して、静的初期化を実行する (それがインスタンスのコンストラクタを呼び出す)。クラスの初期化は初期化ロックによって保護されている ([JVM 仕様書 5.5 章](https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-5.html#jvms-5.5))。

メインのスレッドはクラス初期化をロックして Future を生成する。別のスレッドで実行される Future は静的なラムダ本文メソッド `$anonfun$new$1` を実行しようとするが、それも `O$` の初期化を必要とする。初期化は既にメインのスレッドでロック済みなので、Future を実行中のスレッドはブロックする。一方、メインのスレッドは `Await.result` を実行し続けて、Future が完了するのを待機するため、デッドロックとなる。

この振る舞いは [ScalaCheck 作者の意表を突いた](https://github.com/rickynils/scalacheck/issues/290)が、後に[修正](https://github.com/rickynils/scalacheck/pull/294)された。

### 外側のインスタンスを捕捉するラムダ

ラムダ本文が取り囲むクラスのメソッドとして出力されるため、ラムダが 2.11 では無かったような形で外側のインスタンスを捕捉することが可能となる。これは、シリアライゼーションに影響を及ぼす。

Scala コンパイラはクラスやメソッドを解析して不必要な外側の捕捉を予防する: 不要な外側のパラメータはクラスから消去され ([#4652](https://github.com/scala/scala/pull/4652))、インスタンスメンバーにアクセスしないメソッドは静的なものにされる ([#5099](https://github.com/scala/scala/pull/5099))。既知の制限としては、この解析は単一のクラスに限定されており、小クラスを含まないことだ。

    class C {
      def f = () => {
        class A extends Serializable
        class B extends A
        serialize(new A)
      }
    }

この例では、まずクラス `A` と `B` は `C` に持ち上げ (lift) される。クラスをパッケージレベルに平坦化するとき、`A` は、`A` インスタンスを捕捉するための外側のポインターを取得する。`A` には `B` という子クラスがあるため、クラスレベルでの `A` の解析は外側からのパラメータが未使用なのか結論付けることができない (`B` 内で使われるかもしれないため)。

`A` のインスタンスをシリアライズすると、外側のフィールドもシリアライズしようとするため、`NotSerializableException: C` エラーが発生する。

### SAM 変換は implicit よりも優先される

型システムに組み込まれた [SAM 変換](http://www.scala-lang.org/files/archive/spec/2.12/06-expressions.html#sam-conversion) は、関数型から SAM型への暗黙 (implicit) の変換よりも優先される。これは、現行で SAM 型の暗黙の変換に頼っているコードの意味論を変えるものだ:

    trait MySam { def i(): Int }
    implicit def convert(fun: () => Int): MySam = new MySam { def i() = 1 }
    val sam1: MySam = () => 2 // Uses SAM conversion, not the implicit
    sam1.i()                  // Returns 2

古い振る舞いを保持するためには、`-Xsource:2.11` フラグを使用して、明示的に変換メソッドを呼ぶか、SAM として不適合になるように型を変える必要がある (例えば、2つ目の抽象メソッドを追加する)。

ここで注意するべきなのは、SAM 変換はラムダ式のみに適用され、任意の `FunctionN` 型の式ではないことだ:

    val fun = () => 2     // Type Function0[Int]
    val sam2: MySam = fun // Uses implicit conversion
    sam2.i()              // Returns 1

### オーバーロード解決時の SAM 変換

ソース互換性向上のため、オーバーロード解決は SAM 型をパラメータとして持つメソッドよりも、`Function` 型の引数を持つメソッドを優先するようにした。以下の例は Scala 2.11 と 2.12 において同様に振る舞う:

    scala> object T {
         |   def m(f: () => Unit) = 0
         |   def m(r: Runnable) = 1
         | }

    scala> val f = () => ()

    scala> T.m(f)
    res0: Int = 0

Scala 2.11 では、唯一の適用可能なメソッドである最初のメソッドが選ばれる。Scala 2.12 では両方のメソッドとも適用可能なため、[オーバーロード解決](http://www.scala-lang.org/files/archive/spec/2.12/06-expressions.html#overloading-resolution)がより特定な選択肢を選ぶ必要がある。[*互換性*](http://www.scala-lang.org/files/archive/spec/2.12/03-types.html#compatibility) の仕様が更新され、SAM 変換も考慮しても最初のメソッドが選ばれるようになった。

オーバーロード解決時には、(この例のように) 引数の式が関数リテラルじゃなくても SAM 変換は常に考慮されることに注意してほしい。これは、前項でみた式そのものの SAM 変換とは異なる振る舞いである。[scala-dev#158](https://github.com/scala/scala-dev/issues/158) における議論も参照。

オーバーロード解決の調整によって互換性は向上するが、2.11 ではコンパイルするが、2.12 では曖昧となるコードは存在し得る:

    scala> object T {
         |   def m(f: () => Unit, o: Object) = 0
         |   def m(r: Runnable, s: String) = 1
         | }
    defined object T

    scala> T.m(() => (), "")
    <console>:13: error: ambiguous reference to overloaded definition


### フィールドの型推論

`val` と `lazy val` の型推論は、細かいコーナーケースや矛盾点を修正して `def` のそれにすり合わせるようにした ([#5141](https://github.com/scala/scala/pull/5141) 及び [#5294](https://github.com/scala/scala/pull/5294))。具体的には、オーバーライドするフィールドの型を計算するときは、オーバーライドされる側の型を期待される型として使用する。これによって、Scala 2.12 では `val` や `lazy val` から推論される型が 2.11 より変わる可能性がある。

特に、2.11 において明示的な型宣言が必要なかった `implicit val` が 2.12 において必要になる可能性がある (いづれにせよ、implicit には型注釈を付けるべきだが)。

`-Xsource:2.11` フラグを使用して古い振る舞いを得ることができる。これは、コンパイルできなくなった時にこの変更が原因かを探るのに役立つ。

### 構文木の変更 (マクロ作者やコンパイラプラグイン作者に影響がある)

PR [#4794](https://github.com/scala/scala/pull/4749) は、静的にアクセス可能なシンボルの選択の構文木を変更した。例えば、`Predef` の選択は `q"scala.this.Predef"` という形は必要なくなり、
単に `q"scala.Predef"` で良くなった。古い構文木の形でマッチしていたマクロやコンパイラプラグインは対応する必要がある。

## このリリースノートの改善

リリースノートへの[改善](https://github.com/scala/make-release-notes/blob/2.12.x/hand-written.md)は随時受け付けている。

訳注: [和訳](https://github.com/eed3si9n/eed3si9n.com/blob/master/translation/scala-2.12.0.md)の訂正や指摘も受け付けています。
