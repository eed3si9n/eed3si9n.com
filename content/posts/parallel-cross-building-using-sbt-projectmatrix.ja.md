---
title:       "sbt-projectmatrix を用いた並列クロスビルド"
type:        story
date:        2019-05-10
draft:       false
promote:     true
sticky:      false
url:         /ja/parallel-cross-building-using-sbt-projectmatrix
aliases:     [ /node/299 ]
tags:        [ "sbt" ]
---

去年 sbt のクロスビルドを改善するために、[sbt-projectmatrix](https://github.com/sbt/sbt-projectmatrix/)  という実験的プラグインを書いた。0.2.0 をリリースしたのでここで紹介する。

### 複数の Scala バージョンに対するビルド

sbt-projectmatrix をビルドに追加後、以下のようにして 2つの Scala バージョンを使ったマトリックスをセットアップする。

```scala
ThisBuild / organization := "com.example"
ThisBuild / scalaVersion := "2.12.8"
ThisBuild / version      := "0.1.0-SNAPSHOT"

lazy val core = (projectMatrix in file("core"))
  .settings(
    name := "core"
  )
  .jvmPlatform(scalaVersions = Seq("2.12.8", "2.11.12"))
```

これは `coreJVM2_11` と `coreJVM2_12` というサブプロジェクトを作る。
`++` スタイルのステートフルなクロスビルドと違って、これは並列にビルドする。

### 2つのマトリックス

1つ以上のマトリックスがあると面白くなる。

```scala
ThisBuild / organization := "com.example"
ThisBuild / scalaVersion := "2.12.8"
ThisBuild / version      := "0.1.0-SNAPSHOT"

// uncomment if you want root
// lazy val root = (project in file("."))
//   .aggregate(core.projectRefs ++ app.projectRefs: _*)
//   .settings(
//   )

lazy val core = (projectMatrix in file("core"))
  .settings(
    name := "core"
  )
  .jvmPlatform(scalaVersions = Seq("2.12.8", "2.11.12"))

lazy val app = (projectMatrix in file("app"))
  .dependsOn(core)
  .settings(
    name := "app"
  )
  .jvmPlatform(scalaVersions = Seq("2.12.8"))
```

この例では `core` は Scala 2.11 と 2.12 に対してビルドするが、`app` はそのうちの 1つのみ対応している。

### Scala.js サポート

Tatsuno さん ([@exoego](https://github.com/exoego)) のお蔭で sbt-projectmatrix 0.2.0 から Scala.js にも対応するようになった。
この機能を使うには、sbt-scalajs も事前にセットアップする必要がある。

```scala
lazy val core = (projectMatrix in file("core"))
  .settings(
    name := "core"
  )
  .jsPlatform(scalaVersions = Seq("2.12.8", "2.11.12"))
```

これは、`coreJS2_11` と `coreJS2_12` を作成する。

### 並列クロスライブラリビルド

列を使って、並列クロスライブラリビルドを行うことも可能だ。
例えば、Config 1.2 と Config 1.3 向けのビルドを作りたいとする。

```scala
ThisBuild / organization := "com.example"
ThisBuild / version := "0.1.0-SNAPSHOT"

lazy val core = (projectMatrix in file("core"))
  .settings(
    name := "core"
  )
  .crossLibrary(
    scalaVersions = Seq("2.12.8", "2.11.12"),
    suffix = "Config1.2",
    settings = Seq(
      libraryDependencies += "com.typesafe" % "config" % "1.2.1"
    )
  )
  .crossLibrary(
    scalaVersions = Seq("2.12.8"),
    suffix = "Config1.3",
    settings = Seq(
      libraryDependencies += "com.typesafe" % "config" % "1.3.3"
    )
  )
```

これは `coreConfig1_22_11`、 `coreConfig1_22_12`、 `coreConfig1_32_12` という 3つのサブプロジェクトを作って、それぞれ `core_config1.3_2.12`、 `core_config1.2_2.11`、 `core_config1.2_2.12` というアーティファクトを生成する。

### 生成されたサブプロジェクトの参照

サブプロジェクトを build.sbt 内で参照したい場合は、以下のようにする。

```scala
lazy val core12 = core.crossLib("Config1.2")("2.12.8")
```

上記では `core12` は `Project` 型を返す。

### クレジット

- 前述のとおり、Scala.js サポートは Tatsuno さん ([@exoego](https://github.com/exoego)) にコントリしていただいた。
- サブプロジェクトを使ったクロスビルドというアイディアは Scala.js プラグインにおける Tobias Schlatter 氏の仕事で開拓され、これは [ sbt-crossproject](https://github.com/portable-scala/sbt-crossproject) へと発展した。しかし、これはプラットフォーム (JVM, JS, Native) のクロスビルドに限定されている。
- 2015年に Paul Draper 氏が書いた [sbt-cross](https://github.com/lucidsoftware/sbt-cross) は複数の Scala バージョンのクロスビルドを行う。
