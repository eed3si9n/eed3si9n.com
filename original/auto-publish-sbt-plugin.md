  [1]: https://github.com/olafurpg/sbt-ci-release

In this post, we'll try to automate the release of an sbt plugin using Ólafur's [olafurpg/sbt-ci-release][1]. The README of sbt-ci-release covers the use case for a library published to Sonatype OSS. Read it thoroughly since this post will skip over the details that do not change for publishing sbt plugins.

Automated release in general is a best practice, but there's one benefit specifically for sbt plugin releases. Using this setup allows multiple people to share the authorization to release an sbt plugin without adding them to Bintray sbt organization. This is useful for plugins maintained at work.

### step 1: sbt-ci-release

Remove sbt-release if you're using that. Add sbt-ci-release instead.

<scala>
addSbtPlugin("org.foundweekends" %% "sbt-bintray" % "0.5.6")
addSbtPlugin("com.geirsson" % "sbt-ci-release" % "1.5.3")
</scala>

Don't forget to remove `version.sbt`.

### step 2: -SNAPSHOT version

We need to also suppress sbt-dynver a little bit so we get a simpler -SNAPSHOT versions for commits that are not tagged:

<scala>
ThisBuild / dynverSonatypeSnapshots := true
ThisBuild / version := {
  val orig = (ThisBuild / version).value
  if (orig.endsWith("-SNAPSHOT")) "2.2.0-SNAPSHOT"
  else orig
}
</scala>

### step 3: recover sbt-bintray settings

We typically use sbt-bintray to publish plugins, so rewire `publishTo` back to `bintray / publishTo`. Also set `publishMavenStyle` to `false`.

<scala>
  publishMavenStyle := false,
  bintrayOrganization := Some("sbt"),
  bintrayRepository := "sbt-plugin-releases",
  publishTo := (bintray / publishTo).value,
</scala>

### step 4: remove bintrayReleaseOnPublish overrides

We need to release on publish, so if you have `bintrayReleaseOnPublish := false`, in your `build.sbt` remove it.

```
// bintrayReleaseOnPublish := false,
```

### step 5: create a fresh GPG key

Follow the instruction in [olafurpg/sbt-ci-release][1] to generate a fresh GPG key.

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

Take this down as `LONG_ID`:

<code>
LONG_ID=0AC38C6BAD42D5980D8E01A17766C6BECAD5CE7B
echo $LONG_ID
gpg --armor --export $LONG_ID
</code>

Submit the public key to http://keyserver.ubuntu.com:11371/.

### step 6: Travis CI environment variables

Set up environment variables in the Travis CI setting. Note do NOT limit the access only to master branch since tags are on their own branch.

The following should be made public by toggling "display value in build log":

- `CI_CLEAN`: `clean`
- `CI_RELEASE`: `publishSigned`
- `CI_SONATYPE_RELEASE`: `version` if sbt-bintray is set to automatically release, `bintrayReleaseOnPublish` otherwise

The following should be kept secret (default):

- `BINTRAY_USER`: Bintray user name.
- `BINTRAY_PASS`: The API key for the Bintray user.
- `PGP_PASSPHRASE`: The randomly generated password you used to create a fresh
  GPG key. If the password contains bash special characters, make sure to
  escape it by wrapping it in single quotes `'my?pa$$word'`, see
  [Travis Environment Variables](https://docs.travis-ci.com/user/environment-variables/#defining-variables-in-repository-settings).
- `PGP_SECRET`: The base64 encoded secret of your private key that you can
  export from the command line like here below

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

### step 8: tag-based release

When you're ready to publish your plugin, tag the commit and push it.

<code>
git tag -a v0.1.0 -m "v0.1.0"
git push origin v0.1.0
</code>

This should start a release job on Travis CI.
