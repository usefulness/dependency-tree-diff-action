#!/bin/bash -el

if [ -z "$INPUT_BASEREF" ]; then
  echo "::error::There is no ref to compare against. The action falls back to \`github.base_ref\`, which is only set for pull request events - pass the \`base-ref\` input explicitly for other triggers."
  exit 1
fi

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

# Prefer the ref as published by `origin`, but fall back to the local repository,
# so refs that only exist locally (`HEAD^1`, a not yet pushed commit) keep working.
if git fetch --force origin "$INPUT_BASEREF" --no-tags; then
  base_ref="FETCH_HEAD"
else
  echo "Could not fetch '$INPUT_BASEREF' from origin, resolving it in the local repository instead"
  base_ref="$INPUT_BASEREF"
fi

git switch --force --detach "$base_ref"
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
