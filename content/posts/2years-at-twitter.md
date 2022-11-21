---
title:       "2 years at Twitter"
type:        story
date:        2022-11-20
url:         2years-at-twitter
---

  [pants]: https://www.pantsbuild.org/
  [google2015]: https://blog.bazel.build/2015/09/01/beta-release.html
  [bazel]: https://bazel.build/
  [twitter2020]: https://groups.google.com/g/pants-devel/c/PHVIbVDLhx8/m/LpSKIP5cAwAJ
  [borja]: https://www.youtube.com/watch?v=0l9u-FIaGrQ
  [yi]: https://www.linkedin.com/in/yidcheng/
  [twitter2015]: https://www.youtube.com/watch?v=IWuAWOApn8w
  [ity]: https://www.linkedin.com/in/ikaul/
  [shane]: https://www.linkedin.com/in/shanedelmore/
  [olaf]: https://www.linkedin.com/in/olafurpg/
  [scoot]: https://github.com/twitter/scoot
  [multiversion]: https://github.com/twitter/bazel-multiversion
  [cached-resolution]: https://www.scala-sbt.org/1.x/docs/Cached-Resolution.html
  [bucket]: https://github.com/twitter/bazel-multiversion/pull/4
  [henry]: https://www.linkedin.com/in/henry-fuller-48344496/
  [SC2021]: https://scala.epfl.ch/minutes/2021/02/04/february-4-2021.html
  [angela]: https://www.linkedin.com/in/angela-guardia/
  [martin]: https://www.linkedin.com/in/martinduhem
  [82]: https://github.com/twitter/bazel-multiversion/pull/82
  [bazelcon2021]: https://www.youtube.com/watch?v=fm6YbBLLlYo
  [katya]: https://www.linkedin.com/in/ekaterina-tyurina-134537126/
  [adam]: https://www.linkedin.com/in/adammsinger/
  [scalamatsuri2020]: https://2020.scalamatsuri.org/en/program
  [hackathon]: https://eed3si9n.com/virtualizing-hackathon-at-scalamatsuri2020/
  [diego]: https://www.linkedin.com/in/diegopuppin/
  [ahs]: https://www.linkedin.com/in/schakaki/
  [liana]: https://www.linkedin.com/in/lianabakradze/
  [rules_jvm_export]: https://github.com/twitter/bazel-multiversion/tree/main/rules_jvm_export
  [10]: https://github.com/twitter-incubator/classpath-verifier/pull/10
  [shrinker]: https://github.com/scalacenter/classpath-shrinker/blob/17ca3a968ad8be409063e61176c8cf7dfdd399bf/plugin/src/main/scala/io/github/retronym/classpathshrinker/ClassPathShrinker.scala
  [113]: https://github.com/twitter/bazel-multiversion/pull/113
  [nagesh]: https://www.linkedin.com/in/nagesh-nayudu-ab51bb3/
  [david]: https://www.linkedin.com/in/david-b-rahn/
  [ioana]: https://www.linkedin.com/in/ioanabalas/
  [talha]: https://www.linkedin.com/in/talha-p/
  [scalaschool]: https://twitter.github.io/scala_school/
  [scalding]: https://github.com/twitter/scalding/wiki/Type-safe-api-reference
  [scalaatscala]: https://www.youtube.com/watch?v=Jfd7c1Bfl10
  [effective]: https://twitter.github.io/effectivescala/
  [scio]: https://spotify.github.io/scio/
  [scalacenter]: https://scala.epfl.ch/donate.html

I was a Staff Engineer at Twitter's Build/Bazel Migration team. After two incredible years, November 17 was my last (working) day. Twitter has been a special place to work for, for its culture of excellence, diversity, and outpouring of care for all the people that made Flock the Flock. I am grateful that I got the opportunity to experience that firsthand, and be part of it.

Here's a quick retrospective on my last two years. Info available here are based on publicly available talks and data.

