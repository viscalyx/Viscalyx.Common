Function ConvertTo-DiffString([string]$text, [string]$color) {
    $ansiSequence = "`e[$color"
    $resetSequence = "`e[0m"
    $formattedText = "$ansiSequence$text$resetSequence"
    Write-Host $formattedText
    Write-Information -MessageData $formattedText -InformationAction Continue
    Write-Verbose -Message $formattedText -Verbose
    return $formattedText
}

Write-Color "This is red text" "31m"
Write-Color "This is green text" "32m"
Write-Color "This is yellow text" "33m"
Write-Color "This is blue text" "34m"
Write-Color "This is magenta text" "35m"
Write-Color "This is cyan text" "36m"
Write-Color "This is white text" "37m"

# ANSI escape sequence for inverting text color with a light red background
Write-Color "This is inverted text with a light red background" "7;101m"

# Black text and light read background
Write-Color "This is inverted text with a light red background" "`e[30;101m"

# Blue text on yellow background
Write-Color "This is blue text on a yellow background" "34;43m"

# White text on black background
Write-Color "This is white text on a black background" "37;40m"

# Black text on white background
Write-Color "This is black text on a white background" "30;47m"

# Yellow text on blue background
Write-Color "This is yellow text on a blue background" "33;44m"

# White text on green background
Write-Color "This is white text on a green background" "37;42m"

# Magenta text on cyan background
Write-Color "This is magenta text on a cyan background" "35;46m"

# Black text on yellow background !!!
Write-Color "This is black text on a yellow background" "30;43m"

# Cyan text on black background
Write-Color "This is cyan text on a black background" "36;40m"

# Green on Black
Write-Color "This is green text on a black background" "32;40m"

# Black on Green
Write-Color "This is black text on a green background" "30;42m"

# Cyan on Black
Write-Color "This is cyan text on a black background" "36;40m"

# Black on Cyan
Write-Color "This is black text on a cyan background" "30;46m"
