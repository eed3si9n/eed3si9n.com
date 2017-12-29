This is part 3 of sbt server integration series. I've covered [VS Code](https://developer.lightbend.com/blog/2017-11-30-sbt-1-1-0-RC1-sbt-server/) and [Sublime Text 3](http://eed3si9n.com/sbt-server-with-sublime-text3) thus far.

### setting up neovim with sbt server

First, you need Python 3 and Node installed on your machine. Then update Neovim client library.

<code>
$ sudo pip3 install --upgrade neovim
</code>

Next, add [eed3si9n/LanguageClient-neovim](https://github.com/eed3si9n/LanguageClient-neovim) plugin to Neovim (or Vim) using your plugin manager. This is a fork of [autozimu/LanguageClient-neovim](https://github.com/autozimu/LanguageClient-neovim) repo so we can use the old Python based "master" branch since I couldn't get the latest "next" brach version to work.

Using Dein it looks like:

<code>
[[plugins]]
repo = 'eed3si9n/LanguageClient-neovim'
</code>

and you restart Neovim, `:UpdateRemotePlugins`. If it goes well, you should see:

<code>
remote/host: python3 host registered plugins ['LanguageClient']
remote/host: generated rplugin manifest: /Users/someone/.local/share/nvim/rplugin.vim
Press ENTER or type command to continue
</code>

Next, download [sbt-server-stdio.js](https://gist.githubusercontent.com/eed3si9n/0ee26a15218f1d4031b451dd61315d6c/raw/5693fbcafbb9a71f1ac5a9d13ace94df3b091cbc/sbt-server-stdio.js) and save it to `~/bin/` or somewhere you keep scripts. sbt server by default uses Unix domain sockets on POSIX systems and named pipe on Windows, but editors seem to expect stdio. The script is a Node script that's included as our VS Code extension that discovers the socket, and fronts it with stdio.

We can now configure the Language Server client. In some configuration script:

<code>
set signcolumn=yes

let g:LanguageClient_autoStart = 1

let g:LanguageClient_serverCommands = {
    \ 'scala': ['node', expand('~/bin/sbt-server-stdio.js')]
    \ }

nnoremap <silent> gd :call LanguageClient_textDocument_definition()<CR>
</code>

### usage

Run some project using sbt 1.1.0-RC2.

Once the server comes up, open the directory using Neovim.

Similar to the VS Code extension, this integration is able to

- Run `compile` at the root project on saving `*.scala` files.
- Display compiler errors.
- Display log messages on `:messages`
- Jump to class definitions

![vim-scala-sbt](/images/vim-scala-sbt.gif)
