<#
    .SYNOPSIS
        Retrieves the commit ID(s) for a specified Git branch.

    .DESCRIPTION
        The Get-GitBranchCommit command retrieves the commit ID(s) for a specified
        Git branch. It provides options to retrieve the latest commit ID, a specific
        number of latest commit IDs, or the first X number of commit IDs.

    .PARAMETER BranchName
        Specifies the name of the Git branch. If not provided, the current branch
        will be used.

    .PARAMETER Latest
        Retrieves only the latest commit ID.

    .PARAMETER Last
        Retrieves the specified number of latest commit IDs. The order will be from
        the newest to the oldest commit.

    .PARAMETER First
        Retrieves the first X number of commit IDs. The order will be from the
        oldest to the newest commit.

    .PARAMETER From
        Specifies the starting reference (commit, branch, tag, or HEAD) for the range.
        Used with the To parameter to get commits between two references.

    .PARAMETER To
        Specifies the ending reference (commit, branch, tag, or HEAD) for the range.
        Used with the From parameter to get commits between two references.

    .INPUTS
        None

        This function does not accept pipeline input.

    .OUTPUTS
        System.String

        The commit ID(s) for the specified Git branch.

    .EXAMPLE
        Get-GitBranchCommit -BranchName 'feature/branch'

        Retrieves all commit IDs for the 'feature/branch' Git branch.

    .EXAMPLE
        Get-GitBranchCommit -Latest

        Retrieves only the latest commit ID for the current Git branch.

    .EXAMPLE
        Get-GitBranchCommit -Last 5

        Retrieves the 5 latest commit IDs for the current Git branch.

    .EXAMPLE
        Get-GitBranchCommit -First 3

        Retrieves the first 3 commit IDs for the current Git branch.

    .EXAMPLE
        Get-GitBranchCommit -From 'main' -To 'HEAD'

        Retrieves all commit IDs between the main branch and HEAD.

    .EXAMPLE
        Get-GitBranchCommit -From 'v1.0.0' -To 'v2.0.0'

        Retrieves all commit IDs between version tags v1.0.0 and v2.0.0.

    .EXAMPLE
        Get-GitBranchCommit -From 'abc123' -To 'def456'

        Retrieves all commit IDs between two specific commit hashes.
#>
function Get-GitBranchCommit
{
    [CmdletBinding(DefaultParameterSetName = 'NoParameter')]
    [OutputType([System.String])]
    param
    (
        [Parameter(ParameterSetName = 'NoParameter')]
        [Parameter(ParameterSetName = 'Latest')]
        [Parameter(ParameterSetName = 'Last')]
        [Parameter(ParameterSetName = 'First')]
        [System.String]
        $BranchName,

        [Parameter(ParameterSetName = 'Latest')]
        [System.Management.Automation.SwitchParameter]
        $Latest,

        [Parameter(ParameterSetName = 'Last')]
        [System.UInt32]
        $Last,

        [Parameter(ParameterSetName = 'First')]
        [System.UInt32]
        $First,

        [Parameter(ParameterSetName = 'Range', Mandatory = $true)]
        [System.String]
        $From,

        [Parameter(ParameterSetName = 'Range', Mandatory = $true)]
        [System.String]
        $To
    )

    $commitId = $null
    $exitCode = 0
    $argument = @()


    if (-not $PSBoundParameters.ContainsKey('BranchName') -or $BranchName -eq '.')
    {
        $BranchName = Get-GitLocalBranchName -Current
    }

    $argument += @(
        $BranchName
    )

    switch ($PSCmdlet.ParameterSetName)
    {
        'Latest'
        {
            # Return only the latest commit ID.
            $commitId = git rev-parse $BranchName

            $exitCode = $LASTEXITCODE # cSpell: ignore LASTEXITCODE
        }

        'Last'
        {
            # Return the latest X number of commits.
            $commitId = git log -n $Last --pretty=format:"%H" @argument 2>$null

            $exitCode = $LASTEXITCODE
        }

        'First'
        {
            if (-not $PSBoundParameters.ContainsKey('BranchName'))
            {
                $BranchName = Get-GitLocalBranchName -Current
            }

            # Count the total number of commits in the branch.
            $totalCommits = git rev-list --count $BranchName

            $exitCode = $LASTEXITCODE

            if ($exitCode -eq 0)
            {
                # Calculate the number of commits to skip.
                $skipCommits = $totalCommits - $First

                # Return the first X number of commits.
                $commitId = git log --skip $skipCommits --reverse -n $First --pretty=format:"%H" $BranchName 2>$null

                $exitCode = $LASTEXITCODE
            }
        }

        'Range'
        {
            # Return commits between From and To references using git range syntax
            $commitId = git log --pretty=format:"%H" "$From..$To" 2>$null

            $exitCode = $LASTEXITCODE
        }

        'NoParameter'
        {
            # Return all commit IDs.
            $commitId = git log --pretty=format:"%H" @argument 2>$null

            $exitCode = $LASTEXITCODE
        }
    }

    if ($exitCode -ne 0)
    {
        if ($PSCmdlet.ParameterSetName -eq 'Range')
        {
            $errorMessage = $script:localizedData.Get_GitBranchCommit_FailedFromRange -f $From, $To
        }
        elseif ($PSBoundParameters.ContainsKey('BranchName'))
        {
            $errorMessage = $script:localizedData.Get_GitBranchCommit_FailedFromBranch -f $BranchName
        }
        else
        {
            $errorMessage = $script:localizedData.Get_GitBranchCommit_FailedFromCurrent
        }

        $errorMessageParameters = @{
            Message      = $errorMessage
            Category     = 'ObjectNotFound'
            ErrorId      = 'GGBC0001' # cspell: disable-line
            TargetObject = if ($PSCmdlet.ParameterSetName -eq 'Range')
            {
                "$From..$To"
            }
            else
            {
                $BranchName
            }
        }

        Write-Error @errorMessageParameters
    }

    return $commitId
}
