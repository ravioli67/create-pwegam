class ScreenBuffer {
    [int]$Width
    [int]$Height
    [char[]]$Chars
    [double[]]$Depth
    hidden [char[]]$BlankChars
    hidden [double[]]$BlankDepth

    ScreenBuffer([int]$width, [int]$height) {
        $this.Width = $width
        $this.Height = $height
        $size = $width * $height

        $this.Chars = New-Object char[] $size
        $this.Depth = New-Object double[] $size
        $this.BlankChars = ([string]::new([char]' ', $size)).ToCharArray()
        $this.BlankDepth = New-Object double[] $size

        for ($i = 0; $i -lt $size; $i++) {
            $this.BlankDepth[$i] = [double]::PositiveInfinity
        }

        $this.Clear()
    }

    [void] Clear() {
        [Array]::Copy($this.BlankChars, $this.Chars, $this.Chars.Length)
        [Array]::Copy($this.BlankDepth, $this.Depth, $this.Depth.Length)
    }

    [void] SetPixel([int]$x, [int]$y, [char]$ch) {
        if ($x -ge 0 -and $x -lt $this.Width -and $y -ge 0 -and $y -lt $this.Height) {
            $this.Chars[($y * $this.Width) + $x] = $ch
        }
    }

    [void] SetPixelDepth([int]$x, [int]$y, [double]$z, [char]$ch) {
        if ($x -ge 0 -and $x -lt $this.Width -and $y -ge 0 -and $y -lt $this.Height) {
            $idx = ($y * $this.Width) + $x
            if ($z -lt $this.Depth[$idx]) {
                $this.Depth[$idx] = $z
                $this.Chars[$idx] = $ch
            }
        }
    }

    [void] Present() {
        $sb = [System.Text.StringBuilder]::new(($this.Width + 2) * $this.Height)
        for ($y = 0; $y -lt $this.Height; $y++) {
            $sb.Append($this.Chars, $y * $this.Width, $this.Width)
            if ($y -lt $this.Height - 1) { $sb.Append("`n") }
        }
        [Console]::SetCursorPosition(0, 0)
        [Console]::Out.Write($sb.ToString())
    }
}
