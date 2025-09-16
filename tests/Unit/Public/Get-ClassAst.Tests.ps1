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
                ExpectedParameterSetName = 'String'
                ExpectedParameters = '-Path <string[]> [-ClassName <string>] [<CommonParameters>]'
            }
            @{
                ExpectedParameterSetName = 'FileInfo'
                ExpectedParameters = '-ScriptFile <FileInfo[]> [-ClassName <string>] [<CommonParameters>]'
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

        It 'Should have Path as a mandatory parameter in String parameter set' {
            $parameterInfo = (Get-Command -Name 'Get-ClassAst').Parameters['Path']
            $parameterInfo.Attributes.Mandatory | Should -BeTrue
        }

        It 'Should have ScriptFile as a mandatory parameter in FileInfo parameter set' {
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
            { Get-ClassAst -Path $mockBuiltModuleScriptFilePath } | Should -Throw "*MyDscResource*missing a Set method*"
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
                $astResult = Get-ClassAst -Path $mockBuiltModuleScriptFilePath

                $astResult | Should -HaveCount 2
                $astResult.Name | Should -Contain 'MyDscResource'
                $astResult.Name | Should -Contain 'MyBaseClass'
            }
        }

        Context 'When returning a single class from the script file' {
            It 'Should return the correct classes' {
                $astResult = Get-ClassAst -Path $mockBuiltModuleScriptFilePath -ClassName 'MyBaseClass'

                $astResult | Should -HaveCount 1
                $astResult.Name | Should -Be 'MyBaseClass'
            }
        }
    }

    Context 'When using pipeline input with string arrays' {
        BeforeAll {
            $mockBuiltModulePath1 = Join-Path -Path $TestDrive -ChildPath 'output\MyClassModule1\1.0.0'
            $mockBuiltModulePath2 = Join-Path -Path $TestDrive -ChildPath 'output\MyClassModule2\1.0.0'

            New-Item -Path $mockBuiltModulePath1 -ItemType 'Directory' -Force
            New-Item -Path $mockBuiltModulePath2 -ItemType 'Directory' -Force

            $mockBuiltModuleScriptFilePath1 = Join-Path -Path $mockBuiltModulePath1 -ChildPath 'MyClassModule1.psm1'
            $mockBuiltModuleScriptFilePath2 = Join-Path -Path $mockBuiltModulePath2 -ChildPath 'MyClassModule2.psm1'

            # First module with MyFirstClass
            $mockBuiltModuleScript1 = @'
class MyFirstClass
{
    [void] MyHelperFunction() {}
}
'@

            # Second module with MySecondClass
            $mockBuiltModuleScript2 = @'
class MySecondClass
{
    [void] AnotherHelperFunction() {}
}
'@

            $mockBuiltModuleScript1 | Microsoft.PowerShell.Utility\Out-File -FilePath $mockBuiltModuleScriptFilePath1 -Encoding ascii -Force
            $mockBuiltModuleScript2 | Microsoft.PowerShell.Utility\Out-File -FilePath $mockBuiltModuleScriptFilePath2 -Encoding ascii -Force
        }

        It 'Should process multiple script files via pipeline (String parameter set)' {
            $astResult = @($mockBuiltModuleScriptFilePath1, $mockBuiltModuleScriptFilePath2) | Get-ClassAst

            $astResult | Should -HaveCount 2
            $astResult.Name | Should -Contain 'MyFirstClass'
            $astResult.Name | Should -Contain 'MySecondClass'
        }

        It 'Should filter classes from multiple script files via pipeline (String parameter set)' {
            $astResult = @($mockBuiltModuleScriptFilePath1, $mockBuiltModuleScriptFilePath2) | Get-ClassAst -ClassName 'MyFirstClass'

            $astResult | Should -HaveCount 1
            $astResult.Name | Should -Be 'MyFirstClass'
        }
    }

    Context 'When using pipeline input with FileInfo objects' {
        BeforeAll {
            $mockBuiltModulePath = Join-Path -Path $TestDrive -ChildPath 'output\FileInfoTest'

            New-Item -Path $mockBuiltModulePath -ItemType 'Directory' -Force

            $mockBuiltModuleScriptFilePath1 = Join-Path -Path $mockBuiltModulePath -ChildPath 'Module1.psm1'
            $mockBuiltModuleScriptFilePath2 = Join-Path -Path $mockBuiltModulePath -ChildPath 'Module2.psm1'

            # First module with FileTestClass1
            $mockBuiltModuleScript1 = @'
class FileTestClass1
{
    [void] Method1() {}
}
'@

            # Second module with FileTestClass2
            $mockBuiltModuleScript2 = @'
class FileTestClass2
{
    [void] Method2() {}
}
'@

            $mockBuiltModuleScript1 | Microsoft.PowerShell.Utility\Out-File -FilePath $mockBuiltModuleScriptFilePath1 -Encoding ascii -Force
            $mockBuiltModuleScript2 | Microsoft.PowerShell.Utility\Out-File -FilePath $mockBuiltModuleScriptFilePath2 -Encoding ascii -Force
        }

        It 'Should process FileInfo objects from Get-ChildItem via pipeline (FileInfo parameter set)' {
            $astResult = Get-ChildItem -Path $mockBuiltModulePath -Filter '*.psm1' | Get-ClassAst

            $astResult | Should -HaveCount 2
            $astResult.Name | Should -Contain 'FileTestClass1'
            $astResult.Name | Should -Contain 'FileTestClass2'
        }

        It 'Should filter classes from FileInfo objects via pipeline (FileInfo parameter set)' {
            $astResult = Get-ChildItem -Path $mockBuiltModulePath -Filter '*.psm1' | Get-ClassAst -ClassName 'FileTestClass1'

            $astResult | Should -HaveCount 1
            $astResult.Name | Should -Be 'FileTestClass1'
        }
    }

    Context 'When using unsupported input types' {
        It 'Should handle parameter binding correctly for unsupported types' {
            # This test verifies that PowerShell's parameter binding will convert
            # unsupported types to strings when possible, which is the expected behavior
            $unsupportedInput = [System.Collections.Hashtable]@{ SomeProperty = 'Value' }

            # The hashtable will be converted to string, then treated as a file path
            { $unsupportedInput | Get-ClassAst } | Should -Throw "*does not exist*"
        }
    }
}
