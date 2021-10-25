---
title:       "user-land compiler warnings in Scala, part 2"
type:        story
date:        2020-04-05
draft:       false
promote:     true
sticky:      false
url:         /user-land-compiler-warnings-in-scala-part2
aliases:     [ /node/321 ]
---

  [8820]: https://github.com/scala/scala/pull/8820
  [ApiMayChange]: https://doc.akka.io/docs/akka/current/common/may-change.html

[Last week](http://eed3si9n.com/user-land-compiler-warnings-in-scala) I wrote about [#8820][8820], my proposal to add user-land compiler warnings in Scala. The example I had was implementing `ApiMayChange` annotation.

```scala
package foo

import scala.annotation.apiStatus, apiStatus._

@apiStatus(
  "should DSL is incubating, and future compatibility is not guaranteed",
  category = Category.ApiMayChange,
  since = "foo-lib 1.0",
  defaultAction = Action.Warning,
)
implicit class ShouldDSL(s: String) {
  def should(o: String): Unit = ()
}
```

This was ok as a start, but a bit verbose. If we want some API status to be used frequently, it would be cool if library authors could define their own status annotation. We're going to look into doing that today.

Before we get into that, we need to step into a bit of behind-the-scenes. When the compiler looks at annotations the information is given as `AnnotationInfo`, which contains the arguments as Trees. We will have the source code of the call site, but we won't know if the annotation code did something in the constructor. On the other hand, we will have the annotations tagged to the annotation class.

### implementing ApiMayChange again

The annotations designed specifically for annotations are called meta-annotations (yo dawg), and that's how we can extend `apiStatus`:

```scala
import scala.annotation.{ apiStatus, apiStatusCategory, apiStatusDefaultAction }
import scala.annotation.meta._

@apiStatusCategory("api-may-change")
@apiStatusDefaultAction(apiStatus.Action.Warning)
@companionClass @companionMethod
final class apiMayChange(
  message: String,
  since: String = "",
) extends apiStatus(message, since = since)
```

Instead of passing `category` and `defaultAction` into the `extends apiStatus(....)`, we will pass that along using `@apiStatusCategory` and `@apiStatusDefaultAction`.

Once this is defined, tagging of the API becomes much cleaner:

```scala
@apiMayChange("can DSL is incubating, and future compatibility is not guaranteed")
implicit class CanDSL(s: String) {
  def can(o: String): Unit = ()
}
```

As a reminder, the point of all this is so library authors can tag the APIs to trigger compiler errors and warnings.

```scala
scala> "foo" can "say where the road goes?"
       ^
       warning: can DSL is incubating, and future compatibility is not guaranteed
```

### user-land warnings and errors

Using meta-annotation technique, we were able to extend `apiStatus` so we can tag APIs using a custom status annotation.