### EE Build team

First, I probably need to unpack what Build team did. To quote publicly available data, by 2020, we had around 2000 engineers with 20M lines of hand-written code (10x more including the generated code) in the monorepo alone, mostly Scala, but Python, Java etc. Set aside the actual size of code, due to the number of teams, the rate of change that happens everyday is also very fast. Twitter is certainly not unique in its size of the codebase, but at this scale you need a department of engineers + managers to enable other engineers to code using specialized JVM, customized `git`, build tools, CI etc. That department was Engineering Effectiveness.

EE Build team owned monorepo, which we called Source, as the product. Until 2020, the team developed its own build tool called [Pants][pants], partly inspired by Google's internal build system Blaze, but adding many missing features, like Scala support since early 2010s, designed for Twitter's development and velocity. In [2015][google2015] Google created an open source version of Blaze called [Bazel][bazel], which was growing into an interesting build tool with active development with many companies contributing to the surrounding ecosystem of plugins and tooling. In April of 2020, Build team [announced][twitter2020] that they've made the decision to migrate from Pants to Bazel.

It may not be obvious why you'd need a team of engineers to adopt a build tool if you've never dealt with large-scale code base, but one way to think about it is that circa 2020, Bazel was more like a build-tool toolkit rather than a build tool. This is partly due to the fact that within Google there are other tools that handle deployment, and also because we're dealing with 20M line of code, which co-evolved with rich feature set of Pants. So Build team became Bazel Migration team to re-implement the rich feature set without losing the performance gains, which we had hoped to achieve by migrating to Bazel, and actually migrate the services and data jobs that power Twitter.

To avoid disruptive Big Bang migration, the team adopted an unique approach of create Pants emulation layer at the macro level, so the `BUILD` files so served [both Pants and Bazel][borja]. This allowed incremental adoption without any performance loss.

### 2020

I joined the Build/Bazel Migration team in August of 2020, in the midst of pre-vaccine COVID-19 pandemic. The world was getting acclamated to the idea of working from home, it was an old hat for me as I'd been working from home since 2011. The first week was Flight School, a week of internal training conducted by in-house instructors and senior-level engineers on various topics including the tech stack and the company culture.

Build team had rotating members of about 12 people, a few more consultants, and some borrowed members from sibling teams. Since I've worked with relatively smaller teams it was overwhelming at first. So I remember in the first few weeks, [Yi Cheng][yi] onboarded me to the team. Yi was the pillar of team and knew the answer to anyone's Pants questions, always helpful, and interfaced with various teams, up and sideways.

By then I had like 10 years of experience coding Scala, which was odd for a new-hire. In the first few weeks, I retrofitted Bazel support for the internal remote caching service for Pants called buildcache (see [2015 Scala at Twitter talk][twitter2015] for more on buildcache). Not the most optimized solution for Bazel, but also not a bad start.

Next, I talked to [Ity Kaul][ity] who was the Tech Lead of Build team, at the time based in London. As someone who's been around the longest, and highest ranked, she was busy organizing workstreams and tracking their progress. In one of our 1-on-1s, I asked what would be the most strategically interesting problem I could tackle, and she told me about the multiverse problem.

So in September, I counted multiverses. A multiverse is a set of library dependency version number, for example `{ A: 1.0, B: 2.0 }`. Because Pants calls Coursier at command-invocation, different targets could end up with different library versions. Since Bazel is known to be a one-version (monoversion) build tool, we were interested in sizing up the problem. Using Python, I've come up with variance score and iterative algorithm to identify the axes to minimize the variance. Then I ended up drawing something that resembled a subway map. There were thousands of incidental multiverses, but the major versions clustered into a few dozen multiverses.

During this time, engineers who I knew jumped into my Slack DMs to check up on me, share cool things they've been working on, and showed me the ropes. The two that stood out were from the internal Scala team [Shane Delmore][shane] and [Ólafur Geirsson][olaf]. As I was slowly running Pants commands on thousands of targets on my laptop, Shane ran it on [scoot][scoot] a CI infrastructure capable of running thousands of builds at a time on top of Mesos.

