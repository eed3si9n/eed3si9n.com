  [1]: http://docutils.sourceforge.net/docs/ref/rst/restructuredtext.html#interpreted-text
  [2]: http://www.scala-sbt.org/release/docs/Detailed-Topics/Scripts.html#sbt-script-runner
  [3]: https://github.com/n8han/conscript
  [4]: http://www.scala-lang.org/api/2.10.4/index.html#scala.sys.process.ProcessBuilder
  [5]: https://gist.github.com/eed3si9n/fc1aa881bd28b48843e3

現実問題として正規表現が必要になることがある。いくつかのテキストファイルに変換をかけたりする度に `find` コマンド、zsh のドキュメントや Perl 関連の StackOverflow の質問を手探りしながら作業することになる。苦労しながら Perl を書くよりは Scala を使いたい。結局、僕個人の慣れの問題だ。

例えば、今手元に 100以上の reStructuredText ファイルがあって、それを markdown に変換する必要がある。まずは pandoc を試してみて、それはそれなりにうまくいった。だけど、中身をよく読んでみるとコードリテラルの多くがちゃんとフォーマットされてないことに気づいた。これは単一のバッククォート (backtick) で囲まれていたり、[Interpreted Text][1] を使っているからみたいだ。このテキストをいくつかの正規表現で前処理してやればうまくと思う。

### コマンドライン scalas

僕の現在の開発マシンには `scala` へのパスが通っていない。zip ファイルを一回ダウンロードするのは大した作業じゃないけども、将来的に jar とスクリプトの管理をしなきゃいけないのが面倒な気がする。普通なら僕は sbt を使って Scala の jar をダウンロードさせる。それでもいいけども、単一のファイルのみを使った解法が欲しいとする。

そこで今試してるのが [conscript][3] を使って入れることができる sbt の [script runner][2]だ。

    $ cs sbt/sbt --branch 0.13.2b

注意: 上を実行すると `~/bin/sbt` が上書きされる。`~/bin/` 以下にインストールされるものの一つに `scalas` スクリプトがある。`script.scala` を以下のように書く:

<scala>
#!/usr/bin/env scalas

/***
scalaVersion := "2.10.4"
*/

println("hello")
</scala> <!-- ***/ -->

次に、

    $ chmod +x script.scala
    $ export CONSCRIPT_OPTS="-XX:MaxPermSize=512M -Dfile.encoding=UTF-8"
    $ ./script.scala
    [info] Loading global plugins from /Users/eugene/dotfiles/sbt/0.13/plugins
    [info] Set current project to root-4dcd3aa66723522a07c4 (in build file:/Users/eugene/.conscript/boot/4dcd3aa66723522a07c4/)
    hello

これで自分の Scala version を 2.10.4 に指定するスクリプトができた。コンパイルを含めて "hello" が表示されるまで 12秒かかるから、サクサクとは程遠い感じだけど、個人的には許容範囲内だと思う。

### sbt.IO

まず最初にやりたいのは、`find` を使わずに `src/` 以下の全サブディレクトリの `*.rst` ファイルを走査することだ。sbt の `sbt.IO` はこういうのが得意だし、使い方も分かってる。

<scala>
#!/usr/bin/env scalas

/***
scalaVersion := "2.11.7"

resolvers += Resolver.typesafeIvyRepo("releases")

libraryDependencies += "org.scala-sbt" % "io" % "0.13.8"
*/

import sbt._, Path._
import java.io.File
import java.net.{URI, URL}
def file(s: String): File = new File(s)
def uri(s: String): URI = new URI(s)

val srcDir = file("./src/")

val fs: Seq[File] = (srcDir ** "*.rst").get
fs foreach { x => println(x.toString) }

</scala> <!-- ***/ -->

`Path` オブジェクトに `File` から `PathFinder` への暗黙の変換が含まれていて、`PathFinder` は `**` メソッドを実装する。これがサブディレクトリ内のファイルパターンを参照する。`script.scala` を実行するとこんな感じになる:

    $ ./foo.scala 
    [info] Loading global plugins from /Users/eugene/dotfiles/sbt/0.13/plugins
    [info] Set current project to root-4dcd3aa66723522a07c4 (in build file:/Users/eugene/.conscript/boot/4dcd3aa66723522a07c4/)
    ./src/sphinx/faq.rst
    ./src/sphinx/home.rst
    ./src/sphinx/index.rst
    ....

### src から target への rebase

ファイルのリストが得られたところで、各ファイルから行を読み込んで `target/` ディレクトリ以下に書き出してみよう。このようなファイルパスの操作は `Path.rebase` として提供されていて、これは `File => Option[File]` 関数を返す。

