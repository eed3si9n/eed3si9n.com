---
title:       "君達の JDK は全て SDKMAN! がいただいた"
type:        story
date:        2019-03-26
changed:     2020-09-24
draft:       false
promote:     true
sticky:      false
url:         /ja/all-your-jdks-on-travis-ci-using-sdkman
aliases:     [ /node/295 ]
tags:        [ "scala" ]
---

  [1]: http://eed3si9n.com/ja/all-your-jdks-on-travis-ci-using-jabba

これは Travis CI に自分で JDK をインストールする解説の第2弾だ。以前は、[jabba][1] を紹介した。

今日は [SDKMAN!](https://sdkman.io/), という、Marco Vermeulen ([@marc0der](https://twitter.com/marc0der)) さんが作った元気な名前のツールを見ていく。これは、JDK の他にも Groovy、Spark、sbt など JVM 上の様々なツールを対象とする環境マネージャーだ。

### AdoptOpenJDK 11 と 8

- **2020-09-23 更新**: バージョン番号の正規表現を更新した。
- **2019-11-06 更新**: SDKMAN の更新プロンプトが CI をブロックするのを回避するために `sdkman_auto_selfupdate` を追加した。また、`sdk install` の行に `|| true` を追加した。
- **2019-07-08 更新**: パッチバージョンを自動検知するように変更した。[古い版](https://github.com/eed3si9n/eed3si9n.com/blob/4aeeadaf8b32c4cd8d21afd4d5bdcec7538b0aff/original/all-your-jdks-on-travis-ci-using-sdkman.ja.md)は GitHub に置いてある。

以下は SDKMAN! を使って Travis CI 上で AdoptOpenJDK 8 と 11 を用いてクロスビルドする方法だ:

```yaml
dist: xenial

language: scala

scala: 2.12.10

matrix:
  include:
  - env:
      - ADOPTOPENJDK=11
  - env:
      - ADOPTOPENJDK=8

before_install:
  # adding $HOME/.sdkman to cache would create an empty directory, which interferes with the initial installation
  - "[[ -d /home/travis/.sdkman/ ]] && [[ -d /home/travis/.sdkman/bin/ ]] || rm -rf /home/travis/.sdkman/"
  - curl -sL https://get.sdkman.io | bash
  - echo sdkman_auto_answer=true > /home/travis/.sdkman/etc/config
  - echo sdkman_auto_selfupdate=true >> $HOME/.sdkman/etc/config
  - source "/home/travis/.sdkman/bin/sdkman-init.sh"

install:
  - sdk install java $(sdk list java | grep -o "$ADOPTOPENJDK\.[0-9]*\.[0-9]*\.hs-adpt" | head -1) || true
  - unset _JAVA_OPTIONS
  - unset JAVA_HOME
  - java -Xmx32m -version

script: sbt -Dfile.encoding=UTF8 -J-XX:ReservedCodeCacheSize=256M ++$TRAVIS_SCALA_VERSION! test

before_cache:
  - find $HOME/.ivy2 -name "ivydata-*.properties" -delete
  - find $HOME/.sbt  -name "*.lock"               -delete

cache:
  directories:
    - $HOME/.cache/coursier
    - $HOME/.ivy2/cache
    - $HOME/.sbt/boot
    - $HOME/.sdkman
```

ジョブが走ると、以下のように表示されるはずだ:

```bash
$ java -Xmx32m -version
openjdk version "11.0.3" 2019-04-16
OpenJDK Runtime Environment AdoptOpenJDK (build 11.0.3+7)
OpenJDK 64-Bit Server VM AdoptOpenJDK (build 11.0.3+7, mixed mode)
install.4
$ javac -version
javac 11.0.3
```

### sbt 公式ディストリビューション

SDKMAN! を使うことで、Travis CI がプレインストールする sbt-extras じゃなくて sbt 公式ディストリビューションを使うことも可能だ。

```yaml
dist: xenial

language: scala

scala: 2.12.10

matrix:
  include:
  - env:
      - ADOPTOPENJDK=11
  - env:
      - ADOPTOPENJDK=8

before_install:
  # adding $HOME/.sdkman to cache would create an empty directory, which interferes with the initial installation
  - "[[ -d /home/travis/.sdkman/ ]] && [[ -d /home/travis/.sdkman/bin/ ]] || rm -rf /home/travis/.sdkman/"
  - curl -sL https://get.sdkman.io | bash
  - echo sdkman_auto_answer=true > /home/travis/.sdkman/etc/config
  - echo sdkman_auto_selfupdate=true >> $HOME/.sdkman/etc/config
  - source "/home/travis/.sdkman/bin/sdkman-init.sh"

install:
  - sdk install java $(sdk list java | grep -o "$ADOPTOPENJDK\.[0-9]*\.[0-9]*\.hs-adpt" | head -1) || true
  - unset _JAVA_OPTIONS
  - unset JAVA_HOME
  - java -Xmx32m -version
  # detect sbt version from project/build.properties, otherwise hardcode as export TRAVIS_SBT=1.2.8
  - export TRAVIS_SBT=$(grep sbt.version= project/build.properties | sed -e 's/sbt.version=//g' ) && echo "sbt $TRAVIS_SBT"
  - sdk install sbt $TRAVIS_SBT || true
  # override Travis CI's SBT_OPTS
  - unset SBT_OPTS
  - export JAVA_OPTS="-Xms2048M -Xmx2048M -Xss6M -XX:ReservedCodeCacheSize=256M"

script: sbt -Dfile.encoding=UTF8 ++$TRAVIS_SCALA_VERSION! test

before_cache:
  - find $HOME/.ivy2 -name "ivydata-*.properties" -delete
  - find $HOME/.sbt  -name "*.lock"               -delete

cache:
  directories:
    - $HOME/.cache/coursier
    - $HOME/.ivy2/cache
    - $HOME/.sbt/boot
    - $HOME/.sdkman
```
