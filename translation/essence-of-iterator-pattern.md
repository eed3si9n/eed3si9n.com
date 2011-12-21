> これは [Scala Advent Calendar 2011](http://partake.in/events/33870915-f25b-40b6-9456-b898b898d48b) の 17日目の記事です。
> [specs2](http://etorreborre.github.com/specs2/) の作者であり、[@etorreborre](https://twitter.com/#!/etorreborre) としても活発に発言を続けるシドニーの強豪 Eric Torreborre さんが書いた ["The Essence of the Iterator Pattern"](http://etorreborre.blogspot.com/2011/06/essence-of-iterator-pattern.html) を翻訳しました。翻訳の公開は本人より許諾済みです。翻訳の間違い等があれば遠慮なくご指摘ください。

2011年6月24日 Eric Torreborre 著
2011年12月17日 e.e d3si9n 訳

去年読んだ論文で一番気に入ったのは ["The Essence of the Iterator Pattern"](http://www.cs.ox.ac.uk/jeremy.gibbons/publications/iterator.pdf)（以下、EIP）だ。これを読んだ後で、今まで何年も使い続けてきたあるものに対する考えがガラリと変わった。それは、`for` ループだ。

この論文の中からいくつかのアイディアを紹介して、書かれている解法の実装方法を [Scalaz](http://github.com/scalaz/scalaz) っぽいコードを使って説明する。以前に関数型プログラミング、ファンクタ、モナドなどに少しでも触れたことがあれば、役立つと思う!

## for ループの中身は何だ?

これが、本当に僕がハマったキッカケだ。「`for` ループの中身は何だ」とはどういう意味だ? 僕が何年も使ってきたこの構文に、何か魔法は入っていないだろうか?

EIP の導入部に、（C のような添字を使った `for` ではなく）各要素を一つづつ順に返すタイプの `for` ループの例がでてくる。ここでは、Scala に[変身][1]させて書くけど、考え方は一緒だ:

<scala>
val basket: Basket[Fruit] = Basket(orange, apple)
var count = 0

val juices = Basket[Juice]()
for (fruit <- basket) {
  count = count + 1
  juices.add(fruit.press)
}
</scala>

まず、フルーツの「コンテナ」である `Basket` から始める。これは、`List`、`Tree`、`Map` など別に何でもいい。`for` ループは、次に以下の 3つのことを実行する:

1. **同じ「形」**をしたコンテナを返す（ジュースも `Basket` であるため）。
2. 何らかの計測値を**累積** (accumlate) を行う。ここでは、`count` 変数にフルーツの数が累積されている。
3. 要素を別の要素に**投射する** (map)。ここでは、フルーツを潰して果汁を得ている。

この `for` ループは最も複雑なものというわけでもない:

- `count` 変数が要素の投射に影響を及ぼすこともできる: `juices.add(fruit.press(harder=count))`
- お互いに依存し合った複数の変数を宣言することもできる: `cumulative = cumulative + count`
- 投射が「計測値」変数に影響をあたえることもできる: `liquid = liquid + fruit.press.quantity`

EIP の目的は、上記の `for` ループで起こっている事の「本質」は、**Applicative な走査** (traversal) に抽象化できることを示すことだ。さらに著者らは、この Applicative 抽象化を使うことで、プログラミングにおける驚くべきモジュール性を得られることも証明する。

## Applicative 型クラス

**Applicative な走査**が、`for` ループよりもどう優れているのだろう? そもそも、それはどういう意味なんだろう?? EIP には、関数型プログラムや Haskell の素養が無いと理解しづらい文や式がいっぱいでてくる。これらを、ゆっくり紐解いていこうと思う。何はともあれ、形式的な定義からみていく。

### Functor って何?

まず、`Functor` 型クラスの話から始めなくてはいけない:

<scala>
trait Functor[F[_]] {
  def fmap[A, B](f: A => B): F[A] => F[B]
}
</scala>

`Functor` を解釈する一つの方法は、（一つ、または複数の）型 `A` の値の計算だと考えることだ。例えば、`List[A]` は、型 `A` のいくつかの値を返す計算だし（非決定的 (non-deterministic) な計算だ）、`Option[A]` は、あるかないか分からない計算だし、`Future[A]` は、後で与えられる型 `A` の値の計算、などなど。もう一つの考え方は、型 `A` の値の「コンテナ」の一種だと考えることだ。

これらの計算が `Functor` だと言ったとき、これらを普通の関数と組み合わせて便利に使うことができると考えていい。計算される値に関数を適用(apply) することができるからだ。値 `F[A]` と関数 `f` があるとき、`fmap` を用いて関数を値に適用することができる。例えば、`fmap` は `List` や `Option` では普通の `map` だ。

### Pointed Functor

さて、型が `F[A]` の値を**作る**には、どうすればいいだろう? 一つの方法として、`F[_]` が `Pointed` であると宣言することだ:

<scala>
trait Pointed[F[_]] {
  def point[A](a: => A): F[A]
}
</scala>

別の言い方をすると、型 `A` の値を受け取り `F[A]` を戻り値として返す `point` 関数が定義されているということだ。例えば、普通の `List` はリストのコンストラクタを使うことで `Pointed` になる:

<scala>
object PointedList extends Pointed[List] {
  def point[A](a: => A) = List(a)
}
</scala>

この `Pointed` と `Functor` という 2つの能力を組み合わせると、`PointedFunctor` となる:

<scala>
trait PointedFunctor[F[_]] {
  val functor: Functor[F]
  val pointed: Pointed[F]

  def point[A](a: => A): F[A] = pointed.point(a)

  def fmap[A, B](f: A => B): F[A] => F[B] = functor.fmap(f)
}
</scala>

`PointedFunctor` trait は、`Pointed` と `Functor` の集約にすぎない。

じゃあ、`Applicative` って何? もうちょっとなんだけど、あと最後に残ってるのが `Applic` だ。

### Applic

`Applic` は、「コンテナ」と関数を組み合わせるもう一つの方法だ。

`fmap` を使って関数を計算値に適用するかわりに、関数そのものも**コンテナ `F` の中にある**計算値だと仮定して (`F[A => B]`)、その関数を `F[A]` の値に適用する `applic` というメソッドを提供する:

<scala>
trait Applic[F[_]] {
  def applic[A, B](f: F[A => B]): F[A] => F[B]
}
</scala>

具体例で考えてみよう。市場が開いているときに `Fruit` の値段を計算する方法があると仮定する:

<scala>
def pricer(market: Market): Option[Fruit => Double]
</scala>

市場が閉じている時は、値段が分からないから `pricer` は `None` を返す。それ以外の場合は、値段付けする関数を返す。ここで、`Fruit` を返すかもしれない `grow` 関数があるとする:

<scala>
def grow: Option[Fruit]
</scala>

これで、`Applic` のインスタンスを使って `Fruit` を値付けできる:

<scala>
val price: Option[Double] = applic(pricer(market)).apply(grow)
</scala>

`price` は、`pricer` か `Fruit` が欠けている場合があるため、必然的に `Option` となる。ちょっと名前を変えたり、メソッドを[モンキーパッチ][2]することで、なぜ "Applicative" (適用可能) という用語が使われるのかが明らかになる:

<scala>
val pricingFunction = pricer(market)
val fruit = grow

val price: Option[Double] = pricingFunction ⊛ fruit
</scala>

見方によっては、これは普通の関数の適用を行なっているだけなんだけど、`Applicative` コンテナの中で実行されていると見ることができる。これで、EIP で議論されている `Applicative` Functor を作る部品がそろった。

### Applicative functor

`Applicative` functor は `Applic` と `PointedFunctor` の集約だ:

<scala>
trait Applicative[F[_]] {
  val pointedFunctor: PointedFunctor[F]
  val applic: Applic[F]

  def functor: Functor[F] = new Functor[F] { 
    def fmap[A, B](f: A => B) = pointedFunctor fmap f 
  }
  def pointed: Pointed[F] = new Pointed[F] { 
    def point[A](a: => A) = pointedFunctor point a 
  }

  def fmap[A, B](f: A => B): F[A] => F[B]     = functor.fmap(f)
  def point[A](a: => A): F[A]                 = pointed.point(a)
  def apply[A, B](f: F[A => B]): F[A] => F[B] = applic.applic(f)
}
</scala>

これを `List` を使って実装できるかみてみよう。`fmap` と `point` は簡単だ:

<scala>
def fmap[A, B](f: A => B): F[A] => F[B] = (l: List[A]) => l map f
def point[A](a: => A): F[A]             = List(a)
</scala>

`apply` は 2通りの（両方とも有用な）方法で実装できるため、もう少し面白い:

<ol>
<li>関数のリストを全ての要素に適用してその結果を `List` に集める:
<scala>
def apply[A, B](f: F[A => B]): F[A] => F[B] = (l: List[A]) =>
  for { a <- l; func <- f } yield func(a)
</scala></li>
<li>関数のリストと要素のリストを `zip` して、それぞれの関数をそれぞれの要素に適用する:
<scala>
def apply[A, B](f: F[A => B]): F[A] => F[B] = (l: List[A]) =>
  (l zip f) map (p => p._2 apply p._1)
</scala></li>
</ol>

`List` が `Monoid` であることを利用して、`List` を `Applicative` として使う 3つ目の方法まで実はある。だけど、それに関してはまた後ほど。これらが `for` ループとどう関わってくるのかをまずみていこう。

## データ構造の走査

僕らが `for` ループを実行するとき、何らかの要素が入っている「データ構造」(structure) に対して「走査」(traverse) して以下を返す:

- 別の要素が入った同じデータ構造
- データ構造内の要素を使って計算された値
- 以上を色々組み合わせたもの


Gibbons と Oliveira の主張は、**どんな種類の `for` ループでも**以下の `traverse` 演算を使って表すことができるというものだ:

<scala>
trait Traversable[T[_]] {
  def traverse[F[_] : Applicative, A, B](f: A => F[B]): T[A] => F[T[B]]
}
</scala>

つまり、型 `T` のコンテナ（データ構造）に `Applicative F` を用いた `traverse` 関数があるとき、`for` ループを使ってできることなら何でもできるということだ。

`traverse` 関数への理解を深めるために、二分木のための `Traversable` trait を実装してみて、木を実際にループできるか試してみよう。

### 二分木

ここからは、とてもシンプルな二分木を例にこの問題を考えていく:

<scala>
sealed trait BinaryTree[A]
case class Leaf[A](a: A) extends BinaryTree[A]
case class Bin[A](left: BinaryTree[A], right: BinaryTree[A]) extends BinaryTree[A]
</scala>

一方、`Traversable` の実装の第一弾はとても読めたものじゃない!

<scala>
 def BinaryTreeIsTraversable[A]: Traversable[BinaryTree] = new Traversable[BinaryTree] {

   def createLeaf[B] = (n: B) => (Leaf(n): (BinaryTree[B]))
   def createBin[B]  = (nl: BinaryTree[B]) => 
     (nr: BinaryTree[B]) => (Bin(nl, nr): BinaryTree[B])

   def traverse[F[_] : Applicative, A, B](f: A => F[B]): 
     BinaryTree[A] => F[BinaryTree[B]] = (t: BinaryTree[A]) => {
     val applicative = implicitly[Applicative[F]]
     t match {
       case Leaf(a)   => applicative.apply(applicative.point(createLeaf[B]))(f(a))
       case Bin(l, r) =>
         applicative.apply(applicative.apply(applicative.point(createBin[B]))(traverse[F, A, B](f).apply(l))).
         apply(traverse[F, A, B](f).apply(r))
     }
   }
 }
</scala>

これに対応する Haskell はこんなに簡潔なので残念だ:

<scala>
  instance Traversable Tree where
  traverse f (Leaf x)  = pure Leaf ⊛ f x
  traverse f (Bin t u) = pure Bin  ⊛ traverse f t ⊛ traverse f u
</scala>

多少の[モンキーパッチ][2]を入れて、この状況を改善しよう:

<scala>
def traverse[F[_] : Applicative, A, B](f: A => F[B]): BinaryTree[A] => F[BinaryTree[B]] = (t: BinaryTree[A]) => {
  t match {
    case Leaf(a)   => createLeaf[B] ∘ f(a)
    case Bin(l, r) => createBin[B]  ∘ (l traverse f) <*> (r traverse f)
  }
}
</scala>

くだけた説明をすると、`traverse` メソッドは、関数 `f` を各ノードに適用して、`Applicative` functor の `apply` メソッド (`<*>`) を使って木を「再構築」する。

と言っても古代ギリシア語で言ってるのと同じぐらい分かりやすいと思うから（僕も最初はよく分からなかった）、`traverse` メソッドの使い方をみてみよう。だけど、その前にちょっと寄り道 :-)

### Applicative Monoid

`BinaryTree` を走査するときに、やっておくと便利かもしれないのは木の内容を `List` にしてしまうことだ。そのためには、さっきちょっと話した `List` を `Applicative` として使う 3つめの方法を使う。実は、全ての `Monoid` は `Applicative` のインスタンスと成りうるけど、ちょっと変わったやり方になっている。

<scala>
  /** Const は、型 B の「phantom」を持った型 A の値のコンテナだ。 */
 case class Const[A, +B](value: A)

 implicit def ConstIsPointed[M : Monoid] = new Pointed[({type l[A]=Const[M, A]})#l] {
   def point[A](a: => A) = Const[M, A](implicitly[Monoid[M]].z)
 }

 implicit def ConstIsFunctor[M : Monoid] = new Functor[({type l[A]=Const[M, A]})#l] {
   def fmap[A, B](f: A => B) = (c: Const[M, A]) => Const[M, B](c.value)
 }

 implicit def ConstIsApplic[M : Monoid] = new Applic[({type l[A]=Const[M, A]})#l] {
   def applic[A, B](f: Const[M, A => B]) = (c: Const[M, A]) => Const[M, B](implicitly[Monoid[M]].append(f.value, c.value))
 }

 implicit def ConstIsPointedFunctor[M : Monoid] = new PointedFunctor[({type l[A]=Const[M, A]})#l] {
   val functor = Functor.ConstIsFunctor
   val pointed = Pointed.ConstIsPointed
 }

 implicit def ConstIsApplicative[M : Monoid] = new Applicative[({type l[A]=Const[M, A]})#l] {
   val pointedFunctor = PointedFunctor.ConstIsPointedFunctor
   val applic = Applic.ConstIsApplic
 }
</scala> 

上記のコードで `Const` は、与えられた `Monoid` に対する `Applicative` インスタンスだ。`Const` は、型 `T` の値を格納するコンテナで、`T` は `Monoid` だ。そこから `Const` が `Applicative` であることを満たす条件を順番に示している。

- まずは、`Pointed` である必要がある。くだけた説明をすると、`point` メソッドは `Monoid` の何の変化ももたらさない要素を `Const` インスタンスに入れる。
- 次に、`Functor` である必要がある。ここでは、`fmap` 関数は `Const` の型を `Const[M, A]` から `Const[M, B]` に変える以外は何もしない。
- 最後に、`Applic` の `apply` メソッドが `Monoid` の `append` メソッドを利用して 2つの値を「加算」して、その結果を `Const` のインスタンスとして返すような `Applic` である必要がある。

残念ながら、ここでは多くの黒魔術的な型付けが行われている:

- `Const` の型宣言は `Const[A, +B]` だ。`Const` クラスの値に表れない型パラメータ `B` がある! これは phantom type と呼ばれるものだが、型クラスの型宣言に合わせるためには無くてはならないものだ。
- `Applicative` だとされる型 `F` は... `({type l[A] = Const[T, A]})#l` だ。痛っ。これには、ちょっと説明がいる!

何を必要としてるかを考えると、特に難しいことはしていない。`Const[A, B]` には 2つの型パラメータがある。必要とされているのは、`A` を `T` に**固定**して、戻り値の型を一つの型パラメータに減らすことだ。上の式はこの型を得る最も簡潔な方法だ:

- `{ type l = SomeType }` は型メンバー `l` を持つ匿名型だ。Scala では、`#` を用いてこの型 `l` にアクセスできる: `{ type l = SomeType }#l`
- 次に、`{ type l[A] = SomeType[T, A] }#l` において、`l` は、型変数 `A` を持つ**高カインド型** (higher-kinded type) だ (その実は、`T` が固定された `SomeType[T, A]`)。

> 訳注: カインド (kind) とは、「型を記述する型」の体系のことだ。型システムを考察するには、値 (value)、型 (type)、カインド (kind) と 3つのレベルで言語の式を分けて考える必要がある。
> 具体例で説明すると、`1` という値が `Int` という型に分類されるのと同様に、`Int` などのそのまま使える型はプロパー (proper) な型であると言われ、`*` というカインドに分類され「型」と読まれる。さらに、`List` のような一項の型コンストラクタは、1階カインド (first-order kind) であり、`* => *` に分類される。`Map` のような二項の型コンストラクタも 1階カインドで、これは `* => * => *` に分類される。
> `Functor[F[_]]` での `Functor` のように、型コンストラクタを受け取る型コンストラクタは `(* => *) => *` に分類され、これは高階カインド (higher-order kind) の例だ。
>「高階型」(higher-order type) は抽象化/多相化が複数回行われていることを示す、より広い概念なので higher-kinded type の訳としては不適切だ。例えば、`forall` を用いた高ランク型 (higher-ranked type) も高階型の一種だけど、多相性の話で、カインドは全て `*` だ。
> では、高カインド型 (higher-kinded type) は何かと言うと、高階カインドにカインド付けされた型、つまり型コンストラクタを指す。ここで注意しなければいけないのは、`List` や `Functor` のような型コンストラクタも飽くまで型であることだ。
> これを、値に当てはめてみると分かり易い。値 1 から 2 を構築する「値コンストラクタ」`x => x + 1` を考える。一般的に、これは「関数」と呼ばれるが、1階値 (first-order value) と考えることもできる。高階値は高階関数のことだ。ここで注目して欲しいのは、`x => x + 1` という値コンストラクタもただの値であって、型ではないということだ。同様に、型コンストラクタもやっぱりただの型であって、カインドではない。
> kind の訳語として、「種」と訳された事が多いけど、これは、ぱっと見て意味不明だし、型付け (typing) に対応する kinding が「種付け」になったりして変なので、訳すならばカインドと訳すのが現代的だと思う。
> ただし、Scala に関しては、敢えてカインドいう用語を持ち出さずに、「型コンストラクタ」とか「型コンストラクタパラメータ」で通じるんじゃないかと、変な用語を使って後悔していると[高カインド型を Scala に導入した][13] Adriaan Moors 氏本人が[言っている][12]ので、気にしなくてもいいと思う。

ただの `for` ループのために、かなり寄り道したよね? ここから、やっと... 丸儲けだ!

#### BinaryTree の内容...

ここでは、`BinaryTree` の `Traversable` インスタンスと `List Monoid Applicative` を使って `BinaryTree` の内容を読み込んでみる:

<scala>
import Applicative._

val f    = (i: Int) => List(i)
val tree = Bin(Leaf(1), Leaf(2))

(tree.traverse[...](f)).value must_== List(1, 2)
</scala>

単純だ。木を走査しながら各要素を `List` に格納して、`List Monoid` の魔法を使って全ての戻り値を集約していく。ただ一つ難しい所は、Scala の型推論の限界によるものだ。上の例の `...` は、コンパイラが必要とする型の注釈 (type annotation、訳注: 明示的に型を宣言してあげること) を表す:

<scala>
tree.traverse[Int, ({type l[A]=Const[List[Int], A]})#l](f)
</scala>

これはキレイじゃない :-(

Ittay Dror にコメントで指摘されたように、`List[Int]` はそのままでは Applicative じゃなくて、`traverse` 関数で使うためには、このリストを `Const` の値に入れる必要がある。

これは、`Applicative` オブジェクトにより提供される暗黙の変換 (implicit conversion) メソッドである `liftConst` によって実現されている:

<scala>
implicit def liftConst[A, B, M : Monoid](f: A => M): A => Const[M, B] = 
  (a: A) => Const[M, B](f(a))
</scala>

#### 丸儲けタイム

全てが失われたわけではない! この場合は、複雑さをカプセル化してやればいい。上のコードの一部を抜き出して、**全ての** `Traversable` インスタンスに対して動作する `contents` メソッドを作ることができる (以下の例では、`method(tree)` の代わりに `tree.method` と書けるようにモンキーパッチを当てていることを前提とする):

<scala>
val tree: BinaryTree[Int] = Bin(Leaf(1), Leaf(2))
tree.contents must_== List(1, 2)
</scala>

これは、以下の定義に基づいている:

<scala>
def contents[A]: T[A] => List[A] = {
  val f = (a: A) => Const[List[A], Any](List(a))
  (ta: T[A]) => traverse[({type l[U]=Const[List[A], U]})#l, A, Any](f).apply(ta).value
}
</scala>

実は、この `contents` 関数は、全ての `Monoid` に対して動作するより汎用的な `reduce` 関数の特殊形だ:

<scala>
def contents[A]: T[A] => List[A] = reduce((a: A) => List(a))

def reduce[A, M : Monoid](reducer: A => M): T[A] => M = {
  val f = (a: A) => Const[M, Any](reducer(a))
  (ta: T[A]) => traverse[({type l[A]=Const[M, A]})#l, A, Any](f).apply(ta).value
}
</scala>

この `reduce` 関数は、どの `Traverable` 構造でも各要素から `Monoid` の要素へと投射 (map) する 関数を用いて走査することができる。ここでは、木の内容を読み込むのに使ったけど、簡単に要素数を数えるのにも使うことができる:

<scala>
def count[A]: T[A] => Int = reduce((a: A) => 1)

tree.count must_== 2
</scala>

これよりシンプルにはなりえないよね :-)? 実は、この場合はなりえる! `(a: A)` を全く使っていないため、`reduceConst` を使うことができる:

<scala>
def reduceConst[A, M : Monoid](m: M): T[A] => M = reduce((a: A) => m)

def count[A]: T[A] => Int = reduceConst(1)
</scala>

これは、Scala 標準ライブラリの `reduce` をステロイド強化したようなものだ。二項演算の代わりに、`Monoid` のインスタンスを渡すだけでいいからだ。

### .... そして `BinaryTree` の形

木の要素に基づいて何らかの累積を行うという問題は解決できたから、次に「投射」(map) をみてみよう。

#### Monads も Applicatives だ!

以下の `map` メソッドを `traverse` メソッドから導き出すことができる (しかも、今回は型の注釈無しだ!):

<scala>
def map[A, B](mapper: A => B) = (ta: T[A]) => traverse((a: A) => Ident(mapper(a))).apply(ta).value
</scala>

ここでは、`Applicative` をとてもシンプルな `Ident` クラスを用いて走査している:

<scala>
case class Ident[A](value: A)
</scala>

`Ident` は、値を包むだけのシンプルなラッパーで、それ以上のものではない。こんなシンプルなクラスでも `Applicative` だ。だけど、どうやって?

簡単だ。`Ident` は実は `Monad` で、全ての `Modad` から `Applicative` のインスタンスを構築できるからだ。これは、`Monad` が、`PointedFunctor` であり、`Applic` である事実からくる:

<scala>
trait Monad[F[_]] {
  val pointed: Pointed[F]
  val bind: Bind[F]

  def functor: Functor[F] = new Functor[F] {
    def fmap[A, B](f: A => B): F[A] => F[B] = (fa: F[A]) => 
      bind.bind((a: A) => pointed.point(f(a))).apply(fa)
  }

  def pointedFunctor: PointedFunctor[F] = new PointedFunctor[F] {
    val functor = Monad.this.functor
    val pointed = Monad.this.pointed
  }

  def applic: Applic[F] = new Applic[F] {
    def applic[A, B](f: F[A => B]) = a => 
      bind.bind[A => B, B](ff => functor.fmap(ff)(a))(f)
  }

  def applicative: Applicative[F] = new Applicative[F] {
    val pointedFunctor = Monad.this.pointedFunctor
    val applic = Monad.this.applic
  }
}
</scala>

`Ident` が `Monad` であること (`pointed` と `bind` メンバーを持つ) を示すのは簡単だ:

<scala>
implicit def IdentIsMonad = new Monad[Ident] {

  val pointed = new Pointed[Ident] {
    def point[A](a: => A): Ident[A] = Ident(a)
  }
  val bind = new Bind[Ident] {
    def bind[A, B](f: A => Ident[B]): Ident[A] => Ident[B] = 
      (i: Ident[A]) => f(i.value)
  }
}
</scala>

新品の `map` 関数を使ってみよう:

<scala>
tree.map((i: Int) => i.toString) must_== Bin(Leaf("1"), Leaf("2"))
</scala>

これを使って、例えばコンテナの全ての要素を破棄して「形」だけを得ることさえできる:

<scala>
tree.shape must_== Bin(Leaf(()), Leaf(()))
</scala>

`shape` メソッドは、各要素を `()` に投射する。

### 分解 / 合成

まとめよう。ここまでで、データ構造を、関数を使って走査するとても汎用的な方法を実装した。データ構造は、`Traversable` であるかぎりは、**どんなデータ構造**でもよく、そこに格納される要素も**どんな種類の要素**でもいい。関数は、「適用」を実行することができるかぎり、**どんな種類の適用内容**でもいい。「適用内容」を 2つみた: 通常 `for` ループを用いて行われる演算に不可欠な累積と投射だ。

具体的には、木の内容 (`contents`) とその形 (`shape`) を得ることができた。これらの 2つの演算を合成して、内容と形の両方を得られる分解 (`decompose`) 演算にすることはできないだろうか? 最初の試みとしてはこんな感じになるかもしれない:

<scala>
def decompose[A] = (t: T[A]) => (shape(t), contents(t))

tree.decompose must_== (Bin(Leaf(()), Leaf(())), List(1, 2))
</scala>

これは、一応動作するけど、木の走査を 2回行なっているという点が未熟だ。一回で済ませる方法はないだろうか?

#### Applicative 積

これは、以下の事実に気づけば可能だ: **2つの `Applicative` の積はまた `Applicative` だ。**

証明、証明。`Product` (積) は以下のように定義する:

<scala>
case class Product[F1[_], F2[_], A](first: F1[A], second: F2[A]) {
  def tuple = (first, second)
}
</scala>

`Applicative` としての `Product` の完全な定義を書きだすと冗長なので、`Applic` のインスタンスに焦点を当てて考えてみよう:

<scala>
implicit def ProductIsApplic[F1[_] : Applic, F2[_] : Applic] =
  new Applic[({type l[A]=Product[F1, F2, A]})#l] {
    val f1 = implicitly[Applic[F1]]
    val f2 = implicitly[Applic[F2]]

    def applic[A, B](f: Product[F1, F2, A => B]) = (c: Product[F1, F2, A]) =>
      Product[F1, F2, B](f1.applic(f.first).apply(c.first), 
                         f2.applic(f.second).apply(c.second))
}
</scala>

使われている型さえ追っていけば、そこまで複雑ではない。ちょっと残念なのは、`decompose` の実装に必要な型解釈の量だ。理想的には以下のように書きたい:

<scala>
def decompose[A] = traverse((t: T[A]) => shape(t) ⊗ contents(t))
</scala>

ここで `⊗` は、2つの `Applicative` を受け取り、それらの積を返す。`Const` に対する型の部分適用ができないせいで、またしても全体的に分かりづらくなってしまっている ([SI-2712][3] に投票して下さい!):

<scala>
val shape   = (a: A) => Ident(())
val content = (a: A) => Const[List[A], Unit](List(a))

val product = (a: A) => (shape(a).⊗[({type l[T] = Const[List[A], T]})#l](content(a)))

implicit val productApplicative = 
  ProductIsApplicative[Ident, ({type l1[U] = Const[List[A], U]})#l1]

(ta: T[A]) => { val (Ident(s), Const(c)) = 
  traverse[({type l[V] = Product[Ident, ({type l1[U] = Const[List[A], U]})#l1, V]})#l, A, Unit](product).
   apply(ta).tuple
  (s, c)
}
</scala>

`productApplicative` の `implicit` の定義を `Applicative` のコンパニオンオブジェクトに移動することで、多少はコードが改善する:

<scala>
object Applicative {
  ...
  implicit def ProductWithListIsApplicative[A[_] : Applicative, B] = 
    ProductIsApplicative[A, ({type l1[U] = Const[List[B], U]})#l1]
}
</scala> 

これで、`Applicative` を `import` するだけで `implicit val productApplicative` が必要無くなる。

#### 収集と拡散

データ構造を走査しながら「並列して」何かを実行する方法が他にもある。これから作る `collect` メソッドは以下の 2つのことができる:

- 出会った要素に応じて、なんらかの状態 (state) を**累積**する。
- 各要素を他の種類の要素に**投射** (map) する。

つまり、走査しながら普通の投射をしたり、なんらかの計測値を計算したりできるということだ。だけど、その前にちょっと寄り道をして (え、また?? そうです、またです) `State` モナドをみてみよう。

##### State モナド

`State` Monad は以下のように定義される:

<scala>
trait State[S, +A] {
  def apply(s: S): (S, A)
}
</scala>

基本的には、以下のものから構成される:

- 型 `S` の、何らかの以前の「状態」(state) を格納するオブジェクト。
- この「状態」から、型 `A` の意味のある値を抽出するメソッド。
- このメソッドは、型 `S` の新しい「状態」を計算する。

例えば、`List[Int]` 内の要素を数える簡単なカウンターは以下のように実装できる:

<scala>
val count = state((n: Int) => (n+1, ()))
</scala>

これは、以前の「カウント」数 `n` を受け取り、新しい状態 `n+1` と抽出された値 (特に抽出すべきものが無いので、ここでは`()`) を返す。

上の `State` 型は、`Monad` だ。この話題に関してより理解を深めるには、["Learn You a Haskell"][4] を読むことをお勧めする。ここでは、`Monad` 型クラスの `flatMap` (別名 `bind`) メソッドが `State` を使う上で中心的なものだということを示すにとどめる:

<scala>
val count = (s: String) => state((n: Int) => (n+1, s + n))

(count("a-") flatMap count flatMap count).apply(0) must_== (3, "a-012")
</scala>

この `count` 関数は、最後に計算された文字列を受け取り、現在の「状態」に 1 を加えた `State` と、現在のカウント値を文字列に追加した新たな文字列を返す。そのため、文字列 `"a-"` から始めて、`count` を 2回 `flatMap` すると、`(3, "a-012")` が得られる。`3` は、`n+1` が適用された回数で、`a-012` は、現在の文字列に追加された結果だ。

ところで、`apply(0)` を呼び出す理由はなんだろう?

`flatMap` を何回も呼び出したときに作られるのは、実は「状態付き計算」(stateful computation) だ。これは、初期値が与えられてやっと実行される: `0`!

##### 要素の収集

それでは、カウントするのに役立つように `Traversable` に対する `collect` 演算を定義しよう:

<scala>
def collect[F[_] : Applicative, A, B](f: A => F[Unit], g: A => B) = {
  val applicative = implicitly[Applicative[F]]
  import applicative._

  val application = (a: A) => point((u: Unit) => g(a)) <*> f(a)
  traverse(application)
}
</scala>

この EIP で定義される `collect` 演算は、`filter + map` と等価である Scala コレクションの `collect` 演算とは別物だ。EIP版の `collect` は 2つの関数を使っている:

- `f: A => F[Unit]` これは各要素から effectful に (「場合によっては状態を保ちながら」という意味) データを収集する
- `g: A => B` これは各要素を何か別のものに投射する

このため、EIP版の `collect` は、`fold + map` に似てるとも言える。早速 `collect` を使って要素数を数えて、投射を行なってみよう:

<scala>
val count = (i: Int) => state((n: Int) => (n+1, ()))
val map   = (i: Int) => i.toString

tree.collect[({type l[A]=State[Int, A]})#l, String](count, map).apply(0) must_== 
(2, Bin(Leaf("1"), Leaf("2")))
</scala>

またしても型注釈がコードの意図を少し分かりづらくしているけど、型推論が完全なら以下のように書ける:

<scala>
val count = (i: Int) => state((n: Int) => (n+1, ()))
val map   = (i: Int) => i.toString

tree.collect(count, map).apply(0) must_== (2, Bin(Leaf("1"), Leaf("2")))
</scala>

どう思う? 僕は、これは魔法だと思う。この `Applicative` と `Traversable` の抽象化を使えば、全く別の所で開発されテストされた独立した 2つの関数を組み合わせてプログラムを組むといったことができるからだ。

##### 要素の拡散

EIP で提唱される次のユーティリティ関数は `disperse` 関数だ。シグネチャはこうなる:

<scala>
def disperse[F[_] : Applicative, A, B, C](f: F[B], g: A => B => C): F[A] => F[T[C]]
</scala>

何をするのかって?

- `f` は、データ構造を走査するときに発するが、型 `A` の要素とは無関係な `Applicative` なコンテキスト
- `g` は、現在のコンテキスト値の `B` に対して、型 `A` の各要素が何をして、どう元のデータ構造に投射するのかを記述する関数

頼むから、具体例で説明してくれ!

例えば、`BinaryTree` 内の各要素を `Traversal` 内の「数」を用いて「ラベル」としてマーク付けしたいとする。さらに、このラベルを要素名を使って修飾したいとする:

<scala>
// Double の BinaryTree
val tree: BinaryTree[Double] = Bin(Leaf(1.1), Bin(Leaf(2.2), Leaf(3.3)))

// 順番に整数を返す「ラベル」の state
val labelling: State[Int, Int] = state((n: Int) => (n+1, n+1))

// 木の中の全ての要素と、そのラベルに対して
// 要素名とラベルを使って String を生成する
val naming: Double => Int => String = (p1: Double) => (p2: Int) => p1+" node is "+p2

// 初期状態 (ラベル `0`) を適用して、ペアの `(last label, resulting tree)`
// の 2つ目の要素を取ることでテストする
tree.disperse[elided for sanity](labelling, naming).apply(0)._2 must_==
  Bin(Leaf("1.1 node is 1"), Bin(Leaf("2.2 node is 2"), Leaf("3.3 node is 3")))
</scala>

上の命名関数はカリー化されていることに注意。より親しみやすい方法で書くとこうなる:

<scala>
val naming: (Double, Int) => String = (p1: Double, p2: Int) => p1+" node is "+p2
</scala>

だけど、この関数は `disperse` 関数で使うにはカリー化しなければいけない:

<scala>
tree.disperse[...](labelling, naming.curried)
</scala>

`disperse` の実装はこうなる:

<scala>
def disperse[F[_] : Applicative, A, B, C](f: F[B], g: A => B => C) = {
  val applicative = implicitly[Applicative[F]]
  import applicative._

  val application = (a: A) => point(g(a)) <*> f
  traverse(application)
}
</scala>

これは、`point` メソッドと `<*>` 適用という Applicative ファンクタならではの機能を使っている。

### Traversal の概要

これで、`traverse` 関数の投射と `Applicative` の効果に制約をかけることで、目的に特化した特殊形を得られる例を 2つみた。ここに `traverse` 関数の特殊形をまとめた仮の表を作ってみる:

<table border="1">
<tr><th>関数</th>    <th>要素の投射</th><th>状態の作成</th><th>状態に依存した投射</th><th>要素に依存した状態</th></tr>
<tr><td>collect</td>     <td>◯  </td><td> ◯      </td><td>               </td><td> ◯             </td></tr>
<tr><td>disperse</td>    <td>◯  </td><td> ◯      </td><td> ◯            </td><td>                </td></tr>
<tr><td>measure</td>     <td>◯  </td><td> ◯      </td><td>               </td><td>                </td></tr>
<tr><td>traverse</td>    <td>◯  </td><td> ◯      </td><td> ◯            </td><td> ◯              </td></tr>
<tr><td>reduce</td>      <td>   </td><td> ◯       </td><td>              </td><td> ◯              </td></tr>
<tr><td>reduceConst</td> <td>   </td><td> ◯       </td><td>              </td><td>                 </td></tr>
<tr><td>map</td>         <td>◯  </td><td>         </td><td>              </td><td>                 </td></tr>
</table>

まだ見ていない関数は `measure` だけだ。これは、投射を行い、状態も累計するが、累計は現在の要素に依存しない。以下に具体例で説明する:

<scala>
val crosses = state((s: String) => (s+"x", ()))
val map     = (i: Int) => i.toString

tree.measure(crosses, map).apply("") must_==
("xxx", Bin(Leaf("1"), Bin(Leaf("2"), Leaf("3"))))
</scala>

これはあまり役に立たなさげであるだけでなく、上のコードには嘘が含まれている! 恒例の醜い型注釈無しでは `measure` 関数は `State` モナドを受け取ることができない。そのため、実際の例はこうなる:

<scala>
  tree.measureState(crosses, map).apply("") must_== 
  ("xxx", Bin(Leaf("1"), Bin(Leaf("2"), Leaf("3"))))
</scala>

このとき、`measureState` は `State` のための `measure` の特殊形だ。今回の記事で分かった事の一つは、`traverse` や `collect` などのジェネリックな関数のいくつかは、型注釈を回避するために `Const` や `State` のための特殊形を作ってしまったほうが役立つかもしれないということだ。

## 走査の合成

合成に関してまだ手をつけていない軸がある。

`for` ループならば、特に考えることなく以下のように書ける:

<scala>
for (a <- as) {
  val currentSize = a.size
  total += currentSize
  result.add(total)
}
</scala>

この `for` ループの本文中にはお互いに依存しあっている文がある。Applicative な走査では、これは `Applicative` の**順次的合成** (sequential composition) に翻訳される。2つの `Applicative` を準じ的に合成して 3つ目のものを作るというわけだ。より正確には、`F1[_]` と `F2[_]` が `Applicative` であるとき `F1[F2[_]]` もまた `Applicative` だ。具体例? よし、いこう。

まず、`ApplicFunctor` にユーティリティ関数を導入する:

<scala>
def liftA2[A, B, C](function: A => B => C): F[A] => F[B] => F[C] = 
  fa => applic.applic(functor.fmap(function)(fa))
</scala>

`liftA2` は、2つの引数を取る普通の関数を `Applicative` へ引数として渡せる関数へと持ち上げる (lift)。これは、`ApplicFunctor` が `Functor` であることを利用して、`function: A => B => C` を「箱に入った `a`」に適用して、「箱に入った」`F[B => C]` を得ることができる。さらに、`ApplicFunctor` は `Applic` であるため、`F[B]` を「適用」して `F[C]` を得ることができる。

この関数を利用して、`F1[F2[_]]` の `applic` メソッドは以下のように書ける:

<scala>
implicit val f1ApplicFunctor = implicitly[ApplicFunctor[F1]]
implicit val f2ApplicFunctor = implicitly[ApplicFunctor[F2]]

val applic = new Applic[({type l[A]=F1[F2[A]]})#l] {
  def applic[A, B](f: F1[F2[A => B]]) = (c: F1[F2[A]]) => {
    f1ApplicFunctor.liftA2((ff: F2[A => B]) => f2ApplicFunctor.apply(ff))(f).apply(c)
  }
}
</scala>

その前の定義を使って `F1[F2[A => B]]` が `F1[F2[A]]` 適用できるようにしているという以外は、上のコードが何をやっているのかの直観的な理解を得るのは容易ではない。

人間向けの解説をすると、これはループ内で `Applicative` 計算をして、その計算を別の `Applicative` 計算で再利用した場合、`Applicative` 計算が得られることを意味する。この原則を例示する EIP の例に、ちょっとヤバい関数である `assemble` 関数がある。

### `assemble` 関数

`assemble` 関数は、`Traversable` の**形**と要素のリストを受け取る。十分な要素がそろっていれば、要素を詰めた `Some[Traversable]` (と残りの要素) を返す。そろっていなければ、`None` (と空のリスト) を返す。実際に使ってみよう:

<scala>
// 詰むための「形」
val shape: BinaryTree[Unit] = Bin(Leaf(()), Leaf(()))

// ちょうど同じ要素数のリストで木を組み立てる
shape.assemble(List(1, 2)) must_== (List(), Some(Bin(Leaf(1), Leaf(2))))

// 多めの要素で木を組み立てる
shape.assemble(List(1, 2, 3)) must_== (List(3), Some(Bin(Leaf(1), Leaf(2))))

// 足りない要素で木を組み立てる
shape.assemble(List(1)) must_== (List(), None)
</scala>

`assemble` 関数の実装はどうなっているだろう? 実装には 2つの `Monad` (`Applicative` でもあることは今なら分かる) を使う:

- `State[List[Int], _] Monad` がどの要素を消費したかを管理する
- `Option[_] Monad` がデータ構造に入れるための要素を提供する (もしくはしない)
- 2つのモナドの合成は `State[List[Int], Option[_]]` (上記の `ApplicFunctor` の定義でいうところの `F1[F2[_]]`) となる

あとは `BinaryTree` を関数をつかって走査するだけだ:

<scala>
def takeHead: State[List[B], Option[B]] = state { s: List[B] =>
  s match {
    case Nil     => (Nil, None)
    case x :: xs => (xs, Some(x))
  }
}
</scala>

この `takeHead` 関数は、`state` を適用するたびに、リストに最初の要素があれば、それを削除して Option に包んで返す `State` のインスタンスだ。
これが `assemble` 関数の戻り値が、要素のリストに適用した後で `(List[Int], Option[BinaryTree[Int]])` になる理由だ。

#### 再帰的な実装

比較のために、同じ事を実行する再帰的なバージョンも書いてみた:

<scala>
def assemble(es: List[Int], s: BinaryTree[Unit]) : (List[Int], Option[BinaryTree[Int]]) = {
  (es, s) match {
    case (Nil, _)                      => (es, None)
    case (e :: rest, Leaf(()))         => (rest, Some(Leaf(e)))
    case (_, Bin(left, right))         => {
      assemble(es, left) match {
        case (l, None)       => (l, None)
        case (Nil, Some(l))  => (Nil, None)
        case (rest, Some(l)) => assemble(rest, right) match {
          case (r, None)            => (r, None)
          case (finalRest, Some(r)) => (finalRest, Some(Bin(l, r)))
        }
      }
    }
  }
}
assemble(List(1, 2, 3), shape) must_== (List(3), Some(Bin(Leaf(1), Leaf(2))))
</scala>

動作するけど、頭が混乱しそうだよ!

#### 古典的 `for` ループを用いた実装

ところで、**本物の** `for` ループを使って実装したらどうなるだろう? 僕の知る限り `BinaryTree` を走査して似たような `BinaryTree` を `for` ループ一つだけで得る簡単な方法は無いから、これは簡単ではない! そのため、話を先に進めるため `List` データ構造を使って似たようなことを行なってみる:

<scala>
def assemble[T](es: List[T], shape: List[Unit]) = {
  var elements = es
  var list: Option[List[T]] = None
  for (u <- shape) {
    if (!elements.isEmpty) {
      list match {
        case None    => list = Some(List(elements.first))
        case Some(l) => list = Some(l :+ elements.first)
      }
      elements = elements.drop(1)
    } else {
      list = None
    }
  }
  (elements, list)
}
assemble(List(1, 2, 3), List((), ())) must_== (List(3), Some(List(1, 2)))
</scala>

以下と比較してみよう:

<scala>
List((), ()).assemble(List(1, 2, 3)) must_== (List(3), Some(List(1, 2)))
</scala>

これは、`Traversable` としての `List` を定義するだけでいい:

<scala>
implicit def ListIsTraversable[A]: Traversable[List] = new Traversable[List] {

  def traverse[F[_] : Applicative, A, B](f: A => F[B]): List[A] => F[List[B]] = 
    (l: List[A]) => {
      val applicative = implicitly[Applicative[F]]
      l match {
        case Nil       => applicative.point(List[B]())
        case a :: rest =>
          ((_:B) :: (_: List[B])).curried ∘ f(a) <*> (rest traverse f)
    }
  }

}
</scala>

`Applicative` 合成はたしかに強力だけど、他にも関数を合成して `Traversable` と一緒に使える方法があるので、それをみていく。

### Monadic 合成

この節では、走査時の Applicative 合成と Monadic 合成の関係を探索してよう。`Applicative` のインスタンスが合成可能で `Monad` を `Applicative` として扱うことができることは既にみた。だけど、`Monad` もいわゆる Kleisli 合成を使って合成することができる。以下を仮定する:

<scala>
val f: B => M[C]
val g: A => M[B]
</scala>

このとき、

<scala>
val h: A => M[C] = f ∎ g // これも値から Monad への関数だ
</scala>

2つの「モナディックな」(monadic) 関数 `f` と `g` があるとき、これを Kleisli 的な意味で合成して、その合成されたものを走査に使うことができる。確かにそれはできるけど、この走査は「便利な特性」を満たしているだろうか? 具体的には:

<scala>
traverse(f ∎ g) == traverse(f) ∎ traverse(g)
</scala>

答は... 場合による。

#### モナドの可換性

EIP は、`Monad` が可換 (commutative) であれば、これが常に真であることを証明する。可換 `Monad` って何かって?

もし全ての `mx: M[X]` と `my: M[Y]` に対して以下が成り立つとき、その `Monad` は可換であると言える:

<scala>
val xy = for {
  x <- mx
  y <- my
} yield (x, y)

val yx = for {
  y <- my
  x <- mx
} yield (x, y)

xy == yx
</scala>

例えば、`State Monad` はこれに該当しない:

<scala>
val mx = state((n: Int) => (n+1, n+1))
val my = state((n: Int) => (n+1, n+1))

xy.apply(0) must_== (2, (1, 2))
yx.apply(0) must_== (2, (2, 1))
</scala>

#### モナディック関数の可換性

これとは少し異なる状況として、非可換な `Monad` と可換な関数というものがある:

<scala>
val plus1  = (a: A) => state((n: Int) => (n+1, a))
val plus2  = (a: A) => state((n: Int) => (n+2, a))
val times2 = (a: A) => state((n: Int) => (n*2, a))
</scala>

ここでは `plus1` と `times2` は可換ではない (交換できない):

<scala>
(0 + 1) * 2 != (0 * 2) + 1
</scala>

だけど、`plus1` と `plus2` なら可換であることは明らかだ。これは走査時に何を意味するだろうか?

モナド合成を用いてシンプルな要素のリストを走査した場合、以下を得られる:

<scala>
List(1, 2, 3).traverse(times2 ∎ plus1)                         === 22
List(1, 2, 3).traverse(times2) ∎ List(1, 2, 3).traverse(plus1) === 32
</scala>

異なる結果となった。しかし、`f` と `g` が交換可能の場合は同じ結果となる:

<scala>
List(1, 2, 3).traverse(plus2 ∎ plus1)                         === 10
List(1, 2, 3).traverse(plus2) ∎ List(1, 2, 3).traverse(plus1) === 10
</scala>

#### Applicative 合成 vs Monadic 合成

もう一つの疑問は、モナディックな関数を Applicative な関数とみなした場合 (全ての `Monad` は `Applicative` であるため)、便利な「分配則」は成り立つだろうか? 答は、たとえ関数が可換ではなくても分配則は成り立つ:

<scala>
List(1, 2, 3).traverse(times2 ⊡ plus1)                         === 4
List(1, 2, 3).traverse(times2) ⊡ List(1, 2, 3).traverse(plus1) === 4
</scala>

ま... 一応成り立つという方が正しい。実際の状況はもう少し複雑だ。`List(1, 2, 3).traverse(times2 ⊡ plus1)` は `State[Int, State[Int, List[Int]]]` を返すけど、第二の式は `State[Int, List[State[Int, Int]]` を返すため、ここでは最終結果を問い合わせるために `join` を用いた操作が少し入るけどそれは隠してある。

## 結論

信じられないかもしれないけど、ここで紹介したのは `EIP` で議論されているアイディアの半分だけだ!

最後にまとめとして、これを書きながら勉強になった要点を 3つ:

- 関数型プログラミングは、`Applicative` のような高レベルな制御構造を習得することでもある。一度覚えてしまえば、道具箱が一気に広がる (例えば、`assemble` が良い例だ)
- [Scalaz][5] は素晴らしいライブラリだけど、初心者には分かりづらい。この記事を書くにあたって必要な型クラスは全て僕が書き起こして、例もいっぱい書いた (当然 [specs2][6] を使ってだ)。これにより、Scalaz の機能に対するより深い理解が得られた。Scalaz を習うためには、やってみることをお勧めする (僕のコードは [github に置いてある][7])
- 型推論に関しては Scala は Haskell に水を開けられていて、高階関数やジェネリックなプログラミングの時に本当に厄介だ。これは、頻繁に使われる型に関してはジェネリックな関数を (`traverse` の代わりに `traverseState` などとして) 特殊化することでカプセル化できることもある。もう一度言うけど、[SI-2712][3] へのご投票お願いします!

他にも Haskell で書かれた [functional pearl][8] の多くが Scala に翻訳されることを言及して結びの言葉としたい。Scala 界にはまだ ["Learn you a Haskell"][9] や ["Typeclassopedia"][10] ([snak氏による日本語訳][11]) に相当するものが無いのは残念なことだ。この記事や Debasish Ghosh の記事が少しでもそのギャップを埋めることができれば幸いだ。

> 訳注: ねこはる氏が[一人Scalaz Advent Calendar][14] を書いています。型クラスが丁寧に説明されていてとても参考になります。

  [1]: http://members.shaw.ca/newsong/calvin.html
  [2]: http://www.artima.com/weblogs/viewpost.jsp?thread=179766
  [3]: https://issues.scala-lang.org/browse/SI-2712
  [4]: http://learnyouahaskell.com/for-a-few-monads-more#state
  [5]: http://github.com/scalaz/scalaz
  [6]: http://specs2.org/
  [7]: https://github.com/etorreborre/iterator-essence
  [8]: http://www.haskell.org/haskellwiki/Research_papers/Functional_pearls
  [9]: http://learnyouahaskell.com/
  [10]: http://www.haskell.org/haskellwiki/Typeclassopedia
  [11]: http://snak.tdiary.net/20091020.html
  [12]: http://stackoverflow.com/questions/6246719/what-is-a-higher-kinded-type-in-scala
  [13]: http://adriaanm.github.com/files/higher.pdf
  [14]: http://partake.in/events/4b3afdc8-e4ec-4010-b8ec-31b89210dda0
  [TAPL]: http://www.cis.upenn.edu/~bcpierce/tapl/
  