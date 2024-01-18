### branch has been pushed to, want to review just the differences
* `git range-diff [hash 0] [hash 1] [hash 2]`
  * hash 0 -> base commit, before the changes. like the master commit right before git bs
  * hash 1 -> old tip
  * hash 2 -> new tip

### pull a branch from someone's fork
1. add remote: `git remote add [local-name]
     git@github.com:[github-user]/bitcoin.git`
2. download the info `git fetch [local-name]`
3. track the branch `git co -b [local-branch-name]
     [local-name]/[github-branch-name]`
