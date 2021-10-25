---
title:       "Bintray を用いた sbt ビルドのリモートキャッシュ"
type:        story
date:        2020-10-25
changed:     2020-11-02
draft:       false
promote:     true
sticky:      false
url:         /ja/remote-caching-sbt-builds-with-bintray
aliases:     [ /node/365 ]
tags:        [ "sbt" ]
---

sbt と Zinc 1.4.x 系列で僕が時間と力をかけたのはおそらくファイルの仮想化とタイムスタンプを抜き出すことだ。この組み合わせによりマシン特定性と時から Zinc の状態を解放することができ、Scala のための差分リモートキャッシュを構築するための礎となる。これに関して[sbt でのコンパイルキャッシュ](https://eed3si9n.com/ja/cached-compilation-for-sbt)を書いた。これはその続編となる。

sbt 1.4.x が出たので、この機能を実際に使ってみたいという気運が一部高まっている。

### リモートキャッシュサーバー

リモートキャッシュを運用するには、リモートキャッシュサーバーが必要となる。初期のロールアウトでは、追加でサーバーを用意せずに簡単に試せるように Maven リポジトリ (`MavenCache("local-cache", file("/tmp/remote-cache"))` を含む) と互換を持たせるようにした。次のステップはこのリモートキャッシュをマシン間で共有することだ。

とりあえず [JFrog Bintray](https://bintray.com/) は Maven リポジトリとして振る舞うことができるという意味で良いフィットなんじゃないかと思う。Bintray に publish を行うには RESTful API を経由する必要があって、それは sbt-bintray がカプセル化している。

ちなみに Bazel は [HTTP プロトコルか gRPC][1] を用いたリモートキャッシュのサポートを提供し、これは Nginx、bazel-remote、Google Cloud Storage、その他 HTTP を話せるモノなら何でも実装できる。ライブラリ依存性と違って特に resolve する必要が無いので将来的にはそのような方向に移行するのが良いと思う。

### sbt-bintray-remote-cache

今すぐリモートキャッシュを使ってみたいという人のために、sbt-bintray のスピンオフとして sbt-bintray-remote-cache というプラグインを作った。

使うには以下を `project/plugins.sbt` に追加する:

```scala
addSbtPlugin("org.foundweekends" % "sbt-bintray-remote-cache" % "0.6.1")
```

#### Bintray リポとパッケージ

次に、`https://bintray.com/<your_bintray_user>/` に行って、新しい **Generic** なリポジトリを **`remote-cache`** という名前で作る。通常のアーティファクトとキャッシュが混ざらないようにするために、これは大切なステップだ。

それから、remote-cache リポジトリ内にパッケージを作る。基本的には 1つのビルドに対して 1つのパッケージを作る。

#### 認証情報

リモートキャッシュに push するには、Bintray の認証情報 (ユーザ名と API key) を認証ファイルもしくは環境変数にて渡す必要がある。ローカルでは sbt-bintray と同じ認証ファイルを使うことができる (`$HOME/.bintray/.credentials`)。CI マシーンでは sbt-bintray と**異なる**環境変数を使う:

- `BINTRAY_REMOTE_CACHE_USER` 
- `BINTRAY_REMOTE_CACHE_PASS`

これによって sbt-bintray と sbt-bintray-remote-cache で別の認証を使えるようにしている。

#### build.sbt

次に、`build.sbt` に以下を追加する:

```scala
ThisBuild / bintrayRemoteCacheOrganization := "your_bintray_user or organization"
ThisBuild / bintrayRemoteCachePackage := "your_package_name"
```

これで `ThisBuild / pushRemoteCacheTo` セッティングの設定が自動的に行われる。

#### リモートキャッシュへの push と pull

sbt シェルから `akka-actor/pushRemoteCache` と打ち込む:

```bash
akka > akka-actor/pushRemoteCache
[info] Wrote /Users/eed3si9n/work/quicktest/akka-0/akka-actor/target/scala-2.12/akka-actor_2.12-2.6.5+28-d4f0358c+20201025-1417.pom
[info] compiling 1 Scala source to /Users/eed3si9n/work/quicktest/akka-0/akka-actor/target/scala-2.12/classes ...
[info] Validating all packages are set private or exported for OSGi explicitly...
[warn] bnd: Unused Private-Package instructions, no such package(s) on the class path: [akka.osgi.impl]
[info]  published akka-actor_2.12 to https://api.bintray.com/maven/eed3si9n/remote-cache/akka/com/typesafe/akka/akka-actor_2.12/0.0.0-d4f0358cbd/akka-actor_2.12-0.0.0-d4f0358cbd.pom
[info]  published akka-actor_2.12 to https://api.bintray.com/maven/eed3si9n/remote-cache/akka/com/typesafe/akka/akka-actor_2.12/0.0.0-d4f0358cbd/akka-actor_2.12-0.0.0-d4f0358cbd-cached-compile.jar
[info]  published akka-actor_2.12 to https://api.bintray.com/maven/eed3si9n/remote-cache/akka/com/typesafe/akka/akka-actor_2.12/0.0.0-d4f0358cbd/akka-actor_2.12-0.0.0-d4f0358cbd-cached-test.jar
[success] Total time: 30 s, completed Oct 25, 2020 2:18:46 PM
```

このリモートキャッシュを使うには、`clean`、`akka-actor/pullRemoteCache`、そして `akka-actor/compile` と打ち込む:

```bash
akka > clean
[success] Total time: 5 s, completed Oct 25, 2020 2:19:10 PM
akka > akka-actor/pullRemoteCache
[info] Updating
https://api.bintray.com/maven/eed3si9n/remote-cache/akka/com/typesafe/akka/akka-actor_2.12/0.0.0-d4f0358cbd/akka-actor_2.12-0.0.0-d4f0358cbd.pom
  100.0% [##########] 1.5 KiB (1.4 KiB / s)
[info] Resolved  dependencies
[info] Fetching artifacts of
https://api.bintray.com/maven/eed3si9n/remote-cache/akka/com/typesafe/akka/akka-actor_2.12/0.0.0-d4f0358cbd/akka-actor_2.12-0.0.0-d4f0358cbd-cached-test.jar
  100.0% [##########] 388 B (473 B / s)
https://api.bintray.com/maven/eed3si9n/remote-cache/akka/com/typesafe/akka/akka-actor_2.12/0.0.0-d4f0358cbd/akka-actor_2.12-0.0.0-d4f0358cbd-cached-compile.jar
  100.0% [##########] 4.1 MiB (2.2 MiB / s)
[info] Fetched artifacts of
[info] remote cache artifact extracted for Some(cached-compile)
[info] remote cache artifact extracted for Some(cached-test)
[success] Total time: 4 s, completed Oct 25, 2020 2:19:20 PM
akka > akka-actor/compile
[info] Formatting 22 Java sources...
[info] Reformatted 0 Java sources
[info] Generating 'Tuples.scala'
[info] Generating 'Functions.scala'
[success] Total time: 2 s, completed Oct 25, 2020 2:19:35 PM
```

コンパイルが 2秒で終わった。akka-actor は通常 35~40s かかる。

#### 古いキャッシュの削除

バイナリのキャッシュが無限に溜まっていくのが心配という人もいるかもしれない。最低 100個は残して 1ヶ月以上前のキャッシュは削除するというタスクを作った。

```bash
akka > bintrayRemoteCacheCleanOld
[info] fetching package versions for package akka
[info] - 0.0.0-d4f0358cbd
[info] - 0.0.0-394b4fba9c
[info] about to delete Vector(0.0.0-d4f0358cbd, 0.0.0-394b4fba9c)
[info] eed3si9n/akka@0.0.0-d4f0358cbd was discarded
[info] eed3si9n/akka@0.0.0-394b4fba9c was discarded
```

### その他のこと

sbt 1.4.1 は Git commit id をリモートキャッシュid として使っているけども、コミットのたびにキャッシュが無効化されるは実は非常に効率が悪い。より良いソリューションは入力コンテンツのハッシュを使うことだと思う [sbt/sbt#5842](https://github.com/sbt/sbt/issues/5842)。これを実装した PR が [sbt/sbt#6026](https://github.com/sbt/sbt/pull/6026)。

より良いキャッシュ効果のためには、フォーマッターの状態や生成されるコードなどもキャッシュしていく必要があると思う。生成されるコードの再現性 (repeatability) を評価しなおす必要もある。

- Play が生成するコードを再現可能にするために、吉田さんは [xuwei-k/sbt-remote-cache-playframework](https://github.com/xuwei-k/sbt-remote-cache-playframework) を作っている。
- Arnout Engelen さんは [playframework/twirl#378](https://github.com/playframework/twirl/pull/378) で Twirl が生成するパスを相対パスにしてはどうかという提案をしている。

  [1]: https://docs.bazel.build/versions/2.0.0/remote-caching.html
