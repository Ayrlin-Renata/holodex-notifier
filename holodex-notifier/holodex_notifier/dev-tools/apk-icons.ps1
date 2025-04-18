# Define input file paths
$backgroundImagePath = "F:\Fun\Dev\holodex-notifier\holodex-notifier\holodex_notifier\assets\images\holodex-notifier-icon-bg-full.png"
$foregroundImagePath = "F:\Fun\Dev\holodex-notifier\holodex-notifier\holodex_notifier\assets\images\holodex-notifier-icon-fg-full.png"

# Define output base directory
$outputBaseDir = "F:\Fun\Dev\holodex-notifier\holodex-notifier\holodex_notifier\android\app\src\main\res"

# Define required icon sizes for different densities (in dp)
$iconSizes = @{
    "mipmap-mdpi" = 48
    "mipmap-hdpi" = 72
    "mipmap-xhdpi" = 96
    "mipmap-xxhdpi" = 144
    "mipmap-xxxhdpi" = 192
}

# Loop through each density and resize/save the images
foreach ($densityFolder in $iconSizes.Keys) {
    $iconSize = $iconSizes[$densityFolder]

    # Create density folder if it doesn't exist
    $fullDensityDir = Join-Path -Path $outputBaseDir -ChildPath $densityFolder
    if (!(Test-Path -Path $fullDensityDir -PathType Container)) {
        New-Item -ItemType Directory -Path $fullDensityDir -Force | Out-Null
    }

    # Load background image and resize
    $backgroundBitmap = New-Object System.Drawing.Bitmap($backgroundImagePath)
    $resizedBackgroundBitmap = New-Object System.Drawing.Bitmap($iconSize, $iconSize)
    $graphics = [System.Drawing.Graphics]::FromImage($resizedBackgroundBitmap)
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $graphics.DrawImage($backgroundBitmap, 0, 0, $iconSize, $iconSize)
    $graphics.Dispose()

    # Save resized background image
    $backgroundOutputPath = Join-Path -Path $fullDensityDir -ChildPath "ic_launcher_background.png"
    $resizedBackgroundBitmap.Save($backgroundOutputPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $resizedBackgroundBitmap.Dispose()
    $backgroundBitmap.Dispose()


    # Load foreground image and resize
    $foregroundBitmap = New-Object System.Drawing.Bitmap($foregroundImagePath)
    $resizedForegroundBitmap = New-Object System.Drawing.Bitmap($iconSize, $iconSize)
    $graphics = [System.Drawing.Graphics]::FromImage($resizedForegroundBitmap)
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $graphics.DrawImage($foregroundBitmap, 0, 0, $iconSize, $iconSize)
    $graphics.Dispose()

    # Save resized foreground image
    $foregroundOutputPath = Join-Path -Path $fullDensityDir -ChildPath "ic_launcher_foreground.png"
    $resizedForegroundBitmap.Save($foregroundOutputPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $resizedForegroundBitmap.Dispose()
    $foregroundBitmap.Dispose()
}

Write-Host "Successfully resized and placed app icons in Android resource folders."