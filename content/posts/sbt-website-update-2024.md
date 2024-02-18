---
title: "sbt website update 2024"
type: story
date: 2024-01-21
url: /sbt-website-update-2024
tags: [ "sbt" ]
---

This is a writeup on sbt's website [scala-sbt.org][scala-sbt] updates, some concrete, others more of half-baked ideas.

### Background

I've been the primary maintainer of the site since 2014. Though I have written some of the pages, most of the content had been written by Mark and Havoc by the time I took over. You can see on [2014 archive](https://web.archive.org/web/20140529085505/http://www.scala-sbt.org:80/) that the site was Sphinx doc.

The first things I did in 2014 on the site was to migrate from [Sphix](https://www.sphinx-doc.org/), which used reStructuredText, to [Markdown](https://github.com/sbt/website/commit/57bb93275be27eb6c2a58348204bacf1a0a5f90d) on [Pamflet](https://www.foundweekends.org/pamflet/), a static site generator created by Nathan, and later I inherited.

I've also created [a landing page](https://web.archive.org/web/20140625124822/http://www.scala-sbt.org/) using [Nanoc](https://nanoc.app/). The landing page was rebanded in 2015 to Typesafe color scheme, and in 2017 Lightbend blue/orange color scheme, which still remains today. At some point, I switched from Nanoc to [Paradox](https://developer.lightbend.com/docs/paradox/current/) too.

<b><span style="font-family: Helvetica Neue, Roboto; font-size: 0.8rem;">2017 Lightbend blue/orange (current)</span></b>:
![2017 version](/images/sbt-website-2017.png)

Last year, Lightbend [transferred](https://www.scala-lang.org/news/2023/08/25/sbt-license-transfer.html) the ownership of sbt as well as the site to Scala Center.

### Docusaurus

I've been relatively happy with Paradox and Pamflet, but I also think it's time to switch to another static site generator that are actively maintained. In [sbt 2.0 ideas](/sbt-2.0-ideas) I wrote:

> Maybe this is also a good timing to switch to some other static site generator like MkDocs or Docusaurus.

I've opted for [Docusaurus](https://docusaurus.io/), created by Meta, and fairly popular among Scala open source projects. It comes preconfigured to support landing pages, docs, and blog. Even though it's a static site generator, during the generation it can run components written in JavaScript, and it's extensible.

**2023-02-18 Update**: When I realized that I can't seem to get PDF output easily from Docusaurus, I switched to [mdBook](https://rust-lang.github.io/mdBook/) for the documentation part.

### Phase 1: Landing pages

I've sent a pull request [sbt/website#1173](https://github.com/sbt/website/pull/1173) to migrate the landing pages from Paradox to Docusaurus.

<b><span style="font-family: Helvetica Neue, Roboto; font-size: 0.8rem;">2024 rewite</span></b>:
![2024 version](/images/sbt-website-2024.png)

The picture of the ryōanji dry garden is the same image from the original 2014 landing page. Besides the fact that the download lists are now programmatically generated, there are no material difference between the two.

MDX allows you to embed JavaScript into Markdown:

```markdown
import HomepageVersions from '@site/src/components/HomepageVersions';

### Previous releases

<h4>1.x</h4>

<HomepageVersions />
```

The component is implemented as JavaScript that iterates over a list of versions to produce a table. As of the pull request, Paradox is gone, but sbt 1.x docs is still using Pamflet.

### Phase 2: User documentation

One benefit of static site generator is that it's fairly easy to create versioned documentation. All you need to do is output the HTML files in separate directories during deployment.

**2023-02-18 Update**: When I realized that I can't seem to get PDF output easily from Docusaurus, I switched to [mdBook](https://rust-lang.github.io/mdBook/) for the documentation part.

I sent [sbt/website#1188](https://github.com/sbt/website/pull/1188), which lets us branch out 1.x documentation for `1.x` branch, and start a new sbt 2.x documentation on `develop` branch using mdBook.

This approach has many benefits:

1. 2.x is a clean slate, so we don't have to worry about breaking existing links for sbt 1.x docs.
2. We can work on and publish 2.x docs incrementally.
3. As we reorganize the docs, we can also document any sbt 2.x features or features that were added in 1.x.
4. For any pages that we can reuse, we can keep the git history, as opposed to having both 1.x and 2.x both in one branch.

<b><span style="font-family: Helvetica Neue, Roboto; font-size: 0.8rem;">Setup page (2024-02) using mdBook</span></b>:
![Setup page 2024-02 version](/images/sbt-website-setup2.png)

### Doc reorganization

I would be remiss if I didn't mention Daniele Procida's 2017 ['What nobody tells you about documentation'](https://www.youtube.com/watch?v=t4vKPhjcMZg) talk aka 'The four kinds of documentation' / [The Documentation System](https://documentation.divio.com/). Per Procida, there are four kinds of documentation:

1. learning-oriented quick start guide
2. goal-oriented how-to guides
3. understanding-oriented explanation
4. information-oriented reference material

He calls the first one _tutorial_, but I think quick start guide is probably more apt since the term spans over the first three kinds. In particular, there was an emphasis on _not_ explaining things in quick start or how-to guides as well who the target audiences are.

I am not fully sure where documents on testing or publishing may fit into the above categorization, but in general it would be good to calibrate what we need to include into Getting Started guide, and what we can move out.

We could also get some insight from other software documentations, both build tools and non-build tools:

- [The Cargo Book](https://doc.rust-lang.org/cargo/)
- [Pants Docs](https://www.pantsbuild.org/2.18/docs/introduction/welcome-to-pants)
- [Buck Docs](https://buck.build/setup/getting_started.html)
- [Gradle User Manual](https://docs.gradle.org/current/userguide/userguide.html)
- [Bazel User guide](https://bazel.build/docs)
- [Docusaurus Docs](https://docusaurus.io/docs)
- [Stripe Docs](https://stripe.com/docs/payments)
- [GitHub Actions documentation](https://docs.github.com/en/actions)

Some thoughts:

- I like how Cargo's guide starts with [Why Cargo Exists](https://doc.rust-lang.org/cargo/guide/why-cargo-exists.html) page. Since it's often not clear to new users why some program exists, this could be useful information.
- Gradle docs have clearest demarcation of build users ("Running Gradle Builds") vs build authors ("Authoring Gradle Builds").
- For Bazel docs, the demarcation is Extending Bazel, which is a whole different section of the website. I guess it reflects how disconnected `*.bzl` authors are from `BUILD.bazel` users/authors.
- Overall, not too many of them have how-to guides.

Let me know if you have recommendation for some software documentation, especially the ones that teaches users concepts, not just detailed description.

### Summary

- Phase 1: I've sent a pull request [sbt/website#1173](https://github.com/sbt/website/pull/1173) to migrate the landing pages from Paradox to Docusaurus.
- Phase 2: We can start working on sbt 2.x docs using mdBook, potentially reorganizing the existing docs.

Since I've listed a bunch of static site generators, I should also note that this post was authored using [Hugo](https://gohugo.io/).

  [scala-sbt]: https://scala-sbt.org/