Olaf was working on the prototype of what will be [bazel-multiversion][multiversion]. At the time, there was an internal discussion on which layer would be best suited to run the Coursier resolution, the `jar_library` level per external library or `scala_binary` at the end like Pants and sbt.

By November, I bacame the driver for the 3rdparty/jvm (external library support on JVM) and wrote the Bazel 3rdparty/jvm roadmap. To put myself in a context a bit, I have been a lead maintainer of sbt, a build tool primarily used in the Scala community. In sbt, I have designed and implemented similar features such as [cached resolution][cached-resolution], eviction warnings, and [`versionScheme`](/sbt-1.4.0). Based on these experiences and the data I collected in the multiverse study, I started with [bucketing][bucket] the version numbers to Semantic Version.

On Python side, [Henry Fuller][henry] led the strategy for the 3rdparty/python migration, and general support for Python on Bazel.

As side projects, I co-organized [ScalaMatsuri 2020][scalamatsuri2020] conference with many others in October. One of the sessions I faciliated was [virtualized hackathon][hackathon] where I guided participants to make pull requests against the Scala compiler, sbt, etc.

In November, I ran a mini fundraiser event called [Weehawken-Lang1](/weehawken-lang1) and gave a talk on Equality in Scala.

### 2021

In February 2021, I became Twitter's representative to [the Scala Center Advisory Board][SC2021].

Coincidentally, around the same time JFrog announced the sunset of Bintray. Together with Scala Center, VirtusLab, and Lightbend we formed a task force to safely migrate the sbt plugin ecosystem to maintain secure custody and continuity of build semantics. JFrog granted us an [open source sponsorship](https://jfrog.com/open-source/) and I was able to [migrate](/sbt-1.5.1) the sbt plugins and installers into a cloud-hosted Artifactory instance licensed to Scala Center. Apart from occasional security patches, I've worked on sbt only in weekends while I was at Twitter.

In March [Angela Guardia][angela] joined Build/Bazel Migration team, and joined the 3rdparty/jvm workstream with [Martin Duhem][martin]. One of the ideas we had was making data-driven decisions for adjusting the 3rdparty/jvm graph, so Angela implemented [YAML output][82] on bazel-multiversion, nightly Jenkins jobs to run the linter to detect conflicting JAR files, and log aggregation. I've covered the conflict-detection linting in my Bazelcon talk [Resolving Twitter's 3rdparty/jvm with bazel-multiversion][bazelcon2021].

In June, I implemented custom `collect_jars` phase in rules_scala to automatically resolve conflicts at the leaf target level. In the talk I called it _tertiary resolution_ (There was another awesome Bazelcon 2022 talk by Airbnb that takes this further).

As we were increasing the number of Bazel-compatible targets, we were starting to bump into scalability issues with buildcache. I think around that time [Ekaterina (Katya) Tyurina][katya] produced detailed analysis on scalability walls the buildcache cluster was hitting due to TCP buffer allocation, as well as potential hermeticity leaks.

To switch gears, in Q3 I started driving _Summer of Scalding_ workstream to design and implement Bazel support for data processing jobs. This included talking with different teams who own the deployment pipeline and data platforms. This made me realize that to the rest of the company, we offered "Build" as a product, not Pants or Bazel, and smooth migration required almost a drop-in replacement for the output. For that reason, I implemented shell script level extension `bazel bundle` that would produce Pants-compatible deployment image, and Bazel support for Scalding using it.

