---
title: "Scala 3 の差分コンパイル"
date: 2025-10-12
type: story
url:  /ja/incremental-compilation-of-scala3
tags: [ "scala" ]
---

  [23852]: https://github.com/scala/scala3/issues/23852
  [analysis]: https://www.youtube.com/watch?v=h8ACmUHQ2jg
  [24171]: https://github.com/scala/scala3/pull/24171

本稿では Scala 3 の差分コンパイルと、関連する問題についてみていく。Scala 2.12 と 2.13 の差分コンパイルはある程度安定していると思うが、僕の使っている感覚だと Scala 3 は壊れやすい気がする。この原因を調査して、修正案を [scala/scala3#24171][24171] として送ろうと思う。

<!--more-->

### Scala 2.13 におけるマクロ

比較実験として、まずは Scala 2.13 のマクロを見ていく。
以下は、`Provider.foo(...)` という名前の def マクロで、引数が `0` リテラルならば `0` を返し、非ゼロの場合は、引数を `Core.core(arg)` に渡す:

```scala
package example

import scala.language.experimental.macros
import scala.reflect.macros.blackbox.Context

object Provider {
  def foo(arg: Int): Int = macro fooImpl
  def fooImpl(c: Context)(arg: c.Tree): c.Tree = {
    import c.universe._
    arg match {
      case q"0"  => q"0"
      case q"$a" => q"""Core.core($a)"""
    }
  }
}
```

`Core` はこのようになっている:

```scala
package example

object Core {
  def core(arg: Int): Int = arg + 1
}
```

別のサブプロジェクトから、マクロを以下のように使用することができる:

```scala
package example

object Use {
  val x = Provider.foo(1)
}
```

これらは普通にコンパイルするはずだ。

![inc1](/images/inc1.svg)


次に、`Core` を以下のように変更して、関数を壊してみる:

```scala
object Core {
  def core(arg: String): Int = arg.toInt + 1
}
```

sbt シェル上から `compile` と打ち込むと、(**期待通り**) コンパイルは失敗する:

```scala
[error] macro/usesite/Use.scala:4:24: type mismatch;
[error]  found   : Int(1)
[error]  required: String
[error]   val x = Provider.foo(1)
[error]                        ^
[error] one error found
[error] (usesite / Compile / compileIncremental) Compilation failed
```

![inc2](/images/inc2.svg)

これは、蛇口から水が出てくるかのように何の変哲も無いことのように見えるが、よく考えてみると Zinc は、`Provider.foo(1)` が `Core.core` に対して人工的な関数呼出しを以前にしていて、その関数シグネチャが変更されたために `object Use` が再コンパイルが必要であるということを検知したわけだから、些細ではない事が行われている。

### Scala 3.7.3 におけるマクロ

Scala 3.x の差分コンパイルは、Scala 2.x 系では中々見ない `NoSuchMethodError` を投げたりして、より脆い気がする。これに関していくつかのバグ報告が上がっているが、最近だと scala/scala3 に OlegYch さんが [Macro usage is not invalidated #23852][23852] を報告した。このバグレポートは、マクロ処理が関連していることを示唆する。

表層上では、報告されたバグと前述のマクロの例は似た構造を持つ。`Core` の代わりに、Oleg さんは `Dep` という名前のクラスを変更した:

```scala
// before
class Dep()

// after
class Dep(dep1: Dep1)
```

Scala 3.7.3 を使った場合、この変更は以下の使用サイトを**非有効化しない**:

```scala
import com.softwaremill.macwire.*

object Use extends App {
  try {
    val d = wire[Dep]
    val d1 = wire[Dep1]
    val d2 = wire[Dep2]
  } catch {
    case e: Throwable =>
      e.printStackTrace()
      sys.exit(-1)
  }
}
```

つまり、差分コンパイルは**間違えて成功する**。これを under-compilation と呼ぶ。これは実行時エラーを発生させる:

```scala
[error] java.lang.NoSuchMethodError: Dep: method <init>()V not found
[error]   at Use$.<clinit>(Use.scala:12)
[error]   at Use.main(Use.scala)
```

`Dep` が壊れたことをコンパイル時に検知することが期待されるが、実行時エラーになってしまった。このマクロは SoftwareMill社の MacWire を使っていて単純なマクロ例とは変わっているが、同じ `scripted` テストを Scala 2.13.17 で走らせた場合にはこの問題は起きない。

### Zinc のカスタムフェーズ

Scala 2.13 と Scala 3.x の違いはどこから来ているのだろうか?
Scala 3.x は全く異なるメタプログラミング機構を持っている他に、Scala 3.x は独自の _compiler bridge_ 実装を持つ。compiler bridge とは、Zinc と Scala コンパイラのアダプテーション・レイヤーで、その機能の一部として、差分コンパイルに必要なカスタムフェーズの注入を行う。

この問題を修正する目的としては、差分コンパイルの詳細を完全に理解する必要は無いが、(`Use` のような) 使用サイトから (`Core` や `Dep` のような) 生成されたコードのメンバ参照を登録する必要があるというのは重要な事項だ。より詳しい差分コンパイルの解説は [Analysis of Zinc][analysis] などを参照。

Scala 2.13 では、Zinc は `xsbt-dependency` フェーズを `xsbti-api` フェーズの後に注入し、`xsbti-api` は Typer の後に置かれる。Scala 2.13 ではマクロ展開は Typer フェーズの一部として実行される。そのため、Scala 2.13 では Zinc はマクロ展開後のコードを見ることができる。

Scala 3 チームは compiler bridge を scala/scala3 に取り込んだため、Scala 2.12 と違って compiler bridge は Maven Central にバイナリとして公開されている。これは、一見理にかなっているが、新しいバージョンの Scala 3 をリリースしないと差分コンパイルに関する修正ができないという欠点もある。[Compiler.scala](https://github.com/scala/scala3/blob/3.7.3/compiler/src/dotty/tools/dotc/Compiler.scala) によると、Scala 3 は `sbt-deps` を Typer の後に置く。しかし、Scala 3 ではインライン展開とマクロ展開をかなり後のフェーズで行う。そのため、依存性追跡をしている段階では Scala 3 コンパイラはクォートされたコードは見えるかもしれないが、マクロ展開後の生の構文木は見えない。これで差分コンパイルの不正確さを説明できるかもしれない。

### sbt-deps フェーズの修正

修正の方針としては、以下の2つのことを行うべきだ:

1. `sbt-deps` をインラインフェーズより後に注入する
2. `Inlined(...)` ノードを走査する

最初のは簡単だ:

```diff
--- a/compiler/src/dotty/tools/dotc/Compiler.scala
+++ b/compiler/src/dotty/tools/dotc/Compiler.scala
@@ -48,6 +47,7 @@ class Compiler {
     ....
     List(new Inlining) ::           // Inline and execute macros
+    List(new sbt.ExtractDependencies) :: // Sends information on classes' dependencies to sbt via callbacks
```

二番目も実は難しくない:

```diff
--- a/compiler/src/dotty/tools/dotc/sbt/ExtractDependencies.scala
+++ b/compiler/src/dotty/tools/dotc/sbt/ExtractDependencies.scala
@@ -227,10 +227,12 @@ private class ExtractDependenciesCollector(rec: DependencyRecorder) extends tpd.
     }

     tree match {
-      case tree: Inlined if !tree.inlinedFromOuterScope =>
+      case tree: Inlined =>
         // The inlined call is normally ignored by TreeTraverser but we need to
         // record it as a dependency
-        traverse(tree.call)
+        if !tree.inlinedFromOuterScope then
+          traverse(tree.call)
+        traverseChildren(tree)
```

`Dep` クラスのコンストラクタが捕捉されたかを `print(...)` デバックをすることで確認することができる:

```scala
traverse(Select(New(TypeTree[TypeRef(ThisType(TypeRef(NoPrefix,module class <empty>)),class Dep)]),<init>))
```

`Select(...)` はメンバ参照木であるため、Zinc に登録されるはずだ。`scala3-sbt-bridge-bootstrapped/publishLocalBin` その他をローカル環境で公開して、Oleg さんのテストを Scala 3.7.4-RC1-bin-SNAPSHOT を使って実行することで修正を確認できる:

```scala
[info] [error] -- Error: /private/var/.../Components.scala:5:16
[info] [error] 5 |    val d = wire[Dep]
[info] [error]   |            ^^^^^^^^^
[info] [error]   |            Cannot find a value of type: [Dep1]
[info] [warn] two warnings found
[info] [error] one error found
[info] [error] (Compile / compileIncremental) Compilation failed
```

これは、使用サイトが正しく非有効化され、コンパイルが (期待通り) 失敗したことを示す。

### まとめ

Zinc が差分コンパイルを行うには、Scala のシンボル同士のメンバ参照依存関係を追跡する必要がある。
特にマクロが出てくる場面において Scala 3 での差分コンパイルは退行してしまったようにみえる。これは、Scala 3 コンパイラが依存性追跡をマクロ展開前に行っていることに起因するかもしれない。

本稿で解説した変更は [scala/scala3#24171][24171] として送ったが、コンパイラに取り込まれるには他にも細かい調整が必要になると思う。このプルリクを送った後で、Jan Chyb さんも別の [scala/scala3#23900](https://github.com/scala/scala3/pull/23900) を送っていたことに気づいた。
