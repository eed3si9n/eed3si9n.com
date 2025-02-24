---
title: "sudori part 7: client-side run with sbt"
type: story
date: 2025-02-17
url: /sudori-part7-client-side-run-with-sbt
tags: [ "sbt" ]
---

  [activator]: https://web.archive.org/web/20140323170739/typesafe.com/activator
  [part4]: /sudori-part4
  [part5]: /sudori-part5
  [sbt-remote-cache]: /sbt-remote-cache
  [sbt-2.0-ideas]: /sbt-2.0-ideas
  [sbt-server-reboot]: /sbt-server-reboot
  [rfc-4]: /rfc-4-persistent-worker

This is a blog post on sbt 2.x development, continuing from [sbt 2.x remote cache][sbt-remote-cache], [sudori part 4][part4], [part 5][part5] etc. I work on sbt 2.x in my own time with collaboration with the Scala Center and other volunteers, like Billy at EngFlow. Lately I've been working on a feature called client-side run, a feature I've thought sbt should have for a long time.

## what is client-side run?

A *client-side run* is an execution of the user-land program initiated at the client-side, without blocking the sbt server. I should probably unpack the details for this to make sense.

sbt is a command-line build tool, much like Maven, Gradle, etc. Until sbt 1.x, sbt was a monolithic, single-process program, which stayed up for the duration of the interactive shell session. Typesafe did attempt [Activator][activator] project around 2013, which had in-browser editor that interacted with an sbt session, but it was too ahead of the time.

In March 2016, I wrote [sbt server reboot][sbt-server-reboot] to revive the idea of sbt server that can provide integration with Play and IntelliJ, built into sbt itself. A few months later, Microsoft announced Language Server Protocol (LSP). Scala Center and JetBrains later proposed Build Server Protocol (BSP) to further cement the idea of a build server.

- In these protocols, a _server_ represents a program that can perform compilation tasks, like a compiler or a build tool.
- A _client_ on the other hand, is an editor like IntelliJ IDEA, VS Code, or sbtn.

