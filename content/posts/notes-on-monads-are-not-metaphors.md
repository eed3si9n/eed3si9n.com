---
title:       "Notes on 'Monads Are Not Metaphors'"
type:        story
date:        2013-05-06
draft:       false
promote:     true
sticky:      false
url:         /notes-on-monads-are-not-metaphors
tags:        [ "scala", "fp" ]
aliases:     [ /node/134 ]
---

> This is a translation of [「モナドはメタファーではない」に関する補足](http://d.hatena.ne.jp/xuwei/20130505/1367742286) by Kenji Yoshida ([@xuwei_k](https://twitter.com/xuwei_k)), one of the most active Scala bloggers in Japan covering wide range of topics from Play to Scalaz.

Daniel Spiewak's [Monads Are Not Metaphors](http://www.codecommit.com/blog/ruby/monads-are-not-metaphors) was written about two and a half years ago, but seeing how its [Japanese translation](http://eed3si9n.com/ja/monads-are-not-metaphors) is still being tweeted and being bookmarked by 250 users on [Hantena](http://b.hatena.ne.jp/entry/eed3si9n.com/ja/monads-are-not-metaphors), its popularity doesn't seem to cease. I just remembered something to note about the example code used in the post, which could be an unstylish critique, but I'm going to jot it down here. It's an _unstylish critique_, because I'll be digging into the part where _the author likely knew from the beginning but omitted it intentionally for the sake of illustration_. Also I'll be using Scalaz in this post.

### The example code that calculates `fullName` from `firstName` and `lastName` only requires Applicative[^1] not Monad

Here's the original code

```scala
def firstName(id: Int): Option[String] = ...    // fetch from database
def lastName(id: Int): Option[String] = ...

def fullName(id: Int): Option[String] = {
  firstName(id) bind { fname =>
    lastName(id) bind { lname =>
      Some(fname + " " + lname)
    }
  }
}
```

We can rewrite this using Scalaz[^2] as follows:

```scala
import scalaz._,Scalaz._

def firstName(id: Int): Option[String] = ???
def lastName(id: Int): Option[String] = ???

def fullName(id: Int): Option[String] =
  ^(firstName(id), lastName(id))(_ + " " + _)
```

or

```scala
def fullName(id: Int): Option[String] =
  Apply[Option].apply2(firstName(id), lastName(id))(_ + " " + _)
```

To reiterate, the author likely knows this, since he's said something like this:

<blockquote class="twitter-tweet"><p>Don’t use a monad when an applicative will do.</p>&mdash; Daniel Spiewak (@djspiewak) <a href="https://twitter.com/djspiewak/status/285883841162379265">December 31, 2012</a>
</blockquote>

### Monad's sequence function in Scalaz

First, in Scalaz 7 there's no function with the following signature:

```scala
def sequence[M[_], A](ms: List[M[A]])(implicit tc: Monad[M]): M[List[A]]
```

Instead it has the following under Applicative:

```scala
def sequence[A, G[_]: Traverse](as: G[F[A]]): F[G[A]] =
```

See [https://github.com/scalaz/scalaz/blob/v7.0.0/core/src/main/scala/scalaz/Applicative.scala#L39](https://github.com/scalaz/scalaz/blob/v7.0.0/core/src/main/scala/scalaz/Applicative.scala#L39). To cut to the chase, _the `sequence` function as described in 'Monads Are Not Metaphors'_ [^3] only exists in a _generalized form_ in Scalaz 7.

By the way, in Haskell, there's no corresponding function under `Applicative`, but there's `sequenceA` under `Traversable`: [http://www.haskell.org/ghc/docs/latest/html/libraries/base/Data-Traversable.html#v:sequenceA](http://www.haskell.org/ghc/docs/latest/html/libraries/base/Data-Traversable.html#v:sequenceA).

Coming back to Scalaz, here's what I mean by a _generalized form_.

```scala
def sequence[A, G[_]: Traverse](as: G[F[A]]): F[G[A]] =
```

If we fix the type parameter `G` in the above to `List`, it becomes

```scala
def sequence[A](as: List[F[A]]): F[List[A]]
```

and `sequence` function defined in Scalaz becomes `sequence` described in 'Monads Are Not Metaphors.' It might appear as if

```scala
(implicit tc: Monad[M])
```

disappeared, but this `sequence` is a method of Scalaz's `Applicative`, so `F` is automatically an instance of Applicative. This is a long-winded way to say that even the `sequence` function requires only Applicative, and not Monad.

In Haskell, the Monad directly definining `sqequence` as

```haskell
sequence :: Monad m => [m a] -> m [a]
```

and Traversal defining two similar functions

```haskell
sequenceA :: Applicative f => t (f a) -> f (t a)
```

and

```haskell
sequence :: Monad m => t (m a) -> m (t a)
```

are all artifacts of _historical reason that Monad does not inherit Applicative_, if I may say so at the risk of over-simplification.

To follow up again on the _generalized form_, the implementation of _the `sequence` function as described in 'Monads Are Not Metaphors'_ uses `List`'s `foldRight` [^4].

In other words, to generalize `sequence`, we only need _a container that has equivalent function as `foldLeft`_, which is instances of `Traverse` typeclass [^5].

```scala
def sequence[A, G[_]: Traverse](as: G[F[A]]): F[G[A]]
```

This is the reason `Traverse` appears in the above signature.

### Summary

So it turns out both

- `fullName` function
- `Monad`'s `sequence` function

only require Applicative, and not Monad.

Either on purpose (for the sake of illustration) or by negligence, there are many other examples in Monad tutorials that fall into this "turns out Applicative would suffice instead of Monad" pattern. So readers should keep their eyes open for Applicatives instead of parroting "Monad ( ﾟ∀ﾟ)彡 Monad ( ﾟ∀ﾟ)彡."

  [^1]: `Apply` to more accurate.

  [^2]: 7.0.0 final

  [^3]: The same exists in Haskell.

  [^4]: Haskell implemetation similarly uses `foldr`: [https://github.com/ghc/packages-base/blob/ghc-7.6.3-release/Control/Monad.hs#L97-L103](https://github.com/ghc/packages-base/blob/ghc-7.6.3-release/Control/Monad.hs#L97-L103)

  [^5]: I'm going to omit explanation of `Traverse`.

<script async src="//platform.twitter.com/widgets.js" charset="utf-8"></script>
