---
title:       "tree-sitter-scala 0.20.1"
type:        story
date:        2023-06-10
url:         /tree-sitter-scala-0.20.1
tags:        [ "scala" ]
---

Hi everyone. On behalf of the tree-sitter-scala project, I am happy to announce tree-sitter-scala 0.20.1. The first two segment of the version number comes from the tree-sitter-cli that was used to generate the parser, and the last segment is our actual version number.

### About tree-sitter-scala

tree-sitter-scala is a Scala parser in C language, generated using Tree-sitter CLI, and conforming to the Tree-sitter API. Tree-sitter parsers are generally fast, incremental, and robust (ok with partial errors).
<!--more-->

Since its initial release in 2017, Tree-sitter parsers are adopted by editors like Atom, NeoVim, Emacs, and Helix to provide language features like syntax highlight and folding and more (supposedly part of GitHub.com).

### Highlights

- A new maintainer: Vasil Markoukin (@susliko) joined as a tree-sitter-scala maintainer and contributed important fixes and enhancements
- Overall parsing % improvements in both Scala 2.x and 3.x
- Rust binding published to Crate

Full release note is at <https://github.com/tree-sitter/tree-sitter-scala/releases/tag/v0.20.1>.

### Baseline smoke test

Previously, we've added smoke test that parses the `*.scala` source for Scala 2 library, Scala 2 compiler, and Scala 3 compiler.

| tree-sitter-scala | scala-library | scalac | Dotty |
|-------------------|---------------|--------|-------|
| `0.20.0`          |     `89%`     |  `68%` | `66%` |

{{% note %}}
**Note**: We thought scala-library parsing % was `100%`, but we [found out](https://github.com/tree-sitter/tree-sitter-scala/issues/238) it wasn't parsing all the files.
{{% /note %}}

Since then we've updated smoke test to use Scala 3.3.0 code base. @sideeffffect also contributed adding the syntax complexity check against the parser generation time regression.

### Parsing improvements

Parsing % for Scala 2 library, Scala 2 compiler, and Scala 3 compiler respective are as follows.

| tree-sitter-scala | scala-library | scalac | Dotty |
|-------------------|---------------|--------|-------|
| `0.20.1`          |     `98%`     |  `93%` | `83%` |
| `0.20.0`          |     `89%`     |  `68%` | `66%` |

Here are the fixes that contributed to this jump:

* Fixes `case` clauses with guards by @susliko in [#221][221], scala-library `89%` -> `92%`, scalac `68%` -> `84%`, Dotty `66%` -> `71%`
* Scala 3: `using` clause in method arguments by @susliko in [#235][235], Dotty `71%` -> `78%`
* Fixes import of symbolic identifiers by @eed3si9n in #241, scala-library `92%` -> `93%`
* Fixes Scala 3 catch clause by @susliko in #245, Dotty `78%` -> `80%`
* Fixes type bounds by @susliko in #247, scala-library `93%` -> `94%`
* `val` definition with multiple left-hand-side identifiers by @eed3si9n in #254, scala-library `94%` -> `95%`, Dotty `81%` -> `82%`
* Structural type (refinement) by @eed3si9n in [#266][266], scalac `84%` -> `87%`
* Fixes structural type in `extends`, scalac `87%` -> `89%`
* `val` definition with multiple left-hand-side identifiers, take 2 by @susliko in #292, scala-library `95%` -> `97%`, scalac `89%` -> **`93%`**
* Fixes multi-line parameter lists by @susliko in [#295][295], scala-library `97%` -> **`98%`**, Dotty `82%` -> `83%`

### Rust and Swift bindings

tree-sitter-scala 0.20.1 is published to [crates.io](https://crates.io/crates/tree-sitter-scala/), as well as 0.20.0, which was back published. This allows easier consumption of the parser using Rust.

Swift bindings and Swift Package Manager (SPM) support were contributed by @mattmassicotte in #234.

### Parser optimization

In addition to enhancements, susliko has contributed parser optimizations as well.

* Refactors `$.compilation_unit`, optimize grammar by @susliko in [#269][269]
* Reworks lambda expression (The Gordian Knot) by @susliko in [#277][277]

The parser complexity had crept up a bit to take a few minutes, and the latter in particular, halves the maximum grammar state to 1300 and reduces the parser generation time to 10s:

```
$ time node_modules/.bin/tree-sitter generate
node_modules/.bin/tree-sitter generate  9.24s user 0.41s system 99% cpu 9.664 total
```

### Participation

tree-sitter-scala 0.20.1 was brought to you by 6 contributors and a good bot:

```
$ git shortlog -sn --no-merges v0.20.0...
    26  susliko
    21  Eugene Yokota
    12  GitHub
     6  Ondra Pelech
     1  Domas Poliakas
     1  Kasper Kondzielski
     1  Matt Massicotte
```

Thanks to everyone who's helped improve tree-sitter-scala by using them, reporting bugs, improving our documentation, and submitting and reviewing pull requests.

### Donate to Scala Center

Scala Center is a non-profit center at EPFL to support education and open source.

- https://scala.epfl.ch/donate.html

  [221]: https://github.com/tree-sitter/tree-sitter-scala/pull/221
  [235]: https://github.com/tree-sitter/tree-sitter-scala/pull/235
  [266]: https://github.com/tree-sitter/tree-sitter-scala/pull/266
  [295]: https://github.com/tree-sitter/tree-sitter-scala/pull/295
  [269]: https://github.com/tree-sitter/tree-sitter-scala/pull/295
  [277]: https://github.com/tree-sitter/tree-sitter-scala/pull/277
