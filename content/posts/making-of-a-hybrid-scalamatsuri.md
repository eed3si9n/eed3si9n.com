---
title:       "making of a hybrid ScalaMatsuri"
type:        story
date:        2023-04-17
url:         making-of-a-hybrid-scalamatsuri
tags:        [ "scalamatsuri" ]
---

  [translating]: /translating-a-conference/
  [95]: https://www.slideshare.net/scalaconfjp/scaling-software-with-akka/95
  [univ]: /towards-universal-access-at-a-conference/
  [lifestyle]: /scalamatsuri-as-a-lifestyle/
  [hackathon]: /virtualizing-hackathon-at-scalamatsuri2020/
  [coc]: https://scalamatsuri.org/en/code-of-conduct/
  [helix]: https://helix-editor.com/

A two-day virtual/Tokyo hybrid ScalaMatsuri took place this weekend. Thanks to all the presenters, sponsors, and participants.

Lots of bumps and mishaps for sure, but hopefully it was a successful conference. I join as one of 16 ScalaMatsuri organizers, and also gave a talk and an open-mic session as well.

## 10 years of ScalaMatsuri

Here are some of the highlights of previous editions:

- We held the first ScalaMatsuri (at the time called 'Scala Conference in Japan 2013') on March 2, 2013, which I flew in as staff. According to [translating a conference][translating], I wrote an IRC to web socket relay server to live-translate the talks and project the text on screen. Looking at [the slides from the time][95], we were putting subtitles back then as well.
- 2014 was a pivotal year personally as I joined Typesafe, and thinking about Scala everyday, not just a grand hobby. Some of my concerns can be gleaned from [towards universal access at a conference][univ]. That's the year we adopted a Code of Conduct, and also started unconference like nescala.
- In the 2016 edition, we moved to a bigger venue, adopted a clear non-romantic-advance policy, CoC video, unlimited coffee brew by student volunteers, and public CFP with with travel grants to Tokyo. That year I've also worked with a graphic designer to create T-shirt design. Also Takeshita-san came up with a genious idea of using student volunteers to brew "infite coffee." Naturally people would gather between the sessions, and the conversation would start. Some of this I wrote up in [ScalaMatsuri as a lifestyle][lifestyle].
- In the 2017 edition was a special one with four members from EPFL flew in to Tokyo. Also I think that's one of the years we used ScalaMatsuri-original blend coffee roasted by my brother.
- As we hit COVID pandemic in 2020, ScalaMatsuri became a virtual conference using Zoom Webinar and Discord. I wrote up about on running a hackthon online in [virtualizing hackathon][hackathon].

## hybrid conference

ScalaMatsuri 2023 edition was operated by 16 staff (plus a few more volunteers at the venue). While there are some parts that I contributed, most is the result of many months of prepration and teamwork. Running a hybrid conference makes certain things more complicated than just an on-site or a virtual conference:

```
┌────────────┐    ┌──────────────┐    ┌────────────┐
│Presenter at├─┬─►│ Zoom Webinar ├─┬─►│Audience at ├─┐
│venue       │ │  │              │ │  │venue       │ │  ┌───────┐
└────────────┘ │  └──────▲───────┘ │  └────────────┘ ├─►│Discord│
               │         │         │                 │  │       │
┌────────────┐ │  ┌──────▼───────┐ │  ┌────────────┐ │  └───────┘
│Presenter   │ │  │ Real-time    │ │  │Audience    │ │
│online      ├─┘  │ interpreter  │ └─►│online      ├─┘
└────────────┘    └──────────────┘    └────────────┘
```

On Day 1, a few people presented from the satellite venue, while others presented remotely. Real-time interpretation was provided by professional interpreters from another location and spoken into Zoom Webinar. The staff members at satellite venue constantly had to switch the audio setting between the presenters and forwarding Zoom Webinar, which seemed confusing.

This meant that in practice only talks in Japanese were given at the satellite venue on the main track, and also the audio playback on at the satellite venue was limited to Japanese language as well. A few braved the satellite venue were instructed to bring a smart phone or a laptop to listen to the English audio via Zoom Webinar on their own earbuds.

Throughout all sessions, chat channels and quesiton channels were provided on the Discord server.

### 20 mininute talks

In 2021 edition I suggested that we should shorten the talk length mainly to 20-minutes, and try to make the talks single track, rather than having multiple tracks of long talks, and we continued that this year as well.

- The main motivation is that I find it difficult to focus on virtual lecture for more than 20 minutes.
- I've seen other conferences like Bazelcon and academic conferenes adopt short format.
- Since we have to put subtitles and hire realtime interpreters, making the main track single-track greatly reduces the work.

### open-mic, second track both days

A new experiment we started this year is having the open-mic (unconference track) as the second track on both days.

- This is also an idea I picked up from Bazelcon. They call it Bird-of-Feather, and people can discuss a topic in detail with smaller focused group.
- If speakers run out of time during the normal session, they can also continue in an open-mic.
- Having open-mic allows the conference to function as a place to actively discuss topics, not just listen to lectures.

Unlike the prepared talks, open-mic probably should be expanded to 45 or 60 minutes.

### general timezone matter for me

