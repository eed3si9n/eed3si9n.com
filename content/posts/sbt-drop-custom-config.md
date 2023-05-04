---
title:       "RFC-3: drop custom config"
type:        story
date:        2023-03-26
url:         sbt-drop-custom-config
tags:        [ "sbt" ]
---

- Author: Eugene Yokota
- Date: 2023-03-26
- Status: **Partially Accepted**

 [1]: https://ant.apache.org/ivy/history/2.3.0/ivyfile/configurations.html
 [rfc2]: /sbt-2.0-rfc-process

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

I created a discussion thread <https://github.com/sbt/sbt/discussions/7189>. In there, there were some interesting inputs (reminder: [The goal of the RFC][rfc2] is to collectively explore the space of tradeoffs, and not everyone's opinion gets the same weight). In the thread Sébastien Doeraene wrote:

> There are in fact 2 very different things that `Configuration`s are used for: scoping tasks and settings, and namespacing library dependencies.
>
> ....
>
> I believe that we should deprecate custom configs for task scoping, but keep them for namespacing library dependencies.

The library dependency use cases listed in the threads are:

1. The `Provided` configuration namespaces dependencies that should be on the compilation classpath but not the runtime classpath.
2. Sandbox configuration used for library dependency to download tooling.
3. Olivier Mélois mentioned tagging schema as `"org" % "artifact" % "version" % Smithy4s`, which allows Smithy graph to utilize dependency tooling like scala-steward.

These are  interesting observations. Per Sébastien's suggestion, we would deprecate the scoping usage (for example `Docker / publishLocal`), but keep the `% FooConfig` usage. My counter argument is that the custom configuration resolution is a feature leakage from Apache Ivy days, and we'd be better off using synthetic subproject instead of creating a sandbox configuration.

To this Sébastien pointed out that creating synthetic subproject might incur overhead.

Since the main goal of RFC-3 proposal is to simplify the scoping, we could achieve that by limiting settings and task scoping to `Compile` and `Test`. At least for now, we should keep the library dependency namespacing via `% FooConfig` until the subproject performance is improved.

There was also a side suggestion to rename `Compile` to `Main`. I am undecided whether this is good idea or not. On on hand this makes it more consistent with `src/main/`. On the other than, Maven and Ivy both calls it `compile` scope, and it shows up in `build.sbt` as `"compile->test"` as well, so making this change would likely require long tail of `Compile` being alive.

## outcome

- 2023-04-23: This RFC is **partially accepted** / put on-hold.
- `IntegrationTest` configuration should be deprecated.
- Setting and task scoping will be limited to `Compile` and `Test` configuration.
- Base on the feedback, we'll put the removal of custom configuration **on hold** until we can find suitable replacement for library dependency namespace.
- I am not sure renaming `Compile` to `Main` is good idea or going to be easy.
