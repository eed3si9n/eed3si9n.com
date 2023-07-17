---
title:       "Bazel + Scalafix を用いてリファクタリングを自動化する方法"
type:        story
date:        2023-07-15
draft:       false
promote:     true
sticky:      false
url:         automate-refactoring-with-bazel-and-scalafix
tags:        [ "bazel", "scala" ]
---

### Scalafix について

コードベースが大型化するにつれ、自動リファクタリングを行うことができる言語ツールがあると便利だ。幸いなことに、2016年に Scala Center が [Scalafix][scalafix] を作ってくれた。[公開時のブログ記事](https://www.scala-lang.org/blog/2016/10/24/scalafix.html)の中で Ólafur Geirsson さんは:

> Scalafix は、簡単かもしれないが単調に繰り返されるコード変換を受け持つことで、あなたが意識を向ける価値のあることに集中することができます。大まかに説明すると、Scalafix はソースを読んで、非推奨機能の使用を新しい代替へと変換し、元のソースに書き込みます。

と解説していて、Scala 3 マイグレーションが動機になっていたことがうかがえる。

現在は、Scalafix は Brice Jaglin さんらによってメンテされていて、Scala 3 マイグレーション以外でも一般のリンティングやリファクタリングのツールとして使われている。例えば吉田さん (xuwei-k) なんかは数百の Scalafix を書いたらしく、その一部は [xuwei-k/scalafix-rules][scalafix-rules] にも公開されている。

Scalafix 独特の特徴として、syntactic (構文的) と semantic (意味論的) という2種類のルールがある。

- syntactic rule は、コンパイルすることなくソースコードに対して直接実行することができる。シンプルだが、コード解析の力には制限がある。
- semantic rule は、シンボルや型を用いてより高度なコード解析を行うことができるが、入力ソースを SemanticDB コンパイラ・プラグインと共にコンパイルしたものを事前に用意する必要がある。

syntactic rule は Scalafix CLI さえあれば良いので、Bazel との統合は特に必要無い。一方で、semantic rule は semanticdb などを渡して回るため、少し作業が必要となる。

### Bazel 統合の先行研究

- [ianoc](https://github.com/ianoc) さんが作った [ianoc/bazel-scalafix](https://github.com/ianoc/bazel-scalafix) というリポがあるが、Bash 成分が多い。本稿では、もう少し Starlark を使った方法を解説するが、Bash も多少は必要となる。
- [Bazel を用いて何でもクロスビルドする方法](/ja/cross-build-anything-with-bazel/)も参照。

### Bazel + Scalafix

手順の概要

1. `ch.epfl.scala:scalafix-cli_<scalaVersion>:something`を解決する
2. `org.scalameta:semanticdb-scalac_<scalaVersion>:4.8.4`を解決する
3. Scalafix CLI をラップした `scala_binary` のターゲットを定義する
4. Scalafix CLI に適切なインプットを渡して実行する `scalafix(...)` カスタム・ルールを定義する
5. `upstream_scala_library(...)`, `semanticdb(...)`, `scalafix(...)` に展開する `scala_library(...)` マクロを定義する
6. scalacOptions を渡すためのカスタムツールチェインを定義する
7. 小さい Bash スクリプトを書く

### 3rdparty 依存性の解決

3rdparty 依存性の解決には現在いくつかの方法があって、どれを選んでも構わない。僕が今のところ試したのは [bazel-deps][bazel-deps] と `MODULE.bazel` で両方とも動いた。以下は Bzlmod を使った例からの抜粋だ:

#### MODULE.bazel

バージョン番号は、どの Scala バージョンを使っていてそれらに対してアーティファクトが公開されているかによる。

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

それぞれの依存性解決の方法による細かな違いを吸収するためにこれらの依存性のエイリアスを定義する:

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

これによって、Scalafix を `maven_dep("ch.epfl.scala:::scalafix-cli")` ではなく `//3rdparty/jvm:ch_epfl_scala__scalafix-cli` として参照できる。

### Scalafix の shim を書く

JAR をそのままでは実行できないので、`scala_binary` を使って簡単な shim (調整板) を作る。

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

`bazel run` を使って Scala CLI を呼び出してみる:

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

注意: `bazel run` は隔離されたサンドボックス内で実行される設計なので、このターゲットはこのままでは `*.scala` ファイルの処理をすることができない。

### `scalafix(...)` のためのカスタム・ルール

Bazel 用語で、ルールは呼び出すと、sbt や Gradle におけるサブプロジェクト相当のルール・ターゲットを作ることができる特殊な関数のことだ。

タスクを定義する代わりに、Bazel では新しいルールを定義することで様々なアクションを実行する。

#### tools/rules/scalafix/BUILD.bazel

```python
# blank file
```

#### tools/rules/scalafix/scalafix.bzl

以下は、Scalafix CLI に適切な `--files` と `--classpath` オプションを渡して呼び出す Bash スクリプトを生成するルールを定義する。

ここで裏技として使っているのは `cd "$BUILD_WORKING_DIRECTORY"` の呼び出しで、これによってこのスクリプトはサンドボックスを突破してワークスペースの上書きをすることができるようになる。

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

このルールは 3つの引数を受け取り、そのうちの 1つはデフォルト値を持つ。さらに全てのルールは `name` を持ち、`visibility` や `tags` などを渡すこともできる。

### カスタム `scala_library` マクロ

Bazel 用語で、マクロは純粋関数で通常他のルールを呼ぶ出すために使われる。マクロの名前などは `bazel query` などでは見えなくなるという意味でコンパイルすると無くなる ("compile away" する) と言える。

[rules_scala][rules_scala] が提供する `scala_library` ルールをそのまま使うのが普通だが、`scala_library` をマクロとして定義しなおして、`scala_library(...)` を 3つのターゲットへと分岐させることができる。

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

### カスタム・ツールチェイン

`scala_toolchain` をカスタム化することで全てのコンパイルにデフォルトで `-deprecation` と `-Xlint` が付くようにする。実は Scalafix ルールのいくつかはコンパイラの警告を再利用しているので、これは必要不可欠なステップだ。

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

これで 3つのターゲットが作られることが分かる。

### 便利スクリプト

以下は `bazel run` を呼び出すためのスクリプトだ。

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

一応 Coursier でシステム・パスにインストールできる `scalafix` を使って syntactic ルールの使い方から見ていく。Scala において以下のようなプロシージャ構文は非推奨になっていて ([#6325 で僕が一般的に非推奨にした][6325])、ProcedureSyntax ルールを使って書き換えることができる:

```scala
def close()
```

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

`*.scala` ファイルを渡すだけでいいので、syntactic ルールを実行するのに Bazel 統合は必要無い。

#### demo 4

次に、未使用の import 文を除去する semantic ルールの例をみてみる。

```scala
package gigahorse

import java.nio.ByteBuffer
import scala.collection.mutable.Stack

abstract class FullResponse {
  def bodyAsByteBuffer: ByteBuffer
}
```

上の例では、`import scala.collection.mutable.Stack` は未使用だ。

```bash
$ bin/scalafix //core/... --rules RemoveUnused
```

これで未使用の import 文が除去された。

#### demo 5

また、結構良く使われていると思う Scalafix 組み込みのルールで OrganizeImports というのがある。

```bash
$ bin/scalafix ... --rules OrganizeImports
```

これは全ての import 文を各行1アイテムづつに展開して、アルファベット順に並べ替えるというものだ:

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

個人的にこの結果が良いのかは疑問だが、利点としては自動化できるため、コードレビュー時に不毛な議論をする点 1つ減るということが言える。

### CI での Scalafix ルールの検査

CI 上で Scalafix ルール群を検査してリンターとして使うには、`.scalafix.conf` にルールを列挙して、`bin/scalafix ... --check` を呼び出す。

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

以下は実際の GitHub Actions [ログ](https://github.com/eed3si9n/gigahorse/actions/runs/5564808250/jobs/10164623980)から抜粋したものだ:

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

#### 実用例

これらをまとめた実用例は <https://github.com/eed3si9n/gigahorse/pull/86> を参照。

### まとめ

Scala エコシステムにおいて、Scala Center が開発した Scalafix はリファクタリングやリンティングを自動化するツールを提供する。大規模コードベースを使うユーザーは Scalafix 組み込みもしくはコミュニティーがメンテしているルール群を使って効率的にコードの書き換えを行うことができる。

いくつかのカスタム化を行うことで、Scalafix の semantic rule も Bazel モノリポから使うことができる。

----

#### ライセンス

法令上認められる最大限の範囲で作者は、本稿におけるコード例の著作権および著作隣接権を放棄して、全世界のパブリック・ドメインに提供している。
コード例は一切の保証なく公開される。<http://creativecommons.org/publicdomain/zero/1.0/> 参照。

#### 🏳️‍🌈 ウクライナをサポートしよう 🇺🇦

Forbidden Colours は、ポーランド、ハンガリー、ルーマニアなどで LGBTIQ+ 難民を補助するための募金キャンペーンを行っている。

<https://www.forbidden-colours.com/2022/02/26/support-ukrainian-lgbtiq-refugees/>

#### Scala Center へ寄付しよう

Scala Center は、教育とオープンソースを補助することを目的とした EPFL 内にある非営利団体で、個人からの募金も受け付けている。

- <https://scala.epfl.ch/donate.html>

  [scalafix]: https://scalacenter.github.io/scalafix/
  [scalafix-rules]: https://github.com/xuwei-k/scalafix-rules
  [bazel-deps]: https://github.com/bazeltools/bazel-deps
  [rules_scala]: https://github.com/bazelbuild/rules_scala
  [6325]: https://github.com/scala/scala/pull/6325
