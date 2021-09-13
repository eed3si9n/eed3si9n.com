---
title:       "Zinc 1.4.0-M1"
type:        story
date:        2020-04-14
draft:       false
promote:     true
sticky:      false
url:         /ja/zinc-1.4.0-m1
aliases:     [ /node/328 ]
tags:        [ "sbt", "scala" ]
---

  [@eed3si9n]: https://github.com/eed3si9n
  [@slandelle]: https://github.com/slandelle
  [zinc754]: https://github.com/sbt/zinc/pull/754
  [zinc714]: https://github.com/sbt/zinc/pull/714
  [zinc713]: https://github.com/sbt/zinc/pull/713

Zinc 1.4.0-M1 をリリースした。これはベータ版であって将来の 1.4.x との互換性は保証されないことに注意してほしい。ただ、1.3.x と比較的近いコミットを選んだので実用性は高いはずだ。

- Zinc を Scala 2.12 と 2.13 へとクロスビルドした [zinc#754][zinc754] by [@eed3si9n][@eed3si9n]
- ScalaPB を 0.9.3 へとアップグレードした  [zinc#713][zinc713] by [@slandelle][@slandelle]
- ZipUtils 内での `java.util.Date` の使用を `java.time` 系へと置き換えた [zinc#714][zinc714] by [@slandelle][@slandelle]

Zinc は Scala のための差分コンパイラだ。Zinc は Scala 2.10 ~ 2.13 と Dotty をコンパイルすることが可能だが、これまでの所 Zinc そのものは Scala 2.12 で実装されてきた。これは Scala 2.12 で実装されている sbt 1.x としては問題無いが、Zinc を 2.13 でもクロスビルドして欲しいという要望は前からあった。

どうやら Gatling は Zinc をライブラリとして使っているらしく、Gatling のコア開発者の Stephane Landelle さんはアップデートに必要なパッチを送ってくれた。最後に僕がする必要があった作業は入り組んだサブプロジェクトを解きほぐして再配線することだが、それには僕が[昨日書いた](http://eed3si9n.com/ja/parallel-cross-building-part3) sbt-projectmatrix を使った。

[Li Haoyi](https://github.com/sbt/zinc/issues/697#issuecomment-612563161) さんも Mill を Scala 2.13 で書くのにこれを待っているらしい。お楽しみ下さい :)
