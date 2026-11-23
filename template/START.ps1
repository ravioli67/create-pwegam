$ErrorActionPreference = "Stop"

# Dot-source engine files in dependency order into the shared scope
. "$PSScriptRoot/engine/Native.ps1"
. "$PSScriptRoot/engine/Buffer.ps1"
. "$PSScriptRoot/engine/Renderer3D.ps1"
. "$PSScriptRoot/engine/Renderer2D.ps1"
. "$PSScriptRoot/engine/Engine.ps1"

# Initialize engine: 240x120 characters, 60 Target FPS
$Engine = [PwegamEngine]::new(240, 120, 60)

# Load user game script
$UserGamePath = Join-Path $PSScriptRoot "src/Game.ps1"
if (Test-Path $UserGamePath) {
    . $UserGamePath
} else {
    throw "Could not find src/Game.ps1"
}

# Run user initialization if defined, then start the master loop
if (Get-Command "Start-Game" -ErrorAction SilentlyContinue) {
    Start-Game -Engine $Engine
}

$Engine.Run()
