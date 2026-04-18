---
title:       "tree-sitter-scala 0.24.1 and 0.25.0"
type:        story
date:        2026-03-12
url:         /tree-sitter-scala-0.25.0
tags:        [ "scala" ]
---

Hi everyone. On behalf of the tree-sitter-scala project, I am happy to announce tree-sitter-scala 0.24.1 and 0.25.0. The first two segments of the version number comes from the tree-sitter-cli that was used to generate the parser, and the last segment is our actual version number. For example, tree-sitter-scala 0.25.0 uses tree-sitter 0.25.x.

### About tree-sitter-scala

tree-sitter-scala is a Scala parser in C language, generated using Tree-sitter CLI, and conforming to the Tree-sitter API. Tree-sitter parsers are generally fast, incremental, and robust (ok with partial errors). We publish Rust binding to [crates.io](https://crates.io/crates/tree-sitter-scala).

<!--more-->

Tree-sitter parsers are adopted by editors like NeoVim, Emacs, Helix, and Zed to provide language features like syntax highlight and folding and more (supposedly part of GitHub.com).

### Highlights

* feat: `into` soft modifier by [@susliko] in [#475](https://github.com/tree-sitter/tree-sitter-scala/pull/475)
* feat: applied constructor types by [@susliko] in [#474](https://github.com/tree-sitter/tree-sitter-scala/pull/474)
* feat: `tracked` soft modifier by [@susliko] in [#473](https://github.com/tree-sitter/tree-sitter-scala/pull/473)
* feat: given with type parameters in Scala 3.4+ syntax by [@hamidr][@hamidr] in [#479](https://github.com/tree-sitter/tree-sitter-scala/pull/479)
* feat: anonymous `using` parameters in Scala 3 by [@hamidr][@hamidr] in [#480](https://github.com/tree-sitter/tree-sitter-scala/pull/480)

Full release notes are at <https://github.com/tree-sitter/tree-sitter-scala/releases/tag/v0.24.1> and <https://github.com/tree-sitter/tree-sitter-scala/releases/tag/v0.25.0>.

### Participation

tree-sitter-scala 0.25.0 was brought to you by 3 contributors and a bot:

```
$ git shortlog -sn --no-merges v0.24.0...
     9  Eugene Yokota
     3  GitHub
     3  Vasili Markoukin
     2  Hamid
```

Thanks to everyone who's helped improve tree-sitter-scala by using them, reporting bugs, improving our documentation, and submitting and reviewing pull requests.

----

### FYI - Scala Days talk by Anton

In August 2025, Tree-Sitter Scala co-maintainer Anton Sviridov gave a Tree Sitter + multi-platform talk at Scala Days. Check out [Indoor Vivants](https://blog.indoorvivants.com/2025-11-26-video-scala-days-talk-about-tree-sitter-and-scala-3-multiplatform) for the links to code, slides, and the recording.

  [@susliko]: https://github.com/susliko
  [@eed3si9n]: https://github.com/eed3si9n
  [@amaanq]: https://github.com/amaanq
  [@hamidr]: https://github.com/hamidr
