<#
    .SYNOPSIS
        Retrieves the name of the local Git branch.

    .DESCRIPTION
        The Get-GitLocalBranchName command is used to retrieve the name of the
        local Git branch. It can either return the name of the current branch or
        search for branches based on a specified name or wildcard pattern.

    .PARAMETER Name
        Specifies the name or wildcard pattern of the branch to search for.
        If not provided, all branch names will be returned.

    .PARAMETER Current
        Indicates whether to retrieve the name of the current branch. If this switch parameter is present, the function will return the name of the current branch.

    .INPUTS
        None

        This function does not accept pipeline input.

    .OUTPUTS
        System.String

        The name of the local Git branch.

    .EXAMPLE
        PS> Get-GitLocalBranchName -Name 'main'

        Returns the branch that match exactly to the name 'main'.

    .EXAMPLE
        PS> Get-GitLocalBranchName -Name 'f/*'

        Returns the names of all branches that match the wildcard pattern "f/*".

    .EXAMPLE
        PS> Get-GitLocalBranchName -Current

        Returns the name of the current Git branch.

    .NOTES
        This function requires Git to be installed and accessible from the command line.
#>
function Get-GitLocalBranchName
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter()]
        [System.String]
        $Name,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Current
    )

    $branchName = $null

    if ($Current.IsPresent)
    {
        $branchName = git rev-parse --abbrev-ref HEAD
    }
    else
    {
        if ($Name)
        {
            # Can do wildcard search for branch name, e.g. f/* to find feature branches.
            $branchName = git branch --format='%(refname:short)' --list $Name
        }
        else
        {
            $branchName = git branch --format='%(refname:short)' --list
        }
    }

    if ($LASTEXITCODE -ne 0) # cSpell: ignore LASTEXITCODE
    {
        $errorMessageParameters = @{
            Message      = $script:localizedData.Get_GitLocalBranchName_Failed
            Category     = 'ObjectNotFound'
            ErrorId      = 'GGLBN0001' # cspell: disable-line
            TargetObject = $null
        }

        Write-Error @errorMessageParameters
    }

    return $branchName
}
