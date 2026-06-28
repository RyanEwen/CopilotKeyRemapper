# Generates the MSIX visual assets (dark keycap + white "R") into Images\.
# Run with Windows PowerShell: powershell.exe -NoProfile -File generate-msix-images.ps1
Add-Type -AssemblyName System.Drawing

$imagesDir = Join-Path $PSScriptRoot "Images"
New-Item -ItemType Directory -Force $imagesDir | Out-Null

$tile  = [System.Drawing.Color]::FromArgb(255, 233, 240, 250)  # E9F0FA  light tile
$face  = [System.Drawing.Color]::FromArgb(255, 45, 50, 59)     # 2D323B  keycap face
$base  = [System.Drawing.Color]::FromArgb(255, 32, 36, 43)     # 20242B  keycap base (3D side)
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

# Draws the dark keycap bearing a white "R", centered in a square of side S at (ox, oy).
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

# Full-bleed light tile with the centered keycap (tiles, logos).
function New-Square([int]$size, [string]$path) {
    $bmp = New-Object System.Drawing.Bitmap($size, $size, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
    $g.Clear([System.Drawing.Color]::Transparent)
    $bg = New-Object System.Drawing.SolidBrush($tile)
    $g.FillRectangle($bg, 0, 0, $size, $size); $bg.Dispose()
    Draw-Key $g $size 0 0
    $g.Dispose()
    $bmp.Save((Join-Path $imagesDir $path), [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose()
    Write-Output "  $path ($size x $size)"
}

# Transparent splash with a centered rounded tile badge bearing the keycap.
function New-Splash([int]$w, [int]$h, [string]$path) {
    $bmp = New-Object System.Drawing.Bitmap($w, $h, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
    $g.Clear([System.Drawing.Color]::Transparent)
    $badge = [int]($h * 0.6)
    $bx = [int](($w - $badge) / 2); $by = [int](($h - $badge) / 2)
    $rp = Rounded $bx $by $badge $badge ([single]($badge * 0.22))
    $bg = New-Object System.Drawing.SolidBrush($tile)
    $g.FillPath($bg, $rp); $bg.Dispose(); $rp.Dispose()
    Draw-Key $g $badge $bx $by
    $g.Dispose()
    $bmp.Save((Join-Path $imagesDir $path), [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose()
    Write-Output "  $path ($w x $h)"
}

Write-Output "Generating MSIX images:"
New-Square 50  "StoreLogo.png"
New-Square 44  "Square44x44Logo.png"
New-Square 88  "Square44x44Logo.scale-200.png"
New-Square 24  "Square44x44Logo.targetsize-24_altform-unplated.png"
New-Square 150 "Square150x150Logo.png"
New-Square 300 "Square150x150Logo.scale-200.png"
New-Splash 620 300  "SplashScreen.png"
New-Splash 1240 600 "SplashScreen.scale-200.png"
Write-Output "Done."
