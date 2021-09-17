  [1]: https://github.com/olafurpg/setup-scala

Here's a quick tutorial of how to test your project on JDK 17 using Ólaf's [olafurpg/setup-scala][1]. As the starting point we'll use the following setup, which is documented in [Setting up GitHub Actions with sbt](https://www.scala-sbt.org/1.x/docs/GitHub-Actions-with-sbt.html#Build+matrix):

<code>
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
</code>

Let's say for `jobtype` 3 we'd like to use JDK 8, and for `jobtype` 1 and 2 we'd like to test on JDK 17. sbt-ci-release uses jabba to grab the JDKs, and at the moment the openjdk 17.0 distros are not available on jabba yet. However, java.net does have the binary available, so we can use the custom JDK mode to use it as follows:

<code>
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
            java: "17.0-custom=tgz+https://download.java.net/java/GA/jdk17/0d483333a00540d886896bac774ff48b/35/GPL/openjdk-17_linux-x64_bin.tar.gz"
            jobtype: 1
          - os: ubuntu-latest
            java: "17.0-custom=tgz+https://download.java.net/java/GA/jdk17/0d483333a00540d886896bac774ff48b/35/GPL/openjdk-17_linux-x64_bin.tar.gz"
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
</code>

You should see the following warning if use sbt 1.5.4:

<code>
[info] [launcher] getting org.scala-sbt sbt 1.5.4  (this may take some time)...
[info] [launcher] getting Scala 2.12.14 (for sbt)...
WARNING: A terminally deprecated method in java.lang.System has been called
WARNING: System::setSecurityManager has been called by sbt.TrapExit$ (file:/home/runner/.sbt/boot/scala-2.12.14/org.scala-sbt/sbt/1.5.4/run_2.12-1.5.4.jar)
WARNING: Please consider reporting this to the maintainers of sbt.TrapExit$
WARNING: System::setSecurityManager will be removed in a future release
[info] welcome to sbt 1.5.4 (Oracle Corporation Java 17)
</code>

Generally speaking, my preference would be to use [Eclipse Adoptium fka AdoptOpenJDK](https://adoptium.net/) once it comes out.

