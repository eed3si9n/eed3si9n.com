---
title:       "scopt 3.0"
type:        story
date:        2013-06-09
changed:     2013-07-09
draft:       false
promote:     true
sticky:      false
url:         /ja/scopt3
aliases:     [ /node/138 ]
tags:        [ "scala" ]
---

> scopt is a little command line options parsing library.

今日 scopt 3.0 をリリースする。実装の詳細に興味が無ければ、[readme](https://github.com/scopt/scopt) に飛んでほしい。

2010年3月4日ごろ僕は scopt のコミッタになった。これは元々 Aaron Harnly さんが 2008年ごろ書いた scala-options のフォークだ。確か、usage text 周りの変更と key=value options と argument list という機能を追加したかったんだと思う。それ以降全てのバグレポを担当してきた。その中には jar を scala-tools.org に公開してくれというのもあった。2012年3月18日、僕は再びプロジェクトを [scopt/scopt](https://github.com/scopt/scopt) にフォークして immutable parser を追加した scopt 2.0.0 をリリースした。

数年に渡って重ねるようにして機能が追加されたため、scopt3 は一から書き直すことにした。発端となったのは Leif Wickland さんに[「scopt に intArg() が無いのは設計上の理由があるのか」](https://twitter.com/leifwickland/status/339790970931523586)と聞かれたことだ。

Ruby の [OptionParser](http://ruby-doc.org/stdlib-2.0/libdoc/optparse/rdoc/OptionParser.html) に inspire されて書かれた元の Aaron さんの scala-options にはオプションのために 5個のメソッドがあった: `onInt`、 `onDouble`、 `onBoolean`、 `on`、それからもう一つオーバーロードされた `on`。重なる開発の結果 scopt2 は `opt` のオーバーロードが 6つ、`intOpt`、 `doubleOpt`、 `booleanOpt`、 `keyValueOpt`、 `keyIntValueOpt`、 `keyDoubleValueOpt`、 `keyBooleanValueOpt` それぞれに 4つづつのオーバーロードが蓄積された。合計 34 ものメソッドだ! これらのオーバーロードは省略可能な頭文字や値の名前のために僕が追加したものだから、自分以外に責めようが無い。これ以上の拡張は考えられなかった。

### Read を使ったアドホック多相

気になっていたのは、`Int` や `String` のようなオプションのデータ型ごとのコードの重複だ。これは、`String => Unit` と `Int => Unit` が型消去後に区別つかなくなることを回避してのことだ。

コードを重複させなくても、`Read` を用いたアドホック多相によって最低でも実装は一発で表現することができる。ユーザ側から見ても、`opt[Int]` という方が `intOpt` よりもクリーンなのではないかと思う。

全てのコードをコメントアウトした後、`Read` から書き始めた:

```scala
trait Read[A] {
  def reads: String => A
}

object Read {
  def reads[A](f: String => A): Read[A] = new Read[A] {
    val reads = f
  }

  implicit val intRead: Read[Int]             = reads { _.toInt }
  implicit val stringRead: Read[String]       = reads { identity }
  implicit val doubleRead: Read[Double]       = reads { _.toDouble }
  implicit val booleanRead: Read[Boolean]     =
    reads { _.toLowerCase match {
      case "true"  => true
      case "false" => false
      case "yes"   => true
      case "no"    => false
      case "1"     => true
      case "0"     => false
      case s       =>
        throw new IllegalArgumentException("'" + s + "' is not a boolean.")
    }}
}
```

これは `String` から変換できるという能力を表す型クラスだ。これを用いて、データ型に特定だった case class の全ての以下のジェネリックなものに置き換えることができる。

```scala
class OptionDef[A: Read, C]() {
  ...  
}
```

### fluent interface

省略可能な引数により発生したオーバーロードの乱発を解決するために、`OptionDef` 上で [fluent interface](http://capsctrl.que.jp/kdmsnr/wiki/bliki/?FluentInterface) を実装した。パーサは始めるための最小限のメソッドを提供するだけでいい。

```scala
  /** adds an option invoked by `--name x`.
   * @param name name of the option
   */
  def opt[A: Read](name: String): OptionDef[A, C] = makeDef(Opt, name)

  /** adds an option invoked by `-x value` or `--name value`.
   * @param x name of the short option
   * @param name name of the option
   */
  def opt[A: Read](x: Char, name: String): OptionDef[A, C] =
    opt[A](name) shortOpt(x)
```

頭文字のオプションのデータ型は、グルーピング (`-la` は `-l -a` と解釈される) のために `String` から `Char` に変更された。コールバックや説明文などの残りのパラメータは `OptionDef` へのメソッドとして後で呼び出すことができる:

```scala
  opt[Int]("foo") action { (x, c) =>
    c.copy(foo = x) } text("foo is an integer property")
  opt[File]('o', "out") valueName("<file>") action { (x, c) =>
    c.copy(out = x) } text("out is a string property")
```

上の例で `text("...")` と `action {...}` は両方とも `OptionDef[A, C]` のメソッドで新しい `OptionDef[A, C]` を返す:

```scala
  /** Adds description in the usage text. */
  def text(x: String): OptionDef[A, C] =
    _parser.updateOption(copy(_desc = x))
  /** Adds value name used in the usage text. */
  def valueName(x: String): OptionDef[A, C] =
    _parser.updateOption(copy(_valueName = Some(x)))
```

`Read` と fluent interface を併用することで 32個あったメソッドを 2つのオーバーロードに減らすことができた。API としてはこっちの方が覚えやすい。より重要なのは、これを使った使用コードが初見で読みやすくなったことだ。

### Read のインスタンスを別のインスタンスから派生させる

型クラスの強力な側面として、既存のインスタンスを派生させて別のインスタンスを返すという抽象的なインスタンスを定義できることがある。 key=value インスタンスは 2つの `Read` インスタンスのペアとして以下のように実装されている:

```scala
  implicit def tupleRead[A1: Read, A2: Read]: Read[(A1, A2)] = new Read[(A1, A2)] {
    val arity = 2
    val reads = { (s: String) =>
      splitKeyValue(s) match {
        case (k, v) => implicitly[Read[A1]].reads(k) -> implicitly[Read[A2]].reads(v)
      }
    }
  } 
  private def splitKeyValue(s: String): (String, String) =
    s.indexOf('=') match {
      case -1     => throw new IllegalArgumentException("Expected a key=value pair")
      case n: Int => (s.slice(0, n), s.slice(n + 1, s.length))
    }
```

scopt2 のように `String=Int` をパースできるだけでなく、これは `Int=Boolean` のような組み合わせもパースできるようになった。以下に使用例をみてみる。

```scala
  opt[(String, Int)]("max") action { case ((k, v), c) =>
    c.copy(libName = k, maxCount = v) } validate { x =>
    if (x._2 > 0) success else failure("Value <max> must be >0") 
  } keyValueName("<libname>", "<max>") text("maximum count for <libname>")
```

### さらに Read

データ型を追加するたびに API が大きくならなくなったため、他にもデータ型を追加した: `Long`、 `BigInt`、 `BigDecimal`、 `Calendar`、 `File`、そして `URI` だ。

`Read` に手を加えて値を取らない `opt[Unit]("verbose")` のようなフラグを扱えるようにした:

```scala
  implicit val unitRead: Read[Unit] = new Read[Unit] {
    val arity = 0
    val reads = { (s: String) => () }
  }
```

### specs2 2.0 (RC-1)

ライブラリの書き換えを行う場合、テスト無しではやりたくはない。scopt3 は本体のコード以上に specs2 2.0 spec の行数がある。新しく追加された[文字列補間子](http://etorreborre.blogspot.com.au/2013/05/the-latest-release-of-specs2-2.html)によって acceptance spec が書きやすくなった。以下は [ImmutableParserSpec](https://github.com/scopt/scopt/blob/94b35beb4b9586d9200ec6577bfdf9cd5e9e28a9/src/test/scala/scopt/ImmutableParserSpec.scala) からの抜粋だ:

```scala
class ImmutableParserSpec extends Specification { def is =      s2"""
  This is a specification to check the immutable parser
  
  opt[Int]('f', "foo") action { x => x } should
    parse 1 out of --foo 1                                      ${intParser("--foo", "1")}
    parse 1 out of --foo:1                                      ${intParser("--foo:1")}
    parse 1 out of -f 1                                         ${intParser("-f", "1")}
    parse 1 out of -f:1                                         ${intParser("-f:1")}
    fail to parse --foo                                         ${intParserFail{"--foo"}}
    fail to parse --foo bar                                     ${intParserFail("--foo", "bar")}
                                                                """

  val intParser1 = new scopt.OptionParser[Config]("scopt") {
    head("scopt", "3.x")
    opt[Int]('f', "foo") action { (x, c) => c.copy(intValue = x) }
  }
  def intParser(args: String*) = {
    val result = intParser1.parse(args.toSeq, Config())
    result.get.intValue === 1
  }
  def intParserFail(args: String*) = {
    val result = intParser1.parse(args.toSeq, Config())
    result === None
  }
```

### 出現回数

`Read` ができたため、多相な引数はほぼ自動的に得られることができた。 `arg[File]("<out>")` は `File` をパースし、`arg[Int]("<port>")` は `Int` をパースする。

scopt2 は、`arg`、 `argOpt`、 `arglist`、 `arglistOpt` という4種類の引数を実装していた。API を縮小させるため、scopt3 は `arg[A: Read](name: String): OptionDef[A, C]` のみを実装して、残りは fluent スタイルのメソッド `def minOccurs(n: Int)` と `def maxOccurs(n: Int)` を使ってサポートする。これを使って「糖衣構文」を DSL に提供することができる:

```scala
  /** Requires the option to appear at least once. */
  def required(): OptionDef[A, C] = minOccurs(1)
  /** Chanages the option to be optional. */
  def optional(): OptionDef[A, C] = minOccurs(0)
  /** Allows the argument to appear multiple times. */
  def unbounded(): OptionDef[A, C] = maxOccurs(UNBOUNDED)
```

この結果、scopt3 は省略可能な引数のリストだけではなく、省略不可能なオプションもサポートする:

```scala
opt[String]('o', "out") required()
arg[String]("<file>...") optional() unbounded()
```

### カスタム validation

fluent interface を使って、scopt3 はカスタム validation も提供する:

```scala
opt[Int]('f', "foo") action { (x, c) => c.copy(intValue = x) } validate { x =>
  if (x > 0) success else failure("Option --foo must be >0") } validate { x =>
  failure("Just because") }
```

複数の validate 節は全て評価され、全てが `success` に評価されたときのみ成功とされる。

### 不可変パーサと可変パーサの統合

scopt2 において、実装は `generic`、`immutable`、`mutable` という 3つのパッケージに分かれた。しばらくはこの構造を維持したけど、2つのパーサ実装を持つ意義が無いように思われてきた。不変パーサの意義は、パーサを不変的に使うことにある。だからと言って、パーサそのものの実装が不変である必要はないはずだ。

scopt3 において、不変パーシングは `action` メソッドを用いて行われる:

```scala
opt[Int]('f', "foo") action { (x, c) =>
  c.copy(foo = x) } text("foo is an integer property")
```

可変パーシングは `foreach` を用いて行われる:

```scala
opt[Int]('f', "foo") foreach { x =>
  c = c.copy(foo = x) } text("foo is an integer property")
```

内部構造は可変パーサに統合された。これは妥協点だが、微妙に意味が異なる 2つの DSL cake があるよりはいいと思う。

### コマンド

パーサを統合する理由となった動機の一つとしてコマンドの追加がある。この機能は引数の名前そのものが意味を持ち、他のオプションなどを使える状態にする `git [commit|push|pull]` のようなものを定義する機能だ。

```scala
cmd("update") action { (_, c) =>
  c.copy(mode = "update") } text("update is a command.") children(
  opt[Unit]("not-keepalive") abbr("nk") action { (_, c) =>
    c.copy(keepalive = false) } text("disable keepalive"),
  opt[Boolean]("xyz") action { (x, c) =>
    c.copy(xyz = x) } text("xyz is a boolean property")
)
```

scopt3 が進むにつれて Leif さんから多くの役に立つ感想や指摘を tweet やコミットへのコメントという形でいただいた。例えば、 [efe45ed](https://github.com/scopt/scopt/commit/efe45ed99fbc8ceecde4eb0c6f000f7802b8fee1#commitcomment-3352444):

> One problem with the way you've defined Cmd is that it's not positional. The parser wants to find an argument with cmd's name anywhere in the line. That leads to ambiguities if there are optional (or unbounded) arguments in the definition of the parser's options. [...]

> 君の Cmd の定義は位置特定じゃないという問題がある。パーサは cmd の名前を使って行のどの位置でも検索してしまう。これは、パーサにもし省略可能 (かリスト) の引数があった場合に曖昧さにつながる。 [以下略]

これを考慮した結果、コマンドはレベル内で最初の位置に来た場合のみ有効として、コマンド、オプション、引数の何かが判定した即座に他のコマンドは消去されるように変更された。

### 使ってみる

以下が scopt3 の使用例だ:

```scala
val parser = new scopt.OptionParser[Config]("scopt") {
  head("scopt", "3.x")
  opt[Int]('f', "foo") action { (x, c) =>
    c.copy(foo = x) } text("foo is an integer property")
  opt[File]('o', "out") required() valueName("<file>") action { (x, c) =>
    c.copy(out = x) } text("out is a required file property")
  opt[(String, Int)]("max") action { case ((k, v), c) =>
    c.copy(libName = k, maxCount = v) } validate { x =>
    if (x._2 > 0) success else failure("Value <max> must be >0") 
  } keyValueName("<libname>", "<max>") text("maximum count for <libname>")
  opt[Unit]("verbose") action { (_, c) =>
    c.copy(verbose = true) } text("verbose is a flag")
  note("some notes.\n")
  help("help") text("prints this usage text")
  arg[File]("<file>...") unbounded() optional() action { (x, c) =>
    c.copy(files = c.files :+ x) } text("optional unbounded args")
  cmd("update") action { (_, c) =>
    c.copy(mode = "update") } text("update is a command.") children(
    opt[Unit]("not-keepalive") abbr("nk") action { (_, c) =>
      c.copy(keepalive = false) } text("disable keepalive"),
    opt[Boolean]("xyz") action { (x, c) =>
      c.copy(xyz = x) } text("xyz is a boolean property")
  )
}
// parser.parse returns Option[C]
parser.parse(args, Config()) map { config =>
  // do stuff
} getOrElse {
  // arguments are bad, usage message will have been displayed
}
```

scopt2 同様に、これは自動的に usage text を生成する:

<code>
scopt 3.x
Usage: scopt [update] [options] [<file>...]

  -f <value> | --foo <value>
        foo is an integer property
  -o <file> | --out <file>
        out is a required file property
  --max:<libname>=<max>
        maximum count for <libname>
  --verbose
        verbose is a flag
some notes.

  --help
        prints this usage text
  <file>...
        optional unbounded args

Command: update
update is a command.

  -nk | --not-keepalive
        disable keepalive
  --xyz <value>
        xyz is a boolean property
</code>

バグや質問があれば気軽に [github issue](https://github.com/scopt/scopt/issues/new) に報告して下さい。
