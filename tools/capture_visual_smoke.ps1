$ErrorActionPreference = "Stop"

$ProjectRoot = Split-Path -Parent $PSScriptRoot
$Godot = "E:\Godot\Godot_v4.7-stable_win64.exe"
$OutputDir = Join-Path $ProjectRoot "test-output"
$ScreenshotPath = Join-Path $OutputDir "main-scene-smoke.png"
$MinimumBrightPixels = 1000

if (-not (Test-Path -LiteralPath $Godot)) {
    throw "Godot executable not found: $Godot"
}

New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null

Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Windows.Forms
Add-Type @"
using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;

public struct RECT {
    public int Left;
    public int Top;
    public int Right;
    public int Bottom;
}

public static class Win32Capture {
    public delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);

    [DllImport("user32.dll")]
    public static extern bool EnumWindows(EnumWindowsProc enumProc, IntPtr lParam);

    [DllImport("user32.dll")]
    public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint processId);

    [DllImport("user32.dll")]
    public static extern bool IsWindowVisible(IntPtr hWnd);

    [DllImport("user32.dll")]
    public static extern bool GetWindowRect(IntPtr hWnd, out RECT rect);

    [DllImport("user32.dll")]
    public static extern bool SetForegroundWindow(IntPtr hWnd);

    [DllImport("user32.dll")]
    public static extern bool PrintWindow(IntPtr hWnd, IntPtr hdcBlt, int nFlags);

    public static IntPtr FindLargestWindowForProcess(uint targetProcessId) {
        IntPtr best = IntPtr.Zero;
        int bestArea = 0;
        EnumWindows(delegate(IntPtr hWnd, IntPtr lParam) {
            uint processId;
            GetWindowThreadProcessId(hWnd, out processId);
            if (processId != targetProcessId || !IsWindowVisible(hWnd)) {
                return true;
            }
            RECT rect;
            if (!GetWindowRect(hWnd, out rect)) {
                return true;
            }
            int width = Math.Max(0, rect.Right - rect.Left);
            int height = Math.Max(0, rect.Bottom - rect.Top);
            int area = width * height;
            if (width > 200 && height > 200 && area > bestArea) {
                best = hWnd;
                bestArea = area;
            }
            return true;
        }, IntPtr.Zero);
        return best;
    }
}
"@

$arguments = "--path `"$ProjectRoot`""
$process = Start-Process -FilePath $Godot -ArgumentList $arguments -PassThru
try {
    $handle = [IntPtr]::Zero
    for ($i = 0; $i -lt 40; $i++) {
        Start-Sleep -Milliseconds 250
        $process.Refresh()
        if ($process.HasExited) {
            throw "Godot exited before a screenshot could be captured."
        }
        $handle = [Win32Capture]::FindLargestWindowForProcess([uint32]$process.Id)
        if ($handle -ne [IntPtr]::Zero) {
            break
        }
    }

    Start-Sleep -Seconds 8

    if ($handle -eq [IntPtr]::Zero) {
        throw "Godot window handle for launched process was not found."
    }

    $rect = New-Object RECT
    if (-not [Win32Capture]::GetWindowRect($handle, [ref]$rect)) {
        throw "Could not read Godot window rectangle."
    }

    $width = [Math]::Max(1, $rect.Right - $rect.Left)
    $height = [Math]::Max(1, $rect.Bottom - $rect.Top)
    $bitmap = New-Object System.Drawing.Bitmap($width, $height)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $hdc = $graphics.GetHdc()
    $printed = [Win32Capture]::PrintWindow($handle, $hdc, 2)
    $graphics.ReleaseHdc($hdc)
    $graphics.Dispose()
    if (-not $printed) {
        $bitmap.Dispose()
        throw "PrintWindow failed for the launched Godot window."
    }
    $bitmap.Save($ScreenshotPath, [System.Drawing.Imaging.ImageFormat]::Png)

    $brightPixels = 0
    $step = 4
    for ($y = 0; $y -lt $bitmap.Height; $y += $step) {
        for ($x = 0; $x -lt $bitmap.Width; $x += $step) {
            $pixel = $bitmap.GetPixel($x, $y)
            if (($pixel.R + $pixel.G + $pixel.B) -gt 460) {
                $brightPixels++
            }
        }
    }
    $bitmap.Dispose()

    if ($brightPixels -lt $MinimumBrightPixels) {
        throw "Screenshot looks blank or missing text. Bright pixel count: $brightPixels"
    }

    Write-Host "Visual smoke screenshot saved: $ScreenshotPath"
    Write-Host "Bright pixel count: $brightPixels"
}
finally {
    if ($process -and -not $process.HasExited) {
        $process.CloseMainWindow() | Out-Null
        Start-Sleep -Milliseconds 500
        if (-not $process.HasExited) {
            $process.Kill()
        }
    }
}
