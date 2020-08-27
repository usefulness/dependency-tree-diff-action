#!/bin/bash -el

wget "https://github.com/JakeWharton/dependency-tree-diff/releases/download/1.1.0/dependency-tree-diff.jar" -q -O dependency-tree-diff.jar
ls -l

old="$INPUT_BASEREF"
new="$INPUT_HEADREF"

diff=$(java -jar dependency-tree-diff.jar)
echo "::set-output name=text-diff::$diff"
