  [day11]: http://eed3si9n.com/tetrix-in-scala-day11
  [1]: http://developer.android.com/sdk/installing/index.html
  [android-plugin]: https://github.com/jberkel/android-plugin
  [2]: https://github.com/gseitz/DiningAkkaDroids

[Yesterday][day11] we've created two stage actors so the agent can play against the player. To make things more interesting, attacking was implemented which sends junk blocks to the opponent.

### unfair advantage

Thus far, the agent has been tuned to delete as many lines as it can. But yesterday we introduced attacking, which only kicks in after deleting two or more rows. This gives human side, who are aware of this change, an unfair advantage. Let's see what we can do.

Let's track line counts by the lines deleted in an action:

<scala>
case class GameState(blocks: Seq[Block], gridSize: (Int, Int),
    currentPiece: Piece, nextPiece: Piece, kinds: Seq[PieceKind],
    status: GameStatus = ActiveStatus,
    lineCounts: Seq[Int] = Seq(0, 0, 0, 0, 0),
    lastDeleted: Int = 0, pendingAttacks: Int = 0) {
  def lineCount: Int =
    lineCounts.zipWithIndex map { case (n, i) => n * i } sum
  def attackCount: Int =
    lineCounts.drop(1).zipWithIndex map { case (n, i) => n * i } sum
  ...
}
</scala>

Here's modified `clearFullRow`:

<scala>
  private[this] lazy val clearFullRow: GameState => GameState =
    (s0: GameState) => {
    ....
    val s1 = tryRow(s0.gridSize._2 - 1, s0)
    if (s1.lastDeleted == 0) s1
    else s1.copy(lineCounts = s1.lineCounts updated
      (s1.lastDeleted, s1.lineCounts(s1.lastDeleted) + 1))
  }
</scala>

Now modify the scripting test a bit to print out the attack count:

<scala>
    println(file.getName + ": " +
      s.lineCount.toString + " lines; " +
      s.attackCount.toString + " attacks")
    (s.lineCount, s.attackCount)
</scala>

Here are the results:

<code>
lines  : Vector(34, 34, 32, 52, 29)
attacks: Vector(4, 3, 3, 3, 1)
</code>

I can see how crevasse penalty can work against attacking, so let's increase the height penalty ratio from current 11:10 to 6:5.

<code>
h11:c10:v0 = lines  : Vector(34, 34, 32, 52, 29) // 34 +/- 18
h11:c10:v0 = attacks: Vector(4, 3, 3, 3, 1)      // 3 +/- 2
h6:c5:v0   = lines  : Vector(31, 26, 25, 50, 29) // 29 +/- 21
h6:c5:v0   = attacks: Vector(4, 1, 0, 5, 1)      // 1 +/- 4
</code>

The median actually dropped to 1. To apply the pressure to keep blocks as a chunk, we should bring back the cavity analysis:

<code>
h11:c10:v1 = lines  : Vector(27, 30, 24, 31, 34) // 30 +/- 4
h11:c10:v1 = attacks: Vector(0, 3, 2, 3, 1)      // 3 +/- 3
</code>

Maybe the problem with the cavity analysis is the the penalty calculation was too harsh in comparison with the others. Instead of piling up penalties for each block covering a cavity, why not just use height * height like crevasse:

<scala>
    val coverupWeight = 1
    val coverups = groupedByX flatMap { case (k, vs) =>
      if (vs.size < heights(k)) Some(coverupWeight * heights(k))
      else None
    }
</scala>

We'll denote this as `w1`, `w2` for the amount of `coverupWeight`.

<code>
h1:c1:w1   = lines  : Vector(21, 14, 16, 23, 12) // 16 +/- 7
h1:c1:w1   = attacks: Vector(2, 0, 2, 2, 1)      // 2 +/- 2
h11:c10:w2 = lines  : Vector(22, 24, 28, 50, 37) // 28 +/- 22
h11:c10:w2 = attacks: Vector(1, 0, 2, 7, 1)      // 1 +/- 6
h11:c10:w1 = lines  : Vector(39, 24, 20, 51, 34) // 34 +/- 17
h11:c10:w1 = attacks: Vector(2, 1, 1, 7, 1)      // 1 +/- 6
h22:c20:w1 = lines  : Vector(39, 24, 24, 50, 34) // 34 +/- 17
h22:c20:w1 = attacks: Vector(2, 1, 3, 7, 1)      // 3 +/- 4
h11:c10:w0 = lines  : Vector(34, 34, 32, 52, 29) // 34 +/- 18
h11:c10:w0 = attacks: Vector(4, 3, 3, 3, 1)      // 3 +/- 2
h2:c1:w1   = lines  : Vector(16, 10, 6, 18, 14)  // 14 +/- 8
h2:c1:w1   = attacks: Vector(1, 0, 0, 1, 0)      // 0 +/- 1
</code>

Another possibility may be to further weaken the penalty by using a constant instead of height, which we will use `k1`, `k2`:

