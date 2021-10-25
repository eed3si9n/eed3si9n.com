---
title:       "依存性解決のセマンティクス"
type:        story
date:        2019-07-29
changed:     2019-07-30
draft:       false
promote:     true
sticky:      false
url:         /ja/dependency-resolver-semantics
aliases:     [ /node/303 ]
tags:        [ "scala" ]

# Summary:
# 依存性解決のセマンティクスは、ユーザーが指定した依存性の制約から具象クラスパスを決定する。詳細の違いはバージョン衝突の解決のされ方の違いとして表れる。
# 
# - Maven は nearest-wins 戦略を取り、これは間接依存性をダウングレードすることがある。
# - Ivy は latest-wins 戦略を取る。
# - Cousier は一般的には latest-wins 戦略を取るが、バージョン範囲の計算は厳しい。
# - Ivy のバージョン範囲の処理は Internet へ出てしまうため、ビルドの再現性が落ちる。
# - Coursier のバージョン順序は Ivy と全く異なるものなので注意。
# 

---

  [ivy1]: http://ant.apache.org/ivy/history/2.3.0/ivyfile/conflicts.html
  [ivy2]: http://ant.apache.org/ivy/history/2.3.0/settings/conflict-managers.html
  [ivy3]: https://github.com/sbt/ivy/blob/2.3.0/src/java/org/apache/ivy/plugins/latest/LatestRevisionStrategy.java
  [maven1]: https://maven.apache.org/guides/introduction/introduction-to-dependency-mechanism.html
  [pronounce]: https://forvo.com/word/coursier/
  [coursier1]: https://get-coursier.io/docs/other-version-selection
  [coursier2]: https://github.com/coursier/coursier/blob/c9efac25623e836d6aea95f792bf22f147fa5915/doc/docs/other-version-handling.md
  [php1]: https://www.php.net/manual/en/function.version-compare.php
  [2959]: https://github.com/sbt/sbt/pull/2959
  [1284]: https://github.com/coursier/coursier/issues/1284

### 依存性リゾルバー

依存性リゾルバー (dependency resolver)、もしくはパッケージマネージャーは、ユーザーによって与えられた制約の集合を元に矛盾しないモジュールの集合を決定するプログラムだ。通常この制約要件はモジュール名とそれらのバージョン番号を含む。JVM エコシステムにおける Maven モジュールは organization (group id) も指定に用いられる。その他の制約として、バージョン範囲、除外モジュール、バージョンオーバーライドなどもある。

パッケージングは大まかに OS パッケージ (Homebrew、Debian packages など)、特定のプログラミング言語のモジュール (CPAN、RubyGem、Maven など)、特定のアプリケーションのためのエクステンション (Eclipse プラグイン、IntelliJ プラグイン、VS Code extensions など) の 3つのカテゴリーがある。

### 依存性解決のセマンティクス

考え始めの近似としてモジュール依存性を DAG (有向非巡回グラフ) だと考えることができる。これは依存性グラフ、もしくは "deps graph" と呼ばれる。以下のような 2つのモジュール依存性があるとする:

- `a:1.0`。これはさらに `c:1.0` に依存する。
- `b:1.0`。これはさらに `c:1.0` と `d:1.0` に依存する。

```bash
+-----+  +-----+
|a:1.0|  |b:1.0|
+--+--+  +--+--+
   |        |
   +<-------+
   |        |
   v        v
+--+--+  +--+--+
|c:1.0|  |d:1.0|
+-----+  +-----+
```

`a:1.0` と `b:1.0` に依存すると、`a:1.0`、`b:1.0`、`c:1.0`、そして `d:1.0` が得られる。これは木を歩いているだけだ。

間接依存性にバージョン範囲を含むと状況はもう少し複雑になる。

- `a:1.0`。これはさらに `c:1.0` に依存する。
- `b:1.0`。これはさらに `c:[1.0,2)` と `d:1.0` に依存する。

