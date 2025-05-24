#!/bin/bash -el

cd "$INPUT_BUILD_ROOT_DIR"

if [ "$INPUT_VERSION" == "latest" ]; then
  curl -H "Authorization: Bearer $GITHUB_TOKEN" -s https://api.github.com/repos/JakeWharton/dependency-tree-diff/releases/latest \
  | grep "/dependency-tree-diff.jar" \
  | cut -d : -f 2,3 \
  | tr -d \" \
  | xargs curl -H "Authorization: Bearer $GITHUB_TOKEN" -L -s -o dependency-tree-diff.jar
else
  curl -H "Authorization: Bearer $GITHUB_TOKEN" -L -s -o dependency-tree-diff.jar "https://github.com/JakeWharton/dependency-tree-diff/releases/download/$INPUT_VERSION/dependency-tree-diff.jar"
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

chmod +x dependency-tree-diff.jar

current_head=$(git rev-parse HEAD)

./gradlew $INPUT_ADDITIONAL_GRADLE_ARGUMENTS "$INPUT_PROJECT":dependencies --configuration "$INPUT_CONFIGURATION" > dependency-tree-diff_dependencies-head.txt
git fetch --force origin "$INPUT_BASEREF":"$INPUT_BASEREF" --no-tags
git switch --force "$INPUT_BASEREF"
./gradlew $INPUT_ADDITIONAL_GRADLE_ARGUMENTS "$INPUT_PROJECT":dependencies --configuration "$INPUT_CONFIGURATION" > dependency-tree-diff_dependencies-base.txt
java -jar dependency-tree-diff.jar dependency-tree-diff_dependencies-base.txt dependency-tree-diff_dependencies-head.txt > dependency-tree-diff_output.txt

if [ "$INPUT_DEBUG" == "true" ]; then
  echo "diff generated"
  ls -al
  realpath dependency-tree-diff_output.txt
  pwd
fi

delimiter=$(openssl rand -hex 20)
echo "text-diff<<$delimiter" >> $GITHUB_OUTPUT
cat dependency-tree-diff_output.txt >> $GITHUB_OUTPUT
echo "$delimiter" >> $GITHUB_OUTPUT

echo "file-diff=$(realpath dependency-tree-diff_output.txt)" >> $GITHUB_OUTPUT
echo "file-dependencies-base=$(realpath dependency-tree-diff_dependencies-base.txt)" >> $GITHUB_OUTPUT
echo "file-dependencies-head=$(realpath dependency-tree-diff_dependencies-head.txt)" >> $GITHUB_OUTPUT

git switch --detach "$current_head"
