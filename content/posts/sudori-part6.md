---
title:       "sudori part 6: sbt query"
type:        story
date:        2024-09-26
draft:       false
url:         /sudori-part6
tags:        [ "sbt" ]
---

  [part4]: /sudori-part4
  [part5]: /sudori-part5
  [sbt-remote-cache]: /sbt-remote-cache
  [sbt-remote-cache-with-bazel-compat]: /sbt-remote-cache-with-bazel-compat
  [sbt-2.0-ideas]: /sbt-2.0-ideas

This is a blog post on sbt 2.x development, continuing from [sbt 2.x remote cache][sbt-remote-cache], [sbt 2.x remote cache with Bazel compatibility][sbt-remote-cache-with-bazel-compat], [sudori part 4][part4], [part 5][part5] etc. I work on sbt 2.x in my own time with collaboration with the Scala Center and other volunteers, like Billy at EngFlow.

## sbt query

In [sbt 2.0 ideas][sbt-2.0-ideas] I mentioned:

> See [sbt query](https://github.com/sbt/sbt/discussions/6801). Query would be used to filter down the subprojects:

Once we have sbt-projectmatrix by default, there will be an increase in the number of subprojects. If you work on a large code base you might already have a lot of subprojects that you need to deal with.

For sbt 2.0, I'd like to propose a new mechanism of filtering down the subprojects during task aggregation:

```bash
sbt .../test
sbt abc.../test
sbt ...@scalaBinaryVersion=3/test
```

The idea of integrating with the existing slash syntax was proposed by Adrien Piquerez on [the GitHub discussion thread](https://github.com/sbt/sbt/discussions/6801).

### What does query syntax do?

Here's an example combined with `print` command:

```scala
sbt:root> print .../name
foo / name
  foo
bar / name
  bar
baz / name
  baz
name
  root
```

`...` here means match all subprojects, which is the same as saying `print name` in sbt 1.x. Next, we can show the names of subprojects that starts with b only:

```scala
sbt:root> print b.../name
bar / name
  bar
baz / name
  baz
```

Next, we can show only the subprojects whose `scalaBinaryVersion` is `3`:

```scala
sbt:root> print ...@scalaBinaryVersion=3/name
foo / name
  foo
name
  root
```

We can also test only the subprojects whose `scalaBinaryVersion` is `3`:

```scala
sbt:root> ...@scalaBinaryVersion=3/test
[info] Passed: Total 0, Failed 0, Errors 0, Passed 0
[info] No tests to run for foo / Test / testQuick
[info] compiling 1 Scala source to target/out/jvm/scala-3.3.1/root/backend ...
[info] compiling 1 Scala source to target/out/jvm/scala-3.3.1/root/test-backend ...
[info] Passed: Total 0, Failed 0, Errors 0, Passed 0
[info] No tests to run for Test / testQuick
[success] elapsed time: 3 s, cache 58%, 7 disk cache hits, 5 onsite tasks
```

When we have Scala.JS and Native support, we'll probalby add a way to filter by `@platform` as well. I think it would look like:

```scala
sbt:root> ...@scalaBinaryVersion=3@platform=sjs1/test
```

## details

The PR is at <https://github.com/sbt/sbt/pull/7699>.

### the choice of `...` and `@`

Why use `...` and `@` instead of, let's say `*` and `?`? The dot (`.`) and at-sign (`@`) seem to work on shell evironment without quoting. So I could write:

```bash
$ sbt --client ...@scalaBinaryVersion=3/test
```

Otherwise, we would need to quote that.

### `act` command

sbt core concepts that I gave in Scala Days 2019 is five years ago as of this writing:

<iframe width="560" height="315" src="https://www.youtube.com/embed/-shamsTC7rQ?si=UwMCsQ2rryet0TmQ&amp;start=334" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe>

I start the talk by describing `Command` as `State => State` transformation function, which handles human and BSP interactions. Note that within a command _tasks_ are executed in parallel, but the command-line interaction is sequential. The `shell` command accepts inputs from the user, and the `act` command lifts the task written in slash syntax into the task engine. This is also where the aggregation logic is handled, so we can introduce a new parser for the sbt query in the `act` command to change the way aggregation is filtered.

```scala
def scopedKeyAggregatedFilter(
    current: ProjectRef,
    defaultConfigs: Option[ResolvedReference] => Seq[String],
    structure: BuildStructure
): KeysParserFilter =
  for
    optQuery <- queryOption.?
    selected <- scopedKeySelected(
      structure.index.aggregateKeyIndex,
      current,
      defaultConfigs,
      structure.index.keyMap,
      structure.data,
      askProject = optQuery.isEmpty,
    )
  yield Aggregation
    .aggregate(selected.key, selected.mask, structure.extra)
    .map(k => k.asInstanceOf[ScopedKey[Any]] -> optQuery)

private def queryOption: Parser[ProjectQuery] =
  ProjectQuery.parser <~ spacedSlash
```

Here, I'm using for comprehension to compose two parsers. First one checks if the first segment is an sbt query, and if so pass in `askProject = false`, otherwise we will ask project `foo / Compile / compile` like in sbt 1.x.

### tab completion

The way tab completion works with JLine (I think) is to repeatedly try different parsers, so we have to make sure that `Parser` would succeed, even if the sbt query might return nothing. So instead of outright failing at the parser level, we actually produce a dummy parser called `emptyResult`, which would be used only to show an error message.

```scala
def emptyResult: Parser[() => State] =
  Parser.success(() => throw MessageOnlyException("query result is empty"))

for
  keys <-
    action match
      case SingleAction => akp
      case ShowAction | PrintAction | MultiAction =>
        for pairs <- rep1sep(akp, token(Space))
        yield pairs.flatten
  keys1 = applyQuery(keys, structure)
  p <-
    if keys.nonEmpty && keys1.isEmpty then emptyResult
    else evaluate(keys1.map(_._1))
yield p
```

### summary

<https://github.com/sbt/sbt/pull/7699> implements an extention to slash syntax, which allows filtering of subprojects for sbt 2.x. Initially this will support `scalaBinaryVersion` as parameter, but likely we'll support `platform` as well:

```scala
// TBD
sbt:root> ...@scalaBinaryVersion=3@platform=sjs1/test
```

The above would mean run (incremental) tests on all Scala.JS 1.x subprojects.
