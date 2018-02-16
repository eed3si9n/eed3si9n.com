  [1]: http://eed3si9n.com/ja/cross-jvm-testing-travis-ci
  [2317]: https://github.com/travis-ci/travis-ci/issues/2317
  [3]: https://gist.github.com/larsrh/941b72b9b72abe0c1a49

昨日 [Travis CI を用いてクロス JVM テスト][1] する方法を書いた。

### Travis CI を用いた macOS 上での Scala アプリのテスト

Travis CI を用いて macOS 上で Scala アプリのテストを行うことも可能だ。これは Lars さんと Muuki さんの方法 [Testing Scala programs with Travis CI on OS X][3] をアレンジしたものだ。

<code>
dist: trusty

language: scala

matrix:
  include:
    ## build using JDK 8, test using JDK 8
    - script:
        - sbt universal:packageBin
        - cd citest && ./test.sh
      jdk: oraclejdk8

    ## build using JDK 8, test using JDK 8, on macOS
    - script:
        - sbt universal:packageBin
        - cd citest && ./test.sh
      ## https://github.com/travis-ci/travis-ci/issues/2316
      language: java
      os: osx
      osx_image: xcode9.2

    ## build using JDK 8, test using JDK 9
    - script:
        - sbt universal:packageBin
        - jdk_switcher use oraclejdk9
        - cd citest && ./test.sh
      jdk: oraclejdk8

    ## build using JDK 8, test using JDK 10
    - script:
        - sbt universal:packageBin
        - citest/install-jdk10.sh
        - cd citest && ./test.sh
      jdk: oraclejdk8

scala:
  - 2.10.7

before_install:
  # https://github.com/travis-ci/travis-ci/issues/8408
  - unset _JAVA_OPTIONS
  - if [[ "$TRAVIS_OS_NAME" = "osx" ]]; then
      brew update;
      brew install sbt;
    fi

cache:
  directories:
    - $HOME/.ivy2/cache
    - $HOME/.sbt/boot

before_cache:
  - find $HOME/.ivy2 -name "ivydata-*.properties" -delete
  - find $HOME/.sbt  -name "*.lock"               -delete
</code>

普通はトップレベルで `jdk: oraclejdk8` と書くが、macOS のイメージに `jdk_switcher` スクリプトが入っていないとう問題 [travis/travis#2317][2317]　があるため、matrix 内の `osx` 以外のエントリーに `jdk` を書く必要がある。

最近 macOS と Linux での `sed` の違いに遭遇したため、以上を調べてみようと思った。macOS は古い BSD 版の `sed` を使っていて `?` といった正規表現を使うことができない。

### java version の検知

これを回避するために、JDK バージョンを返す bash 関数を書いた。

<code>
#!/bin/bash

# returns the JDK version.
# 8 for 1.8.0_nn, 9 for 9-ea etc, and "no_java" for undetected
jdk_version() {
  local result
  local java_cmd
  if [[ -n $(type -p java) ]]
  then
    java_cmd=java
  elif [[ (-n "$JAVA_HOME") && (-x "$JAVA_HOME/bin/java") ]]
  then
    java_cmd="$JAVA_HOME/bin/java"
  fi
  local IFS=$'\n'
  # remove \r for Cygwin
  local lines=$("$java_cmd" -Xms32M -Xmx32M -version 2>&1 | tr '\r' '\n')
  if [[ -z $java_cmd ]]
  then
    result=no_java
  else
    for line in $lines; do
      if [[ (-z $result) && ($line = *"version \""*) ]]
      then
        local ver=$(echo $line | sed -e 's/.*version "\(.*\)"\(.*\)/\1/; 1q')
        # on macOS, sed doesn't support '?'
        if [[ $ver = "1."* ]]
        then
          result=$(echo $ver | sed -e 's/1\.\([0-9]*\)\(.*\)/\1/; 1q')
        else
          result=$(echo $ver | sed -e 's/\([0-9]*\)\(.*\)/\1/; 1q')
        fi
      fi
    done
  fi
  echo "$result"
}

v="$(jdk_version)"
echo $v
</code>

これは Java version 1.8.0_nn に対して `8` という単一の整数を返し、Java 9 の場合は `9` を返す。最近の Java のバージョンは `"9-Debian"` とか `"10" 2018-03-20` といった具合に変な文字列が付いてくるので、可能な限りそれらも処理できるようにした。
