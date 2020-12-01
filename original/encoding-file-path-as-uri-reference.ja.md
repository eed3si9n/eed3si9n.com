本稿では古くて新しい問題であるファイルパスの Uniform Resource Identifier (URI) へのエンコード方法について議論する。

2017年現在、権威ある情報の元は Matthew Kerwin 氏によって書かれた [RFC 8089 - The "file" URI Scheme][rfc8089] だ。

<blockquote class="twitter-tweet" data-lang="en"><p lang="en" dir="ltr">RFC 8089 The &quot;file&quot; URI Scheme <a href="https://t.co/pAIVmQNzCT">https://tools.ietf.org/html/rfc8089 </a> Wow, it actually happened.</p>&mdash; Matthew Kerwin (@phluid61) <a href="https://twitter.com/phluid61/status/832817027576246272?ref_src=twsrc%5Etfw">February 18, 2017</a></blockquote>

未来の読者の人は "file URI scheme RFC" で検索して最新版を探してほしい。プログラマの人は RFC を読んで下さい。この覚え書きは URI エンコーディングに関連した問題の認識を高めるためのものだが、RFC の代替とはならない。

最近 `file:/foo/bar` がパースできないというプラットフォーム間の相互乗り入れ問題に出くわした。ファイルパスを URI として表現するのに関連した問題に悩まされるのはこれが最初でもない。ファイルシステムという概念は 1960年代に遡り、1990年代から URL があることを考えると、このコンセンサスが取れていないというのは意外なことだ。しかし、十進法小数のように、深く掘り下げたり、データを交換しはじめると、Matrix　のほころびが見えてくるのかもしれない。

### tl;dr

2020年11月現在での実装:

<scala>
import java.io.File
import java.net.{ URI, URISyntaxException }
import java.util.Locale

private val isWindows: Boolean =
  sys.props("os.name").toLowerCase(Locale.ENGLISH).contains("windows")
private final val FileScheme = "file"

