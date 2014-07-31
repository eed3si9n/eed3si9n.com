個人的には SublimeText で特に困っていないし、メインのエディタとしてしばらく使ってきた。だけど、コマンドラインから使えるエディタにも少しは興味があるし、色んな人がネットワーク上から使えるから便利ということを言っている。X を転送したり、他の方法でリモートインすれば Sublime を使えるんじゃないかとも思うが、一応試してみよう。

この Vim のセットアップをしようと思ったキッカケの一つに新しく MBP を買ったというのがあって、折角だから何か新しいことをやってみようかなと思った。つまり、本稿は完全な素人が個人的なメモとして書いてあるものだ。そもそもブログというのはそういうものなはずだ。動くかどうかは保証できない。全般的に yuroyoko さんが数年前に書いた [iTerm2 + zsh + tmux + vim で快適な256色ターミナル環境を構築する](http://yuroyoro.hatenablog.com/entry/20120211/1328930819)を参考にした。

## Vim 以外の色々なこと

### dotfiles

本稿で書いたセットアップは [eed3si9n/dotfiles](https://github.com/eed3si9n/dotfiles) に上げてある。他の人の dotfiles を fork するのが作法らしいけども、自分の環境に持ち込む設定をちゃんと理解したかったので、一から書き始めた。

dotfiles の基本的な考え方としては、これを `~/dotfiles/` にまず checkout して、そこには `zshrc` などのファイルが入ってる。これらのルートの設定ファイルはホームディレクトリ内で `~/.zshrc` などという感じでシンボリックリンクが張られる。

### Terminal.app

Mac で iTerm2 がどうしても必要になったことはまだない。以前には Terminal.app に色々と制限があったのかもしれないけど、今の所僕はこれで間に合っている。
Terminal.app を使い続けている理由のもう一つが、僕が [TotalTerminal](http://totalterminal.binaryage.com/) のファンであることだ。

### homebrew

[Homebrew](http://brew.sh/) にはお世話になっている。

### Zsh

このマシンのシェルは [Zsh](http://www.zsh.org/) にする。Mac なら [How to use Homebrew Zsh Instead of Max OS X Default](http://zanshin.net/2013/09/03/how-to-use-homebrew-zsh-instead-of-max-os-x-default/) を参照:

<code>
$ brew install zsh
$ chsh -s /usr/local/bin/zsh
</code>

設定に関しては、`zshrc` は他の `zshrc.*` の読み込みだけを行っている:

<code>
## basic
[ -f $HOME/dotfiles/zshrc.basic ] && source $HOME/dotfiles/zshrc.basic

## aliases
[ -f $HOME/dotfiles/zshrc.alias ] && source $HOME/dotfiles/zshrc.alias

case "${OSTYPE}" in
# MacOSX
darwin*)
  [ -f $HOME/dotfiles/zshrc.osx ] && source $HOME/dotfiles/zshrc.osx
  ;;
# Linux
linux*)
  [ -f $HOME/dotfiles/zshrc.linux ] && source $HOME/dotfiles/zshrc.linux
  ;;
esac

## color
[ -f $HOME/dotfiles/zshrc.color ] && source $HOME/dotfiles/zshrc.color
</code>

#### zshrc.basic

Zsh を使う理由の一つはより良いタブ補完だと思うので、それをまず有効化する。あと、落ち着かないのでプロンプトを Bash 風に変える。

<code>
## auto comp
autoload -U compinit
compinit

## prompts
PROMPT="[%m:%~]$ "

## vi bindings
bindkey -v

## history related
HISTFILE=$HOME/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt hist_ignore_dups
setopt share_history

autoload history-search-end
zle -N history-beginning-search-backward-end history-search-end
zle -N history-beginning-search-forward-end history-search-end
bindkey '^r' history-beginning-search-backward-end
bindkey '^f' history-beginning-search-forward-end
</code>

タブ補完における hello world ということで、`ls` のオプションを表示させてみる:

<code>
$ ls -[tab]
-1                  -- single column output
-A                  -- list all except . and ..
-C                  -- list entries in columns sorted vertically
-H                  -- follow symlinks on the command line
-L                  -- list referenced file for sym link
....
</code>

うまくいった。もう一つの役に立つ機能として履歴を複数のセッション間で共有して、検索できるということがある。例えば one-liner の `git` コマンドを書いたとして、他にも色々コマンドを書いた後で再びその `git` コマンドを走らせたいとする。

<code>
$ git[Ctrl-R]
</code>

Zsh は履歴の中で最後に使った `git` という文字列から始まるコマンドを探してきてそれを表示する。
Zsh で設定できることは他にも山ほどあって、もっと一般的な `ll` をエイリアスに登録といったことも当然できる。

次に行く前に言っておきたいのは、このコマンドラインの設定全般に言える話だけども、作業の多くがどのキーボード・バインディングを使うかを決めることだということだ。使いやすいキーボードのショートカットは基本的に数が限られているけども、割り当てたい機能は各方面から限りなく出てくるからだ。Zsh に関しては、`bindkey` コマンドを引数なしで実行することで現在割り当てられているキーが表示される:

<code>
$ bindkey 
"^A"-"^C" self-insert
"^D" list-choices
"^E"-"^F" self-insert
"^G" list-expand
"^H" vi-backward-delete-char
....
</code>

### tmux

[tmux](http://tmux.sourceforge.net/) はターミナルマルチプレクサだ。より詳しい説明は Zanshin.net の [My Tmux Configuration](http://zanshin.net/2013/09/05/my-tmux-configuration/)、thoughtbot.com の [A tmux Crash Course](http://robots.thoughtbot.com/a-tmux-crash-course) などを参照してほしい:

> それは単一のターミナルウィンドウに複数の仮想コンソールを持つことを可能とする。さらに、tmux セッションを終了すること無くにデタッチ、アタッチすることで、リモートのサーバやマシンで作業するときの柔軟性を持たせてくれる。多くの面において GNU Screen とそっくりだと言えるけども、BSD ライセンスの元で配布されている。

Mac なら Homebrew から手に入る:

<code>
$ brew install tmux
</code>

セッションを開始するにはシェル上から `tmux` を実行する:

<code>
$ tmux new -s <session-name>
</code>

僕は `Ctrl-T` というプレフィックスを tmux コマンドに割り当てた。tmux 用語では、ウィンドウというのはタブのようなもので、ペインはスプリット・スクリーンだ。

- `Ctrl-T c` 新しいウィンドウを作成
- `Ctrl-T q` 現在のペインを削除
- `Ctrl-T " "` 次のウィンドウへの移動
- `Ctrl-T s` 水平にウィンドウをスプリット
- `Ctrl-T v` 垂直にウィンドウをスプリット
- `Ctrl-T $` 現在のセッションをリネーム
- `Ctrl-T d` 現在のセッションをデタッチ
- `Ctrl-T (h|j|k|l)` 指した方向へのペインへの移動
- `Ctrl-T Ctrl-T` 次のペインへの移動
- `Ctrl-T (1..9)` ウィンドウへの移動

<code>
# map vi movement keys as pane movement keys
bind h select-pane -L
bind j select-pane -D
bind k select-pane -U
bind l select-pane -R
</code>

修飾キー付きの矢印キーも後で割り当てる。

#### Powerline

次に、ステータスラインをかっこ良くするために [Powerline](https://powerline.readthedocs.org/en/latest/) を入れる。
これは Python が必要になるので、それをまずインストール。

<code>
$ brew install python
</code>

これは Python 2.7.6 をインストールする。ドキュメンテーションは `--user` 付きで powerline をインストールと書いてあるけども、Mac でそれをやるとエラーになったので、`--user` 無しで入れた:

<code>
$ pip install git+git://github.com/Lokaltog/powerline 
Downloading/unpacking git+git://github.com/Lokaltog/powerline
....
</code>

このパッケージを参照するために、`SITE_PACKAGES` という環境変数を `zshrc.osx` で定義する:

<code>
export SITE_PACKAGES=/usr/local/lib/python2.7/site-packages/
</code>

これで以下のように `tmux.conf` に書ける:

<code>
source $SITE_PACKAGES/powerline/bindings/tmux/powerline.conf
</code>

![Powerline](/images/vim-memo-1a.png)

tmux セッションの面白い所はターミナルの接続が切れてもバックグラウンドで走り続けることだ。`Ctrl-T $` を使って現在のセッションを rename して、以下のようにして接続を切って、セッションをリストして、再接続する。

<code>
$ tmux detach
$ tmux ls
$ tmux a -t vim-memo
</code>

他に、tmux に関しては [tmux cheatsheet](https://gist.github.com/MohamedAlaa/2961058) が参考になる。

## Vim

[Vim](http://www.vim.org/) はテキストエディタだ。Mac では Vim も homebrew で入れることができる。プラグインのために、Lua サポートもつける。

<code>
$ brew install vim --with-lua
</code>

Vim まわりはかなりキーバインディングが多い。さらにプラグインを追加しているので、プラグインに割り当てたキーバインディングを覚えなきゃいけない。

### 素の Vim のこと

Vim の学習には色々リソースが整っている

- `vimtutor`
- [vim tutorial videos on derekwyatt.org](http://derekwyatt.org/vim/tutorials/)
- [Practical Vim](http://pragprog.com/book/dnvim/practical-vim)
- [vim quick reference card](http://tnerual.eriogerg.free.fr/vim.html)

Practical Vim はまだ数章しか読んでないけど、既に僕の Vim に関する考え方を変えた。他のエディタから来ると、Insert モードが主なモードで、残りは他の操作のためのモードだと思いがちだ。それは全く逆で、Vim の自然体は Normal モードだ。Drew Neil が使った喩えは、画家はキャンバスにブラシを構えた状態で休まないというものだ。これは、コードを探索したり、コードについて考えるといった行為にもあてはまる喩えだと思う。

Normal モードが自然体であることは検索や移動といった操作にキーボードに対する均等の機会を与えてくれる。それは、またテキストをある単位で挿入するという行為を明示的に考えさせてくれる。Vim の流儀では、バッファに何かを打ち込むということは、まず Insert モードに入って、何かを書いて、Normal モードに帰ってくるという一連の動作になる。このミニ・プログラムは自動的に Vim に保存されて、"`.`" によって呼び出すことができる。同様にして、現在行内での検索は "`;`" で繰り返すことができる。

<scala>
val foo = "method("+arg1+","+arg2+")"
</scala>

上のようなコードがあるとき、Tip3 の説明によると、`f+` と打ち込んで "`+`" を検索して、`s + Esc` で "` + `" と上書きして、`;.` と三回打ち込むことで繰り返すことができる。

### ウィンドウ間の移動

Vim にある全ての機能を列挙するわけにはいかないけども、知っていて役に立つのは `:help` コマンドだ。これに `:help window` というように引数を渡すことで、例えば window 関連に関することがだいたい分かるようになる。プラグインを色々入れたいのと、あとプログラミングという性質上、分割ウィンドウをよく使うけども、今まで使ったことのないものだった。tmux 同様、プリフィックスを押してからサブコマンドを打ち込む:

- `Ctrl-W s` 現在のウィンドウを水平分割する
- `Ctrl-W v` 現在のウィンドウを垂直分割する 
- `Ctrl-W q` (または `:q`) 現在のウィンドウを閉じる
- `Ctrl-W (h|j|k|l)` 指した方向のウィンドウへフォーカスを変更する
- `Ctrl-W (arrow)` 指した方向のウィンドウへフォーカスを変更する

### vimrc

zshrc 同様に、vimrc は複数のスクリプトに分けて管理しやすいようにする。

<code>
" basics
source $HOME/dotfiles/vimrc.basic

" extra
source $HOME/dotfiles/vimrc.extra

" indentation
source $HOME/dotfiles/vimrc.indent

" moving
source $HOME/dotfiles/vimrc.moving

" searching
source $HOME/dotfiles/vimrc.search

" status line
source $HOME/dotfiles/vimrc.statusline

" neobundle
source $HOME/dotfiles/vimrc.bundle

" plugin settings
source $HOME/dotfiles/vimrc.plugins

" unite
source $HOME/dotfiles/vimrc.unite

" colors
source $HOME/dotfiles/vimrc.colors
</code>

現在割り当てられているキーバインディングを探すには、以下の ex コマンドを使う:

<code>
:map
:nmap
:imap
:vmap
</code>

### Shougo/neobundle.vim

[NeoBundle](https://github.com/Shougo/neobundle.vim) は Vim プラグインマネージャだ。Github プロジェクトの名前を書くだけで、残りは全部やってくれる。これは Shougo 氏 (またの名を暗黒美夢王) が書いた多くの Vim プラグインの一つだ。

### Shougo/unite.vim

[unite.vim](https://github.com/Shougo/unite.vim) プラグインは任意のソースからの情報を表示できる。以下は unite.vim を解説したブログ記事のいくつかだ:

- [Unite.vim, the Plugin You Didn't Know You Need](http://bling.github.io/blog/2013/06/02/unite-dot-vim-the-plugin-you-didnt-know-you-need/)
- [Replacing All The Things with Unite.vim](http://www.codeography.com/2013/06/17/replacing-all-the-things-with-unite-vim.html)
- [Vim Ctrlp Behaviour With Unite](http://eblundell.com/thoughts/2013/08/15/Vim-CtrlP-behaviour-with-Unite.html)

> まず、僕がこのプラグインが大好きな理由。これは僕のコードをナビゲートする強力なインターフェイスであるだけじゃなくて、一貫性のあるインターフェイスであるということだ。例えば、バッファをナビゲートするための運動神経を鍛えたとすると、それをそのまま他のこと (例えば、ヤンク履歴) のナビゲートにも流用できることだ。

まず僕が unite.vim を使ってやりたかったのは SublimeText の `Ctrl+P` 機能のエミュレートだ。`Ctrl-P` と `Ctrl-N` は previous と next という感じでよく使われているキーバインディングみたいなので、スペースバーを unite.vim 全般のプレフィックスにして、ファイルは `<space>f` を割り当てる。

<code>
" Unite

let g:unite_enable_start_insert = 1
nmap <space> [unite]
nnoremap [unite] <nop>
let g:unite_data_directory = '~/.unite'

call unite#filters#matcher_default#use(['matcher_fuzzy'])
call unite#filters#sorter_default#use(['sorter_rank'])

" File searching using <space>f
nnoremap <silent> [unite]f :<C-u>Unite -no-split -buffer-name=files -profile-name=buffer -auto-preview file_rec/async:!<cr>
</code>

ここでは `-no-split` を使っているため、ファイルのリストは現在ウィンドウに表示される。Vim はモーダルなエディタなので、この方が通らしい。

![unite.vim](/images/vim-memo-1b.png)

`enter` を押すとデフォルトのアクションが実行され、この場合はファイルが開かれる。タブを押すと分割ウィンドウで開くなど他のアクションが表示される。

これを使って様々な便利なコマンドを定義できる。例えば [the silver searcher](https://github.com/ggreer/the_silver_searcher) を使った grep などだ。

<code>
if executable('ag')
  let g:unite_source_grep_command='ag'
  let g:unite_source_grep_default_opts='--nocolor --nogroup -S -C4'
  let g:unite_source_grep_recursive_opt=''
elseif executable('ack')
  let g:unite_source_grep_command='ack'
  let g:unite_source_grep_default_opts='--no-heading --no-color -C4'
  let g:unite_source_grep_recursive_opt=''
endif

" Grepping using <space>/
nnoremap <silent> [unite]/ :<C-u>Unite -no-quit -buffer-name=search grep:.<cr>

" Yank history using <space>y
let g:unite_source_history_yank_enable = 1
nnoremap <silent> [unite]y :<C-u>Unite -no-split -buffer-name=yank history/yank:<cr>

" Buffer switching using <space>s
nnoremap <silent> [unite]s :<C-u>Unite -no-split -buffer-name=buffers -quick-match -auto-preview buffer:<cr>

" Buffer and recent using <space>r
nnoremap <silent> [unite]r :<C-u>Unite -no-split -buffer-name=mru -quick-match buffer file_mru:<cr>

" Bookmark using <space>b
nnoremap <silent> [unite]b :<C-u>Unite -no-split -buffer-name=bookmark bookmark:<cr>

" Everything using <space>a
nnoremap <silent> [unite]a :<C-u>Unite -no-split -buffer-name=files buffer file_mru bookmark file:<cr>

" Help using <space>h
nnoremap <silent> [unite]h :<C-u>Unite -no-split -buffer-name=help help:<cr>

autocmd FileType unite call s:unite_settings()

function! s:unite_settings()
  let b:SuperTabDisabled=1
  imap <buffer> <C-j>     <Plug>(unite_select_next_line)
  imap <buffer> <C-k>     <Plug>(unite_select_previous_line)

  " Double tapping <Esc> closes unite
  nmap <silent> <buffer> <Esc><Esc> <Plug>(unite_exit)
  imap <silent> <buffer> <Esc><Esc> <Plug>(unite_exit)
endfunction
</code>

### Shougo/neomru.vim 

Unite.vim は他の Unite プラグイン (それらは Vim プラグインでもある) を使って拡張することができる。[neomru.vim](https://github.com/Shougo/neomru.vim) はその一つで、最近使ったファイルを表示する。

### tsukkee/unite-help

[unite-help](https://github.com/tsukkee/unite-help) は help ファイルを表示するための unite ソースだ。Vim 機能の全ては便利なテキストファイルに文書化されていて、これを `<space>h` で参照できるようになった。

例えば、window コマンドのキーバインディングを調べるには `<space>h` と打ち込んでから、Unite に `:wincmd` と打てばいい。これで、現在のウィンドウの幅を広くするには `<C-w>10>` と打てばいいことが分かる。

### Shougo/vimfiler

[Vimfiler](https://github.com/Shougo/vimfiler.vim) はファイルエクスプローラーだ。これがどこまで必要になるかは分からないけども、SublimeText のファイルエクスプローラーのサイドバーを結構使っていると思うので、似たような機能を一応入れておいた。以下の設定で `backslash e` でファイルエクスプローラーが分割ウィンドウに開くようになる。

<code>
" vim.filer {{{
if neobundle#is_installed('vimfiler')
" Enable file operation commands.
let g:vimfiler_safe_mode_by_default = 0

let g:vimfiler_as_default_explorer = 1
nnoremap <silent> <Leader>e :<C-U>VimFiler -buffer-name=explorer -split -simple -winwidth=35 -toggle -no-quit<CR>
nnoremap <silent> <Leader>E :<C-U>VimFiler<CR>

" ....
endif
" }}}
</code>

![vimfiler](/images/vim-memo-1c.png)

vimfiler 内でキーバインディング:

- `?` ヘルプの表示
- `a` アクションのリストを表示
- `N` 新規ファイルの作成
- `K` 新規ディレクトリの作成

### Shougo/neocomplete.vim

[neocomplete](https://github.com/Shougo/neocomplete.vim) はキーワード補完システムで、現在のバッファ内のキーワードをキャッシュに管理する。YouCompleteMe も試してみたけど、こっちの方が良かった。

<!--
$ cmake -G "Unix Makefiles" -DPYTHON_LIBRARY=/usr/local/Frameworks/Python.framework/Versions/2.7/lib/libpython2.7.dylib -DPYTHON_INCLUDE_DIR=/usr/local/Frameworks/Python.framework/Versions/2.7/Headers . ~/.vim/bundle/YouCompleteMe/third_party/ycmd/cpp
-->

### Shougo/neosnippet.vim

[neosnipplet](https://github.com/Shougo/neosnippet.vim) はスニペットサポートを提供する。これは neocomplete とも連携するみたいだ。実際のスニペットは [neosnippet-snippets](https://github.com/Shougo/neosnippet-snippets) から提供されている。

`scala.snip` に何が書いてあるか見てみる:

<code>
$ cat ~/.vim/bundle/neosnippet-snippets/neosnippets/scala.snip | less
snippet     match
abbr        match {\n  case .. => ..
      match {
              case ${1} => ${0}
      }
....
</code>

README で推奨されているキーバインディングはこれ:

<code>
" neosnippet {{{
if neobundle#is_installed('neosnippet.vim')
" Plugin key-mappings.
imap <C-k>     <Plug>(neosnippet_expand_or_jump)
smap <C-k>     <Plug>(neosnippet_expand_or_jump)
xmap <C-k>     <Plug>(neosnippet_expand_target)
endif
" }}}
</code>

これで `.scala` ファイルを開いて `match<ctrl-K>` と打ち込むと match-case に展開する。

### Shougo/vimshell.vim

[vimshell](https://github.com/Shougo/vimshell.vim) は Vim script だけで書かれたシェルだ。エディタ内にシェルを走らせることができると便利らしい。面倒なことをしなくてもテキストを REPL から yank してくるとかできるようになるからだろうか。

![vimshell](/images/vim-memo-1d.png)

これを簡単に立ち上げられるようにショートカットを割り当てる。

<code>
" vimshell {{{
if neobundle#is_installed('vimshell')
nnoremap <silent> <Leader>s :<C-U>VimShell -buffer-name=shell -split -toggle<CR>
let g:vimshell_user_prompt = 'fnamemodify(getcwd(), ":~")'
endif
" }}}
</code>

ファイルエクスプローラー同様に、`backslash s` でシェルウィンドウがトグルするようにした。シェルと Vim を統合するという発想は面白いけども、Zsh とはちょっと勝手が違う。例えば、sbt を走らせてみると上矢印キーが取られてて sbt の履歴補完が使えなくなってた。

### Shougo/vimproc.vim

[vimproc](https://github.com/Shougo/vimproc.vim) は Vimshell を使うのに必要なものだ。これをインストールするのに手動ステップがあるけども、以下のように NeoBundle を書いておけば入るはずだ:

<code>
NeoBundle 'Shougo/vimproc', {
    \ 'build' : {
    \     'windows' : 'make -f make_mingw32.mak',
    \     'cygwin' : 'make -f make_cygwin.mak',
    \     'mac' : 'make -f make_mac.mak',
    \     'unix' : 'make -f make_unix.mak',
      \    },
      \ }
</code>

GNU make に `make` としてパスが通っている必要がある。

### 矢印キーについて

Vimmer はよく「矢印を使うな」という。マウス (またはトラックボールやタッチパッド)的な装置を手放すわけだから、1000行のコードを行ったり来たりするのに矢印キーを 1000回使う癖をつけるなというのは理にかなっている。同じ効率を保つためには、Vim はページ、ブロック、キーワード検索といった他の意味論に基いてナビゲートする必要がある。

とは言っても、修飾キーと矢印キーの組み合わせは特に分割ウィンドウ間の移動などテキスト編集以外での場面での移動に便利であることは否めない。僕が取りあえず設定したのは以下の3つの移動だ:

- tmux ウィンドウ
- tmux ペイン (分割ウィンドウ)
- Vim ウィンドウ (分割ウィンドウ)

矢印キーを正しく設定するには、これまで導入した全てのレイヤーにおける知識が必要になる。以下に参考にしたページのリンクを挙げる:

- [How do I find out what escape sequence my terminal needs to send?](http://stackoverflow.com/questions/19062315/how-do-i-find-out-what-escape-sequence-my-terminal-needs-to-send)
- [How to get shift+arrows and ctrl+arrows working in Vim in tmux?](http://superuser.com/questions/401926/)
- [Where do I find a list of terminal key codes to remap shortcuts in bash?](http://unix.stackexchange.com/questions/76566)

矢印キーを修飾キーとともに押下したときに、Terminal.app はどの文字の列を Zsh に送信しなければいけないかを知らなければいけない。この慣例の一つに "xterm style" というものがあり、以下のようになっている:

<code>
 <Esc> + "1;" + <modifier key> + ("A" | "B" | "C" | "D")
</code>

ここで、`<Esc>` は `\033` で `<modififer key>` は以下の値だ:

- 2 `<Shift>`
- 3 `<Alt>`
- 4 `<Shift-Alt>`
- 5 `<Ctrl>`
- 6 `<Shift-Ctrl>`
- 7 `<Alt-Ctrol>`
- 8 `<Shift-Alt-Ctrl>`

そして

- A `<Up>`
- B `<Down>`
- C `<Right>`
- D `<Left>`

というふうに割り当てられるが、`<Alt-Left>` と `<Alt-Right>`　だけは例外で、慣例により `<Esc>B` と `<Esc>F` というふうに割り当てられる。この割り当ての全てが Terminal.app の設定にはデフォルトで入っているわけじゃないけども、手動で設定できる:

![keyboard mappings](/images/vim-memo-1e.png)

次に、以下を `tmux.conf` に書くことで中で走っている Zsh に転送する:

<code>
# pass through Shift+Arrow
set-window-option -g xterm-keys on
</code>

これで、tmux ウィンドウとペインの移動を設定できるようになった:

<code>
# control arrow to switch windows
bind -n C-Left  previous-window
bind -n C-Right next-window

# use ctrl-shift-arrow keys without prefix key to switch panes
bind -n C-S-Left select-pane -L
bind -n C-S-Right select-pane -R
bind -n C-S-Up select-pane -U
bind -n C-S-Down select-pane -D
</code>

次に、Vim ウィンドウ間での移動は `vimrc.moving` に以下のように書く:

<code>
" moving

" Use Shift-arrows to select the active split!
noremap <silent> <S-Up> :wincmd k<CR>
imap <S-Up> <Esc><S-Up>
noremap <silent> <S-Down> :wincmd j<CR>
imap <S-Down> <Esc><S-Down>
noremap <silent> <S-Left> :wincmd h<CR>
imap <S-Left> <Esc><S-Left>
noremap <silent> <S-Right> :wincmd l<CR>
imap <S-Right> <Esc><S-Right>

if &term =~ '^screen'
  " tmux will send xterm-style keys when its xterm-keys option is on
  execute "set <xUp>=\e[1;*A"
  execute "set <xDown>=\e[1;*B"
  execute "set <xRight>=\e[1;*C"
  execute "set <xLeft>=\e[1;*D"
endif
</code>

これで `<Shift>`-arrow によって Normal モードと Insert モードの両方から Vim ウィンドウ間の移動ができるようになった。ホームポジションから手が離れるため、こういう設定をやってると素人フラグが立ちそうだけども、個人的には便利だと思っている。

### Ctrl+S で保存

素人っぽいけど、便利というので続けると `Ctrl-S` でファイルの保存というのは訳に立っている。

- [Map Ctrl-S to save current or new files](http://vim.wikia.com/wiki/Map_Ctrl-S_to_save_current_or_new_files)

<code>
" map <C-s> to :update
noremap <silent> <C-S>      :update<CR>
noremap <silent> <C-S>     <C-C>:update<CR>
inoremap <silent> <C-S>     <C-O>:update<CR>
</code>

### Powerline

tmux で [Powerline](https://powerline.readthedocs.org/en/latest/) を入れてあるので、Vim でも使う。これは `vimrc.bundle` の最後に追加した。

<code>
set rtp+=$SITE_PACKAGES/powerline/bindings/vim
</code>

### sickill/vim-monokai

Monokai じゃないと SublimeText を使った気がしない。[vim-monokai](https://github.com/sickill/vim-monokai) は Vim の color scheme への移植版だ。

### derekwyatt/vim-scala

Scala のシンタックスサポートのために、Derek Wyatt 氏の [vim-scala](https://github.com/derekwyatt/vim-scala) を入れた。
Monokai と組み合わせると、こんな感じになる:

![Monokai](/images/vim-memo-1f.png)

### kana/vim-smartinput

[vim-smartinput](https://github.com/kana/vim-smartinput) は SublimeText のように自動でカッコとクォートを閉じるためのプラグインだ。

## まとめ

というわけで、今回はリンクとか設定をまとめておくための個人的なメモだ。credit の大部分はネタ元の yuroyoro氏とかプラグインを書いた Shougo 氏に行く。
Vim をメインのエディタとして使えるまで慣れるのにどれだけ時間がかかるか分からないけども、一応本稿は Vim で書いてみた。日本語固有の問題として、日本語の記事は Insert モードから抜けるのに一度 IME を切らないといけないから Vim には向いてないんじゃないかと思い始めているけど気のせいだろうか。`:set noimdisable` 関連をまだ深追いしてないけど、試した限りでは素の Vim では特に効いてない感じだ。

