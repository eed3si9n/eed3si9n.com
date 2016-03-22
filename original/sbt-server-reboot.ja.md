  [roadmap]: http://eed3si9n.com/sbt-1-roadmap
  [1]: https://groups.google.com/d/msg/sbt-dev/1TvYrLF4ExU/-UnenXRdowIJ
  [sbt-remote-control]: https://github.com/sbt/sbt-remote-control
  [apnylle]: https://twitter.com/apnylle
  [amsterdam]: https://www.youtube.com/watch?v=Wl8QzsZ4lZk&feature=youtu.be&t=35m30s

これは先日書いた [sbt 1.0 ロードマップ][roadmap]の続編だ。この記事では sbt server の新しい実装を紹介する。

sbt server の動機は IDE との統合の改善だ。

> ビルドは、巨大で、可変で、共有された、状態のデバイスだ。ディスクのことだよ! ビルドはディスク上で動作するのもであって、ディスクから逃れることはできない。
>
> -- Josh Suereth、[The road to sbt 1.0 is paved with server][amsterdam] より

マシンに積んであるディスクは根本的にステートフルなものであり、sbt がタスクを並行実行できるのもそれが作用に関する完全なコントロールを持っていることが大前提になっている。同じビルドに対して sbt と IDE を同時に実行していたり、複数の sbt インスタンスを実行している場合は、sbt はビルドの状態に関して一切保証することができない。

sbt server というコンセプトは元々 2013年に[提案された][1]。同時期にその考えの実装として [sbt-remote-control][sbt-remote-control] プロジェクトも始まった。ある時点で sbt 0.13 が安定化して、代わりに Activator が sbt-remote-control を牽引する役目になり、sbt 本体を変えない、JavaScript をクライアントとしてサポートするなどという追加の制約を課せられることになった。

sbt 1.0 を念頭に入れて、僕は sbt server の取り組みをリブートすることにした。sbt の外で何かを作るのではなくて、僕はアンダーエンジニアリングすることを目指している。つまり「オーバーエンジニアリング」の逆で、自動ディスカバリーや自動シリアライゼーションといった僕から見て本質的じゃない既存の前提を一度捨てようと思っている。代わりに、気楽に sbt/sbt コードベースに取り込めるような小さいものがほしい。Lightbend 社は Engineering Meeting といってエンジニア全員が日常から離れた所に集結して議論をしたり、内部でのハッカソン的なことをやる合宿みたいなことを年に数回やっている。2月に美しいブダペストで行われたハッカソンでは sbt server リブートという提案に Johan Andrén ([@apnylle][apnylle])、 Toni Cunei、 Martin Duhem の 3人が乗ってくれた。目標として設置したのは、IntelliJ IDEA に sbt のビルドを実行させるボタンを付けることだ。

### sbt シェルの中身

server の話をする前に少し寄り道をしよう。僕が sbt の事を考えるときは大体タスクの依存グラフとそれを並列処理するエンジンを中心に考えることが多い。

実際にはその上位のレイヤー、`State` の中に `Seq[String]` として保持されているコマンドから一つを処理して、新しい `State` を元に再帰的に呼び出すという逐次的なループある。面白いのは新しい `State` は開始時よりも追加で多くのコマンドを持つようになるかもしれなく、はたまた新しいコマンドを待ちながら IO デバイスに対してブロックすることもありえるということだ。実は sbt シェルはそういう仕組みになっていて、ブロックしてる IO デバイスはニンゲンである僕のことだ。

sbt シェルは sbt の `shell` というコマンドだ。これは短い実装なので簡単に読めるし、読んでおいて役に立つと思う:

<scala>
def shell = Command.command(Shell, Help.more(Shell, ShellDetailed)) { s =>
  val history = (s get historyPath) getOrElse Some(new File(s.baseDir, ".history"))
  val prompt = (s get shellPrompt) match { case Some(pf) => pf(s); case None => "> " }
  val reader = new FullReader(history, s.combinedParser)
  val line = reader.readLine(prompt)
  line match {
    case Some(line) =>
      val newState = s.copy(onFailure = Some(Shell),
        remainingCommands = line +: Shell +: s.remainingCommands).setInteractive(true)
      if (line.trim.isEmpty) newState else newState.clearGlobalLog
    case None => s.setInteractive(false)
  }
}
</scala>

肝はこの一行だ:

<scala>
  val newState = s.copy(onFailure = Some(Shell),
    remainingCommands = line +: Shell +: s.remainingCommands).
</scala>

ニンゲンから聞いてきてコマンドと `shell` コマンドを `remainingCommands` の先頭に追加して、新しい state をコマンドエンジンに返している。流れを説明するために、以下のシナリオを追ってみよう。

