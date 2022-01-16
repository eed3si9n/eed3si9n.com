---
title:       "Scala を用いたスクリプティング"
type:        story
date:        2014-05-11
changed:     2021-09-13
draft:       false
promote:     true
sticky:      false
url:         /ja/scripting-with-scala
aliases:     [ /node/167 ]
tags:        [ "scala" ]
---

  [1]: http://docutils.sourceforge.net/docs/ref/rst/restructuredtext.html#interpreted-text
  [2]: http://www.scala-sbt.org/release/docs/Detailed-Topics/Scripts.html#sbt-script-runner
  [3]: https://github.com/n8han/conscript
  [4]: https://www.scala-lang.org/api/2.13.4/scala/sys/process/ProcessBuilder.html
  [5]: https://gist.github.com/eed3si9n/fc1aa881bd28b48843e3

現実問題として正規表現が必要になることがある。いくつかのテキストファイルに変換をかけたりする度に `find` コマンド、zsh のドキュメントや Perl 関連の StackOverflow の質問を手探りしながら作業することになる。苦労しながら Perl を書くよりは Scala を使いたい。結局、僕個人の慣れの問題だ。

例えば、今手元に 100以上の reStructuredText ファイルがあって、それを markdown に変換する必要がある。まずは pandoc を試してみて、それはそれなりにうまくいった。だけど、中身をよく読んでみるとコードリテラルの多くがちゃんとフォーマットされてないことに気づいた。これは単一のバッククォート (backtick) で囲まれていたり、[Interpreted Text][1] を使っているからみたいだ。このテキストをいくつかの正規表現で前処理してやればうまくと思う。

### コマンドライン scalas

僕の現在の開発マシンには `scala` へのパスが通っていない。zip ファイルを一回ダウンロードするのは大した作業じゃないけども、将来的に jar とスクリプトの管理をしなきゃいけないのが面倒な気がする。普通なら僕は sbt を使って Scala の jar をダウンロードさせる。それでもいいけども、単一のファイルのみを使った解法が欲しいとする。

そこで今試してるのが sbt の [script runner][2]だ:

```scala
#!/usr/bin/env sbt -Dsbt.version=1.4.7 -Dsbt.main.class=sbt.ScriptMain -Dsbt.supershell=false -error

/***
ThisBuild / scalaVersion := "2.13.4"
*/

println("hello")
```

次に、

    $ chmod +x script.scala
    $ ./script.scala
    hello

これで自分の Scala version を 2.13.4 に指定するスクリプトができた。コンパイルを含めて "hello" が表示されるまで 8秒かかるから、サクサクとは程遠い感じだけど、個人的には許容範囲内だと思う。

### urlgrep.scala

次に標準入力の読み込みをみてみよう。Przemek さんの 'Truly standalone Scala scripts' というトークで例に出てきた標準入力で HTML ファイルを受け取って全ての URL を列挙するというのをやってみる。

```scala
#!/usr/bin/env sbt -Dsbt.version=1.4.7 -Dsbt.main.class=sbt.ScriptMain -Dsbt.supershell=false -error 
/***
ThisBuild / scalaVersion := "2.13.4"
libraryDependencies += "org.scala-sbt" %% "io" % "1.4.0"
*/

import sbt.io._
import sbt.io.syntax._

def stdinStr = IO.readStream(System.in)
val r = """https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)""".r

for {
  line <- stdinStr.linesIterator
  m <- r.findAllMatchIn(line)
} println(m)
```

    $ chmod +x urlgrep.scala
    $ curl -s https://www.scala-sbt.org/ | ./urlgrep.scala
    https://fonts.googleapis.com/css?family=Source+Sans+Pro:400
    https://optanon.blob.core.windows.net/consent/d759c5db-6821-46e0-a988-6bc699efb74e.js
    https://cdn.jsdelivr.net/npm/docsearch.js@2/dist/cdn/docsearch.min.css
    https://github.com/sbt/sbt
    https://twitter.com/scala_sbt
    https://scalacenter.github.io/scala-developer-survey-2019/#which-build-tools-do-you-use
    https://www.scala-sbt.org/1.x/docs/Community-Plugins.html
    http://www.w3.org/2000/svg
    https://stackoverflow.com/questions/tagged/sbt
    http://www.w3.org/2000/svg
    https://www.lightbend.com/services/expert-support
    https://www.lightbend.com/services/training
    https://www.lightbend.com/services/consulting
    https://www.lightbend.com/legal/licenses
    https://www.lightbend.com/legal/terms
    https://www.lightbend.com/legal/privacy
    https://www.lightbend.com
    https://cdn.jsdelivr.net/npm/docsearch.js@2/dist/cdn/docsearch.min.js

