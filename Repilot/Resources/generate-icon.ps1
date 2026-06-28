# Generates Resources\Repilot.ico - a multi-resolution PNG-compressed ICO
# (dark keycap + white "R", matching the MSIX tile art).
# Run with Windows PowerShell (System.Drawing): powershell.exe -NoProfile -File generate-icon.ps1
Add-Type -AssemblyName System.Drawing

$tile  = [System.Drawing.Color]::FromArgb(255, 233, 240, 250)  # E9F0FA  light tile
$face  = [System.Drawing.Color]::FromArgb(255, 45, 50, 59)     # 2D323B  keycap face
$base  = [System.Drawing.Color]::FromArgb(255, 32, 36, 43)     # 20242B  keycap base
$edge  = [System.Drawing.Color]::FromArgb(255, 58, 64, 73)     # 3A4049  keycap edge
$white = [System.Drawing.Color]::White

function Rounded($x, $y, $w, $h, $r) {
    $d = [single]($r * 2)
    $p = New-Object System.Drawing.Drawing2D.GraphicsPath
    $p.AddArc([single]$x, [single]$y, $d, $d, 180, 90)
    $p.AddArc([single]($x + $w - $d), [single]$y, $d, $d, 270, 90)
    $p.AddArc([single]($x + $w - $d), [single]($y + $h - $d), $d, $d, 0, 90)
    $p.AddArc([single]$x, [single]($y + $h - $d), $d, $d, 90, 90)
    $p.CloseFigure()
    return $p
}

function Draw-Key($g, $S, $ox, $oy) {
    $kc  = [single]($S * 0.64)
    $kx  = [single]($ox + ($S - $kc) / 2)
    $ky  = [single]($oy + ($S - $kc) / 2 - $S * 0.015)
    $r   = [single]($kc * 0.2)
    $lip = [single]($kc * 0.075)

    $bp = Rounded $kx ($ky + $lip) $kc $kc $r
    $bb = New-Object System.Drawing.SolidBrush($base)
    $g.FillPath($bb, $bp); $bb.Dispose(); $bp.Dispose()

    $fp = Rounded $kx $ky $kc $kc $r
    $fb = New-Object System.Drawing.SolidBrush($face)
    $g.FillPath($fb, $fp); $fb.Dispose()
    $pen = New-Object System.Drawing.Pen($edge, [single][Math]::Max(1.0, $kc * 0.02))
    $g.DrawPath($pen, $fp); $pen.Dispose(); $fp.Dispose()

    $font = New-Object System.Drawing.Font("Segoe UI", [single]($kc * 0.62), [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)
    $wb = New-Object System.Drawing.SolidBrush($white)
    $fmt = New-Object System.Drawing.StringFormat
    $fmt.Alignment = [System.Drawing.StringAlignment]::Center
    $fmt.LineAlignment = [System.Drawing.StringAlignment]::Center
    $tr = New-Object System.Drawing.RectangleF($kx, [single]($ky - $kc * 0.04), $kc, $kc)
    $g.DrawString("R", $font, $wb, $tr, $fmt)
    $font.Dispose(); $wb.Dispose()
}

function New-Master([int]$size) {
    $bmp = New-Object System.Drawing.Bitmap($size, $size, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
    $g.Clear([System.Drawing.Color]::Transparent)

    $pad = [single]($size * 0.04)
    $sz = [single]($size - 2 * $pad)
    $rp = Rounded $pad $pad $sz $sz ([single]($size * 0.22))
    $bg = New-Object System.Drawing.SolidBrush($tile)
    $g.FillPath($bg, $rp); $bg.Dispose(); $rp.Dispose()

    Draw-Key $g $size 0 0
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

$target = Join-Path $PSScriptRoot "Repilot.ico"
[System.IO.File]::WriteAllBytes($target, $out.ToArray())
$bw.Dispose(); $master.Dispose()
Write-Output "Wrote $target ($($out.Length) bytes)"
