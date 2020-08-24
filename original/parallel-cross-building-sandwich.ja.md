[sbt-projectmatrix](https://github.com/sbt/sbt-projectmatrix/) は sbt のクロスビルドを改善するために、僕が実験として作っているプラグインで、本稿は[第1回](http://eed3si9n.com/ja/parallel-cross-building-using-sbt-projectmatrix)、[第2回](http://eed3si9n.com/ja/parallel-cross-building-with-virtualaxis)、[第3回](http://eed3si9n.com/parallel-cross-building-part3)に続く第4弾だ。0.6.0 をリリースしたのでここで紹介する。

### おさらい: 複数の Scala バージョンに対するビルド

sbt-projectmatrix をビルドに追加後、以下のようにして 2つの Scala バージョンを使ったマトリックスをセットアップする。

<scala>
ThisBuild / organization := "com.example"
ThisBuild / scalaVersion := "2.12.10"
ThisBuild / version      := "0.1.0-SNAPSHOT"

lazy val core = (projectMatrix in file("core"))
  .settings(
    name := "core"
  )
  .jvmPlatform(scalaVersions = Seq("2.12.10", "2.11.12"))
</scala>

これはそれぞれの `scalaVersion` にサプブロジェクトを作る。 `++` スタイルのステートフルなクロスビルドと違って、これは並列にビルドする。これは変わっていない。

前回では `%` を使って依存性をスコープ付けできることを紹介した。

### 0.6.0 での新機能: よりシンプルなプロジェクトID

`JVM2_13` というサフィックスを追加する代わりに、sbt-projectmatrix 0.6.0 より `JVM` 軸と `2_13` 軸はデフォルトとして、`coreJVM2_13` でなはく普通に `core` とか `util` という名前のサブプロジェクトを生成することにした。

### 0.6.0 での新機能: 2.13-3.0 サンドイッチのサポート

Scala 3.0 は組み込みで Scala 2.13.x に対するインターオペラビリティを持ち、2.13.x ブランチでも最近になって [TASTy reader](https://github.com/scala/scala/pull/9109) という Scala 3.0 インターオペラビリティ機能が追加された。詳細は省くとして、これを用いて 1つのサブプロジェクトは Dotty 別のサプブロジェクトは 2.13 を使うといったことが可能となる。

sbt-projectmatrix 0.6.0 はサプブロジェクトのマトリックスを複数作って、2.13-3.0 サンドイッチが必要ならば自動的に検知して配線できるようにした:

<scala>
val scala212 = "2.12.12"
// TODO use 2.13.4 when it's out
val scala213 = "2.13.4-bin-aeee8f0"
val dottyVersion = "0.23.0"
ThisBuild / resolvers += "scala-integration" at "https://scala-ci.typesafe.com/artifactory/scala-integration/"


lazy val fooApp = (projectMatrix in file("foo-app"))
  .dependsOn(fooCore)
  .settings(
    name := "foo app",
  )
  .jvmPlatform(scalaVersions = Seq(dottyVersion))

lazy val fooCore = (projectMatrix in file("foo-core"))
  .settings(
    name := "foo core",
  )
  .jvmPlatform(scalaVersions = Seq(scala213, scala212))

lazy val barApp = (projectMatrix in file("bar-app"))
  .dependsOn(barCore)
  .settings(
    name := "bar app",
  )
  .jvmPlatform(scalaVersions = Seq(scala213))

lazy val barCore = (projectMatrix in file("bar-core"))
  .settings(
    name := "bar core",
  )
  .jvmPlatform(scalaVersions = Seq(dottyVersion))
</scala>

これは [sbt/sbt#5767](https://github.com/sbt/sbt/pull/5767) をバックポートするため、sbt 1.2 移行から 2.13-3.0 サンドイッチ機能が使えるようになる。

### まとめ

- sbt-projectmatrix を使うことで複数の Scala バージョンや JVM/JS/Native クロスプラットフォームの並列ビルドを行うことができる。
- sbt-projectmatrix 0.6.0 は簡潔なプロジェクト ID を生成する。
- sbt-projectmatrix 0.6.0 はビルド内での Scala 2.13-3.0 インターオペラビリティを可能とする。
