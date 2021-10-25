---
title:       "sudori part 2"
type:        story
date:        2021-08-01
draft:       false
promote:     true
sticky:      false
url:         /ja/sudori-part2
tags:        [ "sbt" ]
---

  [sudori]: https://github.com/eed3si9n/sudori
  [metaprogramming]: http://dotty.epfl.ch/docs/reference/metaprogramming/toc.html
  [Enum]: http://dotty.epfl.ch/docs/reference/enums/adts.html
  [TypeProjection]: http://dotty.epfl.ch/docs/reference/dropped-features/type-projection.html
  [so-50043630]: https://stackoverflow.com/q/50043630/3827
  [Tree]: https://github.com/lampepfl/dotty/blob/3.0.1/library/src/scala/quoted/Quotes.scala#L255
  [Transformer]: https://github.com/scala/scala/blob/v2.13.6/src/reflect/scala/reflect/api/Trees.scala#L2563
  [TreeMap]: https://github.com/lampepfl/dotty/blob/3.0.1/library/src/scala/quoted/Quotes.scala#L4370
  [Type]: http://dotty.epfl.ch/docs/reference/metaprogramming/macros.html#types-for-quotations
  [statically-unknown]: https://docs.scala-lang.org/scala3/guides/macros/faq.html#how-do-i-summon-an-expression-for-statically-unknown-types
  [Instance]: https://github.com/sbt/sbt/blob/v1.5.5/core-macros/src/main/scala/sbt/internal/util/appmacro/Instance.scala
  [1c22478edc]: https://github.com/sbt/sbt-zero-thirteen/commit/1c22478edcad5b083330445317d3ef28f3fa3ef2
  [Selective]: https://eed3si9n.com/ja/selective-functor-in-sbt
  [part1]: https://eed3si9n.com/ja/sudori-part1
  [TypeTest]: http://dotty.epfl.ch/docs/reference/other-new-features/type-test.html
  [Lambda]: https://github.com/lampepfl/dotty/blob/3.0.1/library/src/scala/quoted/Quotes.scala#L1290
  [createFunction]: https://github.com/sbt/sbt/blob/v1.5.5/core-macros/src/main/scala/sbt/internal/util/appmacro/ContextUtil.scala#L234

実験的 sbt として、酢鶏 (sudori) という小さなプロジェクトを作っている。当面の予定はマクロ周りを Scala 3 に移植することだ。sbt のマクロを分解して、土台から作り直すという課題だ。これは Scala 2 と 3 でも上級者向けのトピックで、僕自身も試行錯誤しながらやっているので、覚え書きのようなものだと思ってほしい。これはそのパート2だ。

参考:
- [Scala 3 Reference: Metaprogramming][metaprogramming]
- [酢鶏、パート1][part1]

### Instance

`build.sbt` マクロと言われて思いつくのは `.value` を使った Applicative do マクロなんじゃないかと思う。呼び方としては、そうは呼ばない人もいるかもしれないが。この命令型から関数型への変換を担っているのは、ちょっと変わった名前を持つ [Instance][Instance] class のコンパニオンだ:

```scala
/**
 * The separate hierarchy from Applicative/Monad is for two reasons.
 *
 * 1. The type constructor is represented as an abstract type because a TypeTag cannot represent a type constructor directly.
 * 2. The applicative interface is uncurried.
 */
trait Instance {
  type M[x]
  def app[K[L[x]], Z](in: K[M], f: K[Id] => Z)(implicit a: AList[K]): M[Z]
  def map[S, T](in: M[S], f: S => T): M[T]
  def pure[T](t: () => T): M[T]
}

trait MonadInstance extends Instance {
  def flatten[T](in: M[M[T]]): M[T]
}
```

Scaladoc でも言及されているが、sbt は内部に独自の `Applicative[_]` 型クラスを定義している。Mark が [2012年][1c22478edc] (Scala 2.10.0-M6 あたり) に列挙した 2つの理由が現時点でも当てはまるかは不明だ。マクロはこんな感じだ:

```scala
  def contImpl[T, N[_]](
      c: blackbox.Context,
      i: Instance with Singleton,
      convert: Convert,
      builder: TupleBuilder,
      linter: LinterDSL
  )(
      t: Either[c.Expr[T], c.Expr[i.M[T]]],
      inner: Transform[c.type, N]
  )(
      implicit tt: c.WeakTypeTag[T],
      nt: c.WeakTypeTag[N[T]],
      it: c.TypeTag[i.type]
  ): c.Expr[i.M[N[T]]] = ....
```

このシグネチャを解読するには、sbt の内部を少し理解する必要がある。

### セッティングとタスク

