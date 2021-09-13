---
title:       "ScalaMatsuri as a lifestyle"
type:        story
date:        2016-02-13
changed:     2021-09-13
draft:       false
promote:     true
sticky:      false
url:         /scalamatsuri-as-a-lifestyle
aliases:     [ /node/187 ]
tags:        [ "scala" ]
---

  [sasaki]: http://sasakishun.tumblr.com/
  [katiekovalcin1]: http://kovalc.in/2015/08/12/harassers.html
  [hinata]: http://makebooth.com/booth/hinatique
  [suzuka]: http://www.vi-vo.jp/member-list/9-index/member-list/67-ayasuzuka
  [ky]: http://www.kytrade.co.jp/english/index.php

For me (and for many of the 27 organizers, I imagine) ScalaMatsuri is a lifestyle. It's true that there was a successful two-day conference in Tokyo with 550 participants. But for us the organizers, the preparation has been going on since February 28th, for 11 months. Despite the fact that my contribution was small, planning ScalaMatsuri 2016 was by far the most amount of involvement I've committed to. Through the course of planning months, there were many discussions over Slack, Hangouts, and occasionally even face-to-face. The fun part was coming up with the ideas together, and seeing them materialize. Sometimes, I was the one coming up with radical ideas that were being executed by someone else, while other times, it was the opposite case and I was getting my hands dirty.

