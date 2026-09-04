---
title:       "RFC-5: test scheduling"
type:        story
date:        2026-09-04
url:         /rfc-5-test-scheduling
tags:        [ "sbt" ]
---

- Author: Eugene Yokota
- Date: 2026-09-04
- Status: **Review**

## Background

### Test terminology

In this example, we'll use:
1. _module_ to mean sbt subprojects.
2. _test class_ to mean test suite classes, like ScalaTest, JUnit, MUnit etc.
3. _test method/expression_ to mean individual tests.

### Test scheduling in sbt 1.x and 2.0.0

On sbt 1.x, the build user typically has one knob to choose from, which is whether a subproject should fork the test via `Test / fork := true` or not. Suppose we have Module1, Module2, and Module3 that are not forked, and Module4, Module5, and Module6 that are forked.

The following is a conceptual illustration of how test classes would be scheduled:

<!-- npx -p @mermaid-js/mermaid-cli mmdc --input static/mermaid/topo1.mmd --output static/images/topo1.svg -->

![topo1](/images/topo1.svg)

1. Within the sbt server, test classes map to a task, and test classes from participating subprojects run in parallel, sharing the same JVM. Other tasks such as compilation also run in parallel.
2. The forked tests have a default restriction to run 1 module at a time. Each forked test spawn a fresh JVM.
3. Within the forked process, the test classes run in parallel (`testForkedParallel` is `true` by default).

This is a balanced take on the test scheduling that's been working well.

## Proposals

### Increasing the forked test bandwidth

On a larger build with dozens of subprojects, restricting all forked test modules to be sequential may slow the tests, especially on CI.

![topo2](/images/topo2.svg)

On sbt 1.x, this can be done via the `Global / concurrentRestrictions` setting. I'd like to propose a new setting that can be adjusted via both `build.sbt` and the system property.

```scala
Global / workerMaxInstances := 2 // or use -Dsbt.worker_max_instances=2 for CI
```

Using this we can change the default concurrent restrction as follows:

```scala
  def defaultRestrictions: Initialize[Seq[Tags.Rule]] =
    Def.setting {
      val par = parallelExecution.value
      val max = EvaluateTask.SystemProcessors
      val maxWorker = workerMaxInstances.value
      Tags.limitAll(if par then max else 1) ::
        // This currently defaults to 1
        Tags.limit(Tags.ForkedTestGroup, maxWorker) ::
        Tags.exclusiveGroup(Tags.Clean) ::
        Nil
    }
```

While this would increase the forking testing capacity given enough CPU and RAM, there might be some subprojects that require exclusive execution because it requires setting up a test database etc. We can introduce another setting at the subproject level to control this:

```scala
// Test / testTopology := TestTopology.auto

lazy val m5 = project
  .settings(
    Test / testTopology := TestTopology.subprojectExclusive,
  )
```

For the exclusive forked tests, we can let it consuming all `Tags.ForkedTestGroup` tags, which would run exclusively among the forked tests. There's a relevant pull request [#9665](https://github.com/sbt/sbt/pull/9665) for this.

### Default test class parallelism

Currently the default value of the `testForkedParallelism` setting is `None`, which eventually is interpreted to mean an `Executors.newFixedThreadPool` inside the forked worker with the thread count of avaiable CPU cores. This would create 16 threads on a 16-core machine.

If `Global / workerMaxInstances` is set to a number greater than 1, we should reduce the default parallelism. One potential strategy is to divide the available CPU with `workerMaxInstances`.

### Splitting the test classes

Next, let's consider a situation where we have available workers, but they remain idle because the test classes are distributed unevenly across the subprojects. We can add a knob for this in the `Test / testTopology` value:

```scala
Global / workerMaxInstances := 5
Test / testTopology := {
  if workerMaxInstances.value > 1 then TestToplogy.subprojectSplit(2)
  else TestTopology.subprojectParallel
}

lazy val m4 = project
  .settings(Test / fork := true)

lazy val m5 = project
  .settings(
    Test / fork := true,
    Test / testTopology := TestTopology.subprojectExclusive,
  )

lazy val m6 = project
  .settings(Test / fork := true)
```

In this example, we have 5 workers for 3 forked test subprojects. We can set the default value of `Test / testTopology` to split into two test groups.

### Persistent worker for testing (experimental)

As sketched out in [RFC-4: persistent worker](/rfc-4-persistent-worker/), I'd like to support the worker to be stay alive. Once we have higher bandwidth for the test workers, we can envision running all test in the workers.

**Motivation**:
1. Balancing performance and isolation. The default way of running tests is in-process for JIT performance reasons. However, running the test code inside the sbt server leads to resource leakages over time. Persistent worker can be a middle-ground option.

Making the worker persistent itself is a trivial change, but there are a few secondary issues that arise from taking advantage of the persisted workers.

- Do we support different subprojects reusing the same worker? Given that the number of subprojects are going to be larger than the number of workers, we should support the reuse across different subprojects for persistent workers.
- Where should be the current directory of the worker process? Forked tests have used `baseDirectory` of the subproject. If we allow the reuse, then the current needs to change to something like `ThisBuild / baseDirectory`.
- We can either manage the worker process internally, or use the `BackgroundJobService` facility used for `bgRun`.
- Similarly, how does persistent worker affect the test grouping? We currently bundle all test classes in a subproject into one worker, but if the workers are standing by, we could split the test classes based on the `testForkedParallelism` setting, and queue them dynamically. This would be similar to the in-process scheduling based on the tag restrictions.

![topo3](/images/topo3.svg)

We can start with a minimial, opt-in implementation and benchmark some of the assumptions.

<div class="admonition note">

### Appendix: Related ideas

Once we can capture all the inputs required for testing, there are several related ideas for future considerations:

- Remote execution. Bazel cache services not only allows artifact caching, but they often offer remote execution as a service. This is similar to expanding the test bandwidth, but across different machines.
- Client-side test. If sbtn can manage the orchestration of test aggregation, similar to the client-side run, we can make test a non-blocking operation.
</div>
