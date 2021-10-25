---
title:       "Ergodox"
type:        story
date:        2017-12-04
changed:     2017-12-05
draft:       false
promote:     true
sticky:      false
url:         /ja/ergodox
aliases:     [ /node/242 ]
tags:        [ "diy" ]
summary:
  <img src="/images/ergodox-2-1920.jpg">

---

週末にほったらかしていた Ergodox を組み立てた。

- Infinity ErgoDox Ergonomic Keyboard Kit via massdrop
- Cherry MX Brown スイッチ
- Datamancer Infinity Ergodox Hardwood Case (Black Walnut / Original) via massdrop
- Plum Blossom PBT Dye-Subbed Keycap Set (OEM, Blank) via [massdrop](https://www.massdrop.com/buy/37996)

### 待ち時間

上記のアイテムを共同購入する massdrop にジョインしたのが5月の末で、10月の末になるまで全品到着しなかったので、5ヶ月の待ち時間があった。発送の段階で左右の混乱があったらしいので今回は遅れが出たらしいが、将来のドロップは多少早くなるかもしれない。文字通り [EZ](https://ergodox-ez.com/pages/customize) という名前のよりイージーな方法もあって、それは 3週間で届くとうたっている。キーキャップその他を抜けば値段的にもそうそう変わらない。

### 他にいるもの

- 精密ドライバーセット。パーツをはめるのに使うので 500円ぐらいのやつでいい
- Hakko Digital FX888D & CHP170 bundle, includes Soldering Station & CHP170 cutter
- Hakko T18-C2 - T18 Series Soldering Tip for Hakko FX-888/FX-8801
- DMiotech 0.8mm 50G 63/37 Rosin Core Tin Lead Soldering Solder Wire

### 組み立て

Input Club の [build guide](https://input.club/devices/infinity-ergodox/infinity-ergodox-build-guide/) を読んだだけだと、正直言って分かりづらい組み立てだった。ただしラッカーをスプレーしたりダイオードのはんだ付けが無いので、全行程は一日の作業ですんだ。

組み立てで一番分かりづらいのは Costar スタビライザー (non-Filco style?) の付いた 4つのキーの取り付けだ。まずは、スタビライザーとは何なのかを YouTube とかで調べるといいと思う。

Costar スタビライザーは以下のパーツから構成される:
- ワイヤー x1
- プレートクリップ x2 (コの字にギザギザが色々ついたもの)
- キーキャップインサート x2 (小さめのパーツ)

試行錯誤の結果、僕がやったのは以下の方法だ。



1. プレートクリップを取り付ける。公式のガイドに従って、ワイヤの受け口は液晶画面とは逆の方向を向かせる。
2. 2u のキーキャップを選ぶ。キーキャップが sculpted タイプの場合どれをどこで使うのかを決める必要がある。
3. キーキャップインサートをキーキャップに付ける。長めの突起部はワイヤと逆向きになるようにする。
4. ワイヤをキーキャップインサートに引っかける。
5. 回路基板の穴と向きを合わせて、キースイッチをパチっとプレートにはめる。
6. キーキャップとワイヤを組み合わせたものをスイッチに押し込む。ここで、キーが自由に動くことを確かめる。動かなければクリップを押して広げる。グリスを塗ってる人も多いみたいだ。
7. ミニマイナスドライバーを使ってワイヤを受け口にパチっとはめる。

<a href='/images/ergodox-1-1024.jpg'><img src='/images/ergodox-1-1024.jpg' style='width: 120%;'></a>

### キーボードの印象

最初に感じたのは Cherry MX Brown (45 cN) が Matias の 65 gf に比べて軽めのアクチュエーションであることだ。打鍵したときのバンプもおとなしい。しかし、一番気になったのは打鍵のたびにボトムアウトして、それがうるさいことだ。僕は他のキーボードでも下まで打ち抜いているが、何らかの緩衝が行われている。ところが、これはキーキャップかスイッチが毎回カタカタ鳴っている。

<a href='/images/ergodox-2-1920.jpg'><img src='/images/ergodox-2-1920.jpg' style='width: 120%;'></a>

幸いこれは Oリングを付ければ直る問題らしいので、早くここは改造したい。

Artreus で、格子状のレイアウトは慣れたので qwerty の部分に慣れるのは時間がかからなかった。その他のキーに関しては Command キーをもっと打ちやすい所に移動するなどマッピングの改良が必要なのと、僕自身の練習が必要だ。全般的な印象としては、数字とか矢印キーがコード無しで出てくるのは便利。

サイズ的には Artreus よりもかなり大きい。トレイに乗せて MacBook Pro に乗せるとこも可能だが、その方法で使うかはまだ分からない。

<a href='/images/ergodox-3-1920.jpg'><img src='/images/ergodox-3-1920.jpg' style='width: 120%;'></a>

もう一つ気づいたのは傾きとリストレストが無いことだ。これは僕が木製のケースを選んだことにも起因する。Microsoft Natural Keyboard のファンとしては画面側への軽い傾斜が好みだ。大きめのリストレストと組み合わせることで手首の角度がフラットになる。これも何らかの方法で解決できるはずだ。今のところは靴下を丸めたものを使っている。

### ファームウェア

公式の方法でファームウェアを更新するには [configurator](https://input.club/configurator-ergodox/) に行ってキーの配置を変更する。CLR-KEY はクリアという意味だ。僕のはこんな感じだ。

<a href='/images/ergodox-keymap.png'><img src='/images/ergodox-keymap2.png' style='width: 100%;'></a>

次に、ファームウェアのバージョンを lts に変えてからファームウェアをダウンロードする。

```bash
$ brew install dfu-util
```

ファームウェアを書き換えるには、まず左キーボードのみを接続して、キーボードの底のフラッシュボタンを細いミニドライバーでつつく。液晶画面がオレンジに変わるはずだ。

```bash
$ dfu-util -l
Password:
dfu-util 0.9

Copyright 2005-2009 Weston Schmidt, Harald Welte and OpenMoko Inc.
Copyright 2010-2016 Tormod Volden and Stefan Schmidt
This program is Free Software and has ABSOLUTELY NO WARRANTY
Please report bugs to http://sourceforge.net/p/dfu-util/tickets/

Found DFU: [1c11:b007] ver=0000, devnum=6, cfg=1, intf=0, path="20-5", alt=0, name="Kiibohd DFU", serial="mk20dx256vlh7"
$ dfu-util -D left_kiibohd.dfu.bin
```

右側も同様に `right_kiibohd.dfu.bin` を使っておこなう。
