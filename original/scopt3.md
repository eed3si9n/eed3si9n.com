> scopt is a little command line options parsing library.

Today, I'm releasing scopt 3.0. If you're not interested in the implementation details, skip to the [readme](https://github.com/scopt/scopt).

Around March 4th, 2010, I became a committer to scopt, a fork of Aaron Harnly's scala-options that was written in 2008. I think I wanted to make a few changes around the usage text, key=value options, and argument list. Since then I've been fielding all the bug reports, including the request to publish the jar on scala-tools.org. On March 18, 2012, I forked the project again to [scopt/scopt](https://github.com/scopt/scopt) and released scopt 2.0.0 that added immutable parser.

After years of adding features on top of the other, I decided to rewrite scopt3 from scratch. The tipping point was Leif Wickland asking if there's a ["philosophical reason that scopt doesn't have an `intArg()`."](https://twitter.com/leifwickland/status/339790970931523586).

Inspired by Ruby's [OptionParser](http://ruby-doc.org/stdlib-2.0/libdoc/optparse/rdoc/OptionParser.html), Aaron's original scala-options had 5 methods for options: `onInt`, `onDouble`, `onBoolean`, `on`, and another overload of `on`. Over the course of its development, scopt2 has accumulated 6 overloads of `opt` method, 4 each of `intOpt`, `doubleOpt`, `booleanOpt`, `keyValueOpt`, `keyIntValueOpt`, `keyDoubleValueOpt`, and `keyBooleanValueOpt`. That's total of 34 methods! I have no one else to blame for this but myself since overloads were added by me to support optional parameters like optional short names and value names. I couldn't bare the thought of more expansion.

### adhoc polymorphism with Read

Something that's been bugging me was the code duplication for each data type of options that it supports like `Int` and `String`. This is working around the fact that `String => Unit` and `Int => Unit` cannot be distinguished after type erasure.

Instead of duplicating the code, adhoc polymorphism using `Read` typeclass can at least express the implemtation in one shot. From the user's point of view, `opt[Int]` I think is cleaner than `intOpt`.

After commenting out all the code, I started with `Read`:

<scala>
trait Read[A] {
  def reads: String => A
}

object Read {
  def reads[A](f: String => A): Read[A] = new Read[A] {
    val reads = f
  }

  implicit val intRead: Read[Int]             = reads { _.toInt }
  implicit val stringRead: Read[String]       = reads { identity }
  implicit val doubleRead: Read[Double]       = reads { _.toDouble }
  implicit val booleanRead: Read[Boolean]     =
    reads { _.toLowerCase match {
      case "true"  => true
      case "false" => false
      case "yes"   => true
      case "no"    => false
      case "1"     => true
      case "0"     => false
      case s       =>
        throw new IllegalArgumentException("'" + s + "' is not a boolean.")
    }}
}
</scala>

This a typeclass expressing the ability to convert from `String`. Using this, I replaced all data type specific case classes with this generic one.

<scala>
class OptionDef[A: Read, C]() {
  ...  
}
</scala>

### fluent interface

To address the overloading caused by optional arguments, I implemented a fluent interface on `OptionDef` class. The parser would provide minimal methods to get started.

<scala>
  /** adds an option invoked by `--name x`.
   * @param name name of the option
   */
  def opt[A: Read](name: String): OptionDef[A, C] = makeDef(Opt, name)

  /** adds an option invoked by `-x value` or `--name value`.
   * @param x name of the short option
   * @param name name of the option
   */
  def opt[A: Read](x: Char, name: String): OptionDef[A, C] =
    opt[A](name) shortOpt(x)
</scala>

The parameter type for the short option was changed from `String` to `Char` to support grouping (`-la` is interpretted as `-l -a` for plain flags). The rest of the parameters like the callbacks and desctiption can be passed in later as methods on `OptionDef`:

<scala>
  opt[Int]("foo") action { (x, c) =>
    c.copy(foo = x) } text("foo is an integer property")
  opt[File]('o', "out") valueName("<file>") action { (x, c) =>
    c.copy(out = x) } text("out is a string property")
</scala>

In the above `text("...")` and `action {...}` are both methods on `OptionDef[A, C]` that returns another `OptionDef[A, C]`:

<scala>
  /** Adds description in the usage text. */
  def text(x: String): OptionDef[A, C] =
    _parser.updateOption(copy(_desc = x))
  /** Adds value name used in the usage text. */
  def valueName(x: String): OptionDef[A, C] =
    _parser.updateOption(copy(_valueName = Some(x)))
</scala>

Using `Read` and fluent interface, 34 methods were reduced to just two overloads. This is much easier to remember as an API. More importantly, the resulting usage code easier to guess for someone who is reading it for the first time.

### deriving Read instances from other instances

A powerful aspect of typeclass is that you can define an abstract instance that derives an instance using existing instances. Key=value instance is implemented as a pair of two `Read` instances as follows:

<scala>
  implicit def tupleRead[A1: Read, A2: Read]: Read[(A1, A2)] = new Read[(A1, A2)] {
    val arity = 2
    val reads = { (s: String) =>
      splitKeyValue(s) match {
        case (k, v) => implicitly[Read[A1]].reads(k) -> implicitly[Read[A2]].reads(v)
      }
    }
  } 
  private def splitKeyValue(s: String): (String, String) =
    s.indexOf('=') match {
      case -1     => throw new IllegalArgumentException("Expected a key=value pair")
      case n: Int => (s.slice(0, n), s.slice(n + 1, s.length))
    }
</scala>

Now not only this can parse `String=Int` as scopt2, it can parse `Int=Boolean` etc. Here's a usage example.

<scala>
  opt[(String, Int)]("max") action { case ((k, v), c) =>
    c.copy(libName = k, maxCount = v) } validate { x =>
    if (x._2 > 0) success else failure("Value <max> must be >0") 
  } keyValueName("<libname>", "<max>") text("maximum count for <libname>")
</scala>

### more Read

Since the API footprint is not going to expand for each datatype, I've added more data types: `Long`, `BigInt`, `BigDecimal`, `Calendar`, `File`, and `URI`.

`Read` was modified a bit to support plain flags that do not take any values as `opt[Unit]`("verbose"):

<scala>
  implicit val unitRead: Read[Unit] = new Read[Unit] {
    val arity = 0
    val reads = { (s: String) => () }
  }
</scala>

### specs2 2.0 (RC-1)

You don't want to fly blind when you rewrite a library. scopt3 has more lines in specs2 2.0 specs than the code itself. The newly added [string interpolation](http://etorreborre.blogspot.com.au/2013/05/the-latest-release-of-specs2-2.html) makes it much easier to write acceptance specs. Here's an excerpt from the [ImmutableParserSpec](https://github.com/scopt/scopt/blob/94b35beb4b9586d9200ec6577bfdf9cd5e9e28a9/src/test/scala/scopt/ImmutableParserSpec.scala):

<scala>
class ImmutableParserSpec extends Specification { def is =      s2"""
  This is a specification to check the immutable parser
  
  opt[Int]('f', "foo") action { x => x } should
    parse 1 out of --foo 1                                      ${intParser("--foo", "1")}
    parse 1 out of --foo:1                                      ${intParser("--foo:1")}
    parse 1 out of -f 1                                         ${intParser("-f", "1")}
    parse 1 out of -f:1                                         ${intParser("-f:1")}
    fail to parse --foo                                         ${intParserFail{"--foo"}}
    fail to parse --foo bar                                     ${intParserFail("--foo", "bar")}
                                                                """

  val intParser1 = new scopt.OptionParser[Config]("scopt") {
    head("scopt", "3.x")
    opt[Int]('f', "foo") action { (x, c) => c.copy(intValue = x) }
  }
  def intParser(args: String*) = {
    val result = intParser1.parse(args.toSeq, Config())
    result.get.intValue === 1
  }
  def intParserFail(args: String*) = {
    val result = intParser1.parse(args.toSeq, Config())
    result === None
  }
</scala>

### occurrences

With `Read` in place, polymorphic arguments came almost automatically. `arg[File]("<out>")` parses a `File`, and `arg[Int]("<port>")` parses an `Int`.

scopt2 implemented four variations of arguments: `arg`, `argOpt`, `arglist`, and `arglistOpt`. To reduce the API footprint, scopt3 just implements `arg[A: Read](name: String): OptionDef[A, C]`, and supports the others using fluent-style methods `def minOccurs(n: Int)` and `def maxOccurs(n: Int)`. Using these, "syntactic sugars" are provided to the DSL:

<scala>
  /** Requires the option to appear at least once. */
  def required(): OptionDef[A, C] = minOccurs(1)
  /** Chanages the option to be optional. */
  def optional(): OptionDef[A, C] = minOccurs(0)
  /** Allows the argument to appear multiple times. */
  def unbounded(): OptionDef[A, C] = maxOccurs(UNBOUNDED)
</scala>

As the result, scopt3 supports not only optional argument lists, but also required options:

<scala>
opt[String]('o', "out") required()
arg[String]("<file>...") optional() unbounded()
</scala>

### custom validation

Expanding the fluent interface, scopt3 also adds custom validation:

<scala>
opt[Int]('f', "foo") action { (x, c) => c.copy(intValue = x) } validate { x =>
  if (x > 0) success else failure("Option --foo must be >0") } validate { x =>
  failure("Just because") }
</scala>

Multiple validation clauses are all evaluated, and recognized as successful only when all evaluates to `success`.

### unification of immutable and mutable parser

In scopt2, the implementation was split into three packages: `generic`, `immutable`, and `mutable`. I kept up the same structure for a while, but it became harder for me to justify having two parser implementations. The point of the immutable parser is to provide immutable usage of the parser. That does not mean that the implementation of the parser needs to be immutable.

In scopt3, immutable parsing is supported using `action` method:

<scala>
opt[Int]('f', "foo") action { (x, c) =>
  c.copy(foo = x) } text("foo is an integer property")
</scala>

and mutable parsing is support using `foreach` method:

<scala>
opt[Int]('f', "foo") foreach { x =>
  c = c.copy(foo = x) } text("foo is an integer property")
</scala>

The internal structure is unified to the mutable parser. It's a bit of a compromise, but it's better than having two DSL cakes that are slightly different in semantics.

### commands

One of the motivating factor to unify the parsers was the addition on commands. This is a feature to allow something like `git [commit|push|pull]` where the name of the argument means something, and could enable series of options based on it.

<scala>
cmd("update") action { (_, c) =>
  c.copy(mode = "update") } text("update is a command.") children {
  opt[Boolean]("xyz") action { (x, c) =>
    c.copy(xyz = x) } text("xyz is a boolean property")
}
</scala>

As scopt3 progressed, I got many useful feedback from Leif in the form of tweets and commit comments. For example [efe45ed](https://github.com/scopt/scopt/commit/efe45ed99fbc8ceecde4eb0c6f000f7802b8fee1#commitcomment-3352444):

> One problem with the way you've defined Cmd is that it's not positional. The parser wants to find an argument with cmd's name anywhere in the line. That leads to ambiguities if there are optional (or unbounded) arguments in the definition of the parser's options. [...]

After considering this, the command was changed so it's only valid as the first argument within the level, and all other commands are cleared as soon as a command, an option, or an argument is hit.

### putting it all together

Here's an example of how to use scopt3:

<scala>
val parser = new scopt.OptionParser[Config]("scopt") {
  head("scopt", "3.x")
  opt[Int]('f', "foo") action { (x, c) =>
    c.copy(foo = x) } text("foo is an integer property")
  opt[File]('o', "out") required() valueName("<file>") action { (x, c) =>
    c.copy(out = x) } text("out is a required file property")
  opt[(String, Int)]("max") action { case ((k, v), c) =>
    c.copy(libName = k, maxCount = v) } validate { x =>
    if (x._2 > 0) success else failure("Value <max> must be >0") 
  } keyValueName("<libname>", "<max>") text("maximum count for <libname>")
  opt[Unit]("verbose") action { (_, c) =>
    c.copy(verbose = true) } text("verbose is a flag")
  note("some notes.\n")
  help("help") text("prints this usage text")
  arg[File]("<file>...") unbounded() optional() action { (x, c) =>
    c.copy(files = c.files :+ x) } text("optional unbounded args")
  cmd("update") action { (_, c) =>
    c.copy(mode = "update") } text("update is a command.") children {
    opt[Boolean]("xyz") action { (x, c) =>
      c.copy(xyz = x) } text("xyz is a boolean property")
  }
}
// parser.parse returns Option[C]
parser.parse(args, Config()) map { config =>
  // do stuff
} getOrElse {
  // arguments are bad, usage message will have been displayed
}
</scala>

As with scopt2, this automatically generates usage text:

<code>
scopt 3.x
Usage: scopt [update] [options] [<file>...]

  -f <value> | --foo <value>
        foo is an integer property
  -o <file> | --out <file>
        out is a required file property
  --max:<libname>=<max>
        maximum count for <libname>
  --verbose
        verbose is a flag
some notes.

  --help
        prints this usage text
  <file>...
        optional unbounded args

Command: update
update is a command.

  --xyz <value>
        xyz is a boolean property
</code>

Feel free to open [a github issue](https://github.com/scopt/scopt/issues/new) for bugs and questions.
