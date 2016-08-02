  [1]: https://github.com/eed3si9n/gigahorse-github
  [plugin]: http://eed3si9n.com/gigahorse/plugin.html
  [dispatchplugin]: http://eed3si9n.com/howto-write-a-dispatch-plugin

[gigahorse-github 0.1.0][1] is released. This is a Gigahorse plugin for Github API v3.

Here’s a quick example of how to get repository info:

<scala>
scala> import gigahorse._, gigahorse.github.Github, scala.concurrent._, duration._

scala> val client = Github.localConfigClient
client: gigahorse.github.LocalConfigClient = LocalConfigClient(OAuthClient(****, List(StringMediaType(application/json), GithubMediaType(Some(v3),None,Some(json)))))

scala> Gigahorse.withHttp { http =>
         val f = http.run(client(Github.repo("eed3si9n", "gigahorse-github")), Github.asRepo)
         Await.result(f, 2.minutes)
       }
res0: gigahorse.github.response.Repo = Repo(https://api.github.com/repos/eed3si9n/gigahorse-github, gigahorse-github, 64614221, User(https://api.github.com/users/eed3si9n, eed3si9n, 184683, Some(https://github.com/eed3si9n), Some(https://avatars.githubusercontent.com/u/184683?v=3), Some(), Some(User), Some(true), None, None), eed3si9n/gigahorse-github, Some(Gigahorse plugin for Github API v3),...
</scala>

If you're interested in gigahorse-github itself, [README][1] contains the full documentation.

### extending Gigahorse

I also wrote [Extending Gigahorse][plugin] page describing the overview of how to write a Gigahorse plugin, which is more or less the same as how one would write a Dispach plugin. As I wrote there, the JSON data binding is auto generated from a schema.

For me, gigahorse-github was as much a proof of concept for sbt-datatype as it was for Gigahorse. It did end up exposing minor bugs on all components along the stack, so it was a fruitful exercise.
