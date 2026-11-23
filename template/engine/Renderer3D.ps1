class Vec3 {
    [double]$X; [double]$Y; [double]$Z
    Vec3([double]$x, [double]$y, [double]$z) { $this.X = $x; $this.Y = $y; $this.Z = $z }
}

class Mesh3D {
    [Vec3[]]$Vertices
    [object[]]$Faces
    [Vec3]$Position = [Vec3]::new(0, 0, 0)
    [Vec3]$Rotation = [Vec3]::new(0, 0, 0)
    [double]$Scale = 1.0

    static [Mesh3D] LoadObj([string]$path, [double]$scale) {
        $vList = [System.Collections.Generic.List[Vec3]]::new()
        $fList = [System.Collections.Generic.List[object]]::new()

        foreach ($line in (Get-Content $path)) {
            $parts = $line.Trim() -split '\s+'
            if ($parts.Count -ge 4 -and $parts[0] -eq 'v') {
                $vList.Add([Vec3]::new(
                    [double]$parts[1],
                    [double]$parts[2],
                    [double]$parts[3]
                ))
            }
            elseif ($parts.Count -ge 4 -and $parts[0] -eq 'f') {
                $v1 = [int](($parts[1] -split '/')[0]) - 1
                $v2 = [int](($parts[2] -split '/')[0]) - 1
                $v3 = [int](($parts[3] -split '/')[0]) - 1
                $fList.Add(@($v1, $v2, $v3))
            }
        }

        $mesh = [Mesh3D]::new()
        $mesh.Vertices = $vList.ToArray()
        $mesh.Faces = $fList.ToArray()
        $mesh.Scale = $scale
        return $mesh
    }
}

class Renderer3D {
    [string]$ShadeRamp = " .:-=+*#%@"
    [char]$WireChar = '.'
    [bool]$DrawWireframe = $true
    [bool]$DrawFill = $true
    [double]$Fov = 90.0
    [Vec3]$CameraPos = [Vec3]::new(0, 0, -50)
    [Vec3]$LightDir = [Vec3]::new(0.4, 0.7, -0.6)

    [void] SetRenderMode([int]$mode) {
        switch ($mode) {
            1 { $this.DrawWireframe = $true;  $this.DrawFill = $true }
            2 { $this.DrawWireframe = $false; $this.DrawFill = $true }
            3 { $this.DrawWireframe = $true;  $this.DrawFill = $false }
        }
    }

    [void] DrawMesh([Mesh3D]$mesh, [object]$buf) {
        $cx = $buf.Width / 2.0
        $cy = $buf.Height / 2.0
        $fovRad = 1.0 / [Math]::Tan(($this.Fov * 0.5) * [Math]::PI / 180.0)
        $aspect = ($buf.Height / [double]$buf.Width) * 2.0

        $cosX = [Math]::Cos($mesh.Rotation.X); $sinX = [Math]::Sin($mesh.Rotation.X)
        $cosY = [Math]::Cos($mesh.Rotation.Y); $sinY = [Math]::Sin($mesh.Rotation.Y)
        $cosZ = [Math]::Cos($mesh.Rotation.Z); $sinZ = [Math]::Sin($mesh.Rotation.Z)

        $worldVerts = New-Object Vec3[] $mesh.Vertices.Count
        for ($i = 0; $i -lt $mesh.Vertices.Count; $i++) {
            $v = $mesh.Vertices[$i]
            $x = $v.X * $mesh.Scale; $y = $v.Y * $mesh.Scale; $z = $v.Z * $mesh.Scale

            $y1 = $y * $cosX - $z * $sinX; $z1 = $y * $sinX + $z * $cosX
            $x2 = $x * $cosY + $z1 * $sinY; $z2 = -$x * $sinY + $z1 * $cosY
            $x3 = $x2 * $cosZ - $y1 * $sinZ; $y3 = $x2 * $sinZ + $y1 * $cosZ

            $worldVerts[$i] = [Vec3]::new(
                $x3 + $mesh.Position.X - $this.CameraPos.X,
                $y3 + $mesh.Position.Y - $this.CameraPos.Y,
                $z2 + $mesh.Position.Z - $this.CameraPos.Z
            )
        }

        foreach ($f in $mesh.Faces) {
            $p1 = $worldVerts[$f[0]]
            $p2 = $worldVerts[$f[1]]
            $p3 = $worldVerts[$f[2]]
            if ($p1.Z -le 1 -or $p2.Z -le 1 -or $p3.Z -le 1) { continue }

            $ux = $p2.X - $p1.X; $uy = $p2.Y - $p1.Y; $uz = $p2.Z - $p1.Z
            $vx = $p3.X - $p1.X; $vy = $p3.Y - $p1.Y; $vz = $p3.Z - $p1.Z
            $nx = $uy * $vz - $uz * $vy
            $ny = $uz * $vx - $ux * $vz
            $nz = $ux * $vy - $uy * $vx
            $len = [Math]::Sqrt($nx*$nx + $ny*$ny + $nz*$nz)
            if ($len -eq 0) { continue }
            $nx /= $len; $ny /= $len; $nz /= $len

            if (($nx * $p1.X + $ny * $p1.Y + $nz * $p1.Z) -ge 0) { continue }

            $s1 = [Vec3]::new(($p1.X * $fovRad * $aspect / $p1.Z) * $cx + $cx, (-$p1.Y * $fovRad / $p1.Z) * $cy + $cy, $p1.Z)
            $s2 = [Vec3]::new(($p2.X * $fovRad * $aspect / $p2.Z) * $cx + $cx, (-$p2.Y * $fovRad / $p2.Z) * $cy + $cy, $p2.Z)
            $s3 = [Vec3]::new(($p3.X * $fovRad * $aspect / $p3.Z) * $cx + $cx, (-$p3.Y * $fovRad / $p3.Z) * $cy + $cy, $p3.Z)

            if ($this.DrawFill) {
                $lum = [Math]::Max(0.1, ($nx * $this.LightDir.X + $ny * $this.LightDir.Y + $nz * $this.LightDir.Z))
                $shadeIdx = [Math]::Min($this.ShadeRamp.Length - 1, [int]($lum * $this.ShadeRamp.Length))
                $this.FillTriangle($s1, $s2, $s3, $this.ShadeRamp[$shadeIdx], $buf)
            }
            if ($this.DrawWireframe) {
                $this.DrawLine([int]$s1.X, [int]$s1.Y, [int]$s2.X, [int]$s2.Y, $this.WireChar, $buf)
                $this.DrawLine([int]$s2.X, [int]$s2.Y, [int]$s3.X, [int]$s3.Y, $this.WireChar, $buf)
                $this.DrawLine([int]$s3.X, [int]$s3.Y, [int]$s1.X, [int]$s1.Y, $this.WireChar, $buf)
            }
        }
    }

