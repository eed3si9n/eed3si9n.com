---
title:       "tree-sitter-scala 0.25.1 and 0.26.0"
type:        story
date:        2026-04-18
url:         /tree-sitter-scala-0.26.0
tags:        [ "scala" ]
---

Hi everyone. On behalf of the tree-sitter-scala project, I am happy to announce tree-sitter-scala 0.25.1 and 0.26.0. The first two segments of the version number comes from the tree-sitter-cli that was used to generate the parser, and the last segment is our actual version number. For example, tree-sitter-scala 0.26.0 uses tree-sitter 0.26.x.

### About tree-sitter-scala

tree-sitter-scala is a Scala parser in C language, generated using Tree-sitter CLI, and conforming to the Tree-sitter API. Tree-sitter parsers are generally fast, incremental, and robust (ok with partial errors). We publish Rust binding to [crates.io](https://crates.io/crates/tree-sitter-scala).

<!--more-->

Tree-sitter parsers are adopted by editors like NeoVim, Emacs, Helix, and Zed to provide language features like syntax highlight and folding and more (supposedly part of GitHub.com).

### Highlights

* feat: Leading infix operators by [@susliko] in [#493](https://github.com/tree-sitter/tree-sitter-scala/pull/493)
* feat: Supports typed lambda argument for Scala 2 by [@susliko] in [#496](https://github.com/tree-sitter/tree-sitter-scala/pull/496)
* feat: Supports access modifiers for enums by [@susliko] in [#497](https://github.com/tree-sitter/tree-sitter-scala/pull/497)
* feat: Supports lambdas in braces with block bodies by [@susliko] in [#501](https://github.com/tree-sitter/tree-sitter-scala/pull/501)
* feat: Supports `extends` clause with multiple argument lists by [@susliko] in [#502](https://github.com/tree-sitter/tree-sitter-scala/pull/502)
* feat: Aliased imports without package prefix by @susliko in [#515](https://github.com/tree-sitter/tree-sitter-scala/pull/515)
* feat: Supports dot-syntax for match expressions by [@susliko] in [#514](https://github.com/tree-sitter/tree-sitter-scala/pull/514) + [#516](https://github.com/tree-sitter/tree-sitter-scala/pull/516)

Full release notes are at <https://github.com/tree-sitter/tree-sitter-scala/releases/tag/v0.25.1> and <https://github.com/tree-sitter/tree-sitter-scala/releases/tag/v0.26.0>.

### Parsing improvements

Parsing % for Scala 2 library, Scala 2 compiler, Scala 3 compiler, and Lichess are as follows:

| tree-sitter-scala | scala-library | scalac | Dotty | Lichess |
|-------------------|---------------|--------|-------|---------|
| `0.26.0`          |     `100%`    |  `99%` | `93%` | `98%` |
| `0.25.0`          |     `100%`    |  `96%` | `83%` | `92%` |
| `0.24.0`          |     `100%`    |  `96%` | `83%` | `84%` |
| `0.23.0`          |     `100%`    |  `96%` | `83%` | `84%` |
| `0.22.0`          |     `100%`    |  `97%` | `85%` | _ |
| `0.21.0`          |     `100%`    |  `96%` | `85%` | _ |
| `0.20.2`          |     `100%`    |  `96%` | `84%` | _ |
| `0.20.1`          |     `98%`     |  `93%` | `83%` | _ |
| `0.20.0`          |     `89%`     |  `68%` | `66%` | _ |

0.25.1/0.26.0 offers significant improvement of Scala 3 parsing accuracy. For example, the support for the leading infix operator improved the Scala 3 compiler's parsing from 83% to 89%. 0.25.1/0.26.0 also hits a high watermark of Scala 2 compiler parsing at 99%.

### Participation

tree-sitter-scala 0.26.0 was brought to you by 3 contributors and a bot:

```
$ git shortlog -sn --no-merges v0.25.0...
     12  Vasili Markoukin
     6   GitHub
     3   Eugene Yokota
     1   TheBugYouCantFix
```

Thanks to everyone who's helped improve tree-sitter-scala by using them, reporting bugs, improving our documentation, and submitting and reviewing pull requests.

----

### FYI - Scala Days talk by Anton

In August 2025, Tree-Sitter Scala co-maintainer Anton Sviridov gave a Tree Sitter + multi-platform talk at Scala Days. Check out [Indoor Vivants](https://blog.indoorvivants.com/2025-11-26-video-scala-days-talk-about-tree-sitter-and-scala-3-multiplatform) for the links to code, slides, and the recording.

  [@susliko]: https://github.com/susliko
  [@eed3si9n]: https://github.com/eed3si9n
  [@amaanq]: https://github.com/amaanq
  [@hamidr]: https://github.com/hamidr
