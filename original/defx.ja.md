  [defx]: https://github.com/Shougo/defx.nvim
  [help]: https://github.com/Shougo/defx.nvim/blob/master/doc/defx.txt
  [vinegar]: https://github.com/tpope/vim-vinegar
  [@Shougo]: https://github.com/Shougo
  [command-t]: https://github.com/wincent/command-t
  [denite]: https://github.com/Shougo/denite.nvim
  [fzf]: https://github.com/junegunn/fzf

ファジー検索 ([fzf][fzf], [Command-T][command-t], [Denite][denite] etc) とファイル・エクスプローラーのコンボは最強だ。Sublime Text や VS Code を開いてもこの 2つが出てきて、それでだいたい事足りる。

本稿は Neovim を頑張って設定して、ツリーヴューのファイル・エクスプローラーを作ってみようという試みだ。1つの動機としては Onivim のアルファ版を使ってみて、機能的なファイル・エクスプローラーが無いというのが辛かったというのがある。普段 Sublime や VS Code を使ってる人視点なのでそれは悪しからず。

### Defx

[Defx][defx] は [@Shougo][@Shougo]さんにより書かれた Neovim のためのファイル・エクスプローラー・プラグインだ。氏は「dark powered」(暗黒の力を使った) プラグインと呼んでいる。これは氏が Python 3 を使って書いたからなのかもしれない。悪とどのような契約をしたのかは分からないが、NERDTree よりは高速であることは間違いない。

Defx の面白い所はデフォルトのキーバインドが無いことだ。そのため、ユーザーはプラグインの自分に合ったようにカスタマイズすることが推奨されているんだと解釈する。[help][help] にあるサンプルのバインディングは Netrw 風だと思う。ここでは、Sublime 風にする。

#### スクリーン・キャプチャ

僕の考えた Defx 設定のデモ:

<img border="0" alt="" src="https://github.com/eed3si9n/eed3si9n.com/raw/master/resources/defx.gif" width="900" />

### 基本的なナビゲーションとプレビュー

`<Space>-e` で左分割ウィンドウに Defx が出るようにした。`q` で閉じる。

`j` と `k` は当然カーソルを上下に移動させる。`<CR>` を以下のようにバインドした:

<code>
  nnoremap <silent><buffer><expr> <CR>
  \ defx#is_directory() ?
  \ defx#do_action('open_tree', 'recursive:10') :
  \ defx#do_action('preview')
</code>

もしもノードがディレクトリならば、ツリーを再帰的に展開させて、もしもファイルならばプレビューとして開く。これは、Sublime でのクリックをエミュレートする。これで 3つのキーを使うだけで上下にナビゲートできる。

ツリーの展開後に特定のファイルにジャンプしたければ、`/` を使ってバッファー内の検索を行う。

再帰的に開いたツリーを、閉じるために `b` はツリーを 10回閉じるという力技を使っている:

<code>
  nnoremap <silent><buffer><expr> b
  \ defx#do_action('multi', ['close_tree', 'close_tree', 'close_tree', 'close_tree', 'close_tree', 'close_tree', 'close_tree', 'close_tree', 'close_tree', 'close_tree'])
</code>

ファイルを開くには `o` を使う。実際には drop というアクションを使って、既にファイルが開いていればそのバッファーにフォーカスを移すようになっている。

### ファイルの操作

ファイル操作はエクスプローラーの光る所だ。

- `N` は新規ファイルの作成。
- `K` は新規サブディレクトリの作成。
- `r` はファイルのリネーム。
- `d` はファイルの削除。

これらの操作は現在フォーカスのあるディレクトリ内にて行われる。

### ディレクトリの変更

Netrw のように、特定のサブディレクトリにフォーカスを狭めるのが便利なこともある。


`l` はカレントディレクトリのビューをフォーカスしているものへ変更し、`h` で親に戻る。

<code>
  nnoremap <silent><buffer><expr> l
  \ defx#is_directory() ? defx#do_action('open') : 0
  nnoremap <silent><buffer><expr> h
  \ defx#do_action('cd', ['..'])
</code>

### ボーナス: Vineger モード

