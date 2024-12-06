---
title:       "december adventure 2024"
type:        story
date:        2024-12-03
url:         /december-adventure-2024
---

I'm going to try to work on something small everyday during december. see the original [December Adventure](https://eli.li/december-adventure).

my goal: work on sbt 2.x, other open source like sbt 1.x and plugins, or some post on this site, like music or recipe.

<a id="#5"></a>
### 2024-12-05

my two cents on compilers: compilers should be silent if it did exactly what was told. any warnings should be actionable such that the user can get rid of the warning somehow. `-Xmigration` notices might be an exception. I feel like I've been saying this for [years](https://github.com/scala/scala-dev/issues/513#issuecomment-402602751).

<!--
https://github.com/scala/bug/issues/12961#issuecomment-1971224874
-->

as a low effort exploration, I decided to try the next Scala 3.x, Scala 3.6.2-RC3. unfortunately the compilation failed under `-Xfatal-warnings` because Scala 3.6.2-RC3 decided to display some warnings:

```scala
[warn] -- Warning: /xxx/sbt/protocol/src/main/contraband-scala/sbt/protocol/codec/SettingQuerySuccessFormats.scala:14:91
[warn] 14 |      val value = unbuilder.readField[sjsonnew.shaded.scalajson.ast.unsafe.JValue]("value")
[warn]    |                                                                                           ^
[warn]    |Given search preference for sjsonnew.JsonReader[sjsonnew.shaded.scalajson.ast.unsafe.JValue] between alternatives
[warn]    |  (SettingQuerySuccessFormats.this.JValueFormat :
[warn]    |  sjsonnew.JsonFormat[sjsonnew.shaded.scalajson.ast.unsafe.JValue])
[warn]    |and
[warn]    |  (SettingQuerySuccessFormats.this.JValueJsonReader :
[warn]    |  sjsonnew.JsonReader[sjsonnew.shaded.scalajson.ast.unsafe.JValue])
[warn]    |will change.
[warn]    |Current choice           : the first alternative
[warn]    |New choice from Scala 3.7: the second alternative
[error] No warnings can be incurred under -Werror (or -Xfatal-warnings)
[warn] two warnings found
[error] one error found
```

