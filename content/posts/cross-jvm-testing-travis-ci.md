---
title:       "cross JVM testing using Travis CI"
type:        story
date:        2018-02-15
draft:       false
promote:     true
sticky:      false
url:         /cross-jvm-testing-travis-ci
aliases:     [ /node/256 ]
tags:        [ "sbt" ]
---

Oracle is moving to ship [non-LTS JDK every 6 months](https://mreinhold.org/blog/forward-faster), and LTS JDK every 3 years. Also it's converging to OpenJDK. In this scheme, JDK 9 will be EOL in March 2018; JDK 10 will come out in March 2018, and EOL in September 2018; and LTS JDK 11 that replaces JDK 8 in September 2018 will stay with us until 2021.

As we will see quick succession of JDKs in the upcoming months, here's a how-to on testing your app on JDK 8, JDK 9, and JDK 10 Early Access using Travis CI.

<code>
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
</code>

In this example, I am using sbt with sbt-native-packager, but that should work with any build tools.

In the build I created `citest` directory, and placed `install-jdk10.sh` and `test.sh`.
The [install-jdk10 script](https://sormuras.github.io/blog/2017-12-08-install-jdk-on-travis.html) is written by [Christian Stein (@sormuras)](https://twitter.com/sormuras).

`test.sh` looks as follows:

<code>
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
</code>

Depending on your what you're testing the last two lines would look different.

This technique allows building and testing to use differnt JDKs. In the short term, it would be useful to test JDK 9 and 10 while staying on JDK 8. But in the future once you start using multi-release JAR, you might want to build using JDK 11, but test the behavior on JDK 8 for example.
