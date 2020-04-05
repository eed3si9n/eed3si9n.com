  [1]: https://twitter.com/xuwei_k/status/1232318081600389121
  [7790]: https://github.com/scala/scala/pull/7790
  [8373]: https://github.com/scala/scala/pull/8373
  [8820]: https://github.com/scala/scala/pull/8820
  [ApiMayChange]: https://doc.akka.io/docs/akka/current/common/may-change.html

一ライブラリ作者として、Scala でメソッドをタグ付けしてカスタムのコンパイラ警告やエラーを発動できるといいなと前から思っている。何故意図的にコンパイラエラーを出す必要があるのかと思うかもしれない。一つのユースケースとしては、API を廃止した後でマイグレーションのためのメッセージを表示させることだ。

<blockquote class="twitter-tweet"><p lang="en" dir="ltr">
Restligeist macro: n. A macro that fails immediately to display migration message after implementation has been removed from the API.</p>&mdash; ∃ugene yokot∀ (@eed3si9n) 
<a href="https://twitter.com/eed3si9n/status/770584274819055617?ref_src=twsrc%5Etfw">August 30, 2016</a>
</blockquote>

僕はこれを Restligeist macro、つまり地縛霊マクロと呼んでいる。例えば、sbt 1.3.8 において `<<=` を使うと以下のエラーメッセージが起動時に表示される。

<scala>
/tmp/hello/build.sbt:13: error: `<<=` operator is removed. Use `key := { x.value }` or `key ~= (old => { newValue })`.
See http://www.scala-sbt.org/1.x/docs/Migrating-from-sbt-013x.html
    foo <<= test,
        ^
[error] sbt.compiler.EvalException: Type error in expression
[error] Use 'last' for the full log.
Project loading failed: (r)etry, (q)uit, (l)ast, or (i)gnore?
</scala>

これ実現可能というのは良いことだけども、わざわざマクロを使わなければいけないのいうのが仰々しい。[吉田さん][1]によると Haskell だとこれぐらいのことは型シグネチャに `Whoops` と書くだけでできるらしい:

<code>
-- | This function is being removed and is no longer usable.
-- Use 'Data.IntMap.Strict.insertWith'
insertWith' :: Whoops "Data.IntMap.insertWith' is gone. Use Data.IntMap.Strict.insertWith."
            => (a -> a -> a) -> Key -> a -> IntMap a -> IntMap a
insertWith' _ _ _ _ = undefined
</code>

### configurable な警告

2019年3月に僕は scala/scala に [#7790][7790] という pull request を送って `@compileTimeError` というアノテーションを提案した。レビューの流れを受け入れているうち pull request は `@restricted` アノテーションと configurable な警告オプション `-Wconf` というものに変わっていった。`@restricted` はラベルによってメソッドのタグ付けを行い、`-Wconf` はそのタグを `-Wconfig apiMayChange:foo.*:error` というふうにして警告やエラーにエスカレートさせることができるというものだ。

Scala 2.13.0 のリリースが近かったということもあって残念ながら [#7790][7790] は撃沈させられてしまったが、その夏に同僚の Lukas Rytz ([@lrytz](https://twitter.com/lrytz)) の手によって `-Wconf` は全ての警告をカテゴリー、メッセージ内容、ソース、タグ元、deprecation の `since` フィールドによってふるい分ける汎用フィルター [#8373][8373] として復活した。これを使うことで例えば、ライブラリのユーザが特定のバージョンの廃止勧告だけをエラーにするということができるようになる。[#8373][8373] は既に merge されて、次の Scala 2.13.2 に入る予定だ。

### ApiMayChange アノテーション

API のステータスを表したものの一例として Lightbend の Akka ライブラリにいくつか面白いものがある。例えば、[ApiMayChange][ApiMayChange] はタグ付けされた API が通常のバイナリ互換性保証の例外であることを表す。つまり、これがついた機能はベータ版であって将来変わるかもしれないということだ。

これは長期的にサポートされるライブラリには便利なタグだと思う。このアノテーションの興味深い所はこれは純粋に社会的な慣習によってのみ成り立っていることだ。つまり、"may change" と言っている API を使ってもコンパイラは一切警告を出してくれない。

### apiStatus アノテーション(案)

`-Wconf` は便利だが、今のままでは警告を出すためにライブラリ作者に渡されたツールはマクロという手段を除くと `@deprecated` アノテーションのみだ。先週末 [#8820][8820] を scala/scala に送って `@apiStatus` というユーザーランドでコンパイラ警告やエラーを出せる仕組みを再提案した。

具体例を用いて説明する。例えば `<<=` メソッドをエラーにしたいとする。

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

このメソッドを呼び出すとこうなる:

<code>
example.scala:26: error: method <<= is removed; use := syntax instead (foo-lib 1.0)
  <<=()
  ^
</code>

カスタムでコンパイラーメッセージを出せるようになった。

### ApiMayChange を実装する

ApiMayChange アノテーションを実装してみよう。

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

Akka にならって、デフォルトのアクションは `Action.Silent` なので警告は表示されない。ここで `-Wconf` の出番だ。`-Wconf:cat=api-may-change&origin=foo\..*:warning` をオプションに渡すことで、ユーザサイドで `foo.*` パッケージ内の `api-may-change` というカテゴリーのみを警告にすることができる。

<code>
example.scala:28: warning: should DSL is incubating, and future compatibility is not guaranteed (foo-lib 1.0)
  "bar" should "something"
  ^
</code>

`defaultAction = Action.Warning` とすることでデフォルトでこれを警告にすることも可能だ。

### ユーザランドでの警告とエラー

`category` フィールドはただの String なので想像力を働かしてクラスやメソッドを好きなようにタグ付けすることができる。 (またクロスビルド用に古い Scala に自分で backport するのも容易になると思う)

とりあえず、ユーザランドでの警告やエラーというアイディアについてどう思うだろうか。[#8820][8820] で +1/-1 をポチっと押すかコメントでご意見を聞かせてほしい。
