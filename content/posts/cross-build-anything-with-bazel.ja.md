---
title:       "Bazel を用いて何でもクロスビルドする方法"
type:        story
date:        2023-02-20
draft:       false
promote:     true
sticky:      false
url:         cross-build-anything-with-bazel
tags:        [ "bazel", "scala" ]
---

  [local_repository]: https://bazel.build/versions/6.0.0/reference/be/workspace#local_repository
  [override_repository]: https://bazel.build/versions/6.0.0/reference/command-line-reference#flag--override_repository
  [rules_scala]: https://github.com/bazelbuild/rules_scala
  [bzlmod]: https://bazel.build/versions/6.0.0/build/bzlmod
  [module_extension]: https://bazel.build/external/extension
  [rules_jvm_external]: https://github.com/bazelbuild/rules_jvm_external/blob/master/defs.bzl

一般論として Bazel は、モノバージョンニングといって、(JUnit や Pandas など) どのライブラリでもモノリポ内の全てのターゲットが同一のバージョンを使うという形態を好む。
モノバージョニングは、モノリポ内で発生しうるバージョン衝突を劇的に減らすため、よりコード再利用性を改善させるという効果がある。
しかし、実際に運用してみると全社が二人三脚状態になるという欠点も出てくる。
例えばサービス A、B、C、D の全てが Big Framework 1.1 を使っていると、デグレ (regression) があるかもしれないので全てを同時に Big Framework 1.2 に移植するのは人的負荷が高かったりする。
そんなこんなで数年が経ち、Big Framework 2.0 がリリースされて、やっぱりこれも採用はリスキーなのではということになる。

Scala エコシステムでは、sbt を用いてライブラリ作者がライブラリを複数の Scala 標準ライブラリやその他のフレームワークに対してビルドするというのは普通に行われている。
これは**クロスビルド**と呼ばれている。(x86 から aarch64 など CPU アーキテクチャをまたいだコンパイルを**クロスコンパイル**と言ったりするがそれとは別なことに注意)

このクロスビルドという概念は、同ブランチ内で中長期に渡って色々な軸のマイグレーションを可能とすることから、Bazel においても有用なものじゃないかと思っている。
例えば現行のモノリポが Scala 2.12 だとして、徐々にマイグレーションを行ってほとんどのターゲットが Scala 2.12 と Scala 2.13 の両方でビルド可能な状態へ持っていく。
これは、一部のチームが全社に先行して新バージョンを試しつつ、コードベースとしては普通に進んでいくことができる。

### local_repository ハック

