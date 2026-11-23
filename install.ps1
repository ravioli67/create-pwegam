$ErrorActionPreference = "Stop"

$User = "ravioli67"
$ModuleName = "create-pwegam"
$RepoUrl = "https://github.com"

$UserModuleBase = ($env:PSModulePath -split ';') | Where-Object { $_ -like "*$HOME*" } | Select-Object -First 1
if (-not $UserModuleBase) {
    $UserModuleBase = Join-Path $HOME "Documents\PowerShell\Modules"
}
$InstallDir = Join-Path $UserModuleBase $ModuleName

Write-Host "Installing $ModuleName..." -ForegroundColor Cyan

if (Test-Path $InstallDir) {
    Remove-Item -Recurse -Force $InstallDir
}
New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null

if ($PSScriptRoot -and (Test-Path (Join-Path $PSScriptRoot "create-pwegam.psm1"))) {
    Copy-Item -Path "$PSScriptRoot\*" -Destination $InstallDir -Recurse -Force -Exclude "install.ps1"
} else {
    $TempZip = Join-Path $env:TEMP "$ModuleName.zip"
    $TempExtract = Join-Path $env:TEMP "$ModuleName-extract"
    Invoke-WebRequest -Uri $RepoUrl -OutFile $TempZip
    if (Test-Path $TempExtract) { Remove-Item -Recurse -Force $TempExtract }
    Expand-Archive -Path $TempZip -DestinationPath $TempExtract -Force
    $ExtractedRoot = Get-ChildItem $TempExtract | Select-Object -First 1
    Copy-Item -Path "$($ExtractedRoot.FullName)\*" -Destination $InstallDir -Recurse -Force -Exclude "install.ps1"
    Remove-Item -Force $TempZip
    Remove-Item -Recurse -Force $TempExtract
}

Import-Module $ModuleName -Force

Write-Host "Installed! You can now run:" -ForegroundColor Green
Write-Host "  create pwegam@latest my-game`n" -ForegroundColor White