```bash
+-----+  +-----+
|a:1.0|  |b:1.0|
+--+--+  +--+--+
   |        |
   |        +-----------+
   |        |           |
   v        v           v
+--+--+  +--+------+ +--+--+
|c:1.0|  |c:[1.0,2)| |d:1.0|
+-----+  +---------+ +-----+
```

もしくは間接依存性が異なるバージョンに依存する:

- `a:1.0`。これはさらに `c:1.0` に依存する。
- `b:1.0`。これはさらに `c:1.2` と `d:1.2` に依存する。

もしくは依存性が排除ルールを含む:

- `a:1.0`。これはさらに `c:1.0` に依存するが、`c:*` は排除する。
- `b:1.0`。これはさらに `c:1.2` と `d:1.2` に依存する。

ユーザーが指定した制約がどのように解釈されるかというルール群は、厳密には依存性リゾルバーごとに異なる。僕はこのルール群を依存性解決の**セマンティクス**と呼んでいる。

知っておいたほうがいいかもしれないセマンティクスを以下に挙げる:

- 自分のモジュールのセマンティクス (使っているビルドツールによって決定される)
- 自分が使っているライブラリのセマンティクス (ライブラリ作者が使ったビルドツールによって決定される)
- 自分が作ったモジュールを使ったモジュールのセマンティクス (ユーザーのビルドツールによって決定される)

### JVM エコシステムにおける依存性リゾルバー

sbt のメンテナなので、自分が取り扱っているのは JVM エコシステム関連がほとんどだ。

#### Maven の nearest-wins セマンティクス

依存性の衝突 (依存性 `d` に対して deps graph 内に `d:1.0` と `d:2.0` といった複数のバージョン候補があること) が発生したとき、Maven は [nearst-wins][maven1] 戦略を用いて衝突を解決する:

> - **依存性の仲介** - これは 1つのアーティファクトに対して複数のバージョンが現れたときにどのバージョンを選ぶかを決定する。Maven は「最寄りの定義」を選ぶ。別の言い方をすると、依存性の木があるとき、それはあなたのプロジェクトに最も近い依存性のバージョンを採用する。そのため、明示的にあなたのプロジェクトの POM で宣言されたバージョンが選ばれることが保証される。ただし、依存性の木の中で 2つの依存性バージョンが同じ深さにあるときは最初のものが勝つ。
>   - 「最寄りの定義」は、依存性の木の中であなたのプロジェクトに最も近いバージョンが選ばれることを意味する。例えば、A、B、C の依存性が `A -> B -> C -> D 2.0` と `A -> E -> D 1.0` というふうに定義された場合、A をビルドするとき A から D に行く道のりでは E を通過する方が短いため D 1.0 が使われる。D 2.0 を強制するには、明示的に D 2.0 への依存性を追加する。

これは、Maven を用いて公開された多くの Java モジュールは nearest-wins セマンティクスを元に公開されていることを意味する。

検証のためにシンプルな `pom.xml` を作ってみよう:

```xml
<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
     xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
  <modelVersion>4.0.0</modelVersion>
  <groupId>com.example</groupId>
  <artifactId>foo</artifactId>
  <version>1.0.0</version>
  <packaging>jar</packaging>

   <dependencyManagement>
     <dependencies>
       <dependency>
         <groupId>com.typesafe.play</groupId>
         <artifactId>play-ws-standalone_2.12</artifactId>
         <version>1.0.1</version>
       </dependency>
     </dependencies>
   </dependencyManagement>
</project>
```

`mvn dependency:build-classpath` は解決されたクラスパスを返す。Akka 2.5.3 は間接的に `com.typesafe:config:1.3.1` に依存するにもかかわらず `com.typesafe:config:1.2.0` が返されていることに注目してほしい。

`mvn dependency:tree` はこれを視覚的に表示する:

