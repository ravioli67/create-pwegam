class Sprite2D {
    [object[]]$Frames
    [int]$CurrentFrame = 0
    [double]$AnimationFPS = 10.0
    [double]$Timer = 0.0
    [double]$X = 0
    [double]$Y = 0
    [char]$TransparentChar = ' '
    [bool]$Playing = $true

    Sprite2D([object[]]$frames, [double]$fps) {
        $this.Frames = $frames
        $this.AnimationFPS = $fps
    }

    [void] Update([double]$dt) {
        if (-not $this.Playing -or $this.Frames.Count -le 1 -or $this.AnimationFPS -le 0) { return }
        $this.Timer += $dt
        $frameTime = 1.0 / $this.AnimationFPS
        while ($this.Timer -ge $frameTime) {
            $this.Timer -= $frameTime
            $this.CurrentFrame = ($this.CurrentFrame + 1) % $this.Frames.Count
        }
    }
}

class Renderer2D {
    [void] DrawSprite([object]$sprite, [object]$buf) {
        if ($sprite.Frames.Count -eq 0) { return }
        $frame = $sprite.Frames[$sprite.CurrentFrame]
        $startX = [int][Math]::Round($sprite.X)
        $startY = [int][Math]::Round($sprite.Y)

        for ($row = 0; $row -lt $frame.Count; $row++) {
            $line = [string]$frame[$row]
            for ($col = 0; $col -lt $line.Length; $col++) {
                $ch = $line[$col]
                if ($ch -ne $sprite.TransparentChar) {
                    $buf.SetPixel($startX + $col, $startY + $row, $ch)
                }
            }
        }
    }

    [void] DrawText([int]$x, [int]$y, [string]$text, [object]$buf) {
        for ($i = 0; $i -lt $text.Length; $i++) {
            $buf.SetPixel($x + $i, $y, $text[$i])
        }
    }
}