/** Converts the given File to a URI.  If the File is relative, the URI is relative, unlike File.toURI*/
def toURI(input: File): URI = {
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
</scala>

### ファイルパスとは何か?

以下は、網羅的なリストではないが、よく使われる OS である macOS、Linux、Windows の大部分をカバーする:

- Unix-like なファイルシステムの絶対パス: `/etc/hosts`
- Unix-like なファイルシステムの相対パス: `../src/main/`
- Windows ファイルシステムの絶対パス: `C:\Documents and Settings\`
- Windows ファイルシステムの相対パス: `..\My Documents\test`
- Windows の UNC パス: `\\laptop\My Documents\Some.doc`

Unix-like なファイルシステムにはホームディレクトリを表す `~` というシンボルもある。

### URI の解剖学

[RFC 3986 3. 構文の構成要素][rfc3986] ([日本語訳](https://triple-underscore.github.io/RFC3986-ja.html#section-3))

> 一般的な URI 構文では、scheme, authority, authority, path, query, fragment と呼ばれる構成要素の階層的なシーケンスから成る。

<code>
 foo://example.com:8042/over/there?name=ferret#nose
 \_/   \______________/\_________/ \_________/ \__/
  |           |            |            |        |
scheme     authority       path        query   fragment
  |   _____________________|__
 / \ /                        \
 urn:example:animal:ferret:nose
</code>

僕たちの場合の scheme は `file` となる。

authority はもう少し聞き慣れた感じの構成要素に分かれる:

<code>
authority   = [ userinfo "@" ] host [ ":" port ]
</code>

僕たちの用途としては、authority は「host」とだいたい同じものだと考えることができるが、URI に関連して "authority これこれ" という感じでよく出てくる用語なので覚えておいたほうがいい。

path 構成要素は authority と query の間のなんでもアリのワイルド・ウエストだ。また、古い用語で scheme の `:` と query の間のことを scheme-specific part と呼ぶ。

### u0 記法

URI に関して話すための略記法として、僕は scheme の `:` の後ろのスラッシュを数えて u0 記法、u1 記法というふうに勝手に呼んでいる。

- u0 記法 `file:foo/bar`
- u1 記法 `file:/foo/bar`
- u2 記法 `file://host/foo/bar`
- u3 記法 `file:///foo/bar`

### URI 参照

「URI」と言った場合多くの場合、URI と相対的参照を含む URI 参照 (URI reference) を指していることがある。例えば、`java.net.URI` は URI 参照を表す。

RFC 3986 [4.2. 相対的参照][relative_reference]は以下のように定義される:

<code>
relative-ref  = relative-part [ "?" query ] [ "#" fragment ]

relative-part = "//" authority path-abempty
              / path-absolute
              / path-noscheme
              / path-empty
</code>

僕たちの用法としては、だいたい URI のパス構成要素部分だと考えてよく、何らかの基底 URI に適用することができる。

### Unix-like なファイルシステムの絶対パス

Unix-like なファイルシステムの絶対パス `/etc/hosts` は、過去と現在の RFC との互換性を最大化するために u3 記法で `file:///etc/hosts` というふうにエンコードされるべきだ。

現行の RFC 8089 は、`/etc/hosts` を u1 記法、u2 記法、u3 記法で書くことを認める。

- `file:/etc/hosts`
- `file://localhost/etc/hosts`
- `file:///etc/hosts`

しかし、問題は RFC 8089 が 2017年2月に出たばっかりで、2017年以前にも多くのプログラムやライブラリが書かれていたことだ。1994年に出た [RFC 1738][rfc1738] は URL を定義し、その中の [3.10 FILES][rfc1738_310] は `file` スキームを

<code>
file://<host>/<path>
</code>

と定義し

> 特殊な例として `<host>` は "localhost" もしくは空の文字列にできる。これは「URL が処理されているマシーンから」として処理される。

と書いてある。つまり、RFC 1738 は u2 記法か u3 記法を要請する。これは RFC 3986 や [Kerwin 2013 Draft][kerwin2013] 内の例でも確認できる。このため、u1 記法を用いてエンコードを行った場合、RFC 8089 的には合法かもしれないが、他のプログラムは正しくパースできないかもしれない。

Scala/Java において残念ながら `java.io.File#toURI` は u1 記法を生成する:

<scala>
scala> import java.io.File

scala> val etcHosts = new File("/etc/hosts")
etcHosts: java.io.File = /etc/hosts

scala> etcHosts.toURI
res1: java.net.URI = file:/etc/hosts
</scala>

回避方法として NIO の `java.nio.file.Path#toUri` を使うことができる:

<scala>
scala> etcHosts.toPath.toUri
res2: java.net.URI = file:///etc/hosts
</scala>

u3 記法は `java.io.File` を使ってラウンドトリップできる:

<scala>
scala> new File(res2)
res3: java.io.File = /etc/hosts
</scala>

u1 と u2 記法も合法な URI なので、処理できるか試してみる:

<scala>
scala> new File(new URI("file:/etc/hosts"))
res4: java.io.File = /etc/hosts

scala> new File(new URI("file://localhost/etc/hosts"))
java.lang.IllegalArgumentException: URI has an authority component
</scala>

### Unix-like なファイルシステムの相対パス

Unix-like なファイルシステムの相対パス (`../src/main/`) は相対的参照を用いて `../src/main` とエンコードする。

上記で言及したように、URI 参照はファイルシステムの相対パス同様に、相対パスを表すことができる。

Scala/Java では、残念ながら `java.nio.file.Path#toUri` はフル URI を生成してしまう:

<scala>
scala> import java.io.File

scala> import java.net.URI

scala> val upSrcMain = new File("../src/main")

scala> upSrcMain.toPath.toUri
res1: java.net.URI = file:///Users/someone/io/../src/main
</scala>

相対パスはこのようにして得ることができる:

<scala>
scala> def toUri_v1(f: File): URI = {
         if (f.isAbsolute) f.toPath.toUri
         else new URI(null, f.getPath, null)
       }

scala> toUri_v1(upSrcMain)
res2: java.net.URI = ../src/main
</scala>

これは妥当な URI 参照だが、`File` コンストラクタを用いてラウンドトリップできなくなった。

<scala>
scala> new File(res2)
java.lang.IllegalArgumentException: URI is not absolute
  at java.io.File.<init>(File.java:416)
</scala>

以下のように回避できる:

<scala>
scala> new File(res2.getSchemeSpecificPart)
res4: java.io.File = ../src/main
</scala>

### Windows ファイルシステムの絶対パス

Windows ファイルシステムの絶対パス (`C:\Documents and Settings\`) は、過去と現在の RFC との互換性を最大化するために u3 記法を用いて `file:///C:/Documents%20and%20Settings/` とエンコードするべきだ。

RFC 1738 の他に、もう一つ興味深いソースがあって、それは Dave Risney 氏による [File URIs in Windows][ieblog2006] というタイトルのブログ記事で、Internet Explorer Team Blog に 2006年に投稿されている。この記事は `C:\Documents and Settings\davris\FileSchemeURIs.doc` は `file:///C:/Documents%20and%20Settings/davris/FileSchemeURIs.doc` とエンコードするべきと明言している。

Scala/Java では、`java.nio.file.Path#toUri` は Windows 上で実行した場合のみ機能する:

<scala>
scala> import java.io.File

scala> val doc = new File("""C:\Documents and Settings\""")
doc: java.io.File = C:\Documents and Settings

scala> doc.toPath.toUri
res3: java.net.URI = file:///C:/Documents%20and%20Settings/
</scala>

3つのスラッシュの他に、バックスラッシュがスラッシュに変換され、空白文字が `%20` に変換されていることにも注意してほしい。

u1 記法、u2 記法も合法な URI なので、処理できるか試してみる:

<scala>
scala> new File(new URI("file:/C:/Documents%20and%20Settings/"))
res4: java.io.File = C:\Documents and Settings

scala> new File(new URI("file://localhost/C:/Documents%20and%20Settings/"))
java.lang.IllegalArgumentException: URI has an authority component
  at java.io.File.<init>(File.java:423)
</scala>

Unix-like なシステム同様、Java は u2 記法が苦手のようだ。

もう一つ記法があって、RFC 8089 の厳密な規定外の参考附属 [Appendix E.2. DOS and Windows Drive Letters][drive_letters] として、u0 記法が挙げられている。

> これは、DOS や　Windows-like な環境におけるローカルファイルの最小記法をサポートすることを目指していて、authoriy フィールドを持たず、ドライブレターから始まる絶対パスを持つ。例えば:

<code>
file:c:/path/to/file
</code>

Windows の絶対パスのために u0 記法を受け入れることができれば、全ての絶対ファイルパスを URI に変換できるエレガントな変換方法を使うことができる: パスをスラッシュ変換したあとで `file:` を前に付けるだけでいい。しかし、これはデフォルトだと動作しない:

<scala>
scala> new File(new URI("file:C:/Documents%20and%20Settings/"))
java.lang.IllegalArgumentException: URI is not hierarchical
  at java.io.File.<init>(File.java:418)
</scala>

以下が回避方法だ:

<scala>
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
</scala>

u0 記法を用いることはナイスな気がするが、Microsoft社からのブログ記事や RFC 1738 との互換性を考慮すると、自分が出力する側だと u3 記法が推奨される。

### Windows ファイルシステムの相対パス

Windows ファイルシステムの相対パス `..\My Documents\test` は相対的参照を用いて `../My%20Documents/test` とエンコードするべきだ。

Scala/Java においては、相対パスのバックスラッシュからスラッシュへの変換を自前でやる必要がある:

<scala>
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
</scala>

`URI#getSchemeSpecificPart` を使って `File` を呼び出す方法は動作する:

<scala>
scala> new File(res9.getSchemeSpecificPart)
res10: java.io.File = ..\My Documents\test
</scala>

### Windows の UNC パス

`\\laptop\My Documents\Some.doc` は u2 記法を用いて `file://laptop/My%20Documents/Some.doc` とエンコードするべきだ。

[File URIs in Windows][ieblog2006] でも `file://laptop/My%20Documents/Some.doc` にエンコードすることに同意している。

Scala/Java では、Windows 上で実行した場合に `java.nio.file.Path#toUri` が動くので先ほど書いた `toUri(...)` をそのまま使える:

<scala>
scala> val unc = new File("""\\laptop\My Documents\Some.doc""")
unc: java.io.File = \\laptop\My Documents\Some.doc

scala> toUri(unc)
res14: java.net.URI = file://laptop/My%20Documents/Some.doc
</scala>

これは `URI#getSchemeSpecificPart` トリックが使える:

<scala>
scala> new File(res14.getSchemeSpecificPart)
res15: java.io.File = \\laptop\My Documents\Some.doc
</scala>

UNC パスを path 構成要素として取り扱って、authority は空であるべきという考えもある。その場合は、u4 記法となる。

<scala>
scala> new File(new URI("file:////laptop/My%20Documents/Some.doc"))
res16: java.io.File = \\laptop\My Documents\Some.doc
</scala>

### 実行時性能の改善

[eed3si9n/sjson-new#117](https://github.com/eed3si9n/sjson-new/pull/117) にて João Ferreira さんが `java.nio.file.Path#toUri` はディレクトリかどうかの判定に `stat` 呼び出しを行うため重いため、Json シリアライゼーションなどでは回避した方がいいと指摘してくれた。

以下は高速化された `toUri` だ:

<scala>
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
</scala>

この実装は Unix-like なファイルシステムの絶対パスは u3 記法を用いる。コードが Linux で実行されても Windows 上で実行されてもこの値に関しては同じように動作するようになっている。

### まとめ

以下がまとめだ。ファイルパスを URI 参照へ変換している場合:

- Unix-like なファイルシステムの絶対パス (`/etc/hosts`): u3 記法を用いる `file:///etc/hosts`
- Unix-like なファイルシステムの相対パス (`../src/main/`): 相対的参照を用いる `../src/main`
- Windows ファイルシステムの絶対パス (`C:\Documents and Settings\`): u3 記法を用いる `file:///C:/Documents%20and%20Settings/`
- Windows ファイルシステムの相対パス (`..\My Documents\test`): 相対的参照を用いる `../My%20Documents/test`
- Windows の UNC パス (`\\laptop\My Documents\Some.doc`): u2 記法を用いる `file://laptop/My%20Documents/Some.doc`

URI 参照からファイルパスへ変換する場合、上記の他に:

- u0 記法を処理する `file:C:/Documents%20and%20Settings/`
- u1 記法を処理する `file:/etc/hosts`
- u2 記法を処理する。`file://localhost/etc/hosts` や `file://localhost/C:/Documents%20and%20Settings/` などのローカルぱす。
- u4 記法を処理する `file:////laptop/My%20Documents/Some.doc`

  [rfc8089]: https://tools.ietf.org/html/rfc8089
  [rfc3986]: https://tools.ietf.org/html/rfc3986#section-3
  [relative_reference]: https://tools.ietf.org/html/rfc3986#section-4.2
  [rfc1738]: https://tools.ietf.org/html/rfc1738
  [rfc1738_310]: https://tools.ietf.org/html/rfc1738#section-3.10
  [kerwin2013]: https://tools.ietf.org/id/draft-kerwin-file-scheme-07.html
  [ieblog2006]: https://blogs.msdn.microsoft.com/ie/2006/12/06/file-uris-in-windows/
  [drive_letters]: https://tools.ietf.org/html/rfc8089#appendix-E.2