```bash
[INFO] --- maven-dependency-plugin:2.8:tree (default-cli) @ foo ---
[INFO] com.example:foo:jar:1.0.0
[INFO] \- com.typesafe.play:play-ws-standalone_2.12:jar:1.0.1:compile
[INFO]    +- org.scala-lang:scala-library:jar:2.12.2:compile
[INFO]    +- javax.inject:javax.inject:jar:1:compile
[INFO]    +- com.typesafe:ssl-config-core_2.12:jar:0.2.2:compile
[INFO]    |  +- com.typesafe:config:jar:1.2.0:compile
[INFO]    |  \- org.scala-lang.modules:scala-parser-combinators_2.12:jar:1.0.4:compile
[INFO]    \- com.typesafe.akka:akka-stream_2.12:jar:2.5.3:compile
[INFO]       +- com.typesafe.akka:akka-actor_2.12:jar:2.5.3:compile
[INFO]       |  \- org.scala-lang.modules:scala-java8-compat_2.12:jar:0.8.0:compile
[INFO]       \- org.reactivestreams:reactive-streams:jar:1.0.0:compile
```

多くのライブラリは後方互換性を意識して書かれているが、いくつかの例外を除いては前方互換性は保証されないので、これはぞっとする。

#### Apache Ivy の latest-wins セマンティクス

Apache Ivy はデフォルトで [latest-wins][ivy1] 戦略 (正確には「latest-revision」) を使ったコンフリクトマネージャーを使って衝突の解決を行う:

> このコンテナが無い場合は、全てのモジュールに対してデフォルトのコンフリクトマネージャーが使われる。現在デフォルトのコンフリクトマネージャーは「latest-revision」コンフリクトマネージャーだ。

Apache Ivy は、sbt 1.3.x 系以前の sbt で採用されていた依存性リゾルバーだ。sbt は上記の `pom.xml` を多少簡潔に書くことができる:

```scala
ThisBuild / scalaVersion := "2.12.8"
ThisBuild / organization := "com.example"
ThisBuild / version      := "1.0.0-SNAPSHOT"

lazy val root = (project in file("."))
  .settings(
    name := "foo",
    libraryDependencies += "com.typesafe.play" %% "play-ws-standalone" % "1.0.1",
  )
```

sbt シェルに入って、`show externalDependencyClasspath` と打ち込むと解決されたクラスパスが表示される。`com.typesafe:config:1.3.1` が表示されるはずだ。さらに以下の警告が表示される。

```bash
[warn] There may be incompatibilities among your library dependencies; run 'evicted' to see detailed eviction warnings.
```

`evicted` タスクは以下の eviction report を表示する:

```bash
sbt:foo> evicted
[info] Updating ...
[info] Done updating.
[info] Here are other dependency conflicts that were resolved:
[info]  * com.typesafe:config:1.3.1 is selected over 1.2.0
[info]      +- com.typesafe.akka:akka-actor_2.12:2.5.3            (depends on 1.3.1)
[info]      +- com.typesafe:ssl-config-core_2.12:0.2.2            (depends on 1.2.0)
[info]  * com.typesafe:ssl-config-core_2.12:0.2.2 is selected over 0.2.1
[info]      +- com.typesafe.play:play-ws-standalone_2.12:1.0.1    (depends on 0.2.2)
[info]      +- com.typesafe.akka:akka-stream_2.12:2.5.3           (depends on 0.2.1)
```

latest-wins セマンティクスにおいては、`config:1.2.0` を指定することは実質的に「1.2.0 かそれ以上のものをくれ」と言っていることと同じだ。これは間接的依存性が勝手にダウングレードされないため nearest-wins に比較すると多少マシな振る舞いだと思うが、`evicted` タスクを実行して依存性の退去が正しいものかを確認するべきだ。

#### Coursier の latest-wins セマンティクス

Coursier の依存性リゾルバーセマンティクスについて考察する前に、発音に関して少し。[コース・イェ][pronounce]っぽい感じになるらしい。

Coursier が良いのはドキュメンテーションに [version reconciliation][coursier1] というページがあって、依存性解決のセマンティクスについて書かれている。

