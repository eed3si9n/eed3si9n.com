---
title:       "Scala language server using sbt"
type:        story
date:        2017-09-19
draft:       false
promote:     true
sticky:      false
url:         /scala-language-server-using-sbt
aliases:     [ /node/235 ]
tags:        [ "sbt" ]
---

It's been a month since sbt 1.0 shipped, and I can finally sit back and think about sbt server again. Using my weekends time, I started hacking on an implementation of Scala language server on top of sbt server.

### what is a language server?

A language server is a program that can provide language service to editors like Visual Studio Code, Eclipse Che, and Sublime Text 3 via [Language Server Protocol](https://github.com/Microsoft/language-server-protocol). A typical operation might be `textDocument/didOpen`, which tells the server that a source file was opened in the editor.

This is a clever idea since it frees editor authors from being too close to one programming language (like traditional IDEs), and it simultaneously allows language providers to focus on operations. Since it's a JSON-based protocol, it feels more like writing a backend for a web application. Another neat thing is that we don't have to provide all the features at once.

There is already an implementation of Scala language server by Iulian Dragos called [dragos-vscode-scala](https://github.com/dragos/dragos-vscode-scala), which uses ENSIME as a backend. Given that I mostly use Sublime and sbt to code, I figured I can cut the middle and just get to Zinc events.

### sbt server

The idea behind the sbt server is that the user's operations can be expressed a command or a query, and various console outputs are expressed as events (see also [sbt server reboot](http://eed3si9n.com/sbt-server-reboot)). Often times, events such as compiler warnings and test outputs are the key contents that the build user gains value from, not the return value of tasks.

This design fits nicely with language server protocol, which uses the term "notification" for streaming events.

### InitializeResult

To get things started, we first need to say hi to each other. VS Code will send a request called `initialize`, and we need to respond back with [`InitializeResult`](https://github.com/Microsoft/language-server-protocol/blob/master/versions/protocol-2-x.md#initialize). We then translate TypeScript used in Microsoft's spec into GraphQL that we will use for [Contraband](http://www.scala-sbt.org/contraband/):

```bash
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
```

This is used to generate pseudo case classes and JSON bindings. So, the request-response code looks like this:

```scala
  protected def onRequestMessage(request: JsonRpcRequestMessage): Unit = {

    import sbt.internal.langserver.codec.JsonProtocol._

    println(request)
    request.method match {
      case "initialize" =>
        langRespond(InitializeResult(serverCapabilities), Option(request.id))
      case _ => ()
    }
  }
```

### textDocument/didSave

To mimic what I typically do with editor and sbt, let's try calling `compile` when a file is saved. If we ignore the multi-project for now, it becomes a trivial process of adding more pattern matching.

```scala
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
```

### textDocument/publishDiagnostics

Next, let's try displaying red squigglies for compiler errors. It's a bit more involved, but only because we have more datatypes to deal with, and the process is somewhat mechanical. Like we did before, translate TypeScript to GraphQL and let Contraband generate classes.

```bash
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
```

In Zinc, compiler warnings and errors are sent via datatypes called `xsbti.Problem` and `xsbti.Position`, which are based on Scala compiler's reporter and [`Position`](http://www.scala-lang.org/api/2.12.3/scala-reflect/scala/reflect/api/Position.html). Since VS Code uses `Diagnostic` to notify warnings, we need to translate `xsbt.Problem`:

```scala
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
```

When hitting the save button, this will highlight compiler errors.

![image1](/images/lsp0.png)

![image2](/images/lsp1.png)

![image3](/images/lsp2.png)

### summary and future works

sbt server can potentially support Language Server Protocol, a common protocol that are already supported by a number of editors including VS Code and Eclipse Che. This post demonstrated that we can call sbt's `compile` task and display compiler errors.

Next step might be to migrate the current encoding of sbt server to JSON-RPC. Once my basic setup goes into sbt (currently a pull request https://github.com/sbt/sbt/pull/3524), it would be good to open discussion with various others who have already worked in this area and/or shown interest. Also for weekend hackers, this might be a fun way to contribute to the Scala tooling ecosystem.
