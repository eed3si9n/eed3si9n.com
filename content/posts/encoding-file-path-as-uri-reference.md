---
title:       "encoding file path as URI reference"
type:        story
date:        2017-12-12
changed:     2020-11-27
draft:       false
promote:     true
sticky:      false
url:         /encoding-file-path-as-URI-reference
aliases:     [ /node/245 ]
tags:        [ "scala" ]
---

In this post I am going to discuss an old new problem of encoding file path as Uniform Resource Identifier (URI) reference.

As of 2017, the authoritative source of information is [RFC 8089 - The "file" URI Scheme][rfc8089] written by Matthew Kerwin.

<blockquote class="twitter-tweet" data-lang="en"><p lang="en" dir="ltr">RFC 8089 The &quot;file&quot; URI Scheme <a href="https://t.co/pAIVmQNzCT">https://tools.ietf.org/html/rfc8089 </a> Wow, it actually happened.</p>&mdash; Matthew Kerwin (@phluid61) <a href="https://twitter.com/phluid61/status/832817027576246272?ref_src=twsrc%5Etfw">February 18, 2017</a></blockquote>

Future readers might also want to search for "file URI scheme RFC", and find the latest version. If you're a programmer, read the RFC. This post is to raise the awareness of the some of the issues around file to URI encoding, but it's not a substitution.

Recently I've been running into interop problems as some platforms are unable to parse `file:/foo/bar`. But this is not the first time I'm having trouble with file path represented as URI. Considering that the notion of filesystem goes back to 1960s, and URL has been around since 1990s, it's surprising that we haven't come to a concensus on this. But then again, like decimal numbers, once you start digging deeper, or start exchanging data, we find some glitches in the Matrix.

### tl;dr

Here's the implementation I use as of November, 2020:

```scala
import java.io.File
import java.net.{ URI, URISyntaxException }
import java.util.Locale

private val isWindows: Boolean =
  sys.props("os.name").toLowerCase(Locale.ENGLISH).contains("windows")
private final val FileScheme = "file"

/** Converts the given File to a URI. If the File is relative, the URI is relative, unlike File.toURI*/
def toUri(input: File): URI = {
  def ensureHeadSlash(name: String) =
    if (name.nonEmpty && name.head != File.separatorChar) File.separatorChar.toString + name
    else name
  def normalizeToSlash(name: String) =
    if (File.separatorChar == '/') name
    else name.replace(File.separatorChar, '/')

  val p = input.getPath
  if (isWindows && p.nonEmpty && p.head == File.separatorChar)
    if (p.startsWith("""\\""")) new URI(FileScheme, normalizeToSlash(p), null)
    else new URI(FileScheme, "", normalizeToSlash(p), null)
  else if (input.isAbsolute)
    new URI(FileScheme, "", normalizeToSlash(ensureHeadSlash(input.getAbsolutePath)), null)
  else new URI(null, normalizeToSlash(p), null)
}

/** Converts the given URI to a File. */
def toFile(uri: URI): File =
  try {
    val part = uri.getSchemeSpecificPart
    if (uri.getScheme == null || uri.getScheme == FileScheme) ()
    else sys.error(s"Expected protocol to be '$FileScheme' or empty in URI $uri")
    Option(uri.getAuthority) match {
      case None if part startsWith "/" => new File(uri)
      case _                           =>
        if (!(part startsWith "/") && (part contains ":")) new File("//" + part)
        else new File(part)
    }
  } catch { case _: URISyntaxException => new File(uri.getPath) }
```

### what are file paths?

The following is by no means an exhaustive list, but it covers much of the path that we come across on popular operating systems like macOS, Linux, and Windows:

- Absolute paths on Unix-like filesystem: `/etc/hosts`
- Relative paths on Unix-like filesystem: `../src/main/`
- Absolute paths on Windows filesystem: `C:\Documents and Settings\`
- Relative paths on Windows filesystem: `..\My Documents\test`
- UNC paths on Windows: `\\laptop\My Documents\Some.doc`

On Unix-like filesystem, there's also home directory symbol `~`.

### anatomy of URI

[RFC 3986 3. Syntax Components][rfc3986]

> The generic URI syntax consists of a hierarchical sequence of components referred to as the scheme, authority, path, query, and fragment.

```bash
 foo://example.com:8042/over/there?name=ferret#nose
 \_/   \______________/\_________/ \_________/ \__/
  |           |            |            |        |
