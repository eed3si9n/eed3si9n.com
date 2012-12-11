> これは [Scalaz Advent Calencar 2012](http://partake.in/events/7211abc9-ebb8-4670-b912-3089dc5e0edd) 12日目の記事です。
>
> 次々と Scala 界の知能派を集結させている [Precog](http://precog.com/) 社の開発チームからのブログ [Precog.Copointed](http://www.precog.com/blog-precog-2/categories/listings/precog-copointed)。今日は blueeyes などの開発でも知られる Kris Nuttycombe ([@nuttycom](https://twitter.com/nuttycom)) さんが書いた [The Abstract Future](http://www.precog.com/blog-precog-2/categories/listings/precog-copointed) を翻訳しました。翻訳の公開は本人より許諾済みです。

2012年11月27日 Kris Nuttycombe 著
2012年12月11日 e.e d3si9n 訳

Precog 開発ブログの[前回](http://www.precog.com/blog-precog-2/entry/existential-types-ftw)は僕たちが Cake パターンを使ってコードベースを構造化して、ギリギリまで実装型を抽象化してしていることを Daniel が書いた。その記事での説明のとおり、これは非常に強力な概念だ。型を存在型として保つことで、やがて選択された型を「意識」していないモジュールからはそれらの型の値は不可視であるため、カプセル化の境界の突破をコンパイラが防止してくれる。

今日の記事では、この概念を型からさらに進めて型コンストラクタに適用して、計算モデルを丸ごと置き換える機構として使えることを説明する。

Scala を少しでも使ったことがあれば、何らかの文脈で誰かが「モナド」という言葉を使ったのを聞いたことがあるだろう。例えば、Scala の `for` というキーワードにより提供される糖衣構文に関する議論か、`Option` 型を使うことで null 参照エラーの[落とし穴が回避できる](http://www.codecommit.com/blog/scala/the-option-pattern)ことを説明したブログ記事で読んだのかもしれない。Scala でのモナドに関する議論の大半が「コンテナ」型に焦点を当てているのに対して、Scala エコシステムでよく見かけるいくつかの型の中にモナディック合成のより面白い側面が表れるものがある。限定計算 (delimited computation) だ。どのモナディックな型を合成してもこの側面を見ることができるが、これを直接利用した例として最もよく使われている Scala でのモナディックな型に非同期計算をエンコードした `akka.dispatch.Future` がある (これは Scala 2.10 において現行の Future を置き換える予定のものだ)。これは計算のステップを順序付けするための柔軟な方法を提供することで、本稿が注目するモナディック合成の一面を体現する。

ここで一言断っておくが、この記事はモナドのチュートリアルとして機能することを意図していない。[モナド](http://dl.dropbox.com/u/261418/Monads_are_Elephants/index.html)[の](http://apocalisp.wordpress.com/2011/07/01/monads-are-dominoes/)[解説](http://byorgey.wordpress.com/2009/01/12/abstraction-intuition-and-the-monad-tutorial-fallacy/)とその Scala のプログラミングとの関連を取り扱った記事は既にたくさんある ([ありすぎる](http://eed3si9n.com/ja/monads-are-not-metaphors)かも!)。もしこの概念に不慣れなら読み進める前にそれらの解説を読むと役に立つかもしれない。しかし、最初に注意しておきたい点が一つあって、([モナディック合成のための糖衣構文としての `for`](http://debasishg.blogspot.com/2008/03/monads-another-way-to-abstract.html) が示すとおり) Scala ではモナドは広い範囲で利用されているにも関わらず Scala の標準ライブラリに `Monad` 型が無いというのは Scala 固有な状況だということだ。そのため、モナド型が必要ならば標準ライブラリ外の素晴らしい Scalaz プロジェクトを使う。Scalaz のモナド抽象体は implicit 型クラスパターンを利用している。以下にベースの `Monad` 型を簡略化したものを示す:

<scala>
trait Monad[M[_]] {
  def point[A](a: => A): M[A]
  def bind[A, B](m: M[A])(f: A => M[B]): M[B]
  def map[A, B](m: M[A])(f: A => B): M[B] = bind(m)(a => point(f(a))) 
}
</scala>

`Monad` トレイトが特定の型ではなく一つの引数を受け取る[型コンストラクタ](http://debasishg.blogspot.com/2009/01/higher-order-abstractions-in-scala-with.html)を使ってパラメータ化されていることに気付いただろうか。`Monad` 内で定義されているメソッドは多相的で、つまり呼び出し時点で特定の型を「穴」に挿入する必要がある。これは後ほどこの抽象化を利用する際に重要になる点だ。

Scalaz は Scala 標準ライブラリにあるモナディックな型のほとんどに対してこの型の実装をするほかに、いくつかの洗練された独自のモナディック型も提供するが、それは後で見る。まずは、Akka の Future について話そう。

Akka の Future は非同期に値が与えられ、失敗するかもしれない計算を表す。また前述のとおり、`akka.dispatch.Future` はモナディックだ。言い替えると、これは上の `Monad` トレイトを自明に実装することができ、モナド則を満たし、そのためスレッドや共有可変状態を独自で管理するというあきあきするようなことを行わなくても非同期計算を合成ができる非常に便利な部品を提供する。Precog 社ではこの Future を多用しており、直接使ったり、Akka のアクターフレームワーク上に実装されたサブシステムと合成可能な方法で会話するための方法として使ったりしている。おそらく Future は今あるツールの中で非同期プログラミングにおける複雑さを抑えこむのに最も有用なものだと言えるだろう。そのため、僕らのコードベースの早期のバージョンの API は `Future` を直接露出させたものが多かった。例えば、以下は僕らの内部 API から一部抜粋したもので、前述のとおり Cake パターンを使っている:

<scala>
trait DatasetModule {
  type Dataset 

  trait DatasetLike {
    /** このデータセットのメンバを用いてどの集合を読み込むかが決定され、
        結果の集合は和集合となる。 */
    def load: Future[Dataset]

    /** 渡された値関数を用いてデータセットをソートする。 */
    def sort(sortBy: /*...*/): Future[Dataset]

    /** このデータセットのプレフィックスを保持する。 */
    def take(size: Int): Dataset

    /** データセットのメンバを渡された値関数を用いて型 A に投射して、
        結果をモノイドを用いて組み合わせる。 */
    def reduce[A: Monoid](mapTo: /*...*/): Future[A]
  }
} 
</scala>

ここでの `Dataset` 型は話を進めるためのたたき台だが、僕たちが内部で計算の中間結果を表現するのに使っている型を大まかに表している。遅延評価されたデータ構造で、それを操作するための演算を持っていて、そのうちのいくつかはデータセット全体に対して関数を評価することもあり、そうなると I/O、分散評価、非同期計算が関わってくる。このインターフェイスから、あるデータセットに対するクエリの評価には、データの読み込み (load)、ソート (sort)、プレフィックスの take して、そのプレフィックスの reduce が関わってくることが予想される。さらに、それらの評価の各ステップの合成は Future のモナディックな性質以外には一切何にも依存しない。これが何を意味するかというと、`DatasetModule` インターフェイスを使っているコンシューマの視点から見ると、Future の側面のうち依存しているのは、静的に型検査された方法で複数の演算を順序付けるという能力だけだ。つまり Future の非同期に関連したさまざまな意味論ではなく、この順序付けが型によって提供される情報のうち実際に使われているものだと言える。そのため、自然と以下の一般化を行うことができる:

<scala>
trait DatasetModule[M[+_]] {
  type Dataset 
  implicit def M: Monad[M]

  trait DatasetLike {
    /** このデータセットのメンバを用いてどの集合を読み込むかが決定され、
        結果の集合は和集合となる。 */
    def load: M[Dataset]

    /** 渡された値関数を用いてデータセットをソートする。 */
    def sort(sortBy: /*...*/): M[Dataset]

    /** このデータセットのプレフィックスを保持する。 */
    def take(size: Int): Dataset

    /** データセットのメンバを渡された値関数を用いて型 A に投射して、
        結果をモノイドを用いて組み合わせる。 */
    def reduce[A: Monoid](mapTo: /*...*/): M[A]
  }
}
</scala>

そして、当然、後になって `DatasetModule` の具象実装が型コンストラクタ `M` を Future だと特定する:

<scala>
/** The implicit ExecutionContext is necessary for the implementation of 
    M.point */
class FutureMonad(implicit executor: ExecutionContext) extends Monad[Future] {
  override def point[A](a: => A): Future[A] = Future { a }
  override def bind[A, B](m: Future[A])(f: A => Future[B]): Future[B] = 
    m flatMap f
}

abstract class ConcreteDatasetModule(implicit executor: ExecutionContext) 
extends DatasetModule[Future] {
  val M: Monad[Future] = new FutureMonad 
}
</scala>

実際には、`M` は「世界の終わりまで」抽象型のまま保つ場合もある。Precog 社のコードベースでは `M` 型は往々にして実際の `Dataset` 型が依存する `StateT`、`StreamT`、`EitherT` などのモナド変換子のスタックの底を表す。

この一般化には多くの効用がある。まず、前述の Cake パターンを利用した例のとおり、`DatasetModule` トレイトを利用するコンシューマは実装型という不必要な詳細から完全に、静的に隔離されている。このコンシューマのうち重要なものにテストスイートがある。テスト時には僕たちの計算が非同期で実行されるという事実はおそらく心配したくない。最終的に正しい結果が取得できさえすればいいからだ。もし仮に僕らの `M` が実際にモナド変換子スタックの底だった場合は、これを簡単に恒等モナド ([identity monad](https://github.com/scalaz/scalaz/blob/scalaz-seven/core/src/main/scala/scalaz/Id.scala)) で置き換えて、このモナドの「copointed」な性質 (モナディックなコンテキストから値を「抽出」できる能力) を利用することができる。これを使ってジェネリックなテストハーネスを構築できる:
 
<scala>
/** Copointed も Scalaz から入手できる。*/
trait Copointed[M[_]] {
  /** 包囲するコンテキストから値を抽出して返す。 */
  def copoint[A](m: M[A]): A
}

trait TestDatasetModule[M[+_]] extends DatasetModule {
  implicit def M: Monad[M] with Copointed[M]

  //... utilities for test dataset generation, stubbing load/sort, etc.
}
</scala>

ほとんどの場合は、僕たちはテストには恒等モナドを使う。例えば、先程出てきた読み込み、ソート、take、reduce を組み合わせた機能をテストしたいとする。テストフレームワークはどのモナドを使っているかを一切考えずに済む。
 
<scala>
import scalaz._
import scalaz.syntax.monad._
import scalaz.syntax.copointed._

class MyEvaluationSpec extends Specification {
  val module = new TestDatasetModule[Id] with ConcreteDatasetModule[Id] { 
    val M = Monad[Id] // the monad for Id is copointed in Scalaz.
  }
  
  “evaluation” should {
    “determine the correct result for the load/sort/take/reduce case” in {
      val loadFrom: module.Dataset = //...
      val expected: Int = //...

      val result = for {
        ds 
        sorted - ds.sortBy(mySortFun)
        prefix = sorted.take(10)
        value - prefix.reduce[Int]myCountFunc)
      } yield value

      result.copoint must_== expected
    }
  }
}
</scala>

実装の一部が何らかの特定のモナド型に依存する場合 (例えば、ソートの実装が内部で Akka アクターの [Ask パターン](http://doc.akka.io/docs/akka/2.0.4/scala/actors.html#Ask__Send-And-Receive-Future)に依存しているため Future が必要な場合など) でも、簡単にテストにエンコードすることができる:

<scala>
abstract class TestFutureDatasetModule(implicit executor: ExecutionContext)
extends TestDatasetModule[Future] {
  def testTimeout: akka.util.Duration

  object M extends FutureMonad(executor) with Copointed[Future] {
    def copoint[A](m: Future[A]): A = Await.result(m, testTimeout)
  }
}
</scala>

当然のことながら Future は copointed ではないが (`Await` が例外を投げる可能性があるため) 、テストという用途においては (そしてテスト用途においてのみ) この仕組みは理想的だ。以前通り、僕たちは必要な型を必要な場所で手にすることができ、それは静的に決定される。

実地の経験上、コードが使っている特定のモナドを抽象化することは、僕らのコードベースにおけるそれぞれのパーツを適切に隔離し、また大規模な関数型のコードベースが首尾一貫した全体として協調するのに避けて通れない順序立てという要求を保証するのに途方もないほど役に立った。追加の効用として、初期の設計では並列実行を行うことを考えていなかった多くのパーツが並行して実行できるようになった。例えば、多くの場合 `List[M[...]]` を計算して [`scalaz.Traverse`](https://github.com/scalaz/scalaz/blob/scalaz-seven/core/src/main/scala/scalaz/Traverse.scala) が提供する sequence 関数を用いて `M[List[...]]` に変換できる。そして、この `M` が Future の場合は各要素は並列して計算され、リストのメンバを生成するための全ての計算が完了した時点で最終結果が利用可能となる。そして、最終的にはこの例でさえ、モナドを抽象化することによって得られる合成計算の深いプールの水面を触れたにすぎない。
