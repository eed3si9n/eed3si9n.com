---
title:       "gigahorse-github 0.1.0"
type:        story
date:        2016-08-02
draft:       false
promote:     true
sticky:      false
url:         /ja/gigahorse-github-010
aliases:     [ /node/207 ]
---

  [1]: https://github.com/eed3si9n/gigahorse-github
  [plugin]: http://eed3si9n.com/gigahorse/ja/plugin.html
  [dispatchplugin]: http://eed3si9n.com/ja/howto-write-a-dispatch-plugin

[gigahorse-github 0.1.0][1] をリリースした。これは、Github API v3 のための Gigahorse プラグインだ。

<!--more-->

レポジトリ情報を取得する使用例はこんな感じだ:

```scala
scala> import gigahorse._, gigahorse.github.Github, scala.concurrent._, duration._

scala> val client = Github.localConfigClient
client: gigahorse.github.LocalConfigClient = LocalConfigClient(OAuthClient(****, List(StringMediaType(application/json), GithubMediaType(Some(v3),None,Some(json)))))

scala> Gigahorse.withHttp { http =>
         val f = http.run(client(Github.repo("eed3si9n", "gigahorse-github")), Github.asRepo)
         Await.result(f, 2.minutes)
       }
res0: gigahorse.github.response.Repo = Repo(https://api.github.com/repos/eed3si9n/gigahorse-github, gigahorse-github, 64614221, User(https://api.github.com/users/eed3si9n, eed3si9n, 184683, Some(https://github.com/eed3si9n), Some(https://avatars.githubusercontent.com/u/184683?v=3), Some(), Some(User), Some(true), None, None), eed3si9n/gigahorse-github, Some(Gigahorse plugin for Github API v3),...
```

gigahorse-github 本体に興味がある人は、[README][1] にドキュメンテーションがあるのでそちらを参照してほしい。

### Gigahorse を拡張する

Gigahorse プラグインの書き方を解説した[Gigahorse を拡張する][plugin]というページも書いた。
Dispatch プラグインの書き方とだいたい同じになっている。そこで書いたように、JSON データバインディングをスキーマから自動生成するという方法をとっている。

そのため、僕にとって gigahorse-github は Gigahorse の概念実証であると同じかそれ以上に sbt-datatype の概念実証であるという意味合いがある。やはりというか、全コンポーネントで細かいバグが出てきたので有益な演習だったといえる。
