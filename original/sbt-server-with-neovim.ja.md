sbt server 統合シリーズ・パート3 は Neovim だ。これまでに [VS Code](http://eed3si9n.com/ja/sbt-1-1-0-RC1-sbt-server) と[Sublime Text 3](http://eed3si9n.com/ja/sbt-server-with-sublime-text3) をカバーした。

### sbt server のための Neovim のセットアップ方法

まず Python 3 と Node をマシンにインストールする。次に、Neovim クライアントライブラリを更新する。

<code>
$ sudo pip3 install --upgrade neovim
</code>

次に、[eed3si9n/LanguageClient-neovim](https://github.com/eed3si9n/LanguageClient-neovim) プラグインを Neovim (もしくは Vim) に追加する。これは、[autozimu/LanguageClient-neovim](https://github.com/autozimu/LanguageClient-neovim) レポジトリのフォークで、最新の "next" ブランチでうまく動作しなかったので、古い Python ベースの "master" ブランチを使うようにするためだ。

Dein を使った場合こんな感じになる:

<code>
[[plugins]]
repo = 'eed3si9n/LanguageClient-neovim'
</code>

Neovim を再起動して `:UpdateRemotePlugins` する。うまくいけば以下が表示される:

<code>
remote/host: python3 host registered plugins ['LanguageClient']
remote/host: generated rplugin manifest: /Users/someone/.local/share/nvim/rplugin.vim
Press ENTER or type command to continue
</code>


次に [sbt-server-stdio.js](https://gist.githubusercontent.com/eed3si9n/0ee26a15218f1d4031b451dd61315d6c/raw/5693fbcafbb9a71f1ac5a9d13ace94df3b091cbc/sbt-server-stdio.js) をダウンロードして `~/bin/` もしくは普段スクリプトを保存している場所に保存する。sbt server は、POSIX システムではデフォルトで Unix ドメインソケット、Windows では名前付きパイプを用いるが、エディタは基本的に標準出入力を期待しているみたいだ。これは VS Code エクステンション用に僕が書いた実行中のソケットを発見して、標準出入力でフロントを作る Node スクリプトだ。

これで Language Server クライアントの設定ができるようになった。適当な設定スクリプトに以下の内容を追加する:

<code>
set signcolumn=yes

let g:LanguageClient_autoStart = 1

let g:LanguageClient_serverCommands = {
    \ 'scala': ['node', expand('~/bin/sbt-server-stdio.js')]
    \ }

nnoremap <silent> gd :call LanguageClient_textDocument_definition()<CR>
</code>

### 用法

適当なプロジェクトを sbt 1.1.0-RC2 を使って実行する。(RC-1 ではなく RC-2 であることに注意)

sbt sever が立ち上がったら、そのディレクトリを Neovim を使って開く。

VS Code エクステンション同様にこの統合によって以下のことが行える。

- `*.scala` ファイルの保存時にルートプロジェクトで `compile` を実行する。
- コンパイラエラーを表示する。
- `:messages` でログを表示する。
- クラス定義にジャンプする。

![vim-scala-sbt](/images/vim-scala-sbt.gif)
