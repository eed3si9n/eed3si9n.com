---
title:       "sbt-sidedish を使ったアプリのダウンロードと実行"
type:        story
date:        2017-03-27
draft:       false
promote:     true
sticky:      false
url:         /ja/sbt-sidedish
aliases:     [ /node/219 ]
---

  [@shanedelmore]: https://twitter.com/shanedelmore
  [app]: https://github.com/eed3si9n/sbt-rewritedemo/blob/225e207e1619eafb56e5ff22add60ebca8f9a8c1/app/src/main/scala/RewriteApp.scala

sbt プラグインから JAR をダウンロードしてそれを実行したいという要望が出てきてる。
最近だと Brooklyn での nescala で Shane Delmore ([@shanedelmore][@shanedelmore]) さんに聞かれた。

アンカンファレンスのセッションでデモっぽいものをやっつけで作ったけども、家に帰ってからも色々いじったのでここに報告する。

### sbt-sidedish

sbt-sidedish はアプリをサイドメニュー的に落としてきて実行するためのプラグイン作者のためのツールキットだ。それそのものは特にプラグインを定義しない。

### rewritedemo、コマンドラインアプリ

サイドで走らせたいアプリを作る。これは Scala 2.11 や 2.12 を使ってもいい。
Scalafix を使って import 文を追加する[デモアプリ][app]を書いた。Scalafix は Scala コードの書き換えツールとライブラリで scala.meta を使っている。詳細は Scalafix のドキュメンテーションとソースを参照。

### sbt-rewritedemo、sbt プラグイン

次に、rewritedemo アプリをあるサブプロジェクト相手に実行して別のサブプロジェクトを導出したいとする。
sbt-sidedish を使って以下のようなプラグインが書ける。

```scala
package sbtrewritedemo

import sbt._
import Keys._
import sbtsidedish.Sidedish

object RewriteDemoPlugin extends AutoPlugin {
  override def requires = sbt.plugins.JvmPlugin

  object autoImport extends RewriteDemoKeys
  import autoImport._

  val sidedish = Sidedish("sbtrewritedemo-metatool",
    file("sbtrewritedemo-metatool"),
    // scalaVersion
    "2.12.1",
    // ModuleID of your app
    List("com.eed3si9n" %% "rewritedemo" % "0.1.2"),
    // main class
    "sbtrewritedemo.RewriteApp")

  override def extraProjects: Seq[Project] =
    List(sidedish.project
      // extra settings
      .settings(
        // Resolve the app from sbt community repo.
        resolvers += Resolver.bintrayIvyRepo("sbt", "sbt-plugin-releases")
      ))

  override def projectSettings = Seq(
    rewritedemoOrigin := "example",
    sourceGenerators in Compile +=
      Def.sequential(
        Def.taskDyn {
          val example = LocalProject(rewritedemoOrigin.value)
          val workingDir = baseDirectory.value
          val out = (sourceManaged in Compile).value / "rewritedemo"
          Def.taskDyn {
            val srcDirs = (sourceDirectories in (example, Compile)).value
            val srcs = (sources in (example, Compile)).value
            val cp = (fullClasspath in (example, Compile)).value
            val jvmOptions = List("-Dscalameta.sourcepath=" + "\"" + srcDirs.mkString(java.io.File.pathSeparator) + "\"",
              "-Dscalameta.classpath=" + "\"" + cp.mkString(java.io.File.pathSeparator)+ "\"",
              "-Drewrite.out=" + out)
            Def.task {
              sidedish.forkRunTask(workingDir, jvmOptions = jvmOptions, args = Nil).value
            }
          }
        },
        Def.task {
          val out = (sourceManaged in Compile).value / "rewritedemo"
          (out ** "*.scala").get
        }
      ).taskValue
  )
}

trait RewriteDemoKeys {
  val rewritedemoOrigin = settingKey[String]("")
}

object RewriteDemoKeys extends RewriteDemoKeys
```

sbt 0.13.13 で入ったシンセティック・サブプロジェクトという機能を使っている。

ユーザのビルドからアプリに引数を渡すのが結構面倒なことになっている。ダイナミック・タスクを入れ子にして元プロジェクトのソース・ディレクトリを JVM オプションとして渡している。

### sbt-rewritedemo がどう使われるか

build.properties:

```scala
sbt.version=0.13.13
```

plugins.sbt:

```scala
addSbtPlugin("com.eed3si9n" % "sbt-rewritedemo" % "0.1.2")
```

build.sbt:

```scala
lazy val example = (project in file("example"))
  .settings(
    name := "example",
    scalaVersion := "2.12.1"
  )

lazy val derived1 = (project in file("derived1"))
  .enablePlugins(RewriteDemoPlugin)
  .settings(
    name := "derived1",
    rewritedemoOrigin := "example",
    scalaVersion := "2.12.1"
  )
```

ここで `example/src/main/scala/Example.scala` 以下に `Example.scala` というファイルがあるとする:

```scala
package foo

object Example extends App {
  println(Seq(1, 2, 3))
}
```

sbt シェルから `derived1/compile` を実行すると、Scala 2.12 で書かれた書き換えアプリを使って以下のファイルが managed source directory に生成される:

```scala
package foo

import scala.collection.immutable.Seq
object Example extends App {
  println(Seq(1, 2, 3))
}
```

言い換えると、sbt-sidedish を使って 2.12 アプリを sbt プラグインから実行できたことになる。
