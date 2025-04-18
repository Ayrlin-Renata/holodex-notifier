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

# Define input image configurations
$imageConfigurations = @(
    @{
        ImagePath = "F:\Fun\Dev\holodex-notifier\holodex-notifier\holodex_notifier\assets\images\holodex-notifier-icon-bg-full.png"
        OutputFileName = "ic_launcher_background"
    }
    @{
        ImagePath = "F:\Fun\Dev\holodex-notifier\holodex-notifier\holodex_notifier\assets\images\holodex-notifier-icon-fg-full.png"
        OutputFileName = "ic_launcher_foreground"
    }
    @{
        ImagePath = "F:\Fun\Dev\holodex-notifier\holodex-notifier\holodex_notifier\assets\images\holodex-notifier-notification-icon.png"
        OutputFileName = "notification_icon"
    }
)

# Loop through each density and resize/save the images for each configuration
foreach ($densityFolder in $iconSizes.Keys) {
    $iconSize = $iconSizes[$densityFolder]

    # Create density folder if it doesn't exist
    $fullDensityDir = Join-Path -Path $outputBaseDir -ChildPath $densityFolder
    if (!(Test-Path -Path $fullDensityDir -PathType Container)) {
        New-Item -ItemType Directory -Path $fullDensityDir -Force | Out-Null
    }

    # Loop through each image configuration
    foreach ($imageConfig in $imageConfigurations) {
        $imagePath = $imageConfig.ImagePath
        $outputFileName = $imageConfig.OutputFileName

        # Load image and resize
        $sourceBitmap = New-Object System.Drawing.Bitmap($imagePath)
        $resizedBitmap = New-Object System.Drawing.Bitmap($iconSize, $iconSize)
        $graphics = [System.Drawing.Graphics]::FromImage($resizedBitmap)
        $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $graphics.DrawImage($sourceBitmap, 0, 0, $iconSize, $iconSize)
        $graphics.Dispose()

        # Save resized image
        $outputPath = Join-Path -Path $fullDensityDir -ChildPath "$outputFileName.png"
        $resizedBitmap.Save($outputPath, [System.Drawing.Imaging.ImageFormat]::Png)
        $resizedBitmap.Dispose()
        $sourceBitmap.Dispose()
    }
}

Write-Host "Successfully resized and placed app icons in Android resource folders."