---
title: "sbt 1.13.1 and 2.0.12"
type: story
date: 2026-10-28
url: /sbt-1.13.1-and-2.0.12
tags: ["sbt"]
---

The headline features of sbt 1.13.1 are

- Vulnerability fix for `IO.unzip`
- Zinc 1.13.0, with over-compilation fixes backported from Zinc 2.x
- sbt server and thin client robustness fixes

<!--more-->

Hi everyone. On behalf of the sbt project, I am happy to announce sbt 1.13.1 and sbt 2.0.12. See also [sbt 2.0 change summary](https://www.scala-sbt.org/2.x/docs/en/changes/sbt-2.0-change-summary.html) for the details on sbt 2.0.

### How to upgrade

The sbt version used for your build is upgraded by putting the following in `project/build.properties`:

```bash
sbt.version=1.13.1
```

This mechanism allows that sbt 1.13.1 (or 2.0.12) is used only for the builds that you want.

Download **the official sbt runner** from SDKMAN, or download from <https://github.com/sbt/sbt/releases/tag/v2.0.12> to upgrade the `sbt` shell script, sbtn, and the launcher.

### Vulnerability fix for `IO.unzip`

sbt team received a security report [GHSA-p8jf-532w-4p65](https://github.com/sbt/sbt/security/advisories/GHSA-p8jf-532w-4p65) from [Stas Shevchenko](https://github.com/stasimus) that despite previous attempt to fix it, `IO.unzip` and its variants contain a zip slip vulerability. sbt 1.13.1 and 2.0.12 fix this bug.

### Zinc 1.13.0 over-compilation fixes

sbt 1.13.1 updates Zinc to 1.13.0, which backports a series of incremental compilation fixes to the 1.x series:

- fix: Fixes over-compilation of inheritance by [@lrytz][@lrytz] in https://github.com/sbt/zinc/pull/1799
- Over-compilation fixes by [@retronym][@retronym], [@lrytz][@lrytz], and [@eed3si9n][@eed3si9n] in https://github.com/sbt/zinc/pull/1838
- Tell objects and classes apart in inheritance dependency tracking by [@lrytz][@lrytz] and [@retronym][@retronym] in https://github.com/sbt/zinc/pull/1839
- Record macro type-argument dependencies for every caller and argument-list shape by [@retronym][@retronym] in https://github.com/sbt/zinc/pull/1850
- Reuse one hasher across name groups in `NameHashing` by [@retronym][@retronym] in https://github.com/sbt/zinc/pull/1853

### Other updates and bug fixes

- fix: End the client connection when the channel's write thread stops by [@retronym][@retronym] in https://github.com/sbt/sbt/pull/9991
- fix: Fixes `run` task by [@xuwei-k][@xuwei-k] in https://github.com/sbt/sbt/pull/9963
- Updates sbtn to 2.1.0-e5346417 by [@eed3si9n][@eed3si9n] in https://github.com/sbt/sbt/pull/9996
- fix: Report compile failures with `usePipelining` instead of cancelling by [@mkurz][@mkurz] in https://github.com/sbt/sbt/pull/9969
- fix: Handle `CancellationException` gracefully with `usePipelining` by [@mkurz][@mkurz] in https://github.com/sbt/sbt/pull/8718
- fix: Pass Java sources to scalac when pipelining by [@stasimus][@stasimus] in https://github.com/sbt/zinc/pull/1790
- Adds `Terminal.withRawInput` for reading single keys by [@mkurz][@mkurz] in https://github.com/sbt/sbt/pull/9948
- perf: Avoid per-call allocations in `getModifiedTimeOrZero` by [@retronym][@retronym] in https://github.com/sbt/io/pull/571
- fix: Fixes watch termination callbacks losing their source by [@mkurz][@mkurz] in https://github.com/sbt/sbt/pull/9902
- fix: Fixes task progress and logger retention across evaluations by [@mkurz][@mkurz] in https://github.com/sbt/sbt/pull/9915
- fix: Release the task progress of aborted evaluations by [@mkurz][@mkurz] in https://github.com/sbt/sbt/pull/9935
- fix: Fixes file inputs and reloads failing after a failed load hook by [@mkurz][@mkurz] in https://github.com/sbt/sbt/pull/9926
- fix: Make logging robust against closed sbtn by [@mkurz][@mkurz] in https://github.com/sbt/sbt/pull/9911
- fix: Don't miss a sentinel that is being submitted when cancelling by [@mkurz][@mkurz] in https://github.com/sbt/sbt/pull/9973
- fix: Fail when `FileTreeView` can't list a directory by [@eugkhp][@eugkhp] in https://github.com/sbt/io/pull/573

### Participation

sbt 1.13.1 and 2.0.12 are brought to you by 8 contributors. Lukas Rytz, Eugene Yokota (eed3si9n), Jason Zaugg (retronym), Matthias Kurz, Kenji Yoshida (xuwei-k), Stas Shevchenko, Eugene (eugkhp), and Jozef Koval.

Thanks to everyone who's helped improve sbt and Zinc by using them, reporting bugs, improving our documentation, porting builds, porting plugins, and submitting and reviewing pull requests.

For anyone interested in helping sbt, there are many avenues for you to help, depending on your interest. If you're interested, [Contributing](https://github.com/sbt/sbt/blob/develop/CONTRIBUTING.md), ["help wanted"](https://github.com/sbt/sbt/issues?q=is%3Aissue+is%3Aopen+label%3A%22help+wanted%22), ["good first issue"](https://github.com/sbt/sbt/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22), and [Discussions](https://github.com/sbt/sbt/discussions/) are good starting points.

---

### Donate to Scala Center

Scala Center is a non-profit center at EPFL to support education and open source.

- [The Scala Center Fundraising Campaign](https://scala-lang.org/blog/2023/09/11/scala-center-fundraising.html)

  [@eed3si9n]: https://github.com/eed3si9n
  [@mkurz]: https://github.com/mkurz
  [@retronym]: https://github.com/retronym
  [@lrytz]: https://github.com/lrytz
  [@xuwei-k]: https://github.com/xuwei-k
  [@stasimus]: https://github.com/stasimus
  [@eugkhp]: https://github.com/eugkhp
