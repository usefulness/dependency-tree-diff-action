param(
    [string]$InputProject = $env:INPUT_PROJECT,
    [string]$InputConfiguration = $env:INPUT_CONFIGURATION,
    [string]$InputBaseRef = $env:INPUT_BASEREF,
    [string]$InputBuildRootDir = $env:INPUT_BUILD_ROOT_DIR,
    [string]$InputVersion = $env:INPUT_VERSION,
    [string]$InputAdditionalGradleArguments = $env:INPUT_ADDITIONAL_GRADLE_ARGUMENTS,
    [string]$InputDebug = $env:INPUT_DEBUG
)

$ErrorActionPreference = "Stop"

Set-Location $InputBuildRootDir

if ($InputVersion -eq "latest") {
    $latestRelease = Invoke-RestMethod -Uri "https://api.github.com/repos/JakeWharton/dependency-tree-diff/releases/latest"
    $downloadUrl = $latestRelease.assets | Where-Object { $_.name -eq "dependency-tree-diff.jar" } | Select-Object -ExpandProperty browser_download_url
    Invoke-WebRequest -Uri $downloadUrl -OutFile "dependency-tree-diff.jar"
} else {
    $downloadUrl = "https://github.com/JakeWharton/dependency-tree-diff/releases/download/$InputVersion/dependency-tree-diff.jar"
    Invoke-WebRequest -Uri $downloadUrl -OutFile "dependency-tree-diff.jar"
}

if ($InputProject -eq ":") {
    $InputProject = ""
}

if ($InputDebug -eq "true") {
    Write-Host "download finished"
    Write-Host "JAVA_HOME: $env:JAVA_HOME"
    java -version
}

$currentHead = git rev-parse HEAD

$cmd = "./gradlew.bat $InputAdditionalGradleArguments ${InputProject}:dependencies --configuration $InputConfiguration"
Invoke-Expression $cmd | Out-File -FilePath "dependency-tree-diff_dependencies-head.txt" -Encoding UTF8
git fetch --force origin "${InputBaseRef}:${InputBaseRef}" --no-tags
git switch --force $InputBaseRef
Invoke-Expression $cmd | Out-File -FilePath "dependency-tree-diff_dependencies-base.txt" -Encoding UTF8
java -jar dependency-tree-diff.jar dependency-tree-diff_dependencies-base.txt dependency-tree-diff_dependencies-head.txt | Out-File -FilePath "dependency-tree-diff_output.txt" -Encoding UTF8

if ($InputDebug -eq "true") {
    Write-Host "diff generated"
    Get-ChildItem -Force
    Resolve-Path "dependency-tree-diff_output.txt"
    Get-Location
}

$delimiter = -join ((1..40) | ForEach-Object { Get-Random -InputObject ([char[]]"0123456789abcdef") })

"text-diff<<$delimiter" | Out-File -FilePath $env:GITHUB_OUTPUT -Append -Encoding UTF8
Get-Content "dependency-tree-diff_output.txt" | Out-File -FilePath $env:GITHUB_OUTPUT -Append -Encoding UTF8
$delimiter | Out-File -FilePath $env:GITHUB_OUTPUT -Append -Encoding UTF8

$outputPath = Resolve-Path "dependency-tree-diff_output.txt"
$basePath = Resolve-Path "dependency-tree-diff_dependencies-base.txt"
$headPath = Resolve-Path "dependency-tree-diff_dependencies-head.txt"

"file-diff=$outputPath" | Out-File -FilePath $env:GITHUB_OUTPUT -Append -Encoding UTF8
"file-dependencies-base=$basePath" | Out-File -FilePath $env:GITHUB_OUTPUT -Append -Encoding UTF8
"file-dependencies-head=$headPath" | Out-File -FilePath $env:GITHUB_OUTPUT -Append -Encoding UTF8

git switch --detach $currentHead 