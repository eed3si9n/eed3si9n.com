---
title:       "tree-sitter-scala 0.20.0"
type:        story
date:        2023-05-24
url:         /tree-sitter-scala-0.20.0
tags:        [ "scala" ]
---

Hi everyone. On behalf of the tree-sitter-scala project, I am happy to announce tree-sitter-scala 0.20.0. The first two segment of the version number comes from the tree-sitter-cli that was used to generate the parser, and the last segment is our actual version number.

### About tree-sitter-scala

tree-sitter-scala is a Scala parser in C language, generated using Tree-sitter CLI, and conforming to the Tree-sitter API. Tree-sitter parsers are generally fast, incremental, and robust (ok with partial errors).
<!--more-->

Since its initial release in 2017, Tree-sitter parsers are adopted by editors like Atom, NeoVim, Emacs, Helix to provide language features like syntax highlight and folding and more (supposedly part of GitHub.com).

### Highlights

- New maintainers: Anton Sviridov, Chris Kipp, Eugene Yokota. Three of us joined tree-sitter-scala as maintainers, and we started making various improvements in the contribution infrastructure.
- Improvements on parsing Scala 3 syntax.

Full release note is at <https://github.com/tree-sitter/tree-sitter-scala/releases/tag/v0.20.0>.

### Contribution infrastructure

### Smoke test

As we were making bigger changes, we sometimes noticed afterwards that overall parsing accuracy could regress, but was hard to pinpoint. To tackle this, I added smoke test in [#81][81]. As part of GitHub Actions, this checks out scala/scala and lampepfl/dotty code base to parse the `*.scala` source files using tree-sitter-scala.

Using the special log format `::notice` or `::error`, we can surface the parse success % compared to the expected values:

```bash
  if (( $(echo "$actual > $expected" |bc -l) )); then
    # See https://docs.github.com/en/actions/using-workflows/workflow-commands-for-github-actions#example-creating-an-annotation-for-an-error
    echo -e "::notice file=grammar.js,line=1::ok, ${source_dir}: ${actual}%"
  else
    echo -e "::error file=grammar.js,line=1::${source_dir}: expected ${expected}, but got ${actual} instead"
    failed=$((failed + 1))
  fi
```

Initially, the baseline parsing % for Scala 2 library, Scala 2 compiler, and Scala 3 compiler were `87%`, `46%`, and `35%` respectively. As of version 0.20.0, the parse success % are: `89%`, `68%`, and `66%`.

{{% note %}}
**Correction**: In the first version of this post I wrote that tree-sitter-scala 0.20.0 parses `100%` of Scala 2 library sources, but we [found out](https://github.com/tree-sitter/tree-sitter-scala/issues/238) that there was a bug in smoke test and it was actually `89%`.

**Note**: Due to the robust nature of tree-sitter, even the parse results that contain errors is often usable for the purpose of syntax highlighing.
{{% /note %}}

### C code generation

During the initial period while I was on an extended vacation, and I worked on it around the clock because I was having a lot of fun. Because tree-sitter family of parsers are normally distributed as `*.c` source code checked into the GitHub repo, Anton Sviridov and I would be working on different features, but our PRs collided.

To make the matter worse, C code generation was taking longer and longer as we added more features, ranging from 10 to 40 minutes. I dusted out my old System76 Linux machine, which seemed to do better job.

To work around the git conflicts, we agreed on not including the generated code into the PR, and periodically someone would send a separate PR to bring them up to date. Chris Kipp created a GitHub Action to automate the codegen PR sending process in [#147][147].

It turned out that the reason why the compilation was taking so long or crashing GitHub Actions jobs was due to the memory usage. Andrew Hlynskyi (@ahlinc) from tree-sitter project pointed out to us that Linux was killing `tree-sitter` CLI as it generated tree-sitter-scala because it was consuming [34 GB of RAM][1890]. Andrew also gave us hints on `--report-states-for-rule` flag, which printed out the following:

```bash
$  node_modules/.bin/tree-sitter generate --report-states-for-rule compilation_unit
class_definition                3728
function_definition             2214
ascription_expression           1442
infix_expression                1412
assignment_expression           1412
....
```

Using this as the hint, in [#102][102] I was able to refactor the AST to make `class` parsing left associative (with a right-associative subtree), which brought down the memory usage to 11GB. Later on I applied similar refactoring to `given_definition` etc to bring down the memory usage down to 1 GB. On my old Linux box codegen now took less than a minute.

### Scala 3 syntax improvements

The primary motivation for three of us (Anton, Chris, and me) was better Scala 3 support on editors like Neovim and Helix, so it got a lot of the attention. Though as indicated by the 66% smoke test result, it's still a work in progress.

- Scala 3 [SIP-44][sip44] More braceless syntax support by @eed3si9n in #128
- Scala 3 Enums by @keynmol in #89
- Scala 3 `given` instances by @eed3si9n in #99
- Scala 3 macros by @eed3si9n in #110
- Scala 3 `using` clauses by @eed3si9n in #82
- Scala 3 `inline if`, `inline match`, `inline def`, and inline parameters by @keynmol in #45
- Scala 3 `opaque` type aliases by @keynmol in #87
- Scala 3 `extension` methods by @eed3si9n in #113
- Scala 3 Context functions `?=>` by @eed3si9n in #145
- Scala 3 `transparent`, `open`, and `infix` modifiers by @keynmol in #119
- Scala 3 `export` clauses by @keynmol in #125

### Participation

tree-sitter-scala 0.20.0 was brought to you by 8 contributors and a good bot:

```
$ git shortlog -sn --no-merges v0.19.1...v0.20.0
    47  Eugene Yokota
    24  Anton Sviridov
    16  Chris Kipp
     8  ghostbuster91
     8  GitHub
     5  susliko
     2  Kasper Kondzielski
     1  Logan Wemyss
     1  Guillaume Martres
```

Thanks to everyone who's helped improve tree-sitter-scala by using them, reporting bugs, improving our documentation, and submitting and reviewing pull requests.

### Donate to Scala Center

Scala Center is a non-profit center at EPFL to support education and open source.

- https://scala.epfl.ch/donate.html

  [81]: https://github.com/tree-sitter/tree-sitter-scala/pull/81
  [147]: https://github.com/tree-sitter/tree-sitter-scala/pull/147
  [1890]: https://github.com/tree-sitter/tree-sitter/issues/1890#issuecomment-1374577925
  [102]: https://github.com/tree-sitter/tree-sitter-scala/pull/102
  [sip44]: https://docs.scala-lang.org/sips/fewer-braces.html
