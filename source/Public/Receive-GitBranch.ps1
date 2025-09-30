<#
    .SYNOPSIS
        Pulls the latest changes from the upstream branch, optionally checking out a specified branch first.

    .DESCRIPTION
        The Receive-GitBranch command pulls the latest changes from the upstream branch.
        It can optionally checkout a specified local branch first if the -Checkout switch
        is used. When the -Rebase switch is used, it fetches the upstream branch and
        rebases the local branch using the fetched upstream branch instead of merging.

        When BranchName and/or RemoteName are specified without -Checkout, the command
        performs a pull from the specified remote branch without switching the current
        branch first.

    .PARAMETER BranchName
        Specifies the name of the branch. When used with -Checkout, this branch will
        be checked out first. When used without -Checkout, specifies the remote branch
        to pull from. If not specified, defaults to '.' which is resolved to the
        current local branch name.

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
        uses the current directory. When specified, runs the git operations
        in the specified directory.

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
        Receive-GitBranch -RemoteName 'upstream' -BranchName 'feature-branch'

        Pulls changes from the 'feature-branch' on the 'upstream' remote into the
        current branch without checking out a different branch first.

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

        Sets the working directory to 'C:\repos\MyProject', checks out the
        'feature-branch', and pulls the latest changes.

    .NOTES
        This function requires Git to be installed and accessible from the command line.

        If you have configured 'git config --global pull.rebase true', the command's
        default behavior will perform a rebase using git pull even without the -Rebase
        switch.
