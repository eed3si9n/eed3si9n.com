  [jw1]: http://jakewharton.com/java-interoperability-policy-for-major-version-updates/
  [3173]: https://github.com/ReactiveX/RxJava/issues/3173
  [3170]: https://github.com/ReactiveX/RxJava/issues/3170
  [rxjava2]: https://github.com/ReactiveX/RxJava/wiki/What's-different-in-2.0#maven-address-and-base-package
  [lang3]: http://commons.apache.org/proper/commons-lang/article3_0.html
  [ComparableVersion]: https://maven.apache.org/ref/3.5.0/maven-artifact/apidocs/org/apache/maven/artifact/versioning/ComparableVersion.html
  [latest-wins]: http://ant.apache.org/ivy/history/2.3.0/ivyfile/conflicts.html
  [nearest-wins]: https://maven.apache.org/guides/introduction/introduction-to-dependency-mechanism.html
  [semver2]: http://semver.org/spec/v2.0.0.html
  [harrah1]: https://docs.google.com/presentation/d/160LhAu9nl0zs1JzwAp8YUGQx5naJIE7dt1Q_VOoVnBk/edit#slide=id.gce05306d_050
  [hickey1]: https://www.youtube.com/watch?v=oyLBGkS5ICk

本稿では、僕が Persistent Versioning と呼んでるバージョン方法を紹介する。本稿中に出てくるアイディアの多くは新しくもなければ僕が考案したものでもない。既に名前があるならば是非教えてほしい。

