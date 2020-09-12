# Readme Writer Bot

<!-- readme-writer-readme -->
**Readme Writer** is a Docker container that auto-generates a compound README from Markdown files within the repository. It looks for all content between two comment tags, then inserts them in a README based on a template using the [Liquid template language](https://shopify.github.io/liquid/). (docker://merovex/readme-writer:latest)
<!-- /readme-writer-readme -->

## Configuration

The following Github Action workflow should be added. Your repository name needs to be added

```
# Name: Compile Readme
#
# Description: This Github Action runs on each push to dynamically build
# the repository's README based on the template and other Markdown files
# In the repository.
# =================================================
# on: [push]
on:
  pull_request:
    types:
      - closed
    branches:
      - master

name: Compile Readme
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Get repo
        uses: actions/checkout@master
        with:
          ref: master
      - name: Compile
        uses: docker://merovex/readme-writer:latest
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
      - name: Commit on change
        uses: stefanzweifel/git-auto-commit-action@v4
        with:
          commit_message: "@verkilo rewrote README"

```