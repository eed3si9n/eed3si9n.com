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
    # hack
    $ git commit ...

The local files stay local until you push them, so commit all you want. Without the push privilege, you won't be able to push into the remote (origin) anyway.

To grab the latest as if you haven't hacked it yet,

    $ git pull --rebase

If you want to submit your local patch to the upstream, only then hit the "fork" button.
Next, add the fork as a remote repository:

    $ git remote add fork git@github.com:YOUR_USERNAME/sbt.git 
    
At this point `.git/config` looks as follows:
<code>[core]
  repositoryformatversion = 0
  filemode = true
  bare = false
  logallrefupdates = true
  ignorecase = true
[remote "origin"]
  fetch = +refs/heads/*:refs/remotes/origin/*
  url = http://github.com/sbt/sbt.git
[branch "master"]
  remote = origin
  merge = refs/heads/master
[remote "fork"]
  url = git@github.com:eed3si9n/sbt.git
  fetch = +refs/heads/*:refs/remotes/fork/*
</code>

Edit the aliases for the remote repositories as follows:
<code>[core]
  repositoryformatversion = 0
  filemode = true
  bare = false
  logallrefupdates = true
  ignorecase = true
[remote "upstream"]
  fetch = +refs/heads/*:refs/remotes/origin/*
  url = http://github.com/sbt/sbt.git
[branch "master"]
  remote = origin
  merge = refs/heads/master
[remote "origin"]
  url = git@github.com:eed3si9n/sbt.git
  fetch = +refs/heads/*:refs/remotes/fork/*
</code>

Now, `origin` points to your repository.

    $ git push

- [git guide by sourceforge.jp](http://sourceforge.jp/magazine/09/03/16/0831212)
- [you don't have to fork to hack](http://subtech.g.hatena.ne.jp/miyagawa/20090114/1231910461)
