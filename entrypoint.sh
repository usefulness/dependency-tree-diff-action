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

./gradlew $INPUT_ADDITIONAL_GRADLE_ARGUMENTS "$INPUT_PROJECT":dependencies --configuration "$INPUT_CONFIGURATION" > dependency_tree_diff_dependencies_current.txt
git fetch --force origin "$INPUT_BASEREF":"$INPUT_BASEREF" --no-tags
git switch --force "$INPUT_BASEREF"
./gradlew $INPUT_ADDITIONAL_GRADLE_ARGUMENTS "$INPUT_PROJECT":dependencies --configuration "$INPUT_CONFIGURATION" > dependency_tree_diff_dependencies_previous.txt
java -jar dependency-tree-diff.jar dependency_tree_diff_dependencies_previous.txt dependency_tree_diff_dependencies_current.txt > dependency_tree_diff_output.txt

if [ "$INPUT_DEBUG" == "true" ]; then
  echo "diff generated"
  ls -al
  realpath dependency_tree_diff_output.txt
  pwd
fi

delimiter=$(openssl rand -hex 20)
echo "text-diff<<$delimiter" >> $GITHUB_OUTPUT
cat dependency_tree_diff_output.txt >> $GITHUB_OUTPUT
echo "$delimiter" >> $GITHUB_OUTPUT

echo "file-diff=$(realpath dependency_tree_diff_output.txt)" >> $GITHUB_OUTPUT
echo "dependencies-previous=$(realpath dependency_tree_diff_dependencies_previous.txt)" >> $GITHUB_OUTPUT
echo "dependencies-current=$(realpath dependency_tree_diff_dependencies_current.txt)" >> $GITHUB_OUTPUT

git switch --detach "$current_head"
