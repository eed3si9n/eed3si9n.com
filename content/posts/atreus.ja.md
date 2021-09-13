---
title:       "Atreus"
type:        story
date:        2017-06-19
changed:     2021-09-13
draft:       false
promote:     true
sticky:      false
url:         /ja/atreus
aliases:     [ /node/226 ]
tags:        [ "diy" ]
---

  [quiet]: http://matias.ca/switches/quiet/
  [linear]: http://matias.ca/switches/linear/
  [apple]: https://deskthority.net/wiki/Apple_Standard_Keyboard
  [atreus]: https://atreus.technomancy.us/

しばらく前にキットで買った [Atreus][atreus] を昨日の夜作り終えた。詳細はこんな感じ:

- [Matias Quiet Click][quiet] スイッチのオプションを選んだ（スライダーはグレー）。クリックという名前は付いているがクリック感は無いことに注意。
- 修飾キーには [Matias Quiet Linear][linear] スイッチを使用（スライダーは赤）。
- いわゆる ortholinear 系の格子状の、スプリットレイアウトで、42 のキーがある。
- マホガニー材の合板。

### 材料

キットには Arteus キーボードを組み立てるのに必要なものはほぼそろっている。自分で用意する必要があるのはラッカー、半田ごて、ハンダ、とニッパーだ。

- Minwax Clear Aerosol Lacquer, Clear Gloss
- Hakko Digital FX888D & CHP170 bundle, includes Soldering Station & CHP170 cutter
- Hakko T18-C2 - T18 Series Soldering Tip for Hakko FX-888/FX-8801
- DMiotech 0.8mm 50G 63/37 Rosin Core Tin Lead Soldering Solder Wire

ここで注意してほしいのは Matias社のスイッチは、80年代とか 90年代に [Apple Standard Keyboard][apple] などで採用された日本のアルプス電気の Alps SKCM のクローンであることだ。そのため、Cherry MX スイッチ用のおしゃれなキーキャップは一切使うことができない。それがやりたい人は Cherry 互換のパーシャルキットを注文する必要がある。

### 組み立て

キットに詳しい説明書が付いてくるのでここであえて言う必要のあることはあんまりない。
最初のステップは木製のケースをやすりがけして保護のためにニスをかけることだ。ラッカーの場合 8 から 10 回重ね塗りすることが推奨されているので、予想外に時間のかかるプロセスとなる。きっちり 30 分おきにスプレーをかけたとしても結構な時間がかかる。しかも、しっかり乾くまで 24時間使うことができないはずだ。どうせならウレタンを使っちゃったほうが強度も強いし重ね塗りする回数も少なくていいのでいいんじゃないかと思っている。

![image1](/images/atreus_1_1024.jpeg)

並行してダイオードのはんだ付けを始めることができる。

![image2](/images/atreus_2_1024.jpeg)

次にコントローラーとスイッチをはんだ付けする。
スイッチはダイオードよりも大きいパーツなのでちゃんと温まってしっかりはんだ付けされるように調整する必要があるが、白光の温度調節機能付きの半田ごてを使えばあんまり難しくなくできる。

### ファームウェア

Mac でのファームウェア書き込みの様子はこんな感じになる:

```bash
$ brew tap osx-cross/avr
$ brew install avrdude
# disconnect
$ ls /dev > dev-off.txt
# connect
$ ls /dev > dev-on.txt
$ diff dev-off.txt dev-on.txt
268a269
> cu.usbmodem22
432a434
> tty.usbmodem22
$ avrdude -p atmega32u4 -c avr109 -U flash:w:atreus-qwerty.hex -P /dev/tty.usbmodem22

Connecting to programmer: .
Found programmer: Id = "CATERIN"; type = S
    Software Version = 1.0; No Hardware Version given.
Programmer supports auto addr increment.
Programmer supports buffered memory access with buffersize=128 bytes.

....

avrdude done.  Thank you.
```

ファームウェアそのものは普通の qwerty だけど macos 側で super と option/alt を入れ替えている。

### キーボードの印象

![image3](/images/atreus_3_1024.jpeg)

僕が普段使っているキーボードは Microsoft Natural Ergonomic Keyboard 4000 だけど、ここ一年ぐらいキッチンとか色んな所でコードを書いていて MacBook Pro のキーボードもよく使うようになった。これによってヘナヘナな MacBook Pro に劣化が出てきて、例えばターミナルをスライドアウトさせるのに割り当てたキーが打鍵をミスするようになった。
なので小型なスプリット式のキーボードは良いアイディアかのように思えた。

Matias Quiet Click は、音こそは静かだが、打鍵したときの確かなバンプがあって、比較的高めな 60±5g 荷重でアクチュエートされる。スペック的には MX clear が比較対象となると思うので是非比べてみたい。打鍵感と静音という意味ではこのスイッチは今のところ気に入っている。

最終的な結論はまだ控えるが、Atreus のレイアウトは練習を要するということは言える。ラップトップのキーボードと比較してもかなり少ないキーの数なので、スペース（バーではない）、シフト、エンター、バックスペースといったキーが通常サイズのキーとして最下列に詰め込まれている。さらに格子状のレイアウトなため、今まで培ってきたどこにキーがあるのかという反射神経を再開発する必要がある。特に 'c' を打つのに苦労している。

さらにたとえレイアウトを克服して様々なシンボルの場所を暗記しても残っている問題が一つあって、それは置き場所だ。ラップトップと自分の間に置くと画面が遠すぎる気がする。

Atreus を組み立てるのは楽しい作業だった。だけど、ナチュラルに感じれるようになるにはもう少し練習が必要だ。
(これを書くのにも結構時間がかかった)
