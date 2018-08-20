[pdp8]: https://ja.wikipedia.org/wiki/PDP-8
  [pdp11]: https://ja.wikipedia.org/wiki/PDP-11
  [vax11]: https://ja.wikipedia.org/wiki/VAX
  [rt11]: https://en.wikipedia.org/wiki/RT-11
  [unix]: https://people.eecs.berkeley.edu/~brewer/cs262/unix.pdf
  [vt100]: https://ja.wikipedia.org/wiki/VT100
  [screen]: https://www.gnu.org/software/screen/manual/screen.html#Control-Sequences
  [windows]: https://docs.microsoft.com/en-us/windows/console/console-virtual-terminal-sequences
  [jansi]: https://github.com/fusesource/jansi
  [box]: https://en.wikipedia.org/wiki/Box-drawing_character
  [turner2018]: https://blogs.msdn.microsoft.com/commandline/2018/06/27/windows-command-line-the-evolution-of-the-windows-command-line/#the-windows-console-reboot-and-overhaul

最近リッチなコンソールアプリのことを考えることがある。ただ行を追加していくんじゃなくて、グラッフィック的な事をやっているアプリだ。多分テトリスを書けるぐらいの情報は集めたのでここにまとめておく。

### ANSI X3.64 control sequences

ターミナル画面の任意の位置にテキストを表示するためには、まずターミナル (terminal) とは何かを理解する必要がある。1960年代中盤に各社は [PDP-8][pdp8] などいったミニコンピューターを発売し、これらは [PDP-11][pdp11]、[VAX-11][vax11] と続く。これらは冷蔵庫ぐらいの大きさのコンピューターで、「計算機センター」が購入し、[RT-11][rt11] や元祖 UNIX system といったオペレーティング・システムを走らせ、同時に多くのユーザ (12 ~ 数百人?) をサポートすることができた。ミニコンピュータへ接続するために、ユーザはモノクロ画面とキーボードを合わせた物理端末を使った。端末の中でも最も有名なのは 1978年に DEC社が発売した [VT100][vt100] だ。

VT100 は 80x24文字をサポートし、カーソル制御に ANSI X3.64 標準を採用した初期のターミナルの一つだ。言い換えると、プログラムは文字の列を出力することで任意の位置にテキストを表示することができた。現在の「ターミナル」アプリケーションは、「ターミナル・エミュレータ」と呼ばれることがあるが、それは VT100 といった物理端末をエミュレートしていることに由来する。

VT100 制御シーケンスのレファレンスは以下が参考になる:

- [Console Virtual Terminal Sequences - Windows Console][windows]
- [11.1 Control Sequences - Screen User Manual][screen]

### CUP (Cursor Position)

> `ESC [ <y> ; <x> H` CUP Cursor Position
> 
> *Cursor moves to `<x>; <y>` coordinate within the viewport, where `<x>` is the column of the `<y>` line

ここで `ECS` は `0x1B` を意味する。"hello" と (2, 4) の位置に表示する Scala のコードはこう書ける:

<scala>
print("\u001B[4;2Hhello")
</scala>

<img src='/images/console0.png' style='width: 271px;'>

### CUB (Cursor Backward)

> `ESC [ <n> D` CUB Cursor Backward
>
> Cursor backward (Left) by `<n>`

これはプログレスバーを実装するのに便利な制御シーケンスだ。

<scala>
(1 to 100) foreach { i =>
  val dots = "." * ((i - 1) / 10)
  print(s"\u001B[100D$i% $dots")
  Thread.sleep(10)
}
</scala>

![console1](/images/console1.gif)

### Saving cursor position

> `ESC [ s`
>
> **With no parameters, performs a save cursor operation like DECSC
>
> `ESC [ u`
> 
> **With no parameters, performs a restore cursor operation like DECRC

現在のカーソル位置の保存と復元に使う。

### Text formatting

> `ESC [ <n> m` SGR Set Graphics Rendition
>
> Set the format of the screen and text as specified by `<n>`

このシーケンスを使って、テキストの色を変えることができる。例えば 36 は Foreground Cyan、1 は Bold で 0 がデフォルトへのリセットとなっている。

<scala>
print("\u001B[36mhello, \u001B[1mhello\u001B[0m")
</scala>

<img src='/images/console2.png' style='width: 468px;'>

### ED (Erase in Display)

> `ESC [ <n> J` ED Erase in Display
> 
> Replace all text in the current viewport/screen specified by `<n>` with space characters

