# PowerShell script to remove Dart comments from .dart files in the lib directory, except for // ignore and // TODO: comments.
# This script now correctly handles string literals, URLs, keeps ignore and TODO comments, and excludes .g.dart and .freezed.dart files.

# Set the root directory of your Flutter project
$projectRoot = 'f:\Fun\Dev\holodex-notifier\holodex-notifier\holodex_notifier'
$libDir = Join-Path -Path $projectRoot -ChildPath 'lib'

# Get all .dart files in the lib directory and its subdirectories, excluding .g.dart and .freezed.dart files
$dartFiles = Get-ChildItem -Path $libDir -Filter "*.dart" -Recurse | Where-Object { $_.Name -notlike "*.g.dart" -and $_.Name -notlike "*.freezed.dart" }

if (-not $dartFiles) {
    Write-Host "No eligible .dart files found in '$libDir'."
    exit
}

foreach ($file in $dartFiles) {
    Write-Host "Processing file: $($file.FullName)"

    $fileContent = Get-Content -Path $file.FullName
    $newContent = @()
    $inMultiLineComment = $false
    $inSingleQuoteString = $false
    $inDoubleQuoteString = $false
    $inTripleSingleQuoteString = $false
    $inTripleDoubleQuoteString = $false

    foreach ($line in $fileContent) {
        $processedLine = ""
        $charArray = $line.ToCharArray()
        $isSpecialComment = $false # Flag for ignore or TODO comments

        for ($i = 0; $i -lt $charArray.Length; $i++) {
            $char = $charArray[$i]
            $nextChar = if ($i + 1 -lt $charArray.Length) { $charArray[$i + 1] } else { "" }
            $prevChar = if ($i - 1 -ge 0) { $charArray[$i - 1] } else { "" }

            if ($inMultiLineComment) {
                if ($char -eq "*" -and $nextChar -eq "/") {
                    $inMultiLineComment = $false
                    $i++ # Skip the next character '/'
                    continue # Skip adding comment chars to output
                }
                 continue # Skip adding comment chars to output
            }
            elseif ($inSingleQuoteString) {
                $processedLine += $char
                if ($char -eq "'" -and $prevChar -ne "\") {
                    $inSingleQuoteString = $false
                }
                continue
            }
            elseif ($inDoubleQuoteString) {
                $processedLine += $char
                if ($char -eq '"' -and $prevChar -ne "\") {
                    $inDoubleQuoteString = $false
                }
                continue
            }
            elseif ($inTripleSingleQuoteString) {
                $processedLine += $char
                if ($char -eq "'" -and $prevChar -eq "'" -and ($i + 1 -lt $charArray.Length) -and $nextChar -eq "'") {
                    $inTripleSingleQuoteString = $false
                    $processedLine += $nextChar # Add the next '
                    $i++ # Skip the next character '\''
                    continue
                }
                continue
            }
            elseif ($inTripleDoubleQuoteString) {
                 $processedLine += $char
                if ($char -eq '"' -and $prevChar -eq '"' -and ($i + 1 -lt $charArray.Length) -and $nextChar -eq '"') {
                    $inTripleDoubleQuoteString = $false
                    $processedLine += $nextChar # Add the next "
                    $i++ # Skip the next character '"'
                    continue
                }
                continue
            }
            elseif ($char -eq "/" -and $nextChar -eq "/") {
                # Single-line comment
                $commentPart = $line.Substring($i+2).TrimStart()
                if ($commentPart -like "ignore*" -or $commentPart -like "TODO*") { # Check for "ignore", "ignore_for_file" or "TODO"
                    $processedLine += "//" + $commentPart # Keep the special comment with the line
                    $isSpecialComment = $true
                }
                 break # Stop processing the rest of the line, either way
            }
            elseif ($char -eq "/" -and $nextChar -eq "*") {
                # Multi-line comment start
                $inMultiLineComment = $true
                $i++ # Skip the next character '*'
                continue # Skip adding comment chars to output
            }
            elseif ($char -eq "'") {
                if ($prevChar -ne '\') {
                    if (($i + 2 -lt $charArray.Length) -and $nextChar -eq "'" -and  $charArray[$i+2] -eq "'") {
                        $inTripleSingleQuoteString = -not $inTripleSingleQuoteString # Toggle triple single quote string state
                        $processedLine += "'''"
                        $i+=2
                        continue
                    } else {
                        $inSingleQuoteString = -not $inSingleQuoteString # Toggle single quote string state
                    }
                }
                 $processedLine += $char
                 continue
            }
            elseif ($char -eq '"') {
                 if ($prevChar -ne '\') {
                    if (($i + 2 -lt $charArray.Length) -and $nextChar -eq '"' -and  $charArray[$i+2] -eq '"') {
                        $inTripleDoubleQuoteString = -not $inTripleDoubleQuoteString # Toggle triple double quote string state
                        $processedLine += '"""'
                        $i+=2
                        continue
                    } else {
                        $inDoubleQuoteString = -not $inDoubleQuoteString # Toggle double quote string state
                    }
                }
                $processedLine += $char
                continue
            }
            else {
                $processedLine += $char
            }
        }
        if ($isSpecialComment -or $inMultiLineComment) { # Keep full line if it's a special comment or inside multiline comment (for proper closing detection)
            $newContent += $line
        } else {
            $newContent += $processedLine
        }
    }

    # Write the new content back to the file
    Set-Content -Path $file.FullName -Value $newContent -Encoding UTF8
    Write-Host "Comments removed from: $($file.FullName)"
}

Write-Host "Script finished."