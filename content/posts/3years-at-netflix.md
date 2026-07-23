---
title: "3 years at Netflix"
type: story
date: 2026-07-21
url: 3years-at-netflix
---

I joined the tooling team for Netflix's personalization and recommendation group in January 2023. Three years later, July 13, 2026 was my last day. I got to be part of two great organizations, AI for Member Systems and AI Platform, and experience Netflix's [culture][1] of excellence and diversity firsthand.

<!--more-->

### AIMS (AI for Member Systems)

AIMS is a cross functional group of researchers, engineers, data scientists, and managers, spanning not just recommendations, but also personalization, search, discovery, and messaging algorithms. A few public talks and posts sketch out the different corners of the group:

- [Recommending for Long-Term Member Satisfaction at Netflix](https://netflixtechblog.com/recommending-for-long-term-member-satisfaction-at-netflix-ac15cada49ef) (2024)
- [Foundation Model for Personalized Recommendation](https://netflixtechblog.com/foundation-model-for-personalized-recommendation-1a0bd8e02d39) (2025)
- [How Netflix Built a Single Model for Search & Recommendations](https://www.youtube.com/watch?v=mf1EeqkMbdk) (2026)

The first principle of the [culture][1] memo is _The Dream Team_, and I felt it every day in AIMS and AIP. Most people around me had deep expertise in a specific domain, often backed by years of academic or working experience. It's intimidating at first to sit in a meeting where everyone is an expert, until you realize you have expertise on your own to bring to the conversation. Being able to Slack message hundreds of highly-motivated expert team-players is the most fun part about Netflix.

### 2023

I joined the PTR (Productivity, Tooling, and Reliability) team in AIMS, right as we were merging multiple algorithm repos into a polyglot Bazel _monorepo_ for the group. In my second week, the engineer leading the migration left the company. So the team became me and another person working half-time.

The second principle of the [culture][1] memo is _People over Process_, or formerly _Freedom and Responsibility_. Instead of top-down decisions, teams and individuals are empowered to make calls about their own work. Our group adopting a different build tool from the rest of the company is an example of exercising the latitude because we could make the CI 50x faster.

After ramping up on various deployment setups, one of my first proposals was setting up cross building on Bazel, which let us incrementally migrate Python ML libraries, Scala version, and more.

In March I attended [Scala Tooling Summit](https://www.scala-lang.org/blog/2023/04/11/march-2023-scala-tooling-summit.html) in Lausanne, Switzerland, where we discussed Bazel and sbt 2, etc. An interesting outcome from the Summit was actionable diagnosis, where a compiler can send a structured edit suggestion back to the IDEs.

The team grew throughout the year, and our oncall rotation got better over time.

### 2024/2025

With a bigger team, we could go beyond CI/CD and tackle broader ML productivity work in AIMS. I spent 2024-2025 building a declarative configuration system for ML pipelines alongside a group of researchers and engineers.

This was a huge learning opportunity, since it meant working directly on production pipelines.

The third principle of the [culture][1] memo is _Uncomfortably Exciting_, echoing the idea that changing the world means always working on something uncomfortably exciting. Rather than settling into a comfort zone, Netflix pushes teams and individuals to take big swings at _strategic bets_.

### 2025/2026

Mid-2025, PTR moved to the AIP (AI Platform), Netflix's in-house AI and ML platform. The personalization pipelines already depended on the AIP components like [the training platform](https://www.youtube.com/watch?v=nPHYclgj81c) that provides GPU training.

At AIP, I went back to build-shaped and reliability work: new AIP stack adoption for AIMS, automatic detection of ML integration test, faster build file generation, and org-wide SLO adoption etc.

### Next steps

First, I want to thank everyone at AIMS and AIP who worked with me and mentored me over the years.

As a side project, I've been working on sbt 2 in my own time with collaboration with Scala Center and other community volunteers. We just shipped the [2.0 release](https://www.scala-lang.org/blog/2026/06/29/sbt2.html). We have a backlog of tasks still ahead. My plan for now is to go skateboarding, open source, [Scala Days 2026](https://scaladays.org/), and [BazelCon](https://events.linuxfoundation.org/bazelcon/).

After that, I might start looking for a new team to solve the next big problem. Let's stay in touch.

  [1]: https://jobs.netflix.com/culture
