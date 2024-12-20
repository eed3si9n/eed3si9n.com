---
title:       "back publishing actually"
type:        story
date:        2024-12-18
url:         /back-publishing-actually
---

This is part 2 of [tag-based back publishing](/tag-based-back-publishing-with-sbt/) using sbt-ci-release.

### sbt-ci-release 1.9.2

Now that sbt 2.0.0-M3 is out, I tried sbt-ci-release 1.9.0 for back publishing, but immediate ran into a bug related to `version` setting, so I had to fix that in sbt-ci-release 1.9.2.

```scala
// plugins.sbt
addSbtPlugin("com.github.sbt" % "sbt-ci-release" % "1.9.2")
```

Note sbt-ci-release 1.9.x implements a mini DSL for the Git tag:

```
version[@command|@a.b.c|@a.b."x"][#comment]
```

<!--more-->

### sbt-git 2.1.0 is back published to sbt 2.0.0-M3

Mike Limansky contributed [sbt-git#272](https://github.com/sbt/sbt-git/pull/272) to update sbt 2.x to 2.0.0-M3, and updating to Scala 3.6.2.

Given that all other PRs that we've landed since sbt-git 2.1.0 were not user-facing, I back published the HEAD of `main` branch as 2.1.0 as follows:

```bash
git tag -a -s "v2.1.0@3.x#sbt2.0.0-M3" -m "v2.1.0@3.x#sbt2.0.0-M3"
git push --tags
```

The [v2.1.0@3.x#sbt2.0.0-M3](https://github.com/sbt/sbt-git/releases/tag/v2.1.0%403.x%23sbt2.0.0-M3) tag triggers Publish job: <https://github.com/sbt/sbt-git/actions/runs/12406511789/job/34635095760>:

```bash
[info]  published sbt-git_sbt2.0.0-M3_3 to /home/runner/work/sbt-git/sbt-git/target/sonatype-staging/2.1.0/com/github/sbt/sbt-git_sbt2.0.0-M3_3/2.1.0/sbt-git_sbt2.0.0-M3_3-2.1.0.jar
[info]  published sbt-git_sbt2.0.0-M3_3 to /home/runner/work/sbt-git/sbt-git/target/sonatype-staging/2.1.0/com/github/sbt/sbt-git_sbt2.0.0-M3_3/2.1.0/sbt-git_sbt2.0.0-M3_3-2.1.0.jar.asc
....
```

Note that GitHub Action must not define `CI_RELEASE` environment variable this tag-based approach.

### sbt-pgp 2.3.1 is back published to sbt 2.0.0-M3

Next, I sent [sbt-pgp#219](https://github.com/sbt/sbt-pgp/pull/219) to cross build sbt-pgp against sbt 2.0.0-M3. The tricky part about sbt-pgp repository is that it contains a library and an sbt plugin, and we want to only back publish the sbt plugin.

For this, I had to change the trigger on GitHub Action to use `**` for tags, which allows `/` in it:

```yaml
on:
  push:
    tags:
      - '**'
```

This is important because we need to include `/` in the tag as follows:

```bash
git tag -a -s "v2.3.1@3.x@plugin/publishSigned#sbt2.0.0-M3" -m "v2.3.1@3.x@plugin/publishSigned#sbt2.0.0-M3"
```

sbt-ci-release will execute `3.x` as `++3.x` and `plugin/publishSigned` as-is <https://github.com/sbt/sbt-pgp/actions/runs/12407210411/job/34636873627>:

```bash
[info]  published sbt-pgp_sbt2.0.0-M3_3 to /home/runner/work/sbt-pgp/sbt-pgp/target/sonatype-staging/2.3.1/com/github/sbt/sbt-pgp_sbt2.0.0-M3_3/2.3.1/sbt-pgp_sbt2.0.0-M3_3-2.3.1.jar
[info]  published sbt-pgp_sbt2.0.0-M3_3 to /home/runner/work/sbt-pgp/sbt-pgp/target/sonatype-staging/2.3.1/com/github/sbt/sbt-pgp_sbt2.0.0-M3_3/2.3.1/sbt-pgp_sbt2.0.0-M3_3-2.3.1-javadoc.jar
....
```

### summary

- sbt-ci-release 1.9.2 enables tag-based back publishing. See [tag-based back publishing](/tag-based-back-publishing-with-sbt/) for details.
- `CI_RELEASE` environment variable cannot be specified for the fully tag-based aproach.
- Set the GitHub Action tag trigger to `**`, which allows `/` in tag.
- sbt-git 2.1.0 and sbt-pgp 2.3.1 are back published for sbt 2.0.0-M3.
