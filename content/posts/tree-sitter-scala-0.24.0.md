---
title:       "tree-sitter-scala 0.24.0"
type:        story
date:        2025-06-08
url:         /tree-sitter-scala-0.24.0
tags:        [ "scala" ]
---

Hi everyone. On behalf of the tree-sitter-scala project, I am happy to announce tree-sitter-scala 0.24.0. The first two segments of the version number comes from the tree-sitter-cli that was used to generate the parser, and the last segment is our actual version number. tree-sitter-scala 0.24.0 uses tree-sitter 0.24.x.

### About tree-sitter-scala

tree-sitter-scala is a Scala parser in C language, generated using Tree-sitter CLI, and conforming to the Tree-sitter API. Tree-sitter parsers are generally fast, incremental, and robust (ok with partial errors). We publish Rust binding to [crates.io](https://crates.io/crates/tree-sitter-scala).

<!--more-->

Since its initial release in 2017, Tree-sitter parsers are adopted by editors like NeoVim, Emacs, Helix, and Zed to provide language features like syntax highlight and folding and more (supposedly part of GitHub.com).

### Highlights

* deps: Updates tree-sitter to 0.24.7 by [@eed3si9n][@eed3si9n] in [#455](https://github.com/tree-sitter/tree-sitter-scala/pull/455)
* fix: Fixes nested packages by [@streichsbaer][@streichsbaer] + [@eed3si9n][@eed3si9n] in [#470](https://github.com/tree-sitter/tree-sitter-scala/pull/470)
* feat: String escape sequences by [@jonshea][@jonshea] in [#459](https://github.com/tree-sitter/tree-sitter-scala/pull/459)
* feat: Add `tags.scm` queries by [@susliko][@susliko] in [#461](https://github.com/tree-sitter/tree-sitter-scala/pull/461)

Full release notes are at <https://github.com/tree-sitter/tree-sitter-scala/releases/tag/v0.24.0>.

### Participation

tree-sitter-scala 0.24.0 was brought to you by 5 contributors and two bots:

```
$ git shortlog -sn --no-merges v0.23.4...
     5  Eugene Yokota
     5  Jon Shea
     2  GitHub
     2  dependabot[bot]
     1  Michel Lind
     1  Vasil Markoukin
#    1  Stefan Streichsbier
```

Thanks to everyone who's helped improve tree-sitter-scala by using them, reporting bugs, improving our documentation, and submitting and reviewing pull requests.

----

### Donate to Scala Center

Scala Center is a non-profit center at EPFL to support education and open source.

- https://scala.epfl.ch/donate.html

  [@susliko]: https://github.com/susliko
  [@eed3si9n]: https://github.com/eed3si9n
  [@amaanq]: https://github.com/amaanq
  [@jonshea]: https://github.com/jonshea
  [@streichsbaer]: https://github.com/streichsbaer
