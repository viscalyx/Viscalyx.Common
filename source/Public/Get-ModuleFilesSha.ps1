<#
.SYNOPSIS
    Retrieves the SHA256 hash of all ps1, psm1, and psd1 files in a PowerShell module.

.DESCRIPTION
    The Get-ModuleFilesSha function retrieves the SHA256 hash of all ps1, psm1, and psd1 files in a PowerShell module.
    It takes a module name, module version, and Path as parameters. The function loops through all the ps1, psm1, and psd1 files
    that the module consists of and outputs each file with its corresponding SHA using the SHA256 algorithm.

.PARAMETER ModuleName
    Specifies the name of the module.

.PARAMETER ModuleVersion
    Specifies the version of the module.

.PARAMETER Path
    Specifies the path to the module.

.EXAMPLE
    Get-ModuleFilesSha -ModuleName 'MyModule' -ModuleVersion '1.0.0'

    Retrieves the SHA256 hash of all ps1, psm1, and psd1 files in the 'MyModule' module with version '1.0.0'.

.EXAMPLE
    Get-ModuleFilesSha -Path 'C:\Modules\MyModule'

    Retrieves the SHA256 hash of all ps1, psm1, and psd1 files in the module located at 'C:\Modules\MyModule'.

.INPUTS
    None. You cannot pipe input to this function.

.OUTPUTS
    System.Object. The function returns a list of files with their corresponding SHA256 hash.
#>
function Get-ModuleFilesSha
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true, ParameterSetName = 'ModuleName')]
        [System.String]
        $ModuleName,

        [Parameter(Mandatory = $false, ParameterSetName = 'ModuleName')]
        [System.String]
        $ModuleVersion,

        [Parameter(Mandatory = $true, ParameterSetName = 'Path')]
        [System.String]
        $Path
    )

    process
    {
        $modulePath = if ($PSCmdlet.ParameterSetName -eq 'ModuleName')
        {
            $module = Get-Module -Name $ModuleName -ListAvailable

            if (-not $module)
            {
                throw "Module not found: $ModuleName"
            }

            if ($ModuleVersion)
            {
                $moduleVersion = Get-ModuleVersion -Module $ModuleName

                if ($moduleVersion -ne $ModuleVersion)
                {
                    throw "Module version mismatch: $ModuleName $ModuleVersion"
                }
            }

            $module.ModuleBase
        }
        else
        {
            $Path
        }

        if (-not (Test-Path -Path $modulePath))
        {
            throw "Module path not found: $modulePath"
        }

        $fileExtensions = @('*.ps1', '*.psm1', '*.psd1')

        $files = Get-ChildItem -Path $modulePath -Recurse -Include $fileExtensions

        foreach ($file in $files)
        {
            $fileHash = Get-FileHash -Path $file.FullName -Algorithm SHA256

            [PSCustomObject]@{
                FileName = $file.FullName.Substring($modulePath.Length + 1)
                HashSHA  = $fileHash.Hash
            }
        }
    }
}
