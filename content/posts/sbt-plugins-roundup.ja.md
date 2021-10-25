---
title:       "sbt プラグインのまとめ"
type:        story
date:        2012-04-11
changed:     2013-10-07
draft:       false
promote:     true
sticky:      false
url:         /ja/sbt-plugins-roundup
aliases:     [ /node/55 ]
tags:        [ "sbt" ]
---

XML ベースのビルドツールと比較すると sbt はビルド定義を (.sbt と .scala の両方とも) Scala を使って書くという違いがある。それにより一度 sbt のコンセプトや演算子を押さえてしまえば、ビルドユーザが sbt プラグインを書き始めるのにあまり労力がいらない。

既にあった sbt 0.7 のプラグインも移植してきたが、オリジナルのも書いているのでまとめて紹介したい。

## sbt-dirty-money

[sbt-dirty-money](https://github.com/sbt/sbt-dirty-money) は Ivy キャッシュを何となく選択的に消去するためのプラグインだ (`~/.ivy2/cache` 下の `organization` と `name` を含むもの)。たった 25行の簡単な実装だけど、`clean-cache` と `clean-local` の 2つのタスクは僕の役に立っている。

例えば、何かプラグインを開発していてそれがテスト用の hello プロジェクトにおいてキャッシュされているかどうかが不明であるとする。
プラグインプロジェクト中から `clean-cache` と `clean-local` の両方を走らせ、hello プロジェクトを reload することでプラグインが解決できないかどうかを確認する。解決できなければ、どこか知らない所から引っ張ってきてるわけではないということなので成功だ。

## sbt-buildinfo

[sbt-buildinfo](https://github.com/sbt/sbt-buildinfo) は前から書こうと思っていたプラグインの一つだ。これはビルド定義から Scala のソースを生成する。主な目的はプログラムが自身のバージョン番号を意識することにある (特に、conscript を使ったアプリの場合)。

`sourceGenerators` を使ってバージョン番号を含むオブジェクトを生成するスクリプトをちゃちゃっと書いたことが何回かあったが、他の人にも使ってもらえるようにするにはプラグインにするのが適してると思った。`state` から値を抽出することで sbt-buildinfo は任意の複数のキーから Scala ソースを生成する。以下を `build.sbt` に加える:

```scala
buildInfoSettings

sourceGenerators in Compile <+= buildInfo

buildInfoKeys := Seq[Scoped](name, version, scalaVersion, sbtVersion)

buildInfoPackage := "hello"
```

これで以下が生成される:

```scala
package hello

object BuildInfo {
  val name = "helloworld"
  val version = "0.1-SNAPSHOT"
  val scalaVersion = "2.9.1"
  val sbtVersion = "0.11.2"
}
```

## sbt-scalashim

[sbt-scalashim](https://github.com/sbt/sbt-scalashim) は Scala 2.8.x から 2.9.x の `sys.error` を使うための shim (互換ライブラリ)を生成するためのプラグインだ。最近 Scala コミュニティ内の多くの人がライブラリを 2.8.x 系と 2.9.x 系の両方で cross publishing (異なる Scala ライブラリと共にビルドされたライブラリをそれぞれ用意して公開すること) するよう意識を高めようと声を上げている。

2.8.x 系が見捨てられる原因の一つに `sys.error` によるソースレベルでの非互換性があると思ったので、その差を吸収するプラグインを書いた。パッケージ下のクラスは空のパッケージからの名前をインポートできないので、残念ながら `import scalashim._` をコードに加える必要がある。そのかわり 2.8.0  から `sys.error` を使える。最新版ではその他に `sys.props` や `sys.env` なども使える。

## sbt-man

[sbt-man](https://github.com/sbt/sbt-man) も前から書きたかったプラグインだ。
ちなみに、これらのプラグインのほとんどは週末に (たいていは夜遅く) ハックしたものだ。

しばらくの間、毎日数ページずつ[川合史朗/shiro](http://blog.practical-scheme.net/shiro)さんの訳した[プログラミング Clojure](http://www.amazon.co.jp/%E3%83%97%E3%83%AD%E3%82%B0%E3%83%A9%E3%83%9F%E3%83%B3%E3%82%B0Clojure-Stuart-Halloway/dp/4274067890) を読んでいる。これは Scala でも欲しいなと思ったものの一つに `doc` 関数というのがあって、渡された関数のドキュメンテーションを表示する。

    user=> (doc doc)
    -------------------------
    clojure.core/doc
    ([name])
    Macro
      Prints documentation for a var or special form given its name
    nil

これを知ってしまったことで、ただの標準ライブラリの関数シグネチャを調べるのにブラウザを使うことに対して感じてきた違和感に気づいてしまった。

仕方がないので、やっと先週末 `man` コマンドを追加するプラグインを書いた:

    > man Traversable /:
    [man] scala.collection.Traversable
    [man] def /:[B](z: B)(op: (B ⇒ A ⇒ B)): B
    [man] Applies a binary operator to a start value and all elements of this collection, going left to right. Note: /: is alternate syntax for foldLeft; z /: xs is the same as xs foldLeft z. Note: will not terminate for infinite-sized collections. Note: might return different results for different runs, unless the underlying collection type is ordered. or the operator is associative and commutative. 

中で仕事をしてるのは [Scalex](http://scalex.org/) で僕は cli の実装をパクってきて lift-json の動いていなかった部分を少し直しただけだ。

## 他のプラグイン

他の方が書いた便利なプラグインもいくつもあるので、いくつか紹介する。

Sonatype への移行に際して Josh の [xsbt-gpg-plugin](https://github.com/sbt/xsbt-gpg-plugin) はとりあえず必携となった。Josh は他にも [xsbt-ghpages-plugin](https://github.com/jsuereth/xsbt-ghpages-plugin) や [sbt-git-plugin](https://github.com/sbt/sbt-git-plugin) などもメンテしている。

あと、僕の全プロジェクトで使ってるのは Doug の [ls-sbt](https://github.com/softprops/ls-sbt) で、[ls.implicit.ly](http://ls.implicit.ly/) に登録するのに使ってる。Doug は他にも [np](https://github.com/softprops/np) や [coffeescripted-sbt](https://github.com/softprops/coffeescripted-sbt) もメンテしている。

最近グローバル plugins.sbt に入れたものに Stephen Wells さんの [sbt-sh](https://github.com/steppenwells/sbt-sh) がある。これはコマンドを sbt 外で実行するので、こういうことが sbt シェルから書ける:

    > sh git status 

あと紹介したいのは Mathias の [sbt-revolver](https://github.com/spray/sbt-revolver)。これは sbt シェルのバックグラウンドで、つまりフォークした JVM 内でアプリケーションを実行して監視する。監視してくれているので `re-start` すると既存のインスタンスを落として再起動してくれる。Scala インスタンスで使う分には無料の [JRebel](http://zeroturnaround.com/jrebel/) も自動で使うことができる。

[sbt-appengine](https://github.com/sbt/sbt-appengine) の開発サーバタスクの実装にあたって sbt-revolver 上で実装することで hot reloading などを利用できるようにしてみた。他にも多分面白い使い方が色々あるはずだ。

## sbt 0.12

sbt 0.12 は色々な理由で楽しみだけど、その理由の一つはポイントリリース間のプラグインのバイナリ互換性が保証される点だ。これで sbt が出てくるたびに jar を公開しなくてもよくなるので、プラグイン作者への負担が軽減される。ソース依存性が使える事も知ってはいるが、普通の Ivy 依存性ではないため設定が難しいし、pom.xml に書かれないのであまり使っていない。

0.12 はまた、僕がコントリビュートした Scala 同様の文字列リテラルパーサが追加される。これでタスクやコマンドにホワイトスペース込みの引数を渡せるので、コマンドの幅が少し広がると思う。
