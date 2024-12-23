---
title:       "sbt 1.10.7"
type:        story
date:        2024-12-22
url:         /sbt-1.10.7
tags:        [ "sbt" ]
---

  [@eed3si9n]: https://github.com/eed3si9n
  [@adpi2]: https://github.com/adpi2
  [@xuwei-k]: https://github.com/xuwei-k
  [@Friendseeker]: https://github.com/Friendseeker
  [@dwijnand]: https://github.com/dwijnand
  [@retronym]: https://github.com/retronym

Hi everyone. On behalf of the sbt project, I'm happy to announce that sbt 1.10.7 patch release is available. Full release note is here - https://github.com/sbt/sbt/releases/tag/v1.10.7

See [1.10.0 release note](/sbt-1.10.0) for the details on 1.10.x features.

### Highlights

- Build directory detection (`--allow-empty`). See below.
- `csrMavenDependencyOverride` setting. See below.
- Glob expressions in scripted. See below.

<!--more-->

### How to upgrade

The sbt version used for your build must be upgraded by putting the following in `project/build.properties`:

```bash
sbt.version=1.10.7
```

This mechanism allows that sbt 1.10.7 is used only for the builds that you want.

Download **the official sbt runner** from SDKMAN, or download from <https://github.com/sbt/sbt/releases/tag/v1.10.7> to upgrade the `sbt` shell script and the launcher.

### Build directory detection

Starting 1.10.7, the `sbt` runner script enables build directory detection by default. This means that the `sbt` will exit with error when launched in a directory without `build.sbt` or `project/`, with exeptions of `sbt new`, `sbt --script-version` etc.

To override this behavior temporarily, you can use `--allow-empty` flag. To permanently opt out of the build directory detection, create `$XDG_CONFIG_HOME/sbt/sbtopts` with `--allow-empty` in it.

This change was contributed by Eugene Yokota in [#7966](https://github.com/sbt/sbt/pull/7966).

### csrMavenDependencyOverride setting

sbt 1.10.7 updates Coursier to 2.1.11. sbt 1.10.7 also adds a new setting `csrMavenDependencyOverride` (default: `false`), which controls the resolution, which respects Maven dependency override mechanism, also known as bill-of-materials (BOM) POM. Since there is a performance regression in the new resolver, we are setting the default to `false`.

This change was contributed by Eugene Yokota in [#7966](https://github.com/sbt/sbt/pull/7970).

### Glob expression in scripted

One of the changes between sbt 1.x and 2.x that was difficult to absorb was the difference in the `target` location. To workaround this issue, we're introducing `||` and glob expression in scripted commands such as `exists`.

```bash
# before
$ absent target/out/jvm/scala-3.3.1/clean-managed/src_managed/foo.txt
$ exists target/out/jvm/scala-3.3.1/clean-managed/src_managed/bar.txt

#after
$ absent target/**/src_managed/foo.txt
$ exists target/**/src_managed/bar.txt
```

For multi-project builds we can write:

```bash
$ exists target/**/proj/src_managed/bar.txt || proj/target/**/src_managed/bar.txt
```

This feature was contributed by Eugene Yokota in [#7933](https://github.com/sbt/sbt/pull/7933).

### Other bug fixes and updates

* perf: Precompile a regex in hot code by [@retronym][@retronym] in [zinc#1508](https://github.com/sbt/zinc/pull/1508)
* fix: Update the template resolver to use Giter8 0.17.0, which fixes the SLF4J warning by [@eed3si9n][@eed3si9n] in [#7947](https://github.com/sbt/sbt/pull/7947)
* fix: Update JLine 2 fork to `9a88bc4` and Jansi to 2.4.1, which fixes crash on Windows on ARM by [@Friendseeker][@Friendseeker] in [#7952](https://github.com/sbt/sbt/pull/7952)

### Participation

sbt 1.10.7 was brought to you by nine contributors and two good bots. Jiahui "Jerry" Tan (Friendseeker), Eugene Yokota (eed3si9n), Jason Zaugg, Andrew Brett, Josh Soref, Kenji Yoshida (xuwei-k), Lukas Rytz, Nathan Lao, Seth Tisue, Scala Steward, dependabot[bot]. Thanks!

Thanks to everyone who's helped improve sbt and Zinc by using them, reporting bugs, improving our documentation, porting builds, porting plugins, and submitting and reviewing pull requests.

For anyone interested in helping sbt, there are many avenues for you to help, depending on your interest. If you're interested, [Contributing](https://github.com/sbt/sbt/blob/develop/CONTRIBUTING.md), ["help wanted"](https://github.com/sbt/sbt/issues?q=is%3Aissue+is%3Aopen+label%3A%22help+wanted%22), ["good first issue"](https://github.com/sbt/sbt/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22), and [Discussions](https://github.com/sbt/sbt/discussions/) are good starting points.

----

### Donate to Scala Center

Scala Center is a non-profit center at EPFL to support education and open source.

- [The Scala Center Fundraising Campaign](https://scala-lang.org/blog/2023/09/11/scala-center-fundraising.html)