> - 入力された区間の交叉を取る。これが空 (区間が交差しない) の場合、衝突となる。入力に区間が無い場合は交差区間を `(,)` (全てのバージョンにマッチする区間) とする。
> - 次に、特定のバージョンを見ていく:
>   - 区間に満たない特定バージョンは無視する。
>   - 区間を超えた特定バージョンがある場合は、衝突となる。
>   - 区間内に入る特定バージョンがある場合は、最も高い値を取って結果とする。
>   - 区間内もしくは区間を越える特定バージョンが無い場合は、区間を取って結果とする。

「最も高い値を取って」という表現があるので、これは latest-wins セマンティクスだ。内部で Coursier を使う sbt 1.3.0-RC3 を使ってこれを検証してみよう。

```scala
ThisBuild / scalaVersion := "2.12.8"
ThisBuild / organization := "com.example"
ThisBuild / version      := "1.0.0-SNAPSHOT"

lazy val root = (project in file("."))
  .settings(
    name := "foo",
    libraryDependencies += "com.typesafe.play" %% "play-ws-standalone" % "1.0.1",
  )
```

sbt シェルから `show externalDependencyClasspath` を実行すると、期待通り `com.typesafe:config:1.3.1` が返ってくる。`evicted` レポートも同じものだ:

```bash
sbt:foo> evicted
[info] Here are other dependency conflicts that were resolved:
[info]  * com.typesafe:config:1.3.1 is selected over 1.2.0
[info]      +- com.typesafe.akka:akka-actor_2.12:2.5.3            (depends on 1.3.1)
[info]      +- com.typesafe:ssl-config-core_2.12:0.2.2            (depends on 1.2.0)
[info]  * com.typesafe:ssl-config-core_2.12:0.2.2 is selected over 0.2.1
[info]      +- com.typesafe.play:play-ws-standalone_2.12:1.0.1    (depends on 0.2.2)
[info]      +- com.typesafe.akka:akka-stream_2.12:2.5.3           (depends on 0.2.1)
```

#### 余談: Apache Ivy の nearest-wins セマンティクスのエミュレーション?

Ivy が Maven リポジトリからモジュールを解決するとき、POM ファイルを `ivy.xml` へと変換して Ivy キャッシュに入れるが、そのとき `force="true"` という属性が使われる。例えば、`cat ~/.ivy2/cache/com.typesafe.akka/akka-actor_2.12/ivy-2.5.3.xml` を見てほしい:

```xml
  <dependencies>
    <dependency org="org.scala-lang" name="scala-library" rev="2.12.2" force="true" conf="compile->compile(*),master(compile);runtime->runtime(*)"/>
    <dependency org="com.typesafe" name="config" rev="1.3.1" force="true" conf="compile->compile(*),master(compile);runtime->runtime(*)"/>
    <dependency org="org.scala-lang.modules" name="scala-java8-compat_2.12" rev="0.8.0" force="true" conf="compile->compile(*),master(compile);runtime->runtime(*)"/>
  </dependencies>
...
```
Ivy の[ドキュメンテーション][ivy2]によると:

> 2つの latest系のコンフリクトマネージャーは依存性の force 属性も勘案に入れる。直接依存性は force 属性を宣言することで、間接依存性よりも直接依存性で与えられたリビジョンを優先すべきであることを合図できる。

僕の読みとしては、`force="true"` は latest-wins のロジックをオーバーライドして nearest-wins セマンティクスをエミュレートしようとしているんだと思うが、幸いなことにこれは失敗に終わり、sbt 1.2.8 が `com.typesafe:config:1.3.1` 返すことで検証できたように latest-wins セマンティクスとなっている。

`force="true"` の効果は、壊れている _strict_ コンフリクトマネージャーを使うと観測することができる。

```scala
ThisBuild / conflictManager := ConflictManager.strict
```

