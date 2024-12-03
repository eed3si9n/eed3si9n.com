---
title:       "december adventure 2024"
type:        story
date:        2024-12-02
url:         /december-adventure-2024
---

I'm going to try to work on something small everyday during december. see the original [December Adventure](https://eli.li/december-adventure).

my goal: work on sbt 2.x, other open source like sbt 1.x and plugins, or some post on this site, like music or recipe.

<a id="#2"></a>
### 2024-12-02

sent [Artifact publishing proposal](https://github.com/scalacenter/advisoryboard/pull/168) PR to Scala Center. not going to repeat the content here, but there's been a number of changes to the landscape of publishing, but the solutions are worked on independently by the build tool silos, so I've been thinking it would be useful to consolidate the effort. this could start with basic things like generating correct `ivy.xml` and `pom.xml`, but also include more recent developments like bill-of-materials (BOM) support.

released [sbt-jupiter-interface 0.13.3](https://github.com/sbt/sbt-jupiter-interface/releases/tag/v0.13.3), featuring a bug fix contributed by Li Haoyi. sbt defines an interface for test frameworks, and sbt-jupiter-interface is an implementation for JUnit 5, not to be confused with Jupyter notebook.

worked on [december mixtape](/2024.12-mixtape/) at night. 3h assortment of electronica for taking a walk or skating.

<!-- more -->

<a id="#1"></a>
### 2024-12-01

looking at sbt 2.x bugs that's been reported against 2.0.0-M2.

[#7723](https://github.com/sbt/sbt/issues/7723) reported by xuwei-k (Kenji Yoshida). it says that on sbt 2.x you get a compiler warning during load "Failed to parse -Wconf configuration: cat=unused-nowarn:s". first, this indicates that Scala 3.3.x or 3.5.x isn't really compatible with Scala 2.x's `-Wconf` flag. the flag was ported, but the category part is completely different in Scala 3. to unwind why sbt 1.x even has this flag,

1. in 2020, we observed [#6161](https://github.com/sbt/sbt/issues/6161) "a pure expression does nothing" warning because Scala 2.12.12 started to be more strict about detecting pure expressions
2. as a workaround in 2021, I added `(??? :@scala.annotation.nowarn("cat=other-pure-statement"))` around build.sbt macro expansions
3. during 1.5.0 RC-1, we observed that in some cases `nowarn` itself would cause additional warning [#6398](https://github.com/sbt/sbt/issues/6398) "@nowarn annotation does not suppress any warnings"
4. as a workaround to the workaround, `"-Wconf:cat=unused-nowarn:s"` was added in [#6403](https://github.com/sbt/sbt/pull/6403)

given that Scala 3.x hasn't started to warn about pure expressions, I can remove the workaround, which is what I did today in [#7924](https://github.com/sbt/sbt/pull/7924).

earlier during the day, I was staring at VisualVM heap drump. Adrien Piquerez reported it in one of his pull requests, but seeing `ScopedKey(...)` occupies 8% of the heap was jarring. I didn't remember that he's already tried interning it and saw not much difference, so I tried it and saw not much difference. perf optimization is sometimes like that.
