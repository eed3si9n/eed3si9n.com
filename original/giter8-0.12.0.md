### giter8.version

I added a small app called giter8-launcher for Giter8 0.12.0. The purpose of the app is to make the behavior of the Giter8 template more predictable. Today, template authors may create a template for some version of Giter8 X, but the users might use some other version of Giter8 Y that ships with "sbt new."

One of the neat ideas about sbt is that no matter what version of `sbt` script users might have it installed, the core sbt version is specified by the build author using `project/build.properties` file. This significantly reduces the it-only-works-on-my-machine problem. giter8-launcher is analogous to sbt's sbt-launcher. giter8-launcher clones the template and reads `project/build.properties` file to determine the Giter8 version to render the template.

Template authors can now specify the Giter8 version in `project/build.properties` file as:

```
giter8.version=0.12.0
```

Once "sbt new" uses this mechanism it should decouple the Giter8 version from the release cycle of sbt.

I implemented this feature in [#444][444] working on and off for a while. The original idea was proposed by Merlijn Boogerd ([@mboogerd][@mboogerd]) in 2017 as [#303][303], and was merged as [#344][344] but it didn't work so we had to pull it out. I am hoping third time is the charm.

#### Coursier bootstrap

Giter8 0.12.0 also adds a bootstrap script for giter8-launcher generated using Coursier, and publishes to Maven Central as <http://repo1.maven.org/maven2/org/foundweekends/giter8/giter8-bootstrap_2.12/0.12.0/giter8-bootstrap_2.12-0.12.0.sh>. This could be locally saved as `~/bin/g8`.

### Documentation in Korean

Earlier this year (2019), documentation was translated to [Korean](http://www.foundweekends.org/giter8/ko/) by Hamel Yeongho Moon ([@hamelmoon][@hamelmoon]) in [#417][417] with review by [@yoohaemin][@yoohaemin]. Thanks!

### Other updates

- Adds help description for `--out` option [#391][391] by [@anilkumarmyla][@anilkumarmyla]
- Replaces Scalasti dependency with StringTemplate [#392][392] by [@xuwei-k][@xuwei-k]
- Switches to using Maven Central API [#395][395] by [@kounoike][@kounoike]
- Fixes conditional file creation [#432][432] by [@ihostage][@ihostage]
- Fixes how Giter8 deals with scripted test [#408][408] by [@renatocaval][@renatocaval]
- Switch from Apache HTTP client to `URL#openConnection` [#441][441]
- Lots of build upkeep by [@xuwei-k][@xuwei-k]

Special thanks to the contributors for making this release a success.

```
$ git shortlog -sn --no-merges v0.11.0...v0.12.0
    50  kenji yoshida (xuwei-k)
    11  Eugene Yokota (eed3si9n)
     3  Yeongho Moon
     2  Dale Wijnand
     2  Renato Cavalcanti
     1  Yuusuke Kounoike
     1  Jentsch
     1  Anil Kumar Myla
     1  Sergey Morgunov
```

  [@anilkumarmyla]: https://github.com/anilkumarmyla
  [@xuwei-k]: https://github.com/xuwei-k
  [@kounoike]: https://github.com/kounoike
  [@hamelmoon]: https://github.com/hamelmoon
  [@yoohaemin]: https://github.com/yoohaemin
  [@ihostage]: https://github.com/ihostage
  [@renatocaval]: https://github.com/renatocaval
  [@eed3si9n]: https://github.com/eed3si9n
  [@mboogerd]: https://github.com/mboogerd
  [303]: https://github.com/foundweekends/giter8/pull/303
  [391]: https://github.com/foundweekends/giter8/pull/391
  [392]: https://github.com/foundweekends/giter8/pull/392
  [395]: https://github.com/foundweekends/giter8/pull/395
  [408]: https://github.com/foundweekends/giter8/pull/408
  [417]: https://github.com/foundweekends/giter8/pull/417
  [432]: https://github.com/foundweekends/giter8/pull/432
  [441]: https://github.com/foundweekends/giter8/pull/441
  [444]: https://github.com/foundweekends/giter8/pull/444
  [344]: https://github.com/foundweekends/giter8/pull/344