Within the Flock, engineers moved around fluidly between the teams. A skateboarding Staff Engineer [Adam Singer][adam], who has been at many teams, branched into Scala team, and quickly became a lead of important Bazel Migration workstreams. He had a big desktop machine at his home and ran all the JUnit jobs to collect the breaking points of Bazel conversion. He was also comfortable around profiling tools to diagonose various issues. For example, I think it was Adam who pointed out that the Mac laptops were unable to fully utilize the remote cache because action cache was platform specific. This remains to be an open challenge of Bazel to date. Adam also had the funninest stories to share during the social hours.

To prepare for the mainstream adoption of Bazel, I've also led the effort to create internal documentation site "go/bazel" with tutorials and troubleshooting guide, as well as internal training "Bazel at Twitter" course, highlighting the differences between Pants and Bazel.

Following up on a series of log4j vulnerabilities in December, I've helped patch the internal dependencies as well release timely sbt 1.5.x patch releases.

During 2021, I was promoted to Staff Engineer because "Eugene was clearly mis-leveled when he was hired one year ago. His deep industry credentials were not fully appreciated or taken into account during the hiring process, ..." (Thanks, [David Rahn][david]!)

### 2022

I should also touch on the dynamics between Engineering Effectiveness group and other organizations that worked on Products and Revenue etc. The first time [Yi][yi] or [Ity][ity] used the word _customer_ to refer to other teams in the company, it felt a bit strange to my ears, but soon it clicked to me that those other teams have _hired_ Build team to provide Source monorepo as a product, and they were free to choose any other build system (mobile apps did). Soon enough, I also adopted the mindset of considering other organizations as customers of EE.

Build team ran oncall rotation that lasted for a week. The main responsibility was to provide customer support via JIRA during the normal business hours. Initially, many of the tickets were Pants questions and I needed help from the teammates to assist the customers, but I became more comfortable as I gained more Pants knowledge, and also questions started to become more about Bazel migration issues, and I relished providing good customer support as Build team.

The oncall responsibility also included outage response of the Source monorepo. Partly due to the US timezone, [Yi][yi] and I were often involved to fix the CI pipeline or buildcache when they went down, debugging memory usage, Maven XML file caching etc to come up the workarounds, and later document in a postmortem report.

One of the remaining areas of challenges at the infra level was the IDE support. In February 2022, I investigated several of the IntelliJ IDEA import issues for the internal code, including transitive dependencies not showing up.

Also in February, I implemented excludes support for the leaf targets, by using `collect_jars` phase again, and documented the usage.

In March, I facilitated internal Bazel Hack Week during the company-wide Hack Week, partly to onboard people to Bazel, but also to recruit engineers to implement remaining Pants features. Features such as shading support and Node.JS support were prototyped during the Hack Week in addition to general increase in the Bazel-compatibility %. Soon afterwards, the conversation shifted more to actual migration % of the deployments.

A few members left the team, but Bazel Migration still gained traction to attract experienced engineers to join the team.

- From media team, [Diego Puppin][diego] joined to lead the Node.JS support and other workstreams.
- From Meta, [Adam Hani Schakaki][ahs] joined Workflow migration effort, and he also mentored an intern [Talha Pathan][talha] who implemented Golang support in the summer. Adam also left detailed review comments on Python code, and I learned a lot from those.
- [Liana Bakradze][liana] joined from JetBrains. Initially she made improvements on migration metrics tracking, and later she led Pants Deprecation workstream to reduce the dual building to just Bazel-only.

In May, I implemented per-target strict-deps support for `scala_library` rule. There were many details like that where Pants supported per-target something, but Bazel generally doesn't out-of-box. Another example that I implemented was per-target `protoc_version` support for generating Protobufs. This was a major breakthrough to migrate Scalding jobs, as Hadoop required protobuf-java 2.x.

I implemented publishing support for Scala, Thrift, and Java targets. This work was open source as [rules_jvm_export][rules_jvm_export]. rules_jvm_export aims to create proper POM file matching the target dependencies.

Another area that I worked on was dead code analysis at the target level. I've implemented [classpath-verifier#10][10] using JVM call graph to detect unused JAR files, as well as a port of [ClassPathShrinker][shrinker] Scalac plugin. The aim for dead code analysis is to reduce the build time for some of the very large targets.

