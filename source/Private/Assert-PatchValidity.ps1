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
        throw "Module not found: $($PatchEntry.ModuleName) $($PatchEntry.ModuleVersion)"
    }

    $moduleVersion = Get-ModuleVersion -Module $PatchEntry.ModuleName

    if ($moduleVersion -ne $PatchEntry.ModuleVersion)
    {
        throw "Module version mismatch: $($PatchEntry.ModuleName) $($PatchEntry.ModuleVersion)"
    }

    $modulePath = Join-Path -Path $module.ModuleBase -ChildPath $PatchEntry.ScriptFileName

    if (-not (Test-Path -Path $modulePath))
    {
        throw "Script file not found: $modulePath"
    }

    $computedHash = (Get-FileHash -Path $modulePath -Algorithm SHA256).Hash

    if ($computedHash -ne $PatchEntry.HashSHA)
    {
        throw "Hash validation failed for script file: $modulePath. Expected: $($PatchEntry.HashSHA), Actual: $computedHash"
    }
}
