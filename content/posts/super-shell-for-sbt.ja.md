---
title:       "sbt のための super shell"
type:        story
date:        2018-10-01
draft:       false
promote:     true
sticky:      false
url:         /ja/super-shell-for-sbt
aliases:     [ /node/277 ]
tags:        [ "sbt" ]
---

週末中に sbt のための super shell の実装がまとまってきたのでここに報告する。大まかな概要としては、ターミナル画面の下 n行を乗っ取って今走っているタスクを表示させる。

### ログを現状報告に使うことの限界

ログは多くの場面で有用で、時としては何が起こっているかを知るための唯一の現実解であったりする。だけども、sbt のようなコンソールアプリにおいては、ログを使ってビルド・ユーザに現在なにが起こっているかを報告するのはうまくいかないことがある。

仮に sbt が一切ログを表示しなかったとすると、sbt が長時間走るタスクを実行して一見固まってしまったときに何が起きているか分からなくなる。そのため、`update` のようなタスクは "Updating blabla subproject" と "Done updating" といった開始、終了ログを表示する。`update` タスクはユーザやビルドによって非常に長い時間がかかってしまうことで有名だが、少ないライブラリ依存性を持つその他の多くのビルドは 1s 以内で完了する。そのような場合、ビルドの開始時に "Done updating" がズラーッと壁のように並ぶことになる。

つまり、ログ表示を現状報告に使うのはログが出すぎてうるさい状態と、情報が足りなくて不便な両極端の間を揺れることになる。

### show your work (途中式を書くこと)

人生における多くの事と同様に、やったことの提示方法やユーザー・インターフェイスはその作業とかプロダクトそのものの必要不可欠な側面であり、特にその作業やプロダクトが自明で無いものほどそれが顕著になる。

僕は、sbt が単一のコマンド実行内においてタスクを並列処理することを当たり前のように考えてきた。しかし、最近になってその事を知らない人がいる場面に出くわすことが増えてきた。これは、実はもっともなことだ。なぜなら、ビルドの DSL もユーザインターフェイスも sbt がタスクの並列処理を行っていることを明らかにしていないからだ。

さらに、古参のユーザが sbt がタスクを並列実行していることを信じていたとしても、現在はどのタスクがパフォーマンスのボトルネックになっているのかを知るのが難しい。何らかのプラグインが不必要に `update` を呼び出したり、ソースが一切変わっていないのにプロセス外の Typescript コンパイラを呼び出したりしているかもしれない。

### super shell

現在実行中のタスクを表示する "super shell" はこれらの問題を解決する。1s 以内に実行するタスクは画面には表示されず、長時間走っているタスクはカウントアップする時計が表示される。

![super shell](https://raw.githubusercontent.com/eed3si9n/eed3si9n.com/master/images/super-shell.gif)

初めて僕がこのような機能に気付いたのは Gradle の "rich console" だ。Buck もこれを実装していて、"super console" と呼ばれているらしいので、僕もその名前を借りることにした。

### super shell の実装方法

一ヶ月ぐらい前に [Scala で書くコンソール・ゲーム](http://eed3si9n.com/ja/console-games-in-scala)を書いたが、実はそれはこの機能のための予備研究だった。

super shell は二部から構成される。第一にロガーを変更して、ログがターミナルの上方向へ移動するようにする。このテクニックは「コンソール・ゲーム」で既に解説したが、ScrollUp を使うことでターミナルで同じ位置を保ったままログを表示させ続けることができる。

<scala>
  private final val ScrollUp = "\u001B[S"
  private final val DeleteLine = "\u001B[2K"
  private final val CursorLeft1000 = "\u001B[1000D"
....
        out.print(s"$ScrollUp$DeleteLine$msg${CursorLeft1000}")
</scala>

次に、現在実行中のタスクを表示させる必要がある。タスクのトレーシングを行うために `ExecuteProgress[Task]` というものがあるので、それを実装して現在アクティブなタスクを集めてくる。開始時間を hash map に入れておいて現在の時間を引けば経過時間が分かる。

<scala>
  final val DeleteLine = "\u001B[2K"
  final val CursorDown1 = cursorDown(1)
  def cursorUp(n: Int): String = s"\u001B[${n}A"
  def cursorDown(n: Int): String = s"\u001B[${n}B"

...

def report0: Unit = {
  console.print(s"$CursorDown1")
  currentTasks foreach {
    case (task, start) =>
      val elapsed = (System.nanoTime - start) / 1000000000L
      console.println(s"$DeleteLine  | => ${taskName(task)} ${elapsed}s")
  }
  console.print(cursorUp(currentTasks.size + 1))
}
</scala>

表示する前に、ログを上書きしないようにカーソルを 1行下げる必要がある。アクティブなタスクは各行に `DeleteLine` と共に表示する。最後に `CursorUp` を使ってカーソル位置を元に戻す。

### 課題

これは現行の "Done updating" スタイルのシェルの良い代替になると僕は思っている。だけども、実際に毎日使ってみないと使い勝手の良さはなかなか分からない。

もう一つ考えなければ行けないのは、IDE や thin client のためにこの情報を JSON でどう伝達するかだ。
