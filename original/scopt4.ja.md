  [scala-options]: https://github.com/aaronharnly/scala-options
  [OptionParser]: http://ruby-doc.org/stdlib-2.0/libdoc/optparse/rdoc/OptionParser.html
  [1]: http://eed3si9n.com/ja/monads-are-fractals
  [github_search]: https://github.com/search?q=%22com.github.scopt%22&type=Code
  [215]: https://github.com/scopt/scopt/issues/215

> 本稿は 2018年12月に 4.0.0-RC2 と共に初出した。2020年11月にリリースした 4.0.0 での変更を反映して更新してある。

最近 scopt 4.0 を書いている。せっかちな人は [readme](https://github.com/scopt/scopt) に飛んでほしい。

4.0.0 を試すには以下を build.sbt に書く:

<code>
libraryDependencies += "com.github.scopt" %% "scopt" % "4.0.0"
</code>

scopt 4.0.0 は以下のビルドマトリックスに対してクロスパブリッシュされている:

| Scala         | JVM | JS (1.x) |  JS (0.6.x) |  Native (0.4.0-M2) |  Native (0.3.x) |
| ------------- | :-: | :------: | :---------: | :------------:  | :------------:  |
| 3.0.0-M2      | ✅  |   ✅     |     n/a     |      n/a        |     n/a        |
| 3.0.0-M1      | ✅  |   ✅     |     n/a     |      n/a        |      n/a       |
| 2.13.x        | ✅  |   ✅     |     ✅      |      n/a        |      n/a        |
| 2.12.x        | ✅  |   ✅     |     ✅      |      n/a        |      n/a        |
| 2.11.x        | ✅  |   ✅     |     ✅      |      ✅         |      ✅         |

scopt はコマンドラインオプションをパースするための小さなライブラリだ。2008年に [aaronharnly/scala-options][scala-options] として始まり、当初は Ruby の [OptionParser][OptionParser] を緩めにベースにしたものだった。scopt 2 で immutable parsing を導入して、scopt 3 では `Read` 型クラスを使ってメソッド数を大幅に減らすことができた。

### 後方ソース互換性

Sonatype によると scopt 3.x は 2018年11月に 370,325回ダウンロードされた。GitHub のコード検索を行うと ["com.github.scopt"][github_search] に対して 61,449件のヒットがある。CI やキャッシングがあるため、絶対値にはあまり意味が無いが、これらは scopt 3.x がある程度のユーザに使われていることを示唆する。そのため、マイグレーションコストを意識する必要がある。

scopt 4 はオプションパーサーを定義するための新しい方法を導入するが、scopt 3 での「オブジェクト指向 DSL」もそのままキープする予定だ。

<scala>
val parser = new scopt.OptionParser[Config]("scopt") {
  head("scopt", "3.x")

  opt[Int]('f', "foo")
    .action((x, c) => c.copy(foo = x))
    .text("foo is an integer property")

  opt[File]('o', "out")
    .required()
    .valueName("<file>")
    .action((x, c) => c.copy(out = x))
    .text("out is a required file property")
}
</scala>

これまで scopt 3 を使ってきた人は、コンパイルが通れば多分 ok なはずだ。

### コマンドラインパーサーの合成

scopt で何回か聞かれた質問の機能の要望として、複数の小さいオプションパーサーを合成して一つのパーサーを作りたいというものがある。例えば [scopt/scopt#215][215] がある:

> 互いに素であるオプションの集合に対して別々のパーサーを定義して、必要に応じてそれらを合成したい。例えば、サブプロジェクトにそれぞれ別のパーサーを定義したい。

2014年に書いた[「モナドはフラクタルだ」][1]でオプションパーサーをモナディックなデータ型として定義すれば合成可能になるのではないかというアイディアを思いついた。

### 関数型 DSL

scopt 4 における関数型 DSL は以下のようになる:

<scala>
import scopt.OParser
val builder = OParser.builder[Config]
val parser1 = {
  import builder._
  OParser.sequence(
    programName("scopt"),
    head("scopt", "4.x"),
    // option -f, --foo
    opt[Int]('f', "foo")
      .action((x, c) => c.copy(foo = x))
      .text("foo is an integer property"),
    // more options here...
  )
}

// OParser.parse returns Option[Config]
OParser.parse(parser1, args, Config()) match {
  case Some(config) =>
    // do something
  case _ =>
    // arguments are bad, error message will have been displayed
}
</scala>

`OptionParser` 内でメソッドを呼ぶのではなく、関数型 DSL はまず特定の `Config` データ型に対するビルダーを作って、`opt[A](...)` など `Oparser[A, Config]` を返す関数を呼ぶ。

これらの `OParser[A, Config]` パーサーは `OParser.sequence(...)` を用いて合成できる。

最初は `for` 内包表記を使ってこの合成を表すことも考えていたが、その見た目に慣れて人にとっては分かりづらいと思ったので `sequence` 関数を作った。

### OParser.sequence を用いた合成

`OParser.sequence` を用いた `OParser` の合成の具体例を見てみる。

<scala>
import scopt.OParser
val builder = OParser.builder[Config]
import builder._

val p1 =
  OParser.sequence(
    opt[Int]('f', "foo")
      .action((x, c) => c.copy(intValue = x))
      .text("foo is an integer property"),
    opt[Unit]("debug")
      .action((_, c) => c.copy(debug = true))
      .text("debug is a flag")
  )
val p2 =
  OParser.sequence(
    arg[String]("<source>")
      .action((x, c) => c.copy(a = x)),
    arg[String]("<dest>")
      .action((x, c) => c.copy(b = x))
  )
val p3 =
  OParser.sequence(
    head("scopt", "4.x"),
    programName("scopt"),
    p1,
    p2
  )
</scala>

### cmd("...").children(...) を用いた合成

`OParser` を再利用するもう一つの方法があって、それは `cmd("...")` パーサーの `.children(...)` メソッドに渡すことだ。

<scala>
val p4 = {
  import builder._
  OParser.sequence(
    programName("scopt"),
    head("scopt", "4.x"),
    cmd("update")
      .action((x, c) => c.copy(update = true))
      .children(suboptionParser1),
    cmd("status")
      .action((x, c) => c.copy(status = true))
      .children(suboptionParser1)
  )
}
</scala>

上の例では `suboptionParser1` も `OParser` だ。これによって例えば update コマンドと status コマンドにおいて共通のコマンドを再利用することができる。

### コンフィギュレーションデータ型の合成

`OParser.sequence` はパーサープログラムの合成を可能とするが、同じ `Config` データ型を使わなければいけないという制約がある。別々のサププロジェクトからパーサーを提供しようした場合これは嬉しくない。

`Config` データ型を分ける一つの具体例をここに紹介する。

<scala>
// provide this in subproject1
trait ConfigLike1[R] {
  def withDebug(value: Boolean): R
}
def parser1[R <: ConfigLike1[R]]: OParser[_, R] = {
  val builder = OParser.builder[R]
  import builder._
  OParser.sequence(
    opt[Unit]("debug").action((_, c) => c.withDebug(true)),
    note("something")
  )
}

// provide this in subproject2
trait ConfigLike2[R] {
  def withVerbose(value: Boolean): R
}
def parser2[R <: ConfigLike2[R]]: OParser[_, R] = {
  val builder = OParser.builder[R]
  import builder._
  OParser.sequence(
    opt[Unit]("verbose").action((_, c) => c.withVerbose(true)),
    note("something else")
  )
}

// compose config datatypes and parsers
case class Config1(debug: Boolean = false, verbose: Boolean = false)
    extends ConfigLike1[Config1]
    with ConfigLike2[Config1] {
  override def withDebug(value: Boolean) = copy(debug = value)
  override def withVerbose(value: Boolean) = copy(verbose = value)
}
val parser3: OParser[_, Config1] = {
  val builder = OParser.builder[Config1]
  import builder._
  OParser.sequence(
    programName("scopt"),
    head("scopt", "4.x"),
    parser1,
    parser2
  )
}
</scala>

この例では `parser1` と `parser2` は、`ConfigLike1[R]` と `ConfigLike2[R]` のサブタイプであるという制約を満たす抽象型 `R` に対して書かれている。`parser3` において、`R` は具象データ型 `Config1` に束縛される。

### effects の抽象化

RC2 を出したあとにもらったフィードバックは effects の管理に関してだった。以前も `reporError` 関数などを差し替えるということは可能だったが、effects をデータ構造で表現できればより良いだろう。

それを 4.0.0 で行った:

<scala>
sealed trait OEffect
object OEffect {
  case class DisplayToOut(msg: String) extends OEffect
  case class DisplayToErr(msg: String) extends OEffect
  case class ReportError(msg: String) extends OEffect
  case class ReportWarning(msg: String) extends OEffect
  case class Terminate(exitState: Either[String, Unit]) extends OEffect
}
</scala>

通常の `OParser.parse(...)` の他に scopt 4 は `runParser` というパーサーの呼び出しの新しい方法を提供して、これは `(Option[Config], List[OEffect])` を返す:

<scala>
// OParser.runParser returns (Option[Config], List[OEffect])
OParser.runParser(parser1, args, Config()) match {
  case (result, effects) =>
    OParser.runEffects(effects, new DefaultOEffectSetup {
      // override def displayToOut(msg: String): Unit = Console.out.println(msg)
      // override def displayToErr(msg: String): Unit = Console.err.println(msg)
      // override def reportError(msg: String): Unit = displayToErr("Error: " + msg)
      // override def reportWarning(msg: String): Unit = displayToErr("Warning: " + msg)
      
      // ignore terminate
      override def terminate(exitState: Either[String, Unit]): Unit = ()
    })

    result match {
      Some(config) =>
        // do something
      case _ =>
        // arguments are bad, error message will have been displayed
    }
}
</scala>

返ってきた effects を好きにできるようになった。

### usage の自動生成

scopt 3 同様に、usage text が自動的に生成される。

<code>
scopt 4.x
Usage: scopt [update] [options] [<file>...]

  -f, --foo <value>        foo is an integer property
  -o, --out <file>         out is a required file property
  --max:<libname>=<max>    maximum count for <libname>
  -j, --jars <jar1>,<jar2>...
                           jars to include
  --kwargs k1=v1,k2=v2...  other arguments
  --verbose                verbose is a flag
  --help                   prints this usage text
  <file>...                optional unbounded args
some notes.

Command: update [options]
update is a command.
  -nk, --not-keepalive     disable keepalive
  --xyz <value>            xyz is a boolean property
</code>

scopt 4 を使ってみて、何か気づいたら[バグ報告](https://github.com/scopt/scopt/issues/new)をしてほしい。
