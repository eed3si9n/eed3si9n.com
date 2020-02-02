### giter8.version

Giter8 0.12.0 に giter8-launcher という小さなアプリを追加した。このアプリの目的は Giter8 テンプレートの振る舞いを予測可能にすることにある。現状だと、テンプレート作者が Giter8 バージョン X を想定してテンプレートを作ったとしてもユーザー側は "sbt new" に同梱される別な Giter8 バージョン Y を使って実行されている。

sbt の良いアイディアの一つにユーザーがどのバージョンの `sbt` スクリプトをインストールしていてもコアの sbt バージョンはビルド作者が `project/build.properties` ファイルを使って指定できるというものがある。これによって「自分のマシンでしか動作しない」問題が大幅に改善される。giter8-launcher は sbt における sbt-launcher に同様のものだ。giter8-launcher はテンプレートのクローンして、`project/build.properties` ファイルを読み込んで、テンプレートのレンダリングに用いる実際の Giter8 バージョンを決定する。

テンプレート作者は `project/build.properties` ファイルを用いて以下のように Giter8 バージョンを指定できる:

```
giter8.version=0.12.0
```

"sbt new" がこの仕組みを使うようになれば、sbt のリリースのタイミングと Giter8 バージョンを分離することができる。

夏ぐらいから、たまに作業して [#444][444] として実装した。元のアイディアは 2017年に Merlijn Boogerd ([@mboogerd][@mboogerd]) さんによって [#303][303] として提案され、別の人が [#344][344] として実装して一旦 merge されたが、うまく動作しなかったので差し戻されたという経緯がある。3度目なのでうまくいくことを願っている。

#### Coursier bootstrap

giter8-launcher のための bootstrap スクリプトを Coursier を用いて生成して、Maven Central に <http://repo1.maven.org/maven2/org/foundweekends/giter8/giter8-bootstrap_2.12/0.12.0/giter8-bootstrap_2.12-0.12.0.sh> として公開した。これはローカルで `~/bin/g8` として保存して使うことができる。

### 韓国語のドキュメンテーション

今年 (2019) の春ぐらいに Hamel Yeongho Moon ([@hamelmoon][@hamelmoon]) さんが [#417][417] としてドキュメンテーションを[韓国語](http://www.foundweekends.org/giter8/ko/)に翻訳してくれ、[@yoohaemin][@yoohaemin] さんがレビューを行ってくれた。ありがとうございます。

### その他の更新

- `--out` オプションをヘルプに追加した [#391][391] by [@anilkumarmyla][@anilkumarmyla]
- Scalasti へのライブラリ依存を StringTemplate に置き換えた [#392][392] by [@xuwei-k][@xuwei-k]
- Maven Central API を使うように切り替えた [#395][395] by [@kounoike][@kounoike]
- 条件的ファイルの作成の修正 [#432][432] by [@ihostage][@ihostage]
- Giter8 からの scripted test 処理の修正 [#408][408] by [@renatocaval][@renatocaval]
- Apache HTTP client から `URL#openConnection` を使うように切り替えた [#441][441]
- あとは吉田さんによるビルドのメンテがかなり大量にある

コントリビューターの皆さんありがとうございます。

```
$ git shortlog -sn --no-merges v0.11.0...v0.12.0
    50  kenji yoshida (xuwei-k)
    11  Eugene Yokota (eed3si9n)
     3  Yeongho Moon
     2  Dale Wijnand
     2  Renato Cavalcanti
     1  Yuusuke Kounoike
     1  Jentsch
     1  Anil Kumar Myla
     1  Sergey Morgunov
```

  [@anilkumarmyla]: https://github.com/anilkumarmyla
  [@xuwei-k]: https://github.com/xuwei-k
  [@kounoike]: https://github.com/kounoike
  [@hamelmoon]: https://github.com/hamelmoon
  [@yoohaemin]: https://github.com/yoohaemin
  [@ihostage]: https://github.com/ihostage
  [@renatocaval]: https://github.com/renatocaval
  [@eed3si9n]: https://github.com/eed3si9n
  [@mboogerd]: https://github.com/mboogerd
  [303]: https://github.com/foundweekends/giter8/pull/303
  [391]: https://github.com/foundweekends/giter8/pull/391
  [392]: https://github.com/foundweekends/giter8/pull/392
  [395]: https://github.com/foundweekends/giter8/pull/395
  [408]: https://github.com/foundweekends/giter8/pull/408
  [417]: https://github.com/foundweekends/giter8/pull/417
  [432]: https://github.com/foundweekends/giter8/pull/432
  [441]: https://github.com/foundweekends/giter8/pull/441
  [444]: https://github.com/foundweekends/giter8/pull/444
  [344]: https://github.com/foundweekends/giter8/pull/344
