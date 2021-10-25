---
title:       "sbt での Selective ファンクター"
type:        story
date:        2020-05-16
changed:     2021-03-13
draft:       false
promote:     true
sticky:      false
url:         /ja/selective-functor-in-sbt
aliases:     [ /node/336 ]
tags:        [ "sbt" ]
---

  [Mokhov2018]: https://www.microsoft.com/en-us/research/uploads/prod/2018/03/build-systems.pdf
  [Mokhov2019]: https://www.staff.ncl.ac.uk/andrey.mokhov/selective-functors.pdf
  [Birchall]: https://github.com/cb372/cats-selective/blob/a1f4c0e19a1a90b5b27dd502f5a83f35dbec477d/core/src/main/scala/cats/Selective.scala
  [core]: https://www.youtube.com/watch?v=-shamsTC7rQ
  [core_matsuri]: https://www.youtube.com/watch?v=mY7zu21Cceg
  [Hood2018]: https://youtu.be/s_3qLMSGHkI?t=631

[sbt コア・コンセプト][core_matsuri]のトークをするとき僕は sbt をカジュアルに関数型なビルド・ツールと言っている。関数型プログラミングの 2つの特徴としてデータを変化させるのではなく immutable (不変)なデータ構造を使うことと、いつ、どのようにして effect (作用) を取り扱うかに気を使っていることが挙げられる。

### セッティングとタスク

その観点から見ると、セッティング式とタスクはその 2点に合致していると考えることができる:

- セッティング列はビルドの不変グラフを形成する。
- タスクは作用を表す。

匿名セッティングは `Initialize[A]` で表され、以下のようになっている:

```scala
  sealed trait Initialize[A] {
    def dependencies: Seq[ScopedKey[_]]
    def evaluate(build: BuildStructure): A // approx
    ....
  }
```

名前の付いたセッティングは `Setting` クラスで表される:

```scala
  sealed class Setting[A] private[Init] (
      val key: ScopedKey[A],
      val init: Initialize[A],
      val pos: SourcePosition
  ) ....
```

`sbt.Task` は副作用関数 `() => A` のラッパーだと便宜的に考えていい。ただし、僕たちが「compile はタスクだ」と言うとき、の文脈でのタスクは `Initialize[Task[A]]` で表される。つまり、これは `Task[A]` 型を返すセッティングだ。

これは `Def.task` の戻り型 `Def.Initialize[Task[A]]` を見ることで確認することができる。

### Applicative 合成

`Def.task` はタスク (`Def.Initialize[Task[A]]`) の Applicative 合成をエンコードするためのマクロだ。以下の `task1`、`task2`、`task3` を考察する:

```scala
lazy val task1 = taskKey[Int]("")
lazy val task2 = taskKey[Int]("")
lazy val task3 = taskKey[Int]("")

task1 := 1
task2 := 2

task3 := {
  val t1 = task1.value
  val t2 = task2.value
  t1 + t2
}
```

これを旧タプル構文で書き下すとこうなる:

```scala
task3 := ((task1, task2) map { case (t1, t2) =>
  t1 + t2
}).value
```

ここから色々な情報を得ることができる。

- `task1` と `task2` は両方とも `task3` に対して事前発生 (happens-before) する
- `task1` と `task2` は互いに因果的に独立である

これによってタスク・スケジューラーは、CPU コアが空いていれば `task1` と `task2` を並列に実行することができる。さらに、sbt はグラフを自己観察してタスク間の依存性を表示することができる:

```bash
sbt:selective> inspect tree task3
[info] task3 = Task[Int]
[info]   +-task1 = Task[Int]
[info]   +-task2 = Task[Int]
```

思考実験が役に立つこともあるので考えてみよう。パンデミックを無視して良いとして、親戚が飛行機で来るとして、迎えに行くのにだいたい 1~2時間かかるとする。ちょっとおもてなしのご馳走を作りたいが、それも 2時間ぐらいかかるとする。もしも、パートナーの人がいれば 1人が空港に行って、もう1人が料理を行うという分業ができる。最終的に晩ごはんを始めるには料理が作られ、かつ親戚が来ている状態にある必要がある。

### Monadic 合成

もし 1つのタスクの結果を使って次にどのタスクを走らせるかを決めたいとしたらどうだろうか? sbt では `Def.taskDyn` を使ってこれを実現できる。

```scala
lazy val condition = taskKey[Boolean]("")
lazy val trueAction = taskKey[Unit]("")
lazy val falseAction = taskKey[Unit]("")
lazy val foo = taskKey[Unit]("")

condition := true
trueAction := { println("true") }
falseAction := { println("false") }

foo := (Def.taskDyn {
  val c = condition.value
  if (c) trueAction
  else falseAction
}).value
```

このマクロを展開するとこのようになる:

