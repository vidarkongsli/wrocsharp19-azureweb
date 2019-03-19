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

# Run tests
dotnet test --configuration Release $testProject
exitWithMessageOnError "Tests failed"

# Build and publish
dotnet publish --configuration Release --output $deploymentTemp $project
exitWithMessageOnError "Publish failed"

# Defining variables
$projectName = (split-path $project -Leaf).Replace('.csproj', '')
Write-Output "`$projectName is $projectName"
$targetFile = "$($projectName)-$(Get-Date -Format FileDateTime).zip"
Write-Output "`$targetFile is $targetFile"
$targetFilePath = "$deploymentDirectory\$targetFile"
Write-Output "`$targetFilePath is $targetFilePath"

# Make zip file
New-Item -Path $deploymentDirectory -Type Directory -ErrorAction SilentlyContinue | Out-Null
Write-Output "Compressing content from $deploymentTemp\* to $targetFilePath"
Compress-Archive -Path $deploymentTemp\* -DestinationPath $targetFilePath
exitWithMessageOnError "Compression failed"

# Set package ref.
$targetFile | Out-File -FilePath "$deploymentDirectory\packagename.txt" `
    -Encoding ASCII -NoNewline
exitWithMessageOnError "Application publish failed"