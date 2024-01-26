#!/usr/bin/env sh
set -eu

/setup-ssh.sh

export GIT_SSH_COMMAND="ssh -v -i ~/.ssh/id_rsa -o StrictHostKeyChecking=no -l $INPUT_SSH_USERNAME"
git remote add mirror "$INPUT_TARGET_REPO_URL"

# Check if the repository uses Git LFS
if grep -q 'filter=lfs' .gitattributes; then
  # If it does, use the appropriate commands to mirror the repo
  git lfs install --local
  git lfs fetch --all
  git lfs push --all mirror
else
  # If it doesn't, use the standard git commands to mirror the repo
  git push --tags --force --prune mirror "refs/remotes/origin/*:refs/heads/*"
fi

# NOTE: Since `post` execution is not supported for local action from './' for now, we need to
# run the command by hand.
/cleanup.sh mirror
