---
title:       "GitHub Actions からの JDK 17"
type:        story
date:        2021-09-17
draft:       false
promote:     true
sticky:      false
url:         /ja/jdk17-on-github-actions
aliases:     [ /node/407 ]
tags:        [ "scala" ]
---

  [1]: https://github.com/olafurpg/setup-scala

Ólaf さんの [olafurpg/setup-scala][1] を使ってプロジェクトを JDK 17 でテストする簡単な解説をしてみる。[Setting up GitHub Actions with sbt](https://www.scala-sbt.org/1.x/docs/GitHub-Actions-with-sbt.html#Build+matrix) でドキュメント化されている以下の設定をスタート地点とする。

```yaml
name: CI
on:
  pull_request:
  push:
jobs:
  test:
    strategy:
      fail-fast: false
      matrix:
        include:
          - os: ubuntu-latest
            java: 11
            jobtype: 1
          - os: ubuntu-latest
            java: 11
            jobtype: 2
          - os: ubuntu-latest
            java: 11
            jobtype: 3
    runs-on: ${{ matrix.os }}
    steps:
    - name: Checkout
      uses: actions/checkout@v1
    - name: Setup
      uses: olafurpg/setup-scala@v13
      with:
        java-version: "adopt@1.${{ matrix.java }}"
    - name: Build and test
      run: |
        case ${{ matrix.jobtype }} in
          1)
            sbt -v "mimaReportBinaryIssues; scalafmtCheckAll; +test;"
            ;;
          2)
            sbt -v "scripted actions/*"
            ;;
          3)
            sbt -v "dependency-management/*"
            ;;
          *)
            echo unknown jobtype
            exit 1
        esac
      shell: bash
```

例えば、`jobtype` が 3 の場合は JDK 8 を使いたいとして、`jobtype` が 1 と 2 の場合は JDK 17 でテストしたいとする。sbt-ci-release は JDK を持ってくるのに jabba を使っているが、これを書いている時点では各社の openjdk 17.0 ディストロが jabba にまだ上がっていない。しかし、[Eclipse Adoptium 旧名 AdoptOpenJDK](https://adoptium.net/) からバイナリが出たのでカスタム JDK モードを利用して強引に使うことが可能だ:

```yaml
name: CI
on:
  pull_request:
  push:
jobs:
  test:
    strategy:
      fail-fast: false
      matrix:
        include:
          - os: ubuntu-latest
            java: "17.0-custom=tgz+https://github.com/adoptium/temurin17-binaries/releases/download/jdk-17%2B35/OpenJDK17-jdk_x64_linux_hotspot_17_35.tar.gz"
            jobtype: 1
          - os: ubuntu-latest
            java: "17.0-custom=tgz+https://github.com/adoptium/temurin17-binaries/releases/download/jdk-17%2B35/OpenJDK17-jdk_x64_linux_hotspot_17_35.tar.gz"
            jobtype: 2
          - os: ubuntu-latest
            java: "adopt@1.11"
            jobtype: 3
    runs-on: ${{ matrix.os }}
    steps:
    - name: Checkout
      uses: actions/checkout@v1
    - name: Setup
      uses: olafurpg/setup-scala@v13
      with:
        java-version: "{{ matrix.java }}"
    - name: Build and test
      run: |
        case ${{ matrix.jobtype }} in
          1)
            sbt -v "mimaReportBinaryIssues; scalafmtCheckAll; +test;"
            ;;
          2)
            sbt -v "scripted actions/*"
            ;;
          3)
            sbt -v "dependency-management/*"
            ;;
          *)
            echo unknown jobtype
            exit 1
        esac
      shell: bash
```

うまくいけば sbt 1.5.4 だと以下のような警告が表示される:

```bash
[info] [launcher] getting org.scala-sbt sbt 1.5.4  (this may take some time)...
[info] [launcher] getting Scala 2.12.14 (for sbt)...
WARNING: A terminally deprecated method in java.lang.System has been called
WARNING: System::setSecurityManager has been called by sbt.TrapExit$ (file:/home/runner/.sbt/boot/scala-2.12.14/org.scala-sbt/sbt/1.5.4/run_2.12-1.5.4.jar)
WARNING: Please consider reporting this to the maintainers of sbt.TrapExit$
WARNING: System::setSecurityManager will be removed in a future release
[info] welcome to sbt 1.5.4 (Eclipse Adoptium Java 17)
```

**Update**:

ややこしい事にビルド済みバイナリは Eclipse Adoptium のサブプロジェクトにあたる Eclipse Temurin によって作られているらしい。しかし、上記のバナーの通り `java.vendor` は `"Eclipse Adoptium"` を返している。ということは tar ball だけが Eclipse Temurin なのだろうか?
