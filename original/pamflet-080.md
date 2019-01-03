  [1]: http://www.foundweekends.org/pamflet/
  [2]: http://www.foundweekends.org/pamflet/Combined+Pages.md
  [sbt]: https://www.scala-sbt.org/1.x/docs/
  [Gigahorse]: http://eed3si9n.com/gigahorse/
  [contraband]: https://www.scala-sbt.org/contraband/
  [tetrix]: http://eed3si9n.com/tetrix-in-scala/
  [herding]: http://eed3si9n.com/herding-cats/
  [recipes]: http://eed3si9n.com/recipes/

Over the holiday break I've implemented left TOC for Pamflet, and released it as [Pamflet 0.8.0][1].

<img src='/images/pamflet-toc.png' style='width: 100%;'>

Pamflet is a publishing application for short texts, particularly user documentation of open-source software.

It's what I use for [sbt][sbt] docs, [Gigahorse][Gigahorse] docs, [contraband][contraband] docs, [tetrix in Scala][tetrix], and [herding Cats][herding]. I also have a few vegetarian [recipes][recipes] on it.

It has globalization support that I added a while back, so I can publish docs in both English and Japanese, linking one page to the other.

Another cool feature is that it generates a [single page markdown file][2], which can be fed to pandoc to create a PDF file.

Pamflet has long displayed table of contents at the bottom of each page, but starting Pamflet 0.8.0 the toc will be displayed on the left. This can be configured back to `bottom`.

I've also removed the giant clickable regions for page flipping.
