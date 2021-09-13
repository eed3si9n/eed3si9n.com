---
title:       "scala/scala の git bisect"
type:        story
date:        2021-02-06
draft:       false
promote:     true
sticky:      false
url:         /ja/git-bisecting-scala-scala
aliases:     [ /node/380 ]
tags:        [ "git" ]
Summary:
  git bisect はバグの入った場所を特定するのに有用なテクニックだ。
  特に scala/scala の場合は、`bisect.sh` はビルド済みのコンパイラを Scala CI Artifactory から利用することで時間を節約できる。
---

<blockquote class="twitter-tweet"><p lang="en" dir="ltr">should I git bisect or watch Expanse?</p>&mdash; ∃ugene yokot∀ (@eed3si9n) <a href="https://twitter.com/eed3si9n/status/1352814320749576192?ref_src=twsrc%5Etfw">January 23, 2021</a></blockquote>

Scala コンパイラと標準ライブラリは全体的に安定していると言えるが、サンプルサイズを上げていったり、内部を拡張しはじめると、おかしな振る舞いに出くわすこともある。

Lukas Rytz さんが書いたスクリプトを使って scala/scala のコミット履歴を bisect する方法を簡単に紹介する。

### 再現ビルドのセットアップ

とりあえずは問題を sbt のビルドとして再現する。具体的には、ある Scala のバージョンでは動作したが、別のバージョンでデグレしたというものを作る。ここでは既に直っているバグを例に、どこでバグが入ったのかを探してみよう。適当に `/tmp/bisectscala/` という名前のディレクトリを作る。

#### build.sbt

<scala>
ThisBuild / resolvers += "scala-integration" at "https://scala-ci.typesafe.com/artifactory/scala-integration/"
</scala>

ビルドファイルはこれだけ。

#### Test.scala

<scala>
object Test extends App {
  val x = Set[AnyVal](1L, (), 28028, -3.8661012E-17, -67)
  val y = Set[AnyVal](1, 3.3897517E-23, ())
  val z = x ++ y
  assert(z.size == 6)
}
</scala>

