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
}

Describe 'Get-ClassResourceAst Integration Tests' {
    Context 'When parsing real DSC resource classes' {
        BeforeAll {
            $script:dscResourceContent = @'
class HelperClass
{
    [System.String] $Name
    
    [System.String] GetValue()
    {
        return $this.Name
    }
}

[DscResource()]
class TestDscResource
{
    [DscProperty(Key)]
    [System.String] $Name

    [DscProperty()]
    [System.String] $Value

    [TestDscResource] Get()
    {
        return [TestDscResource] $this
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

[DscResource()]
class AnotherDscResource
{
    [DscProperty(Key)]
    [System.String] $Key

    [AnotherDscResource] Get()
    {
        return [AnotherDscResource] $this
    }

    [System.Boolean] Test()
    {
        return $false
    }

    [void] Set()
    {
        # Implementation
    }
}
'@

            $script:dscResourcePath = Join-Path -Path $TestDrive -ChildPath 'TestDscResource.ps1'
            Set-Content -Path $script:dscResourcePath -Value $script:dscResourceContent -Force
        }

        It 'Should parse DSC resource classes correctly' {
            $result = Get-ClassResourceAst -ScriptFile $script:dscResourcePath

            $result | Should -HaveCount 2
            $dscResourceClass1 = $result | Where-Object { $_.Name -eq 'TestDscResource' }
            $dscResourceClass2 = $result | Where-Object { $_.Name -eq 'AnotherDscResource' }

            $dscResourceClass1 | Should -Not -BeNullOrEmpty
            $dscResourceClass1.IsClass | Should -BeTrue
            $dscResourceClass1.Name | Should -Be 'TestDscResource'

            $dscResourceClass2 | Should -Not -BeNullOrEmpty
            $dscResourceClass2.IsClass | Should -BeTrue
            $dscResourceClass2.Name | Should -Be 'AnotherDscResource'

            # Should not include the helper class that doesn't have DscResource attribute
            $result.Name | Should -Not -Contain 'HelperClass'
        }

        It 'Should filter for specific DSC resource class' {
            $result = Get-ClassResourceAst -ScriptFile $script:dscResourcePath -ClassName 'TestDscResource'

            $result | Should -HaveCount 1
            $result.Name | Should -Be 'TestDscResource'
            $result.IsClass | Should -BeTrue
        }

        It 'Should return empty collection when filtering for non-existent DSC resource' {
            $result = Get-ClassResourceAst -ScriptFile $script:dscResourcePath -ClassName 'NonExistentDscResource'

            $result | Should -HaveCount 0
        }

        It 'Should return empty collection when filtering for non-DSC class' {
            $result = Get-ClassResourceAst -ScriptFile $script:dscResourcePath -ClassName 'HelperClass'

            $result | Should -HaveCount 0
        }
    }

    Context 'When parsing script files with multiple classes' {
        BeforeAll {
            $script:testScriptContent = @'
class RegularClass
{
    [System.String] $Property
}

[DscResource()]
class FirstDscResource
{
    [DscProperty(Key)]
    [System.String] $Key

    [FirstDscResource] Get()
    {
        return [FirstDscResource] $this
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

class AnotherRegularClass
{
    [System.Int32] $Number
}

[DscResource()]
class SecondDscResource
{
    [DscProperty(Key)]
    [System.String] $Identifier

    [SecondDscResource] Get()
    {
        return [SecondDscResource] $this
    }

    [System.Boolean] Test()
    {
        return $false
    }

    [void] Set()
    {
        # Implementation
    }
}

enum TestEnum
{
    Value1
    Value2
}
'@

            $script:testScriptPath = Join-Path -Path $TestDrive -ChildPath 'TestScript.ps1'
            Set-Content -Path $script:testScriptPath -Value $script:testScriptContent -Force
        }

        It 'Should return only DSC resource classes' {
            $result = Get-ClassResourceAst -ScriptFile $script:testScriptPath

            $result | Should -HaveCount 2
            $classNames = $result | ForEach-Object { $_.Name }
            $classNames | Should -Contain 'FirstDscResource'
            $classNames | Should -Contain 'SecondDscResource'
            $classNames | Should -Not -Contain 'RegularClass'
            $classNames | Should -Not -Contain 'AnotherRegularClass'
        }

        It 'Should return only the specified DSC resource class when ClassName parameter is provided' {
            $result = Get-ClassResourceAst -ScriptFile $script:testScriptPath -ClassName 'FirstDscResource'

            $result | Should -HaveCount 1
            $result | Should -BeOfType [System.Management.Automation.Language.TypeDefinitionAst]
            $result.Name | Should -Be 'FirstDscResource'
            $result.IsClass | Should -BeTrue
        }

        It 'Should return empty collection when filtering for regular class' {
            $result = Get-ClassResourceAst -ScriptFile $script:testScriptPath -ClassName 'RegularClass'

            $result | Should -HaveCount 0
        }

        It 'Should not return enums when parsing script file' {
            $result = Get-ClassResourceAst -ScriptFile $script:testScriptPath

            $result | Should -HaveCount 2
            $classNames = $result | ForEach-Object { $_.Name }
            $classNames | Should -Not -Contain 'TestEnum'
        }
    }

    Context 'When processing file paths using Path parameter' {
        BeforeAll {
            $script:pathTestContent = @'
[DscResource()]
class PathTestDscResource
{
    [DscProperty(Key)]
    [System.String] $Name

    [PathTestDscResource] Get()
    {
        return [PathTestDscResource] $this
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

            $script:pathTestScriptPath = Join-Path -Path $TestDrive -ChildPath 'PathTest.ps1'
            Set-Content -Path $script:pathTestScriptPath -Value $script:pathTestContent -Force
        }

        It 'Should work with Path parameter' {
            $result = Get-ClassResourceAst -Path $script:pathTestScriptPath

            $result | Should -HaveCount 1
            $result.Name | Should -Be 'PathTestDscResource'
            $result.IsClass | Should -BeTrue
        }

        It 'Should work with Path parameter and ClassName filter' {
            $result = Get-ClassResourceAst -Path $script:pathTestScriptPath -ClassName 'PathTestDscResource'

            $result | Should -HaveCount 1
            $result.Name | Should -Be 'PathTestDscResource'
        }

        It 'Should throw error for non-existent file path' {
            $nonExistentPath = Join-Path -Path $TestDrive -ChildPath 'NonExistent.ps1'

            { Get-ClassResourceAst -Path $nonExistentPath } | Should -Throw "*does not exist*"
        }
    }
}