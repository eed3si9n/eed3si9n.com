  [@eed3si9n]: https://github.com/eed3si9n
  [@slandelle]: https://github.com/slandelle
  [zinc754]: https://github.com/sbt/zinc/pull/754
  [zinc714]: https://github.com/sbt/zinc/pull/714
  [zinc713]: https://github.com/sbt/zinc/pull/713

I've just released Zinc 1.4.0-M1. Note this is a beta release and it won't be compatible with future 1.4.x, but I chose a commit fairly close to 1.3.x so it should be usable.

- Cross builds Zinc to Scala 2.12 and 2.13 [zinc#754][zinc754] by [@eed3si9n][@eed3si9n]
- Upgrades ScalaPB to 0.9.3  [zinc#713][zinc713] by [@slandelle][@slandelle]
- Replaces ZipUtils usage of deprecated `java.util.Date` with `java.time` [zinc#714][zinc714] by [@slandelle][@slandelle]

Zinc is an incremental compiler for Scala. Though Zinc is capable of compiling Scala 2.10 ~ 2.13 and Dotty, thus far Zinc itself has been implemented using Scala 2.12. This is fine for sbt 1.x, which is also implemented in Scala 2.12, but there's been requests to cross build Zinc for 2.13.

Apparently Gatling uses Zinc as a library, so its core developer Stephane Landelle has contributed some patches towards the update. The last bit I had to work on was untangling and rewiring the web of subprojects, which I'm using sbt-projectmatrix as [I wrote about it](http://eed3si9n.com/parallel-cross-building-part3) yesterday.

[Li Haoyi](https://github.com/sbt/zinc/issues/697#issuecomment-612563161) says he's also waiting for this so he can use Scala 2.13 for Mill. Have fun :)
