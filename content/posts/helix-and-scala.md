---
title: "Helix and Scala"
type: story
date: 2023-11-16
url: /helix-and-scala
tags: [ "sbt" ]
---

I recorded a 11 minute video of me pecking around Scala 3 code using my recent favorite editor Helix.

<iframe width="560" height="315" src="https://www.youtube.com/embed/uYopbRq62ds?si=grHpwJ2_gev29sLK" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" allowfullscreen></iframe>

<!--more-->

I originally gave a 20-minute talk at ScalaMatsuri 2023 on this, so the above is a more condensed version with higher information density.

### about Helix

<https://helix-editor.com/> is the official site of Helix. Helix is an editor, inspired by editors like Vim and Kakoune, but has improved usability by first letting you see the code selection, and also by providing pop-up guides on keyboard shortcuts. It comes with Tree Sitter and Language Server Protocol (LSP) built-in, and with Monokai Aqua theme that I contributed, making it the best setup to code Scala 3 with sbt server for me.

### setup

1. Follow [Installing Helix](https://docs.helix-editor.com/install.html) to install Helix. For macOS, Home Brew works:
   ```bash
   brew install helix
   ```
2. Follow [Coursier Installation](https://get-coursier.io/docs/cli-installation) to install `cs`:
   ```bash
   brew install coursier/formulas/coursier
   ```
3. Installs Metals CLI:
   ```
   cs install metals
   metals --version
   # metals 1.1.0
   ```

### setup per project

1. Open an sbt project using VS Code, and [switch the build server to sbt](https://scalameta.org/metals/docs/build-tools/sbt/). On mac, this would be `⌘Cmd - ↑Shift - P`, then type "Metals: Switch build server" and pick "sbt". Next, `⌘Cmd - ↑Shift - P` and type "Metals: Import build" to build the build. Close VS Code.
2. Run Helix by typing:
   ```
   hx
   ```
3. Open a Scala file by typing `<Space> f` and selecting a Scala file. This should automatically trigger Helix to run `metals`, which then should trigger Metals to run sbt server.

### Helix configuration

Follow [Helix configuration](https://docs.helix-editor.com/configuration.html) page.

In your shell setup, like `.zshrc`:

```bash
export XDG_CONFIG_HOME="$HOME/dotfiles"
```

This will move the default configuration directory from `$HOME/.config/` to `$HOME/dotfiles/`, and share it on GitHub etc. Here's my `$HOME/dotfiles/helix/config.toml`:

```bash
theme = "monokai_aqua"

[editor]
true-color = true
color-modes = true
bufferline = "always"

[editor.lsp]
display-messages = true

[editor.whitespace.render]
space = "all"
tab = "all"
nbsp = "all"
newline = "none"

[keys.normal]
C-s = ":w"
C-j = "save_selection"

[keys.normal."]"]
"]" = "goto_next_paragraph"

[keys.normal."["]
"[" = "goto_prev_paragraph"

[keys.insert]
j = { j = "normal_mode" } # Maps `jj` to exit insert mode
```

Note the total lack of plugin configuration. Apart from `display-messages = true`, everything else is just my personal preference, and can be omitted for you. I find this nice compared to other terminal editors where keeping up with plugin is a hassle.

### Vim aesthetics

There are many books that tries to teach the kata (form) of things, and perhaps that is one way to learn by repetition. [Drew Neil's Practical Vim](https://pragprog.com/titles/dnvim2/practical-vim-second-edition/) teaches the spirit of Vim through practice, blending the theory and practice.

According to Neil, the Normal mode is the resting state, giving equal keyboard opportunities to searching and moving. In the Vim way, the act of typing something into a buffer is crafting a mini-program that is automatically stored inside Vim, and can be recalled using `.`.

I think this spirit lives on in Helix as well, but with improved usability by providing immediate visual feedback, like in Vim's Visual mode.

### transcript of Helix and Scala

Alright I want to demonstrate Helix, which is an editor that I like using. "brew install helix" should work on Mac and let's see. Yeah so it's sort of like an editor written in Rust that is sort of inspired by [Vim](https://www.vim.org/) and another editor called [Kakoune](https://kakoune.org/) that flips the ordering of the selection and command.

In Helix you first select, and then you take an action. (On screen, I keep typing `w`, which keeps selecting next word) For example if you want to change this word, you say `c`. Or you want to select more (`vwwww` selects multiple words), change (`c`) this selection. So in a way this implements multiple selection. Select the word `override` and you can say capital `C` twice to select three of these `override` across three lines. `d` removes them.

The syntax highlighting here is using [Tree Sitter](https://tree-sitter.github.io/tree-sitter/) so Helix itself doesn't know specific about Scala but it knows about the tree-sitter-scala so that's how it's doing the syntax highlight. For this particular theme, I made a minor adjustment to the existing Monokai theme and created "monokai-aqua" it's now been merged. So my minor contribution to Helix editor is that I added on this Aqua theme.

As you can see, it knows about Scala, sort of. So it's using [Metals](https://scalameta.org/metals/) in the backend. It's actually using the command line version of Metals so let's see if we can reimplement this:

```scala
override def arguments: Array[String] = config.arguments()
```

`v w` to select `arguments()` and let's just delete it with `d`. `i` to go to Insert mode, and delete and retype Period. Code completion works. Then `<tab>` through the candidates, or go `<Up>`. Select it using `<Return>`. [Ba Dum Tss]

Back to Normal mode (`jj`). Save this (`:w`). I just use `Ctrl-s`, which is how I remapped save. Let's try with this again.

Often it's kind of useful to split the screen (`Ctrl-w v`). You hit space or any of these first character of the command. Get this thing open on for example `<Space>-k` gives you the hovering. `g` is a go-to so the one that I use most is the `g-d`, which is go-to-definition and you can say `Ctrl-o` to get back.

`x` to select these lines. `d` to delete them. `u` to undo. Or you can select the entire file using `%` and then delete them. Probably a more useful thing if you select is for example you can search within it. See import and now you've created a multiple selection of the word "import" and then change to "import2" [Funny sound]

So `<Space>-f` opens the file picker. This also has fuzzy search. If you want to create an error, `<Space>-d` tells you the error message. So this is pretty useful if you're somewhere out, and you just want to jump to that.

This is using BSP so it's running an sbt server in the background if you use sbt client, you can hook up to it. So then have this and then you get the same error without recompiling everything.

If you say `/dummy`, it's one way to jump [by searching]. Then say `<Space>-r`. This lets you rename. Rename to `dummy2` and and now we see these [use sites] have been changed.

Fuzzy search for actioncache test to open the file. So you can use `sbt --client` and use `testQuick` to run tests. Change code, and retest.

Go-to-definition to read the code around. I guess one thing that could be convenient if you had it is go-to-next-method so I don't know if there is something like that. But I've mapped `[[` to basically go-to-next-paragraph as kind of like an equivalent thing and since typically in Scala you chunk your your method that's almost like a paragraph it works [Jazz music]

### what is with the Jazz sounds?

It's partly to comedic effect and to keep the attention. But there's also a bit more. I'm not a huge Jazz buff, I think Bill Evans along with Miles Davis is considered someone who created a more sophisticated modern Jazz sound. While piano, the instrument he plays, is capable of producing all ranges in the orchestra, when he is playing in a trio with bass and drums, he intentionally doesn't play the key note because the bassist would play it, or emulate the bass line. Instead he plays a chord above it, [for example FM7/A](https://www.youtube.com/watch?v=dH3GSrCmzC8). So our ear would hear F but we would feel A with the mixed texture of left hand, right hand, and bass. This elevated both piano and bass from being an accompaniment to front and center.

Helix's simplicity to me feels similar, because it assumes Tree-Sitter and LSP to be the bass note provided by the language tooling.