<scala>
h11:c10:k2 = lines  : Vector(34, 34, 32, 38, 29) // 34 +/- 5 
h11:c10:k2 = attacks: Vector(4, 3, 3, 5, 1)      // 3 +/- 2
h11:c10:k1 = lines  : Vector(34, 34, 32, 38, 29) // 34 +/- 5
h11:c10:k1 = attacks: Vector(4, 3, 3, 5, 1)      // 3 +/- 2
h11:c10:k0 = lines  : Vector(34, 34, 32, 52, 29) // 34 +/- 18
h11:c10:k0 = attacks: Vector(4, 3, 3, 3, 1)      // 3 +/- 2
</scala>

In terms of the attacks per lines h11:c10:k1 is looking good, so we'll use this for now.

### android

It would be cool if we can show this game off on a cellphone, so let's port this to Android. First [install Android SDK][1] or update to the latest SDK if you can't remember the last time you updated it by launching `android` tool from command line:

<code>
$ android
</code>

As of August 2012, the latest is Android 4.1 (API 16). Next, create an Android Virtual Device (AVD) using the latest API.

Next we need sbt's [android-plugin][android-plugin]. Create `project/plugins.sbt` and add the following:

<scala>
resolvers += Resolver.url("scalasbt releases", new URL("http://scalasbt.artifactoryonline.com/scalasbt/sbt-plugin-releases"))(Resolver.ivyStylePatterns)

addSbtPlugin("org.scala-sbt" % "sbt-android-plugin" % "0.6.2")
</scala>

And add the following to `project/build.scala`:

<scala>
  lazy val android = Project("tetrix_android", file("android"),
    settings = buildSettings ++ Seq(
        platformName in Android := "android-8",
        versionCode := 7
      ) ++
      AndroidProject.androidSettings ++
      AndroidManifestGenerator.settings ++
      TypedResources.settings ++ Seq(

      )) dependsOn(library)
</scala>

When you reload sbt, we should be able to launch emulator as follows:

<code>
> project android
> android:emulator-start test_adv16
</code>

To install your app on the emulator and start it:

<code>
> android:start-emulator
</code>

To install on a phone:

<code>
> android:install-device
</code>

### hello world

An Android apps consists mainly of activities, views, and threads. For tetrix, we just need to get a handle to the `Canvas` object to draw things, so activities and views become fairly simple. I will stuff most of the logic in a thread, which I am not sure is the right approach.

Here's the activity class:

<scala>
package com.eed3si9n.tetrix.droid
  
import android.app.Activity
import android.os.Bundle
  
class MainActivity extends Activity {
  override def onCreate(savedInstanceState: Bundle ) {
    super.onCreate(savedInstanceState)
    setContentView(R.layout.main)
  }
}
</scala>

The layout file is `android/src/main/res/layout/main.xml`:

<code>
<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
  android:orientation="horizontal"
  android:layout_width="fill_parent"
  android:layout_height="fill_parent"
  >
    <com.eed3si9n.tetrix.droid.MainView android:id="@+id/main_view"
      android:layout_height="fill_parent"
      android:layout_width="fill_parent"
      />
</LinearLayout>
</code>

This points to `MainView`:

<scala>
package com.eed3si9n.tetrix.droid

import android.content.Context
import android.util.AttributeSet
import android.view.{View, SurfaceView, SurfaceHolder, GestureDetector, MotionEvent}

class MainView(context: Context, attrs: AttributeSet) extends SurfaceView(context, attrs) {
  val holder = getHolder
  val thread = new MainThread(holder, context)
  
  holder addCallback (new SurfaceHolder.Callback {
    def surfaceCreated(holder: SurfaceHolder) {
      thread.start()
    }
    def surfaceChanged(holder: SurfaceHolder, format: Int, width: Int, height: Int) {
      thread.setCanvasSize(width, height)
    }
    def surfaceDestroyed(holder: SurfaceHolder) {}
  })
  
  setFocusable(true)
  setLongClickable(true)
  setGesture()

  def setGesture() {
    val gd = new GestureDetector(new GestureDetector.SimpleOnGestureListener() {
      override def onFling(e1: MotionEvent, e2: MotionEvent,
          velocityX: Float, velocityY: Float): Boolean = {
        thread.addFling(velocityX, velocityY)
        true
      }
    })
    setOnTouchListener(new View.OnTouchListener() {
      def onTouch(v: View, e: MotionEvent): Boolean = gd.onTouchEvent(e)
    })
  }
}
</scala>

Finally, in order to manage my own repaint, I am going to run a thread in an infinite loop:

<scala>
package com.eed3si9n.tetrix.droid

import com.eed3si9n.tetrix._
import android.content.Context
import android.view.{SurfaceHolder}
import android.graphics.{Canvas, Paint, Rect}

class MainThread(holder: SurfaceHolder, context: Context) extends Thread {
  val quantum = 100

  var canvasWidth: Int = _
  var canvasHeight: Int = _
  val bluishSilver = new Paint
  bluishSilver.setARGB(255, 210, 255, 255)
 