以前に [Selective][Selective] でも書いたが、関数型プログラミングの 2つの特徴としてデータを変化させるのではなく immutable (不変)なデータ構造を使うことと、いつ、どのようにして effect (作用) を取り扱うかに気を使っていることが挙げられる。

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

`sbt.Task` は副作用関数 `() => A` のラッパーだと便宜的に考えていい。ただし、僕たちが「compile はタスクだ」と言うとき、の文脈でのタスクは `Initialize[Task[A]]` で表される。つまり、これは実行プランと作用を表した入れ子データ型だ。このマクロのシグネチャを以下のように書き換えることができる:

```scala
  def contImpl[A, Effect[_]](
      c: blackbox.Context,
      i: Instance & scala.Singleton,
      convert: Convert,
      builder: TupleBuilder,
      linter: LinterDSL
  )(
      t: Either[c.Expr[A], c.Expr[i.F[A]],
      inner: Transform[c.type, Effect]
  ): c.Expr[i.F[Effect[A]]] = ....
```

では、この `t` は何だろうか? 何故 Either を受け取るのだろうか? 答えは、`Left[c.Expr[A]]` を受け取ると Applicative-do を行って、`Right[c.Expr[i.F[A]]]` を受け取ると Monadic-do を実行するというふうになっているからだ。コード再利用のためのちょっと変わった実装詳細だ。[パート1][part1]で書いたとおり、`convert` は部分関数の豪華版で、抽象構文木の一部を検索置換できるようになっている。

### pure

以下のようなセッティング式を考える:

```scala
someKey := { 1 }
```

`someKey` がセッティングだとすると、`Initialize[Int]` を構築する必要がある。`contImpl` マクロは、`Initialize` のための Applicative の「インスタンス」を受け取ることでジェネリックな形でこれを実行する。具体的にはこの場合 `i.pure(...)` を呼び出す。

```scala
// no inputs, so construct F[A] via Instance.pure or pure+flatten
def pure(body: Term): Expr[i.F[Effect[A]]] =
  def pure0[A1: Type](body: Expr[A1]): Expr[i.F[A1]] =
    '{
      $i
        .pure[A1] { () => $body }
        .asInstanceOf[i.F[A1]]
    }
  eitherTree match
    case Left(_) => pure0[Effect[A]](body.asExprOf[Effect[A]])
    case Right(_) =>
      flatten(pure0[i.F[Effect[A]]](body.asExprOf[i.F[Effect[A]]]))
```

`i` から `pure` 関数を呼ぶだけの一見実直なコードに見える。しかし、実際にはこれは以下のように失敗する:

<code>
[error] -- [E007] Type Mismatch Error: sudori/core-macros/src/main/scala-3/sbt/internal/util/appmacro/Cont.scala:119:13
[error] 119 |            $i
[error]     |             ^
[error]     |  Found:    (i : sbt.internal.util.appmacro.MonadInstance & Singleton)
[error]     |  Required: quoted.Expr[Any]
[error] one error found
</code>

### i.type からインスタンスを取得する

`i` をクォートされたコードにスプライスする必要がある。1つの方法としては `i` をインライン化することがだ、そうすると今度は `i.F` といった形で `i` が使えなくなるのでうまくいかない。`i` をシングルトン型から召喚するテクニックがある。シングルトン型は、住人となる値を 1つだけ持つ型で、`p` が `AnyRef` を拡張する項ならば `p.type` と表記できる。

`i.type` があると仮定する。コンテキストバウンド `A: Type` と書くことで　`Type[i.type]` を取得できる。次に、`TypeRepr[A]` と書いて、マクロ時の型情報を提供する `TypeRepr` を取得する。ただし、`TypeRepr[A]` に対してパターンマッチが効かない。ここで Scala 3 の新機能である `unapply` を用いて型検査を行うことができる [TypeTest][TypeTest] を使う。

```scala
  def extractSingleton[A: Type]: Expr[A] =
    def termRef(r: TypeRepr)(using rtt: TypeTest[TypeRepr, TermRef]): Ref = r match
      case rtt(ref) => Ref.term(ref)
      case _        => sys.error(s"expected termRef but got $r")
    termRef(TypeRepr.of[A]).asExprOf[A]
```

`pure` に戻ると、これは以下のように使うことができる:

```scala
// we can extract i out of i.type
val instance = extractSingleton[i.type]

// no inputs, so construct F[A] via Instance.pure or pure+flatten
def pure(body: Term): Expr[i.F[Effect[A]]] =
  def pure0[A1: Type](body: Expr[A1]): Expr[i.F[A1]] =
    '{
      $instance
        .pure[A1] { () => $body }
        .asInstanceOf[i.F[A1]]
    }
  eitherTree match
    case Left(_) => pure0[Effect[A]](body.asExprOf[Effect[A]])
    case Right(_) =>
      flatten(pure0[i.F[Effect[A]]](body.asExprOf[i.F[Effect[A]]]))
```

