# Generates Resources\CopilotKeyRemapper.ico — a multi-resolution PNG-compressed ICO.
# Run with Windows PowerShell (System.Drawing): powershell.exe -NoProfile -File generate-icon.ps1
Add-Type -AssemblyName System.Drawing

function New-Master([int]$size) {
    $bmp = New-Object System.Drawing.Bitmap($size, $size, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
    $g.Clear([System.Drawing.Color]::Transparent)

    # Rounded-rect background with a blue -> purple gradient
    $pad = [int]($size * 0.06)
    $rectSize = $size - 2 * $pad
    $radius = [int]($size * 0.22)
    $rect = New-Object System.Drawing.Rectangle($pad, $pad, $rectSize, $rectSize)
    $path = New-Object System.Drawing.Drawing2D.GraphicsPath
    $d = $radius * 2
    $path.AddArc($rect.X, $rect.Y, $d, $d, 180, 90)
    $path.AddArc($rect.Right - $d, $rect.Y, $d, $d, 270, 90)
    $path.AddArc($rect.Right - $d, $rect.Bottom - $d, $d, $d, 0, 90)
    $path.AddArc($rect.X, $rect.Bottom - $d, $d, $d, 90, 90)
    $path.CloseFigure()

    $c1 = [System.Drawing.Color]::FromArgb(255, 38, 132, 255)   # blue
    $c2 = [System.Drawing.Color]::FromArgb(255, 138, 79, 255)   # purple
    $brush = New-Object System.Drawing.Drawing2D.LinearGradientBrush($rect, $c1, $c2, 55.0)
    $g.FillPath($brush, $path)

    # Keyboard glyph (Segoe Fluent Icons ) in white
    $glyph = [char]0xE765
    $font = New-Object System.Drawing.Font("Segoe Fluent Icons", [single]($size * 0.5), [System.Drawing.GraphicsUnit]::Pixel)
    $white = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
    $fmt = New-Object System.Drawing.StringFormat([System.Drawing.StringFormat]::GenericTypographic)
    $fmt.Alignment = [System.Drawing.StringAlignment]::Center
    $fmt.LineAlignment = [System.Drawing.StringAlignment]::Center
    $rectF = New-Object System.Drawing.RectangleF([single]$pad, [single]$pad, [single]$rectSize, [single]$rectSize)
    $g.DrawString([string]$glyph, $font, $white, $rectF, $fmt)

    $g.Dispose()
    return $bmp
}

$master = New-Master 256
$sizes = @(16, 24, 32, 48, 64, 128, 256)
$pngs = @()
foreach ($s in $sizes) {
    $resized = New-Object System.Drawing.Bitmap($s, $s, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $rg = [System.Drawing.Graphics]::FromImage($resized)
    $rg.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $rg.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $rg.Clear([System.Drawing.Color]::Transparent)
    $rg.DrawImage($master, 0, 0, $s, $s)
    $rg.Dispose()
    $ms = New-Object System.IO.MemoryStream
    $resized.Save($ms, [System.Drawing.Imaging.ImageFormat]::Png)
    $pngs += , $ms.ToArray()
    $resized.Dispose()
}

$out = New-Object System.IO.MemoryStream
$bw = New-Object System.IO.BinaryWriter($out)
$bw.Write([int16]0)              # reserved
$bw.Write([int16]1)              # type: icon
$bw.Write([int16]$sizes.Count)   # count
$offset = 6 + $sizes.Count * 16
for ($i = 0; $i -lt $sizes.Count; $i++) {
    $s = $sizes[$i]
    $bw.Write([byte]($(if ($s -ge 256) { 0 } else { $s })))  # width
    $bw.Write([byte]($(if ($s -ge 256) { 0 } else { $s })))  # height
    $bw.Write([byte]0)           # palette
    $bw.Write([byte]0)           # reserved
    $bw.Write([int16]1)          # planes
    $bw.Write([int16]32)         # bpp
    $bw.Write([int32]$pngs[$i].Length)
    $bw.Write([int32]$offset)
    $offset += $pngs[$i].Length
}
foreach ($png in $pngs) { $bw.Write($png) }
$bw.Flush()

$target = Join-Path $PSScriptRoot "CopilotKeyRemapper.ico"
[System.IO.File]::WriteAllBytes($target, $out.ToArray())
$bw.Dispose(); $master.Dispose()
Write-Output "Wrote $target ($($out.Length) bytes)"
