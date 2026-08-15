---
title:       "sbt プラグイン・クラスパスの隔離"
type:        story
date:        2026-08-15
url:         /ja/sbt-plugin-classpath-isolation
---

  [1]: https://www.scala-sbt.org/2.x/docs/ja/recipes/plugin-isolation.html

ビルドは様々なタスクを実行するため、既存のライブラリやツールを再利用することが多い。sbt のプラグイン機構は、メタビルドにライブラリを追加することでそのような再利用を可能とする。軽めのタスクや、`gpg` のような外部ツールとの統合するのには丁度いい。しかし、メタビルドにライブラリを追加し続けるのは、不可能だったり好ましくなかったりする場合もある。例えば、Scalafix や Coursier は特定の Scala バージョンで書かれているが、これは sbt 2.x や 1.x が使っている Scala バージョンと非互換であるかもしれない。そのためか、プラグイン・クラスパスの隔離という概念が時折出てくることがあるので、本稿で解説していきたいと思う。ソースは[プラグイン・クラスパスの隔離レシピ][1]を参照。

<!--more-->

### 概要

概要をさらっとまとめると:

1. コマンドライン・アプリを定義する。
2. プラグインからコマンドライン・アプリを `run` 経由で呼び出す。

そもそも sbt は、`run` タスクを新規プロセスではなく、サンドボックス化されたクラスローダーで実装しているので、これは実質クラスパス隔離と同等なものだと考えることができる。クラスパス隔離に必要なその他の機能も sbt 0.13.13 以降実装済みだ。実際、2017年に[アプリのダウンロードと実行](/ja/sbt-sidedish)という似たような記事を既に書いてある。今回は、sbt-sidedish を必要としない改訂版だ。

### 人工サブプロジェクト

プラグインは `extraProjects` をオーバーライドすることで、人工サブプロジェクトを作ることができる:

```scala
package example

import sbt.{ *, given }
import Keys.*

object BootstrapPlugin extends AutoPlugin:
  override lazy val requires = sbt.plugins.JvmPlugin

  lazy val bootstrapCs = project
    .settings(
      scalaVersion := "2.12.21",
      libraryDependencies += "io.get-coursier" %% "coursier-cli" % "2.1.14",
      Compile / run / mainClass := Some("coursier.cli.Coursier"),
      // applicable to sbt 2.x only
      clientSide := false,
    )

  override lazy val extraProjects = Vector(bootstrapCs)

  ....
end BootstrapPlugin
```

この例では、Scala 2.12 で書かれた Coursier CLI を追加する。これは、ビルドに追加されるので名前が衝突しないように `bootstrapCs` というふうに、なんらかのプリフィックスを付ける。

### コマンドライン・アプリの呼び出し

Coursier CLI を使って bootstrap JAR を生成するタスクを実装できる。まずはキーを定義する:

```scala
  object autoImport:
    val packageBootstrap = taskKey[HashedVirtualFileRef]("packageBootstrap")
    val packageBootstrapArgs = settingKey[Seq[String]]("packageBootstrapArgs")
    val packageBootstrapOutput = settingKey[File]("packageBootstrapOutput")
  end autoImport
  import autoImport.*
```

実際の実装は以下のようになっている:

```scala
  override lazy val projectSettings = Vector(
    packageBootstrapOutput := target.value / "bootstrap" / s"${moduleName.value}.jar",
    packageBootstrapArgs := {
      val coord =
        s"${organization.value}:${name.value}_${scalaBinaryVersion.value}:${version.value}"
      val sv = scalaVersion.value
      Vector("bootstrap", "--verbose", "--bat=true",
        "--scala-version", sv,
        "-f", coord,
        "-o", packageBootstrapOutput.value.toString)
    },
    packageBootstrap := Def.uncached {
      // to process args before toTask, we need to use dynamic tasks
      (Def.taskDyn {
        // phase 1
        val c = fileConverter.value
        val args = packageBootstrapArgs.value
        val out = packageBootstrapOutput.value
        // phase 2
        val outVf: HashedVirtualFileRef = c.toVirtualFile(out.toPath())
        IO.createDirectory(out.getParentFile())
        // phase 3
        (bootstrapCs / Compile / run)
          .toTask(args.mkString(" ", " ", ""))
          .map(_ => outVf)
      }).value
    },
  )
```

上の例で `packageBootstrapOutput` と `packageBootstrapArgs` は、コマンドライン・アプリの引数を作るためのセッティングで、Coursier CLI に渡される。`packageBootstrap` は動的タスク `Def.taskDyn` を使うことでタスクを逐次的に合成している (sbt における `flatMap` 的なもの)。

Coursier CLI への入力は文字列の引数で、期待される出力は複数のファイルだ。コンソール出力があれば、自動的にターミナルへ表示される:

```bash
sbt:isolation-root> app/publishLocal
sbt:isolation-root> app/packageBootstrap
[info] running coursier.cli.Coursier bootstrap --verbose --bat=true --scala-version 3.8.4 -f com.example:hello_3:0.1.0-SNAPSHOT -o /.../isolation/target/out/jvm/scala-3.8.4/hello/bootstrap/hello.jar
  Dependencies:
com.example:hello_3:0.1.0-SNAPSHOT:
Wrote /.../isolation/target/out/jvm/scala-3.8.4/hello/bootstrap/hello.jar
Wrote /.../isolation/target/out/jvm/scala-3.8.4/hello/bootstrap/hello.jar.bat
[success] elapsed time: 3 s, cache 100%, 17 disk cache hits
```

上の例は、sbt 2.x の `app/packageBootstrap` が Coursier CLI を呼び出して bootstrap JAR を構築したことを示している。

### フォークに関する備考

`bootstrapCs` サブプロジェクトを定義するときに、わざわざ `clientSide` を `false` に設定した:

```scala
clientSide := false,
```

これは、デフォルトでオンになっているクライアント・サイド run を止めて、sbt サーバーと同じ JVM 上で Coursier CLI が走るようにするためだ。ただし、注意が必要なのは CLI プログラムは `sys.exit(1)` を呼ぶことが多いので、それをやられると、sbt サーバーごとシャットダウンしてしまう:

```bash
sbt:isolation-root> bootstrapCs/run --help
[info] running coursier.cli.Coursier --help
Usage: coursier <COMMAND>
Coursier is the Scala application and artifact manager.
It can install Scala applications and setup your Scala development environment.
It can also download and cache artifacts from the web.
....
$
```

ビルドを `sys.exit(1)` から保護したい場合は、`run` をフォークする必要がある:

```scala
// default for sbtn
clientSide := true,
// for sbt --server
Compile / run / fork := true,
```

プロセス内の `run` と比べるとフォークした場合は、JVM のウォームアップのせいで実行が遅くなるかもしれないというトレードオフがあるため、タスクが何回呼ばれるかにもよるだろう。

### まとめ

sbt プラグイン・クラスパスの隔離は sbt 2.x と 1.x の両方で実装されており、任意の Scala バージョンで人工サブプロジェクトとしてコマンドライン・アプリを定義することで実現される。ソースは[プラグイン・クラスパスの隔離レシピ][1]を参照。
