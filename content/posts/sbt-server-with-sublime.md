---
title:       "sbt server with Sublime Text 3"
type:        story
date:        2017-12-08
draft:       false
promote:     true
sticky:      false
url:         /sbt-server-with-sublime-text3
aliases:     [ /node/243 ]
tags:        [ "sbt" ]
---

On [Tech Hub blog](https://developer.lightbend.com/blog/2017-11-30-sbt-1-1-0-RC1-sbt-server/) I demonstrated how to use sbt server from VS Code to display compiler errors from a running sbt session. In this post, I'll show how to do that for Sublime Text 3 in this post.

### setting up Sublime Text 3 with sbt server

First, add [tomv564/LSP](https://github.com/tomv564/LSP) plugin to Sublime Text 3.

1. `cd ~/Library/Application\ Support/Sublime\ Text\ 3/Packages`
2. `git clone https://github.com/tomv564/LSP.git`
3. Run 'Preferences > Package Control > Satisfy Dependencies'

Next, download [sbt-server-stdio.js](https://gist.githubusercontent.com/eed3si9n/0ee26a15218f1d4031b451dd61315d6c/raw/5693fbcafbb9a71f1ac5a9d13ace94df3b091cbc/sbt-server-stdio.js) and save it to `~/bin/` or somewhere you keep scripts. sbt server by default uses Unix domain sockets on POSIX systems and named pipe on Windows, but editors seem to expect stdio. The script is a Node script that's included as our VS Code extension that discovers the socket, and fronts it with stdio.

We can now configure the Language Server client. Open 'Preferences > Package Settings > LSP > Settings'.

```json
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
```

**Note**: Substitute `/Users/someone/bin/` with your own path.

### usage

Run some project using sbt 1.1.0-RC1 with `-no-colors` option:

```bash
$ sbt -no-colors
```

Once the sbt server comes up, open the directory using Sublime.

Similar to the VS Code extension, this integration is able to

- Run `compile` at the root project on saving `*.scala` files.
- Display compiler errors.
- Display log messages on Ctrl-```
- Jump to class definitons

![sublime-sbt-scala](/images/sublime-sbt-scala.gif)