so in Scala 3.6 givens search prioritization is going to change, and we're using compiler to announce this? setting aside the change itself, I think these "FYI - something WILL change" notification should go to `-Xmigration:3.5.0`. if anyone uses Scala 3.x for a library or an app, they'll look at this warning every time they compile the code. I submitted [scala/scala3#22153](https://github.com/scala/scala3/issues/22153) to file this as a bug.

sent PR [#7928](https://github.com/sbt/sbt/pull/7928) to update the Scala CLA checker URL to <https://contribute.akka.io/contribute/cla/scala/check/>. note that the checker is hosted by Lightbend, Inc. dba Akka, but the CLA signs the rights away to EPFL for sbt code.

addressed one of review comments, from last night's URI changes and landed [#7927](https://github.com/sbt/sbt/pull/7927).

<!-- more -->

<a id="#4"></a>
### 2024-12-04
sent a PR [#7927](https://github.com/sbt/sbt/pull/7927).

`java.net.URL` infamously calls out to the network to perform `equals`, so likely we should avoid it for keys and data types that might be used in caching. thankfully not too many keys are URLs so I changed them all to URI.

related, I cherry picked a commit from a dormant PR that turns license information into a data type, as opposed to a tuple of `(String, URL)`. I had a few backward compatibility suggestions in the PR, and I just implemented the suggestions myself.

<a id="#3"></a>
### 2024-12-03

went skating in the morning before work. 8.25 inch + AF-1 still feels heavy compared to previous setups. the temperature was like 3C/37F going to 4C/39F. initially it was a bit cold, so I warmed up by pushing around the park then tictac, switch push, awkward penguin walks and monster walks on smooth surface. see Mike Osterman's [How to Monster Walk](https://www.youtube.com/watch?v=kDob9qNPTW4).

| truck                       | weight |
|-----------------------------|-------:|
| Tensor Aluminium 8"         |   361 g |
| Independent Stage 11 Hollow |   [351 g](https://nhsskatedirect.com/products/stage-11-hollow-silver-ano-red-standard-skateboard-trucks-independent?variant=45317833392285) |
| Ace AF-1 44 | [393 g](https://www.skatedeluxe.com/en/p/ace-x-carhartt-wip-44-af1-truck-carhartt-orange-silver-8-25-2-pack_p173877#&gid=1&pid=1) |

the above chart illustrates why AF-1 feels heavier to me. on the positive side, I'm exploring non-ollie tricks too so I should keep skating this setup a bit more.

no night hacking today, but I'll document one of sbt 2.x bug fix that I implemented on day 1.

a couple months ago xuwei-k reported [#7738](https://github.com/sbt/sbt/issues/7738). sbt has a semi-documented source-dependencies feature, and he's found a bug in sbt 2.x which shows the project resolution doesn't work:

```
[info] welcome to sbt 2.0.0-M2 (Eclipse Adoptium Java 21.0.4)
[info] loading project definition from /home/runner/work/sbt-2-ProjectRef/sbt-2-ProjectRef/project
java.lang.RuntimeException: Invalid build URI (no handler available): file:/home/runner/work/sbt-2-ProjectRef/sbt-2-ProjectRef/a1/a1/
```

to debug this I put in `println(...)` in a bunch of places in [Load.scala](https://github.com/sbt/sbt/blob/bc69030e58d9790065b72f9c90586c63bd293373/main/src/main/scala/sbt/internal/Load.scala). it turned out that the problem was caused by the detection of whether a subproject is root project or not.

in Yoshida-san's repro `a/build.sbt` contained:

```scala
val a1 = (project in file("."))
```

so `ProjectRef(file("a1"), "a1")` should have been resolved to the root project of the `{file:/home/runner/work/sbt-2-ProjectRef/sbt-2-ProjectRef/a1}` build. this is one of the buggy lines:

```scala
-    val (root, nonRoot) =
-      rawProjects.partition(_.base.getCanonicalFile() == projectBase.getCanonicalFile())
```

in the above, `projectBase` would have the absolute path of the build, and `_.base` would be the base directory passed in by the user `file(".")`. the problem is that for the source dependency situation, `projectBase` is not the current directory of the sbt session. so `file(".").getCanonicalFile()` becomes cwd (`/home/runner/work/sbt-2-ProjectRef/sbt-2-ProjectRef/`), which doesn't match `projectBase` (`/home/runner/work/sbt-2-ProjectRef/sbt-2-ProjectRef/a1/`)

the fix I sent in [#7925](https://github.com/sbt/sbt/pull/7925) was to evaluate the base directory relative to `projectBase`, and then compare the `getCanonicalFile()`.

```scala
+  def isRootPath(value: File, projectBase: File): Boolean =
+    projectBase.getCanonicalFile() == IO.resolve(projectBase, value).getCanonicalFile()

....

+ val (root, nonRoot) = rawProjects.partition(p => isRootPath(p.base, projectBase))
```

<a id="#2"></a>
### 2024-12-02

sent [Artifact publishing proposal](https://github.com/scalacenter/advisoryboard/pull/168) PR to Scala Center. not going to repeat the content here, but there's been a number of changes to the landscape of publishing, but the solutions are worked on independently by the build tool silos, so I've been thinking it would be useful to consolidate the effort. this could start with basic things like generating correct `ivy.xml` and `pom.xml`, but also include more recent developments like bill-of-materials (BOM) support.

released [sbt-jupiter-interface 0.13.3](https://github.com/sbt/sbt-jupiter-interface/releases/tag/v0.13.3), featuring a bug fix contributed by Li Haoyi. sbt defines an interface for test frameworks, and sbt-jupiter-interface is an implementation for JUnit 5, not to be confused with Jupyter notebook.

worked on [december mixtape](/2024.12-mixtape/) at night. 3h assortment of electronica for taking a walk or skating.

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
