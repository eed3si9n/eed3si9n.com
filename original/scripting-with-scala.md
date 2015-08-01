  [1]: http://docutils.sourceforge.net/docs/ref/rst/restructuredtext.html#interpreted-text
  [2]: http://www.scala-sbt.org/release/docs/Detailed-Topics/Scripts.html#sbt-script-runner
  [3]: https://github.com/n8han/conscript
  [4]: http://www.scala-lang.org/api/2.10.4/index.html#scala.sys.process.ProcessBuilder
  [5]: https://gist.github.com/eed3si9n/fc1aa881bd28b48843e3

The need for regular expressions is real. Whenver I need to transform a set of text files it usually ends up with fumbling through the documentation of `find` command, zsh, and StackOverflow Perl questions. I would rather use Scala instead of muddling through Perl. It's really the matter of my familiarity than anything else.

For example, I now have over a hundred reStructuredText files that I want to convert into markdown. I first tried pandoc, and it looked mostly ok. As I was going through the details, however, I noticed that many of the code literals were not converting over as formatted. This is because they were formatted using either single ticks or using [Interpreted Text][1]. Preprocessing the text with a series of regex replacements should work.

### command line scalas

On my development machine, I currently do not have `scala` on my path. It's not like it's too much work to download the zip file once, but rather the fact that I'd need to maintain the jar and the script going forward seems tedious. Normally I'd just use sbt, which downloads the Scala jars, and it mostly works, but let's say I want a one-file solution.

One solution I'm trying out now is sbt's [script runner][2], which is available via [conscript][3]:

    $ cs sbt/sbt --branch 0.13.2b

Note: Running the above will wipe your `~/bin/sbt` if you have one. One of the things it installs under `~/bin/` is `scalas` script. 
Make `script.scala`:

<scala>
#!/usr/bin/env scalas

/***
scalaVersion := "2.10.4"
*/

println("hello")
</scala> <!-- ***/ -->

Next,

    $ chmod +x script.scala
    $ export CONSCRIPT_OPTS="-XX:MaxPermSize=512M -Dfile.encoding=UTF-8"
    $ ./script.scala
    [info] Loading global plugins from /Users/eugene/dotfiles/sbt/0.13/plugins
    [info] Set current project to root-4dcd3aa66723522a07c4 (in build file:/Users/eugene/.conscript/boot/4dcd3aa66723522a07c4/)
    hello

Now we have a script that specifies its own Scala version to 2.10.4. Including the compilation, it takes 12 seconds for "hello" to show up, so it's not the most snappy experience, but I can live with it.

### sbt.IO

The first thing I want to do is traverse all `*.rst` file in all the subdirectories of `src/` without using `find` command. sbt's `sbt.IO` is good at this, and I'm familiar with it.

<scala>
#!/usr/bin/env scalas

/***
scalaVersion := "2.11.7"

resolvers += Resolver.typesafeIvyRepo("releases")

libraryDependencies += "org.scala-sbt" % "io" % "0.13.8"
*/

import sbt._, Path._
import java.io.File
import java.net.{URI, URL}
def file(s: String): File = new File(s)
def uri(s: String): URI = new URI(s)

val srcDir = file("./src/")

val fs: Seq[File] = (srcDir ** "*.rst").get
fs foreach { x => println(x.toString) }

</scala> <!-- ***/ -->

`Path` object contains an implicit converter from `File` to `PathFinder`, which implements `**` method. This looks for the file pattern into subdirectories. Here's what you'd see if you run `script.scala`:

    $ ./foo.scala 
    [info] Loading global plugins from /Users/eugene/dotfiles/sbt/0.13/plugins
    [info] Set current project to root-4dcd3aa66723522a07c4 (in build file:/Users/eugene/.conscript/boot/4dcd3aa66723522a07c4/)
    ./src/sphinx/faq.rst
    ./src/sphinx/home.rst
    ./src/sphinx/index.rst
    ....

### rebasing from src to target

Now that we have the list of files, let's try reading the lines from each file and write it out under `target/` directory. This file path manipulation is provided as `Path.rebase`, which returns `File => Option[File]` function.

Reading and writing of lines are called `IO.readLines` and `IO.writeLines` respectively. Here's a script that adds "!" at the end of each line:

<scala>
#!/usr/bin/env scalas

/***
scalaVersion := "2.11.7"

resolvers += Resolver.typesafeIvyRepo("releases")

libraryDependencies += "org.scala-sbt" % "io" % "0.13.8"
*/

import sbt._, Path._
import java.io.File
import java.net.{URI, URL}
import sys.process._
def file(s: String): File = new File(s)
def uri(s: String): URI = new URI(s)

