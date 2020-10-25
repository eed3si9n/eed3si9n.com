Here's a report of running a virtual hackathon at ScalaMatsuri Day 2 Unconference. Someone proposed it for the Unconference, and I volunteered to be a facilitator on the day, so I went in without preparation. I booked the time originally for 4h (noon - 4pm JST, 11pm - 3am EDT) but it was successful so it got extended after some coffee break.

One thing I emphasize is The Law of Two Feet:

> If at any time you find yourself in any situation where you are neither learning nor contributing: use your two feet and go someplace else

It's an online Unconference with multiple sessions going on, so I've stated up front that people should feel free to drop in and out of Hackathon and check out other talks, or come in later and code.

### what we used

- Zoom Meeting
- Discord
- Google Docs

Main communication was done using Zoom Meeting that ScalaMatsuri created. This allowed different participants to share their screen or ask questions. One potential drawback is that everyone can hear everything, so it wouldn't work well if multiple groups tried to pair program.

Text-based communication was done using Discord. Discord was used to share links or for asking questions. We didn't use it, a potential use of Discord can be for split-up room per project since it can [share screen](https://support.discord.com/hc/en-us/articles/360040816151-Share-your-screen-with-Go-Live-Screen-Share) in a voice channel.

A Google Doc was created for listing projects, GitHub issues, and for signing up to the issues to work on.

### work flow

- Ask around to see if there are any project maintainers who could be a mentor.
- Project maintainers list good first GitHub issues people can work on the Google doc, and give quick summary of the issue over Zoom.
- Participants can sign up to an issue by placing their name(s) next to it.
- Project maintainers give tutorial on to get unit tests and intergration tests going (partest for scala/scala, scripted for sbt/sbt etc)
- Project maintainers can also list more challenging work task and code together.
- Repeat the process as people come in and out.
- Mute and hack.
- Facilitator occasionally ping people to see if they have things to work on.
- When someone completes a task either successfully or unsuccessfully, they present a quick overview of what they did on Zoom. (This could be pushed to the end of the day if there are many participants)

### scala/scala

People were interested in contributing to scala/scala where Scala compiler and standard library is hosted. I also gave a fair warning that it's not uncommon for scala/scala pull request to sit around for several months especially when it's not a clear-cut bug fix.

Funnily the first issue that got assigned was a regression introduced by another participant @exoego, so he mentored Shibuya-san to the fix.

- Mitsuhiro Shibuya (@mshibuya) sent [Fix ArrayBuffer incorrectly reporting the upper bound in IndexOutOfBoundsException #9249][9249]
- Kazuhiro Sera (@seratch) sent [WIP: Add a regression test for issue #10134 #9250][9250]
- Sera-san also sent [Fix #12065 by adding scaladocs][9251]
- Taisuke Oe started looking into [tailrec doesn't mind recursive calls to supertypes in branches #11989][11989]
- TAKAHASHI Osamu (@zerosum) sent [Scaladoc member permalinks now get us to destination, not to neighbors #9252][9252]

Some useful links:
- https://github.com/scala/scala/blob/2.13.x/CONTRIBUTING.md#junit
- https://github.com/scala/scala/blob/2.13.x/CONTRIBUTING.md#partest
- https://docs.scala-lang.org/overviews/reflection/symbols-trees-types.html

### sbt

For any projects, it's actually hard to come up with a good first issue. Some could be too easy. Others could look easy but not possible to fix in a day. For sbt, I suggested fixes for recent sbt 1.4.0 features.

- Kenji Yoshida (@xuwei-k) [bumped up Dotty versions used in scripted tests #5982][5982] on his own
- Yoshida-san also fixed [Scala-2-dependsOn-Scala-3 feature with Scala.js #5984][5984]
- Taichi Yamakawa (@xirc) fixed [build linting warning about shellPrompt key #5983][5983]
- Yamakawa-san also sent [Use `lint***Filter` instead of `***LintKeys` for more reliable tests #5985][5985]
- Eugene Yokota (@eed3si9n) worked on [Try to workaround "a pure expression does nothing" warning #5981][5981]

### sbt-gpg

- Mitsuhiro Shibuya (@mshibuya) fixed [misleading loglevel given to gpg command stderr #181][181]

### Airframe

The maintainer Taro Saito (@xerial) dropped in and asked if someone could bump up Scalafmt version manually since Scala Steward doesn't run the scalafmt after the update.

- TAKAHASHI Osamu (@zerosum) sent [update scalafmt-core to 2.7.5 #1323][1323]

### Scala Steward

TATSUNO Yasuhiro (@exoego) tackled the root cause and decided to change the Scala Steward itself.

- TATSUNO Yasuhiro (@exoego) sent [Run scalafmt when upgrading scalafmt (opt-in) #1673][1673]

### summary

Some of the work might require some follow up work after the code is reviewed, but we managed to send around 12 pull requests, which I think is great. This is certainly more than one person could have coded in a day. In that sense, doing these Hackathon event is a huge force multiplier if you could pick up some issues get a group of people.

Through the context of talking about GitHub issues and coding, I had so much fun spending quality time with Scala programmers whom I've now known for years, and also meet new people. Thanks to all the participants, because it wouldn't have worked if you didn't show up and code :)

  [9249]: https://github.com/scala/scala/pull/9249
  [9250]: https://github.com/scala/scala/pull/9250
  [9251]: https://github.com/scala/scala/pull/9251
  [9252]: https://github.com/scala/scala/pull/9252
  [11989]: https://github.com/scala/bug/issues/11989
  [5982]: https://github.com/sbt/sbt/pull/5982
  [5984]: https://github.com/sbt/sbt/pull/5984
  [5985]: https://github.com/sbt/sbt/pull/5985
  [5981]: https://github.com/sbt/sbt/pull/5981
  [1323]: https://github.com/wvlet/airframe/pull/1323
  [1673]: https://github.com/scala-steward-org/scala-steward/pull/1673
  [181]: https://github.com/sbt/sbt-pgp/pull/181
