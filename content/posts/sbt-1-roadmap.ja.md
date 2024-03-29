---
title:       "sbt 1.0 ロードマップ"
type:        story
date:        2016-03-11
changed:     2016-03-22
draft:       false
promote:     true
sticky:      false
url:         /ja/sbt-1-roadmap
aliases:     [ /node/191 ]
tags:        [ "sbt" ]
---

sbt 1.0 にに関して TL上とかで議論があったので、叩き台としてこれを書くことにした。何かをちゃんとリリースできるように仕切り直しするための中期的なミッション・ステートメントだと思ってほしい。[sbt-dev mailing list](https://groups.google.com/d/msg/sbt-dev/PoR7n1ZV_i4/L-Jg6AAABwAJ) にて今後も議論を続けていきたい。

### タイミング

いつ sbt 1.0 をリリースできるかという予定はまだ見当が付いていない。
sbt 1.0 の最大の機能はコードの再組織で、それは既に進んでいる: http://www.scala-sbt.org/0.13/docs/Modularization.html

sbt/io、 sbt/util、 sbt/librarymanagement、 sbt/incrementalcompiler といったモジュールがある。実装という観点からするとインクリメンタルコンパイラが sbt の中で一番複雑な部分だと思うので、まずはそれをモジュール化することを目標としてきた。全部のモジュールの API が安定したときが、sbt 本体にも 1.0 を付けれる時になる。

### モジュール化の動機

sbt/sbt の現在のコードは、ビルドユーザやプラグイン作者に内部を晒しすぎている。これによってとっつきづらいコードになっている。さらに、バイナリ互換性を保つのも難しくなっている。
モジュール化の目標はどこまでが public な API でどこからが private な実装なのかの境界をハッキリさせることだ。

あと、これらのモジュールは今まで使ってたような Ivy リポジトリじゃなくて Maven Central に乗せる。

### sbt/zinc

新しいインクリメンタルコンパイラは完全に name hashing に移行する。name hashing はしばらく前 (sbt 0.13.6) からデフォルトでオンになっている。それだけじゃなくて、クラスベースの name hashing を使う予定で、これは性能改善が期待されている。

### Java バージョン

sbt 0.13 は JDK 6 の上に書かれている。sbt 1.0 は JDK 8 ベースだ。

### sbt-archetype

sbt-archetype は Jim Powers が提案するコンセプトで、sbt に Activator みたいに `new` コマンドを付けるというものだ。`templateResolvers` セッティングみたいなバックエンド機構をつけて、テンプレートのソースは設定で Activator Template、Github、private repository など変えれるようにしたい。

### sbt Server

これも sbt 1.0 の側面の一つだ。sbt server の動機はより良い IDE との統合だ。全ての IDE は sbt にタスクやコマンドを sbt に伝えれるようにするべきだ。プラグインやライブラリ依存性を含めたビルドの意味論は一ヶ所にまとまっているべきだ。

sbt を 2つの JVM プロセスに分けることに関して理にかなった懸念が出ている。自動スタートや自動発見の機構も複雑さを増すことになる。

この近辺でのオーバーエンジニアリングを極力避けて、一般的にありがちなユースケースにフォーカスするべきだ。例えば:

- サブプロジェクトの切り替え
- IDE から Scala アプリをコンパイルして、エラーや警告を表示
- IDE から Play アプリを実行
- IDE から単体テストの実行
- テキストコマンドの受け付け

IDE 統合に興味の無いユーザは "sbt" と打ち込めば今まで通り単一の JVM プロセスで稼働するべきだ。ユーザが自分でポート番号を指定して手動で sbt をスタートするようにすれば自動スタート機能はいらなくなる。sbt server コマンドのリブート版を近日公開したい。

### serialization (直列化) の再考

早期のうちに僕たちが打ち立てた前提条件は全てのセッティングキー（これはプラグインで定義されたキーも含む）はネットワーク上を飛ばなければいけないというものだった。この前提条件によって serialization のライブラリとして Scala Pickling の採用が有利になった。なぜなら Pickling は Java や Scala のクラスから JSON を含むカスタム可能なフォーマットへの無スキーマで、「自動」な変換を約束したからだ。

しかし、Java では自動変換として約束されたものは実際にはメソッド名が "get" と "set" で始まるかという推測だということがフタを開けてみると分かった。そのため、`java.io.File` や `java.lang.Byte` といった型を空の値に保存したり、`org.joda.time.LocalDate` に至ってはあるフィールドは保存するが他は保存しないという怪奇なふるまいをすることになった。

現実的には sbt に関するほとんどのインタラクションはテキスト的なものであることが多く、殆どのデータ型はネットワークを飛ぶ必要がない。例えば、sbt-assembly を使うにはユーザは sbt シェルに向かって `assembly` と打ち込むだけでいい。タスクの進捗は流れてくるログから観測できるが、戻り値がシェルに打ち込んだユーザ本人に必要になることはほとんど無い。（build.sbt でカスタムタスクから値を使う場合とは別であることに注意）
sbinary から Scala Pickling に移行してうまくいった部分もいくつかはあるから、可能ならその両方をリプレースできるものを探す必要がある。

考慮するべき候補:

- 適当な JSON ライブラリ (どれ?) + 手書きのフォーマット
- 適当な JSON ライブラリ + sbt-datatype を使ってフォーマットもしくはタプル isomorphism を生成

### NIO

JDK 8 に決定すれば、sbt/io にある Path とか globbing のコードを NIO に移行することができる。http://docs.oracle.com/javase/tutorial/essential/io/index.html 

### Network API

Network API というのは sbt に HTTP クライアントサービスを提供する仮想のモジュールだ。 https://github.com/sbt/sbt/issues/2189
sbt 0.13 のダウンロードの振る舞いは非常に非効率なので、コネクションプールやクライアントサイドでリダイレクトすることで改善できるかもしれない。
これはまずは API だけ決めておいて、改善は後回しでもいいけど。
