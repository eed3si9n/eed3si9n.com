### split a subdirectory into a new repo (simple case)

<code>
git clone --no-hardlinks --branch master originalRepoURL childRepo
cd childRepo
git filter-branch --prune-empty --subdirectory-filter path/to/keep master
git remote remove origin
git prune
git gc --aggressive
</code>

Change `originalRepoURL`, `master`, and `path/to/keep` to appropriate values. Use `-- --all` to handle all branches.

### split a subdirectory into a new repo (complex case)

In case you have multiple paths you want to filter, you need to use `--index-filter` together with GNU xargs and GNU sed available via `brew install gnu-sed findutils`.

<code>
git clone --no-hardlinks --branch master originalRepoURL childRepo
cd childRepo
git filter-branch --index-filter 'git rm --cached -qr --ignore-unmatch -- . && git reset -q $GIT_COMMIT -- path1/to/keep path2/to/keep' --prune-empty master
git filter-branch --prune-empty --parent-filter 'gsed "s/-p //g" | gxargs git show-branch --independent | gsed "s/\</-p /g"'
git remote remove origin
git prune
git gc --aggressive
</code>

Change `originalRepoURL`, `master`, `path1/to/keep`, `path2/to/keep` to appropriate values. Use `-- --all` to handle all branches.

### move src back to path/to/keep

`--subdirectory-filter` moves the path of `src/` etc under `path/to/keep` to root, so if you need to add a commit to move it back to the same (or another) path.

<code>
mkdir -p path/to/keep
git mv src path/to/keep
git commit -m "move files"
</code>

### delete tags

To remove tags from the original repo, save the following as `deltags.sh`, and run it.

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

### merge it to an existing repo

Optionally, this technique can be used to graft a history into an existing repo.
To be safe, let's do that in a branch called `wip/graft`.

<code>
cd ..
git clone someotherRepo
cd someotherRepo
git remote add childRepo ../childRepo
git checkout -b wip/graft
git pull childRepo master --allow-unrelated-histories
git remote remove childRepo
</code>

This way you can send this as a pull request etc.

### reference

- [git-filter-branch](https://git-scm.com/docs/git-filter-branch)
- [Splitting a subfolder out into a new repository](https://help.github.com/en/articles/splitting-a-subfolder-out-into-a-new-repository)
- [Moving Files from one Git Repository to Another, Preserving History](http://gbayer.com/development/moving-files-from-one-git-repository-to-another-preserving-history/)
- [Detach many subdirectories into a new, separate Git repository](https://stackoverflow.com/a/17867910/3827)
