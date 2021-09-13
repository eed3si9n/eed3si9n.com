---
title:       "Pamflet 0.8.0"
type:        story
date:        2019-01-03
draft:       false
promote:     true
sticky:      false
url:         /ja/pamflet-080
aliases:     [ /node/289 ]
---

  [1]: http://www.foundweekends.org/pamflet/ja/
  [2]: http://www.foundweekends.org/pamflet/Combined+Pages.md
  [sbt]: https://www.scala-sbt.org/1.x/docs/
  [Gigahorse]: http://eed3si9n.com/gigahorse/
  [contraband]: https://www.scala-sbt.org/contraband/
  [tetrix]: http://eed3si9n.com/tetrix-in-scala/
  [herding]: http://eed3si9n.com/herding-cats/
  [recipes]: http://eed3si9n.com/recipes/

年末の連休中に Pamflet の left TOC (目次) を実装して、[Pamflet 0.8.0][1] としてリリースした。

<img src='/images/pamflet-toc.png' style='width: 100%;'>

Pamflet は短い文書、特にオープンソース・ソフトウェアの ユーザ・ドキュメントを公開するためのアプリだ。

<!--more-->

僕が [sbt][sbt] ドキュメント、[Gigahorse][Gigahorse] ドキュメント、 [contraband][contraband] ドキュメント、 [tetrix in Scala][tetrix]、[猫番][herding]を書くのに使っている。ベジタリアンの[レシピ][recipes]もまとめたりしてる。

しばらく前にグローバリゼーション機能をつけたのでこれらのドキュメントは英語と日本語の両方で書くことができ、ページごとに相互リンクされている。

もう一つ便利な機能として[単一の markdown ファイル][2]を生成するので、それを pandoc に渡して PDF ファイルを作ることもできる。

Pamflet は長い間、各ページの下に目次を表示していたが、Pamflet 0.8.0 より左側に表示させることにした。設定で以前のように `bottom` に戻すことも可能だ。

ページをめくるための左右の巨大なマージンも取り除いた。
