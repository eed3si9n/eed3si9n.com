---
title:       "酢鶏、パート5"
type:        story
date:        2024-09-08
draft:       false
url:         /ja/sudori-part5
tags:        [ "sbt" ]
---

  [part3]: /sudori-part3
  [part4]: /ja/sudori-part4
  [sbt-remote-cache]: /ja/sbt-remote-cache
  [sbt-remote-cache-with-bazel-compat]: /ja/sbt-remote-cache-with-bazel-compat
  [7644]: https://github.com/sbt/sbt/pull/7644
  [Mokhov2018]: https://www.microsoft.com/en-us/research/uploads/prod/2018/03/build-systems.pdf

本稿は sbt 2.x 開発に関する記事で、[sudori part3][part3]、[sbt 2.x リモートキャッシュ][sbt-remote-cache]、[Bazel 互換な sbt 2.x リモートキャッシュ][sbt-remote-cache-with-bazel-compat]、[酢鶏、パート4][part4] などの続編だ。僕は個人の時間を使って Scala Center や EngFlow の Billy さんなどのボランティアの人と協力して sbt 2.x の作業をしていて、このような記事はプルリクコメントの拡張版で、将来 sbt に実装されるかもしれない機能を共有できたらいいと思っている。

### 導入

今週はコネチカット州の浜辺の町で遅い夏休みを取って地元のスケボースポットをチェックしたり、少し冷ためな海に入ったり、ロブスター・ロールを食べ比べたりしていた。スケボーをしたり海遊びの合間に sbt におけるテストのリモート・キャッシュの作業をしたり、関連する実験をしたりしていた。開発用の覚書として、ここに結果を報告したい。

[酢鶏、パート4][part4]では `compile` タスクのリモート・キャシュを見た。`compile` がキャッシュできれば役立つのは間違い無いが、CI (継続的統合) システムの多くの時間はコードのコンパイルではなくテストに割かれることが多いのではないだろうか。Bazel は数桁違いに高速な CI の性能を叩き出すことがあるが、その一つの理由としてデフォルトでの `test` コマンドがリモート・キャッシュ化されているということが挙げられる。言い換えると、Bazel を使った場合、もし CI マシン上でテストが一度実行されると、インプットが変わるまではそのテスト結果はキャッシュされ続ける。

