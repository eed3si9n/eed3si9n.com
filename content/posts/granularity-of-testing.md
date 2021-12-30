---
title:       "granularity of testing"
type:        story
date:        2021-12-31
draft:       false
url:         /granularity-of-testing
tags:        [ "sbt" ]
---

In the context of sbt, Bazel, and likely many other build tools, the term _test_ could encompass various levels, 
and it's useful to disamgibuate this, especially when we want to configure pre- and post-hooks and parallel execution.
In other words, what do we mean when we say "test"?

There are four levels to test:

1. test command
2. test modules
3. test class
4. test method/expression

### test as commandline interface

The top-most level is the `test` command that the build tools provide to the users.

- When the user types `test` in the sbt shell or call `sbt --client test` from the terminal,
the command engine of sbt would lift "test" as task executions in the subprojects that are listed in the aggregate list.
  If the `root` subproject aggregated `core` and `util` subproject, `test` would be interpreted as a parallel execution of
`root/Test/test`, `core/Test/test` and `util/Test/test`.
  I often call this behavior as command broadcasting.
- In Bazel, the broadcasting is done more explicitly by the user.
  For instance, the user could issue `bazel test example1/...`, and Bazel would query all the test targets
  under `example1/` directory recursively and test the discovered test targets in parallel.

### test as module

The common theme is that test-as-command aggregates test modules, and runs them in parallel.

- sbt typically represents a test module as a pair of subproject and `Test` configuration.
- Bazel represents a test module as a target of some kind, like `scala_test(...)`.
  Bazel also provides named test aggregate, such as `scala_test_suite(...)` in rules\_scala.

One thing to note about Bazel is that it's good at handling test modules, like really good.
Test results are cached by default, the caching can be configured to be remote caching,
and the execution can also be configured to remote machines, which means hundreds of jobs
can potentially be triggered from a laptop.
Targets are often created more granularly than traditional build tools, and in theory you could
declare `scala_test(...)` per `.scala` file to run them in parallel (in different machines).

### test as class

In JVM test frameworks such as JUnit, MUnit, ScalaTest, Specs2, Hedgehog, Verify etc related test methods are grouped together in a class or an object.
In Scala, these test classes are sometimes named _suite_, like `FunSuite`, however, in JUnit `Suite` is a special kind of test class created as an alias
to aggregate multiple test classes.

- sbt standardizes the notion of inheritance-based and annotation-based test classes, and they are individually assigned to an internal task, so test classes are evaluated in parallel without any configuration.
- In Bazel, the runner provided by rules\_scala I don't think runs classes in parallel, but can be customized another runner.

### test as method/expression

In JVM test frameworks, individual test code is written in a method, or an expression such as `test("...") { ... }`.
To differentiate from test classes, test methods are sometimes called _test examples_ as well.

The parallelism of test method executions are up to the implementation of the runner.

- For instance, ScalaTest runs test methods [sequentially by default](https://www.scalatest.org/user_guide/async_testing).
  This can be overridden by defining an async suite with `ParallelTestExecution` trait mixed in.
- Specs2 by default runs test examples [in parallel](https://etorreborre.github.io/specs2/guide/SPECS2-4.8.3/org.specs2.guide.Execution.html).
  This can be overridden by adding `sequential` into `def is`.

The ability to select a specific test method and execute it remains to be an [open question](https://github.com/build-server-protocol/build-server-protocol/issues/249), which Kamil Podsiadło seems to be working on for Metals support.

[sbt/sbt#911](https://github.com/sbt/sbt/issues/911) potentially should be reopened for standardization of test method selection from sbt. Currently test frameworks implement this feature as argument processing that can be passed into `testOnly --`:

- junit-interface: `testOnly -- example.HelloTest.testHello`
- Scala Test: `testOnly example.HelloTest -- -z testHello`
- Specs2: `testOnly example.HelloTest -- ex testHello`

### parallelism

As we have seen, we can consider parallelism at each of the four levels.

At the command level, we can think of the parallelization of test command as executing in different CI workers to test multiple JDKs at the same time.

As the build tool, module level parallelism is the most coarse granularity, and both sbt and Bazel run independent test modules in parallel by default.
The how this parallelism is scheduled is up to the implementation, but with sbt, there's an experimental feature to associate tasks
with parallelism budget [tags](https://www.scala-sbt.org/1.x/docs/Parallel-Execution.html#Tagging+Tasks) along with `Global / concurrencyRestrictions`.
This mechanism could be used to run specific modules exclusively, while running the rest in parallel.
In terms of the execution environment, Bazel by default forks to another process, while sbt by default runs in a sandboxed thread.

At the class level, sbt implements parallelism by default by mapping each test class to a task.
In general, test framework specific knowledge is required to interact with this notion, which gives JVM specific build tools some upper hand.

Method level parallelism is implemented by the test framework. This means that the parallelism at the method level is limited to
threadind, as opposed to having forks.

As a reference, Maven's [Surefire Plugin](https://maven.apache.org/surefire/maven-surefire-plugin/examples/fork-options-and-parallel-execution.html)
provides `parallel` attribute, which can be configured to `methods`, `classes`, `both`,
`suites`, `suitesAndMethods`, `classesAndMethods`, or `all`.

### setup and teardown

We can also consider setup and teardown at four levels.

A command level setup does not exist, but it would be something like `pretest;test;posttest;`,
where `pretest` command would set some environment up, run `test`, and clean up in `posttest`.

At module level, sbt can append `Tests.Setup( loader => ... )` to `Test / testOptions`.
In theory this could be used as way of setting up some environment.

At class level, the setups are sometimes called fixture, and often supported by the framework.
JUnit for instance provides `@BeforeClass` and `@AfterClass` annotation.

A method level setups are called before each test method.
JUnit provides `@Before` and `@After` annotation.

### summary

When we discuss testing there are four different levels: test command, test module, test class, and test method/expression.

Potentially each of these levels can be parallelized, and depending on the build tool or the runner provided by the test framework, the execution might be forked in separate processes or executed as threads.
While build tools are capable of parallelizing execution of test modules, support for selection and parallelization of test classes and test methods remain patchy.

Bazel lacks `testOnly`, but it has powerful testing capability by supporting granular test targets,
named aggregates, remote caching, and remote execution.

