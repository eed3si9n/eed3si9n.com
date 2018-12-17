  [1]: https://www.scala-lang.org/blog/2017/02/28/collections-rework.html#language-integration
  [218]: https://github.com/scopt/scopt/issues/218
  [args]: https://github.com/scala/scala/blob/v2.13.0-M5/src/library/scala/App.scala#L46
  [11317]: https://github.com/scala/bug/issues/11317

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
