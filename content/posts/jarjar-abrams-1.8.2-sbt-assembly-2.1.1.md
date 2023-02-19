---
title:       "Jar Jar Abrams 1.8.2 and sbt-assembly 2.1.1"
type:        story
date:        2023-02-12
url:         /jarjar-abrams-1.8.2-sbt-assembly-2.1.1
tags:        [ "sbt" ]
---

  [jarjar-abrams28]: https://github.com/eed3si9n/jarjar-abrams/pull/28
  [jarjar-abrams29]: https://github.com/eed3si9n/jarjar-abrams/pull/29
  [jarjar-abrams30]: https://github.com/eed3si9n/jarjar-abrams/pull/30
  [@AlessandroPatti]: https://github.com/AlessandroPatti
  [@shanielh]: https://github.com/shanielh
  
Jar jar Abrams 1.8.2 and sbt-assembly 2.1.1 are released.

[Jar Jar Abrams](https://eed3si9n.com/jarjar-abrams) is an experimental extension to Jar Jar Links, intended to shade Scala libraries.

<!--more-->

## bug fixes

- Stops remapping inner class names by [@AlessandroPatti][@AlessandroPatti] in [#30][jarjar-abrams30]

## enhacements

- KeepProcessor: Processes files that are not in wildcard by [@shanielh][@shanielh] in [#28][jarjar-abrams28]
- Supports versioned classes by [@AlessandroPatti][@AlessandroPatti] in [#29][jarjar-abrams29]

sbt-assembly 2.1.1 upgrades the Jar Jar Abrams dependency to 1.8.2.