これは吉田さんが Scala 2.13.0-RC3 で見つけた [scala/bug#11551](https://github.com/scala/bug/issues/11551) を再現する。2つの集合を足したときに 6要素ではなく 7要素が返ってくるというやつだ。

#### project/build.properties

<scala>
sbt.version=1.2.8
</scala>

最近の Zinc だと 2.13 のベータ付近が扱えなくなっているので、枯れた 1.2.8 を使う。

#### bisect.sh

`bisect.sh` をダウンロードする:

<code>
wget https://raw.githubusercontent.com/adriaanm/binfu/e996e30d6095d83160746f007737209a02b85944/bisect.sh
chmod +x bisect.sh
</code>

次に 83行目と 84行目をエディタで開いて以下のように変更する:

<code>
  cd /tmp/bisectscala/
  sbt "++$sv!" "run"
</code>

### bisect の実行

bisect を実行するには、ローカルマシンに scala/scala を clone する必要がある。Scala のコミット履歴が必要なので、当然と言えば当然だ。

別のターミナル窓を開いて、scala/scala を clone したワーキングディレクトリに移動する:

<code>
$ head -n 3 README.md
# Welcome!

This is the official repository for the [Scala Programming Language](http://www.scala-lang.org)
</code>

scala のディレクトリから以下を実行する:

<code>
/tmp/bisectscala/bisect.sh <good> <bad>
</code>

ただし、`<good>` は good な tag か commit で、`<bad>` は既知の bad な tag か commit を使う。今回の場合:

<code>
/tmp/bisectscala/bisect.sh v2.12.8 v2.13.0-RC3
</code>

scala/scala の面白いことは、全ての merge commit ごとに `scala-compiler`、`scala-library` などのアーティファクトが自動的にビルドされて Scala CI Artifactory に公開されていることだ。そのため、(全てではないが) 多くのコミットを `scalaVersion` に設定してあたかも普通の Scala バージョンであるかのように扱うことができる。sbt はコンパイラ JAR をリポジトリからダウンロードして、compiler bridge をコンパイルして使う。独自にコンパイラをコンパイルして、publishLocal する手間が省けるため、これが大きな時間の節約となる。

<code>
$ /tmp/bisectscala/bisect.sh v2.12.8 v2.13.0-RC3
notice:
* currently you have to edit this script for each use
maintenance status:
* this is somewhat rough, but hopefully already useful
* pull requests with improvements welcome
Bisecting: 2295 revisions left to test after this (roughly 11 steps)
</code>

二分探索の結果は以下のようになった:
- good: dbf9a6a631
- skip: e7eca326c3
- skip: 10f066bff4
- bad: af24410986
- good: bcb6ddff10
- skip: be1d651fea
- skip: 9a04c4d9b7
- bad: f8fdd3e736
- skip: 536988631c
- skip: f421ca1249
- skip: c02e4ae4c3
- skip: 28e20d1b27
- bad: c742cff1fb
- skip: 0c114dc58c
- good: f65fb09c1c
- skip: cb33737d09
- good: d4a9eaa070
- skip: 508eeca620
- skip: 67f51bd62d
- skip: f85610711e
- skip: d9f00716ce
- good: d5d397ff63
- bad: c2be3187be
- bad: 1775dbad30
- good: f1c1d62d0c
- skip: 24a571368b
- bad: 3a8a5ddd01
- skip: f293db4572
- good: fa5ad9ac24
- bad: 0807abfb4f
- skip: c39acf5bbf

非merge コミットはスキップしている。最後に出てきた結果がこれだ:

<code>
There are only 'skip'ped commits left to test.
The first bad commit could be any of:
c39acf5bbf8d57c8684ad65abff77075b9524b5d
0807abfb4f45611e9df5bb7e2f4285945448bce2
We cannot bisect more!
bisect run cannot continue any more
</code>

つまり、2295個あるコミットから、手動で検査する必要のあるものを 2つにまで絞ることができた。タイムスタンプを見るとだいたい 9分ぐらいかかったみたいだ。ちょっと好みの飲み物を作って戻ってくると終わっている感じだ。

この場合、c39acf5bbf8d57c8684ad65abff77075b9524b5d は実際にバグが入っていたコミットだ。0807abfb4f45611e9df5bb7e2f4285945448bce2 はその merge commit なので、両方正解だ。

### 魔法の解読

Lukas のスクリプトを少し読んでみよう。メインの部分はここだ:

```bash
git bisect start --no-checkout
git bisect good $good
git bisect bad $bad
git bisect run "$script_path" run-the-run "$current_dir"
git bisect log > "bisect_$good-$bad.log"
git bisect reset
```

面白い詳細は `run` が呼び出すヘルパー関数にある:

```bash
current () {
  local sha=$(cat "$repo_dir/.git/BISECT_HEAD")
  echo ${sha:0:10}
}

scalaVersion () {
  local sha=$(current)
  sha=${sha:0:7}
  local artifact=$(curl -s "https://scala-ci.typesafe.com/artifactory/api/search/artifact?name=$sha" | jq -r '.results | .[] | .uri' | grep "/scala-compiler-.*-$sha.jar")
  # scala version is in second-to-last column
  # http://scala-ci.typesafe.com/artifactory/api/storage/scala-integration/org/scala-lang/scala-compiler/2.13.0-pre-d40e267/scala-compiler-2.13.0-pre-d40e267.jar
  res=$(echo $artifact | awk -F/ '{print $(NF-1)}' 2> /dev/null)
  echo $res
}
```

git sha を検知して、Artifactory の search API を使ってバージョンが上がってるかどうかをクエリしているみたいだ。

### まとめ

git bisect はバグの入った場所を特定するのに有用なテクニックだ。
特に scala/scala の場合は、`bisect.sh` はビルド済みのコンパイラを Scala CI Artifactory から利用することで時間を節約できる。
