I'm happy to announce sbt 1.4.1 patch release is available. Full release note is here - https://github.com/sbt/sbt/releases/tag/v1.4.1

### How to upgrade

Download **the official sbt launcher** from SDKMAN or download from <https://www.scala-sbt.org/download.html>. This installer includes the `sbtn` binary.

In addition, the sbt version used for your build is upgraded by putting the following in `project/build.properties`:

<code>
sbt.version=1.4.1
</code>

This mechanism allows that sbt 1.4.1 is used only for the builds that you want.

### Highlights

- Various read line and character handling fixes by [@eatkins][@eatkins], including `sbt new` not echoing back the characters
- Fixes Scala 2.13-3.0 sandwich support for Scala.JS [#5984][5984] by [@xuwei-k][@xuwei-k]
- Fixes `shellPrompt` and `release*` keys warning on build linting [#5983][5983]/[#5991][5991] by [@xirc][@xirc] and [@eed3si9n][@eed3si9n]
- Improves `plugin` command output by grouping by subproject [#5932][5932] by [@aaabramov][@aaabramov]

For more details please see https://github.com/sbt/sbt/releases/tag/v1.4.1

### Participation

sbt 1.4.1 was brought to you by 9 contributors. Ethan Atkins, Eugene Yokota (eed3si9n), Adrien Piquerez, Kenji Yoshida (xuwei-k), Nader Ghanbari, Taichi Yamakawa, Andrii Abramov, Guillaume Martres, Regis Desgroppes. Thank you! Some of the contributions were made during ScalaMatsuri 2020 [Hackathon][1].

Thanks to everyone who's helped improve sbt and Zinc 1 by using them, reporting bugs, improving our documentation, porting builds, porting plugins, and submitting and reviewing pull requests.

For anyone interested in helping sbt, there are many avenues for you to help, depending on your interest. If you're interested, [Contributing](https://github.com/sbt/sbt/blob/develop/CONTRIBUTING.md), ["help wanted"](https://github.com/sbt/sbt/issues?q=is%3Aissue+is%3Aopen+label%3A%22help+wanted%22), ["good first issue"](https://github.com/sbt/sbt/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22) are good starting points. If you have ideas let us know on [Lightbend Discuss](https://discuss.lightbend.com/c/tooling).

### Donate to April

Apparently April, an active contributor to Scala compiler has been sick without diagnosis. Let's help her out!

https://www.gofundme.com/f/help-april-survive-while-sick

  [1]: https://eed3si9n.com/virtualizing-hackathon-at-scalamatsuri2020
  [5930]: https://github.com/sbt/sbt/pull/5930
  [5946]: https://github.com/sbt/sbt/pull/5946
  [5945]: https://github.com/sbt/sbt/pull/5945
  [5947]: https://github.com/sbt/sbt/pull/5947
  [5961]: https://github.com/sbt/sbt/pull/5961
  [5960]: https://github.com/sbt/sbt/pull/5960
  [5966]: https://github.com/sbt/sbt/pull/5966
  [5954]: https://github.com/sbt/sbt/pull/5954
  [5948]: https://github.com/sbt/sbt/pull/5948
  [5964]: https://github.com/sbt/sbt/pull/5964
  [5967]: https://github.com/sbt/sbt/pull/5967
  [5950]: https://github.com/sbt/sbt/issues/5950
  [5932]: https://github.com/sbt/sbt/pull/5932
  [5972]: https://github.com/sbt/sbt/pull/5972
  [5973]: https://github.com/sbt/sbt/pull/5973
  [5975]: https://github.com/sbt/sbt/pull/5975
  [5984]: https://github.com/sbt/sbt/pull/5984
  [5983]: https://github.com/sbt/sbt/pull/5983
  [5981]: https://github.com/sbt/sbt/pull/5981
  [5991]: https://github.com/sbt/sbt/pull/5991
  [5990]: https://github.com/sbt/sbt/pull/5990
  [zinc931]: https://github.com/sbt/zinc/pull/931
  [zinc934]: https://github.com/sbt/zinc/pull/934
  [@adpi2]: https://github.com/adpi2
  [@eed3si9n]: https://github.com/eed3si9n
  [@eatkins]: https://github.com/eatkins
  [@xuwei-k]: https://github.com/xuwei-k
  [@rdesgroppes]: https://github.com/rdesgroppes
  [@naderghanbari]: https://github.com/naderghanbari
  [@aaabramov]: https://github.com/aaabramov
  [@xirc]: https://github.com/xirc
  [@smarter]: https://github.com/smarter