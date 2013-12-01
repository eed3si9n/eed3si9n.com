  [1]: https://groups.google.com/d/msg/simple-build-tool/1c7unObqjJ8/3Wr30wMWKwEJ
  [1001]: https://github.com/sbt/sbt/issues/1001

本稿では sbt 0.13 における実行意味論 (execution semantics) とタスクの逐次化 (task sequencing) についてみていこうと思う。まずは前提となる背景を大まかに復習して、次に逐次的タスク (sequential task) を追加するために書いた実験的プラグイン `sbt-sequential` を紹介したい。

## 背景

Mark 曰く:

> sbt のモデルは副作用をタスクに局所化させることで、依存性さえ満たせば、タスクはいつでも実行できるというものだ。この利点はデフォルトで並列であることで、実際により速いビルドを可能とすることだ。

言い替えると、sbt を使ったビルド定義はタスク間の依存性のみを定義していて、これらのタスクがどのタイミングで始動されるかは sbt によって自動的に計算される。これをちゃんと理解するために、まず副作用を持った Scala コードの実行意味論をみてみよう。

### 直列実行 (serial execution)

<scala>
class Test {
  def startServer(): Unit = {
    println("starting...")
    Thread.sleep(500)
  }
  def stopServer(): Unit = {
    println("stopping...")
    Thread.sleep(500)
  }
  def numberTask: Int = 1
  
  def integrationTest0(): Int = {
    val n = numberTask
    startServer()
    println("testing...")
    Thread.sleep(1000)
    stopServer()
    n
  }
}
</scala>

誰かが `integrationTest0()` を呼び出すと、コードは書かれたのと全く同じ順序で実行される。まず `numberTask` が呼び出され、次に `startServer()` が呼ばれこの実行は 0.5 秒間かかる。メソッドが実行している間は戻ってくるまで制御はブロックされる。次に `println("testing...")` が呼ばれるといった具合だ。このような順序の入れ替えを伴わず、またオーバーラップを伴わない実行は**直列実行** (serial execution) と呼ばれる。

### 直列化可能な実行 (serializable execution)

あるプログラムの実行 (program execution) の結果が直列実行の結果と等価であるとき、それは**直列化可能** (serializable) と言われる。そのような実行は直列実行と「意味論的に等価である」(semantically equivalent) もしくは "*as-if serial*" と言うこともできる。

例えば、`integrationTest0` メソッド内において、全般的な結果を変えずに `val n = numberTask` を `startServer()` の後に移動することができる。さらに、結果を変えることなく `startServer()` の実行を `numberTask` の実行とインターリーブ (interleave; 同時実行させる) させることもできる:

<scala>
class Test {
  def startServer(): Unit = {
    println("starting...")
    Thread.sleep(500)
  }
  def stopServer(): Unit = {
    println("stopping...")
    Thread.sleep(500)
  }
  def numberTask: Int = 1
  
  def integrationTest1(): Int = {
    startServer()
    val n = numberTask
    println("testing...")
    Thread.sleep(1000)
    stopServer()
    n
  }
}
</scala>

### 並行実行 (concurrent execution)

似たようなビルド定義を sbt を使って書こうすると、まずはこのようになると思う。

<scala>
val startServer = taskKey[Unit]("start server")
val stopServer = taskKey[Unit]("stop server")
val numberTask = taskKey[Int]("number task")
val integrationTest2 = taskKey[Int]("integration test")

startServer := {
  println("starting...")
  Thread.sleep(500)
}

stopServer := {
  println("stopping...")
  Thread.sleep(500)
}

numberTask := 1

integrationTest2 := {
  val n = numberTask.value
  startServer.value
  println("testing...")
  Thread.sleep(1000)
  stopServer.value
  n
}
</scala>

一見うまくいっているように見えるけども、プログラムの実行は並行 (concurrent) で、順序を無視した (out-of-order) なものとなっている。上の例では、`startServer`、`numberTask`、`stopServer` はタスクの始めに並行的なコンテキストで実行される。並列で実行されるかもしれないし、されないかもしれないけども、順序は保証されない。これらの依存タスクが戻ってきた時点で残りの Scala コードが実行される。sbt では命令型のスタイルでコードを書くのではなく、タスクの依存性のグラフを構築するため、このような並行実行でも普通は問題無い。

