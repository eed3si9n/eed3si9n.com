---
title:       "Scala脳のための C# LINQ"
type:        story
date:        2012-07-22
draft:       false
promote:     true
sticky:      false
url:         /csharp-linq-for-scala-heads
aliases:     [ /node/59 ]
---

  [1]: http://stackoverflow.com/questions/8104846/chart-of-ienumerable-linq-equivalents-in-scala/8106548#8106548

これは Scala プログラマのための C# LINQ 機能の覚え書きだが、逆としても使えるはず。

## 型推論

C# には型推論がある。個人的に、ローカル変数ではできるだけ `var` を使うようにしている。

<csharp>
var x = 1;
</csharp>

Scala にも `var` があるけど、可能なら不変 (immutable) な `val` を使うのが好ましいとされている。

```scala
val x = 1
```

## 新しい List と Array の作成

C# はインラインでコレクションを作ることができる。

<csharp>
using System.Collections.Generic;

var list = new List<string> { "Adam", "Alice", "Bob", "Charlie" };
var array = new [] { 0, 1, 2 };
</csharp>

全ての Scala コレクションにファクトリメソッドがある。

```scala
val list = List("Adam", "Alice", "Bob", "Charlie")
val array = Array(0, 1, 2)
```

## ラムダ式を使ったフィルタ

C# には "enrich-my-library" 的なモンキーパッチングがあり、普通の Array に `Where` メソッドが追加されている。

<csharp>
using System;
using System.Collections.Generic;
using System.Collections.Linq;

var xs = array.Where(x => x >= 1);
</csharp>

これは Scala では何通りかの書き方がある。

```scala
array.filter(x => x >= 1)
array filter { _ >= 1 }
array filter { 1 <= }
```

## 投射

C# での投射は `Select` と `SelectMany` によって行われる。

<csharp>
var xs = array.Select(x => x + 1);
var yx = array.SelectMany(x => new [] { x, 3 });
</csharp>

これは `map` と `flatMap` に対応する。

```scala
array map { _ + 1 }
array flatMap { Array(_, 3) }
```

## ソート

C# は `OrderBy` を使ってソートすることができる。

<csharp>
var xs = list.OrderBy(x => x.Length);
</csharp>

Scala で何かをソートする必要があったことが思い出せないけど、`sortBy` を使えばできる。

```scala
list sortBy { _.length }
```

## クエリ式を使ったフィルタ

いよいよクエリ式 (query expression) の登場。

<csharp>
var results =
    from x in array
    where x >= 1
    select x;
</csharp>

Scala でこれに近いものだと多分 for 内包表記 (for comprehension) だと思う。

```scala
for (x <- array if x >= 1)
  yield x
```

これに似たようなものも C# で書けるんだけど、Scala と違って `foreach` が値を返さないから、まるごとメソッドでラッピングする必要がある。

<csharp>
static IEnumerable<int> Foo(int[] array)
{
    foreach (var x in array)
        if (x >= 1)
            yield return x;
}
</csharp>

## クエリ式を使った投射

暗黙型 (anonymous type) への投射を C# で試そう。

<csharp>
var results =
    from x in array
    select new { Foo = x + 1 };
</csharp>

Scala は for 内包表記で。

```scala
for (x <- array)
  yield new { def foo = x + 1 }
```

## 中間値によるソート

中間値を用いてソートする。

<csharp>
using System;
using System.Collections.Generic;
using System.Collections.Linq;
using System.Text.RegularExpression;

var results =
    from x in list
    let cs = new Regex(@"[aeiou]").Replace(x.ToLower(), "")
    orderby cs.Length
    select x;
</csharp>

Scala の for 内包表記ではソートできないけど、後付けでソートできる。

```scala
list sortBy { x =>
  val cs = """[aeiou]""".r.replaceAllIn(x.toLowerCase, "")
  cs.length
}
```

## クロスジョイン

この SQLっぽさは C# でジョインで便利になってくる。

<csharp>
var results =
    from x in list
    from c in x.ToCharArray()
    where c != 'a' && c != 'e'
    select c;
</csharp>

Scala は for 内包表記で。

```scala
for {
  x <- list
  c <- x.toCharArray
  if c != 'a' && c != 'e'
} yield c
```

## インナージョイン

C# でのインナージョイン。

<csharp>
var results =
    from name in list
    join n in array on name.Length equals n + 3
    select new { name, n };
</csharp>

Scala は for 内包表記で。

```scala
for {
  name <- list
  n <- array if name.length == n + 3
} yield (name, n)
```

## グループ化

C# でのグループ化。

<csharp>
var results =
    from x in list
    group x by x[0] into g
    where g.Count() > 1
    select g;
</csharp>

for 内包表記じゃないけど、Scala でも可能。

```scala
list groupBy { _(0) } filter { case (k, vs) =>
  vs.size > 1 }
```

## 限定子

限定子 (quantifier) はだいたい同じように動作する。

<csharp>
var hasThree = list.Any(x => x.Length == 3)
var allThree = list.All(x => x.Length == 3)
</csharp>

Scala では。

```scala
val hasThree = list exists { _.length == 3 }
val allThree = list forall { _.length == 3 }
```

## パターンマッチング

Scala に特徴的なのはラムダ式が期待されている所に部分関数 (partial function) を渡すことができることだ。

```scala
array map {
  case 1 => "foo"
  case n if n % 2 == 0 => n.toString + "!"
}
```

C# でこれを真似するには自分で例外を投げる必要があると思う。

## 感想

Scala では、for 内包表記よりも普通の `filter` とか `map` を呼び出すのが好みだ。演算子の中置記法とプレースホルダ構文のお陰で `array filter { _ >= 1 }` が十分簡潔になってるから、入れ子で使わない限りは for 内包表記の方が見た目が大きくなっている。

一方 C# は、クエリ式の構文はメソッド構文からいくつかのシンボルを (`.`, `()`, `=>`) を取り除いている。

ここで書ききれなかったことの全ては、Rahul (@missingfaktor) が [Enumerable のメソッドとそれに対応する Scala のコード][1]という形でまとめている。
