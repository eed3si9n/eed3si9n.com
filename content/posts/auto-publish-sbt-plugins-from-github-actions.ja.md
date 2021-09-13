---
title:       "GitHub Actions からの sbt プラグインの自動公開"
type:        story
date:        2020-12-01
changed:     2020-12-03
draft:       false
promote:     true
sticky:      false
url:         /ja/auto-publish-sbt-plugin-from-github-actions
aliases:     [ /node/371 ]
tags:        [ "sbt" ]
---

  [1]: https://github.com/olafurpg/sbt-ci-release

本稿は前に書いた[Travis-CI からの sbt プラグインの自動公開](https://eed3si9n.com/ja/auto-publish-sbt-plugin)の GitHub Actions 版だ。

Ólaf さんの [olafurpg/sbt-ci-release][1] を使って sbt プラグインのリリースを自動化してみる。sbt-ci-release の README は Sonatype OSS 向けの普通のライブラリのリリースを前提に書かれている。sbt プラグインのリリースに必要な差分以外の詳細は README を参照してほしい。

リリースを自動化することそのものがベスト・プラクティスだが、sbt プラグインのリリースに関連して特に嬉しいことがある。この方法を使うことで Bintray の sbt organization にユーザーを追加せずに、複数人で sbt プラグインのリリース権限を共有することが可能となる。これは仕事でメンテしているプラグインがあるときに便利だ。

### step 1: sbt-ci-release

sbt-release を使っている場合は削除する。sbt-ci-release を追加する。

<scala>
addSbtPlugin("org.foundweekends" %% "sbt-bintray" % "0.6.1")
addSbtPlugin("com.geirsson" % "sbt-ci-release" % "1.5.4")
addSbtPlugin("com.jsuereth" % "sbt-pgp" % "2.1.1") // for gpg 2
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

### step 6: 秘密の設定

`https://github.com/<owner>/<repo>/settings/secrets/actions` から秘密を設定する:

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

### step 7: 秘密鍵のデコード

最近の Ubuntu ディストロで使われいる gpg 2.2 のために、秘密鍵を時前でデコードする必要がある。 `.github/decodekey.sh` というファイルを追加する:

<code>
#!/bin/bash

echo $PGP_SECRET | base64 --decode | gpg  --batch --import
</code>

実行権を付ける:

<code>
$ chmod +x .github/decodekey.sh
</code>

### step 8: GitHub Actions YAML

`.github/workflows/ci.yml` を作る。詳細は [Setting up GitHub Actions with sbt](https://www.scala-sbt.org/1.x/docs/GitHub-Actions-with-sbt.html) 参照。

<code>
name: CI
on:
  pull_request:
  push:
  schedule:
  # 2am EST every Saturday
  - cron: '0 7 * * 6'
jobs:
  tests:
    runs-on: ubuntu-latest
    env:
      # define Java options for both official sbt and sbt-extras
      JAVA_OPTS: -Xms2048M -Xmx2048M -Xss6M -XX:ReservedCodeCacheSize=256M -Dfile.encoding=UTF-8
      JVM_OPTS:  -Xms2048M -Xmx2048M -Xss6M -XX:ReservedCodeCacheSize=256M -Dfile.encoding=UTF-8
    steps:
    - name: Checkout
      uses: actions/checkout@v2
    - name: Setup Scala
      uses: olafurpg/setup-scala@v10
      with:
        java-version: "adopt@1.8"
    - name: Coursier cache
      uses: coursier/cache-action@v5
    - name: Build and test
      run: |
        sbt -v clean scalafmtCheckAll test scripted
        rm -rf "$HOME/.ivy2/local" || true
        find $HOME/Library/Caches/Coursier/v1        -name "ivydata-*.properties" -delete || true
        find $HOME/.ivy2/cache                       -name "ivydata-*.properties" -delete || true
        find $HOME/.cache/coursier/v1                -name "ivydata-*.properties" -delete || true
        find $HOME/.sbt
</code>

リリース用に `.github/worflows/release.yml` も作る:

<code>
name: Release
on:
  push:
    tags:
      - '*'
jobs:
  build:
    runs-on: ubuntu-latest
    env:
      # define Java options for both official sbt and sbt-extras
      JAVA_OPTS: -Xms2048M -Xmx2048M -Xss6M -XX:ReservedCodeCacheSize=256M -Dfile.encoding=UTF-8
      JVM_OPTS:  -Xms2048M -Xmx2048M -Xss6M -XX:ReservedCodeCacheSize=256M -Dfile.encoding=UTF-8
    steps:
    - name: Checkout
      uses: actions/checkout@v2
    - name: Setup Scala
      uses: olafurpg/setup-scala@v10
      with:
        java-version: "adopt@1.8"
    - name: Coursier cache
      uses: coursier/cache-action@v5
    - name: Test
      run: |
        sbt test packagedArtifacts
    - name: Release
      env:
        BINTRAY_USER: ${{ secrets.BINTRAY_USER }}
        BINTRAY_PASS: ${{ secrets.BINTRAY_PASS }}
        PGP_PASSPHRASE: ${{ secrets.PGP_PASSPHRASE }}
        PGP_SECRET: ${{ secrets.PGP_SECRET }}
        CI_CLEAN: clean
        CI_RELEASE: publishSigned
        CI_SONATYPE_RELEASE: version
      run: |
        .github/decodekey.sh
        sbt ci-release
</code>

### step 9: タグ駆動リリース

プラグインをリリースする準備ができたら、コミットにタグを付けて push する。

<code>
git tag -a v0.1.0 -m "v0.1.0"
git push origin v0.1.0
</code>

GitHub Actions でリリースジョブが開始するはずだ。

<a name="gpg2"></a>
### gpg 2 に関する備考

sbt-pgp は署名をするときに `--passphrase` オプションを使う。[ドキュメンテーション](https://www.gnupg.org/documentation/manuals/gnupg/GPG-Esoteric-Options.html#GPG-Esoteric-Options) によると、新たに `--pinentry-mode loopback` を渡す必要がある:

> Note that since Version 2.0 this passphrase is only used if the option `--batch` has also been given. Since Version 2.1 the `--pinentry-mode` also needs to be set to `loopback`.

sbt-pgp 2.1.1 で `gpg` コマンドのバージョン番号を検知して `--pinetry-mode loopback` オプションを渡すようにした。

sbt-ci-release は `--import` を使うが、これは gpg 2.2 で静かに失敗して以下のようなエラーとなって表出する:

<code>
gpg: key 24A4616356F15CE1: public key "sbt-something bot <some@example.com>" imported
gpg: key 24A4616356F15CE1/24A4616356F15CE1: error sending to agent: Inappropriate ioctl for device
gpg: error building skey array: Inappropriate ioctl for device
gpg: Total number processed: 1
gpg:               imported: 1
gpg:       secret keys read: 1
Tag push detected, publishing a stable release
....
[info] gpg: no default secret key: No secret key
[info] gpg: signing failed: No secret key
[error] java.lang.RuntimeException: Failure running 'gpg --batch --pinentry-mode loopback --passphrase *** --detach-sign --armor --use-agent --output /home/runner/work/sbt-projectmatrix/sbt-projectmatrix/target/scala-2.12/sbt-1.0/sbt-projectmatrix-0.7.1-M1.jar.asc /home/runner/work/sbt-projectmatrix/sbt-projectmatrix/target/scala-2.12/sbt-1.0/sbt-projectmatrix-0.7.1-M1.jar'.  Exit code: 2
</code>

[T2313](https://dev.gnupg.org/T2313) によると、この回避策は `--batch --import` を使うことで、`.github/decodekey.sh` はそれを行う。

この辺りの問題に関しては一応何となく存在は知っていたけども自分が使っている Xenial イメージに付いてくる gpg 1.4 はこれらのオプションと互換性が無かったため特にアクションを取ってこなかった。GitHub Action は Bionic を使っていて、これから Focal にも移行するようなのでこれらの問題に皆も遭遇するようになったということだ。
