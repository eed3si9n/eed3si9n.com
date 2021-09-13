---
title:       "ユーザランドでの警告とエラー、パート2"
type:        story
date:        2020-04-05
draft:       false
promote:     true
sticky:      false
url:         /ja/user-land-compiler-warnings-in-scala-part2
aliases:     [ /node/322 ]
---

  [8820]: https://github.com/scala/scala/pull/8820
  [ApiMayChange]: https://doc.akka.io/docs/akka/current/common/may-change.html

[先週](http://eed3si9n.com/ja/user-land-compiler-warnings-in-scala)は、Scala でユーザランドから警告を出す仕組みの提案である [#8820][8820] について書いた。例として `ApiMayChange` アノテーションを実装した。

<scala>
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
</scala>

これは始めとしては一応使えるけども、少し冗長だ。もしなんらかの API ステータスが頻繁に使われる場合、ライブラリ作者が独自のステータスアノテーションを定義できると嬉しいと思う。今日はその方法を考える。

その前に少し裏方の解説を必要とする。コンパイラがアノテーションを見る時この情報は `AnnotationInfo` として渡され、引数は構文木で表される。これによってコールサイトのソースコードはあるが、アノテーションのコードがコンストラクタで何かやったなどの事は分からない。一方、アノテーションクラスにタグ付けされたアノテーションのことは分かる。

### ApiMayChange の実装再び

アノテーションのに付けることを前提に作られたアノテーションはメタアノテーションと呼ばれ、これを使うことで `apiStatus` の継承を行うことができる:

<scala>
import scala.annotation.{ apiStatus, apiStatusCategory, apiStatusDefaultAction }
import scala.annotation.meta._

@apiStatusCategory("api-may-change")
@apiStatusDefaultAction(apiStatus.Action.Warning)
@companionClass @companionMethod
final class apiMayChange(
  message: String,
  since: String = "",
) extends apiStatus(message, since = since)
</scala>

`category` や `defaultAction` を `extends apiStatus(....)` で渡すのではなく `@apiStatusCategory` と `@apiStatusDefaultAction` を使って指定する。

一度これを定義してしまうと API のタグ付けは綺麗になる:

<scala>
@apiMayChange("can DSL is incubating, and future compatibility is not guaranteed")
implicit class CanDSL(s: String) {
  def can(o: String): Unit = ()
}
</scala>

確認しておくと、この仕組みを使ってライブラリ作者が API をタグ付けしてコンパイラエラーや警告を出すのが目的だ。

<scala>
scala> "foo" can "say where the road goes?"
       ^
       warning: can DSL is incubating, and future compatibility is not guaranteed
</scala>

### ユーザランドでの警告とエラー

メタアノテーションというテクニックを使って `apiStatus` を継承して独自のステータスアノテーションを定義して API のタグ付けをすることができた。
