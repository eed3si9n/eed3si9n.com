---
title:       "ifdef 0.4.0"
type:        story
date:        2024-12-30
url:         /ifdef-0.4.0
tags:        [ "scala" ]
---

`@ifdef` is a Scala compiler plugin that implements conditional compilation in Scala. ifdef 0.4.0 supports Scala JVM, JS and Native.

| Scala Version | JVM | JS (1.x) |  Native (0.5.x) |  sbt plugin |
| ------------- | :-: | :------: | :---------: | :---------: |
| 3.x           | ✅  |   ✅     |    ✅     |    ✅     |
| 2.13.x        | ✅  |   ✅     |     ✅      |    n/a     |
| 2.12.x        | ✅  |   ✅     |     ✅      |    ✅     |

<!--more-->

### setup

Put this in `project/plugins.sbt`:

```scala
addSbtPlugin("com.eed3si9n.ifdef" % "sbt-ifdef" % "0.4.0")
```

Source is available at https://github.com/eed3si9n/ifdef

### new in 0.4.0

- Fixes typo in the key name `ifDefDeclarations` (was `ifDefDeclations`)
- Cross publishes to sbt 2.0.0-M3

### conditional compilation

Same as [ifdef 0.3.0](/ifdef-0.3.0-conditional-compilation-in-scala), 0.4.0 implements two declarations out of box:
1. build configuration names: `compile`, `test`
2. scalaBinaryVersion: e.g. `scalaBinaryVersion:3`

These should cover the most common conditional compilation needs, but you can customize it by using `Compile / ifDefDeclarations` key.

### reference

- [conditonal compilation in Scala](/ifdef-0.3.0-conditional-compilation-in-scala) (ifdef 0.3.0)
- [ifdef in Scala via pre-typer processing](/ifdef-in-scala-via-pre-typer-processing) (ifdef 0.2.0)
- [ifdef macro in Scala](/ifdef-macro-in-scala) (ifdef 0.1.0)
