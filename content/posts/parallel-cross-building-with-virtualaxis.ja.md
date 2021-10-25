---
title:       "VirtualAxis を用いた並列クロスビルド"
type:        story
date:        2019-11-04
draft:       false
promote:     true
sticky:      false
url:         /ja/parallel-cross-building-with-virtualaxis
aliases:     [ /node/311 ]
---

[sbt-projectmatrix](https://github.com/sbt/sbt-projectmatrix/) は sbt のクロスビルドを改善するために、僕が実験として作っているプラグインで、本稿は[前篇](http://eed3si9n.com/ja/parallel-cross-building-using-sbt-projectmatrix)に続く第2弾だ。0.4.0 をリリースしたのでここで紹介する。

### おさらい: 複数の Scala バージョンに対するビルド

sbt-projectmatrix をビルドに追加後、以下のようにして 2つの Scala バージョンを使ったマトリックスをセットアップする。

```scala
ThisBuild / organization := "com.example"
ThisBuild / scalaVersion := "2.12.10"
ThisBuild / version      := "0.1.0-SNAPSHOT"

lazy val core = (projectMatrix in file("core"))
  .settings(
    name := "core"
  )
  .jvmPlatform(scalaVersions = Seq("2.12.10", "2.11.12"))
```

これは `coreJVM2_11` と `coreJVM2_12` というサブプロジェクトを作る。 `++` スタイルのステートフルなクロスビルドと違って、これは並列にビルドする。これは変わっていない。

前篇ではこの考え方をクロス・プラットフォームやクロス・ライブラリへと応用させることを考えた。

### 0.2.0 の問題

[Support for mixed-style matrix dependencies #13](https://github.com/sbt/sbt-projectmatrix/issues/13) と [Support for pure Java subprojects #14](https://github.com/sbt/sbt-projectmatrix/issues/14) という 2つの issue が立てられて、0.2.0 の設計に限界があることに気づいた。0.2.0 は各列は以下のように表現される:

```scala
final class ProjectRow(
    val idSuffix: String,
    val directorySuffix: String,
    val scalaVersions: Seq[String],
    val process: Project => Project
) {}
```

これは、列が追跡できるもの (例えばプラットフォーム) を 1つの次元とプラスで特定の Scala バージョンに限定する。報告された issue はマトリックス内の列を別のマトリックス内の列へと少し弱めた制限を用いて関連付けようとしていると意味で同じ問題の変種であると言える。

### VirtualAxis

sbt-projectmatrix 0.4.0 は `VirtualAxis` を導入するが、最初はこれが何かを理解しなくても sbt-projectmatrix 自体は使い始めることができる。

```scala
/** A row in the project matrix, typically representing a platform + Scala version.
 */
final class ProjectRow(
    val autoScalaLibrary: Boolean,
    val axisValues: Seq[VirtualAxis],
    val process: Project => Project
)

/** Virtual Axis represents a parameter to a project matrix row. */
sealed abstract class VirtualAxis {
  def directorySuffix: String

  def idSuffix: String

  /* The order to sort the suffixes if there were multiple axes. */
  def suffixOrder: Int = 50
}

object VirtualAxis {
  /**
   * WeakAxis allows a row to depend on another row with Zero value.
   * For example, Scala version can be Zero for Java project, and it's ok.
   */
  abstract class WeakAxis extends VirtualAxis

  /** StrongAxis requires a row to depend on another row with the same selected value. */
  abstract class StrongAxis extends VirtualAxis
  
  ....
}
```

`ProjectRow` は `VirtualAxis` の集合となった。`VirtualAxis` の典型的な使いみちはプラットフォーム (JVM, JS, Native) や Scala バージョンを表すのに使う。`VirtualAxis` クラスは `WeakAxis` と `StrongAxis` という 2つのサブクラスに分かれる。

`StrongAxis` は関連する列が同値を持つことを要請し、これはプラットフォームなどを表すのに便利だ。一方、`WeakAxis` は同じ値または全く値を持たないことを許容する。Scala バージョンはその 1例だ。

```scala
lazy val intf = (projectMatrix in file("intf"))
  .jvmPlatform(autoScalaLibrary = false)

lazy val core = (projectMatrix in file("core"))
  .dependsOn(intf)
  .jvmPlatform(scalaVersions = Seq("2.12.10", "2.11.12"))
```

上の例では `core` マトリックスは Scala バージョン 2.12.10 と 2.11.12 に対応する 2つの JVM 列を持つ。`ScalaVersionAxis` は `WeakAxis` であるため、Scala バージョンを持たない `intf` マトリックスの JVM 列に依存することができる。

### 並列クロスライブラリビルド

並列クロスライブラリビルドもカスタム `VirtualAxis` を定義することで実装できる。`project/LightbendConfigAxis.scala` 内に以下を書く:

```scala
import sbt._

case class LightbendConfigAxis(idSuffix: String, directorySuffix: String) extends VirtualAxis.WeakAxis {
}
```

次に `build.sbt`:

```scala
ThisBuild / organization := "com.example"
ThisBuild / version := "0.1.0-SNAPSHOT"

lazy val config12 = LightbendConfigAxis("Config1_2", "config1.2")
lazy val config13 = LightbendConfigAxis("Config1_3", "config1.3")

lazy val scala212 = "2.12.10"
lazy val scala211 = "2.11.12"

lazy val app = (projectMatrix in file("app"))
  .settings(
    name := "app"
  )
  .customRow(
    scalaVersions = Seq(scala212, scala211),
    axisValues = Seq(config12, VirtualAxis.jvm),
    settings = Seq(
      moduleName := name.value + "_config1.2",
      libraryDependencies += "com.typesafe" % "config" % "1.2.1",
    )
  )
  .customRow(
    scalaVersions = Seq(scala212, scala211),
    axisValues = Seq(config13, VirtualAxis.jvm),
    settings = Seq(
      moduleName := name.value + "_config1.3",
      libraryDependencies += "com.typesafe" % "config" % "1.3.3",
    )
  )
```

`LightbendConfigAxis` は `VirtualAxis.WeakAxis` を継承することに注目してほしい。これによって、`app` マトリックスは `LightbendConfigAxis` を持たない他のマトリックスにも依存することができる。

### 生成されたサブプロジェクトの参照

サブプロジェクトを `build.sbt` 内で参照したい場合は、以下のようにする:

```scala
lazy val core212 = core.jvm("2.12.10")

lazy val appConfig12_212 = app.finder(config13, VirtualAxis.jvm)("2.12.10")
  .settings(
    publishMavenStyle := true
  )
```

### Scala Native サポート

Tatsuno さん ([@exoego](https://github.com/exoego)) のお蔭で、sbt-projectmatrix は 0.3.0 から Scala.JS も Scala Native にも対応している。これを使うには別に sbt-scala-native もセットアップする必要がある:

```scala
lazy val core = (projectMatrix in file("core"))
  .settings(
    name := "core",
    Compile / run mainClass := Some("a.CoreMain")
  )
  .nativePlatform(scalaVersions = Seq("2.11.12"))
```

### まとめ

- sbt-projectmatrix を使うことで複数の Scala バージョンや JVM/JS/Native クロスプラットフォームの並列ビルドを行うことができる。
- `VirtualAxis` は、Scala-Java 間の依存やカスタムのクロスライブラリといったより柔軟なマトリックス間依存を可能とする。
