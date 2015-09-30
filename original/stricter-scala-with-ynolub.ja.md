  [1]: http://days2011.scala-lang.org/sites/days2011/files/41.%20Effective%20Scala.pdf
  [2]: http://rapture.io/talks/inference/boston.html
  [lubSource]: https://github.com/scala/scala/blob/v2.11.7/src/reflect/scala/reflect/internal/tpe/GlbLubs.scala#L299-L300

Scala は柔軟なプログラミング言語なので、個人的な Good Parts のような言語のサブセット、もしくは主義主張のあるスタイルガイドを作ることは有用だ。

### セットアップ

`-Yno-lub` を試してみたい人は、以下を `project/ynolub.sbt` に書いて sbt プラグインを引っ張ってくる:

<scala>
addSbtPlugin("com.eed3si9n" % "sbt-ynolub" % "0.2.0")
</scala>

### lub

Scala の型推論が型 `A` と型 `B` を統合するとき、それらの `<:<` に関する lub (least upper bounds, 最小上界) を計算する。この過程を lubbing と呼ぶこともある。具体例で説明する:

<scala>
scala> if (true) Some(1) else None
res0: Option[Int] = Some(1)

scala> if (true) List(1) else Nil
res1: List[Int] = List(1)
</scala>

ここ数年考えているのは、少なくとも今ある形での lubbing は有益ではないのではないか、ということだ。2013年にもこんなことを言っている:

<blockquote class="twitter-tweet" lang="en"><p lang="en" dir="ltr">are non-imported implicits and lubing useful in <a href="https://twitter.com/hashtag/scala?src=hash">#scala</a>? Map to List[Tuple2], Int to Double, Foo and Bar to Any. I&#39;d rather see errors</p>&mdash; eugene yokota (@eed3si9n) <a href="https://twitter.com/eed3si9n/status/405388934525775872">November 26, 2013</a></blockquote>
<script async src="//platform.twitter.com/widgets.js" charset="utf-8"></script>

> 非import の implicit や lubbing は #scala の役に立つものだろうか? Map から List[Tuple2]、Int から Double、 Foo と Bar から Any。むしろ僕はそれらがエラーになってほしい。

要因の一つは `<:<` が表すサブタイプ関係が Scala では様々なものをエンコードしていることにある。自動的に lubbing が行われるせいで、Scala は多様なものを式の中に統合してしまう。具体例で説明する:

<scala>
scala> if (true) Right(1) else Left("1")
res2: ....

scala> 1 match { case 1 => Array(1); case n => Vector(n) }
res3: ....

scala> if (true) 1 else false
res4: ....

scala> 1 match { case 1 => 2; case n => None }
res5: ....

scala> if (true) Vector(1) else Range(1, 1)
res6: ....
</scala>

ユニバーサルな top 型である `Any` のせいで、Scala はどの 2つの型をとってもを統合する。

ちなみに、上の戻り値の型を当てることができるだろうか?

<scala>
scala> if (true) Right(1) else Left("1")
res2: Product with Serializable with scala.util.Either[String,Int] = Right(1)

scala> 1 match { case 1 => Array(1); case n => Vector(n) }
res3: java.io.Serializable = Array(1)

scala> if (true) 1 else false
res4: AnyVal = 1

scala> 1 match { case 1 => 2; case n => None }
res5: Any = 2

