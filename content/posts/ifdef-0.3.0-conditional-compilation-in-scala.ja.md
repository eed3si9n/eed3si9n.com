---
title:       "ifdef 0.3.0: Scala における条件付きコンパイル"
type:        story
date:        2024-07-20
url:         /ja/ifdef-0.3.0-conditional-compilation-in-scala
tags:        [ "scala" ]
---

  [@eed3si9n]: https://github.com/eed3si9n
  [@uosis]: https://github.com/uosis
  [sip-nn-conditional]: https://github.com/scala/docs.scala-lang/pull/1541/files?short_path=0952117#diff-0952117606ef631d9a0a01c4190bc8878ca024d270a9dd519350d038a3290cc1

`@ifdef` は Scala コンパイラ・プラグインで、Scala 言語における条件付きコンパイルを実装する。ifdef 0.3.0 では Scala.JS と Scala Native のサポートを追加した。

| Scala Version | JVM | JS (1.x) |  Native (0.5.x) |
| ------------- | :-: | :------: | :---------: |
| 3.x           | ✅  |   ✅     |    ✅     |
| 2.13.x        | ✅  |   ✅     |     ✅      |
| 2.12.x        | ✅  |   ✅     |     ✅      |

<!--more-->

### セットアップ

`project/plugins.sbt` に以下を追加する:

```scala
addSbtPlugin("com.eed3si9n.ifdef" % "sbt-ifdef" % "0.3.0")
```

ソースは https://github.com/eed3si9n/ifdef 参照。

## 条件付きコンパイル

Rust 言語は[**条件付きソースコード**](https://doc.rust-lang.org/reference/conditional-compilation.html)を以下のように定義する:

> 特定の条件によりソースコード全体の一部に含まれたり含まれなかったりするコード

`ifDefDeclaration` は、名前もしくはキーと値のペアで、宣言されているかされていないかで条件を制御する。sbt-ifdef 0.3.0 は 2つの宣言を組み込みで提供する:

1. ビルドのコンフィギュレーション名: `compile`、`test`
2. scalaBinaryVersion: `scalaBinaryVersion:3`

このあたりは想像をはたらかせて、旧来はクロスビルドが必要だったほかの軸などにも試してみてほしい。

### ソース内単体テスト

Rust 言語での条件付きコンパイルの使われ方の 1つとして、ライブラリコード内に単体テストを埋め込むというものがある:

```scala
package example

import com.eed3si9n.ifdef.ifdef

class A:
  def foo: Int = 42
end A

@ifdef("test")
class ATest extends munit.FunSuite:
  test("foo"):
    val actual = new A().foo
    val expected = 42
    assertEquals(actual, expected)
end ATest
```

単体テストの多くは、別のソースよりもこのように埋め込んだ方が見通しが良くなると思う。

### Scala クロス・ビルド

`@ifdef` と `@ifndef` を使った `scalaBinaryVersion` の例を見てみる:

```scala
package example

import com.eed3si9n.ifdef.{ ifdef, ifndef }
import java.util.{ Map => JMap }

class A {
  @ifdef("scalaBinaryVersion:2.12")
  def convertMapToScala[K, V](jmap: JMap[K, V]): Map[K, V] = {
    // -Xsource:3 を使うことで Scala 2.12 からも * を使える。ナイス
    import scala.collection.JavaConverters.*
    Map.empty ++ jmap.asScala
  }

  @ifndef("scalaBinaryVersion:2.12")
  def convertMapToScala[K, V](jmap: JMap[K, V]): Map[K, V] = {
    import scala.jdk.CollectionConverters.*
    Map.empty.concat(jmap.asScala)
  }
}
```

上の例は実は Stefan Zeiger さんが、[SIP-NN Language support for conditional compilation][sip-nn-conditional] (現在は閉じてる) で条件付きコンパイルの提案を行ったときに引用したものと同じ例だ。この例は `@ifdef` と `@ifndef` が、**タイパー** (typer) フェーズ以前に処理していることをデモしている。なぜなら、Scala 2.12 は `scala.jdk.CollectionConverters.*` のことを知らないので、普通のコンパイルだとここで失敗するからだ。

## 0.3.0 から入ったもの

- Scala.JS サポート by [@uosis][@uosis] in [#2](https://github.com/eed3si9n/ifdef/pull/2)
- Scala Native サポート by [@eed3si9n][@eed3si9n] in [#3](https://github.com/eed3si9n/ifdef/pull/3)
- 重複する `scalacOptions` の修正 by [@eed3si9n][@eed3si9n] in [#4](https://github.com/eed3si9n/ifdef/pull/4)

### 参照

- [ifdef in Scala via pre-typer processing](/ifdef-in-scala-via-pre-typer-processing) (ifdef 0.2.0)
- [ifdef macro in Scala](/ifdef-macro-in-scala) (ifdef 0.1.0)
