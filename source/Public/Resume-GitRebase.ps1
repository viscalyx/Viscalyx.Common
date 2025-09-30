<#
    .SYNOPSIS
        Resumes a Git rebase operation after resolving conflicts.

    .DESCRIPTION
        The Resume-GitRebase command resumes a rebase operation after conflicts
        have been resolved, or skips the current commit during a rebase. It uses
        the Invoke-Git command to execute the git rebase operation. The command
        validates that the repository is in a rebase state before proceeding.

    .PARAMETER Path
        Specifies the path to the git repository directory. If not specified,
        uses the current directory.

    .PARAMETER Skip
        Skips the current commit and continues the rebase operation. If not
        specified, the command will continue the rebase with the resolved changes.

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
        Resume-GitRebase

        Resumes the rebase operation in the current directory after conflicts
        have been resolved.

    .EXAMPLE
        Resume-GitRebase -Skip

        Skips the current commit and continues the rebase operation in the
        current directory.

    .EXAMPLE
        Resume-GitRebase -Path 'C:\repos\MyProject'

        Resumes the rebase operation in the 'C:\repos\MyProject' repository
        after conflicts have been resolved.

    .NOTES
        This function requires Git to be installed and accessible from the
        command line. The repository must be in a rebase state for this command
        to succeed.
#>
function Resume-GitRebase
{
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType()]
    param
    (
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Path = (Get-Location).Path,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Skip,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Force
    )

    if ($Force.IsPresent -and -not $Confirm)
    {
        $ConfirmPreference = 'None'
    }

    # Check if repository is in rebase state
    $rebaseMergePath = Join-Path -Path $Path -ChildPath '.git' | Join-Path -ChildPath 'rebase-merge'
    $rebaseApplyPath = Join-Path -Path $Path -ChildPath '.git' | Join-Path -ChildPath 'rebase-apply'

    $isRebasing = (Test-Path -Path $rebaseMergePath) -or (Test-Path -Path $rebaseApplyPath)

    if (-not $isRebasing)
    {
        $errorMessage = $script:localizedData.Resume_GitRebase_NotInRebaseState

        $newException = New-Exception -Message $errorMessage

        $errorMessageParameters = @{
            Message      = $errorMessage
            Category     = 'InvalidOperation'
            ErrorId      = 'RGRE0001' # cspell: disable-line
            TargetObject = $Path
            Exception    = $newException
        }

        Write-Error @errorMessageParameters

        return
    }

    if ($Skip.IsPresent)
    {
        $action = 'skip'
        $shouldProcessVerboseDescription = $script:localizedData.Resume_GitRebase_Skip_ShouldProcessVerboseDescription
        $shouldProcessVerboseWarning = $script:localizedData.Resume_GitRebase_Skip_ShouldProcessVerboseWarning
        $shouldProcessCaption = $script:localizedData.Resume_GitRebase_Skip_ShouldProcessCaption
        $successMessage = $script:localizedData.Resume_GitRebase_Skip_Success
    }
    else
    {
        $action = 'continue'
        $shouldProcessVerboseDescription = $script:localizedData.Resume_GitRebase_Continue_ShouldProcessVerboseDescription
        $shouldProcessVerboseWarning = $script:localizedData.Resume_GitRebase_Continue_ShouldProcessVerboseWarning
        $shouldProcessCaption = $script:localizedData.Resume_GitRebase_Continue_ShouldProcessCaption
        $successMessage = $script:localizedData.Resume_GitRebase_Continue_Success
    }

    if ($PSCmdlet.ShouldProcess($shouldProcessVerboseDescription, $shouldProcessVerboseWarning, $shouldProcessCaption))
    {
        Write-Verbose -Message ($script:localizedData.Resume_GitRebase_Resuming -f $action)

        $invokeGitParameters = @{
            Path      = $Path
            Arguments = @('rebase', "--$action")
        }

        try
        {
            Invoke-Git @invokeGitParameters -ErrorAction 'Stop'

            Write-Verbose -Message $successMessage
        }
        catch
        {
            $errorMessage = $script:localizedData.Resume_GitRebase_FailedRebase -f $action

            $newException = New-Exception -Message $errorMessage -ErrorRecord $_

            $errorMessageParameters = @{
                Message      = $errorMessage
                Category     = 'InvalidOperation'
                ErrorId      = 'RGRE0002' # cspell: disable-line
                TargetObject = $action
                Exception    = $newException
            }

            Write-Error @errorMessageParameters

            return
        }
    }
}