By November, majority of the laptop usages and many of the deployments have migrated to Bazel. However, some performance challenges remained, and a few of us were still making improvements to the last days. My last phab (our name for pull request) was to [patch bazel-multiversion][113] against a Coursier CVE, and apply it to Source after the code-freeze.

Looking back, I feel like this has been among the most productive 2 years of my career. This was facilitated precisely because of the work/life balance afforded by the "peak-Kumbaya" Twitter culture, and the psychological safety harnessed by Engineering Effectiveness leaders like [Nagesh Nayudu][nagesh] and Build/Bazel Migration team managers [David Rahn][david] and [Ioana Balas][ioana]. In Engineering Effectiveness's mission I found business alignment, in a sense that what I wanted to work on was exactly what the work wanted me to work on. I always looked forward to 1-on-1 syncs with Nagesh and David to share my ideas and also learn from their vantage points. Because I could trust David and senior members in the team, I could dive into difficult challenges. I'll miss that OneTeam energy.

### Scala at Twitter

I won't get into anything that isn't public, but Twitter has a very balanced approach to Scala, which is neither throwing out all the rich features of Scala language as "Better Java", nor going overboard to a "Worse Haskell" (or sometimes loveably called Type Astronaut), in part because we have lot of engineers. Instead Twitter's codebase strikes somewhere in the middle:

- Prefer immutability
- Use Scala's collections library
- Avoid implicit conversions
- Use `com.twitter.util.Future`s to express concurrency as type

This philosophy can be gleaned from resources like [Scala School][scalaschool], [Effective Scala][effective], [Scalding][scalding] documentation, and talks like [Scala at Scale at Twitter (2016)][scalaatscala]. Note: Twitter implemented locally-scheduled, cancellable Future, long before Scala 2.10 added fork/join one in 2013.

For those who might not be familar with Scala, the standard library of Scala especially the collections library allows elegant transformation of basic JVM data structures like arrays, list, and `Map` (dictionary), which would take multiple lines of boilerplate in more procedural languages like Java.

More than almost any mainstream language, Scala gives library authors the power to extend the language itself to create a local dialect (often called Domain Specific Language, or DSL) or wrap an existing Java library to provide a better developer experience. [Scalding][scalding] is a stellar example of this where a Hadoop code, which could take a whole page of Java boilerplate can be concisely expressed in a few lines of Scala. This idea is carried on by other companies such as Spotify, which created [Scio][scio] on top of Dataflow.

At Twitter, we strived to create fair and diverse workplace, encompassing various axes including gender and ethnicity, but also different skill background. Some were experts with PhD, while others were newly starting their career as programmer. To put another way, with thousands of engineers, we probably had hundreds of women coding Scala. I do lament the loss of diversity if they move on to something else.

### Donate to the Scala Center

[Support the Scala Center][scalacenter].

Corporate sponsors might reduce their funding in a downturn economy, but I think the individual programmers can chip in to [support the Scala Center][scalacenter]. The rate of inflation is at 8%, and our stock positions that the new owners generously cashed out for us is going to lose its values quickly.

There are thousands of us, and if we all put in even 3% of the RSU or severance, that should add up to a decent amount for Scala Center. For former Tweeps, there's a utilitarian benefit of having Scala ecosystem, and Scala job market around, and since I don't know if Twitter will continue to fund Scala Center, which works on keeping the lights on by fixing CVEs and organizing workshops and conferences.

### Next steps

I joined Twitter to migrate their monorepo to Bazel, got it done by collaborating with many others, and now we're getting out. The way I look at it, the new owners are going to fund our vacations for a while. Maybe I can get back to making chili oil, and write blog posts.

After that, I'll be looking for a new team to solve the next big problem. Let's stay in touch. CV etc are available at [about](/about) page.
