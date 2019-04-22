
  [1]: http://eed3si9n.com/ja/all-your-jdks-on-travis-ci-using-jabba

これは Travis CI に自分で JDK をインストールする解説の第2弾だ。以前は、[jabba][1] を紹介した。

今日は [SDKMAN!](https://sdkman.io/), という、Marco Vermeulen ([@marc0der](https://twitter.com/marc0der)) さんが作った元気な名前のツールを見ていく。これは、JDK の他にも Groovy、Spark、sbt など JVM 上の様々なツールを対象とする環境マネージャーだ。

### AdoptOpenJDK 11 と 8

以下は SDKMAN! を使って Travis CI 上で AdoptOpenJDK 8 と 11 を用いてクロスビルドする方法だ:

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

`11.0.2.hs-adpt` といった文字列は、ローカル環境で `sdk list java` を実行すると出てくる。

ジョブが走ると、以下のように表示されるはずだ:

<code>
$ java -Xmx32m -version
openjdk version "11.0.2" 2019-01-15
OpenJDK Runtime Environment AdoptOpenJDK (build 11.0.2+9)
OpenJDK 64-Bit Server VM AdoptOpenJDK (build 11.0.2+9, mixed mode)
</code>

### sbt 公式ディストリビューション

SDKMAN! を使うことで、Travis CI がプレインストールする sbt-extras じゃなくて sbt 公式ディストリビューションを使うことも可能だ。

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
