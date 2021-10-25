---
title:       "君達の JDK は全て jabba がいただいた"
type:        story
date:        2018-06-11
changed:     2018-11-27
draft:       false
promote:     true
sticky:      false
url:         /ja/all-your-jdks-on-travis-ci-using-jabba
aliases:     [ /node/266 ]
tags:        [ "scala" ]
---

  [jabba]: https://github.com/shyiko/jabba

OpenJDK 11-ea, GraalVM, Eclipse OpenJ9 を試してみたり、未だに OpenJDK 6 でビルドしなければいけなかったりしたとしても [jabba][jabba] なら万全だ。[jabba][jabba] は Stanley Shyiko ([@shyiko](https://twitter.com/shyiko)) さんが作ったクロスプラットフォームな Java のバージョンマネージャーだ。

### AdoptOpenJDK 8 and 11

以下は jabba を使って Travis CI 上で AdoptOpenJDK 8 と 11 を用いてクロスビルドする方法だ:

```yaml
sudo: false
dist: trusty
group: stable

language: scala

scala:
  - 2.12.7

env:
  global:
    - JABBA_HOME=/home/travis/.jabba

matrix:
  include:
  - env:
      - TRAVIS_JDK=adopt@1.8.192-12
  - env:
      - TRAVIS_JDK=adopt@1.11.0-1

before_install:
  - curl -sL https://raw.githubusercontent.com/shyiko/jabba/0.11.0/install.sh | bash && . ~/.jabba/jabba.sh

install:
  - $JABBA_HOME/bin/jabba install $TRAVIS_JDK
  - unset _JAVA_OPTIONS
  - export JAVA_HOME="$JABBA_HOME/jdk/$TRAVIS_JDK" && export PATH="$JAVA_HOME/bin:$PATH" && java -Xmx32m -version

script: sbt -Dfile.encoding=UTF8 -J-XX:ReservedCodeCacheSize=256M ++$TRAVIS_SCALA_VERSION! test

before_cache:
  - find $HOME/.ivy2 -name "ivydata-*.properties" -delete
  - find $HOME/.sbt  -name "*.lock"               -delete

cache:
  directories:
    - $HOME/.ivy2/cache
    - $HOME/.sbt/boot
    - $HOME/.jabba/jdk
```

ジョブが走ると、以下のように表示されるはずだ:

```bash
$ export JAVA_HOME="$JABBA_HOME/jdk/$TRAVIS_JDK" && export PATH="$JAVA_HOME/bin:$PATH" && java -Xmx32m -version
openjdk version "11.0.1" 2018-10-16
OpenJDK Runtime Environment AdoptOpenJDK (build 11.0.1+13)
OpenJDK 64-Bit Server VM AdoptOpenJDK (build 11.0.1+13, mixed mode)
```


### Azul Zulu OpenJDK 6

以下は jabba を使って Travis CI 上で Azul Zulu OpenJDK 6 を用いてビルドする方法だ:

```yaml
sudo: false
dist: trusty
group: stable

language: scala

env:
  global:
    - TRAVIS_JDK=zulu@1.6.107
    - JABBA_HOME=/home/travis/.jabba
  matrix:
    - SCRIPT_TEST="; mimaReportBinaryIssues; test"

before_install:
  - curl -sL https://raw.githubusercontent.com/shyiko/jabba/0.11.0/install.sh | bash && . ~/.jabba/jabba.sh

install:
  - $JABBA_HOME/bin/jabba install $TRAVIS_JDK
  - unset _JAVA_OPTIONS
  - export JAVA_HOME="$JABBA_HOME/jdk/$TRAVIS_JDK" && export PATH="$JAVA_HOME/bin:$PATH" && java -Xmx32m -version

# Undo _JAVA_OPTIONS environment variable
before_script:
  - unset _JAVA_OPTIONS

script:
  - sbt -J-XX:ReservedCodeCacheSize=128m "$SCRIPT_TEST"

before_cache:
  - find $HOME/.ivy2 -name "ivydata-*.properties" -delete
  - find $HOME/.sbt  -name "*.lock"               -delete

cache:
  directories:
    - $HOME/.ivy2/cache
    - $HOME/.sbt/boot
    - $HOME/.jabba/jdk
```

`TRAVIS_JDK` 変数を指定するには <https://github.com/shyiko/jabba/blob/master/index.json> の `"linux"` セクションから JDK を選択する。

ジョブが走ると、以下のように表示されるはずだ:

```bash
Downloading zulu@1.6.107 (https://cdn.azul.com/zulu/bin/zulu6.20.0.1-jdk6.0.107-linux_x64.tar.gz)
64356908/64356908
Extracting /tmp/jabba-d-303130071 to /home/travis/.jabba/jdk/zulu@1.6.107
zulu@1.6 -> /home/travis/.jabba/jdk/zulu@1.6.107
Picked up _JAVA_OPTIONS: -Xmx2048m -Xms512m
openjdk version "1.6.0-107"
OpenJDK Runtime Environment (Zulu 6.20.0.1-linux64) (build 1.6.0-107-b107)
OpenJDK 64-Bit Server VM (Zulu 6.20.0.1-linux64) (build 23.77-b107, mixed mode)
....
```

上記は [travis-ci/travis-ci#9713](https://github.com/travis-ci/travis-ci/issues/9713) の回避方法だが、jabba は将来の JDK をテストに使うのにも便利になると思う。
