---
title:       "auto publish (a website) from Travis-CI"
type:        story
date:        2017-07-19
changed:     2019-09-16
draft:       false
promote:     true
sticky:      false
url:         /auto-publish-from-travis-ci
aliases:     [ /node/229 ]
tags:        [ "sbt" ]
---

GitHub Pages is a convenient place to host OSS project docs.
This post explains how to use Travis CI to deploy your docs automatically on a pull request merge.

### 1. Generate a fresh RSA key in some directory

Make a directory outside of your project first.
Pick a key name `deploy_yourproject_rsa`, so you can distinguish it from other keys.

<code>
$ mkdir keys
$ cd keys
$ ssh-keygen -t rsa -b 4096 -C "yours@example.com"
Generating public/private rsa key pair.
Enter file in which to save the key (/Users/xxx/.ssh/id_rsa): deploy_website_rsa
Enter passphrase (empty for no passphrase):
</code>

Keep the passphrase empty.

### 2. Switch to your website project

Move to your website project, start a branch on your project, and create `.travis` directory.

<code>
$ cd ../website
$ mkdir .travis
</code>

### 3. Install `travis` utility, and encrypt the private key

Run `travis encrypt-file --repo foo/website ../website_keys/deploy_website_rsa .travis/deploy_rsa.enc` where `--repo foo/website` represents your GitHub repo.

**Note**: If you don't specify `--repo` it will pick up on git origin, which for me often points to my private fork.

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

See [Encrypting Files](https://docs.travis-ci.com/user/encrypting-files/). Double check that your environmental variables are set correctly by going to the Travis Settings <https://travis-ci.org/foo/website/settings>. You should see the entries for the encrypted key and the initialization vector (iv).

### 4. Add publish-site.sh

Add `publish-site.sh` under `.travis` directory.

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

  - Replace `"master"` with your branch.
  - Replace `"foo/website"` with your repo.
  - Replace `-K $encrypted_1234_key -iv $encrypted_1234_iv` with your own.

<code>
$ chmod +x .travis/publish-site.sh
</code>

This script was originally [written](https://github.com/foundweekends/conscript/commit/3dbeca317c363ca4c224ba4d5f0f9eb44a64d1bf) by Yoshida-san. According to [him](https://twitter.com/xuwei_k/status/887519941884129284), this was in turn based on [GitHub push from Travis](http://blog.eiel.info/blog/2014/02/18/github-push-from-travis/) by eiel.

### 5. Edit .travis.yml

<code>
after_success:
  - .travis/publish-site.sh
</code>

### 6. Add public key to the GitHub pages repo

Go to the GitHub pages repo, Settings > Deploy keys https://github.com/foo/foo.github.com/settings/keys, and add the content of your public key `deploy_website_rsa.pub`. Name the entry as `travis-ci-website` or something along the line so you'll remember what it's for.

### 7. During syncLocal configure git

The following is specific to the behavior of sbt-ghpages. It might not be needed if you're doing something else.

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

### A note about Pamflet + Pandoc

Travis CI's rencent build environments allow the use of `apt-get` inside the container-based images, so now we can install `latex-cjk-all` and `pandoc` in addition to `sbt`.

Because [Pamflet](http://www.foundweekends.org/pamflet/) can generate a single-page markdown file per localized languages, I can not only automatically deploy the static HTML website, but also build PDF document both in [English](https://github.com/sbt/sbt.github.com/blob/14cea8077dc369b7998b7fe59d958a4bf4c418a0/1.0/docs/sbt-reference.pdf) and [Japanese](https://github.com/sbt/sbt.github.com/blob/14cea8077dc369b7998b7fe59d958a4bf4c418a0/1.0/docs/ja/sbt-reference.pdf) from Travis CI.
