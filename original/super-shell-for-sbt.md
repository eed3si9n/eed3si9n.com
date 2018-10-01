I've implemented "super shell" feature for sbt over the weekend. The idea is to take over the bottom n lines of the termnial, and display the current tasks in progress.

### the limitation of using log as status report

Logs are useful in many situations, and sometimes it's the only viable tool to find out what's going on. But on a console app like sbt, using logs to tell the build user what's going on doesn't always work.

If sbt doesn't display any logs, we wouldn't know when it appears to get stuck running a long-running task. So some of the tasks like `udpate` displays "Updating blabla subproject" and "Done updating" when it's done. `update` task takes notoriously long time for some build or some user, but it takes less than a 1s for other builds with only a few dependencies. In those cases, you'd end up seeing a wall of "Done updating" at the beginning of the build.

In other words, using log output as status report end up oscillating between too noisy, or not helpful enough.

### show your work

Like many things in life, the presentation of work, or the user interface for the work is significant aspect of the work itself, especially as the work become less trivial.

I've taken for granted that sbt processes the task in parallel within a single command execution. However, I've come across several occasions lately that I noticed that people did not know that about sbt. This is actually understandable since nothing in the build DSL or the user interface makes it obvious that sbt does parallel task execution.

Moreover, even if an old-timer user takes it as a faith that sbt is executing the tasks in parallel, it's currently difficult to know which tasks become the bottle neck of the performance. Some plugin could be calling `update` unnecessarily, or maybe out-of-process Typescript compiler is being called repeatedly without any changes to source.

### super shell

"super shell" that displays the current tasks in progress solves these problems. Tasks that finish in less than 1s wouldn't even show up to the screen, but when tasks are taking a long time the build user will see the count up clock.

![super shell](https://raw.githubusercontent.com/eed3si9n/eed3si9n.com/master/images/super-shell.gif)

I think the first time I noticed something like that was the "rich console" of Gradle. Buck also implements this, and it apparently calls the feature "super console", so I am going to use the name as well.

### how to implement the super shell

I posted [console games in Scala](http://eed3si9n.com/console-games-in-scala) about a month ago, which was actually a preliminary research for this.

There are two parts to the super shell. First is modifying the logger so the logs move upwards in the terminal. This is a technique I specifically covered in the console games post. By using scroll up, we can keep displaying the log at the same position in the terminal.

<scala>
  private final val ScrollUp = "\u001B[S"
  private final val DeleteLine = "\u001B[2K"
  private final val CursorLeft1000 = "\u001B[1000D"
....
        out.print(s"$ScrollUp$DeleteLine$msg${CursorLeft1000}")
</scala>

Next, I need to display the work-in-progress tasks. I can collect the active tasks by implementing `ExecuteProgress[Task]` created for tracing the tasks. I can keep track of the start time in a hash map, and subtract current time to figure out the elapsed time.

<scala>
  final val DeleteLine = "\u001B[2K"
  final val CursorDown1 = cursorDown(1)
  def cursorUp(n: Int): String = s"\u001B[${n}A"
  def cursorDown(n: Int): String = s"\u001B[${n}B"

...

def report0: Unit = {
  console.print(s"$CursorDown1")
  currentTasks foreach {
    case (task, start) =>
      val elapsed = (System.nanoTime - start) / 1000000000L
      console.println(s"$DeleteLine  | => ${taskName(task)} ${elapsed}s")
  }
  console.print(cursorUp(currentTasks.size + 1))
}
</scala>

Before displaying, I need to move the cursor down 1 line so not to overwrite a log entry.
Active tasks are then displayed with `DeleteLine`. After that, the cursor position is restored using `CursorUp`.

### open questions

I think this would be a good replacement for current "Done updating" style shell. But it's hard to tell how it feels until we start using it often.

Another thing to think about is how to transmit this information as JSON so IDEs and thin clients can do the same.
