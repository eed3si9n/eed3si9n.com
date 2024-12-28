---
title:       "december adventure 2024"
type:        story
date:        2024-12-27
url:         /december-adventure-2024
---

  [3.6.2]: https://www.scala-lang.org/news/3.6.2

I'm going to try to work on something small everyday during december. see the original [December Adventure](https://eli.li/december-adventure).

my goal: work on sbt 2.x, other open source like sbt 1.x and plugins, or some post on this site, like music or recipe.

<a id="27"></a>
### 2024-12-27
sent [sbt/website#1273](https://github.com/sbt/website/pull/1273) to update the migration guide.

going back to [day 6](#6) / [day 7](#7), I wanted to optimize the sbtn JSON-RPC traffic being full of terminal queries by JLine. sent [#7977](https://github.com/sbt/sbt/pull/7977) to cache the terminal capability, which hopefully should be ok.

#### skating notes
went skating in the evening after a long time. it wasn't for lack of trying, but there's been slushy snow on my goto spot. it was dry today and also the temperature was nice 5C/41F. I was pretty much skating the whole time with Vermont flannel, and occasional Marmot shell.

I moved from smooth surface to rougher concrete a bit halfway into the session, and the board feel improved significantly. it might be partly tails getting scraped you get a fresh layer. another hypothesis I have is that something about the surface forces my toes to grip the board, which improves the board feel? as you get better at ollie, the side of the front shoe supposedly would get damaged, but the side of mine is as good as new. however, the bottom is getting damaged and pieces of rubbers are coming off, so I think it's some progress. I did attempt the foot sliding once or twice midair too.

<!--more-->

<a id="26"></a>
### 2024-12-26
tying up some loose ends from yesterday. back published [sbt-buildinfo 0.13.1](https://github.com/sbt/sbt-buildinfo/releases/tag/v0.13.1) for sbt 2.0.0-M3 after working around the URL to URI changes that were introduced in M3.

released [tree-sitter-scala 0.23.4](https://github.com/tree-sitter/tree-sitter-scala/releases/tag/v0.23.4), which includes Scala 3.6.x syntax changes.

merged João's [PR-on-PR](https://github.com/eed3si9n/sbt-native-packager/pull/1) onto [sbt-native-packager#1647](https://github.com/sbt/sbt-native-packager/pull/1647), which fixed all but one test failures, and updated the scripted tests to use glob expression. sbt-native-packager PR is now green.

<a id="25"></a>
### 2024-12-25
back published sbt-vimquit 0.1.1 using sbt 2.0.0-M3.

updated [sbt-native-packager#1647](https://github.com/sbt/sbt-native-packager/pull/1647), which is still faling scripted tests. also sent a draft PR [sbt-buildinfo#213](https://github.com/sbt/sbt-buildinfo/pull/213), which is also failing scripted tests.

<a id="24"></a>
### 2024-12-24
made vegan meatless meat sauce. [basic recipe](/recipes/meatless-meat-sauce.html) + carrots + biber salçası (Aleppo pepper paste) + gochugaru (Korean pepper flakes), which are both flavorful but very mild.

sent [sbt-assembly#545](https://github.com/sbt/sbt-assembly/pull/545) to cross build against sbt 2.0.0-M3, and also to try the new glob expression for sbt 1.x / 2.x testing, undoing some of the custom tasks that I added to cross build for 2.0.0-M2.

<a id="23"></a>
### 2024-12-23
went to 唐家食府 (M & T Restaurant) in Fairfield, NJ for the first time with a flexi-vegetarian friend. it's authentic Shandong cuisine. my mostly-vegeratian friend likes their spicy fried string beans (干煸四季豆), and it was quite good actually.

we also ordered shimp dumpings, tomato and egg drop soup (customized to add dumpings), and fish fillet in chili oil. the soup was too large for two, but I enjoyed it. in terms of of the cuisine, Shandong cuisine seems to use a lot of garlic, and influenced partly by Sichuan, and also a lot of sea food, so reminds be a bit of Shanghai as well. I'd love to go back and try different items.

<a id="22"></a>
### 2024-12-22
released [Zinc 1.10.7](https://github.com/sbt/zinc/releases/tag/v1.10.7) and [sbt 1.10.7](/sbt-1.10.7). writing good release note is work.

to workaround the Coursier perf regression on the new BOM-respecting resolution, I've sent [sbt-coursier#545](https://github.com/coursier/sbt-coursier/pull/545) so we can toggle the behavior from sbt side. this is then exposed as `csrMavenDependencyOverride`, which is set to `false` by default.

<a id="21"></a>
### 2024-12-21
during the day, fixed the sbt 2.x documentation whose navigation had broken recently. this seemed to be a known mdbook issue where the theme file and the mdbook version had drifted, so I had to manually update the theme file, which implements globalization support.

sent [#7968](https://github.com/sbt/sbt/pull/7968) to fix the glob support in scripted. it doesn't really make sense, but apparently some scripted tests use absolute path, so that required slightly different glob construction.

started releasing a few modules in preparation for an sbt 1.10.x release.

<a id="20"></a>
### 2024-12-20
there were some review comments re: [#7966](https://github.com/sbt/sbt/pull/7966) on Windows, so I pulled out my Lenovo Ideapad S130 for testing. as far as I can tell the batch script worked ok.

afterwards, I was looking into some tree-sitter-scala issues unsuccessfully, like adding support for lambda expression with parenthesis around the parameter. implementing the parser itself is not too difficult, but I think the problem is that there's similar-looking syntax such that adding it would break other parsers.

<a id="19"></a>
### 2024-12-19
at the outer most layer, `sbt` runner is a shell script, and sometimes the features and bugs appear in that layer. tonight I looked into a few issues related to `sbt`'s working directory check, which confirms if the user wants to continue when `sbt` is launched a directory without `build.sbt` file. for most users, this feature is not enabled.

the reason why it's not enabled by default in most cases is because `sbt` reads default options from `sbtopts` file that ships with the installer, and in the installer currently contains:

```
-create-sbt
```

there are a number of issues related to this.

1. `-create-sbt` as option name isn't great
2. there's no clear mechanism for people to opt into this feature
3. apparently this mechanism could get triggered for `sbt --script-version`
4. we shouldn't block for input

I sent [#7966](https://github.com/sbt/sbt/pull/7966), which does the following:

1. remove `-create-sbt` from the default `sbtopts` file, so everyone would get the feature
2. rename the option to `--allow-empty`, like git
3. to opt out again, users can create `$XDG_CONFIG_HOME/sbt/sbtopts` (or `%LOCALAPPDATA%\sbt\sbtconfig.txt` on Windows)
4. when `sbt` is called in a directory without `build.sbt`, and a non-new comand is about to be invoked, print an error and exit

<a id="18"></a>
### 2024-12-18

see [back publishing actually](back-publishing-actually.md).

#### skating notes
went skating in the morning. in the past weeks, I've been mostly skating on relatively smooth surface like volleyball court since the park is mostly empty. I couldn't pop the ollie straight, so moved to the bleacher area where the surface is rougher concrete. at first I could not do stationary ollie. but eventually I got the hang of it, and the board started popping better on asphalt.

one hypothesis is that my stance is based on visual cue from the deck, but I should reproduce the stance I'd take on 8 inch deck, ergonomically. another hypothesis is that popping on rough surface scrapes the flattened wood, and fresher grain becomes available. or it's just timing.

<a id="17"></a>
### 2024-12-17

#### sbt 2.0.0-M3

released [sbt 2.0.0-M3](/sbt-2.0.0-M3). beside small code adjustments between sbt and Zinc repos, most of the work was organizing and writing up the release notes.

there's one I publish on GitHub that includes most of the pull requests, and another that I publish on this site that focuses on what the users would see, which includes upgrade instruction, more details on some of the changes etc.

#### skating notes
went skating in the morning. some breakthrough with AF-1/8.25. if I crouch, and while crouched down extend both arms like like wings, and then jump, I could pop 9 out of 10 times stationary. it was so consistent, I tried fakie ollie (moving backwards), and I sorted of landed it after a few attempts. spreading the arms forces body axis to be vertical?

this is a thought I've had for nth times, but to ollie, you need normal vector (ground reaction force), which means you need to put pressure on the front wheel and release it.

<a id="16"></a>
### 2024-12-16

#### merge 1.10.x continued
addressed a few review comments on [#7950](https://github.com/sbt/sbt/pull/7950). thanks reviewers!

#### release note
we recently in-source lm module into sbt/sbt, which makes the git history somewhat complicated. I asked chatgpt how to get a diff between two versions, exclude commits from existing tag, and filter by date, and here's what we came up with:

```bash
git log v2.0.0-M2..develop --since 2024-10-04 --not 1.10.x --reverse
```

I might just use GitHub's generate relese note button, but I'll have some head start.

#### scala-sbt.org update
there was an odd caching bug with the scala-sbt.org it seems, so I decided to update Docusaurus to the latest. since sbt 2.x docs adopted mdBooks, there's no real benefit to using Docusaurus to overcome some of the buggy behaviors it has exhibited.

<a id="15"></a>
### 2024-12-15

#### mappings
looked at one of draft PRs by João Ferreira [#7939](https://github.com/sbt/sbt/pull/7939), which port `Mapper` functions to create `(HashedVirtualFileRef, String)` version. the test needed to be updated, so I created a new branch and landed it as [[2.x] Add Mapper that returns VirtualFile based mappings, take 2](https://github.com/sbt/sbt/pull/7949).

#### merge 1.10.x
sent a PR to merge 1.10.x into develop branch - [#7950](https://github.com/sbt/sbt/pull/7950). also sent a PR to merge 1.10.x into develop branch for Zinc - [zinc#1515](https://github.com/sbt/zinc/pull/1515).

#### skating notes
went skating in the evening. around 3C/38F, and the big park was mostly empty except for people walking their dog. I try to incorporate switch pushing into warm up. so I'm ok at pushing. switch tictac is a whole different story. generally, I'm horrible at lifting tail (switch nose). I tried switch tictac today, and ended up slipping and falling (no injury), likely because I'm tilting the body axis.

back to ollie, which is still more difficult on current setup. one thing that crossed my mind today is that AF-1 is heavy, but maybe the shape of 8.25 Habitat twin tail is a contributing factor. compared to other decks like Chocolate, I feel like 8.25 Habitat one has steeper kick.

<a id="14"></a>
### 2024-12-14
#### SIP-58 Named tuples support, continued
got a review on [tree-sitter-scala#446](https://github.com/tree-sitter/tree-sitter-scala/pull/446) by Anton:
> I think we also need a modified case_class_pattern with the named arguments: <https://docs.scala-lang.org/sips/named-tuples.html#pattern-matching-with-named-fields-in-general>

so implemented the suport for the named tuple case class pattern.

```javascript
    case_class_pattern: $ =>
      seq(
        field("type", choice($._type_identifier, $.stable_type_identifier)),
        "(",
        choice(
          field("pattern", trailingCommaSep($._pattern)),
          field("pattern", trailingCommaSep($.named_pattern)),
        ),
        ")",
      ),
```

#### mappings
there's a key in sbt 1.x called `mappings`, `Seq[(File, String)]`, which is sequence of file name and its path inside a JAR:

```scala
val mappings = taskKey[Seq[(File, String)]]("Defines the mappings from a file to a path, used by packaging, for example.").withRank(BTask)
```

I spent the last december describing how problematic `java.io.File` is for remote caching. [sbt 2.x remote cache](/sbt-remote-cache/) has a full write-up, but the problem is that it captures absolute paths unnecessarily, and doesn't have content hash, to simultaneously too much and not enough.

```scala
val mappings = taskKey[Seq[(HashedVirtualFileRef, String)]]("Defines the mappings from a file to a path, used by packaging, for example.").withRank(BTask)
```

João Ferreira has been highlighting some of the UX challenges with sbt 2.0.0-M2, and suggested that we might revert it back to `Seq[(File, String)]`. that might make the migration easier, but I'm concerned if that would hold sbt 2.x back. many of the tasks that deals with deployment uses `mappings`. if we used `File`, those tasks would likely remain to use `File`, which can't be cached as-is. on the other hand, if we used `HashedVirtualFileRef`, the task results would be cachable.

#### java.home problem
as I was looking at a draft PR [#7939](https://github.com/sbt/sbt/pull/7939) by João, which failed a test unexpectedly, so I pulled it on my machine to examine. after some debugging, I realized that the problem is:

```bash
java.io.IOException: Cannot run program "/Users/xxx/.sdkman/candidates/java/zulu8.76.0.17-ca-jdk8.0.402-macosx_aarch64/zulu-8.jdk/Contents/Home/jre/bin/javac"
```

note `jre/bin/javac`. JRE doesn't have `javac`. this is happening because a few places in the code we are passing into `sys.props("java.home")` as `javaHome`. according to [System Properties](https://docs.oracle.com/javase/tutorial/essential/environment/sysprop.html), `java.home` points to:

> Installation directory for Java Runtime Environment (JRE)

I sent [#7948](https://github.com/sbt/sbt/pull/7948) to change `javaHome` in the failing test to the JDK path instead.

```scala
  lazy val javaHome: Path =
    if sys.props("java.home").endsWith("jre") then Paths.get(sys.props("java.home")).getParent()
    else Paths.get(sys.props("java.home"))
```

#### skating notes
went skating during the day around 0C/32F. with Patagonia retro fleece I looked like a pollar bear, but was comfortable the whole time, partly because there weren't much wind.

<a id="13"></a>
### 2024-12-13
released [Giter8 0.17.0](https://github.com/foundweekends/giter8/releases/tag/v0.17.0) after confirming the fix from yesterday with 0.17.0-RC1. [#7947](https://github.com/sbt/sbt/pull/7947) updates the sbt-giter8-resolver to 0.17.0.

#### SIP-58 Named tuples support
going back to the [Scala 3.6.2][3.6.2] changes, I sent [tree-sitter-scala#446](https://github.com/tree-sitter/tree-sitter-scala/pull/446) to add named tuples support.

Scala example looks like this:

```scala
object O:
  type A = (name: String, age: Int)
```

tree-sitter-scala changes are:

```javascript
/*
 * NameAndType       ::=  id ':' Type
 */
name_and_type: $ =>
  prec.left(
    PREC.control,
    seq(
      field("name", $._identifier),
      ":",
      field("type", $._param_type),
    ),
  ),

named_tuple_type: $ => seq(
  "(",
  trailingCommaSep1($.name_and_type),
  ")",
),
```

there's also named tuple patterns, which seems useful:

```scala
$ scala -language:experimental.namedTuples

scala> case class City(zip: Int, name: String, population: Int)
// defined case class City

scala> val c = City(zip = 7030, name = "Hoboken", population = 57000)
val c: City = City(7030,Hoboken,57000)

scala> c match
     |   case c @ City(name = "Hoboken") => c.population
     |
val res0: Int = 57000
```

in the above we're passing in only the `name` to match against the `City` case class.

#### E205 given search preference warning

also speaking of Scala 3.6, my humble [scala3#22189](https://github.com/scala/scala3/pull/22189), which we implemented on [day 10](#10) to improve the warning message has landed.

<a id="12"></a>
### 2024-12-12
sent [giter8#935](https://github.com/foundweekends/giter8/pull/935) to fix the 'SLF4J: Failed to load class "org.slf4j.impl.StaticLoggerBinder"' issue.

SLF4J highlights the dynamic nature of JVM languages like Java and Scala. even though these languages have static type system, at the point of deployment, we swap out the JARs and depending on what's on the classpath, some function calls behavior would change. in other words, classpath acts as a global variable. combine that with the trend of automatic version updates, people can update the dependency libraries without ever having to run them on their own machine or reading the release notes.

here's a test I added with the help from chatgpt to switchout stderr:

```scala
  test("log scala/scala-seed.g8") {
    val (r, err) = withErr {
      IO.withTemporaryDirectory { dir =>
        launcher.run(Array("scala/scala-seed.g8", "--name=hello"), dir)
        assert((dir / "hello" / "build.sbt").exists)
      }
    }
    assert(!err.contains("SLF4J"))
  }

  def withErr[A1](f: => A1): (A1, String) = {
    val originalErr           = System.err
    val byteArrayOutputStream = new ByteArrayOutputStream()
    val inMemoryPrintStream   = new PrintStream(byteArrayOutputStream)
    val result =
      try {
        System.setErr(inMemoryPrintStream)
        val r = f
        inMemoryPrintStream.flush()
        r
      } finally {
        System.setErr(originalErr)
      }
    (result, byteArrayOutputStream.toString)
  }
```

<a id="11"></a>
### 2024-12-11
continuing with the [Scala 3.6.2][3.6.2] theme. anytime Scala syntax changes are introduced, there are sometimes period of adjustment for development tooling. then it dawned on me that it's not someone else's problem since I maintain tree-sitter-scala with others. see [fast Scala 3 parsing with tree-sitter](/fast-scala3-parsing-with-tree-sitter/) post from 2022.

in general, humans are remarkably good at skimming through something without appreciating the point of something. my process of working through something is to get my hands dirty and create some form of output. what better way to familiarize myself with the syntax changes than reimplemting them myself in native code (tree-sitter generates C).

#### SIP-47 clause interleaving support

I sent [tree-sitter-scala#439](https://github.com/tree-sitter/tree-sitter-scala/pull/439), which supports [SIP-47](https://docs.scala-lang.org/sips/clause-interleaving.html) clause interleaving:

> We propose to generalize method signatures to allow any number of type parameter lists, interleaved with term parameter lists and using parameter lists.

here are some examples:

```scala
def getOrElse(k: Key)[V >: k.Value](default: V): V

def aaa[A](using a: A)(b: List[A])[C <: a.type, D](cd: (C, D))[E]: Unit
```

Here's the change to the syntax:

```diff
  _function_constructor: $ =>
    prec.right(
      seq(
        field("name", $._identifier),
-       field("type_parameters", optional($.type_parameters)),
        field(
          "parameters",
-         repeat(seq(optional($._automatic_semicolon), $.parameters)),
+          repeat(seq(optional($._automatic_semicolon),
+           choice(
+             $.parameters,
+             $.type_parameters
+           )
+         )),
        ),
        optional($._automatic_semicolon),
      ),
    ),
```

#### SIP-64 - syntax for context bounds and givens

I sent [tree-sitter-scala#442](https://github.com/tree-sitter/tree-sitter-scala/pull/442), which supports [SIP-64](https://docs.scala-lang.org/sips/sips/typeclasses-syntax.html). SIP-64 bundles a number of changes both syntactical changes and new features.

first, we can now define givens without `with` and use `:` instead.

```scala
  given intFoo: CanFoo[Int]:
    def foo(x: Int): Int = 0
```

tree-sitter-scala change is:

```javascript
choice(
  ":",
  "with"
),
```

then a new syntax to name context bounds using `as`:

```scala
def reduce[A : Monoid as m](xs: List[A]): A = ()
```

here's new context bound:

```javascript
context_bound: $ => seq(
  ":",
  field("type", $._type),
  optional(seq(
    "as",
    field("name", $._identifier),
  )),
),
```

also a new syntax to aggregate context bounds:

```scala
def showMax[X : {Ordering, Show}](x: X, y: X): String = ()
```

here's new context bounds:

```javascript
_context_bounds: $ => choice(
  repeat1(seq(
    ":",
    $.context_bound
  )),
  seq(
    ":",
    "{",
    trailingCommaSep1($.context_bound),
    "}",
  )
),
````

there's also conditional givens and context bound for type members. I can't remember the last time a SIP had this many changes.

#### SIP-62 - for comprehension syntax

because tree-sitter-scala parser is more relaxed than the real parser, I didn't have to make changes for [SIP-62](https://docs.scala-lang.org/sips/better-fors.html), which lets you start `for` with an alias enumerator.

I sent [tree-sitter-scala#443](https://github.com/tree-sitter/tree-sitter-scala/pull/443) as a test.

#### SIP-64 again

there's actually another change in [SIP-64](https://docs.scala-lang.org/sips/sips/typeclasses-syntax.html), which is to allow context bound in polymorphic function type.

apparently we haven't implemented polymorphic function type support, so I sent [tree-sitter-scala#444](https://github.com/tree-sitter/tree-sitter-scala/pull/444) for that. example looks like this:

```scala
class A:
  type Comparer = [X: Ord] => (X, X) => Boolean
  val less: Comparer = [X: Ord] => (x: X, y: X) => ???
```

here's poly function type:

```javascript
    function_type: $ =>
      prec.left(
        choice(
          seq(field("type_parameters", $.type_parameters), $._arrow_then_type),
          seq(field("parameter_types", $.parameter_types), $._arrow_then_type),
        )
      ),
```

at least for tree-sitter-scala, it didn't take too long to catch up with Scala 3.6.2.

<a id="10"></a>
### 2024-12-10
#### bumping to Scala 3.6.2, and improving the compiler
since [Scala 3.6.2][3.6.2] seems to have been released, I sent a PR to update sbt 2.x to Scala 3.6.2 in [#7941](https://github.com/sbt/sbt/pull/7941).

not sure why there are no tweets from the official [scala-lang.bsky.social](https://bsky.app/profile/scala-lang.bsky.social) and [scala_lang@fosstodon.org](https://fosstodon.org/@scala_lang). if you're curious who are the people behind Scala 3, there's a helpful [Scala 3 Compiler Team](https://www.scala-lang.org/maintainers/) page.

if you recall from [day 5](#5), Scala 3.6.x adds a new compiler warning related to the givens search prioritization change that is planned for Scala 3.7. today I discovered [Upcoming Changes to Givens in Scala 3.7](https://www.scala-lang.org/2024/08/19/given-priority-change-3.7.html) post written by Oliver Bračevac in August 2024 detailing the change. as it turns out, the warning isn't unactionable since we can suppress it by passing in `-source 3.5`, `-source 3.7`, or by filtering by the warning message:

```scala
import scala.annotation.nowarn

@nowarn("msg=Given search preference") // not great
val x = summon[A]
```

to commemorate the release of Scala 3.6 series, I've sent in a pull request [scala/scala3#22189](https://github.com/scala/scala3/pull/22189) 'refactor: improve Given search preference warning'.

1. this refactors the code to give the warning an error code `E205`.
2. when this is displayed as a warning, tell the user to choose `-source 3.5` vs `3.7`, or use `@nowarn("id=205")` annotation.

#### follow up on SbtParser ConcurrentModificationException

I sent [#7938](https://github.com/sbt/sbt/pull/7938) last night as an attempt to fix a `ConcurrentModificationException`, and wrote

> since this wasn't failing on CI, it's hard to say if the fix would actually hold.

my trepidation about the fix was warranted, since overnight I got helpful code review by Adrien Piquerez that it won't fix the concurrency issue by protecting the initialization per se.

> Looking at the stack trace, it seems that dotty is iterating the `System.properties` while another thread modifies them.

João Ferreira also pointed out that in Scala 2.x compiler already implements a workaround for it in 2018 in [scala/scala#6413](https://github.com/scala/scala/pull/6413). for now, I decided to wrap it in `Retry(...)`, which should fix the issue in case we observe `sys.prop` changes.

<a id="9"></a>
### 2024-12-09
a quick sbt 2.0.0-M2 bug fix today. about a month ago, xuwei-k reported [#7873](https://github.com/sbt/sbt/issues/7873) 'ConcurrentModificationException in SbtParser':

```scala
Error:  Exception in thread "sbt-parser-init-thread" java.lang.ExceptionInInitializerError
Error:    at sbt.internal.parser.SbtParserInit$$anon$1.run(SbtParser.scala:179)
Error:  Caused by: java.util.ConcurrentModificationException
Error:    at java.util.Hashtable$Enumerator.next(Hashtable.java:1408)
....
Error:    at dotty.tools.dotc.core.Contexts$ContextBase.<init>(Contexts.scala:857)
Error:    at dotty.tools.dotc.Driver.initCtx(Driver.scala:61)
Error:    at sbt.internal.parser.SbtParser$ParseDriver.<init>(SbtParser.scala:138)
Error:    at sbt.internal.parser.SbtParser$.<clinit>(SbtParser.scala:135)
```

a few days ago João Ferreira reported that he's seen it too. to parse `build.sbt` DSL, sbt uses ligthtly customized Scala 3 compiler. for sbt 1.x, that's Scala 2.12, and sbt 2.x it's Scala 3.x. because the compiler JARs are hefty to JIT, we give it a head start by creating a thread to classload `SbtParser` when sbt starts up.

```scala
/**
 * This gives JVM a head start to JIT Scala 3 compiler JAR.
 * Called by sbt.internal.ClassLoaderWarmup.
 */
private class SbtParserInit:
  val t = new Thread("sbt-parser-init-thread"):
    setDaemon(true)
    override def run(): Unit =
      val _ = SbtParser.defaultGlobalForParser
  t.start()
end SbtParserInit
```

the problem is that if sbt starts up quickly enough, now the initialization might end up concurrency issue. I sent [#7938](https://github.com/sbt/sbt/pull/7938) as an attempt to fix this:

```diff
+  private lazy val defaultGlobalForParser = ParseDriver()
+  private[sbt] def getGlobalForParser: ParseDriver = synchronized:
+    defaultGlobalForParser

....

+    val _ = SbtParser.getGlobalForParser
```

since this wasn't failing on CI, it's hard to say if the fix would actually hold.

<a id="8"></a>
### 2024-12-08

switching gear to sbt 2.0.0-M2 bug. let's look into the `exists` problem [#7931](https://github.com/sbt/sbt/issues/7931), which is the top priority issue we need for 2.0.0-M3. one of the changes I made in sbt 2.x is the location of `target` directory. in sbt 1.x each subproject has its own `target` directory where the build artifacts like `*.class` files and `*.jar` files are created. in this model, the source code and binary directory are intertwined with each other. in sbt 2.x, there's going to be one `target` directory for the entire build, and each subproject would create a subdirectory under `target`:

```bash
target/out/jvm/scala-3.5.2/root/classes/example/A.class
```

the problem is that now it's difficult to write a scripted test that would work for both sbt 1.x and 2.x. a solution that I came up today is to allow glob support in the scripted test commands liks like `exists` and `absent`. for example the above can be tested as:

```bash
$ exists target/**/classes/example/A.class
```

the `**` part would match to zero or more directories, so that should ignore the extra levels in sbt 2.x. a more tricky example might be:

```bash
# sbt 1.x
$ exists core/target/scala-3.5.2/classes/example/A.class

# sbt 2.x
$ exists target/out/jvm/scala-3.5.2/core/classes/example/A.class
```

for this, I've added `||` so we can write:

```bash
$ exists core/target/scala-3.5.2/classes/example/A.class || target/out/jvm/scala-3.5.2/core/classes/example/A.class
```

this would match either the path. given that `||` isn't going to exist as a file name, this should be a safe change to introduce. we should still abstract out the Scala version so we don't have to update it each time we bump the Scala version:

```bash
$ exists core/target/scala-3.*/classes/example/A.class || target/out/jvm/scala-3.*/core/classes/example/A.class
```

in scripted, the file commands are implemented in [FileCommands.scala](https://github.com/sbt/sbt/blob/ffb6770bdee26e7ac94fcd3bc250132b626c805e/internal/util-scripted/src/main/scala/sbt/internal/scripted/FileCommands.scala). glob functionality already exists in sbt 1.x as part of a change Ethan implemented for `~` improvements. first, we need to progress the arguments passed into `exitst` into `List[PathFilter]`:

```scala
def filterFromStrings(exprs: List[String]): List[PathFilter] =
  def orGlobs =
    val exprs1 = exprs.mkString("").split(OR)
      .filter(_ != OR).toList.map(_.trim)
    val combined = exprs1.map(Glob(baseDirectory, _)) match
      case Nil      => sys.error("unexpected Nil")
      case g :: Nil => (g: PathFilter)
      case g :: gs =>
        gs.foldLeft(g: PathFilter) { case (acc, g) =>
          acc || (g: PathFilter)
        }
    List(combined)
  if exprs.contains("||") then orGlobs
  else exprs.map(Glob(baseDirectory, _): PathFilter)
```

we can then pass this into `FileTreeView.Ops(FileTreeView.default)` to see if the filter returns anything. is the returns is non-empty `exists` succeeds, and if the result is empty `absent` succeeds. PR for this is [#7932](https://github.com/sbt/sbt/pull/7932).

#### skating notes

went skating in the afternoon a bit since it's relatively nicer 11C/52F. more awkward penguin walks and monster walks. still trying to get used to ollie with AF-1. AF-1 is physically heavier, but what's throwing me off literally might be more to do with timing of Indy Hollow vs AF-1. with Indy Hollow, I just needed to put some pressure upfront, and jump, and the pop happened on its own a split seconds later. with AF-1, part of the heaviness might just be unweighing timing. with AF-1 I sometimes jump up and I'm off the board, which likely means front leg needs to go up faster? on a positive note, when I can pop, it feels like the board comes up slower. if I can hang in the air, the perceived slowness could buy me time, potentially to a leveled out the ollie.

<a id="7"></a>
### 2024-12-07
went skating for a few hours in the evening. given that people go skiing and snow boarding in the mountain, I guess any temperature is skatable if you wear the right layers. my 4C/38F outfit was t-shirt, [uniqlo flannel](https://www.uniqlo.com/us/en/products/E470187-000/00?colorDisplayCode=03), big hoodie, [lululemon jogger in a nice chino pants color](https://shop.lululemon.com/p/men-joggers/Abc-Jogger/_/prod8530240?color=29283), beanie hat, and a pair of thin gloves. after a while, I was running too warm and it was windy so switched hoodie with a marmot minimalist. put another way, skateboarding is snowboarding that you can do at your local empty park.

continuing from yesterday on the thin client. in case you didn't know, sbt ships with a native thin client called sbtn, which can communicate with an existing sbt session. the motivation for the thin client is to reduce the startup speed (if the server is already up) and share the session with IDEs.

I posted the `socat` dump of the UNIX domain socket: <https://gist.github.com/eed3si9n/0e104e33caa18e468aab92af10dfaf28>. in the session I issued `compile` task. it might be surprising to see nearly 700 lines of log for passing in `compile`. same as LSP, the first handshake is called [initialize](https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#initialize). next, we identified `sbt/attach` method.

next, sbt server starts asking the thin client back for information:

```json
{"jsonrpc":"2.0","id":"b8d058b0-af7a-4d40-93a9-5e2432183fe7","method":"sbt/terminalPropertiesQuery","params":""}
```

to this the thin client responds:

```json
{ "jsonrpc": "2.0", "id": "b8d058b0-af7a-4d40-93a9-5e2432183fe7", "result": {"type":"TerminalPropertiesResponse","width":316,"height":43,"isAnsiSupported":true,"isColorEnabled":true,"isSupershellEnabled":true,"isEchoEnabled":true} }
```

sbt server then starts forwarding stdout:

```json
{"jsonrpc":"2.0","method":"sbt/systemOut","params":[27,91,48,74]}
{"jsonrpc":"2.0","method":"sbt/systemOut","params":[27,91,50,75,27,91,49,48,48,48,68,27,91,48,74]}
{"jsonrpc":"2.0","method":"sbt/systemOut","params":[27,91,50,75,27,91,49,48,48,48,68,27,91,48,74]}
```

I typed the following to chatgpt:

> Decode the following, assuming that the numbers represent ASCII code in decimal:
> `[27,91,48,74]`

the response was:

> `ESC [ 0 J`<br>
> This sequence is a common ANSI escape code used in terminal control. Specifically, `ESC [ 0 J` clears the screen from the cursor to the end.

so far this all makes sense. then comes lines after lines of `sbt/terminalCapabilities` method by sbt server:

```json
{"jsonrpc":"2.0","id":"10a87b11-001f-407f-aa67-a48e6cead549","method":"sbt/terminalCapabilities","params":{"numeric":"max_colors"}}
{ "jsonrpc": "2.0", "id": "10a87b11-001f-407f-aa67-a48e6cead549", "result": {"type":"TerminalCapabilitiesResponse","numeric":256} }
{"jsonrpc":"2.0","id":"67296a90-e9b1-4dd9-af4b-8adf89f8556e","method":"sbt/terminalCapabilities","params":{"string":"key_a1"}}
{ "jsonrpc": "2.0", "id": "67296a90-e9b1-4dd9-af4b-8adf89f8556e", "result": {"type":"TerminalCapabilitiesResponse","string":"null"} }
{"jsonrpc":"2.0","id":"ac7e102d-2815-401e-8cc6-f490c3aa9a5a","method":"sbt/terminalCapabilities","params":{"string":"key_a3"}}
{ "jsonrpc": "2.0", "id": "ac7e102d-2815-401e-8cc6-f490c3aa9a5a", "result": {"type":"TerminalCapabilitiesResponse","string":"null"} }
{"jsonrpc":"2.0","id":"b846fbb7-6370-4a0b-8fde-47d5ea94ba2e","method":"sbt/terminalCapabilities","params":{"string":"key_b2"}}
{ "jsonrpc": "2.0", "id": "b846fbb7-6370-4a0b-8fde-47d5ea94ba2e", "result": {"type":"TerminalCapabilitiesResponse","string":"\\\\EOE"} }
....
{"jsonrpc":"2.0","id":"b90e4668-8d51-4e83-bf8f-8c958da17dd6","method":"sbt/terminalCapabilities","params":{"string":"exit_alt_charset_mode"}}
{ "jsonrpc": "2.0", "id": "b90e4668-8d51-4e83-bf8f-8c958da17dd6", "result": {"type":"TerminalCapabilitiesResponse","string":"\\\\E(B"} }
```

some more `sbt/systemout`:

```json
{"jsonrpc":"2.0","method":"sbt/systemOut","params":[27,91,63,49,104,27,61,27,91,63,50,48,48,52,104,115,98,116,58,102,111,111,27,91,51,54,109,62,32,27,91,48,109]}
```

according to chatgpt that's:

> `ESC[?1h ESC= ESC[?2004h sbt:foo ESC[36m> ESC[0m`

this is the sbt prompt with cyan `>`.

sbt server then sends

```json
{"jsonrpc":"2.0","method":"sbt/readSystemIn","params":""}
```

to prompt for stdin. sbtn sends

```json
{ "jsonrpc": "2.0", "method": "sbt/systemIn", "params": 99 }
```

`99` is `c` for `compile`. sbt server goes back to asking a few more the terminal capabilities and sends 'c' back in `sbt/systemOut` method:

```json
{"jsonrpc":"2.0","method":"sbt/systemOut","params":[99]}
```

basically it goes on to send `compile` and `\n` (CR). after a few stdout of ANSI control sequences, sbt server sends:

```json
{"jsonrpc":"2.0","id":"06433732-e24f-4f6a-b278-a39a1b927f1b","method":"sbt/terminalSetRawMode","params":{"toggle":false}}
```

eventually we get stdout from some super shell outputs from the server:

```json
{"jsonrpc":"2.0","method":"sbt/systemOut","params":[27,91,49,48,48,48,68,10,27,91,50,75,27,91,50,75,32,32,124,32,61,62,32,102,111,111,32,47,32,117,112,100,97,116,101,32,48,115,10,27,91,50,75,27,91,50,65,27,91,49,48,48,48,68]}
```

per chatgpt, that says:

```bash
  | => foo / update 0s
```

next we kind of get a progress report from the server as well:

```json
{"jsonrpc":"2.0","method":"build/taskStart","params":{"taskId":{"id":"2","parents":[]},"eventTime":1733553247768,"message":"Compiling foo","dataKind":"compile-task","data":{"target":{"uri":"file:/private/tmp/foo/#foo/Compile"}}}}
```

in any case, I think we get the idea of the style of communication between the thin client and sbt server. to put simply, it seems like Ethan has implemented `telnet` / `ssh` equivalent over the existing JSON RPC protocol, including color support. let's try uparrow.

```json
{"jsonrpc":"2.0","method":"sbt/readSystemIn","params":""}
{ "jsonrpc": "2.0", "method": "sbt/systemIn", "params": 27 }
{"jsonrpc":"2.0","method":"sbt/readSystemIn","params":""}
{ "jsonrpc": "2.0", "method": "sbt/systemIn", "params": 79 }
{"jsonrpc":"2.0","method":"sbt/readSystemIn","params":""}
{ "jsonrpc": "2.0", "method": "sbt/systemIn", "params": 65 }
```

sbt server reponded as follows:

```json
{"jsonrpc":"2.0","method":"sbt/systemOut","params":[99,111,109,112,105,108,101]}
```

chatgpt says it's `compile`, which mean up-arrow history works! in other words, the thin client faithfully reproduces the sbt shell experience including the history lookup and tab completions. we'll continue tomorrow.

<a id="6"></a>
### 2024-12-06
an area of sbt that likely few people know the details about is the thin client, which was sort of [prototyped first](https://github.com/sbt/sbt/pull/4227) by me, but Ethan Atkins took it to the next level by supporting almost all tasks in a general way. let's try reverse engineering sbtn to see how the native code is communicating with sbt 1.x.

the thin client is part of sbt 1.x's code base, and it's written in Scala 2.12. it is then compiled using GraalVM native-image to turn into a native app. it talks with sbt server, which uses JSON-RPC over a UNIX domain socket like an LSP server. to monitor the communication, first install [socat](https://formulae.brew.sh/formula/socat).

start an sbt session in `/tmp/foo`:

```bash
$ sbt
[info] Updated file /private/tmp/foo/project/build.properties: set sbt.version to 1.10.6
[info] welcome to sbt 1.10.6 (Azul Systems, Inc. Java 1.8.0_402)
.....
[info] sbt server started at local:///Users/xxxx/.sbt/1.0/server/aaaa/sock
[info] started sbt server
```

`/Users/xxxx/.sbt/1.0/server/aaaa/sock` is the UNIX domain socket, the sbt server is listening. in another terminal, proxy the UNIX domain socket as follows:

```bash
$ socat -v UNIX-LISTEN:$HOME/.sbt/1.0/server/aaaa/proxy.sock,fork UNIX-CONNECT:$HOME/.sbt/1.0/server/aaaa/sock
```

next, open `project/target/active.json`:

```json
{"uri":"local:///Users/xxxx/.sbt/1.0/server/aaaa/sock"}
```

change the content to `proxy.sock` instead:

```json
{"uri":"local:///Users/xxxx/.sbt/1.0/server/aaaa/proxy.sock"}
```

open yet another terminal window in `/tmp/foo`:

```bash
$ sbt --client
[info] entering *experimental* thin client - BEEP WHIRR
[info] terminate the server with `shutdown`
[info] disconnect from the server with `exit`
sbt:foo> compile
[success] Total time: 0 s
```

if you go back to the `socat` window, the screen should be filled with JSON-RPC.

```json
> 2024/12/07 01:30:49.000005239  length=181 from=0 to=180
Content-Length: 158\r
\r
{ "jsonrpc": "2.0", "id": "cb0ffdd8-be63-42cb-b853-4fce15a5c9f5", "method": "initialize", "params": { "initializationOptions": { "skipAnalysis" : true } } }\r
> 2024/12/07 01:30:49.000005821  length=148 from=181 to=328
Content-Length: 125\r
\r
{ "jsonrpc": "2.0", "id": "44b67b11-1551-424d-9b5f-1454112b769c", "method": "sbt/attach", "params": {"interactive": true} }\r
< 2024/12/07 01:30:49.000028766  length=338 from=0 to=337
Content-Length: 258\r
Content-Type: application/vscode-jsonrpc; charset=utf-8\r
\r
{"jsonrpc":"2.0","id":"cb0ffdd8-be63-42cb-b853-4fce15a5c9f5","result":{"capabilities":{"textDocumentSync":{"openClose":true,"change":0,"willSave":false,"willSaveWaitUntil":false,"save":{"includeText":false}},"hoverProvider":false,"definitionProvider":true}}}< 2024/12/07 01:30:49.000039588  length=192 from=338 to=529
....
```

this shows that sbtn sent `initialize` method, and `sbt/attach` method, and sbt serer responsed to the first request cb0ffdd8 with the list of capabilities supported by the server:

```json
{"capabilities":{"textDocumentSync":{"openClose":true,"change":0,"willSave":false,"willSaveWaitUntil":false,"save":{"includeText":false}},"hoverProvider":false,"definitionProvider":true}}
```

full output is here <https://gist.github.com/eed3si9n/0e104e33caa18e468aab92af10dfaf28>. this looks promising. we'll continue tomorrow.

<a id="5"></a>
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

<a id="4"></a>
### 2024-12-04
sent a PR [#7927](https://github.com/sbt/sbt/pull/7927).

`java.net.URL` infamously calls out to the network to perform `equals`, so likely we should avoid it for keys and data types that might be used in caching. thankfully not too many keys are URLs so I changed them all to URI.

related, I cherry picked a commit from a dormant PR that turns license information into a data type, as opposed to a tuple of `(String, URL)`. I had a few backward compatibility suggestions in the PR, and I just implemented the suggestions myself.

<a id="3"></a>
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

<a id="2"></a>
### 2024-12-02

sent [Artifact publishing proposal](https://github.com/scalacenter/advisoryboard/pull/168) PR to Scala Center. not going to repeat the content here, but there's been a number of changes to the landscape of publishing, but the solutions are worked on independently by the build tool silos, so I've been thinking it would be useful to consolidate the effort. this could start with basic things like generating correct `ivy.xml` and `pom.xml`, but also include more recent developments like bill-of-materials (BOM) support.

released [sbt-jupiter-interface 0.13.3](https://github.com/sbt/sbt-jupiter-interface/releases/tag/v0.13.3), featuring a bug fix contributed by Li Haoyi. sbt defines an interface for test frameworks, and sbt-jupiter-interface is an implementation for JUnit 5, not to be confused with Jupyter notebook.

worked on [december mixtape](/2024.12-mixtape/) at night. 3h assortment of electronica for taking a walk or skating.

<a id="1"></a>
### 2024-12-01

looking at sbt 2.x bugs that's been reported against 2.0.0-M2.

[#7723](https://github.com/sbt/sbt/issues/7723) reported by xuwei-k (Kenji Yoshida). it says that on sbt 2.x you get a compiler warning during load "Failed to parse -Wconf configuration: cat=unused-nowarn:s". first, this indicates that Scala 3.3.x or 3.5.x isn't really compatible with Scala 2.x's `-Wconf` flag. the flag was ported, but the category part is completely different in Scala 3. to unwind why sbt 1.x even has this flag,

1. in 2020, we observed [#6161](https://github.com/sbt/sbt/issues/6161) "a pure expression does nothing" warning because Scala 2.12.12 started to be more strict about detecting pure expressions
2. as a workaround in 2021, I added `(??? :@scala.annotation.nowarn("cat=other-pure-statement"))` around build.sbt macro expansions
3. during 1.5.0 RC-1, we observed that in some cases `nowarn` itself would cause additional warning [#6398](https://github.com/sbt/sbt/issues/6398) "@nowarn annotation does not suppress any warnings"
4. as a workaround to the workaround, `"-Wconf:cat=unused-nowarn:s"` was added in [#6403](https://github.com/sbt/sbt/pull/6403)

given that Scala 3.x hasn't started to warn about pure expressions, I can remove the workaround, which is what I did today in [#7924](https://github.com/sbt/sbt/pull/7924).

earlier during the day, I was staring at VisualVM heap drump. Adrien Piquerez reported it in one of his pull requests, but seeing `ScopedKey(...)` occupies 8% of the heap was jarring. I didn't remember that he's already tried interning it and saw not much difference, so I tried it and saw not much difference. perf optimization is sometimes like that.
