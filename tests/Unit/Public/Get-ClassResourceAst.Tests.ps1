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

Describe 'Get-ClassResourceAst' {
    Context 'When checking command structure' {
        BeforeDiscovery {
            $testCases = @(
                @{
                    ExpectedParameterSetName = 'String'
                    ExpectedParameters = '-Path <string[]> [-ClassName <string>] [<CommonParameters>]'
                }
                @{
                    ExpectedParameterSetName = 'FileInfo'
                    ExpectedParameters = '-ScriptFile <FileInfo[]> [-ClassName <string>] [<CommonParameters>]'
                }
            )
        }

        It 'Should have the correct parameters in parameter set <ExpectedParameterSetName>' -ForEach $testCases {
            $result = (Get-Command -Name 'Get-ClassResourceAst').ParameterSets |
                Where-Object -FilterScript { $_.Name -eq $ExpectedParameterSetName } |
                Select-Object -Property @(
                    @{ Name = 'ParameterSetName'; Expression = { $_.Name } },
                    @{ Name = 'ParameterListAsString'; Expression = { $_.ToString() } }
                )
            $result.ParameterSetName | Should -Be $ExpectedParameterSetName
            $result.ParameterListAsString | Should -Be $ExpectedParameters
        }

        It 'Should have Path as a mandatory parameter in String parameter set' {
            $parameterInfo = (Get-Command -Name 'Get-ClassResourceAst').Parameters['Path']
            $parameterInfo.Attributes.Mandatory | Should -BeTrue
        }

        It 'Should have ScriptFile as a mandatory parameter in FileInfo parameter set' {
            $parameterInfo = (Get-Command -Name 'Get-ClassResourceAst').Parameters['ScriptFile']
            $parameterInfo.Attributes.Mandatory | Should -BeTrue
        }

        It 'Should have ClassName as an optional parameter' {
            $parameterInfo = (Get-Command -Name 'Get-ClassResourceAst').Parameters['ClassName']
            $parameterInfo.Attributes.Mandatory | Should -BeFalse
        }
    }

    Context 'When the script file cannot be parsed' {
        It 'Should throw an error' {
            $invalidScriptPath = Join-Path -Path $TestDrive -ChildPath 'invalid.ps1'
            Set-Content -Path $invalidScriptPath -Value 'class InvalidSyntax { [' -Force

            { Get-ClassResourceAst -Path $invalidScriptPath } | Should -Throw '*failed*'
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
class AzDevOpsProject
{
    [AzDevOpsProject] Get()
    {
        return [AzDevOpsProject] $this
    }

    [System.Boolean] Test()
    {
        return $true
    }

    [void] Set() {}

    [DscProperty(Key)]
    [System.String] $ProjectName
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

        Context 'When returning all DSC class resources in the script file' {
            It 'Should return the correct DSC class resources' {
                $astResult = Get-ClassResourceAst -Path $mockBuiltModuleScriptFilePath

                $astResult | Should -HaveCount 2
                $astResult.Name | Should -Contain 'MyDscResource'
                $astResult.Name | Should -Contain 'AzDevOpsProject'
                $astResult.Name | Should -Not -Contain 'MyBaseClass'
            }
        }

        Context 'When returning a single DSC class resource from the script file' {
            It 'Should return the correct DSC class resource' {
                $astResult = Get-ClassResourceAst -Path $mockBuiltModuleScriptFilePath -ClassName 'MyDscResource'

                $astResult | Should -HaveCount 1
                $astResult.Name | Should -Be 'MyDscResource'
            }
        }
    }

    Context 'When using pipeline input with string arrays' {
        BeforeAll {
            $mockBuiltModulePath = Join-Path -Path $TestDrive -ChildPath 'output\StringArrayTest'

            New-Item -Path $mockBuiltModulePath -ItemType 'Directory' -Force

            $mockBuiltModuleScriptFilePath1 = Join-Path -Path $mockBuiltModulePath -ChildPath 'Module1.psm1'
            $mockBuiltModuleScriptFilePath2 = Join-Path -Path $mockBuiltModulePath -ChildPath 'Module2.psm1'

            # First module with DSC resource
            $mockBuiltModuleScript1 = @'
[DscResource()]
class MyFirstDscResource
{
    [DscProperty(Key)]
    [System.String] $Name

    [MyFirstDscResource] Get()
    {
        return [MyFirstDscResource] $this
    }

    [System.Boolean] Test()
    {
        return $true
    }

    [void] Set()
    {
        # Implementation
    }
}
'@

            # Second module with DSC resource
            $mockBuiltModuleScript2 = @'
[DscResource()]
class MySecondDscResource
{
    [DscProperty(Key)]
    [System.String] $Name

    [MySecondDscResource] Get()
    {
        return [MySecondDscResource] $this
    }

    [System.Boolean] Test()
    {
        return $true
    }

    [void] Set()
    {
        # Implementation
    }
}
'@

            $mockBuiltModuleScript1 | Microsoft.PowerShell.Utility\Out-File -FilePath $mockBuiltModuleScriptFilePath1 -Encoding ascii -Force
            $mockBuiltModuleScript2 | Microsoft.PowerShell.Utility\Out-File -FilePath $mockBuiltModuleScriptFilePath2 -Encoding ascii -Force
        }

        It 'Should process multiple script files via pipeline (String parameter set)' {
            $astResult = @($mockBuiltModuleScriptFilePath1, $mockBuiltModuleScriptFilePath2) | Get-ClassResourceAst

            $astResult | Should -HaveCount 2
            $astResult.Name | Should -Contain 'MyFirstDscResource'
            $astResult.Name | Should -Contain 'MySecondDscResource'
        }

        It 'Should filter DSC class resources from multiple script files via pipeline (String parameter set)' {
            $astResult = @($mockBuiltModuleScriptFilePath1, $mockBuiltModuleScriptFilePath2) | Get-ClassResourceAst -ClassName 'MyFirstDscResource'

            $astResult | Should -HaveCount 1
            $astResult.Name | Should -Be 'MyFirstDscResource'
        }
    }

    Context 'When using pipeline input with FileInfo objects' {
        BeforeAll {
            $mockBuiltModulePath = Join-Path -Path $TestDrive -ChildPath 'output\FileInfoTest'

            New-Item -Path $mockBuiltModulePath -ItemType 'Directory' -Force

            $mockBuiltModuleScriptFilePath1 = Join-Path -Path $mockBuiltModulePath -ChildPath 'Module1.psm1'
            $mockBuiltModuleScriptFilePath2 = Join-Path -Path $mockBuiltModulePath -ChildPath 'Module2.psm1'

            # First module with DSC resource
            $mockBuiltModuleScript1 = @'
[DscResource()]
class FileTestDscResource1
{
    [DscProperty(Key)]
    [System.String] $Name

    [FileTestDscResource1] Get()
    {
        return [FileTestDscResource1] $this
    }

    [System.Boolean] Test()
    {
        return $true
    }

    [void] Set()
    {
        # Implementation
    }
}
'@

            # Second module with DSC resource
            $mockBuiltModuleScript2 = @'
[DscResource()]
class FileTestDscResource2
{
    [DscProperty(Key)]
    [System.String] $Name

    [FileTestDscResource2] Get()
    {
        return [FileTestDscResource2] $this
    }

    [System.Boolean] Test()
    {
        return $true
    }

    [void] Set()
    {
        # Implementation
    }
}
'@

            $mockBuiltModuleScript1 | Microsoft.PowerShell.Utility\Out-File -FilePath $mockBuiltModuleScriptFilePath1 -Encoding ascii -Force
            $mockBuiltModuleScript2 | Microsoft.PowerShell.Utility\Out-File -FilePath $mockBuiltModuleScriptFilePath2 -Encoding ascii -Force
        }

        It 'Should process FileInfo objects from Get-ChildItem via pipeline (FileInfo parameter set)' {
            $astResult = Get-ChildItem -Path $mockBuiltModulePath -Filter '*.psm1' | Get-ClassResourceAst

            $astResult | Should -HaveCount 2
            $astResult.Name | Should -Contain 'FileTestDscResource1'
            $astResult.Name | Should -Contain 'FileTestDscResource2'
        }

        It 'Should filter DSC class resources from FileInfo objects via pipeline (FileInfo parameter set)' {
            $astResult = Get-ChildItem -Path $mockBuiltModulePath -Filter '*.psm1' | Get-ClassResourceAst -ClassName 'FileTestDscResource1'

            $astResult | Should -HaveCount 1
            $astResult.Name | Should -Be 'FileTestDscResource1'
        }
    }

    Context 'When using unsupported input types' {
        It 'Should handle parameter binding correctly for unsupported types' {
            # This test verifies that PowerShell's parameter binding will convert
            # unsupported types to strings when possible, which is the expected behavior
            $unsupportedInput = [System.Collections.Hashtable]@{ SomeProperty = 'Value' }

            # The hashtable will be converted to string, then treated as a file path
            { $unsupportedInput | Get-ClassResourceAst } | Should -Throw "*does not exist*"
        }
    }
}
