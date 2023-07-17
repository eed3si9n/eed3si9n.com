---
title:       "automate refactoring with Bazel + Scalafix"
type:        story
date:        2023-07-15
draft:       false
promote:     true
sticky:      false
url:         automate-refactoring-with-bazel-and-scalafix
tags:        [ "bazel", "scala" ]
---

### about Scalafix

As a code base becomes larger, it's useful to have language tooling that can perform automatic refactoring. Thankfully, in 2016 Scala Center created [Scalafix][scalafix]. In [the announcement blog post](https://www.scala-lang.org/blog/2016/10/24/scalafix.html) Ólafur Geirsson wrote:

> Scalafix takes care of easy, repetitive and tedious code transformations so you can focus on the changes that truly deserve your attention. In a nutshell, scalafix reads a source file, transforms usage of unsupported features into newer alternatives, and writes the final result back to the original source file.

This shows the original emphasis on Scala 3 migration.

Nowadays Scalafix is maintained by Brice Jaglin et al, and often used as a general linting and refactoring tool, beyond Scala 3 migration. Yoshida-san (xuwei-k) for example, has been writing hundreds of Scalafix rules, and some of them are available publicly in his [xuwei-k/scalafix-rules][scalafix-rules] repo.

One interesting characteristic of Scalafix is that there are two kind of rules: syntactic rules and semantic rules.

- A syntactic rule can run directly on source code without compilation. They are simple, and are limited code analysis.
- A semantic rule can do more adanced code analysis based on symbols and types, but it requires input sources to be compiled beforehand with the SemanticDB compiler plugin enabled.

For syntactic rules, all you need is a Scalafix CLI, and you don't need Bazel integration. Semantic rules require more work since you need to pass the semanticdb etc.

### prior works on Bazel integration

