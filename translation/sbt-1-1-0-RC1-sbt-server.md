> Lightbend の技術系ブログ Tech Hub blog に [sbt 1.1.0-RC1 with sbt server and slash syntax](https://developer.lightbend.com/blog/2017-11-30-sbt-1-1-0-RC1-sbt-server/) という記事を書いたので、訳しました。

[@eed3si9n](https://twitter.com/eed3si9n) 著

皆さんこんにちは。Lightbend Tooling team にかわって sbt 1.1.0-RC1 をアナウンスします。これは、sbt 1 初のフィーチャーリリースで、バイナリ互換性は維持しつつ新機能にフォーカスを当てたリリースとなっている。
sbt 1 は Semantic Versioning にもとづいてリリースされるので、プラグインは sbt 1.x シリーズ中機能することが期待されている。2017年12月14日までに大きな問題が見つからなければ、1.1.0-RC1 は 1.0.0 final 版となる予定だ。

sbt 1.1 の主な新機能は統一スラッシュ構文 (unified slash syntax) と sbt server だ。これらは両方とも僕が個人的にしばらく関わってきた機能だが、sbt 1.0 には入れずに延期させたものだ。そのため、やっとこれらを世に出せるのがひとしお嬉しい。

### セッティングキーの統一スラッシュ構文

sbt の 1ユーザとして、sbt シェルと `build.sbt` でセッティングとタスクキーに 2つの表記方法があるのが、sbt の学習を難しくしている理由だと長いこと思ってきた。[コミュニティーの皆さん](https://contributors.scala-lang.org/t/unification-of-sbt-shell-notation-and-build-sbt-dsl/913)と議論を重ね、[いくつかのプロトタイプ](https://github.com/sbt/sbt-slash)を作った後、sbt 1.1.0-RC1 より統一スラッシュ構文がサポートされることになった。 (sbt 0.13 表記も引き続き動作するのでご心配無く)

`build.sbt` と sbt shell の両方において、セッティングはスコープ軸をスラッシュで分けて以下のように書くことができる:

    ref / Config / intask / key

上の `ref` は典型的にはサブプロジェクト名もしくは `ThisBuild` が入り、`Config` は `Compile` や `Test` などコンフィギュレーションの Scala 識別子が入る。それぞれの軸は省略するか、特殊な `Zero` という値で置き換えることが可能なので、実際は以下のようになっている:

    ((ref | "Zero") "/") ((Config | "Zero") "/") ((intask | "Zero") "/") key

具体例で説明すると、sbt 0.13 では:

- `Test` コンフィギュレーションのみをコンパイルするには `build.sbt` 内では `(compile in Test).value` と書き、sbt shell では `test:compile` と書いた。
- `Global` レベルの `cancelable` セッティングは `build.sbt` 内では `(cancelable in Global).value` と書き、sbt shell では `*/*:cancelable` と書いた。

一方 sbt 1.1.0-RC1 では:

- `Test` にスコープ付けされた `compile` タスクは、`build.sbt` 内では `(Test / compile).value` と書き、sbt shell でも `Test / compile` と書く。
- `Global` にスコープ付けされた `cancelable` セッティングは `build.sbt` 内では `(Global / cancelable).value` と書き、sbt shell でも `Global / cancelable` と書く。

以下はデモだ:

![slash](https://developer.lightbend.com/blog/2017-11-30-sbt-1-1-0-RC1-sbt-server/slash.gif)

詳細は [Migrating to slash syntax](http://www.scala-sbt.org/1.x-beta/docs/Migrating-from-sbt-013x.html#Migrating+to+slash+syntax) と[スコープ](http://www.scala-sbt.org/1.x-beta/docs/ja/Scopes.html)のドキュメンテーションを参照。

**注意**: プラグイン作者の皆さんに注意してほしいのは、この新構文をプラグインで使うと動作可能な最小 sbt バージョンが sbt 1.1.0-RC1 に引き上がってしまうことだ。

[#1812][1812]/[#3434][3434]/[#3617][3617]/[#3620][3620] by [@eed3si9n][@eed3si9n] and [@dwijnand][@dwijnand]

### sbt server

「sbt server」という名前を聞くと、リモートのサーバで走って、何かすごいことをやってくれるんじゃないかと想像するかもしれない。しかし、今のところ sbt server はそれではない。sbt server は単に sbt shell にネットワークからのアクセスを追加するだけだ。sbt 1.1 はこの機能を刷新して [Language Server Protocol 3.0](https://github.com/Microsoft/language-server-protocol/blob/master/protocol.md) (LSP) をワイヤープロトコルとして採用した。これは、Microsoft 社が Visual Studio Code のために開発したプロトコルだ。

実行中のサーバを発見するには、sbt 1.1.0 はビルドから見て `./project/target/active.json` にポートファイルを作成するので、それを見つける:

<code>
{"uri":"local:///Users/foo/.sbt/1.0/server/0845deda85cb41abcdef/sock"}
</code>

ここで `local:` は Unix ドメインソケットを表している。`nc` を用いてサーバに hello と言うには以下を実行する (`^M` を発信するには `Ctrl-V` を打ってから `Return` を打つ):

<code>
$ nc -U /Users/foo/.sbt/1.0/server/0845deda85cb41abcdef/sock
Content-Length: 99^M
^M
{ "jsonrpc": "2.0", "id": 1, "method": "initialize", "params": { "initializationOptions": { } } }^M
</code>

`compile` は以下のように行う:

<code>
Content-Length: 93^M
^M
{ "jsonrpc": "2.0", "id": 2, "method": "sbt/exec", "params": { "commandLine": "compile" } }^M
</code>

これで、現在実行中の sbt セッションは `compile` をキューに加え、もしコンパイラ警告やエラーがあれば、メッセージを返すはずだ:

<code>
Content-Length: 296
Content-Type: application/vscode-jsonrpc; charset=utf-8

{"jsonrpc":"2.0","method":"textDocument/publishDiagnostics","params":{"uri":"file:/Users/foo/work/hellotest/Hello.scala","diagnostics":[{"range":{"start":{"line":2,"character":26},"end":{"line":2,"character":27}},"severity":1,"source":"sbt","message":"object X is not a member of package foo"}]}}
</code>

これによって、複数のクライアントが**単一**の sbt セッションに接続することが可能となる。クライアントの主な用途はエディタや IDE といったツーリングの統合を想定している。詳細に関しては [sbt server](http://www.scala-sbt.org/1.x-beta/docs/sbt-server.html) を参照。

[#3524][3524]/[#3556][3556] by [@eed3si9n][@eed3si9n]

### VS Code エクステンション

エディタ統合の概念実証として、[Scala (sbt)][vscode-sbt-scala] という Visual Studio Code エクステンションを作ってみた。これを試すには、[Visual Studio Code](https://code.visualstudio.com/) をインストールして、「Scala (sbt)」 を Extensions タブから検索して、sbt 1.1.0-RC1 を何らかのプロジェクトから実行して、VS Code を使ってそのプロジェクトを開く。

今のところこのエクステンションが可能なのは:

- `*.scala` ファイルが保存されたら、ルートプロジェクトから `compile` を実行する。 [#3524][3524] by Eugene Yokota ([@eed3si9n][@eed3si9n])
- コンパイラエラーを表示する。
- ログメッセージを表示する。 [#3740][3740] by Alexey Alekhin ([@laughedelic][@laughedelic])
- クラス定義にジャンプする。 [#3660][3660] by Wiesław Popielarski at VirtusLab ([@wpopielarski][@wpopielarski])

以下はデモだ:

![vscode-scala-sbt](https://developer.lightbend.com/blog/2017-11-30-sbt-1-1-0-RC1-sbt-server/vscode-scala-sbt.gif)

### その他のバグ修正や改善点

- Semantic Versioning に準拠して `version` セッティングのデフォルトを `0.1.0-SNAPSHOT` に変更した。 [#3577][3577] by [@laughedelic][@laughedelic]
- Java 9 でのオーバーコンパイルを修正した。 [zinc#450][zinc450] by [@retronym][@retronym]
- 深く入れ子になった Java クラスの処理を修正した。 [zinc#423][zinc423] by [@romanowski][@romanowski]
- JavaDoc が全てのエラーを表示しない問題を修正した。 [zinc#415][zinc415] by [@raboof][@raboof]
- `ScalaInstance.otherJars` の JAR の順序を保つようにした。 [zinc#411][zinc411] by [@dwijnand][@dwijnand]
- 名前に改行が含まれる場合の used name 処理を修正した。 [zinc#449][zinc449] by [@jilen][@jilen]
- `ThisProject` の処理を修正した。 [#3609][3609] by [@dwijnand][@dwijnand]
- sbt ファイルにおける import 文をエスケープして、もしバッククォートが必要な定義があった場合にタスクが失敗しないようにした。 [#3635][3635] by [@panaeon][@panaeon]
- 警告文からバージョン 0.14.0 への言及を削除した。 [#3693][3693] by [@saniyatech][@saniyatech]
- screpl が "Not a valid key: console-quick" を投げる問題を修正した。 [#3762][3762] by [@xuwei-k][@xuwei-k]
- scripted test を `project/build.properties` を用いてフィルターできるようにした。 [#3564][3564]/[#3566][3566] by [@jonas][@jonas]
- サブプロジェクトの id を変更するために `Project#withId` を追加した。 [#3601][3601] by [@dwijnand][@dwijnand]
- 現在のアーティファクトを boot ディレクトリから削除する `reboot dev` というコマンドを追加した。これは sbt の開発版を使っているときに便利な機能だ。 [#3659][3659] by [@eed3si9n][@eed3si9n]
- `reload` 時に sbt version が変わっていないかチェックするようにした。 [#1055][1055]/[#3673][3673] by [@RomanIakovlev][@RomanIakovlev]
- 現在 CI環境で実行されているかを知るための `insideCI` という新セッティングを追加した。 [#3672][3672] by [@RomanIakovlev][@RomanIakovlev]
- `Command` trait に `nameOption` を追加した。 [#3671][3671] by [@miklos-martin][@miklos-martin]
- IO に `IO.chmod(...)` など POSIX アクセス権処理を追加した。 [io#76][io76] by [@eed3si9n][@eed3si9n]
- sbt 1 モジュールを eviction warning において Semantic Versioning 扱いするようにした。 [lm#188][lm188] by [@eed3si9n][@eed3si9n]
- コード内で kind-projector を使うようにした。 [#3650][3650] by [@dwijnand][@dwijnand]
- `Completions` 内の `displayOnly` メソッドなどを正格にした。 [#3763][3763] by [@xuwei-k][@xuwei-k]

### 参加

sbt や Zinc 1 を実際に使ったり、バグ報告、ドキュメンテーションの改善、ビルドの移植、プラグインの移植、pull request をレビューしたり送ってくれた皆さん、ありがとうございます。

sbt, zinc, librarymanagement, util, io, website などのモジュールで実行した `git shortlog -sn --no-merges v1.0.4..v1.1.0-RC` によると、sbt 1.1.0-RC1 は 32名のコントリビュータのお陰でできました (敬称略): Eugene Yokota, Dale Wijnand, Kenji Yoshida (xuwei-k), Alexey Alekhin, Simon Schäfer, Jorge Vicente Cantero (jvican), Miklos Martin, Jeffrey Olchovy, Jonas Fonseca, Andrey Artemov, Arnout Engelen, Dominik Winter, Krzysztof Romanowski, Roman Iakovlev, Wiesław Popielarski, Age Mooij, Allan Timothy Leong, Antonio Cunei, Jason Zaugg, Jilen Zhang, Long Jinwei, Martin Duhem, Michael Stringer, Michael Wizner, Nud Teeraworamongkol, OlegYch, PanAeon, Philippus Baalman, Pierre Dal-Pra, Saniya Tech, Tom Walford, その他大勢の人のアイディアも得ている。 Thank you!

sbt を手伝ってみたいと興味があれば、好みによって色々な方法があります。

- プラグインやライブラリを sbt 1 へと移行させる。
- バグを見つけたら報告する。
- バグの修正を送る。
- ドキュメンテーションの更新。

他にもアイディアがあれば、[sbt-contrib](https://gitter.im/sbt/sbt-contrib) で声をかけてください。

  [@eed3si9n]: https://github.com/eed3si9n
  [@dwijnand]: http://github.com/dwijnand
  [@jvican]: https://github.com/jvican
  [@Duhemm]: https://github.com/Duhemm
  [@jonas]: https://github.com/jonas
  [@laughedelic]: https://github.com/laughedelic
  [@panaeon]: https://github.com/panaeon
  [@RomanIakovlev]: https://github.com/RomanIakovlev
  [@miklos-martin]: https://github.com/miklos-martin
  [@saniyatech]: https://github.com/saniyatech
  [@xuwei-k]: https://github.com/xuwei-k
  [@wpopielarski]: https://github.com/wpopielarski
  [@retronym]: https://github.com/retronym
  [@romanowski]: https://github.com/romanowski
  [@raboof]: https://github.com/raboof
  [@jilen]: https://github.com/jilen
  [@wpopielarski]: https://github.com/wpopielarski
  [vscode-sbt-scala]: https://marketplace.visualstudio.com/items?itemName=lightbend.vscode-sbt-scala
  [1812]: https://github.com/sbt/sbt/issues/1812
  [3524]: https://github.com/sbt/sbt/pull/3524
  [3556]: https://github.com/sbt/sbt/pull/3556
  [3564]: https://github.com/sbt/sbt/issues/3564
  [3566]: https://github.com/sbt/sbt/pull/3566
  [3577]: https://github.com/sbt/sbt/pull/3577
  [3434]: https://github.com/sbt/sbt/pull/3434
  [3601]: https://github.com/sbt/sbt/pull/3601
  [3609]: https://github.com/sbt/sbt/pull/3609
  [3617]: https://github.com/sbt/sbt/pull/3617
  [3620]: https://github.com/sbt/sbt/pull/3620
  [3464]: https://github.com/sbt/sbt/issues/3464
  [3635]: https://github.com/sbt/sbt/pull/3635
  [3659]: https://github.com/sbt/sbt/pull/3659
  [3650]: https://github.com/sbt/sbt/pull/3650
  [3673]: https://github.com/sbt/sbt/pull/3673
  [1055]: https://github.com/sbt/sbt/issues/1055
  [3672]: https://github.com/sbt/sbt/pull/3672
  [3671]: https://github.com/sbt/sbt/pull/3671
  [3693]: https://github.com/sbt/sbt/issues/3693
  [3763]: https://github.com/sbt/sbt/pull/3763
  [3762]: https://github.com/sbt/sbt/pull/3762
  [3740]: https://github.com/sbt/sbt/pull/3740
  [3660]: https://github.com/sbt/sbt/pull/3660
  [io76]: https://github.com/sbt/io/pull/76
  [lm188]: https://github.com/sbt/librarymanagement/pull/188
  [zinc450]: https://github.com/sbt/zinc/pull/450
  [zinc423]: https://github.com/sbt/zinc/pull/423
  [zinc415]: https://github.com/sbt/zinc/issues/415
  [zinc411]: https://github.com/sbt/zinc/pull/411
  [zinc449]: https://github.com/sbt/zinc/pull/449
