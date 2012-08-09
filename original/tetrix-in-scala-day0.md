  [swing]: http://www.scala-lang.org/sites/default/files/sids/imaier/Mon,%202009-11-02,%2008:55/scala-swing-design.pdf

Every now and then I get an urge to explore a new platform, new ways of thinking, even a new programming language. The first thing I try to implement is always the same: a clone of the famous falling block game. I've implemented them in I think eight languages, Palm V that I borrowed, and on Android. Probably the first Scala program I wrote was Tetrix too. Some had network capability so two players could play against each other, and C# one had AI that kept playing on its own.

I feel like writing Tetrix again. It's non-trivial enough that it lends itself well as an example application. The looping and similar-but-different operations allows languages to showcase lambda or point-free style. The UI and event handling may reveal lack of native support for basic things.

### sbt

I want to eventually target Android, but initially I'll code using scala swing. The core logic should be in a separate jar. So the first thing I do is to create a multi-project build using sbt:

<code>
  library/
    +- src/
         +- main/
              +- scala/
  project/
    +- build.properties
    +- build.scala
  swing/
    +- src/
         +- main/
              +- scala/
</code>

Here's `project/build.properties`:

<code>
sbt.version=0.12.0
</code>

Here's `project/build.scala`:

<scala>
import sbt._

object Builds extends Build {
  import Keys._

  lazy val buildSettings = Defaults.defaultSettings ++ Seq(
    version := "0.1.0-SNAPSHOT",
    organization := "com.eed3si9n",
    homepage := Some(url("http://eed3si9n.com")),
    licenses := Seq("MIT License" -> url("http://opensource.org/licenses/mit-license.php/")),
    scalaVersion := "2.9.2",
    scalacOptions := Seq("-deprecation", "-unchecked"),
    resolvers ++= Seq(
      "sonatype-public" at "https://oss.sonatype.org/content/repositories/public")
  )

  lazy val root = Project("root", file("."),
    settings = buildSettings ++ Seq(name := "tetrix.scala"))
  lazy val library = Project("library", file("library"),
    settings = buildSettings ++ Seq())
  lazy val swing = Project("swing", file("swing"),
    settings = buildSettings ++ Seq(
      fork in run := true,
      libraryDependencies += "org.scala-lang" % "scala-swing" % "2.9.2"
    )) dependsOn(library)
}
</scala>

### swing

Now let's write swing.

<scala>
package com.tetrix.swing

import swing._
import event._

object Main extends SimpleSwingApplication {
  import event.Key._
  import java.awt.{Dimension, Graphics2D, Graphics, Image, Rectangle}
  import java.awt.{Color => AWTColor}

  val bluishGray = new AWTColor(48, 99, 99)
  val bluishSilver = new AWTColor(210, 255, 255)

  def onKeyPress(keyCode: Value) = keyCode match {
    case _ => // do something
  }
  def onPaint(g: Graphics2D) {
    // paint something
  }  

  def top = new MainFrame {
    title = "tetrix"
    contents = mainPanel
  }
  def mainPanel = new Panel {
    preferredSize = new Dimension(700, 400)
    focusable = true
    listenTo(keys)
    reactions += {
      case KeyPressed(_, key, _, _) =>
        onKeyPress(key)
        repaint
    }
    override def paint(g: Graphics2D) {
      g setColor bluishGray
      g fillRect (0, 0, size.width, size.height)
      onPaint(g)
    }
  }
}
</scala>

I did glance a bit of [The scala.swing package][swing], but I took most of the above from my first Tetrix implemention.
scala swing implements a bunch of setter methods (`x_=`) so we can write `x = "foo"` strait in class body. It's almost refershing to see how proudly mutable this framework is, and I think it works here since UI is one big side effect anyway. 

### abstract UI

I don't want to be tied to swing, but there aren't much difference among the platforms. Mostly you have some screen and input to move blocks around. So, the player or the timer takes actions that changes the state of the game, and the result is displayed on the screen. For now, let's approximate the state using a `String` var.

<scala>
package com.eed3si9n.tetrix

class AbstractUI {
  private[this] var lastKey: String = ""

  def left() {
    lastKey = "left"
  }
  def right() {
    lastKey = "right"
  }
  def up() {
    lastKey = "up"
  }
  def down() {
    lastKey = "down"
  }
  def space() {
    lastKey = "space"
  }
  def last: String = lastKey
}
</scala>

We can hook this up to the swing UI as follows:

<scala>
  import com.eed3si9n.tetrix._

  val ui = new AbstractUI

  def onKeyPress(keyCode: Value) = keyCode match {
    case Left  => ui.left()
    case Right => ui.right()
    case Up    => ui.up()
    case Down  => ui.down()
    case Space => ui.space()
    case _ =>
  }
  def onPaint(g: Graphics2D) {
    g setColor bluishSilver
    g drawString (ui.last, 20, 20)
  }  
</scala>

So now, we have an exciting game that displays `"left"` when you hit left arrow key.
I think this is good enough for the first day.

To run this on your machine,

<code>
$ git clone https://github.com/eed3si9n/tetrix.scala.git
$ cd tetrix.scala
$ git co day0
$ sbt "project swing" run
</code>
