#!/usr/bin/env sh
set -eu

/setup-ssh.sh

export GIT_SSH_COMMAND="ssh -v -i ~/.ssh/id_rsa -o StrictHostKeyChecking=no -l $INPUT_SSH_USERNAME"
git remote add mirror "$INPUT_TARGET_REPO_URL"
grep -q 'filter=lfs' .gitattributes
export LFS_CHECK=$?
# Check if the repository uses Git LFS
if [ $LFS_CHECK -eq 0 ]; then
  echo "Found LFS Repository"
  echo "$INPUT_TARGET_REPO_URL"
  # If it does, disable LFS locking verification for the mirror remote
  git config lfs."$INPUT_TARGET_REPO_URL"/info/lfs.locksverify false

  # Fetch and push all LFS files
  echo "LFS Fetch"
  git lfs fetch --all
  git lfs push --all mirror
fi

# Push the Git history to the mirror repository
echo "Pushing to mirror repository"
git push --tags --force --prune mirror "refs/remotes/origin/*:refs/heads/*"

# NOTE: Since `post` execution is not supported for local action from './' for now, we need to
# run the command by hand.
/cleanup.sh mirror