数行の見慣れた感じの Scala コードを書くだけでこれができた。

### sbt.io.IO

もう少し複雑な例として、`find` を使わずに `src/` 以下の全サブディレクトリの `*.rst` ファイルを走査したい。sbt の `sbt.IO` はこういうのが得意だし、使い方も分かってる。

```scala
#!/usr/bin/env sbt -Dsbt.version=1.4.7 -Dsbt.main.class=sbt.ScriptMain -Dsbt.supershell=false -error 
/***
ThisBuild / scalaVersion := "2.13.4"
libraryDependencies += "org.scala-sbt" %% "io" % "1.4.0"
*/
import sbt.io._
import sbt.io.syntax._

import java.io.File
import java.net.URI
def file(s: String): File = new File(s)
def uri(s: String): URI = new URI(s)

val srcDir = file("./src/")

val fs: Seq[File] = (srcDir ** "*.rst").get()
fs foreach { x => println(x.toString) }
```

`sbt.io.syntax` オブジェクトに `File` から `PathFinder` への暗黙の変換が含まれていて、`PathFinder` は `**` メソッドを実装する。これがサブディレクトリ内のファイルパターンを参照する。`script.scala` を実行するとこんな感じになる:

    $ ./foo.scala
    ./src/sphinx/faq.rst
    ./src/sphinx/home.rst
    ./src/sphinx/index.rst
    ....

### src から target への rebase

ファイルのリストが得られたところで、各ファイルから行を読み込んで `target/` ディレクトリ以下に書き出してみよう。このようなファイルパスの操作は `Path.rebase` として提供されていて、これは `File => Option[File]` 関数を返す。

行の読み書きはそれぞれ `IO.readLines` と `IO.writeLines` と呼ばれている。各行末に "!" を追加するスクリプトはこうなる:

```scala
#!/usr/bin/env sbt -Dsbt.version=1.4.7 -Dsbt.main.class=sbt.ScriptMain -Dsbt.supershell=false -error 
/***
ThisBuild / scalaVersion := "2.13.4"
libraryDependencies += "org.scala-sbt" %% "io" % "1.4.0"
*/
import sbt.io._
import sbt.io.syntax._

import java.io.File
import java.net.URI
def file(s: String): File = new File(s)
def uri(s: String): URI = new URI(s)

val targetDir = file("./target/")
val srcDir = file("./src/")
val toTarget = Path.rebase(srcDir, targetDir)

def processFile(f: File): Unit = {
  val newParent = toTarget(f.getParentFile) getOrElse {sys.error("wat")}
  val file1 = newParent / f.name
  println(s"""$f => $file1""")
  val xs = IO.readLines(f) map { _ + "!" }
  IO.writeLines(file1, xs)
}

val fs: Seq[File] = (srcDir ** "*.rst").get()
fs foreach { processFile }
```

これがアウトプットだ:

    ./src/sphinx/faq.rst => ./target/sphinx/faq.rst
    ./src/sphinx/home.rst => ./target/sphinx/home.rst
    ./src/sphinx/index.rst => ./target/sphinx/index.rst

### 純粋関数型行変換

行の読み書きというガワができた所で各行の処理という実際の作業に移ることができる。これは `String` を受け取って `String` を返す関数となる。

今取り扱っている reStructuredText ファイルは 3種類の interpreted text の role (`doc`、`key`、`ref`) があって以下のような書式になっている

    :role:`some text here`

