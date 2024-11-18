---
title:       "intro to Hedgehog for Scala"
type:        story
date:        2024-11-18
url:         /hedgehog-scala
tags:        [ "scala" ]
---

  [claessenhughes2000]: https://dl.acm.org/doi/10.1145/351240.351266
  [choosing]: https://fsharpforfunandprofit.com/posts/property-based-testing-2/
  [hypothesis]: https://hypothesis.works/

In this post, I want to talk about [Hedgehog for Scala](https://hedgehogqa.github.io/scala-hedgehog/), a property-based testing framework created by Charles O'Farrell around 2018, and has been maintained by Kevin Lee more recently, based on Haskell Hedgehog, which was cofounded by Jacob Stanley and Nikos Baxevanis.

<!--more-->

## property-based testing

The origin of property-based testing is considered to be [QuickCheck: a lightweight tool for random testing of Haskell programs][claessenhughes2000] by Koen Claessen and John Hughes (2000).

Citing from Erik's talk about [property-based testing](https://www.youtube.com/watch?v=O78hnJuzQwA) in 2019, the basic idea behind property-based testing is:

1. describe how to generate input data
2. describe properties for all input data
3. generate cases until satisfied (or until failure)

The benefit of this approach, as opposed to the unit testing, is that we have a chance to catch bugs we didn't anticipate.

In the original Haskell QuickCheck, this is expressed via a typeclass called `Arbitrary a` and a data structure called `Gen a`, which helps you create randomized values. ScalaCheck, which was inspired by QuickCheck, also takes `Arbitrary` and `Gen` double structure.

### shrinking: automatic minimization

One of an interesting features of property-based test is its ability to automatically minimize the failing example when a test fails. With QuickCheck and ScalaCheck, this process requires `shrink` implemented by the test users, which often does not happen.

Hedgehog automates this process, by integrating shrinking into `Gen`, similar to the approach taken by [Hypothesis][hypothesis]. For more details, see Jacob Stanley's [Gens N' Roses: Appetite for Reduction](https://www.youtube.com/watch?v=LfD0DHqpeVQ) talk.

## Hedgehog for Scala

With Hedgehog, there are mainly two concepts `Gen` and `Result`.

### setup

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

According to the [tutorial](https://hedgehogqa.github.io/scala-hedgehog/docs/guides-tutorial#generators):

> Generators are responsible for generating test data in Hedgehog, and are represented by the `hedgehog.Gen` class.

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

In the above, `intGen` and `listGen` are example generators, which is defined using `Gen.int` and `Gen.list` helper functions. For example, `intGen` will produce an integer from 0 to 100, distributed linearly.

### Result

`Result` is a fancy `Boolean` value, that also supports `.log(...)`. Since equality check is relatively common there's also a shorthand `====`:

```scala
  def propDistinct = listGen.forAll.map: xs =>
    xs.distinct ==== xs
```

The property that I'm claim, which is that for a random `xs` calling `distinct` is going to produce the same exact list, is obviously false.

### shrinking demo

Running the test from sbt or Metals, we should get an output like this:

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

The test failed, and Hedgehog has produced a counterexample `List(0, 0)`. This looks nice and minimized. I've intentionally made a false claim, but in practice we would be using the real properties to catch bugs in your code.

## strategies for writing properties

Coming up with a _property_ can be intimidating at first. If we can all come up with a nice universal properties for our code that might be ideal, but you can take small steps. See also Scott Wlaschin's [Choosing properties for property-based testing][choosing].

### just call the function

Given that test isn't often written, just calling the function under test is better than nothing. What you're testing is that it won't crash after passing in a random input. Maybe check that the result is non-null.

### symmetry

Whenever you find symmetry in your system, that's often a good candidate for a property. From Scott Wlaschin's list:

- Different paths, same destination
- There and back again

"There and back again" would be something like calling serialization then deserialization would yield the same value.

### invariance

Finding an invariance is not always easy. From Scott Wlaschin's list:

- Some things never change
- The more things change, the more they stay the same

The second one is actually talking about idempotence. For example, calling `distinct` twice shouldn't change the list since the first one.

```scala
  def propDistinct = listGen.forAll.map: xs =>
    xs.distinct ==== xs.distinct.distinct
```

### test oracle

The test oracle strategy is basically running two different implementations and comparing the results. This could be useful for function rewrite, or when implementing an optimization, and you have access to a slow-but-stable implementation.

## Gen in practice

<https://github.com/sbt/sbt/pull/7875> is an example of porting from ScalaCheck to Hedgehog.

### identifier

Here's an example of generating a string that looks like an identifier:

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

`Gen.frequency1(...)` takes a frequency and `Gen` candidates.

### Gen as pseudo-typeclass

Unlike `Arbitrary`, `Gen` isn't a typeclass, so you're expected to pass `Gen` around explicitly. If you want, however, you can write a `summon(...)` wrapper as follows:

```scala
  def gen[A1: Gen]: Gen[A1] = summon[Gen[A1]]
```

Then you could do something like:

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

Now, within the confine of `import BuildSettingsInstances.given`, we will have a coherent `Gen` for the types that we care about, which can be summoned using `gen[A1]`.

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

### limitations of Hedgehog for Scala

The oldest issue that's open as of this writing reads ["Gen.list is not stack safe"](https://github.com/hedgehogqa/scala-hedgehog/issues/47). So unlike modern functional programming libraries, like Cats, Hedgehog's internal code does not trampoline.

This means depending on the size of your data, you might run into a stackoverflow, or you might need to bump up the stack size to workaround the problem.

## summary

1. Hedgehog for Scala is a property-based testing framework created by Charles O'Farrell around 2018, and has been maintained by Kevin Lee more recently.
2. Hedgehog simplifies the random value creation by just needing `Gen` (no more `Arbitrary`), and it automatically minimizes the failing example.
3. `Gen` can be passed around explicitly, or if you want, defined as composite of anonymous givens.
