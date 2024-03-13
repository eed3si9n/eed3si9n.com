---
title:       "tree-sitter-scala 0.21.0"
type:        story
date:        2024-03-13
url:         /tree-sitter-scala-0.21.0
tags:        [ "scala" ]
---

Hi everyone. On behalf of the tree-sitter-scala project, I am happy to announce tree-sitter-scala 0.20.3 and 0.21.0. The first two segments of the version number comes from the tree-sitter-cli that was used to generate the parser, and the last segment is our actual version number.

tree-sitter-scala 0.21.0 uses tree-sitter 0.21.x; and tree-sitter-scala 0.20.3 uses tree-sitter 0.20.x.

### About tree-sitter-scala

tree-sitter-scala is a Scala parser in C language, generated using Tree-sitter CLI, and conforming to the Tree-sitter API. Tree-sitter parsers are generally fast, incremental, and robust (ok with partial errors). We publish Rust binding to [crates.io](https://crates.io/crates/tree-sitter-scala).

<!--more-->

Since its initial release in 2017, Tree-sitter parsers are adopted by editors like NeoVim, Emacs, Helix, and Atom to provide language features like syntax highlight and folding and more (supposedly part of GitHub.com).

### Highlights

- Overall some parsing % improvements in Scala 3.x
- Scala 3: Abstract givens suppoprt by [@susliko][@susliko] in [#372][372]
- Supports shebang `#!` header by [@antosha417][@antosha417] in [#363][363]
- Fixes crashes in markdown by [@susliko][@susliko] in [#368][368]
- Fixes anonymous `given`s by [@eed3si9n][@eed3si9n] in [#341][341]

Full release notes are at <https://github.com/tree-sitter/tree-sitter-scala/releases/tag/v0.20.3> and <https://github.com/tree-sitter/tree-sitter-scala/releases/tag/v0.21.0>.

### Parsing improvements

Parsing % for Scala 2 library, Scala 2 compiler, and Scala 3 compiler are as follows:

| tree-sitter-scala | scala-library | scalac | Dotty |
|-------------------|---------------|--------|-------|
| `0.21.0`          |     `100%`    |  `96%` | `85%` |
| `0.20.2`          |     `100%`    |  `96%` | `84%` |
| `0.20.1`          |     `98%`     |  `93%` | `83%` |
| `0.20.0`          |     `89%`     |  `68%` | `66%` |

### Participation

tree-sitter-scala 0.20.2 was brought to you by 5 contributors and two good bots:

```
$ git shortlog -sn --no-merges v0.20.2...
    11  susliko
    10  Eugene Yokota
    10  GitHub
     2  Vasili Markoukin
     1  antosha417
     1  dependabot[bot]
     1  Amaan Qureshi
```

Thanks to everyone who's helped improve tree-sitter-scala by using them, reporting bugs, improving our documentation, and submitting and reviewing pull requests.

----

### Donate to Scala Center

Scala Center is a non-profit center at EPFL to support education and open source.

- https://scala.epfl.ch/donate.html

  [372]: https://github.com/tree-sitter/tree-sitter-scala/pull/372
  [363]: https://github.com/tree-sitter/tree-sitter-scala/pull/363
  [341]: https://github.com/tree-sitter/tree-sitter-scala/pull/341
  [368]: https://github.com/tree-sitter/tree-sitter-scala/pull/368
  [@susliko]: https://github.com/susliko
  [@eed3si9n]: https://github.com/eed3si9n
  [@antosha417]: https://github.com/antosha417
