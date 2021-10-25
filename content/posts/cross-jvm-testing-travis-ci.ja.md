---
title:       "Travis CI を用いたクロス JVM テスト"
type:        story
date:        2018-02-15
draft:       false
promote:     true
sticky:      false
url:         /ja/cross-jvm-testing-travis-ci
aliases:     [ /node/257 ]
tags:        [ "sbt" ]
---

Oracle は [non-LTS JDK を 6ヶ月おき](https://mreinhold.org/blog/forward-faster)、LTS JDK を 3年おきにリリースする計画だ。また、今後は OpenJDK に集約されていくらしい。計画どおりにいけば、JDK 9 は 2018年3月に EOL、JDK 10 は 2018年3月にリリースされ、2018年9月に EOL、そして 2018年9月に JDK8 をリプレースする LTS JDK 11 は 2021年まで続くということになる。

今後立て続けにリリースされる JDK に備えて、Travis CI を使ってアプリを JDK 8, JDK 9, そして JDK 10 Early Access でテストする方法を紹介する。

```yaml
dist: trusty

language: scala

matrix:
  include:
    ## build using JDK 8, test using JDK 8
    - script:
        - sbt universal:packageBin
        - cd citest && ./test.sh

    ## build using JDK 8, test using JDK 9
    - script:
        - sbt universal:packageBin
        - jdk_switcher use oraclejdk9
        - cd citest && ./test.sh

    ## build using JDK 8, test using JDK 10
    - script:
        - sbt universal:packageBin
        - citest/install-jdk10.sh
        - cd citest && ./test.sh

scala:
  - 2.10.7

jdk:
  - oraclejdk8

# Undo _JAVA_OPTIONS environment variable
before_script:
  - _JAVA_OPTIONS=

cache:
  directories:
    - $HOME/.ivy2/cache
    - $HOME/.sbt/boot

before_cache:
  - find $HOME/.ivy2 -name "ivydata-*.properties" -delete
  - find $HOME/.sbt  -name "*.lock"               -delete
```

この例では、sbt と sbt-native-packager を使っているが、どのビルドツールでも動くはずだ。

ビルド内に `citest` ディレクトリを作って、`install-jdk10.sh` と `test.sh` を置いた。
[install-jdk10 スクリプト](https://sormuras.github.io/blog/2017-12-08-install-jdk-on-travis.html) は [Christian Stein (@sormuras)](https://twitter.com/sormuras) さんによって書かれたものを使っている。


`test.sh` はこんな感じだ:

```bash
#!/bin/bash

## https://github.com/travis-ci/travis-ci/issues/8408
export _JAVA_OPTIONS=

## begin Java switching
## swtich to JDK 10 if we've downloaded it
if [ -d ~/jdk-10 ]
then
  JAVA_HOME=~/jdk-10
fi
## include JAVA_HOME into path
PATH=${JAVA_HOME}/bin:$PATH
java -version
## end of Java switching

SBT_OPTS=-Dfile.encoding=UTF-8

mkdir freshly-baked

unzip -qo ../target/universal/sbt.zip -d ./freshly-baked
./freshly-baked/sbt/bin/sbt about run
```

何をテストしているのかによって最後の 2行を変えるだけでいい。

このテクニックによってビルドとテストの工程で別の JDK を使うことができるようになった。短期的には JDK 8 に留まったまま JDK 9 や JDK 10 をテストするのに役立つ。しかし、将来的には multi-release JAR を使って JDK 11 上でビルドして JDK 8 での動作を確認するといったことにも使えるかもしれない。
