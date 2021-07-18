
  [@eed3si9n]: https://github.com/eed3si9n
  [@Nirvikalpa108]: https://github.com/Nirvikalpa108
  [@adpi2]: https://github.com/adpi2
  [@eatkins]: https://github.com/eatkins
  [@dwijnand]: https://github.com/dwijnand
  [@retronym]: https://github.com/retronym
  [@ephemerist]: https://github.com/ephemerist
  [@samuelClarencTeads]: https://github.com/samuelClarencTeads
  [@sebastian-alfers]: https://github.com/sebastian-alfers
  [6551]: https://github.com/sbt/sbt/pull/6551
  [6554]: https://github.com/sbt/sbt/pull/6554
  [6556]: https://github.com/sbt/sbt/pull/6556
  [6552]: https://github.com/sbt/sbt/pull/6552
  [6565]: https://github.com/sbt/sbt/pull/6565
  [6553]: https://github.com/sbt/sbt/pull/6553
  [lm383]: https://github.com/sbt/librarymanagement/pull/383
  [lm384]: https://github.com/sbt/librarymanagement/pull/384
  [zinc989]: https://github.com/sbt/zinc/pull/989
  [zinc988]: https://github.com/sbt/zinc/pull/988
  [zinc990]: https://github.com/sbt/zinc/pull/990
  [zinc985]: https://github.com/sbt/zinc/pull/985
  [zinc986]: https://github.com/sbt/zinc/pull/986
  [zinc987]: https://github.com/sbt/zinc/pull/987
  [launcher98]: https://github.com/sbt/launcher/pull/98

I'm happy to announce sbt 1.5.5 patch release is available. Full release note is here - https://github.com/sbt/sbt/releases/tag/v1.5.5

### How to upgrade

Download **the official sbt runner + launcher** from SDKMAN or download from <https://github.com/sbt/sbt/releases/>.

In addition, the sbt version used for your build is upgraded by putting the following in `project/build.properties`:

<code>
sbt.version=1.5.5
</code>

This mechanism allows that sbt 1.5.5 is used only for the builds that you want.

### Highlights

- Various Zinc fixes and enhancements by [@ephemerist][@ephemerist] and [@retronym][@retronym]
- Adds `buildTarget/resources` support for BSP [#6552][6552] by [@samuelClarencTeads][@samuelClarencTeads]
- Adds `build.sbt` support for BSP import [#6553][6553] by [@retronym][@retronym]
- Fixes BSP task error handling [#6565][6565] by [@adpi2][@adpi2]
- Fixes remote caching not managing resource files [#6554][6554] by [@Nirvikalpa108][@Nirvikalpa108]
- Fixes launcher causing `NoClassDefFoundError` when launching sbt 1.4.0 - 1.4.2 [launcher#98][launcher98] by [@eed3si9n][@eed3si9n]
- Fixes cross-Scala suffix conflict warning involving `_3` [lm#383][lm383] by [@eed3si9n][@eed3si9n]

### Participation

sbt 1.5.5 was brought to you by 7 contributors. Andrew Brett, Jason Zaugg, Eugene Yokota (eed3si9n), Adrien Piquerez, Samuel CLARENC, Chris Andrews, Amina Adewusi, Sebastian Alfers. Thank you!

Thanks to everyone who's helped improve sbt and Zinc 1 by using them, reporting bugs, improving our documentation, porting builds, porting plugins, and submitting and reviewing pull requests.

For anyone interested in helping sbt, there are many avenues for you to help, depending on your interest. If you're interested, [Contributing](https://github.com/sbt/sbt/blob/develop/CONTRIBUTING.md), ["help wanted"](https://github.com/sbt/sbt/issues?q=is%3Aissue+is%3Aopen+label%3A%22help+wanted%22), ["good first issue"](https://github.com/sbt/sbt/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22) are good starting points. If you have ideas let us know on [sbt Discussions](https://github.com/sbt/sbt/discussions).


### Donate/Hire April

Apparently April, an active contributor to Scala compiler has been sick without diagnosis. Let's help her out!

- https://www.gofundme.com/f/help-april-survive-while-sick
- https://twitter.com/NthPortal/status/1412504710754541572