scheme     authority       path        query   fragment
  |   _____________________|__
 / \ /                        \
 urn:example:animal:ferret:nose
```

The *scheme* in our case will be `file`.

The *authority* breaks down to more familar components:

```bash
authority   = [ userinfo "@" ] host [ ":" port ]
```

For our purpose, authority mostly equals to "host," but it's good to learn this term because you hear a lot of "authority this" and "authority that" when discussing URIs.

The path component is the wild west between authority and query. In an old terminology, the string between scheme's `:` and query is called *scheme-specific part*.

### u0 notation

As a shorthand for discussing URIs, I count the number of slashes after the scheme `:`, and call them u0 notation, u1 notation etc.

- u0 notation `file:foo/bar`
- u1 notation `file:/foo/bar`
- u2 notation `file://host/foo/bar`
- u3 notation `file:///foo/bar`

### URI reference

When we say "URI", we often mean URI reference that includes both a URI or a relative reference. For example, `java.net.URI` represents URI reference.

[4.2. Relative Reference][relative_reference] is defined by RFC 3986 as follows:

```bash
relative-ref  = relative-part [ "?" query ] [ "#" fragment ]

relative-part = "//" authority path-abempty
              / path-absolute
              / path-noscheme
              / path-empty
```

For our purpose, we can think of it as mostly as the path component of the URI, which then gets applied to some target URI.

### absolute paths from Unix-like filesystem

An absolute path from Unix-like filesystem `/etc/hosts` should be encoded using u3 notation `file:///etc/hosts` to maximize compatibility with current and previous RFCs.

Current RFC 8089 allows `/etc/hosts` to be encoded in u1, u2, and u3 notations.

- `file:/etc/hosts`
- `file://localhost/etc/hosts`
- `file:///etc/hosts`

But the problem is that RFC 8089 came out in Februrary 2017, and there has been plenty of programs and libraries written priror to 2017. [RFC 1738][rfc1738] that came out in 1994 defines URL, and [3.10 FILES][rfc1738_310] defines the `file` scheme as

```bash
file://<host>/<path>
```

and

> As a special case, `<host>` can be the string "localhost" or the empty string; this is interpreted as 'the machine from which the URL is being interpreted'.

In other words, RFC 1738 requires u2 notation or u3 notation. This is further confirmed in RFC 3986 and [Kerwin 2013 Draft][kerwin2013] examples. So if we encode using u1 notation, it might be legal for RFC 8089, but other programs may not be able to parse it correctly.

In Scala/Java, `java.io.File#toURI` unfortunately produces u1:

```scala
scala> import java.io.File

scala> val etcHosts = new File("/etc/hosts")
etcHosts: java.io.File = /etc/hosts

scala> etcHosts.toURI
res1: java.net.URI = file:/etc/hosts
```

A workaround is to use NIO's `java.nio.file.Path#toUri`:

```scala
scala> etcHosts.toPath.toUri
res2: java.net.URI = file:///etc/hosts
```

u3 notation can roundtrip back to `java.io.File` fine:

```scala
scala> new File(res2)
res3: java.io.File = /etc/hosts
```

Since u1 and u2 are also legal URI, let's see if they are handled:

```scala
scala> new File(new URI("file:/etc/hosts"))
res4: java.io.File = /etc/hosts

scala> new File(new URI("file://localhost/etc/hosts"))
java.lang.IllegalArgumentException: URI has an authority component
```

### relative path from Unix-like filesystem

A relative path from Unix-like filesystem `../src/main/` should be encoded using relative reference `../src/main`.

As noted previously, URI reference is able to express a relative path, similar to the relative path on filesystems.

In Scala/Java, `java.nio.file.Path#toUri` unfortunately produces full URI:

```scala
scala> import java.io.File

scala> import java.net.URI

scala> val upSrcMain = new File("../src/main")

scala> upSrcMain.toPath.toUri
res1: java.net.URI = file:///Users/someone/io/../src/main
```

Here's how to get a relative path:

```scala
scala> def toUri_v1(f: File): URI = {
         if (f.isAbsolute) f.toPath.toUri
         else new URI(null, f.getPath, null)
       }

scala> toUri_v1(upSrcMain)
res2: java.net.URI = ../src/main
```

This is a valid URI reference, but now it will not round trip using `File` constructor.

