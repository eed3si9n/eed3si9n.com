  [Convert]: https://github.com/sbt/sbt/blob/v1.5.5/core-macros/src/main/scala/sbt/internal/util/appmacro/Convert.scala
  [metaprogramming]: http://dotty.epfl.ch/docs/reference/metaprogramming/toc.html
  [Enum]: http://dotty.epfl.ch/docs/reference/enums/adts.html
  [TypeProjection]: http://dotty.epfl.ch/docs/reference/dropped-features/type-projection.html
  [so-50043630]: https://stackoverflow.com/q/50043630/3827
  [Tree]: https://github.com/lampepfl/dotty/blob/3.0.1/library/src/scala/quoted/Quotes.scala#L255
  [Transformer]: https://github.com/scala/scala/blob/v2.13.6/src/reflect/scala/reflect/api/Trees.scala#L2563
  [TreeMap]: https://github.com/lampepfl/dotty/blob/3.0.1/library/src/scala/quoted/Quotes.scala#L4370
  [Type]: http://dotty.epfl.ch/docs/reference/metaprogramming/macros.html#types-for-quotations
  [statically-unknown]: https://docs.scala-lang.org/scala3/guides/macros/faq.html#how-do-i-summon-an-expression-for-statically-unknown-types

実験的 sbt として、酢鶏 (sudori) という小さなプロジェクトを作っている。当面の予定はマクロ周りを Scala 3 に移植することだ。sbt のマクロを分解して、土台から作り直すという課題だ。これは Scala 2 と 3 でも上級者向けのトピックで、僕自身も試行錯誤しながらやっているので、覚え書きのようなものだと思ってほしい。

参考:
- [Scala 3 Reference: Metaprogramming][metaprogramming]

### Convert

何にも依存していない基礎となる [Convert][Convert] というものを特定できた。

<scala>
abstract class Convert {
  def apply[T: c.WeakTypeTag](c: blackbox.Context)(nme: String, in: c.Tree): Converted[c.type]

  ....
}
</scala>

`Tree` を受け取って `Converted` という抽象データ型を返す部分関数の豪華版みたいなものに見える。`Converted` は、以下のように型パラメータとして `[C <: blackbox.Context with Singleton]` を取る:

<scala>
  final case class Success[C <: blackbox.Context with Singleton](
      tree: C#Tree,
      finalTransform: C#Tree => C#Tree
  ) extends Converted[C] {
    def isSuccess = true
    def transform(f: C#Tree => C#Tree): Converted[C] = Success(f(tree), finalTransform)
  }
</scala>

このように直接 `Tree`、つまり抽象構文木 (AST) を扱う古い Scala 2 マクロの実装の典型的な例だが、Scala 3 ではもっと綺麗に高度なレベルで[メタプログラミング][metaprogramming]を行う仕掛けとして `inline` などがあるので、そこから始めるのを通常は推奨される。

ただし、この場合は既存のマクロを移植しているのでクォートリフレクション (quote reflection) にひとっ飛びする。これは Scala 2 マクロに似ている感じだ。

#### Enums

[enum][Enum] の定義はこんな感じになる:

<scala>
import scala.quoted.*

enum Converted[C <: Quotes]:
  case Success() extends Converted[C]
  case Failure() extends Converted[C]
  case NotApplicable() extends Converted[C]
end Converted
</scala>

sealed trait と case class の組み合わせと違って、ADT にぶら下がるメソッドも `enum` 内で定義される:

<scala>
import scala.quoted.*

enum Converted[C <: Quotes]:
  def isSuccess: Boolean = this match
    case Success() => true
    case _         => false

  case Success() extends Converted[C]
  case Failure() extends Converted[C]
  case NotApplicable() extends Converted[C]
end Converted
</scala>

`Success()` や `Failure()` を `Converted[C]` 型を持つ値だと捉えるとこれも納得がいく。

#### Type projection is gone

Scala 3 は[型射影][TypeProjection] (type projection) `C#A` を廃止した。実際の `Success` は `C#Tree` と `C#Tree => C#Tree` という 2つのパラメータを受け取るので、いきなり難題となった。[What does Dotty offer to replace type projections?][so-50043630] という StackOverflow での質問がある。

そこで示されている 1つの解法はパス依存型を使うことだ。この場合、quote reflection の [Tree][Tree] は `qctx.reflection.Tree` というふうに `qctx.reflection` にぶら下がっているので、この方法でいけるかもしれない。

`Success` と `Failure` は以下のようになる:

<scala>
enum Converted[C <: Quotes](val qctx: C):
  def isSuccess: Boolean = this match
    case _: Success[C] => true
    case _             => false

  case Success(override val qctx: C)(
      val tree: qctx.reflect.Term,
      val finalTransform: qctx.reflect.Term => qctx.reflect.Term)
    extends Converted[C](qctx)

  case Failure(override val qctx: C)(
      val position: qctx.reflect.Position,
      val message: String)
    extends Converted[C](qctx)
end Converted
</scala>

パラメータとして `qctx.reflect.Term` を受け取るためにこれらの case は複数のパラメータリストを持ち、最初のパラメータリストで `qctx` を受け取る。次は `transform` メソッドの実装で、これもややこしい。

<scala>
enum Converted[C <: Quotes](val qctx: C):
  def isSuccess: Boolean = this match
    case _: Success[C] => true
    case _             => false

  def transform(f: qctx.reflect.Term => qctx.reflect.Term): Converted[C] = this match
    case x: Failure[C]       => Failure(x.qctx)(x.position, x.message)
    case x: Success[C] if x.qctx == qctx =>
      Success(x.qctx)(
        f(x.tree.asInstanceOf[qctx.reflect.Term]).asInstanceOf[x.qctx.reflect.Term],
        x.finalTransform)
    case x: NotApplicable[C] => x
    case x                   => sys.error(s"Unknown case $x")

end Converted
</scala>

`transform` は関数 `f` を `Sucess(...)` に格納された構文木に適用するが、`transform` で使われている `qctx` が `Success(...)` で捕捉されたものと同じだということをコンパイラに伝える方法があるのか分からない。

#### Cake trait

この醜いキャストを取り除く方法があって、それは外囲 trait (outer trait) を定義することだ。

<scala>
trait Convert[C <: Quotes & Singleton](val qctx: C):
  import qctx.reflect.*
  given qctx.type = qctx

  ....

end Convert
</scala>

これで `Convert` trait 内では、`Term` は常に `qctx.reflect.Term` を意味するようになった。型パラメータ `C` を使っていないので、ここで `C` を定義する必要があるのかは良く分かっていない。

<scala>
trait Convert[C <: Quotes & Singleton](val qctx: C):
  import qctx.reflect.*
  given qctx.type = qctx

  def convert[A: Type](nme: String, in: Term): Converted

  object Converted:
    def success(tree: Term) = Converted.Success(tree, Types.idFun)

  enum Converted:
    def isSuccess: Boolean = this match
      case Success(_, _) => true
      case _             => false

    def transform(f: Term => Term): Converted = this match
      case Success(tree, finalTransform) => Success(f(tree), finalTransform)
      case x: Failure       => x
      case x: NotApplicable => x

    case Success(tree: Term, finalTransform: Term => Term) extends Converted
    case Failure(position: Position, message: String) extends Converted
    case NotApplicable() extends Converted
  end Converted
end Convert
</scala>

実装はシンプルで前より短いものとなった。一つの欠点は `Converted` が `Convert` の入れ子型になるため、それを使うのに後でまたパス依存型が出てくるだろうことだ。

後で詰まないようにこの trait が合成可能か確認したい。まず、`Convert` 内の関数が別のモジュールの関数に `Term` を渡せるか確認しよう。この `qctx` だけのパス依存性から逃れられないと困るからだ。以下のようなモジュールを考える:

<scala>
object SomeModule:
  def something(using qctx0: Quotes)(tree: qctx0.reflect.Term): qctx0.reflect.Term =
    tree

end SomeModule
</scala>

以下のようにして `SomeModule.something` を呼び出せる:

<scala>
trait Convert[C <: Quotes & Singleton](override val qctx: C):
  import qctx.reflect.*
  given qctx.type = qctx

  def test(term: Term): Term =
    SomeModule.something(term)

  ....
</scala>

キャスト無しでコンパイルできたので良い兆しだ。`qctx.type` の `given` インスタンスを定義して明示的に `qctx` を渡さなくてもいいようにしてある。Cake trait を合成するもう 1つの方法は、別の trait を積み上げることだ:

<scala>
import scala.quoted.*

trait ContextUtil[C <: Quotes & Singleton](val qctx: C):
  import qctx.reflect.*
  given qctx.type = qctx

  def something1(tree: Term): Term =
    tree
end ContextUtil
</scala>

`Convert` を `ContextUtil` から拡張することで共通の関数を再利用できる:

<scala>
trait Convert[C <: Quotes & Singleton](override val qctx: C) extends ContextUtil[C]:
  import qctx.reflect.*

  def test(term: Term): Term =
    something1(term)

  ....
</scala>

これもキャスト無しでコンパイルできた。

#### TreeMap

マクロでよくあるのは、渡された抽象構文木 (AST) を走査して、何らかの条件を満たす木の一部を変換するというパターンだ。この走査は "tree walking"「木を歩く」と言われたりする。この走査と変換はよく出てきすぎるのでそれを簡単にする API がある。

Scala 2 では [Transformer][Transformer] を拡張することでこれを行う。Scala 3 では、これは [TreeMap][TreeMap] と呼ばれている。気の利いた名前だが、`scala.collection.immutable.TreeMap` と混同されないか心配になる。`TreeMap` を使うには実装を読んでどのメソッドをオーバーライドするかを選ぶ必要がある。一見 `transformTree` だと思うかもしれないが、おそらく求めているのは `transformTerm` であることが多いと思う。

<scala>
  def transformWrappers(
    tree: Term,
    subWrapper: (String, Type[_], Term, Term) => Converted
  ): Term =
    // the main tree transformer that replaces calls to InputWrapper.wrap(x) with
    //  plain Idents that reference the actual input value
    object appTransformer extends TreeMap:
      override def transformTerm(tree: Term)(owner: Symbol): Term =
        tree match
          case Apply(TypeApply(Select(_, nme), targ :: Nil), qual :: Nil) =>
            subWrapper(nme, targ.tpe.asType, qual, tree) match
              case Converted.Success(tree, finalTransform) =>
                finalTransform(tree)
              case Converted.Failure(position, message) =>
                report.error(message, position)
                sys.error("macro error: " + message)
              case _ =>
                super.transformTerm(tree)(owner)
          case _ =>
            super.transformTerm(tree)(owner)
    end appTransformer
    appTransformer.transformTerm(tree)(Symbol.spliceOwner)
</scala>

#### convert の用例

convert を使ってみる:

<scala>
  final val WrapInitName = "wrapInit"
  final val WrapInitTaskName = "wrapInitTask"

  class InputInitConvert[C <: Quotes & Singleton](override val qctx: C) extends Convert[C](qctx):
    import qctx.reflect.*
    def convert[A: Type](nme: String, in: Term): Converted =
      nme match
        case WrapInitName     => Converted.success(in)
        case WrapInitTaskName => Converted.Failure(in.pos, initTaskErrorMessage)
        case _                => Converted.NotApplicable()

    private def initTaskErrorMessage = "Internal sbt error: initialize+task wrapper not split"
  end InputInitConvert
</scala>

これは sbt で実際に使われている convert に似てて、`wrapInit` メソッドにマッチするようにしてある。これを使って `ConvertTest.wrapInit(1)` を `2` に置換するマクロを定義できる。

<scala>
  inline def someMacro(inline expr: Boolean): Boolean =
    ${ someMacroImpl('expr) }

  def someMacroImpl(expr: Expr[Boolean])(using qctx0: Quotes) =
    val convert1: Convert[qctx.type] = new InputInitConvert(qctx)
    import convert1.qctx.reflect.*
    def substitute(name: String, tpe: Type[_], qual: Term, replace: Term) =
      convert1.convert[Boolean](name, qual) transform { (tree: Term) =>
        '{ 2 }.asTerm
      }
    convert1.transformWrappers(expr.asTerm, substitute).asExprOf[Boolean]
</scala>

Verify を使って以下のようにテストできる:

<scala>
import verify.*
import ConvertTestMacro._

object ConvertTest extends BasicTestSuite:
  test("convert") {
    assert(someMacro(ConvertTest.wrapInit(1) == 2))
  }

  def wrapInit[A](a: A): Int = 2
end ConvertTest
</scala>

ここでは 2つのレイヤーのフィルタリングが起こっている。第一に、`appTransformer` という名前で定義した `TreeMap` は単一のパラメータを受け取るジェネリック関数の呼び出しのみ見るようになっている。次に、`convert1` は `wrapInit` というメソッド名のみを成功したメソッドとする。

#### レイファイ型とそれを型に戻す方法

木歩きで補足しておきたいのは、この時点で型情報が得られることだ。例えば、`wrapInit[A](...)` の型引数は `TypeApply(...)` 木に渡されている。これは `targ.tpe.asType` を使って `Type[_]` データ型に変換することができる。[Type[T]][Type] は「型消去されていない型 `T` の表象」だと説明されている。

これが `substitute` 関数に `Type[_]` として渡されている。これは `wrapInit[A](...)` を捕獲しているわけだから、`Type[_]` より特定なものは無い。だけども、これをアンマーシャル (unmarshal) して実際に使える `T` に解凍したい。これに関連した [How do I summon an expression for statically unknown types?][statically-unknown] という質問が Scala 3 マクロ FAQ にある。

<scala>
val tpe: Type[_] = ...
tpe match
  // (1) Use `a` as the name of the unknown type and (2) bring a given `Type[a]` into scope
  case '[a] => Expr.summon[a]
</scala>

これはなかなか面白い。このテクニックを使って `A` を `Option[A]` で包む `addType(...)` を実装してみよう。

<scala>
  inline def someMacro(inline expr: Boolean): Boolean =
    ${ someMacroImpl('expr) }

  def someMacroImpl(expr: Expr[Boolean])(using qctx0: Quotes) =
    val convert1: Convert[qctx.type] = new InputInitConvert(qctx)
    import convert1.qctx.reflect.*
    def addTypeCon(tpe: Type[_], qual: Term, selection: Term): Term =
      tpe match
        case '[a] =>
          '{
            Option[a](${selection.asExprOf[a]})
          }.asTerm
    def substitute(name: String, tpe: Type[_], qual: Term, replace: Term) =
      convert1.convert[Boolean](name, qual) transform { (tree: Term) =>
        addTypeCon(tpe, tree, replace)
      }
    convert1.transformWrappers(expr.asTerm, substitute).asExprOf[Boolean]
</scala>

テストするとこうなる:

<scala>
object ConvertTest extends BasicTestSuite:
  test("convert") {
    assert(someMacro(ConvertTest.wrapInit(1).toString == "Some(2)"))
  }

  def wrapInit[A](a: A): Int = 2
end ConvertTest
</scala>

つまり、`2` を返す `ConvertTest.wrapInit(1)` を `Option(2)` へと書き換えるマクロを書くことができた。このように型コンストラクタで値を包み込んだりというのは正に `build.sbt` で行っていることだ。

### 酢鶏

ケチャップという言葉は、中国南部海岸沿い福建の膎汁 (kôe-chiap もしくは kê-chiap) という言葉に由来していて魚醤という意味だ。魚醤はしばらくは醤油などの豆系調味料に駆逐されていたが、1700年代にベトナムなどから再導入された。貿易を通じて魚醤はイギリスでも流行して、輸入する代わりに生産されマッシュルームペーストへと変化した。1800年代にはアメリカ人がこれをトマトで作り出す。そういう意味では、酢豚といった広東料理がレシピにケチャップを取り入れているのは興味深いと言える。広東語では咕嚕肉 (gūlōuyuhk) と呼ばれグールーというのはお腹が鳴る音を表している。酢豚というのは日本での名前だが、これは sbt のバクロニムでもある。豚肉を鶏肉に置き換えた酢鶏 (sudori) は酢豚からの派生だ。

### まとめ

- クォートリフレクション (quote reflection) は構文木の操作を提供する
- パス依存型の一貫性を保つのは難しい。cake trait が使えるかもしれない。
- 木を歩くのには TreeMap を使う
- 型情報は `Type[T]` で表すことができ、それを型として埋め込み直すことができる
