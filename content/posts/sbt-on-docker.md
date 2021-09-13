---
title:       "sbt on Docker"
type:        story
date:        2019-02-17
draft:       false
promote:     true
sticky:      false
url:         /sbt-on-docker
aliases:     [ /node/290 ]
---

I wanted to run sbt inside Docker, so I created some images. The GitHub repo is [eed3si9n/docker-sbt](https://github.com/eed3si9n/docker-sbt/).

<!--more-->

### AdoptOpenJDK

AdoptOpenJDK provides prebuilt OpenJDK binaries for various platforms based on the community-maintained OpenJDK source tree. They provide Docker images as [adoptopenjdk/openjdk8](https://hub.docker.com/r/adoptopenjdk/openjdk8) etc based on Ubuntu or Alpine Linux.

See [Java Is Still Free](https://medium.com/@javachampions/java-is-still-free-c02aef8c9e04) document for more details on OpenJDK situation.

### JDK 11

One of my motivation for creating this image is to do JDK 11 testing in a repeatable fashion. So I've created sbt image based on [adoptopenjdk/openjdk8](https://hub.docker.com/r/adoptopenjdk/openjdk8) as well as [adoptopenjdk/openjdk11](https://hub.docker.com/r/adoptopenjdk/openjdk11).

### usage


For AdoptOpenJDK JDK 8:

```
docker pull eed3si9n/sbt:jdk8-alpine
docker run -it --mount src="$(pwd)",target=/opt/workspace,type=bind eed3si9n/sbt:jdk8-alpine
```

For AdoptOpenJDK JDK 11:

```
docker pull eed3si9n/sbt:jdk11-alpine
docker run -it --mount src="$(pwd)",target=/opt/workspace,type=bind eed3si9n/sbt:jdk11-alpine
```

This will start a shell inside Alpine Linux as a non-root user who has access to `/opt/workspace` mapped to the current directory of the host machine, and sbt 1.2.8 installed.

To reuse the Ivy cache from the host machine, mount it as follows:

```
docker run -it --mount src="$(pwd)",target=/opt/workspace,type=bind \
  --mount src="$HOME/.ivy2",target=/home/demiourgos1/.ivy2,type=bind eed3si9n/sbt:jdk8-alpine
```

### other images

- [hseeberger/scala-sbt](https://hub.docker.com/r/hseeberger/scala-sbt/)

There are over 1000 images if you search for sbt on Docker Hub.
