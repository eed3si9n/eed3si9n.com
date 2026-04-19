---
title: "shutting down the goldmine"
type:  story
date:  2026-04-19
url:   shutting-down-the-goldmine
tags: [ "sbt" ]
---

This is a follow-up of [sbt and the miners of the wild west](/sbt-and-the-miners-of-the-wild-west), in which I described the story of sbt/sbt getting listed on a crypo-based, open source bounty program called [Gittensor][gittensor], and subsequently getting a high volume of contributions from dozens of users, many using AI tools. Well, I'm shutting it down.

### general pace

In January I wrote

> According to [pulse](https://github.com/sbt/sbt/pulse), between December 25, 2025 and January 25, 2026, **23 contributors have opened 145 pull requests**, merged 132 pull requests, and closed 194 issues. While the stat includes some of my own pull requests, by far this has been the most active 1 month in the 10+ years that I've been the maintainer.

Looking at [pulse](https://github.com/sbt/sbt/pulse) again, between March 18, 2026 and April 18, 2026, **27 contributors have opened 140 pull requests**, merged 126 pull requests, and closed 78 issues. So stats-wise there are still many pull requests coming in, but I think the Gittensor pull requests have slowed down compared to the peak.

As I wrote last time, some of the contributions are interesting, and I enjoy working with a few of the folks.

### garbage pull requests

> However, as you might imagine, the pull requests come in varying degree of readiness:
>
> | issue         | junior dev | senior dev |
> |---------------|:----------:|:----------:|
> | easy issue    |      ⛅     |      ☀️   |
> | complex issue |      ⛈️     |      ⛅   |

Despite some mechanisms that Gittensor created, many of the attempts were low-quality pull requests. I'm not going to jump to the conclusion here to fault AI tools because AI tools at the hand of knowledgeable, senior devs can help with various aspects of coding. It's more that if you've never worked on Scala, or not coded at all before, getting an LLM subscription won't magically make you a _developer_. By developer, I mean someone who takes an issue, analyzes it, and fixes the issue. In the [Contributor's guide (CONTRIBUTING.md)][contributing], I kept using increasingly harsh language instructing them to first test the problem before coding.

> ### **Important**:  ⚠️ Pull request must be tested with GitHub Actions or human-in-the-loop
>
> Given the wide user base and the long history, not all issues are valid or relevant.
>
> - [ ] Before working on a pull request, please confirm with a Maintainer that a contribution is wanted for the issue.
> - [ ] Before working on a pull request, please confirm that **you can reproduce the reported problem** using GitHub Actions or your computer.
> - [ ] After making the code change, please confirm that **your change compiles, and has fixed the problem**.

I'm not sure if it's just ignored, some portions of pull requests were garbage pull requests that either sent in for an issue that's no longer reproducible, or doesn't fix the reported issue.

### sifting sand for falsehood

For example, a miner with private profile with full name "Full Stack Developer" sent in a pull request [[2.x] fix: Forward WarnOnSourceChanges warning to sbt client #9092](https://github.com/sbt/sbt/pull/9092). This pull request claims to fix an issue [#6831](https://github.com/sbt/sbt/issues/6831), an issue on sbtn which doesn't display reloading warning.

The pull request has well-written summary section, problem, and solution outlined with bullet points. The AI Disclosure is "N/A", so the person has written the code by hand. The diff is concise:

```diff
-    val loggerOrTerminal =
-      name.flatMap(StandardMain.exchange.channelForName(_).map(_.terminal)) match {
-        case Some(t) => Right(t)
-        case _       => Left(state.globalLogging.full)
-      }
+    val loggerOrTerminal = name.flatMap(StandardMain.exchange.channelForName) match {
+      // Non-interactive network clients only consume build/logMessage notifications.
+      // Route these warnings through the logger so they are delivered to sbt -client.
+      case Some(c: NetworkChannel) if !c.isAttached => Left(state.globalLogging.full)
+      case Some(c)                                  => Right(c.terminal)
+      case None                                     => Left(state.globalLogging.full)
+    }
```

It even comes with a test on top of existing `ClientTest.scala`. The test is slightly longer than the change. At a glance, it might look like a great first contribution. It didn't quite make sense to me, so I let it sit for a day or two. What I realized later is that [#6831](https://github.com/sbt/sbt/issues/6831) can no longer be reproduced using sbt 2.0.0-RC12.

If the underlying issue is already fixed, the contributor can basically send in any plausible looking code and claim to pass the test. If I didn't stop and ask "does this make sense", this could have easily gone in. Moreover, I worry these falsehood can be used for attack.

### falsified logs

There was another pull request sent in by another miner/contributor who claimed to fix a duplicate standby bug, which was recently reported. When I asked if he had tested the fix manually, he attached a log file:

```bash
=== BUGGY: Simulating two standBy() calls for 5s setting ===

--- Call #1 (Boot.main direct) ---
[info] [launcher] standing by: 5
[info] [launcher] standing by: 4
[info] [launcher] standing by: 3
[info] [launcher] standing by: 2
[info] [launcher] standing by: 1
```

The person has also attached a Python script that generated the log file:

```python
def stand_by(duration_s: int, label: str):
    """Simulates xsbt.boot.Boot.standBy()"""
    print(f"\n--- {label} ---")
    for i in range(duration_s, 0, -1):
        print(f"[info] [launcher] standing by: {i}")
        time.sleep(0.1)  # Sped up for repro; real is 1000ms
```

So instead of running sbt, he created a Python script that generates a fake log. I can't tell if the person is disingenuous or maliciously stupid.

### pestering for reviews

Gittensor miners are sending pull requests, likely motivated chiefly for the crypto payout. To prevent abuse, the miners can open 10 pull requests at a time. This creates an incentive to try to land an open pull requests as fast as possible, which results to constant pestering for reviews.

It gets tiring, especially because I'm maintaining sbt as a volunteer hobby project.

### maintainability concerns

Related to the misaligned incentives, Gittensor miners gets paid based on the size of the pull request, so the bigger the better. As long as the tests pass, they could use hardcoded variables and `return` statements (idiomatic Scala selcome uses `null` or `return`), but they won't have to maintain the code base in the long term.

This maintainability concern exists for any drive-by pull requests, but with AI tools and crypto payout, there's little incentive to make the smallest amount of change necessary to fix the issue and/or send cleanup pull requests.

### limitation of blocking the contributors

I didn't know this functionality existed until Gittensor miners came, but GitHub has a feature to block someone from making future contributions to an organization. What I do when I come across garbage pull request is to close the pull request and block the miner. This should decrease their credibility score as a warning to other projects.

There are limitations to this approach. For one, some of the miners get frustrated that they were blocked from sbt. Some start negotiating or apologizing on Discord channel.

It's a stressful situation for me and other maintainers as well. Open source is supposed to be a nurturing, fun activity, based on high trust. With anonymous miners, I have to implicitly take adversarial stance against the potential contributors and contributions. If this continues, maintainers would burn out, make a bunch of folks angry about sbt, and/or a nation state would inject some weird code into a simple build tool. So I sent in a pull request [remove sbt/sbt from Gittensor](https://github.com/entrius/gittensor/pull/590) effective immediately.

### Gittensor mining as an agentic future

Despite our departure, overall experience of interacting with many miners was a new experience for me, and I'm grateful to their contributions. In both positive and negative ways, I was able to peak into a slice of agentic future. With LLM/AI tools, the miners went through the entire list of GitHub issues that were long neglected, and opportunistically fixed or closed hundreds of them. It also showed that many of the technical-looking changes can be false or unsafe vector of attack.

I currently do not use LLM/AI tools on sbt, except for translating documentations, but I'll keep an open mind about them going forward. However, more than anything, I'll be looking forward to normal pull requests sent in from the sbt users.

  [gittensor]: https://gittensor.io/
  [scoring]: https://docs.gittensor.io/scoring.html
  [contributing]: https://github.com/sbt/sbt/blob/develop/CONTRIBUTING.md
