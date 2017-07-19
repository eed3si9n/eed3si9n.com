GitHub Pages は OSS プロジェクトのドキュメントをホスティングするのに便利だ。
ここでは Travis CI を使って pull request の merge 時に自動デプロイする方法を説明する。

### 1. 新しい RSA キーを適当なディレクトリ内で生成する。

プロジェクト外にまずはディレクトリを作る。
キーの名前は `deploy_yourproject_rsa` などとつけて、他のキーと区別できるようにする。

<code>
$ mkdir keys
$ cd keys
$ ssh-keygen -t rsa -b 4096 -C "yours@example.com"
Generating public/private rsa key pair.
Enter file in which to save the key (/Users/xxx/.ssh/id_rsa): deploy_website_rsa
Enter passphrase (empty for no passphrase):
</code>

パスフレーズは空のままにする。

### 2. ウェブサイトプロジェクトに移動する。

プロジェクトに移動して、ブランチを立てて、`.travis` という名前のディレクトリを作る。

<code>
$ cd ../website
$ mkdir .travis
</code>

### 3. `travis` ユーティリティをインストールして、秘密鍵を暗号化する。

`travis encrypt-file --repo foo/website ../website_keys/deploy_website_rsa .travis/deploy_rsa.enc` を実行する。ここで、`--repo` は GitHub レポジトリを指定する。

**注意**: `--repo` を指定しないと、git origin が使われることになるが、僕の場合これはフォークを指しているので正しくないレポジトリになってしまう。

<code>
$ gem install travis
$ travis login --auto
$ travis encrypt-file --repo foo/website ../website_keys/deploy_website_rsa .travis/deploy_rsa.enc
encrypting ../keys/deploy_website_rsa for foo/website
storing result as .travis/deploy_rsa.enc
storing secure env variables for decryption

Please add the following to your build script (before_install stage in your .travis.yml, for instance):

    openssl aes-256-cbc -K $encrypted_1234_key -iv $encrypted_1234_iv -in .travis/deploy_rsa.enc -out ../website_keys/deploy_website_rsa -d

Pro Tip: You can add it automatically by running with --add.

Make sure to add .travis/deploy_rsa.enc to the git repository.
Make sure not to add ../website_keys/deploy_website_rsa to the git repository.
Commit all changes to your .travis.yml.
</code>

[Encrypting Files](https://docs.travis-ci.com/user/encrypting-files/) を参照。Travis Settings <https://travis-ci.org/foo/website/settings> に行って、環境変数がセットされたか再確認する。うまくいったならば、暗号キーと初期化ベクトル (iv) の変数が見えるはずだ。

### 4. publish-site.sh を追加する。

`.travis` ディレクトリ内に `publish-site.sh` というスクリプトを作る。

<code>
#!/bin/bash -ex

if [[ "${TRAVIS_PULL_REQUEST}" == "false" && "${TRAVIS_BRANCH}" == "master" && "${TRAVIS_REPO_SLUG}" == "foo/website" ]]; then
  openssl version
  echo -e "Host github.com\n\tStrictHostKeyChecking no\nIdentityFile ~/.ssh/deploy_rsa\n" >> ~/.ssh/config
  openssl aes-256-cbc -K $encrypted_1234_key -iv $encrypted_1234_iv -in .travis/deploy_rsa.enc -out .travis/deploy_rsa -d
  chmod 600 .travis/deploy_rsa
  cp .travis/deploy_rsa ~/.ssh/
  sbt ghpagesPushSite
fi
</code>

  - `"master"` をブランチに置き換える。
  - `"foo/website"` 自分のリポジトリに置き換える。
  - `-K $encrypted_1234_key -iv $encrypted_1234_iv` を自分のものに置き換える。

<code>
$ chmod +x .travis/publish-site.sh
</code>

このスクリプトは吉田さんが[書いたもの](https://github.com/foundweekends/conscript/commit/3dbeca317c363ca4c224ba4d5f0f9eb44a64d1bf)を使っている。えいるさんの [Travis-CI でコミットして GitHub にプッシュする - 公開鍵認証を利用してみる](http://blog.eiel.info/blog/2014/02/18/github-push-from-travis/) がさらに[元ネタ](https://twitter.com/xuwei_k/status/887519941884129284)になっているらしい。

### 5. .travis.yml を編集する。

<code>
after_success:
  - .travis/publish-site.sh
</code>

### 6. 公開鍵を GitHub Page のリポジトリに追加する。

GitHub Page に使っているリポジトリ内の Settings > Deploy keys https://github.com/foo/foo.github.com/settings/keys に行って公開鍵 `deploy_website_rsa.pub` の内容を追加する。このエントリーは `travis-ci-website` と名前をつけて後で思い出せるようにする。

### 7. syncLocal 時に git の設定を行う。

以下は、sbt-ghpages に特定の設定なので、別のことをやっているならばいらないかもしれない。

<code>
  lazy val siteEmail = settingKey[String]("")

  val syncLocalImpl = Def.task {
    // sync the generated site
    val repo = ghkeys.updatedRepository.value
    val git = GitKeys.gitRunner.value
    val s = streams.value

    gitConfig(repo, siteEmail.value, git, s.log)
    ....
    repo
  }

  def gitConfig(dir: File, email: String, git: GitRunner, log: Logger): Unit =
    sys.env.get("CI") match {
      case Some(_) =>
        git(("config" :: "user.name" :: "Travis CI" :: Nil) :_*)(dir, log)
        git(("config" :: "user.email" :: email :: Nil) :_*)(dir, log)
      case _           => ()
    }
</code>

### Pamflet + Pandoc に関して

Travis CI の最近のビルド環境はコンテナ・ベースの環境でも `apt-get` を使えるようになったので、`sbt` の他にも `latex-cjk-all` とか `pandoc` をインストールすることができる。

[Pamflet](http://www.foundweekends.org/pamflet/ja/) はローカライズされた言語ごとに全ページをまとめた単一ページ markdown ファイルを出力することができるので、Travis CI から static HTML ウェブサイトをデプロイするだけじゃなくて、[英語](https://github.com/sbt/sbt.github.com/blob/14cea8077dc369b7998b7fe59d958a4bf4c418a0/1.0/docs/sbt-reference.pdf)と[日本語](https://github.com/sbt/sbt.github.com/blob/14cea8077dc369b7998b7fe59d958a4bf4c418a0/1.0/docs/ja/sbt-reference.pdf)の PDF ドキュメントをビルドすることもできる。
