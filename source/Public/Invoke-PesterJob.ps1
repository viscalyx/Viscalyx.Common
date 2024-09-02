<#
    .SYNOPSIS
        Runs Pester tests using a job-based approach.

    .DESCRIPTION
        The `Invoke-PesterJob` command runs Pester tests using a job-based approach.
        It allows you to specify various parameters such as the test path, root path,
        module name, output verbosity, code coverage path, and more.

        Its primary purpose is to run Pester tests in a separate job to avoid polluting
        the current session with PowerShell classes and project specific assemblies
        which can cause issues when building the project.

        It is helpful for projects based on the Sampler project template, but it can
        also be used for other projects.

    .PARAMETER Path
        Specifies one or more paths to the Pester test files. If not specified, the
        current location is used. This also has tab completion support. Just write
        part of the test script file name and press tab to get a list of available
        test files matching the input, or if only one file matches, it will be
        auto-completed.

    .PARAMETER RootPath
        Specifies the root path for the Pester tests. If not specified, the current
        location is used.

    .PARAMETER Tag
        Specifies the tags to filter the Pester tests.

    .PARAMETER ModuleName
        Specifies the name of the module to test. If not specified, it will be
        inferred based on the project type.

    .PARAMETER Output
        Specifies the output verbosity level. Valid values are 'Normal', 'Detailed',
        'None', 'Diagnostic', and 'Minimal'. Default is 'Detailed'.

    .PARAMETER CodeCoveragePath
        Specifies the paths to one or more the code coverage files (script or module
        script files). If not provided the default path for code coverage is the
        content of the built module. This parameter also has tab completion support.
        Just write part of the script file name and press tab to get a list of
        available script files matching the input, or if only one file matches,
        it will be auto-completed.

    .PARAMETER SkipCodeCoverage
        Indicates whether to skip code coverage.

    .PARAMETER PassThru
        Indicates whether to pass the Pester result object through.

    .PARAMETER ShowError
        Indicates whether to display detailed error information. When using this
        to debug a test it is recommended to run as few tests as possible, or just
        the test having issues, to limit the amount of error information displayed.

    .PARAMETER SkipRun
        Indicates whether to skip running the tests, this just runs the discovery
        phase. This is useful when you want to see what tests would be run without
        actually running them. To actually make use of this, the PassThru parameter
        should also be specified. Suggest to also use the parameter SkipCodeCoverage.

    .PARAMETER BuildScriptPath
        Specifies the path to the build script. If not specified, it defaults to
        'build.ps1' in the root path. This is used to ensure that the test environment
        is configured correctly, for example required modules are available in the
        session. It is also used to ensure to find the specific Pester module used
        by the project.

    .PARAMETER BuildScriptParameter
        Specifies a hashtable with the parameters to pass to the build script.
        Defaults to parameter 'Task' with a value of 'noop'.

    .EXAMPLE
        $invokePesterJobParameters = @{
            Path = './tests/Unit/DSC_SqlAlias.Tests.ps1'
            CodeCoveragePath = './output/builtModule/SqlServerDsc/0.0.1/DSCResources/DSC_SqlAlias/DSC_SqlAlias.psm1'
        }
        Invoke-PesterJob @invokePesterJobParameters

        Runs the Pester test DSC_SqlAlias.Tests.ps1 located in the 'tests/Unit'
        folder. The code coverage is based on the code in the DSC_SqlAlias.psm1
        file.

    .EXAMPLE
        $invokePesterJobParameters = @{
            Path = './tests'
            RootPath = 'C:\Projects\MyModule'
            Tag = 'Unit'
            Output = 'Detailed'
            CodeCoveragePath = 'C:\Projects\MyModule\coverage'
        }
        Invoke-PesterJob @invokePesterJobParameters

        Runs Pester tests located in the 'tests' directory of the 'C:\Projects\MyModule'
        root path. Only tests with the 'Unit' tag will be executed. Detailed output
        will be displayed, and code coverage will be collected from the
        'C:\Projects\MyModule\coverage' directory.

    .EXAMPLE
        $invokePesterJobParameters = @{
            Path = './tests/Unit'
            SkipRun = $true
            SkipCodeCoverage = $true
            PassThru = $true
        }
        Invoke-PesterJob @invokePesterJobParameters

        Runs the discovery phase on all the Pester tests files located in the
        'tests/Unit' folder and outputs the Pester result object.

    .NOTES
        This function requires the Pester module to be imported. If the module is
        not available, it will attempt to run the build script to ensure the
        required modules are available in the session.