問題は strict コンフリクトマネージャーは退去 (eviction) を防止できていないことだ。`show externalDependencyClasspath` はお気楽に `com.typesafe:config:1.3.1` を返してくる。関連する問題として、strict コンフリクトマネージャーが解決したはずの `com.typesafe:config:1.3.1` をグラフに追加すると失敗する。

```scala
ThisBuild / scalaVersion    := "2.12.8"
ThisBuild / organization    := "com.example"
ThisBuild / version         := "1.0.0-SNAPSHOT"
ThisBuild / conflictManager := ConflictManager.strict

lazy val root = (project in file("."))
  .settings(
    name := "foo",
    libraryDependencies ++= List(
      "com.typesafe.play" %% "play-ws-standalone" % "1.0.1",
      "com.typesafe" % "config" % "1.3.1",
    )
  )
```

以下のようになる:

```bash
sbt:foo> show externalDependencyClasspath
[info] Updating ...
[error] com.typesafe#config;1.2.0 (needed by [com.typesafe#ssl-config-core_2.12;0.2.2]) conflicts with com.typesafe#config;1.3.1 (needed by [com.example#foo_2.12;1.0.0-SNAPSHOT])
[error] org.apache.ivy.plugins.conflict.StrictConflictException: com.typesafe#config;1.2.0 (needed by [com.typesafe#ssl-config-core_2.12;0.2.2]) conflicts with com.typesafe#config;1.3.1 (needed by [com.example#foo_2.12;1.0.0-SNAPSHOT])
```

### バージョンの順序

latest-wins セマンティクスが何回か出てきているが、これは 2つのバージョン文字列があるときそれらが何らか方法で順列付けできることを示唆する。そのため、バージョンの順序もセマンティクスの一部だと考えるべきである。

#### Apache Ivy のバージョン順序

ある [Javadoc コメント][ivy3] によると、Ivy の comparator は PHP の [version_compare][php1] を元にしているらしい:

> この関数はまずバージョン文字列に出てくる `_`、`-`、`+` をドット `.` で置き換え、非数字の前にもドット `.` を挿入して、例えば '4.3.2RC1' は '4.3.2.RC.1' となる。次に、パーツごとに左から右へと比較する。もし、パーツが特殊なパージョン文字列を含む場合は、以下の順序を用いて比較する: *このリストに含まれない全ての文字列 < dev < alpha = a < beta = b < RC = rc < # < pl = p*。これによって、'4.1' と '4.1.2' のように異なるレベルを持つバージョンが比較できるだけではなく、PHP に特定の開発状態を含むバージョンも比較できる。

バージョンの順序は小さな関数を書くことで検証できる。

```scala
scala> :paste
// Entering paste mode (ctrl-D to finish)

val strategy = new org.apache.ivy.plugins.latest.LatestRevisionStrategy
case class MockArtifactInfo(version: String) extends
    org.apache.ivy.plugins.latest.ArtifactInfo {
  def getRevision: String = version
  def getLastModified: Long = -1
}
def sortVersionsIvy(versions: String*): List[String] = {
  import scala.collection.JavaConverters._
  strategy.sort(versions.toArray map MockArtifactInfo)
    .asScala.toList map { case MockArtifactInfo(v) => v }
}

// Exiting paste mode, now interpreting.

scala> sortVersionsIvy("1.0", "2.0", "1.0-alpha", "1.0+alpha", "1.0-X1", "1.0a", "2.0.2")
res7: List[String] = List(1.0-X1, 1.0a, 1.0-alpha, 1.0+alpha, 1.0, 2.0, 2.0.2)
```

#### Coursier のバージョン順序

解決セマンティクスのページの [GitHub][coursier2] 版はバージョン順序を解説した節がある。

> Coursier のバージョン順序は Maven のそれに準拠する。
>
> 比較するために、バージョンは「アイテム」に分割される。(中略)
>
> アイテムを得るためには、バージョンは `.`、`-`、`_` で分割され (それらのセパレーターはその後無視される)、文字から数字、数字から文字への切り替え点でも分割される。

