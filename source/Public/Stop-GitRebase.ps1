<#
    .SYNOPSIS
        Aborts an ongoing Git rebase operation.

    .DESCRIPTION
        The Stop-GitRebase command aborts an ongoing rebase operation and
        restores the branch to its previous state before the rebase started.
        It uses the Invoke-Git command to execute the git rebase abort operation.
        This command will only run if the repository is currently in a rebase state.

    .PARAMETER Path
        Specifies the path to the git repository directory. If not specified,
        uses the current directory.

    .PARAMETER Force
        Forces the operation to proceed without confirmation prompts when similar
        to -Confirm:$false.

    .INPUTS
        None

        This function does not accept pipeline input.

    .OUTPUTS
        None

        This function does not return any output.

    .EXAMPLE
        Stop-GitRebase

        Aborts the current rebase operation in the current directory.

    .EXAMPLE
        Stop-GitRebase -Path 'C:\repos\MyProject'

        Aborts the current rebase operation in the 'C:\repos\MyProject' repository.

    .NOTES
        This function requires Git to be installed and accessible from the command line.
        The repository must be in a rebase state for this command to execute.
#>
function Stop-GitRebase
{
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType()]
    param
    (
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Path = (Get-Location).Path,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Force
    )

    if ($Force.IsPresent -and -not $Confirm)
    {
        $ConfirmPreference = 'None'
    }

    # Check if the repository is in a rebase state
    $gitRebaseDirectory = Join-Path -Path $Path -ChildPath '.git/rebase-merge'
    $gitRebaseApplyDirectory = Join-Path -Path $Path -ChildPath '.git/rebase-apply'

    if (-not (Test-Path -Path $gitRebaseDirectory) -and -not (Test-Path -Path $gitRebaseApplyDirectory))
    {
        $errorMessage = $script:localizedData.Stop_GitRebase_NotInRebaseState

        $newException = New-Exception -Message $errorMessage

        $errorMessageParameters = @{
            Message      = $errorMessage
            Category     = 'InvalidOperation'
            ErrorId      = 'SPGR0001' # cspell: disable-line
            TargetObject = $Path
            Exception    = $newException
        }

        Write-Error @errorMessageParameters

        return
    }

    $shouldProcessVerboseDescription = $script:localizedData.Stop_GitRebase_ShouldProcessVerboseDescription
    $shouldProcessVerboseWarning = $script:localizedData.Stop_GitRebase_ShouldProcessVerboseWarning
    $shouldProcessCaption = $script:localizedData.Stop_GitRebase_ShouldProcessCaption

    if ($PSCmdlet.ShouldProcess($shouldProcessVerboseDescription, $shouldProcessVerboseWarning, $shouldProcessCaption))
    {
        Write-Verbose -Message $script:localizedData.Stop_GitRebase_AbortingRebase

        $invokeGitParameters = @{
            Path      = $Path
            Arguments = @('rebase', '--abort')
        }

        try
        {
            Invoke-Git @invokeGitParameters -ErrorAction 'Stop'

            Write-Verbose -Message $script:localizedData.Stop_GitRebase_Success
        }
        catch
        {
            $errorMessage = $script:localizedData.Stop_GitRebase_FailedAbort

            $newException = New-Exception -Message $errorMessage -ErrorRecord $_

            $errorMessageParameters = @{
                Message      = $errorMessage
                Category     = 'InvalidOperation'
                ErrorId      = 'SPGR0002' # cspell: disable-line
                TargetObject = $Path
                Exception    = $newException
            }

            Write-Error @errorMessageParameters

            return
        }
    }
}