行の読み書きはそれぞれ `IO.readLines` と `IO.writeLines` と呼ばれている。各行末に "!" を追加するスクリプトはこうなる:

<scala>
#!/usr/bin/env scalas

/***
scalaVersion := "2.11.7"

resolvers += Resolver.typesafeIvyRepo("releases")

libraryDependencies += "org.scala-sbt" % "io" % "0.13.8"
*/

import sbt._, Path._
import java.io.File
import java.net.{URI, URL}
import sys.process._
def file(s: String): File = new File(s)
def uri(s: String): URI = new URI(s)

val targetDir = file("./target/")
val srcDir = file("./src/")
val toTarget = rebase(srcDir, targetDir)

def processFile(f: File): Unit = {
  val newParent = toTarget(f.getParentFile) getOrElse {sys.error("wat")}
  val file1 = newParent / f.name
  println(s"""$f => $file1""")
  val xs = IO.readLines(f) map { _ + "!" }
  IO.writeLines(file1, xs)
}

val fs: Seq[File] = (srcDir ** "*.rst").get
fs foreach { processFile }
</scala> <!-- ***/ -->

これがアウトプットだ:

    ./src/sphinx/faq.rst => ./target/sphinx/faq.rst
    ./src/sphinx/home.rst => ./target/sphinx/home.rst
    ./src/sphinx/index.rst => ./target/sphinx/index.rst

### 純粋関数型行変換

行の読み書きというガワができた所で各行の処理という実際の作業に移ることができる。これは `String` を受け取って `String` を返す関数となる。

今取り扱っている reStructuredText ファイルは 3種類の interpreted text の role (`doc`、`key`、`ref`) があって以下のような書式になっている

    :role:`some text here`

まずは、単一の role を取り除く純粋な関数生成器を作る:

<scala>
def removeRole(role: String): String => String =
  _.replaceAll("""(:""" + role + """:)(\`[^`]+\`)""", """$2""")
</scala> <!--_ -->

次に、`Function1` の `andThen` メソッドを使ってそれを連鎖する:

<scala>
val processRest: String => String =
  removeRole("doc") andThen removeRole("key") andThen removeRole("ref")
</scala>

単一のバッククォートとダブルのバッククォートを統一するためには、一度全部単一にしてから、全部をダブルにする。

<scala>
def nTicks(n: Int): String = """(\`{""" + n.toString + """})"""
def toSingleTicks: String => String = 
  _.replaceAll(nTicks(2), "`")
def toDoubleTicks: String => String =
  _.replaceAll(nTicks(1), "``")
val preprocessRest: String => String =
  removeRole("doc") andThen removeRole("key") andThen removeRole("ref") andThen 
  toSingleTicks andThen toDoubleTicks
</scala>

### sys.process

シェルスクリプトでよくある操作の一つに他のプログラムの呼び出しがある。sbt の `Process` は今では標準ライブラリに `sys.process` パッケージに含まれている。詳しくは [`ProcessBuilder`][4] を参照。

`Seq[String]` から `ProcessBuilder` へと暗黙の変換があって、これは渡されたシェルコマンドを実行して結果の行を返す `lines` メソッドを提供する。例えば、以下のようにして `pandoc` を実行できる:

<scala>
def runPandoc(f: File): Seq[String] =
  Seq("pandoc", "-f", "rst", "-t", "markdown", f.toString).lines.toSeq
</scala>

### 引数の処理

Scala を使う動機の一つが Unix コマンドへの依存を減らすことだったけど、多くの場合ファイルのリストを受け取って結果を標準出力に返すといったスクリプトが望ましい。そうすることで、まず少数のファイルでテストすることができるからだ。script runner は引数を `args` という名前の変数に保存するため、それを `processFile` に渡してやればいい。

以下は最近書いた別のスクリプトでカスタムの `howto` タグを抽出している。

<scala>
#!/usr/bin/env scalas
 
/***
scalaVersion := "2.11.7"

resolvers += Resolver.typesafeIvyRepo("releases")

libraryDependencies += "org.scala-sbt" % "io" % "0.13.8"
*/

// $ script/extracthowto.scala ../sbt/src/sphinx/Howto/*.rst

import sbt._, Path._
import java.io.File
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
      Some(s"""<a name="""${extractId(line2)}"></a>
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
</scala>

### まとめ 

sbt の script runner と `IO` モジュールを使うことで、Scala を使って静的型付けされたシェルスクリプトを書くことができる。[script.scala の gist][5]。

