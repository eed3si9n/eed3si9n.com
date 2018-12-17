  [1]: https://www.scala-lang.org/blog/2017/02/28/collections-rework.html#language-integration
  [218]: https://github.com/scopt/scopt/issues/218
  [args]: https://github.com/scala/scala/blob/v2.13.0-M5/src/library/scala/App.scala#L46
  [11317]: https://github.com/scala/bug/issues/11317

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
