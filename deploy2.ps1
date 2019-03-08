param(
    [Parameter(Mandatory = $false)]
    $deploymentSource = $PSScriptRoot,
    [Parameter(Mandatory = $false)]
    $deploymentTarget = $env:DEPLOYMENT_TARGET,
    $deploymentTemp = $env:DEPLOYMENT_TEMP,
    $project = "$deploymentSource\vandelay.web\vandelay.web.csproj",
    $testProject = "$deploymentSource\vandelay.xunittests\vandelay.xunittests.csproj"
)
$ErrorActionPreference = 'stop'

function exitWithMessageOnError($errorMessage) {
    if ($? -eq $false) {
        Write-Output "An error has occurred during web site deployment: $errorMessage"
        exit $LASTEXITCODE
    }
}

$projectName = (split-path $project -Leaf).Replace('.csproj', '')
$targetFile = "$deploymentTarget\$($projectName)-$(Get-Date -Format FileDateTime).zip"

# 1. Restore nuget packages
dotnet restore $project
exitWithMessageOnError "Restore failed"

dotnet test $testProject
exitWithMessageOnError "Tests failed"

# 2. Build and publish
dotnet publish --no-restore --output $deploymentTemp $project
exitWithMessageOnError "Publish failed"

if (-not(Test-Path $deploymentTarget)) { mkdir $deploymentTarget | Out-Null }
Compress-Archive -Path $deploymentTemp -DestinationPath $targetFile
exitWithMessageOnError "Compression failed"
