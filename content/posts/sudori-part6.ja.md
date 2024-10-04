---
title:       "酢鶏、パート6: sbt query"
type:        story
date:        2024-09-28
draft:       false
url:         /ja/sudori-part6
tags:        [ "sbt" ]
---

  [part4]: /ja/sudori-part4
  [part5]: /ja/sudori-part5
  [sbt-remote-cache]: /ja/sbt-remote-cache
  [sbt-remote-cache-with-bazel-compat]: /ja/sbt-remote-cache-with-bazel-compat
  [sbt-2.0-ideas]: /sbt-2.0-ideas

本稿は sbt 2.x 開発に関する記事で、[sbt 2.x リモートキャッシュ][sbt-remote-cache]、[Bazel 互換な sbt 2.x リモートキャッシュ][sbt-remote-cache-with-bazel-compat]、[酢鶏、パート4][part4]、[パート5][part4] などの続編だ。僕は個人の時間を使って Scala Center や EngFlow の Billy さんなどのボランティアの人と協力して sbt 2.x の作業をしていて、このような記事はプルリクコメントの拡張版で、将来 sbt に実装されるかもしれない機能を共有できたらいいと思っている。

## sbt query

[sbt 2.0 ideas][sbt-2.0-ideas] で出したアイディアとして sbt query というものがある:

> [sbt query](https://github.com/sbt/sbt/discussions/6801) 参照。クエリはサブプロジェクトをふるい分けるのに使うことができる。

sbt-projectmatrix がデフォルトで使われるようになると、サブプロジェクトの数は増加することになる。大規模なコードベースで作業してる人は既に大量のサブプロジェクトを取り扱っているかもしれない。

sbt 2.0 でのタスク集約におけるサブプロジェクトのふるい分け機構をここで提案したい:

```bash
sbt .../test
sbt abc.../test
sbt ...@scalaBinaryVersion=3/test
```

スラッシュ構文にこれを統合させるというアイディアは[the GitHub discussion](https://github.com/sbt/sbt/discussions/6801) において Adrien Piquerez さんが提案したものだ。

### クエリ構文は何を行うか?

`print` コマンドと組み合わせた例だ:

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

このとき `...` は、全サブプロジェクトを意味し、sbt 1.x における `print name` と同義だ。次に、名前が `b` から始まるサブプロジェクトだけを表示してみる:

```scala
sbt:root> print b.../name
bar / name
  bar
baz / name
  baz
```

以下は、`scalaBinaryVersion` が `3` のサブプロジェクトだ:

```scala
sbt:root> print ...@scalaBinaryVersion=3/name
foo / name
  foo
name
  root
```

`scalaBinaryVersion` が `3` のサブプロジェクトのみをテストすることもできる:

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

Scala.JS と Native をサポートできるようになれば、`@platfomrm` でのフィルターも追加する予定だ:

```scala
sbt:root> ...@scalaBinaryVersion=3@platform=sjs1/test
```

## 詳細

プルリクは <https://github.com/sbt/sbt/pull/7699> だ。

### `...` と `@` を選んだ理由

例えば `*` と `?` を使わずに何故あえて `...` と `@` という組み合わせを選んだのか? 理由は、ドット (`.`) とアットマーク (`@`) がシェル環境でもクォートしなくても良いからだ。そのため、以下のように書くことができる:

```bash
$ sbt --client .../test
```

一方 `*` を採用した場合、これをクォートする必要がある。`*` は一見すると直観的な選択肢にみえるが、実際は落とし穴につながるアフォーダンス的押し扉を作ることになる。以下に具体例で解説しよう:

```bash
$ sbt */test
```

Bash では、`*/test` は `test` という名前のファイルやディレクトリを含むディレクトリにマッチするため、ある程度の確率で `src/test` にマッチしてしまい、以下が実行される:

```bash
$ sbt src/test
```

これは以下のようなエラーメッセージを表示して失敗する:

```bash
[error] Expected ID character
[error] Not a valid command: src (similar: set)
[error] Expected <unspecified>
[error] Expected '@scalaBinaryVersion='
[error] Expected project ID
[error] Expected configuration
[error] Expected ':'
[error] Expected key
[error] Not a valid key: src (similar: sources, ps, run)
[error] src/test
[error]    ^
```

GitHub issue などで、クエリを使おうと思ったが「Not a valid key: src」と表示されると質問する人が、何度も何度も出てくることが今から目に見える。

### `act` コマンド

sbt コア・コンセプトというトークを ScalaMatsuri 2019 で話したが、これを書いている時点ではもう 5年前となる:

<iframe width="560" height="315" src="https://www.youtube.com/embed/mY7zu21Cceg?si=KDA9XLGsbbFy0nuO&amp;start=259" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe>

トークの初めの方で `Command` は `State => State` の遷移関数だと言ったが、これは人間からのインプットや BSP の処理を行う。コマンド内でのタスクは並列処理されるが、コマンドラインの処理は逐次処理であることに注目してほしい。`shell` コマンドはユーザからのインプットを受け取り、`act` コマンドはスラッシュ構文で書かれたタスクをタスクエンジンに持ち上げる。ここで集約のロジックも処理されているため、sbt query を行うパーサーを `act` コマンドに導入すれば集約をフィルターできる。

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

ここでは for 内包表記を使って 2つのパーサーを合成している。最初のパーサーは最初のセグメントが sbt query であるかをチェックして、もしそうならば `askProject = false` を渡し、そうじゃなければ sbt 1.x 同様に `foo / Compile / compile` といった感じでサブプロジェクトをパースしようとする。

### タブ補完

動作した感じだと JLine のタブ補完はパーサーを何度も呼び出すことで実装されているみたいなので、sbt query 自体が何もマッチしなくても `Parser` は成功させる必要がある。そのため、クエリが空の場合はパーサーレベルで失敗させるのではなく、`emptyResult` というエラーメッセージを表示するだけの仮のパーサーを立てる。

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

### まとめ

<https://github.com/sbt/sbt/pull/7699> は、sbt 2.x 系におけるスラッシュ構文を拡張化してサブプロジェクトのふるい分けを行う機構を提案する。最初は、`scalaBinaryVersion` をパラメータとしてサポートするが、将来的には `platform` なども取り扱うと思う:

```scala
// TBD
sbt:root> ...@scalaBinaryVersion=3@platform=sjs1/test
```

上記は、Scala.JS 1.x のサブプロジェクト全てを（差分）テストするという意味になる。