- [ianoc](https://github.com/ianoc) has a repo called [ianoc/bazel-scalafix](https://github.com/ianoc/bazel-scalafix), but it's a lot of Bash. In this post I'll describe an approach using more Starlark, although some Bash will be necessary.
- See also [cross build anything with Bazel](/cross-build-anything-with-bazel/)

### Bazel + Scalafix

The overview of the steps

1. Resolve `ch.epfl.scala:scalafix-cli_<scalaVersion>:something`
2. Resolve `org.scalameta:semanticdb-scalac_<scalaVersion>:4.8.4`
3. Define a `scala_binary` target wrapping Scalafix CLI
4. Define a custom rule for `scalafix(...)`, which calls Scalafix CLI with appropriate inputs
5. Define a `scala_library(...)` macro that expands to `upstream_scala_library(...)`, `semanticdb(...)`, and `scalafix(...)`
6. Define a custom toolchain to set scalacOptions.
7. Write a small Bash script

### resolving 3rdparty dependencies

There are currently several ways of resolving 3rdparty dependencies, and you can use either of them. I've thus far used [bazel-deps][bazel-deps] and `MODULE.bazel`, and they both work. The following is a snippet from Bzlmod example:

#### MODULE.bazel

The exact version of these artifact depends on the availability for the Scala version(s) you're using.

```python
bazel_dep(name = "mod_scala_multiverse")
local_path_override(
  module_name="mod_scala_multiverse",
  path="tools/local_modules/default",
)

maven = use_extension("@mod_scala_multiverse//:extensions.bzl", "maven")

maven.install(
    artifacts = [
        "ch.epfl.scala:::scalafix-cli:0.11.0",
        "org.scalameta:::semanticdb-scalac:4.8.4",
        ....
    ],
)
use_repo(maven, "maven")
```

#### 3rdparty/jvm/BUILD.bazel

To absorb the notational differences between the solutions, I am going to define aliases for those dependencies:

```python
load("@scala_multiverse//:cross_scala_config.bzl", "maven_dep")

alias(
    name = "ch_epfl_scala__scalafix-cli",
    actual = maven_dep("ch.epfl.scala:::scalafix-cli"),
    visibility = ["//visibility:public"],
)

alias(
    name = "org_scalameta__semanticdb_scalac",
    actual = maven_dep("org.scalameta:::semanticdb.scalac"),
    visibility = ["//visibility:public"],
)
```

This way we can reference Scalafix as `//3rdparty/jvm:ch_epfl_scala__scalafix-cli` instead of `maven_dep("ch.epfl.scala:::scalafix-cli")`.

### write a shim for Scalafix

Since we can't execute a JAR on its own, we can define a `scala_binary` shim.

#### tools/scalafix_app/BUILD.bazel

```python
load("@io_bazel_rules_scala//scala:scala.bzl", "scala_binary")

scala_binary(
    name = "bin",
    srcs = glob(include = ["*.scala"]),
    main_class = "com.example.tools.scalafix_app.Main",
    visibility = ["//visibility:public"],
    deps = ["//3rdparty/jvm:ch_epfl_scala__scalafix-cli"],
)
```

#### tools/scalafix_app/Main.scala

```scala
package com.example.tools.scalafix_app

object Main extends App {
  scalafix.cli.Cli.main(args)
}
```

#### demo 1

We can use `bazel run` to try calling Scalafix CLI:

```bash
$ bazel run tools/scalafix_app:bin -- -version
INFO: Analyzed target //tools/scalafix_app:bin (0 packages loaded, 0 targets configured).
INFO: Found 1 target...
Target //tools/scalafix_app:bin up-to-date:
  bazel-bin/tools/scalafix_app/bin.jar
  bazel-bin/tools/scalafix_app/bin
INFO: Elapsed time: 0.155s, Critical Path: 0.00s
INFO: 1 process: 1 internal.
INFO: Build completed successfully, 1 total action
INFO: Running command line: bazel-bin/tools/scalafix_app/bin -version
0.11.0
```

Note: `bazel run` runs inside of a sandbox by design, so this target as it is cannot be used to actually process `*.scala` files.

### custom rule for `scalafix(...)`

In Bazel-speak, a rule is a special function whose invocation defines a rule target, which is equivalent to a subproject in build tools like sbt and Gradle.

Instead of defining tasks, in Bazel we introduce new rules to take different actions.

#### tools/rules/scalafix/BUILD.bazel

```python
# blank file
```

#### tools/rules/scalafix/scalafix.bzl

The following defines a rule that generates a Bash script that calls Scalafix CLI with `--files` and `--classpath` options already passed in.

A notable trick I am using here is to call `cd "$BUILD_WORKING_DIRECTORY"`, which allows this script to escape the sandbox and make changes on the workspace in situ.

```python
def _scalafix_impl(ctx):
    out = ctx.actions.declare_file(ctx.label.name + ".sh")
    tool = ctx.executable._scalafix_bin
    tool_rf = ctx.attr._scalafix_bin[DefaultInfo]
    srcs = ctx.files.srcs
    semanticdb = ctx.attr.semanticdb[DefaultInfo]
    deps = semanticdb.files.to_list()
    script = """SANDBOX_DIR=$(pwd)
JARS=""
JARS0=({jars})
for JAR in ${{JARS0[@]}}; do
  JARS="$JARS --classpath $SANDBOX_DIR/$JAR"
done
cd "$BUILD_WORKING_DIRECTORY"
exec "$SANDBOX_DIR/{tool}" --files {srcs} $JARS --scalac-options -Xlint $@
""".format(
        tool = tool.short_path,
        srcs = " --files ".join([src.short_path for src in srcs]),
        jars = " ".join([x.short_path for x in deps])
    )
    ctx.actions.write(out, script, is_executable = True)
    files = srcs + deps
    rf = ctx.runfiles(
        transitive_files = depset(files)
    ).merge(tool_rf.default_runfiles)
    return [DefaultInfo(
        executable = out,
        runfiles = rf,
    )]

scalafix = rule(
    attrs = {
        "srcs": attr.label_list(
            allow_files = [".scala"],
        ),
        "semanticdb": attr.label(),
        "_scalafix_bin": attr.label(
            executable = True,
            cfg = "host",
            allow_files = True,
            default = Label("//tools/scalafix_app:bin"),
        ),
    },
    doc = "Runs scalafix",
    executable = True,
    implementation = _scalafix_impl,
)
```

This rule expects three arguments, of which one has a default value supplied. In addition, all rules have `name`, and optionally `visibility`, `tags` etc.

### custom `scala_library` macro

In Bazel-speak, a macro is a pure function that's typically used to call other rules. They compile away, in a sense that the names of the macros will not be available to `bazel query` etc.

Normally we use `scala_library` rule provided by [rules_scala][rules_scala]. We can redefine it in a macro to split `scala_library(...)` to define three targets instead of one.

#### tools/rules/scala/BUILD.bazel

```python
# blank file
```

#### tools/rules/scala/scala.bzl

```python
load(
    "@io_bazel_rules_scala//scala:scala.bzl",
    upstream_scala_library = "scala_library",
)
load(
    "@io_bazel_rules_scala//scala/unstable:defs.bzl",
    "make_scala_library",
)
load(
    "//tools/rules/scalafix:scalafix.bzl",
    "scalafix"
)

scala_semanticdb = make_scala_library()

def scala_library(
        name,
        srcs = [],
        deps = [],
        runtime_deps = [],
        plugins = [],
        data = [],
        resources = [],
        scalacopts = None,
        main_class = "",
        exports = [],
        resource_jars = [],
        visibility = None,
        javacopts = [],
        tags = []):
    upstream_scala_library(
        name = name,
        srcs = srcs,
        deps = deps,
        runtime_deps = runtime_deps,
        plugins = plugins,
        resources = resources,
        scalacopts = scalacopts,
        main_class = main_class,
        exports = exports,
        resource_jars = resource_jars,
        visibility = visibility,
        javacopts = [],
        tags = tags,
    )
    scalacopts_mod = scalacopts
    if scalacopts_mod and ("-Xfatal-warnings" in scalacopts_mod):
        scalacopts_mod.remove("-Xfatal-warnings")

    scala_semanticdb(
        name = "{}__semanticdb".format(name),
        srcs = srcs,
        deps = deps,
        runtime_deps = runtime_deps,
        plugins = plugins + ["//3rdparty/jvm:org_scalameta__semanticdb_scalac"],
        resources = resources,
        scalacopts = scalacopts_mod,
        main_class = main_class,
        exports = exports,
        resource_jars = resource_jars,
        visibility = visibility,
        javacopts = [],
        tags = tags + ["manual"],
    )
    scalafix(
        name = "{}__scalafix".format(name),
        srcs = srcs,
        semanticdb = "{}__semanticdb".format(name),
        tags = tags + ["manual"],
    )
```

### custom toolchain

We should customize the `scala_toolchain` so the compilation uses `-deprecation` and `-Xlint` by default. This is essential because some Scalafix rules rely on these the compiler warnings.

#### toolchains/BUILD.bazel

```python
load(
    "@io_bazel_rules_scala//scala:scala.bzl",
    "setup_scala_toolchain",
)

setup_scala_toolchain(
    name = "scala_toolchain",
    scala_compile_classpath = [
        "@maven//:org_scala_lang_scala_compiler",
        "@maven//:org_scala_lang_scala_library",
        "@maven//:org_scala_lang_scala_reflect",
    ],
    scala_library_classpath = [
        "@maven//:org_scala_lang_scala_library",
        "@maven//:org_scala_lang_scala_reflect",
    ],
    scala_macro_classpath = [
        "@maven//:org_scala_lang_scala_library",
        "@maven//:org_scala_lang_scala_reflect",
    ],
    scalacopts = [
        "-Yrangepos",
        "-deprecation",
        "-Xlint",
        "-feature",
        "-language:existentials",
        "-language:higherKinds",
    ],
    visibility = ["//visibility:public"]
)
```

#### WORKSPACE

```diff
# remove these
-load("@io_bazel_rules_scala//scala:toolchains.bzl", "scala_register_toolchains")
-scala_register_toolchains()

register_toolchains("//toolchains:scala_toolchain")
```

#### demo 2

```bash
$ bazel query common-test/src/main/scala/gigahorsetest/...
//common-test/src/main/scala/gigahorsetest:gigahorsetest
//common-test/src/main/scala/gigahorsetest:gigahorsetest__scalafix
//common-test/src/main/scala/gigahorsetest:gigahorsetest__semanticdb
Loading: 0 packages loaded
```

We now see three targets.

### convenience script

Here are convenience scripts to call `bazel run`.

#### bin/scalafix

```bash
#!/usr/bin/env bash

set -o errexit  # abort on nonzero exitstatus
set -o nounset  # abort on unbound variable
set -o pipefail # don't hide errors within pipes

BUILD_TARGET_QUERY=${1:-}
if [[ -z "$BUILD_TARGET_QUERY" ]]; then
  echo "usage: $0 <query> --rules <scalafix rules>"
  exit 1
fi
shift

SCALAFIX_TARGETS=$(bazel query "kind('scalafix', $BUILD_TARGET_QUERY)")
for TARGET in $SCALAFIX_TARGETS; do
  echo "processing $TARGET"
  bazel run "$TARGET" -- $@
done
```

#### demo 3

First, we can use Coursier to install `scalafix` on the system path to run syntactic rules. In Scala, procedure syntax:

```scala
def close()
```

is deprecated ([I deprecated it from general use in #6325][6325]), and the ProcedureSyntax rule can rewrite it to:

```scala
def close(): Unit
```

```bash
$ cs install scalafix

$ scalafix core/src/main/scala/gigahorse/FullResponse.scala --rules ProcedureSyntax

$ rg -tscala 'def close' core
core/src/main/scala/gigahorse/FullResponse.scala
27:  def close(): Unit

core/src/main/scala/gigahorse/HttpClient.scala
26:  def close(): Unit
```

Since all you need to pass along is `*.scala` files, we do not need Bazel integration to run syntactic rules.

#### demo 4

Next, let's demonstrate semantic rule by removing unused imports.

```scala
package gigahorse

import java.nio.ByteBuffer
import scala.collection.mutable.Stack

abstract class FullResponse {
  def bodyAsByteBuffer: ByteBuffer
}
```

In the above, `import scala.collection.mutable.Stack` is unsed.

```bash
$ bin/scalafix //core/... --rules RemoveUnused
```

This removes the ununsed import.

#### demo 5

Another often used built-in rule for Scalafix is OrganizeImports.

```bash
$ bin/scalafix ... --rules OrganizeImports
```

This expands all imports to one item per line, and alphabetically sorts them:

```diff
diff --git a/core/src/main/scala/gigahorse/HttpClient.scala b/core/src/main/scala/gigahorse/HttpClient.scala
index fa08735..891e07f 100644
--- a/core/src/main/scala/gigahorse/HttpClient.scala
+++ b/core/src/main/scala/gigahorse/HttpClient.scala
@@ -16,8 +16,9 @@

 package gigahorse

-import scala.concurrent.{ Future, ExecutionContext }
 import java.io.File
+import scala.concurrent.ExecutionContext
+import scala.concurrent.Future
```

Not sure if the result is better, but the good thing is that it can be automated, so it's one less thing to bikeshed during code reviews.

### enforcing Scalafix rules on CI

To enforce Scalafix on CI, list the rules in `.scalafix.conf` and call `bin/scalafix ... --check`.

#### .scalafix.conf

```python
rules = [
  DisableSyntax,
  OrganizeImports,
  RemoveUnused,
]
```

#### demo 6

```bash
$ bin/scalafix ... --check
```

Here's an output from an actual GitHub Actions [log](https://github.com/eed3si9n/gigahorse/actions/runs/5564808250/jobs/10164623980):

```bash
processing //common-test/src/main/scala/gigahorsetest:gigahorsetest__scalafix
Loading: 
Loading: 0 packages loaded
Analyzing: target //common-test/src/main/scala/gigahorsetest:gigahorsetest__scalafix (0 packages loaded, 0 targets configured)
INFO: Analyzed target //common-test/src/main/scala/gigahorsetest:gigahorsetest__scalafix (0 packages loaded, 44 targets configured).
INFO: Found 1 target...
....
Target //common-test/src/main/scala/gigahorsetest:gigahorsetest__scalafix up-to-date:
  bazel-bin/common-test/src/main/scala/gigahorsetest/gigahorsetest__scalafix.sh
INFO: Elapsed time: 13.906s, Critical Path: 7.07s
INFO: 46 processes: 9 internal, 35 linux-sandbox, 2 worker.
INFO: Build completed successfully, 46 total actions
INFO: Running command line: bazel-bin/common-test/src/main/scala/gigahorsetest/gigahorsetest__scalafix.sh --check
--- /home/runner/work/gigahorse/gigahorse/common-test/src/main/scala/gigahorsetest/BaseHttpClientSpec.scala
+++ <expected fix>
@@ -16,18 +16,20 @@
 
 package gigahorsetest
 
+import gigahorse.HeaderNames
+import gigahorse.MimeTypes
+import gigahorse.SignatureCalculator
+import gigahorse.WebSocketEvent
 import org.scalatest.Assertion
 import org.scalatest.flatspec.AsyncFlatSpec
 import org.scalatest.matchers.should.Matchers
+import unfiltered.netty.Server

Error: Process completed with exit code 32.
```

#### working example

See <https://github.com/eed3si9n/gigahorse/pull/86> for a working example.

### summary

In the Scala ecosystem, Scalafix, developed originally at Scala Center, provides tooling to automate linting and refactoring. Users with large code base can use built-in or community-maintained rules to rewrite the code efficiently.

With some customization, Scalafix semantic rules can be used on a Bazel monorepo. 

----

#### license

To the extent possible under law, the author(s) have dedicated all copyright and related and neighboring rights to the code examples to the public domain worldwide. The code examples are distributed without any warranty. See http://creativecommons.org/publicdomain/zero/1.0/.

#### 🏳️‍🌈 support Ukraine 🇺🇦

Forbidden Colours has started a fundraising campaign to support organisations in Poland, Hungary and Romania that are welcoming LGBTIQ+ refugees.

<https://www.forbidden-colours.com/2022/02/26/support-ukrainian-lgbtiq-refugees/>

#### donate to Scala Center

Scala Center is a non-profit center at EPFL to support education and open source.

- <https://scala.epfl.ch/donate.html>

  [scalafix]: https://scalacenter.github.io/scalafix/
  [scalafix-rules]: https://github.com/xuwei-k/scalafix-rules
  [bazel-deps]: https://github.com/bazeltools/bazel-deps
  [rules_scala]: https://github.com/bazelbuild/rules_scala
  [6325]: https://github.com/scala/scala/pull/6325
