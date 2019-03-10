param(
    [Parameter(Mandatory = $false)]
    $deploymentSource = $PSScriptRoot,
    [Parameter(Mandatory = $false)]
    $deploymentDirectory = 'd:\home\data\SitePackages',
    [Parameter(Mandatory = $false)]
    $deploymentTemp = $env:DEPLOYMENT_TEMP,
    [Parameter(Mandatory = $false)]
    $project = "$deploymentSource\vandelay.web\vandelay.web.csproj",
    [Parameter(Mandatory = $false)]
    $testProject = "$deploymentSource\vandelay.xunittests\vandelay.xunittests.csproj",
    [Parameter(Mandatory = $false)]
    [bool]$randomizePackageName = $true
)
$ErrorActionPreference = 'stop'
$global:ProgressPreference = 'silentlycontinue'

function exitWithMessageOnError($errorMessage) {
    if ($? -eq $false) {
        Write-Output "An error has occurred during web site deployment: $errorMessage"
        exit $LASTEXITCODE
    }
}

$projectName = (split-path $project -Leaf).Replace('.csproj', '')
$targetFile = if ($randomizePackageName) {
    "$($projectName)-$(Get-Date -Format FileDateTime).zip"
} else {
    "$($projectName).zip"
}
$targetFilePath = "$deploymentDirectory\$targetFile"

# 1. Run tests
dotnet test --configuration Release $testProject
exitWithMessageOnError "Tests failed"

# 2. Build and publish
dotnet publish --configuration Release --output $deploymentTemp $project
exitWithMessageOnError "Publish failed"

# 3. Make zip file
New-Item -Path $deploymentDirectory -Type Directory -ErrorAction SilentlyContinue | Out-Null
Write-Output "Compressing content from $deploymentTemp\* to $targetFilePath"
Compress-Archive -Path $deploymentTemp\* -DestinationPath $targetFilePath
exitWithMessageOnError "Compression failed"

# 4. Set package ref.
$targetFile | Out-File -FilePath "$deploymentDirectory\packagename.txt" `
    -Encoding ASCII -NoNewline
exitWithMessageOnError "Application publish failed"