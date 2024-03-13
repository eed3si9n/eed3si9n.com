---
title:       "tree-sitter-scala 0.20.2"
type:        story
date:        2023-08-20
url:         /tree-sitter-scala-0.20.2
tags:        [ "scala" ]
---

Hi everyone. On behalf of the tree-sitter-scala project, I am happy to announce tree-sitter-scala 0.20.2. The first two segments of the version number comes from the tree-sitter-cli that was used to generate the parser, and the last segment is our actual version number.

### About tree-sitter-scala

tree-sitter-scala is a Scala parser in C language, generated using Tree-sitter CLI, and conforming to the Tree-sitter API. Tree-sitter parsers are generally fast, incremental, and robust (ok with partial errors).
<!--more-->

Since its initial release in 2017, Tree-sitter parsers are adopted by editors like Atom, NeoVim, Emacs, and Helix to provide language features like syntax highlight and folding and more (supposedly part of GitHub.com).

### Highlights

- Overall parsing % improvements in both Scala 2.x and 3.x
- Scala 3: Type Lambda support by [@KaranAhlawat][@KaranAhlawat] in [#312][312]
- Scala 3: Given pattern support by [@susliko][@susliko] in [#330][330]
- Scala 2 macros support by [@eed3si9n][@eed3si9n] in [#325][325]

Full release note is at <https://github.com/tree-sitter/tree-sitter-scala/releases/tag/v0.20.2>.

### Parsing improvements

Parsing % for Scala 2 library, Scala 2 compiler, and Scala 3 compiler respective are as follows.

| tree-sitter-scala | scala-library | scalac | Dotty |
|-------------------|---------------|--------|-------|
| `0.20.2`          |     `100%`    |  `96%` | `84%` |
| `0.20.1`          |     `98%`     |  `93%` | `83%` |
| `0.20.0`          |     `89%`     |  `68%` | `66%` |

### Participation

tree-sitter-scala 0.20.2 was brought to you by 9 contributors and a good bot:

```
$ git shortlog -sn --no-merges v0.20.1...
     9  GitHub
     7  Johannes Coetzee
     6  susliko
     3  Natsu Kagami
     2  Max Smirnov
     2  Karan Ahlawat
     1  Amaan Qureshi
     1  Vasil Markoukin
     1  s.bazarsadaev
     1  Eugene Yokota
```

Thanks to everyone who's helped improve tree-sitter-scala by using them, reporting bugs, improving our documentation, and submitting and reviewing pull requests.

----

### Donate to Scala Center

Scala Center is a non-profit center at EPFL to support education and open source.

- https://scala.epfl.ch/donate.html


  [312]: https://github.com/tree-sitter/tree-sitter-scala/pull/312
  [330]: https://github.com/tree-sitter/tree-sitter-scala/pull/330
  [325]: https://github.com/tree-sitter/tree-sitter-scala/pull/325
  [@KaranAhlawat]: https://github.com/KaranAhlawat
  [@susliko]: https://github.com/susliko
  [@eed3si9n]: https://github.com/eed3si9n