```scala
scala> new File(res2)
java.lang.IllegalArgumentException: URI is not absolute
  at java.io.File.<init>(File.java:416)
```

Here's a workaround:

```scala
scala> new File(res2.getSchemeSpecificPart)
res4: java.io.File = ../src/main
```

### absolute path on Windows filesystem

An absolute path on Windows filesystem `C:\Documents and Settings\` should be encoded using u3 notation `file:///C:/Documents%20and%20Settings/` to maximize compatibility with current and previous RFCs.

In addition to RFC 1738, there's another interesting source which is a post titled [File URIs in Windows][ieblog2006] written by Dave Risney for Internet Explorer Team Blog in 2006. This post states `C:\Documents and Settings\davris\FileSchemeURIs.doc` should be encoded as `file:///C:/Documents%20and%20Settings/davris/FileSchemeURIs.doc`.

In Scala/Java, `java.nio.file.Path#toUri` works only when you run it on Windows:

```scala
scala> import java.io.File

scala> val doc = new File("""C:\Documents and Settings\""")
doc: java.io.File = C:\Documents and Settings

scala> doc.toPath.toUri
res3: java.net.URI = file:///C:/Documents%20and%20Settings/
```

In addition to the 3 slashes, note that backslash is converted to slash, and that whitespace is denoted using percent notation `%20`.

Since u1 and u2 are also legal URI, let's see if they are handled:

```scala
scala> new File(new URI("file:/C:/Documents%20and%20Settings/"))
res4: java.io.File = C:\Documents and Settings

scala> new File(new URI("file://localhost/C:/Documents%20and%20Settings/"))
java.lang.IllegalArgumentException: URI has an authority component
  at java.io.File.<init>(File.java:423)
```

Just like Unix-like systems, Java doesn't handle u2 notation.

Another notation that is mentioned in the non-normative [Appendix E.2. DOS and Windows Drive Letters][drive_letters] of RFC 8089 is u0 notation.

> This is intended to support the minimal representation of a local file in a DOS- or Windows-like environment, with no authority field and an absolute path that begins with a drive letter. For example:

```bash
file:c:/path/to/file
```

Accomodating u0 notation for Windows absolute path opens the door to an elegant conversion from any absolute file path to URI: just prepend `file:` in front of the path after slash conversion. But this does not work by default:

```scala
scala> new File(new URI("file:C:/Documents%20and%20Settings/"))
java.lang.IllegalArgumentException: URI is not hierarchical
  at java.io.File.<init>(File.java:418)
```

Here's a workaround:

```scala
scala> def toFile(uri: URI): File = {
        assert(
           Option(uri.getScheme) match {
             case None | Some("file") => true
             case _                   => false
           },
           s"Expected protocol to be 'file' or empty in URI $uri"
         )
         val part = uri.getSchemeSpecificPart
         if (!(part startsWith "/") && (part contains ":")) new File("///" + part)
         else new File(part)
       }

scala> toFile(new URI("file:C:/Documents%20and%20Settings/"))
res6: java.io.File = C:\Documents and Settings
```

Even though using u0 notation has a nice property, given the blog post by Microsoft and backward compatibility with RFC 1738, if you are on the emitting side, u3 notation is recommended.

### relative path on Windows filesystem

A relative path on Windows filesystem `..\My Documents\test` should be encoded using relative reference `../My%20Documents/test`.

In Scala/Java, we need to convert the backslash to slash manually for the relative path.

```scala
scala> val upDocsTest = new File("""..\My Documents\test""")
upDocsTest: java.io.File = ..\My Documents\test

scala> def toUri(f: File): URI = {
         if (f.isAbsolute) f.toPath.toUri
         else {
           val sep = File.separatorChar
           val slashPath = if (sep == '/') f.getPath
                           else f.getPath.replace(sep, '/')
           new URI(null, slashPath, null)
         }
       }

scala> toUri(upDocsTest)
res9: java.net.URI = ../My%20Documents/test
```

calling `File` with `URI#getSchemeSpecificPart` works:

```scala
scala> new File(res9.getSchemeSpecificPart)
res10: java.io.File = ..\My Documents\test
```

### UNC path on Windows filesystem

A UNC paths on Windows `\\laptop\My Documents\Some.doc` should be encoded using u2 notation `file://laptop/My%20Documents/Some.doc`.

[File URIs in Windows][ieblog2006] post also agrees that it should be encoded as `file://laptop/My%20Documents/Some.doc`.