#>
function Receive-GitBranch
{
    [CmdletBinding(SupportsShouldProcess = $true, DefaultParameterSetName = 'Default', ConfirmImpact = 'Medium')]
    [OutputType()]
    param
    (
        [Parameter()]
        [System.String]
        $BranchName = '.',

        [Parameter()]
        [System.String]
        $UpstreamBranchName = 'main',

        [Parameter()]
        [System.String]
        $RemoteName = 'origin',

        [Parameter(Mandatory = $true, ParameterSetName = 'Checkout')]
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

    if ($BranchName -eq '.')
    {
        $BranchName = Get-GitLocalBranchName -Current
    }

    # Use current location if Path is not specified
    if (-not $PSBoundParameters.ContainsKey('Path'))
    {
        $Path = (Get-Location).Path
    }

    # Checkout the specified branch if requested
    if ($Checkout.IsPresent)
    {
        $checkoutDescription = $script:localizedData.Receive_GitBranch_Checkout_ShouldProcessDescription -f $BranchName
        $checkoutWarning = $script:localizedData.Receive_GitBranch_Checkout_ShouldProcessConfirmation -f $BranchName
        $checkoutCaption = $script:localizedData.Receive_GitBranch_Checkout_ShouldProcessCaption

        if ($PSCmdlet.ShouldProcess($checkoutDescription, $checkoutWarning, $checkoutCaption))
        {
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
    }

    if ($Rebase.IsPresent)
    {
        # Fetch upstream changes
        $fetchDescription = $script:localizedData.Receive_GitBranch_Fetch_ShouldProcessDescription -f $UpstreamBranchName, $RemoteName
        $fetchWarning = $script:localizedData.Receive_GitBranch_Fetch_ShouldProcessConfirmation -f $UpstreamBranchName, $RemoteName
        $fetchCaption = $script:localizedData.Receive_GitBranch_Fetch_ShouldProcessCaption

        if ($PSCmdlet.ShouldProcess($fetchDescription, $fetchWarning, $fetchCaption))
        {
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
        }

        # Rebase local branch with upstream
        $rebaseDescription = $script:localizedData.Receive_GitBranch_RebaseOperation_ShouldProcessDescription -f $BranchName, $UpstreamBranchName, $RemoteName
        $rebaseWarning = $script:localizedData.Receive_GitBranch_RebaseOperation_ShouldProcessConfirmation -f $BranchName, $UpstreamBranchName, $RemoteName
        $rebaseCaption = $script:localizedData.Receive_GitBranch_RebaseOperation_ShouldProcessCaption

        if ($PSCmdlet.ShouldProcess($rebaseDescription, $rebaseWarning, $rebaseCaption))
        {
            try
            {
                Invoke-Git -Path $Path -Arguments @('rebase', "$RemoteName/$UpstreamBranchName") -ErrorAction 'Stop'
            }
            catch
            {
                # TODO: If for example there are unstaged changes it will fail, but not show the error message from Invoke-Git unless switching to ErrorView = 'Detailed'.
                # It will show when passing -Debug, but should be propagated to error message.
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

            Write-Information -MessageData ($script:localizedData.Receive_GitBranch_Success) -InformationAction 'Continue'
        }
    }
    else
    {
        # Determine if we should use git pull with explicit remote and branch
        $useExplicitPull = $PSBoundParameters.ContainsKey('RemoteName') -or $PSBoundParameters.ContainsKey('BranchName')

        if ($useExplicitPull)
        {
            # Use git pull with explicit remote and branch
            $pullDescription = $script:localizedData.Receive_GitBranch_PullWithRemote_ShouldProcessDescription -f $RemoteName, $BranchName
            $pullWarning = $script:localizedData.Receive_GitBranch_PullWithRemote_ShouldProcessConfirmation -f $RemoteName, $BranchName
            $pullCaption = $script:localizedData.Receive_GitBranch_PullWithRemote_ShouldProcessCaption

            if ($PSCmdlet.ShouldProcess($pullDescription, $pullWarning, $pullCaption))
            {
                try
                {
                    Invoke-Git -Path $Path -Arguments @('pull', $RemoteName, $BranchName) -ErrorAction 'Stop'
                }
                catch
                {
                    $errorMessage = $script:localizedData.Receive_GitBranch_FailedPullWithRemote -f $RemoteName, $BranchName

                    $newException = New-Exception -Message $errorMessage -ErrorRecord $_

                    $errorMessageParameters = @{
                        Message      = $errorMessage
                        Category     = 'InvalidOperation'
                        ErrorId      = 'RGB0005' # cspell: disable-line
                        TargetObject = $BranchName
                        Exception    = $newException
                    }

                    Write-Error @errorMessageParameters
                    return
                }

                Write-Information -MessageData ($script:localizedData.Receive_GitBranch_Success) -InformationAction 'Continue'
            }
        }
        else
        {
            # Check if upstream tracking branch is configured before prompting
            $hasUpstream = Invoke-Git -Path $Path -Arguments @('rev-parse', '--abbrev-ref', '@{u}') -PassThru

            if ($hasUpstream.ExitCode -ne 0)
            {
                $errorMessageParameters = @{
                    Message      = $script:localizedData.Receive_GitBranch_NoTrackingBranch -f $BranchName
                    Category     = 'InvalidOperation'
                    ErrorId      = 'RGB0014' # cspell: disable-line
                    TargetObject = $BranchName
                }

                Write-Error @errorMessageParameters
                return
            }

            # Use git pull with default behavior
            $pullDescription = $script:localizedData.Receive_GitBranch_PullOperation_ShouldProcessDescription -f $BranchName
            $pullWarning = $script:localizedData.Receive_GitBranch_PullOperation_ShouldProcessConfirmation -f $BranchName
            $pullCaption = $script:localizedData.Receive_GitBranch_PullOperation_ShouldProcessCaption

            if ($PSCmdlet.ShouldProcess($pullDescription, $pullWarning, $pullCaption))
            {
                try
                {
                    Invoke-Git -Path $Path -Arguments @('pull') -ErrorAction 'Stop'
                }
                catch
                {
                    $newException = New-Exception -Message ($script:localizedData.Receive_GitBranch_FailedPull -f $BranchName) -ErrorRecord $_

                    $errorMessageParameters = @{
                        Message      = $script:localizedData.Receive_GitBranch_FailedPull -f $BranchName
                        Category     = 'InvalidOperation'
                        ErrorId      = 'RGB0004' # cspell: disable-line
                        TargetObject = $null
                        Exception    = $newException
                    }

                    Write-Error @errorMessageParameters
                    return
                }

                Write-Information -MessageData ($script:localizedData.Receive_GitBranch_Success) -InformationAction 'Continue'
            }
        }
    }
}