In 2020, [Adrien Piquerez](https://www.linkedin.com/in/adrien-piquerez-22b478177/) implemented BSP support for sbt 1.4.0. Also in 2020, Ethan Atkins implemented sbtn, a native client for sbt server using GraalVM native image, which can be started with `--client`. For example:

```bash
sbt --client run
```

In the above, the `run` request is sent to the sbt server via JSON-RPC, and the actual execution of the program takes places on the sbt server. We can call this a _server-side run_. Since sbt was originally designed around human inputs, this `run` blocks any incoming BSP requests.

To use an analogy, sbt server is like a restaurant operated by a single person, who does cooking and serving. sbtn is like a take-out order from the phone, and when a `run` order comes, the chef cooks the food, gets on the bike, and delivers the food to someone's house. During the time, no one can be served.

So again, a *client-side run* is an execution of the user-land program initiated at the client-side, without blocking the sbt server. Using the analogy, the chef just packages the food to go, and someone else comes and delivers the food. If all goes well, most people won't notice the difference.

## details

The PR is at <https://github.com/sbt/sbt/pull/8040>.

### bspGeneral0 input task

We can't just change the behavior of the existing `run` task, so instead I created a new input task called `bspGeneral0`. Some mechanism will call this task as `bspGeneral0 foo/run`. The task will dispatch `foo/Compile/bspGeneralRunInfo` based on the scoping of `foo/run`.

### bspGeneralRunInfo

`bspGeneralRunInfo` does everything that a `run` would need, and copies the files into a sandbox, similar to `bgRun`. Then makes a `sbt/general` notification back to the client program.

```graphql
type RunInfo {
  jvm: Boolean!
  args: [String],
  classpath: [sbt.internal.worker.FilePath],
  mainClass: String
  connectInput: Boolean!
  javaHome: java.net.URI
  outputStrategy: String
  workingDirectory: java.net.URI
  jvmOptions: [String]
  environmentVariables: StringStringMap!
  inputs: [sbt.internal.worker.FilePath] @since("0.1.0"),
  outputs: [sbt.internal.worker.FilePath] @since("0.1.0"),
  cmd: String @since("0.1.0"),
}

## Parameter for the sbt/general command, which is a generic command to
## run a program.
type GeneralParams {
  runInfo: sbt.internal.worker.RunInfo
}
```

### sbtn: onNotification

When sbtn received `sbt/general` notification, it then forks a new JVM process to run the sandboxed program:

```scala
// Scala 2.12 in sbt 1.x code base
case (`general`, Some(json)) =>
  import sbt.internal.worker.codec.JsonProtocol._
  Converter.fromJson[GeneralParams](json) match {
    case Success(params) => generalRun(params).get; Vector.empty
    case Failure(_)      => Vector.empty
  }
```

With these implemented, we now have client-side run using `bspGeneral0` input task.

### taking over the run task

It turned out that the general design of the sbt server hasn't changed much since I wrote [sbt server reboot][sbt-server-reboot], and the server creates a `NetworkChannel` for each sbtn connection and waits for socket communication.

```scala
  // Take over commandline for network channel
  private val networkCommand: PartialFunction[String, String] = {
    case cmd if cmd.split(" ").head.split("/").last == "run" =>
      s"bspGeneral0 $cmd"
  }
  override protected def appendExec(commandLine: String, execId: Option[String]): Boolean =
    if (networkCommand.isDefinedAt(commandLine))
      super.appendExec(networkCommand(commandLine), execId)
    else super.appendExec(commandLine, execId)
```

This allows sbtn to function normally by sending `run` request, but only for the sbt server after some versions it will convert the request to `bspGeneral0 run`.

## motivation and discussion

### sbtn is shared with sbt 2.x

One background information is that sbtn is implemented currently in **sbt 1.x**, but it's used by **both** sbt 1.x and 2.x. With `sbt/general` notification, sbtn gains the ability to launch any program, similar to [genrule](https://bazel.build/reference/be/general#genrule) in Bazel.

This smoothes the sbtn to be the default client on sbt 2.x, and also allows sbt 2.x server to launch the worker proposed in [RFC-4][rfc-4].

### stdout/stdin

Another aspect to consider about running is the standard input and output handling. The programs that sbt runs aren't always "hello world" application. Some of them, for example Scala REPL require the terminal information to display color using ANSI sequence, and use JLine to take over the keyboard input to display history. The server-side run must emulate all of this information over the wire to give the illusion that a program is running with the console access. The client-side run can simplify this.

### isolation and JIT performance

The client-side run is similar to forking implemented at client-side, so it has the similar tradeoff as [forked run](https://www.scala-sbt.org/1.x/docs/Forking.html) in sbt 1.x.

On one hand, it provides your program an isolation from the sbt server. The flip side to the isolation is that it can't take advantage of the warmed JVM, so the startup speed will be slower. Given that `run` is called relatively infrequently, likely the JIT performance isn't a big issue. If we want to retain warmed JVM, that's what [RFC-4][rfc-4] proposes.

### tradeoff

Here's the above tradeoffs summarized into a table:

| feature                    | sbt 1.x | sbt 2.x | availability    | console / stdin | JIT perf | isolation |
|----------------------------|:-------:|:-------:|:----------------:|:---------------:|:--------:|:--------:|
| server-side x              |    ✅   |    ✅  |        ❌        |        ⚠️      |     ✅    |   ❌      |
| client-side x              |    ✅   |    ✅  |        ✅        |        ✅      |     ⚠️    |     ✅    |
| persistent worker (planned)|    ❌   |   ✅   |        ✅        |        ❌      |     ✅    |     ✅    |

So this hopefully clarifies that to improve the sbt server availability, we should go for client-side x (run, console, etc) if the task requires stdin; and try the persistent worker route for performance sensitive tasks like test.
