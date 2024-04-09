---
title: "Bazel 互換な sbt 2.x リモートキャッシュ"
type: story
date: 2024-04-05
url: /ja/sbt-remote-cache-with-bazel-compat
tags: [ "sbt" ]
---

  [remote_execution.proto]: https://github.com/bazelbuild/remote-apis/blob/main/build/bazel/remote/execution/v2/remote_execution.proto
  [bazel-remote]: https://github.com/buchgr/bazel-remote
  [engflow]: https://www.engflow.com/
  [buildbuddy]: https://www.buildbuddy.io/
  [buildbuddy-oss]: https://github.com/buildbuddy-io/buildbuddy
  [nativelink]: https://docs.nativelink.dev/
  [develocity]: https://gradle.com/gradle-enterprise-solutions/bazel-build-system/
  [buildfarm]: https://github.com/bazelbuild/bazel-buildfarm
  [Boulet2024]: https://medium.com/teads-engineering/leveraging-sbt-remote-caching-on-a-big-modular-monolith-84826f949ae8
  [contraband]: https://www.scala-sbt.org/contraband/
  [part2]: /ja/sbt-remote-cache
  [shaded-remoteapis-java]: https://repo1.maven.org/maven2/com/eed3si9n/remoteapis/shaded/shaded-remoteapis-java/2.3.0-M1-52317e00d8d4c37fa778c628485d220fb68a8d08/
  [buildbarn]: https://github.com/buildbarn
  [cached-compilation-for-sbt]: /ja/cached-compilation-for-sbt

本稿は sbt 2.x リモートキャッシュ関連の第3部だ。ここ数年自分の時間を使って sbt 2.x の開発を行っていて、最近は Scala Center にも手伝ってもらっている。これらの記事はプルリクコメントの拡張版で将来 sbt に実装されるかもしれない機能を共有できたらいいと思っている。

約1年前 sbt 2.x における自動キャッシュ・タスクの設計の提案を [RFC-1: sbt cache ideas](/sbt-cache-ideas/) で行い、[「sbt 2.x リモートキャッシュ」][part2]では実装の解説を行った:

```scala
someKey := Def.cachedTask {
  val output = StringVirtualFile1("a.txt", "foo")
  Def.declareOutput(output)
  name.value + version.value + "!"
}
```

リモートキャッシュは、マシン間でビルドの結果を共有することで劇的な性能の改善を可能とする。2020年に、僕は sbt 1.x の[コンパイルキャッシュ](/cached-compilation-for-sbt)を実装した。これも `compile` タスクに限られていたが、有意な性能向上があることが何例も報告されている。最近だと、[Leveraging sbt remote caching on a big modular monolith][Boulet2024] (2024) において、Teads 社の Sébastien Boulet さんが以下のように書いている:

> 完全キャッシュ・ヒットの場合は sbt ビルドは 3分30秒かかる。全てのタスクがキャッシュ化されているわけでは無いのでやはり数分かかってしまう。(中略) 一方、Scala Steward がプルリクを送ってライブラリが更新するなどして完全キャッシュ・ミスがあった場合は全てがリビルドされ、テストが実行される。これは 45分かかる。そのため、完全キャッシュ化されたビルドは 92% 効率化されていると言える。
>
> 実際に、エンジニアが経験するのはこの両極端の間のどこかに位置して、導入した変更に応じて著しくビルド時間の変化がある。

sbt 2.x のキャッシュに戻ると、これまでの所 `compile` タスクを例に汎用的な機構を作るための基盤を入れ替えることに集中してきたので、リモート・キャッシュと言えどまだ「分散」の部分には手を出していなかった。本稿ではこれを見ていく。

![sbt 2.x and bazel-remote](/images/bazel-remote-2024.png)