### map

以下のようなセッティング式を考える:

```scala
someKey := { name.value + "!" }
```

これは以下のように展開される:

```scala
someKey <<= i.map(wrap(name), (q1: String) => { q1 + "!" })
```

### ラムダ式

面白いのは、ラムダ式 ()

The interesting part is generating the lambda expression (anonymous function) `(q1) => { q1 + "!" }`. If we didn't care about the symbol for the lambda expression, then there's a shortcut function provided by Quote Reflection called [Lambda(...)][Lambda]:

```scala
def makeLambdaImpl(expr: Expr[Unit])(using qctx: Quotes) =
  import qctx.reflect.*
  Lambda(
    owner = Symbol.spliceOwner,
    tpe = MethodType(List("x"))(_ => List(TypeRepr.of[Boolean]), _ => TypeRepr.of[String]),
    rhsFn = (sym, params0) => {
      val param = params0.head
      val toStr = Select.unique(Ref(param.symbol), "toString")
      toStr.appliedToNone
    }
  ).asExprOf[Boolean => String]
```

### lambda expansion problem

This presents a problem because to create a lambda expression we'd have to know the list of parameters upfront listed in `MethodType(...)`. In sbt 1.x macro, currently it uses `transformWrappers(...)` and walk the tree to figure out whether we need to create a lambda expression, and if so how many parameters we need. The substitution function also needs to know the `val`, which requires a function symbol to the lambda expression.

sbt 1.x goes through a bunch of casting to create [an anonymous function value][createFunction], creating `Function(...)` tree, and assigning the symbol. As far as I know, none of these techniques would translate to Scala 3 unless we can somehow cast into the internal API. Two workarounds that I can think of are:

- Walk the tree twice
- Move the `val` out of lambda

Walking the tree twice would let us create lambda expressions immutably, but that could add some performance penalty. So for now, we can try the second way, which is to move the `val` out of lambda, and turn it into `var`. You might be repulsed by the use of `var`, which is an instinct we develop as Scala programmers. `var` is normally discouraged because shared mutable state makes the program difficult to reason about. In this case, we won't expose the `var` to outside, and it will be assigning exactly once before use, so we can think of it as a minor implemtation detail of the macro.

Here's an example. In sbt 1.x let's say we are generating something like:

```scala
someKey <<= i.map(wrap(name), (q1: String) => { q1 + "!" })
```

The workaround would be to generate:

```scala
someKey <<= {
  // step 1: when name.value is found, declare a var and add it to input list
  var q1: String = _

  // step 3: because there's single input, map is chosen, which requires a lambda
  // expression with a single parameter accepting p1: String
  i.map(wrap(name), (p1: String) => {
    // step 4: assign p1 value to q1 placeholder
    q1 = p1

    q1 + "!" // step 2: name.value is replaced with ref to q1
  })
}
```

As long as the name `q1` is unique within the scope this should be safe. So the implementation splits into the four steps outlined above as comments:

1. when `name.value` is found, declare a `var` and add it to `input` list
2. `name.value` is replaced with ref to `q1`
3. because there's single input, `map` is chosen, which then requires a lambda expression with a single parameter accepting `p1: String`
4. assign `p1` value to `q1` placeholder

Here's how we can perform steps 1 and 2:

```scala
def subToProxy(tpe: TypeRepr, qual: Term, selection: Term): Term =
  val vd = freshValDef(Symbol.spliceOwner, tpe)
  inputs = Input(tpe, qual, vd) :: inputs
  tpe.asType match
    case '[a] =>
      Typed(Ref(vd.symbol), TypeTree.of[a])

def substitute(name: String, tpe: TypeRepr, qual: Term, replace: Term) =
  convert[A](name, qual) transform { (tree: Term) =>
    subToProxy(tpe, tree, replace)
  }
val tx = transformWrappers(expr.asTerm, substitute)
```

Steps 3 and 4:

