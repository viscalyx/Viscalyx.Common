<#
    .SYNOPSIS
        Pulls the latest changes from the upstream branch, optionally checking out a specified branch first.

    .DESCRIPTION
        The Receive-GitBranch command pulls the latest changes from the upstream branch.
        It can optionally checkout a specified local branch first if the -Checkout switch
        is used. When the -Rebase switch is used, it fetches the upstream branch and
        rebases the local branch using the fetched upstream branch instead of merging.

    .PARAMETER BranchName
        Specifies the name of the local branch. If -Checkout is specified, this branch
        will be checked out first. If not specified, defaults to 'main'.

    .PARAMETER UpstreamBranchName
        Specifies the name of the upstream branch to pull from. If not specified,
        defaults to 'main'. This parameter is used when rebasing to specify the
        upstream branch for rebase operations.

    .PARAMETER RemoteName
        Specifies the name of the remote repository. If not specified, defaults to 'origin'.

    .PARAMETER Checkout
        Specifies that the command should checkout the specified branch before pulling.
        By default, the command operates on the current branch.

    .PARAMETER Rebase
        Specifies that the command should fetch the upstream branch and rebase
        the local branch using the fetched upstream branch instead of merging.

    .PARAMETER Path
        Specifies the path to the git repository directory. If not specified,
        uses the current directory. When specified, the function will temporarily
        change to this directory to perform git operations.

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
        Receive-GitBranch

        Pulls the latest changes into the current branch using the default git pull behavior.

    .EXAMPLE
        Receive-GitBranch -Checkout -BranchName 'feature-branch'

        Checks out the 'feature-branch' and pulls the latest changes using the
        default git pull behavior.

    .EXAMPLE
        Receive-GitBranch -Rebase

        Fetches the upstream changes and rebases the current branch using the upstream branch.

    .EXAMPLE
        Receive-GitBranch -Checkout -BranchName 'feature-branch' -UpstreamBranchName 'develop' -Rebase

        Checks out the 'feature-branch', fetches changes from the 'develop' upstream
        branch, and rebases the local branch using the upstream 'develop' branch.

    .EXAMPLE
        Receive-GitBranch -RemoteName 'upstream' -UpstreamBranchName 'main' -Rebase

        Fetches changes from the 'main' branch on the 'upstream' remote and rebases
        the current branch using those changes.

    .EXAMPLE
        Receive-GitBranch -Path 'C:\repos\MyProject' -Checkout -BranchName 'feature-branch'

        Temporarily changes to the 'C:\repos\MyProject' directory, checks out the
        'feature-branch', pulls the latest changes, and then returns to the original directory.

    .NOTES
        This function requires Git to be installed and accessible from the command line.

        If you have configured 'git config --global pull.rebase true', the command's
        default behavior will perform a rebase using git pull even without the -Rebase
        switch.
