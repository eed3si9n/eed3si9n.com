treehugger はコードを用いて Scala のソースコードを書くためのライブラリだ。それはまた、Refelection API に基づく Scala AST の代替実装の一つでもあり、github で [eed3si9n/treehugger](https://github.com/eed3si9n/treehugger) として公開している。まだ実験だ段階だけど、一区切りをつけるために何か書いてみることにした。

### 背景

コードを生成するコードを書くのは楽しいけれども、String を数珠つなぎにしたコードを書くのは楽しくない。そう思っていた所ちょくちょく Reflection API を用いて生のコードを AST (abstract syntax tree) に lift するコード例を見かけるようになった:

    scala> scala.reflect.Code.lift((x: Int) => x + 1).tree
    res0: scala.reflect.Tree = Function(List(LocalValue(NoSymbol,x,PrefixedType(ThisType(Class(scala)),Class(scala.Int)))),Apply(Select(Ident(LocalValue(NoSymbol,x,PrefixedType(ThisType(Class(scala)),Class(scala.Int)))),Method(scala.Int.$plus,MethodType(List(LocalValue(NoSymbol,x,PrefixedType(ThisType(Class(scala)),Class(scala.Int)))),PrefixedType(ThisType(Class(scala)),Class(scala.Int))))),List(Literal(1))))

考えてみれば、コンパイラよりも Scala の構文に詳しいものがあるわけないよね? とにかく、AST の実装を得るのに最適なものであるかのように思えた。

が、第一の関門は Reflection API そのものが完成していないことだ。これは 2.10 で入るものだからだ。あと、僕が欲しいのは 複数の Scala バージョンで動作するものであってコンパイラに依存したくはない。

第二の関門は、reflection の API だけあって、Scala コードの視点が少し scalac がランタイムに保持する情報よりに偏っているという問題だ。具体的には、`for` 式という概念が無かったりする。コンパイラは、ぱっぱと `map`/`flatMap`/`foreach` のどれかに展開して流してしまっている。

前途多難だけれども、Reflection API には魅力的な点も多い。第一に、コード生成という用途に限れば難しい仕事の大部分は完成していることだ。例えば、`TreePrinter` という名前の Cake パターンモジュールがあって、AST をソースコードの形式で表示できたりする。また、`TreeDSL` というコード上から AST を作るためのものまで入っている。第二に、scalac の実装と似たようなコードを使えば、既に scalac のコードに慣れている人は覚えることが少ないという利点もある。

こうして生まれたのが treehugger だ。借りてきた scalac のソースのつぎはぎで作られたプログラムはコードにおけるフランケンシュタインのクリーチャーのようなものだといえる。

## DSL

treehugger DSL は scalac の `TreeDSL` の拡張版だ。具体例を見ていこう:

### Hello world

<scala>
lazy val universe = new treehugger.Universe
import universe._
import definitions._
import CODE._
import Flags.{PRIVATE, ABSTRACT, IMPLICIT}

object sym {
  val println = ScalaPackageClass.newMethod("println")
}

val tree = sym.println APPLY LIT("Hello, world!")
val s = treeToString(tree)
println(s)
</scala>

上記は以下を表示する:

<scala>
println("Hello, world!")
</scala>

セットアップの部分を取り除くと、AST の部分は以下に要約できる:

<scala>
sym.println APPLY LIT("Hello, world!")
</scala>

これは、以下のような case class 構造を作りだす:

<scala>
Apply(Ident(println),List(Literal(Constant(Hello, world!))))
</scala>

これよりセットアップのコードは省略する。

### メソッド宣言

<scala>
DEF("hello", UnitClass) := BLOCK(
  sym.println APPLY LIT("Hello, world!"))
</scala>

上記は以下を表示する:

<scala>
def hello() {
  println("Hello, world!")
}
</scala>

### for 式と中置適用

for 式と中置適用は scalac の tree には一切入っていなかったので、勝手に付け加えた:

<scala>
val greetStrings = RootClass.newValue("greetStrings")
FOR(VALFROM("i") := LIT(0) INFIX (sym.to, LIT(2))) DO
  (sym.print APPLY (greetStrings APPLY REF("i")))
</scala>

上記は以下を表示する:

<scala>
for (i <- 0 to 2)
  print(greetStrings(i))
</scala>

### クラス、トレイト、オブジェクト、パッケージ

クラス、トレイト、オブジェクト、パッケージの宣言は、treehugger DSL で新たに加わった:

<scala>
val IntQueue: ClassSymbol = RootClass.newClass("IntQueue".toTypeName)

CLASSDEF(IntQueue) withFlags(ABSTRACT) := BLOCK(
  DEF("get", IntClass).empty,
  DEF("put", UnitClass) withParams(VAL("x", IntClass).empty) empty
)
</scala>

上記は、抽象クラスの宣言の一例で、以下のように表示される:

<scala>
abstract class IntQueue {
  def get(): Int
  def put(x: Int): Unit
}
</scala>

### パターンマッチング

パターンマッチングは、(`UNAPPLY` と `INFIXUNAPPLY` 以外は) だいたいもとの DSL に入っていた:

<scala>
val maxListUpBound = RootClass.newMethod("maxListUpBound")
val T = maxListUpBound.newTypeParameter("T".toTypeName)
val upperboundT = TypeBounds.upper(orderedType(T.toType))

DEF(maxListUpBound.name, T)
    withTypeParams(TypeDef(T, TypeTree(upperboundT))) withParams(VAL("elements", listType(T.toType)).empty) :=
  REF("elements") MATCH(
    CASE(ListClass UNAPPLY()) ==> THROW(IllegalArgumentExceptionClass, "empty list!"),
    CASE(ListClass UNAPPLY(ID("x"))) ==> REF("x"),
    CASE(ID("x") INFIXUNAPPLY("::", ID("rest"))) ==> BLOCK(
      VAL("maxRest") := maxListUpBound APPLY(REF("rest")),
      IF(REF("x") INFIX (">", REF("maxRest"))) THEN REF("x")
      ELSE REF("maxRest") 
    )
  )
</scala>

上記は以下を表示する:

<scala>
def maxListUpBound[T <: Ordered[T]](elements: List[T]): T =
  elements match {
    case List() => throw new IllegalArgumentException("empty list!")
    case List(x) => x
    case x :: rest => {
      val maxRest = maxListUpBound(rest)
      if (x > maxRest) x
      else maxRest
    }
  }
</scala>

### さらに...

他にも [TreePrinterSpec](https://github.com/eed3si9n/treehugger/blob/master/src/test/scala/TreePrinterSpec.scala) に色々使い方の例がある。
