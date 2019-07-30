  [ivy1]: http://ant.apache.org/ivy/history/2.3.0/ivyfile/conflicts.html
  [ivy2]: http://ant.apache.org/ivy/history/2.3.0/settings/conflict-managers.html
  [ivy3]: https://github.com/sbt/ivy/blob/2.3.0/src/java/org/apache/ivy/plugins/latest/LatestRevisionStrategy.java
  [maven1]: https://maven.apache.org/guides/introduction/introduction-to-dependency-mechanism.html
  [pronounce]: https://forvo.com/word/coursier/
  [coursier1]: https://get-coursier.io/docs/other-version-selection
  [coursier2]: https://github.com/coursier/coursier/blob/c9efac25623e836d6aea95f792bf22f147fa5915/doc/docs/other-version-handling.md
  [php1]: https://www.php.net/manual/en/function.version-compare.php
  [2959]: https://github.com/sbt/sbt/pull/2959
  [1284]: https://github.com/coursier/coursier/issues/1284

### dependency resolver

A dependency resolver, or package manager, is a program that determines a consistent set of modules based on a set of constraints provided by the user. The constraint specification would normally include the names of the modules and their version numbers. In JVM ecosystem, Maven modules are denoted with organization name (group id) as well. In addition there may be more constraints like version range, excluded modules, version overrides etc.

The three major categories of packaging are OS packages (Homebrew, Debian packages, etc), modules for specific programming languages (CPAN, RubyGem, Maven, etc), and application-specifc extensions (Eclipse plugins, IntelliJ plugins, VS Code extensions).

### semantics of a dependency resolver

As an initial approximation, we can think of module dependencies as a DAG (directed acyclic graph). This is called a dependency graph, or a "deps graph". Let's say we have two module dependencies:

- `a:1.0`, which depends on `c:1.0`
- `b:1.0`, which depends on `c:1.0` and `d:1.0`

<code>
+-----+  +-----+
|a:1.0|  |b:1.0|
+--+--+  +--+--+
   |        |
   +<-------+
   |        |
   v        v
+--+--+  +--+--+
|c:1.0|  |d:1.0|
+-----+  +-----+
</code>

By depending on both `a:1.0` and `b:1.0`, you get `a:1.0`, `b:1.0`, `c:1.0`, and `d:1.0`. This is just tree walking.

The situation might be more complicated if the transitive dependencies include a version range.

- `a:1.0`, which depends on `c:1.0`
- `b:1.0`, which depends on `c:[1.0,2)` and `d:1.0`

<code>
+-----+  +-----+
|a:1.0|  |b:1.0|
+--+--+  +--+--+
   |        |
   |        +-----------+
   |        |           |
   v        v           v
+--+--+  +--+------+ +--+--+
|c:1.0|  |c:[1.0,2)| |d:1.0|
+-----+  +---------+ +-----+
</code>

Or the transitive dependencies specify different versions:

- `a:1.0`, which depends on `c:1.0`
- `b:1.0`, which depends on `c:1.2` and `d:1.2`

Or the dependency includes exclusion rules:

- depend on `a:1.0`, which depends on `c:1.0`, but exclude `c:*`
- `b:1.0`, which depends on `c:1.2` and `d:1.2`

The exact rules governing how the user-specified constraints are interpreted vary from one dependency resolver to another. I call these rules the _semantics_ of the dependency resolvers.

Here are some of the semantics you might need to know:

