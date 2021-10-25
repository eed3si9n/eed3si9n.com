---
title:       "syntactic Scalafix rule for unified slash syntax"
type:        story
date:        2021-02-16
draft:       false
promote:     true
sticky:      false
url:         /syntactic-scalafix-rule-for-unified-slash-syntax
aliases:     [ /node/381 ]
tags:        [ "sbt" ]
---

  [6309]: https://github.com/sbt/sbt/pull/6309

In sbt 1.1.0 I implemented unified slash syntax for sbt. Today I sent a pull request to deprecate the old sbt 0.13 shell syntax [#6309][6309].

Naturally, the topic of deprecating old syntax for `build.sbt` also [came](https://twitter.com/dwijnand/status/1361425290182995969) [up](https://twitter.com/SethTisue/status/1361466421847330818).

<blockquote class="twitter-tweet"><p lang="en" dir="ltr">will you also deprecate `scalacOptions in (Compile, console)` in *.sbt and *.scala files? I hope so</p>&mdash; Seth Tisue (@SethTisue) <a href="https://twitter.com/SethTisue/status/1361466421847330818?ref_src=twsrc%5Etfw">February 16, 2021</a></blockquote>

This is because "unified" slash syntax is called so because it unifies the shell syntax and the build syntax together. Thus, it makes sense to deprecate the old `build.sbt` syntax that uses `in` like `skip in publish` or `scalacOptions in (Compile, console)`, if we're deprecating the old shell syntax.

I was able to hack together a syntactic Scalafix rule to convert `build.sbt` to unified slash syntax - https://gist.github.com/eed3si9n/57e83f5330592d968ce49f0d5030d4d5

### usage

Make sure your project is on git or make a backup.

<code>
$ cs install scalafix
$ export PATH="$PATH:$HOME/Library/Application Support/Coursier/bin"
$ scalafix --rules=https://gist.githubusercontent.com/eed3si9n/57e83f5330592d968ce49f0d5030d4d5/raw/7f576f16a90e432baa49911c9a66204c354947bb/Sbt0_13BuildSyntax.scala *.sbt project/*.scala
</code>

It might not be precise, but it surely beats doing it by hand.

### what did I just run?

This rewrite rule changes any invocation of `in` method with one to three arguments, and turn them into `arg0 / arg1 / arg2 / lhs`. Please only point the rule to `*.sbt` files and sbt plugin code. If you point it to ScalaTest with `in`, it will change it to `/` too.

Unlike semantic rules, syntactic rules just looks at the shape of the code and applies the rules mechanically. You can think of it as a crude IDE refactor feature, or a precise regex. It's somewhere in between.

### some examples

```scala
diff --git a/sbt-pgp/src/main/scala-sbt-0.13/Compat.scala b/sbt-pgp/src/main/scala-sbt-0.13/Compat.scala
index cf70ab2..5214226 100644
--- a/sbt-pgp/src/main/scala-sbt-0.13/Compat.scala
+++ b/sbt-pgp/src/main/scala-sbt-0.13/Compat.scala
@@ -59,7 +59,7 @@ object Compat {
       signedArtifacts.value,
       pgpMakeIvy.value,
       resolverName = Classpaths.getPublishTo(publishTo.value).name,
-      checksums = (checksums in publish).value,
+      checksums = (publish / checksums).value,
       logging = ivyLoggingLevel.value
     )
   }
@@ -68,7 +68,7 @@ object Compat {
     Classpaths.publishConfig(
       signedArtifacts.value,
       Some(deliverLocal.value),
-      (checksums in publishLocal).value,
+      (publishLocal / checksums).value,
       logging = ivyLoggingLevel.value
     )
   }
diff --git a/build.sbt b/build.sbt
index 22de1a398..610a4d410 100644
--- a/build.sbt
+++ b/build.sbt
@@ -78,17 +78,17 @@ def commonBaseSettings: Seq[Setting[_]] = Def.settings(
   )(Resolver.ivyStylePatterns),
   testFrameworks += TestFramework("hedgehog.sbt.Framework"),
   testFrameworks += TestFramework("verify.runner.Framework"),
-  concurrentRestrictions in Global += Util.testExclusiveRestriction,
-  testOptions in Test += Tests.Argument(TestFrameworks.ScalaCheck, "-w", "1"),
-  testOptions in Test += Tests.Argument(TestFrameworks.ScalaCheck, "-verbosity", "2"),
-  javacOptions in compile ++= Seq("-Xlint", "-Xlint:-serial"),
+  (Global / concurrentRestrictions) += Util.testExclusiveRestriction,
+  (Test / testOptions) += Tests.Argument(TestFrameworks.ScalaCheck, "-w", "1"),
+  (Test / testOptions) += Tests.Argument(TestFrameworks.ScalaCheck, "-verbosity", "2"),
+  (compile / javacOptions) ++= Seq("-Xlint", "-Xlint:-serial"),
   Compile / doc / scalacOptions ++= {
     import scala.sys.process._
     val devnull = ProcessLogger(_ => ())
     val tagOrSha = ("git describe --exact-match" #|| "git rev-parse HEAD").lineStream(devnull).head
     Seq(
       "-sourcepath",
-      (baseDirectory in LocalRootProject).value.getAbsolutePath,
+      (LocalRootProject / baseDirectory).value.getAbsolutePath,
       "-doc-source-url",
       s"https://github.com/sbt/sbt/tree/$tagOrSha€{FILE_PATH}.scala"
     )
```

It puts more parentheses than I'd put sometimes, but these changes all look ok.

### known issue

It does not handle chained `in` like `contrabandFormatsForType in generateContrabands in Compile`:

```scala
-    contrabandFormatsForType in generateContrabands in Compile := ContrabandConfig.getFormats,
+    (Compile / contrabandFormatsForType in generateContrabands)(generateContrabands / contrabandFormatsForType) := ContrabandConfig.getFormats,
```

You'd have to fix this manually: `Compile / generateContrabands / contrabandFormatsForType`