まずは、単一の role を取り除く純粋な関数生成器を作る:

```scala
def removeRole(role: String): String => String =
  _.replaceAll("""(:""" + role + """:)(\`[^`]+\`)""", """$2""")
```

次に、`Function1` の `andThen` メソッドを使ってそれを連鎖する:

```scala
val processRest: String => String =
  removeRole("doc") andThen removeRole("key") andThen removeRole("ref")
```

単一のバッククォートとダブルのバッククォートを統一するためには、一度全部単一にしてから、全部をダブルにする。

```scala
def nTicks(n: Int): String = """(\`{""" + n.toString + """})"""
def toSingleTicks: String => String = 
  _.replaceAll(nTicks(2), "`")
def toDoubleTicks: String => String =
  _.replaceAll(nTicks(1), "``")
val preprocessRest: String => String =
  removeRole("doc") andThen removeRole("key") andThen removeRole("ref") andThen 
  toSingleTicks andThen toDoubleTicks
```

### sys.process

シェルスクリプトでよくある操作の一つに他のプログラムの呼び出しがある。sbt の `Process` は今では標準ライブラリに `sys.process` パッケージに含まれている。詳しくは [`ProcessBuilder`][4] を参照。

`Process.apply` は `Seq[String]` を受け取って `ProcessBuilder` を返し、これは渡されたシェルコマンドを実行して結果の行を返す `lazyLines` メソッドを提供する。例えば、以下のようにして `pandoc` を実行できる:

```scala
def runPandoc(f: File): Seq[String] =
  Process(Seq("pandoc", "-f", "rst", "-t", "markdown", f.toString)).lazyLines.toVector
```

### 引数の処理

Scala を使う動機の一つが Unix コマンドへの依存を減らすことだったけど、多くの場合ファイルのリストを受け取って結果を標準出力に返すといったスクリプトが望ましい。そうすることで、まず少数のファイルでテストすることができるからだ。script runner は引数を `args` という名前の変数に保存するため、それを `processFile` に渡してやればいい。

以下は書いた別のスクリプトでカスタムの `howto` タグを抽出している。

```scala
#!/usr/bin/env sbt -Dsbt.version=1.4.7 -Dsbt.main.class=sbt.ScriptMain -Dsbt.supershell=false -error 
/***
ThisBuild / scalaVersion := "2.13.4"
libraryDependencies += "org.scala-sbt" %% "io" % "1.4.0"
*/

// $ script/extracthowto.scala ../sbt/src/sphinx/Howto/*.rst

import sbt.io._
import sbt.io.syntax._
import java.net.{URI, URL}
def file(s: String): File = new File(s)
def uri(s: String): URI = new URI(s)

/*
A how to tag looks like this:

.. howto::
   :id: unmanaged-base-directory
   :title: Change the default (unmanaged) library directory
   :type: setting

   unmanagedBase := baseDirectory.value / "jars"
*/

def extractId(line: String): String = line.replaceAll(":id:", "").trim
def extractTitle(line: String): String = line.replaceAll(":title:", "").trim

def processLine(num: Int, line1: String, line2: String, line3: String): Option[String] =
  line1 match {
    case x if x.trim == ".. howto::" =>
      Some(s"""<a name="${extractId(line2)}"></a>
### ${extractTitle(line3)}""")
    case _ => None
  }

def processFile(f: File): Unit = {
  if (!f.exists) sys.error(s"$f does not exist!")

  val lines0: Vector[String] = IO.readLines(f).toVector
  val size = lines0.size
  val xs: Vector[String] = (0 to size - 3).toVector flatMap { i =>
    processLine(i, lines0(i), lines0(i + 1), lines0(i + 2))
  }
  println("-------------------\n")
  println(xs.mkString("\n\n"))
  println("\n")
}

args foreach { x => processFile(file(x)) }
```

### まとめ 

sbt の script runner と `IO` モジュールを使うことで、Scala を使って静的型付けされたシェルスクリプトを書くことができる。[script.scala の gist][5]。