実装の提案は [sbt/sbt#7525](https://github.com/sbt/sbt/pull/7525) にある。

<!-- more -->

### Bazel とそのリモート・キャッシュ

Bazel はオープンソースなビルド・ツールでその点では Make や sbt と一緒だ。Bazel の特徴は、再現性とキャッシュ化を中心に設計されていることだ。Bazel はディスク・キャッシュとリモート・キャッシュの両方をサポートして、リモート・キャッシュが用いるプロトコルは公開されていて、gRPC 経由の [Remote Execution API][remote_execution.proto] と普通の HTTP がある。現在オープンソース、専有を含め一般に知られているだけでも 11のリモート・キャッシュ・バックエンド実装がある (非公開のものを何個かいじった事があるので、各社色々作っているんだと思う)。Language Server Protocol の構図と似てて、Buck2 など Bazel 以外のビルドツールもこの API をサポートし始めている。名前の通り、API はリモート実行もサポートするが、今回はキャッシュ用のエンドポイントだけ使う。

一応補足しておくと、僕は sbt のリモート・キャッシュのバックエンドは Bazel のリモート・キャッシュのみに限定することは提案していない。そうではなく、僕が提案したいのは必要条件となる情報を捕獲することで、もしそうしたければ sbt があたかも Bazel であるかのように Bazel リモート・キャッシュと話せるようにできる事を提案したい。この特性を**Bazel 互換**と呼ぼう。追加で、例えば S3 をキャッシュと使うように拡張したい人がいれば 6つのメソッドを実装するだけでそれは可能になっている。

Bazel 互換であることの利点の 1つとして、実戦で鍛えられた作法に従えることが挙げられる。例えば、全てのタスク入力の SHA-256 (これは SHA-512 などにも拡張可能)、アウトプットされるファイルの SHA-256、およびファイルのサイズを追跡することだ。

### cacheStores の流れ

sbt 2.x は `cacheStores` という新しいセッティングを導入する。決定の流れは以下の図のようになる:

```
  ┌────────────┐ yes?  ┌─────┐          
  │ Disk Cache ├──────►│ JAR │          
  └─┬──────────┘       └───▲─┘          
    │ no                   │            
┌───▼──────────┐ yes?  ┌───┴─────────┐  
│ Remote Cache ├──────►│ Download to │  
└───┬──────────┘       │ Disk Cache  │  
    │ no               └─────────────┘  
    │                                   
┌───▼──────────┐       ┌───────────────┐
│ Onsite Task  ├──────►│ Upload to     │
└──────────────┘       │ Remote Cache/ │
                       │ Copy to       │
                       │ Disk Cache    │
                       └───────────────┘
```

キャッシュ化可能なタスクに関しては、sbt は登録されている cacheStore を順に試して、キャッシュに入っていれば JAR などのアウトプットを使う。まず、ディスク・キャッシュを試して、そこに JAR ファイルがあれば、それを使う。次に、リモート・キャッシュを試す。アクション・キャッシュが見つからなければ、sbt はタスクをオンサイトで実行して、`put(...)` を呼んでダイジェストとアウトプットをコピーもしくはアップロードを行う。

## Bazel のリモート・キャッシュ実装を用いたテスト

Remote Execution API というプロトコルは 1つであるのは間違い無いが、実際に色々なバックエンドを試してみると微妙な違い (と僕のコード内のバグ) が見つかり、ちょこちょこ直しながらテストを行った。以下では 4つの Bazel リモート・キャッシュ・バックエンドを見ていく。

### gRPC 認証

[gRPC 認証](https://grpc.io/docs/guides/auth/)にもいくつか種類があって、 Bazel リモート・キャッシュ・バックエンドはそれぞれ色々な認証を行っている:

1. 認証なし。テスト時によく使われる。
2. Default TLS/SSL.
3. TLS/SSL with custom server certificate.
4. TTL/SSL with custom server and client certificate, mTLS.
5. Default TLS/SSL with API token header.

### buchgr/bazel-remote

buchgr/bazel-remote はオープンソースで最初に思いついたリモート・キャッシュなので、ここから始めるのがいいと思った。コードを [buchgr/bazel-remote][bazel-remote] から引っ張ってきて、ラップトップ上で `bazel` を使えばそのまま実行できる:

```bash
bazel run :bazel-remote  -- --max_size 5 --dir $HOME/work/bazel-remote/temp \
  --http_address localhost:8000 \
  --grpc_address localhost:2024
```

うまくいけば以下のように表示されるはずだ:

```bash
$ bazel run :bazel-remote  -- --max_size 5 --dir $HOME/work/bazel-remote/temp \
  --http_address localhost:8000 \
  --grpc_address localhost:2024
....
2024/03/31 01:00:00 Starting gRPC server on address localhost:2024
2024/03/31 01:00:00 HTTP AC validation: enabled
2024/03/31 01:00:00 Starting HTTP server on address localhost:8000
```

sbt 2.x を設定するには、`project/plugins.sbt` に以下のように書く:

```scala
addRemoteCachePlugin
```

そして `build.sbt` に以下を追加する:

```scala
Global / remoteCache := Some(uri("grpc://localhost:2024"))
```

sbt シェルを起動して、`compile` を走らせる:

```bash
$ sbt
sbt:remote-cache-example> compile
```

以下のように表示される:

```bash
sbt:remote-cache-example> compile
[info] compiling 1 Scala source to target/out/jvm/scala-3.3.0/remote-cache-example/classes ...
[success] elapsed time: 3 s, cache 0%, 1 onsite task
sbt:remote-cache-example> exit
```

buchgr/bazel-remote 側のターミナルでは以下のように表示される:

```bash
2024/03/31 01:00:00 GRPC AC GET d88e3626474d51fb4863a41eaf3005eda5e2b738fdaaec31d096b01bc6cefeba NOT FOUND
2024/03/31 01:00:00 GRPC CAS HEAD db6c5dd72d04cdf04be5021ef4ef913968269b4bab384c0ac31d7aa85c40b319 OK
2024/03/31 01:00:00 GRPC CAS PUT d9ce4f88979fc075338ba7f3213fa5dbe871d255eb6c7b733fba226e59f4cfd3 OK
2024/03/31 01:00:00 GRPC CAS PUT c4d4c1119e10b16b5af9b078b7d83c2cd91b0ba61979a6af57bf2f39ae649c11 OK
2024/03/31 01:00:00 GRPC AC PUT d88e3626474d51fb4863a41eaf3005eda5e2b738fdaaec31d096b01bc6cefeba O
```

ここから sbt が d88e36 という AC (action cache) をクエリしようとしたが、キャッシュ・ミスで、sbt がオンサイトで有機タスク実行を行い、AC d88e36 に付随する 2つのブロブをアップロードしたことが解析できる。

次に、ディスク・キャッシュとローカルの `target` ディレクトリを消去して再試行してみよう。リモート・キャッシュがうまくいけば、タスクを実行する代わりに JAR のダウンロードを行うはずだ:

```bash
$ rmtrash $HOME/Library/Caches/sbt/v2/ && rmtrash target
$ sbt
sbt:remote-cache-example> compile
```

以下のように表示される:

```bash
sbt:remote-cache-example> compile
[success] elapsed time: 1 s, cache 100%, 1 remote cache hit
sbt:remote-cache-example> run
[info] running example.main
Hello
[success] elapsed time: 1 s, cache 50%, 1 remote cache hit, 1 onsite task
```

これは Bazel リモート・キャッシュから JAR を引っ張ってきて、ちゃんと実行できることを示す。うまくいったみたいだ。

### mTLS の設定

実際の運用では mTLS を使うことで相互認証を行い、かつトランスポートが符号化される事を保証できる。buchgr/bazel-remote を以下のようにして起動することでこれをテストできる:

```bash
bazel run :bazel-remote  -- --max_size 5 --dir $HOME/work/bazel-remote/temp \
  --http_address localhost:8000 \
  --grpc_address localhost:2024 \
  --tls_ca_file /tmp/sslcert/ca.crt \
  --tls_cert_file /tmp/sslcert/server.crt \
  --tls_key_file /tmp/sslcert/server.pem
```

このシナリオでは sbt.x 側のセッティングは以下のようになる:

```scala
Global / remoteCache := Some(uri("grpcs://localhost:2024"))
Global / remoteCacheTlsCertificate := Some(file("/tmp/sslcert/ca.crt"))
Global / remoteCacheTlsClientCertificate := Some(file("/tmp/sslcert/client.crt"))
Global / remoteCacheTlsClientKey := Some(file("/tmp/sslcert/client.pem"))
```

ここでは `grpc://` では無く `grpcs://` となることに注意。

### EngFlow

[EngFlow GmbH][engflow]社は 2020年に元 Bazel チームのコアメンバーによって立ち上げられたビルド・ソリューション系のスタートアップ企業で、ビルド解析とリモート実行のための商用サービスする。sbt 2.x は Build Event Protocol (BEP) データを生成しないため、EngFlow のリモートキャッシュ機能のみを使うことになる。

<https://my.engflow.com/> からトライアル版に登録すると、Docker でトライアル・クラスターを立ち上げるようドキュメントに書いてある。

```bash
docker run \
  --env CLUSTER_UUID=.... \
  --env UI_URL=http://localhost:8080 \
  --env DATA_DIR=/usr/share/myengflow_mini \
  --publish 8080:8080 \
  --pull always \
  --rm \
  --volume ~/.cache/myengflow_mini:/usr/share/myengflow_mini \
  ghcr.io/engflow/myengflow_mini
```

この指示通りに動かすと 8080番ポートでリモート・キャッシュ・サービスが起動する。トライアル・クラスターを使うための sbt 2.x 側の設定は以下のようになる:

```scala
Global / remoteCache := Some(uri("grpc://localhost:8080"))
```

以下を 2回実行する:

```bash
$ rmtrash $HOME/Library/Caches/sbt/v2/ && rmtrash target
$ sbt
sbt:remote-cache-example> compile
```

このように表示されるはずだ:

```bash
sbt:remote-cache-example> compile
[success] elapsed time: 1 s, cache 100%, 1 remote cache hit
```

### BuildBuddy

[BuildBuddy][buildbuddy] は、ビルド・ソリューションを提供する企業で、ここも 2019年に元 Google社員によって起業され、Bazel のためのビルド解析とリモート実行バックエンドをサービスとして提供する。尚これは、[buildbuddy-io/buildbuddy][buildbuddy-oss] としてオープン・ソースでも公開されている。

登録すると BuildBuddy Personal プランでもインターネット越しに BuildBuddy を使うことができる。

1. <https://app.buildbuddy.io/> から Settings に行って、Organization URL を `<何か>.buildbuddy.io` に変更する。
2. 次に、Quickstart に行って、URL と `--remote_headers` を書き留める。
3. `$HOME/.sbt/buildbuddy_credential.txt` というファイルを作って API key を書く:

```
x-buildbuddy-api-key=*******
```

sbt 2.x 側の設定は以下のようになる:

```scala
Global / remoteCache := Some(uri("grpcs://something.buildbuddy.io"))
Global / remoteCacheHeaders += IO.read(BuildPaths.defaultGlobalBase / "buildbuddy_credential.txt").trim
```

以下を 2回実行する:

```bash
$ rmtrash $HOME/Library/Caches/sbt/v2/ && rmtrash target
$ sbt
sbt:remote-cache-example> compile
```

このように表示されるはずだ:

```bash
sbt:remote-cache-example> compile
[success] elapsed time: 1 s, cache 100%, 1 remote cache hit
```

### NativeLink

[NativeLink][nativelink] は比較的新しいオープンソースのリモート実行バックエンドで、Rust で実装されており、高速であることにこだわっている。

```bash
cargo install --git https://github.com/TraceMachina/nativelink --tag v0.2.0
curl -O https://raw.githubusercontent.com/TraceMachina/nativelink/main/nativelink-config/examples/basic_cas.json
nativelink basic_cas.json
```

デフォルトの設定だと、50051番ポートでリモート・キャッシュが起動するはずだ。sbt 2.x 側の設定は以下のようになる:

```scala
Global / remoteCache := Some(uri("grpc://localhost:50051/main"))
```

`/main` というふうにインスタンス名を指定していることに注意。以下を 2回実行する:

```bash
$ rmtrash $HOME/Library/Caches/sbt/v2/ && rmtrash target
$ sbt
sbt:remote-cache-example> compile
```

このように表示されるはずだ:

```bash
sbt:remote-cache-example> compile
[success] elapsed time: 1 s, cache 100%, 1 remote cache hit
```

### 選外佳作

- [Buildfarm][buildfarm] はオープンソースな Bazel リモートキャッシュ実装の一つで 2017年頃からある。
- [Buildbarn][buildbarn] も結構前からあるオープンソースな Bazel リモートキャッシュ実装。これはまだ試していない。

### 技術的詳細

ここから、リモートキャッシュを実装しながら気づいた技術的詳細などをメモしておく。

#### gRPC

gRPC は、Google が開発したリモート・プロシージャ・コール (RPC) のためのオープンソースなフレームワークだ。ワイヤ・プロトコルを先に定義してから、多言語でスタブを生成して、そのプロトコルを利用して相互通信できるという意味では SOAP の現代版と言えるのではないかと思う。[Remote Execution API][remote_execution.proto] は、1つのプロトコルが Scala、Go、Rust などによって実装されている良い例だ。スタブが関数を定義してくれるので、コードを書いている際には一切パーシングをしなくても良い。Protocol Buffer に基づいているため、API を進化していけるのも強みだ。

remote-apis をフォークして、Java のスタブを追加する sbt ビルドを追加して、ライブラリを shade して Maven Central に [com.eed3si9n.remoteapis.shaded:shaded-remoteapis-java][shaded-remoteapis-java] として公開した。

#### Contraband

sbt のコードベースでは Protobuf に似たアイディアで [Contraband][contraband] を使っていて、これはデータ型を記述するインターフェイス言語だ。JSON のバインディングの自動生成の他、Scala ではバイナリ互換な進化を可能とする疑似 case class を生成する。

例えば、以下は `ActonResult` の定義で、これは Remote Execution API の要となる同名のデータ構造を sbt 内部に合わせて少し変えたものだ:

```python
package sbt.util
@target(Scala)
@codecPackage("sbt.internal.util.codec")
@fullCodec("ActionResultCodec")

## An ActionResult represents a result from executing a task.
## In addition to the value typically represented in the return type
## of a task, ActionResult tracks the file output and other side effects.
type ActionResult {
  outputFiles: [xsbti.HashedVirtualFileRef] @since("0.1.0")
  origin: String @since("0.2.0")
  exitCode: Int @since("0.3.0")
  contents: [java.nio.ByteBuffer] @since("0.4.0")
  isExecutable: [Boolean] @since("0.5.0")
}
```

Contraband は `sjsonnew.JsonFormat` コーデックを自動導出するので、それを用いて SHA-256 のハッシュを計算することもできる (詳細は[「sbt 2.x リモートキャッシュ」][part2]参照)。

#### ActionCacheStore の変更点

ローカルでのディスク・ストーレジを含むリモート・キャッシュ・バックエンドは以下の trait の 6つのメソッドによって抽象化される (今後も調整が入るかもしれないが):

```scala
/**
 * An abstration of a remote or local cache store.
 */
trait ActionCacheStore:
  /**
   * A named used to identify the cache store.
   */
  def storeName: String

  /**
   * Put a value and blobs to the cache store for later retrieval,
   * based on the `actionDigest`.
   */
  def put(request: UpdateActionResultRequest): Either[Throwable, ActionResult]

  /**
   * Get the value for the key from the cache store.
   * `inlineContentPaths` - paths whose contents would be inlined.
   */
  def get(request: GetActionResultRequest): Either[Throwable, ActionResult]

  /**
   * Put VirtualFile blobs to the cache store for later retrieval.
   */
  def putBlobs(blobs: Seq[VirtualFile]): Seq[HashedVirtualFileRef]

  /**
   * Materialize blobs to the output directory.
   */
  def syncBlobs(refs: Seq[HashedVirtualFileRef], outputDirectory: Path): Seq[Path]

  /**
   * Find if blobs are present in the storage.
   */
  def findBlobs(refs: Seq[HashedVirtualFileRef]): Seq[HashedVirtualFileRef]
end ActionCacheStore
```

12月に `Def.cachedTask` を実装したときも一応 API にも目を通したが、`ActionResult[A1]` が型 `A1` の値を持つなど、一部自分の想像に任せて実装した。実際に gRPC クライアントの実装を始めると、API はよりシンプルなものであることが分かってきた。全てのコンテンツは CAS (content addressable storage) で管理され、`ActionResult` はアウトプット・ファイルのリストを持つ。そのため、`ActionResult` は型パラメータ化するべきではない。ただし、`get(...)` 呼び出し時にアウトプットをレスポンスにインライン化することを要請できるので、僕が完全に間違ってわけでも無い。そのため、タスク結果を JSON にエンコードできれば、`ActionResult` 内にそれをペイロードとして乗せることで `syncBlobs(...)` 呼び出しがその分無くなり、ネットワーク往復を 1つ省ける。

#### Digest の変更点

12月の時点で読み誤ったものがもう 1つあって、それは `Digest` だ。

```
コンテンツのダイジェスト。任意のブロブのダイジェストは、
そのブロブのサイズ及びハッシュによって構成される。
使用するハッシュ・アルゴリズムはサーバーによって定義される。

サイズはダイジェストに不可欠なものだと考慮され、
分けてはいけない。つまり、`hash` フィールドが正しく指定
されても、`size_bytes` が正しくなければサーバは
必ず (MUST) リクエストを拒否しなければいけない。
```

API のコメントは `size_bytes` がファイルサイズを表すことを明記しているが、ダイジェスト計算にこれが必要なことは見逃していた。しばらくの間僕はダイジェストのサイズを送って、何回やってもキャッシュミスするので不思議に思っていた。ダイジェストを直すと、ブロブがキャッシュから受け取れるようになった。

#### プラグイン

[com.eed3si9n.remoteapis.shaded:shaded-remoteapis-java][shaded-remoteapis-java] が 11MB と少し大きいので、Bazel互換機能はプラグインとして実装した。これによって、この機能が欲しい人だけがオプトインできる。

#### 課題: フォールバック?

Bazel について長々と書いているが、実は完璧なシステムだとは思っていない。前回もキャッシュに関する落とし穴をいくつか列挙した。特に[パッケージ集約問題](/sbt-remote-cache/#package-aggregation)は重要だ:

> 問題を要約すると、1つのサブプロジェクトにより多くのソースファイルが集約すると、サブプロジェクト間の依存性がより密になってしまい、依存性グラフを逆向きにするという単純な無効化だと、コード変更による初期の無効化が山火事のようにモノリポ全体に広がってしまうという問題だ。

Bazel はパッケージを小さくしたり、strict deps を用いてこの対策を行うが、sbt は Zinc を経由して言語レベルで行動しているので無効化の管理に関してはもっと上手だ。例えば、`B.scala` が `A.scala` を使っていて `A.scala` が変更されたとしても、`B.scala` が使っている実体のシグネチャが変更されなければ `B.scala` は無効化されない。

[sbt 1.x でのキャッシュ][cached-compilation-for-sbt] (2020) では、前の git commit に関連した Zinc Analysis を引っ張ってくることで、差分コンパイルを別マシンからレジュームすることを可能とした。`main` ブランチのキャッシュがだいたい整っていると仮定すると、似た仕組みを sbt 2.x を実装する意義があるかもしれない。

#### 課題: デフォルトで testQuick

sbt 1.x でも `testQuick` という名前で差分テストがあるが、あんまり知られていない気がする。だいたいの CI はただ `test` を呼び出していることを考えるとテスト結果をキャッシュ化して、Bazel のように `testQuick` をデフォルトの振る舞いとするのが良いと思う。

テストを再実行したければ、Bazel の場合以下のフラグが必要となる:

```bash
bazel test --cache_test_results=no <query>
```

変わって無いテストは飛ばしてしまうというのが実は Bazel が速い秘密の 1つだったりする。

### まとめ

[RFC-1: sbt cache ideas](/sbt-cache-ideas/)、[`Def.cachedTask`][part2]、及び Bazel の Remote Execution API に基づいて、[sbt/sbt#7525](https://github.com/sbt/sbt/pull/7525) はリモート・キャッシュ・クライアント機能を sbt 2.x に実装する。sbt 2.x リモート・キャッシュが複数の実装に対してタスクの結果を保存、取得できることを示した:

- [buchgr/bazel-remote][bazel-remote]
- [EngFlow][engflow]
- [BuildBuddy][buildbuddy]
- [NativeLink][nativelink]
- などなど

リモート・キャッシュは、チーム全員が全員分のコードをビルドする代わりに、チームのサイズと共に線形にスケールする新しい次元のビルドのスケーラビリティを与えてくれる。小さなプロジェクトでも、バイナリのアウトプットをコントリビュータ同士で共有できると開発の効率化になる。これは Maven Central を使って JAR を共有するのに似ているが、バージョン番号を上げ続けなくてもいいのと、今後 `compile` 以外でも利用できる可能性があるという違いがある。

リモート・キャッシュ機能全体で見るとまだ課題が残っているが、Bazel 互換ができたことは個人的には大きな節目だ。

----

### Scala Center への募金お願い

Scala Center は教育とオープンソースのサポートを目的とする EPFL 内の非営利団体だ。是非[募金して](https://scala.epfl.ch/donate.html)、募金したよと @eed3si9n と @scala_lang にメンションを飛ばしてください (僕は Scala Center 勤務じゃないですが、sbt のメンテは一緒にやっています)。
