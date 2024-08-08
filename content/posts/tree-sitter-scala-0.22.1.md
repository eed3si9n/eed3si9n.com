---
title:       "tree-sitter-scala 0.22.1"
type:        story
date:        2024-08-08
url:         /tree-sitter-scala-0.22.1
tags:        [ "scala" ]
---

Hi everyone. On behalf of the tree-sitter-scala project, I am happy to announce tree-sitter-scala 0.22.1. The first two segments of the version number comes from the tree-sitter-cli that was used to generate the parser, and the last segment is our actual version number. tree-sitter-scala 0.22.0 uses tree-sitter 0.22.x.

### About tree-sitter-scala

tree-sitter-scala is a Scala parser in C language, generated using Tree-sitter CLI, and conforming to the Tree-sitter API. Tree-sitter parsers are generally fast, incremental, and robust (ok with partial errors). We publish Rust binding to [crates.io](https://crates.io/crates/tree-sitter-scala).

<!--more-->

Since its initial release in 2017, Tree-sitter parsers are adopted by editors like NeoVim, Emacs, Helix, Zed, and Atom to provide language features like syntax highlight and folding and more.

### Highlights

- Fixes literal types to be an operand of an infix type by [@susliko][@susliko] in [#409](https://github.com/tree-sitter/tree-sitter-scala/pull/409)
- tree-sitter-scala 0.22.1 is published to [NPM](https://www.npmjs.com/package/tree-sitter-scala) in addition to [crates.io](https://crates.io/crates/tree-sitter-scala) by [@amaanq][@amaanq] in [#408](https://github.com/tree-sitter/tree-sitter-scala/pull/408)

Full release notes are at <https://github.com/tree-sitter/tree-sitter-scala/releases/tag/v0.22.1>.

### Participation

tree-sitter-scala 0.22.1 was brought to you by 3 contributors and a bot:

```
$ git shortlog -sn --no-merges v0.22.0...
     8  Eugene Yokota
     2  Amaan Qureshi
     1  GitHub
     1  Vasili Markoukin
```

Thanks to everyone who's helped improve tree-sitter-scala by using them, reporting bugs, improving our documentation, and submitting and reviewing pull requests.

----

### Donate to Scala Center

Scala Center is a non-profit center at EPFL to support education and open source.

- https://scala.epfl.ch/donate.html

  [@susliko]: https://github.com/susliko
  [@eed3si9n]: https://github.com/eed3si9n
  [@amaanq]: https://github.com/amaanq