  override def run {
    var isRunning: Boolean = true
    while (isRunning) {
      val t0 = System.currentTimeMillis

      withCanvas { g =>
        g drawText ("hello world", 10, 10, bluishSilver)
      }
      
      val t1 = System.currentTimeMillis
      if (t1 - t0 < quantum) Thread.sleep(quantum - (t1 - t0))
      else ()
    }
  }
  def setCanvasSize(w: Int, h: Int) {
    canvasWidth = w
    canvasHeight = h
  }
  def addFling(vx: Float, vy: Float) {
    val theta = math.toDegrees(math.atan2(vy, vx)).toInt match {
      case x if x < 0 => x + 360
      case x => x
    }
    // do something
  }
  def withCanvas(f: Canvas => Unit) {
    val canvas = holder.lockCanvas(null)
    try {
      f(canvas)
    } finally {
      holder.unlockCanvasAndPost(canvas)
    }
  }
}
</scala>

The above would print out "hello world" at 10 frames per second. The rest is just the matter of hooking things up.

### akka 1.3.1

I chose the latest stable Scala 2.9.2 and Akka 2.0.2, which was the latest when I started. The problem is that Akka 2.0.2 doesn't seem to work on Android easily. On the other hand, for older version of Akka there's an example application [gseitz/DiningAkkaDroids][2] that's suppose to work. It wasn't much work, but I had to basically downgrade Akka to 1.3.1.

Here are some of the changes. Instead of an `ActorSystem`, `Actor` singleton object is used to create an actor. Names are set using `self.id`:

<scala>
  private[this] val stageActor1 = actorOf(new StageActor(
    stateActor1) {
    self.id = "stageActor1"
  }).start()
</scala>

Grabbing the values from `Future` is much simpler. You just call `get`:

<scala>
  def views: (GameView, GameView) =
    ((stateActor1 ? GetView).mapTo[GameView].get,
    (stateActor2 ? GetView).mapTo[GameView].get)
</scala>

Instead of the path, you can use `id` to lookup actors:

<scala>
  private[this] def opponent: ActorRef =
    if (self.id == "stageActor1") Actor.registry.actorsFor("stageActor2")(0)
    else Actor.registry.actorsFor("stageActor1")(0)
</scala>

I had to implement scheduling myself using `GameMasterActor`, but that wasn't a big deal either.

### UI for Android

Android has its own library for widgets and graphics. They are all well-documented, and not that much different from any other UI platforms. I was able to port `drawBoard` etc from swing with only a few modification.

<scala>
  var ui: Option[AbstractUI] = None

  override def run {
    ui = Some(new AbstractUI)
    var isRunning: Boolean = true
    while (isRunning) {
      val t0 = System.currentTimeMillis
      val (view1, view2) = ui.get.views
      synchronized {
        drawViews(view1, view2)
      }
      val t1 = System.currentTimeMillis
      if (t1 - t0 < quantum) Thread.sleep(quantum - (t1 - t0))
      else ()
    }
  }
  def drawViews(view1: GameView, view2: GameView) =
    withCanvas { g =>
      g drawRect (0, 0, canvasWidth, canvasHeight, bluishGray)
      val unit = blockSize + blockMargin
      val xOffset = canvasWidth / 2
      drawBoard(g, (0, 0), (10, 20), view1.blocks, view1.current)
      drawBoard(g, (12 * unit, 0), view1.miniGridSize, view1.next, Nil)
      drawStatus(g, (12 * unit, 0), view1)
      drawBoard(g, (xOffset, 0), (10, 20), view2.blocks, view2.current)
      drawBoard(g, (12 * unit + xOffset, 0), view2.miniGridSize, view2.next, Nil)
      drawStatus(g, (12 * unit + xOffset, 0), view2)
    }
</scala>

`withCanvas` is a loan pattern that ensures that the canvas gets unlocked. The only thing is that there's no keyboard on newer phones. Here's how we can translate gesture angles into actions:

<scala>
  def addFling(vx: Float, vy: Float) {
    val theta = math.toDegrees(math.atan2(vy, vx)).toInt match {
      case x if x < 0 => x + 360
      case x => x
    }
    theta match {
      case t if t < 45 || t >= 315  => ui map {_.right()}
      case t if t >= 45 && t < 135  => ui map {_.space()}
      case t if t >= 135 && t < 225 => ui map {_.left()}
      case t if t >= 225 && t < 315 => ui map {_.up()}
      case _ => // do nothing
    }
  }
</scala>

Let's load it on the emulator:

<code>
> android:start-emulator
</code>

It was a bit shaky but it did showed up on the emulator.

<img src="/images/tetrix-in-scala-day12.png"/>

I was hoping it runs on multicore androids, and it did! It ran smoothly on a borrowed Galaxy S III.

<img src="/images/tetrix-in-scala-day12b.png"/>

Anyway, this is going to be the end of our tetrix in Scala series. Thanks for the comments and retweets. I'd like to hear what you think. Also, if you are up for the challenge, send me a pull request of a smarter agent-actor that can beat human!
