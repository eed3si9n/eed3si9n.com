It's been a month now, but on March 1, 2013 I flew to Japan to attend "Scala Conference in Japan 2013." That's the name of the conference.

### from a podcast

One day (June 2, 2012), I was listening to Scala Types recorded at Scala Days 2012, and someone (turns out it's @timperrett) said "I would love to see Scala Days in Asia. We had two in Europe now. It would be wicked to have it in China or Japan, or somewhere like that." I relayed this info on twitter saying there's an opportunity for the Scala community in Japan to invite the conference.

As the conversation started, [@jsuereth](https://twitter.com/jsuereth/status/208708052134789123) voiced support immediately:

> @kmizu @eed3si9n_ja If you guys manage to get a Scala conference somewhere in asia, I'll be there!

And @kmizu with the support of many, kicked off "Scala Conference in Japan" as the first major Scala conference in Japan.

### background

As a person who's been following both the Japanese Scala community and the mainline English-based community, I'd been feeling a bit of anxiety. There's a growing gap between the two, not unlike the Galápagos metaphors Japanese geeks use to describe their odd cellphone system.

My original assumption was that the divide stems from the language barrier. So, I started translating some prominent blog articles and official documents as they came up. When I blogged about Scalaz, I wrote them in both languages. But as the time went by, there were nagging suspicion that there were more to it.

Scala was always designed to be a scalable language, and there's a sense in the community that we're making the Scala the ecosystem better together by providing tools and ideas together. Almost like a collective sense of ownership. That notion, I feel is missing across the sea. Maybe there are cultural reasons behind it.

It's not like they are behind. A Tokyo Scala group just did their [100th meet](http://partake.in/events/615caa8e-dac4-405a-98a9-c8cc067b1ed9). There are [nine books](http://www.scala-lang.org/node/959) published in Japan on Scala. A highschool student wrote [an advent calendar](http://partake.in/events/4b3afdc8-e4ec-4010-b8ec-31b89210dda0) explaning one Scalaz typeclasses a day. There are lots of smart guys there, and that's precisely why I feel the sense of anxiety since little is visible to the rest the world.

### shoulders of giants

To make it an international Scala conference, it was understood that many of the talks would be in English. As the self-appointed translations guy, I started looking at what how other language communities in Japan were handling their conferences.

- [YAPC::Asia Tokyo](http://yapcasia.org/2012/talk/)
- [RubyKaigi](http://rubykaigi.org/2011/en/schedule/grid)

As the days approached, we found out that four Typesafe guys would be there in Tokyo, including Josh who said "I'll be there!"

### translation team

Living in the US and never making it to any of the face-to-face planning meetings for the conference, I was an outsider. But I somehow managed to become one of the translation leads once I made up my mind about flying to Japan. The other lead was Chris Birchall (@cbirchall) with wicked Japanese fluency and keen sense of humor. He'd been translating the conference website etc.

Borrowing from both Perl and Ruby guys, I proposed that we implement both subtitles for the slides and live text translations of the talks. Looking at the slide decks ahead of time would give us chance to study the lingos. Here are some of the slide decks we added the subs:

- [Jonas Bonér: Scaling software with akka](http://www.slideshare.net/scalaconfjp/scaling-software-with-akka)
- [Joshua Suereth: Coding in Style](http://www.slideshare.net/scalaconfjp/coding-in-style)
- [Jamie Allen: Effective Actors](http://www.slideshare.net/shinolajla/effective-actors-japanesesub)

Besides Chris and I, Yuta Okamoto (@okapies) and Kazuo Kashima (@k4200jp) were also involved in translation and review process. We also translated some of the Japanese slide decks into English, but many of the Japanese speakers wrote English slides themselves. Besides making sure the subtitles are technically sound, we also tried to keep it not too heavy.

### closed-captioning

The first thing most people think about text-based live translation of a conference talk is just using Twitter. It actually may be not that bad, but I've noticed that Ruby guys were typing into Word with big fonts, and that they've also developed a special app that aggregates tweets from the audience and messages from IRC for translations.

Why would Ruby guys write their own software to use IRC? My theory is that it's for responsiveness, avoidance of API limits, and for priotization of the messages. Tweets based on hashtag search would be slow and probably not that reliable. Even if they were, you can only tweet 127 times in 3 hours. Some of these decks were 70 pages long. In 3 hours, we could go over 127, tweeting every 85 second.

Instead of trying to figure out Ruby's kaigi_subscreen, I decided to whip up a clone called [closed-captioning](https://github.com/eed3si9n/closed-captioning) over a weekend. It's an Akka-backed Unfiltered web-socket server that's running twitter client and IRC robot as actors.

![closed-captioning](https://raw.github.com/eed3si9n/closed-captioning/master/screenshot.png)

The system worked nicely, displaying the live translations by Chris and me rapidly, and occasionally mixing in the tweets from the crowd. I missed a bunch of things at first as I was listening, translating and typing at the same time. Eventually I got the hang of it, just in time for the last talk by James Roper's [All work no Play doesn't scale](http://prezi.com/vtmxbxmpiroy/all-work-no-play-doesnt-scale/), in which he showed two slides and did an epic live coding using IntelliJ IDEA for the rest of the 40 min describing all the moves verbally.

### lightning talk

I wasn't planning on giving a talk, but I decided to sign up for a lunch time lightning talk since I'm flying all the way there. I wanted to address the community schism issue in a positive way.

- [Phasing out of "Customer": How to send a pull req](http://eed3si9n.com/scalaconfjp2013/)

Before even getting to the machanics, I spent some time describing the softer side of community-driven development, which I summarized as showing love. Sending shoutout on Twitter, building trust, that sort of things.

### people

Since I stayed at the same hotel as the invited guests, I got to spend some time with Typesafe guys, talking about random stuff over morning cappuccino. Apparently Jamie lived in Tokyo when he was a kid, and he knew the neighborhood we were in.

The most valuable experience for me, was just being there connecting faces with some of the people I've heard of since the Java days, guys I tweet to daily. Sadly almost no women were there. No doubt a single conference is not going to solve all the problems, but Scala Conference in Japan 2013 made a huge step in the right direction by bringing people out, getting them excited, and sharing ideas. I am hopeful that some of the attendants would emerge on our timeline soon.
