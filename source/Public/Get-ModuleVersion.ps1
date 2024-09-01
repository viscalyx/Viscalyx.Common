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
