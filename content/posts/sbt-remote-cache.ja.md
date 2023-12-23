---
title: "sbt 2.x リモートキャッシュ"
type: story
date: 2023-12-21
url: /ja/sbt-remote-cache
---

  [build-system]: https://www.microsoft.com/en-us/research/uploads/prod/2018/03/build-systems.pdf
  [7464]: https://github.com/sbt/sbt/pull/7464
  [HashWriter]: https://github.com/eed3si9n/sjson-new/blob/66f05ac562a5c4ed544d24c41aacf3b69a9318f4/core/src/main/scala/sjsonnew/HashWriter.scala
  [JsonFormat]: https://github.com/eed3si9n/sjson-new/blob/develop/core/src/main/scala/sjsonnew/JsonFormat.scala
  [reibitto]: https://reibitto.github.io/blog/remote-caching-with-sbt-and-s3/
  [tweets]: https://twitter.com/eed3si9n/status/1319626955159896064

> これは [Scala Advent Calendar 2023](https://qiita.com/advent-calendar/2023/scala) の 23日目の記事です。21日目は、さっちゃんの[path 依存型って何? 調べてみました!](https://c4se.hatenablog.com/entry/2023/12/22/001904)でした。

### はじめに

リモートキャッシュは、ビルドの結果を共有することで劇的な性能の改善を可能とする。[Mokhov 2018][build-system] ではクラウド・ビルド・システム (cloud build system) とも呼ばれている。これは、僕が Blaze (現在は Bazel としてオープンソース化されている) のことを聞いて以来関心を持ち続けてきた機能だ。2020年に、僕は sbt 1.x の[コンパイルキャッシュ](/cached-compilation-for-sbt)を実装した。[reibitto][reibitto] さんの報告によると「以前は全てをコンパイルするのに 7分かかっていたが、**15秒**で終わるようになった」らしい。他にも **2x ~ 5x** 速くなったという報告を他の人も行っている。これらは期待の持てる内容であることに間違いないが、現行の機能は少し不器用で `compile` タスクにしか使えないという限界がある。2023年の3月に、[RFC-1: sbt cache ideas](/sbt-cache-ideas/) として現状の課題と対策の設計のアウトラインを書き出してみた。以下に課題をまとめる:

- 問題1: sbt 1.x は `compile` のリモートキャッシュ、およびその他いくつかのタスクに対してディスクキャッシュを実装するが、カスタムタスクが参加できるソリューションが望ましい。
- 問題2: sbt 1.x はディスクキャッシュとリモートキャッシュで別の機構を持つが、ビルドユーザがローカルかリモートのキャッシュかを切り替えられる統一した機構が望ましい。
- 問題3: sbt 1.x は Ivy resolver をキャッシュの抽象化に用いたが、よりオープンなリモートキャッシュ・バックエンドが望ましい

12月中は適当に自分でプロジェクトを選んで 毎日少しでもいいから作業して、それをブログに数行ずつ記録したり [#decemberadventure](https://mastodon.social/tags/DecemberAdventure) というハッシュタグをつけて投稿するという独りアベントが Mastodon 界隈の一部で流行ってて、僕の [december adventure 2023](/december-adventure-2023) として、sbt 2.x のリモートキャッシュに挑戦してみようと思った。実装の提案は GitHub [#7464][7464] で、本稿では、提案した変更点の解説を行う。**注意**: sbt の内部構造に関する予備知識はあんまり必要としないが、プルリクコメントの拡張版のようなものなので上級レベルの読者を想定している。あと、プルリク段階なので書いている先から詳細はどんどん変わっていくかもしれない。

<!--more-->

### 低レベルな基礎

抽象的には、キャッシュ化されたタスクは以下のように考える事ができる:

```scala
(In1, In2, In3, ...) => (A1 && Seq[Path])
```

インプット値のハッシュと結果値をどこか (例えばディスク内) に保存できれば、次回呼ばれたときには重いタスクの評価をする代わりに結果だけを返すことができる。キャッシュ化されたタスクの結果値は `ActionResult` として表される:

```scala
import xsbti.HashedVirtualFileRef

class ActionResult[A1](a: A1, outs: Seq[HashedVirtualFileRef]):
  def value: A1 = a
  def outputs: Seq[HashedVirtualFileRef] = outs
  ....
end ActionResult
```

`HashedVirtualFileRef` は後でもみるが、ファイル名とコンテンツハッシュを持つ。これらを使って以下のように `cache` 関数を実装できる:

```scala
import sjsonnew.{ HashWriter, JsonFormat }
import xsbti.VirtualFile

object ActionCache:
  def cache[I: HashWriter, O: JsonFormat: ClassTag](key: I, otherInputs: Long)(
      action: I => (O, Seq[VirtualFile])
  ): ActionResult[O] =
    ...
end ActionCache
```

上の型パラメータ `I` は典型的にはタプル型となる。`action` 関数のシグネチャが `Seq[VirtualFile]` というのが出てきて不自然に見えるかもしれない。これはタスク内でのファイル出力エフェクトを捕獲するためのものだ。

### キャッシュ化されたタスクの自動導出

sbt の DSL は、Applicative のための do 記法で、

```scala
someKey := {
  name.value + version.value + "!"
}
```

をマクロを経由して Applicative の `mapN` 式に書き換える:

```scala
someKey <<= i.mapN((wrap(name), wrap(version)), (q1: String, q2: String) => {
  q1 + q2 + "!"
})
```

Scala 3 マクロを使って、結果値をさらに装飾してキャッシュ化されたタスクを自動導出することができる:

```scala
someKey <<= i.mapN((wrap(name), wrap(version)), (q1: String, q2: String) => {
  ActionCache.cache[(String, String), String](
    key = (q1, q2),
    otherInputs = 0): input =>
      (q1 + q2 + "!", Nil))
})
```

これがうまくいくにはインプット・タプルは [`sjsonnew.HashWriter`][HashWriter] を満たす必要があり、`String` などの結果値の型は `JsonFormat` を満たす必要がある。便宜的には、これは `build.sbt` の抽象構文木と[疑似 case class](/ja/contraband-an-alternative-to-case-class/) から[マークル木](https://ja.wikipedia.org/wiki/%E3%83%8F%E3%83%83%E3%82%B7%E3%83%A5%E6%9C%A8)を構築していると考えることができる。

### キャッシュのバックエンド

以下の trait はキャッシュのバックエンドを抽象化する。

```scala
class ActionInput(hash: String):
  def inputHash: String = hash
  ....
end ActionInput

/**
 * An abstration of a remote or local cache store.
 */
trait ActionCacheStore:
  def put[A1: ClassTag: JsonFormat](
      key: ActionInput,
      value: A1,
      blobs: Seq[VirtualFile],
  ): ActionResult[A1]

  def get[A1: ClassTag: JsonFormat](key: ActionInput): Option[ActionResult[A1]]

  def putBlobs(blobs: Seq[VirtualFile]): Seq[HashedVirtualFileRef]

  def getBlobs(refs: Seq[HashedVirtualFileRef]): Seq[VirtualFile]

  def syncBlobs(refs: Seq[HashedVirtualFileRef], outputDirectory: Path): Seq[Path]
end ActionCacheStore
```

メソッドはだいたい自明だと思うが、これはキャッシュのバックエンドを実装したい人向けのものなので、詳細を理解するのは重要ではない。興味深いのはたったの 5つのメソッドで済むということだ。初期段階のテストでは、ローカル環境でのディスクキャッシュに注力することにする。

キャッシュ・タスク化した `packageBin` を実行後のキャッシュ・ディレクトリは以下のようになった:

```bash
$ tree $HOME/Library/Caches/sbt/v2/
~/Library/Caches/sbt/v2/
├── ac
│   └── sha256-eeefc535fd395cb6bfd300197acc2a3512f4e71b1eb7006c7d0a168ae919538c
└── cas
    └── farm64-b9c876a13587c8e2
```

`ac/sha256-eeefc535fd395cb6bfd300197acc2a3512f4e71b1eb7006c7d0a168ae919538c` のファイルの内容は:

```json
{"$fields":["value","outputs"],"value":"${OUT}/jvm/3.3.1/hello/scala-3.3.1/hello_3-0.1.0-SNAPSHOT.jar>farm64-b9c876a13587c8e2","outputs":["${OUT}/jvm/3.3.1/hello/scala-3.3.1/hello_3-0.1.0-SNAPSHOT.jar>farm64-b9c876a13587c8e2"]}
```

`cas/farm64-b9c876a13587c8e2` は JAR ファイルだ:

```bash
$ unzip -l $HOME/Library/Caches/sbt/v2/cas/farm64-b9c876a13587c8e2
Archive:  ~Library/Caches/sbt/v2/cas/farm64-b9c876a13587c8e2
  Length      Date    Time    Name
---------  ---------- -----   ----
      298  01-01-2010 00:00   META-INF/MANIFEST.MF
        0  01-01-2010 00:00   example/
      608  01-01-2010 00:00   example/Greeting.class
....
```

### キャッシュ化における実際の問題

もしキャッシュ化が簡単ならば、オープンソースから利益を上げることと並んで計算機科学の 2大難問と言われることは無いだろう (あとは off-by-one エラーも)。

#### シリアライゼーション問題

第一に、キャッシュ化は serialization-hard、つまりシリアライゼーション問題と同等もしくはそれ以上に困難だ。現在の形で 10年以上続いているビルドツールである sbt にとっては、これが最大の難関となると思う。具体例で説明すると、`Attributed[A1]` というデータ型があって、これは `A1` のデータ及び任意のメタデータをキー・値として保持する。クラスパスなどの基礎的なものが `Seq[Attributed[File]]` として表されており、これを用いてクラスパス内のエントリーを Zinc の `Analysis` と関連付けたりしている。

`compile` のようなタスクをメモリ内で実行しているうちは、ぶっちゃけ `Map[String, Any]` と等価である `Attributed[A1]` で特に問題は無かった。しかし、キャッシュ化を考慮するとインプットならば `HashWriter`、結果値ならば `JsonFormat` が必要となり、`Any` はどれも不可能だ。この場合は、`StringAttributeMap` という別のデータ型を作ることで回避した。

#### ファイル・シリアライゼーション問題

キャッシュ化は file-serialization-hard、ファイル・シリアライゼーション問題と同等もしくはそれ以上に困難だ。`java.io.File` (もしくは `Path`) は特別な存在なので、別個に考察する必要があるが、それが技術的に難しいからというよりは、それが何を意味するかという我々自身の期待による所が大きい。僕たちが「ファイル」と言うときそれは以下のことを意味する:

1. 事前に取り決めた場所からの相対パス
2. ファイルに関する一意な証明、コンテンツハッシュなど
3. 具現化された実際のファイル

`java.io.File` を使った場合、上の 3つのうちどれを意味したのかが少し曖昧になる。厳密には `File` はただのファイル・パスなので、`target/a/b.jar` といったファイル名だけをデシリアライズするだけでいい。しかし、下流のタスクが `target/a/b.jar` がファイルシステムに存在していることを期待していた場合、タスクは失敗する。

これを明示化するために、`xsbti.VirtualFileRef` は相対パスのためのみに用い、`xsbti.VirtualFile` はコンテンツを持った具現化された仮想ファイルを指す。しかし、ファイルのリストなどをキャッシュする用途としてはどちらも不向きだ。ファイル名だけを保存してもファイルそのものが同一であるか保証できないし、ファイルの全コンテンツを引き回すのは JSON などには非効率的すぎる。同じ JAR がビルド内で何度も出てくることを考えると、ただの参照がほしいだけなのにファイルを埋め込んでしまうのは馬鹿げている。

ここで、謎の2つ目の選択肢ファイルに関する**一意な証明**が役に立つ。Bazel cache のイノベーションの鍵の一つに content-addressable storage (CAS) というアイディアがある。ディレクトリいっぱいにファイルが入っていて、それぞれがコンテンツハッシュをもとにファイル名が付けられているようなものだと考えていい。これがあれば、コンテンツハッシュを知っているだけでいつでもファイルを具現化できる。実際には、ファイル名も必要になってくるので、これを表すために `HashedVirtualFileRef` というデータ型を sbt 2.x に追加した:

```java
public interface HashedVirtualFileRef extends VirtualFileRef {
  String contentHashStr();
}
```

#### エフェクト問題

ファイル・シリアライゼーション問題を全ての副作用に一般化するとキャッシュ化は IO-hard だと考えることができる。とにかくタスクが実行する副作用のうち、僕たちが必要だと思うものは管理する必要がある。これには例えば画面に文字を表示することも含む。合成についても考える必要があるかもしれない。

#### アウトプットの宣言

sbt 2.x で、僕は `Def.declareOutput` という新しい関数を導入する:

```scala
Def.declareOutput(out)
```

これはファイル出力の宣言を行うためにタスク内で呼ばれる。典型的なビルドツールだとファイルの生成は副作用ととして行われ、1つのタスクから多くのファイルが生成されることもあり、それらの一部だけを下流のタスクが使うといったことがある。リモートキャッシュを用いたビルドツールは、期待されるファイルをダウンロードする必要があるため、アウトプットを宣言する必要がある。`compile` タスクのようにファイルを色々生成するが、戻り値の型にファイルを持たないものもあることに注意してほしい。

```scala
someKey := Def.cachedTask {
  val output = StringVirtualFile1("a.txt", "foo")
  Def.declareOutput(output)
  name.value + version.value + "!"
}
```

上のタスクは、以下のようになる:

```scala
someKey <<= i.mapN((wrap(name), wrap(version)), (q1: String, q2: String) => {
  var o0 = _
  ActionCache.cache[(String, String), String](
    key = (q1, q2),
    otherInputs = 0): input =>
      var o1: VirtualFile = _
      val output = StringVirtualFile1("a.txt", "foo")
      o1 = output
      (q1 + q2 + "!", List(o1))
})
```

このタスクを最初に走らせたときは、sbt は `q1 + q2 + "!"` を評価して、また別に `o1` を CAS に保存して `HashedVirtualFileRef` のリストを持つ `ActionResult` を計算する。2度目にこのタスクが呼び出されたときは、`ActionCache.cache(...)` はこのファイルを物理ファイルとして具現化してそれを参照する `VirtualFile` を返す。

#### シリアライゼーションからのオプトアウト

上の例では、全てのインプット側のセッティングとタスクはキャッシュキーである前提でマクロ展開が行われた:

```scala
ActionCache.cache[(String, String), String](
  key = (q1, q2),
  ....
```

これは多分デフォルトのふるまいとしては適切だが、実際にはキャッシュキーから除外したいキーもあるはずだ。例えば、ログに使われる `streams` キーなんかは、新しい値が毎回与えられ、シリアライゼーションできる意味のある値を特に持たない。そのため、無理にこれを JSON に変換する必要性が無い。

このような除外のために、`cacheOptOut(...)` というアノテーションを追加した:

```scala
@meta.getter
class cacheOptOut(reason: String = "") extends StaticAnnotation
```

これで、以下のようにして `streams` をキャッシュからオプトアウトすることができる:

```scala
@cacheOptOut(reason = "not useful as a cache key")
val streams = taskKey[TaskStreams]("Provides streams for logging and persisting data.")
  .withRank(DTask)
```

一般的に、マシンに特定なキーや非密閉な (non-hermetic) なキーは、可能な限りキャッシュから除外するべきだ。

#### レイテンシー・トレードオフ問題

キャッシュ化は latency-tradeoff-hard、レイテンシーのトレードオフ問題と同等もしくはそれ以上に困難だ。仮に `compile` タスクが 100 の `.class` ファイルを生成して、`packageBin` が 1つの `.jar` を生成するとした場合、`compile` タスクはキャッシュが当たったとしてもディスクキャッシュからから 100個のファイルを読み込むか、リモートキャッシュから 100個のファイルをダウンロードをする必要がある。JAR ファイルが `.class` ファイル群を近似することを考慮すると、ファイルのダウンロード往復を減らすためには `compile` にも JAR ファイルを使うべきだろう。

<a id="hermeticity"></a>
#### 密閉性問題

リモートキャッシュ化は密閉性問題 (hermeticity) と同等もしくはそれ以上に困難だ。リモートキャッシュの前提条件はキャッシュの結果が異なるマシンで共有可能であることだ。意図せずにマシン特定の情報を生成物の中に捕獲してしまった場合、キャッシュのサイズが大きくなってしまったり、キャッシュヒット率が低下したり、実行時エラーとなったりする。これを密閉性が壊れたと言ったりする。

2つのよくある問題は `java.io.File` 経由で絶対パスを捕獲してしまうのと、現在のタイムスタンプを捕獲してしまうことだ。もう少し目立たないが実際に僕が遭遇したことがあるのは JVM のバグでマシンのタイムゾーンを捕獲してしまう問題と GraalVM が glibc のバージョンを捕獲してしまう問題だ。

<a id="package-aggregation"></a>
#### パッケージ集約問題

キャッシュの無効化はパッケージ集約問題 (package aggregation) と同等もしくはそれ以上に困難だ。詳細は [Analysis of Zinc](https://www.youtube.com/watch?v=h8ACmUHQ2jg) 参照。「パッケージ集約問題」という用語は今僕が勝手に思いついたものだが、問題を要約すると、1つのサブプロジェクトにより多くのソースファイルが集約すると、サブプロジェクト間の依存性がより密になってしまい、依存性グラフを逆向きにするという単純な無効化だと、コード変更による初期の無効化が山火事のようにモノリポ全体に広がってしまうという問題だ。

ビルドツールはそれぞれこの問題に対して色々な対策を行っている:

- サブプロジェクトの粒度を上げる。1:1:1 ルール (1ディレクトリ、1 パッケージ、1 ターゲット)
- 間接的依存性を無視する。これは strict deps とも呼ばれている。(Bazel は Java でこれを行う)
- メソッドの使用粒度で依存性を追跡する (Zinc が行っていること)
- 未使用の import やライブラリ依存性の削除

今回は、多分単純な無効化から実装すると思うが、後でこのあたりを改善できる道は確保しておきたい。

### ケーススタディー: packageBin タスク

`packageBin` タスクは class ファイルから構成される JAR ファイルを作る。一般的に、`package*` 系のタスクは  [`packageTaskSettings` と `packageTask` 関数](https://github.com/sbt/sbt/blob/v1.9.7/main/src/main/scala/sbt/Defaults.scala#L1848-L1871)および [`Package` object](https://github.com/sbt/sbt/blob/v1.9.7/main-actions/src/main/scala/sbt/Package.scala) によって定義される。`packageBin` タスクをキャッシュ・タスク化してみよう。

第一に、`PackageOption` をシリアライズ可能とする必要がある。Scala 3 enum を使って実装して、それぞれに対して `JsonFormat` を実装して、直和型を定義した:

```scala
enum PackageOption:
  case JarManifest(m: Manifest)
  case MainClass(mainClassName: String)
  case ManifestAttributes(attributes: (Attributes.Name, String)*)
  case FixedTimestamp(value: Option[Long])

object PackageOption:
  ....

  given JsonFormat[PackageOption] = flatUnionFormat4[
    PackageOption,
    PackageOption.JarManifest,
    PackageOption.MainClass,
    PackageOption.ManifestAttributes,
    PackageOption.FixedTimestamp,
  ]("type")
end PackageOption
```

`Package.Configuration` クラスは以下のように変更した:

```scala
// in sbt 1.x
final class Configuration(
  val sources: Seq[(File, String)],
  val jar: File,
  val options: Seq[PackageOption]
)

// in sbt 2.x
final class Configuration(
  val sources: Seq[(HashedVirtualFileRef, String)],
  val jar: VirtualFileRef,
  val options: Seq[PackageOption]
)
```

インプット側のソースは `HashedVirtualFileRef` で表し、アウトプット用のファイル名は `VirtualFileRef` で表していることに注目してほしい。実際に JAR ファイルを作る `Pkg.apply(...)` は `Unit` でなく `VirtualFile` を返すようにした。

`Keys.scala` での `packageBin` キーの定義は以下のように変更した:

```scala
val packageBin = taskKey[HashedVirtualFileRef]("Produces a main artifact, such as a binary jar.").withRank(ATask)
```

新しい `pacakgeTask` は以下のようになる:

```scala
def packageTask: Initialize[Task[HashedVirtualFileRef]] =
  Def.cachedTask {
    val config = packageConfiguration.value
    val s = streams.value
    val converter = fileConverter.value
    val out = Pkg(
      config,
      converter,
      s.log,
      Pkg.timeFromConfiguration(config)
    )
    Def.declareOutput(out)
    out
  }
```

地味なポイントかもしれないがここでも注意してほしいのは、`out` の型は `VirtualFile` であるが、タスクの戻り値の型はわざと `HashedVirtualFileRef` に広げてあることだ。タスクキーを `Initialize[Task[VirtualFile]]` に変えるとコンパイルが通らないはずだ:

```scala
[error] -- [E172] Type Error: /user/xxx/sbt/main/src/main/scala/sbt/Defaults.scala:1979:5
[error] 1979 |    }
[error]      |     ^
[error]      |Cannot find JsonWriter or JsonFormat type class for xsbti.VirtualFile.
```

ディスクキャッシュ `ac/sha256-eeefc535fd395cb6bfd300197acc2a3512f4e71b1eb7006c7d0a168ae919538c` の中身が以下であることを思い出してほしい:

```json
{"$fields":["value","outputs"],"value":"${OUT}/jvm/3.3.1/hello/scala-3.3.1/hello_3-0.1.0-SNAPSHOT.jar>farm64-b9c876a13587c8e2","outputs":["${OUT}/jvm/3.3.1/hello/scala-3.3.1/hello_3-0.1.0-SNAPSHOT.jar>farm64-b9c876a13587c8e2"]}
```

もしタスクの戻り値の型が `VirtualFile` ならば、この JSON の中に全ファイルコンテンツを埋め込む必要がある。代わりに、相対パスと FarmHash を使ったファイルに関する一意な証明のみを保存する: `"${OUT}/jvm/3.3.1/hello/scala-3.3.1/hello_3-0.1.0-SNAPSHOT.jar>farm64-b9c876a13587c8e2"`。実際のコンテンツは `Def.declareOutput(out)` にて CAS に渡す。

ディスクキャッシュが潤うと、`clean` の後でも、`packageBin` はインプットを zip せずともディスクキャッシュに対して高速にシンボリックリンクを張るだけでよくなる。

### ケーススタディー: compile task

`packageBin` の自動キャッシュ化ができたので、この考え方を `compile` にも当てはめて考えることができる。課題の 1つとして、上でも言及したレイテンシー・トレードオフ問題がある。sbt 1.x では、型付けされた並列処理のまとまりだったので、好きなだけ細かいタスクを作ることができた。sbt 2.x ではおそらくネットワークのレイテンシーも考慮に入れる必要がある (検証実験が多分必要)。幸いなことに、JAR ファイルというコンパイラが扱い慣れているものがあるので、全ての `*.class` をキャッシュ化する代わりに JAR ファイルを生成させる。

`compileIncremental` の大まかな流れは以下のようになる:

```scala
compileIncremental := (Def.cachedTask {
  val s = streams.value
  val ci = (compile / compileInputs).value
  val c = fileConverter.value
  // do the normal incremental compilation here:
  val analysisResult: CompileResult =
    BspCompileTask
      .compute(bspTargetIdentifier.value, thisProjectRef.value, configuration.value) {
        bspTask => compileIncrementalTaskImpl(bspTask, s, ci, ping, reporter)
      }
  val analysisOut = c.toVirtualFile(setup.cachePath())
  Def.declareOutput(analysisOut)

  // inline packageBin to create a JAR file
  val mappings = ....
  val pkgConfig = Pkg.Configuration(...)
  val out = Pkg(...)
  s.log.info(s"wrote $out")
  Def.declareOutput(out)
  analysisResult.hasModified() -> (out: HashedVirtualFileRef)
})
.tag(Tags.Compile, Tags.CPU)
.value,
```

使ってみると、こんな感じだ:

```scala
$ sbt
[info] welcome to sbt 2.0.0-alpha8-SNAPSHOT (Azul Systems, Inc. Java 1.8.0_352)
[info] loading project definition from hello1/project
[info] compiling 1 Scala source to hello1/target/out/jvm/scala-3.3.1/hello1-build/classes ...
[info] wrote ${OUT}/jvm/scala-3.3.1/hello1-build/hello1-build-0.1.0-SNAPSHOT-noresources.jar
....
sbt:Hello> compile
[info] compiling 1 Scala source to hello1/target/out/jvm/scala-3.3.1/hello/classes ...
[info] wrote ${OUT}/jvm/scala-3.3.1/hello/hello_3-0.1.0-SNAPSHOT-noresources.jar
[success] Total time: 3 s
sbt:Hello> clean
[success] Total time: 0 s
sbt:Hello> compile
[success] Total time: 1 s
sbt:Hello> run
[info] running example.Hello
hello
[success] Total time: 1 s
sbt:Hello> exit
[info] shutting down sbt server
```

これは `clean` で target ディレクトリごと消しても `compile` がキャッシュされていることを示す。実際には、キャッシュ化されていない依存タスクもあるので完全な no-op では無いが、1秒で終わった。sbt セッションを抜けて、`target/` を再度消して確認してみる:

```bash
$ rm -rf project/target
$ rm -rf target
$ sbt
[info] welcome to sbt 2.0.0-alpha8-SNAPSHOT (Azul Systems, Inc. Java 1.8.0_352)
....
sbt:Hello> run
[info] running example.Hello
hello
[success] Total time: 2 s, completed Dec 18, 2023 3:36:51 AM
sbt:Hello> exit
[info] shutting down sbt server
$ ls -l target/out/jvm/scala-3.3.1/hello/
total 0
drwxr-xr-x  4 xxx  staff  128 Dec 18 03:36 classes/
lrwxr-xr-x  1 xxx  staff   65 Dec 18 03:36 hello_3-0.1.0-SNAPSHOT-noresources.jar@ -> /Users/xxx/Library/Caches/sbt/v2/cas/farm64-ac08c53b3364a204
lrwxr-xr-x  1 xxx  staff   65 Dec 18 03:36 hello_3-0.1.0-SNAPSHOT.jar@ -> /Users/xxx/Library/Caches/sbt/v2/cas/farm64-b9c876a13587c8e2
```

Scala コンパイラを呼ばずに `run` を動かすことができた。ここで 2つの JAR があるのは、厳密には `compile` タスクは `src/main/resources/` のコンテンツを含まないからだ。sbt 1.x ではこの作業は `copyResources` というタスクで行われ、`products` タスクがそれを呼び出す。

タスクの粒度のトレードオフがまた出てきた。コンパイルとリソースを分ければ、ソースが変わるたびにリソースファイルをキャッシュにアップロードすることを回避することができる。一方、分けることで `product` つまり `packageBin` を呼んだときに二重でアップロードが必要となる。

#### 新しい Classpath 型

前の方でも出てきたが、sbt 1.x ではクラスパスは `Seq[Attributed[File]]` として表現される。`java.io.File` は、絶対パスを捕獲してしまうのと、コンテンツ変更に無頓着なせいでキャッシュのインプットには向いていない。sbt 2.x では `Classpath` は以下のように定義する:

```scala
type Classpath = Seq[Attributed[HashedVirtualFileRef]]
```

補足すると、`HashedVirtualFileRef` は、`fileConverter.value` で得られる `FileConverter` のインスタンスがあればいつでも `Path` に変換することができる。Scala 3 の extension メソッドを使ってクラスパスを `Seq[Path]` に変換する `files` も定義してある:

```scala
given FileConverter = fileConverter.value
val cp = (Compile / dependencyClasspath).value.files
```

### まとめ

[RFC-1: sbt cache ideas](/sbt-cache-ideas/) をもとに、[#7464][7464] は `Def.cachedTask` という自動キャッシュタスクを実装する:

```scala
someKey := Def.cachedTask {
  val output = StringVirtualFile1("a.txt", "foo")
  Def.declareOutput(output)
  name.value + version.value + "!"
}
```

これは Scala 3 マクロを用い依存タスクをキャッシュ・キーとして追跡して、アウトプットのシリアライズやデシリアライズを自動的に行う。インプットは [`sjsonnew.HashWriter`][HashWriter] という[マークル木](https://ja.wikipedia.org/wiki/%E3%83%8F%E3%83%83%E3%82%B7%E3%83%A5%E6%9C%A8)のための型クラスを満たす必要があり、結果型は [`sjsonnew.JsonFormat`][JsonFormat] を満たす必要がある。

ファイルの追跡のために sbt 2.x は主に `VirtualFile` と `HashedVirtualFileRef` という 2つの型を用いる。`VirtualFile` は、タスクが実際の読み書きを行うのに用いられ、`HashedVirtualFileRef` はキャッシュに便利なファイル参照としてクラスパス関連などのタスクに用いられる。

タスクのアウトプットとして意味のあるファイルは、`Def.declareOutput(...)` を用いて明示的に宣言される必要がある。例えば、`compile` は `*.class` ファイルも生成するかもしれないが、キャッシュには含まれない。代わりに JAR ファイルが `Def.declareOutput(...)` を用いて登録される。

この機構を試すために、[#7464][7464] は `packageBin` タスクと `compile` タスクの自動キャッシュ化を実装する。
