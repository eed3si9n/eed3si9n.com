  [1]: https://github.com/olafurpg/sbt-ci-release

本稿では Ólafur さんの [olafurpg/sbt-ci-release][1] を使って sbt プラグインのリリースを自動化してみる。sbt-ci-release の README は Sonatype OSS 向けの普通のライブラリのリリースを前提に書かれている。sbt プラグインのリリースに必要な差分以外の詳細は README を参照してほしい。

リリースを自動化することそのものがベスト・プラクティスだが、sbt プラグインのリリースに関連して特に嬉しいことがある。この方法を使うことで Bintray の sbt organization にユーザーを追加せずに、複数人で sbt プラグインのリリース権限を共有することが可能となる。これは仕事でメンテしているプラグインがあるときに便利だ。

### step 1: sbt-ci-release

sbt-release を使っている場合は削除する。sbt-ci-release を追加する。

<scala>
addSbtPlugin("org.foundweekends" %% "sbt-bintray" % "0.5.6")
addSbtPlugin("com.geirsson" % "sbt-ci-release" % "1.5.3")
</scala>

`version.sbt` も削除する。

### step 2: -SNAPSHOT version

sbt-dynver を多少抑えて、タグの付いていないコミットで -SNAPSHOT バージョンを使えるようにする:

<scala>
ThisBuild / dynverSonatypeSnapshots := true
ThisBuild / version := {
  val orig = (ThisBuild / version).value
  if (orig.endsWith("-SNAPSHOT")) "2.2.0-SNAPSHOT"
  else orig
}
</scala>

### step 3: sbt-bintray セッティングを復活させる

プラグインは通常 sbt-bintray を使ってリリースするので、`publishTo` を `bintray / publishTo` に戻す。`publishMavenStyle` を `false` にする。

<scala>
  publishMavenStyle := false,
  bintrayOrganization := Some("sbt"),
  bintrayRepository := "sbt-plugin-releases",
  publishTo := (bintray / publishTo).value,
</scala>

### step 4: bintrayReleaseOnPublish オーバーライドの削除

publish が自動的にリリースするようにしてほしいので、現在 `bintrayReleaseOnPublish := false` を設定している場合はそれを削除する。

```
// bintrayReleaseOnPublish := false,
```

### step 5: 新規に GPG キーを作成する

[olafurpg/sbt-ci-release][1] の指示に従って新規に GPG キーを生成する。

<code>
$ gpg --gen-key
gpg (GnuPG/MacGPG2) 2.2.20; Copyright (C) 2020 Free Software Foundation, Inc.
This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.

Note: Use "gpg --full-generate-key" for a full featured key generation dialog.

GnuPG needs to construct a user ID to identify your key.

Real name: sbt-avro bot
Email address: eed3si9n@gmail.com

....

public and secret key created and signed.

pub   rsa2048 2020-08-07 [SC] [expires: 2022-08-07]
      0AC38C6BAD42D5980D8E01A17766C6BECAD5CE7B
uid                      sbt-avro bot <eed3si9n@gmail.com>
sub   rsa2048 2020-08-07 [E] [expires: 2022-08-07]
</code>

この公開鍵 ID を `LONG_ID` として書き留める:

<code>
LONG_ID=0AC38C6BAD42D5980D8E01A17766C6BECAD5CE7B
echo $LONG_ID
gpg --armor --export $LONG_ID
</code>

公開鍵を http://keyserver.ubuntu.com:11371/ に届け出る。

### step 6: Travis CI 環境変数

Travis CI セッティング内の環境変数を設定する。タグは独自のブランチを作るので、master ブランチに**制限してはいけない**ことに注意。

以下の変数は "display value in build log" をトグルして内容を公開する:

- `CI_CLEAN`: `clean`
- `CI_RELEASE`: `publishSigned`
- `CI_SONATYPE_RELEASE`: sbt-bintray が自動リリースする場合は `version`、そうじゃなければ `bintrayReleaseOnPublish`

以下の変数はデフォルトのまま値を秘密にする:

- `BINTRAY_USER`: Bintray ユーザー名
- `BINTRAY_PASS`: Bintray ユーザーの API キー
- `PGP_PASSPHRASE`: さっき作成した GPG 鍵のキーフレーズ。Bash 特殊文字が含まれている場合は `'my?pa$$word'` というふうにシングルクォートでくくってやる必要がある。[Travis Environment Variables](https://docs.travis-ci.com/user/environment-variables/#defining-variables-in-repository-settings) 参照。
- `PGP_SECRET`: base64 エンコードされた秘密鍵。以下のコマンドを実行して得られる:

<code>
# macOS
gpg --armor --export-secret-keys $LONG_ID | base64 | pbcopy
# Ubuntu (assuming GNU base64)
gpg --armor --export-secret-keys $LONG_ID | base64 -w0 | xclip
# Arch
gpg --armor --export-secret-keys $LONG_ID | base64 | sed -z 's;\n;;g' | xclip -selection clipboard -i
# FreeBSD (assuming BSD base64)
gpg --armor --export-secret-keys $LONG_ID | base64 | xclip
</code>

### step 7: Travis CI YAML

<code>
language: scala

jdk: openjdk8

stages:
  - name: test
  - name: release
    if: (tag IS present) AND NOT fork

jobs:
  include:
    # stage="test" if no stage is specified
    - name: jdk8
      jdk: openjdk8
    - name: jdk11
      jdk: openjdk11
    # run ci-release only if previous stages passed
    - stage: release
      script: sbt ci-release

before_install:
  - git fetch --tags

script: sbt clean test scripted

before_cache:
- find $HOME/.ivy2/cache     -name "ivydata-*.properties" -print -delete
- find $HOME/.cache/coursier -name                        -print -delete
- find $HOME/.sbt            -name "*.lock"               -print -delete

cache:
  directories:
    - $HOME/.ivy2/cache
    - $HOME/.cache/coursier
    - $HOME/.sbt
</code>

### step 8: タグ駆動リリース

プラグインをリリースする準備ができたら、コミットにタグを付けて push する。

<code>
git tag -a v0.1.0 -m "v0.1.0"
git push origin v0.1.0
</code>

Travis CI でリリースジョブが開始するはずだ。