In the before-times, I'd fly in to Japan, so the timezone matter was sorted out. I participated from New Jersey (Eastern Daylight Saving Time), so for me, ScalaMatsuri started around 20:00 on Friday April 14th, which then went in till 4:00am on Saturday. Then on Saturday evening it started again around 21:00 until 5:00am ish, as we sent out a few emails out after the conference closed.

For now it kind of works because it's happening in the weekend, and I am ok with staying up overnight. As I get older, I wonder if staying up all night two nights in a row might become more difficult. I should remember to plan ahead, and consider flying in.

## return of keynote

Japan tends to have insulated tech culture, and a recurrent theme for ScalaMatsuri has been to introduce bigger trend in the English-based community to Japan, and also provide a platform for Japanese technologists to broadcast their ideas overseas. In that light, I thought Daniel Spiewak's 'The Case For Effect Systems' would be most fitting keynote. The topic is relevant, and also we can put Japanese subtitles and dubbing to present to the ScalaMatsuri participants.

One experient we wanted to try was pre-recording a talk. It's a bit more work upfront, but we thought having the ability to do so might be a workaround for the timezone issue.

- First, I contacted Daniel, who said yes. Thanks, Daniel!
- Next, I added subtitles to the slide deck.
- Daniel then sent me the recordings of both the slide deck and his camera.
- The slide he used wasn't the version with subtitles, so I then created a third movie, mirroring his slide movements.
- Using Adobe Illustrator, I created a PDF file with ScalaMatsuri logo to be used as the background.
- Using iMovie, I overlayed the subtitled movie on top of the background and exported it as forth movie.
- Next, I overlayed Daniel's camera movie on top as picture-in-picture.
- I edited a few scenes using iMovie. For example one slide was removed in Daniel version that was still in the subtitled version of the slides.
- Final version was exported as mp4 file.

Timezone-wise, the keynote was given in the evening time Boulder, so Daniel himself was standing by in Discord server, and answered the questions both on camera and on Discord. Some of the questions we asked:

- What's your take on the direct style? Is `build.sbt` an applicative direct style?
- Could you dig deeper into the differences between the effect system and Project Loom?
- What are the other examples of effect systems in other languages?
- Is there a plan to accommodate cats.effect.IO runtime to use loom's VirtualThread?
- I feel like we don't hear about Monad transformers much. Has IO won the IO vs transformer vs Eff war?
- Is there a plan to rewrite cats/ce to take advantage of the new scala 3 features?

## codifying the bathroom policy

In general, all conferences should understand and design its bathroom implementation. In a sense bathroom is where the gender rubber meets the road. Specifically it needs to anwer:

1. Who can use which bathrooms, and who decides who uses which bathrooms?
2. What signage would the bathrooms have?
3. How do we communicate the policy, either in writing or during the conference?

ScalaMatsuri staff did discuss this back in 2019 too, I think, but to mark our current policy (so we don't have to rethink each year), we codified it as part of [Code of Conduct operational policy][coc].

> - At the conference venues, participants are free to use bathrooms based on their own self-declared gender identity. A non-binary person is allowed to use any bathrooms.

The verbal script for the satellite venue:

> Thank you for coming to ScalaMatsuri satellite venue.
>
> In this venue, we have men's and women's bathroom at this second floor, and a multi-purpose bathroom at the first floor.
>
> As our policy, everyone can choose bathrooms based on your self-declared gender identity. If you identify as male gender, please use the men's room. If you identify as female gender, please use the women's room. If you identify as a non-binary person, either is fine.

I think this strikes the balance of individual rights and common practice. Men can use men's room, and women and use women's room. Who are men? Only the person can self identify! Non-binary person can use all the bathrooms. If you're uncomfortable with any of that, then _you_ go to the multi-purpose individual bathroom. And no change to signages.

Future organizers may take different route, but at least our current thinking would be recorded there.

## talks I gave

### talk: Helix and Scala

On Day 2, I gave a talk on Helix and Scala. [Helix][helix] is my current favorite editor, which out-of-box works with LSP and Treesitter, and I thought it would be a fun session to a demo session for 20 minutes. First I talked about modern jazz and how Bill Evans doesn't play the bass note because the bass player can play it, which elevated the piano as instrument from being an accompaniment to a solo intrument.

Helix, not implementing its own syntax highlighting grammar, and relying on each language to have a Treesitter parser, to me is analogous to Bill Evans. This was also a perfect moment for me to show off that I contributed [monokai_aqua](https://github.com/helix-editor/helix/pull/5578) to Helix.

In the seond half, I showed jumping to definition of Scala 3 macro, displaying compiler errors, and renaming method.

### open-mic: about sbt 2.x

Per request, I also gave another session on sbt 2.x on the open-mic track. For the most part this was quickly going over some of my activities like sudori, the idea post and RFCs. Since some of these material are only available in English, I hope it was useful to cover them in Japanese. People could also ask different questions or suggest ideas on the fly.

## feedback

Did you attend ScalaMatsuri? Let us know what we can improve on the feedback form(s):

- Day 1: https://forms.gle/TLvVLyrjziesueZZ9 (by April 22)
- Day 2: https://forms.gle/hDR9AkjGXQ7y93Rp7 (by April 22)
- Or email us at `cfp@scalamatsuri.org`
- Or write a blog post

Also if you enjoyed someone's talk, ping them on Twitter or email. They'll appreciate it.
