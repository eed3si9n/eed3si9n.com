---
title:       "git bisecting scala/scala"
type:        story
date:        2021-02-06
draft:       false
promote:     true
sticky:      false
url:         /git-bisecting-scala-scala
aliases:     [ /node/379 ]
tags:        [ "scala" ]
tags:        [ "git" ]
Summary:
  git bisecting is a useful technique to locate the source of a bug. For scala/scala in particular, `bisect.sh` can save a lot of time by using the pre-build compiler artifacts on the Scala CI Artifactory.
---

<blockquote class="twitter-tweet"><p lang="en" dir="ltr">should I git bisect or watch Expanse?</p>&mdash; ∃ugene yokot∀ (@eed3si9n) <a href="https://twitter.com/eed3si9n/status/1352814320749576192?ref_src=twsrc%5Etfw">January 23, 2021</a></blockquote>

Scala compiler and the standard library are fairly stable overall, but you do come across weird behaviors as you start to increase the sample size or try to extend the internals.

Here's a quick tip on how to bisect across scala/scala commit history using a script written by Lukas Rytz.

### setting up the test build

First reproduce your issue using an sbt build. To be concrete, it should be something that used to work on one version of Scala but regressed in another. As an example, we can pick a resolved bug and try to find where it came from. Make a directory named `/tmp/bisectscala/` (you can choose whatever name).

#### build.sbt

```scala
ThisBuild / resolvers += "scala-integration" at "https://scala-ci.typesafe.com/artifactory/scala-integration/"
```

That's it for the build file.

#### Test.scala

```scala
object Test extends App {
  val x = Set[AnyVal](1L, (), 28028, -3.8661012E-17, -67)
  val y = Set[AnyVal](1, 3.3897517E-23, ())
  val z = x ++ y
  assert(z.size == 6)
}
```

This reproduces [scala/bug#11551](https://github.com/scala/bug/issues/11551), which was found during Scala 2.13.0-RC3 where adding two `Set`s produced 7 elements instead of 6.

#### project/build.properties

```scala
sbt.version=1.2.8
```

An older version of sbt works better since newer Zinc doesn't work with 2.13 beta releases.

#### bisect.sh

Download `bisect.sh`:

<code>
wget https://raw.githubusercontent.com/adriaanm/binfu/e996e30d6095d83160746f007737209a02b85944/bisect.sh
chmod +x bisect.sh
</code>

Next, edit line 83 and 84 as follows:

<code>
  cd /tmp/bisectscala/
  sbt "++$sv!" "run"
</code>

### running the bisect

To run the bisect, you need to also clone scala/scala to your local machine. After all, it needs to know the commit history of Scala.

In another terminal window, navigate to the scala/scala working directory:

<code>
$ head -n 3 README.md
# Welcome!

This is the official repository for the [Scala Programming Language](http://www.scala-lang.org)
</code>

From the scala directory run:

<code>
/tmp/bisectscala/bisect.sh <good> <bad>
</code>

where `<good>` is the known good tag or commit, and `<bad>` is the known bad tag or commit. For example:

<code>
/tmp/bisectscala/bisect.sh v2.12.8 v2.13.0-RC3
</code>

The interesting thing about scala/scala is that for each merged commits, `scala-compiler`, `scala-library` etc artifacts are automatically built and published to the Scala CI Artifactory. This means that for many of the commits (not all), we can point `scalaVersion` at them like they are a normal Scala version. sbt will download the compiler JARs from the repository, and compile the "compiler bridge" to use them. This is a huge time saver since otherwise we would have to compile and locally publish the compiler.

<code>
$ /tmp/bisectscala/bisect.sh v2.12.8 v2.13.0-RC3
notice:
* currently you have to edit this script for each use
maintenance status:
* this is somewhat rough, but hopefully already useful
* pull requests with improvements welcome
Bisecting: 2295 revisions left to test after this (roughly 11 steps)
</code>

Here are the results of binary search:
- good: dbf9a6a631
- skip: e7eca326c3
- skip: 10f066bff4
- bad: af24410986
- good: bcb6ddff10
- skip: be1d651fea
- skip: 9a04c4d9b7
- bad: f8fdd3e736
- skip: 536988631c
- skip: f421ca1249
- skip: c02e4ae4c3
- skip: 28e20d1b27
- bad: c742cff1fb
- skip: 0c114dc58c
- good: f65fb09c1c
- skip: cb33737d09
- good: d4a9eaa070
- skip: 508eeca620
- skip: 67f51bd62d
- skip: f85610711e
- skip: d9f00716ce
- good: d5d397ff63
- bad: c2be3187be
- bad: 1775dbad30
- good: f1c1d62d0c
- skip: 24a571368b
- bad: 3a8a5ddd01
- skip: f293db4572
- good: fa5ad9ac24
- bad: 0807abfb4f
- skip: c39acf5bbf

Note that it skips over the non-merge commits. The following is the final result:

```bash
There are only 'skip'ped commits left to test.
The first bad commit could be any of:
c39acf5bbf8d57c8684ad65abff77075b9524b5d
0807abfb4f45611e9df5bb7e2f4285945448bce2
We cannot bisect more!
bisect run cannot continue any more
```

Out of 2295 it narrowed down to 2 commits that we need to examine manually. From the timestamps it took around 9 minutes to go through this. So maybe you could go prepare your favorite beverage in the meantime.

In this case the first commit c39acf5bbf8d57c8684ad65abff77075b9524b5d contained the bug. 0807abfb4f45611e9df5bb7e2f4285945448bce2 is a merge commit for it. So they are both correct.

### decoding the magic

Let's look at Lukas's script a bit. The main part is:

```bash
git bisect start --no-checkout
git bisect good $good
git bisect bad $bad
git bisect run "$script_path" run-the-run "$current_dir"
git bisect log > "bisect_$good-$bad.log"
git bisect reset
```

The interesting details are the helper functions called by `run`:

```bash
current () {
  local sha=$(cat "$repo_dir/.git/BISECT_HEAD")
  echo ${sha:0:10}
}

scalaVersion () {
  local sha=$(current)
  sha=${sha:0:7}
  local artifact=$(curl -s "https://scala-ci.typesafe.com/artifactory/api/search/artifact?name=$sha" | jq -r '.results | .[] | .uri' | grep "/scala-compiler-.*-$sha.jar")
  # scala version is in second-to-last column
  # http://scala-ci.typesafe.com/artifactory/api/storage/scala-integration/org/scala-lang/scala-compiler/2.13.0-pre-d40e267/scala-compiler-2.13.0-pre-d40e267.jar
  res=$(echo $artifact | awk -F/ '{print $(NF-1)}' 2> /dev/null)
  echo $res
}
```

Looks like it figures out the current git sha, and then queries if there's a version published on Artifactory using the search API.

### summary

git bisecting is a useful technique to locate the source of a bug.
For scala/scala in particular, `bisect.sh` can save a lot of time by using the pre-build compiler artifacts on the Scala CI Artifactory.
