  [foundweekends]: https://github.com/foundweekends
  [1]: https://twitter.com/eed3si9n_ja/status/718908096119193600
  [2]: https://gitter.im/foundweekends/foundweekends
  [3]: https://github.com/foundweekends/conscript
  [4]: https://github.com/foundweekends/giter8
  [5]: https://github.com/foundweekends/pamflet
  [n8han]: https://twitter.com/n8han
  [6]: http://notes.implicit.ly/post/142596511554/conscript-050
  [85]: https://github.com/foundweekends/conscript/pull/85
  [86]: https://github.com/foundweekends/conscript/pull/86
  [7]: http://www.meetup.com/Functional-Alcoholics/events/26013721/
  [8]: https://twitter.com/xuwei_k/status/709409362096173056

週末に趣味プログラミングをする人のための Github organization として [foundweekends][foundweekends] を作った。参加したい人は [twitter][1] か [Gitter][2] で声をかけてください。

当面の活動は [@n8han][n8han] から [conscript][3]、[giter8][4]、[pamflet][5] を引き継ぐことだ。

### conscript 0.5.0

既に新 organization での[初リリース][6]も今日出した。まずは pull request をいくつかマージした。次に、conscript が使っている Scala、Dispatch、scopt などのバージョンを上げた [#85][85]。conscript がどこに何をインストールするのかに関連する issue とか pull request がいくつかあったので、`CONSCRIPT_HOME` という考えを導入した。

conscript が色々ダウンロードする所を変えたければ、変えることができるようになった [#86][86]。

### cake shop の話

しばらく前に New York で毎週活動してる hacking group というか「もくもく会」みたいなのがあった。Cake Shop というボロボロっぽい、夜はロックのライブハウスみたくなってて、土曜の朝の 11:00 だとガラガラのカフェに別々のメンバーが集まってきてた。そのもくもく会は、[Found Weekends][7][^1]とよばれていた。Unfiltered などのプロジェクトはこのグループから始まった。

僕は数回しか顔を出したことがないけども、オープンソースの開発者と実際に会ったことは初めてに近かったと思う。Unfiltered への pull request に関連して呼び出しをくらって、ドキドキしながら行ったのを覚えている。行ってみると自分みたいなギークが普通にコード書いてるだけで、心配することはなかった。誰もあんまり知らなかった当時、開発に参加させてくれた @n8han とか @softprops は僕の師匠だと勝手に思っている。名前はそこからもらってきた。

### foundweekends

今回新たに foundweekends を作った直接の[動機][8]は確かに conscript その他のツールのメンテナンスを分散させるためだけども、僕はコミッタだったので何とかしなきゃとはしばらく思ってたし、誰もメンテしなくなったプロジェクトの管理だけやる会に制限したくないとも思っている。
(Gitter とかで) アイディアを出しあったり、週末だけちょっと時間があるときに参加できるプロジェクトを見つけるための場所になればいいかなと思っている。どうなるかは、今後次第だけど。

[^1]: やることが無くて呆然とする状態 (feel lost) と、英語で忘れ物取扱所のことを lost and found　ということから "found" を lost の対義語と見立てて、「(やることを) 見つけた週末」という意味で found weekends という言葉遊び。
