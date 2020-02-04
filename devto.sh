#!/usr/bin/env bash

project=$(basename "$PWD")
branch=$(git branch | sed -n -e 's/^\* \(.*\)/\1/p')
timestamp=$(date +%s)
sed "s/\.\/images/https:\/\/raw.githubusercontent.com\/eon-com\/$project\/$branch\/images/" README.md | sed "s/\.png/\.png?version=$timestamp/" | tail -n +3 | pbcopy