sbt 上級者の読者の皆さんは、sbt には既にローカルで差分テストを行う `testQuick` があるじゃないかとお気づきかもしれない。`testQuick` の難点は、キャッシュの無効化にタイムスタンプを用いるため、ビルド的に非密閉 (non-hermetic) で、そのためマシン間で再現性が無いことだ。本稿では、マシン間で安全に共有できる sbt 2.x のテスト・キャッシュを考察する。対応するプルリクは [sbt/sbt#7644][7644] だ。

<!--more-->

### sbt 1.x testQuick の解剖学

比較対象として、sbt 1.x の `testQuick` がどのような仕組みで動いているのかを少し詳しく理解したほうがいいと思うので、まずは見ていこう。sbt には、`TestsLister` という機構があって、ビルドユーザはテスト完了といったイベントに対するイベントハンドラーを登録することができる。sbt 1.x は、デフォルトで [TestStatusReporter](https://github.com/sbt/sbt/blob/v1.10.1/testing/src/main/scala/sbt/TestStatusReporter.scala) というリスナーを登録してある:

```scala
private[sbt] class TestStatusReporter(f: File) extends TestsListener {
  private lazy val succeeded: concurrent.Map[String, Long] = TestStatus.read(f)
  def startGroup(name: String): Unit = { succeeded.remove(name); () }
  def endGroup(name: String, result: TestResult): Unit = {
    if (result == TestResult.Passed)
      succeeded(name) = System.currentTimeMillis
  }
  def doComplete(finalResult: TestResult): Unit = {
    TestStatus.write(succeeded, "Successful Tests", f)
  }
}
```

要約すると、テストが通るたびに現在時刻のタイムスタンプが記録される。`test` の最後に、`TestStatus.write(...)` が `succeeded_tests` という名前の Java プロパティーファイルを `target/` 以下の決められた場所に保存する。

`testQuick` は [testQuickFilter](https://github.com/sbt/sbt/blob/v1.10.1/main/src/main/scala/sbt/Defaults.scala#L1432-L1473) を用いて検知されたテスト・スイートの候補をフィルターするが、これはテスト実装の間接的依存性のうち最近のタイムスタンプを計算する:

```scala
val stamps = collection.mutable.Map.empty[String, Long]
def stamp(dep: String): Long = {
  val stamps = for (a <- ans) yield intlStamp(dep, a, Set.empty)
  if (stamps.isEmpty) Long.MinValue
  else stamps.max
}
def intlStamp(c: String, analysis: Analysis, s: Set[String]): Long =
  ....
def noSuccessYet(test: String) = succeeded.get(test) match {
  case None     => true
  case Some(ts) => stamps.synchronized(stamp(test)) > ts
}
```

ここで「間接的依存性」は、クラス依存性とライブラリ JAR の両方を指す。

### 差分テストとは何か?

[Build Systems à la Carte (Mokhov et al, 2018)][Mokhov2018] を少し言い換えると、差分テストは以下のように考えられる。テスト・システムは、間接的に依存するインプットが以前の実行以降に変更されたテスト・スイートを実行ごとに最多1回のみ走らせるとき、ミニマルだと呼ばれる。テスト・システムがミニマルもしくはそれより多くの走らせる場合は差分テストだと定義できる気がする。

一見すると、差分コンパイルと似ているように見えるが、コンパイルとテストでは決定的な違いがある。Scala での多くの場合、コンパイル時にはメソッドの本体を無視することができる。Bazel だと Java のコンパイルに `ijar` と呼ばれる実装部分を省いたものを定義したりする。そのため、クラス `B` が `A` の `A#foo` を呼び出したとして、`A#foo` の本文が変わったとしても、差分コンパイルは `B` を無効化しないことが多い。しかし、テストの場合はメソッドの本文の変更は絶対にチェックする必要がある。

具体例で説明した方が分かりやすいかもしれない。以下のようなクラスを色々定義してみる:

```scala
// Animal.scala
package example

trait Animal:
  def walk: Int = 0
end Animal

// Cow.scala
package example

class Cow extends Animal:
  def moo: Int = 0
end Cow

// Mineral.scala
package example

trait Mineral:
  def ok: Boolean = true
end Mineral
```

以下のように JUnit 4 でテストを定義する:

```scala
package example

import org.junit.Test
import org.junit.Assert.assertEquals

class CowTest:
  @Test
  def testMoo: Unit =
    val cow = Cow()
    assertEquals(cow.moo, 0)
end CowTest
```

最小性によると:

1. `CowTest` 自身を変更すると、以前のテスト結果は無効化される
2. `Cow` を変更すると、以前のテスト結果は無効化される
3. `Anminal` を変更すると、以前のテスト結果は無効化される
4. `Mineral` を変更しても、以前のテスト結果は無効化されない

リモート・キャッシュ化されたテストは以上の処理を複数のマシン間で行うことを目指す。

### ステップ 1: 密閉な差分テスト

リモート・キャッシュ化以前に、まずは非密閉なタイムスタンプへの依存を直す必要がある。Bazel は、「ターゲット」と呼ばれるサブプロジェクト間で依存性グラフを形成して、キャッシュ化や無効化はターゲットを一つのまとまりとして処理される。この考え方は、1つのサブプロジェクトに複数のテスト・スイートを持つ sbt にはちょっと合わない。

しかしながら、sbt はクラス単位での JARよりも細かい粒度でグラフを形成することができ、差分コンパイルではこれを Zinc Analysis として管理する。僕の考え方としては、差分コンパイルは `*.class` の圏におけるモノイドを形成して、シグネチャが変わった場合のみにメソッド呼び出しに射が出ていく。一方、差分テストも `*.class` の圏におけるモノイドを形成するが、バイトコードが変更されるたびにメソッド呼び出しに射が出ていく。

| -           |       object |                  arrow |
|-------------|-------------:|-----------------------:|
| bazel test  | JAR (target) |         JAR dependency |
| sbt compile |    `*.class` |      method call / API |
| sbt test    |    `*.class` | method call / bytecode |

sbt は既に `definedTests` と呼ばれるタスクでサブプロジェクト内のテスト・スイートの自動検知を行う。ここで、`definedTestDigests` という `Map[String, Digest]` に型付けされた新しいタスクを導入した。`Digest` は、暗号学的ハッシュとファイルサイズの組み合わせを表すが、ここではダイジェストの[マークル木](https://ja.wikipedia.org/wiki/%E3%83%8F%E3%83%83%E3%82%B7%E3%83%A5%E6%9C%A8)として使っている。

```scala
class ClassStamper(
    classpath: Seq[Attributed[HashedVirtualFileRef]],
    converter: FileConverter,
):
  /**
   * Given a classpath and a class name, this tries to create a SHA-256 digest.
   * @param className className to stamp
   * @param extraHashes additional information to include into the returning digest
   */
  private[sbt] def transitiveStamp(
      className: String, extaHashes: Seq[Digest]): Option[Digest] =
    val digests = SortedSet(analyses.flatMap(internalStamp(className, _, Set.empty)): _*)
    if digests.nonEmpty then Some(Digest.sha256Hash(digests.toSeq ++ extaHashes: _*))
    else None

  private def internalStamp(
      className: String,
      analysis: Analysis,
      alreadySeen: Set[String],
  ): SortedSet[Digest] =
    ....
end ClassStamper
```

`internalStamp(...)` は `testQuick` と似たロジックになっているが、コンパイルが行われたタイムスタンプの代わりにバイトコードの SHA-256 を計算する。`compile` 直後に、`definedTestDigests` を計算して、検知された全てのテスト・スイートの SHA-256 ハッシュのマークル木を事前に用意しておくことができる。

```scala
  // cache the test digests against the fullClasspath.
  def definedTestDigestTask: Initialize[Task[Map[String, Digest]]] = Def.cachedTask {
    val cp = (Keys.test / fullClasspath).value
    val testNames = Keys.definedTests.value.map(_.name).toVector.distinct
    val converter = fileConverter.value
    val sv = Keys.scalaVersion.value
    val inputs = (Keys.compile / Keys.compileInputs).value
    // by default this captures JVM version
    val extraInc = Keys.extraIncOptions.value
    // throw in any information useful for runtime invalidation
    val salt = s"""$sv
${converter.toVirtualFile(inputs.options.classesDirectory)}
${extraInc.mkString(",")}
"""
    val extra = Vector(Digest.sha256Hash(salt.getBytes("UTF-8")))
    val stamper = ClassStamper(cp, converter)
    Map((testNames.flatMap: name =>
      stamper.transitiveStamp(name, extra) match
        case Some(ts) => Seq(name -> ts)
        case None     => Nil
    ): _*)
  }
```

1つのクラスが異なる JVM バージョン、Scala バージョン、JVM vs JS vs Native などとクロス・ビルドされる可能性があるので、`salt` として追加情報を捕捉して、一緒にハッシュ化する。この `Digest` は `succeeded_test` 内でタイムスタンプの代わりに使うことができる。例えば、`CowTest` というようなテスト・スイートが与えられたとき、現行の `Digest` とファイル内での `Digest` が一致した場合、このテストは飛ばしてもいいということになる。

### ステップ 2: テスト結果のキャッシュ化

sbt 2.x のキャッシュシステムの良いところは、ローカルのディスク・キャッシュとリモート・キャッシュのインターフェイスが統一されていることだ。そのため、sbt 2.x のキャッシュ・システムに乗せることができれば、ディスク・キャッシュとリモート・キャッシュを両方実装できる。

Bazel の流儀に従って、キャッシュ化の単位はアクション・キャッシュと呼ばれる。成功したテストしかキャッシュする予定が無いので、これらは整数の `0` で表すことができる。新しい `TestStatusReporter` は、テスト・スイートが成功するたびに、これを行うことができる:

```scala
private[sbt] class TestStatusReporter(
    digests: Map[String, Digest],
    cacheConfiguration: BuildWideCacheConfiguration,
) extends TestsListener:
  // int value to represent success
  private final val successfulTest = 0

  /**
   * If the test has succeeded, record the fact that it has
   * using its unique digest, so we can skip the test later.
   */
  def endGroup(name: String, result: TestResult): Unit =
    if result == TestResult.Passed then
      digests.get(name) match
        case Some(ts) =>
          // treat each test suite as a successful action that returns 0
          ActionCache.cache(
            key = (),
            codeContentHash = ts,
            extraHash = Digest.zero,
            tags = CacheLevelTag.all.toList,
            config = cacheConfiguration,
          ): (_) =>
            ActionCache.actionResult(successfulTest)
        case None => ()
    else ()
end TestStatusReporter
```

次に、`testQuick` のフィルターは、マークル木のアクション・キャッシュの有無をチェックできる:

```scala
def hasSucceeded(className: String): Boolean = digests.get(className) match
  case None     => false
  case Some(ts) => hasCachedSuccess(ts)

def hasCachedSuccess(ts: Digest): Boolean =
  val input = cacheInput(ts)
  ActionCache.exists(input._1, input._2, input._3, config)

def cacheInput(value: Digest): (Unit, Digest, Digest) =
  ((), value, Digest.zero)
```

もしアクション・キャッシュが存在すれば、`0` であることは分かっているので、値の捕獲は行わない。

### デモ 1: 情報の受け渡し

リモート・キャッシュの設定方法は [Bazel 互換な sbt 2.x リモートキャッシュ][sbt-remote-cache-with-bazel-compat]参照。`CowTest` でテストしてみよう。

```scala
package example

import org.junit.Test
import org.junit.Assert.assertEquals

class CowTest:
  @Test
  def testMoo: Unit =
    val cow = Cow()
    assertEquals(cow.moo, 0)
end CowTest
```

**ディレクトリ 1**:

まずは普通にテストを通す:

```bash
$ sbt
[info] welcome to sbt 2.0.0-alpha11-SNAPSHOT (Azul Systems, Inc. Java 1.8.0_402)
....
sbt:inctest> testQuick
[info] Updating inctest_3
[info] Resolved inctest_3 dependencies
....
[info] Passed: Total 1, Failed 0, Errors 0, Passed 1
[success] elapsed time: 3 s, cache 0%, 6 onsite tasks
```

**ディレクトリ 2**:

次に、ディレクトリ全体を別のディレクトリにコピーして、ディスク・キャッシュも空にしてからテストを再実行する:

```bash
$ rmtrash $HOME/Library/Caches/sbt/v2/ && rmtrash target && rmtrash project/target
$ sbt
[info] welcome to sbt 2.0.0-alpha11-SNAPSHOT (Azul Systems, Inc. Java 1.8.0_402)
sbt:inctest> testQuick
....
[info] Passed: Total 0, Failed 0, Errors 0, Passed 0
[info] No tests to run for Test / testQuick
[success] elapsed time: 2 s, cache 20%, 1 remote cache hit, 4 onsite tasks
```

同じラップトップ内ではあるが、これは Bazel 互換なリモート・キャッシュを介して一つのディレクトリから別のディレクトリへとテスト結果を渡すことができたことを示す。

### デモ 2: 結果の無効化

最小化の条件もテストしてみよう。まずは、テスト自身を変更してちゃんと失敗するかを確認する:

```scala
package example

import org.junit.Test
import org.junit.Assert.assertEquals

class CowTest:
  @Test
  def testMoo: Unit =
    val cow = Cow()
    assertEquals(cow.moo, 1)
end CowTest
```

```bash
sbt:inctest> testQuick
[error] Test example.CowTest.testMoo failed: java.lang.AssertionError: expected:<0> but was:<1>, took 0.002 sec
[error]     at example.CowTest.testMoo(CowTest.scala:10)
[error]     ...
[error] Failed: Total 1, Failed 1, Errors 0, Passed 0
[error] Failed tests:
[error]   example.CowTest
[error] (Test / testQuick) sbt.TestsFailedException: Tests unsuccessful
[error] elapsed time: 0 s, cache 100%, 5 remote cache hits
```

期待通り失敗した。次に、`Cow#moo` が `1` を返すように変更する:

```scala
package example

class Cow extends Animal:
  def moo: Int = 1
end Cow
```

期待通り、成功した。次に、`Animal` trait の実装を変更する:

```scala
package example

trait Animal:
  def walk: Int = 0
  def swim: Int = 0
end Animal
```

```bash
sbt:inctest> testQuick
[info] compiling 1 Scala source to target/out/jvm/scala-3.4.2/inctest/backend ...
[info] compiling 1 Scala source to target/out/jvm/scala-3.4.2/inctest/backend ...
[info] Passed: Total 1, Failed 0, Errors 0, Passed 1
[success] elapsed time: 1 s, cache 16%, 1 remote cache hit, 5 onsite tasks
```

期待通り、テストが再実行された。最後に、`CowTest` とは無関係な `Mineral` trait の実装を変更する:

```scala
package example

trait Mineral:
  def ok: Boolean = false
end Mineral
```

```bash
sbt:inctest> testQuick
[info] compiling 1 Scala source to target/out/jvm/scala-3.4.2/inctest/backend ...
[info] Passed: Total 0, Failed 0, Errors 0, Passed 0
[info] No tests to run for Test / testQuick
[success] elapsed time: 0 s, cache 20%, 1 remote cache hit, 4 onsite tasks
```

コンパイルはしたが、`CowTest` の結果は無効化しなかったため、これも期待通り動作した。他にも細かい改善可能な点はあるかもしれないが、これでテストのリモート・キャッシュ化をデモできたと思う。

### まとめ

[sbt/sbt#7644][7644] において、sbt 2.x のテストのリモート・キャッシュ化実装して、マシン境界をまたいでテストの成功結果を保存できるようにした。将来的に `test` を置き換えるかもしれない `testQuick` は、インプットの変更によって無効化されたテストのみを実行する。sbt 1.x 系と違って、このプルリクではマシン間で安全に共有できるようにマークル木を使ってテスト結果を無効化する。一般的に、テスト結果をキャッシュ化できれば、CI ジョブを数桁台高速化することが可能となる。

### Appdendix A: 酢鶏

酢豚は sbt のバクロニムでもある。豚肉を鶏肉に置き換えた酢鶏 (sudori) は酢豚からの派生で、sbt 2.x の開発中のコードネームとして僕が使っている。ケチャップという言葉は、中国南部海岸沿い福建の膎汁 (kôe-chiap もしくは kê-chiap) という言葉に由来していて魚醤という意味だ。魚醤はしばらくは醤油などの豆系調味料に駆逐されていたが、1700年代にベトナムなどから再導入された。貿易を通じて魚醤はイギリスでも流行して、輸入する代わりに生産されマッシュルームペーストへと変化した。1800年代にはアメリカ人がこれをトマトで作り出す。広東語での酢豚は咕嚕肉 (gūlōuyuhk) と呼ばれグールーというのはお腹が鳴る音を表しているが、これらの広東料理のレシピにケチャップが取り入れられているのが一周回った感があって興味深い。

### Appendix B: なぜ JUnit 4 を使ったのか?

実は、テスト・フレームワークが使うマクロが非密閉であることがあるからだ。例えば、munit を使った場合、ディレクトリを変えると異なるバイトコードが生成される:

```diff
--- a/example/CowTest.class.asm
+++ b/example/CowTest.class.asm
@@ -56,7 +56,7 @@
     ]
     NEW munit/Location
     DUP
-    LDC "/Users/xxx/inctest/src/test/scala/example/CowTest.scala"
+    LDC "/Users/xxx/inctest2/src/test/scala/example/CowTest.scala"
     BIPUSH 6
     INVOKESPECIAL munit/Location.<init> (Ljava/lang/String;I)V
     INVOKEVIRTUAL example/CowTest.assert (Lscala/Function0;Lscala/Function0;Lmunit/Location;)V
```
