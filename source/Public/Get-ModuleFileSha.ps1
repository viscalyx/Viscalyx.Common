<#
    .SYNOPSIS
        Retrieves the SHA256 hash of all ps1, psm1, and psd1 files in a PowerShell module.

    .DESCRIPTION
        The Get-ModuleFileSha function retrieves the SHA256 hash of all ps1, psm1, and
        psd1 files in a PowerShell module. It takes a module name, module version, and
        Path as parameters. The function loops through all the ps1, psm1, and psd1 files
        that the module consists of and outputs each file with its corresponding SHA
        using the SHA256 algorithm.

    .PARAMETER Name
        Specifies the name of the module.

    .PARAMETER Version
        Specifies the version of the module.

    .PARAMETER Path
        Specifies the path to the root of module for a specific version.

    .EXAMPLE
        Get-ModuleFileSha -Name 'MyModule' -Version '1.0.0'

        Retrieves the SHA256 hash of all ps1, psm1, and psd1 files in the 'MyModule'
        module with version '1.0.0'.

    .EXAMPLE
        Get-ModuleFileSha -Path 'C:\Modules\MyModule\1.0.0'

        Retrieves the SHA256 hash of all ps1, psm1, and psd1 files in the module located
        at 'C:\Modules\MyModule'.

    .INPUTS
        None. You cannot pipe input to this function.

    .OUTPUTS
        System.Object. The function returns a list of files with their corresponding SHA256 hash.
#>
function Get-ModuleFileSha
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true, ParameterSetName = 'ModuleName')]
        [System.String]
        $Name,

        [Parameter(ParameterSetName = 'ModuleName')]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Version,

        [Parameter(Mandatory = $true, ParameterSetName = 'Path')]
        [ValidateScript({
            if (-not (Test-Path -Path $_ -PathType Container))
            {
                # $writeErrorParameters = @{
                #     Message      = $script:localizedData.Get_ModuleFileSha_PathMustBeDirectory
                #     Category     = 'InvalidArgument'
                #     ErrorId      = 'GMFS0003' # cSpell: disable-line
                #     TargetObject = $Name
                # }

                # Write-Error @writeErrorParameters -ErrorAction 'Stop'
                throw $script:localizedData.Get_ModuleFileSha_PathMustBeDirectory
            }

            return $true
        })]
        [System.String]
        $Path
    )

    $modulePath = if ($PSCmdlet.ParameterSetName -eq 'ModuleName')
    {
        $availableModule = Get-Module -Name $Name -ListAvailable

        if ($Version)
        {
            $filteredModule = $null

            foreach ($currentModule in $availableModule)
            {
                $moduleVersion = Get-ModuleVersion -Module $currentModule

                if ($moduleVersion -eq $Version)
                {
                    $filteredModule = $currentModule

                    break
                }
            }

            $availableModule = $filteredModule
        }

        if (-not $availableModule)
        {
            if ($Version)
            {
                $errorMessage = $script:localizedData.Get_ModuleFileSha_MissingModuleVersion -f $Name, $Version
            }
            else
            {
                $errorMessage = $script:localizedData.Get_ModuleFileSha_MissingModule -f $Name
            }

            $writeErrorParameters = @{
                Message      = $errorMessage
                Category     = 'ObjectNotFound'
                ErrorId      = 'GMFS0001' # cSpell: disable-line
                TargetObject = $Name
            }

            Write-Error @writeErrorParameters

            return
        }

        # Will return multiple paths if more than one module is found.
        $availableModule.ModuleBase
    }
    else
    {
        if (-not (Test-Path -Path $Path))
        {
            $writeErrorParameters = @{
                Message      = $script:localizedData.Get_ModuleFileSha_ModulePathNotFound -f $Path
                Category     = 'ObjectNotFound'
                ErrorId      = 'GMFS0002' # cSpell: disable-line
                TargetObject = $Name
            }

            Write-Error @writeErrorParameters

            return
        }

        [System.IO.Path]::GetFullPath($Path)
    }

    $fileExtensions = @('*.ps1', '*.psm1', '*.psd1')

    foreach ($path in $modulePath)
    {
        $moduleFiles = Get-ChildItem -Path $path -Recurse -Include $fileExtensions

        foreach ($file in $moduleFiles)
        {
            $fileHash = Get-FileHash -Path $file.FullName -Algorithm SHA256

            [PSCustomObject]@{
                # Output the relative path
                ModuleBase = $path
                RelativePath = $file.FullName.Substring($path.Length + 1)
                FileName = $file.Name
                HashSHA  = $fileHash.Hash
            }
        }
    }
}
