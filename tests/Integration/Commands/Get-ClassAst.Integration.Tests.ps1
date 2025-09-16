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

    # Create test script content with multiple classes
    $script:testScriptContent = @'
class TestClassOne
{
    [string] $Property1

    [string] GetProperty()
    {
        return $this.Property1
    }
}

class TestClassTwo
{
    [int] $Property2

    [int] GetValue()
    {
        return $this.Property2
    }
}

enum TestEnum
{
    Value1
    Value2
}

function Test-Function
{
    return 'test'
}
'@

    # Create test script with invalid syntax
    $script:invalidScriptContent = @'
class InvalidClass
{
    [string] $Property1

    [string] GetProperty(
    {
        return $this.Property1
    }
}
'@

    # Create temporary test files
    $script:testScriptPath = Join-Path -Path $TestDrive -ChildPath 'TestScript.ps1'
    $script:invalidScriptPath = Join-Path -Path $TestDrive -ChildPath 'InvalidScript.ps1'
    $script:nonExistentPath = Join-Path -Path $TestDrive -ChildPath 'NonExistent.ps1'

    Set-Content -Path $script:testScriptPath -Value $script:testScriptContent -Force
    Set-Content -Path $script:invalidScriptPath -Value $script:invalidScriptContent -Force
}

Describe 'Get-ClassAst' {
    Context 'When parsing a valid PowerShell script file' {
        It 'Should return all class definitions when no ClassName is specified' {
            $result = Get-ClassAst -ScriptFile $script:testScriptPath

            $result | Should -HaveCount 2
            $result[0] | Should -BeOfType [System.Management.Automation.Language.TypeDefinitionAst]
            $result[1] | Should -BeOfType [System.Management.Automation.Language.TypeDefinitionAst]

            $classNames = $result | ForEach-Object { $_.Name }
            $classNames | Should -Contain 'TestClassOne'
            $classNames | Should -Contain 'TestClassTwo'
        }

        It 'Should return only the specified class when ClassName parameter is provided' {
            $result = Get-ClassAst -ScriptFile $script:testScriptPath -ClassName 'TestClassOne'

            $result | Should -HaveCount 1
            $result | Should -BeOfType [System.Management.Automation.Language.TypeDefinitionAst]
            $result.Name | Should -Be 'TestClassOne'
            $result.IsClass | Should -BeTrue
        }

        It 'Should return empty collection when filtering for non-existent class' {
            $result = Get-ClassAst -ScriptFile $script:testScriptPath -ClassName 'NonExistentClass'

            $result | Should -HaveCount 0
        }

        It 'Should not return enums when parsing script file' {
            $result = Get-ClassAst -ScriptFile $script:testScriptPath

            $result | Should -HaveCount 2
            $enumFound = $result | Where-Object { $_.Name -eq 'TestEnum' }
            $enumFound | Should -BeNullOrEmpty
        }

        It 'Should return TypeDefinitionAst objects with correct properties' {
            $result = Get-ClassAst -ScriptFile $script:testScriptPath -ClassName 'TestClassOne'

            $result | Should -HaveCount 1
            $result.IsClass | Should -BeTrue
            $result.Name | Should -Be 'TestClassOne'
            $result.Members | Should -Not -BeNullOrEmpty
            $result.Members.Count | Should -BeGreaterThan 0
        }
    }

    Context 'When handling error conditions' {
        It 'Should throw terminating error when script file does not exist' -ErrorAction Stop {
            { Get-ClassAst -ScriptFile $script:nonExistentPath -ErrorAction Stop } | Should -Throw -ErrorId 'GCA0005,Get-ClassAst'
        }

        It 'Should throw terminating error when script file has parse errors' {
            { Get-ClassAst -ScriptFile $script:invalidScriptPath -ErrorAction Stop } | Should -Throw -ErrorId 'GCA0006,Get-ClassAst'
        }
    }

    Context 'When working with real-world scenarios' {
        BeforeAll {
            # Create a more complex test script that mimics a DSC resource
            $script:dscResourceContent = @'
[DscResource()]
class TestDscResource
{
    [DscProperty(Key)]
    [string] $Name

    [DscProperty()]
    [string] $Value

    [DscProperty(NotConfigurable)]
    [string] $Status

    [TestDscResource] Get()
    {
        return $this
    }

    [void] Set()
    {
        # Implementation
    }

    [bool] Test()
    {
        return $true
    }
}

class HelperClass
{
    [string] $HelperProperty

    [string] DoSomething()
    {
        return 'Helper result'
    }
}
'@

            $script:dscResourcePath = Join-Path -Path $TestDrive -ChildPath 'TestDscResource.ps1'
            Set-Content -Path $script:dscResourcePath -Value $script:dscResourceContent -Force
        }

        It 'Should parse DSC resource classes correctly' {
            $result = Get-ClassAst -ScriptFile $script:dscResourcePath

            $result | Should -HaveCount 2
            $dscResourceClass = $result | Where-Object { $_.Name -eq 'TestDscResource' }
            $helperClass = $result | Where-Object { $_.Name -eq 'HelperClass' }

            $dscResourceClass | Should -Not -BeNullOrEmpty
            $dscResourceClass.IsClass | Should -BeTrue
            $dscResourceClass.Name | Should -Be 'TestDscResource'

            $helperClass | Should -Not -BeNullOrEmpty
            $helperClass.IsClass | Should -BeTrue
            $helperClass.Name | Should -Be 'HelperClass'
        }

        It 'Should filter for specific DSC resource class' {
            $result = Get-ClassAst -ScriptFile $script:dscResourcePath -ClassName 'TestDscResource'

            $result | Should -HaveCount 1
            $result.Name | Should -Be 'TestDscResource'
            $result.IsClass | Should -BeTrue
        }
    }
}
