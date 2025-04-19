remove_dart_comments.ps1
# PowerShell script to remove Dart comments from .dart files in the lib directory, except for // ignore comments.

# Set the root directory of your Flutter project
$projectRoot = 'f:\Fun\Dev\holodex-notifier\holodex-notifier\holodex_notifier'
$libDir = Join-Path -Path $projectRoot -ChildPath 'lib'

# Get all .dart files in the lib directory and its subdirectories
$dartFiles = Get-ChildItem -Path $libDir -Filter "*.dart" -Recurse

if (-not $dartFiles) {
    Write-Host "No .dart files found in '$libDir'."
    exit
}

foreach ($file in $dartFiles) {
    Write-Host "Processing file: $($file.FullName)"

    $fileContent = Get-Content -Path $file.FullName
    $newContent = @()
    $inMultiLineComment = $false

    foreach ($line in $fileContent) {
        $trimmedLine = $line

        if ($inMultiLineComment) {
            if ($trimmedLine -match '\*/') {
                $trimmedLine = $trimmedLine -replace '(?s).*?\*/', '' # Remove everything up to and including */
                $inMultiLineComment = $false
                if ($trimmedLine) { # Add remaining part of the line after */ processing
                    if ($trimmedLine -match '//') {
                        if ($trimmedLine -match '// ignore') {
                            $newContent += $trimmedLine
                        }
                    } else {
                        $newContent += $trimmedLine
                    }
                }
            }
            # If still in multi-line comment, skip the line
            continue
        }

        if ($trimmedLine -match '/\*') {
            if ($trimmedLine -notmatch '\*/') { # Multiline comment starts but doesn't end on this line
                $beforeComment = $trimmedLine -replace '(?s)/\*.*', '' # Keep content before /*
                if ($beforeComment -match '//') {
                    if ($beforeComment -match '// ignore') {
                        $newContent += $beforeComment
                    }
                } else {
                    $newContent += $beforeComment
                }
                $inMultiLineComment = $true
            } else { # Multiline comment starts and ends on the same line
                $trimmedLine = $trimmedLine -replace '(?s)/\*.*?\*/', ''
                 if ($trimmedLine -match '//') {
                    if ($trimmedLine -match '// ignore') {
                        $newContent += $trimmedLine
                    }
                } else {
                    $newContent += $trimmedLine
                }
            }
        }
        elseif ($trimmedLine -match '//') {
            if ($trimmedLine -match '// ignore') {
                $newContent += $trimmedLine
            }
        }
        else {
            $newContent += $trimmedLine
        }
    }

    # Write the new content back to the file
    Set-Content -Path $file.FullName -Value $newContent -Encoding UTF8
    Write-Host "Comments removed from: $($file.FullName)"
}

Write-Host "Script finished."