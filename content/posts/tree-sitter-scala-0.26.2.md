---
title:       "tree-sitter-scala 0.26.2"
type:        story
date:        2026-08-08
url:         /tree-sitter-scala-0.26.2
tags:        [ "scala" ]
---

Hi everyone. On behalf of the tree-sitter-scala project, I am happy to announce tree-sitter-scala 0.26.2. The first two segments of the version number comes from the tree-sitter-cli that was used to generate the parser, and the last segment is our actual version number. For example, tree-sitter-scala 0.26.2 uses tree-sitter 0.26.x.

### About tree-sitter-scala

tree-sitter-scala is a Scala parser in C language, generated using Tree-sitter CLI, and conforming to the Tree-sitter API. Tree-sitter parsers are generally fast, incremental, and robust (ok with partial errors). We publish Rust binding to [crates.io](https://crates.io/crates/tree-sitter-scala).

<!--more-->

Tree-sitter parsers are adopted by editors like NeoVim, Emacs, Helix, Zed, and Scastie to provide language features like syntax highlight, folding, and more (supposedly part of GitHub.com).

### Highlights

* feat: Capture checking syntax by [@exoego][@exoego] in [#629](https://github.com/tree-sitter/tree-sitter-scala/pull/629)
* feat: XML literals and XML patterns by [@exoego][@exoego] in [#606](https://github.com/tree-sitter/tree-sitter-scala/pull/606)
* feat: Binary integer literals by [@exoego][@exoego] in [#608](https://github.com/tree-sitter/tree-sitter-scala/pull/608)
* feat: Wildcard in self type by [@susliko][@susliko] in [#521](https://github.com/tree-sitter/tree-sitter-scala/pull/521)
* feat: Reserved keywords by [@iigaz][@iigaz] in [#537](https://github.com/tree-sitter/tree-sitter-scala/pull/537)
* feat: Infix operator precedence and associativity per SLS 6.12.3 by [@exoego][@exoego] in [#603](https://github.com/tree-sitter/tree-sitter-scala/pull/603)
* perf: Cuts parse time by a third  by [@exoego][@exoego] in [#607](https://github.com/tree-sitter/tree-sitter-scala/pull/607)
* fix: Fixes self types with empty bodies, empty-bodied lambdas, enum self types by [@exoego][@exoego] in [#551](https://github.com/tree-sitter/tree-sitter-scala/pull/551)
* fix: Fixes soft keyword `extension` and Scala 3 keywords in import paths by [@exoego][@exoego] in [#573](https://github.com/tree-sitter/tree-sitter-scala/pull/573)

Full release notes are at <https://github.com/tree-sitter/tree-sitter-scala/releases/tag/v0.26.2>.

### Parsing improvements

Parsing % for Scala 2 library, Scala 2 compiler, Scala 3 compiler, and Lichess are as follows:

| tree-sitter-scala | scala-library | scalac | Dotty | Lichess |
|-------------------|---------------|--------|-------|---------|
| `0.26.2`          |     `100%`    | `100%` | `100%`| `100%` |
| `0.26.0`          |     `100%`    |  `99%` | `93%` | `98%` |
| `0.25.0`          |     `100%`    |  `96%` | `83%` | `92%` |
| `0.24.0`          |     `100%`    |  `96%` | `83%` | `84%` |
| `0.23.0`          |     `100%`    |  `96%` | `83%` | `84%` |
| `0.22.0`          |     `100%`    |  `97%` | `85%` | _ |
| `0.21.0`          |     `100%`    |  `96%` | `85%` | _ |
| `0.20.2`          |     `100%`    |  `96%` | `84%` | _ |
| `0.20.1`          |     `98%`     |  `93%` | `83%` | _ |
| `0.20.0`          |     `89%`     |  `68%` | `66%` | _ |

0.26.2 offers significant improvement of both Scala 2 and Scala 3 parsing accuracy. 0.26.2 parses both Scala 2 and Scala 3 compiler code bases 100%.

### Participation

tree-sitter-scala 0.26.0 was brought to you by 6 contributors:

```
$ git shortlog -sn --no-merges v0.26.0...
    79  TATSUNO “Taz” Yasuhiro
    28  GitHub
     9  Vasili Markoukin
     4  Eugene Yokota
     2  Ilnar Gazizov
     2  Vasil Markoukin
     1  orbisai0security
```

Thanks to everyone who's helped improve tree-sitter-scala by using them, reporting bugs, improving our documentation, and submitting and reviewing pull requests.

----

### FYI - Scala Days talk by Anton

In August 2025, Tree-Sitter Scala co-maintainer Anton Sviridov gave a Tree Sitter + multi-platform talk at Scala Days. Check out [Indoor Vivants](https://blog.indoorvivants.com/2025-11-26-video-scala-days-talk-about-tree-sitter-and-scala-3-multiplatform) for the links to code, slides, and the recording.

  [@susliko]: https://github.com/susliko
  [@eed3si9n]: https://github.com/eed3si9n
  [@amaanq]: https://github.com/amaanq
  [@exoego]: https://github.com/exoego
  [@iigaz]: https://github.com/iigaz
