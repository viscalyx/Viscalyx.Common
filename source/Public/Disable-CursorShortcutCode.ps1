<#
    .SYNOPSIS
        Disables the Cursor shortcuts by renaming the 'code' and 'code.cmd' files.

    .DESCRIPTION
        This script searches for the Cursor path in the system's PATH variable and
        renames the 'code' and 'code.cmd' files to disable the Cursor shortcuts.

    .EXAMPLE
        Disable-CursorShortcuts
#>
function Disable-CursorShortcutCode
{
    # Get the directories in the $env:Path
    $pathDirs = $env:Path.Split([System.IO.Path]::PathSeparator)

    # Search for the Cursor path
    $cursorPath = $pathDirs | Where-Object -FilterScript { $_ -match 'Cursor' }

    if (-not $cursorPath)
    {
        Write-Information 'Cursor path not found in the PATH variable.' -InformationAction 'Continue'
        return
    }

    # Check if the necessary files exist
    $codeCmdPath = Join-Path -Path $cursorPath -ChildPath 'code.cmd'
    $codePath = Join-Path -Path $cursorPath -ChildPath 'code'

    if (Test-Path $codeCmdPath)
    {
        Rename-Item -Path $codeCmdPath -NewName 'code.cmd.old'
        Write-Information 'Renamed code.cmd to code.cmd.old' -InformationAction 'Continue'
    }
    else
    {
        Write-Information "File 'code.cmd' not found in the Cursor path." -InformationAction 'Continue'
    }

    if (Test-Path $codePath)
    {
        Rename-Item -Path $codePath -NewName 'code.old'
        Write-Information 'Renamed code to code.old' -InformationAction 'Continue'
    }
    else
    {
        Write-Information "File 'code' not found in the Cursor path." -InformationAction 'Continue'
    }
}
