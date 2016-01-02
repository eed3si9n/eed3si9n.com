## global gitignore

See [Create a global .gitignore](https://help.github.com/articles/ignoring-files).

    $ git config --global core.excludesfile ~/.gitignore_global

## checking out pull requests locally

See [Checking out pull requests locally](https://gist.github.com/piscisaureus/3342247).

<code>[remote "origin"]
        url = git@github.com:sbt/sbt.git
        fetch = +refs/heads/*:refs/remotes/origin/*
        fetch = +refs/pull/*/head:refs/remotes/origin/pr/*</code>

Or if you're calling it "upstream",

<code>[remote "upstream"]
        url = git@github.com:sbt/sbt.git
        fetch = +refs/heads/*:refs/remotes/upstream/*
        fetch = +refs/pull/*/head:refs/remotes/upstream/pr/*</code>

The third line in the above adds pull request Git refs to the fetch list.

    $ git fetch upstream
    From github.com:sbt/sbt
     * [new ref]         refs/pull/1/head -> upstream/pr/1
     * [new ref]         refs/pull/1002/head -> upstream/pr/1002
     * [new ref]         refs/pull/1003/head -> upstream/pr/1003
     * [new ref]         refs/pull/1005/head -> upstream/pr/1005

This creates Git ref `remotes/upstream/pr/*`. To make a tracking branch:

    $ git co pr/1467
    Branch pr/1467 set up to track remote branch pr/1467 from upstream.
    Switched to a new branch 'pr/1467'

## signing tag

See [Tagging](http://git-scm.com/book/en/Git-Basics-Tagging)

    $ git tag -s v1.5 -m 'my signed 1.5 tag'

## checking out remote branch

    $ git fetch upstream
    $ git ba
    ....
    remotes/upstream/wip/exclude-rules-ivy
    ....
    $ git co wip/exclude-rules-ivy
    Branch wip/exclude-rules-ivy set up to track remote branch wip/exclude-rules-ivy from upstream.
    Switched to a new branch 'wip/exclude-rules-ivy'

## hacking on a topic branch

Create and switch to the topic branch:

    $ git checkout -b try/parser

Merge changes from master, pretending it occurred before the topic branch:

    $ git rebase master

Switch back to the master:
  
    $ git checkout master

Merge changes from a try branch in a single commit (if you want):

    $ git merge --squash try/parser
(note this will cause conflict for all changes in the future if you try to merge in normal fashion.)

Force delete a try branch:

    $ git branch -D try/parser

## hacking after forking on github

    $ git remote add upstream git@github.com:sbt/sbt.git
    $ git fetch upstream

To track remote branch locally:

    $ git checkout --track upstream/0.13.2
    Branch 0.13.2 set up to track remote branch 0.13.2 from upstream.
    Switched to a new branch '0.13.2'

## hacking without forking on github

    $ git clone git://github.com/sbt/sbt.git
    $ cd sbt
    $ git checkout -b topic/foo
    # hack
    $ git commit ...

The local files stay local until you push them, so commit all you want. Without the push privilege, you won't be able to push into the remote (origin) anyway.

To rename the remove origin to upstream,

    $ git remote rename origin upstream

To grab the latest as if you haven't hacked it yet,

    $ git pull --rebase upstream master

Hit the "fork" button on Github. Next, add the fork as a remote repository:

    $ git remote add origin git@github.com:YOUR_USERNAME/sbt.git 

Now, `origin` points to your repository.

    $ git push --set-upstream origin topic/foo

- [git guide by sourceforge.jp](http://sourceforge.jp/magazine/09/03/16/0831212)
- [you don't have to fork to hack](http://subtech.g.hatena.ne.jp/miyagawa/20090114/1231910461)
- [yuroyoro's git alises](http://yuroyoro.hatenablog.com/entry/20101008/1286531851)
- [Git push existing repo to a new and different remote repo server?](http://stackoverflow.com/q/5181845/3827)
