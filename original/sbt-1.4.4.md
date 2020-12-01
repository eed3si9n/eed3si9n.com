I'm happy to announce sbt 1.4.4 patch release is available. Full release note is here - https://github.com/sbt/sbt/releases/tag/v1.4.4

### How to upgrade

Download **the official sbt launcher** from SDKMAN or download from <https://github.com/sbt/sbt/releases/>.

In addition, the sbt version used for your build is upgraded by putting the following in `project/build.properties`:

<code>
sbt.version=1.4.4
</code>

This mechanism allows that sbt 1.4.4 is used only for the builds that you want.

### Highlights

- Updates SemanticDB to 4.4.0 to support Scala 2.13.4 [#6148][6148] by [@adpi2][@adpi2]
- Fixes sbt plugin cross building fix [#6091][6091]/[#6151][6151] by [@xuwei-k][@xuwei-k] and [@eatkins][@eatkins]
- Fixes scala-compiler not included into the metabuild classpath [#6146][6146] by [@eatkins][@eatkins]
- Fixes UTF-8 handling in shell and console [#6106][6106] by [@eatkins][@eatkins]
- Fixes macro occasionally dropping expressions trying to work around Scala compiler displaying "a pure expression does nothing" when sbt is really doing something [#6158][6158] by [@eed3si9n][@eed3si9n]
- `Global / localCacheDirectory` for remote caching [#6155][6155] by [@eed3si9n][@eed3si9n]
- Adds system property `sbt.build.onchange` for `onChangedBuildSource` [#6099][6099] by [@xirc][@xirc]

For more details please see https://github.com/sbt/sbt/releases/tag/v1.4.4

### Participation

sbt 1.4.4 was brought to you by 7 contributors. Ethan Atkins, Eugene Yokota (eed3si9n), Kenji Yoshida (xuwei-k), Adrien Piquerez, Taichi Yamakawa, Erwan Queffélec, dependabot. Thank you!

Thanks to everyone who's helped improve sbt and Zinc 1 by using them, reporting bugs, improving our documentation, porting builds, porting plugins, and submitting and reviewing pull requests.

For anyone interested in helping sbt, there are many avenues for you to help, depending on your interest. If you're interested, [Contributing](https://github.com/sbt/sbt/blob/develop/CONTRIBUTING.md), ["help wanted"](https://github.com/sbt/sbt/issues?q=is%3Aissue+is%3Aopen+label%3A%22help+wanted%22), ["good first issue"](https://github.com/sbt/sbt/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22) are good starting points. If you have ideas let us know on [Lightbend Discuss](https://discuss.lightbend.com/c/tooling).

### Donate to April

Apparently April, an active contributor to Scala compiler has been sick without diagnosis. Let's help her out!

https://www.gofundme.com/f/help-april-survive-while-sick


  [@adpi2]: https://github.com/adpi2
  [@eed3si9n]: https://github.com/eed3si9n
  [@eatkins]: https://github.com/eatkins
  [@xuwei-k]: https://github.com/xuwei-k
  [@xirc]: https://github.com/xirc
  [@3rwww1]: https://github.com/3rwww1
  [6091]: https://github.com/sbt/sbt/pull/6091
  [6097]: https://github.com/sbt/sbt/pull/6097
  [6151]: https://github.com/sbt/sbt/pull/6151
  [6099]: https://github.com/sbt/sbt/pull/6099
  [6106]: https://github.com/sbt/sbt/pull/6106
  [6107]: https://github.com/sbt/sbt/pull/6107
  [6108]: https://github.com/sbt/sbt/pull/6108
  [6112]: https://github.com/sbt/sbt/pull/6112
  [6113]: https://github.com/sbt/sbt/pull/6113
  [6115]: https://github.com/sbt/sbt/pull/6115
  [6114]: https://github.com/sbt/sbt/pull/6114
  [6130]: https://github.com/sbt/sbt/pull/6130
  [6128]: https://github.com/sbt/sbt/pull/6128
  [6129]: https://github.com/sbt/sbt/pull/6129
  [6148]: https://github.com/sbt/sbt/pull/6148
  [6146]: https://github.com/sbt/sbt/pull/6146
  [6158]: https://github.com/sbt/sbt/pull/6158
  [6155]: https://github.com/sbt/sbt/pull/6155
  [ivy40]: https://github.com/sbt/ivy/pull/40
