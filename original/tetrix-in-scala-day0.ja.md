  [sbt]: http://scalajp.github.com/sbt-getting-started-guide-ja/multi-project/
  [amazon]: http://www.amazon.co.jp/dp/4798125415

時折新しいプラットフォームや、新しい考え方、新しいプログラミング言語を探索してみたくなる衝動にかられる。僕が最初に実装してみるのはいつも同じだ。ブロックが落ちてくる某ゲームのクローン。今まで多分 8つの言語、ひとに借りた Palm V、それから Android でも実装した。多分最初に Scala で書いたプログラムも Tetrix だったはずだ。そのうちのいくつかはネットワーク機能があってプレーヤー同士が対戦できた。C# で書いたのには勝手にプレイし続ける AI があった。

最近また Tetrix が書きたくなってきた。Tetrix は難しくは無いけど例題アプリケーションとしては手頃な複雑さがある。例えば、ループや似て異なる演算がいくつかあるため、言語によってはラムダ式やポイントフリースタイルを自慢できる。逆に、UI やイベント処理は基本的な事に対するネイティブなサポートが欠けている事を露見させるかもしれない。

### sbt

後ほど Android 向けに書くつもりだけど、最初は scala swing を使う。コアとなるロジックは別の jar に入れよう。取り敢えず sbt でマルチプロジェクトのビルドを作る:

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

始める sbt だと [マルチプロジェクト・ビルド][sbt]、[Scala 逆引きレシピ][amazon]だと「209: 複数のsbtプロジェクトをまとめて管理したい」が参考になる。

これが `project/build.properties`:

<code>
sbt.version=0.12.0
</code>

これが `project/build.scala`:

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

次に swing を書く。[Scala 逆引きレシピ][amazon]だと、「165: GUIアプリケーションを作りたい」が一応参考になるけど、ある程度 Java Swing を一緒に勉強する必要があると思う。

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

[The scala.swing package](http://www.scala-lang.org/sites/default/files/sids/imaier/Mon,%202009-11-02,%2008:55/scala-swing-design.pdf) もちらっと見たけど、上はだいたい前に書いた Tetrix の実装からもらってきた。
scala swing はセッターメソッド (`x_=`) をいくつも定義しているため、クラスの本体に直接 `x = "foo"` のように書くことができる。すがすがしいぐらいに可変 (mutable) なフレームワークだ。UI は全部副作用なので、これはうまくいっていると思う。

### 抽象 UI

あまり swing に縛られたくないが、特にプラットフォーム間で違いがあるわけでもない。だいたい画面があって、ブロックを動かすインプットがある。プレーヤーかタイマーがゲームがアクションを実行し、ゲームの状態が変わり、結果が画面に表示される。今のところは、ゲームの状態を `String` の var で代用しよう。

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

以下のようにして swing UI につなぐ:

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

これで、左矢印を押すと `"left"` と表示される面白いゲームができた。
初日はこんなものでいいんじゃないかな。

自分のマシンで試してみる手順:

<code>
$ git clone https://github.com/eed3si9n/tetrix.scala.git
$ cd tetrix.scala
$ git co day0 -b try/day0
$ sbt "project swing" run
</code>

[1日目](http://eed3si9n.com/ja/tetrix-in-scala-day1)へ続く。
