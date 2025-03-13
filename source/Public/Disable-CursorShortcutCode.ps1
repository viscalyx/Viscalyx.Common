<#
    .SYNOPSIS
        Disables the Cursor shortcuts by renaming the 'code' and 'code.cmd' files.

    .DESCRIPTION
        This script searches for the Cursor path in the system's PATH variable and
        renames the 'code' and 'code.cmd' files to disable the Cursor shortcuts.

    .PARAMETER Force
        Specifies that the operation will be forced and override any previous backed
        up shortcuts.

    .EXAMPLE
        Disable-CursorShortcuts
#>
function Disable-CursorShortcutCode
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Force
    )

    # Get the directories in the $env:Path
    $pathDirs = $env:Path.Split([System.IO.Path]::PathSeparator)

    # Search for the Cursor path
    $cursorPath = $pathDirs | Where-Object -FilterScript { $_ -match 'Cursor' }

    if (-not $cursorPath)
    {
        Write-Information 'Cursor path not found in the PATH environment variable. Exiting.' -InformationAction 'Continue'

        return
    }

    if ($cursorPath.Count -gt 1)
    {
        $errorMessageParameters = @{
            Message = 'More than one Cursor path was found in the PATH environment variable.'
            Category = 'InvalidResult'
            ErrorId = 'DCSC0001' # cspell: disable-line
            TargetObject = 'Path'
        }

        Write-Error @errorMessageParameters

        return
    }

    # Check if the necessary files exist
    $codeCmdPath = Join-Path -Path $cursorPath -ChildPath 'code.cmd'
    $codeCmdPathDestination = Join-Path -Path $cursorPath -ChildPath 'code.cmd.old'

    $codePath = Join-Path -Path $cursorPath -ChildPath 'code'
    $codePathDestination = Join-Path -Path $cursorPath -ChildPath 'code.old'

    if (Test-Path $codeCmdPath)
    {
        Move-Item -Path $codeCmdPath -Destination $codeCmdPathDestination -Force:$Force -Verbose:$VerbosePreference -ErrorAction 'Stop'

        Write-Information 'Renamed code.cmd to code.cmd.old' -InformationAction 'Continue'
    }
    else
    {
        Write-Information "File 'code.cmd' not found in the Cursor path. Skipping." -InformationAction 'Continue'
    }

    if (Test-Path $codePath)
    {
        Move-Item -Path $codePath -Destination $codePathDestination -Force:$Force -Verbose:$VerbosePreference -ErrorAction 'Stop'

        Write-Information 'Renamed code to code.old' -InformationAction 'Continue'
    }
    else
    {
        Write-Information "File 'code' not found in the Cursor path. Skipping." -InformationAction 'Continue'
    }
}
