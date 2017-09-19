sbt 1.0 がリリースされてからもう一ヶ月になり、やっと少し落ち着いて sbt server のことを考えれるようになった。週末の時間をさいて最近 Scala language server (言語サーバー) を sbt server 上にハックしている。

### language server って何?

language server とは、Visual Studio Code、 Eclipse Che、 Sublime Text 3 といったエディタに対して [Language Server Protocol](https://github.com/Microsoft/language-server-protocol) を通じて何らかの言語サービスを提供するプログラムのことだ。演算の一例を挙げると `textDocument/didOpen` はエディタ内でソースファイルが開かれたことをサーバーに伝える。

これは賢いアイディアで、エディタ作者を (従来の IDE のように) 単一の言語にべったりになることから解放し、また同時に言語プロバイダーは「演算」に専念すればいいようになる。JSON ベースのプロトコルなので、web アプリのバックエンドを書いている感覚に近い。もう一つ嬉しいのは、一度に全ての機能を提供しなくてもいいことだ。

Scala language server は、Iulian Dragosさんによる [dragos-vscode-scala](https://github.com/dragos/dragos-vscode-scala) という実装が既にあって、それは ENSIME をバックエンドとして使う。僕は、だいたい Sublime と sbt だけでコードを書いているので、中抜きして直接 Zinc のイベントを使えばいいんじゃないかと思った。

### sbt server

sbt server の考え方としては、ユーザの演算はコマンドとクエリとして表現でき、コンソールに表示される様々な出力はイベントとして表現できるというものだ ([sbt server リブート](http://eed3si9n.com/ja/sbt-server-reboot)も参照)。多くの場合、ビルドユーザが価値を見出すのはタスクの戻り値ではなく、コンパイラの警告やテストの出力といったコンテンツだ。

この設計は、language server protocol にもよくマッチしていて、彼らはストリームされるイベントに対して「通知」 (notification) という用語を使っている。

### InitializeResult

まず手始めに、お互いに挨拶をする作法となっている。VS Code は、`initialize` というリクエストを送信するので、それに対して [`InitializeResult`](https://github.com/Microsoft/language-server-protocol/blob/master/versions/protocol-2-x.md#initialize) で返事をする。Microsoft社の書いた仕様は TypeScript で書かれているので、それを [Contraband](http://www.scala-sbt.org/contraband/) で使えるように GraphQL に翻訳する:

<code>
type InitializeResult {
  ## The capabilities the language server provides.
  capabilities: sbt.internal.langserver.ServerCapabilities!
}

type ServerCapabilities {
  textDocumentSync: sbt.internal.langserver.TextDocumentSyncOptions

  ## The server provides hover support.
  hoverProvider: Boolean
}

....
</code>

これは、疑似 case class と JSON バインディングを生成するのに使われる。リクエスト・レスポンスのコードはこんな感じになる:

<scala>
  protected def onRequestMessage(request: JsonRpcRequestMessage): Unit = {

    import sbt.internal.langserver.codec.JsonProtocol._

    println(request)
    request.method match {
      case "initialize" =>
        langRespond(InitializeResult(serverCapabilities), Option(request.id))
      case _ => ()
    }
  }
</scala>

### textDocument/didSave

僕がエディタと sbt で通常やっていることにならってファイルの保存時に `compile` を呼んでみよう。マルチ・プロジェクトを無視すると、パターンマッチングを追加するだけの簡単な処理となる。

<scala>
  protected def onRequestMessage(request: JsonRpcRequestMessage): Unit = {

    import sbt.internal.langserver.codec.JsonProtocol._

    println(request)
    request.method match {
      case "initialize" =>
        langRespond(InitializeResult(serverCapabilities), Option(request.id))
      case "textDocument/didSave" =>
        append(Exec("compile", Some(request.id), Some(CommandSource(name))))
      case _ => ()
    }
  }
</scala>

### textDocument/publishDiagnostics

次に、コンパイラーのエラーを赤の波線で表示させてみる。これは、もうちょっと込み入っているが、扱う必要があるデータ型が多いというだけで、実際の作業は単純作業に近い。以前通り TypeScript を GraphQL へ翻訳して、Contraband にクラスを生成させる。

<code>
## Position in a text document expressed as zero-based line and zero-based character offset.
## A position is between two characters like an 'insert' cursor in a editor.
type Position {
  ## Line position in a document (zero-based).
  line: Long!

  ## Character offset on a line in a document (zero-based).
  character: Long!
}

....

## Represents a diagnostic, such as a compiler error or warning.
## Diagnostic objects are only valid in the scope of a resource.
type Diagnostic {
  ## The range at which the message applies.
  range: sbt.internal.langserver.Range!

  ## The diagnostic's severity. Can be omitted. If omitted it is up to the
  ## client to interpret diagnostics as error, warning, info or hint.
  severity: Long

  ## The diagnostic's code. Can be omitted.
  code: String

  ## A human-readable string describing the source of this
  ## diagnostic, e.g. 'typescript' or 'super lint'.
  source: String

  ## The diagnostic's message.
  message: String!
}
</code>

Zinc では、コンパイラ警告やエラーは `xsbti.Problem` と `xsbti.Position` というデータ型で送られ、それぞれ Scala コンパイラの reporter と [`Position`](http://www.scala-lang.org/api/2.12.3/scala-reflect/scala/reflect/api/Position.html) にもとづいている。VS Code は警告の通知に `Diagnostic` を用いるので、`xsbt.Problem` から変換する必要がある:

<scala>
  protected def onObjectEvent(event: ObjectEvent[_]): Unit = {
    import sbt.internal.langserver.codec.JsonProtocol._

    val msgContentType = event.contentType
    msgContentType match {
      case "xsbti.Problem" =>
        val p = event.message.asInstanceOf[xsbti.Problem]
        toDiagnosticParams(p) map { d =>
          println(s"sending $d")
          langNotify("textDocument/publishDiagnostics", d)
        }
      case _ => ()
    }
  }

  def toDiagnosticParams(problem: xsbti.Problem): Option[PublishDiagnosticsParams] = {
    val pos = problem.position
    for {
      sourceFile <- pos.sourceFile.toOption
      line0 <- pos.line.toOption
      pointer0 <- pos.pointer.toOption
    } yield {
      val line = line0.toLong - 1L
      val pointer = pointer0.toLong
      PublishDiagnosticsParams(
        sourceFile.toURI.toString,
        Vector(
          Diagnostic(
            Range(start = Position(line, pointer), end = Position(line, pointer + 1)),
            Option(toDiagnosticSeverity(problem.severity)),
            None,
            Option("sbt"),
            problem.message
          ))
      )
    }
  }
</scala>

保存ボタンを押すと、コンパイラエラーが表示されるようになった。

![image1](/images/lsp0.png)

![image2](/images/lsp1.png)

![image3](/images/lsp2.png)

### まとめと今後への課題

sbt server は、VS Code や Eclipse Che などのいくつかのエディタで既に採用されている共通プロトコルである Language Server Protocol をサポートすることが可能だ。本稿では、sbt の `compile` を呼び出してコンパイラエラーを表示させる所までをデモした。

次のステップとして考えられるのは現在の sbt server のエンコードを JSON-RPC に移行させることだ。セットアップ的なことは今回揃えたので、それが sbt に採用されれば (現在は pull request の段階 <https://github.com/sbt/sbt/pull/3524>)、この分野で既に活動してる人たちや興味を示した人たちとディスカッションを始める機会となる。また、週末ハッカーの人にとっても、Scala のツーリング・エコシステムへコントリビュートする面白い方法の一つになるんじゃないかと思う。
