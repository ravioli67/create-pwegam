function create {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [string]$Target,

        [Parameter(Position = 1)]
        [string]$ProjectName
    )

    if (-not $Target -or $Target -notmatch '^pwegam(@.+)?$') {
        Write-Host "Usage: create pwegam@latest [project-name]" -ForegroundColor Yellow
        return
    }

    if ([string]::IsNullOrWhiteSpace($ProjectName)) {
        $ProjectName = Read-Host "Project name (default: my-pwegam-game)"
        if ([string]::IsNullOrWhiteSpace($ProjectName)) {
            $ProjectName = "my-pwegam-game"
        }
    }

    $dest = Join-Path (Get-Location) $ProjectName
    if (Test-Path $dest) {
        Write-Host "Error: Directory '$ProjectName' already exists." -ForegroundColor Red
        return
    }

    Write-Host "`nCreating~~~ " -ForegroundColor Cyan -NoNewline
    Start-Sleep -Milliseconds 350

    # Create folder tree
    New-Item -ItemType Directory -Path "$dest/engine", "$dest/src", "$dest/assets" -Force | Out-Null

    # 1. START.ps1
    @'
$ErrorActionPreference = "Stop"

. "$PSScriptRoot/engine/Native.ps1"
. "$PSScriptRoot/engine/Buffer.ps1"
. "$PSScriptRoot/engine/Renderer3D.ps1"
. "$PSScriptRoot/engine/Renderer2D.ps1"
. "$PSScriptRoot/engine/Engine.ps1"

$Engine = [PwegamEngine]::new(240, 120, 60)

$UserGamePath = Join-Path $PSScriptRoot "src/Game.ps1"
if (Test-Path $UserGamePath) {
    . $UserGamePath
} else {
    throw "Could not find src/Game.ps1"
}

if (Get-Command "Start-Game" -ErrorAction SilentlyContinue) {
    Start-Game -Engine $Engine
}

$Engine.Run()
'@ | Set-Content -Path "$dest/START.ps1" -Encoding UTF8

    # 2. engine/Native.ps1
    @'
if (-not ("Windows.Native.Kernel32" -as [type])) {
    Add-Type -TypeDefinition @"
    namespace Windows.Native {
        using System;
        using System.ComponentModel;
        using System.IO;
        using System.Runtime.InteropServices;

        public class Kernel32 {
            public const uint FILE_SHARE_READ = 1;
            public const uint FILE_SHARE_WRITE = 2;
            public const uint GENERIC_READ = 0x80000000;
            public const uint GENERIC_WRITE = 0x40000000;
            public static readonly IntPtr INVALID_HANDLE_VALUE = new IntPtr(-1);

            [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
            public class CONSOLE_FONT_INFOEX {
                private int cbSize;
                public CONSOLE_FONT_INFOEX() {
                    this.cbSize = Marshal.SizeOf(typeof(CONSOLE_FONT_INFOEX));
                }
                public int FontIndex;
                public short FontWidth;
                public short FontHeight;
                public int FontFamily;
                public int FontWeight;
                [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)]
                public string FaceName;
            }

            [DllImport("kernel32.dll", SetLastError = true)]
            public static extern bool CloseHandle(IntPtr hHandle);

            [DllImport("kernel32.dll", CharSet = CharSet.Auto, SetLastError = true)]
            public static extern IntPtr CreateFile(
                [MarshalAs(UnmanagedType.LPTStr)] string filename,
                uint access, uint share, IntPtr securityAttributes,
                [MarshalAs(UnmanagedType.U4)] FileMode creationDisposition,
                uint flagsAndAttributes, IntPtr templateFile);

            [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
            public static extern bool GetCurrentConsoleFontEx(
                IntPtr hConsoleOutput, bool bMaximumWindow,
                [In, Out] CONSOLE_FONT_INFOEX lpConsoleCurrentFont);

            [DllImport("kernel32.dll", SetLastError = true)]
            public static extern bool SetCurrentConsoleFontEx(
                IntPtr ConsoleOutput, bool MaximumWindow,
                [In, Out] CONSOLE_FONT_INFOEX ConsoleCurrentFontEx);

            public static void SetSquareFont(short size) {
                IntPtr hFile = CreateFile("CONOUT$", GENERIC_READ | GENERIC_WRITE,
                    FILE_SHARE_READ | FILE_SHARE_WRITE, IntPtr.Zero, FileMode.Open, 0U, IntPtr.Zero);
                if (hFile == INVALID_HANDLE_VALUE) return;
                try {
                    CONSOLE_FONT_INFOEX cfi = new CONSOLE_FONT_INFOEX();
                    if (GetCurrentConsoleFontEx(hFile, false, cfi)) {
                        cfi.FontIndex = 0;
                        cfi.FontWidth = size;
                        cfi.FontHeight = size;
                        cfi.FontFamily = 48;
                        cfi.FontWeight = 400;
                        cfi.FaceName = "Terminal";
                        SetCurrentConsoleFontEx(hFile, false, cfi);
                    }
                } finally {
                    CloseHandle(hFile);
                }
            }
        }

        public class User32 {
            [DllImport("user32.dll")]
            public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);

            [DllImport("user32.dll", CharSet = CharSet.Auto, ExactSpelling = true)]
            public static extern short GetAsyncKeyState(int virtualKeyCode);
        }
    }
"@
}

class Input {
    static [bool] IsKeyDown([int]$vKey) {
        $u32 = "Windows.Native.User32" -as [type]
        return ($u32::GetAsyncKeyState($vKey) -band 0x8000) -ne 0
    }
    static [bool] IsKeyDown([string]$key) {
        $u32 = "Windows.Native.User32" -as [type]
        $code = [int][char]::ToUpper($key)
        return ($u32::GetAsyncKeyState($code) -band 0x8000) -ne 0
    }
}

class TerminalHost {
    static [void] Initialize([int]$width, [int]$height) {
        [Console]::CursorVisible = $false
        $k32 = "Windows.Native.Kernel32" -as [type]
        $u32 = "Windows.Native.User32" -as [type]
        $k32::SetSquareFont(8)
        try {
            $global:host.UI.RawUI.BufferSize = [Management.Automation.Host.Size]::new($width, $height)
            $global:host.UI.RawUI.WindowSize = [Management.Automation.Host.Size]::new($width, $height)
        } catch {}
        $hwnd = (Get-Process -Id $global:PID).MainWindowHandle
        if ($hwnd -ne [IntPtr]::Zero) {
            $u32::ShowWindowAsync($hwnd, 3) | Out-Null
        }
        Clear-Host
    }
}
'@ | Set-Content -Path "$dest/engine/Native.ps1" -Encoding UTF8

    # 3. engine/Buffer.ps1
    @'
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
'@ | Set-Content -Path "$dest/engine/Buffer.ps1" -Encoding UTF8

    # 4. Copy your working Renderer3D.ps1, Renderer2D.ps1, Engine.ps1, Game.ps1, and cube.obj
    # (Or paste their here-strings right here so the CLI is 100% standalone!)
    Copy-Item "$PSScriptRoot/template/*" -Destination $dest -Recurse -Force -ErrorAction SilentlyContinue

    Write-Host "Done!" -ForegroundColor Green
    Write-Host "`n  cd $ProjectName" -ForegroundColor White
    Write-Host "  pwsh ./START.ps1`n" -ForegroundColor DarkGray
}

Export-ModuleMember -Function create