    [void] FillTriangle([Vec3]$v1, [Vec3]$v2, [Vec3]$v3, [char]$ch, [object]$buf) {
        $minX = [Math]::Max(0, [int][Math]::Floor([Math]::Min($v1.X, [Math]::Min($v2.X, $v3.X))))
        $maxX = [Math]::Min($buf.Width - 1, [int][Math]::Ceiling([Math]::Max($v1.X, [Math]::Max($v2.X, $v3.X))))
        $minY = [Math]::Max(0, [int][Math]::Floor([Math]::Min($v1.Y, [Math]::Min($v2.Y, $v3.Y))))
        $maxY = [Math]::Min($buf.Height - 1, [int][Math]::Ceiling([Math]::Max($v1.Y, [Math]::Max($v2.Y, $v3.Y))))

        $denom = (($v2.Y - $v3.Y) * ($v1.X - $v3.X) + ($v3.X - $v2.X) * ($v1.Y - $v3.Y))
        if ([Math]::Abs($denom) -lt 0.0001) { return }

        for ($y = $minY; $y -le $maxY; $y++) {
            for ($x = $minX; $x -le $maxX; $x++) {
                $w1 = (($v2.Y - $v3.Y) * ($x - $v3.X) + ($v3.X - $v2.X) * ($y - $v3.Y)) / $denom
                $w2 = (($v3.Y - $v1.Y) * ($x - $v3.X) + ($v1.X - $v3.X) * ($y - $v3.Y)) / $denom
                $w3 = 1.0 - $w1 - $w2
                if ($w1 -ge 0 -and $w2 -ge 0 -and $w3 -ge 0) {
                    $z = $w1 * $v1.Z + $w2 * $v2.Z + $w3 * $v3.Z
                    $buf.SetPixelDepth($x, $y, $z, $ch)
                }
            }
        }
    }

    [void] DrawLine([int]$x0, [int]$y0, [int]$x1, [int]$y1, [char]$ch, [object]$buf) {
        $dx = [Math]::Abs($x1 - $x0); $sx = if ($x0 -lt $x1) { 1 } else { -1 }
        $dy = -[Math]::Abs($y1 - $y0); $sy = if ($y0 -lt $y1) { 1 } else { -1 }
        $err = $dx + $dy
        while ($true) {
            $buf.SetPixel($x0, $y0, $ch)
            if ($x0 -eq $x1 -and $y0 -eq $y1) { break }
            $e2 = 2 * $err
            if ($e2 -ge $dy) { $err += $dy; $x0 += $sx }
            if ($e2 -le $dx) { $err += $dx; $y0 += $sy }
        }
    }
}
