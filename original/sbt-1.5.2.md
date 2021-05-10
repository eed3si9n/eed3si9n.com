[6469]: https://github.com/sbt/sbt/pull/6469
[6484]: https://github.com/sbt/sbt/pull/6484
[6483]: https://github.com/sbt/sbt/pull/6483
[6488]: https://github.com/sbt/sbt/pull/6488
[6493]: https://github.com/sbt/sbt/pull/6493
[6500]: https://github.com/sbt/sbt/pull/6500
[6497]: https://github.com/sbt/sbt/issues/6497
[zinc974]: https://github.com/sbt/zinc/issues/974
[@eed3si9n]: https://github.com/eed3si9n
[@lefou]: https://github.com/lefou
[@Nirvikalpa108]: https://github.com/Nirvikalpa108
[@rdesgroppes]: https://github.com/rdesgroppes
[@adpi2]: https://github.com/adpi2

I'm happy to announce sbt 1.5.2 patch release is available. Full release note is here - https://github.com/sbt/sbt/releases/tag/v1.5.2

### How to upgrade

Download **the official sbt runner + launcher** from SDKMAN or download from <https://github.com/sbt/sbt/releases/>.

In addition, the sbt version used for your build is upgraded by putting the following in `project/build.properties`:

<code>
sbt.version=1.5.2
</code>

This mechanism allows that sbt 1.5.2 is used only for the builds that you want.

### Highlights

- Fixes `sbt new` leaving behind `target` directory [#6488][6488] by [@eed3si9n][@eed3si9n]
- Fixes `ConcurrentModificationException` while compiling Scala 2.13.4 and Java sources [zinc#974][zinc974] by [@lefou][@lefou]
- Improved [developer guide](https://github.com/sbt/sbt/blob/develop/DEVELOPING.md) for new contributors [#6469][6469] by [@Nirvikalpa108][@Nirvikalpa108]
- Fixes `-client` by making it the same as `--client` [#6500][6500] by [@Nirvikalpa108][@Nirvikalpa108]
- Uses `-Duser.home` instead of `$HOME` to download launcher JAR [#6483][6483] by [@rdesgroppes][@rdesgroppes]

For more details please see https://github.com/sbt/sbt/releases/tag/v1.5.2

### Participation

sbt 1.5.2 was brought to you by 6 contributors. Eugene Yokota (eed3si9n), Amina Adewusi, Adrien Piquerez, Regis Desgroppes, Tobias Roeser, and Filip Popić. Thank you!

Thanks to everyone who's helped improve sbt and Zinc 1 by using them, reporting bugs, improving our documentation, porting builds, porting plugins, and submitting and reviewing pull requests.

For anyone interested in helping sbt, there are many avenues for you to help, depending on your interest. If you're interested, [Contributing](https://github.com/sbt/sbt/blob/develop/CONTRIBUTING.md), ["help wanted"](https://github.com/sbt/sbt/issues?q=is%3Aissue+is%3Aopen+label%3A%22help+wanted%22), ["good first issue"](https://github.com/sbt/sbt/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22) are good starting points. If you have ideas let us know on [sbt Discussions](https://github.com/sbt/sbt/discussions).

### Donate to April

Apparently April, an active contributor to Scala compiler has been sick without diagnosis. Let's help her out!

https://www.gofundme.com/f/help-april-survive-while-sick
