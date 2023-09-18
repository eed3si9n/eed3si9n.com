---
title:       "sbt 1.9.6"
type:        story
date:        2023-09-15
url:         /sbt-1.9.6
tags:        [ "sbt" ]
---

Hi everyone. On behalf of the sbt project, I'm happy to announce sbt 1.9.6 patch release is available. Full release note is here - https://github.com/sbt/sbt/releases/tag/v1.9.6

See [1.9.0 release note](/sbt-1.9.0) for the details on 1.9.x features.

### Highlights

- sbt 1.9.6 reverts "internal representation of class symbol names", which caused Scala compiler to generate wrong anonymous class name by [@eed3si9n][@eed3si9n] in [sbt/zinc#1256](https://github.com/sbt/zinc/pull/1256). See [scala/bug#12868](https://github.com/scala/bug/issues/12868) for more details.

<!--more-->

### How to upgrade

The sbt version used for your build must be upgraded by putting the following in `project/build.properties`:

```bash
sbt.version=1.9.6
```

This mechanism allows that sbt 1.9.6 is used only for the builds that you want.

Download **the official sbt runner** from, `cs setup`, SDKMAN, or download from <https://github.com/sbt/sbt/releases/tag/v1.9.6> to upgrade the `sbt` shell script and the launcher.

## Zinc regression

We're still investigating on the details, but per Lukas on [scala/bug#12868](https://github.com/scala/bug/issues/12868):

> Say we have `package p { class C { def m { new anon { def sol } } } }`.
>
> The phase travel `exitingFlatten` added in sbt/zinc#1244 causes the (cached) flatname of `ClassSymbol` for the anonymous class to be computed after the flatten phase. The owner chain of the symbol is different at this point. So instead of something like `p.C$m$anon` we end up with only `p.m$anon`.
>
> The error in Pekko is due to two anonymous classes now having the same name accidentally. However, I believe that this has a broad effect, many anonymous classes will get a different name when compiling with the new zinc.
>
> While it's possibly OK in terms of binary compatibiliy (anonymous classes cannot be referenced externally), it's still an unintended wide-reaching change.
>
> It probably should be considered a bug in the compiler, but we cannot change existing compiler releases. The new Zinc needs to continue working with existing compiler releases.

I merged [sbt/zinc#1244](https://github.com/sbt/zinc/pull/1244) with a cursory review (it looked ok to me), so I take responsibility on this regression. IT'S ME HI.

### Participation

Thanks to everyone who's helped improve sbt and Zinc by using them, reporting bugs, improving our documentation, porting builds, porting plugins, and submitting and reviewing pull requests.

For anyone interested in helping sbt, there are many avenues for you to help, depending on your interest. If you're interested, [Contributing](https://github.com/sbt/sbt/blob/develop/CONTRIBUTING.md), ["help wanted"](https://github.com/sbt/sbt/issues?q=is%3Aissue+is%3Aopen+label%3A%22help+wanted%22), ["good first issue"](https://github.com/sbt/sbt/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22), and [Discussions](https://github.com/sbt/sbt/discussions/) are good starting points.

----

### 🏳️‍🌈 Support Ukraine 🇺🇦

Forbidden Colours has started a fundraising campaign to support organisations in Poland, Hungary and Romania that are welcoming LGBTIQ+ refugees.

<https://www.forbidden-colours.com/2022/02/26/support-ukrainian-lgbtiq-refugees/>

### Donate to Scala Center

Scala Center is a non-profit center at EPFL to support education and open source.

- [The Scala Center Fundraising Campaign](https://scala-lang.org/blog/2023/09/11/scala-center-fundraising.html)

  [@eed3si9n]: https://github.com/eed3si9n
  [@Nirvikalpa108]: https://github.com/Nirvikalpa108
  [@adpi2]: https://github.com/adpi2
  [@er1c]: https://github.com/er1c
  [@eatkins]: https://github.com/eatkins
  [@dwijnand]: https://github.com/dwijnand
  [zinc1246]: https://github.com/sbt/zinc/pull/1246
  [zinc1244]: https://github.com/sbt/zinc/pull/1244
  [zinc1228]: https://github.com/sbt/zinc/pull/1228
  [zinc1247]: https://github.com/sbt/zinc/pull/1247
