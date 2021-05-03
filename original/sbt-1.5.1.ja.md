
  [runner]: https://raw.githubusercontent.com/sbt/sbt/v1.5.1/sbt
  [6431]: https://github.com/sbt/sbt/pull/6431
  [6425]: https://github.com/sbt/sbt/pull/6425
  [6456]: https://github.com/sbt/sbt/pull/6456
  [6436]: https://github.com/sbt/sbt/issues/6436
  [6434]: https://github.com/sbt/sbt/pull/6434
  [launcher95]: https://github.com/sbt/launcher/pull/95
  [launcher96]: https://github.com/sbt/launcher/pull/96
  [@adpi2]: https://github.com/adpi2
  [@eed3si9n]: https://github.com/eed3si9n
  [@eatkins]: https://github.com/eatkins
  [@xuwei-k]: https://github.com/xuwei-k
  [@ashleymercer]: https://github.com/ashleymercer
  [@guilgaly]: https://github.com/guilgaly
  [@steinybot]: https://github.com/steinybot

sbt 1.5.1 パッチリリースをアナウンスする。リリースノートの完全版はここにある - https://github.com/sbt/sbt/releases/tag/v1.5.1 。本稿では Bintray から JFrog Artifactory へのマイグレーションの報告もする。

### Bintray から JFrog Artifactory へのマイグレーション

まずは JFrog社に、sbt プロジェクトおよび Scala エコシステムへの継続的なサポートをしてもらっていることにお礼を言いたい。

sbt がコントリビューター数とプラグイン数において伸び盛りだった時期に Bintray の形をした問題があった。個人のコントリビューターに Ivy レイアウトのレポジトリを作って、sbt プラグインを公開して、しかし解決側では集約したいという問題だ。GitHub の sbt オーガニゼーションでプラグインのソースを複数人で流動的に管理することができるようになったが、バイナリファイルの配信は課題として残っていた。当時は sbt のバージョンもよく変わっていたというのがある。2014年に Bintray を採用して、成長期の配信メカニズムを担ってくれた。さらに僕たちは sbt の Debian と RPM インストーラーをホスティングするのに Bintray を使っていて、これは Lightbend 社が払ってくれている。