検証するためには `libraryDependencies += "io.get-coursier" %% "coursier-core" % "2.0.0-RC2-6"` を含むサブプロジェクトを作って、`console` を走らせる:

```scala

sbt:foo> helper/console
[info] Starting scala interpreter...
Welcome to Scala 2.12.8 (OpenJDK 64-Bit Server VM, Java 1.8.0_212).
Type in expressions for evaluation. Or try :help.

scala> import coursier.core.Version
import coursier.core.Version

scala> def sortVersionsCoursier(versions: String*): List[String] =
     |   versions.toList.map(Version.apply).sorted.map(_.repr)
sortVersionsCoursier: (versions: String*)List[String]

scala> sortVersionsCoursier("1.0", "2.0", "1.0-alpha", "1.0+alpha", "1.0-X1", "1.0a", "2.0.2")
res0: List[String] = List(1.0-alpha, 1.0, 1.0-X1, 1.0+alpha, 1.0a, 2.0, 2.0.2)
```

驚くべきことに、Coursier は Ivy とは完全に異なる方法でバージョンを順序付けする。

これまで、比較的寛容なタグ文字の処理に乗っかってきてた場合は、今後混乱を招くかもしれない。

### バージョンの範囲

僕はバージョンの範囲は通常避けるようにしているけども、webjars という npm モジュールを Maven Central に公開しなおしたものでよく使われているみたいだ。npm モジュールだと `"is-number": "^4.0.0"` というような表現が出てきて、これは `[4.0.0,5)` に翻訳される。

#### Apache Ivy のバージョン範囲処理

以下のビルドにおいて、`angular-boostrap:0.14.2` は `angular:[1.3.0,)` に依存する。

```scala
ThisBuild / scalaVersion  := "2.12.8"
ThisBuild / organization  := "com.example"
ThisBuild / version       := "1.0.0-SNAPSHOT"

lazy val root = (project in file("."))
  .settings(
    name := "foo",
    libraryDependencies ++= List(
      "org.webjars.bower" % "angular" % "1.4.7",
      "org.webjars.bower" % "angular-bootstrap" % "0.14.2",
    )
  )
```

sbt 1.2.8 使うと、`show externalDependencyClasspath` は `angular-bootstrap:0.14.2` と angular:1.7.8` を返す。`1.7.8` なんて一体どこから出てきたのだろう? Ivy はバージョンの範囲を見つけると Internet へと飛び出して、スクリーンスクレイピングをやったりしながら探せるものは何でも持ってくる。

これはビルドを非再現的 (non-repeatable) にする。数ヶ月おきにビルドを走らせると、そのたびに異なる結果となる。

#### Coursier のバージョン範囲処理

Coursier の解決セマンティクスのページの [GitHub][coursier2] 版によると:

> #### 区間内の特定バージョンの優先
>
> `[1.0,2.0)` と `1.4` に依存した場合、バージョン解決は `1.4` という結果を出す。`1.4` という依存性があるため、これは `[1.0,2.0)` よりも優先される。

これは期待できるかもしれない。

```bash
sbt:foo> show externalDependencyClasspath
[warn] There may be incompatibilities among your library dependencies; run 'evicted' to see detailed eviction warnings.
[info] * Attributed(/Users/eed3si9n/.sbt/boot/scala-2.12.8/lib/scala-library.jar)
[info] * Attributed(/Users/eed3si9n/.coursier/cache/v1/https/repo1.maven.org/maven2/org/webjars/bower/angular/1.4.7/angular-1.4.7.jar)
[info] * Attributed(/Users/eed3si9n/.coursier/cache/v1/https/repo1.maven.org/maven2/org/webjars/bower/angular-bootstrap/0.14.2/angular-bootstrap-0.14.2.jar)
```

`angular-bootstrap:0.14.2` がある同一のビルドを用いて検証すると、`show externalDependencyClasspath` は期待通り `angular-bootstrap:0.14.2` と `angular:1.4.7` を返す。これは Ivy に対する改善と言える。

バージョン範囲が重なり合わない場合はちょっと微妙な感じになる。以下に具体例を挙げる:

```scala
ThisBuild / scalaVersion  := "2.12.8"
ThisBuild / organization  := "com.example"
ThisBuild / version       := "1.0.0-SNAPSHOT"

