  [1]: https://www.lightbend.com/blog/preview-of-upcoming-sbt-10-features-read-about-the-new-plugins
  [2075]: https://github.com/sbt/sbt/pull/2075
  [road]: https://www.slideshare.net/EugeneYokota/road-to-sbt-10-paved-with-server
  [sphere2017]: https://www.slideshare.net/EugeneYokota/the-state-of-sbt-013-sbt-server-and-sbt-10-scalasphere-ver
  [days2018]: https://www.slideshare.net/EugeneYokota/sbt-1
  [tapad2018]: https://engineering.tapad.com/scala-spree-nyc-a-community-effort-open-sourcing-live-tapad-4844eaf6ebc0
  [berlin2018]: https://www.lightbend.com/blog/berlin-scala-spree
  [orchestration]: https://developer.lightbend.com/docs/lightbend-orchestration/current/
  [6315]: https://github.com/scala/scala/pull/6315
  [6711]: https://github.com/scala/scala/pull/6711
  [native]: https://github.com/sbt/sbt-native-packager/releases/tag/v1.3.16
  [orchestration171]: https://www.lightbend.com/blog/released-lightbend-orchestration-171-and-sbt-native-packager-1318
  [lausanne2019]: https://scaladays.org/2019/lausanne/schedule/sbt-core-concepts
  [sphere2019]: https://www.youtube.com/watch?v=h8ACmUHQ2jg
  [zinc712]: https://github.com/sbt/zinc/pull/712

I joined Lightbend (then Typesafe) in March, 2014. After six incredible years April 7, 2020 was my last day. I am grateful that I got the opportunity to work with an amazing group of people at Lightbend, partners, customers, and various people I got to meet at conferences. Looking back, before COVID-19 times, it's almost surreal that I was flying to Europe, Asia, and North America every few months to attend conferences and tech meetings.

Here is a quick retrospective of my last six years.

### 2014

I started coding Scala at the end of 2009 for fun, so by 2014 I had been doing it for four years. I had just finished 'learning Scalaz' blog series and given my first nescala talk about it. I had written about a dozen sbt plugins, and was also active on Stackoverflow.

In March, I joined Lighbend's Tooling team (then Typesafe "Q Branch") staffed by Josh Suereth and Toni Cunei. Maintaining sbt with Josh was certainly part of my responsibility, but the majority of the work was either strategic or customer-driven, which was challenging and great learning opportunity. I remember that soon after I started I flew into a customer site, and spent the time reading and profiling Apache Ivy. It was overwhelming at first, but library dependency quickly became an area I was most familiar with in sbt.

In May 2014 we bumped the version number of sbt from 0.13.2 to 0.13.5 to start [technology preview][1] for sbt 1.x. The idea was to start experimenting with the necessary features so the jump wouldn't be too big.

In sbt 0.13.6, we started to see some of the library dependency related enhancements that I added such as unresolved dependencies error displaying the graph of missing dependencies, eviction warnings, and `withLatestSnapshots` for `updateOptions`.

Also in the latter half of 2014, Q Branch worked on building out the infrastructure for Typesafe Reactive Platform v1. This was our commercial distribution package based on Dbuild implemented by Toni.

### 2015

In March 2015, I gave my first Scala Days talk ['The road to sbt 1.0 is paved with server'][road] with Josh, who seemed to have infinite insight of sbt from my perspective.

Josh left the company that summer. So I became the sbt lead, at first awkwardly. Looking back on sbt 0.13.9, my contributions were still around library dependency, like [fixing][2075] the SNAPSHOT resolution from Maven Central.

Meanwhile Reactive Platform was gaining traction.

### 2016

In 2016, I became the tech lead for the Tooling team (then Reactive Platform team). We launched Reactive Platform v2 which tried to align closer to developer norms. These ideas came from face-to-face discussions and code retreats in places like Budapest.

In sbt 0.13.13, for example I added `sbt new` command based on Jim Powers's `templateResolver` idea and `Giter8`, replacing the older Activator templates. Aiming at sbt 1.x, we deprecated old sbt 0.12 operators. Tooling team also launched Tech Hub that included browser-based project starter implemented by Toni and Jim Powers.

### 2017

In February 2017, Dale Wijnand and I gave a talk at ScalaSphere ['The state of sbt 0.13, sbt server, and sbt 1.0'][sphere2017]. One of the ideas presented in the talk was to modularize sbt into multiple repositories io, util, librarymanagement, Zinc, and sbt so the loosely-coupled modules can evolve their implementations without exposing too much to the plugin ecosystem. The other motivation was that the modularization effort would nudge us to understand each module better in isolation.

sbt 1.0 development quickly picked up the pace after the talk so plugin authors can get out of supporting Scala 2.10, and sbt 1.0.0 was shipped in August 2017.

### 2018

With sbt 1.x semantically versioned, we could push out bug fixes on patch releases while new features were batched to sbt 1.1.0, 1.2.0 etc. I called sbt 1.1.0 that came out in January 2018 the director's cut because it included the features that I wanted to ship in sbt 1.0 like unified slash syntax and sbt server, but was originally cut for stability.

As Dale and I gave [sbt 1 talks][days2018] in Scala Days New York and Berlin, we also went to contributor outreach efforts like [Scala Spree NYC at Tapad][tapad2018] and [Berlin Scala Spree][berlin2018] hosted by Zalando and Scala Center. I'm not sure if either of the initiatives stuck but Ethan Atkins started to contribute heavily to sbt around this time.

2018 was the year I started sending scala/scala pull requests in my personal time. Some of the notable PRs I sent were [#6315][6315] (deprecation of `any2stringadd`) and [#6711][6711] (typo correction suggestion).

In the latter half of 2018, Tooling team took over [Lightbend Orchestration][orchestration], a project that originally started as a suite of tools to deploy Reactive Platform applications on Kubernetes. With steady guidance by Tim Moore and others, we tried to stabilize the situation by narrowing down the deployment target (OpenShift was picked as the first candidate), setting up a company-wide OpenShift cluster available for integration testing, and gradually migrating to something that's closer to developer norms. This was a great learning opportunity as I needed to quickly catch up to Kubernetes and how its ecosystem related to Akka Clustering etc.

### 2019

Lightbend Orchestration continued into 2019. The effort to increase OpenShift compatibility was released as [sbt-native-packager 1.3.16][native], and [Lightbend Orchestration 1.7.1][orchestration171] became the last release to successfully soft land the project.

In March, I joined the Scala (compiler) team. My responsibility remained to be around build tools and Zinc, but working with the Scala team gave us a fresh look to improve certain things. In September, we released sbt 1.3.0 with Coursier integration and super shell, as well with layered classloader and improved file watcher contributed by Ethan Atkins.

In the latter half of 2019, I shifted my focus to improving Zinc working together with a customer. I needed to brush up on the incremental compiler internals. I gave a talk [Analysis of Zinc][sphere2019] based on this study.

### 2020

Here we are in 2020. Besides the social distancing to prevent the spread of COVID-19, 2020 has been mostly about Zinc for me. One of the features I've always wanted in Scala tool chain is the ability to treat build as a pure function, and cache the build across different machines. This was prevented by the fact that logics around the compilation and incremental compilation requires `java.io.File` with absolute paths. [zinc#712][zinc712] virtualizes the file paths, allowing them to be converted into something machine-independent.

### next steps

I should probably take some time off and process things as a mandatory staycation.
After that, I'll be looking for a new team to solve the next big problem. Let's stay in touch.
