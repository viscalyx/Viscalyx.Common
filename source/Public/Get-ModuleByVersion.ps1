<#
    .SYNOPSIS
        Gets a specific version of a PowerShell module from the list of available
        modules.

    .DESCRIPTION
        The Get-ModuleByVersion function retrieves a specific version of a PowerShell
        module from the list of available modules based on the module name and version
        provided. If the module with the specified version is found, it returns the
        module object; otherwise, it returns $null.

    .PARAMETER ModuleName
        The name of the module to retrieve.

    .PARAMETER Version
        The version of the module to retrieve.

    .EXAMPLE
        Get-ModuleByVersion -Name 'MyModule' -Version '1.0.0'

        Retrieves the module 'MyModule' with version '1.0.0' and returns the module
        object.

    .INPUTS
        None. You cannot pipe input to this function.

    .OUTPUTS
        [PSModuleInfo] or $null

        The function returns a PSModuleInfo object if the module with the specified
        name and version is found; otherwise, it returns $null.
#>
function Get-ModuleByVersion
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Version
    )

    # Get all the modules with the specified name
    $availableModules = Get-Module -Name $Name -ListAvailable

    $foundModule = $null

    # Loop through the available modules and check the version
    foreach ($module in $availableModules)
    {
        $availableModuleVersion = Get-ModuleVersion -Module $module

        if ($Version -eq $availableModuleVersion)
        {
            $foundModule = $module

            break
        }
    }

    return $foundModule
}
