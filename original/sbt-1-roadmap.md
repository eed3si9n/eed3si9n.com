There’s been some discussions around sbt 1.0 lately, so here is a writeup to discuss it. This document is intended to be a mid-term mission statement. A refocus to get something out. Please post on [sbt-dev mailing list](https://groups.google.com/d/msg/sbt-dev/PoR7n1ZV_i4/L-Jg6AAABwAJ) for feedback.

### Timing

I don’t have a good idea on the timing of when sbt 1.0 will ship.
The biggest feature of sbt 1.0 is code reorganization, which is is already in progress:
http://www.scala-sbt.org/0.13/docs/Modularization.html

There’s sbt/io, sbt/util, sbt/librarymanagement, sbt/incrementalcompiler already. Given that the incremental compiler is probably the most complex aspect of sbt at least in terms of implementation, that has been our focus on modularization. When we’re comfortable with all the module APIs being stable, that’s when we can put 1.0 on sbt itself.

### Motivation for modularization

Current codebase of sbt/sbt exposes too much inners to the build user and plugin authors. This makes the code harder to learn. This also makes it harder to maintain binary compatibility.
The goal of the modularization is to clarify the boundary of what’s public API and what’s private implementation.

We are going to have these modules available on Maven Central instead of an Ivy repo.

### sbt/incrementalcompiler

The new incrementalcompiler will be based completely on named hashing, which has been turned on by default for a while now (sbt 0.13.6). Not only that it will use the class-based name hashing, which is showing good performance improvements.

### Java version

sbt 0.13 is on JDK 6. sbt 1.0 will be based on JDK 8.


### sbt-archetype

sbt-archetype is a concept proposed by Jim Powers. The idea is to add “new” command to sbt similar to that of Activator. It will be a pluggable backend like `templateResolvers` setting so the source of the template can be configured to Activator Template, Github, private repository etc.

### sbt Server

This is another aspect of sbt 1.0. The motivation for sbt server is better IDE integration. All IDEs should be able to communicate tasks and commands to sbt so the semantics of the build, including plugins and library dependencies are kept in one place only.

There are legitimate concerns over the stability on splitting sbt into two JVM processes. Auto-starting and auto discovery also adds complication.

We should avoid over-engineering around this area, and focus on the common use cases first such as:

- switch subproject
- compile Scala application and getting errors and warnings if any, from the IDE
- run Play application from the IDE
- run unit tests from the IDE
- accept text commands

For user who are not interested in IDE integration, typing "sbt" command should operate as before with single JVM process. We can do away with auto-starting by requiring the user to specify a port number and manually starting sbt. A reboot of sbt server command to follow up soon.

### Rethinking serialization

One of the assumptions that we made early on is that we need to fly all setting keys across the wire, and that includes setting keys defined by the plugins. This assumption skewed the decision to pick Scala pickling for the serialization since it promised schemaless “automatic” conversion from any Java or Scala class to customizable format including JSON. 

On Java, what was promised to be automatic conversion turned out to be guesses based on method that starts with the string “get” and “set”. This resulted in bizarre behavior such as incorrectly storing types such as `java.io.File` and `java.lang.Byte` as an empty value, or for `org.joda.time.LocalDate`, it will store some fields but not the other.

In reality, however, most of the interaction regarding sbt will be textual, and thus does not require datatypes to fly over the wire. For example, to use sbt-assembly the user on sbt shell just needs to type in “assembly”. The progression of the task can be observed via logs, but the result is almost never needed directly to the user who is typing into the shell. (Note this is different from using the value from the custom task in build.sbt)
We do have some use cases that transitioned from using sbinary to Scala Pickling that worked out, so we will have to come up with a replacement for both, if possible.

Some of the candidates to consider:

- use some JSON library (which one?) + hand-written formats
- use some JSON library + sbt-datatype to generate formats or tuple isomorphism

### NIO

Once we are committed to JDK 8, we can move some of the custom Path and globbing code in sbt/io to use NIO. http://docs.oracle.com/javase/tutorial/essential/io/index.html 

### Network API

Network API is a hypothetical module of sbt that provides HTTP client service. https://github.com/sbt/sbt/issues/2189
The behavior of download is really inefficient in sbt 0.13, and we might be able to improve connection pooling or client-side redirection.
This is something we can define the API up front and improve later.

