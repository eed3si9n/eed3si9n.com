---
title:       "Hedgehog for Scala 入門"
type:        story
date:        2024-11-18
url:         /ja/hedgehog-scala
tags:        [ "scala" ]
---

  [claessenhughes2000]: https://dl.acm.org/doi/10.1145/351240.351266
  [choosing]: https://fsharpforfunandprofit.com/posts/property-based-testing-2/
  [hypothesis]: https://hypothesis.works/

本稿では、[Hedgehog for Scala](https://hedgehogqa.github.io/scala-hedgehog/) というプロパティー・ベース・テスト・フレームワークを簡単に紹介したい。Hedgehog for Scala は、Jacob Stanley さんと Nikos Baxevanis さん共著の Haskell Hedgehog というライブラリを基に 2018年ごろ Charles O'Farrell さんが実装したもので、最近では Kevin Lee さんが主にメンテナンスを行っている。

<!--more-->

## プロパティー・ベース・テスト

プロパティー・ベース・テストの起源は Koen Claessen さんと John Hughes さん共著の [QuickCheck: a lightweight tool for random testing of Haskell programs][claessenhughes2000] (2000) だと言われている。

2019年の Erik さんの [property-based testing](https://www.youtube.com/watch?v=O78hnJuzQwA) トークを引用してプロパティー・ベース・テストを軽くまとめると:

1. インプット・データをどう生成するかを記述
2. 全てのインプット・データに当てはまる属性を記述
3. 納得がいくまで (もしくは失敗するまで) データを生成する

単体テストと比較した場合のこのような方法のメリットは、自分でも予期しなかったバグを発見できる可能性があるということだ。

元祖の Haskell QuickCheck はこれは `Arbitrary a` (任意の a) という型クラスと `Gen a` と呼ばれるランダムな値を生成するデータ型によって表される。この QuickCheck にインスパイヤされた ScalaCheck も、基本的に `Arbitrary` と `Gen` という二重構造を取る。

### シュリンク: 自動最小化

プロパティー・ベース・テストの便利な機能の 1つに、テストが失敗した場合、最も単純な失敗例を導出する自動最小化機能というものがある。QuickCheck と ScalaCheck の場合、この機能を使うにはテスト・ユーザが `shrink` 関数を実装必要があって、だいたいの人は面倒くさがって行われないことが多い。

Hedgehog の良い所は、シュリンクを `Gen` に統合させることで、自動最小化を自動化してくれていることだ。[Hypothesis][hypothesis] などのテスト・フレームワークも似た方法を取っているらしい。詳細は、Haskell Hedgehog 原作者の Jacob Stanley さんの [Gens N' Roses: Appetite for Reduction](https://www.youtube.com/watch?v=LfD0DHqpeVQ) を参照してほしい。

## Hedgehog for Scala

Hedgehog は覚えることが少なくて、`Gen` と `Result` だけ分かっていればいい。

### セットアップ

```scala
lazy val hedgehogVersion = "0.11.0"

scalaVersion := "3.5.2"
libraryDependencies ++= Seq(
  "qa.hedgehog" %% "hedgehog-core" % hedgehogVersion % Test,
  "qa.hedgehog" %% "hedgehog-runner" % hedgehogVersion % Test,
  "qa.hedgehog" %% "hedgehog-sbt" % hedgehogVersion % Test,
)
```

### Gen

[チュートリアル](https://hedgehogqa.github.io/scala-hedgehog/docs/guides-tutorial#generators)によると:

> ジェネレーターは、テストデータの生成を受け持ち、`hedgehog.Gen` クラスで表される。

```scala
import hedgehog.*
import hedgehog.core.PropertyT
import hedgehog.runner.*

object FooTest extends Properties:
  override lazy val tests = List(
    property("distinct doesn't change list", propDistinct),
  )

  val intGen = Gen.int(Range.linear(0, 100))
  val listGen = Gen.list[Int](intGen, Range.linear(0, 100))

  def propDistinct: PropertyT[Result] = listGen.forAll.map: xs =>
    Result.assert(xs.distinct == xs)
end FooTest
```

上の例では、`intGen` と `listGen` が例のジェネレーターで、それぞれ `Gen.int` と `Gen.list` というヘルパー関数を使って定義されている。例えば、`intGen` は線形に分散された形で 0 から 10 の整数を生成する。

### Result

`Result` は `Boolean` 値を少しかっこよくして、ログメソッド `.log(...)` を付けただけらしい。等価性の検査はよく出てくるので `====` という簡易記法が用意されている:

```scala
  def propDistinct = listGen.forAll.map: xs =>
    xs.distinct ==== xs
```

ここで僕が主張している属性は、ランダムな `xs` があるとき、`distinct` メソッドを呼び出すと、全く同じリストが得られるというもので、明らかに間違っている。

### シュリンクのデモ

このテストを sbt か Metals で走らせると、以下のようなアウトプットが得られる:

```
Using random seed: 1765426093946750
- FooTest$.distinct doesn't change list: Falsified after 3 passed tests
> List(0, 0)
> === Not Equal ===
> --- lhs ---
> List(0)
> --- rhs ---
> List(0, 0)
```

テストは失敗して、Hedgehog は `List(0, 0)` という反例を出してきた。きれいな値に最小化されていることが分かる。ここでは意図的に偽の主張を行ったが、実践では本当のプロパティーを使ってコードのバグ探しを行う。

## プロパティーを書くための戦略

属性を考え出すのは、結構手強く感じる。全員がコードに対する普遍的なプロパティーを思いつければそれは理想かもしれないが、あまり難しく考えずに、段階を踏んで書くこともできる。 Scott Wlaschin さんの [Choosing properties for property-based testing][choosing] も参照。

### とりあえず関数を呼び出してみる

テストが書かれないことが多いことを考えると、ただ関数を呼び出すというテストは何も無いよりはマシだ。ランダムは値を渡してもクラッシュはしないことをテストできるからだ。結果が null じゃないことをテストしてもいい。

### シンメトリー

システムにシンメトリーを見つけた場合、プロパティーにできることが多い。Scott Wlaschin さんのリストだと:

- 異なる道筋、同じ目的地 (Different paths, same destination)
- 行って、戻って来る (There and back again)

「行って、戻って来る」パターンとしては、シリアライズ後にデシリアライズした場合同一の値になるというのがよくある例だ。

### 不変性

不変性は簡単には見つからないことが多い。Scott Wlaschin さんのリストだと:

- いつまでも変わらないこともある
- こっちが変わっても、向こうは同じ

2つ目は冪等性の話をしているみたいだ。例えば、`distinct` を 2回呼んでも、1回呼んだ結果と同一となる。

```scala
  def propDistinct = listGen.forAll.map: xs =>
    xs.distinct ==== xs.distinct.distinct
```

### テストオラクル

テストオラクル戦略は、2つの異なる実装で走らせて結果を比較するという手法だ。これは関数の書き換えを行ったり、最適化を実装していて、遅いが確実な実装がある場合などに役に立つ。

## Gen の実践

<https://github.com/sbt/sbt/pull/7875> は ScalaCheck から Hedgehog に移植した例だ。

### identifier

識別子っぽい文字列の生成を行う例:

```scala
  def identifier: Gen[String] = for
    first <- Gen.char('a', 'z')
    length <- Gen.int(Range.linear(0, 20))
    rest <- Gen.list(
      Gen.frequency1(
        8 -> Gen.char('a', 'z'),
        8 -> Gen.char('A', 'Z'),
        5 -> Gen.char('0', '9'),
        1 -> Gen.constant('_')
      ),
      Range.singleton(length)
    )
  yield (first :: rest).mkString
```

`Gen.frequency1(...)` は頻度と `Gen` 候補を受け取る。

### 疑似型クラスとしての Gen

`Arbitrary` とは違って `Gen` は型クラスではないので、`Gen` を明示的に渡すことが期待されている。しかし、`summon(...)` をラップした関数が以下のように書ける:

```scala
  def gen[A1: Gen]: Gen[A1] = summon[Gen[A1]]
```

それで、以下のようなことを書ける:

```scala
object BuildSettingsInstances:
  given genScopeAxis[A1: Gen]: Gen[ScopeAxis[A1]] =
    Gen.choice1[ScopeAxis[A1]](
      Gen.constant(This),
      Gen.constant(Zero),
      summon[Gen[A1]].map(Select(_))
    )

  given Gen[ConfigKey] = Gen.frequency1(
    2 -> Gen.constant[ConfigKey](Compile),
    2 -> Gen.constant[ConfigKey](Test),
    1 -> Gen.constant[ConfigKey](Runtime),
    1 -> Gen.constant[ConfigKey](IntegrationTest),
    1 -> Gen.constant[ConfigKey](Provided),
  )

  given Gen[Scope] =
    for
      r <- gen[ScopeAxis[Reference]]
      c <- gen[ScopeAxis[ConfigKey]]
      t <- gen[ScopeAxis[AttributeKey[?]]]
      e <- gen[ScopeAxis[AttributeMap]]
    yield Scope(r, c, t, e)
end BuildSettingsInstances
```

これで、`import BuildSettingsInstances.given` という縛りの中では、自分たちがテストしたい型に関して coherent な `Gen` を定義して、それを `gen[A1]` として呼び出すということができる。

```scala
  def propReferenceKey: Property =
    for
      ref <- gen[Reference].forAll
      k <- genKey[Unit].forAll
      actual = k match
        case k: InputKey[?]   => ref / k
        case k: TaskKey[?]    => ref / k
        case k: SettingKey[?] => ref / k
    yield Result.assert(
      actual.key == k.key &&
        (if k.scope.project == This then actual.scope.project == Select(ref)
         else true)
    )
```

### propertyN

サンプル数を設定するのには以下のような関数を使っている:

```scala
import hedgehog.core.{ ShrinkLimit, SuccessCount }

def propertyN(name: String, result: => Property, n: Int): Test =
  Test(name, result)
    .config(_.copy(testLimit = SuccessCount(n), shrinkLimit = ShrinkLimit(n * 10)))
```

### Hedgehog for Scala の弱み

今日現在で、報告されている issue で最も古いものは ["Gen.list is not stack safe"](https://github.com/hedgehogqa/scala-hedgehog/issues/47) という名前がついている。つまり、Cats などの最近の関数型ライブラリと違って、Hedgehog の内部実装ではトランポリンが行われていないということだ。

これは、データのサイズによっては stackoverflow を起こす可能性があり、その場合スタックサイズを変更するなどして回避する必要がある。

## まとめ

1. [Hedgehog for Scala](https://hedgehogqa.github.io/scala-hedgehog/) は、2018年ごろ Charles O'Farrell が実装したプロパティー・ベース・テスト・フレームワークで、最近では Kevin Lee さんが主にメンテナンスを行っている。
2. Hedgehog はランダム値の生成を `Gen` に一本化して (`Arbitrary` が無くなった)、また反例を算出するときの最小化を自動的に行う。
3. `Gen` は明示的に渡すこともできるし、無名の given から合成することも可能だ。
