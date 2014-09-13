This year was the second Scala conference in Japan. We've changed the name to [ScalaMatsuri](http://scalamatsuri.org/en/), which means Scala festival in Japanese. 300 tickets sold out. With invited guests and free tickets for sponsors, there may have been even more people. The venue was at CyberAgent, which runs blog service and online ad services.

Day 1 kicked off with Martin's ([@ordersky](https://twitter.com/odersky)) 'Evolution of Scala.' Many people were looking forward to see Martin, so I think it was full house from the get go. During all sessions that I attended, I was busy typing live text translation using my [closed-captioning](https://github.com/eed3si9n/closed-captioning) both from English to Japanese, and from Japanese to English along with other members [@cbirchall](https://twitter.com/cbirchall), [@cdepillabout](https://twitter.com/cdepillabout), [@okapies](https://twitter.com/okapies), and [@oe_uia](oe_uia).

Next up, I gave 'sbt, past and future' in Japanese. Started out with a demo to showcase first steps in starting a project from "mkdir helloworld" to running continuous testing. Then I reintroduced the basic concepts, new features coming up in 0.13.6 such as HTTPS by default, consolidated resolution and eviction warnings, and finished the talk with future outlook of "sbt as server" and further performance enhancements. I had gotten permission from LinkedIn's press team to mention that they are funding the perf works, so I was able to give them credits for the enhancements.

There were some questions on the relationship between Activator and sbt. I think people were happy with my answer of Activator's three use cases:
- offline distribution of Typesafe stack in a thumb drive for training sessions
- improving the out-of-the-box experience for new users
- platform to host tutorials that the users can type in code 

Many positive response on sbt server, both for having better integration with IntelliJ and for future potential of being able to do remote compilation type things.

Jon Pretty ([@propensive](https://twitter.com/propensive)) gave 'Fifty Rapture One-Liners in Forty Minutes.' A nice library that provides abstraction for reading/writing resource from online and slurping/parsing them into case classes. Lots of language tricks were used including enrich-my-library, macros, and dynamics to provide user-friendly json processing. I liked the fact that it lets the user choose json library backend.

Sponsor LT session during Japanese style fried chicken lunch box. The bento box was so good, I don't remember much about the talks except for everyone saying "we are hiring!"

Yevgeniy (Jim) Brikman ([@brikis98](https://twitter.com/brikis98)), ex-LinkedIn Play lead, gave a talk 'Node.js vs Play Framework.' He introduced his scorecard method of comparing two web frameworks, not just in terms of plain performance, but also including maintainability, learning curve, and code size scalability. Node.js won some, Play won others, but overall it was a well-balanced analysis of where they both stand. 
Someone from the audience asked how Play is in comparison to other Scala web frameworks, and Jim answered that LinkedIn evaluated all frameworks and Play is miles ahead of the rest, especially in terms of asynchronous handling.

Yugo Maede ([@yugolf](https://twitter.com/yugolf)) from TIS gave 'Scalable Generator: Using Scala in SIer Business.' This was like Rail's Scaffold equivalent using Play and Slick. For enterprisey business application, these tooling would be useful.

Aaron Davidson from Databricks gave 'Building a Unified "Big Data" Pipeline in Apache Spark'. He showed Databrick's yet-released service that can render clustered information as a graph on browser-based repl. I think in the demo, he created a Spark Stream of tweets, ran Spark SQL to extract just the text, and used k-means categorization to auto-detect the language. The in-browser graphs had wow factor.

Next session was coffee break along with 'Business Meeting presented by Typesafe'. I figured it would be most effective if it's an opt-in session targeting production users.

After the coffee break/business user meeting, Yoshimasa Niwa ([@niw](https://twitter.com/niw)) from Twitter gave talk on 'Getting started with Scaling, Storm, and Summingbird.' The story of how these tools came about was fun to listen to. One of the things these tools enable is to calculate tweet per second real-time, and as an example he mentioned the curse of balus. This is a known phenomena in Japan that about once an year Nippon Television would air Miyazaki's 'Castle in the Sky.' Exactly at the moment the main character chants the magic word of destruction, many people who are watching it live would tweet "balus." Here's Wall Street Journal from last year:

> By the time the movie was last aired, in 2011, the action had moved to Twitter, which also worried whether its servers could take the strain. Despite Twitter’s pleas through staff accounts for restraint, at the magic moment Japanese netizens recorded 25,088 "balus" tweets per second, a record which was only beaten in Japan by this year’s stroke-of-midnight New Year’s greetings, with 33,388 tweets.

Takehide Soh ([@TakehideSoh](https://twitter.com/TakehideSoh)) from Kobe University gave a talk in English on 'Scarab: SAT-based Constraint Programming System in Scala'. Probably the only academically flavored talk, but personally this was my favorite. Scarab provides expressive DSL around state-of-the art CSP (constraint satisfaction problem) solver and SAT techniques. This project hit close to home as I've been working on Ivy resolution performance problem, and graph resolution with eviction rules and exclusion can be expressed as CSP. Eclipse for example uses SAT4j to solve plugin dependencies. I caught Takehide afterwards to see if my problem can be expressed using SAT as well, and he was excited to get his hands on real-world problem for his postdoc research.

Dwango mobile's Takuya Fujimura ([@tlync](https://twitter.com/tlync)) gave talk on 'Japan's national sport and Scala'. Apparently Dwango (Japanese equivalent of YouTube) has a long relationship with Sumo association in Japan, and they were commissioned to build the official mobile application. One of the interesting thing was that they chose to adhere to strict Domain Driven Design, and kept many of the sumo terminology like *banzuke* in the model layer instead of trying to translate them into English.

Marverick's [@todesking](https://twitter.com/todesking) gave talk on '(When I moved) From Ruby to Scala'. He enumerated Ruby's syntax along side that of Scala's. I think the whole point was that both languages came from different routes, but share the idea of respecting the fun in coding and achieving expressiveness by blending fp with OO.

At the end of day 1, there was a surprise dimming-the-light, everyone-singing, cake ceremony for Martin since his birthday was just the day before.

<blockquote class="twitter-tweet" lang="ja"><p>In some part of the world it is still <a href="https://twitter.com/odersky">@odersky</a>&#39;s birthday, so he gets a cake! <a href="https://twitter.com/hashtag/ScalaMatsuri?src=hash">#ScalaMatsuri</a> 

<img src="https://pbs.twimg.com/media/Bw2MFy0CIAAcfkK.jpg">

<!-- a href="http://t.co/cLal8xODiG">pic.twitter.com/cLal8xODiG</a -->

</p>&mdash; Jon Pretty (@propensive) <a href="https://twitter.com/propensive/status/508216380785557504">2014, September 6th</a></blockquote>
<script async src="//platform.twitter.com/widgets.js" charset="utf-8"></script>

It's doubley funny as @propensive supposedly invented the term *Cake pattern*. Afterwards we all had good time enjoying catered beer, appetizers, sushi, and pizza.

Day2 was the first ever Scala unconference in Japan (I strongly pushed for it!), which was just as fun, or even more festival-like than day1. Proud to be a member of ScalaMatsuri organizer. Big props to all the sponsors too! Where do you think all the $$ came from to fly guests in and serve sushi at a conference?! Check out their [jobs page](http://scalamatsuri.org/ja/jobs/index.html) if you want to code Scala in Tokyo.
