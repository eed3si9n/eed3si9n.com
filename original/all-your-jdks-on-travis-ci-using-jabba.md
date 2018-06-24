  [jabba]: https://github.com/shyiko/jabba

Whether you want to try using OpenJDK 11-ea, GraalVM, Eclipse OpenJ9, or you are stuck needing to build using OpenJDK 6, [jabba][jabba] has got it all. [jabba][jabba] is a cross-platform Java version manager written by Stanley Shyiko ([@shyiko](https://twitter.com/shyiko)).

Here's how we can use jabba on Travis CI to run a build using Azul Zulu OpenJDK 6:

<code>
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
  - curl -sL https://raw.githubusercontent.com/shyiko/jabba/0.10.1/install.sh | bash && . ~/.jabba/jabba.sh

install:
  - $JABBA_HOME/bin/jabba install $TRAVIS_JDK && export JAVA_HOME="$JABBA_HOME/jdk/$TRAVIS_JDK" && export PATH="$JAVA_HOME/bin:$PATH" && java -Xmx32m -version

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
</code>

To specify the `TRAVIS_JDK` variable, you need to pick a JDK from the `"linux"` section of <https://github.com/shyiko/jabba/blob/0.10.1/index.json>.

When the job runs you should see something like:

<code>
Downloading zulu@1.6.107 (https://cdn.azul.com/zulu/bin/zulu6.20.0.1-jdk6.0.107-linux_x64.tar.gz)
64356908/64356908
Extracting /tmp/jabba-d-303130071 to /home/travis/.jabba/jdk/zulu@1.6.107
zulu@1.6 -> /home/travis/.jabba/jdk/zulu@1.6.107
Picked up _JAVA_OPTIONS: -Xmx2048m -Xms512m
openjdk version "1.6.0-107"
OpenJDK Runtime Environment (Zulu 6.20.0.1-linux64) (build 1.6.0-107-b107)
OpenJDK 64-Bit Server VM (Zulu 6.20.0.1-linux64) (build 23.77-b107, mixed mode)
....
</code>

The above is a workaround for [travis-ci/travis-ci#9713](https://github.com/travis-ci/travis-ci/issues/9713), but jabba also is useful for testing future JDKs as well.
