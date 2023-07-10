---
title:       "sbt 1.9.1"
type:        story
date:        2023-06-26
url:         /sbt-1.9.1
tags:        [ "sbt" ]
---

Hi everyone. On behalf of the sbt project, I'm happy to announce sbt 1.9.1 patch release is available. Full release note is here - https://github.com/sbt/sbt/releases/tag/v1.9.1

See [1.9.0 release note](/sbt-1.9.0) for the details on 1.9.x features.

### Highlights

- Change of contributor license agreement to Scala CLA, which transfers contribution copyrights to the Scala Center, instead of Lightbend by [@julienrf][@julienrf] (Julien Richard-Foy is Technical Director at Scala Center) in [#7306][7306]
- Publishing related bug fixes following up on sbt 1.9.0, contributed by Adrien Piquerez at Scala Center

<!--more-->

### Change to Scala CLA

sbt 1.9.1 is the first release of sbt after changing to Scala CLA in [#7306][7306] etc. A number of contributors to sbt voiced concerns about donating our work to Lightbend after 2022, and Lightbend, Scala Center, and I agreed on changing the contributor license agreement such that the copyright would tranfer to Scala Center, a non-profit organization. sbt and its subcompoments, including Zinc, will remain available under Apache v2 license.

### Updates

- Fixes "Repository for publishing is not specified" error even when `publish / skip` is set `true` by [@adpi2][@adpi2] in [#7295][7295]
- Fixes scripted test not working when `sbtPluginPublishLegacyMavenStyle := false` by [@adpi2][@adpi2] in [#7286][7286]
- Fixes copy-pasting to `sbt console` being slow by [@andrzejressel][@andrzejressel] in [#7280][7280]
- Fixes missing range in BSP Diagnostic by [@adpi2][@adpi2] in [#7298][7298]
- Fixes zip64 offset writing by [@dwijnand][@dwijnand] in [zinc#1206][zinc1206]
- Fixes a typo in the description of `exportPipelining` key by [@alexklibisz][@alexklibisz] in [#7291][7291]
- `dependencyBrowseGraph` and `dependencyDot` render in color by [@sideeffffect][@sideeffffect] in [#7301][7301]. This can be opted-out using `dependencyDotNodeColors` setting.
- Adds softwaremill/tapir.g8 to `sbt new` default menu by [@katlasik][@katlasik] in [#7300][7300]
- Makes `sbt new` default menu extensible via `templateDescriptions` setting key and `templateRunLocal` input key by [@eed3si9n][@eed3si9n] in [#7304][7304]
- Adds Hedgehog Scala to default test framework by [@kevin-lee][@kevin-lee] in [#7287][7287]
- Updates `semanticdbVersion` to 4.7.8 by [@ckipp01][@ckipp01] in [#7294][7294]
- Updates JNA to 5.13.0 by [@xuwei-k][@xuwei-k] in [io#346][io346]
- Updates Scala 2.13 for Zinc etc to 2.13.11 by [@mkurz][@mkurz] in [#7279][7279]
- Updates sbtn to 1.9.0 by [@mkurz][@mkurz] in [#7290][7290]
- Updates Scala Toolkit to 0.2.0 by [@eed3si9n][@eed3si9n] in [#7318][7318]

### Behind the scene

- Adds `@tailrec` annotation by [@xuwei-k][@xuwei-k] in [zinc#1209][zinc1209]
- Updates Scala versions in scripted tests by [@xuwei-k][@xuwei-k] in [#7312][7312]
- Many typo fixes by [@xuwei-k][@xuwei-k] in [#7313][7313]
- Fixes Scaladoc warnings by [@xuwei-k][@xuwei-k] in [#7314][7314]
- Typo fix in `DEVELOPING.md` by [@dongxuwang][@dongxuwang] in [#7299][7299]
- Avoids deprecated `java.net.URL` constructor by [@xuwei-k][@xuwei-k] in [#7315][7315]
- Refactors `filter` to `withFilter` where possible by [@xuwei-k][@xuwei-k] in [#7317][7317]

### Participation

sbt 1.9.1 was brought to you by 13 contributors and one good bot: Kenji Yoshida (xuwei-k), Eugene Yokota (eed3si9n), Adrien Piquerez, Matthias Kurz, Julien Richard-Foy, Alex Klibisz, Andrzej Ressel, Chris Kipp, Dale Wijnand, Dongxu Wang, Kevin Lee, Krzysztof Atłasik, Ondra Pelech, Scala Steward. Thanks!

Thanks to everyone who's helped improve sbt and Zinc by using them, reporting bugs, improving our documentation, porting builds, porting plugins, and submitting and reviewing pull requests.

For anyone interested in helping sbt, there are many avenues for you to help, depending on your interest. If you're interested, [Contributing](https://github.com/sbt/sbt/blob/develop/CONTRIBUTING.md), ["help wanted"](https://github.com/sbt/sbt/issues?q=is%3Aissue+is%3Aopen+label%3A%22help+wanted%22), ["good first issue"](https://github.com/sbt/sbt/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22), and [Discussions](https://github.com/sbt/sbt/discussions/) are good starting points.

### 🏳️‍🌈 Support Ukraine 🇺🇦

Forbidden Colours has started a fundraising campaign to support organisations in Poland, Hungary and Romania that are welcoming LGBTIQ+ refugees.

<https://www.forbidden-colours.com/2022/02/26/support-ukrainian-lgbtiq-refugees/>

### Donate to Scala Center

Scala Center is a non-profit center at EPFL to support education and open source.

- <https://scala.epfl.ch/donate.html>

  [@eed3si9n]: https://github.com/eed3si9n
  [@Nirvikalpa108]: https://github.com/Nirvikalpa108
  [@adpi2]: https://github.com/adpi2
  [@er1c]: https://github.com/er1c
  [@eatkins]: https://github.com/eatkins
  [@dwijnand]: https://github.com/dwijnand
  [@ckipp01]: https://github.com/ckipp01
  [@mdedetrich]: https://github.com/mdedetrich
  [@xuwei-k]: https://github.com/xuwei-k
  [@julienrf]: https://github.com/julienrf
  [@mkurz]: https://github.com/mkurz
  [@andrzejressel]: https://github.com/andrzejressel
  [@kevin-lee]: https://github.com/kevin-lee
  [@alexklibisz]: https://github.com/alexklibisz
  [@dongxuwang]: https://github.com/dongxuwang
  [@katlasik]: https://github.com/katlasik
  [@sideeffffect]: https://github.com/sideeffffect
  [7306]: https://github.com/sbt/sbt/pull/7306
  [7279]: https://github.com/sbt/sbt/pull/7279
  [7280]: https://github.com/sbt/sbt/pull/7280
  [7287]: https://github.com/sbt/sbt/pull/7287
  [7286]: https://github.com/sbt/sbt/pull/7286
  [7290]: https://github.com/sbt/sbt/pull/7290
  [7291]: https://github.com/sbt/sbt/pull/7291
  [7294]: https://github.com/sbt/sbt/pull/7294
  [7295]: https://github.com/sbt/sbt/pull/7295
  [7298]: https://github.com/sbt/sbt/pull/7298
  [7299]: https://github.com/sbt/sbt/pull/7299
  [7300]: https://github.com/sbt/sbt/pull/7300
  [7301]: https://github.com/sbt/sbt/pull/7301
  [7304]: https://github.com/sbt/sbt/pull/7304
  [7312]: https://github.com/sbt/sbt/pull/7312
  [7313]: https://github.com/sbt/sbt/pull/7313
  [7314]: https://github.com/sbt/sbt/pull/7314
  [7315]: https://github.com/sbt/sbt/pull/7315
  [7317]: https://github.com/sbt/sbt/pull/7317
  [7318]: https://github.com/sbt/sbt/pull/7318
  [io346]: https://github.com/sbt/io/pull/346
  [zinc1206]: https://github.com/sbt/zinc/pull/1206
  [zinc1209]: https://github.com/sbt/zinc/pull/1209