scala> if (true) Vector(1) else Range(1, 1)
res6: scala.collection.immutable.IndexedSeq[Int] with scala.collection.AbstractSeq[Int] with Serializable with scala.collection.CustomParallelizable[Int,scala.collection.parallel.immutable.ParSeq[Int] with Serializable{def seq: scala.collection.immutable.IndexedSeq[Int] with scala.collection.AbstractSeq[Int] with Serializable with scala.collection.CustomParallelizable[Int,scala.collection.parallel.immutable.ParSeq[Int] with Serializable]{def dropRight(n: Int): scala.collection.immutable.IndexedSeq[Int] with scala.collection.AbstractSeq[Int] with Serializable; def takeRight(n: Int): scala.collection.immutable.IndexedSeq[Int] with scala.collection.AbstractSeq[Int] with Serializable; def drop(n: Int): scala.collection.immutable.IndexedSeq[Int] with scala.collection.AbstractSeq[Int] with Se...
</scala>

上の例だけを見ても、lubbing が何を行っているのかを推論するのは難しく、意外な結果となることが多いのが分かる。

lubbing が問題であることの証拠の一つとして、メソッドの戻り値や implicit 値の型注釈を明記するべきという「ベストプラクティス」が広まっていることが挙げられる。僕が最初にこれを聞いたのは Dick と Bill の Scala Days 2011 での[セッション][1]だったと思う。良い助言であるけども、多くのパターンやベスト・プラクティスがそうであるように、これは言語の問題の回避策ではないだろうか? つまり、僕達は型推論が何をしでかすか一切分からないため、メソッドごとにチェックを入れているわけだ。

何かが自動的に実行されるとき、その結果は安全かつ予測可能であるべきだ。上の例が示唆するもう一つのことは、型 `A` と型 `B` を統合することはどの型が比較可能であるかという個人のセンスがからんでくることだ。

上から順に見ていこう。`Right(1)` と `Left("1")`。これらは比較可能だろうか? 何らかの形で代数的データ型をサポートするべきというが、僕の意見だ。それがどのようにエンコードさるべきかは、僕にはまだハッキリしていない。現状の戻り型である `Product with Serializable with scala.util.Either[String,Int]` が望ましくないというのは確かだろう。

次は、`Array(1)` と `Vector(n)`。個人的には、2つの異なるデータ型は別物として考えるので、自動的に統合されるべきではないと思う。両者に共通の trait や型クラスなどがあるかもしれないが、だからといって if式、パターンマッチング、for 内包表記でそれが統合されてほしいわけではない。

続いては、`1` と `false`。これも、同様に同じ式の中で比較されるべきではないと思う。ここで注意してほしいのは、僕は `Seq` trait や `AnyVal` trait の存在に反対しているわけではないことだ。僕が反対しているのは、`1` と `false` が `AnyVal` に lubbing されることだ。

`2` と `None` の例は、`2` を `Some(...)` に包み忘れた状況を再現している。lubbing が静的型付けを無効化してしまっているのが分かる例だ。

最後の例は Jon Pretty さんの [Demystifying Type Inference][2] から借用した。

### lub が出てくるところ

これまで if 式とパターンマッチングの例をみてきたけども、lubbing は他の所にも出現する。Jon のトークで例に出てきているのは `List` のようなデータ型の構築が lubbing を行うことだ。

<scala>
scala> List(Array(1), Vector(2))
res7: List[java.io.Serializable] = List(Array(1), Vector(2))

scala> List(1, false)
res8: List[AnyVal] = List(1, false)

scala> List(1, None)
res9: List[Any] = List(1, None)
</scala>

別の見方をすると、これは `List.apply[A](1, None)` を呼び出していて、コンパイラは `A` が何であるかを推論していると考えることができる。これを簡単な関数で表すとこうなる:

<scala>
scala> def first[A](a1: A, a2: A): A = a1
first: [A](a1: A, a2: A)A

scala> first(Array(1), Vector(2))
res10: java.io.Serializable = Array(1)

scala> first(1, false)
res11: AnyVal = 1
</scala>

数値の拡大変換というトピックもある:

<scala>
scala> List(1, 1L)
res12: List[Long] = List(1, 1)

scala> 1 :: List(1L)
res13: List[AnyVal] = List(1, 1)
</scala>

### やることを減らす

TypeScript は少しかじった程度だけども、ラッパーの体感的な薄さが心地良かったのが印象的だった。静的型付けや型推論も提供するんだけども、だいたいどのような JavaScript を出力するのかを推測することができる。コンパイルできないものもあるが、そのときはコンパイラを手助けできるようになっている。

例えば、`Number` と `Boolean` の統合を防ぐようになっている:

    var x = function() {
      if (true) return 1
      else return false
    }

以下のエラーが発生する:

    No best common type exists among return expressions.

どうしてもやりたければ、手動で `any` にキャストする必要がある。これが僕の好みだ:

    var x = function() {
      if (true) return <any>1
      else return <any>false
    }

Scala コンパイラに `-Yno-lub` という、lubbing を止めるフラグがあればいいのではというアイディアを考えていた。カンファレンスの後の懇親会とか、バスの移動中に Scala チームの隣に座ることができるとこのネタを話していた。最近、Seth と話したときにトークやブログなどの草の根から始めてみたらどうかと助言を受けた。

Scala World 2015 が近づいていたので、日曜のアンカンファレンスで発表したら面白いのではと思って用意した。試してみたい人は、このページ冒頭の手順をみてほしい。この sbt プラグインを使うと、ビルドで使われるコンパイラを海賊版の 2.11 Scala コンパイラと差し替えて `-Yno-lub` を有効にする。

### -Yno-lub

とりあえずアイディアを形にしただけのプロトタイプを作るのはあっけないぐらい簡単だった。`lub` で grep をかけると正に[その名前][lubSource]の関数が見つかったからだ:

<scala>
    /** The least upper bound wrt <:< of a list of types */
    protected[internal] def lub(ts: List[Type], depth: Depth): Type = ....
</scala>

ここに数行書き加える。これだけで大丈夫 (＜別のフラグが立ってる)。

<scala>
    val res =
      if (noLub) checkSameTypes(ts)
      else lub0(ts)
</scala>

lubbing のロジックの大半を飛ばすことができるため、`-Yno-lub` の副次的な利点としてコンパイル時間の低下があるかもしれない。

これだけでも上で見た例は取り扱えるようになった。結果は以下のようになる:

<scala>
scala> if (true) Right(1) else Left("1")
<console>:12: error: same types expected: scala.util.Right[Nothing,Int] and scala.util.Left[String,Nothing]
       if (true) Right(1) else Left("1")
       ^

scala> if (true) (Right(1): Either[String, Int]) else (Left("1"): Either[String, Int])
res1: Either[String,Int] = Right(1)

scala> 1 match { case 1 => Array(1); case n => Vector(n) }
<console>:12: error: same types expected: Array[Int] and scala.collection.immutable.Vector[Int]
       1 match { case 1 => Array(1); case n => Vector(n) }
         ^

scala> if (true) 1 else false
<console>:12: error: same types expected: Int and Boolean
       if (true) 1 else false
       ^

scala> 1 match { case 1 => 2; case n => None }
<console>:12: error: same types expected: Int and None.type
       1 match { case 1 => 2; case n => None }
         ^
</scala>

見ての通り、`Right(1)` と `Left("1")` の例は型注釈を必要とするようになった。`None` と `Nil` も同様だ:

<scala>
scala> if (true) Some(1) else None
<console>:12: error: same types expected: Some[Int] and None.type
       if (true) Some(1) else None
       ^

scala> if (true) List(1) else Nil
<console>:12: error: same types expected: List[Int] and scala.collection.immutable.Nil.type
       if (true) List(1) else Nil
       ^
</scala>

これは代数的データ型のエンコード問題に似ている。全ての `Nil` に型注釈を付けるのは面倒だけど、個人的には許容範囲だと思う。

### 「リアルワールド」問題と回避策

以下は、実際に `-Yno-lub` を使おうとして遭遇した問題をいくつか。

#### `Nothing` 型との統合

当然の事と思って考えて忘れていたのは `Nothing` 型との統合だ。例えば:

<scala>
scala> if (true) 1 else sys.error("boom")
</scala>

これは `Int` と `Nothing` 型の統合だ。厳密には、これは禁止するべきだけども、例外を投げるのはプログラマ側が意識的に選ぶ行為なのので妥協することにした。

#### 存在型の統合

他にも回避する必要があったのはこれだ:

<scala>
scala> def something(clazz: Class[_]): List[Class[_]] = {
         if (true) List(clazz)
         else clazz :: something(clazz.getSuperclass)
       }
<console>:13: error: same types expected: Class[_] and Class[_$1]
         else clazz :: something(clazz.getSuperclass)
                    ^
</scala>

1番目の2番目の `Class[_]` が同じ型だとみなされていないが、意味論的には同じ項をカバーしてるはずだ。これを修正するためには、`TypeComparers` に以下のケースを追加する必要があった:

<scala>
  // @pre: at least one argument contains existentials
  private def sameExistentialTypes(tp1: Type, tp2: Type): Boolean = (
    try {
      skolemizationLevel += 1
      (tp1.skolemizeExistential.normalize, tp2.skolemizeExistential.normalize) match {
        case (sk1: TypeRef, sk2: TypeRef) =>
          equalSymsAndPrefixes(sk1.sym, sk1.pre, sk2.sym, sk2.pre) &&
            (isSameHKTypes(sk1, sk2) ||
              ((sk1.args corresponds sk2.args) (isComparableSkolemType)))
        case _ => false
      }
    } finally {
      skolemizationLevel -= 1
    }
  )
  // this comparison intentionally ignores the name of the symbol.
  private def isComparableSkolemType(tp1: Type, tp2: Type): Boolean =
    (tp1, tp2) match {
      case (sk1: TypeRef, sk2: TypeRef) =>
        sk1.sym.info =:= sk2.sym.info &&
          sk1.pre =:= sk2.pre
      case _ => false
    }

....

  private def isSameType1(tp1: Type, tp2: Type): Boolean = typeRelationPreCheck(tp1, tp2) match {
    case state if state.isKnown                                  => state.booleanValue
    case _ if typeHasAnnotations(tp1) || typeHasAnnotations(tp2) => sameAnnotatedTypes(tp1, tp2)
    case _ if containsExistential(tp1) || containsExistential(tp2) => sameExistentialTypes(tp1, tp2)
    case _                                                       => isSameType2(tp1, tp2)
  }
</scala>

見ての通り、段々と深みにはまってきている。

#### case class によるコード生成

意外な例としてこういうのもある:

<scala>
scala> case class Movie(name: String, year: Int)
<console>:11: error: same types expected: None.type and Some[(String, Int)]
       case class Movie(name: String, year: Int)
                  ^
</scala>

何が起こっているのかを調べるために便利なのは `-Xprint:typer` というコンパイラのフラグだ:

<scala>
    case <synthetic> def unapply(x$0: Movie): Option[(String, Int)] = if (x$0.==(null))
      scala.this.None
    else
      Some.apply[(String, Int)](scala.Tuple2.apply[String, Int](x$0.name, x$0.year));
</scala>

`unapply` で生成されるコードに型注釈を付ける必要がある。`productElement` も同様で、これは手動で `Any` に広げる必要がある:

<scala>
    <synthetic> def productElement(x$1: Int): Any = x$1 match {
      case 0 => Movie.this.name
      case 1 => Movie.this.year
      case _ => throw new IndexOutOfBoundsException(x$1.toString())
    };
</scala>

一応これも対策したけども、厳密さを新規に導入することで様々なコード生成が引っかかるという前途多難を予測させる。

#### if 節によるコード生成

これも別のコード生成:

<scala>
scala> if (true) "1"
<console>:12: error: same types expected: String and Unit
       if (true) "1"
       ^
</scala>

これは自分で対策できるので、特にコンパイラ側では対策しなかった:

<scala>
scala> if (true) { "1"; () }
</scala>

他にも問題は残っているかもしれないが、これで以前よりは使えるようになった。

### 代数的データのエンコード

代数的データのエンコードは課題として残っているままだ。

#### 関数でラッピングする

ユーザランド側での回避策は末端の値を親 trait に型注釈したラッパー関数を作ることだ。

<scala>
scala> def nil[A]: List[A] = (Nil: List[A])
nil: [A]=> List[A]

scala> if (true) List(1) else nil[Int]
res14: List[Int] = List(1)
</scala>

この方法の利点は `List[A]` に `Eq` などの型クラスが使えるなど、他の利点もある。

#### 直和型

Scala に第一級のサポートを追加できるとしたら、どのようになるだろうか?
一つの方法は `Either[A1, A2]` を `Left[A1]` と `Right[A2]` の直和型だと扱うようにすることだ。

<scala>
package object collection {
  type Either[A1, A2] = Left[A1] | Right[A2]
}
</scala>

`Either[A1, A2]` に実装を書きたいので、この方法はうまくいくか分からない。

#### 型制限

直和型の一部であることを表記する構文を考えてみる:

<scala>
sealed trait Either[A1, A2] {
  def a1: A1
  def a2: A2
  def leftOption: Option[A1] =
    this match {
      case Left(a1) => (Some(a1): Option[A1])
      case Right(_) => (None: Option[A1])
    }
  def rightOption: Option[A2] =
    this match {
      case Left(_)   => (None: Option[A1])
      case Right(a2) => (Some(a2): Option[A2])
    }
  def isLeft: Boolean =
    this match {
      case Left(_)  => true
      case Right(_) => false
    }
  def isRight: Boolean = !isLeft
  def map[B](f: A2 => B): Either[A1, B] =
    this match {
      case Left(a1)  => Left(a1)
      case Right(a2) => Right(f(a2))
    }
}
final case class Left[A1](a1: A1) restricts Either[A1, Nothing]
final case class Right[A2](a2: A2) restricts Either[Nothing, A2]
</scala>

この空想の型制限は特別なサブタイプで、コンストラクタで捕獲されるもの以外のフィールドを禁止する。これによって `Either[A1, A2]` を推論するのは許されるとコンパイラに伝えることができる。制限型での実装を禁止することで、`Vector` が `Seq` が拡張するのと、普通の代数的データ型の区別に使えたらいいと思っている。

### まとめ

Scala は多様なものをサブタイプでエンコードするため、型 `A` と型 `B` の lub を計算するという方法での型推論の結果は、予測不可能で、役に立たないことが多い。任意の 2つの型があるとき、どれを比較可能とすべきかの境界線は主観的なものだ。`-Yno-lub` は実験的なフラグで、2つの型が同一であることを要請する型推論を弱くした Scala を体験することができる。このフラグの存在を知らないコード生成や、代数的データのエンコードなどが課題として残っている。
