
$ErrorActionPreference = "Stop"

$ModuleName = "create-pwegam"
$RepoOwner = "ravioli67"
$RepoName = "create-pwegam"
$Branch = "1.0"

$RepoUrl = "https://github.com/$RepoOwner/$RepoName/archive/refs/heads/$Branch.zip"

Write-Host "Installing $ModuleName..." -ForegroundColor Cyan

# Find PowerShell module directory
$UserModuleBase = Join-Path $HOME "Documents\PowerShell\Modules"

if (-not (Test-Path $UserModuleBase)) {
    New-Item -ItemType Directory -Path $UserModuleBase -Force | Out-Null
}

$InstallDir = Join-Path $UserModuleBase $ModuleName
$StageDir = Join-Path $UserModuleBase "$ModuleName-staging"
$BackupDir = Join-Path $UserModuleBase "$ModuleName-backup"

$TempRoot = Join-Path $env:TEMP "$ModuleName-install"
$TempZip = Join-Path $TempRoot "$ModuleName.zip"
$ExtractDir = Join-Path $TempRoot "extracted"

try {
    # Clean temporary files
    foreach ($Path in @($TempRoot, $StageDir, $BackupDir)) {
        if (Test-Path $Path) {
            Remove-Item $Path -Recurse -Force
        }
    }

    New-Item -ItemType Directory -Path $TempRoot -Force | Out-Null

    Write-Host "Downloading branch: $Branch..." -ForegroundColor Cyan

    # Use local files if running from the repository
    if ($PSScriptRoot -and
        (Test-Path (Join-Path $PSScriptRoot "$ModuleName.psm1"))) {

        $SourceDir = $PSScriptRoot
        Write-Host "Using local repository files." -ForegroundColor Gray
    }
    else {
        Invoke-WebRequest -Uri $RepoUrl -OutFile $TempZip

        Expand-Archive -Path $TempZip -DestinationPath $ExtractDir -Force

        $ExtractedRoot = Get-ChildItem $ExtractDir -Directory |
            Select-Object -First 1

        if (-not $ExtractedRoot) {
            throw "Could not find extracted repository."
        }

        $SourceDir = $ExtractedRoot.FullName
    }

    # Validate module
    $ModuleFile = Join-Path $SourceDir "$ModuleName.psm1"

    if (-not (Test-Path $ModuleFile)) {
        throw "Missing required module file: $ModuleName.psm1"
    }

    Write-Host "Module validated." -ForegroundColor Green

    # Stage installation
    New-Item -ItemType Directory -Path $StageDir -Force | Out-Null

    Get-ChildItem $SourceDir |
        Where-Object { $_.Name -ne "install.ps1" } |
        Copy-Item -Destination $StageDir -Recurse -Force

    # Backup existing installation
    if (Test-Path $InstallDir) {
        Write-Host "Backing up previous installation..." -ForegroundColor Yellow
        Move-Item $InstallDir $BackupDir
    }

    # Install new version
    try {
        Move-Item $StageDir $InstallDir
    }
    catch {
        if (Test-Path $BackupDir) {
            Move-Item $BackupDir $InstallDir
        }
        throw
    }

    # Import module
    Import-Module $ModuleName -Force -ErrorAction Stop

    # Remove backup after successful installation
    if (Test-Path $BackupDir) {
        Remove-Item $BackupDir -Recurse -Force
    }

    Write-Host ""
    Write-Host "====================================" -ForegroundColor Green
    Write-Host " $ModuleName installed successfully!" -ForegroundColor Green
    Write-Host "====================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Run the following command:" -ForegroundColor Cyan
    Write-Host "  create pwegam@latest my-game" -ForegroundColor White
    Write-Host ""
}
catch {
    Write-Host ""
    Write-Host "Installation failed!" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}
finally {
    if (Test-Path $TempRoot) {
        Remove-Item $TempRoot -Recurse -Force -ErrorAction SilentlyContinue
    }

    if (Test-Path $StageDir) {
        Remove-Item $StageDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}
