### サブディレクトリを新しいリポジトリへ分岐させる

<code>
git clone --no-hardlinks --branch master originalRepoURL childRepo
cd childRepo
git filter-branch --prune-empty --subdirectory-filter path/to/keep master
git remote remove origin
git prune
git gc --aggressive
</code>

`originalRepoURL`、`master`、`path/to/keep` などは適当な値に変える。全てのブランチを処理したい場合は `-- --all` を使う。

### src を path/to/keep に戻す

`--subdirectory-filter` は `path/to/keep` 以下の `src/` などをルートに移動してしまうので、元のパス (もしくは別のパス) に戻したい場合は移動させてコミットを 1つ追加する必要がある。

<code>
mkdir -p path/to/keep
git mv src path/to/keep
git commit -m "move files"
</code>

### タグの削除

元リポの全てのタグを削除したい場合は、以下を `deltags.sh` という名前で保存して、実行する。

<code>
#!/bin/bash

for t in `git tag`
do
  git tag -d $t
done
</code>

<code>
chmod +x deltags.sh
./deltags.sh
</code>

### 既存のリポジトリへと merge する

オプションとして、このテクニックを応用して既存のリポへと履歴を接ぎ木をすることができる。
念の為 `wip/graft` というブランチを作ってそこに接ぎ木する。

<code>
cd ..
git clone someotherRepo
cd someotherRepo
git remote add childRepo ../childRepo
git checkout -b wip/graft
git pull childRepo master --allow-unrelated-histories
git remote remove childRepo
</code>

これでプルリクなどを送ることができる。

### 参照

- [git-filter-branch](https://git-scm.com/docs/git-filter-branch)
- [Splitting a subfolder out into a new repository](https://help.github.com/en/articles/splitting-a-subfolder-out-into-a-new-repository)
- [Moving Files from one Git Repository to Another, Preserving History](http://gbayer.com/development/moving-files-from-one-git-repository-to-another-preserving-history/)
