---
title:       "C# LINQ for Scala heads"
type:        story
date:        2012-07-22
draft:       false
promote:     true
sticky:      false
url:         /csharp-linq-for-scala-heads
aliases:     [ /node/58 ]
---

  [1]: http://stackoverflow.com/questions/8104846/chart-of-ienumerable-linq-equivalents-in-scala/8106548#8106548

This is a memo of C# Linq features for Scala programmers. Or vice versa.

## Type inference

C# has type inference. I try to use `var` when I can for local variables.

<csharp>
var x = 1;
</csharp>

Scala also has `var`, but the preferred way is to use immutable `val` if possible.

```scala
val x = 1
```

## Creating a new List or an Array

C# can create collections in-line.

<csharp>
using System.Collections.Generic;

var list = new List<string> { "Adam", "Alice", "Bob", "Charlie" };
var array = new [] { 0, 1, 2 };
</csharp>

All collections in Scala comes with a factory method.

```scala
val list = List("Adam", "Alice", "Bob", "Charlie")
val array = Array(0, 1, 2)
```

## Filtering using lambda expression

C# has "enrich-my-library" monkey patching that adds `Where` method to a normal Array.

<csharp>
using System;
using System.Collections.Generic;
using System.Collections.Linq;

var xs = array.Where(x => x >= 1);
</csharp>

There are several ways to write this in Scala.

```scala
array.filter(x => x >= 1)
array filter { _ >= 1 }
array filter { 1 <= }
```

## Projection

Projection in C# is done by `Select` and `SelectMany`.

<csharp>
var xs = array.Select(x => x + 1);
var yx = array.SelectMany(x => new [] { x, 3 });
</csharp>

These correspond to `map` and `flatMap`.

```scala
array map { _ + 1 }
array flatMap { Array(_, 3) }
```

## Sorting

C# can sort things using `OrderBy`.

<csharp>
var xs = list.OrderBy(x => x.Length);
</csharp>

I can't remember the last time I had to sort something in Scala, but you can do that using `sortBy`.

```scala
list sortBy { _.length }
```

## Filtering using query expression

Now comes the query expression.

<csharp>
var results =
    from x in array
    where x >= 1
    select x;
</csharp>

The closest thing Scala got probably is for-comprehension.

```scala
for (x <- array if x >= 1)
  yield x
```

You can write something similar in C#, but unlike Scala `foreach` does not return a value, so the whole thing needs to be wrapped in a method.

<csharp>
static IEnumerable<int> Foo(int[] array)
{
    foreach (var x in array)
        if (x >= 1)
            yield return x;
}
</csharp>

## Projection using query expression

Let's try projection to an anonymous type in C#.

<csharp>
var results =
    from x in array
    select new { Foo = x + 1 };
</csharp>

Scala using for-comprehension.

```scala
for (x <- array)
  yield new { def foo = x + 1 }
```

## Sorting by intermediate values

Here's how to sort by intermediate values.

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

Scala's for-comprehension does not support sorting, but you can always sort things afterwards.

```scala
list sortBy { x =>
  val cs = """[aeiou]""".r.replaceAllIn(x.toLowerCase, "")
  cs.length
}
```

## Cross join

The SQL-ness comes in handy when you join with C#.

<csharp>
var results =
    from x in list
    from c in x.ToCharArray()
    where c != 'a' && c != 'e'
    select c;
</csharp>

Using Scala for-comprehension.

```scala
for {
  x <- list
  c <- x.toCharArray
  if c != 'a' && c != 'e'
} yield c
```

## Inner join

Inner joining using C#.

<csharp>
var results =
    from name in list
    join n in array on name.Length equals n + 3
    select new { name, n };
</csharp>

Using Scala for-comprehension.

```scala
for {
  name <- list
  n <- array if name.length == n + 3
} yield (name, n)
```

## Grouping

Grouping using C#.

<csharp>
var results =
    from x in list
    group x by x[0] into g
    where g.Count() > 1
    select g;
</csharp>

Not for-comprehension, but still doable in Scala.

```scala
list groupBy { _(0) } filter { case (k, vs) =>
  vs.size > 1 }
```

## Quantifiers

Quantifiers work more or less the same way.

<csharp>
var hasThree = list.Any(x => x.Length == 3)
var allThree = list.All(x => x.Length == 3)
</csharp>

In Scala.

```scala
val hasThree = list exists { _.length == 3 }
val allThree = list forall { _.length == 3 }
```

## Pattern matching

One unique aspect of Scala is that it accepts a partial function where a lambda expression is expected.

```scala
array map {
  case 1 => "foo"
  case n if n % 2 == 0 => n.toString + "!"
}
```

You probably have to throw an exception to mimic this in C#.

## Notes

For Scala I prefer normal calls to `filter` and `map` over for-comprehension. Infix operator syntax and placeholder syntax makes `array filter { _ >= 1 }` concise enough that for-comprehension ends up becoming more bulkier unless they are nested.

On the other hand in C#, query expression syntax rids of some of the symbols (`.`, `()`, `=>`) from fluent syntax.

Rahul (@missingfaktor) wrote a nice [list of Enumerable methods and their equivalent ones in Scala][1], which covers everything I couoldn't here.
