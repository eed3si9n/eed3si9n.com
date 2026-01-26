---
title: "sbt and the miners of the wild west"
type:  story
date:  2026-01-26
url:   sbt-and-the-miners-of-the-wild-west
---

### small village of sbt

I'm a volunteer maintainer/core dev of sbt and Zinc, the toolchain that powers the Scala programming language, which is a multi-paradigm language targetting JVM, JS, and native. Scala itself has been around for 20 years, and since Twitter's adoption in [2009](https://web.archive.org/web/20260000000000*/http://www.technologyreview.com/blog/editors/23282/) it's been used by Apache Spark, LinkedIn, Morgan Stanley, ING, Airbnb, Spotify, Netflix, etc.

Despite Scala's accolades over the years, both sbt and Zinc remain niche projects, maintained mostly by me with the collaboration with Scala Center, and contributions by a small circle of Scala users and tooling folks from EPFL, Lightbend/Akka, JetBrains, VirtusLab, Databricks, and Gradle many of whom I've met in Poland or Switzerland.

### gold miners comes to the village

One day in January 2026, this change when sbt/sbt started getting pull requests from people whom I've never heard of before. What I've put together gradually is that sbt/sbt has been added to a crypo-based open source bounty program called [Gittensor][gittensor]. According to <https://subnetalpha.ai/subnet/gittensor/>:

> Gittensor is a specialized subnet on the Bittensor network that incentivizes and rewards developers for contributing to open-source software. In essence, it creates a decentralized "open-source workforce" by allowing developers (as miners) to earn cryptocurrency for meaningful contributions (like code improvements and pull requests) to selected open-source projects.

If I understand correctly, a _subnet_ is a virtual startup within Bittensor (TAO), and the alpha token act as a stock for the startup. Bittensor funds the subnets (called _emission_) in some cadence, and the miners are rewarded with the alpha token, which they can _unstake_ to TAO. In other words, the idea behind Bittensor startup seems to be replacing the useless Bitcoin _mining_ with some form of useful activities. I have no idea who is investing into Bittensor (TAO) itself, but it market itselfs as "a decentralized network where computers work together to develop AI," not virtual venture capital.

Regardless, Gittensor claims that it has a monthly $116k USD reward pool. They get 41.38 TAO/day, which is $9548, and they claim 41% goes to the "miners." I have no way to confirming the veracity of these numbers, but there are group of people who seem to think this is true. Let's assume they get paid around $100 per pull request.

Once one person got their pull request merged, more people started to show up.

#### GitHub pulse

According to [pulse](https://github.com/sbt/sbt/pulse), between December 25, 2025 and January 25, 2026, **23 contributors have opened 145 pull requests**, merged 132 pull requests, and closed 194 issues. While the stat includes some of my own pull requests, by far this has been the most active 1 month in the 10+ years that I've been the maintainer.

Unlike a bug bounty program, Gittensor has no limits to which GitHub issues the "miners" can work on. The score is calculated using Drake's equation-esque [scoring system][scoring]:

> ```
> code_density = min(token_score / total_lines, 3.0)
> contribution_bonus = min(1.0, token_score / 2000) * 30
> base_score = (30 × code_density) + contribution_bonus
> earned_score = base_score
>               × repo_weight_multiplier
>               × issue_multiplier
>               × open_pr_spam_multiplier
>               × time_decay_multiplier
>               × repository_uniqueness_multiplier
>               × credibility_multiplier
> final_score = max(0, total_earned_score - total_collateral_score)
> ```

Some of the "miners"/contributors ask if they can work on an issue, others start sending pull requests. This has motivated me to close some of the inactive issues, which explains why we closed more issues than the pull requests.

### the big question: how are the PRs?

The big question is how are the PRs? One thing I can say is that Gittensor has put in various mechanism to discourage low-quality pull requests. For example, the `base_score` is calculated by analyzing the abstract syntax tree via Treesitter, so if you sent a PR just changing a comments, "miner" would get no points. It would also hurt their `credibility_multiplier`, which is calcualted by the ratio of merged / open PRs. So as far as I can tell, the "miners" are sincerely trying to address the GitHub issues.

However, as you might imagine, the pull requests come in varying degree of readiness:

| issue         | junior dev | senior dev |
|---------------|:----------:|:----------:|
| easy issue    |      ⛅     |      ☀️   |
| complex issue |      ⛈️     |      ⛅   |

My observation is that the "miner"/contributors split into two camps. Let's call them junior devs and senior devs. The senior devs can tackle a portfolio of easy and complex issues, and resolved issues that I haven't been able to give attention to in years. Meanwhile, junior devs require several round of reviews to fix easy issues, and often struggle with complex ones. This also has to do with peculiar nature of the sbt project, which sometimes requires Scala metaprogramming or working with Windows batch changes that can pass GitHub Actions CI, so it's not a judgement of the general skill level.

Here are select PRs that were contributed this month:

- [[2.x] test: Fix ParseKeySpec flaky test when task name matches project name #8454](https://github.com/sbt/sbt/pull/8454). This fixes our property-based testing for key parser.
- [[2.x] ci: Upgrade launcher-package from sbt 0.13 to sbt 1.x](https://github.com/sbt/sbt/pull/8465)
- [[2.x] fix: Fix ProjectMatrix invalid project ID with CrossVersion.full](https://github.com/sbt/sbt/pull/8484). Scala 3 macro contribution.
- [[2.x] fix: Invalidate update cache across commands when dependencies change](https://github.com/sbt/sbt/pull/8501)
- [[2.x] feat: Add "3-latest.candidate" support for Scala 3 release candidates](https://github.com/sbt/sbt/pull/8596). This was a feature requested by Scala 3 team.
- [[2.x] feat: Add dependency lock file support](https://github.com/sbt/sbt/pull/8581)
- [[2.x] feat: Support forked console](https://github.com/sbt/sbt/pull/8604). This is a feature I worked on during the winter vacation, but got stuck with JLine issue. The contributor figured out the last bit of the puzzle.

Some other pull requests are in more rough shape, as if they were produced by Gen AI or have no evidence that the contributor tried to reproduce or verify the issue in question.

### contributor's guide and the code review

As the barrage of pull requests and pull request comments kept coming in, it became more clear to me about how important code reviews are to accept good contributions, but also to maintain the standard of the code base, and prevent potential security issues.

For this purpose, I've started to write up [Contributor's guide (CONTRIBUTING.md)][contributing]. This includes a section pleading to first test the problem before coding:

> - [ ]  Before working on a pull request, please confirm that **you can reproduce the reported problem** using GitHub Actions or your computer.
> - [ ] After making the code change, please confirm that **your change compiles, and has fixed the problem**.

I've never had to do this before, but in this age of Gen AI, I suspect some people are sort of sending speculative code changes without even compiling the change. Speaking of this, here's the Gen-AI assisted contributions guideline in full:

<a id="genai"></a>
> ### Gen-AI assisted contributions
>
> Generally, it's fine to use Gen-AI tools to help you create Pull Requests for sbt as long as you adhere to the following guidelines:
>
> - State in your PR description that you have used Gen-AI tools to assist in creating the PR.
> - No third party materials are included in the output; or materials that are included in the output are in compliance with an open source license compatible with Apache License.
> - Ensure that you review and understand all code generated by Gen-AI tools before including it in your PR - do not blindly trust the generated code.
> - Remember that the final responsibility for the code in your PR lies with you, regardless of whether it was generated by a tool or written by you.
> - Blindly copy-pasting code from Gen-AI tools is detrimental as it might introduce security and stability risks to the project.
>
> ⚠️ Maintainers that spot untested, unexplainable, Gen-AI copy-pasted PRs will close the related PRs and block the user from making further contributions. ⚠️

Given that there's no clear mechanism to forbid the use of Gen-AI assisted contributions, I'm taking the strategy to just state the bar the pull request must cross, which is that it must demonstrate the fix.

I speculate that most "miners" using the Gen-AI assistance, both the junior and the senior devs, but they are arriving at different results because Gen-AI doesn't magically make programmers a better programmer, beyond regurgitating code patterns in the training set. In that sense, we can think of it as a chain saw. If you give a chain saw to a trained carpenter, they could speed up some common tasks; however, if you give a chain saw to a novice, they wouldn't know what to cut, they wouldn't know when the cut needs planing, and likely that they would hurt themselves or damage the project.

If people have better suggestion than carefully reviewing the PRs, testing locally, and closing untested, unexplainable, Gen-AI copy-pasted PRs and blocking the users, please let me know.

### a chaotic Tidelift

In 2017, a few of the folks involved in Red Hat and Typesafe founded a company called Tidelift. Tidelift I think focused on enterprise subscription model to ensure security patches and licensing etc, but the novel aspect was paying the open source developers, rather than hiring them all like Red Hat did.

Gittensor seems like a chaotic version of the Tidelift where anyone can try to participate in this "gig". In the current form, it acts as a market of open source contribution and "miners" getting crypo coins. The energy expended by the project maintainers are externalities in this equation (I'm not interested in crypo coins), but like I mentioned above, we do get some interesting pull requests in return. See also the recent news on [curl stopping their bug bounty](https://curl.se/docs/bugbounty.html):

> Up until the end of January 2026 there was a curl bug bounty. It is no more.

Not that I'm concerned about Gittensor's health, I'm not sure how sustainable the bounty program would be, if it only relied on the windfalls from the Bittensor handouts.

  [gittensor]: https://gittensor.io/
  [scoring]: https://docs.gittensor.io/scoring.html
  [contributing]: https://github.com/sbt/sbt/blob/develop/CONTRIBUTING.md
