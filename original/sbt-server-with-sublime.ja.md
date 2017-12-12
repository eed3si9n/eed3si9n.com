[Tech Hub blog](http://eed3si9n.com/ja/sbt-1-1-0-RC1-sbt-server) にて sbt server を VS Code と併用して実行中の sbt セッションからコンパイラエラーを表示できることをデモした。本稿では Sublime Text 3 でそれをやってみる。

### sbt server のための Sublime Text 3 のセットアップ方法

まずは Sublime Text 3 に [tomv564/LSP](https://github.com/tomv564/LSP) プラグインを追加する。

1. `cd ~/Library/Application\ Support/Sublime\ Text\ 3/Packages`
2. `git clone https://github.com/tomv564/LSP.git`
3. 'Preferences > Package Control > Satisfy Dependencies' を実行する

次に [sbt-server-stdio.js](https://gist.githubusercontent.com/eed3si9n/0ee26a15218f1d4031b451dd61315d6c/raw/5693fbcafbb9a71f1ac5a9d13ace94df3b091cbc/sbt-server-stdio.js) をダウンロードして `~/bin/` もしくは普段スクリプトを保存している場所に保存する。sbt server は、POSIX システムではデフォルトで Unix ドメインソケット、Windows では名前付きパイプを用いるが、エディタは基本的に標準出入力を期待しているみたいだ。これは VS Code エクステンション用に僕が書いた実行中のソケットを発見して、標準出入力でフロントを作る Node スクリプトだ。

これで Language Server クライアントの設定ができるようになった。 'Preferences > Package Settings > LSP > Settings' を開く。

<code>
{
  "clients":
  {
    "sbt":
    {
      "command": ["node", "/Users/someone/bin/sbt-server-stdio.js"],
      "scopes": ["source.scala"],
      "syntaxes": ["Packages/Scala/Scala.sublime-syntax"],
      "languageId": "scala"
    }
  }
}
</code>

**注意**: `/Users/someone/bin/` を自分のものと置き換える。

### 用法

適当なプロジェクトを sbt 1.1.0-RC1 を `-no-colors` オプションを使って実行する。

<code>
$ sbt -no-colors
</code>

sbt sever が立ち上がったら、そのディレクトリを Sublime を使って開く。

VS Code エクステンション同様にこの統合によって以下のことが行える。

- `*.scala` ファイルの保存時にルートプロジェクトで `compile` を実行する。
- コンパイラエラーを表示する。
- <code>Ctrl-`</code> でログを表示する。
- クラス定義にジャンプする。

![sublime-sbt-scala](/images/sublime-sbt-scala.gif)
