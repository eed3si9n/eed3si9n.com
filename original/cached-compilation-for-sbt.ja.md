Google のビルドインフラ Blaze (現在は Bazel としてオープンソース化されている) のことを知ってから Scala のツールチェインにも似たような仕組みが欲しいとずっと思い続けてきた。これは特に独創的な発想という訳では無く、Peter Vlugter さんと Ben Dougherty さんの [nailgun Zinc](https://github.com/typesafehub/zinc/commits/master/src/main/scala/com/typesafe/zinc/SbtAnalysis.scala) での機能 (Pants で使われていた?) や、Krzysztof Romanowski さんの [Hoarder](https://github.com/romanowski/hoarder) など先行研究もある。それらは、作業ディレクトリに合わせて Zinc Analsis ファイル内に格納されている絶対パスを変換するというアイディアから成り立っている。

僕の作業の詳細に入る前に、問題スペースをざっとデモしよう。

### ビルドのマシン依存性

Akka の `akka-actor/compile` を sbt 1.3.10 でビルドするとこのようになる:

<code>
cd ~/work/quicktest/
git clone git@github.com:akka/akka.git akka-0
cd akka-0
sbt
akka > akka-actor/compile
[info] Generating 'Tuples.scala'
[info] Generating 'Functions.scala'
[info] Updating
[info] Resolved  dependencies
[info] Updating
[info] Formatting 22 Java sources...
[info] Reformatted 0 Java sources
[info] Compiling 191 Scala sources and 28 Java sources to /Users/eed3si9n/work/quicktest/akka-0/akka-actor/target/scala-2.12/classes ...
....
[success] Total time: 39 s, completed May 6, 2020 1:53:36 PM
</code>

別の人が同じことをやるのを再現したいので、このディレクトリごと別の場所にコピーする:

<code>
cd ~/work/quicktest/
cp -r akka-0 akka-1
cd akka-1
sbt
akka > akka-actor/compile
[info] Generating 'Tuples.scala'
[info] Generating 'Functions.scala'
[info] Formatting 22 Java sources...
[info] Reformatted 0 Java sources
[info] Compiling 191 Scala sources and 28 Java sources to /Users/eed3si9n/work/quicktest/akka-1/akka-actor/target/scala-2.12/classes ...
....
[success] Total time: 48 s, completed May 6, 2020 1:57:33 PM
</code>

同じ仕事が 2回繰り返された。もしもデベロッパーのチームと仕事しているとすると、これが毎朝繰り返されることになる。チームが大きくなれば、コードが増殖するスピードも上がり、重複される作業も増えていく。コンパイル・キャッシュの基本的な考えは、既にコンパイルされているもののコンパイルを避けるということにある。

### 関数としてのビルド

ScalaSphere 2019 の 'Analysis of Zinc' というトークで、Zinc の関数としてのビルドのためのサブゴールとして以下の 2点を提案した:

- 1マシンからの解放
- 時からの解放

Scala コンパイラも Java コンパイラもバーチャル・ファイルという抽象概念を扱うことができる。Zinc の状態をいじる代わりに、作業ディレクトリに特定の絶対パスをコンパイルから撤廃できればいいんじゃないかというのが僕の考えだ。大規模ビルドツールはこの仕組みを使って例えば全てのソースをメモリに保持するといったことも可能になる。さらに、絶対パスまで通した `java.io.File` を大量に保持してると結構かさばってくる。

内部ではソース、ライブラリ、`*.class` ファイルなどコンパイルに使われるファイルは全て `VirtualFileRef` に変換される。デフォルトの実装は `/Users/xxx/work/quicktest/cats-0/kernel/src/main/scala/cats/kernel/Band.scala` を `${BASE}/kernel/src/main/scala/cats/kernel/Band.scala` へと変換する。(現在は `${0}` だが、多分 `${BASE}` というふうに変更される予定。)

この提案の二つ目の部分は、無効化のキーとしてタイムスタンプを使うのを止めることだ。タイムスタンプは効率が良いので今後も使うと思うが、コンテンツハッシュで二重にチェックするべきだ。ハッシュ化の技術は年を追うごとに進歩している。1000個の JAR ファイルを SHA-1 でハッシュすると数秒かかってしまうが、効率の良い非暗号学的ハッシュだと半秒でそれができる。僕が選んだのは Zero-Allocation-Hashing が実装した FarmHash だ。

### sbt との統合

ローカルでビルドした sbt 1.4.0-SNAPSHOT を使ったワークフローを見ていこう。まずは以下を `build.sbt` に追加する:

<scala>
ThisBuild / pushRemoteCacheTo := Some(MavenCache("local-cache", file("/tmp/remote-cache")))
</scala>

これは、Maven スタイルのリポジトリなら何でもいい。だけどもキャッシュなので、実際のアーティファクトと混ぜない方がいいと思う。

次に、sbt シェルから `akka-actor/pushRemoteCache` と打ち込む:

<code>
akka > akka-actor/pushRemoteCache
[info] Formatting 22 Java sources...
[info] Reformatted 0 Java sources
[info] Generating 'Tuples.scala'
[info] Generating 'Functions.scala'
[info] Wrote /Users/eed3si9n/work/quicktest/akka-0/akka-actor/target/scala-2.12/akka-actor_2.12-2.6.5+25-683868f9+20200506-1411.pom
[info] Compiling 191 Scala sources and 28 Java sources to /Users/eed3si9n/work/quicktest/akka-0/akka-actor/target/scala-2.12/classes ...
....
[info]  published akka-actor_2.12 to file:/tmp/remote-cache/com/typesafe/akka/akka-actor_2.12/0.0.0-683868f9fe/akka-actor_2.12-0.0.0-683868f9fe.pom
[info]  published akka-actor_2.12 to file:/tmp/remote-cache/com/typesafe/akka/akka-actor_2.12/0.0.0-683868f9fe/akka-actor_2.12-0.0.0-683868f9fe-cached-compile.jar
[info]  published akka-actor_2.12 to file:/tmp/remote-cache/com/typesafe/akka/akka-actor_2.12/0.0.0-683868f9fe/akka-actor_2.12-0.0.0-683868f9fe-cached-test.jar
[success] Total time: 45 s, completed May 6, 2020 2:12:11 PM
</code>

上の「683868f9fe」は `remoteCacheId` だ。取り敢えず Git のコミットid を使ったけども、自分のビルドに合わせて変えることもできる。将来これは全てのソースのハッシュとかに変えるべきかも。

別の作業ディレクトリから `clean` と `akka-actor/pullRemoteCache` と打ち込む:

<code>
cd ~/work/quicktest/
cp -r akka-0 akka-1
cd akka-1
sbt
akka > clean
[success] Total time: 1 s, completed May 6, 2020 2:17:40 PM
akka > akka-actor/pullRemoteCache
[success] Total time: 1 s, completed May 6, 2020 2:17:46 PM
</code>

次に `akka-actor/compile` を実行する:

<code>
akka > akka-actor/compile
[info] Formatting 22 Java sources...
[info] Reformatted 0 Java sources
[info] Generating 'Tuples.scala'
[info] Generating 'Functions.scala'
[info] Compiling 1 Scala source to /Users/eed3si9n/work/quicktest/akka-1/akka-actor/target/scala-2.12/classes ...
[success] Total time: 4 s, completed May 6, 2020 2:21:13 PM
</code>

Java の整形とコード生成が走って多少のコンパイルが発生した。これは実は悪いことではなくて、このセットアップの緩さを証明してくれた。差分コンパイラは部分的に一致するコードは見慣れているので、リモートのキャッシュと多少の違いがあっても良しなにしてくれるのだ。

別の言い方をすると、リモートのキャッシュから差分コンパイルの**レジューム**を行うことができたと言える。この概念は例えば、コミット履歴にも当てはまる。例えば、もし現在のコミットid に相当するリモート・キャッシュが無かったとしても、数コミット分履歴をさかのぼって古いキャッシュからコンパイルをレジュームしても多分大丈夫だと思う。とりあえず、このシンプルなテストでも 45 vs (1 + 4)s なので 9x のスピードアップとなった。

### リモート・キャッシュに何が入ってるの?

今の所はリモート・キャッシュの JAR には classes ディレクトリと zip化された Zinc Analysis ファイルが入っている。全てのビルドツールは Maven リポジトリへの publish をしたり、Maven リポジトリから依存性解決を行うことができるはずなので、このアイディアは Zinc を採用している全てのビルドツールに応用できるはずだ。

さらに、この考えはテスト結果などにも応用できるかもしれない。sbt は成功したテストとそれらのタイムスタンプを保存している。それを使って `testQuick` は差分テストを走らせることができる。タイムスタンプじゃなくてコンテンツハッシュ的なものを使うことで、最後に走った CI 以降変わったテストのみ実行するといったことができるようになるかもしれない。

### 万人のためのコンパイルキャッシュ

コンパイルキャッシュ (もしくはリモートキャッシュ) という概念はしばらくあったものだが、それを実際にセットアップするのは簡単ではなかった。「関数としてのビルド」機能を基礎的なツールチェインである Zinc や sbt に仕込むことで Scala コミュニティー全体がビルドの高速化の恩恵が得られると思っている。

オープンソースのプロジェクトでも Travis CI が Bintray にキャッシュをプッシュすれば、コントリビューターは最新のビルドからコンパイルをレジュームということができるかもしれない。

sbt の変更の pull req は [sbt/sbt#5534](https://github.com/sbt/sbt/pull/5534) で、Zinc 側の仮想ファイル化は [sbt/zinc#712](https://github.com/sbt/zinc/pull/712) だ。
