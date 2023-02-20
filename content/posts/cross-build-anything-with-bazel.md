---
title:       "cross build anything with Bazel"
type:        story
date:        2023-02-19
draft:       false
promote:     true
sticky:      false
url:         /cross-build-anything-with-bazel
tags:        [ "bazel", "scala" ]
---

  [local_repository]: https://bazel.build/versions/6.0.0/reference/be/workspace#local_repository
  [override_repository]: https://bazel.build/versions/6.0.0/reference/command-line-reference#flag--override_repository
  [rules_scala]: https://github.com/bazelbuild/rules_scala
  [bzlmod]: https://bazel.build/versions/6.0.0/build/bzlmod
  [module_extension]: https://bazel.build/external/extension
  [rules_jvm_external]: https://github.com/bazelbuild/rules_jvm_external/blob/master/defs.bzl

Bazel generally prefers monoversioning, in which all targets in the monorepo uses the same version given any library (JUnit or Pandas). Monoversioning greatly reduces the version conflict concerns within the monorepo, and in return enables better code reuse. In practice, monoversioning has a drawback of tying everyone at the hip. If service A, B, C, D, etc are all using Big Framework 1.1, it becomes costly to migrate all to Big Framework 1.2 if there might be a regression. Years would go by, and Big Framework 2.0 might come out, and again, it would be too risky.

In Scala ecosystem, using sbt, library authors often build a library against multiple versions of Scala standard libraries, or some other framework. This is called *cross building*. (Note that this is different from *cross compiling* from one CPU architecture like x86 to aarch64.)

This idea of cross building could be useful in Bazel as well, which allows the migration of some axis to take place *in situ* over a course of some time. For example you could start with Scala 2.12 in the monorepo, but gradually try to migrate to 2.13 such that most targets would build in *both* Scala 2.12 and Scala 2.13. This allows some teams to try out the new version ahead of everyone else while the codebase keeps marching on.

### local_repository hack

This week [@ianoc](https://macaw.social/@ianoc) showed me a trick that can be used as a mechanism of cross building in Bazel. We wanted it for Python 3rdparty dependencies, but in this post I'll demonstrate that we can use this to implement Scala cross building. (I am pretty sure Long Cao tried to explain this to me while waiting on a line to get into a bar last year, but at the time I didn't quite see how powerful this technique was.)

Here's the basics. You declare a [`local_repository`][local_repository] in the root `WORKSPACE` pointing to a subdirectory, like an in-workspace workspace. Then at runtime, you can override it to something else using [`--override_repository`][override_repository] flag. The local repository can expose constant variables, macros, targets, including files, which should be sufficient override anything.

### Hello world example

#### `WORKSPACE`

Here's a snippet of `WORKSPACE`:

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

See [rules_scala][rules_scala] for the rest of the file.

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

This demonstrates that from the commmand line we can switch the Scala version used for the build.

### Modifying the 3rdparty resolution (traditonal)

It depends on how you are currently handling 3rdparty resolution, but the basic idea is to either put the lock file or the `bzl` file into `tools/local_repos/default/` or `tools/local_repos/scala_2.13`.

For bazel-multiversion, the process looks like:

```bash
echo 'multiversion_config(scala_versions = ["2.12.14"])' > 3rdparty/jvm/BUILD
bin/multiversion import-build --output-path=tools/local_repos/default/jvm_deps.bzl
echo 'multiversion_config(scala_versions = ["2.13.6"])' > 3rdparty/jvm/BUILD
bin/multiversion import-build --output-path=tools/local_repos/scala_2.13/jvm_deps.bzl
```

Then in WORKSPACE,

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

### Switching out source code

In some situations, it would be convenient to switch out the source code depending on the Scala version etc.
Since we can expose variables from the local repository, implementing it is easy.

Recall that we've define a variable named `IS_SCALA_2_12`:

```python
IS_SCALA_2_12 = True
```

Let's say we want to use different source code for the hello world app, we could implement it as follows:

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

### Hiding the command line option

Let's say you would like to hide the command line option because it's too verbose.
We could do that using a `.bazelrc` file.

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

Using `.bazelrc`, we can now switch between the Scala version without passing in the command line option.

### Modifying the 3rdparty resolution (MODULE.bazel)

As of Bazel 6 [MODULE.bazel][bzlmod] ("Bzlmod") is no longer experimental, so naturally I wanted to see how this technique can be implemented in the new way. Unlike the traditional workspace way, [module extensions][module_extension] can only expose the extension or a repo.

**Update: 2023-02-20**: The general strategy seems to be use the tag class as declaration inside the `MODULE.bazel` file, and call repository rules inside the module extension to perform the side effects as before, including `http_archive(...)`. On Bazel Slack, Xudong Yang [wrote](https://bazelbuild.slack.com/archives/C014RARENH0/p1660212206376779?thread_ts=1659965864.646099&cid=C014RARENH0):

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

Thankfully [rules_jvm_external][rules_jvm_external] exposes `maven_install(...)` as a traditional repository rule, so we can use that as a Couriser frontend.

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
load("@rules_jvm_external//:defs.bzl", "maven_install")

SCALA_SUFFIX = "_2.12"

_install = tag_class(
  attrs = {
    "artifacts": attr.string_list(
      doc = "Maven artifact tuples, in `artifactId:groupId:version` format",
      allow_empty = True,
    ),
  },
)

def _modify_artifact(artifact):
  return artifact.replace("{scala_suffix}", SCALA_SUFFIX)

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

_install = tag_class(
  attrs = {
    "artifacts": attr.string_list(
      doc = "Maven artifact tuples, in `artifactId:groupId:version` format",
      allow_empty = True,
    ),
  },
)

def _modify_artifact(artifact):
  return artifact.replace("{scala_suffix}", SCALA_SUFFIX)

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
       "com.typesafe:ssl-config-core{scala_suffix}:0.6.1",
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

This shows that we were able to switch out the local module extension to resolve Scala 2.13 libraries.
A minor issue is that the Scala suffix bleeds out to the target name.

### Paper over the differences

We can paper over the difference between `@maven//:com_typesafe_ssl_config_core_2_12` and `@maven//:com_typesafe_ssl_config_core_2_13` by defining a macro.

### summary

- Bazel has a built-in feature called [`local_repository`][local_repository]. By pushing configurations related to the language versions and 3rdparty lock files into it, we can switch between different configurations while being on the same monorepo branch.
- Some tweaks to the existing tooling might be required, but generally this means that we can cross build along various axes like language versions and major library upgrades.
- The new MODULE.bazel allows overriding module extension, which we can use to process the declarative dependencies in different ways.
