build.sbt は、自動的な並列処理を行うタスク・グラフを定義するための DSL だ。タスク同士のメッセージ・パッシングは `something.value` マクロで表され、これは Applicative 合成 `(task1, task2) mapN { case (t1, t2) => .... }` をエンコードする。

長く走っている `task1` があるとき、途中で `task2` と通信できる仕組みがあればいいと思っていた。

![promise](/images/promise-01.png)

通常は `task1` をサブタスクに分けることでこれを解決する。しかし、それを実装するのは一筋縄ではいかないこともある。例えば、Zinc に半分だけコンパイルして、残りは後で続けて下さい? もしくは Coursier に解決だけ行って実際のダウンロードは後でとどう言えばいいだろうか?

たたき台として `task1` が何らかの JSON ファイルを生成して、`task2` はファイルが現れるまで待って、それを読み込むというやり方が考えられる。JSON ファイルの代わりに `Promise[A]` のような並行データ構造を使って改善することができる。しかし、待機という厄介なものが残っている。sbt は並列に実行するタスクの数を限っているので、待機のために枠を使うのはもったいない。Daniel さんの [Thread Pools](https://gist.github.com/djspiewak/46b543800958cf61af6efa8e072bfd5c) にこの辺りの事が良くまとまっている。今回あるのは差し当たり作業を一切行わないブロッキング IO ポーリングと考えることができると思う。

### Def.promise

`scala.concurrent.Promise` のラッパーを実装して `Def.promise` と呼んだ。具体例で説明する:

```scala
val midpoint = taskKey[PromiseWrap[Int]]("")
val longRunning = taskKey[Unit]("")
val task2 = taskKey[Unit]("don't call this from shell")
val joinTwo = taskKey[Unit]("")

// Global / concurrentRestrictions := Seq(Tags.limitAll(1))

lazy val root = (project in file("."))
  .settings(
    name := "promise",
    midpoint := Def.promise[Int],
    longRunning := {
      val p = midpoint.value
      val st = streams.value
      st.log.info("start")
      Thread.sleep(1000)
      p.success(5)
      Thread.sleep(1000)
      st.log.info("end")
    },
    task2 := {
      val st = streams.value
      val x = midpoint.await.value
      st.log.info(s"got $x in the middle")
    },
    joinTwo := {
      val x = longRunning.value
      val y = task2.value
    }
  )
```

まず、`midpoint` という `PromiseWrap[Int]` のタスクを作る。コマンド呼び出しの度にフレッシュな promise が欲しいのでタスクを使う。次に、`longRunning` というタスクがあって、これは途中で promise を補完する。`task2` は `midpoint.await.value` に依存する。これは、`midpoint` に格納された promise が完了するまで sbt のスケジューラーは `task2` を開始しないことを意味する。

`longRunning` と `task2` を同時に走らせるために `joinTwo` タスクを定義する。これを実行すると以下のようになる:

<code>
sbt:promise> joinTwo
[info] start
[info] got 5 in the middle
[info] end
</code>

見た通り、両方のタスクが並列実行して、かつ `longRunning` タスクから `task2` へとメッセージを渡せたことが確認できる。

**警告**: `task2` をシェルから実行すると永遠にブロックして返って来ない。Ctrl-C を使って抜け出す必要がある。

### まとめ

`Def.promise` [sbt/sbt#5552](https://github.com/sbt/sbt/pull/5552) は、長く走るタスクから別のタスクへとメッセージを渡すための草案だ。潜在的な用途としてはサブプロジェクトのパイプライン化されたビルドなどがあるかもしれない。
