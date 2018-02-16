  [1]: http://eed3si9n.com/cross-jvm-testing-travis-ci
  [2317]: https://github.com/travis-ci/travis-ci/issues/2317
  [3]: https://gist.github.com/larsrh/941b72b9b72abe0c1a49

Yesterday I wrote about [cross JVM testing using Travis CI][1].

### testing Scala apps on macOS using Travis CI

Here's how we can test Scala apps on macOS using Travis CI. This is adapted from Lars and Muuki's method: [Testing Scala programs with Travis CI on OS X][3]

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

Normally you'd write `jdk: oraclejdk8` at the top level, but since the macOS image does not have the `jdk_switcher` script [travis/travis#2317][2317], we need to add to all entries in the matrix except for the `osx` one.

What motivated me to work this out is running into a `sed` difference between macOS and Linux. macOS uses an old BSD version of `sed` that does not support regular expressions like `?`.

### detecting java version

To workaround this, I wrote a bash function that returns the JDK version.

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

This returns single integer `8` for Java version 1.8.0_nn, and `9` for Java 9. Recent versions of Java contains weird string in its version like `"9-Debian"` and `"10" 2018-03-20`, and this tries to handle them as much as possible.
