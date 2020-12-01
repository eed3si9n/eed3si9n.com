I'm happy to announce sbt 1.4.3 patch release is available. Full release note is here - https://github.com/sbt/sbt/releases/tag/v1.4.3

### How to upgrade

Download **the official sbt launcher** from SDKMAN or download from <https://github.com/sbt/sbt/releases/>. This installer includes the `sbtn` binary.

In addition, the sbt version used for your build is upgraded by putting the following in `project/build.properties`:

<code>
sbt.version=1.4.3
</code>

This mechanism allows that sbt 1.4.3 is used only for the builds that you want.

### Highlights

- Updates to Coursier 2.0.6 [#6036][6036] by [@jtjeferreira][@jtjeferreira]
- Fixes IntelliJ import on Windows [#6051][6051] by [@eatkins][@eatkins]
- Fixes the dependency resolution in metabuild [#6085][6085] by [@eed3si9n][@eed3si9n]
- Removes "duplicate compilations" assertion to work around Play issue [zinc#940][zinc940] by [@johnduffell][@johnduffell]
- Fixes GC monitor warnings [#6082][6082] by [@nafg][@nafg]

For more details please see https://github.com/sbt/sbt/releases/tag/v1.4.3

### Participation

sbt 1.4.3 was brought to you by 6 contributors. Ethan Atkins, Eugene Yokota (eed3si9n), Naftoli Gugenheim, Jason Zaugg, João Ferreira, John Duffell. Thank you!

Thanks to everyone who's helped improve sbt and Zinc 1 by using them, reporting bugs, improving our documentation, porting builds, porting plugins, and submitting and reviewing pull requests.

For anyone interested in helping sbt, there are many avenues for you to help, depending on your interest. If you're interested, [Contributing](https://github.com/sbt/sbt/blob/develop/CONTRIBUTING.md), ["help wanted"](https://github.com/sbt/sbt/issues?q=is%3Aissue+is%3Aopen+label%3A%22help+wanted%22), ["good first issue"](https://github.com/sbt/sbt/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22) are good starting points. If you have ideas let us know on [Lightbend Discuss](https://discuss.lightbend.com/c/tooling).

### Donate to April

Apparently April, an active contributor to Scala compiler has been sick without diagnosis. Let's help her out!

https://www.gofundme.com/f/help-april-survive-while-sick

  [6051]: https://github.com/sbt/sbt/pull/6051
  [6044]: https://github.com/sbt/sbt/pull/6044
  [6054]: https://github.com/sbt/sbt/pull/6054
  [6036]: https://github.com/sbt/sbt/pull/6036
  [6041]: https://github.com/sbt/sbt/pull/6041
  [6068]: https://github.com/sbt/sbt/pull/6068
  [6073]: https://github.com/sbt/sbt/pull/6073
  [6067]: https://github.com/sbt/sbt/pull/6067
  [6082]: https://github.com/sbt/sbt/pull/6082
  [6085]: https://github.com/sbt/sbt/pull/6085
  [zinc940]: https://github.com/sbt/zinc/pull/940
  [zinc939]: https://github.com/sbt/zinc/pull/939
  [@adpi2]: https://github.com/adpi2
  [@eed3si9n]: https://github.com/eed3si9n
  [@eatkins]: https://github.com/eatkins
  [@xuwei-k]: https://github.com/xuwei-k
  [@jtjeferreira]: https://github.com/jtjeferreira
  [@nafg]: https://github.com/nafg
  [@johnduffell]: https://github.com/johnduffell
  [@retronym]: https://github.com/retronym
