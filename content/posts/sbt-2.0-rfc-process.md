---
title:       "RFC-2: sbt 2.0 RFC process"
type:        story
date:        2023-03-25
url:         sbt-2.0-rfc-process
tags:        [ "sbt" ]
---

- Author: Eugene Yokota
- Date: 2023-03-25
- Status: **Implemented**

## problem space

There are various technical decisions around sbt and Zinc that impact the Scala ecosystem, but currently the process of adding new features or changes to existing feature is not well defined. For the most part, the contributors like Scala Center and I come up with ideas and execute them.

## RFC process

At the Tooling Summit in Lausanne this week, Iulian Dragos suggested we adopt "a lightweight process based on RFC (request for comments) docs that can serve as a design document." In general, it would be a good idea to capture motivations and design intent of major changes.

### goal of the RFC process

To quote ["Why wasn't I consulted" - How Rust does OSS](https://www.youtube.com/watch?v=m0rakUuPXFM):

> The goal isn't that everyone's opinion gets the same weight. It's not a voting democracy. It's more that we are collectively exploring the space of tradeoffs. First the process is what are the options, what are the tradeoffs. At some point it reaches a steady state. That doesn't mean that everyone in the thread has reached the same concensus. In fact that usually doesn't happen. At that point the team would head towards making a decision, rejecting or accepting the RFC.

### details

- RFCs are sequentially numbered.
- RFCs have a status (Review, Accepted, Implemented, Closed), and an outcome.
- RFCs can be a blog post, a Google Doc (in that case please give me edit rights) etc.
- RFCs have a GitHub discussion thread for discussion.
- RFCs are mutable. It's ok to keep editing the document incorporating the ideas brought up in the discussions.

### status and outcome

The status transitions in the following flow (happy path).

```
                ┌────────┐    ┌───────────┐
           ┌───►│Accepted├───►│Implemented│
┌────────┐ │    └────────┘    └───────────┘
│ Review ├─┤
└────────┘ │    ┌────────┐
           └───►│ Closed │
                └────────┘
```

Comments are open during `Review` state, and during this period the document will be actively updated to reflect the discussion. After some point, the core devs will either move the proposal to `Accepted`/`Closed` state. We'll update the decision in the outcome section. An accepted RFC should then transition to `Implemented`, but depending on the situation it could also move back to `Review` or `Closed` as well.

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

### who is going to work on it?

It bears repeating that my job is not maintaining sbt. I work on sbt in my free time, like many others who work on open source. When I write an RFC, I may work on it, or not if I am busy. But hopefully outlining the ideas would help other contributors and organizations plan for what may happen, participate in the design, or join the implementation effort.

If someone else writes an RFC, and we accept it, it should also be presumed that they work on it (or find someone to work on it), not me.

### alternatives considered: Google Docs?

I generally like Google docs for internal memos, but for public RFCs there are some issues:

- It's sort of distracting to read the original doc when there are too many comments. This is more so true for public RFC where anyone can comment on anything with wide spectrum of opinions (ranging from "this is the worst idea" to technical critique).
- On the discussion side, comments on Google Doc is too narrow to have detailed discussion. GitHub Discussion allows people to post and reply fairly long Markdown text.

## feedback

I created a discussion thread <https://github.com/sbt/sbt/discussions/7188>. Let me know what you think there.

## outcome

- 2023-03-30: This RFC is accepted, and actually already implemented in RFC-3.
- Based on the feedback, RFCs will have an outcome section to capture the decision. (You're reading it now!)
- Also I've added state transition diagram to clarify that RFC can either be accepted or closed.
