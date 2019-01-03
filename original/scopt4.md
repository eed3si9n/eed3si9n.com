  [scala-options]: https://github.com/aaronharnly/scala-options
  [OptionParser]: http://ruby-doc.org/stdlib-2.0/libdoc/optparse/rdoc/OptionParser.html
  [1]: http://eed3si9n.com/monads-are-fractals
  [github_search]: https://github.com/search?q=%22com.github.scopt%22&type=Code
  [215]: https://github.com/scopt/scopt/issues/215

> scopt is a little command line options parsing library.

I've been working on scopt 4.0 lately. You can skip to the [readme](https://github.com/scopt/scopt), if you're in a hurry.

To try the beta:

<code>
libraryDependencies += "com.github.scopt" %% "scopt" % "4.0.0-RC2"
</code>

scopt started its life in 2008 as [aaronharnly/scala-options][scala-options] based loosely on Ruby's [OptionParser][OptionParser]. scopt 2 added immutable parsing, and scopt 3 cleaned up the number of methods by introducing `Read` typeclass.

### backward source compatibility

According to Sonatype, scopt 3.x was downloaded 370,325 times in November, 2018. On GitHub there are 61,449 matches for seaching ["com.github.scopt"][github_search]. The absolute number might not mean much because of CI and caching, but these are good indication that scopt 3.x has some users. This informs me that I should be aware of the migration cost.

I am introducing a new style of defining options parser in scopt 4, but I am keeping scopt 3 style "object oriented DSL" around:

<scala>
val parser = new scopt.OptionParser[Config]("scopt") {
  head("scopt", "3.x")

  opt[Int]('f', "foo")
    .action((x, c) => c.copy(foo = x))
    .text("foo is an integer property")

  opt[File]('o', "out")
    .required()
    .valueName("<file>")
    .action((x, c) => c.copy(out = x))
    .text("out is a required file property")
}
</scala>

If you have been using scopt 3, and if source compiles, you should be ok.

### composing command line parsers

One of the recurring questions/feature requests for scopt has been allowing an options parser to be composed from smaller parsers. For example [scopt/scopt#215][215]

> I would like to define separate parsers responsible for disjoint sets of options and compose them as needed, for example: I would define one parser per submodule of my project.

In [monads are fractals][1] that I wrote in 2014, I had an idea of making the options parser composable by defining it as a monadic datatype.

### functional DSL

Here's how functional DSL looks like in scopt 4:

<scala>
import scopt.OParser
val builder = OParser.builder[Config]
val parser1 = {
  import builder._
  OParser.sequence(
    programName("scopt"),
    head("scopt", "4.x"),
    // option -f, --foo
    opt[Int]('f', "foo")
      .action((x, c) => c.copy(foo = x))
      .text("foo is an integer property"),
    // more options here...
  )
}

// OParser.parse returns Option[Config]
OParser.parse(parser1, args, Config()) match {
  case Some(config) =>
    // do something
  case _ =>
    // arguments are bad, error message will have been displayed
}
</scala>

Instead of calling methods on `OptionParser`, the functional DSL first creates a builder based on your specific `Config` datatype, and calls `opt[A](...)` functions that returns `OParser[A, Config]`.

These `OParser[A, Config]` parsers can be composed using `OParser.sequence(...)`.

Initially I was thinking about using `for` comprehension to do this composition, but I figured that it might be a bit confusing for those who are unfamiliar with the look.

### composing with OParser.sequence

Here's a demonstration of composing `OParser`s using `OParser.sequence`.

<scala>
import scopt.OParser
val builder = OParser.builder[Config]
import builder._

val p1 =
  OParser.sequence(
    opt[Int]('f', "foo")
      .action((x, c) => c.copy(intValue = x))
      .text("foo is an integer property"),
    opt[Unit]("debug")
      .action((_, c) => c.copy(debug = true))
      .text("debug is a flag")
  )
val p2 =
  OParser.sequence(
    arg[String]("<source>")
      .action((x, c) => c.copy(a = x)),
    arg[String]("<dest>")
      .action((x, c) => c.copy(b = x))
  )
val p3 =
  OParser.sequence(
    head("scopt", "4.x"),
    programName("scopt"),
    p1,
    p2
  )
</scala>

### composing with cmd("...").children(...)

Another way of reusing an `OParser` is passing them into `.children(...)` method of a `cmd("...")` parser.

<scala>
val p4 = {
  import builder._
  OParser.sequence(
    programName("scopt"),
    head("scopt", "4.x"),
    cmd("update")
      .action((x, c) => c.copy(update = true))
      .children(suboptionParser1),
    cmd("status")
      .action((x, c) => c.copy(status = true))
      .children(suboptionParser1)
  )
}
</scala>

In the above, `suboptionParser1` itself would be a `OParser`. This allows common options to be reused between update and status commands.

### composing configuration datatype

`OParser.sequence` gives us the composition of the parsing program, but we are still bound by the same `Config` datatype, which is not ideal since we want different subproject to provide parsers.

Here's a demonstration of how we can split up the `Config` datatype.

<scala>
// provide this in subproject1
trait ConfigLike1[R] {
  def withDebug(value: Boolean): R
}
def parser1[R <: ConfigLike1[R]]: OParser[_, R] = {
  val builder = OParser.builder[R]
  import builder._
  OParser.sequence(
    opt[Unit]("debug").action((_, c) => c.withDebug(true)),
    note("something")
  )
}

// provide this in subproject2
trait ConfigLike2[R] {
  def withVerbose(value: Boolean): R
}
def parser2[R <: ConfigLike2[R]]: OParser[_, R] = {
  val builder = OParser.builder[R]
  import builder._
  OParser.sequence(
    opt[Unit]("verbose").action((_, c) => c.withVerbose(true)),
    note("something else")
  )
}

// compose config datatypes and parsers
case class Config1(debug: Boolean = false, verbose: Boolean = false)
    extends ConfigLike1[Config1]
    with ConfigLike2[Config1] {
  override def withDebug(value: Boolean) = copy(debug = value)
  override def withVerbose(value: Boolean) = copy(verbose = value)
}
val parser3: OParser[_, Config1] = {
  val builder = OParser.builder[Config1]
  import builder._
  OParser.sequence(
    programName("scopt"),
    head("scopt", "4.x"),
    parser1,
    parser2
  )
}
</scala>

In the above example, `parser1` and `parser2` are written against an abstract type `R` that meets type constraint of being a subtype of `ConfigLike1[R]` and `ConfigLike2[R]`. In `parser3`, `R` gets bound to a concrete datatype `Config1`.

### automatic usage generation

As with scopt 3, usage text is generated automatically.

<code>
scopt 4.x
Usage: scopt [update] [options] [<file>...]

  -f, --foo <value>        foo is an integer property
  -o, --out <file>         out is a required file property
  --max:<libname>=<max>    maximum count for <libname>
  -j, --jars <jar1>,<jar2>...
                           jars to include
  --kwargs k1=v1,k2=v2...  other arguments
  --verbose                verbose is a flag
  --help                   prints this usage text
  <file>...                optional unbounded args
some notes.

Command: update [options]
update is a command.
  -nk, --not-keepalive     disable keepalive
  --xyz <value>            xyz is a boolean property
</code>


Try scopt 4, and please [report a bug](https://github.com/scopt/scopt/issues/new) if you find something.
