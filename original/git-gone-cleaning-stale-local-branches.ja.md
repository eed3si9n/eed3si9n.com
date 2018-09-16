  [1]: http://erikaybar.name/git-deleting-old-local-branches/
  [2]: https://git-scm.com/docs/git-branch#git-branch---delete
  [3]: https://git-scm.com/docs/git-branch#git-branch---merged

GitHub の pull request を中心に作業していると、やたらといらないブランチがローカルに溜まってくる。本稿では、このいらないローカルブランチを掃除する方法をみてみる。

基本的に 2つの戦略があると思う:
- "master" ブランチを選んで、そこにマージ済みのものを削除する
- GitHub 上で既にブランチは削除されている前提で、リモートの "origin" にはもう無いローカルのブランチを削除する

Erik Aybar さんの [Git Tip: Deleting Old Local Branches][1] というブログ記事は第2の方法をとっている。

<blockquote class="twitter-tweet" data-lang="en"><p lang="en" dir="ltr">This just helped clean up 150+ old local branches for me this morning, so I thought I should share! <a href="https://twitter.com/hashtag/git?src=hash&amp;ref_src=twsrc%5Etfw">#git</a><a href="https://t.co/VLKLtl5inp">https://t.co/VLKLtl5inp</a></p>&mdash; Erik Aybar (@erikaybar_) <a href="https://twitter.com/erikaybar_/status/826452297190404096?ref_src=twsrc%5Etfw">January 31, 2017</a></blockquote>

### git gone

