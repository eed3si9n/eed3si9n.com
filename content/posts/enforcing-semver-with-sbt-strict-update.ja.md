---
title:       "sbt-strict-update を用いた Semantic Versioning の施行"
type:        story
date:        2020-12-14
draft:       false
promote:     true
sticky:      false
url:         /ja/enforcing-semver-with-sbt-strict-update
aliases:     [ /node/374 ]
tags:        [ "scala" ]
---

  [1]: https://github.com/sbt/sbt-strict-update
  [2]: https://github.com/scalacenter/sbt-eviction-rules
  [5976]: https://github.com/sbt/sbt/issues/5976
  [Publishing]: https://www.scala-sbt.org/1.x/docs/Publishing.html#Version+scheme

[Rob wrote](https://twitter.com/tpolecat/status/1338168877474308097):

> I want to tell sbt "this specific version breaks binary compatibility, so don't resolve it via eviction, fail the build instead." How do I do this? Complete answers only, I'm done trying to figure it out by following clues.
>
> sbt に「この特定のバージョンはバイナリ互換性を壊すからバージョンの解決をしないでビルドを失敗して」と言いたい。これはどうやるんだろうか? ヒントを追うのに疲れたので、完全な回答のみ募集。

これを行う小さな sbt プラグイン [sbt-strict-update][1] を書いた。

`project/plugins.sbt` に以下を追加:

```scala
addSbtPlugin("com.eed3si9n" % "sbt-strict-update" % "0.1.0")
```

そして `build.sbt` にこれを書く:

```scala
ThisBuild / libraryDependencySchemes += "org.typelevel" %% "cats-effect" % "early-semver"
```

それだけだ。

```scala
ThisBuild / scalaVersion := "2.13.3"
ThisBuild / libraryDependencySchemes += "org.typelevel" %% "cats-effect" % "early-semver"

lazy val root = (project in file("."))
  .settings(
    name := "demo",
    libraryDependencies ++= List(
      "org.http4s" %% "http4s-blaze-server" % "0.21.11",
      "org.typelevel" %% "cats-effect" % "3.0-8096649",
    ),
  )
```

もし Rob さんが上のビルドを `compile` しようとすると以下のように失敗するはずだ:

```bash
sbt:demo> compile
[warn] There may be incompatibilities among your library dependencies; run 'evicted' to see detailed eviction warnings.
[error] stack trace is suppressed; run last update for the full output
[error] (update) found version conflict(s) in library dependencies; some are suspected to be binary incompatible:
[error]
[error]   * org.typelevel:cats-effect_2.13:3.0-8096649 (early-semver) is selected over {2.2.0, 2.0.0, 2.0.0, 2.2.0}
[error]       +- demo:demo_2.13:0.1.0-SNAPSHOT                      (depends on 3.0-8096649)
[error]       +- org.http4s:http4s-core_2.13:0.21.11                (depends on 2.2.0)
[error]       +- io.chrisdavenport:vault_2.13:2.0.0                 (depends on 2.0.0)
[error]       +- io.chrisdavenport:unique_2.13:2.0.0                (depends on 2.0.0)
[error]       +- co.fs2:fs2-core_2.13:2.4.5                         (depends on 2.2.0)
[error] Total time: 0 s, completed Dec 13, 2020 11:53:31 PM
```

### 厳密な解決

依存性の解決をより厳密にするという試みはすでにいくつか行われた。今までの所ちゃんと動作する方法は無かったと思う。

潜在的な非互換性に関してユーザの注意を引こうとした僕の試みに eviction warning がある。しかし、良かれと思っても実際には偽陽性が多すぎて eviction warning ほど不人気な機能も無いんじゃないだろうか。

これは推論を全て無くすことで直すことができる。Scala Center とコラボしていた夏の間、`ThisBuild / versionScheme` を追加した。この情報によって eviction warning を改善できるが、そもそも何も警告しないかもし非互換性が分かっているならばビルドを失敗させるべきだ。

sbt-strict-update は eviction warning の下地を再利用するが、エラーであると確かに分かるまでは静かにしている。`versionScheme` はそんなにまだ使われていないので、Scala Center の [sbt-eviction-rules][2] のように `libraryDependencySchemes` キーを使ってアプリ・ユーザー側でライブラリのバージョンスキームを設定できるようにした。

### ThisBuild / versionScheme を設定しよう

ライブラリ作者の人は、`ThisBuild / versionScheme` セッティングを設定するようにしてください。詳細は [Publishing][Publishing] 参照。

### 次のステップ

sbt 1.5.0 では、既に [#5976][5976] などで提案されている通り eviction warning を削除して、この機能で置き換えるべきだと思う。
