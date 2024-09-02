<#
    .SYNOPSIS
        Retrieves the version of a PowerShell module.

    .DESCRIPTION
        The Get-ModuleVersion command retrieves the version of a PowerShell module.
        It accepts a module name or a PSModuleInfo object as input and returns the
        module version as a string.

    .PARAMETER Module
        Specifies the module for which to retrieve the version. This can be either
        a module name or a PSModuleInfo object.

    .EXAMPLE
        Get-ModuleVersion -Module 'MyModule'

        Retrieves the version of the module named "MyModule".

    .EXAMPLE
        $moduleInfo = Get-Module -Name 'MyModule'
        Get-ModuleVersion -Module $moduleInfo

        Retrieves the version of the module specified by the PSModuleInfo object $moduleInfo.

    .INPUTS
        [System.Object]

        Accepts a module name or a PSModuleInfo object as input.

    .OUTPUTS
        [System.String]

        Returns the module version as a string.
#>
function Get-ModuleVersion
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 0)]
        [System.Object]
        $Module
    )

    process
    {
        $moduleInfo = $null
        $moduleVersion = $null

        if ($Module -is [System.String])
        {
            $moduleInfo = Get-Module -Name $Module -ErrorAction 'Stop'

            if (-not $moduleInfo)
            {
                Write-Error -Message "Cannot find the module '$Module'. Make sure it is loaded into the session."
            }
        }
        elseif ($Module -is [System.Management.Automation.PSModuleInfo])
        {
            $moduleInfo = $Module
        }
        else
        {
            Write-Error -Message "Invalid parameter type. The parameter 'Module' must be either a string or a PSModuleInfo object."
        }

        if ($moduleInfo)
        {
            $moduleVersion = $moduleInfo.Version.ToString()

            $previewReleaseTag = $moduleInfo.PrivateData.PSData.Prerelease

            if ($previewReleaseTag)
            {
                $moduleVersion += '-{0}' -f $previewReleaseTag
            }
        }

        return $moduleVersion
    }
}