```scala
def genMap(body: Term, input: Input): Expr[i.F[Effect[A]]] =
  def genMap0[A1: Type](body: Expr[A1], input: Input): Expr[i.F[A1]] =
    input.tpe.asType match
      case '[a] =>
        val tpe = MethodType(List("$p0"))(_ => List(TypeRepr.of[a]), _ => TypeRepr.of[A1])
        val lambda = Lambda(
          owner = Symbol.spliceOwner,
          tpe = tpe,
          rhsFn = (sym, params) => {
            val param = params.head.asInstanceOf[Term]
            Block(
              // $q1 = $p0
              List(Assign(Ref(input.local.symbol), param)),
              body.asTerm
            )
          }
        ).asExprOf[a => A1]
        val expr = input.expr.asExprOf[i.F[a]]
        Typed(
          Block(
            // this contains var $q1 = ...
            List(input.local),
            '{
              val _i = $instance
              _i
                .map[a, A1]($expr.asInstanceOf[_i.F[a]], $lambda)
            }.asTerm
          ),
          TypeTree.of[i.F[A1]]
        ).asExprOf[i.F[A1]]
  eitherTree match
    case Left(_) =>
      genMap0[Effect[A]](body.asExprOf[Effect[A]], input)
    case Right(_) =>
      flatten(genMap0[i.F[Effect[A]]](body.asExprOf[i.F[Effect[A]]], input))
```

The unit test looks like this:

```scala
package sbt.internal

import sbt.internal.util.appmacro.*
import verify.*
import ContTestMacro.*

object ContTest extends BasicTestSuite:
  test("pure") {
    assert(contMapNMacro[Int](12) == List(12))
  }

  test("getMap") {
    assert(contMapNMacro[Int](ContTest.wrapInit(List(1)) + 1).toString == "List(2)")
  }

  // This compiles away
  def wrapInit[A](a: List[A]): A = ???
end ContTest
```

Here I'm using `List` datatype as the `Functor` to test this.

### freshValDef

There's a detail I glossed over in the above, which is:

```scala
val vd = freshValDef(Symbol.spliceOwner, tpe)
```

Defining a `val` or `var` can be done like this:

```scala
def freshValDef(parent: Symbol, tpe: TypeRepr): ValDef =
  tpe.asType match
    case '[a] =>
      val sym =
        Symbol.newVal(parent, freshName("q"), tpe, Flags.Mutable, Symbol.noSymbol)
      ValDef(sym, rhs = Option('{ 0 }.asTerm))

private var counter: Int = -1
def freshName(prefix: String): String =
  counter = counter + 1
  s"$$${prefix}${counter}"
```

The problem is that I'm hardcoding the right-hand side to be `0`.

### Zero

There are probably multiple ways to initialize a `var` with a zero-equivalent value, but probably a more straightforward way would be to define a typeclass called `Zero[A]`:

```scala
package sbt.internal.util.appmacro

trait Zero[A]:
  def zero: A

object Zero extends LowPriorityZero:
  private[appmacro] def mk[A](a: A): Zero[A] = new Zero:
    def zero: A = a

  given Zero[Byte] = Zero.mk(0: Byte)
  given Zero[Char] = Zero.mk(0: Char)
  given Zero[Short] = Zero.mk(0: Short)
  given Zero[Int] = Zero.mk(0)
  given Zero[Long] = Zero.mk(0L)
  given Zero[Float] = Zero.mk(0f)
  given Zero[Double] = Zero.mk(0.0)
  given Zero[Boolean] = Zero.mk(false)
  given Zero[Unit] = Zero.mk((): Unit)
  given Zero[String] = Zero.mk("")

class LowPriorityZero:
  given [A]: Zero[A] = Zero.mk(null.asInstanceOf[A])
```

This will have a given instance for all types. There's a convenient way to defer the summon invocation called `summonInline[A]`.

```scala
/**
 * Constructs a new, synthetic, local var with type `tpe`, a unique name, initialized to
 * zero-equivalent (Zero[A]), and owned by `parent`.
 */
def freshValDef(parent: Symbol, tpe: TypeRepr): ValDef =
  tpe.asType match
    case '[a] =>
      val sym =
        Symbol.newVal(
          parent,
          freshName("q"),
          tpe,
          Flags.Mutable | Flags.Synthetic,
          Symbol.noSymbol
        )
      ValDef(sym, rhs = Option('{ summonInline[Zero[a]].zero }.asTerm))
```

This would codegen:

```scala
var q1: String = summon[Zero[String]].zero
```

### Summary

- `contImpl` macro implements both Applicative-do and Monadic-do. It does so by first scanning the abstract syntax tree for `key.value`. When there are none, it calls `pure(...)` and `map(...)` when there is exactly one.
- To pass the Instance instance `i` to macro and back to the generated code, it uses `Singleton` type `i.type`, which internally holds on to the symbol of `i`.
- Quotes API provides a convenient way to generating lambda expression, but it must know the exact type of the parameters. This means we can't gradually expand the definition of the lambda expression as we walk the tree. To workaround this, we will use `var` one scope outside of the lambda expression.
- We defined `Zero` typeclass and summon a value for it to initialize the `var`s.
