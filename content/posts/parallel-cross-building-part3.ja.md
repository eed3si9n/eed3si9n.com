---
title:       "並列クロスビルド、パート3"
type:        story
date:        2020-04-13
draft:       false
promote:     true
sticky:      false
url:         /ja/parallel-cross-building-part3
aliases:     [ /node/326 ]
tags:        [ "sbt" ]
---

[sbt-projectmatrix](https://github.com/sbt/sbt-projectmatrix/) は sbt のクロスビルドを改善するために、僕が実験として作っているプラグインで、本稿は[前々回](http://eed3si9n.com/ja/parallel-cross-building-using-sbt-projectmatrix)、[前回](http://eed3si9n.com/ja/parallel-cross-building-with-virtualaxis)に続く第3弾だ。0.5.0 をリリースしたのでここで紹介する。

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

前回では列で複数の次元を表現できる VirtualAxis を紹介した。

### 0.5.0 での新機能

0.4.0 は結構いい線いっていたが、実際に使ってみると不便な点があった。まずは `%` 構文が無いことだ。

サブプロジェクト間で `Test` コンフィギュレーションからだけ依存したり、`Compile` 同士、`Test` 同士で依存するというのは良くあることだ。0.5.0 は `%` を追加してこれを可能とする。

```scala
lazy val app = (projectMatrix in file("app"))
  .dependsOn(core % "compile->compile;test->test")
  .settings(
    name := "app"
  )
  .jvmPlatform(scalaVersions = Seq("2.12.10"))

lazy val core = (projectMatrix in file("core"))
  .settings(
    name := "core"
  )
  .jvmPlatform(scalaVersions = Seq("2.12.10", "2.13.1"))
```

`Project` にある機能の一つとして `.configure(...)` メソッドというものがある。これは `Project => Project` 関数の可変長引数を受け取り、順次適用するだけのものだ。僕が取り扱っているビルドにこれがたまに出てくるので `.configure(...)` があると `Project` から `ProjectMatrix` に移植しやすくなる。

### zincApiInfo の例

Zinc のビルドから抜粋してみる:

```scala
lazy val compilerInterface = (projectMatrix in internalPath / "compiler-interface")
  .enablePlugins(ContrabandPlugin)
  .settings(
    minimalSettings,
    name := "Compiler Interface",
    exportJars := true,
    crossPaths := false,
  )
  .jvmPlatform(autoScalaLibrary = false)
  .configure(addSbtUtilInterface)

lazy val zincApiInfo = (projectMatrix in internalPath / "zinc-apiinfo")
  .dependsOn(compilerInterface, compilerBridge, zincClassfile % "compile;test->test")
  .settings(
    name := "zinc ApiInfo",
    compilerVersionDependentScalacOptions,
    mimaSettings,
  )
  .jvmPlatform(scalaVersions = List(scala212, scala213))
  .configure(addBaseSettingsAndTestDeps)
```

上の例では `compilerInterface` と `zincApiInfo` は両方ともマトリックスだ。`compilerInterface` は Java のみのマトリックスの例で、`zincApiInfo` は複数の Scala バージョンを持つ Scala プロジェクトの例だ。

従来のマルチプロジェクトのセットアップと違ってこれは各 Scala バージョンごとにサププロジェクトを作成し、`++` を一切使わずに複雑なプロジェクト間の依存性を表現することができる。

### まとめ

- sbt-projectmatrix を使うことで複数の Scala バージョンや JVM/JS/Native クロスプラットフォームの並列ビルドを行うことができる。
- sbt-projectmatrix 0.5.0 はマトリックス間の依存性のための `%` をサポートする。
