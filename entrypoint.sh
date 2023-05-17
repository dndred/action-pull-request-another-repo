#!/bin/sh

set -e
set -x


if [ $INPUT_DESTINATION_HEAD_BRANCH == "main" ] || [ $INPUT_DESTINATION_HEAD_BRANCH == "master"]
then
  echo "Destination head branch cannot be 'main' nor 'master'"
  return -1
fi

CLONE_DIR=$(mktemp -d)

echo "Setting git variables"
export GITHUB_TOKEN=$API_TOKEN_GITHUB
git config --global user.email "$INPUT_USER_EMAIL"
git config --global user.name "$INPUT_USER_NAME"

echo "Cloning destination git repository"
git clone --depth 1  --branch $INPUT_DESTINATION_HEAD_BRANCH "https://$API_TOKEN_GITHUB@github.com/$INPUT_DESTINATION_REPO.git" "$CLONE_DIR" ||
  git clone --depth 1  "https://$API_TOKEN_GITHUB@github.com/$INPUT_DESTINATION_REPO.git" "$CLONE_DIR"

cd "$CLONE_DIR"

git checkout -b $INPUT_DESTINATION_HEAD_BRANCH ||
  git checkout $INPUT_DESTINATION_HEAD_BRANCH



echo "Running command $INPUT_COMMAND"
eval "$INPUT_COMMAND"

echo "Adding git commit"
git add .
if git status | grep -q "Changes to be committed"
then
  git commit --message "Update from https://github.com/$GITHUB_REPOSITORY/commit/$GITHUB_SHA"
  echo "Pushing git commit"
  git push -u origin HEAD:$INPUT_DESTINATION_HEAD_BRANCH
  echo "Creating a pull request"


  gh pr edit $INPUT_DESTINATION_HEAD_BRANCH -b "$INPUT_BODY" -t "$INPUT_TITLE"  &&
   gh pr reopen $INPUT_DESTINATION_HEAD_BRANCH ||
    gh pr create -t "$INPUT_TITLE" \
                 -b "$INPUT_BODY" \
                 -B $INPUT_DESTINATION_BASE_BRANCH \
                 -H $INPUT_DESTINATION_HEAD_BRANCH

else
  echo "No changes detected"
fi
