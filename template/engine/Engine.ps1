class PwegamEngine {
    [object]$Buffer
    [object]$Renderer3D
    [object]$Renderer2D
    [int]$TargetFPS
    [double]$CurrentFPS = 0
    [bool]$Running = $false

    PwegamEngine([int]$width, [int]$height, [int]$targetFps) {
        ("TerminalHost" -as [type])::Initialize($width, $height)
        $actualW = [Math]::Min($width, [Console]::WindowWidth - 1)
        $actualH = [Math]::Min($height, [Console]::WindowHeight - 1)
        $this.Buffer     = ("ScreenBuffer" -as [type])::new($actualW, $actualH)
        $this.Renderer3D = ("Renderer3D" -as [type])::new()
        $this.Renderer2D = ("Renderer2D" -as [type])::new()
        $this.TargetFPS  = $targetFps
    }


    [object] Load3DModel([string]$path, [double]$scale) {
        return ("Mesh3D" -as [type])::LoadObj($path, $scale)
    }

    [void] Render3D([object]$mesh) {
        $this.Renderer3D.DrawMesh($mesh, $this.Buffer)
    }

    [void] Render2D([object]$sprite) {
        $this.Renderer2D.DrawSprite($sprite, $this.Buffer)
    }

    [void] DrawText([int]$x, [int]$y, [string]$text) {
        $this.Renderer2D.DrawText($x, $y, $text, $this.Buffer)
    }

    [void] Run() {
        $this.Running = $true
        $sw = [System.Diagnostics.Stopwatch]::New()
        $dt = 1.0 / $this.TargetFPS
        $inputType = "Input" -as [type]

        try {
            while ($this.Running) {
                $sw.Restart()
                $this.Buffer.Clear()

                # Press ESC (0x1B) to quit
                if ($inputType::IsKeyDown(0x1B)) { $this.Running = $false }

                # Execute user's Update-Game function
                if (Get-Command "Update-Game" -ErrorAction SilentlyContinue) {
                    Update-Game -Engine $this -DeltaTime $dt
                }

                $this.Buffer.Present()

                # Frame rate limiter
                $targetMs = 1000.0 / $this.TargetFPS
                $elapsedMs = $sw.Elapsed.TotalMilliseconds
                if ($elapsedMs -lt $targetMs) {
                    [System.Threading.Thread]::Sleep([int]($targetMs - $elapsedMs))
                }

                $dt = $sw.Elapsed.TotalSeconds
                if ($dt -gt 0) { $this.CurrentFPS = [Math]::Round(1.0 / $dt, 1) }
            }
        } finally {
            [Console]::CursorVisible = $true
            Clear-Host
        }
    }
}
