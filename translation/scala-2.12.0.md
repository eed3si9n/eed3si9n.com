Scala 2.12.0 がリリースされました!

Scala 2.12 コンパイラは Java 8 から使えるようになった新しい VM 機能を利用するために、完全なオーバーホールが行われた。

- トレイトは、デフォルトメソッド付きの[インターフェイスに直にコンパイルされる](#trait-compiles-to-an-interface)。これはバイナリ互換性と Java との相互運用性を向上させる。
- Scala と Java 8 の相互運用 (interop) という点では、関数を受け取るメソッドが両方向からもラムダ構文で呼び出せるようになったので関数型なコードにおいても改善した。Scala 標準ライブラリの `FunctionN` クラス群は、Single Abstract Method (SAM) 型となり、全ての [SAM型](#lambda-syntax-for-sam-types)は、型検査からコード生成におけるまで統一的に取り扱われる (クラスファイルは生成されず、代わりに `invokedynamic` が用いられる)。

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

Scala は、ant、maven](http://docs.scala-lang.org/tutorials/scala-with-maven.html)、[gradle](https://docs.gradle.org/current/userguide/scala_plugin.html) からも動作する。[scala-lang.org](http://scala-lang.org/download/2.12.0.html) からディストリビューションをダウンロードしたり、[Maven Central](http://search.maven.org/#search%7Cga%7C1%7Cg%3A%22org.scala-lang%22%20AND%20v%3A%222.12.0%22) から JAR を取得することも可能だ。

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

#### 型コンストラクタの推論のための部分的統一

`-Ypartial-unification` フラグを用いてコンパイルすることで型コンストラクタの推論に部分的統一が追加され、悪名高い [SI-2712](https://issues.scala-lang.org/browse/SI-2712) 問題が解決される。この[実装](https://github.com/scala/scala/pull/5102)をコントリビュートし ([2.11.9 にもバックポートしてくれた](https://github.com/scala/scala/pull/5343)) [Miles Sabin さん](https://github.com/milessabin)に感謝したい!

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

### Tooling improvements

#### New back end

Scala 2.12 standardizes on the "GenBCode" back end, which emits code more quickly because it directly generates bytecode from Scala compiler trees, while the previous back end used an intermediate representation called "ICode". The old back ends (GenASM and GenIcode) have been removed ([#4814](https://github.com/scala/scala/pull/4814), [#4838](https://github.com/scala/scala/pull/4838)).


#### New optimizer

The GenBCode back end includes a new inliner and bytecode optimizer. The optimizer is configured using the `-opt` compiler option. By default it only removes unreachable code within a method. Check `-opt:help` to see the list of available options for the optimizer.

The following optimizations are available:

* Inlining final methods, including methods defined in objects and final methods defined in traits
* If a closure is allocated and invoked within the same method, the closure invocation is replaced by an invocations of the corresponding lambda body method
* Dead code elimination and a small number of cleanup optimizations
* Box/unbox elimination [#4858](https://github.com/scala/scala/pull/4858): primitive boxes and tuples that are created and used within some method without escaping are eliminated.

For example, the following code

    def f(a: Int, b: Boolean) = (a, b) match {
      case (0, true) => -1
      case _ if a < 0 => -a
      case _ => a
    }

produces, when compiled with `-opt:l:method`, the following bytecode (decompiled using [cfr](http://www.benf.org/other/cfr/)):

    public int f(int a, boolean b) {
      int n = 0 == a && true == b ? -1 : (a < 0 ? - a : a);
      return n;
    }

The optimizer supports inlining (disabled by default). With `-opt:l:project` code from source files currently being compiled is inlined, while `-opt:l:classpath` enables inlining code from libraries on the compiler's classpath. Other than methods marked [`@inline`](http://www.scala-lang.org/files/archive/api/2.12.0/scala/inline.html), higher-order methods are inlined if the function argument is a lambda, or a parameter of the caller.

Note that:

  - We recommend to enable inlining only for production builds, as sbt's incremental compilation does not track dependencies introduced by inlining.
  - When inlining code from the classpath, you need to ensure that all dependencies have exactly the same versions at compile time and run time.
  - If you are building a library to publish on Maven Central, you should not inline code from its dependencies. Users of your library might have different versions of its dependencies on the classpath, which breaks binary compatibility.

The Scala distribution is built using `-opt:l:classpath`, which improves the performance of the Scala compiler by roughly 5% (hot and cold, measured using our [JMH-based benchmark suite](https://github.com/scala/compiler-benchmark/blob/master/compilation/src/main/scala/scala/tools/nsc/ScalacBenchmark.scala)) compared to a non-optimized build.

The GenBCode backend and the implementation of the new optimizer are built on earlier work by Miguel Garcia.


#### Scaladoc look-and-feel overhauled

Scaladoc's output is now more attractive, more modern, and easier to use. Take a look at the [Scala Standard Library API](http://www.scala-lang.org/api/2.12.0).

Thanks, [Felix Mulder](https://github.com/felixmulder), for leading this effort.

#### Scaladoc can be used to document Java sources
This fix for [SI-4826](https://issues.scala-lang.org/browse/SI-4826) simplifies generating comprehensive documentation for projects with both Scala and Java sources. Thank you for your contribution, [Jakob Odersky](https://github.com/jodersky)!

This feature is enabled by default, but can be disabled with:

    scalacOptions in (Compile, doc) += "-no-java-comments"

Some projects with very large Javadoc comments may run into a stack overflow in the Javadoc scanner, which [will be fixed in 2.12.1](https://github.com/scala/scala/pull/5469).


#### Scala Shell ([REPL](https://en.wikipedia.org/wiki/Read%E2%80%93eval%E2%80%93print_loop))
Scala's interactive shell ships with several spiffy improvements. To try it out, launch it from the command line with the `scala` script or in sbt using the `console` task. If you like color (who doesn't!), use `scala -Dscala.color` instead until [it's turned on by default](https://github.com/scala/scala-dev/issues/256).

Since 2.11.8, the REPL uses the same tab completion logic as Scala IDE and ENSIME, which greatly improves the experience! Check out the [PR description](https://github.com/scala/scala/pull/4725) for some tips and tricks.

#### sbt builds Scala

Scala itself is now completely built, tested and published with sbt! This makes it easier to get started hacking on the compiler and standard library. All you need on your machine is JDK 8 and sbt - no ant, no environment variables to set, no shell scripts to run. You can [build, use, test and publish](https://github.com/scala/scala/blob/2.12.x/README.md#using-the-sbt-build) Scala like any other sbt-based project. Due to the recursive nature of building Scala with itself, IntelliJ cannot yet import our sbt build directly -- use the `intellij` task instead to generate suitable project files.


### Library Improvements

#### Either is now right-biased

`Either` now supports operations like `map`, `flatMap`, `contains`, `toOption`, and so forth, which operate on the right-hand side. The `.left` and `.right` methods may be deprecated in favor of `.swap` in a later release.
The changes are source-compatible with existing code (except in the presence of conflicting extension methods).

This change has allowed other libraries, such as [cats](http://typelevel.org/cats/) to standardize on `Either`.

Thanks, [Simon Ochsenreither](https://github.com/soc), for this contribution.


#### Futures improved

A number of improvements to `scala.concurrent.Future` were made for Scala 2.12. This [blog post series](https://github.com/viktorklang/blog) by Viktor Klang explores them in detail.


#### scala-java8-compat

The [Java 8 compatibility module for Scala](https://github.com/scala/scala-java8-compat) has received an overhaul for Scala 2.12. Even though interoperability of Java 8 SAMs and Scala functions is now baked into the language, this module provides additional convenience for working with Java 8 SAMs. Java 8 streams support was also added during the development cycle of Scala 2.12. Releases are available for both Scala 2.11 and Scala 2.12.



### Other changes and deprecations

  - A [mutable TreeMap](http://www.scala-lang.org/files/archive/api/2.12.0/scala/collection/mutable/TreeMap.html) implementation was added ([#4504](https://github.com/scala/scala/pull/4504)).
  - [ListSet](http://www.scala-lang.org/files/archive/api/2.12.0/scala/collection/immutable/ListSet.html) and [ListMap](http://www.scala-lang.org/files/archive/api/2.12.0/scala/collection/immutable/ListMap.html) now ensure insertion-order traversal (in 2.11.x, traversal was in reverse order), and their performance has been improved ([#5103](https://github.com/scala/scala/pull/5103)).
  - The [`@deprecatedInheritance`](http://www.scala-lang.org/files/archive/api/2.12.0/scala/deprecatedInheritance.html) and [`@deprecatedOverriding`](http://www.scala-lang.org/files/archive/api/2.12.0/scala/deprecatedOverriding.html) are now public and available to library authors.
  - The `@hideImplicitConversion` Scaladoc annotation allows customizing which implicit conversions are hidden ([#4952](https://github.com/scala/scala/pull/4952)).
  - The `@shortDescription` Scaladoc annotation customizes the method summary on entity pages ([#4991](https://github.com/scala/scala/pull/4991)).
  - JavaConversions, providing implicit conversions between Scala and Java collection types, has been deprecated. We recommend using [JavaConverters](http://www.scala-lang.org/files/archive/api/2.12.0/scala/collection/JavaConverters$.html) and explicit `.asJava` / `.asScala` conversions.
  - Eta-expansion (conversion of a method to a function value) of zero-args methods has been deprecated, as this can lead to surprising behavior ([#5327](https://github.com/scala/scala/pull/5327)).
  - The Scala library is [free](https://github.com/scala/scala/pull/4443) of [references](https://github.com/scala/scala/pull/4712) to `sun.misc.Unsafe`, and [no longer ships](https://github.com/scala/scala/pull/4629) with a fork of the forkjoin library.
  - Exhaustiveness analysis in the pattern matcher has been improved ([#4919](https://github.com/scala/scala/pull/4919)).
  - We emit parameter names according to [JEP-118](http://openjdk.java.net/jeps/118), which makes them available to Java tools and exposes them through Java reflection.


## Breaking changes

### Object initialization locks and lambdas

In Scala 2.11, the body of a lambda is in the `apply` method of the anonymous function class generated at compile time. The new lambda encoding in 2.12 lifts the lambda body into a method in the enclosing class. An invocation of the lambda will therefore indirect through the enclosing class, which may cause deadlocks that did not happen before.

For example, the following code

    import scala.concurrent._
    import scala.concurrent.duration._
    import ExecutionContext.Implicits.global
    object O { Await.result(Future(1), 5.seconds) }

compiles to (simplified):

    public final class O$ {
      public static O$ MODULE$;
      public static final int $anonfun$new$1() { return 1; }
      public static { new O$(); }
      private O$() {
        MODULE$ = this;
        Await.result(Future.apply(LambdaMetaFactory(Function0, $anonfun$new$1)), DurationInt(5).seconds);
      }
    }

Accessing `O` for the first time initializes the `O$` class and executes the static initializer (which invokes the instance constructor). Class initialization is guarded by an initialization lock ([Chapter 5.5 in the JVM specification](https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-5.html#jvms-5.5)).

The main thread locks class initialization and spawns the Future. The Future, executed on a different thread, attempts to execute the static lambda body method `$anonfun$new$1`, which also requires initialization of the class `O$`. Because initialization is locked by the main thread, the thread running the future will block. In the meantime, the main thread continues to run `Await.result`, which will block until the future completes, causing the deadlock.

One example of this [surprised the authors of ScalaCheck](https://github.com/rickynils/scalacheck/issues/290) -- now [fixed](https://github.com/rickynils/scalacheck/pull/294).

### Lambdas capturing outer instances

Because lambda bodies are emitted as methods in the enclosing class, a lambda can capture the outer instance in cases where this did not happen in 2.11. This can affect serialization.

The Scala compiler analyzes classes and methods to prevent unnecessary outer captures: unused outer parameters are removed from classes ([#4652](https://github.com/scala/scala/pull/4652)), and methods not accessing any instance members are made static ([#5099](https://github.com/scala/scala/pull/5099)). One known limitation is that the analysis is local to a class and does not cover subclasses.

    class C {
      def f = () => {
        class A extends Serializable
        class B extends A
        serialize(new A)
      }
    }

In this example, the classes `A` and `B` are first lifted into `C`. When flattening the classes to the package level, the `A` obtains an outer pointer to capture the `A` instance. Because `A` has a subclass `B`, the class-level analysis of `A` cannot conclude that the outer parameter is unused (it might be used in `B`).

Serializing the `A` instance attempts to serialize the outer field, which causes a `NotSerializableException: C`.


### SAM conversion precedes implicits

The [SAM conversion](http://www.scala-lang.org/files/archive/spec/2.12/06-expressions.html#sam-conversion) built into the type system takes priority over implicit conversion of function types to SAM types. This can change the semantics of existing code relying on implicit conversion to SAM types:

    trait MySam { def i(): Int }
    implicit def convert(fun: () => Int): MySam = new MySam { def i() = 1 }
    val sam1: MySam = () => 2 // Uses SAM conversion, not the implicit
    sam1.i()                  // Returns 2

To retain the old behavior, you may compile under `-Xsource:2.11`, use an explicit call to the conversion method, or disqualify the type from being a SAM (e.g. by adding a second abstract method).

Note that SAM conversion only applies to lambda expressions, not to arbitrary expressions with Scala `FunctionN` types:

    val fun = () => 2     // Type Function0[Int]
    val sam2: MySam = fun // Uses implicit conversion
    sam2.i()              // Returns 1


### SAM conversion in overloading resolution

In order to improve source compatibility, overloading resolution has been adapted to prefer methods with `Function`-typed arguments over methods with parameters of SAM types. The following example is identical in Scala 2.11 and 2.12:

    scala> object T {
         |   def m(f: () => Unit) = 0
         |   def m(r: Runnable) = 1
         | }

    scala> val f = () => ()

    scala> T.m(f)
    res0: Int = 0

In Scala 2.11, the first alternative is chosen because it is the only applicable method. In Scala 2.12, both methods are applicable, therefore [overloading resolution](http://www.scala-lang.org/files/archive/spec/2.12/06-expressions.html#overloading-resolution) needs to pick the most specific alternative. The specification for [*compatibility*](http://www.scala-lang.org/files/archive/spec/2.12/03-types.html#compatibility) has been updated to consider SAM conversion, so that the first alternative is more specific.

Note that SAM conversion in overloading resolution is always considered, also if the argument expression is not a function literal (like in the example). This is unlike SAM conversions of expressions themselves, see the previous section. See also the discussion in [scala-dev#158](https://github.com/scala/scala-dev/issues/158).

While the adjustment to overloading resolution improves compatibility, there also exists code that compiles in 2.11, but is ambiguous in 2.12:

    scala> object T {
         |   def m(f: () => Unit, o: Object) = 0
         |   def m(r: Runnable, s: String) = 1
         | }
    defined object T

    scala> T.m(() => (), "")
    <console>:13: error: ambiguous reference to overloaded definition


### Inferred types for fields

Type inference for `val`, and `lazy val` has been aligned with `def`, fixing assorted corner cases and inconsistencies ([#5141](https://github.com/scala/scala/pull/5141) and [#5294](https://github.com/scala/scala/pull/5294)). Concretely, when computing the type of an overriding field, the type of the overridden field is used used as expected type. As a result, the inferred type of a `val` or `lazy val` may change in Scala 2.12.

In particular, an `implicit val` that did not need an explicitly declared type in 2.11 may need one now. (This is always good practice anyway.)

You can get the old behavior with `-Xsource:2.11`. This may be useful for testing whether these changes are responsible if your code fails to compile.

### Changed syntax trees (affects macro and compiler plugin authors)

PR [#4794](https://github.com/scala/scala/pull/4749) changed the syntax trees for selections of statically accessible symbols. For example, a selection of `Predef` no longer has the shape `q"scala.this.Predef"` but simply `q"scala.Predef"`. Macros and compiler plugins matching on the old tree shape need to be adjusted.




## Improving these notes

Improvements to these release notes [are welcome!](https://github.com/scala/make-release-notes/blob/2.12.x/hand-written.md)