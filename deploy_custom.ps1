param(
    [Parameter(Mandatory = $false)]
    $deploymentSource = $PSScriptRoot,
    [Parameter(Mandatory = $false)]
    $deploymentDirectory = 'd:\home\data\SitePackages',
    $deploymentTemp = $env:DEPLOYMENT_TEMP,
    $project = "$deploymentSource\vandelay.web\vandelay.web.csproj",
    $testProject = "$deploymentSource\vandelay.xunittests\vandelay.xunittests.csproj"
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
$targetFile = "$deploymentDirectory\$($projectName)-$(Get-Date -Format FileDateTime).zip"

# 1. Run tests
dotnet test $testProject
exitWithMessageOnError "Tests failed"

# 2. Build and publish
dotnet publish --no-restore --output $deploymentTemp $project
exitWithMessageOnError "Publish failed"

# 3. Make zip file
mkdir $deploymentDirectory -ErrorAction SilentlyContinue | Out-Null
Write-Output "Compressing content from $deploymentTemp\* to $targetFile"
Compress-Archive -Path $deploymentTemp\* -DestinationPath $targetFile
exitWithMessageOnError "Compression failed"

# 4. Set package ref.
$targetFile | Out-File -FilePath "$deploymentDirectory\packagename.txt" `
    -Encoding ASCII -NoNewline
exitWithMessageOnError "Application publish failed"