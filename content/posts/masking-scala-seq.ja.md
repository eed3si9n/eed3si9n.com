---
title:       "scala.Seq のマスキング"
type:        story
date:        2018-12-17
changed:     2018-12-18
draft:       false
promote:     true
sticky:      false
url:         /ja/masking-scala-seq
aliases:     [ /node/283 ]
tags:        [ "scala" ]
---

  [1]: https://www.scala-lang.org/blog/2017/02/28/collections-rework.html#language-integration
  [218]: https://github.com/scopt/scopt/issues/218
  [args]: https://github.com/scala/scala/blob/v2.13.0-M5/src/library/scala/App.scala#L46
  [11317]: https://github.com/scala/bug/issues/11317
  [heiko]: https://hseeberger.wordpress.com/2013/10/25/attention-seq-is-not-immutable/

現行の Scala 2.13.0-M5 のままで行くと、`scala.Seq` は `scala.collection.Seq` から `scala.collection.immutable.Seq` に変更される予定だ。[Scala 2.13 collections rework][1] に何故今まで不変じゃなかったのかの解説が少し書かれている。行間から推し量ると、`scala.Seq` がデフォルトで不変になることを喜ぶべきだと言っているんだと思う。

デフォルトで列が不変になることはアプリや新しく書かれるコードには良いことだと思う。ライブラリ作者にとってはもう少しこみいっているかもしれない。

- あなたがクロスビルドされたライブラリを持っていて
- ライブラリのユーザも複数の Scala バージョンを使っていて
- ライブラリのユーザが `Array(...)` を使っていた場合

この不変 `Seq` への変更は、breaking change つまり非互換な API 変更となりうる。

失敗例としては [scopt/scopt#218][218] がある。僕が scopt のクロスビルドを行ったが、`args` を渡せなくなったらしい。Scala 2.13.0-M5 においても [`args`][args] は `Array[String]` のままだ。

シンプルな修正は全てのソースにおいて `scala.collection.Seq` を import することだ。僕が欲しいのは `Seq` を使うとコンパイルが通らなくなることだ。

### scala.Seq を unimport する

まず最初にやってみたのは `scala.Seq` を unimport して、`scala.collection.Seq` か `scala.collection.immutable.Seq` のどちらかを import することを強制することだ。

<scala>
import scala.{ Seq => _, _ }
</scala>

最も外側にあるスコープ内でデフォルトの `import scala._` によって `Seq` という名前が束縛されているため、これは効果が無い。あと、よく考えてみると、もし仮にそれがうまくいったとしても import 文を全てのソースに忘れずに書かなければいけないので、良い手では無い。

Jasper-M さんが `-Yno-imports` のことを思い出させてくれた。これは検討する価値があるかもしれない。

### ダミーの Seq の定義

次に、自分のパッケージ以下に `Seq` という名前の trait を定義してみた:

<scala>
package scopt

import scala.annotation.compileTimeOnly

/**
  * In Scala 2.13, scala.Seq moved from scala.collection.Seq to scala.collection.immutable.Seq.
  * In this code base, we'll require you to name ISeq or CSeq.
  *
  * import scala.collection.{ Seq => CSeq }
  * import scala.collection.immutable.{ Seq => ISeq }
  *
  * This Seq trait is a dummy type to prevent the use of `Seq`.
  */
@compileTimeOnly("Use ISeq or CSeq") private[scopt] trait Seq[A1, F1[A2], A3]
</scala>

わざと複雑な型パラメータを使うことで既存のコードのコンパイルが通らないようになっている。例えば、コードに `Seq[String]` が出てきた場合は以下のようなエラーとなる:

<code>
[info] Compiling 3 Scala sources to /scopt/jvm/target/scala-2.12/classes ...
[error] /scopt/shared/src/main/scala/scopt/options.scala:434:19: wrong number of type arguments for scopt.Seq, should be 3
[error]   def parse(args: Seq[String])(implicit ev: Zero[C]): Boolean =
[error]                   ^
[error] one error found
</code>

コードが `scopt` パッケージ内にさえあれば、`Seq` の使用を防止できる。実際の Seq を使うためには以下の import を行う:

<scala>
import scala.collection.{ Seq => CSeq }
import scala.collection.immutable.{ Seq => ISeq }
</scala>

クロスビルド間の API semantics が統一されているべきと思うならば、public なものは全て `CSeq` を使うのがいいと思う。そして API が変更されるタイミングで `ISeq` を全面的に採用するかを検討すればいいと思う。

### 追記: scala.IndexedSeq

Sciss (Hanns) さんに `scala.IndexSeq` にも同様に影響があることを指摘してもらった。`scala.Seq` 対策をする場合は `scala.IndexedSeq` も同様に対応するべきだろう。

### 追記: Heiko Seq

あともう一つ Sciss (Hanns) さんに[思い出させて](https://www.reddit.com/r/scala/comments/a71pi3/masking_scalaseq/)もらったのは Heiko Seq のことだ。これは、Heiko さんが 2013年に [Seq is not immutable!][heiko] 書いている:

<scala>
package object scopt {
  type Seq[+A] = scala.collection.immutable.Seq[A]
  val Seq = scala.collection.immutable.Seq
  type IndexedSeq[+A] = scala.collection.immutable.IndexedSeq[A]
  val IndexedSeq = scala.collection.immutable.IndexedSeq
}
</scala>

これは `scala.immutable.Seq` を全ての Scala バージョンで採用することになる。`scala.collection.Seq` のままが良ければ Sciss さんのバリエーションを使えばいい:

<scala>
package object scopt {
  type Seq[+A] = scala.collection.Seq[A]
  val Seq = scala.collection.Seq
  type IndexedSeq[+A] = scala.collection.IndexedSeq[A]
  val IndexedSeq = scala.collection.IndexedSeq
}
</scala>

ソースを検査して `CSeq`、`ISeq`、`List` と決めるのが面倒なひとはこういう手もあるかもしれない。

### 追記: 可変長引数 (vararg)

あと、関連する Scala 2.13 マイグレーションの事項として可変長引数 (vararg) があるというコメントを Dale 君がしていた。
Scala の言語仕様として可変長引数は `scala.Seq` を受け取ることになっているので、この変更によって実質 `scala.collection.immutable.Seq` を期待するという変更になる。あなたのユーザが API を `something(xs: _*)` というふうに呼び出していて、`xs` が配列などであった場合に影響が出てくる。これは Scala 全体の変更で、Scala 2.13 に移行するときに全員が変更しなければいけない。