2021年2月、JFrog は Bintray サービスの終了をアナウンスした。その直後から、JFrog 社は向こうからコンタクトしてきて、何回もミーティングをスケジュールしてくれたり、[open source sponsorship](https://jfrog.com/open-source/) をグラントしてくれたり、マイグレーション用のツールキットをくれたりとお世話になっている。

今現在 **Scala Center** にライセンスされ、**JFrog**がスポンサーしてくれたクラウド・ホストな Artifactory のインスタンスが稼働している。「Artifactory のインスタンス」と何度も書くのが長いので、本稿では Artsy と呼ぶ。sbt 1.5.1 がリリースされたことで、マイグレーションは完了したと思う。

#### read 系

- 4月18日の時点で全ての sbt プラグインと sbt 0.13 アーティファクトを Artsy に移行して、Lightbend IT チームが https://repo.scala-sbt.org/scalasbt/ を Artsy を指すようにしてくれたため、**既存のビルドは何もしなくてもそのまま動く**はずだ。これは5月1日以降でも大丈夫なはずだ。もしもそうじゃないなら、[issue](https://github.com/sbt/sbt/issues) が上がっているかチェックした後、報告をお願いします。

#### write 系

Artsy の `sbt-plugin-releases` はリードオンリーにする予定だ。そのため、プラグイン作者の人は、[Sonatype OSSRH](https://central.sonatype.org/publish/publish-guide/) に移行する必要がある。organization 名の許可が下りたら、公開は [sbt-ci-release](https://github.com/olafurpg/sbt-ci-release) で自動化できる。

近年の sbt はバイナリ互換によって昔より安定しているので、この機会に Ivy レイアウトのリポジトリから巣立ちするというのは良いことだと思う。

#### Linux サポート

- 4月26日の時点で、Debian パッケージは Artsy の `deb https://repo.scala-sbt.org/scalasbt/debian all main` にて公開される。古いリリースは `deb https://repo.scala-sbt.org/scalasbt/debian /` のままだ。

<code>
echo "deb https://repo.scala-sbt.org/scalasbt/debian all main" | sudo tee /etc/apt/sources.list.d/sbt.list
echo "deb https://repo.scala-sbt.org/scalasbt/debian /" | sudo tee /etc/apt/sources.list.d/sbt_old.list
curl -sL "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x2EE0EA64E40A89B84B2DF73499E82A75642AC823" | sudo apt-key add
sudo apt-get update
sudo apt-get install sbt
</code>

- RPM リポジトリファイルは `https://www.scala-sbt.org/sbt-rpm.repo` にてホスティングされる。RPM パッケージは Artsy にてホスティングされる。

<code>
# remove old Bintray repo file
sudo rm -f /etc/yum.repos.d/bintray-rpm.repo
curl -L https://www.scala-sbt.org/sbt-rpm.repo > sbt-rpm.repo
sudo mv sbt-rpm.repo /etc/yum.repos.d/
sudo yum install sbt
</code>

帯域要求を最小化するため、DEB ファイルと RPM ファイルは `sbt` ランナーファイルのみ含み、`sbt-launch.jar` は抜いた。

### sbt 1.5.1

sbt 1.5.1 に関しても少し。

#### アップグレード方法

SDKMAN かもしくは https://github.com/sbt/sbt/releases/tag/v1.5.1 から**公式 sbt ランナー**をダウンロードする。これは、`sbtn` バイナリを含む。

さらに、ビルドで実際に使われる sbt のバージョンは `project/build.properties` に以下を書くことでアップグレードされる:

<code>
sbt.version=1.5.1
</code>

このような二重化を行っているのは、sbt 1.5.1 を使いたいビルドだけで使うようにしているからだ。

### sbt 1.5.1 のハイライト

- [sbt][runner] ランナースクリプトを sbt/sbt リポジトリに持ってきて、`sbt-launch.jar` のダウンロードを実装した。
- sbt プラグインで偽の「@nowarn annotation does not suppress any warnings」警告が出てくる問題の修正 [#6431][6431] by [@adpi2][@adpi2]

その他の詳細は https://github.com/sbt/sbt/releases/tag/v1.5.1 参照。

### Travis CI での公式ランナーの使い方

何らかの理由で非公式な `sbt` が使えなくなった場合、以下の方法で公式 `sbt` ランナーをインストールすることができる:

<code>
install:
  - |
    export SBT_OPTS=""
    curl -L --silent "https://raw.githubusercontent.com/sbt/sbt/v1.5.1/sbt" > $HOME/sbt
    chmod +x $HOME/sbt && sudo mv $HOME/sbt /usr/local/bin/sbt
</code>

### 参加

sbt 1.5.1 は 6名のコントリビューターにより作られた。Eugene Yokota (eed3si9n), Adrien Piquerez, Ashley Mercer, Guillaume Galy, Jason Pickens, Kenji Yoshida (xuwei-k), Philippus Baalman。この場をお借りしてコントリビューターの皆さんにお礼を言いたい。

他にも sbt や Zinc 1 を使ったり、バグ報告したり、ドキュメンテーションを改善したり、ビルドを移植したり、プラグインを移植したり、pull request を送ったりレビューをするなどして sbt を改善してくれている皆さんにも感謝。

sbt を手伝ってみたいなという人は興味次第色々方法がある。[Contributing](https://github.com/sbt/sbt/blob/develop/CONTRIBUTING.md)、["help wanted"](https://github.com/sbt/sbt/issues?q=is%3Aissue+is%3Aopen+label%3A%22help+wanted%22)、["good first issue"](https://github.com/sbt/sbt/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22)、 [Discussions](https://github.com/sbt/sbt/discussions/) などが出発地点になると思う。
