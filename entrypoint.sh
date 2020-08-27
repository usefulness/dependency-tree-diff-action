#!/bin/bash -el

wget "https://github.com/JakeWharton/dependency-tree-diff/releases/download/1.1.0/dependency-tree-diff.jar"
ls -l

diff=$(java -jar dependency-tree-diff.jar "$INPUT_BASEREF" "$INPUT_HEADREF")
echo "::set-output name=text-diff::$diff"
