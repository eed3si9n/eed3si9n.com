---
title:       "RFC-2: sbt 2.0 RFC process"
type:        story
date:        2023-03-25
url:         sbt-2.0-rfc-process
tags:        [ "sbt" ]
---

- Author: Eugene Yokota
- Date: 2023-03-25
- Status: **Review**

## problem space

There are various technical decisions around sbt and Zinc that impact the Scala ecosystem, but currently the process of adding new features or changes to existing feature is not well defined. For the most part, the contributors like Scala Center and I come up with ideas and execute them.

## RFC process

At the Tooling Summit in Lausanne this week, Iulian Dragos suggested we adopt "a lightweight process based on RFC (request for comments) docs that can serve as a design document." In general, it would be a good idea to capture motivations and design intent of major changes.

### goal of the RFC process

To quote ["Why wasn't I consulted" - How Rust does OSS](https://www.youtube.com/watch?v=m0rakUuPXFM):

> The goal isn't that everyone's opinion gets the same weight. It's not a voting democracy. It's more that we are collectively exploring the space of tradeoffs. First the process is what are the options, what are the tradeoffs. At some point it reaches a steady state. That doesn't mean that everyone in the thread has reached the same concensus. In fact that usually doesn't happen. At that point the team would head towards making a decision, rejecting or accepting the RFC.

### details

- RFCs are sequentially numbered.
- RFCs have a status. (Review, Accepted, Implemented, Closed)
- RFCs can be a blog post, a Google Doc (in that case please give me edit rights) etc.
- RFCs have a GitHub discussion thread for discussion.
- RFCs are mutable. It's ok to keep editing the document incorporating the ideas brought up in the discussions.

### continuum of continuity

During the sbt 2.0 discussion in the Tooling Summit I drew something like this on the whiteboard:

```
┌───────────────┐           ┌────────────────────────┐
│               │           │                        │
│ Don't Change  │◄─────────►│ Change Everything      │
│ (stability)   │           │ (perf, UX improvements,│
│               │           │  simplicity etc)       │
└───────────────┘           └────────────────────────┘
```

Given that sbt has many builds out in the wild, my general philosophy is to avoid making huge jumps conceptually from sbt 1 (see also how long we kept bincompat for sbt 0.13). The iron rule is to bring the ecosystem forward together.

At the same time, since there already is sbt 1 for users who do not want any changes, sbt core devs shouldn't be too afraid of changes if that could improve sbt's user experience, performance, or the long-term maintainability of sbt etc.

## feedback

I created a discussion thread <https://github.com/sbt/sbt/discussions/7188>. Let me know what you think there.