ボーナスとして、[Vinegar](https://github.com/tpope/vim-vinegar) もエミュレートしてみよう。Sublime のファイル・エクスプローラーと違って、Vinegar のアプローチはカレント・ファイルの親ディレクトリをカレント・ウィンドウにリストさせるというものだ。

`-` はこのようにマップした:

<code>
nnoremap <silent> - :<C-U>:Defx `expand('%:p:h')` -search=`expand('%:p')` -buffer-name=defx<CR>
</code>

例えば、カレントバッファーが `internal/compiler-interface/src/main/java/sxbti/VirtualFile.java` ならば、`-` は Defx を `internal/compiler-interface/src/main/java/sxbti/` で開く。

ここで `o` がファイルを別のウィンドウに drop されると困る。以下のようにバッファー名によって振る舞いを切り替えてみた:

<code>
  nnoremap <silent><buffer><expr> o
  \ match(bufname('%'), 'explorer') >= 0 ?
  \ (defx#is_directory() ? 0 : defx#do_action('drop', 'vsplit')) :
  \ (defx#is_directory() ? 0 : defx#do_action('multi', ['open', 'quit']))
</code>

`l`/`h` で 1レベル上に上がったりなど他のキーバインドはそのままだ。

### 設定

[defx.nvimで高速でリッチなファイラを実現する(アイコン、git status表示)](https://qiita.com/arks22/items/9688ec7f4cb43444e9d9) 参照。

#### Nerd font

<code>
brew tap homebrew/cask-fonts
brew cask install font-hack-nerd-font
</code>

ターミナルの Non-ASCII フォントを Hack Nerd Font Mono に変更する。

#### plugins.toml

<code>
[[plugins]]
repo = 'ryanoasis/vim-devicons'

[[plugins]]
repo = 'kristijanhusak/defx-icons'

[[plugins]]
repo = 'kristijanhusak/defx-git'
</code>

#### plugins_lazy.toml

<code>
[[plugins]]
repo = 'Shougo/defx.nvim'

hook_add = '''
nnoremap <silent> <Leader>e :<C-U>:Defx -resume -buffer_name=explorer -split=vertical -vertical_preview<CR>

nnoremap <silent> - :<C-U>:Defx `expand('%:p:h')` -search=`expand('%:p')` -buffer-name=defx<CR>

autocmd FileType defx call s:defx_my_settings()
function! s:defx_my_settings() abort
  " Define mappings
  nnoremap <silent><buffer><expr> <CR>
  \ defx#is_directory() ?
  \ defx#do_action('open_tree', 'recursive:10') :
  \ defx#do_action('preview')
  nnoremap <silent><buffer><expr> b
  \ defx#do_action('multi', ['close_tree', 'close_tree', 'close_tree', 'close_tree', 'close_tree', 'close_tree', 'close_tree', 'close_tree', 'close_tree', 'close_tree'])
  nnoremap <silent><buffer><expr> o
  \ match(bufname('%'), 'explorer') >= 0 ?
  \ (defx#is_directory() ? 0 : defx#do_action('drop', 'vsplit')) :
  \ (defx#is_directory() ? 0 : defx#do_action('multi', ['open', 'quit']))
  nnoremap <silent><buffer><expr> l
  \ defx#is_directory() ? defx#do_action('open') : 0
  nnoremap <silent><buffer><expr> h
  \ defx#do_action('cd', ['..'])
  nnoremap <silent><buffer><expr> K
  \ defx#do_action('new_directory')
  nnoremap <silent><buffer><expr> N
  \ defx#do_action('new_file')
  nnoremap <silent><buffer><expr> d
  \ defx#do_action('remove')
  nnoremap <silent><buffer><expr> r
  \ defx#do_action('rename')
  nnoremap <silent><buffer><expr> q
  \ defx#do_action('quit')
endfunction
'''

hook_post_source = '''
call defx#custom#option('_', {
\ 'winwidth': 50,
\ 'ignored_files': '.*,target*',
\ 'direction': 'topleft',
\ 'toggle': 1,
\ 'columns': 'indent:git:icons:filename:mark',
\ })
'''
</code>

