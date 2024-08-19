---
title:       "酢鶏、パート4"
type:        story
date:        2024-08-18
draft:       false
url:         /ja/sudori-part4
tags:        [ "sbt" ]
---

  [part3]: /sudori-part3
  [sbt-remote-cache]: /ja/sbt-remote-cache
  [sbt-remote-cache-with-bazel-compat]: /ja/sbt-remote-cache-with-bazel-compat
  [7621]: https://github.com/sbt/sbt/pull/7621

本稿は sbt 2.x 開発に関する記事で、[sudori part3][part3]、[sbt 2.x リモートキャッシュ][sbt-remote-cache]、[Bazel 互換な sbt 2.x リモートキャッシュ][sbt-remote-cache-with-bazel-compat]などの続編だ。僕は個人の時間を使って Scala Center と強力して sbt 2.x の作業をしていて、このような記事はプルリクコメントの拡張版で、将来 sbt に実装されるかもしれない機能を共有できたらいいと思っている。

### 2024年8月現在での状況

2024年4月の段階から一応 Bazel 互換のリモートキャッシュ機能が入っている。この実装はキャッシュされた副作用としてファイル・アウトプットをサポートする。言い換えると、まっさらなマシンでビルドを行ったとしても、リモート・キャッシュが潤っていれば、コンパイラを実行する代わりに JAR をダウンロードできるという算段だ。

しかし、実際に差分コンパイルを行うにはディレクトリに任意の数のファイルを作ることをサポートする必要がある。頑張れば他の方法もあるのだが、今のところディレクトリをサポートするのが現実的な次のステップだと思う。

#### ファイル・ディレクトリ問題

ファイル・ディレクトリのキャッシュ化は [sbt 2.x リモートキャッシュ][sbt-remote-cache]で列挙した様々なキャッシュ関連の問題に当たることになる:

1. ファイル・ディレクトリは相対パス名、ディレクトリに関する一意な証明、ファイル・システム内の実際のディレクトリなど色々なものを指す可能性がある
2. 実際のファイル・ディレクトリは任意の数のファイルを含む
3. 恐らく、ディレクトリをキャッシュするのに大量のネットワーク呼び出しはしたくない

### アウトプットの宣言

