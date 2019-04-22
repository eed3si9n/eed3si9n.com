
  [1]: http://eed3si9n.com/all-your-jdks-on-travis-ci-using-jabba

This is a second post on installing your own JDKs on Travis CI. Previously I've written about [jabba][1].

Today, let's look at [SDKMAN!](https://sdkman.io/), an environment manager written by Marco Vermeulen ([@marc0der](https://twitter.com/marc0der)) for JDKs and various tools on JVM, including Groovy, Spark, sbt, etc.

### AdoptOpenJDK 11 and 8

Here's how we can use SDKMAN! on Travis CI to cross build using AdoptOpenJDK 11 and 8:

<code>
sudo: false
dist: trusty
group: stable

language: scala

scala: 2.12.8

matrix:
  include:
  - env:
      - TRAVIS_JDK=11.0.2.hs-adpt
  - env:
      - TRAVIS_JDK=8.0.202.hs-adpt

before_install:
  # adding $HOME/.sdkman to cache would create an empty directory, which interferes with the initial installation
  - "[[ -d /home/travis/.sdkman/ ]] && [[ -d /home/travis/.sdkman/bin/ ]] || rm -rf /home/travis/.sdkman/"
  - curl -sL https://get.sdkman.io | bash
  - echo sdkman_auto_answer=true > /home/travis/.sdkman/etc/config
  - source "/home/travis/.sdkman/bin/sdkman-init.sh"

install:
  - sdk install java $TRAVIS_JDK
  - unset _JAVA_OPTIONS
  - java -Xmx32m -version

script: sbt -Dfile.encoding=UTF8 -J-XX:ReservedCodeCacheSize=256M ++$TRAVIS_SCALA_VERSION! test

before_cache:
  - find $HOME/.ivy2 -name "ivydata-*.properties" -delete
  - find $HOME/.sbt  -name "*.lock"               -delete

cache:
  directories:
    - $HOME/.ivy2/cache
    - $HOME/.sbt/boot
    - $HOME/.sdkman
</code>

How did I get those `11.0.2.hs-adpt` string? Run `sdk list java` locally.

When the job runs you should see something like:

<code>
$ java -Xmx32m -version
openjdk version "11.0.2" 2019-01-15
OpenJDK Runtime Environment AdoptOpenJDK (build 11.0.2+9)
OpenJDK 64-Bit Server VM AdoptOpenJDK (build 11.0.2+9, mixed mode)
</code>

### official sbt distribution

Using SDKMAN! we can use the official sbt distribution, instead of sbt-extras that Travis CI preinstalls.

<code>
sudo: false
dist: trusty
group: stable

language: scala

scala: 2.12.8

matrix:
  include:
  - env:
      - TRAVIS_JDK=11.0.2.hs-adpt
  - env:
      - TRAVIS_JDK=8.0.202.hs-adpt

before_install:
  # adding $HOME/.sdkman to cache would create an empty directory, which interferes with the initial installation
  - "[[ -d /home/travis/.sdkman/ ]] && [[ -d /home/travis/.sdkman/bin/ ]] || rm -rf /home/travis/.sdkman/"
  - curl -sL https://get.sdkman.io | bash
  - echo sdkman_auto_answer=true > /home/travis/.sdkman/etc/config
  - source "/home/travis/.sdkman/bin/sdkman-init.sh"

install:
  - sdk install java $TRAVIS_JDK
  - unset _JAVA_OPTIONS
  - java -Xmx32m -version
  # detect sbt version from project/build.properties, otherwise hardcode as export TRAVIS_SBT=1.2.8
  - export TRAVIS_SBT=$(grep sbt.version= project/build.properties | sed -e 's/sbt.version=//g' ) && echo "sbt $TRAVIS_SBT"
  - sdk install sbt $TRAVIS_SBT
  # override Travis CI's SBT_OPTS
  - unset SBT_OPTS
  - export JAVA_OPTS="-Xms2048M -Xmx2048M -Xss6M -XX:ReservedCodeCacheSize=256M"

script: sbt -Dfile.encoding=UTF8 ++$TRAVIS_SCALA_VERSION! test

before_cache:
  - find $HOME/.ivy2 -name "ivydata-*.properties" -delete
  - find $HOME/.sbt  -name "*.lock"               -delete

cache:
  directories:
    - $HOME/.ivy2/cache
    - $HOME/.sbt/boot
    - $HOME/.sdkman
</code>
