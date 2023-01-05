---
title:       "sbt 1.8.2"
type:        story
date:        2023-01-05
url:         /sbt-1.8.2
tags:        [ "sbt" ]
---

Hi everyone. On behalf of the sbt project, I'm happy to announce sbt 1.8.2 patch release fixing a few regressions found in sbt 1.8.1. Full release note is here - https://github.com/sbt/sbt/releases/tag/v1.8.2

See [1.8.0 release note](/sbt-1.8.0) for the details on 1.8.x features.

### Highlights

- Fixes M1/M2/Aarch64 Mac support by [#7120][7120] by [@eed3si9n][@eed3si9n]
- Fixes glibc 2.31/Debian 11/Ubuntu 20.04 compatibility [#7118][7118] by [@eed3si9n][@eed3si9n]

<!--more-->

### M1/M2/Aarch64 Mac support

sbt 1.8.1 stopped working on Aarch64 Macs. Here are some details.

There are a few areas in sbt that uses native C code, and one such area is inter-process communication (IPC)
for the sbt server, specifically Unix domain socket on POSIX system and named pipe on Windows.
This allows sbt clients to communicate in a platform-independent manner without using an IP socket.
[sbt/ipcsocket][ipcsocket] is a Java library that provides `java.net.Socket` and `java.net.ServerSocket`
implementations for IPC protocols.

In sbt 1.8.1, we started providing support for Aarch64 ("arm64") Linux by cross compiling the
ipcsocket C code using gcc-aarch64-linux-gnu, and allowed the CPU architecture to switch between the implementations. Unfortunately, this broke the Aarch64 Macs because we actually use "universal binary" for Macs,
which contains the support for both x86_64 and Aarch64 in a single binary.
sbt 1.8.2 fixes this by hardcoding the architecture to x86_64 for macOS.

### glibc 2.31/Debian 11/Ubuntu 20.04 support

sbt 1.8.1 stopped working on Debian 11. Here are some details.

To use the sbt server, we provide a native thin client called `sbtn`.
The code [NetworkClient.scala](https://github.com/sbt/sbt/blob/v1.8.2/main-command/src/main/scala/sbt/internal/client/NetworkClient.scala) is written in normal Scala code using the ipcsocket library,
and it's converted into native image using GraalVM native-image on Github Actions.

As it turns out that GraalVM native-image picks up the glibc installed on the system,
and by using `"ubuntu-latest"` on Github Actions, we've inadvertently updated the glibc from 2.31 to 2.35.
In general, we do not make any compatibility guarantees regarding sbtn and glibc versions,
but we were able to fix this in sbt 1.8.2 by downgrading Github Actions to `"ubuntu-20.04"`.

### How to upgrade

Download **the official sbt runner + launcher** from `cs setup`, SDKMAN, or download from <https://github.com/sbt/sbt/releases/>.

In addition, the sbt version used for your build is upgraded by putting the following in `project/build.properties`:

```bash
sbt.version=1.8.2
```

This mechanism allows that sbt 1.8.2 is used only for the builds that you want.

### Participation

Thanks to everyone who's helped improve sbt and Zinc 1 by using them, reporting bugs, improving our documentation, porting builds, porting plugins, and submitting and reviewing pull requests.

For anyone interested in helping sbt, there are many avenues for you to help, depending on your interest. If you're interested, [Contributing](https://github.com/sbt/sbt/blob/develop/CONTRIBUTING.md), ["help wanted"](https://github.com/sbt/sbt/issues?q=is%3Aissue+is%3Aopen+label%3A%22help+wanted%22), ["good first issue"](https://github.com/sbt/sbt/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22) are good starting points. If you have ideas let us know on [sbt Discussions](https://github.com/sbt/sbt/discussions).

### Support Scala Center

Individuals can donate and directly [support Scala Center](/support-scala-center-2022).

### 🏳️‍🌈 Support Ukraine 🇺🇦

Forbidden Colours has started a fundraising campaign to support organisations in Poland, Hungary and Romania that are welcoming LGBTIQ+ refugees.

<https://www.forbidden-colours.com/2022/02/26/support-ukrainian-lgbtiq-refugees/>

  [ipcsocket]: https://github.com/sbt/ipcsocket
  [7120]: https://github.com/sbt/sbt/pull/7120
  [7118]: https://github.com/sbt/sbt/issues/7118
  [@eed3si9n]: https://github.com/eed3si9n
  [@Nirvikalpa108]: https://github.com/Nirvikalpa108
  [@adpi2]: https://github.com/adpi2
  [@er1c]: https://github.com/er1c
  [@eatkins]: https://github.com/eatkins
  [@dwijnand]: https://github.com/dwijnand
  [@mkurz]: https://github.com/mkurz
  [@dos65]: https://github.com/dos65