lazy val root = (project in file("."))
  .settings(
    name := "foo",
    libraryDependencies ++= List(
      "org.webjars.npm" % "randomatic" % "1.1.7",
      "org.webjars.npm" % "is-odd" % "2.0.0",
    )
  )
```

sbt 1.3.0-RC3 を使うと、`show externalDependencyClasspath` はエラーをなる:

```bash
sbt:foo> show externalDependencyClasspath
[info] Updating
https://repo1.maven.org/maven2/org/webjars/npm/kind-of/maven-metadata.xml
  No new update since 2018-03-10 06:32:27
https://repo1.maven.org/maven2/org/webjars/npm/is-number/maven-metadata.xml
  No new update since 2018-03-09 15:25:26
https://repo1.maven.org/maven2/org/webjars/npm/is-buffer/maven-metadata.xml
  No new update since 2018-08-17 14:21:46
[info] Resolved  dependencies
[error] lmcoursier.internal.shaded.coursier.error.ResolutionError$ConflictingDependencies: Conflicting dependencies:
[error] org.webjars.npm:is-number:[3.0.0,4):default(compile)
[error] org.webjars.npm:is-number:[4.0.0,5):default(compile)
[error]   at lmcoursier.internal.shaded.coursier.Resolve$.validate(Resolve.scala:394)
[error]   at lmcoursier.internal.shaded.coursier.Resolve.validate0$1(Resolve.scala:140)
[error]   at lmcoursier.internal.shaded.coursier.Resolve.$anonfun$ioWithConflicts0$4(Resolve.scala:184)
[error]   at lmcoursier.internal.shaded.coursier.util.Task$.$anonfun$flatMap$2(Task.scala:14)
[error]   at scala.concurrent.Future.$anonfun$flatMap$1(Future.scala:307)
[error]   at scala.concurrent.impl.Promise.$anonfun$transformWith$1(Promise.scala:41)
[error]   at scala.concurrent.impl.CallbackRunnable.run(Promise.scala:64)
[error]   at java.util.concurrent.ThreadPoolExecutor.runWorker(ThreadPoolExecutor.java:1149)
[error]   at java.util.concurrent.ThreadPoolExecutor$Worker.run(ThreadPoolExecutor.java:624)
[error]   at java.lang.Thread.run(Thread.java:748)
[error] (update) lmcoursier.internal.shaded.coursier.error.ResolutionError$ConflictingDependencies: Conflicting dependencies:
[error] org.webjars.npm:is-number:[3.0.0,4):default(compile)
[error] org.webjars.npm:is-number:[4.0.0,5):default(compile)
```

これは範囲が重なり合わないため、厳密には正しい。sbt 1.2.8 ならば `is-number:4.0.0` に解決してくれる。

バージョン範囲は、失敗すると面倒な程度の頻度では出てくるので、Coursier に追加で latest-wins のルールを追加してバージョン範囲の下限値の最大値を取れるようにした pull request を出している。[coursier/coursier#1284][1284] 参照。

### まとめ

依存性解決のセマンティクスは、ユーザーが指定した依存性の制約から具象クラスパスを決定する。詳細の違いはバージョン衝突の解決のされ方の違いとして表れる。

- Maven は nearest-wins 戦略を取り、これは間接依存性をダウングレードすることがある。
- Ivy は latest-wins 戦略を取る。
- Cousier は一般的には latest-wins 戦略を取るが、バージョン範囲の計算は厳しい。
- Ivy のバージョン範囲の処理は Internet へ出てしまうため、ビルドの再現性が落ちる。
- Coursier のバージョン順序は Ivy と全く異なるものなので注意。