`<n>` に `2` を指定すると、ビューポート全体を消去する。

<scala>
print("\u001B[2J")
</scala>

### EL (Erase in Line)

> `ESC [ <n> K` EL  Erase in Line
> 
> Replace all text on the line with the cursor specified by `<n>` with space characters

テキストが上下にスクロールしている場合に行を丸ごと消せると便利だ。`<n>` に `2` を指定するとそれができる:

<scala>
println("\u001B[2K")
</scala>

### SU (Scroll Up)

> `ESC [ <n> S` SU Scroll Up
>
> Scroll text up by `<n>`. Also known as pan down, new lines fill in from the bottom of the screen

例えば、画面の下半分は乗っ取るが、上半分ではテキストをスクロールさせたいとする。Scroll Up シーケンスを使うことでテキストを上方向に移動させることができる。

REPL から実験するには以下の手順を取る:

1. カーソル位置を保存する
2. カーソルを `(1, 4)` に移動させる
3. 1行分スクロールアップする
4. 行を消去する
5. 何かを表示させる
6. カーソル位置を復元する

<scala>
scala> print("\u001B[s\u001B[4;1H\u001B[S\u001B[2Ksomething 1\u001B[u")

scala> print("\u001B[s\u001B[4;1H\u001B[S\u001B[2Ksomething 2\u001B[u")

scala> print("\u001B[s\u001B[4;1H\u001B[S\u001B[2Ksomething 3\u001B[u")
</scala>

### Jansi

JVM上には [Jansi][jansi] というライブラリがあって ANSI X3.64 制御シーケンスのサポートを提供する。Windows でシーケンスが無い場合にシステムAPI を使ってエミュレートするといったこともやってくれるらしい。

カーソル位置の例は Jansi を使うとこう書ける。

<scala>
scala> import org.fusesource.jansi.{ AnsiConsole, Ansi }
import org.fusesource.jansi.{AnsiConsole, Ansi}

scala> AnsiConsole.out.print(Ansi.ansi().cursor(6, 10).a("hello"))

         hello
</scala>

### Box drawing characters

VT100 のイノベーションの一つとして箱を描くための拡張文字を追加したということが挙げられる。現在これらは、Unicode [box-drawing symbols][box] に取り込まれている。

<code>
 ┌───┐
 │     │
 └───┘
</code>

以下は箱とテトリスのブロックを表示する小さなアプリだ。

<scala>
package example

import org.fusesource.jansi.{ AnsiConsole, Ansi }

object ConsoleGame extends App {
  val b0 = Ansi.ansi().saveCursorPosition().eraseScreen()
  val b1 = drawbox(b0, 2, 6, 20, 5)
  val b2 = b1
    .bold
    .cursor(7, 10)
    .a("***")
    .cursor(8, 10)
    .a(" * ")
    .reset()
    .restoreCursorPosition()

  AnsiConsole.out.println(b2)

  def drawbox(b: Ansi, x0: Int, y0: Int, w: Int, h: Int): Ansi = {
    require(w > 1 && h > 1)
    val topStr = "┌".concat("─" * (w - 2)).concat("┐")
    val wallStr = "│".concat(" " * (w - 2)).concat("│")
    val bottomStr = "└".concat("─" * (w - 2)).concat("┘")
    val top = b.cursor(y0, x0).a(topStr)
    val walls = (0 to h - 2).toList.foldLeft(top) { (b: Ansi, i: Int) =>
       b.cursor(y0 + i + 1, x0).a(wallStr)
     }
    walls.cursor(y0 + h - 1, x0).a(bottomStr)
  }
}
</scala>

<img src='/images/console3.png' style='width: 182px;'>


### BuilderHelper データ型

Jansi を使っていて個人的に気になるのは、お絵描きを合成しようとすると `Ansi` オブジェクトを正しい順番で渡して回る必要があるということだ。これは State データ型を使うことで簡単に解決する。ただし、State という名前がゲームの状態管理と紛らわしいので、ここでは `BuilderHelper` と呼んでしまう。

<scala>
package example

class BuilderHelper[S, A](val run: S => (S, A)) {
  def map[B](f: A => B): BuilderHelper[S, B] = {
    BuilderHelper[S, B] { s0: S =>
      val (s1, a) = run(s0)
      (s1, f(a))
    }
  }

  def flatMap[B](f: A => BuilderHelper[S, B]): BuilderHelper[S, B] = {
    BuilderHelper[S, B] { s0: S =>
      val (s1, a) = run(s0)
      f(a).run(s1)
    }
  }
}

