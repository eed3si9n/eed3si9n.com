---
title:       "all your JDKs on Travis CI using SDKMAN!"
type:        story
date:        2019-03-26
changed:     2020-09-24
draft:       false
promote:     true
sticky:      false
url:         /all-your-jdks-on-travis-ci-using-sdkman
aliases:     [ /node/294 ]
tags:        [ "scala" ]
---

  [1]: http://eed3si9n.com/all-your-jdks-on-travis-ci-using-jabba

This is a second post on installing your own JDKs on Travis CI. Previously I've written about [jabba][1].

Today, let's look at [SDKMAN!](https://sdkman.io/), an environment manager written by Marco Vermeulen ([@marc0der](https://twitter.com/marc0der)) for JDKs and various tools on JVM, including Groovy, Spark, sbt, etc.

### AdoptOpenJDK 11 and 8

- **Update 2020-09-23**: Updated the regex of version number.
- **Update 2019-11-06**: Added `sdkman_auto_selfupdate` to workaround the update prompt blocking the CI. Also it adds `|| true` on the `sdk install` line.
- **Update 2019-07-08**: Updated the script to detect patch version. See GitHub for the [older version](https://github.com/eed3si9n/eed3si9n.com/blob/4aeeadaf8b32c4cd8d21afd4d5bdcec7538b0aff/original/all-your-jdks-on-travis-ci-using-sdkman.md).

Here's how we can use SDKMAN! on Travis CI to cross build using AdoptOpenJDK 11 and 8:

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
  - echo sdkman_auto_answer=true > $HOME/.sdkman/etc/config
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

When the job runs you should see something like:

```bash
$ java -Xmx32m -version
openjdk version "11.0.3" 2019-04-16
OpenJDK Runtime Environment AdoptOpenJDK (build 11.0.3+7)
OpenJDK 64-Bit Server VM AdoptOpenJDK (build 11.0.3+7, mixed mode)
install.4
$ javac -version
javac 11.0.3
```

### official sbt distribution

Using SDKMAN! we can use the official sbt distribution, instead of sbt-extras that Travis CI preinstalls.

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
