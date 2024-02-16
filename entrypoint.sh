#!/bin/bash -el

cd "$INPUT_BUILD_ROOT_DIR"

if [ "$INPUT_VERSION" == "latest" ]; then
  curl -s https://api.github.com/repos/JakeWharton/dependency-tree-diff/releases/latest \
  | grep "/dependency-tree-diff.jar" \
  | cut -d : -f 2,3 \
  | tr -d \" \
  | xargs curl -L -s -o dependency-tree-diff.jar
else
  curl -L -s -o dependency-tree-diff.jar "https://github.com/JakeWharton/dependency-tree-diff/releases/download/$INPUT_VERSION/dependency-tree-diff.jar"
fi

if [ "$INPUT_PROJECT" == ":" ]; then
  INPUT_PROJECT=""
fi

if [ "$INPUT_DEBUG" == "true" ]; then
  echo "download finished"
  echo "$JAVA_HOME"
  java -version
  ls -al
fi

current_head=$(git rev-parse HEAD)

./gradlew $INPUT_ADDITIONAL_GRADLE_ARGUMENTS "$INPUT_PROJECT":dependencies --configuration "$INPUT_CONFIGURATION" > new_diff.txt
git fetch --force origin "$INPUT_BASEREF":"$INPUT_BASEREF" --no-tags
git switch --force "$INPUT_BASEREF"
./gradlew $INPUT_ADDITIONAL_GRADLE_ARGUMENTS "$INPUT_PROJECT":dependencies --configuration "$INPUT_CONFIGURATION" > old_diff.txt
java -jar dependency-tree-diff.jar old_diff.txt new_diff.txt > tree_diff.txt

if [ "$INPUT_DEBUG" == "true" ]; then
  echo "diff generated"
  ls -al
  du tree_diff.txt
  realpath tree_diff.txt
  pwd
fi

delimiter=$(openssl rand -hex 20)
echo "text-diff<<$delimiter" >> $GITHUB_OUTPUT
cat tree_diff.txt >> $GITHUB_OUTPUT
echo "$delimiter" >> $GITHUB_OUTPUT

echo "file-diff=$(realpath tree_diff.txt)" >> $GITHUB_OUTPUT

git switch --detach "$current_head"
