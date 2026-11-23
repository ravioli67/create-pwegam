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
        $code = [int][char]::ToUpper($key[0])
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
