#!/usr/bin/env bash
set -euo pipefail

testproject=$(cd "$1" && pwd)
mkdir -p "$2"
root=$(cd "$2" && { pwd -W 2>/dev/null || pwd; })
remotes="$root/remotes"
work="$root/work"

export GIT_AUTHOR_NAME="dependency-tree-diff-action"
export GIT_AUTHOR_EMAIL="dependency-tree-diff-action@example.com"
export GIT_COMMITTER_NAME="$GIT_AUTHOR_NAME"
export GIT_COMMITTER_EMAIL="$GIT_AUTHOR_EMAIL"

git init --quiet --bare --initial-branch=main "$remotes/plugins.git"
git init --quiet --bare --initial-branch=main "$remotes/superproject.git"

git init --quiet --initial-branch=main "$work/plugins"
cd "$work/plugins"
cat > dependencies.gradle <<'EOF'
dependencies {
    implementation("androidx.paging:paging-common-ktx:3.2.0")
}
EOF
git add dependencies.gradle
git commit --quiet --message "Use paging 3.2.0"
git push --quiet "$remotes/plugins.git" HEAD:refs/heads/main

git init --quiet --initial-branch=main "$work/superproject"
cd "$work/superproject"
git remote add origin "$remotes/superproject.git"
cp -R "$testproject/gradle" "$testproject/gradlew" "$testproject/gradlew.bat" "$testproject/settings.gradle" "$testproject/gradle.properties" .
grep -v "androidx.paging" "$testproject/build.gradle" > build.gradle
echo 'apply from: "plugins/dependencies.gradle"' >> build.gradle
git -c protocol.file.allow=always submodule --quiet add ../plugins.git plugins
git add .
git commit --quiet --message "Apply dependencies from the plugins submodule"
git push --quiet origin HEAD:refs/heads/main

cd "$work/superproject/plugins"
cat > dependencies.gradle <<'EOF'
dependencies {
    implementation("androidx.paging:paging-common-ktx:3.3.0")
    implementation("com.squareup.okio:okio:$okioVersion")
}
EOF
git commit --quiet --all --message "Use paging 3.3.0 and okio"
git push --quiet origin HEAD:refs/heads/main

cd "$work/superproject"
echo "okioVersion=3.9.0" >> gradle.properties
git commit --quiet --all --message "Bump the plugins submodule"
git push --quiet origin HEAD:refs/heads/feature

case "$remotes" in
  /*) remotes_url="file://$remotes" ;;
  *) remotes_url="file:///$remotes" ;;
esac

git init --quiet "$root/superproject"
cd "$root/superproject"
git remote add origin "$remotes_url/superproject.git"
git fetch --quiet --depth=1 origin +refs/heads/feature:refs/remotes/origin/feature
git checkout --quiet --detach refs/remotes/origin/feature
git submodule sync --quiet
git -c protocol.file.allow=always -c protocol.version=2 submodule update --quiet --init --force --depth=1
