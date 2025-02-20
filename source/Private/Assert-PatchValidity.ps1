<#
    .SYNOPSIS
        Assesses if a module with the correct version exists and validates script file existence and SHA hash.

    .DESCRIPTION
        The Assert-PatchValidity function checks if a module with the correct version exists.
        If the PowerShell module has a prerelease string, it is also evaluated when the version is checked.
        Additionally, it validates that each script file exists with the expected SHA hash.

    .PARAMETER PatchEntry
        Specifies the patch entry to validate.

    .EXAMPLE
        $patchEntry = @{
            ModuleName = "TestModule"
            ModuleVersion = "1.0.0"
            ScriptFileName = "TestScript.ps1"
            HashSHA = "1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef"
        }
        Assert-PatchValidity -PatchEntry $patchEntry

        Validates the module version and script file existence with the expected SHA hash.

    .INPUTS
        None. You cannot pipe input to this function.

    .OUTPUTS
        None. The function does not generate any output.
#>
function Assert-PatchValidity
{
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Object]
        $PatchEntry
    )

    $module = Get-Module -Name $PatchEntry.ModuleName -ListAvailable

    if (-not $module)
    {
        $writeErrorParameters = @{
            Message      = $script:localizedData.Assert_PatchValidity_ModuleNotFound -f $PatchEntry.ModuleName, $PatchEntry.ModuleVersion
            Category     = 'ObjectNotFound'
            ErrorId      = 'APV0001' # cSpell: disable-line
            TargetObject = $PatchEntry.ModuleName
        }

        Write-Error @writeErrorParameters

        return
    }

    $moduleVersion = Get-ModuleVersion -Module $PatchEntry.ModuleName

    if ($moduleVersion -ne $PatchEntry.ModuleVersion)
    {
        $writeErrorParameters = @{
            Message      = $script:localizedData.Assert_PatchValidity_ModuleVersionMismatch -f $PatchEntry.ModuleName, $PatchEntry.ModuleVersion
            Category     = 'InvalidData'
            ErrorId      = 'APV0002' # cSpell: disable-line
            TargetObject = $PatchEntry.ModuleName
        }

        Write-Error @writeErrorParameters

        return
    }

    $modulePath = Join-Path -Path $module.ModuleBase -ChildPath $PatchEntry.ScriptFileName

    if (-not (Test-Path -Path $modulePath))
    {
        $writeErrorParameters = @{
            Message      = $script:localizedData.Assert_PatchValidity_ScriptFileNotFound -f $modulePath
            Category     = 'ObjectNotFound'
            ErrorId      = 'APV0003' # cSpell: disable-line
            TargetObject = $PatchEntry.ScriptFileName
        }

        Write-Error @writeErrorParameters

        return
    }

    $computedHash = (Get-FileHash -Path $modulePath -Algorithm SHA256).Hash

    if ($computedHash -ne $PatchEntry.HashSHA)
    {
        $writeErrorParameters = @{
            Message      = $script:localizedData.Assert_PatchValidity_HashValidationFailed -f $modulePath, $PatchEntry.HashSHA, $computedHash
            Category     = 'InvalidData'
            ErrorId      = 'APV0004' # cSpell: disable-line
            TargetObject = $PatchEntry.ScriptFileName
        }

        Write-Error @writeErrorParameters

        return
    }
}
