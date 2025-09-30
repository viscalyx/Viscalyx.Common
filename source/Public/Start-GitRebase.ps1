<#
    .SYNOPSIS
        Starts a Git rebase operation from a remote branch.

    .DESCRIPTION
        The Start-GitRebase command initiates a rebase operation from a remote
        branch onto the current branch. It uses the Invoke-Git command to
        execute the git rebase operation.

    .PARAMETER RemoteName
        Specifies the name of the remote repository. If not specified, defaults to 'origin'.

    .PARAMETER Branch
        Specifies the name of the branch to rebase from. If not specified, defaults to 'main'.

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
        Start-GitRebase

        Starts a rebase from the 'origin/main' branch onto the current branch.

    .EXAMPLE
        Start-GitRebase -RemoteName 'upstream' -Branch 'develop'

        Starts a rebase from the 'upstream/develop' branch onto the current branch.

    .EXAMPLE
        Start-GitRebase -Path 'C:\repos\MyProject'

        Starts a rebase from 'origin/main' onto the current branch in the
        'C:\repos\MyProject' repository.

    .NOTES
        This function requires Git to be installed and accessible from the command line.
#>
function Start-GitRebase
{
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType()]
    param
    (
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $RemoteName = 'origin',

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Branch = 'main',

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

    $remoteBranch = '{0}/{1}' -f $RemoteName, $Branch

    $shouldProcessVerboseDescription = $script:localizedData.Start_GitRebase_ShouldProcessVerboseDescription -f $remoteBranch
    $shouldProcessVerboseWarning = $script:localizedData.Start_GitRebase_ShouldProcessVerboseWarning -f $remoteBranch
    $shouldProcessCaption = $script:localizedData.Start_GitRebase_ShouldProcessCaption

    if ($PSCmdlet.ShouldProcess($shouldProcessVerboseDescription, $shouldProcessVerboseWarning, $shouldProcessCaption))
    {
        Write-Verbose -Message ($script:localizedData.Start_GitRebase_RebasingFrom -f $remoteBranch)

        $invokeGitParameters = @{
            Path      = $Path
            Arguments = @('rebase', $remoteBranch)
        }

        try
        {
            Invoke-Git @invokeGitParameters -ErrorAction 'Stop'

            Write-Verbose -Message $script:localizedData.Start_GitRebase_Success
        }
        catch
        {
            $errorMessage = $script:localizedData.Start_GitRebase_FailedRebase -f $remoteBranch

            $newException = New-Exception -Message $errorMessage -ErrorRecord $_

            $errorMessageParameters = @{
                Message      = $errorMessage
                Category     = 'InvalidOperation'
                ErrorId      = 'SGR0001' # cspell: disable-line
                TargetObject = $remoteBranch
                Exception    = $newException
            }

            Write-Error @errorMessageParameters

            return
        }
    }
}