I've already written a lot of what I wanted to say in [A regional tech conference that's also global](http://blog-en.scalamatsuri.org/entry/2015/10/06/024029), so there might be some overlap over here.

### March, 2015

By March 16, 2015, ScalaMatsuri 2015 planning was in motion. I know this because Oe-san ([@oe_uia](https://twitter.com/oe_uia)) showed up at Scala Days San Francisco wearing a matsuri garb called happi. He was promoting Matsuri to the Scala Days goers. One of the ideas that spawned there was moving the timing to January of 2016, so people can combine the conference with skiing or snow boarding.

During the walk back from the Scala Days venue to the hotels, I remember discussing with Oe-san the idea of opening up CFP to the public and providing fixed amount of travel support. It's an idea I've been tinkering with since 2014 ([towards universal access at a conference](http://eed3si9n.com/towards-universal-access-at-a-conference)) that I think has a number of benefits over closed-door invitation and paying their expenses. Especially given the extra time we got from postponing the conference, it seemed doable.

### Github issue all the things

We abandoned the Trello board and co-meeting from the previous conferences, and moved into using Slack and Github issues. Both complemented each other, and I think it was a good decision. We used labels to categorize issues to different teams, which was also helpful.

One tricky thing about Github issues when we have many micro tasks, is that it quickly becomes difficult to track where each task is currently at. Is it waiting for something to happen, or is someone actively working on it? I started putting a mini status into the subject line enclosed in a parenthesis. For tasks with clear predefined steps like the translation tasks, this made it clear where things are at.

### a website evocative of Japan

During the earlier phase of preparation, the organizers met once a month. Since some of us don't live in Tokyo, the meeting was streamed over the Google Hangout and we could join the discussion there or using Slack.

One of the topics in May was about making a pretty landing page that's evocative of Japan to attract speakers and participants from overseas. The project was commissioned to a designer after a public bidding. After the initial setup Kawachi-san ([@kawachi](https://twitter.com/kawachi)) has been maintaining the site. The source for the site is available at [scalajp/2016.scalamatsuri.org](https://github.com/scalajp/2016.scalamatsuri.org/).

### two-way interpreters by the professionals

For 2013 and 2014, we provided subtitles to the slide decks, and live text translations to the talks using a kaigi_subscreen clone. (More on that [here](http://eed3si9n.com/translating-a-conference)). We could wing the subtitles because we had weeks to prepare for them, but the quality of the live translation was not ideal. As the number of participants expanded in 2014, we heard more complaints about how difficult it was to follow along the talks given in English. This is a contrasting issue compared to European cities like Berlin and Amsterdam where programmers seem to listen/speak English.

Following suit of PyCon JP, YAPC::Asia Tokyo, and Ruby Kaigi, we've adopted two-way interpreters from [KY Trade][ky] in two of the halls. Overall, this was a success. The task of finding the interpreters and coordinating with them were done by the leader of Translations team, Okamoto-san ([@okapies](https://twitter.com/okapies)).

### t-shirt design

I thought ScalaMatsuri should make a cool t-shirt, and it seemed like this was the best year to do it.
Similar to the website, I wanted a t-shirt that's inspired by matsuri, Japanese festival. At the same time, I definitely wanted to avoid the trap of making something that's gaudy or nationalistic. My inspiration for the design was the closing the artisans would wear such as happi lobe or koiguchi shirt.

I took some of these ideas to a graphic designer [Shun Sasaki][sasaki], and we worked together to make the idea into the actual design. We repeated the process of Sasaki-san coming up with some suggestions in the form of a mockup t-shirt, me giving back some feedback such as "I want the indigo color to be closer to black." Some of these feedback were my personal opinions and others from the Planning team members.

I've sent him down the rabbit hole of experimenting with Japanese typography, and incorporating Japanese characters. This turned out to be more avant garde than that we wanted, and in the end, we worked really hard to remove all text other than what's absolutely necessary. Sasaki-san was patient throughout the process, and I'm really happy with the final design.

<img src="http://eed3si9n.com/images/scalamatsuri-tshirt.jpg"/>

While I was obsessing on the t-shirts design, Aoyama-san ([@aoiroaoino](https://twitter.com/aoiroaoino)) was in charge of all other swags, such as hoodie for the staff member, tote bag, sticker, and notebook for the participants. This process involved picking the merchandise, and retrieving samples. Sasaki-san's t-shirt design was adopted for all of our swags this year.

<img src="http://eed3si9n.com/images/scalamatsuri-hoodie.jpg"/>

### August 4th, public CFP

When trying to convince someone to give a talk all the way in Japan, an important thing is to give them enough time to plan.

<blockquote class="twitter-tweet" data-lang="en"><p lang="en" dir="ltr"><a href="https://twitter.com/hashtag/ScalaMatsuri?src=hash">#ScalaMatsuri</a> 2016 CFP is now open! we are trying voting + travel support (up to $2000, ymmv) + hired interpreters<a href="http://t.co/Kk2p1il42P">http://t.co/Kk2p1il42P</a></p>&mdash; eugene yokota (@eed3si9n) <a href="https://twitter.com/eed3si9n/status/628591085904904192">August 4, 2015</a></blockquote>
<script async src="//platform.twitter.com/widgets.js" charset="utf-8"></script>

We opened CFP on August 4th. So it started roughly 6 months ahead of the conference, and it was open until October 15th. Luckily this overlapped with Scala World 2015 where Oe-san again laid the groundwork by promoting Matsuri. In the end, we got 60 English talk applications and 57 Japanese talk applications.

We used Google Forms to collect the talks. Iwanaga-san ([@kiris](https://twitter.com/kiris)) implemented an automation to turn each submission into a Github issue.

### universal access

Another agenda I've been pushing among the ScalaMatsuri organizers is the Code of Conduct. As the participation base gets wider for the tech conferences around the world, we are seeing more reports of awkward situations and outright harassments. Or it could be just that we are at the stage where we can talk about this publicly, and this type of things always happened. In any case, ScalaMatsuri adopted Geek Feminism style CoC in 2014 like PNW Scala, nescala, and Scala Days.

<blockquote class="twitter-tweet" data-lang="ja"><p lang="en" dir="ltr">Today a conference lost a woman speaker while simultaneously promoting a dangerous one. <a href="http://t.co/tTLTi6crzP">http://t.co/tTLTi6crzP</a></p>&mdash; Katie Kovalcin (@katiekovalcin) <a href="https://twitter.com/katiekovalcin/status/631530242314600448">August 12, 2015</a></blockquote>
<script async src="//platform.twitter.com/widgets.js" charset="utf-8"></script>

As I reflected on more disturbing reports on harassments like [We Still Let Harassers Participate In Our Community][katiekovalcin1] and other anecdotes I've heard personally, it became clear that simply posting CoC on the website wasn't enough.

First, I suggested that we adopt stricter policy on making advances, asking people out, etc. By strict, I mean we ban it. Usually the first reaction people have is some discomfort to the notion of restricting participant's behavior, which I think is normal. But the discomfort on the receiving end is far greater and damaging to our conference. Imagine that someone musters up courage to submit the talk publicly, prepares the talk, overcomes the nerve and gave the talk, and some random person reaction is "You look so hot. Can I call you some time?" Unfortunately, this happens all the time.

Next, we discussed protocols on how to deal with the issues during sessions. The idea is to have a referee in each room, and either give warnings later, or if needed, interrupt the session. The ruling by the referee would have the absolute power, at least on the spot.

No amount of rule making is going to help, if the policy and the thinking behind it not communicated effectively. Drawing inspiration from stylish Virgin Atlantic and Virgin America's security videos, I bought up the idea of making a video introducing the CoC:

- [Virgin Atlantic Safety Video](https://www.youtube.com/watch?v=LlKXhL4mlMY)
- [Trip: The Virgin Atlantic Safety Film](https://www.youtube.com/watch?v=8XNxZh9_YN0)
- [Virgin America Safety Video #VXsafetydance](https://www.youtube.com/watch?v=DtyfiPIHsIg)

In a video form, we can avoid missing to communicate important points, and also we'll be able to reuse it multiple times. At first, the idea seemed far fetched, but Oe-san ([@oe_uia](https://twitter.com/oe_uia)) ran with the ball, and worked with an animation artist [Kaori Hinata][hinata] to turn it into a reality. First, she came up with nine sets of characters, and the organizers agreed to go with the animals. Next, she turned the talking points into a story board. After several rounds of discussion to polish the script, the voice was recorded by a professional voice actor [Aya Suzuka][suzuka] who played four roles by herself.

<iframe width="560" height="315" src="https://www.youtube.com/embed/lIfOQNTWdxI" frameborder="0" allowfullscreen></iframe>

During the character design, we avoided obvious villain-looking stereotypes like monsters, germs, and big bully types. The idea we intended to infuse was that we all harbor the seeds of prejudice, and often the majority group is unaware of how the other side might feel.
The primary objective of the CoC is establishing the means to deal with harassments. But more important secondary effect is that the CoC acts as a preemptive signal of ScalaMatsuri drawing the line on the sand. This signal could prevent offhand remarks on other's appearance or other insensitive comments, since it would be clear from the get-go that "this is not the time or the place." Hopefully, the signal reaches to potential speakers and participants that they are welcome at matsuri.

Make no mistake that even within the ScalaMatsuri organizers, not everyone is a Massachusetts hippie in their personal lives. But I think we all recognize the fruit of having a diverse and fun conference. For this, I'm truly appreciative of both the organizers supportive of these efforts, and of the others who let us push the line this far.

### CFP translations

Probably one of the most labor intensive process for the Translation team was translating all of 117 submissions' talk titles and their abstracts into both English and Japanese. I've translated 50 of them, and reviewed (and sometimes re-translated) the rest of the translations done by other members. The Translation team loosely consisted of Okamoto-san ([@okapies](https://twitter.com/okapies)), Go Tanaka-san ([@tan_go238](https://twitter.com/tan_go238)), Takei-san ([@taketon_](https://twitter.com/taketon_)), Kimura-san ([@kimutansk](https://twitter.com/kimutansk)), and Sho Tanaka-san ([@tshowis](https://twitter.com/tshowis)), Okada-san ([@ocadaruma](https://twitter.com/ocadaruma)), Omura-san ([@everpeace](https://twitter.com/everpeace)), Aoyama-san ([@aoiroaoino](https://twitter.com/aoiroaoino)), Kawachi-san ([@kawachi](https://twitter.com/kawachi)).

The translation was necessary because we wanted the session ideas to attract participants from both domestic and overseas. Another reason was because we decided to let the public vote for the talks.

### public voting

As a fan of nescala, I've been a proponent of public voting. Voting sounds simple enough, until you start thinking about what parameter you're trying to collect. For example, how should the language be split up between Japanese and English talks? 80% of the English talk applications were 40-min, whereas more than half of the applications in Japanese talks were for 15-min segment. How many votes should one person cast?

Thanks to the Shogun sponsors, we were sure about the budget to invite speakers for half of the slots, so we've settle on the language ratio of 1:1 for both 40-minute and 15-minute sessions on Day 1: That is 8 speakers each for long ones, and 3 speakers each for the short ones.
Next, we adjusted the number of the votes per person to be 25% of the available selection per category. This allowed us to compare the popularity of sessions across both languages.

Since we didn't have enough time to implement a custom voting system, we used Google Forms that displayed only the session titles in a random order. This required the voters fish for the session abstract on another website, which also displayed the session in another random order. This might have resulted to people voting mostly based on the titles. If we are going to do the voting again, we should consider implementing a system that lets you read the abstract more easily.

One aspect of letting hundreds of people vote for 22 sessions is that the result ends up forming a cluster of similar topics. Looking at the voting result of 40-minutes talks, another observation we can make is that there was a pack of 6 or 8 talks that clearly got more votes than the others, but then the curve flattens to one or two votes difference.

<img src="http://eed3si9n.com/images/scalamatsuri-40min-votes.png"/>

For multi-track conference like ScalaMatsuri, I am starting to think that determining schedule purely based on the voting result is not going to yield the best result. For example, having 10 talks named "Intro to FP" or "Intro to DDD" wouldn't be a fun conference, even if the constituency is really interested in those topics. A potential workaround might be to reduce the elected slots to top 3 or 4, and allow the organizer to handpick the rest. Also note that given all sessions had 25% chance of receiving a vote, even when all voters rolled a die, any session that received significantly fewer than 25% of the vote should be probably be avoided.

### time table

During the 2013 planning I remember suggesting the guys making [the time table](http://2013.scalamatsuri.org/en/program/index.html) to put 20 minute recess every now and then, similar to how [Scala Days 2011](https://wiki.scala-lang.org/display/SW/ScalaDays+2011+Resources) was organized. I think the schedule went mostly ok.

This tip was lost in the 2014 [program](http://2014.scalamatsuri.org/en/program/index.html). Probably because the two halls were located next to each other, the schedule was packed with only 5 or 10 minutes recess in between. Combined with some speakers going over the their allotted time or technical difficulties connecting Linux laptop to the projector, there was a major delay in the schedule.

This year, I've butt myself into the scheduling again, and resurrected the 40 minute talk + 20 minute recess system. If you want the talk to start on time, people need to be seated a few minutes in advance. 100 to 400 people getting out of a room and getting back in alone would take 5 to 10 minutes. Add in choke points like rest rooms and stair cases. With 20 minute recess, the participants have enough time to grab a cup of coffee, and visit a sponsor booth.

Another system I borrowed from Scala Days is the dedicated time keeping person. Here's from actual email I sent out to the speakers:

To make sure everyone gets their turn, we'd have to be fairly strict about keeping time.

1. Your scheduled END time does not change even if you can't connect to the projector in
   the first 10 minutes. Please come early to get your PC connected.
2. Someone who would be holding up a sign 10, 5, and 1 minute before the time is up.
3. A bell would ring at the end.
4. If possible, we'll try to cut the sound off after exceeding 5 minutes past the end.

As far as I know, most of the sessions proceeded in a punctual manner this year.

### placing the sessions

After the sessions were selected, I came up with the proposal for arranging them in order. A major constraint was that the main International Conference Hall fit 400 people, but the other two locations Media Hall and Conference Room 1 fit only 100 people each, and that the live interpreters were not available at Conference Room 1.

For the morning sessions, I used the main hall to describe what a Reactive System is and how it relates to microservices, while other topics were placed in smaller halls. For the afternoon sessions, I've placed topics related to pragmatic functional programming in the main hall while further topics related to Reactive Systems and other topics continued in Media Hall.

Apparently Sera-san's session was so popular that people were overflowing from the room. This kind of thing was bound to happen since the hall size were lopsided, and we were simultaneously trying to balance the number of talks given in each language. Given that more than half of the Japanese talk applications were for the 15-minute segment, I had no choice but to place them in the main hall.

To publicize the scheduling, I worked on updating the website as well:

- https://github.com/scalajp/2016.scalamatsuri.org/pull/328
- https://github.com/scalajp/2016.scalamatsuri.org/pull/329
- https://github.com/scalajp/2016.scalamatsuri.org/pull/330

### speakers support

Since I was involved in both the CFP process and the Translations team, I was corresponding with the speakers directly this year more than the previous conferences, especially with the speakers from overseas.

Making [travel info](http://scalamatsuri.org/en/travel/) page was one of the first things I did.
This was communicated to the selected speakers along with CoC, limits on travel support etc.

Next, I created Google Groups to communicate with the speakers, which helped in shooting out the emails. On the receiving end, too, the list should help them to appropriately organize the messages related to ScalaMatsuri.

### December 22nd, slide deck with subtitles

From the very beginning, we've settled on enforcing English slide deck, even if the presentation itself is given in Japanese. In addition, we've put in Japanese subtitles to the slides.
This year, I've been more proactive on communicating [the format of the subtitles](http://scalamatsuri.org/en/slides/), so I think there was less confusion around this matter.

The Translations team collected the slide decks from the speakers by December 22nd, five weeks ahead of the conference, so we can place Japanese subtitles for the English speaker's slide decks. Japanese speakers were asked to provide both the English body text and the subtitles, and we've help them proof the English part. I'd like to think that the subtitle have aided the live interpreters since we are likely more versed in terminology around Scala, functional programming etc.

Of course, not everyone submitted the slide decks on time, and we were doing some translation till the day of the conference.

### actual ScalaMatsuri

During Day 1, I was doing the CoC referee so I was mostly in the main hall watching the sessions.
As far as I know, there were no harassment incidents during ScalaMatsuri 2016.

I got to hang out with some people after the sessions, but the two days went by in a flash.
One of my regrets is that I didn't make enough effort to reach out to all the speakers and other participants. I appreciate anyone who came by and said hello.

During one of the lunches, [@lyrical_logical](https://twitter.com/lyrical_logical) and I talked about typeclass being "first class" in Scala and [lubbing](http://eed3si9n.com/stricter-scala-with-ynolub). One thing we agreed on was that observed issues around lubbing was caused by the combination of the Scala compiler behavior and the implementation of the libraries, in particular the design of the Scala collection library. I just want to code in Scala normally, but when I say I don't want the (overloaded and semantically corrupt) inheritance in type inference, some people think "it's not longer Scala," which I question. As always, these hallway sessions tend to be more fun than the sessions.

### thinking in Cats

I gave a talk on the thinking behind Cats. I didn't want to distill the talk into a take-home one-liner, but rather tried to convey the complex background as is. I figured there are other talks later in the day that talked about the mechanics of the functional programming, I should highlight the motivational background.

<iframe src="//www.slideshare.net/slideshow/embed_code/key/txv4p2jq6jowSk" width="595" height="485" frameborder="0" marginwidth="0" marginheight="0" scrolling="no" style="border:1px solid #CCC; border-width:1px; margin-bottom:5px; max-width: 100%;" allowfullscreen> </iframe> <div style="margin-bottom:5px"> <strong> <a href="//www.slideshare.net/EugeneYokota/thinking-in-cats" title="Thinking in Cats" target="_blank">Thinking in Cats</a> </strong> from <strong><a href="//www.slideshare.net/EugeneYokota" target="_blank">Eugene Yokota</a></strong> </div>

I ended up putting too many things, but not explaining each parts well enough.

### intro to sbt

During the unconference on day 2, I gave a talk on sbt intro without any slide decks.
Maybe because it was with smaller audience and I was more comfortable with the material, I felt like this session went better than the one on Cats.

### unlimited coffee

Takeshita-san ([@takezoux2](https://twitter.com/takezoux2)) came up with the idea of organizing a team of student volunteers to make coffee non-stop using multiple coffee machines throughout the conference this year. This was pure genius. People gathered around between the session to get coffee, have snacks, and had conversations about how safe the type system should be. I hope we keep this system for next year too. Takeshita-san, the leader of Planning team, was in charge of pretty much everything that's not related to the venue and translations. A bunch of us working on CFP, swag, and catering reported to him.

### future directions

ScalaMatsuri is clearly growing, and we need to continue to scale the organization. It's not like we need to make it bigger, but we should make the system more robust so people can join, work on tasks, and leave more easily. For that, we as organizers should work on documenting the overall process and details, so we don't have to reinvent or rediscover them each year.

One thing we couldn't work on this year was the idea of making the conference infant and kids friendly. In an actual Japanese matsuri, you see many kids running around the shrine, and I see that as a goal to pursue. Similar to airlines, we should have a few seats designated near the entrance as priority seats (we actually did this, this year), and explicitly allow infants in the audience.

For older kids, it would be fun to have programming workshop, or just some play area where kids and parents can hang out. Ideally we should have professional sitters looking after the kids while the parents check out the sessions.

### summary

Two major goals that I considered ScalaMatsuri 2016 had are:

- Providing a space for Japanese Scala community to socialize, and present ideas to the international audience.
- Making a global technical conference with the universal access, where people from various background such as languages, gender, or ethnicity, can be comfortable.

Achieving these goals took continuous planning by the organizers, and involvement of both volunteers and professionals. Without the generous funding many sponsorship companies like CyberAgent, chatwork, Maverick, Septeni Original none of these would not be possible. Thanks also to Typesafe for letting me work on ScalaMatsuri.

Like the real matsuri, the real fun is in dreaming up the future with other organizers and seeing it come true once a year. If you're interested, you should check out your local conference organization.
