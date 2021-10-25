---
title:       "Scala, Python quick reference"
type:        story
date:        2021-05-30
draft:       false
promote:     true
sticky:      false
url:         /scala-python-quick-reference
aliases:     [ /node/393 ]
---

| syntax                 | Scala                         | Python                        |
| ---------------------- | ----------------------------- | ----------------------------- |
| immutable variable     | `val x = 1`                   | Starlark:<br>`REV = "1.1.0"`  |
| lazy variable          | `lazy val x = 1`              | n/a                           |
| mutable variable       | `var x = 1`                   | in function:<br>`x = 1`       |
| if expression          | `if (x > 1) "a" else "b"`     | `"a" if x > 1 else "b"`       |
| ---------------------- | ----------------------------  | ---------------------------- |
| function               | `def add3(x: Int): Int =`<br><code>  x + 3</code> | `def add3(x):`<br><code>  return x + 3</code>|
| anonymous function     | `_ * 2`                       | not in Starlark:<br>`lambda x: x * 2`|
| ---------------------- | ----------------------------  | ---------------------------- |
| List                   | `val xs = List(1, 2, 3, 4)`   | `xs = [1, 2, 3, 4]`           |
| size                   | `xs.size`                     | `len(xs)`                     |
| empty test             | `xs.isEmpty`                  | `not xs`                      |
| head                   | `xs.head`                     | `xs[0]`                       |
| tail                   | `// List(2, 3, 4)`<br>`xs.tail` | `# [2, 3, 4]`<br>`xs[1:]`   |
| take                   | `// List(1, 2)`<br>`xs.take(2)` | `# [1, 2]`<br>`xs[:2]`      |
| drop                   | `// List(3, 4)`<br>`xs.drop(2)` | `# [3, 4]`<br>`xs[2:]`      |
| drop right             | `// List(1, 2, 3)`<br>`xs.dropRight(1)` | `# [1, 2, 3]`<br>`xs[:-1]` |
| nth element            | `xs(2)`                       | `xs[2]`                       |
| map                    | `xs.map(_ * 2)`<br><br>`for {`<br><code>  x <- xs</code><br>`} yield x * 2` | `map(lambda x: x * 2, xs)`<br><br>`[x * 2 for x in xs]`         |
| filter                 | `xs.filter(_ % 2 == 0)`<br><br>`for {`<br><code>  x <- xs if x % 2 == 0</code><br>`} yield x` | `filter(lambda x: not x % 2, xs)`<br><br>`[x for x in xs if not x % 2 ]` |
| fold from left         | `// "a1234"`<br>`xs.foldLeft("a") { _ + _ }` | `from functools import reduce`<br>`# "a1234"`<br>`reduce(lambda a,x: a + str(x), xs, "a")` |
| membership             | `xs.contains(3)`              | `3 in xs`                     |
| ---------------------- | ----------------------------  | ---------------------------- |
| String                 | `val s = "hello"`             | `s = "hello"`                 |
| variable interpolation | `val count = 3`<br>`s"$count items"` | not in Starlark:<br>`count = 3`<br>`f"{count} items"` |
| split                  | `// Array(1.2.3, M1)`<br>`"1.2.3-M1".split("-")` | `# ['1.2.3', 'M1']`<br>`"1.2.3-M1".split("-")` |
| substring test         | `s.contains("el")`            | `"el" in s`                   |
| ---------------------- | ----------------------------  | ---------------------------- |
| Map                    | `val d = Map("a" -> 1,`<br><code>  "b" -> 2)</code> | `d = { "a": 1, "b": 2 }`  |

- [Skylark one-page overview](https://docs.bazel.build/versions/master/skylark/lib/skylark-overview.html)
- Many of the examples were borrowed from [Hyperpolyglot: Rust, Swift, Scala](https://hyperpolyglot.org/rust)

### notes

I'm picking up Python and its Bazel dialect Skylark lately. On the other hand, I'm familiar with Scala and its sbt dialect. Often I know exactly what I want to express, and I am fairly certain Python has the equivalent concept as Scala, but just don't remember the exact incantation. For people starting Scala, maybe they could use this table in reverse.
