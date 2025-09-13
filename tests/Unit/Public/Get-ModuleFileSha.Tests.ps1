[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
param ()

BeforeDiscovery {
    try
    {
        if (-not (Get-Module -Name 'DscResource.Test'))
        {
            # Assumes dependencies has been resolved, so if this module is not available, run 'noop' task.
            if (-not (Get-Module -Name 'DscResource.Test' -ListAvailable))
            {
                # Redirect all streams to $null, except the error stream (stream 2)
                & "$PSScriptRoot/../../../build.ps1" -Tasks 'noop' 3>&1 4>&1 5>&1 6>&1 > $null
            }

            # If the dependencies has not been resolved, this will throw an error.
            Import-Module -Name 'DscResource.Test' -Force -ErrorAction 'Stop'
        }
    }
    catch [System.IO.FileNotFoundException]
    {
        throw 'DscResource.Test module dependency not found. Please run ".\build.ps1 -ResolveDependency -Tasks build" first.'
    }
}

BeforeAll {
    $script:dscModuleName = 'Viscalyx.Common'

    Import-Module -Name $script:dscModuleName

    $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:dscModuleName
    $PSDefaultParameterValues['Mock:ModuleName'] = $script:dscModuleName
    $PSDefaultParameterValues['Should:ModuleName'] = $script:dscModuleName
}

AfterAll {
    $PSDefaultParameterValues.Remove('InModuleScope:ModuleName')
    $PSDefaultParameterValues.Remove('Mock:ModuleName')
    $PSDefaultParameterValues.Remove('Should:ModuleName')

    Get-Module -Name $script:dscModuleName -All | Remove-Module -Force
}

Describe 'Get-ModuleFileSha' {
    BeforeAll {
        # Create test module structure
        $script:testModuleBase = Join-Path -Path $TestDrive -ChildPath 'TestModule'
        New-Item -Path $script:testModuleBase -ItemType Directory -Force
        'Function Test {}' | Set-Content -Path (Join-Path -Path $script:testModuleBase -ChildPath 'TestModule.psm1')
        'Function Test {}' | Set-Content -Path (Join-Path -Path $script:testModuleBase -ChildPath 'TestModule.psd1')
    }

    Context 'When the module name is specified and exists' {
        BeforeAll {
            Mock -CommandName Get-Module -MockWith {
                return @{
                    ModuleBase = $script:testModuleBase
                }
            }

            Mock -CommandName Get-FileHash -MockWith {
                return @{
                    Hash = 'TestHash123'
                }
            }
        }

        It 'Should return the file hashes for all module files' {
            $result = Get-ModuleFileSha -Name 'TestModule'

            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 2
            $result[0].HashSHA | Should -Be 'TestHash123'
            Should -Invoke -CommandName Get-FileHash -Times 2 -Exactly
        }

        It 'Should validate module version when specified' {
            Mock -CommandName Get-ModuleVersion -MockWith {
                return '1.0.0'
            }

            $result = Get-ModuleFileSha -Name 'TestModule' -Version '1.0.0'
            $result | Should -Not -BeNullOrEmpty
            Should -Invoke -CommandName Get-ModuleVersion -Times 1 -Exactly
        }
    }

    Context 'When the module does not exist' {
        BeforeAll {
            Mock -CommandName Get-Module -MockWith { return $null }
        }

        It 'Should throw the correct error' {
            { Get-ModuleFileSha -Name 'NonExistentModule' -ErrorAction 'Stop' } |
                Should -Throw -ExpectedMessage 'Module not found: NonExistentModule'
        }
    }

    Context 'When module version does not match' {
        BeforeAll {
            Mock -CommandName Get-Module -MockWith {
                return @{
                    ModuleBase = $script:testModuleBase
                }
            }

            Mock -CommandName Get-ModuleVersion -MockWith {
                return '2.0.0'
            }
        }

        It 'Should throw version mismatch error' {
            { Get-ModuleFileSha -Name 'TestModule' -Version '1.0.0' -ErrorAction 'Stop' } |
                Should -Throw -ExpectedMessage 'Module with specified version not found: TestModule 1.0.0'
        }
    }

    Context 'When using path parameter' {
        BeforeAll {
            Mock -CommandName Get-FileHash -MockWith {
                return @{
                    Hash = 'TestHash123'
                }
            }
        }

        It 'Should return file hashes when path exists' {
            $result = Get-ModuleFileSha -Path $script:testModuleBase

            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 2
            $result[0].HashSHA | Should -Be 'TestHash123'
        }

        It 'Should throw when path does not exist' {
            { Get-ModuleFileSha -Path 'NonExistentPath' -ErrorAction 'Stop' } |
                Should -Throw -ExpectedMessage "Cannot validate argument on parameter 'Path'. The specified path must be a directory, the root of a module including its version folder, e.g. './Viscalyx.Common/1.0.0'."
        }
    }

    Context 'When verifying relative path output' {
        BeforeAll {
            # Create test module structure with parent folders
            $script:testModuleRelativeBase = Join-Path -Path $TestDrive -ChildPath 'TestModuleRelative'
            $publicFolder = Join-Path -Path $script:testModuleRelativeBase -ChildPath 'Public'
            $privateFolder = Join-Path -Path $script:testModuleRelativeBase -ChildPath 'Private'

            New-Item -Path $script:testModuleRelativeBase -ItemType Directory -Force
            New-Item -Path $publicFolder -ItemType Directory -Force
            New-Item -Path $privateFolder -ItemType Directory -Force

            'Function RootTest {}' | Set-Content -Path (Join-Path -Path $script:testModuleRelativeBase -ChildPath 'TestModule.psm1')
            'Function PublicTest {}' | Set-Content -Path (Join-Path -Path $publicFolder -ChildPath 'Test.ps1')
            'Function PrivateTest {}' | Set-Content -Path (Join-Path -Path $privateFolder -ChildPath 'Helper.ps1')

            Mock -CommandName Get-FileHash -MockWith {
                return @{
                    Hash = 'TestHash123'
                }
            }
        }

        It 'Should output correct relative paths including parent folders' {
            $result = Get-ModuleFileSha -Path $script:testModuleRelativeBase

            $result.Count | Should -Be 3

            $result.ModuleBase[0] | Should -Be $script:testModuleRelativeBase
            $result.ModuleBase[1] | Should -Be $script:testModuleRelativeBase
            $result.ModuleBase[2] | Should -Be $script:testModuleRelativeBase
            $result.HashSHA[0]  | Should -Be 'TestHash123'
            $result.HashSHA[1]  | Should -Be 'TestHash123'
            $result.HashSHA[2]  | Should -Be 'TestHash123'

            $result.RelativePath | Should -Contain 'TestModule.psm1'
            $result.RelativePath | Should -Contain ('Public{0}Test.ps1' -f [System.IO.Path]::DirectorySeparatorChar)
            $result.RelativePath | Should -Contain ('Private{0}Helper.ps1' -f [System.IO.Path]::DirectorySeparatorChar)
            $result.RelativePath | Should -Not -Match [regex]::Escape($script:testModuleRelativeBase)

            $result.FileName | Should -Contain 'TestModule.psm1'
            $result.FileName | Should -Contain 'Test.ps1'
            $result.FileName | Should -Contain 'Helper.ps1'
            $result.FileName | Should -Not -Match [regex]::Escape($script:testModuleRelativeBase)
        }
    }
}
