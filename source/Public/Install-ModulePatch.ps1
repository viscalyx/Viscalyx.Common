<#
.SYNOPSIS
    Applies patches to PowerShell modules based on a patch file.

.DESCRIPTION
    The Install-ModulePatch command reads a patch file, validates its content, and applies patches to PowerShell modules.
    The patch file can be provided as a local file path or a URL. The command verifies the module version and hash,
    and replaces the content according to the patch file. It supports multiple patch entries in a single patch file,
    applying them in descending order of StartOffset.

.PARAMETER Path
    Specifies the path to the patch file.

.PARAMETER URI
    Specifies the URL of the patch file.

.PARAMETER Force
    Overrides the confirmation dialogs.

.EXAMPLE
    Install-ModulePatch -Path "C:\patches\MyModule_1.0.0_patch.json"

    Applies the patches specified in the patch file located at "C:\patches\MyModule_1.0.0_patch.json".

.EXAMPLE
    Install-ModulePatch -URI "https://gist.githubusercontent.com/user/gistid/raw/MyModule_1.0.0_patch.json"

    Applies the patches specified in the patch file located at the specified URL.

.INPUTS
    None. You cannot pipe input to this function.

.OUTPUTS
    None. The function does not generate any output.
#>
function Install-ModulePatch
{
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param
    (
        [Parameter(Mandatory = $true, ParameterSetName = 'Path')]
        [System.String]
        $Path,

        [Parameter(Mandatory = $true, ParameterSetName = 'URI')]
        [System.Uri]
        $URI,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Force
    )

    process
    {
        if ($PSCmdlet.ShouldProcess("Applying patches from $Path or $URI"))
        {
            $patchFileContent = if ($PSCmdlet.ParameterSetName -eq 'Path')
            {
                Get-PatchFileContentFromPath -Path $Path
            }
            else
            {
                Get-PatchFileContentFromURI -URI $URI
            }

            Assert-PatchFile -PatchFileContent $patchFileContent

            $patchFileContent = $patchFileContent |
                Sort-Object -Property StartOffset -Descending

            foreach ($patchEntry in $patchFileContent)
            {
                Merge-Patch -PatchEntry $patchEntry
            }
        }
    }
}
