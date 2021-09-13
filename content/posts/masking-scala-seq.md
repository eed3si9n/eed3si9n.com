---
title:       "masking scala.Seq"
type:        story
date:        2018-12-17
changed:     2018-12-18
draft:       false
promote:     true
sticky:      false
url:         /masking-scala-seq
aliases:     [ /node/282 ]
tags:        [ "scala" ]
---

  [1]: https://www.scala-lang.org/blog/2017/02/28/collections-rework.html#language-integration
  [218]: https://github.com/scopt/scopt/issues/218
  [args]: https://github.com/scala/scala/blob/v2.13.0-M5/src/library/scala/App.scala#L46
  [11317]: https://github.com/scala/bug/issues/11317
  [heiko]: https://hseeberger.wordpress.com/2013/10/25/attention-seq-is-not-immutable/

As of Scala 2.13.0-M5, it's planned that `scala.Seq` will change from `scala.collection.Seq` to `scala.collection.immutable.Seq`. [Scala 2.13 collections rework][1] explains a bit about why it's been non-immutable historically. Between the lines, I think it's saying that we should celebrate that `scala.Seq` will now be immutable out of the box.

Defaulting to immutable sequence would be good for apps and fresh code. The situation is a bit more complicated for library authors.

- If you have a cross-built library, and
- if your users are using your library from multiple Scala versions
- and your users are using `Array(...)`

this change to immutable `Seq` could be a breaking change to your API.

An example of such breakage is [scopt/scopt#218][218]. I cross-published scopt, and now it won't work with `args`. Even in Scala 2.13.0-M5, [`args`][args] is an `Array[String]`.

A simple fix is to import `scala.colletion.Seq` in all source code. But I want to make it such that using `Seq` won't compile the code.

### unimporting scala.Seq

First thing I thought of is unimporting the name `scala.Seq`, so I would be forced to import either `scala.collection.Seq` or `scala.collection.immutable.Seq`.

<scala>
import scala.{ Seq => _, _ }
</scala>

This does not work, since the name `Seq` is bound by the default `import scala._` in the outermost scope. Even if it did work, this would require remembering to put the import statement in all source code, so it's not good.

Jasper-M reminded me about `-Yno-imports`, which might be an option to consider.

### defining a dummy Seq

Next, I tried defining a trait named `Seq` under my package:

<scala>
package scopt

import scala.annotation.compileTimeOnly

/**
  * In Scala 2.13, scala.Seq moved from scala.collection.Seq to scala.collection.immutable.Seq.
  * In this code base, we'll require you to name ISeq or CSeq.
  *
  * import scala.collection.{ Seq => CSeq }
  * import scala.collection.immutable.{ Seq => ISeq }
  *
  * This Seq trait is a dummy type to prevent the use of `Seq`.
  */
@compileTimeOnly("Use ISeq or CSeq") private[scopt] trait Seq[A1, F1[A2], A3]
</scala>

I am using nonsensical type parameters so the existing code won't compile. For example, `Seq[String]` in my code will be caught as follows:

<code>
[info] Compiling 3 Scala sources to /scopt/jvm/target/scala-2.12/classes ...
[error] /scopt/shared/src/main/scala/scopt/options.scala:434:19: wrong number of type arguments for scopt.Seq, should be 3
[error]   def parse(args: Seq[String])(implicit ev: Zero[C]): Boolean =
[error]                   ^
[error] one error found
</code>

As long as the code is within `scopt` package, this should prevent the use of `Seq`. To use actual Seqs, we would import them as follows:

<scala>
import scala.collection.{ Seq => CSeq }
import scala.collection.immutable.{ Seq => ISeq }
</scala>

If you care about your API semantics being the same across cross builds you might opt for `CSeq` for anything public. And maybe when you bump your API, you can change them all to `ISeq`.

### addendum: scala.IndexedSeq is affected too

Sciss (Hanns) pointed out that `scala.IndexedSeq` are affected in the same way. So if you're doing this for `scala.Seq` you might as well check for `scala.IndexedSeq` too.

### addendum: Heiko Seq

Sciss (Hanns) also [reminded](https://www.reddit.com/r/scala/comments/a71pi3/masking_scalaseq/) me about Heiko Seq, which Heiko wrote in [Seq is not immutable!][heiko] post back in 2013:

<scala>
package object scopt {
  type Seq[+A] = scala.collection.immutable.Seq[A]
  val Seq = scala.collection.immutable.Seq
  type IndexedSeq[+A] = scala.collection.immutable.IndexedSeq[A]
  val IndexedSeq = scala.collection.immutable.IndexedSeq
}
</scala>

This will adopt the `scala.immutable.Seq` across all Scala versions. If you want to stay on `scala.collection.Seq`, you can use the Sciss variation:

<scala>
package object scopt {
  type Seq[+A] = scala.collection.Seq[A]
  val Seq = scala.collection.Seq
  type IndexedSeq[+A] = scala.collection.IndexedSeq[A]
  val IndexedSeq = scala.collection.IndexedSeq
}
</scala>

If you don't want to go through your source deciding whether to use `CSeq`, `ISeq`, or `List`, this might be a solution for you.

### addendum: vararg

Dale reminded about related Scala 2.13 migration issue, which is vararg.
Given that Scala specification specifies that `scala.Seq` is passed on, vararg parameters will expect `scala.collection.immutable.Seq`. This matters if your users are calling your API as `something(xs: _*)`, and `xs` happens to be an array etc. This is a Scala wide change, and it's something everyone has to change if you migrate to Scala 2.13.
