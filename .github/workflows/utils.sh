#!/bin/bash
set -o pipefail

# Function to check if a branch exists in the remote repository
function branch_exists() {
    local branch=$1
    git ls-remote --heads https://github.com/rdkcentral/firebolt-apis.git "$branch" | grep -q "$branch"
}
  
function runTests(){
  echo "Determine the branch to checkout"
  # Convert event name to lowercase
  PR_BRANCH=$(echo "$EVENT_NAME" | tr '[:upper:]' '[:lower:]')

  # Check if OPENRPC_PR_BRANCH is not empty and the event is repository_dispatch
  if [ -n "$OPENRPC_PR_BRANCH" ] && [ "$PR_BRANCH" == "repository_dispatch" ]; then
      # Check if the branch exists in firebolt-apis
      if branch_exists "$OPENRPC_PR_BRANCH"; then
          PR_BRANCH=$OPENRPC_PR_BRANCH
          echo "Using branch from OPENRPC_PR_BRANCH: $OPENRPC_PR_BRANCH"
      else
          echo "Branch '$OPENRPC_PR_BRANCH' does not exist in firebolt-apis. Defaulting to 'next'."
          PR_BRANCH="next"
      fi
  elif [ "$PR_BRANCH" == "pull_request" ]; then
      # If it's a pull request event, use the PR branch
      PR_BRANCH=$PR_HEAD_REF
  elif [ "$PR_BRANCH" == "push" ]; then
      # For push events, extract the branch name
      PR_BRANCH=$GITHUB_REF
      PR_BRANCH="${PR_BRANCH#refs/heads/}"
  else
      echo "Unsupported event: $EVENT_NAME"
      exit 1
  fi

  echo "Cloning firebolt-apis repo with branch: $PR_BRANCH"
  git clone --branch ${PR_BRANCH} https://github.com/kdivya153/REPO2
  if [ "$EVENT_NAME" == "repository_dispatch" ]; then
  # If OPENRPC_PR_BRANCH is set and is not 'next'
    if [ -n "$OPENRPC_PR_BRANCH" ] && [ "$OPENRPC_PR_BRANCH" != "next" ]; then
      echo "Updating OpenRPC dependency to branch: $OPENRPC_PR_BRANCH"
      jq ".dependencies[\"@firebolt-js/openrpc\"] = \"file:../firebolt-openrpc#$OPENRPC_PR_BRANCH\"" package.json > package.json.tmp && mv package.json.tmp package.json
    fi
  fi
}
