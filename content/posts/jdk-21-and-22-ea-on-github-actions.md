---
title:       "JDK 21 and 22-ea on GitHub Actions"
type:        story
date:        2023-10-27
url:         /jdk-21-and-22-ea-on-github-actions
tags:        [ "scala" ]
---

JDK 21 just came out, and given its LTS status projects are encouraged to test their code on JDK 21. A few projects are already starting to test on JDK 22-ea as well. Here's a quick tutorial of how to test your project on GitHub Actions with JDK 21 or JDK 22-ea using `actions/setup-java`.

### JDK 21

For cross building on JDK 21, follow [Setting up GitHub Actions with sbt](https://www.scala-sbt.org/1.x/docs/GitHub-Actions-with-sbt.html) on the official docs.

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
            java: 8
          - os: ubuntu-latest
            java: 21
    runs-on: ${{ matrix.os }}
    steps:
    - name: Checkout
      uses: actions/checkout@v4
    - name: Setup JDK
      uses: actions/setup-java@v3
      with:
        distribution: temurin
        java-version: ${{ matrix.java }}
        cache: sbt
    - name: Build and test
      shell: bash
      run: sbt -v +test
```

This uses Temurin builds of OpenJDK by Eclipse Adoptium. Consult Scala's [JDK Compatibility](https://docs.scala-lang.org/overviews/jdk-compatibility/overview.html) to choose the compatible Scala and build tool versions. Specifically for JDK 21, you'd need to Scala 3.3.1, 2.13.11, 2.12.18 etc.

### JDK 22-ea

Here's an example setup that cross builds using JDK 8 and 22-ea:

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
            java: 8
          - os: ubuntu-latest
            java: 22-ea
    runs-on: ${{ matrix.os }}
    steps:
    - name: Checkout
      uses: actions/checkout@v4
    - name: Setup JDK
      uses: actions/setup-java@v3
      with:
        distribution: temurin
        java-version: ${{ matrix.java }}
        cache: sbt
    - name: Build and test
      shell: bash
      run: sbt -v +test
```

This uses JDK 22 Early Access build from Eclipse Temurin. In the log you should see something like this:

```bash
sbt -v clean scripted
[sbt_options] declare -a sbt_options=()
[process_args] java_version = '22'
[copyRt] java9_rt = '/home/runner/.sbt/1.0/java9-rt-ext-eclipse_adoptium_22_beta/rt.jar'
copying runtime jar...
# Executing command line:
java
-Dfile.encoding=UTF-8
-Dsbt.script=/usr/bin/sbt
-Dscala.ext.dirs=/home/runner/.sbt/1.0/java9-rt-ext-eclipse_adoptium_22_beta
-jar
/usr/share/sbt/bin/sbt-launch.jar
+test

Oct 27, 2023 3:06:54 PM org.jline.utils.Log logr
WARNING: Unable to create a system terminal, creating a dumb terminal (enable debug logging for more information)
[info] welcome to sbt 1.9.7 (Eclipse Adoptium Java 22-beta)
```