val targetDir = file("./target/")
val srcDir = file("./src/")
val toTarget = rebase(srcDir, targetDir)

def processFile(f: File): Unit = {
  val newParent = toTarget(f.getParentFile) getOrElse {sys.error("wat")}
  val file1 = newParent / f.name
  println(s"""$f => $file1""")
  val xs = IO.readLines(f) map { _ + "!" }
  IO.writeLines(file1, xs)
}

val fs: Seq[File] = (srcDir ** "*.rst").get
fs foreach { processFile }
</scala> <!-- ***/ -->

Here's the output:

    ./src/sphinx/faq.rst => ./target/sphinx/faq.rst
    ./src/sphinx/home.rst => ./target/sphinx/home.rst
    ./src/sphinx/index.rst => ./target/sphinx/index.rst

### purely functional line transformation

Now that we have outer harness to read and write lines, we can focus on the actual task at hand, which is to process each line. This is a function that takes a `String` and returns a `String`.

The reStructuredText files I have contain three interpreted text roles (`doc`, `key`, and `ref`), which are formatted like

    :role:`some text here`

First, construct a pure function generator that removes a single role:

<scala>
def removeRole(role: String): String => String =
  _.replaceAll("""(:""" + role + """:)(\`[^`]+\`)""", """$2""")
</scala> <!--_ -->

Next, chain the functions using `andThen` method on `Function1`:

<scala>
val processRest: String => String =
  removeRole("doc") andThen removeRole("key") andThen removeRole("ref")
</scala>

To unify the single ticks and double ticks, convert all double ticks into single ticks first, and then make them all double ticks.

<scala>
def nTicks(n: Int): String = """(\`{""" + n.toString + """})"""
def toSingleTicks: String => String = 
  _.replaceAll(nTicks(2), "`")
def toDoubleTicks: String => String =
  _.replaceAll(nTicks(1), "``")
val preprocessRest: String => String =
  removeRole("doc") andThen removeRole("key") andThen removeRole("ref") andThen 
  toSingleTicks andThen toDoubleTicks
</scala>

### sys.process

Another common operation in shell scripting is calling other programs. sbt's `Process` was included into the standard library as `sys.process` package. See [`ProcessBuilder`][4] for details.

There's an implicit converter from `Seq[String]` to `ProcessBuilder`, and this provides `lines` method that returns the resulting lines from running the given shell command. For example, here's how to run `pandoc`:

<scala>
def runPandoc(f: File): Seq[String] =
  Seq("pandoc", "-f", "rst", "-t", "markdown", f.toString).lines.toSeq
</scala>

### processing args

One of the motivation to use Scala is to reduce reliance on Unix commands, but in many cases it's desirable to write a script that accepts a list of file names and print the result on stdout so you can test it with a few files files first. In script runner, the arguments are stored in a variable named args` so you can pass that along to `processFile`.

The following is another script that I wrote recently to extract custom `howto` tag.

<scala>
#!/usr/bin/env scalas
 
/***
scalaVersion := "2.11.7"

resolvers += Resolver.typesafeIvyRepo("releases")

libraryDependencies += "org.scala-sbt" % "io" % "0.13.8"
*/

// $ script/extracthowto.scala ../sbt/src/sphinx/Howto/*.rst

import sbt._, Path._
import java.io.File
import java.net.{URI, URL}
def file(s: String): File = new File(s)
def uri(s: String): URI = new URI(s)

/*
A how to tag looks like this:

.. howto::
   :id: unmanaged-base-directory
   :title: Change the default (unmanaged) library directory
   :type: setting

   unmanagedBase := baseDirectory.value / "jars"
*/

def extractId(line: String): String = line.replaceAll(":id:", "").trim
def extractTitle(line: String): String = line.replaceAll(":title:", "").trim

def processLine(num: Int, line1: String, line2: String, line3: String): Option[String] =
  line1 match {
    case x if x.trim == ".. howto::" =>
      Some(s"""<a name="""${extractId(line2)}"></a>
### ${extractTitle(line3)}""")
    case _ => None
  }

def processFile(f: File): Unit = {
  if (!f.exists) sys.error(s"$f does not exist!")

  val lines0: Vector[String] = IO.readLines(f).toVector
  val size = lines0.size
  val xs: Vector[String] = (0 to size - 3).toVector flatMap { i =>
    processLine(i, lines0(i), lines0(i + 1), lines0(i + 2))
  }
  println("-------------------\n")
  println(xs.mkString("\n\n"))
  println("\n")
}

args foreach { x => processFile(file(x)) }
</scala>

### summary

By using sbt's script runner and `IO` module, Scala can be used for statically typed shell scripting. Here's the [gist for the script.scala][5].

