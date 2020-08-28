#!/bin/bash -el

wget "https://github.com/JakeWharton/dependency-tree-diff/releases/download/1.1.0/dependency-tree-diff.jar" -q -O dependency-tree-diff.jar

cd "$INPUT_BUILD_ROOT_DIR"
./gradlew project
./gradlew :"$INPUT_PROJECT":dependencies --configuration "$INPUT_CONFIGURATION" >new_diff.txt
git checkout "$INPUT_BASEREF"
./gradlew :"$INPUT_PROJECT":dependencies --configuration "$INPUT_CONFIGURATION" >old_diff.txt

diff=$(java -jar dependency-tree-diff.jar old_diff.txt new_diff.txt)
diff="${diff//'%'/'%25'}"
diff="${diff//$'\n'/'%0A'}"
diff="${diff//$'\r'/'%0D'}"
echo "::set-output name=text-diff::$diff"
