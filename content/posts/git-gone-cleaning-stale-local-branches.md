---
title:       "git gone: cleaning stale local branches"
type:        story
date:        2018-09-15
changed:     2018-09-16
draft:       false
promote:     true
sticky:      false
url:         /git-gone-cleaning-stale-local-branches
aliases:     [ /node/271 ]
tags:        [ "git" ]
---

  [1]: http://erikaybar.name/git-deleting-old-local-branches/
  [2]: https://git-scm.com/docs/git-branch#git-branch---delete
  [3]: https://git-scm.com/docs/git-branch#git-branch---merged

Working with GitHub and pull requests a lot, I end up accumulating stale branches that are no longer needed. In this post, we will look at how to clean the stale local branches.

There are mainly two strategies:
- Pick a "master" branch, and delete what's merged to it
- Assuming branches are deleted first on GitHub, delete local branches that no longer exists on remote "origin"

Erik Aybar's [Git Tip: Deleting Old Local Branches][1] takes the second approach.

<blockquote class="twitter-tweet" data-lang="en"><p lang="en" dir="ltr">This just helped clean up 150+ old local branches for me this morning, so I thought I should share! <a href="https://twitter.com/hashtag/git?src=hash&amp;ref_src=twsrc%5Etfw">#git</a><a href="https://t.co/VLKLtl5inp">https://t.co/VLKLtl5inp</a></p>&mdash; Erik Aybar (@erikaybar_) <a href="https://twitter.com/erikaybar_/status/826452297190404096?ref_src=twsrc%5Etfw">January 31, 2017</a></blockquote>

### git gone

`git gone` is a custom git command that I wrote based on Erik Aybar's technique. I'm not comfortable with Bash scripting, so it took me some Googling and Stackoverflowing, but hopefully it does the job. Save the source in [eed3si9n/git-gone](https://github.com/eed3si9n/git-gone) as `git-gone` in `~/bin` or wherever you keep your local scripts.

To read how to use it type in `git gone`:

```bash
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
```

First we need to delete the remote tracking branches (in `remotes/origin/`). This is called pruning.

Next, we want to list the branches local branches whose tracking branches are now gone. `git gone -pn` combines these steps:

```bash
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
```

Next, we can delete these branches as follows:

```bash
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
```

Note that a few branches failed to delete. This is because [`git branch -d`][2] requires the branch to be merged either to the tracking branch or in `HEAD`. Since my current `HEAD` is on `develop` branch, the two backport branches failed to delete. We can pass `-D` to git gone to delete them:

```bash
$ git gone -D
Deleted branch bport/fix-server-broadcast (was b472d5d2b).
Deleted branch wip/rangepos (was 48418408b).
```

### following up with strategy 1

I just deleted 17 branches, so that's a progress, but I am still seeing some branches that look old. Some of pull request references, and others might be local branches.

There's an option in `git branch` called [`git branch --merged`][3] that shows only the branches that are merged to `HEAD` (current branch). If you're using Git workflow with multiple active branches, you can end up with stable branches or feature branches that are fully merged but you do not want to delete, so you have to be careful with this one.

Here's how to list merged branches:

```bash
$ git branch --merged | grep -v "\*"
  1.0.x
  1.1.x
  pr/4194
  pr/4221
  wip/contributing
  wip/crossjdk
  wip/launcher
```

We can chain `grep` to list only the branches that start with `pr/` or `wip/` for example:

```bash
$ git branch --merged | grep -v "\*" | grep "wip/\|pr/"
  pr/4194
  pr/4221
  wip/contributing
  wip/crossjdk
  wip/launcher
```

To delete these we pipe to `git branch -d` as follows:

```bash
$ git branch --merged | grep -v "\*" | grep "wip/\|pr/" | xargs git branch -d
Deleted branch pr/4194 (was e465aee36).
Deleted branch pr/4221 (was 59465d9e1).
Deleted branch wip/contributing (was 5b8272b93).
Deleted branch wip/crossjdk (was 7f808bd3a).
Deleted branch wip/launcher (was fa56cf394).
```

### summary

We've looked at two different strategies for making local git repository tidier.

1. Using `git gone` to sync the "origin" branch deletion with local deletion.
2. Using `git branch --merged` to delete local branches.
