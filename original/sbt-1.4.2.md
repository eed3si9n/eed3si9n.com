I'm happy to announce sbt 1.4.2 patch release is available. Full release note is here - https://github.com/sbt/sbt/releases/tag/v1.4.2

### How to upgrade

Download **the official sbt launcher** from SDKMAN or download from <https://github.com/sbt/sbt/releases/>. This installer includes the `sbtn` binary.

In addition, the sbt version used for your build is upgraded by putting the following in `project/build.properties`:

<code>
sbt.version=1.4.2
</code>

This mechanism allows that sbt 1.4.2 is used only for the builds that you want.

### Highlights

- Remote caching is now content-based [#6026][6026] by [@eed3si9n][@eed3si9n]
- `installSbtn` wizard for installing sbtn and completions [#6023][6023] by [@eatkins][@eatkins]
- Fixes memory leak during task evaluation [#6001][6001] by [@eatkins][@eatkins]
- Various read line and character handling fixes by [@eatkins][@eatkins]
- Various BSP fixes by [@adpi2][@adpi2]

For more details please see https://github.com/sbt/sbt/releases/tag/v1.4.2

### Participation

sbt 1.4.2 was brought to you by 5 contributors. Ethan Atkins, Eugene Yokota (eed3si9n), Adrien Piquerez, Dale Wijnand, and Kenji Yoshida (xuwei-k). Thank you!

Thanks to everyone who's helped improve sbt and Zinc 1 by using them, reporting bugs, improving our documentation, porting builds, porting plugins, and submitting and reviewing pull requests.

For anyone interested in helping sbt, there are many avenues for you to help, depending on your interest. If you're interested, [Contributing](https://github.com/sbt/sbt/blob/develop/CONTRIBUTING.md), ["help wanted"](https://github.com/sbt/sbt/issues?q=is%3Aissue+is%3Aopen+label%3A%22help+wanted%22), ["good first issue"](https://github.com/sbt/sbt/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22) are good starting points. If you have ideas let us know on [Lightbend Discuss](https://discuss.lightbend.com/c/tooling).

### Donate to April

Apparently April, an active contributor to Scala compiler has been sick without diagnosis. Let's help her out!

https://www.gofundme.com/f/help-april-survive-while-sick

  [6001]: https://github.com/sbt/sbt/pull/6001
  [6003]: https://github.com/sbt/sbt/pull/6003
  [6000]: https://github.com/sbt/sbt/pull/6000
  [5998]: https://github.com/sbt/sbt/pull/5998
  [5996]: https://github.com/sbt/sbt/pull/5996
  [6005]: https://github.com/sbt/sbt/pull/6005
  [6011]: https://github.com/sbt/sbt/pull/6011
  [6016]: https://github.com/sbt/sbt/pull/6016
  [6018]: https://github.com/sbt/sbt/pull/6018
  [6019]: https://github.com/sbt/sbt/pull/6019
  [6008]: https://github.com/sbt/sbt/pull/6008
  [6007]: https://github.com/sbt/sbt/pull/6007
  [6023]: https://github.com/sbt/sbt/pull/6023
  [6026]: https://github.com/sbt/sbt/pull/6026
  [lp338]: https://github.com/sbt/sbt-launcher-package/pull/338
  [zinc935]: https://github.com/sbt/zinc/pull/935
  [@adpi2]: https://github.com/adpi2
  [@eed3si9n]: https://github.com/eed3si9n
  [@eatkins]: https://github.com/eatkins
  [@xuwei-k]: https://github.com/xuwei-k
