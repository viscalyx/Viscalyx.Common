<#
    .SYNOPSIS
        Retrieves Git tags based on specified parameters.

    .DESCRIPTION
        The Get-GitTag function retrieves Git tags based on the specified parameters.
        It can retrieve the latest tag, a specific tag by name, or a list of tags.
        The function supports sorting and filtering options.

    .PARAMETER Name
        Specifies the name of the tag to retrieve. This parameter is used in the
        'First' parameter set.

    .PARAMETER Latest
        Retrieves the latest Git tag. This parameter is used in the 'Latest' parameter
        set.

    .PARAMETER First
        Specifies the number of tags to retrieve. This parameter is used in the 'First'
        parameter set.

    .PARAMETER AsVersions
        Specifies whether to retrieve tags as version numbers. This parameter is
        used in the 'First' parameter set.

    .PARAMETER Descending
        Specifies whether to sort the tags in descending order. This parameter is
        used in the 'First' parameter set. Default is ascending order.

    .OUTPUTS
        System.String
            The retrieved Git tag(s).

    .EXAMPLE
        Get-GitTag -Name 'v1.0'

        Retrieves the Git tag with the name 'v1.0'.

    .EXAMPLE
        Get-GitTag -Latest

        Retrieves the latest Git tag.

    .EXAMPLE
        Get-GitTag -Name 'v13*' -AsVersions -Descending

        Retrieves all Git tags as versions that start with 'v13', and sort them
        in descending order.

    .EXAMPLE
        Get-GitTag -First 5 -AsVersions -Descending

        Retrieves the first 5 Git tags as version numbers after the tags are sorted
        in descending order.

    .NOTES
        This function requires Git to be installed and accessible from the command line.
#>
function Get-GitTag
{
    [CmdletBinding()]
    param (
        [Parameter(Position = 0, ParameterSetName = 'First')]
        [System.String]
        $Name,

        [Parameter(ParameterSetName = 'Latest')]
        [System.Management.Automation.SwitchParameter]
        $Latest,

        [Parameter(ParameterSetName = 'First')]
        [System.UInt32]
        $First,

        [Parameter(ParameterSetName = 'First')]
        [System.Management.Automation.SwitchParameter]
        $AsVersions,

        [Parameter(ParameterSetName = 'First')]
        [System.Management.Automation.SwitchParameter]
        $Descending
    )

    if ($Latest.IsPresent)
    {
        $First = 1
        $Descending = $true
        $AsVersions = $true
        # git describe --tags --abbrev=0

        # $exitCode = $LASTEXITCODE # cSpell: ignore LASTEXITCODE
    }

    $arguments = @(
        '--list'
    )

    if ($AsVersions.IsPresent)
    {
        if ($Descending.IsPresent)
        {
            $arguments += '--sort=-v:refname'
        }
        else
        {
            $arguments += '--sort=v:refname'
        }
    }
    else
    {
        if ($Descending.IsPresent)
        {
            $arguments += '--sort=-refname'
        }
        else
        {
            $arguments += '--sort=refname'
        }
    }

    # Get all tags or filter tags using git directly
    if ($Name)
    {
        $tag = git tag @arguments $Name

        $exitCode = $LASTEXITCODE
    }
    else
    {
        $tag = git tag @arguments

        $exitCode = $LASTEXITCODE
    }

    if ($First)
    {
        $tag = $tag | Select-Object -First $First
    }

    if ($exitCode -ne 0)
    {
        $errorMessageParameters = @{
            Message      = $script:localizedData.Get_GitTag_FailedToGetTag
            Category     = 'InvalidOperation'
            ErrorId      = 'GGT0001' # cspell: disable-line
            TargetObject = $Name
        }

        Write-Error @errorMessageParameters
    }

    return $tag
}