`git gone` は、Erik Aybar さんのテクニックをベースに僕が書いたカスタム git コマンドだ。Bash でスクリプト書くのは不慣れなので Google とか Stackoverflow を見ながら書いたが、一応動いてくれていると思う。[eed3si9n/git-gone](https://github.com/eed3si9n/git-gone) にソースを貼ったのでそれを `~/bin` など適当な場所に `git-gone` として保存する。

使い方は `git gone` と打てば出てくるようにした:

<code>
$ git gone
usage: git gone [-pndD] [<branch>=origin]
OPTIONS
  -p  prune remote branch
  -n  dry run: list the gone branches
  -d  delete the gone branches
  -D  delete the gone branches forcefully

EXAMPLES
git gone -pn  prune and dry run
git gone -d   delete the gone branches
</code>

まずは remote を (`remotes/origin/` 内で) トラッキングしてるブランチを削除する必要がある。これはプルーニング (pruning) と呼ばれる。

次に、トラッキングブランチが無くなったローカルのブランチを列挙する。`git gone -pn` はこのステップを組み合わせる:

<code>
$ git gone -pn
  bport/fix-server-broadcast         b472d5d2b [origin/bport/fix-server-broadcast: gone] Bump modules
  fport/rangepos                     45c857d15 [origin/fport/rangepos: gone] Bump modules
  fport/scalaCompilerBridgeBinaryJar 7eab02fff [origin/fport/scalaCompilerBridgeBinaryJar: gone] Add scalaCompilerBridgeBinaryJar task
  wip/1.2.0                          305a8de31 [origin/wip/1.2.0: gone] 1.2.1-SNAPSHOT
  wip/allfix                         f4ae03802 [origin/wip/allfix: gone] Fix single repo emulation script
  wip/bump                           a1d1c7731 [origin/wip/bump: gone] Zinc 1.2.1, IO 1.2.1
  wip/bumpvscodemodules              fa3b0f031 [origin/wip/bumpvscodemodules: gone] sbt 1.2.1
  wip/bumpzinc                       29fa4fb20 [origin/wip/bumpzinc: gone] Zinc 1.2.0-M2
  wip/disable-flaky-test             aa7c2cde3 [origin/wip/disable-flaky-test: gone] Disable eval-is-safe-and-sound test
  wip/license                        4ff4f6e45 [origin/wip/license: gone] Update header
  wip/link                           d40d3fe29 [origin/wip/link: gone] Fix CONTRIBUTING and link to it
  wip/merge-1.2.x                    42a4ae33f [origin/wip/merge-1.2.x: gone] Merge branch 'wip/bumpvscodemodules' into wip/merge-1.2.x
  wip/parser                         4ecb3a3f7 [origin/wip/parser: gone] Fix bimcompat breakages in complete
  wip/rangepos                       48418408b [origin/wip/rangepos: gone] Follow up on Position extension
  wip/remove-configuration-warning   780ca366d [origin/wip/remove-configuration-warning: gone] Remove warnings about configuration
  wip/switch                         1bf6f0d2a [origin/wip/switch: gone] Make ++ fail when it doesn't affect any subprojects
  wip/vararg                         26c180e76 [origin/wip/vararg: gone] Revert "Switch inThisBuild (+friends) to use varargs SettingsDefinition"
</code>

次に、以下のようにしてブランチを削除する:

<code>
$ git gone -d
error: The branch 'bport/fix-server-broadcast' is not fully merged.
If you are sure you want to delete it, run 'git branch -D bport/fix-server-broadcast'.
Deleted branch fport/rangepos (was 45c857d15).
Deleted branch fport/scalaCompilerBridgeBinaryJar (was 7eab02fff).
Deleted branch wip/1.2.0 (was 305a8de31).
Deleted branch wip/allfix (was f4ae03802).
Deleted branch wip/bump (was a1d1c7731).
Deleted branch wip/bumpvscodemodules (was fa3b0f031).
Deleted branch wip/bumpzinc (was 29fa4fb20).
Deleted branch wip/disable-flaky-test (was aa7c2cde3).
Deleted branch wip/license (was 4ff4f6e45).
Deleted branch wip/link (was d40d3fe29).
Deleted branch wip/merge-1.2.x (was 42a4ae33f).
Deleted branch wip/parser (was 4ecb3a3f7).
error: The branch 'wip/rangepos' is not fully merged.
If you are sure you want to delete it, run 'git branch -D wip/rangepos'.
Deleted branch wip/remove-configuration-warning (was 780ca366d).
Deleted branch wip/switch (was 1bf6f0d2a).
Deleted branch wip/vararg (was 26c180e76).
</code>

いくつかのブランチの削除に失敗したことに注目してほしい。これは [`git branch -d`][2] が、ブランチがトラッキングブランチもしくは `HEAD` にマージされていることを要請するからだ。現在の僕の `HEAD` が `develop` ブランチであるため、バックポート用のブランチ 2つが削除に失敗している。`-D` を渡すことで強制削除できる:

<code>
$ git gone -D
Deleted branch bport/fix-server-broadcast (was b472d5d2b).
Deleted branch wip/rangepos (was 48418408b).
</code>

### 戦略1も見てみよう

17個のブランチを削除できたので捗ったと言えるが、まだ古いブランチが残っているみたいだ。pull request の参照やローカルで作られたブランチみたいだ。

`git branch` には [`git branch --merged`][3] というオプションがあって、`HEAD` (現行のブランチ) にマージされたブランチだけを表示することができる。Git workflow とかを採用していて複数のアクティブなブランチを持っている場合は自然と stable branch とか feature branch みたいにマージ済みではあるが削除したくないブランチも作られたりするので、この方法は少し気をつける必要がある。

マージ済みのブランチを一覧は以下のようにして得る:

<code>
$ git branch --merged | grep -v "\*"
  1.0.x
  1.1.x
  pr/4194
  pr/4221
  wip/contributing
  wip/crossjdk
  wip/launcher
</code>

ここに `grep` をチェインさせて例えばブランチ名が `pr/` か `wip/` で始まるものだけを表示させる:

<code>
$ git branch --merged | grep -v "\*" | grep "wip/\|pr/"
  pr/4194
  pr/4221
  wip/contributing
  wip/crossjdk
  wip/launcher
</code>

これらを削除するには `git branch -d` にパイプで渡す:

<code>
$ git branch --merged | grep -v "\*" | grep "wip/\|pr/" | xargs git branch -d
Deleted branch pr/4194 (was e465aee36).
Deleted branch pr/4221 (was 59465d9e1).
Deleted branch wip/contributing (was 5b8272b93).
Deleted branch wip/crossjdk (was 7f808bd3a).
Deleted branch wip/launcher (was fa56cf394).
</code>

### まとめ

ローカルの git リポジトリをきれいにする 2つの戦略を見た。

1. `git gone` を使って "origin" ブランチの削除をローカルにシンクロさせる。
2. `git branch --merged` を使ってローカルブランチを削除する。
