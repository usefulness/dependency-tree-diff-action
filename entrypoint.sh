#!/bin/bash -el

wget "https://github.com/JakeWharton/dependency-tree-diff/releases/download/1.1.0/dependency-tree-diff.jar" -q -O dependency-tree-diff.jar

cd app
git checkout "$INPUT_BASEREF"
./gradlew :"$INPUT_PROJECT":dependencies --configuration "$INPUT_CONFIGURATION" >../old.txt
git checkout "$INPUT_HEADREF"
./gradlew :"$INPUT_PROJECT":dependencies --configuration "$INPUT_CONFIGURATION" >../new.txt
cd ..

diff=$(java -jar dependency-tree-diff.jar old.txt new.text)
echo "::set-output name=text-diff::$diff"