[sbt/sbt#7621][7621] において、`Def.declaraOutputDirectory` という新しいアウトプットを導入した:

```scala
Def.declareOutputDirectory(dir)
```

これはタスク内で呼び出すことをでディレクトリのアウトプットを宣言する。これは、タスクの返り値の型とは異なることに注意。例えば、`compile` タスクは `Analysis` を返すが、横で `*.class` ファイルを生成して、事前に取り決められたディレクトリを使って他のタスクはその内容を使うということが行われている。宣言することでこの流れがもう少し明示的になる。具体例だとこのようになる:

```scala
import sjsonnew.BasicJsonProtocol.given

lazy val someKey = taskKey[Int]("")

someKey := (Def.cachedTask {
  val conv = fileConverter.value
  val dir = target.value / "foo"
  IO.write(dir / "bar.txt", "1")
  val vf = conv.toVirtualFile(dir.toPath())
  Def.declareOutputDirectory(vf)
  1
}).value
```

#### NativeLink キャッシュの設定

[NativeLink][nativelink] は比較的新しいリモート実行バックエンドで、Rust で実装されており、高速であることにこだわっている。オープンソースだが、NativeLink Cloud というサービスも行っていて、無料でお試しできると友達の Adam Singer がよく言っている。

1. リモート・キャッシュ機能を使うには `project/plugins.sbt` に `addRemoteCachePlugin` を追加する。
2. <https://app.nativelink.com/> から Quickstart に行って、URL と `--remote_header` を書き留める。
3. `$HOME/.sbt/nativelink_credential.txt` というファイルを作成して、API key を書く:

```
x-nativelink-api-key=*******
```

sbt 2.x 側の設定は以下のようになる:

```scala
Global / remoteCache := Some(uri("grpcs://something.build-faster.nativelink.net"))
Global / remoteCacheHeaders += IO.read(BuildPaths.defaultGlobalBase / "nativelink_credential.txt").trim
```

その他のリモート・キャッシュのソリューションに関する設定に関しては [Bazel 互換な sbt 2.x リモートキャッシュ][sbt-remote-cache-with-bazel-compat]参照。

#### タスクの実行

上記の設定ができたら、`someKey` タスクを実行してみよう:

```scala
> someKey
[success] elapsed time: 1 s, cache 0%, 1 onsite task
> exit
```

次にローカルのキャッシュを削除して、ディレクトリを回復できるか試してみよう:

```bash
$ rmtrash $HOME/Library/Caches/sbt/v2/ && rmtrash target
$ sbt
> someKey
[success] elapsed time: 1 s, cache 100%, 1 remote cache hit
> exit
$ tree target/out/jvm/scala-3.4.2/dirtest/
target/out/jvm/scala-3.4.2/dirtest/
├── aaa
│   └── bbb.txt -> $HOME/Library/Caches/sbt/v2/cas/sha256-6b86b273ff34fce19d6b804eff5a3f5747ada4eaa22f1d49c01e52ddb7875b4b-1
└── aaa.sbtdir.zip -> $HOME/Library/Caches/sbt/v2/cas/sha256-b8e8af292865273d51e6ab681d52cc2410cd6e4d33aa563f6e691b8cd3c6e665-904
$ cat target/out/jvm/scala-3.4.2/dirtest/aaa/bbb.txt
1
```

リモート・キャッシュから `aaa` ディレクトリが回復できた。

### 実装の詳細

要約すると、`aaa.sbtdir.zip` という名前の `.zip` ファイルを作って、それをキャッシュすることでディレクトリのキャッシュ化をエミュレートした。これによって、ハッシュを計算したりなど、単一のファイルとして扱うことができ `Def.declareOuput` の機構を再利用することができる。

#### アウトプットのマクロ展開

ディレクトリの話をする前に、アウトプットを持つキャッシュタスクがどのように実装されているかのおさらいをしよう。例えば、以下のようなタスクがあるとする:

```scala
Def.cachedTask {
  val vf = StringVirtualFile1("a.txt", "foo")
  Def.declareOutput(vf)
  name.value + version.value + "!"
}
```

マクロは、以下のような関数呼び出しに展開される:

```scala
i.mapN((wrap(name), wrap(version)), (q1: String, q2: String) => {
  var o1: VirtualFile = _
  ActionCache.cache[(String, String), String](
    key = (q1, q2),
    otherInputs = 0): input =>
      val vf = StringVirtualFile1("a.txt", "foo")
      o1 = vf
      InternalActionResult(q1 + q2 + "!", List(o1))
})
```

`Def.declareOutput(vf)` が 3通りに展開されることに注目してほしい:

1. `var o1: VirtualFile` という人工変数
2. `Def.declareOutput(vf)` は単に `o1 = vf` という代入文となる
3. 後で `o1` は `InternalActionResult` に渡され、それは `ActionCache.cache` に渡される

`Dec.declareOutputDirectory` でもほぼ同じことを行った:

1. `var o1: VirtualFile` という人工変数
2. `Def.declareOutput(vf)` は `o1 = ActionCache.packageDirectory(vf)` という代入文となる
3. 後で `o1` は `InternalActionResult` に渡され、それは `ActionCache.cache` に渡される

`ActionCache.packageDirectory` を使って zip ファイルの作成を行う。

#### エフェクトの実行

ここまでだと、zip ファイルのキャッシュ化しか行っていない。次に、以下のような目録 (マニフェスト) を作成して zip ファイルに入れる:

```bash
$ unzip -p target/out/jvm/scala-3.4.2/dirtest/aaa.sbtdir.zip sbtdir_manifest.json | jq
{
  "version": "0.1.0",
  "outputFiles": [
    "${OUT}/jvm/scala-3.4.2/dirtest/aaa/bbb.txt>sha256-6b86b273ff34fce19d6b804eff5a3f5747ada4eaa22f1d49c01e52ddb7875b4b/1"
  ]
}
```

これは、ディレクトリ内にある全てのアイテムとそれらのコンテンツ・ハッシュを列挙する。sbt が `.sbtdir.zip` で終わるアウトプットを見つけると、この目録ファイルを開いて、SHA-256 ハッシュを既存のファイルと比較して、ディスク・キャッシュを用いてファイルの同期を行う。これで、コンパイルなどによって同じアイテムが何回出てきても、中央で一度キャッシュ化するだけでいい。

### ケーススタディー: compile タスク

[sbt 2.x リモートキャッシュ][sbt-remote-cache]での `compile` タスクの実装は、リソースファイル抜きの JAR ファイルを作るというものだった。ディレクトリを使うという方法に戻ることで、実装は少しシンプルになる:

```scala
val analysisResult = Retry(compileIncrementalTaskImpl(bspTask, s, ci, ping))
....

val dir = ci.options.classesDirectory
val vfDir = c.toVirtualFile(dir)
val packedDir = Def.declareOutputDirectory(vfDir)
(analysisResult.hasModified(), vfDir: VirtualFileRef, packedDir: HashedVirtualFileRef)
```

`zip` ファイルをアップロードするため、実質的には JAR ファイルを作っているのとあまり変わりが無いが、マシン非依存な方法で各ファイルが自動的に unzip されるという利点がある。

#### 密閉性の破壊注意

この `compile` タスクの例は、`Def.cachedTask(...)` 内で `Def.declareOutputDirectory` で使うとき、気を付けないと密閉性が壊れるという落とし穴があることを思い出させれくれる。具体的には、古い、間違ったキャッシュを再利用してしまう可能性がある。

これは、`VirtualFileRef` がディレクトリ名だけを表し、コンテンツのハッシュ情報を持たないため、下流のタスクを無効化するのに十分な情報を持たないためだ。例えば、`foo` というタスクがディレクトリを作成して、それを別のキャッシュ・タスク `bar` に `VirtualFileRef` を経由して渡したとしたら、不十分なキャッシュとなる。

```scala
// bad
foo := (Def.cachedTask {
  val dir = target.value / "foo"
  ....
  val vfDir = c.toVirtualFile(dir)
  Def.declareOutputDirectory(vfDir)
  vfDir // returning VirtualFileRef may not be safe here
}).value

bar := (Def.cachedTask {
  val vfDir = foo.value
  ....
}).value
```

この回避策として、`Def.declareOutputDirectory` は、人工的 zip ファイルの `VirtualFile` を返し、これはハッシュ情報を含むため、下流の無効化を行うことができる。

```scala
// good
foo := (Def.cachedTask {
  val dir = target.value / "foo"
  ....
  val vfDir = c.toVirtualFile(dir)
  val packedDir = Def.declareOutputDirectory(vfDir)
  (vfDir, packedDir)
}).value

bar := (Def.cachedTask {
  val (vfDir, _) = foo.value
  ....
}).value
```

### まとめ

[sbt/sbt#7621][7621] は、`Def.declareOutputDirectory(...)` という新しいアウトプットを導入して、キャッシュ・タスクから任意の数のファイルを生成することを可能とする。このアウトプットは、差分コンパイルなどの sbt 1.x タスクの移植を簡易化することを目的とする。

これは内部では zip ファイルを生成し、どの Bazel リモート・キャッシュ実装でもこの機能が使えるはずだ。しかし、ディレクトリを別のキャッシュ・タスクに渡す場合は密閉性が壊れるのを回避するために注意する必要がある。

----

### Scala Center への募金お願い

Scala Center は教育とオープンソースのサポートを目的とする EPFL 内の非営利団体だ。是非[募金](https://scala.epfl.ch/donate.html)して、募金したよと @eed3si9n と @scala_lang にメンションを飛ばしてください (僕は Scala Center 勤務じゃないですが、sbt のメンテは一緒にやっています)。
