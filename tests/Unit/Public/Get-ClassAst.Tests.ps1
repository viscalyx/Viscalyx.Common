[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '', Justification = 'Suppressing this rule because Script Analyzer does not understand Pester syntax.')]
param ()

BeforeDiscovery {
    try
    {
        if (-not (Get-Module -Name 'DscResource.Test'))
        {
            # Assumes dependencies have been resolved, so if this module is not available, run 'noop' task.
            if (-not (Get-Module -Name 'DscResource.Test' -ListAvailable))
            {
                # Redirect all streams to $null, except the error stream (stream 2)
                & "$PSScriptRoot/../../../build.ps1" -Tasks 'noop' 3>&1 4>&1 5>&1 6>&1 > $null
            }

            # If the dependencies have not been resolved, this will throw an error.
            Import-Module -Name 'DscResource.Test' -Force -ErrorAction 'Stop'
        }
    }
    catch [System.IO.FileNotFoundException]
    {
        throw 'DscResource.Test module dependency not found. Please run ".\build.ps1 -ResolveDependency -Tasks noop" first.'
    }
}

BeforeAll {
    $script:moduleName = 'Viscalyx.Common'

    Import-Module -Name $script:moduleName -Force -ErrorAction 'Stop'

    $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:moduleName
    $PSDefaultParameterValues['Mock:ModuleName'] = $script:moduleName
    $PSDefaultParameterValues['Should:ModuleName'] = $script:moduleName
}

AfterAll {
    $PSDefaultParameterValues.Remove('InModuleScope:ModuleName')
    $PSDefaultParameterValues.Remove('Mock:ModuleName')
    $PSDefaultParameterValues.Remove('Should:ModuleName')

    # Unload the module being tested so that it doesn't impact any other tests.
    Get-Module -Name $script:moduleName -All | Remove-Module -Force
}

Describe 'Get-ClassAst' {
    Context 'When checking command structure' {
        It 'Should have the correct parameters in parameter set <ExpectedParameterSetName>' -ForEach @(
            @{
                ExpectedParameterSetName = '__AllParameterSets'
                ExpectedParameters = '[-ScriptFile] <string> [[-ClassName] <string>] [<CommonParameters>]'
            }
        ) {
            $result = (Get-Command -Name 'Get-ClassAst').ParameterSets |
                Where-Object -FilterScript { $_.Name -eq $ExpectedParameterSetName } |
                Select-Object -Property @(
                    @{ Name = 'ParameterSetName'; Expression = { $_.Name } },
                    @{ Name = 'ParameterListAsString'; Expression = { $_.ToString() } }
                )
            $result.ParameterSetName | Should -Be $ExpectedParameterSetName
            $result.ParameterListAsString | Should -Be $ExpectedParameters
        }

        It 'Should have ScriptFile as a mandatory parameter' {
            $parameterInfo = (Get-Command -Name 'Get-ClassAst').Parameters['ScriptFile']
            $parameterInfo.Attributes.Mandatory | Should -BeTrue
        }

        It 'Should have ClassName as an optional parameter' {
            $parameterInfo = (Get-Command -Name 'Get-ClassAst').Parameters['ClassName']
            $parameterInfo.Attributes.Mandatory | Should -BeFalse
        }
    }

    Context 'When the script file cannot be parsed' {
        BeforeAll {
            $mockBuiltModulePath = Join-Path -Path $TestDrive -ChildPath 'output\MyClassModule\1.0.0'

            New-Item -Path $mockBuiltModulePath -ItemType 'Directory' -Force

            $mockBuiltModuleScriptFilePath = Join-Path -Path $mockBuiltModulePath -ChildPath 'MyClassModule.psm1'

            # The class DSC resource in the built module.
            $mockBuiltModuleScript = @'
[DscResource()]
class MyDscResource
{
    [MyDscResource] Get()
    {
        return [MyDscResource] $this
    }

    [System.Boolean] Test()
    {
        return $true
    }

    [DscProperty(Key)]
    [System.String] $ProjectName
}
'@

            # Uses Microsoft.PowerShell.Utility\Out-File to override the stub that is needed for the mocks.
            $mockBuiltModuleScript | Microsoft.PowerShell.Utility\Out-File -FilePath $mockBuiltModuleScriptFilePath -Encoding ascii -Force
        }

        It 'Should throw an error' {
            # This evaluates just part of the expected error message.
            { Get-ClassAst -ScriptFile $mockBuiltModuleScriptFilePath } | Should -Throw "*MyDscResource*missing a Set method*"
        }
    }

    Context 'When the script file is parsed successfully' {
        BeforeAll {
            $mockBuiltModulePath = Join-Path -Path $TestDrive -ChildPath 'output\MyClassModule\1.0.0'

            New-Item -Path $mockBuiltModulePath -ItemType 'Directory' -Force

            $mockBuiltModuleScriptFilePath = Join-Path -Path $mockBuiltModulePath -ChildPath 'MyClassModule.psm1'

            # The class DSC resource in the built module.
            $mockBuiltModuleScript = @'
class MyBaseClass
{
    [void] MyHelperFunction() {}
}

[DscResource()]
class MyDscResource
{
    [MyDscResource] Get()
    {
        return [MyDscResource] $this
    }

    [System.Boolean] Test()
    {
        return $true
    }

    [void] Set() {}

    [DscProperty(Key)]
    [System.String] $ProjectName
}
'@

            # Uses Microsoft.PowerShell.Utility\Out-File to override the stub that is needed for the mocks.
            $mockBuiltModuleScript | Microsoft.PowerShell.Utility\Out-File -FilePath $mockBuiltModuleScriptFilePath -Encoding ascii -Force
        }

        Context 'When returning all classes in the script file' {
            It 'Should return the correct classes' {
                $astResult = Get-ClassAst -ScriptFile $mockBuiltModuleScriptFilePath

                $astResult | Should -HaveCount 2
                $astResult.Name | Should -Contain 'MyDscResource'
                $astResult.Name | Should -Contain 'MyBaseClass'
            }
        }

        Context 'When returning a single class from the script file' {
            It 'Should return the correct classes' {
                $astResult = Get-ClassAst -ScriptFile $mockBuiltModuleScriptFilePath -ClassName 'MyBaseClass'

                $astResult | Should -HaveCount 1
                $astResult.Name | Should -Be 'MyBaseClass'
            }
        }
    }
}
