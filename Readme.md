# Dependency Tree Diff - GitHub Action

![.github/workflows/main.yml](https://github.com/usefulness/dependency-tree-diff-action/workflows/.github/workflows/main.yml/badge.svg)

Simple GitHub Action wrapper for Jake Wharton's [Dependency Tree Diff](https://github.com/JakeWharton/dependency-tree-diff) tool.

## Usage 
The action only exposes _output_ containing the diff, so to effectively consume its output, it is highly recommended to use other GitHub Actions to customize your experience.

#### Create Pull Request comment on dependency change   
[See it in action!](https://github.com/mateuszkwiecinski/github_browser/pull/31)  
Create `.github/workflows/dependency_diff.yml`

```yml
name: Generate dependency diff

on:
  pull_request:

jobs:
  generate-diff:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v4

    - uses: actions/setup-java@v4
      with:
        distribution: 'temurin'
        java-version: 23
        
    - uses: gradle/actions/setup-gradle@v4

    - id: dependency-diff
      name: Generate dependency diff
      uses: usefulness/dependency-tree-diff-action@v2

    - uses: peter-evans/find-comment@v3
      id: find_comment
      with:
        issue-number: ${{ github.event.pull_request.number }}
        body-includes: Dependency diff

    - uses: peter-evans/create-or-update-comment@v4
      if: ${{ steps.dependency-diff.outputs.text-diff != null || steps.find_comment.outputs.comment-id != null }}
      with:
        body: |
          Dependency diff (customize your message here): 
            ```diff
            ${{ steps.dependency-diff.outputs.text-diff }}
            ```
        edit-mode: replace
        comment-id: ${{ steps.find_comment.outputs.comment-id }}
        issue-number: ${{ github.event.pull_request.number }}
        token: ${{ secrets.GITHUB_TOKEN }}
```

## Customization
All inputs with their default values:
```yml
    - id: dependency-diff
      uses: usefulness/dependency-tree-diff-action@v2
      with:
        configuration: 'releaseRuntimeClasspath'
        project: 'app'
        build-root-directory: .
        base-ref: ''
        additional-gradle-arguments: ''
        lib-version: 'latest'
        lib-checksum: ''
```

- **`configuration`** - Selected Gradle configuration, passed to `./gradlew dependencies --configuration xxx`.
It should correspond to output artifact considered output of the project.
- **`project`** - Gradle project which dependency tree diff should be generated for. 
Dependency diff for root projects can be configured using `project: ''`. 
 For Android projects use the one that has `com.android.application` plugin applied.
- **`build-root-directory`** - Relative path to folder containing gradle wrapper. 
Example usage: `build-root-directory: library`
- **`base-ref`** - The ref currently checked out revision is compared against. 
Accepts anything git can resolve to a commit - a branch name, a tag, a commit sha or an expression like `HEAD^1`. 
Refs available in the local repository are used as is, everything else is fetched from `origin` first. 
When left empty (the default) the action falls back to `github.base_ref`, i.e. the branch the pull request targets. 
See [Stacked pull requests](#stacked-pull-requests).
- **`additional-gradle-arguments`** - Additional arguments passed to internal Gradle invocation. Example: `"--no-configuration-cache"` or `"--stacktrace"`  
- **`lib-version`** - Overrides [dependency-tree-diff](https://github.com/JakeWharton/dependency-tree-diff) dependency version. Example: `"1.2.1"`, `"1.1.0"`, `"latest"`
- **`lib-checksum`** - Expected SHA-256 checksum of the downloaded `dependency-tree-diff.jar`. 
When set, the action fails if the downloaded file doesn't match. 
Only makes sense in combination with a pinned `lib-version`. 
Example: `lib-version: '1.2.1'` + `lib-checksum: 'f6c84d5ce8beb3277103fb8235071dd8bc69a7cde75239f636a7c8293ff0c865'`

### Stacked pull requests

For [stacked pull requests](https://docs.github.com/en/pull-requests/reference/stacked-pull-requests) `github.base_ref` points at the base of the whole stack (e.g. `main`), 
while the merge commit CI checks out is built on top of the parent pull request. 
Both sides of the comparison then contain a different version of `main`, and dependency changes that landed there in the meantime get reported as if they were introduced by the pull request.

Comparing against the first parent of the checked out merge commit puts the same `main` on both sides:

```yml
    - uses: actions/checkout@v4
      with:
        fetch-depth: 2

    - id: dependency-diff
      uses: usefulness/dependency-tree-diff-action@v2
      with:
        base-ref: HEAD^1
```

<details><summary></summary>
<p>

🙏 Praise 🙏 be 🙏 to 🙏 Wharton 🙏

</p>
</details>
