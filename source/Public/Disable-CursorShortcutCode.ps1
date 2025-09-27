<#
    .SYNOPSIS
        Disables the Cursor shortcuts by renaming the 'code' and 'code.cmd' files.

    .DESCRIPTION
        This script searches for the Cursor path in the system's PATH variable and
        renames the 'code' and 'code.cmd' files to disable the Cursor shortcuts.

    .PARAMETER Force
        Specifies that the operation will be forced and override any previous backed
        up shortcuts.

    .INPUTS
        None

        This function does not accept pipeline input.

    .OUTPUTS
        None

        This function does not return any output.

    .EXAMPLE
        Disable-CursorShortcutCode

        Disables Cursor shortcuts by renaming 'code' and 'code.cmd' files to '.old' extensions.

    .EXAMPLE
        Disable-CursorShortcutCode -Force

        Disables Cursor shortcuts and forces overwrite of any existing '.old' backup files.

    .NOTES
        This function searches for Cursor installation paths in the system PATH variable.
        If multiple Cursor paths are found, the function will throw an error.
        Files are renamed with '.old' extension to preserve them for later restoration.
#>
function Disable-CursorShortcutCode
{
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType()]
    param
    (
        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Force
    )

    if ($Force.IsPresent -and -not $Confirm)
    {
        $ConfirmPreference = 'None'
    }

    # Get the directories in the $env:Path
    $pathDirs = $env:Path.Split([System.IO.Path]::PathSeparator)

    # Search for the Cursor path
    $cursorPath = $pathDirs | Where-Object -FilterScript { $_ -match 'Cursor' }

    if (-not $cursorPath)
    {
        Write-Information -MessageData $script:localizedData.Disable_CursorShortcutCode_CursorPathNotFound -InformationAction 'Continue'

        return
    }

    if ($cursorPath.Count -gt 1)
    {
        $errorMessageParameters = @{
            Message = $script:localizedData.Disable_CursorShortcutCode_MultipleCursorPaths
            Category = 'InvalidResult'
            ErrorId = 'DCSC0002' # cspell: disable-line
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
        $shouldProcessDescription = $script:localizedData.Disable_CursorShortcutCode_RenameCodeCmd_ShouldProcessDescription -f $cursorPath
        $shouldProcessConfirmation = $script:localizedData.Disable_CursorShortcutCode_RenameCodeCmd_ShouldProcessConfirmation
        $shouldProcessCaption = $script:localizedData.Disable_CursorShortcutCode_RenameCodeCmd_ShouldProcessCaption

        if ($PSCmdlet.ShouldProcess($shouldProcessDescription, $shouldProcessConfirmation, $shouldProcessCaption))
        {
            Move-Item -Path $codeCmdPath -Destination $codeCmdPathDestination -Force:$Force -Verbose:$VerbosePreference -ErrorAction 'Stop'

            Write-Information -MessageData $script:localizedData.Disable_CursorShortcutCode_RenamedCodeCmd -InformationAction 'Continue'
        }
    }
    else
    {
        Write-Information -MessageData $script:localizedData.Disable_CursorShortcutCode_CodeCmdNotFound -InformationAction 'Continue'
    }

    if (Test-Path $codePath)
    {
        $shouldProcessDescription = $script:localizedData.Disable_CursorShortcutCode_RenameCode_ShouldProcessDescription -f $cursorPath
        $shouldProcessConfirmation = $script:localizedData.Disable_CursorShortcutCode_RenameCode_ShouldProcessConfirmation
        $shouldProcessCaption = $script:localizedData.Disable_CursorShortcutCode_RenameCode_ShouldProcessCaption

        if ($PSCmdlet.ShouldProcess($shouldProcessDescription, $shouldProcessConfirmation, $shouldProcessCaption))
        {
            Move-Item -Path $codePath -Destination $codePathDestination -Force:$Force -Verbose:$VerbosePreference -ErrorAction 'Stop'

            Write-Information -MessageData $script:localizedData.Disable_CursorShortcutCode_RenamedCode -InformationAction 'Continue'
        }
    }
    else
    {
        Write-Information -MessageData $script:localizedData.Disable_CursorShortcutCode_CodeNotFound -InformationAction 'Continue'
    }
}