- semantics of your own module (determined by the build tool you're using)
- semantics of the libraries that you're using (determined by the build tool the library author used)
- semantics of the modules that might use your module as a dependency (determined by your user's build tool)

### dependency resolvers in JVM ecosystem

As a maintainer of sbt, I come across the JVM ecosystem the most.

#### Maven's nearest-wins semantics

Upon a dependency conflict (that is multiple version candidates `d:1.0` and `d:2.0` are found for `d` within a deps graph), Maven uses [nearst-wins][maven1] strategy to resolve the conflicts:

> - _Dependency mediation_ - this determines what version of an artifact will be chosen when multiple versions are encountered as dependencies. Maven picks the "nearest definition". That is, it uses the version of the closest dependency to your project in the tree of dependencies. You can always guarantee a version by declaring it explicitly in your project's POM. Note that if two dependency versions are at the same depth in the dependency tree, the first declaration wins.
>   - "nearest definition" means that the version used will be the closest one to your project in the tree of dependencies. For example, if dependencies for A, B, and C are defined as
>     `A -> B -> C -> D 2.0` and `A -> E -> D 1.0`, then D 1.0 will be used when building A because the path from A to D through E is shorter. You could explicitly add a dependency to D 2.0 in A to force the use of D 2.0.

This means that many of the Java modules published using Maven were built based on nearst-wins semantics.

To demonstrate this, let's create a simple `pom.xml`:

<code>
<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
     xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
  <modelVersion>4.0.0</modelVersion>
  <groupId>com.example</groupId>
  <artifactId>foo</artifactId>
  <version>1.0.0</version>
  <packaging>jar</packaging>

   <dependencyManagement>
     <dependencies>
       <dependency>
         <groupId>com.typesafe.play</groupId>
         <artifactId>play-ws-standalone_2.12</artifactId>
         <version>1.0.1</version>
       </dependency>
     </dependencies>
   </dependencyManagement>
</project>
</code>

`mvn dependency:build-classpath` returns a resolved classpath. The notable part is that it returned `com.typesafe:config:1.2.0` even though Akka 2.5.3 depends transitively on `com.typesafe:config:1.3.1`.

`mvn dependency:tree` shows this visually:

<code>
[INFO] --- maven-dependency-plugin:2.8:tree (default-cli) @ foo ---
[INFO] com.example:foo:jar:1.0.0
[INFO] \- com.typesafe.play:play-ws-standalone_2.12:jar:1.0.1:compile
[INFO]    +- org.scala-lang:scala-library:jar:2.12.2:compile
[INFO]    +- javax.inject:javax.inject:jar:1:compile
[INFO]    +- com.typesafe:ssl-config-core_2.12:jar:0.2.2:compile
[INFO]    |  +- com.typesafe:config:jar:1.2.0:compile
[INFO]    |  \- org.scala-lang.modules:scala-parser-combinators_2.12:jar:1.0.4:compile
[INFO]    \- com.typesafe.akka:akka-stream_2.12:jar:2.5.3:compile
[INFO]       +- com.typesafe.akka:akka-actor_2.12:jar:2.5.3:compile
[INFO]       |  \- org.scala-lang.modules:scala-java8-compat_2.12:jar:0.8.0:compile
[INFO]       \- org.reactivestreams:reactive-streams:jar:1.0.0:compile
</code>

Many libraries are written in backward compatible way, but forward compatibility is not guaranteed with a few exceptions, so this seems horrifying.

#### Apache Ivy's latest-wins semantics

By default Apache Ivy uses a conflict manager with [latest-wins][ivy1] strategy ("latest-revision" to be specific) to resolve conflicts:

> If this container is not present, a default conflict manager is used for all modules.
The current default conflict manager is the "latest-revision" conflict manager.

Apache Ivy is the internal dependency resolver that's been used by sbt until sbt 1.3.x. sbt describes the above `pom.xml` in a slightly shorter way:

<scala>
ThisBuild / scalaVersion := "2.12.8"
ThisBuild / organization := "com.example"
ThisBuild / version      := "1.0.0-SNAPSHOT"

lazy val root = (project in file("."))
  .settings(
    name := "foo",
    libraryDependencies += "com.typesafe.play" %% "play-ws-standalone" % "1.0.1",
  )
</scala>

After entering sbt shell, type `show externalDependencyClasspath` to show the resolved classspath. It should show `com.typesafe:config:1.3.1`. It should also print the following warning:

<code>
[warn] There may be incompatibilities among your library dependencies; run 'evicted' to see detailed eviction warnings.
</code>

Running `evicted` task displays the following eviction report:

<code>
sbt:foo> evicted
[info] Updating ...
[info] Done updating.
[info] Here are other dependency conflicts that were resolved:
[info]  * com.typesafe:config:1.3.1 is selected over 1.2.0
[info]      +- com.typesafe.akka:akka-actor_2.12:2.5.3            (depends on 1.3.1)
[info]      +- com.typesafe:ssl-config-core_2.12:0.2.2            (depends on 1.2.0)
[info]  * com.typesafe:ssl-config-core_2.12:0.2.2 is selected over 0.2.1
[info]      +- com.typesafe.play:play-ws-standalone_2.12:1.0.1    (depends on 0.2.2)
[info]      +- com.typesafe.akka:akka-stream_2.12:2.5.3           (depends on 0.2.1)
</code>

In the latest-wins semantics, specifying `config:1.2.0` effectively means "give me 1.2.0 or above." This behaves a bit more reasonably than the nearest-wins since the transitive libraries are not downgraded, but you should run `evicted` task to check if the evictions look ok.

#### Coursier's latest-wins semantics

Before we get into the dependency resolution semantics of Coursier, a quick note about how to pronounce the stuff. It's kind of like [COURSE-yeah][pronounce] according to [Alex](https://twitter.com/alxarchambault/status/1156109836033171456).

Cool thing about Coursier is that there's a [version reconciliation][coursier1] page in the documentation that talks about the dependency resolution semantics.

> - Take the intersection of the input intervals. If it's empty (the intervals don't overlap), there's a conflict. If there are no input intervals, assume the intersection is `(,)` (interval matching all versions).
> - Then look at specific versions:
>   - Ignore the specific versions below the interval.
>   - If there are specific versions above the interval, there's a conflict.
>   - If there are specific versions in the interval, take the highest as result.
>   - If there are no specific versions in or above the interval, take the interval as result.

It says "take the highest", so it's a latest-wins semantics. We can confirm this using sbt 1.3.0-RC3 that internally uses Coursier.

<scala>
ThisBuild / scalaVersion := "2.12.8"
ThisBuild / organization := "com.example"
ThisBuild / version      := "1.0.0-SNAPSHOT"

lazy val root = (project in file("."))
  .settings(
    name := "foo",
    libraryDependencies += "com.typesafe.play" %% "play-ws-standalone" % "1.0.1",
  )
</scala>

Running `show externalDependencyClasspath` from sbt shell on sbt 1.3.0-RC3 returns `com.typesafe:config:1.3.1` as expected. The `evicted` report is the same too:

<code>
sbt:foo> evicted
[info] Here are other dependency conflicts that were resolved:
[info]  * com.typesafe:config:1.3.1 is selected over 1.2.0
[info]      +- com.typesafe.akka:akka-actor_2.12:2.5.3            (depends on 1.3.1)
[info]      +- com.typesafe:ssl-config-core_2.12:0.2.2            (depends on 1.2.0)
[info]  * com.typesafe:ssl-config-core_2.12:0.2.2 is selected over 0.2.1
[info]      +- com.typesafe.play:play-ws-standalone_2.12:1.0.1    (depends on 0.2.2)
[info]      +- com.typesafe.akka:akka-stream_2.12:2.5.3           (depends on 0.2.1)
</code>

#### side note: Apache Ivy's emulation of nearest-wins semantics?

When Ivy resolves a module out of a Maven repository, it puts `force="true"` attribute on the `ivy.xml` in Ivy cache when it translates from POM file. See for example `cat ~/.ivy2/cache/com.typesafe.akka/akka-actor_2.12/ivy-2.5.3.xml`:

<code>
  <dependencies>
    <dependency org="org.scala-lang" name="scala-library" rev="2.12.2" force="true" conf="compile->compile(*),master(compile);runtime->runtime(*)"/>
    <dependency org="com.typesafe" name="config" rev="1.3.1" force="true" conf="compile->compile(*),master(compile);runtime->runtime(*)"/>
    <dependency org="org.scala-lang.modules" name="scala-java8-compat_2.12" rev="0.8.0" force="true" conf="compile->compile(*),master(compile);runtime->runtime(*)"/>
  </dependencies>
...
</code>

The Ivy's [documentation][ivy2] says:

> The two "latest" conflict managers also take into account the force attribute of the dependencies. Indeed direct dependencies can declare a force attribute (see dependency), which indicates that the revision given in the direct dependency should be preferred over indirect dependencies.

My read is that `force="true"` was meant to override the latest-wins logic and emulate the nearest-wins semantics, but thankfully this never succeeded and we have latest-wins as demonstrated by the sbt 1.2.8 picking up `com.typesafe:config:1.3.1`.

We can still observe the effect of the `force="true"` when we use the _strict_ conflict manager, which seems broken.

<scala>
ThisBuild / conflictManager := ConflictManager.strict
</scala>

The problem is that strict conflict manager doesn't seem to prevent eviction. `show externalDependencyClasspath` happily returns `com.typesafe:config:1.3.1`. Related problem is that adding `com.typesafe:config:1.3.1`, which the strict conflict manager resolved back into the graph triggers a failure.

<scala>
ThisBuild / scalaVersion    := "2.12.8"
ThisBuild / organization    := "com.example"
ThisBuild / version         := "1.0.0-SNAPSHOT"
ThisBuild / conflictManager := ConflictManager.strict

lazy val root = (project in file("."))
  .settings(
    name := "foo",
    libraryDependencies ++= List(
      "com.typesafe.play" %% "play-ws-standalone" % "1.0.1",
      "com.typesafe" % "config" % "1.3.1",
    )
  )
</scala>

Here's how it looks like:

<code>
sbt:foo> show externalDependencyClasspath
[info] Updating ...
[error] com.typesafe#config;1.2.0 (needed by [com.typesafe#ssl-config-core_2.12;0.2.2]) conflicts with com.typesafe#config;1.3.1 (needed by [com.example#foo_2.12;1.0.0-SNAPSHOT])
[error] org.apache.ivy.plugins.conflict.StrictConflictException: com.typesafe#config;1.2.0 (needed by [com.typesafe#ssl-config-core_2.12;0.2.2]) conflicts with com.typesafe#config;1.3.1 (needed by [com.example#foo_2.12;1.0.0-SNAPSHOT])
</code>

### version ordering

We've been mentioning latest-wins semantics, which implies that two version strings could be ordered somehow. Thus, ordering of versions is a part of semantics.

#### Apache Ivy's version ordering

[A Javadoc comment][ivy3] says Ivy's comparator was inspired by PHP [version_compare][php1]:

> The function first replaces `_`, `-` and `+` with a dot `.` in the version strings and also inserts dots `.` before and after any non number so that for example '4.3.2RC1' becomes '4.3.2.RC.1'. Then it compares the parts starting from left to right. If a part contains special version strings these are handled in the following order: *any string not found in this list < dev < alpha = a < beta = b < RC = rc < # < pl = p*. This way not only versions with different levels like '4.1' and '4.1.2' can be compared but also any PHP specific version containing development state.

We can test the version ordering by writing a small function.

<scala>
scala> :paste
// Entering paste mode (ctrl-D to finish)

val strategy = new org.apache.ivy.plugins.latest.LatestRevisionStrategy
case class MockArtifactInfo(version: String) extends
    org.apache.ivy.plugins.latest.ArtifactInfo {
  def getRevision: String = version
  def getLastModified: Long = -1
}
def sortVersionsIvy(versions: String*): List[String] = {
  import scala.collection.JavaConverters._
  strategy.sort(versions.toArray map MockArtifactInfo)
    .asScala.toList map { case MockArtifactInfo(v) => v }
}

// Exiting paste mode, now interpreting.

scala> sortVersionsIvy("1.0", "2.0", "1.0-alpha", "1.0+alpha", "1.0-X1", "1.0a", "2.0.2")
res7: List[String] = List(1.0-X1, 1.0a, 1.0-alpha, 1.0+alpha, 1.0, 2.0, 2.0.2)
</scala>

#### Coursier's version ordering

The resolution semantics page on [GitHub][coursier2] contains a section about version ordering.

> Version ordering in coursier was adapted from Maven.
>
> To be compared, versions are splitted into "items"....
>
> To get items, versions are split at `.`, `-`, and `_` (and those separators are discarded), and at letter-to-digit or digit-to-letter switches.

To write a test, create a subproject with `libraryDependencies += "io.get-coursier" %% "coursier-core" % "2.0.0-RC2-6"`, and run `console`:

<scala>

sbt:foo> helper/console
[info] Starting scala interpreter...
Welcome to Scala 2.12.8 (OpenJDK 64-Bit Server VM, Java 1.8.0_212).
Type in expressions for evaluation. Or try :help.

scala> import coursier.core.Version
import coursier.core.Version

scala> def sortVersionsCoursier(versions: String*): List[String] =
     |   versions.toList.map(Version.apply).sorted.map(_.repr)
sortVersionsCoursier: (versions: String*)List[String]

scala> sortVersionsCoursier("1.0", "2.0", "1.0-alpha", "1.0+alpha", "1.0-X1", "1.0a", "2.0.2")
res0: List[String] = List(1.0-alpha, 1.0, 1.0-X1, 1.0+alpha, 1.0a, 2.0, 2.0.2)
</scala>

As it turns out, Coursier orders version number in a completely different way from Ivy.

If you've been taking advange of the permissive tag letters, this might create some confusion.

### version range

I usually avoid the use of version ranges, but they are used a lot in webjars, npm modules republished to Maven Central. An npm module would say something like `"is-number": "^4.0.0"`, which translates to `[4.0.0,5)`.

#### Apache Ivy's version range handling

In the following build, `angular-boostrap:0.14.2` depends on `angular:[1.3.0,)`.

<scala>
ThisBuild / scalaVersion  := "2.12.8"
ThisBuild / organization  := "com.example"
ThisBuild / version       := "1.0.0-SNAPSHOT"

lazy val root = (project in file("."))
  .settings(
    name := "foo",
    libraryDependencies ++= List(
      "org.webjars.bower" % "angular" % "1.4.7",
      "org.webjars.bower" % "angular-bootstrap" % "0.14.2",
    )
  )
</scala>

Using sbt 1.2.8, `show externalDependencyClasspath` yields `angular-bootstrap:0.14.2` and `angular:1.7.8`. Where did `1.7.8` come from? When Ivy sees a version range, it basically goes out to the Internet and find what it can get, sometimes using screenscraping.

This makes the build non-repeatable (you run the same build every few month, and you'd get different result).

#### Coursier's version range handling

Coursier's resolution semantics page on [GitHub][coursier2] says:

> #### Specific versions in interval are preferred
>
> If you depend on `[1.0,2.0)` and `1.4`, version reconciliation results in `1.4`. As there's a dependency on `1.4`, it is preferred over other versions in `[1.0,2.0)`.

This is promising.

<code>
sbt:foo> show externalDependencyClasspath
[warn] There may be incompatibilities among your library dependencies; run 'evicted' to see detailed eviction warnings.
[info] * Attributed(/Users/eed3si9n/.sbt/boot/scala-2.12.8/lib/scala-library.jar)
[info] * Attributed(/Users/eed3si9n/.coursier/cache/v1/https/repo1.maven.org/maven2/org/webjars/bower/angular/1.4.7/angular-1.4.7.jar)
[info] * Attributed(/Users/eed3si9n/.coursier/cache/v1/https/repo1.maven.org/maven2/org/webjars/bower/angular-bootstrap/0.14.2/angular-bootstrap-0.14.2.jar)
</code>

Using the same build with `angular-bootstrap:0.14.2`, `show externalDependencyClasspath` yields `angular-bootstrap:0.14.2` and `angular:1.4.7` as expected. This is an improvement over Ivy.

What's a bit more tricky if if there are multiple version ranges that do not overlap. Here is an example:

<scala>
ThisBuild / scalaVersion  := "2.12.8"
ThisBuild / organization  := "com.example"
ThisBuild / version       := "1.0.0-SNAPSHOT"

lazy val root = (project in file("."))
  .settings(
    name := "foo",
    libraryDependencies ++= List(
      "org.webjars.npm" % "randomatic" % "1.1.7",
      "org.webjars.npm" % "is-odd" % "2.0.0",
    )
  )
</scala>

Using sbt 1.3.0-RC3, `show externalDependencyClasspath` results to the following error:

<code>
sbt:foo> show externalDependencyClasspath
[info] Updating
https://repo1.maven.org/maven2/org/webjars/npm/kind-of/maven-metadata.xml
  No new update since 2018-03-10 06:32:27
https://repo1.maven.org/maven2/org/webjars/npm/is-number/maven-metadata.xml
  No new update since 2018-03-09 15:25:26
https://repo1.maven.org/maven2/org/webjars/npm/is-buffer/maven-metadata.xml
  No new update since 2018-08-17 14:21:46
[info] Resolved  dependencies
[error] lmcoursier.internal.shaded.coursier.error.ResolutionError$ConflictingDependencies: Conflicting dependencies:
[error] org.webjars.npm:is-number:[3.0.0,4):default(compile)
[error] org.webjars.npm:is-number:[4.0.0,5):default(compile)
[error]   at lmcoursier.internal.shaded.coursier.Resolve$.validate(Resolve.scala:394)
[error]   at lmcoursier.internal.shaded.coursier.Resolve.validate0$1(Resolve.scala:140)
[error]   at lmcoursier.internal.shaded.coursier.Resolve.$anonfun$ioWithConflicts0$4(Resolve.scala:184)
[error]   at lmcoursier.internal.shaded.coursier.util.Task$.$anonfun$flatMap$2(Task.scala:14)
[error]   at scala.concurrent.Future.$anonfun$flatMap$1(Future.scala:307)
[error]   at scala.concurrent.impl.Promise.$anonfun$transformWith$1(Promise.scala:41)
[error]   at scala.concurrent.impl.CallbackRunnable.run(Promise.scala:64)
[error]   at java.util.concurrent.ThreadPoolExecutor.runWorker(ThreadPoolExecutor.java:1149)
[error]   at java.util.concurrent.ThreadPoolExecutor$Worker.run(ThreadPoolExecutor.java:624)
[error]   at java.lang.Thread.run(Thread.java:748)
[error] (update) lmcoursier.internal.shaded.coursier.error.ResolutionError$ConflictingDependencies: Conflicting dependencies:
[error] org.webjars.npm:is-number:[3.0.0,4):default(compile)
[error] org.webjars.npm:is-number:[4.0.0,5):default(compile)
</code>

This is technically correct since these ranges do not overlap. sbt 1.2.8 would resolve this to `is-number:4.0.0`.

Since the version ranges come up frequently enough to be annoying, I am sending a pull request to Coursier to allow an additional latest-wins rules to pick the latest of the lower buonds. See [coursier/coursier#1284][1284].

### summary

The semantics of a dependency resolver determines the concrete classpath based on the user-specified dependency constraints. Typically the differences in the details manifest as different way the version conflicts are resolved.

- Maven uses nearest-wins strategy, which could downgrade transitive dependencies
- Ivy uses latest-wins strategy
- Coursier generally uses latest-wins strategy, but it's tries to enforce version range strictly
- Ivy's version range handling goes to the Internet, which makes the build non-repeatable
- Coursier orders version string completely differently from Ivy
