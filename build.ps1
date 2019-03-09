& $PSScriptRoot\deploy2.ps1 `
    -deploymentDirecctory "$($PSScriptRoot)\dist" `
    -deploymentTemp "$env:temp\___deployTemp$(-join ((48..57) * 32 | Get-Random -Count 32 | ForEach-Object {[char]$_}))" `