#>
function Receive-GitBranch
{
    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType()]
    param
    (
        [Parameter()]
        [System.String]
        $BranchName = 'main',

        [Parameter()]
        [System.String]
        $UpstreamBranchName = 'main',

        [Parameter()]
        [System.String]
        $RemoteName = 'origin',

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Checkout,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Rebase,

        [Parameter()]
        [System.String]
        $Path,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Force
    )

    if ($Force.IsPresent -and -not $Confirm)
    {
        $ConfirmPreference = 'None'
    }

    # Use current location if Path is not specified
    if (-not $PSBoundParameters.ContainsKey('Path'))
    {
        $Path = (Get-Location).Path
    }

    # Determine the ShouldProcess messages based on parameters
    if ($Checkout.IsPresent -and $Rebase.IsPresent)
    {
        $descriptionMessage = $script:localizedData.Receive_GitBranch_CheckoutRebase_ShouldProcessVerboseDescription -f $BranchName, $RemoteName, $UpstreamBranchName
        $confirmationMessage = $script:localizedData.Receive_GitBranch_CheckoutRebase_ShouldProcessVerboseWarning -f $BranchName, $RemoteName, $UpstreamBranchName
        $captionMessage = $script:localizedData.Receive_GitBranch_CheckoutRebase_ShouldProcessCaption
    }
    elseif ($Checkout.IsPresent)
    {
        $descriptionMessage = $script:localizedData.Receive_GitBranch_CheckoutPull_ShouldProcessVerboseDescription -f $BranchName
        $confirmationMessage = $script:localizedData.Receive_GitBranch_CheckoutPull_ShouldProcessVerboseWarning -f $BranchName
        $captionMessage = $script:localizedData.Receive_GitBranch_CheckoutPull_ShouldProcessCaption
    }
    elseif ($Rebase.IsPresent)
    {
        $descriptionMessage = $script:localizedData.Receive_GitBranch_Rebase_ShouldProcessVerboseDescription -f $RemoteName, $UpstreamBranchName
        $confirmationMessage = $script:localizedData.Receive_GitBranch_Rebase_ShouldProcessVerboseWarning -f $RemoteName, $UpstreamBranchName
        $captionMessage = $script:localizedData.Receive_GitBranch_Rebase_ShouldProcessCaption
    }
    else
    {
        $descriptionMessage = $script:localizedData.Receive_GitBranch_Pull_ShouldProcessVerboseDescription
        $confirmationMessage = $script:localizedData.Receive_GitBranch_Pull_ShouldProcessVerboseWarning
        $captionMessage = $script:localizedData.Receive_GitBranch_Pull_ShouldProcessCaption
    }

    if ($PSCmdlet.ShouldProcess($descriptionMessage, $confirmationMessage, $captionMessage))
    {
        # Checkout the specified branch if requested
        if ($Checkout.IsPresent)
        {
            Write-Verbose -Message ($script:localizedData.Receive_GitBranch_CheckoutBranch -f $BranchName)

            try
            {
                Invoke-Git -Path $Path -Arguments @('checkout', $BranchName) -ErrorAction 'Stop'
            }
            catch
            {
                $errorMessage = $script:localizedData.Receive_GitBranch_FailedCheckout -f $BranchName

                $newException = New-Exception -Message $errorMessage -ErrorRecord $_

                $errorMessageParameters = @{
                    Message      = $errorMessage
                    Category     = 'InvalidOperation'
                    ErrorId      = 'RGB0001' # cspell: disable-line
                    TargetObject = $BranchName
                    Exception    = $newException
                }

                Write-Error @errorMessageParameters
                return
            }
        }

        if ($Rebase.IsPresent)
        {
            # Fetch upstream changes
            Write-Verbose -Message ($script:localizedData.Receive_GitBranch_FetchUpstream -f $UpstreamBranchName, $RemoteName)

            try
            {
                Invoke-Git -Path $Path -Arguments @('fetch', $RemoteName, $UpstreamBranchName) -ErrorAction 'Stop'
            }
            catch
            {
                $errorMessage = $script:localizedData.Receive_GitBranch_FailedFetch -f $RemoteName, $UpstreamBranchName

                $newException = New-Exception -Message $errorMessage -ErrorRecord $_

                $errorMessageParameters = @{
                    Message      = $errorMessage
                    Category     = 'InvalidOperation'
                    ErrorId      = 'RGB0002' # cspell: disable-line
                    TargetObject = $UpstreamBranchName
                    Exception    = $newException
                }

                Write-Error @errorMessageParameters
                return
            }

            # Rebase local branch with upstream
            Write-Verbose -Message ($script:localizedData.Receive_GitBranch_RebaseWithUpstream -f $RemoteName, $UpstreamBranchName)

            try
            {
                Invoke-Git -Path $Path -Arguments @('rebase', "$RemoteName/$UpstreamBranchName") -ErrorAction 'Stop'
            }
            catch
            {
                $errorMessage = $script:localizedData.Receive_GitBranch_FailedRebase -f $RemoteName, $UpstreamBranchName

                $newException = New-Exception -Message $errorMessage -ErrorRecord $_

                $errorMessageParameters = @{
                    Message      = $errorMessage
                    Category     = 'InvalidOperation'
                    ErrorId      = 'RGB0003' # cspell: disable-line
                    TargetObject = $UpstreamBranchName
                    Exception    = $newException
                }

                Write-Error @errorMessageParameters
                return
            }
        }
        else
        {
            # Use git pull with default behavior
            Write-Verbose -Message ($script:localizedData.Receive_GitBranch_PullChanges)

            try
            {
                Invoke-Git -Path $Path -Arguments @('pull') -ErrorAction 'Stop'
            }
            catch
            {
                $newException = New-Exception -Message $script:localizedData.Receive_GitBranch_FailedPull -ErrorRecord $_

                $errorMessageParameters = @{
                    Message      = $script:localizedData.Receive_GitBranch_FailedPull
                    Category     = 'InvalidOperation'
                    ErrorId      = 'RGB0004' # cspell: disable-line
                    TargetObject = $null
                    Exception    = $newException
                }

                Write-Error @errorMessageParameters
                return
            }
        }

        Write-Verbose -Message ($script:localizedData.Receive_GitBranch_Success)
    }
}