1. sbt 起動。小人が `remainingCommands` 列の先頭に `shell` コマンドを追加する。
2. メインループが  `remainingCommands` から最初のコマンドを取り出す。
3. コマンドエンジンが `shell` コマンドを処理して、ニンゲンが何か打ち込むのを待つ。
4. 僕は `"compile"` と打ち込む。`shell` コマンドは `remainingCommand` を `Seq("compile", "shell")` に変える。
5. メインループが  `remainingCommands` から最初のコマンドを取り出す。
6. コマンドエンジンが `"compile"` の意味するものを処理する。(例えば、全てのサブプロジェクトにまたがって `compile in Compile` タスクを実行するという意味かもしれない)
7. ステップ 2 に戻る。

### キューによるマルチプレックス

複数の IO デバイス (ニンゲンとネットワーク) からの入力をサポートするには、JLine の代わりにキューにブロックする必要がある。これらのデバイスを仲介するために `CommandExchange` という概念を作る。

<scala>
private[sbt] final class CommandExchange {
  def subscribe(c: CommandChannel): Unit = ....
  @tailrec def blockUntilNextExec: Exec = ....
  ....
}
</scala>

デバイスを表すために、もう一つ `CommandChannel` という概念も作る。コマンドチャンネルは全二重のメッセージバスで、コマンド実行を発行して、イベントを受信することができる。

### イベントとは?

`CommandChannel` の設計をするためには、少し立ち止まって普段 sbt シェルとどう接しているかを観察する必要がある。例えば `"compile"` と打ち込んだ後に何が起こるかと言うと、`compile` タスクは警告やエラーメッセージをターミナル画面に表示して、最後に `[success]` とか `[error]` と書いて終わる。`compile` タスクの戻り値はビルドユーザには役に立たない。副作用として、このタスクはたまたまファイルシステムに `*.class` も生成していたりする。 `assemlby` タスクや `test` タスクにおいても同様だ。テストを実行すると、その結果はターミナル画面に表示される。

このターミナル画面に表示されるメッセージは、コンパイルエラーやテストの結果など、IDE にとっても役に立つ情報が入っている。もう一度言うが、これらのイベントはタスクの戻り値の型とは別のものだ。(`test` の戻り値の型は `Unit` であるのが良い例。)

とりあえず、コマンドエンジンが今何かを処理してるか、command exchange 待ちで待機しているのかを表す `CommandStatus` というイベントを一つ用意しよう。

### ネットワークチャンネル

便宜上、ここではネットワーククライアントは 1つだけしか考えないことにする。

ワイヤープロトコルは改行文字で区切られた UTF-8 JSON を TCP ソケットに流したものだ。以下が Exec のフォーマットだ:

    { "type": "exec", "command_line": "compile" }

Exec はコマンドの実行を表す。JSON メッセージが受信されると、それは各チャンネルの自分のキューに一旦書き込まれる。

Status イベントのフォーマットはこんな感じだ:

    { "type": "status_event", "status": "processing", "command_queue": ["compile", "server"] }

最後に、ポート番号を指定するために `serverPort` という新しい `Int` のセッティングを導入する。デフォルトではこれはビルドのパスのハッシュから自動で割り当てられる。

以下がコマンドチャンネルに共通のインターフェイスだ:

<scala>
abstract class CommandChannel {
  private val commandQueue: ConcurrentLinkedQueue[Exec] = new ConcurrentLinkedQueue()
  def append(exec: Exec): Boolean =
    commandQueue.add(exec)
  def poll: Option[Exec] = Option(commandQueue.poll)
  def publishStatus(status: CommandStatus, lastSource: Option[CommandSource]): Unit
}
</scala>

### server コマンド

CommandExchange とコマンドチャンネルが何か分かった所で server をコマンドとして実装してみよう。

<scala>
def server = Command.command(Server, Help.more(Server, ServerDetailed)) { s0 =>
  val exchange = State.exchange
  val s1 = exchange.run(s0)
  exchange.publishStatus(CommandStatus(s0, true), None)
  val Exec(source, line) = exchange.blockUntilNextExec
  val newState = s1.copy(onFailure = Some(Server),
    remainingCommands = line +: Server +: s1.remainingCommands).setInteractive(true)
  exchange.publishStatus(CommandStatus(newState, false), Some(source))
  if (line.trim.isEmpty) newState
  else newState.clearGlobalLog
}
</scala>

CommandExchange に対してブロックしている違いを除けば、shell コマンドがやっていることと大体同じだ。上のコードでは　`exchange.run(s0)` はバックグラウンドスレッドを実行して TCP ソケットを listen している。`Exec` が来たら、与えられた行と `"server"` コマンドを先頭に追加する。

これをコマンドとして実装することの利点の一つとして、CI 環境などでのバッチ・モード実行への影響がゼロであることが挙げられる。`sbt compile` と書けば、server は起動されない。

実際に使ってみよう。例えば以下のようなビルドがあるとする:

<scala>
lazy val root = (project in file(".")).
  settings(inThisBuild(List(
      scalaVersion := "2.11.7"
    )),
    name := "hello"
  )
</scala>

ターミナルでそのビルドを開いて、`sbt server` と実行する (1.0.x のカスタム版を使っている):

    $ sbt server
    [info] Loading project definition from /private/tmp/minimal-scala/project
    ....
    [info] Set current project to hello (in build file:/private/tmp/minimal-scala/)
    [info] sbt server started at 127.0.0.1:4574
    >

