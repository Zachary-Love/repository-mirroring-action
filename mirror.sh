#!/usr/bin/env sh
set -eu

/setup-ssh.sh

export GIT_SSH_COMMAND="ssh -v -i ~/.ssh/id_rsa -o StrictHostKeyChecking=no -l $INPUT_SSH_USERNAME"
git remote add mirror "$INPUT_TARGET_REPO_URL"

# Check if the repository uses Git LFS
if grep -q 'filter=lfs' .gitattributes; then
  # If it does, disable LFS locking verification for the mirror remote
  git config lfs."$INPUT_TARGET_REPO_URL"/info/lfs.locksverify false

  # Fetch and push all LFS files
  git lfs fetch --all
  git lfs push --all mirror
fi

# Push the Git history to the mirror repository
git push --tags --force --prune mirror "refs/remotes/origin/*:refs/heads/*"

# NOTE: Since `post` execution is not supported for local action from './' for now, we need to
# run the command by hand.
/cleanup.sh mirror
