Docker 内で sbt を走らせたかったので、イメージをいくつか作った。GitHub リポジトリは [eed3si9n/docker-sbt](https://github.com/eed3si9n/docker-sbt/)。

### AdoptOpenJDK

AdoptOpenJDK は、コミュニティーがメンテナンスを行っている OpenJDK のソースを元に複数のプラットフォーム向けにバイナリをビルドして配布している。[adoptopenjdk/openjdk8](https://hub.docker.com/r/adoptopenjdk/openjdk8) など Docker イメージも提供していて、Ubuntu ベースと Alpine Linux ベースのものがある。

OpenJDK を取り巻く状況は [Java Is Still Free](https://medium.com/@javachampions/java-is-still-free-c02aef8c9e04) に詳しくまとまっている。

### JDK 11

自分でイメージを作った動機として、再現可能な方法で JDK 11 を用いたテストを行いたかったというのがある。そのため、[adoptopenjdk/openjdk8](https://hub.docker.com/r/adoptopenjdk/openjdk8) を使ったものと [adoptopenjdk/openjdk11](https://hub.docker.com/r/adoptopenjdk/openjdk11) を使ったものの両方を作った。

### 使用方法

AdoptOpenJDK JDK 8 を用いる場合:

```
docker pull eed3si9n/sbt:jdk8-alpine
docker run -it --mount src="$(pwd)",target=/opt/workspace,type=bind eed3si9n/sbt:jdk8-alpine
```

AdoptOpenJDK JDK 11 を用いる場合:

```
docker pull eed3si9n/sbt:jdk11-alpine
docker run -it --mount src="$(pwd)",target=/opt/workspace,type=bind eed3si9n/sbt:jdk11-alpine
```

これは、non-root ユーザーとして Alpine Linux 内でシェルを開始する。ホストマシンのカレントディレクトリは `/opt/workspace` としてマウントされ、また sbt 1.2.8 がインストール済みになっている。

ホストマシンの Ivy キャッシュを再利用するには、以下のようにマウントする:

```
docker run -it --mount src="$(pwd)",target=/opt/workspace,type=bind \
  --mount src="$HOME/.ivy2",target=/home/demiourgos1/.ivy2,type=bind eed3si9n/sbt:jdk8-alpine
```

### その他のイメージ

- [hseeberger/scala-sbt](https://hub.docker.com/r/hseeberger/scala-sbt/)

Docker Hub で sbt と検索すると 1000 以上のヒットがある。
