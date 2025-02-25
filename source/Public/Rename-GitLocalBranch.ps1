<#
    .SYNOPSIS
        Renames a local Git branch and optionally updates remote tracking and default
        branch settings.

    .DESCRIPTION
        This function renames a local Git branch. It can also update the upstream
        tracking and set the new branch as the default for the remote repository.

    .PARAMETER Name
        The current name of the branch to be renamed.

    .PARAMETER NewName
        The new name for the branch.

    .PARAMETER RemoteName
        The name of the remote repository. Defaults to 'origin'.

    .PARAMETER SetDefault
        If specified, sets the newly renamed branch as the default branch for the
        remote repository.

    .PARAMETER TrackUpstream
        If specified, sets up the newly renamed branch to track the upstream branch.

    .EXAMPLE
        Rename-GitLocalBranch -Name "feature/old-name" -NewName "feature/new-name"

        This example renames a local branch from "feature/old-name" to "feature/new-name".
        It does not affect any remote settings.

    .EXAMPLE
        Rename-GitLocalBranch -Name "develop" -NewName "main" -TrackUpstream -SetDefault

        This example renames the local "develop" branch to "main", sets up upstream tracking
        for the new branch, and sets it as the default branch for the remote repository.
        This is useful when standardizing branch names across projects.

    .EXAMPLE
        Rename-GitLocalBranch -Name "bugfix/issue-123" -NewName "hotfix/critical-fix" -RemoteName "upstream" -TrackUpstream

        This example renames a branch from "bugfix/issue-123" to "hotfix/critical-fix",
        sets up tracking with a remote named "upstream", but does not change the default branch.

    .NOTES
        This function requires Git to be installed and accessible in the system PATH.
#>
function Rename-GitLocalBranch
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter(Mandatory = $true)]
        [System.String]
        $NewName,

        [Parameter()]
        [System.String]
        $RemoteName = 'origin',

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $SetDefault,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $TrackUpstream
    )

    # Rename the local branch
    git branch -m $Name $NewName

    if ($LASTEXITCODE -eq 0) # cSpell: ignore LASTEXITCODE
    {
        Write-Verbose -Message ($script:localizedData.Rename_GitLocalBranch_RenamedBranch -f $Name, $NewName)
    }
    else
    {
        $errorMessageParameters = @{
            Message      = $script:localizedData.Rename_GitLocalBranch_FailedToRename -f $Name, $NewName
            Category     = 'InvalidOperation'
            ErrorId      = 'RGLB0001' # cspell: disable-line
            TargetObject = $Name
        }

        Write-Error @errorMessageParameters

        # Exit early if the branch rename failed, and user did not ask for terminating error.
        return
    }


    # Only fetch if either switch parameter is passed
    if ($SetDefault.IsPresent -or $TrackUpstream.IsPresent)
    {
        # Fetch the remote to ensure we have the latest information
        git fetch $RemoteName

        if ($LASTEXITCODE -ne 0)
        {
            $errorMessageParameters = @{
                Message      = $script:localizedData.Rename_GitLocalBranch_FailedFetch -f $RemoteName
                Category     = 'InvalidOperation'
                ErrorId      = 'RGLB0002' # cspell: disable-line
                TargetObject = $RemoteName
            }

            Write-Error @errorMessageParameters

            # Exit early if the branch rename failed, and user did not ask for terminating error.
            return
        }
    }

    if ($TrackUpstream.IsPresent)
    {
        # Set up the new branch to track the upstream branch
        git branch -u "$RemoteName/$NewName" $NewName

        if ($LASTEXITCODE -ne 0)
        {
            $errorMessageParameters = @{
                Message      = $script:localizedData.Rename_GitLocalBranch_FailedSetUpstreamTracking -f $NewName, $RemoteName
                Category     = 'InvalidOperation'
                ErrorId      = 'RGLB0003' # cspell: disable-line
                TargetObject = $Name
            }

            Write-Error @errorMessageParameters

            # Exit early if the branch rename failed, and user did not ask for terminating error.
            return
        }
    }

    if ($SetDefault.IsPresent)
    {
        # Set the new branch as the default for the remote
        git remote set-head $RemoteName --auto

        if ($LASTEXITCODE -ne 0)
        {
            $errorMessageParameters = @{
                Message      = $script:localizedData.Rename_GitLocalBranch_FailedSetDefaultBranchForRemote -f $NewName, $RemoteName
                Category     = 'InvalidOperation'
                ErrorId      = 'RGLB0003' # cspell: disable-line
                TargetObject = $RemoteName
            }

            Write-Error @errorMessageParameters

            # Exit early if the branch rename failed, and user did not ask for terminating error.
            return
        }
    }
}
