---
title:       "the holy graal of GitHub Actions"
type:        story
date:        2024-02-25
url:         /holy-graal-of-gitHub-actions
---

  [native_yaml]: https://github.com/sbt/sbtn-dist/blob/ec82e4d25c0f942114c7460868b656089934eb7d/.github/workflows/native.yml
  [7427]: https://github.com/sbt/sbt/issues/7427
  [11]: https://github.com/sbt/sbtn-dist/pull/11
  [github-blog-2024-01-30]: https://github.blog/changelog/2024-01-30-github-actions-introducing-the-new-m1-macos-runner-available-to-open-source/

Last week on [sbt/sbt#7427][7427] [@keynmol](https://github.com/keynmol) (Anton Sviridov) told me:

> @eed3si9n I think this can be reopened, given that Github finally released free Apple Silicon workers - I think it's best to modify the Github workflow to build all binaries automatically: [sbt/sbtn-dist#11][11]

I guess somehow I missed the memo for a whole month, but I'm happy that [ARM macOS runners are here][github-blog-2024-01-30]! In this post, let's dig into how we automated GraalVM native image creation using GitHub Actions. If you're in a hurry, see the working example [native.yaml][native_yaml].

<!--more-->
### basic GitHub Actions + sbt

GitHub Actions is convenient for basic PR validations.  For details on these basics, [Setting up GitHub Actions with sbt](https://www.scala-sbt.org/1.x/docs/GitHub-Actions-with-sbt.html). The following should take care of most cares:

```yaml
name: CI
on:
  pull_request:
  push:
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
    - name: Setup JDK
      uses: actions/setup-java@v4
      with:
        distribution: temurin
        java-version: 17
        cache: sbt
    - name: Build and Test
      run: sbt -v +test
```

### What's a GraalVM and native image?

Put simply GraamVM is a mix of tools that is part HotSpot JVM alternative, part a way to produce native code from a Java or Scala app, and a part polyglot platform. One thing about GraalVM is that its not a virutal machine exactly.

**HotSpot VM**
<table>
  <tr>
    <td style="text-align: center;">C1 (Client)</td>
    <td style="text-align: center;">C2 (Server)</td>
  </tr>
  <tr>
    <td colspan="2" style="text-align: center;">Compiler Interface</td>
  </tr>
  <tr>
    <td colspan="2" style="text-align: center;">HotSpot VM</td>
  </tr>
</table>

HotSpot VM ships with two just-in-time compilers named C1 and C2, written in C++. Whena program starts, the VM is able to interpret the bytecode as they run. As the program proceeds, just-in-time (JIT) compilation turns the JVM bytecode into machine code, for the portion that are used more often (the hotspot). C1 is tuned for faster classloading, whereas C2 is tuned for more optimization. These optimization steps had allowed JVM languages to perform comparable to backend services written in C++ etc for the last 20 years. C2 was implemented a long time ago with procedural style Java in mind, and it doesn't work well what Scala compiler produces from functional style code.

**"GraalVM"**
<table>
  <tr>
    <td style="text-align: center;">C1 (Client)</td>
    <td style="text-align: center;">Graal compiler</td>
  </tr>
  <tr>
    <td style="text-align: center;">Compiler Interface</td>
    <td style="text-align: center;">JVMCI</td>
  </tr>
  <tr>
    <td colspan="2" style="text-align: center;">HotSpot VM</td>
  </tr>
</table>

In this view, Graal compiler is a just-in-time compiler, written in Java, that replaces C2 compiler in HotSpot VM. When GraalVM came out in 2019, Oracle published [a case study](https://www.oracle.com/a/ocom/docs/graalvm-twitter-casestudy-constellation.pdf) with Twitter saying they were able to sae 8-11% CPU utilization by switching to GraalVM.
One selling point of Graal compiler is that it looks at the graph to perform more holistic optimization.

**Native Image**
<table>
  <tr>
    <td style="text-align: center;">Polyglot programs</td>
  </tr>
  <tr>
    <td style="text-align: center;">Language Runtimes</td>
  </tr>
  <tr>
    <td style="text-align: center;">Substrate VM</td>
  </tr>
</table>

Native Image builder is a tool to produce native code from an existing Java or Scala application. There's an integration in major built tools that the process is relatively simple. I don't know if there's a description of how Native Imanage builder works, but the idea seems to be basically run Graal compiler at compile-time, or ahead-of-time like a normal compiler and for runtime features like garbage collection provide Substrate VM.

> **Note**: Both C2 and GraalVM perform optimization based on a profile, the usage of the program at runtime, or hotspots, and if you just ran Native Image build, the optimizer won't have any profile info. Oracle knows this, and sells this feature as [Profile-Guided Optimization, or PGO](https://www.graalvm.org/latest/reference-manual/native-image/guides/optimize-native-executable-with-pgo/).

#### Why use GraalVM native image?

The interpreter/C1/C2 setup of the HotSpot VM affects **both the latency and throughput** of a JVM application. In general, a program would like a second or two just to start. It gets longer as the number and size of the dependency JAR needed for the startup increases. Then C2 compiler would collect profiles and compiling scala-library etc into native code at the startup. This could last for 30s or more, as the program loads necessary classes. Until warm C2-optimized code kicks in, your program runs slower.

> Aside: This effect is so pronounced that a warm Scala compiler is reported to run 2x faster than a cold one. There's an issue that I opened as [sbt/sbt#2984](https://github.com/sbt/sbt/issues/2984) suggesting that we should consider preemptively compiling a "hello world" Scala before compiling anything else.

This is especially not great for CLI programs and *serverless* handlers that are called frequently for a short burst of time. Native image provides a solution for this since we can utilize the existing tools and libraries like Cats Effect to make small programs, and tune it into native code.

#### challenges with Native Image

Native Image building is not without issues. Setting aside the fact that it would be difficult to build certain kind of code that use dynamic loading and reflection, there are inherent challenges with building native code in general.

When Sun created Java, they said "Write once, run everywhere," and they've kept their end of the bargain. Unless I intentionally drop into JNI/JNA, the libraries I ship as JARs would work on macOS, Windows, or Linux regardless of what the user may have installed on their machines. Not so much with the native code. The native image you produce would be specific to operating system, CPU architecture, and the GNU C library (glibc) version. This is why languages like C++ and Rust that target native code use package manager to compile on user's machine. If you want to distribute native images, you have to create a development environment for each target platform.

### GitHub Actions

GraalVM is available for macOS and Linux on x86-64 and ARM/AArch64, and for Windows on x86_64. As of [January 30][github-blog-2024-01-30], we now have the ability to produce native image on all supported OSes and architectures:

| OS      | x86-64      | ARM/AArch64 |
|---------|------------:|------------:|
| macOS   | macOS-12    | macOS-14    |
| Linux   | ubuntu-20.04| uraimo/run-on-arch-action@v2|
| Windows | windows-2019| _ |

> **Note**: It's also been possible at [Cirrus CI](https://cirrus-ci.org/).

Here's an example [native.yaml][native_yaml].

#### building a universal macOS binary

Since macOS has gone through mutiple CPU artichecture through its lifetime, it has a notion of universal binary to bundle executables for multiple CPU architecture in a single file.

To build one on GitHub Actions, we can follow the following strategy:

1. Build x86-64 binary on macOS-12, and upload it to upload-artifact space.
2. Build ARM binary on macOS-14, and upload it to upload-artifact space.
3. Use download-artifact to download both files on another macOS-12 job, and call `lipo` to create a universal binary.

```yaml
  native-image-macos:
    needs: native-image
    runs-on: ${{ matrix.os }}
    strategy:
      fail-fast: false
      matrix:
        include:
          - os: macOS-12
            uploaded_filename: sbtn-x86_64-apple-darwin
            local_path: client/target/bin/sbtn
          - os: macOS-14
            uploaded_filename: sbtn-aarch64-apple-darwin
            local_path: client/target/bin/sbtn
    env:
      JAVA_OPTS: -Xms2048M -Xmx2048M -Xss6M -XX:ReservedCodeCacheSize=256M
    steps:
      - name: Checkout
        uses: actions/checkout@v4
      - name: Setup JDK
        uses: actions/setup-java@v4
        with:
          distribution: temurin
          java-version: 17
      - run: git fetch --tags || true
      - name: Build
        shell: bash
        run: |
          mkdir -p "$HOME/bin/"
          curl -sL https://raw.githubusercontent.com/sbt/sbt/v1.9.9/sbt > "$HOME/bin/sbt"
          export PATH="$PATH:$HOME/bin"
          chmod +x "$HOME/bin/sbt"
          sbt clean nativeImage
      - uses: actions/upload-artifact@v4
        with:
          path: ${{ matrix.local_path }}
          name: ${{ matrix.uploaded_filename }}

  native-image-universal-macos:
    needs: native-image-macos
    runs-on: ${{ matrix.os }}
    strategy:
      fail-fast: false
      matrix:
        include:
          - os: macOS-12
            uploaded_filename: sbtn-universal-apple-darwin
            local_path: client/target/bin/sbtn
    steps:
      - name: Download binaries
        uses: actions/download-artifact@v4
      - name: Display structure of downloaded files
        run: ls -R
      - name: Build universal binary
        shell: bash
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        run: |
          mkdir -p client/target/bin/
          lipo -create -o "${{ matrix.local_path }}" "sbtn-x86_64-apple-darwin/sbtn" "sbtn-aarch64-apple-darwin/sbtn"
      - uses: actions/upload-artifact@v4
        with:
          path: ${{ matrix.local_path }}
          name: ${{ matrix.uploaded_filename }}
```

The above assumes that your build would create `client/target/bin/sbtn` in each job.

#### building an ARM Linux binary

As of this writing, GitHub Actions [does not support ARM Linux](https://github.com/actions/runner-images/blob/df722a3cf81bbe65c3b964c9b4830c85451542fc/README.md#available-images).
However, we can still build an ARM Linux binary using [uraimo/run-on-arch-action](https://github.com/uraimo/run-on-arch-action), which runs [QEMU](https://www.qemu.org/), a machine emulator that can emulate other CPUs.

```yaml
  native-image-aarch64-pc-linux-linux:
    runs-on: ${{ matrix.os }}
    strategy:
      fail-fast: false
      matrix:
        include:
          - os: ubuntu-20.04
            uploaded_filename: sbtn-aarch64-pc-linux
            local_path: client/target/bin/sbtn
    env:
      JAVA_OPTS: -Xms2048M -Xmx2048M -Xss6M -XX:ReservedCodeCacheSize=256M
    steps:
      - name: Checkout
        uses: actions/checkout@v4
      - name: Build Linux aarch64
        uses: uraimo/run-on-arch-action@v2
        with:
          arch: aarch64
          distro: ubuntu20.04
          githubToken: ${{ github.token }}
          shell: /bin/bash
          # build-essential and libz-dev are required to build native images.
          install: |
            apt-get update -q -y
            apt-get install -q -y curl openjdk-8-jdk build-essential libz-dev
            mkdir -p "$HOME/bin/"
            curl -sL https://raw.githubusercontent.com/sbt/sbt/v1.9.9/sbt > "$HOME/bin/sbt"
            chmod +x "$HOME/bin/sbt"
          run: |
            export PATH="$PATH:$HOME/bin"
            sbt clean nativeImage
      - uses: actions/upload-artifact@v4
        with:
          path: ${{ matrix.local_path }}
          name: ${{ matrix.uploaded_filename }}
```

The fact that this is possible at all is interesting, but it does come with a cost of time. If the normal Linux build takes 3 minutes, this would take 30 minutes.

Note that the above example uses Ubuntu 20.04 (Focal), which will create a dependency to **glibc 2.31**. This means that it will **not** work on Ubuntu 18.04 (Bionic). Given that glibc maintains [99% backward compatibility](https://abi-laboratory.pro/?view=timeline&l=glibc), it should work on Ubuntu 22.04 (Jammy), and hopefully on Ubuntu 24.04 (Noble) as well when it comes out later this year.

#### attaching to a GitHub Release

To make the files publicly available, you can use something like the following to upload the files to a GitHub Release:

```yaml
      - name: Upload release
        if: github.event_name == 'release'
        uses: actions/upload-release-asset@v1
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        with:
          upload_url: ${{ github.event.release.upload_url }}
          asset_path: ${{ matrix.local_path }}
          asset_name: ${{ matrix.uploaded_filename }}
          asset_content_type: application/octet-stream
```

### summary

- Graal is an optimizing compiler that transforms JVM bytecode into machine code, typically called during the JVM execution time as one of two just-in-time compilers.
- GraalVM Native Image builder can produce native code that can improve the startup time and performance of short-lived programs. However, producing native image for five supported platforms require setting up a machine for ARM and x86_64 environemnt.
- Thanks to the recent macOS-14 ARM image, we can now produce all five variants of native image, including universal macOS binary.