```scala
foo := (condition flatMap { c =>
  if (c) trueAction
  else falseAction
}).value
```

これはビルド作者の点から見るとよりパワフルだ。しかしいくつかの欠点もある。

1. `foo` は `condition` タスクにブロックされる。これは、正に僕たちが意図したことだが、それによって並列性が犠牲になる可能性がある。
2. タスクグラフを自己観察できなくなる。

```bash
sbt:selective> inspect tree foo
[info] foo = Task[Unit]
[info]   +-condition = Task[Boolean]
[info]   +-Global / settingsData = Task[sbt.internal.util.Settings[sbt.Scope]]
```

inspect tree の結果から `trueAction` と `falseAction` が抜けていることに注目してほしい。

この問題を回避するには、`if` 条件をタスクの実装本体に移動させる必要がある。複数のタスクを合成する場合、それだとうまくいかないことも多い。特にビルド・ツールにおけるこの Applicative と Monad 合成の緊張関係は ScalaSphere 2018 での Stu Hood さんの [Incrementalism and Inference in Build Tools][Hood2018] というトークで僕は見たことがあるが、今見返してみると彼は Andrey Mokhov さんの [Build Systems à la Carte][Mokhov2018] というペーパーを引用していた。

晩ごはんの例に戻ると、その親戚は好き嫌いの多い従兄弟だとする。家に着いてから家でパスタでいいか、モロッコ料理屋に行きたいか聞いてみたいとする。どちらにせよ、家に着くまで料理を始めることができない。これが柔軟性と並列性のトレードオフだ。2時間かかるロースト料理はできなくなる。

### Selective applicative functor

2019年の4月頃 Dale が [Build Systems à la Carte][Mokhov2018] と、同じ作者 Andrey Mokhov さんによる [Selective applicative functor][Mokhov2019] というペーパーのことを教えてくれた。それまで `Selective` というのは聞いたことが無かったので、その利点を sbt に移植することができるのか興味があった。

Chris Birchall さんの [cats-selective][Birchall] における `Selective` の定義は以下のようになっている:

```scala
trait Selective[F[_]] {
  def select[A, B](fab: F[Either[A, B]])(fn: F[A => B]): F[B]
  
  ...
}
```

意味論としては、もし `fab` が `Right(b)` を格納していればそれをそのまま返し、`Left(a)` を格納していれば `fn` を適用する。ただし、全て `F[_]` というコンテキストで実行するということみたいだ。これをコンポーネントとして Mokhov さんは `if` ファンクターもエンコードできることを示している。(実装は [cats-selective][Birchall] 参照):

```scala
trait Selective[F[_]] {
  def select[A, B](fab: F[Either[A, B]])(fn: F[A => B]): F[B]
  def branch[A, B, C](x: F[Either[A, B]])(l: F[A => C])(r: F[B => C]): F[C] = ...
  def ifS[A](x: F[Boolean])(t: F[A])(e: F[A]): F[A] = ....
}
```

論文によると `Selective` の利点は inspect を犠牲にせずに条件的タスクを表現できるらしい。どのような仕組みでこれは可能になっているのだろう?

肝となっているのは `Selective` が `Monad` ベースと `Applicative` ベースという 2つの異なる方法で実装でき、それぞれ異なる特性を持つということらしい。これは少し普通じゃない気がするがペーパーにはそう書いてある:

> One can implement `select` using monads in a straightforward manner ...
>
> `select` はモナドを使って率直に実装できる。 

```scala
// This is Scala implementation from cats-selective
def selectM[F[_]](implicit M: Monad[F]): Selective[F] =
  new Selective[F] {
    def select[A, B](fab: F[Either[A, B]])(fn: F[A => B]): F[B] =
      fab.flatMap {
        case Right(b) => M.pure(b)
        case Left(a)  => fn.map(_(a))
      }
  }
```

> One can also implement a function with the type signature of `select` using applicative functors,
but it will always execute the effects associated with the second argument, rendering any conditional execution of effects impossible...
>
> Applicative ファンクターを使って `select` と同じ型シグネチャを持つ関数を実装することも可能だが、これは常に 2つめの引数に関連付けられた作用を実行して、作用の条件的実行を無効化してしまう。

```scala
// This is Scala implementation
def selectA[F[_]](implicit Ap: Applicative[F]): Selective[F] =
  new Selective[F] {
    def select[A, B](fab: F[Either[A, B]])(fn: F[A => B]): F[B] =
      (fab, fn) mapN { case (ab, n) =>
        ab match {
          case Right(b) => Ap.pure(b)
          case Left(a)  => n(a)
        }
      }
  }
```

> While `selectM` is useful for conditional execution of effects, `selectA` is useful for static analysis.
>
> `selectM` は作用の条件的実行に役立つ一方、`selectA` は静的解析に役立つ。

