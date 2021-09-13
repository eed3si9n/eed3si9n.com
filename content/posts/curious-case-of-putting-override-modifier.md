---
title:       "curious case of putting override modifier when overriding an abstract method in Scala"
type:        story
date:        2013-12-20
changed:     2013-12-21
draft:       false
promote:     true
sticky:      false
url:         /curious-case-of-putting-override-modifier
aliases:     [ /node/153 ]
tags:        [ "scala" ]
---

> This is a translation of [Scalaで抽象メソッドをoverrideする際にoverride修飾子を付けるべきかどうかの是非](http://d.hatena.ne.jp/xuwei/20131220/1387509706) by Kenji Yoshida ([@xuwei_k](https://twitter.com/xuwei_k)), a Scalaz committer.

First, a quote from Programming in Scala, 2nd ed. p. 192:

> Scala requires [`override`] modifier for all members that override a concrete member in a parent class. The modifier is optional if a member implements an abstract member with the same name.

In this post, we'll discuss this "The modififier is optional." Since overriding an existing method with implementation requires `override` modifier, and failure to do so would result to a compiler error, there's not much to talk about for that case. We'll focus on whether one should put `override` modifier or not in the case of overring an abtract method. I don't think there's going to be any difference in Scala version, but let's assume the latest stable 2.10.3.

"The modifier is option" is correct in face value, but I found seen much discussion in the book or on the web[^1] on which one should be used, or if there is any difference in putting `override` or not.

For a long while, I used to think: It's true that "the modifier is optional," but

- Putting `override` would make it clear that it's implementing an abtract method.
- Putting `override` could prevent, thinking that I'm overriding a method, but declaring another method with slightly different signature by mistake. So defensively speaking, it's preferable to put `override`, especially because there seems to be no downside to it.

However, I realized a rare, but an actual case that *not putting `override` might be preferable*, so I'm writing this now. This occurs in so-called diamond inheritance.

Let's see the code first. This will compile:

<scala>
trait A{
  def foo: Int
}

trait B extends A{
  override def foo = 1
}

trait C extends A{
  override def foo = 2
}

trait D extends C with B
// Later mixin has precedence, so B's implementation is used
</scala>

This, on the other hand would result to a compiler error:

<scala>
trait A{
  def foo: Int
}

trait B extends A{
  def foo = 1
}

trait C extends A{
  def foo = 2
}

trait D extends C with B
/**
error: trait D inherits conflicting members:
  method foo in trait C of type => Int  and
  method foo in trait B of type => Int
(Note: this can be resolved by declaring an override in trait D.)
       trait D extends C with B
             ^
*/
</scala>

In short, this is a case in which there's a possibility of a diamond inheritance, and when *one would prefer to explicitly override conflicts* instead of depending on the mixin order of the traits.

You might ask "how often would would such case arise?" but I see them. In Scalaz.

In Scalaz,

- `Functor` has one abstract method named `map`.
- `Traverse` inherits `Functor`.[^3]
- In `Traverse`, `map` could be implemented from other methods, so it's overridden as follows:

<scala>
override def map[A,B](fa: F[A])(f: A => B): F[B] = traversal[Id](Id.id).run(fa)(f)
</scala>

Further discussion require a bit of an internal knowledge of Scalaz:

- When defining a typeclass instance, there are cases that require other typeclass instances and the cases that do not.
- Examples of the cases that do not require other typeclass instances:
  - List https://github.com/scalaz/scalaz/blob/v7.1.0-M4/core/src/main/scala/scalaz/std/List.scala#L14
  - Option https://github.com/scalaz/scalaz/blob/v7.1.0-M4/core/src/main/scala/scalaz/std/Option.scala#L11
- Example of the cases that do require other typeclass instances would be OneAnd, OneOr, Cokleisli, Kleisli, Coproduct, EitherT, ListT, OptionT, StreamT etc.

 In case other typeclass instances are required, by conventions in Scalaz, we define private traits to share the implementation. Since each typeclass require different typeclasses[^4], we end up with defining enormous amount of private traits. 

For instance, here's from `OneOr` as of 7.1.0-M4. https://github.com/scalaz/scalaz/blob/v7.1.0-M4/core/src/main/scala/scalaz/OneOr.scala#L112:

<scala>
private sealed trait OneOrFunctor[F[_]]
    extends Functor[({type λ[α] = OneOr[F, α]})#λ] {
  implicit def F: Functor[F]

  override def map[A, B](fa: OneOr[F, A])(f: A => B): OneOr[F, B] =
    fa map f
}

private sealed trait OneOrTraverse[F[_]]
  extends OneOrFunctor[F] with OneOrFoldable[F] with Traverse[({type λ[α] = OneOr[F, α]})#λ] {

  implicit def F: Traverse[F]

  override def traverseImpl[G[_]: Applicative,A,B](fa: OneOr[F, A])(f: A => G[B]) =
    fa traverse f

  override def foldMap[A, B](fa: OneOr[F, A])(f: A => B)(implicit M: Monoid[B]) =
    fa.foldMap(f)
}
</scala>

`OneOrTraverse` is inheriting `OneOrFunctor` to use the implementation of `map` overridden by `OneOrFunctor`. Or at least, that's the intention.

But in actuality, because `with Traverse` is at the end, so the implementation from `Traverse` is being used. In other words, inheriting `OneOrFunctor` is rendered pointless. It's only by accident that `map` implementation from `Traverse` is included. So I just fixed it: https://github.com/scalaz/scalaz/commit/db3082f1895

It's not exactly a critical bug if the `map` implementation from `Traverse` is being used. But in most cases we can provide more efficient implementation of `map` than that of `Traverse`.

This logic applies for `Applicative` and `Monad`, which also provide default implementation of `map`.

Had it been the case that the `map` implementation of `Traverse` *did not have `override` modifier*, the `map` implementation of `OneOrFunctor` and `Traverse` would conflict, and it would result in a compiler error.

Thus, in the case of diamond inheritance, whether or not putting `override` modifier would make the difference of it being a compiler error or not.

In current Scalaz:

- We can provide default implementation for parent typeclasses (Haskell can't do this, and apparently there's been some discussion on putting similar function in.)

This is convenient, but on the other hand:

- It's hard to tell which implementation ends up being used. It's dependent on mixin order of the traits.
- In most cases, there are more efficient implementation, so the default implementation isn't as often.

This is a subtle conundrum. The topic of default implementation for typeclass has both pros and cons to it, that there's no clear panacea. Scalaz ended up in the current implementation after taking various issues into consideration, so I continue to forge on making very minor improvements like this, while fighting suble conundrums like this.

A feature of marking the implementations of abtract methods `override`, but make it a compiler error when they conflict instead of using the mixin order of the traits may be useful. But personally speaking, I hate the very spec of semantics depending on the mixin orders, so I wish that went away from the spec altogether.

  [^1]: Please let me know if there's any material covering this topic whether it's a book or online.

  [^3]: `Applicative` also overrides `map`, so similar problem arises.

  [^4]: For instance, to define `Functor` for `OneOr` the type parameter `F` needs to be a `Functor`, but to define `Traverse` for `OneOr` `F` needs to be a `Traverse`.
