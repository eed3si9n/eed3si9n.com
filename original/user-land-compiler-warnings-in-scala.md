  [1]: https://twitter.com/not_xuwei_k/status/1240354073297268737
  [7790]: https://github.com/scala/scala/pull/7790
  [8373]: https://github.com/scala/scala/pull/8373
  [8820]: https://github.com/scala/scala/pull/8820
  [ApiMayChange]: https://doc.akka.io/docs/akka/current/common/may-change.html

As a library author, I've been wanting to tag methods in Scala that can trigger custom warnings or compiler errors. Why would I want to intentionally cause a compiler error? One potential use case is displaying a migration message for a removed API.

<blockquote class="twitter-tweet"><p lang="en" dir="ltr">
Restligeist macro: n. A macro that fails immediately to display migration message after implementation has been removed from the API.</p>&mdash; ∃ugene yokot∀ (@eed3si9n) 
<a href="https://twitter.com/eed3si9n/status/770584274819055617?ref_src=twsrc%5Etfw">August 30, 2016</a>
</blockquote>

For example, if you try to use `<<=` in sbt 1.3.8 you'd get the following error on load:

<scala>
/tmp/hello/build.sbt:13: error: `<<=` operator is removed. Use `key := { x.value }` or `key ~= (old => { newValue })`.
See http://www.scala-sbt.org/1.x/docs/Migrating-from-sbt-013x.html
    foo <<= test,
        ^
[error] sbt.compiler.EvalException: Type error in expression
[error] Use 'last' for the full log.
Project loading failed: (r)etry, (q)uit, (l)ast, or (i)gnore?
</scala>

It's good that it's doable, but using a macro for this is too pompous. According to [Yoshida-san][1], you can do this in Haskell just by putting `Whoops` in the type signature:

<code>
-- | This function is being removed and is no longer usable.
-- Use 'Data.IntMap.Strict.insertWith'
insertWith' :: Whoops "Data.IntMap.insertWith' is gone. Use Data.IntMap.Strict.insertWith."
            => (a -> a -> a) -> Key -> a -> IntMap a -> IntMap a
insertWith' _ _ _ _ = undefined
</code>

### configurable warnings

In March 2019, I sent a pull request [#7790][7790] to scala/scala proposing `@compileTimeError` annotation. The pull request evolved into `@restricted` annotation and configurable warning option `-Wconf`. The idea was that `@restricted` can tag methods with labels, and `-Wconf` would be able to escalate the tag to either a warning or an error like `-Wconfig apiMayChange:foo.*:error`.

Unfortunately [#7790][7790] got shot down as we were approaching Scala 2.13.0, but `-Wconfig` was resurrected during the summer by Lukas Rytz ([@lrytz](https://twitter.com/lrytz)) as a general-purpose filter [#8373][8373] that can configure any warnings by the category, message content, source, origin, or the deprecation `since` field. Using this the library users will be able to toggle deprecation messages from certain version as error etc. [#8373][8373] is merged and will be part of Scala 2.13.2.

### ApiMayChange annotation

As an example of denoting a "status" of API, Lightbend's Akka library has a few interesting ones. For example [ApiMayChange][ApiMayChange] denotes that the tagged APIs are exempt from the normal binary compatibility guarantees, basically a beta feature that might evolve in the future.

This would be an interesting tag for any long-supported libraries. One interesting aspect of this annotation is that it's purely a social convention. Meaning that the compiler will not print any warnings if you call the "may change" API.

### apiStatus annotation (proposal)

`-Wconfig` is useful, but currently the only tool given to library authors are `@deprecated` annotation to trigger a warning without resorting to a macro. A week ago, I sent [#8820][8820] to scala/scala proposing the idea of `@apiStatus` that enables user-land compiler warnings and errors.

Here are some examples. Let's say we want to make `<<=` method an error.

<scala>
import scala.annotation.apiStatus, apiStatus._

@apiStatus(
  "method <<= is removed; use := syntax instead",
  category = Category.ForRemoval,
  since = "foo-lib 1.0",
  defaultAction = Action.Error,
)
def <<=(): Unit = ???
</scala>

Here how it would look if someone calls this method:

<code>
example.scala:26: error: method <<= is removed; use := syntax instead (foo-lib 1.0)
  <<=()
  ^
</code>

So the custom compiler message works.

### implementing ApiMayChange

Let's try implementing ApiMayChange annotation.

<scala>
package foo

import scala.annotation.apiStatus, apiStatus._

@apiStatus(
  "should DSL is incubating, and future compatibility is not guaranteed",
  category = Category.ApiMayChange,
  since = "foo-lib 1.0",
  defaultAction = Action.Silent,
)
implicit class ShouldDSL(s: String) {
  def should(o: String): Unit = ()
}
</scala>

Following Akka, I chose the default action to be `Action.Silent` so it won't display a warning. Here's where `-Wconf` can shine. Using `-Wconf:cat=api-may-change&origin=foo\..*:warning` option, the user can enable "api-may-change" category just for `foo.*` package.

<code>
example.scala:28: warning: should DSL is incubating, and future compatibility is not guaranteed (foo-lib 1.0)
  "bar" should "something"
  ^
</code>

If you want to make it a warning by default you can also change it to `defaultAction = Action.Warning`.

### user-land warnings and errors

The `category` field is just a String so you can use your imagination on what kind of useful tagging you can do to denote your classes and methods. (This should also make it easy to backport to older Scala for cross building).

In general, what do you think about the idea of user-land warnings and errors? Please let us know by hitting +1/-1 or commenting on [#8820][8820].