見ての通り、サーバはポート番号 4574で実行され、これはビルドパスに固有のものだ。次に別のターミナル画面から `telnet 127.0.0.1 4574` と実行する:

    $ telnet 127.0.0.1 4574
    Trying 127.0.0.1...
    Connected to localhost.
    Escape character is '^]'.

以下のように Exec Json を打ち込んで改行する:

    { "type": "exec", "command_line": "compile" }

sbt server 側で以下のように表示されるはずだ:

    > compile
    [info] Updating {file:/private/tmp/minimal-scala/}root...
    [info] Resolving jline#jline;2.12.1 ...
    [info] Done updating.
    [info] Compiling 1 Scala source to /private/tmp/minimal-scala/target/scala-2.11/classes...
    [success] Total time: 4 s, completed Mar 21, 2016 3:00:00 PM

telnet 側はこうなる:

    { "type": "exec", "command_line": "compile" }
    {"type":"status_event","status":"processing","command_queue":["compile","server"]}
    {"type":"status_event","status":"ready","command_queue":[]}

スクリーンショットを取ってみた:

<img src="http://eed3si9n.com/images/sbt-server-reboot1.png" />

この API はワイヤ上の表現のみで定義されていて、case class などが出てこないことに注目してほしい。

### IntelliJ プラグイン

Johan と僕が server 側の作業をしている間 Martin は IntelliJ プラグインの書き方を調べてくれた。プラグインは現在 12700 番に決め打ちされているので、それをビルドに追加する必要がある:

<scala>
lazy val root = (project in file(".")).
  settings(inThisBuild(List(
      scalaVersion := "2.11.7",
      serverPort := 12700
    )),
    name := "hello"
  )
</scala>

この IntelliJ プラグインには "Build on sbt server"、 "Clean on sbt server"、 "Connect to sbt server"　という 3つのボタンがある。まず sbt server をターミナル画面から実行して、次にサーバに接続する。次に、"Build on sbt server" を押せばコンパイルが始まる。

<img src="http://eed3si9n.com/images/sbt-server-reboot2.png" />

うまくいった。telnet と同様、プラグインは現在生の JSON を表示するだけだが、これがコンパイラの警告など役に立つ情報を表示できそうなのは想像に難くない。

### コンソールチャンネル

次のパズルのピースは非ブロッキングな `readLine` だ。ニンゲンを listen するスレッドを実行したいけども、JLine をそのまま使うとブロック呼び出しのせいで他に何もできなくなる。
Mac で試してみた限りではうまくいっている解法が一応あるけど、まだ Linux と Windows ではテストしていない。

`new FileInputStream(FileDescriptor.in)` を以下でラッピングした:

<scala>
private[sbt] class InputStreamWrapper(is: InputStream, val poll: Duration) extends FilterInputStream(is) {
  @tailrec
  final override def read(): Int =
    if (is.available() != 0) is.read()
    else {
      Thread.sleep(poll.toMillis)
      read()
    }
}
</scala>

これでスレッドから `readLine` を呼び出すと、IO にブロックする代わりにに殆どの時間を sleep して過ごす。shell コマンド同様、このスレッドは単一の行を読み込むと終了する。コンソールチャンネルが `CommandExchange` から Status イベントを受信すると、次のコマンドを画面に表示する。これはあたかも誰かがコマンドを打ち込んだかのように見せかけて、外部から Exec コマンドが来たことを表している。

これがうまくいけば、`sbt server` はネットワークからの入力も受け取れるということ以外は、普通の sbt シェルと同様に機能するはずだ。

<img src="http://eed3si9n.com/images/sbt-server-reboot3.png" />

### まとめと今後への課題

- sbt server は既存のアーキテクチャを大きく変えること無くコマンドとして実装できる
- JSONベースのソケット API によって IDE が外部から安全に sbt を操作することができる

sbt コードを変えれるようになったことで、Exec に一意な ID を持たせて、紐付けられたイベントに含めることができるはずだ。こういうのをイメージしている:

    { "type": "exec", "command_line": "compile", "id": "29bc9b"  } // I write this
    {"type":"problem_event","message":"not found: value printl","severity":"error","position":{"lineContent":"printl","sourcePath":"\/temp\/minimal-scala","sourceFile":"file:\/temp\/minimal-scala\/Hello.scals","line":2,"offset":2},"exec_id":"29bc9b"}

コマンドの実行は衝突回避するために逐次計画される必要があるが、最新の `State` に対するクエリ (例えば現在プロジェクトへの参照やセッティング値など) は可能なはずだ。このクエリとその応答もソケットに流すことができるだろう。

ここで使ったソースは以下から公開している:

- [sbt/sbt v0.99.0-reboot tag](https://github.com/sbt/sbt/tree/v0.99.0-reboot)
- [sbt/idea-sbt v0.99.0-reboot tag](https://github.com/sbt/intellij-sbt/tree/v0.99.0-reboot)