先週、[@ianoc](https://macaw.social/@ianoc)さんに Bazel でクロスビルドを可能とする機構を教えてもらった。
僕たちがやったのは Python の外部ライブラリの切り替えだが、本稿では Scala のクロスビルドを実装する。
(思い出すと去年、Long Cao さんがバーに入る行列で待っている間にこの説明を試みてくれた気がするが、当時はこのテクニックが非常に強力なものだと僕がイマイチ理解できなかった。)

まず基本を先に言うと、ルートの `WORKSPACE` 内でサブディレクトリを参照する [`local_repository`][local_repository] を宣言して、入れ子ワークスペースを作る。
実行時に [`--override_repository`][override_repository] オプションを使って、これを別のワークスペースへとオーバーライドする。
このローカル・リポジトリは定数、マクロ、ファイルを含むターゲットなどを公開することができ、これを使うことで何でもオーバーライドできるはずだ。

### Hello world の例

#### `WORKSPACE`

`WORKSPACE` から一部抜粋:

```python
....

rules_scala_version = "56bfe4f3cb79e1d45a3b64dde59a3773f67174e2"
http_archive(
    name = "io_bazel_rules_scala",
    sha256 = "f1a4a794bad492fee9eac1c988702e1837373435c185736df45561fe68e85227",
    strip_prefix = "rules_scala-%s" % rules_scala_version,
    type = "zip",
    url = "https://github.com/bazelbuild/rules_scala/archive/%s.zip" % rules_scala_version,
)

local_repository(
    name = "scala_multiverse",
    path = "tools/local_repos/default",
)

load("@scala_multiverse//:cross_scala_config.bzl", "cross_scala_config")
cross_scala_config()

....
```

このファイルの残りは [rules_scala][rules_scala] 参照。

#### `tools/local_repo/default/WORKSPACE`

```python
rules_scala_version = "56bfe4f3cb79e1d45a3b64dde59a3773f67174e2"
http_archive(
    name = "io_bazel_rules_scala",
    sha256 = "f1a4a794bad492fee9eac1c988702e1837373435c185736df45561fe68e85227",
    strip_prefix = "rules_scala-%s" % rules_scala_version,
    type = "zip",
    url = "https://github.com/bazelbuild/rules_scala/archive/%s.zip" % rules_scala_version,
)
```

#### `tools/local_repo/default/BUILD.bazel`

```python
# Empty file
```

#### `tools/local_repo/default/cross_scala_config.bzl`

```python
load("@io_bazel_rules_scala//:scala_config.bzl", "scala_config")

MULTIVERSE_NAME="default"
IS_SCALA_2_12 = True

def cross_scala_config(enable_compiler_dependency_tracking = False):
  scala_config(
    "2.12.14",
    enable_compiler_dependency_tracking=enable_compiler_dependency_tracking,
  )
```

#### `tools/local_repo/scala_2.13/WORKSPACE`

```python
rules_scala_version = "56bfe4f3cb79e1d45a3b64dde59a3773f67174e2"
http_archive(
    name = "io_bazel_rules_scala",
    sha256 = "f1a4a794bad492fee9eac1c988702e1837373435c185736df45561fe68e85227",
    strip_prefix = "rules_scala-%s" % rules_scala_version,
    type = "zip",
    url = "https://github.com/bazelbuild/rules_scala/archive/%s.zip" % rules_scala_version,
)
```

#### `tools/local_repo/scala_2.13/BUILD.bazel`

```python
# Empty file
```

#### `tools/local_repo/scala_2.13/cross_scala_config.bzl`

```python
load("@io_bazel_rules_scala//:scala_config.bzl", "scala_config")

MULTIVERSE_NAME="scala_2.13"
IS_SCALA_2_12 = False

def cross_scala_config(enable_compiler_dependency_tracking = False):
  scala_config(
    "2.13.6",
    enable_compiler_dependency_tracking = enable_compiler_dependency_tracking,
  )
```

#### `hello/BUILD.bazel`

```python
load("@io_bazel_rules_scala//scala:scala.bzl", "scala_binary")

scala_binary(
    name = "bin",
    srcs = ["Hello.scala"],
    main_class = "hello.Hello",
)
```

#### `hello/Hello.scala`

```scala
package hello

import scala.util.Properties.versionNumberString

object Hello extends App {
  println(s"hello, Scala $versionNumberString")
}
```

#### demo 1

```bash
$ bazel run //hello:bin
INFO: Analyzed target //hello:bin (25 packages loaded, 460 targets configured).
INFO: Found 1 target...
Target //hello:bin up-to-date:
  bazel-bin/hello/bin.jar
  bazel-bin/hello/bin
INFO: Elapsed time: 0.426s, Critical Path: 0.02s
INFO: 1 process: 1 internal.
INFO: Build completed successfully, 1 total action
INFO: Build completed successfully, 1 total action
hello, Scala 2.12.14

$ bazel run //hello:bin --override_repository="scala_multiverse=$(pwd)/tools/local_repos/scala_2.13"
INFO: Analyzed target //hello:bin (25 packages loaded, 460 targets configured).
INFO: Found 1 target...
Target //hello:bin up-to-date:
  bazel-bin/hello/bin.jar
  bazel-bin/hello/bin
INFO: Elapsed time: 0.379s, Critical Path: 0.02s
INFO: 1 process: 1 internal.
INFO: Build completed successfully, 1 total action
INFO: Build completed successfully, 1 total action
hello, Scala 2.13.6
```

これは、コマンドライン上からビルドに使う Scala バージョンを切り替えれることを示す。

### 3rdparty 解決の変更 (従来型)

3rdparty 解決処理をどのように行っているかによるが、基本的な考え方としてはロックファイルか `deps.bzl` を `tools/local_repos/default/` か `tools/local_repos/scala_2.13` に入れるということだ。

bazel-multiversion の場合は、このような手順となる:

```bash
echo 'multiversion_config(scala_versions = ["2.12.14"])' > 3rdparty/jvm/BUILD
bin/multiversion import-build --output-path=tools/local_repos/default/jvm_deps.bzl
echo 'multiversion_config(scala_versions = ["2.13.6"])' > 3rdparty/jvm/BUILD
bin/multiversion import-build --output-path=tools/local_repos/scala_2.13/jvm_deps.bzl
```

そして `WORKSPACE` 内で:

#### `WORKSPACE`

```python
load("@scala_multiverse//:jvm_deps.bzl", "jvm_deps")
jvm_deps()
load("@maven//:jvm_deps.bzl", "load_jvm_deps")
load_jvm_deps()
```

#### demo 2

```bash
$ bazel build //core/src/main:main
....
Target //core/src/main:main up-to-date:
  bazel-bin/core/src/main/main.jar
INFO: Elapsed time: 14.986s, Critical Path: 13.53s
INFO: 10 processes: 4 internal, 2 darwin-sandbox, 4 worker.
INFO: Build completed successfully, 10 total actions

$ bazel query 'deps(//core/src/main:main)' | grep '@maven//:com.*ssl-config'
@maven//:com.typesafe/ssl-config-core_2.12/0.6.1/ssl-config-core_2.12-0.6.1-sources.jar
@maven//:com.typesafe/ssl-config-core_2.12/0.6.1/ssl-config-core_2.12-0.6.1.jar
@maven//:com.typesafe_ssl-config-core_2.12_0.6.1_-1177452640

$ bazel build //core/src/main:main --override_repository="scala_multiverse=$(pwd)/tools/local_repos/scala_2.13"
....
Target //core/src/main:main up-to-date:
  bazel-bin/core/src/main/main.jar
INFO: Elapsed time: 14.648s, Critical Path: 13.32s
INFO: 10 processes: 4 internal, 2 darwin-sandbox, 4 worker.
INFO: Build completed successfully, 10 total actions

$ bazel query 'deps(//core/src/main:main)' --override_repository="scala_multiverse=$(pwd)/tools/local_repos/scala_2.13" | grep '@maven//:com.*ssl-config'
@maven//:com.typesafe/ssl-config-core_2.13/0.6.1/ssl-config-core_2.13-0.6.1-sources.jar
@maven//:com.typesafe/ssl-config-core_2.13/0.6.1/ssl-config-core_2.13-0.6.1.jar
@maven//:com.typesafe_ssl-config-core_2.13_0.6.1_-1177452640
```

### ソースコードの切り替え

Scala バージョンなどによってソースコードごと切り替えてしまった方が便利な場合もある。
ローカル・リポジトリから変数を公開できるので、簡単に実装できる。

`IS_SCALA_2_12` という変数を定義したことを思い出してほしい:

```python
IS_SCALA_2_12 = True
```

先ほどの hello world の例で別のソースコードを使いたいとすると、以下のように実装できる:

#### `hello/BUILD.bazel`

```python
load("@io_bazel_rules_scala//scala:scala.bzl", "scala_binary")
load("@scala_multiverse//:cross_scala_config.bzl", "IS_SCALA_2_12")

scala_binary(
    name = "bin",
    srcs = ["Hello.scala"] if IS_SCALA_2_12 else ["Hello_2.13.scala"],
    main_class = "hello.Hello",
)
```

#### demo 3

```bash
$ bazel run //hello:bin --override_repository="scala_multiverse=$(pwd)/tools/local_repos/scala_2.13"
....
hi, Scala 2.13.6!
```

### コマンドライン・オプションの隠蔽

コマンドライン・オプションが冗長なので、これを隠したいとする。
これは `.bazelrc` ファイルを使って行う。

#### `bazelenv`

```bash
#!/usr/bin/env bash

MODE=$1
function usage() {
  echo "usage ./bazelenv [<multiverse>]"
  echo ""
  echo "available multiverses are:"
  candidates=$(/bin/ls tools/local_repos)
  echo "$candidates"
}
if [[ "$MODE" == "" ]]; then
  usage
elif [[ -d tools/local_repos/$MODE ]]; then
  echo "common --override_repository=scala_multiverse=$(pwd)/tools/local_repos/$MODE" > ".bazelenv"
else
  usage; exit 1
fi
```

#### `.bazelrc`

```python
try-import ".bazelenv"
```

#### demo 4

```bash
$ chmod +x bazelenv
$ ./bazelenv
usage ./bazelenv [<multiverse>]

available multiverses are:
default
scala_2.13
$ ./bazelenv default
$ bazel query 'deps(//core/src/main:main)' | grep '@maven//:com.*ssl-config'
@maven//:com.typesafe/ssl-config-core_2.12/0.6.1/ssl-config-core_2.12-0.6.1-sources.jar
@maven//:com.typesafe/ssl-config-core_2.12/0.6.1/ssl-config-core_2.12-0.6.1.jar
@maven//:com.typesafe_ssl-config-core_2.12_0.6.1_-1177452640
$ ./bazelenv scala_2.13
$ bazel query 'deps(//core/src/main:main)' | grep '@maven//:com.*ssl-config'
@maven//:com.typesafe/ssl-config-core_2.13/0.6.1/ssl-config-core_2.13-0.6.1-sources.jar
@maven//:com.typesafe/ssl-config-core_2.13/0.6.1/ssl-config-core_2.13-0.6.1.jar
@maven//:com.typesafe_ssl-config-core_2.13_0.6.1_-1177452640
```

`.bazelrc` を使うことで、コマンドライン・オプション無しで Scala バージョンを切り替えることができた。

### 3rdparty 解決の変更 (MODULE.bazel)

Bazel 6 より [MODULE.bazel][bzlmod] (コードネーム Bzlmod) は実験的機能でな無くなったため、このテクニックがどのように実装できるか当然気になった。従来のワークスペースと違って、[module extension][module_extension] は extension 自体かリポジトリしか公開することができない。

そのため、大まかな戦略としては `MODULE.bazel` ファイル内ではタグクラスを用いて依存性の宣言を行い、module extension 内で従来どおり repository rule を呼び出して `http_archive` を含む副作用を実行するということらしい。
Bazel の Slack での Xudong Yang さんの[発言](https://bazelbuild.slack.com/archives/C014RARENH0/p1660212206376779?thread_ts=1659965864.646099&cid=C014RARENH0)を引用すると:

> The module extension is as simple as
>
> ```python
> def http_stuff():
>   http_file(...)
>   http_file(...)
>   http_archive(...)
> 
> my_ext = module_extension(implementation=lambda ctx: http_stuff())
> ```
>
> it's _basically_ a workspace macro

幸いなことに [rules_jvm_external][rules_jvm_external] は、`maven_install(...)` を従来の repositori rule として公開しているので、それを Coursier フロントエンドとして使うことができる。

#### `tools/local_modules/default/WORKSPACE`

```python
# Empty file
```

#### `tools/local_modules/default/BUILD`

```python
# Empty file
```

#### `tools/local_modules/default/MODULE.bazel`

```python
module(
  name = "mod_scala_multiverse",
)
bazel_dep(
  name = "rules_jvm_external",
  version = "4.5",
)
bazel_dep(
  name = "bazel_skylib",
  version = "1.3.0",
)
```

#### `tools/local_modules/default/extensions.bzl`

```python
load("@rules_jvm_external//:defs.bzl", "artifact", "maven_install")

SCALA_SUFFIX = "_2.12"

_install = tag_class(
  attrs = {
    "artifacts": attr.string_list(
      doc = "Maven artifact tuples, in `artifactId:groupId:version` format",
      allow_empty = True,
    ),
  },
)

def _modify_artifact(coordinates_string):
  coord = _parse_maven_coordinates(coordinates_string)
  if coord["is_scala"]:
    return "{}:{}:{}".format(
      coord["group_id"],
      coord["artifact_id"] + SCALA_SUFFIX,
      coord["version"],
    )
  else:
    return coordinates_string

def _local_ext_impl(mctx):
  artifacts = []
  for mod in mctx.modules:
    for install in mod.tags.install:
      artifacts += [_modify_artifact(artifact) for artifact in install.artifacts]
  maven_install(
    artifacts=artifacts,
    repositories=[
      "https://repo1.maven.org/maven2",
    ],
  )

maven = module_extension(
  implementation=_local_ext_impl,
  tag_classes={"install": _install},
)

def _parse_maven_coordinates(coordinates_string):
    """
    Given a string containing a standard Maven coordinate (g:a:[p:[c:]]v),
    returns a Maven artifact map (see above).
    See also https://github.com/bazelbuild/rules_jvm_external/blob/4.3/specs.bzl
    """
    if "::" in coordinates_string:
      idx = coordinates_string.find("::")
      group_id = coordinates_string[:idx]
      rest = coordinates_string[idx + 2:]
      is_scala = True
    elif ":" in coordinates_string:
      idx = coordinates_string.find(":")
      group_id = coordinates_string[:idx]
      rest = coordinates_string[idx + 1:]
      is_scala = False
    else:
      fail("failed to parse '{}'".format(coordinates_string))
    parts = rest.split(":")
    artifact_id = parts[0]
    if (len(parts)) == 1:
      result = dict(group_id=group_id, artifact_id=artifact_id, is_scala=is_scala)
    elif len(parts) == 2:
      version = parts[1]
      result = dict(group_id=group_id, artifact_id=artifact_id, version=version, is_scala=is_scala)
    elif len(parts) == 3:
      packaging = parts[1]
      version = parts[2]
      result = dict(group_id=group_id, artifact_id=artifact_id, packaging=packaging, version=version, is_scala=is_scala)
    elif len(parts) == 4:
      packaging = parts[1]
      classifier = parts[2]
      version = parts[3]
      result = dict(group_id=group_id, artifact_id=artifact_id, packaging=packaging, classifier=classifier, version=version, is_scala=is_scala)
    else:
      fail("failed to parse '{}'".format(coordinates_string))
    return result
```

#### `tools/local_modules/scala_2.13/WORKSPACE`

```python
# Empty file
```

#### `tools/local_modules/scala_2.13/BUILD`

```python
# Empty file
```

#### `tools/local_modules/scala_2.13/MODULE.bazel`

```python
module(
  name = "mod_scala_multiverse",
)
bazel_dep(
  name = "rules_jvm_external",
  version = "4.5",
)
bazel_dep(
  name = "bazel_skylib",
  version = "1.3.0",
)
```

#### `tools/local_modules/scala_2.13/extensions.bzl`

```python
load("@rules_jvm_external//:defs.bzl", "artifact", "maven_install")

SCALA_SUFFIX = "_2.13"

# ... 以下 tools/local_modules/default/extensions.bzl と同じ
```

#### `MODULE.bazel`

```python
bazel_dep(name = "mod_scala_multiverse")
local_path_override(
  module_name="mod_scala_multiverse",
  path="tools/local_modules/default",
)

maven = use_extension("@mod_scala_multiverse//:extensions.bzl", "maven")

maven.install(
    artifacts = [
        "com.squareup.okhttp3:okhttp:3.14.2",
        "com.typesafe::ssl-config-core:0.6.1",
        "org.asynchttpclient:async-http-client:2.0.39",
        "org.scalatest::scalatest:3.2.10",
        "org.slf4j:slf4j-api:1.7.28",
        "org.reactivestreams:reactive-streams:1.0.3",
    ],
)
use_repo(maven, "maven")
```

#### demo 5

```bash
$ bazel query 'filter('com_typesafe_ssl', @maven//...)'
@maven//:com_typesafe_ssl_config_core_2_12
@maven//:com_typesafe_ssl_config_core_2_12_0_6_1
Loading: 0 packages loaded

$ bazel query 'filter('com_typesafe_ssl', @maven//...)' --override_module=mod_scala_multiverse=$(pwd)/tools/local_modules/scala_2.13
@maven//:com_typesafe_ssl_config_core_2_13
@maven//:com_typesafe_ssl_config_core_2_13_0_6_1
```

これは、module extension を使って Scala 2.13 ライブラリ群へと依存性解決を切り替えることができたことを示す。
些細な問題だが、Scala バージョンの接尾詞がターゲット名に漏れ出しているのが分かる。

### 違いの取り繕い

`maven_dep()` というマクロを定義することで `@maven//:com_typesafe_ssl_config_core_2_12` と `@maven//:com_typesafe_ssl_config_core_2_13` の違いを取り繕うことができる。

#### `tools/local_repos/default/cross_scala_config.bzl`

```python
load("@io_bazel_rules_scala//:scala_config.bzl", "scala_config")

MULTIVERSE_NAME="default"
IS_SCALA_2_12 = True

def cross_scala_config(enable_compiler_dependency_tracking = False):
  scala_config(
    "2.12.14",
    enable_compiler_dependency_tracking=enable_compiler_dependency_tracking,
  )

TARGET_SCALA_SUFFIX="_2_12"

def maven_dep(coordinates_string):
  coord = _parse_maven_coordinates(coordinates_string)
  if coord["is_scala"]:
    artifact_id = coord["artifact_id"] + TARGET_SCALA_SUFFIX
  else:
    artifact_id = coord["artifact_id"]
  if "version" in coord:
    str = "@maven//:{}_{}_{}".format(coord["group_id"], artifact_id, coord["version"])
  else:
    str = "@maven//:{}_{}".format(coord["group_id"], artifact_id)
  return str.replace(".", "_").replace("-", "_")

def _parse_maven_coordinates(coordinates_string):
    """
    Given a string containing a standard Maven coordinate (g:a:[p:[c:]]v),
    returns a Maven artifact map (see above).
    See also https://github.com/bazelbuild/rules_jvm_external/blob/4.3/specs.bzl
    """
    if "::" in coordinates_string:
      idx = coordinates_string.find("::")
      group_id = coordinates_string[:idx]
      rest = coordinates_string[idx + 2:]
      is_scala = True
    elif ":" in coordinates_string:
      idx = coordinates_string.find(":")
      group_id = coordinates_string[:idx]
      rest = coordinates_string[idx + 1:]
      is_scala = False
    else:
      fail("failed to parse '{}'".format(coordinates_string))
    parts = rest.split(":")
    artifact_id = parts[0]
    if (len(parts)) == 1:
      result = dict(group_id=group_id, artifact_id=artifact_id, is_scala=is_scala)
    elif len(parts) == 2:
      version = parts[1]
      result = dict(group_id=group_id, artifact_id=artifact_id, version=version, is_scala=is_scala)
    elif len(parts) == 3:
      packaging = parts[1]
      version = parts[2]
      result = dict(group_id=group_id, artifact_id=artifact_id, packaging=packaging, version=version, is_scala=is_scala)
    elif len(parts) == 4:
      packaging = parts[1]
      classifier = parts[2]
      version = parts[3]
      result = dict(group_id=group_id, artifact_id=artifact_id, packaging=packaging, classifier=classifier, version=version, is_scala=is_scala)
    else:
      fail("failed to parse '{}'".format(coordinates_string))
    return result
```

#### 適当な BUILD

これは `::` を使って、`_2.12` という接尾詞付きの Scala ライブラリであることを表記する。

```python
load("@io_bazel_rules_scala//scala:scala.bzl", "scala_library")
load("@scala_multiverse//:cross_scala_config.bzl", "maven_dep")

scala_library(
    name = "main",
    srcs = glob(["*.scala"]),
    deps = [
        maven_dep("com.typesafe::ssl-config-core"),
        maven_dep("com.typesafe:config"),
        maven_dep("org.reactivestreams:reactive-streams"),
        maven_dep("org.slf4j:slf4j-api"),
    ],
    visibility = ["//visibility:public"],
)
```

### `bazelenv`

```bash
#!/usr/bin/env bash

MODE=$1
function usage() {
  echo "usage ./bazelenv [<multiverse>]"
  echo ""
  echo "available multiverses are:"
  candidates=$(/bin/ls tools/local_repos)
  echo "$candidates"
}
if [[ "$MODE" == "" ]]; then
  usage
elif [[ -d tools/local_repos/$MODE ]]; then
  echo "common --override_repository=scala_multiverse=$(pwd)/tools/local_repos/$MODE" > ".bazelenv"
  echo "common --override_module=mod_scala_multiverse=$(pwd)/tools/local_modules/$MODE" >> ".bazelenv"
else
  usage; exit 1
fi

```

#### demo 6

```bash
$ bazel query 'deps(//core/src/main:main)' | grep '@maven//:.*ssl-config.*'
Loading: 0 packages loaded
@maven//:v1/https/repo1.maven.org/maven2/com/typesafe/ssl-config-core_2.12/0.6.1/ssl-config-core_2.12-0.6.1.jar

$ ./bazelenv scala_2.13
$ bazel query 'deps(//core/src/main:main)' | grep '@maven//:.*ssl-config.*'
@maven//:v1/https/repo1.maven.org/maven2/com/typesafe/ssl-config-core_2.13/0.6.1/ssl-config-core_2.13-0.6.1.jar
```

### まとめ

- Bazel には [`local_repository`][local_repository] という機能が付いてきている。言語バージョンや 3rdparty のロックファイルなどをそこに押し込むことで、同一のモノリポのブランチから異なる設定を用いることができる。
- 現行のツールに対する多少の変更が必要になるかもしれないが、これは言語バージョンやライブラリのアップグレードなどさまざま軸に対してクロスビルドを行うことを示唆する。
- 新しい MODULE.bazel は module extension のオーバーライドを可能とし、そこで宣言的に定義された依存性を異なる方法で処理することができる。

### ライセンス

法令上認められる最大限の範囲で作者は、本稿におけるコード例の著作権および著作隣接権を放棄して、全世界のパブリック・ドメインに提供している。
コード例は一切の保証なく公開される。<http://creativecommons.org/publicdomain/zero/1.0/> 参照。