### andFinally と doFinally

しかし、タスクの逐次化というトピックは再三メーリングリスト、StackOverflow、カンファレンス、ポッドキャストなどの場で議論されてきた。以下がいくつかの例だ:

- [Sequential chaining operators for Initialize](https://groups.google.com/d/msg/simple-build-tool/Yg17YxQ2su0/NCjwZx6IAIwJ)
- [FYI found the way how to create wrapper for stb.Task[Unit] without dependsOn](https://groups.google.com/d/msg/simple-build-tool/7CMIQTCQdOY/u_uxTy0bWgMJ)
- [Concurrency semantics (aka task sequencing) in 0.13 syntax][1]

sbt でタスクを逐次化するための現行の解決方法は普通のタスク依存性 `task.value` (または `dependsOn`) を使うことだ。cleanup 処理のために sbt は `andFinally` と `doFinally` という機能も用意する。

`andFinally` は任意の Scala ブロックを追加した新たなタスクを作成する:

<scala>
lazy val integrationTestBody = Def.task {
  startServer.value
  val n = 1
  Thread.sleep(2000)
  n
}

lazy val integrationTestImpl = integrationTestBody andFinally {
  println("stop")
  IO.delete(file("server.txt"))
}

integrationTest3 := integrationTestImpl.value
</scala> 

もしも cleanup コードがタスの場合は `doFinally` もある:

<scala>
lazy val integrationTestBody = Def.task {
  startServer.value
  val n = 1
  Thread.sleep(2000)
  n
}

integrationTest4 <<= (integrationTestBody, stopServer) { (body, stop) =>
  body doFinally stop
}
</scala>

### addCommandAlias

いくつかのタスクをシェルから打ち込んだかのように実行するだけが目的ならば、sbt はコマンドに対してエイリアスを定義する `addCommandAlias` も提供する。以下を `build.sbt` 内に追加する:

<scala>
addCommandAlias("sts", ";startServer;test;stopServer")
</scala>

sbt シェル内から `sts` と打ち込むと指定されたタスクが順次実行される。

先ほど挙げたリンクの一つは、旧 sbt メーリングリストに僕が投稿したもので、最近 github で立てられた興味深い議論 [Make it easier to control the sequencing of Tasks (#1001)][1001] の中でも言及された。

## sbt-sequential

sbt-sequential は僕が[このスレッド][1]と [#1001][1001] で提案した "sequential" マクロの実装だ。(提案した時点では、このようなマクロを書くのがどれだけ複雑化を分かってなかった)

sbt-sequential は `sbt.Def` オブジェクトに対して `sequentialTask[T](t: T)` メソッドを注入して逐次的タスクを追加する。例えば、`integrationTest2` は以下のように書き換えれる:

<scala>
val startServer = taskKey[Unit]("start server")
val stopServer = taskKey[Unit]("stop server")
val numberTask = taskKey[Int]("number task")
val integrationTest5 = taskKey[Int]("integration test")

startServer := {
  println("starting...")
  Thread.sleep(500)
}

stopServer := {
  println("stopping...")
  Thread.sleep(500)
}

numberTask := 1

val integrationTestImpl = Def.sequentialTask {
  val n = numberTask.value
  startServer.value
  println("testing...")
  Thread.sleep(1000)
  stopServer.value
  n
}

integrationTest5 := integrationTestImpl.value
</scala>

`integrationTest5` の実行順序は直列実行をエミュレートする。この特定の例においては、副作用の観測可能な結果は直列実行の場合と同一になるはずだ。普通のタスクと違って、実行は各行ごとにブロックされる。

これは `Def.sequentialTask` ブロックに渡されたコードを自動的に変換することで達成する (一般的にマクロはコード変換を行う)。この変換は各行を人工的なタスクでラッピングして、それらを全て flatMap して逐次的に実行する。

### タスク依存性

`Def.sequentialTask` はタスクの依存性には手を付けない。ブロック内から参照されるタスク間に新たな依存性を導入することはしない。また、より重要な点として、タスク間に既存の依存性があった場合はそれを除去しない。

例えば、何らかの理由で `startServer` タスクが `stopServer` タスクに依存した場合は、`stopServer` タスクは `startServer` タスクの前に実行され、また一度しか実行されない。

### 直列化の粒度

直列的な意味論を持つプログラミング言語では、普通明示的な左から右への (left-to-right) 順序付けがある。例えば、関数 `f` に `f(arg0, arg1, arg2)` のように 3つの引数を渡した場合は、`arg0` が最初に評価される。

sbt-sequential は各行、正確には最上レベルの式、のみをラッピングするため、部分式を直列化しようとしない。そのため `f(arg0.value, arg1.value, arg2.value)` があった場合、全てのタスクは並列に実行される。これを回避するには val を定義する必要がある。

### flatMap

このマクロの実装は [#1001][1001] での Mark の以下のコメントにインスパイヤされた:

> sequence の実装は簡単で、future のように `flatMap` (別名 `taskDyn`) を使うだけでいい:

<scala>
def sequence(tasks: List[Initialize[Task[Unit]]]): Initialize[Task[Unit]] =
  tasks match {
    case Nil => Def.task{ () }
    case x :: xs => Def.taskDyn { val _ = x.value; sequence(xs) }
  }
</scala>

`taskDyn` に関する説明は [Dynamic Computations with Def.taskDyn](https://github.com/sbt/sbt/blob/818f4f96fb4885adf8bbd2f43c2c1341022d22b2/src/sphinx/Detailed-Topics/Tasks.rst#dynamic-computations-with-deftaskdyn) にもある:

> あるタスクの実行結果を使って次に評価するタスクを決定できれば便利なことがある。これは `Def.taskDyn` を使って実現できる。実行時に依存性を導入するため、`taskDyn` の戻り値は動的タスクと呼ばれる。

### 展開されたコード

概念的にはコードは以下のように展開される:

<scala>
// before
val integrationTestImpl = Def.sequentialTask {
  val n = numberTask.value
  startServer.value
  println("testing...")
  Thread.sleep(1000)
  stopServer.value
  n
}

// after
val integrationTestImpl: Def.Initialize[Task[Int]] = {
  var v0: Int = 0
  val t0 = Def.task { v0 = startServer.value; () }
  val t1 = Def.taskDyn { val _ = t0.value; Def.task { startServer.value; () } }
  val t2 = Def.taskDyn { val _ = t1.value; Def.task { println("testing..."); () } }
  val t3 = Def.taskDyn { val _ = t2.value; Def.task { Thread.sleep(1000); () } }
  val t4 = Def.taskDyn { val _ = t3.value; Def.task { stopServer.value; () } }
  Def.taskDyn { val _ = t4.value; Def.task { v0 } }
}
</scala>

見てのとおりコードは `Def.taskDyn` を使った Mark の `sequence` に似ている。違いとしては普通の Scala コードを混ぜ込めることと、最後に得られる型として `Def.Initialize[Task[Int]]` をキープできたことだ。

`t0` と最後の `Def.taskDyn` の両方から参照できるように `val n` は `var v0` に変換する必要があった。

マクロ展開をデバックしやすいように `Def.debugSequentialTask` も追加した。これはコードの書き換えを行った後その結果を例外として投げるというものだ。実行してマクロがさらに展開されいるのを確認してみてほしい。

### まとめ

sbt のタスク依存性グラフは、柔軟性の高いビルド定義と並行な実行順序を両立するものだ。多くの場合それで構わないけども、たまにタスクをブロックして逐次的に実行したいなと思うこともある。

sbt-sequential は、タスクや Scala コードを一連の flatMap に自動的に展開する `Def.sequentialTask` を追加する。このマクロの性質上、複雑なコードには使えないかもしれないけども、独立したタスクや Scala コードを逐次的に始動してブロックすることができる。
