param(
    [string]$InputPath = "assets/raw/ui/title/ui_common_title_atlas_v1.png",
    [string]$OutputDir = "game/art/ui/title"
)

Add-Type -AssemblyName System.Drawing
$source = [System.Drawing.Bitmap]::FromFile((Resolve-Path $InputPath))
New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null
$names = @("victory", "defeat", "battle_result", "chapter_complete", "quest_log", "skills")
$cellWidth = [int]($source.Width / 2)
$cellHeight = [int]($source.Height / 3)
$frameInset = 6
for ($row = 0; $row -lt 3; $row++) {
    for ($column = 0; $column -lt 2; $column++) {
        $index = $row * 2 + $column
        $cropWidth = [int]($cellWidth - ($frameInset * 2))
        $cropHeight = [int]($cellHeight - ($frameInset * 2))
        $crop = [System.Drawing.Bitmap]::new($cropWidth, $cropHeight, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
        $graphics = [System.Drawing.Graphics]::FromImage($crop)
        $sourceX = [int]($column * $cellWidth)
        $sourceY = [int]($row * $cellHeight)
        $destinationRect = [System.Drawing.Rectangle]::new(0, 0, $crop.Width, $crop.Height)
        $sourceRect = [System.Drawing.Rectangle]::new($sourceX + $frameInset, $sourceY + $frameInset, $crop.Width, $crop.Height)
        $graphics.DrawImage($source, $destinationRect, $sourceRect, [System.Drawing.GraphicsUnit]::Pixel)
        $graphics.Dispose()

        # The atlas uses black as a removable background. Keep bright lettering and
        # its glow, while giving the antialiased dark edge a soft alpha ramp.
        for ($x = 0; $x -lt $crop.Width; $x++) {
            for ($y = 0; $y -lt $crop.Height; $y++) {
                $pixel = $crop.GetPixel($x, $y)
                $brightness = [int][Math]::Max($pixel.R, [Math]::Max($pixel.G, $pixel.B))
                if ($brightness -le 12) {
                    $alpha = 0
                } elseif ($brightness -ge 48) {
                    $alpha = 255
                } else {
                    $alpha = [int](($brightness - 12) * 255 / 36)
                }
                $crop.SetPixel($x, $y, [System.Drawing.Color]::FromArgb($alpha, $pixel.R, $pixel.G, $pixel.B))
            }
        }
        $crop.Save((Join-Path $OutputDir ("title_{0}_v1.png" -f $names[$index])), [System.Drawing.Imaging.ImageFormat]::Png)
        $crop.Dispose()
    }
}
$source.Dispose()
