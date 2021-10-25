---
title:       "auto publish sbt plugin from GitHub Actions"
type:        story
date:        2020-12-01
changed:     2020-12-03
draft:       false
promote:     true
sticky:      false
url:         /auto-publish-sbt-plugin-from-github-actions
aliases:     [ /node/370 ]
tags:        [ "sbt" ]
---

  [1]: https://github.com/olafurpg/sbt-ci-release

This is a GitHub Actions version of [auto publish sbt plugin from Travis CI](https://eed3si9n.com/auto-publish-sbt-plugin).

In this post, we'll try to automate the release of an sbt plugin using Ólaf's [olafurpg/sbt-ci-release][1]. The README of sbt-ci-release covers the use case for a library published to Sonatype OSS. Read it thoroughly since this post will skip over the details that do not change for publishing sbt plugins.

Automated release in general is a best practice, but there's one benefit specifically for sbt plugin releases. Using this setup allows multiple people to share the authorization to release an sbt plugin without adding them to Bintray sbt organization. This is useful for plugins maintained at work.

### step 1: sbt-ci-release

Remove sbt-release if you're using that. Add sbt-ci-release instead.

```scala
addSbtPlugin("org.foundweekends" %% "sbt-bintray" % "0.6.1")
addSbtPlugin("com.geirsson" % "sbt-ci-release" % "1.5.4")
addSbtPlugin("com.jsuereth" % "sbt-pgp" % "2.1.1") // for gpg 2
```

Don't forget to remove `version.sbt`.

### step 2: -SNAPSHOT version

We need to also suppress sbt-dynver a little bit so we get a simpler -SNAPSHOT versions for commits that are not tagged:

```scala
ThisBuild / dynverSonatypeSnapshots := true
ThisBuild / version := {
  val orig = (ThisBuild / version).value
  if (orig.endsWith("-SNAPSHOT")) "2.2.0-SNAPSHOT"
  else orig
}
```

### step 3: recover sbt-bintray settings

We typically use sbt-bintray to publish plugins, so rewire `publishTo` back to `bintray / publishTo`. Also set `publishMavenStyle` to `false`.

```scala
  publishMavenStyle := false,
  bintrayOrganization := Some("sbt"),
  bintrayRepository := "sbt-plugin-releases",
  publishTo := (bintray / publishTo).value,
```

### step 4: remove bintrayReleaseOnPublish overrides

We need to release on publish, so if you have `bintrayReleaseOnPublish := false`, in your `build.sbt` remove it.

```
// bintrayReleaseOnPublish := false,
```

### step 5: create a fresh GPG key

Follow the instruction in [olafurpg/sbt-ci-release][1] to generate a fresh GPG key.

```bash
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
```

Take this down as `LONG_ID`:

```bash
LONG_ID=0AC38C6BAD42D5980D8E01A17766C6BECAD5CE7B
echo $LONG_ID
gpg --armor --export $LONG_ID
```

Submit the public key to http://keyserver.ubuntu.com:11371/.

### step 6: Secrets

Set up secrets from `https://github.com/<owner>/<repo>/settings/secrets/actions`:

- `BINTRAY_USER`: Bintray user name.
- `BINTRAY_PASS`: The API key for the Bintray user.
- `PGP_PASSPHRASE`: The randomly generated password you used to create a fresh
  GPG key. If the password contains bash special characters, make sure to
  escape it by wrapping it in single quotes `'my?pa$$word'`, see
  [Travis Environment Variables](https://docs.travis-ci.com/user/environment-variables/#defining-variables-in-repository-settings).
- `PGP_SECRET`: The base64 encoding of your private key that you can
  export from the command line like here below

```bash
# macOS
gpg --armor --export-secret-keys $LONG_ID | base64 | pbcopy
# Ubuntu (assuming GNU base64)
gpg --armor --export-secret-keys $LONG_ID | base64 -w0 | xclip
# Arch
gpg --armor --export-secret-keys $LONG_ID | base64 | sed -z 's;\n;;g' | xclip -selection clipboard -i
# FreeBSD (assuming BSD base64)
gpg --armor --export-secret-keys $LONG_ID | base64 | xclip
```

### step 7: Decode the secret key

For gpg 2.2 that are on more recent Ubuntu distros, we need to hand decode the private keys ourselves for now. Add `.github/decodekey.sh`:

```bash
#!/bin/bash

echo $PGP_SECRET | base64 --decode | gpg  --batch --import
```

And give it execution rights:

```bash
$ chmod +x .github/decodekey.sh
```

### step 8: GitHub Actions YAML

Create `.github/workflows/ci.yml`. See [Setting up GitHub Actions with sbt](https://www.scala-sbt.org/1.x/docs/GitHub-Actions-with-sbt.html) for details:

```yaml
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
```

Create `.github/worflows/release.yml` for releasing:

```yaml
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
```

For cross-built plugins, adjust the above commands accordingly.

### step 9: tag-based release

When you're ready to publish your plugin, tag the commit and push it.

```bash
git tag -a v0.1.0 -m "v0.1.0"
git push origin v0.1.0
```

This should start a release job on GitHub Actions.

<a name="gpg2"></a>
### notes about gpg 2

sbt-pgp uses `gpg`'s `--passphrase` option during signing. According to the [documentation](https://www.gnupg.org/documentation/manuals/gnupg/GPG-Esoteric-Options.html#GPG-Esoteric-Options):

> Note that since Version 2.0 this passphrase is only used if the option `--batch` has also been given. Since Version 2.1 the `--pinentry-mode` also needs to be set to `loopback`.

sbt-pgp 2.1.1 was released with version detection of `gpg` command, which will add the necessary `--pinetry-mode loopback` options.

sbt-ci-release uses `--import`, which also now fails silently on gpg 2.2 and causes 

```bash
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
```

According to [T2313](https://dev.gnupg.org/T2313), the workaround for this is to use `--batch --import`, which our `.github/decodekey.sh` will do.

I was peripherally aware of some of this issue, but never took action since Xenial image that I've been using came with gpg 1.4 which is incompatible with these new options. Since GitHub Actions uses Bionic, and soon to move to Focal we're seeing this more often.