晩ごはんの例で言うと、Selective はチキンとベジタリアン・ハンバーガーの両方できるようにしてあるようなものだろうか。従兄弟は 2つら選ぶことができ、彼が着くまで料理はしないが事前に計画して買い物をしておくことはできる。

### タスクの Selective 合成

`foo` タスクは `Selective` を使って以下のように実装できる:

```scala
foo := (Def.ifS(condition)(trueAction)(falseAction)).value,
```

これを実行してみよう:

```scala
sbt:selective> foo
true
```

うまくいった。`inspect` はどうだろう?

```scala
sbt:selective> inspect tree foo
[info] foo = Task[Unit]
[info]   +-condition = Task[Boolean]
[info]   +-falseAction = Task[Unit]
[info]   +-trueAction = Task[Unit]
```

`inspect` も動作している。

`Def` 内の `selectITask` の実装はこうなっている:

```scala
  private[sbt] def selectITask[A, B](
      fab: Initialize[Task[Either[A, B]]],
      fin: Initialize[Task[A => B]]
  ): Initialize[Task[B]] =
    fab.zipWith(fin)((ab, in) => TaskExtra.select(ab, in))
```

`Initialize[_]` レイヤーでは `fab.zipWith(fin)` は Applicative 的な意味論を使っている。ここで呼ばれている `TaskExtra.select(...)` は以下のように定義されている:

```scala
  def select[A, B](fab: Task[Either[A, B]], f: Task[A => B]): Task[B] =
    Task(newInfo(fab.info), new Selected[A, B](fab, f))
```

構築時には取り敢えず作用の捕捉だけを行って何もしていない。タスク・エンジンがこのタスクをスケジュールする直前に `Selected` を Monadic 合成に書き換える:

```scala
  private[sbt] def asFlatMapped: FlatMapped[B, K] = {
    val f: Either[A, B] => Task[B] = {
      case Right(b) => std.TaskExtra.task(b)
      case Left(a)  => std.TaskExtra.singleInputTask(fin).map(_(a))
    }
    FlatMapped[B, K](fab, {
      f compose std.TaskExtra.successM
    }, ml)
  }
```

つまり、セッティング層は Applicative 的に合成して、タスク層は Monad 的に合成することで `Selective` の両方の側面を利用している。

### 使用例

`Def.taskDyn` を使っている実用例を `Def.ifS` を使って書き換えてみよう。以下は `dependencyResolutionTask` だ:

```scala
def dependencyResolutionTask: Def.Initialize[Task[DependencyResolution]] =
  Def.taskDyn {
    if (useCoursier.value) {
      Def.task { CoursierDependencyResolution(csrConfiguration.value) }
    } else
      Def.task {
        IvyDependencyResolution(ivyConfiguration.value, CustomHttp.okhttpClient.value)
      }
  }
```

`dependencyResolution` タスクの inspect を阻害しているのが確認できる:

```bash
sbt:selective> inspect tree dependencyResolution
[info] dependencyResolution = Task[sbt.librarymanagement.DependencyResolution]
[info]   +-Global / settingsData = Task[sbt.internal.util.Settings[sbt.Scope]]
[info]   +-Global / useCoursier = true
```

`dependencyResolutionTask` は以下のように書き換えられる:

```scala
def dependencyResolutionTask: Def.Initialize[Task[DependencyResolution]] =
  Def.ifS(useCoursier.toTask)(Def.task { CoursierDependencyResolution(csrConfiguration.value) })(
    Def.task { IvyDependencyResolution(ivyConfiguration.value, CustomHttp.okhttpClient.value) }
  )
```

```bash
sbt:selective> inspect tree dependencyResolution
[info] dependencyResolution = Task[sbt.librarymanagement.DependencyResolution]
[info]   +-csrConfiguration = Task[lmcoursier.CoursierConfiguration]
[info]   | +-allCredentials = Task[scala.collection.Seq[sbt.librarymanagement.ivy.Credentials]]
[info]   | | +-Global / credentials = Task[scala.collection.Seq[sbt.librarymanagement.ivy.Credentials]]
[info]   | | +-allCredentials / streams = Task[sbt.std.TaskStreams[sbt.internal.util.Init$ScopedKey[_ <: Any]]]
[info]   | | | +-Global / streamsManager = Task[sbt.std.Streams[sbt.internal.util.Init$ScopedKey[_ <: Any]]]
[info]   | | |
[info]   | | +-credentials = Task[scala.collection.Seq[sbt.librarymanagement.ivy.Credentials]]
[info]   | |
....
```

他の例も試してみよう。

```scala
def publishTask(config: TaskKey[PublishConfiguration]): Initialize[Task[Unit]] =
  Def.taskDyn {
    val s = streams.value
    val skp = (publish / skip).value
    val ref = thisProjectRef.value
    if (skp) Def.task { s.log.debug(s"Skipping publish* for ${ref.project}") } else
      Def.task { IvyActions.publish(ivyModule.value, config.value, s.log) }
  } tag (Tags.Publish, Tags.Network)
```

