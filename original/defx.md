  [defx]: https://github.com/Shougo/defx.nvim
  [help]: https://github.com/Shougo/defx.nvim/blob/master/doc/defx.txt
  [vinegar]: https://github.com/tpope/vim-vinegar
  [@Shougo]: https://github.com/Shougo
  [command-t]: https://github.com/wincent/command-t
  [denite]: https://github.com/Shougo/denite.nvim

The combination of fuzzy searching ([Command-T][command-t], [Denite][denite] etc) and file explorer are great. That's pretty much what you get when you open Sublime Text or VS Code.

This post is my attempt to configure Neovim so I can get a nice tree-view style file explorer. This was inspired in part because I tried to use Onivim, and for me the lack of functional file explorer was noticable maybe because I mostly use Sublime or VS Code.

### Defx

[Defx][defx] is a file explorer plugin for Neovim written by [@Shougo][@Shougo]. He calls this a "dark powered" plugin. This may be because he wrote this using Python 3. Whatever the transaction he made with the evil, it is much faster compared to NERDTree.

An interesting aspect of Defx is that it does not come with the default key binding. The users are encouraged to customize the feel of the plugin. The sample bindings in [help file][help] is Netrw-like. Here we'll make it Sublime-like.

#### Screen capture

Here's a demo of how I've set up Defx:

<img border="0" alt="" src="https://github.com/eed3si9n/eed3si9n.com/raw/master/resources/defx.gif" width="900" />

### Basic navigation and previewing

I made `<Space>-e` to split Defx to the left. `q` closes it.

`j`/`k` moves the cursor up and down as it should. I bound `<CR>` as follows:

<code>
  nnoremap <silent><buffer><expr> <CR>
  \ defx#is_directory() ?
  \ defx#do_action('open_tree', 'recursive:10') :
  \ defx#do_action('preview')
</code>

If the node is a directory it expands the tree recursively, and when it's a file it opens in the preview. This emulates the clicking action in Sublime. Using this I can go up and down navigating using just three keys.

To jump to a file after expanding a tree, we can use `/` to search in the buffer.

To close the recursively opened trees, I've implemented a brute force binding to `b` that closes the tree ten times:

<code>
  nnoremap <silent><buffer><expr> b
  \ defx#do_action('multi', ['close_tree', 'close_tree', 'close_tree', 'close_tree', 'close_tree', 'close_tree', 'close_tree', 'close_tree', 'close_tree', 'close_tree'])
</code>

I've mapped `o` to open a file. It actually uses _drop_ action so if the file is already open it will just move the focus to the buffer.

### File manipulation

File manipulation is where the explorer shines.

- `N` creates a new file.
- `K` creates a new subdirectory.
- `r` renames a file.
- `d` delete a file.

These operations will be performed at the directory of current focus.

### Changing directory

Sometimes it's useful to narrow the focus to a specific subdirectory, similar to Netrw.

`l` changes the current directory view to the one on focus, and `h` goes back to the parent.

<code>
  nnoremap <silent><buffer><expr> l
  \ defx#is_directory() ? defx#do_action('open') : 0
  nnoremap <silent><buffer><expr> h
  \ defx#do_action('cd', ['..'])
</code>

### Bonus: Vineger mode

As a bonus, let's emulate [Vinegar](https://github.com/tpope/vim-vinegar) as well. Unlike Sublime file explorer, the Vinegar approach is to list the directory of the current file in the current window.

Here's how I've mapped `-`:

<code>
nnoremap <silent> - :<C-U>:Defx `expand('%:p:h')` -search=`expand('%:p')` -buffer-name=defx<CR>
</code>

For example, if my current buffer is at `internal/compiler-interface/src/main/java/sxbti/VirtualFile.java`, `-` will open Defx at `internal/compiler-interface/src/main/java/sxbti/`.

I don't want `o` to "drop" the file into another window. I can differentiate the behavior based on the buffer name as follows:

<code>
  nnoremap <silent><buffer><expr> o
  \ match(bufname('%'), 'explorer') >= 0 ?
  \ (defx#is_directory() ? 0 : defx#do_action('drop', 'vsplit')) :
  \ (defx#is_directory() ? 0 : defx#do_action('multi', ['open', 'quit']))
</code>

For everything else, this will have the same key bindings including `l`/`h` to go back up one level.

### Setup

#### Nerd font

<code>
brew tap homebrew/cask-fonts
brew cask install font-hack-nerd-font
</code>

Then change Non-ASCII Font to "Hack Nerd Font Mono" in your terminal.

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

