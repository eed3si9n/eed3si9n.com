  [6309]: https://github.com/sbt/sbt/pull/6309

sbt 1.1.0 で僕は統一スラッシュ構文を実装した。それから数年経った今日になって、古い sbt 0.13 でのシェル構文を廃止勧告するための pull request を送った。[#6309][6309]

成り行きとして、`build.sbt` のための旧構文も廃止勧告にするという[話題](https://twitter.com/dwijnand/status/1361425290182995969)が[出てきた](https://twitter.com/SethTisue/status/1361466421847330818)。

<blockquote class="twitter-tweet"><p lang="en" dir="ltr">will you also deprecate `scalacOptions in (Compile, console)` in *.sbt and *.scala files? I hope so</p>&mdash; Seth Tisue (@SethTisue) <a href="https://twitter.com/SethTisue/status/1361466421847330818?ref_src=twsrc%5Etfw">February 16, 2021</a></blockquote>

「統一」スラッシュ構文がそう名付けられたのはシェル構文とビルド定義構文を統一するからだ。そのため、シェルの旧構文を廃止勧告するならば、`skip in publish` や `scalacOptions in (Compile, console)` というふうに `in` を使う旧 `build.sbt` 構文も同時に廃止勧告するというのは理にかなっている。

`build.sbt` を統一スラッシュ構文へと変換する syntactic Scalafix rule をちゃちゃっと作ったのでここで紹介する - https://gist.github.com/eed3si9n/57e83f5330592d968ce49f0d5030d4d5

### 用法

プロジェクトを git で管理するか、バックアップを取ること。

<code>
$ cs install scalafix
$ export PATH="$PATH:$HOME/Library/Application Support/Coursier/bin"
$ scalafix --rules=https://gist.githubusercontent.com/eed3si9n/57e83f5330592d968ce49f0d5030d4d5/raw/7f576f16a90e432baa49911c9a66204c354947bb/Sbt0_13BuildSyntax.scala *.sbt project/*.scala
</code>

完全には正確じゃないが、手動で全部やるよりはマシだと思う。

### 今一体何を走らせたのか?

この書き換えルールは 1~3個の引数を受け取る `in` メソッドの呼び出しを `arg0 / arg1 / arg2 / lhs` という感じで書き換える。このルールは必ず `*.sbt` と sbt プラグインにのみ適用するべきであることに注意してほしい。例えば、`in` を使った ScalaTest とかに適用した場合もお構いなく `/` に変更するからだ。

semantic rule と違って syntactic rule はコードの形だけを見て機械的にルールを適用する。雑な IDE リファクター機能を考えることもできるし、非常に正確な正規表現だと考えることもできる。多分答えはその中間ぐらいだと思う。

### いくつかの適用例

<scala>
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
</scala>

僕が自分で書くより少し括弧が多い気がするが、変更そのものは正しいと思う。

### 既知の問題点

`contrabandFormatsForType in generateContrabands in Compile` というふうに `in` が連鎖する場合はうまく動作しない:

<scala>
-    contrabandFormatsForType in generateContrabands in Compile := ContrabandConfig.getFormats,
+    (Compile / contrabandFormatsForType in generateContrabands)(generateContrabands / contrabandFormatsForType) := ContrabandConfig.getFormats,
</scala>

これは手で `Compile / generateContrabands / contrabandFormatsForType` というふうに直してあげる必要がある。
