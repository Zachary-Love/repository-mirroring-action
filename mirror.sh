#!/usr/bin/env sh
set -eu

# Setup SSH for secure communication
/setup-ssh.sh

# Configure SSH command with increased verbosity
export GIT_SSH_COMMAND="ssh -v -i ~/.ssh/id_rsa -o StrictHostKeyChecking=no -l $INPUT_SSH_USERNAME"

# Add the mirror repository as a remote
git remote add mirror "$INPUT_TARGET_REPO_URL"

# Check if the repository uses Git LFS
if grep -q 'filter=lfs' .gitattributes; then
  echo "Found LFS Repository"

  # Convert SSH URL to HTTPS URL for LFS operations
  HTTPS_REPO_URL=$(echo "$INPUT_TARGET_REPO_URL" | sed 's/ssh:/https:/g')
  echo "Converted URL: $HTTPS_REPO_URL"
  
  # Disable LFS locking verification for the mirror remote to speed up the process
  git config lfs."$HTTPS_REPO_URL"/info/lfs.locksverify false

  # Fetch and push all LFS files with better logging
  echo "LFS Fetch"
  git lfs fetch --all 2>&1 | tee lfs-fetch.log

  echo "LFS Push"
  GIT_TRACE=1 GIT_CURL_VERBOSE=1 git lfs push --all mirror 2>&1 | tee lfs-push.log
else
  echo "No LFS Repository detected."
fi

# Push the Git history to the mirror repository with better logging
echo "Pushing to mirror repository"
git push --tags --force --prune mirror "refs/remotes/origin/*:refs/heads/*" 2>&1 | tee git-push.log

# Cleanup procedure
/cleanup.sh mirror