#>
function Invoke-PesterJob
{
    # cSpell: ignore Runspaces
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseUsingScopeModifierInNewRunspaces', '', Justification = 'This is a false positive. The script block is used in a job and does not use variables from the parent scope, they are passed in ArgumentList.')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('AvoidWriteErrorStop', '', Justification = 'If $PSCmdlet.ThrowTerminatingError were used, the error would not stop any command that would call Invoke-PesterJob.')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Justification = 'Argument completers always need the same parameters even if they are not used in the argument completer script.')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('DscResource.AnalyzerRules\Measure-Hashtable', '', Justification = 'The hashtable must be format as is to work when documentation is being generated by PlatyPS.')]
    [Alias('ipj')]
    [CmdletBinding()]
    param
    (
        [Parameter(Position = 0)]
        [ArgumentCompleter(
            {
                <#
                    This scriptblock is used to provide tab completion for the Path
                    parameter. The scriptblock could be a command, but then it would
                    need to be a public command. Also, if anything goes wrong in the
                    completer scriptblock, it will just fail silently and not provide
                    any completion results.
                #>
                param
                (
                    [Parameter()]
                    $CommandName,

                    [Parameter()]
                    $ParameterName,

                    [Parameter()]
                    $WordToComplete,

                    [Parameter()]
                    $CommandAst,

                    [Parameter()]
                    $FakeBoundParameters
                )

                # This parameter is from Invoke-PesterJob.
                if (-not $FakeBoundParameters.ContainsKey('RootPath'))
                {
                    $RootPath = (Get-Location).Path
                }

                $testRoot = Join-Path -Path $RootPath -ChildPath 'tests/unit'

                $values = (Get-ChildItem -Path $testRoot -Recurse -Filter '*.tests.ps1' -File).FullName

                foreach ($val in $values)
                {
                    if ($val -like "*$WordToComplete*")
                    {
                        New-Object -Type System.Management.Automation.CompletionResult -ArgumentList @(
                            (ConvertTo-RelativePath -AbsolutePath $val -CurrentLocation $RootPath) # completionText
                            (Split-Path -Path $val -Leaf) -replace '\.[Tt]ests.ps1' # listItemText
                            'ParameterValue' # resultType
                            $val # toolTip
                        )
                    }
                }
            })]
        [ValidateNotNullOrEmpty()]
        [System.String[]]
        $Path = (Get-Location).Path,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $RootPath = (Get-Location).Path,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String[]]
        $Tag,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ModuleName,

        [Parameter()]
        [System.String]
        [ValidateSet('Normal', 'Detailed', 'None', 'Diagnostic', 'Minimal')]
        $Output,

        [Parameter(Position = 1)]
        [ArgumentCompleter(
            {
                <#
                    This scriptblock is used to provide tab completion for the
                    CodeCoveragePath parameter. The scriptblock could be a command,
                    but then it would need to be a public command. Also, if anything
                    goes wrong in the completer scriptblock, it will just fail
                    silently and not provide any completion results.
                #>
                param
                (
                    [Parameter()]
                    $CommandName,

                    [Parameter()]
                    $ParameterName,

                    [Parameter()]
                    $WordToComplete,

                    [Parameter()]
                    $CommandAst,

                    [Parameter()]
                    $FakeBoundParameters
                )

                # This parameter is from Invoke-PesterJob.
                if (-not $FakeBoundParameters.ContainsKey('RootPath'))
                {
                    $RootPath = (Get-Location).Path
                }

                # TODO: builtModule should be dynamic.
                $builtModuleCodePath = @(
                    Join-Path -Path $RootPath -ChildPath 'output/builtModule'
                )

                $paths = Get-ChildItem -Path $builtModuleCodePath -Recurse -Include @('*.psm1', '*.ps1') -File -ErrorAction 'SilentlyContinue'

                # Filter out the external Modules directory.
                $values = $paths.FullName -notmatch 'Modules'

                $leafRegex = [regex]::new('([^\\/]+)$')

                foreach ($val in $values)
                {
                    $leaf = $leafRegex.Match($val).Groups[1].Value

                    if ($leaf -like "*$WordToComplete*")
                    {
                        New-Object -Type System.Management.Automation.CompletionResult -ArgumentList @(
                            (ConvertTo-RelativePath -AbsolutePath $val -CurrentLocation $RootPath) # completionText
                            $leaf -replace '\.(ps1|psm1)' # listItemText
                            'ParameterValue' # resultType
                            $val # toolTip
                        )
                    }
                }
            })]
        [ValidateNotNullOrEmpty()]
        [System.String[]]
        $CodeCoveragePath,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $SkipCodeCoverage,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $PassThru,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $ShowError,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $SkipRun,

        [Parameter()]
        [ValidateScript({
                if (-not (Test-Path $_ -PathType 'Leaf'))
                {
                    throw "The file path '$_' does not exist or is a container."
                }

                $true
            })]
        [System.String]
        $BuildScriptPath,

        [Parameter()]
        [System.Collections.Hashtable]
        $BuildScriptParameter = @{ Task = 'noop' }
    )

    if (-not $PSBoundParameters.ContainsKey('BuildScriptPath'))
    {
        $BuildScriptPath = Join-Path -Path $RootPath -ChildPath 'build.ps1'
    }

    $pesterModuleVersion = $null

    do
    {
        $triesCount = 0

        try
        {
            $importedPesterModule = Import-Module -Name 'Pester' -MinimumVersion '4.10.1' -ErrorAction 'Stop' -PassThru

            $pesterModuleVersion = $importedPesterModule | Get-ModuleVersion

            <#
                Assuming that the project is a Sampler project if the Sampler
                module is available in the session. Also assuming that a Sampler
                build task has been run prior to running the command.
            #>
            $isSamplerProject = $null -ne (Get-Module -Name 'Sampler')
        }
        catch
        {
            $triesCount++

            if ($triesCount -eq 1 -and (Test-Path -Path $BuildScriptPath))
            {
                Write-Information -MessageData 'Could not import Pester. Running build script to make sure required modules is available in session. This can take a few seconds.' -InformationAction 'Continue'

                # Redirect all streams to $null, except the error stream (stream 2)
                & $BuildScriptPath @buildScriptParameter 2>&1 4>&1 5>&1 6>&1 > $null
            }
            else
            {
                Write-Error -ErrorRecord $_ -ErrorAction 'Stop'
            }
        }
    } until ($importedPesterModule)

    Write-Information -MessageData ('Using imported Pester v{0}.' -f $pesterModuleVersion) -InformationAction 'Continue'

    if (-not $PSBoundParameters.ContainsKey('ModuleName'))
    {
        if ($isSamplerProject)
        {
            $ModuleName = Get-SamplerProjectName -BuildRoot $RootPath
        }
        else
        {
            $ModuleName = (Get-Item -Path $RootPath).BaseName
        }
    }

    $testResultsPath = Join-Path -Path $RootPath -ChildPath 'output/testResults'

    if (-not $PSBoundParameters.ContainsKey('CodeCoveragePath'))
    {
        # TODO: Should be possible to use default coverage paths for a module that is not based on Sampler.
        if ($isSamplerProject)
        {
            $BuiltModuleBase = Get-SamplerBuiltModuleBase -OutputDirectory "$RootPath/output" -BuiltModuleSubdirectory 'builtModule' -ModuleName $ModuleName

            # TODO: This does not take into account any .ps1 files in the module.
            # TODO: This does not take into account any other .psm1 files in the module, e.g. MOF-based DSC resources.
            $CodeCoveragePath = '{0}/*/{1}.psm1' -f $BuiltModuleBase, $ModuleName
        }
    }

    if ($importedPesterModule.Version.Major -eq 4)
    {
        $pesterConfig = @{
            Script = $Path
        }
    }
    else
    {
        $pesterConfig = New-PesterConfiguration -Hashtable @{
            CodeCoverage = @{
                Enabled        = $true
                Path           = $CodeCoveragePath
                OutputPath     = (Join-Path -Path $testResultsPath -ChildPath 'PesterJob_coverage.xml')
                UseBreakpoints = $false
            }
            Run          = @{
                Path = $Path
            }
        }
    }

    if ($PSBoundParameters.ContainsKey('Output'))
    {
        if ($importedPesterModule.Version.Major -eq 4)
        {
            $pesterConfig.Show = $Output
        }
        else
        {
            $pesterConfig.Output.Verbosity = $Output
        }
    }
    else
    {
        if ($importedPesterModule.Version.Major -eq 4)
        {
            $pesterConfig.Show = 'All'
        }
        else
        {
            $pesterConfig.Output.Verbosity = 'Detailed'
        }
    }

    # Turn off code coverage if the user has specified that they don't want it
    if ($SkipCodeCoverage.IsPresent)
    {
        # Pester v4: By not passing code paths the code coverage is disabled.

        # Pester v5: By setting the Enabled property to false the code coverage is disabled.
        if ($importedPesterModule.Version.Major -ge 5)
        {
            $pesterConfig.CodeCoverage.Enabled = $false
        }
    }
    else
    {
        # Pester 4: By passing code paths the code coverage is enabled.
        if ($importedPesterModule.Version.Major -eq 4)
        {
            $pesterConfig.CodeCoverage = $CodeCoveragePath
        }
    }

    if ($PassThru.IsPresent)
    {
        if ($importedPesterModule.Version.Major -eq 4)
        {
            $pesterConfig.PassThru = $true
        }
        else
        {
            $pesterConfig.Run.PassThru = $true
        }
    }

    if ($SkipRun.IsPresent)
    {
        # This is only supported in Pester v5 or higher.
        if ($importedPesterModule.Version.Major -ge 5)
        {
            $pesterConfig.Run.SkipRun = $true
        }
    }

    if ($PSBoundParameters.ContainsKey('Tag'))
    {
        if ($importedPesterModule.Version.Major -eq 4)
        {
            $pesterConfig.Tag = $Tag
        }
        else
        {
            $pesterConfig.Filter.Tag = $Tag
        }
    }

    Start-Job -ScriptBlock {
        [CmdletBinding()]
        param
        (
            [Parameter(Mandatory = $true, Position = 0)]
            [System.Object]
            $PesterConfiguration,

            [Parameter(Mandatory = $true, Position = 1)]
            [System.Management.Automation.SwitchParameter]
            $ShowError,

            [Parameter(Mandatory = $true, Position = 2)]
            [System.Version]
            $PesterVersion,

            [Parameter(Mandatory = $true, Position = 3)]
            [System.String]
            $BuildScriptPath,

            [Parameter(Mandatory = $true, Position = 4)]
            [System.Collections.Hashtable]
            $BuildScriptParameter
        )

        Write-Information -MessageData 'Running build task ''noop'' inside the job to setup the test pipeline.' -InformationAction 'Continue'

        & $BuildScriptPath @buildScriptParameter

        if ($ShowError.IsPresent)
        {
            $Error.Clear()
            $ErrorView = 'DetailedView'
        }

        if ($PesterVersion.Major -eq 4)
        {
            Invoke-Pester @PesterConfiguration
        }
        else
        {
            Invoke-Pester -Configuration $PesterConfiguration
        }

        if ($ShowError.IsPresent)
        {
            'Error count: {0}' -f $Error.Count
            $Error | Out-String
        }
    } -ArgumentList @(
        $pesterConfig
        $ShowError.IsPresent
        $importedPesterModule.Version
        $BuildScriptPath
        $BuildScriptParameter
    ) |
        Receive-Job -AutoRemoveJob -Wait
}
