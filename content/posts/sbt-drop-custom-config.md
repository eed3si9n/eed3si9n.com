---
title:       "RFC-3: drop custom config"
type:        story
date:        2023-03-26
url:         sbt-drop-custom-config
tags:        [ "sbt" ]
---

- Author: Eugene Yokota
- Date: 2023-03-26
- Status: **Review**

 [1]: https://ant.apache.org/ivy/history/2.3.0/ivyfile/configurations.html

In [sbt 2.0 ideas](/sbt-2.0-ideas) I wrote:

> **idea 3-A: limit dependency configuration to `Compile` and `Test`**
>
> Here are some more ideas to simplify sbt.
> sbt generally allows creating of custom dependency configuration, but it doesn't work well. For the most part, anything that requires custom configuration should likely be handled using separate subproject instead.

## problem space

Dependency configuration, such as `Compile`, `Test` etc, is a notion directly imported from Apache Ivy's [configuration][1], which allows custom configurations and `extends`-relationship among them. The shift in sbt 0.9 embraced configuration and enabled code reuse via `inConfig(...)(...)`. However, generally the custom configuration often requires reimplementation of all tasks, and thus the complete knowledge of the internals.

I've literally written a section called "You probably won't need your own configuration" in Plugin Best Practice guide in [2014](https://github.com/sbt/website/pull/22). If it's been a best practice to discourage the use for a decade, it's probably a good sign to drop the feature.

Since then we've dropped the use of Bintray (Ivy repo), and migrated for the most part to use Maven repo, which mostly supports `Compile` artifacts and their sources. IDE integration is shifting towards Build Server Protocol, which also supports `Compile` and `Test`.

## drop custom configuration

I propose that we drop `config` macro in sbt 2.0, so we only have the built-in configurations, such as `Compile` and `Test`. Any custom test configuration should migrated to be test inside another subproject instead.

### sandbox configuration

One trick that plugin authors use sometimes is to define a sandbox configuration to download JAR files using Coursier without affecting the dependency graph of the application. sbt itself uses this trick to download the Scala compiler JARs.

As a workaround, we can provide `PluginTool` configuration during sbt 1.x for this purpose:

```scala
lazy val PluginTool = Configuration.of(...)
```

### what about Provided?

I think `Provided` can stay.

### what about IntegrationTest?

`IntegrationTest` should be removed. It doesn't add anything useful besides the fact that it hangs off a subproject.

### migration for schema languages

Some plugins extends sbt by adding support for schema or otherwise alternative languages such as XML Schema, Procol Buffer etc. Generally I think they would belong to `Compile` configuration, placed under `src/main/xsd/` directory for XML Schema, and code generation can follow [Generating files](https://www.scala-sbt.org/1.x/docs/Howto-Generating-Files.html).

Specifically for Protocol Buffer, it seems like the [Google way](https://repo1.maven.org/maven2/com/google/api/grpc/proto-google-common-protos/2.14.3/) is to include both `.proto` file and `.class` files in a JAR:

```bash
$ unzip -l $HOME/Downloads/proto-google-common-protos-2.14.3.jar

    11216  03-14-2023 15:33   com/google/geo/type/Viewport.class
....
     2416  03-14-2023 15:33   google/geo/type/viewport.proto
....
```

## alternatives

### why not drop `Compile` and `Test` as well?

In Bazel for instance, there are only targets, and in fact tests are just other target(s). That would require creating a new `project`-equivalent thing for `Test`, like `testProject`, which would need its own name, and thus would change the shell invocation:

```bash
# sbt 1.x
> core/test

# if we did this
> coreTest/test
```

It doesn't look like a good trade to me.

## feedback

I created a discussion thread <https://github.com/sbt/sbt/discussions/7189>. Let me know what you think.
