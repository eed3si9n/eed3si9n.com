Unlike XML-based build tools sbt's build definitions are written in Scala (for both .sbt and .scala). This means that once one gets over the hurdle of learning sbt's concepts and operators, it doesn't take much for build users to start writing sbt plugins.

I've ported a few from sbt 0.7 before, but I've also been writing some original ones recently that I'd like to share.

## sbt-dirty-money

[sbt-dirty-money](https://github.com/sbt/sbt-dirty-money) is a plugin to clean Ivy cache somewhat selectively (anything that includes `organization` and `name` under `~/.ivy2/cache`). It was such a simplistic 25-line implementation, but `clean-cache` and `clean-local` tasks continue to be useful for me.

For example, if I am unsure if a plugin that I am developing if being cached by a test hello project or not, I run both `clean-cache` and `clean-local` from the plugin project and reload the hello project to see it not resolving the plugin. If it can't resolve it that's good because it's not grabbing it from some magical place.

## sbt-buildinfo

[sbt-buildinfo](https://github.com/sbt/sbt-buildinfo) is a plugin I've been meaning to write for a while. It's a plugin to generate Scala source from your build definition. The purpose mainly is for a program to be self-aware of its own version number, especially when they are conscripted.

In the past, I have whipped out ad hoc `sourceGenerators` to generate an object that contains version number, but making it a plugin made sense since others may needs it too. By extracting the values from `state` sbt-buildinfo is able to grab generate Scala source containing arbitrary keys. Add the following to the `build.sbt`:

<scala>buildInfoSettings

sourceGenerators in Compile <+= buildInfo

buildInfoKeys := Seq[Scoped](name, version, scalaVersion, sbtVersion)

buildInfoPackage := "hello"</scala>

and it generates:

<scala>package hello

object BuildInfo {
  val name = "helloworld"
  val version = "0.1-SNAPSHOT"
  val scalaVersion = "2.9.1"
  val sbtVersion = "0.11.2"
}</scala>

## sbt-scalashim

[sbt-scalashim](https://github.com/sbt/sbt-scalashim) is a plugin that generates shim for Scala 2.8.x to use 2.9.x's `sys.error`.
Number of people in the Scala community has been raising the awareness of cross publishing the libraries to support 2.8.x and 2.9.x. 

I felt like one of the reasons people abandon 2.8.x is the source-level incompatibility due to `sys.error`, so I wrote a plugin to absorb the differences. Because a packaged class cannot import things from the empty package it requires you to add `import scalashim._` in your code, which is not ideal. But you can use `sys.error` in 2.8.0. The latest version also support things like `sys.props` and `sys.env`.

## sbt-man

[sbt-man](https://github.com/sbt/sbt-man) is also another plugin I've been wanting to write. By the way, most of these plugins are written over a weekend, often in a single stretch of a late night hacking.

For a while, I've been reading [Programming Clojure](http://pragprog.com/book/shcloj/programming-clojure) a few pages at a time. One thing that inspired me was the `doc` function, which prints documentation for a given function.

    user=> (doc doc)
    -------------------------
    clojure.core/doc
    ([name])
    Macro
      Prints documentation for a var or special form given its name
    nil

Reading this made me realize that I've been feeling awkward about using a web browser to lookup function signatures for standard lib functions.

So I wrote a plugin that adds `man` command last weekend:

    > man Traversable /:
    [man] scala.collection.Traversable
    [man] def /:[B](z: B)(op: (B ⇒ A ⇒ B)): B
    [man] Applies a binary operator to a start value and all elements of this collection, going left to right. Note: /: is alternate syntax for foldLeft; z /: xs is the same as xs foldLeft z. Note: will not terminate for infinite-sized collections. Note: might return different results for different runs, unless the underlying collection type is ordered. or the operator is associative and commutative. 

This is powerd by [Scalex](http://scalex.org/). I just ripped off the cli implementation with a few lift-json adjustments added to it.

## Other plugins

There are also number of cool plugins written by others. 

Since the Sonatype migration, Josh's [xsbt-gpg-plugin](https://github.com/sbt/xsbt-gpg-plugin) has been indispensable. Josh also maintains [xsbt-ghpages-plugin](https://github.com/jsuereth/xsbt-ghpages-plugin) and [sbt-git-plugin](https://github.com/sbt/sbt-git-plugin).

All my projects have Doug's [ls-sbt](https://github.com/softprops/ls-sbt) so I can register it with [ls.implicit.ly](http://ls.implicit.ly/). Doug also maintains [np](https://github.com/softprops/np) and [coffeescripted-sbt](https://github.com/softprops/coffeescripted-sbt).

A plugin I put in my global plugins.sbt recently is Stephen Wells's [sbt-sh](https://github.com/steppenwells/sbt-sh). This executes the command outside of sbt, so I can do something like:

    > sh git status 

from sbt shell.

I also want to mention Mathias's [sbt-revolver](https://github.com/spray/sbt-revolver). It runs your application in the background of sbt shell as a forked JVM, and keeps track of it. Because it's tracked, you can run `re-start` and it'll take down the existing instance and start it again. It automatically takes advantage of [JRebel](http://zeroturnaround.com/jrebel/), which is free for Scala instances.

For the development server task for [sbt-appengine](https://github.com/sbt/sbt-appengine) I tried to base it on top of sbt-revolver to take advantage of hot reloading etc. There are probably other interesting uses for it.

## sbt 0.12

I'm looking forward to sbt 0.12 for many reasons, but one of them is the binary compatibility of the plugins across point releases. This would lessen the burden on plugin authors to keep publishing jars every time sbt comes out. I know you can use source dependencies, but because they aren't like the normal Ivy dependencies the setting is difficult and it doesn't get written in pom.xml.

0.12 also adds Scala-like string literal parser I contributed. This allows the tasks and commands to accept arguments including white spaces, which should make some of the commands more useful.