これは `publish / skip` が true ならば publish タスクをスキップするという `Def.taskDyn` の用例だ。

```scala
def publishTask(config: TaskKey[PublishConfiguration]): Initialize[Task[Unit]] =
  Def.ifS((publish / skip).toTask)(Def.task {
    val s = streams.value
    val ref = thisProjectRef.value
    s.log.debug(s"Skipping publish* for ${ref.project}")
  })(Def.task {
    val s = streams.value
    IvyActions.publish(ivyModule.value, config.value, s.log)
  }) tag (Tags.Publish, Tags.Network)
```

以前と同じように動作し、かつ `inspect` を取り戻すことができた。

### データとしてのコード

`Def.ifS` は期待通り動作するが、`Def.ifS(...)(...)(...)` は Scala コードの中では異質的だ。Scala では、if 条件は `if` を使って表現するのが慣習に沿っている。これは、`Def.task(...)` マクロ内を使ってエンコードできる。

`Def.task(...)` 内のトップレベルの式が `if`式の場合、そのコンテンツを `Def.ifS(...)(...)(...)` の中に持ち上げるということを行う。使用例のコードはこうなる:

```scala
def dependencyResolutionTask: Def.Initialize[Task[DependencyResolution]] =
  Def.task {
    if (useCoursier.value) CoursierDependencyResolution(csrConfiguration.value)
    else IvyDependencyResolution(ivyConfiguration.value, CustomHttp.okhttpClient.value)
  }

def publishTask(config: TaskKey[PublishConfiguration]): Initialize[Task[Unit]] =
  Def.task {
    if ((publish / skip).value) {
      val s = streams.value
      val ref = thisProjectRef.value
      s.log.debug(s"Skipping publish* for ${ref.project}")
    } else {
      val s = streams.value
      IvyActions.publish(ivyModule.value, config.value, s.log)
    }
  } tag (Tags.Publish, Tags.Network)
```

何が起こっているのかというドキュメンテーションが必要になるが、`Def.ifS(...)(...)(...)` よりも取っつきやすいのではと思う。

### Selective に関するその他の考察

本稿では、入っていきやすそうだった `ifS` に焦点を置いて考えてみたが、[Selective applicative functor][Mokhov2019] は他のコンビネーターも定義してある。

```scala
trait Selective[F[_]] {
  def select[A, B](fab: F[Either[A, B]])(fn: F[A => B]): F[B]
  def branch[A, B, C](x: F[Either[A, B]])(l: F[A => C])(r: F[B => C]): F[C] = ...
  def ifS[A](x: F[Boolean])(t: F[A])(e: F[A]): F[A] = ...
  def whenS[A](fbool: F[Boolean])(fa: F[Unit]): F[Unit] = ...
  def bindBool[A](fbool: F[Boolean])(f: Boolean => F[A]): F[A] = ...
  def fromMaybeS[A](fa: F[A])(fm: F[Option[A]]): F[A] = ...
  def orS(fbool: F[Boolean])(fa: F[Boolean]): F[Boolean] = ...
  def andS(fbool: F[Boolean])(fa: F[Boolean]): F[Boolean] = ...
  def anyS[G[_]: Foldable, A](test: A => F[Boolean])(ga: G[A]): Eval[F[Boolean]] = ...
  def allS[G[_]: Foldable, A](test: A => F[Boolean])(ga: G[A]): Eval[F[Boolean]] = ...
}
```

`branch` は特に面白そうだ。sbt の内部では `Applicative` を扱うとき arity (引数の数) を `AList[X[F[A]]]` というインターフェイスを使って抽象化する。その延長線で考えると、`Either[A, B]` は `Tuple2[A, B]` の逆だと考えられる。つまり、`Either[A, B]` は `A1`、 `A2`、`A3`... の Coproduct を作るための部品でもある。

Scala だと関連する構文はパターンマッチかもしれない:

```scala
something match {
  case pattern1 => something1
  case pattern2 => something2
  case pattern3 => something3
}
```

これがあれば、if 式はその上にエンコードできる。

### まとめ

Selective ファンクターは `inspect` コマンドを犠牲にせずにタスクの条件的実行を可能とする仕組みを提供する。

sbt では、Selective 合成は条件的タスク (conditional task) として表すことができる:

```scala
Def.task {
  if (Boolean) something1
  else something2
}
```

sbt への pull req は [sbt/sbt#5558](https://github.com/sbt/sbt/pull/5558)だ。

**追記**:

当初は `Def.taskIf { ... }` として提案されたが、`Def.task { ... }` として merge されたので、本稿もそれに追随して変更した。
