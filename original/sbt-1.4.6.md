I'm happy to announce sbt 1.4.6 patch release is available. Full release note is here - https://github.com/sbt/sbt/releases/tag/v1.4.6

### How to upgrade

Download **the official sbt launcher** from SDKMAN or download from <https://github.com/sbt/sbt/releases/>.

In addition, the sbt version used for your build is upgraded by putting the following in `project/build.properties`:

<code>
sbt.version=1.4.6
</code>

This mechanism allows that sbt 1.4.6 is used only for the builds that you want.

### Highlights

- Updates to Coursier 2.0.8, which fixes the cache directory setting on Windows (Fix contributed by Frank Thomas)
- Fixes performance regression in shell tab completion [#6214][6214] by [@eed3si9n][@eed3si9n]
- Fixes match error when using `withDottyCompat` [lm#352][lm352] by [@eed3si9n][@eed3si9n]
- Fixes thread-safety in AnalysisCallback handler [zinc#957][zinc957] by [@dotta][@dotta]

### Participation

sbt 1.4.6 was brought to you by 3 contributors. Eugene Yokota (eed3si9n), Mirco Dotta, and Frank Thomas. Thank you!

Thanks to everyone who's helped improve sbt and Zinc 1 by using them, reporting bugs, improving our documentation, porting builds, porting plugins, and submitting and reviewing pull requests.

For anyone interested in helping sbt, there are many avenues for you to help, depending on your interest. If you're interested, [Contributing](https://github.com/sbt/sbt/blob/develop/CONTRIBUTING.md), ["help wanted"](https://github.com/sbt/sbt/issues?q=is%3Aissue+is%3Aopen+label%3A%22help+wanted%22), ["good first issue"](https://github.com/sbt/sbt/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22) are good starting points. If you have ideas let us know on [sbt Discussions](https://github.com/sbt/sbt/discussions).

### Donate to April

Apparently April, an active contributor to Scala compiler has been sick without diagnosis. Let's help her out!

https://www.gofundme.com/f/help-april-survive-while-sick

  [lm352]: https://github.com/sbt/librarymanagement/pull/352
  [6214]: https://github.com/sbt/sbt/pull/6214
  [zinc957]: https://github.com/sbt/zinc/pull/957
  [@dotta]: https://github.com/dotta
  [@adpi2]: https://github.com/adpi2
  [@eed3si9n]: https://github.com/eed3si9n
  [@eatkins]: https://github.com/eatkins