object BuilderHelper {
  def apply[S, A](run: S => (S, A)): BuilderHelper[S, A] = new BuilderHelper(run)
  def unit[S](run: S => S): BuilderHelper[S, Unit] = BuilderHelper(s0 => (run(s0), ()))
}
</scala>

これを使うと描画コードをこんなふうに書けるようになる:

<scala>
package example

import org.fusesource.jansi.{ AnsiConsole, Ansi }

object ConsoleGame extends App {
  val drawing: BuilderHelper[Ansi, Unit] =
    for {
      _ <- Draw.saveCursorPosition
      _ <- Draw.eraseScreen
      _ <- Draw.drawBox(2, 4, 20, 5)
      _ <- Draw.drawBlock(10, 5)
      _ <- Draw.restoreCursorPosition
    } yield ()

  val result = drawing.run(Ansi.ansi())._1
  AnsiConsole.out.println(result)
}

object Draw {
  def eraseScreen: BuilderHelper[Ansi, Unit] =
    BuilderHelper.unit { _.eraseScreen() }

  def saveCursorPosition: BuilderHelper[Ansi, Unit] =
    BuilderHelper.unit { _.saveCursorPosition() }

  def restoreCursorPosition: BuilderHelper[Ansi, Unit] =
    BuilderHelper.unit { _.restoreCursorPosition() }

  def drawBlock(x: Int, y: Int): BuilderHelper[Ansi, Unit] = BuilderHelper.unit { b: Ansi =>
    b.bold
      .cursor(y, x)
      .a("***")
      .cursor(y + 1, x)
      .a(" * ")
      .reset
  }

  def drawBox(x0: Int, y0: Int, w: Int, h: Int): BuilderHelper[Ansi, Unit] = BuilderHelper.unit { b: Ansi =>
    require(w > 1 && h > 1)
    val topStr = "┌".concat("─" * (w - 2)).concat("┐")
    val wallStr = "│".concat(" " * (w - 2)).concat("│")
    val bottomStr = "└".concat("─" * (w - 2)).concat("┘")
    val top = b.cursor(y0, x0).a(topStr)
    val walls = (0 to h - 2).toList.foldLeft(top) { (bb: Ansi, i: Int) =>
       bb.cursor(y0 + i + 1, x0).a(wallStr)
     }
    walls.cursor(y0 + h - 1, x0).a(bottomStr)
  }
}
</scala>

`b0`, `b1`, `b2` といった変数をいちいち作るのを回避しているだけなので、こっちのほうがかえって分かりづらいという人は `BuilderHelper` を使わなくても大丈夫。

### 入力シーケンス

ここまでは、プログラム側が送信する制御シーケンスを見てきたが、ターミナル側もキーボードを使って同じプロトコルでプログラムに話すことができる。ANSI X3.64 互換モード上では VT100 の矢印キーはそれぞれ CUU (Cursor Up)、CUD (Cursor Down)、CUF (Cursor Forward)、CUB (Cursor Back) を送信した。この振る舞いはターミナルエミュレータである iTerm2 にも受け継がれている。

つまり、左矢印キーを押下すると `ESC + "[D"`、つまり `"\u001B[D"` が標準入力に送られる。標準入力から 1バイトづつ読み込んで制御シーケンスをパースすることが可能だ。

<scala>
var isGameOn = true
var pending = ""
val escStr = "\u001B"
val escBracket = escStr.concat("[")
def clearPending(): Unit = { pending = "" }
while (isGameOn) {
  if (System.in.available > 0) {
    val x = System.in.read.toByte
    if (pending == escBracket) {
      x match {
        case 'A' => println("Up")
        case 'B' => println("Down")
        case 'C' => println("Right")
        case 'D' => println("Left")
        case _   => ()
      }
      clearPending()
    } else if (pending == escStr) {
      if (x == '[') pending = escBracket
      else clearPending()
    } else
      x match {
        case '\u001B' => pending = escStr
        case 'q'      => isGameOn = false
        // Ctrl+D to quit
        case '\u0004' => isGameOn = false
        case c        => println(c)
      }
  } // if
}
</scala>

簡単なゲームを書くにはこの方法で十分だと思うが、組み合わせがもっと複雑になったり Windows ターミナルの振る舞いなども勘案すると結構面倒になるかもしれない。

### JLine2 を使うか?