In Scala/Java, `java.nio.file.Path#toUri` works while on Windows, so we can use `toUri(...)` that we wrote earlier:

```scala
scala> val unc = new File("""\\laptop\My Documents\Some.doc""")
unc: java.io.File = \\laptop\My Documents\Some.doc

scala> toUri(unc)
res14: java.net.URI = file://laptop/My%20Documents/Some.doc
```

This also roundtrips using `URI#getSchemeSpecificPart` trick:

```scala
scala> new File(res14.getSchemeSpecificPart)
res15: java.io.File = \\laptop\My Documents\Some.doc
```

Another school of thought is to treat UNC path as path component of URI, and keep the authority blank. This will result to u4 notation.

```scala
scala> new File(new URI("file:////laptop/My%20Documents/Some.doc"))
res16: java.io.File = \\laptop\My Documents\Some.doc
```

### Improving runtime performance

In [eed3si9n/sjson-new#117](https://github.com/eed3si9n/sjson-new/pull/117) João Ferreira pointed out that `java.nio.file.Path#toUri` is expensive because it calls `stat` to check if the path is a directory or not, and thus it should be avoided during Json serialization.

Here's the new `toUri` that's faster:

```scala
scala> import java.io.File
       import java.net.{ URI, URISyntaxException }
       import java.util.Locale

scala> val isWindows: Boolean =
         sys.props("os.name").toLowerCase(Locale.ENGLISH).contains("windows")

scala> final val FileScheme = "file"

scala> def toUri(input: File): URI = {
         def ensureHeadSlash(name: String) =
           if (name.nonEmpty && name.head != File.separatorChar) File.separatorChar.toString + name
           else name
         def normalizeToSlash(name: String) =
           if (File.separatorChar == '/') name
           else name.replace(File.separatorChar, '/')
      
         val p = input.getPath
         if (isWindows && p.nonEmpty && p.head == File.separatorChar)
           if (p.startsWith("""\\""")) new URI(FileScheme, normalizeToSlash(p), null)
           else new URI(FileScheme, "", normalizeToSlash(p), null)
         else if (input.isAbsolute)
           new URI(FileScheme, "", normalizeToSlash(ensureHeadSlash(input.getAbsolutePath)), null)
         else new URI(null, normalizeToSlash(p), null)
       }

scala> val etcHosts = new File("/etc/hosts")

scala> toURI(etcHosts)
val res0: java.net.URI = file:///etc/hosts
```

This implementation will use u3 notation for absolute paths from Unix-like filesystem. Note that this will hold whether the code is run on Linux or Windows.

### summary

Here's the summary. If you are converting from a file path to a URI reference:

- Absolute paths from Unix-like filesystem (`/etc/hosts`): Use u3 notation `file:///etc/hosts`
- Relative paths from Unix-like filesystem (`../src/main/`): Use relative reference `../src/main`
- Absolute paths from Windows filesystem (`C:\Documents and Settings\`): Use u3 notation `file:///C:/Documents%20and%20Settings/`
- Relative paths from Windows filesystem (`..\My Documents\test`): Use relative reference `../My%20Documents/test`
- UNC paths from Windows (`\\laptop\My Documents\Some.doc`): Use u2 notation `file://laptop/My%20Documents/Some.doc`

If you are converting from a URI reference to a file path, in addition to the above,

- Handle u0 notation `file:C:/Documents%20and%20Settings/`
- Handle u1 notation `file:/etc/hosts`
- Handle u2 notation `file://localhost/etc/hosts` and `file://localhost/C:/Documents%20and%20Settings/` for local path
- Handle u4 notation `file:////laptop/My%20Documents/Some.doc`

  [rfc8089]: https://tools.ietf.org/html/rfc8089
  [rfc3986]: https://tools.ietf.org/html/rfc3986#section-3
  [relative_reference]: https://tools.ietf.org/html/rfc3986#section-4.2
  [rfc1738]: https://tools.ietf.org/html/rfc1738
  [rfc1738_310]: https://tools.ietf.org/html/rfc1738#section-3.10
  [kerwin2013]: https://tools.ietf.org/id/draft-kerwin-file-scheme-07.html
  [ieblog2006]: https://blogs.msdn.microsoft.com/ie/2006/12/06/file-uris-in-windows/
  [drive_letters]: https://tools.ietf.org/html/rfc8089#appendix-E.2
