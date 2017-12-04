> Lightbend の技術系ブログ Tech Hub blog に [sbt 1.0.4 hotfix and the performance fixes](https://developer.lightbend.com/blog/2017-11-27-sbt-1-0-4-hotfix-and-performance-fixes/) という記事を書いたので、訳しました。

[@eed3si9n](https://twitter.com/eed3si9n)) 著

皆さんこんにちは。アメリカに住んでいる人たちは、良い感謝祭 (Thanksgiving) の連休すごせたでしょうか。
遠くからの親戚や友達が集まって食事を作ったり、小咄を交わす年中行事という意味では、日本の正月休みに近いものがあると思う。

あと、sbt 1.0.4 をリリースしたこともアナウンスします。これは sbt 1.0.x シリーズの hotfix で、バグ修正にフォーカスを当てたバイナリ互換リリースだ。
sbt 1 は Semantic Versioning にもとづいてリリースされるので、プラグインは sbt 1.x シリーズ中機能することが期待されている。

### パフォーマンスデグレの修正

感謝祭ということで、お世話になっている人たちの事を考えるわけだけど、僕は Scala のツーリングエコシステムにコントリビュートしてくれている皆さんに感謝している。これは、sbt へのコードのコントリビュートだけじゃなく、考えさせられるブログ (Haoyi さんの [So, what's wrong with SBT?](http://www.lihaoyi.com/post/SowhatswrongwithSBT.html) など)、トーク (Jeff さんの [Beyond the Build Tool](https://www.youtube.com/watch?v=zWh4kFX63Gc) など)、ドキュメンテーション、IDE/エディタ統合、や代替ビルドツール (Chris さんの [cbt](https://github.com/cvogt/cbt) など) も含めている。冷笑的に「sbt はダメ」って言って終わりにするんじゃなく、この人たちは腕をまくって、sbt そのものを直したり、代替案を考え出しているからだ。

sbt 1 に関連してパフォーマンスのデグレが報告されているが、何人もの人が飛び込んで取り組んでくれている。

- Scala Center の Jorge さん ([@jvican](https://twitter.com/jvican)) は性能向上関係を色々やっていて、sbt 1.0.4 で使われている Zinc 1.0.5 ではクラスパス上の JAR のハッシュ計算のパフォーマンスが落ちた対策として、JAR ごとにキャッシュする修正を提供してくれた。
- Sam Halliday さん ([@fommil](https://twitter.com/fommil))‏ もクラスパスハッシュ問題に取り組んで、再現プロジェクトを提供したり、pull request を送ってくれた。
- OlegYch さん ([@OlegYch](https://twitter.com/OlegYch)) は `testQuick` のパフォーマンスがデグレを修正してくれた。 [#3680][3680]/[#3720][3720]
- Leonard Ehrenfried さん ([@leonardehrenfried][@leonardehrenfried]) も[パフォーマンスのベンチマーク](https://leonard.io/blog/2017/11/a-reproducible-benchmark-for-sbt/)に取り組んで、Sam さんの再現プロジェクトをもとに自動で実行して性能を比較するハーネスを作ってくれた。また、Ivy-log4j のパフォーマンスデグレを修正してくれた。 [#3711][3711]/[util#132][util132]
- Lightbend Tooling team からは Dale ([@dwijnand](https://twitter.com/dwijnand)) がパフォーマンス関連の issue に取り組んだり、社内のエキスパートから知見を得たりしている。

以下は、Leonard / Sam の 25個のサブプロジェクトを使ったテストプロジェクトで no-op compile を行った sbt 1.0.4 のパフォーマンスだ:

**注意**: sbt セッションが立ち上がっていることを前提として、ベンチマークのコンパイル時間の結果からスタートアップ時間を差し引いた。

|                   | sbt 0.13.16 | sbt 1.0.3 | sbt 1.0.4 |
| ----------------- | ----------  | --------- | --------- |
| startup           | 28s         | 38s       | 34s       |
| no-op compile*    | 27s         | 46s       | 22s       |
| no-op compile x2* | 37s         | 80s       | 33s       |

sbt 1.0.3 で no-op コンパイルのがデグレしたが、sbt 1.0.4 では 0.13.16 より 10 から 20% ぐらい速くなっていることが分かる。

### Java 9 関連の修正

sbt 1.0.4 は、Java 9 で警告が出る Ivy 内でのリフレクションの使用を取り除いた。以前のバージョンでそれをやろうとして作り込んでしまったバグを吉田さん ([@xuwei_k](https://twitter.com/xuwei_k)) が修正してくれた。これらが、launcher と library management モジュールに行き渡ったので、警告の数は減ると思う。

- Java 9 上で実行した場合に Ivy で `ArrayIndexOutOfBoundsException` が発生する問題を修正した。 [ivy#27][ivy27] by [@xuwei-k][@xuwei-k]
- launcher 1.0.2 アップグレードして Java 9 上での警告を減らした。 [ivy#26][ivy26]/[launcher#45][launcher45] by [@dwijnand][@dwijnand]
- Java 9 上での `-jvm-debug` 処理を修正した。 [launcher-package197][sbt-launcher-package197] by [@mkurz][@mkurz]

### Scala 2.13.0-M2 サポート

Adriaan ([@adriaanm](https://twitter.com/adriaanm/)) は、Scala の 2.13.x ブランチで REPL まわりのコードの構造を改善している。これに対して sbt 側で対応する必要があるので、まだ 2.13 がマイルストーンのうちに対策した。
ブリッジとなるコードを sbt 1.0.3 を使って Scala 2.13.0-M2 でコンパイルして確認する必要があったが、sbt 1.0.3 が 2.13.0-M2 に対応していないという堂々巡り問題を対策する必要があった。

[zinc#453][zinc453] by [@eed3si9n][@eed3si9n] and [@jan0sch][@jan0sch]

### その他の修正

- 値クラスの内部型が変更した時にアンダーコンパイルする問題を修正した。 [zinc#444][zinc444] by [@smarter][@smarter]
- `run` タスクのログレベルが `debug` になる問題を修正した。 [#3655][3655]/[#3717][3717] by [@cunei][@cunei]
- Scala コンパイラの `templateStats()` がスレッドセーフじゃない問題を対策した。 [#3743][3743] by [@cunei][@cunei]
- "Attempting to overwrite" というエラーメッセージを修正した。 [lm#174][lm174] by [@dwijnand][@dwijnand]
- eviction warning の内容が間違っているのを修正した。 [lm#179][lm179] by [@xuwei-k][@xuwei-k]
- プラグインとの相性を改善するために、Ivy のプロトコルを `http:` と `https:` のみ登録するようにした。 [lm183][lm183] by [@tpunder][@tpunder]
- スクリプトで `bc` を採用したことで問題が出たので `expr` を使うようにした。 [launcher-package#199][sbt-launcher-package199] by [@thatfulvioguy][@thatfulvioguy]
- Zinc の scripted テストを改善した。 [zinc#440][zinc440] by [@jvican][@jvican]

### 参加

sbt や Zinc 1 を実際に使ったり、バグ報告、ドキュメンテーションの改善、ビルドの移植、プラグインの移植、pull request をレビューしたり送ってくれた皆さん、ありがとうございます。

sbt, zinc, librarymanagement, util, io, website などのモジュールで実行した `git shortlog -sn --no-merges v1.0.3..v1.0.4` によると、sbt 1.0.4 は 17人のコントリビュータのお陰でできました (敬称略): Eugene Yokota, Kenji Yoshida (xuwei-k), Jorge Vicente Cantero (jvican), Dale Wijnand, Leonard Ehrenfried, Antonio Cunei, Brett Randall, Guillaume Martres, Arnout Engelen, Fulvio Valente, Jens Grassel, Matthias Kurz, OlegYch, Philippus Baalman, Sam Halliday, Tim Underwood, Tom Most. Thank you!

sbt を手伝ってみたいと興味があれば、好みによって色々な方法があります。

- プラグインやライブラリを sbt 1 へと移行させる。
- バグを見つけたら報告する。
- バグの修正を送る。
- ドキュメンテーションの更新。

他にもアイディアがあれば、[sbt-contrib](https://gitter.im/sbt/sbt-contrib) で声をかけてください。

  [@dwijnand]: https://github.com/dwijnand
  [@cunei]: https://github.com/cunei
  [@eed3si9n]: https://github.com/eed3si9n
  [@jvican]: https://github.com/jvican
  [@OlegYch]: https://github.com/OlegYch
  [@leonardehrenfried]: https://github.com/leonardehrenfried
  [@xuwei-k]: https://github.com/xuwei-k
  [@tpunder]: https://github.com/tpunder
  [@smarter]: https://github.com/smarter
  [@jan0sch]: https://github.com/jan0sch
  [@mkurz]: https://github.com/mkurz
  [@thatfulvioguy]: https://github.com/thatfulvioguy
  [@fommil]: https://github.com/fommil
  [3655]: https://github.com/sbt/sbt/issues/3655
  [3717]: https://github.com/sbt/sbt/pull/3717
  [ivy26]: https://github.com/sbt/ivy/pull/26
  [ivy27]: https://github.com/sbt/ivy/pull/27
  [launcher45]: https://github.com/sbt/launcher/pull/45
  [3680]: https://github.com/sbt/sbt/issues/3680
  [3720]: https://github.com/sbt/sbt/pull/3720
  [3743]: https://github.com/sbt/sbt/pull/3743
  [3711]: https://github.com/sbt/sbt/issues/3711
  [util132]: https://github.com/sbt/util/pull/132
  [lm174]: https://github.com/sbt/librarymanagement/pull/174
  [lm179]: https://github.com/sbt/librarymanagement/pull/179
  [lm183]: https://github.com/sbt/librarymanagement/pull/183
  [zinc452]: https://github.com/sbt/zinc/pull/452
  [zinc444]: https://github.com/sbt/zinc/pull/444
  [zinc453]: https://github.com/sbt/zinc/pull/453
  [zinc440]: https://github.com/sbt/zinc/pull/440
  [sbt-launcher-package197]: https://github.com/sbt/sbt-launcher-package/pull/197
  [sbt-launcher-package199]: https://github.com/sbt/sbt-launcher-package/pull/199