JVM 上には JLine2 というライブラリがあって、これは [KeyMap](https://github.com/jline/jline2/blob/jline-2.14.6/src/main/java/jline/console/KeyMap.java) という概念を実装する。KeyMap はバイトシーケンスを [Operation](https://github.com/jline/jline2/blob/jline-2.14.6/src/main/java/jline/console/Operation.java) に写像する。

JLine はもともと、Bash とか sbt shell みたいな履歴とかタブ補完があるラインエディタのためのものなので Operation もそれを反映している。例えば、上矢印は `Operation.PREVIOUS_HISTORY` に関連付けされている。JLine2 を使うとさっきのコードはこう書ける:

<scala>
import jline.console.{ ConsoleReader, KeyMap, Operation }
var isGameOn = true
val reader = new ConsoleReader()
val km = KeyMap.keyMaps().get("vi-insert")
while (isGameOn) {
  val c = reader.readBinding(km)
  val k: Either[Operation, String] =
    if (c == Operation.SELF_INSERT) Right(reader.getLastBinding)
    else Left(c match { case op: Operation => op })
  k match {
    case Right("q")                   => isGameOn = false
    case Left(Operation.VI_EOF_MAYBE) => isGameOn = false
    case _                            => println(k)
  }
}
</scala>

個人的には `System.in` を直に読みにいく率直さが嫌いではないんだけども、JLine2 の方がキレイにまとまっている感じはするので、これも自分が納得できる方法を使えばいいと思う。

### バックグラウンドでキーボードに耳をすます

`System.in` のコードで気づくのはキーボード入力を待つのはファイルの読み込みと等価であることだ。もう一つ気づくのは、ほとんどのマイクロ秒をユーザを待つことに費やすということだ。ユーザの入力はバックグラウンドで捕獲して、定期的にこっちに都合がいいタイミングで処理を行うことができればいいと思う。

キープレスのイベントを Apache Kafka に書き込めばこれができる。というのは冗談。だけど、半分だけ冗談で、Kafka はプログラムがイベントを書き込めるログ・システムで、他のプログラムは各自好きなときに読みにいけるという特性がある。

こんな感じで書いてみた:

<scala>
import jline.console.{ ConsoleReader, KeyMap, Operation }
import scala.concurrent.{ blocking, Future, ExecutionContext }
import java.util.concurrent.atomic.AtomicBoolean
import java.util.concurrent.ArrayBlockingQueue

val reader = new ConsoleReader()
val isGameOn = new AtomicBoolean(true)
val keyPressses = new ArrayBlockingQueue[Either[Operation, String]](128)

import ExecutionContext.Implicits._

// inside a background thread
val inputHandling = Future {
  val km = KeyMap.keyMaps().get("vi-insert")
  while (isGameOn.get) {
    blocking {
      val c = reader.readBinding(km)
      val k: Either[Operation, String] =
        if (c == Operation.SELF_INSERT) Right(reader.getLastBinding)
        else Left(c match { case op: Operation => op })
      keyPressses.add(k)
    }
  }
}

// inside main thread
while (isGameOn.get) {
  while (!keyPressses.isEmpty) {
    Option(keyPressses.poll) foreach { k =>
      k match {
        case Right("q")                   => isGameOn.set(false)
        case Left(Operation.VI_EOF_MAYBE) => isGameOn.set(false)
        case _                            => println(k)
      }
    }
  }
  // draw game etc..
  Thread.sleep(100)
}
</scala>

スレッドを立ち上げるために、`scala.concurrent.Future` をデフォルトの global execution context で使っている。これはユーザからの入力待ちでブロックして、受け取ったキープレスは `ArrayBlockingQueue` に追加する。

実行して、左矢印、右矢印、`'q'` と押すと以下のように表示される:

<code>
Left(BACKWARD_CHAR)
Left(FORWARD_CHAR)
[success] Total time: 3 s
</code>

### キープレスの処理

これで現在のブロックをキープレスに応じて動かせるようになった。位置を追跡するために、`GameState` データ型を定義する:

<scala>
  case class GameState(pos: (Int, Int))
  var gameState: GameState = GameState(pos = (6, 4))
</scala>

次に、状態遷移関数を定義する:

<scala>
  def handleKeypress(k: Either[Operation, String], g: GameState): GameState =
    k match {
      case Right("q") | Left(Operation.VI_EOF_MAYBE) =>
        isGameOn.set(false)
        g
      // Left arrow
      case Left(Operation.BACKWARD_CHAR) =>
        val pos0 = gameState.pos
        g.copy(pos = (pos0._1 - 1, pos0._2))
      // Right arrow
      case Left(Operation.FORWARD_CHAR) =>
        val pos0 = g.pos
        g.copy(pos = (pos0._1 + 1, pos0._2))
      // Down arrow
      case Left(Operation.NEXT_HISTORY) =>
        val pos0 = g.pos
        g.copy(pos = (pos0._1, pos0._2 + 1))
      // Up arrow
      case Left(Operation.PREVIOUS_HISTORY) =>
        g
      case _ =>
        // println(k)
        g
    }
</scala>

この `handleKeyPress` をメインの while ループから呼び出す:

<scala>
  // inside the main thread
  while (isGameOn.get) {
    while (!keyPressses.isEmpty) {
      Option(keyPressses.poll) foreach { k =>
        gameState = handleKeypress(k, gameState)
      }
    }
    drawGame(gameState)
    Thread.sleep(100)
  }
  
  def drawGame(g: GameState): Unit = {
    val drawing: BuilderHelper[Ansi, Unit] =
      for {
        _ <- Draw.drawBox(2, 2, 20, 10)
        _ <- Draw.drawBlock(g.pos._1, g.pos._2)
        _ <- Draw.drawText(2, 12, "press 'q' to quit")
      } yield ()
    val result = drawing.run(Ansi.ansi())._1
    AnsiConsole.out.println(result)
  }
</scala>

実行すると以下のようになる:

![console4](/images/console4.gif)

### ログと組み合わせる

これを Scroll Up テクニックと合わせてみよう。

<scala>
  var tick: Int = 0
  // inside the main thread
  while (isGameOn.get) {
    while (!keyPressses.isEmpty) {
      Option(keyPressses.poll) foreach { k =>
        gameState = handleKeypress(k, gameState)
      }
    }
    tick += 1
    if (tick % 10 == 0) {
      info("something ".concat(tick.toString))
    }
    drawGame(gameState)
    Thread.sleep(100)
  }

  def info(msg: String): Unit = {
    AnsiConsole.out.println(Ansi.ansi()
      .cursor(5, 1)
      .scrollUp(1)
      .eraseLine()
      .a(msg))
  }
</scala>

ここでは `(1, 5)` に毎秒スクロールアップさせながらログを表示している。上書きしていないため、うまくいけばスクロールバッファーには全てのログが残るはずだ。

![console5](/images/console5.gif)

ANSI 制御シーケンスを使ったテクニックは他にも色々あるはずだ。ここでは Jansi や JLine2 といった Java のライブラリを使ったが、ここで行ったことは特に JVM やライブラリに依存したことは行っていない。

### Windows 10 に関して

2018年6月に書かれたブログ記事 [Windows Command-Line: The Evolution of the Windows Command-Line][turner2018] によると:

> 特に Console が、*NIX 互換のシステムでは当たり前となっている ANSI/VT シーケンスのパーシングとレンダリングができないことが問題となった。*NIX の世界では ANSI/VT シーケンスが広範囲で使われており、リッチでカラフルなテキストやテキストベースの UI のレンダリングが行われている。WSL を構築しても、ユーザが Linux のツールを正しく使えなければ無用の長物だ。
> 
> これを受けて 2014年に Console のコードベースを解きほぐし、理解し、改善することを任務とする新たな小さなチームが立ち上がった。当時既にこのコードベースは 28才で、担当のデベロッパよりも年上だった。

この記事によると、Windows 10 の Console は VT100 制御シーケンス互換であるみたいだ。これで、何故 Microsoft社にちゃんとしたレファレンスガイドがあるのかの説明がついた。

### まとめ

リッチなコンソールアプリの基盤は、1970年代の [VT100][vt100] のような物理端末、そしてそれらのカーソル制御、テキスト整形のためのバイトシーケンスを標準化した ANSI X3.64 制御シーケンスにある。現代のターミナルアプリケーションはこれらターミナルのふるまいをエミュレートする。

そのため、良いターミナルアプリを前提とすれば、[制御シーケンス][windows]を `println(...)` して、標準入力を読み込む能力さえあればリッチなコンソールアプリを書くことができる。これは、どのプログラミング言語でも可能なはずだ。

JAnsi や JLine2 といったライブラリはコードを読みやすい形にきれいにするのには便利だ。また、Windows のためのフォールバック機能も提供すると謳っているが、それがモダンな Windows 10 環境か古い Windows 上でどこまでうまくいくのかは分からない。