2015年に Jake Wharton ([@JakeWharton](https://twitter.com/JakeWharton/)) さんが [メジャーバージョンアップデートのための Java 相互互換方針 (Java Interoperability Policy for Major Version Updates)][jw1] というブログ記事を書いた:

<blockquote class="twitter-tweet" data-lang="en"><p lang="en" dir="ltr">A new policy from <a href="https://twitter.com/jessewilson">@jessewilson</a> and I for the libraries we work on to ensure major version updates are interoperable: <a href="https://t.co/zKqYRwrXmq">https://t.co/zKqYRwrXmq</a></p>&mdash; Jake Wharton (@JakeWharton) <a href="https://twitter.com/JakeWharton/status/675344652527083520">December 11, 2015</a></blockquote>

> 1. **Java パッケージ名にバージョン番号を含むように名前を変える。**
>
>    これによって、間接的依存ライブラリが複数のバージョンを持つ場合の API 互換性の問題が即時に解決する。同じクラスパスから各々のクラスを相互干渉することなく読み込むことができる。(中略)
>    (メジャーバージョンが 0 か 1 のライブラリはこの方針を飛ばして、メジャーバージョンが 2 に上がってから始めてもいい。)
>
> 2. **Maven 座標の group ID の一部としてライブラリ名を含ませること。**
>   
>    たとえ単一のアーティファクトしか持たないプロジェクトでも、group ID にプロジェクト名を入れておくと将来的に複数のアーティファクトを持ったときにルートの名前空間を散らかさなくてもいい。最初から複数のアーティファクトを持つ場合は、Maven Central などにおいてアーティファクトをまとめる方法となる。 ....
>
> 3. **Maven 座標中の group ID にバージョン番号を含むように名前を変える。**
>
>    独立した group ID を持たせることで依存性解決のセマンティクスが古いバージョンを新しい非互換なものにアップグレードさせることを予防する。メジャーバージョンはそれぞれ独立して解決され、間接的依存性が互換性を保ちながらアップグレードされるようになる。(中略)
>
>    (メジャーバージョンが 0 か 1 のライブラリはこの方針を飛ばして、メジャーバージョンが 2 に上がってから始めてもいい。)

上記の tweet のスレッドでは Jake さんは RxJava の 2つの GitHub イッシュー [Version 2.x Maven Central Identification ReactiveX/RxJava#3170][3170] と [2.0 Package Name ReactiveX/RxJava#3173](3173) に言及していて、それらは Ben Christensen ([@benjchristensen](https://twitter.com/benjchristensen)) さんにより開かれている。

#### RxJava

[RxJava 2.x][rxjava2] は別の organization (group ID) とパッケージ名にてリリースされた:

> ### Maven アドレスとベース・パッケージ
>
> RxJava 1.x系 と RxJava 2.x系を併用できるように、RxJava 2.x系は Maven 座標 `io.reactivex.rxjava2:rxjava:2.x.y` にてリリースされ、クラスは `io.reactivex` 以下に置かれる。
>
> 1.x系から 2.x系に切り替える場合は、import 文を注意深く変える必要がある。

GitHub イッシューと上記のリリースノートから分かるように、この変更は 1.x系と 2.x系が併用できるように意識的に行われた。

#### Square Retrofit と Square OkHttp

[メジャーバージョンアップデートのための Java 相互互換方針 (Java Interoperability Policy for Major Version Updates)][jw1]中で Jake さんは、自身が管理している Square Retrofit 3.x と Square OkHttp 2.x がこの方針を採用することを公言した。

> ライブラリのメジャーバージョンアップデートは古いライブラリの欠点を解決し、新品ピカピカの API をもたらすが、多くの場合互換性の無い変更となる。Android や Java のアプリの依存性を更新して、恩恵を得るのには一日または二日がかりの作業となる。このとき、自分が依存する他のライブラリがまだ更新した間接的依存性の古いバージョンを使っている場合問題となる。

Jake さんは間接的依存性によってもたらされる問題を提起している。これは diamond dependency problem (菱形依存性問題) と呼ばれる。

#### Apache Commons Lang

2011年に Apache Commons team は [Apache Commons Lang 3.0][lang3] を発表した。

> ... 我々は API のうち廃止勧告となっていた部分を削除して、また弱かったり不必要だと思われる機能も削除した。そのため、Lang 3.0 には後方互換性が無い。
> 
> これに対処するため、副作用無く Lang 3.0 が Lang の過去のバージョンと併用できるようにパッケージ名を変更した。新しいパッケージ名は、エキサイティングで独創的な `org.apache.commons.lang3` という名前だ。これは、コードの再コンパイルを強制し、もし後方互換性の影響を受けた場合はコンパイラが教えてくれるようようにした。

これは、同一のライブラリの別バージョンがクラスパス上で共存できることを目的としてパッケージ名と **group ID** (organization 名) の両方を変更した有名な例の中では最も早期のものかもしれない。

### バージョンの中毒になってはいけない

情報開示しておくと、僕は本業で [sbt](http://www.scala-sbt.org/) という Scala や Java のプロジェクトで使われてるビルドツールのメンテを行っていて、それは Apache Ivy や Maven エコシステムを使ってパッケージマネジャーとしてふるまうこともできる。だから僕の意見に何らかの資格があるわけじゃないが、僕がこのトピックに関してたまに考えているという目安にはなると思う。

![persistent-versioning-water](/images/persistent-versioning-water.jpg)

Mad Max: Fury Road が始まってすぐに、世界滅亡後の砂漠に住んでいるボロ布を着た市民に対して Immortan Joe が水を一分だけ噴水して、高らかに演説するシーンがある。曰く、「友よ、水の中毒になってはいけない。それは君たちを乗っ取り、その欠如を恨むだろう。」これを、僕達のコンテキストに換言すると:

> バージョンの中毒になってはいけない。それは君たちを乗っ取り、その欠如を恨むだろう。

僕の基本的なバージョン番号に対するスタンスは、依存性を減らしていくべきものだと思っているということだ。そもそも、バージョンは `String` だ。アプリのプログラマ視点で見ると、Maven や Ivy といった依存性リゾルバーが選択するものなので、その文字列が何になるかの制御はほとんど無い。ライブラリ作者の視点で見ると、状況はさらに悪くて、誰が自分のコードをどの間接依存性と一緒に使うかも分からない。

`String` なので、バージョン番号そのものには、ソートの序列や意味なんて無い。ここでも再び我々は Maven や Ivy の内部実装にしぶしぶ勝ちを譲って、「`beta` or `b`」 に特殊な意味を持たせる [ComparableVersion][ComparableVersion] に甘んじるしかない。

Scala、Java、その他の静的型付けが行われる言語を書くプログラマとして、多くの間違った振る舞いをコンパイル時に避けることができることを誇りに思い、ときとして型クラスの法則や大域的一意性 (coherence とも呼ばわる) にまで思いを馳せたりする。コードを書くのに多くの時間やエネルギーを費やしてる割に、いざサービスを本番環境にデプロイするとなると JAR ファイルは依存性リゾルバーが任意に選択したものを使っている。Maven や Ivy を使っているうちは Liskov は嘘だ。

例えば、依存性グラフに複数のバージョンが見つかった場合、Ivy は Ivy アーティファクトに [latest-wins][latest-wins] を使い、Maven は [nearest-wins][nearest-wins] を使い、Maven アーティファクトに関しては Ivy は nearest-win を模倣する。そのため、アプリ開発者の気分次第でライブラリの依存性はアップグレードされたりダウングレードされることを意味する。

### Spec-ulation Keynote

2016年12月の Clojure/conj の基調講演として Rich Hickey さんは、このトピックに関する [Spec-ulaiton Keynote][hickey1] というトークを行った ([Alexandru](https://github.com/typelevel/cats/issues/1233#issuecomment-320989701) さんに教えてもらった)。

![persistent-versioning-spec](/images/persistent-versioning-spec.png)

> Breaking changes are broken. (互換性の無い変更は壊れている)。ダメなアイディアだ。やめろ。
> それを行う正しい方法を模索するのもやめろ。

このトークにおいて Rich さんは「accrual」つまり蓄積をソフトフェアの変更のモードとして、同じパッケージ名内では breaking change を行わないことを推奨している。

### 嘘、意図的な嘘、そしてバージョン意味論

Rich さんが話したポイントの一つに依存性リゾルバーは悪くないというのがあって、それは僕も賛成する。依存性リゾルバーは、オーバーに指定されすぎた制約充足問題をどうにか解決しようしているに過ぎないからだ。いつも通り、悪いのは人間ということになる。

区分けされた数字に希望や意味論を上乗せし始めたのは我々だからだ。[Semantic Versioning][semver2] の擁護者は第一区分を使って互換性の無い変更点を表記する:

> メジャーバージョン X （X.y.z | X > 0）は、パブリックAPIに対して後方互換性を持たない変更が取り込まれた場合、上げなければなりません（MUST）。その際マイナー、パッチレベルの変更も含めてよいです（MAY）。メジャーバージョンを上げた際にはパッチ、マイナーバージョンは0にリセットしなければなりません（MUST）。

Scala コンパイラと標準ライブラリは Semantic Versioning の亜種を採用していて、第一区分は神秘的な「epoch」数、つまり言語そのものの意味論を表す。この伝統は何故か残りの Scala エコシステムにも伝搬して、Scala ライブラリの多くが "epoch.major.minor" スキームを採用して、第二区分を使って互換性を持たない変更を表す。

ここで注目するべきなのは、Semantic Versioning にしろ、Scala のガラパゴス進化的な第二区分変種にしろ、これらの意味論は一切 `pom.xml` や `ivy.xml` ファイルには形式化されていないということだ。つまり、これらはウェブサイトやリリースノートに書かれているかもしれないという社会的慣例に過ぎない。

### 脱出方法

これらを全て解決する一つの方法としては、JAR ファイルの入れ替えを止めて、コミットに対して毎回ライブラリエコシステムの全てをソースからコンパイルすることだ。monorepo はこれプラス良いキャッシングを与えてくれる。Google 社はこれを行っているが、これはこれで興味深い長所と短所があって、例えば、社員全員が単一のソースツリー上で作業する必要がある。

[メタデータを Git のような DVCS][harrah1]に保存するというアイディアもある。僕個人としては、Maven や Maven Central に競合して継続的な労力を要する方法は懐疑的だ。

Persistent Versioning は、既存の Maven エコシステムと戦う代わりに受け入れているという点において、この泥沼からの脱出方法として見込みがあるんじゃないかと思っている。

### 永続ライブラリ

考えようによっては、JAR ファイルは関数が色々入ったバッグにすぎない。破壊的な変更において、パッケージ名と organization (group ID) を変更するというのは、JAR ファイルを immutable なコレクションとして扱うということだ。その結果として得られるライブラリは**永続ライブラリ**だと考えることができる。ここに含まれるデータ型や関数群は永遠に失われないからだ。

メンテのオーバーヘッドとしては、ライブラリが Semantic Versioning を採用していればマイナーリリースでバイナリ互換性を壊さないかの方策を既に取っているはずなので、特に変わらないはずだ。

### Persistent Versioning を誰が採用するべきか

Persistent Versioning の初期採用者を見ると、それらが広く使われることを意図したライブラリであることが明らかだ。また、これは別のライブラリから間接依存性として使われることが多いだろう。Square OkHttp を一例にとると、これは Android 本体の一部として搬出されている。ライブラリの複数バージョンの併用が不可能ではない限りこのスキームの採用を是非検討してみてほしい。
