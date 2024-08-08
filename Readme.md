# Dependency Tree Diff - Github Action

![.github/workflows/main.yml](https://github.com/usefulness/dependency-tree-diff-action/workflows/.github/workflows/main.yml/badge.svg)

Simple Github Action wrapper for Jake Wharton's [Dependency Tree Diff](https://github.com/JakeWharton/dependency-tree-diff) tool.

## Usage 
The action only exposes _output_ containing the diff, so to effectively consume its output it is highly recommended to use other Github Actions to customize your experience.

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
    - uses: actions/checkout@v3

    - uses: actions/setup-java@v3
      with:
        distribution: 'temurin'
        java-version: 21
        
    - uses: gradle/actions/setup-gradle@v4

    - name: Run dependencies
      run: ./gradlew dependencies

    - id: dependency-diff
      name: Generate dependency diff
      uses: usefulness/dependency-tree-diff-action@v2

    - uses: peter-evans/find-comment@v3
      id: find_comment
      with:
        issue-number: ${{ github.event.pull_request.number }}
        body-includes: Dependency diff

    - uses: peter-evans/create-or-update-comment@v3
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
        additional-gradle-arguments: ''
        lib-version: 'latest'
```

- **`configuration`** - Selected Gradle configuration, passed to `./gradlew dependencies --configuration xxx`.
Should correspond to output artifact that is considered output of the project.
- **`project`** - Gradle project which dependency tree diff should be generated for. 
Dependency diff for root projects can be configured using `project: ''`. 
 For Android projects use the one that has `com.android.application` plugin applied.
- **`build-root-directory`** - Relative path to folder containing gradle wrapper. 
Example usage: `build-root-directory: library`
- **`additional-gradle-arguments`** - Additional arguments passed to internal Gradle invocation. Example: `"--no-configuration-cache"` or `"--stacktrace"`  
- **`lib-version`** - Overrides [dependency-tree-diff](https://github.com/JakeWharton/dependency-tree-diff) dependency version. Example: `"1.2.1"`, `"1.1.0"`, `"latest"`

<details><summary></summary>
<p>

🙏 Praise 🙏 be 🙏 to 🙏 Wharton 🙏

</p>
</details>
