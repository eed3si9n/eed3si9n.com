---
title:       "tree-sitter-scala 0.22.0"
type:        story
date:        2024-06-23
url:         /tree-sitter-scala-0.22.0
tags:        [ "scala" ]
---

Hi everyone. On behalf of the tree-sitter-scala project, I am happy to announce tree-sitter-scala 0.22.0. The first two segments of the version number comes from the tree-sitter-cli that was used to generate the parser, and the last segment is our actual version number. tree-sitter-scala 0.22.0 uses tree-sitter 0.22.x.

### About tree-sitter-scala

tree-sitter-scala is a Scala parser in C language, generated using Tree-sitter CLI, and conforming to the Tree-sitter API. Tree-sitter parsers are generally fast, incremental, and robust (ok with partial errors). We publish Rust binding to [crates.io](https://crates.io/crates/tree-sitter-scala).

<!--more-->

Since its initial release in 2017, Tree-sitter parsers are adopted by editors like NeoVim, Emacs, Helix, and Atom to provide language features like syntax highlight and folding and more (supposedly part of GitHub.com).

### Highlights

- Uses tree-sitter 0.22.6 by [@eed3si9n][@eed3si9n] in [#379][379]
- Improves single opchar by excluding colon, at, and equal, by [@eed3si9n][@eed3si9n] in [#394][394]

Full release notes are at <https://github.com/tree-sitter/tree-sitter-scala/releases/tag/v0.22.0>.

### Parsing improvements

Parsing % for Scala 2 library, Scala 2 compiler, and Scala 3 compiler are as follows:

| tree-sitter-scala | scala-library | scalac | Dotty |
|-------------------|---------------|--------|-------|
| `0.22.0`          |     `100%`    |  `97%` | `85%` |
| `0.21.0`          |     `100%`    |  `96%` | `85%` |
| `0.20.2`          |     `100%`    |  `96%` | `84%` |
| `0.20.1`          |     `98%`     |  `93%` | `83%` |
| `0.20.0`          |     `89%`     |  `68%` | `66%` |

Prior to 0.22.0 ([#394][394]), `operator_identifier` included characters like `:` (colon), `@` (at), and `=` (equal sign) even though those characters cannot be a legal operator without backticks. Having equal etc pushes tree-sitter into falsely thinking some construct to be an infix operation when they are `=` that is part of a definition or an assignment. This single change bumped the scalac parsing rate from 96% to 97%.

### tree-sitter-scala inside

Perhaps the most interesting thing about this release is not exactly what's in it, but who requested it. I had [#379][379] open as a draft PR since March, and yesterday someone from GitHub [commented](https://github.com/tree-sitter/tree-sitter-scala/pull/379#issuecomment-2183456443):

> Hello from the GitHub code search team. I would like to propose that this change be merged and a new release of the Rust crate be cut. Doing so will help us with an ongoing upgrade to our code navigation systems.

I've sorted guessed that tree-sitter is used within GitHub since the author of tree-sitter, Max Brunsfeld worked there, but now we have a confirmation. (Max now develops [Zed](https://zed.dev/) editor)

### Participation

tree-sitter-scala 0.22.0 was brought to you by me and a bot:

```
$ git shortlog -sn --no-merges v0.21.0...
     4  Eugene Yokota
     2  GitHub
```

Thanks to everyone who's helped improve tree-sitter-scala by using them, reporting bugs, improving our documentation, and submitting and reviewing pull requests.

----

### Donate to Scala Center

Scala Center is a non-profit center at EPFL to support education and open source.

- https://scala.epfl.ch/donate.html

  [379]: https://github.com/tree-sitter/tree-sitter-scala/pull/379
  [394]: https://github.com/tree-sitter/tree-sitter-scala/pull/394
  [@susliko]: https://github.com/susliko
  [@eed3si9n]: https://github.com/eed3si9n
  [@antosha417]: https://github.com/antosha417
