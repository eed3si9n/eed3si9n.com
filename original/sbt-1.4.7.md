I'm happy to announce sbt 1.4.7 patch release is available. Full release note is here - https://github.com/sbt/sbt/releases/tag/v1.4.7

### How to upgrade

Download **the official sbt launcher** from SDKMAN or download from <https://github.com/sbt/sbt/releases/>.

In addition, the sbt version used for your build is upgraded by putting the following in `project/build.properties`:

<code>
sbt.version=1.4.7
</code>

This mechanism allows that sbt 1.4.7 is used only for the builds that you want.

### Highlights

- Updates to Coursier 2.0.9, fixing authentication with Sonatype Nexus [#6278][6278] / [coursier#1948] by [@cchepelov][@cchepelov]
- Fixes Ctrl-C printing out stack trace [#6213][6213] by [@eatkins][@eatkins]
- GNU Emacs support for `sbtn` and `sbt --client` [#6276][6276] by [@fommil][@fommil]

### Participation

sbt 1.4.7 was brought to you by 5 contributors. Sam Halliday, Eugene Yokota (eed3si9n), Adrien Piquerez, Cyrille Chepelov, Ethan Atkins. Thank you!

Thanks to everyone who's helped improve sbt and Zinc 1 by using them, reporting bugs, improving our documentation, porting builds, porting plugins, and submitting and reviewing pull requests.

For anyone interested in helping sbt, there are many avenues for you to help, depending on your interest. If you're interested, [Contributing](https://github.com/sbt/sbt/blob/develop/CONTRIBUTING.md), ["help wanted"](https://github.com/sbt/sbt/issues?q=is%3Aissue+is%3Aopen+label%3A%22help+wanted%22), ["good first issue"](https://github.com/sbt/sbt/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22) are good starting points. If you have ideas let us know on [sbt Discussions](https://github.com/sbt/sbt/discussions).

### Donate to April

Apparently April, an active contributor to Scala compiler has been sick without diagnosis. Let's help her out!

https://www.gofundme.com/f/help-april-survive-while-sick

  [@adpi2]: https://github.com/adpi2
  [@eed3si9n]: https://github.com/eed3si9n
  [@eatkins]: https://github.com/eatkins
  [@cchepelov]: https://github.com/cchepelov
  [@fommil]: https://github.com/fommil
  [6278]: https://github.com/sbt/sbt/pull/6278
  [6213]: https://github.com/sbt/sbt/pull/6213
  [6257]: https://github.com/sbt/sbt/pull/6257
  [6276]: https://github.com/sbt/sbt/pull/6276
  [6284]: https://github.com/sbt/sbt/pull/6284
  [6231]: https://github.com/sbt/sbt/pull/6231
  [coursier1948]: https://github.com/coursier/coursier/pull/1948
