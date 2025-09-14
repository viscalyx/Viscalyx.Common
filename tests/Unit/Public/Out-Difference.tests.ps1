[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '', Justification = 'Suppressing this rule because Script Analyzer does not understand Pester syntax.')]
param ()

# ----
# NOTE! This file must be UTF with BOM for the unicode test to work.
# ----

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
        throw 'DscResource.Test module dependency not found. Please run ".\build.ps1 -ResolveDependency -Tasks build" first.'
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

Describe 'Out-Difference' {
    It 'Should have the expected parameter set <Name>' -ForEach @(
        @{
            Name = '__AllParameterSets'
            ExpectedParameterSetString = '[-Reference] <string[]> [-Difference] <string[]> [[-EqualIndicator] <string>] [[-NotEqualIndicator] <string>] [[-HighlightStart] <string>] [[-HighlightEnd] <string>] [[-ReferenceLabel] <string>] [[-DifferenceLabel] <string>] [[-ReferenceLabelAnsi] <string>] [[-DifferenceLabelAnsi] <string>] [[-ColumnHeaderAnsi] <string>] [[-ColumnHeaderResetAnsi] <string>] [[-EncodingType] <string>] [[-ConcatenateChar] <string>] [-NoColumnHeader] [-NoLabels] [-ConcatenateArray] [-NoHexOutput] [<CommonParameters>]'
        }
    ) {
        $parameterSet = (Get-Command -Name 'Out-Difference').ParameterSets |
            Where-Object -FilterScript { $_.Name -eq $Name }

        $parameterSet | Should -Not -BeNullOrEmpty
        $parameterSet.Name | Should -Be $Name
        $parameterSet.ToString() | Should -Be $ExpectedParameterSetString
    }

    BeforeAll {
        $esc = [System.Char] 0x1b
    }

    # cSpell: disable
    Context 'When there are multiple lines' {
        It 'Should output to console' {
            $expected = @(
                'My String very long string that is longer than actual'
                'Line 2'
                'Line 3'
            )
            $actual = @(
                'My string that is shorter'
                'Line 2'
                'Line 3 is longer than expected'
                'Line 4'
            )

            $result = Out-Difference -Reference $expected -Difference $actual

            $result | Should-BeBlockString @(
                "Expected:$($esc)[0m                                                               But was:$($esc)[0m"
                "----------------------------------------------------------------        ----------------------------------------------------------------"
                "Bytes                                           Ascii                   Bytes                                           Ascii"
                "-----                                           -----                   -----                                           -----"
                "4D 79 20 $($esc)[31m53$($esc)[0m 74 72 69 6E 67 20 $($esc)[31m76$($esc)[0m $($esc)[31m65$($esc)[0m $($esc)[31m72$($esc)[0m $($esc)[31m79$($esc)[0m 20 $($esc)[31m6C$($esc)[0m My $($esc)[31mS$($esc)[0mtring $($esc)[31mv$($esc)[0m$($esc)[31me$($esc)[0m$($esc)[31mr$($esc)[0m$($esc)[31my$($esc)[0m $($esc)[31ml$($esc)[0m   !=   4D 79 20 $($esc)[31m73$($esc)[0m 74 72 69 6E 67 20 $($esc)[31m74$($esc)[0m $($esc)[31m68$($esc)[0m $($esc)[31m61$($esc)[0m $($esc)[31m74$($esc)[0m 20 $($esc)[31m69$($esc)[0m My $($esc)[31ms$($esc)[0mtring $($esc)[31mt$($esc)[0m$($esc)[31mh$($esc)[0m$($esc)[31ma$($esc)[0m$($esc)[31mt$($esc)[0m $($esc)[31mi$($esc)[0m"
                "$($esc)[31m6F$($esc)[0m $($esc)[31m6E$($esc)[0m $($esc)[31m67$($esc)[0m $($esc)[31m20$($esc)[0m $($esc)[31m73$($esc)[0m $($esc)[31m74$($esc)[0m $($esc)[31m72$($esc)[0m $($esc)[31m69$($esc)[0m $($esc)[31m6E$($esc)[0m $($esc)[31m67$($esc)[0m $($esc)[31m20$($esc)[0m $($esc)[31m74$($esc)[0m $($esc)[31m68$($esc)[0m $($esc)[31m61$($esc)[0m $($esc)[31m74$($esc)[0m $($esc)[31m20$($esc)[0m $($esc)[31mo$($esc)[0m$($esc)[31mn$($esc)[0m$($esc)[31mg$($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31ms$($esc)[0m$($esc)[31mt$($esc)[0m$($esc)[31mr$($esc)[0m$($esc)[31mi$($esc)[0m$($esc)[31mn$($esc)[0m$($esc)[31mg$($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31mt$($esc)[0m$($esc)[31mh$($esc)[0m$($esc)[31ma$($esc)[0m$($esc)[31mt$($esc)[0m$($esc)[31m $($esc)[0m   !=   $($esc)[31m73$($esc)[0m $($esc)[31m20$($esc)[0m $($esc)[31m73$($esc)[0m $($esc)[31m68$($esc)[0m $($esc)[31m6F$($esc)[0m $($esc)[31m72$($esc)[0m $($esc)[31m74$($esc)[0m $($esc)[31m65$($esc)[0m $($esc)[31m72$($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31ms$($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31ms$($esc)[0m$($esc)[31mh$($esc)[0m$($esc)[31mo$($esc)[0m$($esc)[31mr$($esc)[0m$($esc)[31mt$($esc)[0m$($esc)[31me$($esc)[0m$($esc)[31mr$($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m"
                "$($esc)[31m69$($esc)[0m $($esc)[31m73$($esc)[0m $($esc)[31m20$($esc)[0m $($esc)[31m6C$($esc)[0m $($esc)[31m6F$($esc)[0m $($esc)[31m6E$($esc)[0m $($esc)[31m67$($esc)[0m $($esc)[31m65$($esc)[0m $($esc)[31m72$($esc)[0m $($esc)[31m20$($esc)[0m $($esc)[31m74$($esc)[0m $($esc)[31m68$($esc)[0m $($esc)[31m61$($esc)[0m $($esc)[31m6E$($esc)[0m $($esc)[31m20$($esc)[0m $($esc)[31m61$($esc)[0m $($esc)[31mi$($esc)[0m$($esc)[31ms$($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31ml$($esc)[0m$($esc)[31mo$($esc)[0m$($esc)[31mn$($esc)[0m$($esc)[31mg$($esc)[0m$($esc)[31me$($esc)[0m$($esc)[31mr$($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31mt$($esc)[0m$($esc)[31mh$($esc)[0m$($esc)[31ma$($esc)[0m$($esc)[31mn$($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31ma$($esc)[0m   !=   $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m"
                "$($esc)[31m63$($esc)[0m $($esc)[31m74$($esc)[0m $($esc)[31m75$($esc)[0m $($esc)[31m61$($esc)[0m $($esc)[31m6C$($esc)[0m                                  $($esc)[31mc$($esc)[0m$($esc)[31mt$($esc)[0m$($esc)[31mu$($esc)[0m$($esc)[31ma$($esc)[0m$($esc)[31ml$($esc)[0m              !=   $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m                                  $($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m           "
                "Expected:$($esc)[0m                                                               But was:$($esc)[0m"
                "----------------------------------------------------------------        ----------------------------------------------------------------"
                "Bytes                                           Ascii                   Bytes                                           Ascii"
                "-----                                           -----                   -----                                           -----"
                "4C 69 6E 65 20 32                               Line 2             ==   4C 69 6E 65 20 32                               Line 2          "
                "Expected:$($esc)[0m                                                               But was:$($esc)[0m"
                "----------------------------------------------------------------        ----------------------------------------------------------------"
                "Bytes                                           Ascii                   Bytes                                           Ascii"
                "-----                                           -----                   -----                                           -----"
                "4C 69 6E 65 20 33 $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m Line 3$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m   !=   4C 69 6E 65 20 33 $($esc)[31m20$($esc)[0m $($esc)[31m69$($esc)[0m $($esc)[31m73$($esc)[0m $($esc)[31m20$($esc)[0m $($esc)[31m6C$($esc)[0m $($esc)[31m6F$($esc)[0m $($esc)[31m6E$($esc)[0m $($esc)[31m67$($esc)[0m $($esc)[31m65$($esc)[0m $($esc)[31m72$($esc)[0m Line 3$($esc)[31m $($esc)[0m$($esc)[31mi$($esc)[0m$($esc)[31ms$($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31ml$($esc)[0m$($esc)[31mo$($esc)[0m$($esc)[31mn$($esc)[0m$($esc)[31mg$($esc)[0m$($esc)[31me$($esc)[0m$($esc)[31mr$($esc)[0m"
                "$($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m       $($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m     !=   $($esc)[31m20$($esc)[0m $($esc)[31m74$($esc)[0m $($esc)[31m68$($esc)[0m $($esc)[31m61$($esc)[0m $($esc)[31m6E$($esc)[0m $($esc)[31m20$($esc)[0m $($esc)[31m65$($esc)[0m $($esc)[31m78$($esc)[0m $($esc)[31m70$($esc)[0m $($esc)[31m65$($esc)[0m $($esc)[31m63$($esc)[0m $($esc)[31m74$($esc)[0m $($esc)[31m65$($esc)[0m $($esc)[31m64$($esc)[0m       $($esc)[31m $($esc)[0m$($esc)[31mt$($esc)[0m$($esc)[31mh$($esc)[0m$($esc)[31ma$($esc)[0m$($esc)[31mn$($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31me$($esc)[0m$($esc)[31mx$($esc)[0m$($esc)[31mp$($esc)[0m$($esc)[31me$($esc)[0m$($esc)[31mc$($esc)[0m$($esc)[31mt$($esc)[0m$($esc)[31me$($esc)[0m$($esc)[31md$($esc)[0m  "
                "Expected:$($esc)[0m                                                               But was:$($esc)[0m"
                "----------------------------------------------------------------        ----------------------------------------------------------------"
                "Bytes                                           Ascii                   Bytes                                           Ascii"
                "-----                                           -----                   -----                                           -----"
                "$($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m                               $($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m             !=   $($esc)[31m4C$($esc)[0m $($esc)[31m69$($esc)[0m $($esc)[31m6E$($esc)[0m $($esc)[31m65$($esc)[0m $($esc)[31m20$($esc)[0m $($esc)[31m34$($esc)[0m                               $($esc)[31mL$($esc)[0m$($esc)[31mi$($esc)[0m$($esc)[31mn$($esc)[0m$($esc)[31me$($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m4$($esc)[0m          "
            )
        }

        It 'Should output to console, but without column header' {
            $expected = @(
                'My String very long string that is longer than actual'
                'Line 2'
                'Line 3'
            )
            $actual = @(
                'My string that is shorter'
                'Line 2'
                'Line 3 is longer than expected'
                'Line 4'
            )

            $result = Out-Difference -Reference $expected -Difference $actual -NoColumnHeader

            $result | Should-BeBlockString @(
                "Expected:$($esc)[0m                                                               But was:$($esc)[0m"
                "----------------------------------------------------------------        ----------------------------------------------------------------"
                "4D 79 20 $($esc)[31m53$($esc)[0m 74 72 69 6E 67 20 $($esc)[31m76$($esc)[0m $($esc)[31m65$($esc)[0m $($esc)[31m72$($esc)[0m $($esc)[31m79$($esc)[0m 20 $($esc)[31m6C$($esc)[0m My $($esc)[31mS$($esc)[0mtring $($esc)[31mv$($esc)[0m$($esc)[31me$($esc)[0m$($esc)[31mr$($esc)[0m$($esc)[31my$($esc)[0m $($esc)[31ml$($esc)[0m   !=   4D 79 20 $($esc)[31m73$($esc)[0m 74 72 69 6E 67 20 $($esc)[31m74$($esc)[0m $($esc)[31m68$($esc)[0m $($esc)[31m61$($esc)[0m $($esc)[31m74$($esc)[0m 20 $($esc)[31m69$($esc)[0m My $($esc)[31ms$($esc)[0mtring $($esc)[31mt$($esc)[0m$($esc)[31mh$($esc)[0m$($esc)[31ma$($esc)[0m$($esc)[31mt$($esc)[0m $($esc)[31mi$($esc)[0m"
                "$($esc)[31m6F$($esc)[0m $($esc)[31m6E$($esc)[0m $($esc)[31m67$($esc)[0m $($esc)[31m20$($esc)[0m $($esc)[31m73$($esc)[0m $($esc)[31m74$($esc)[0m $($esc)[31m72$($esc)[0m $($esc)[31m69$($esc)[0m $($esc)[31m6E$($esc)[0m $($esc)[31m67$($esc)[0m $($esc)[31m20$($esc)[0m $($esc)[31m74$($esc)[0m $($esc)[31m68$($esc)[0m $($esc)[31m61$($esc)[0m $($esc)[31m74$($esc)[0m $($esc)[31m20$($esc)[0m $($esc)[31mo$($esc)[0m$($esc)[31mn$($esc)[0m$($esc)[31mg$($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31ms$($esc)[0m$($esc)[31mt$($esc)[0m$($esc)[31mr$($esc)[0m$($esc)[31mi$($esc)[0m$($esc)[31mn$($esc)[0m$($esc)[31mg$($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31mt$($esc)[0m$($esc)[31mh$($esc)[0m$($esc)[31ma$($esc)[0m$($esc)[31mt$($esc)[0m$($esc)[31m $($esc)[0m   !=   $($esc)[31m73$($esc)[0m $($esc)[31m20$($esc)[0m $($esc)[31m73$($esc)[0m $($esc)[31m68$($esc)[0m $($esc)[31m6F$($esc)[0m $($esc)[31m72$($esc)[0m $($esc)[31m74$($esc)[0m $($esc)[31m65$($esc)[0m $($esc)[31m72$($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31ms$($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31ms$($esc)[0m$($esc)[31mh$($esc)[0m$($esc)[31mo$($esc)[0m$($esc)[31mr$($esc)[0m$($esc)[31mt$($esc)[0m$($esc)[31me$($esc)[0m$($esc)[31mr$($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m"
                "$($esc)[31m69$($esc)[0m $($esc)[31m73$($esc)[0m $($esc)[31m20$($esc)[0m $($esc)[31m6C$($esc)[0m $($esc)[31m6F$($esc)[0m $($esc)[31m6E$($esc)[0m $($esc)[31m67$($esc)[0m $($esc)[31m65$($esc)[0m $($esc)[31m72$($esc)[0m $($esc)[31m20$($esc)[0m $($esc)[31m74$($esc)[0m $($esc)[31m68$($esc)[0m $($esc)[31m61$($esc)[0m $($esc)[31m6E$($esc)[0m $($esc)[31m20$($esc)[0m $($esc)[31m61$($esc)[0m $($esc)[31mi$($esc)[0m$($esc)[31ms$($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31ml$($esc)[0m$($esc)[31mo$($esc)[0m$($esc)[31mn$($esc)[0m$($esc)[31mg$($esc)[0m$($esc)[31me$($esc)[0m$($esc)[31mr$($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31mt$($esc)[0m$($esc)[31mh$($esc)[0m$($esc)[31ma$($esc)[0m$($esc)[31mn$($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31ma$($esc)[0m   !=   $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m"
                "$($esc)[31m63$($esc)[0m $($esc)[31m74$($esc)[0m $($esc)[31m75$($esc)[0m $($esc)[31m61$($esc)[0m $($esc)[31m6C$($esc)[0m                                  $($esc)[31mc$($esc)[0m$($esc)[31mt$($esc)[0m$($esc)[31mu$($esc)[0m$($esc)[31ma$($esc)[0m$($esc)[31ml$($esc)[0m              !=   $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m                                  $($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m           "
                "Expected:$($esc)[0m                                                               But was:$($esc)[0m"
                "----------------------------------------------------------------        ----------------------------------------------------------------"
                "4C 69 6E 65 20 32                               Line 2             ==   4C 69 6E 65 20 32                               Line 2          "
                "Expected:$($esc)[0m                                                               But was:$($esc)[0m"
                "----------------------------------------------------------------        ----------------------------------------------------------------"
                "4C 69 6E 65 20 33 $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m Line 3$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m   !=   4C 69 6E 65 20 33 $($esc)[31m20$($esc)[0m $($esc)[31m69$($esc)[0m $($esc)[31m73$($esc)[0m $($esc)[31m20$($esc)[0m $($esc)[31m6C$($esc)[0m $($esc)[31m6F$($esc)[0m $($esc)[31m6E$($esc)[0m $($esc)[31m67$($esc)[0m $($esc)[31m65$($esc)[0m $($esc)[31m72$($esc)[0m Line 3$($esc)[31m $($esc)[0m$($esc)[31mi$($esc)[0m$($esc)[31ms$($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31ml$($esc)[0m$($esc)[31mo$($esc)[0m$($esc)[31mn$($esc)[0m$($esc)[31mg$($esc)[0m$($esc)[31me$($esc)[0m$($esc)[31mr$($esc)[0m"
                "$($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m       $($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m     !=   $($esc)[31m20$($esc)[0m $($esc)[31m74$($esc)[0m $($esc)[31m68$($esc)[0m $($esc)[31m61$($esc)[0m $($esc)[31m6E$($esc)[0m $($esc)[31m20$($esc)[0m $($esc)[31m65$($esc)[0m $($esc)[31m78$($esc)[0m $($esc)[31m70$($esc)[0m $($esc)[31m65$($esc)[0m $($esc)[31m63$($esc)[0m $($esc)[31m74$($esc)[0m $($esc)[31m65$($esc)[0m $($esc)[31m64$($esc)[0m       $($esc)[31m $($esc)[0m$($esc)[31mt$($esc)[0m$($esc)[31mh$($esc)[0m$($esc)[31ma$($esc)[0m$($esc)[31mn$($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31me$($esc)[0m$($esc)[31mx$($esc)[0m$($esc)[31mp$($esc)[0m$($esc)[31me$($esc)[0m$($esc)[31mc$($esc)[0m$($esc)[31mt$($esc)[0m$($esc)[31me$($esc)[0m$($esc)[31md$($esc)[0m  "
                "Expected:$($esc)[0m                                                               But was:$($esc)[0m"
                "----------------------------------------------------------------        ----------------------------------------------------------------"
                "$($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m                               $($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m             !=   $($esc)[31m4C$($esc)[0m $($esc)[31m69$($esc)[0m $($esc)[31m6E$($esc)[0m $($esc)[31m65$($esc)[0m $($esc)[31m20$($esc)[0m $($esc)[31m34$($esc)[0m                               $($esc)[31mL$($esc)[0m$($esc)[31mi$($esc)[0m$($esc)[31mn$($esc)[0m$($esc)[31me$($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m4$($esc)[0m          "
            )
        }

        It 'Should output to console, but without labels' {
            $expected = @(
                'My String very long string that is longer than actual'
                'Line 2'
                'Line 3'
            )
            $actual = @(
                'My string that is shorter'
                'Line 2'
                'Line 3 is longer than expected'
                'Line 4'
            )

            $result = Out-Difference -Reference $expected -Difference $actual -NoLabels

            $result | Should-BeBlockString @(
                "Bytes                                           Ascii                   Bytes                                           Ascii"
                "-----                                           -----                   -----                                           -----"
                "4D 79 20 $($esc)[31m53$($esc)[0m 74 72 69 6E 67 20 $($esc)[31m76$($esc)[0m $($esc)[31m65$($esc)[0m $($esc)[31m72$($esc)[0m $($esc)[31m79$($esc)[0m 20 $($esc)[31m6C$($esc)[0m My $($esc)[31mS$($esc)[0mtring $($esc)[31mv$($esc)[0m$($esc)[31me$($esc)[0m$($esc)[31mr$($esc)[0m$($esc)[31my$($esc)[0m $($esc)[31ml$($esc)[0m   !=   4D 79 20 $($esc)[31m73$($esc)[0m 74 72 69 6E 67 20 $($esc)[31m74$($esc)[0m $($esc)[31m68$($esc)[0m $($esc)[31m61$($esc)[0m $($esc)[31m74$($esc)[0m 20 $($esc)[31m69$($esc)[0m My $($esc)[31ms$($esc)[0mtring $($esc)[31mt$($esc)[0m$($esc)[31mh$($esc)[0m$($esc)[31ma$($esc)[0m$($esc)[31mt$($esc)[0m $($esc)[31mi$($esc)[0m"
                "$($esc)[31m6F$($esc)[0m $($esc)[31m6E$($esc)[0m $($esc)[31m67$($esc)[0m $($esc)[31m20$($esc)[0m $($esc)[31m73$($esc)[0m $($esc)[31m74$($esc)[0m $($esc)[31m72$($esc)[0m $($esc)[31m69$($esc)[0m $($esc)[31m6E$($esc)[0m $($esc)[31m67$($esc)[0m $($esc)[31m20$($esc)[0m $($esc)[31m74$($esc)[0m $($esc)[31m68$($esc)[0m $($esc)[31m61$($esc)[0m $($esc)[31m74$($esc)[0m $($esc)[31m20$($esc)[0m $($esc)[31mo$($esc)[0m$($esc)[31mn$($esc)[0m$($esc)[31mg$($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31ms$($esc)[0m$($esc)[31mt$($esc)[0m$($esc)[31mr$($esc)[0m$($esc)[31mi$($esc)[0m$($esc)[31mn$($esc)[0m$($esc)[31mg$($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31mt$($esc)[0m$($esc)[31mh$($esc)[0m$($esc)[31ma$($esc)[0m$($esc)[31mt$($esc)[0m$($esc)[31m $($esc)[0m   !=   $($esc)[31m73$($esc)[0m $($esc)[31m20$($esc)[0m $($esc)[31m73$($esc)[0m $($esc)[31m68$($esc)[0m $($esc)[31m6F$($esc)[0m $($esc)[31m72$($esc)[0m $($esc)[31m74$($esc)[0m $($esc)[31m65$($esc)[0m $($esc)[31m72$($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31ms$($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31ms$($esc)[0m$($esc)[31mh$($esc)[0m$($esc)[31mo$($esc)[0m$($esc)[31mr$($esc)[0m$($esc)[31mt$($esc)[0m$($esc)[31me$($esc)[0m$($esc)[31mr$($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m"
                "$($esc)[31m69$($esc)[0m $($esc)[31m73$($esc)[0m $($esc)[31m20$($esc)[0m $($esc)[31m6C$($esc)[0m $($esc)[31m6F$($esc)[0m $($esc)[31m6E$($esc)[0m $($esc)[31m67$($esc)[0m $($esc)[31m65$($esc)[0m $($esc)[31m72$($esc)[0m $($esc)[31m20$($esc)[0m $($esc)[31m74$($esc)[0m $($esc)[31m68$($esc)[0m $($esc)[31m61$($esc)[0m $($esc)[31m6E$($esc)[0m $($esc)[31m20$($esc)[0m $($esc)[31m61$($esc)[0m $($esc)[31mi$($esc)[0m$($esc)[31ms$($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31ml$($esc)[0m$($esc)[31mo$($esc)[0m$($esc)[31mn$($esc)[0m$($esc)[31mg$($esc)[0m$($esc)[31me$($esc)[0m$($esc)[31mr$($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31mt$($esc)[0m$($esc)[31mh$($esc)[0m$($esc)[31ma$($esc)[0m$($esc)[31mn$($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31ma$($esc)[0m   !=   $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m"
                "$($esc)[31m63$($esc)[0m $($esc)[31m74$($esc)[0m $($esc)[31m75$($esc)[0m $($esc)[31m61$($esc)[0m $($esc)[31m6C$($esc)[0m                                  $($esc)[31mc$($esc)[0m$($esc)[31mt$($esc)[0m$($esc)[31mu$($esc)[0m$($esc)[31ma$($esc)[0m$($esc)[31ml$($esc)[0m              !=   $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m                                  $($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m           "
                "Bytes                                           Ascii                   Bytes                                           Ascii"
                "-----                                           -----                   -----                                           -----"
                "4C 69 6E 65 20 32                               Line 2             ==   4C 69 6E 65 20 32                               Line 2          "
                "Bytes                                           Ascii                   Bytes                                           Ascii"
                "-----                                           -----                   -----                                           -----"
                "4C 69 6E 65 20 33 $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m Line 3$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m   !=   4C 69 6E 65 20 33 $($esc)[31m20$($esc)[0m $($esc)[31m69$($esc)[0m $($esc)[31m73$($esc)[0m $($esc)[31m20$($esc)[0m $($esc)[31m6C$($esc)[0m $($esc)[31m6F$($esc)[0m $($esc)[31m6E$($esc)[0m $($esc)[31m67$($esc)[0m $($esc)[31m65$($esc)[0m $($esc)[31m72$($esc)[0m Line 3$($esc)[31m $($esc)[0m$($esc)[31mi$($esc)[0m$($esc)[31ms$($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31ml$($esc)[0m$($esc)[31mo$($esc)[0m$($esc)[31mn$($esc)[0m$($esc)[31mg$($esc)[0m$($esc)[31me$($esc)[0m$($esc)[31mr$($esc)[0m"
                "$($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m       $($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m     !=   $($esc)[31m20$($esc)[0m $($esc)[31m74$($esc)[0m $($esc)[31m68$($esc)[0m $($esc)[31m61$($esc)[0m $($esc)[31m6E$($esc)[0m $($esc)[31m20$($esc)[0m $($esc)[31m65$($esc)[0m $($esc)[31m78$($esc)[0m $($esc)[31m70$($esc)[0m $($esc)[31m65$($esc)[0m $($esc)[31m63$($esc)[0m $($esc)[31m74$($esc)[0m $($esc)[31m65$($esc)[0m $($esc)[31m64$($esc)[0m       $($esc)[31m $($esc)[0m$($esc)[31mt$($esc)[0m$($esc)[31mh$($esc)[0m$($esc)[31ma$($esc)[0m$($esc)[31mn$($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31me$($esc)[0m$($esc)[31mx$($esc)[0m$($esc)[31mp$($esc)[0m$($esc)[31me$($esc)[0m$($esc)[31mc$($esc)[0m$($esc)[31mt$($esc)[0m$($esc)[31me$($esc)[0m$($esc)[31md$($esc)[0m  "
                "Bytes                                           Ascii                   Bytes                                           Ascii"
                "-----                                           -----                   -----                                           -----"
                "$($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m                               $($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m             !=   $($esc)[31m4C$($esc)[0m $($esc)[31m69$($esc)[0m $($esc)[31m6E$($esc)[0m $($esc)[31m65$($esc)[0m $($esc)[31m20$($esc)[0m $($esc)[31m34$($esc)[0m                               $($esc)[31mL$($esc)[0m$($esc)[31mi$($esc)[0m$($esc)[31mn$($esc)[0m$($esc)[31me$($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m4$($esc)[0m          "
            )
        }

        It 'Should output to console, but without column header and labels' {
            $expected = @(
                'My String very long string that is longer than actual'
                'Line 2'
                'Line 3'
            )

            $actual = @(
                'My string that is shorter'
                'Line 2'
                'Line 3 is longer than expected'
                'Line 4'
            )

            $result = Out-Difference -Reference $expected -Difference $actual -NoColumnHeader -NoLabels

            $result | Should-BeBlockString @(
                "4D 79 20 $($esc)[31m53$($esc)[0m 74 72 69 6E 67 20 $($esc)[31m76$($esc)[0m $($esc)[31m65$($esc)[0m $($esc)[31m72$($esc)[0m $($esc)[31m79$($esc)[0m 20 $($esc)[31m6C$($esc)[0m My $($esc)[31mS$($esc)[0mtring $($esc)[31mv$($esc)[0m$($esc)[31me$($esc)[0m$($esc)[31mr$($esc)[0m$($esc)[31my$($esc)[0m $($esc)[31ml$($esc)[0m   !=   4D 79 20 $($esc)[31m73$($esc)[0m 74 72 69 6E 67 20 $($esc)[31m74$($esc)[0m $($esc)[31m68$($esc)[0m $($esc)[31m61$($esc)[0m $($esc)[31m74$($esc)[0m 20 $($esc)[31m69$($esc)[0m My $($esc)[31ms$($esc)[0mtring $($esc)[31mt$($esc)[0m$($esc)[31mh$($esc)[0m$($esc)[31ma$($esc)[0m$($esc)[31mt$($esc)[0m $($esc)[31mi$($esc)[0m"
                "$($esc)[31m6F$($esc)[0m $($esc)[31m6E$($esc)[0m $($esc)[31m67$($esc)[0m $($esc)[31m20$($esc)[0m $($esc)[31m73$($esc)[0m $($esc)[31m74$($esc)[0m $($esc)[31m72$($esc)[0m $($esc)[31m69$($esc)[0m $($esc)[31m6E$($esc)[0m $($esc)[31m67$($esc)[0m $($esc)[31m20$($esc)[0m $($esc)[31m74$($esc)[0m $($esc)[31m68$($esc)[0m $($esc)[31m61$($esc)[0m $($esc)[31m74$($esc)[0m $($esc)[31m20$($esc)[0m $($esc)[31mo$($esc)[0m$($esc)[31mn$($esc)[0m$($esc)[31mg$($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31ms$($esc)[0m$($esc)[31mt$($esc)[0m$($esc)[31mr$($esc)[0m$($esc)[31mi$($esc)[0m$($esc)[31mn$($esc)[0m$($esc)[31mg$($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31mt$($esc)[0m$($esc)[31mh$($esc)[0m$($esc)[31ma$($esc)[0m$($esc)[31mt$($esc)[0m$($esc)[31m $($esc)[0m   !=   $($esc)[31m73$($esc)[0m $($esc)[31m20$($esc)[0m $($esc)[31m73$($esc)[0m $($esc)[31m68$($esc)[0m $($esc)[31m6F$($esc)[0m $($esc)[31m72$($esc)[0m $($esc)[31m74$($esc)[0m $($esc)[31m65$($esc)[0m $($esc)[31m72$($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31ms$($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31ms$($esc)[0m$($esc)[31mh$($esc)[0m$($esc)[31mo$($esc)[0m$($esc)[31mr$($esc)[0m$($esc)[31mt$($esc)[0m$($esc)[31me$($esc)[0m$($esc)[31mr$($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m"
                "$($esc)[31m69$($esc)[0m $($esc)[31m73$($esc)[0m $($esc)[31m20$($esc)[0m $($esc)[31m6C$($esc)[0m $($esc)[31m6F$($esc)[0m $($esc)[31m6E$($esc)[0m $($esc)[31m67$($esc)[0m $($esc)[31m65$($esc)[0m $($esc)[31m72$($esc)[0m $($esc)[31m20$($esc)[0m $($esc)[31m74$($esc)[0m $($esc)[31m68$($esc)[0m $($esc)[31m61$($esc)[0m $($esc)[31m6E$($esc)[0m $($esc)[31m20$($esc)[0m $($esc)[31m61$($esc)[0m $($esc)[31mi$($esc)[0m$($esc)[31ms$($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31ml$($esc)[0m$($esc)[31mo$($esc)[0m$($esc)[31mn$($esc)[0m$($esc)[31mg$($esc)[0m$($esc)[31me$($esc)[0m$($esc)[31mr$($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31mt$($esc)[0m$($esc)[31mh$($esc)[0m$($esc)[31ma$($esc)[0m$($esc)[31mn$($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31ma$($esc)[0m   !=   $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m"
                "$($esc)[31m63$($esc)[0m $($esc)[31m74$($esc)[0m $($esc)[31m75$($esc)[0m $($esc)[31m61$($esc)[0m $($esc)[31m6C$($esc)[0m                                  $($esc)[31mc$($esc)[0m$($esc)[31mt$($esc)[0m$($esc)[31mu$($esc)[0m$($esc)[31ma$($esc)[0m$($esc)[31ml$($esc)[0m              !=   $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m                                  $($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m           "
                "4C 69 6E 65 20 32                               Line 2             ==   4C 69 6E 65 20 32                               Line 2          "
                "4C 69 6E 65 20 33 $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m Line 3$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m   !=   4C 69 6E 65 20 33 $($esc)[31m20$($esc)[0m $($esc)[31m69$($esc)[0m $($esc)[31m73$($esc)[0m $($esc)[31m20$($esc)[0m $($esc)[31m6C$($esc)[0m $($esc)[31m6F$($esc)[0m $($esc)[31m6E$($esc)[0m $($esc)[31m67$($esc)[0m $($esc)[31m65$($esc)[0m $($esc)[31m72$($esc)[0m Line 3$($esc)[31m $($esc)[0m$($esc)[31mi$($esc)[0m$($esc)[31ms$($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31ml$($esc)[0m$($esc)[31mo$($esc)[0m$($esc)[31mn$($esc)[0m$($esc)[31mg$($esc)[0m$($esc)[31me$($esc)[0m$($esc)[31mr$($esc)[0m"
                "$($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m       $($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m     !=   $($esc)[31m20$($esc)[0m $($esc)[31m74$($esc)[0m $($esc)[31m68$($esc)[0m $($esc)[31m61$($esc)[0m $($esc)[31m6E$($esc)[0m $($esc)[31m20$($esc)[0m $($esc)[31m65$($esc)[0m $($esc)[31m78$($esc)[0m $($esc)[31m70$($esc)[0m $($esc)[31m65$($esc)[0m $($esc)[31m63$($esc)[0m $($esc)[31m74$($esc)[0m $($esc)[31m65$($esc)[0m $($esc)[31m64$($esc)[0m       $($esc)[31m $($esc)[0m$($esc)[31mt$($esc)[0m$($esc)[31mh$($esc)[0m$($esc)[31ma$($esc)[0m$($esc)[31mn$($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31me$($esc)[0m$($esc)[31mx$($esc)[0m$($esc)[31mp$($esc)[0m$($esc)[31me$($esc)[0m$($esc)[31mc$($esc)[0m$($esc)[31mt$($esc)[0m$($esc)[31me$($esc)[0m$($esc)[31md$($esc)[0m  "
                "$($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m                               $($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m             !=   $($esc)[31m4C$($esc)[0m $($esc)[31m69$($esc)[0m $($esc)[31m6E$($esc)[0m $($esc)[31m65$($esc)[0m $($esc)[31m20$($esc)[0m $($esc)[31m34$($esc)[0m                               $($esc)[31mL$($esc)[0m$($esc)[31mi$($esc)[0m$($esc)[31mn$($esc)[0m$($esc)[31me$($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m4$($esc)[0m          "
            )
        }
    }

    Context 'When actual value is an empty value' {
        It 'Should output to console' {
            $expected = @(
                'My String very long string that is longer than actual'
                'Line 2'
                'Line 3'
            )
            $actual = ''

            $result = Out-Difference -Reference $expected -Difference $actual

            $result | Should-BeBlockString @(
                "Expected:$($esc)[0m                                                               But was:$($esc)[0m"
                "----------------------------------------------------------------        ----------------------------------------------------------------"
                "Bytes                                           Ascii                   Bytes                                           Ascii"
                "-----                                           -----                   -----                                           -----"
                "$($esc)[31m4D$($esc)[0m $($esc)[31m79$($esc)[0m $($esc)[31m20$($esc)[0m $($esc)[31m53$($esc)[0m $($esc)[31m74$($esc)[0m $($esc)[31m72$($esc)[0m $($esc)[31m69$($esc)[0m $($esc)[31m6E$($esc)[0m $($esc)[31m67$($esc)[0m $($esc)[31m20$($esc)[0m $($esc)[31m76$($esc)[0m $($esc)[31m65$($esc)[0m $($esc)[31m72$($esc)[0m $($esc)[31m79$($esc)[0m $($esc)[31m20$($esc)[0m $($esc)[31m6C$($esc)[0m $($esc)[31mM$($esc)[0m$($esc)[31my$($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31mS$($esc)[0m$($esc)[31mt$($esc)[0m$($esc)[31mr$($esc)[0m$($esc)[31mi$($esc)[0m$($esc)[31mn$($esc)[0m$($esc)[31mg$($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31mv$($esc)[0m$($esc)[31me$($esc)[0m$($esc)[31mr$($esc)[0m$($esc)[31my$($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31ml$($esc)[0m   !=   $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m"
                "$($esc)[31m6F$($esc)[0m $($esc)[31m6E$($esc)[0m $($esc)[31m67$($esc)[0m $($esc)[31m20$($esc)[0m $($esc)[31m73$($esc)[0m $($esc)[31m74$($esc)[0m $($esc)[31m72$($esc)[0m $($esc)[31m69$($esc)[0m $($esc)[31m6E$($esc)[0m $($esc)[31m67$($esc)[0m $($esc)[31m20$($esc)[0m $($esc)[31m74$($esc)[0m $($esc)[31m68$($esc)[0m $($esc)[31m61$($esc)[0m $($esc)[31m74$($esc)[0m $($esc)[31m20$($esc)[0m $($esc)[31mo$($esc)[0m$($esc)[31mn$($esc)[0m$($esc)[31mg$($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31ms$($esc)[0m$($esc)[31mt$($esc)[0m$($esc)[31mr$($esc)[0m$($esc)[31mi$($esc)[0m$($esc)[31mn$($esc)[0m$($esc)[31mg$($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31mt$($esc)[0m$($esc)[31mh$($esc)[0m$($esc)[31ma$($esc)[0m$($esc)[31mt$($esc)[0m$($esc)[31m $($esc)[0m   !=   $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m"
                "$($esc)[31m69$($esc)[0m $($esc)[31m73$($esc)[0m $($esc)[31m20$($esc)[0m $($esc)[31m6C$($esc)[0m $($esc)[31m6F$($esc)[0m $($esc)[31m6E$($esc)[0m $($esc)[31m67$($esc)[0m $($esc)[31m65$($esc)[0m $($esc)[31m72$($esc)[0m $($esc)[31m20$($esc)[0m $($esc)[31m74$($esc)[0m $($esc)[31m68$($esc)[0m $($esc)[31m61$($esc)[0m $($esc)[31m6E$($esc)[0m $($esc)[31m20$($esc)[0m $($esc)[31m61$($esc)[0m $($esc)[31mi$($esc)[0m$($esc)[31ms$($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31ml$($esc)[0m$($esc)[31mo$($esc)[0m$($esc)[31mn$($esc)[0m$($esc)[31mg$($esc)[0m$($esc)[31me$($esc)[0m$($esc)[31mr$($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31mt$($esc)[0m$($esc)[31mh$($esc)[0m$($esc)[31ma$($esc)[0m$($esc)[31mn$($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31ma$($esc)[0m   !=   $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m"
                "$($esc)[31m63$($esc)[0m $($esc)[31m74$($esc)[0m $($esc)[31m75$($esc)[0m $($esc)[31m61$($esc)[0m $($esc)[31m6C$($esc)[0m                                  $($esc)[31mc$($esc)[0m$($esc)[31mt$($esc)[0m$($esc)[31mu$($esc)[0m$($esc)[31ma$($esc)[0m$($esc)[31ml$($esc)[0m              !=   $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m                                  $($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m           "
                "Expected:$($esc)[0m                                                               But was:$($esc)[0m"
                "----------------------------------------------------------------        ----------------------------------------------------------------"
                "Bytes                                           Ascii                   Bytes                                           Ascii"
                "-----                                           -----                   -----                                           -----"
                "$($esc)[31m4C$($esc)[0m $($esc)[31m69$($esc)[0m $($esc)[31m6E$($esc)[0m $($esc)[31m65$($esc)[0m $($esc)[31m20$($esc)[0m $($esc)[31m32$($esc)[0m                               $($esc)[31mL$($esc)[0m$($esc)[31mi$($esc)[0m$($esc)[31mn$($esc)[0m$($esc)[31me$($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m2$($esc)[0m             !=   $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m                               $($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m          "
                "Expected:$($esc)[0m                                                               But was:$($esc)[0m"
                "----------------------------------------------------------------        ----------------------------------------------------------------"
                "Bytes                                           Ascii                   Bytes                                           Ascii"
                "-----                                           -----                   -----                                           -----"
                "$($esc)[31m4C$($esc)[0m $($esc)[31m69$($esc)[0m $($esc)[31m6E$($esc)[0m $($esc)[31m65$($esc)[0m $($esc)[31m20$($esc)[0m $($esc)[31m33$($esc)[0m                               $($esc)[31mL$($esc)[0m$($esc)[31mi$($esc)[0m$($esc)[31mn$($esc)[0m$($esc)[31me$($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m3$($esc)[0m             !=   $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m                               $($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m          "
            )
        }
    }

    Context 'When actual value is null' {
        It 'Should output to console' {
            $expected = @(
                'My String very long string that is longer than actual'
                'Line 2'
                'Line 3'
            )
            $actual = $null

            $result = Out-Difference -Reference $expected -Difference $actual

            $result | Should-BeBlockString @(
                "Expected:$($esc)[0m                                                               But was:$($esc)[0m"
                "----------------------------------------------------------------        ----------------------------------------------------------------"
                "Bytes                                           Ascii                   Bytes                                           Ascii"
                "-----                                           -----                   -----                                           -----"
                "$($esc)[31m4D$($esc)[0m $($esc)[31m79$($esc)[0m $($esc)[31m20$($esc)[0m $($esc)[31m53$($esc)[0m $($esc)[31m74$($esc)[0m $($esc)[31m72$($esc)[0m $($esc)[31m69$($esc)[0m $($esc)[31m6E$($esc)[0m $($esc)[31m67$($esc)[0m $($esc)[31m20$($esc)[0m $($esc)[31m76$($esc)[0m $($esc)[31m65$($esc)[0m $($esc)[31m72$($esc)[0m $($esc)[31m79$($esc)[0m $($esc)[31m20$($esc)[0m $($esc)[31m6C$($esc)[0m $($esc)[31mM$($esc)[0m$($esc)[31my$($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31mS$($esc)[0m$($esc)[31mt$($esc)[0m$($esc)[31mr$($esc)[0m$($esc)[31mi$($esc)[0m$($esc)[31mn$($esc)[0m$($esc)[31mg$($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31mv$($esc)[0m$($esc)[31me$($esc)[0m$($esc)[31mr$($esc)[0m$($esc)[31my$($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31ml$($esc)[0m   !=   $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m"
                "$($esc)[31m6F$($esc)[0m $($esc)[31m6E$($esc)[0m $($esc)[31m67$($esc)[0m $($esc)[31m20$($esc)[0m $($esc)[31m73$($esc)[0m $($esc)[31m74$($esc)[0m $($esc)[31m72$($esc)[0m $($esc)[31m69$($esc)[0m $($esc)[31m6E$($esc)[0m $($esc)[31m67$($esc)[0m $($esc)[31m20$($esc)[0m $($esc)[31m74$($esc)[0m $($esc)[31m68$($esc)[0m $($esc)[31m61$($esc)[0m $($esc)[31m74$($esc)[0m $($esc)[31m20$($esc)[0m $($esc)[31mo$($esc)[0m$($esc)[31mn$($esc)[0m$($esc)[31mg$($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31ms$($esc)[0m$($esc)[31mt$($esc)[0m$($esc)[31mr$($esc)[0m$($esc)[31mi$($esc)[0m$($esc)[31mn$($esc)[0m$($esc)[31mg$($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31mt$($esc)[0m$($esc)[31mh$($esc)[0m$($esc)[31ma$($esc)[0m$($esc)[31mt$($esc)[0m$($esc)[31m $($esc)[0m   !=   $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m"
                "$($esc)[31m69$($esc)[0m $($esc)[31m73$($esc)[0m $($esc)[31m20$($esc)[0m $($esc)[31m6C$($esc)[0m $($esc)[31m6F$($esc)[0m $($esc)[31m6E$($esc)[0m $($esc)[31m67$($esc)[0m $($esc)[31m65$($esc)[0m $($esc)[31m72$($esc)[0m $($esc)[31m20$($esc)[0m $($esc)[31m74$($esc)[0m $($esc)[31m68$($esc)[0m $($esc)[31m61$($esc)[0m $($esc)[31m6E$($esc)[0m $($esc)[31m20$($esc)[0m $($esc)[31m61$($esc)[0m $($esc)[31mi$($esc)[0m$($esc)[31ms$($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31ml$($esc)[0m$($esc)[31mo$($esc)[0m$($esc)[31mn$($esc)[0m$($esc)[31mg$($esc)[0m$($esc)[31me$($esc)[0m$($esc)[31mr$($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31mt$($esc)[0m$($esc)[31mh$($esc)[0m$($esc)[31ma$($esc)[0m$($esc)[31mn$($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31ma$($esc)[0m   !=   $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m"
                "$($esc)[31m63$($esc)[0m $($esc)[31m74$($esc)[0m $($esc)[31m75$($esc)[0m $($esc)[31m61$($esc)[0m $($esc)[31m6C$($esc)[0m                                  $($esc)[31mc$($esc)[0m$($esc)[31mt$($esc)[0m$($esc)[31mu$($esc)[0m$($esc)[31ma$($esc)[0m$($esc)[31ml$($esc)[0m              !=   $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m                                  $($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m           "
                "Expected:$($esc)[0m                                                               But was:$($esc)[0m"
                "----------------------------------------------------------------        ----------------------------------------------------------------"
                "Bytes                                           Ascii                   Bytes                                           Ascii"
                "-----                                           -----                   -----                                           -----"
                "$($esc)[31m4C$($esc)[0m $($esc)[31m69$($esc)[0m $($esc)[31m6E$($esc)[0m $($esc)[31m65$($esc)[0m $($esc)[31m20$($esc)[0m $($esc)[31m32$($esc)[0m                               $($esc)[31mL$($esc)[0m$($esc)[31mi$($esc)[0m$($esc)[31mn$($esc)[0m$($esc)[31me$($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m2$($esc)[0m             !=   $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m                               $($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m          "
                "Expected:$($esc)[0m                                                               But was:$($esc)[0m"
                "----------------------------------------------------------------        ----------------------------------------------------------------"
                "Bytes                                           Ascii                   Bytes                                           Ascii"
                "-----                                           -----                   -----                                           -----"
                "$($esc)[31m4C$($esc)[0m $($esc)[31m69$($esc)[0m $($esc)[31m6E$($esc)[0m $($esc)[31m65$($esc)[0m $($esc)[31m20$($esc)[0m $($esc)[31m33$($esc)[0m                               $($esc)[31mL$($esc)[0m$($esc)[31mi$($esc)[0m$($esc)[31mn$($esc)[0m$($esc)[31me$($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m3$($esc)[0m             !=   $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m                               $($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m          "
            )
        }
    }

    Context 'When expected value is an empty value' {
        It 'Should output to console' {
            $expected = ''
            $actual = @(
                'My String very long string that is longer than actual'
                'Line 2'
                'Line 3'
            )

            $result = Out-Difference -Reference $expected -Difference $actual

            $result | Should-BeBlockString @(
                "Expected:$($esc)[0m                                                               But was:$($esc)[0m"
                "----------------------------------------------------------------        ----------------------------------------------------------------"
                "Bytes                                           Ascii                   Bytes                                           Ascii"
                "-----                                           -----                   -----                                           -----"
                "$($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m   !=   $($esc)[31m4D$($esc)[0m $($esc)[31m79$($esc)[0m $($esc)[31m20$($esc)[0m $($esc)[31m53$($esc)[0m $($esc)[31m74$($esc)[0m $($esc)[31m72$($esc)[0m $($esc)[31m69$($esc)[0m $($esc)[31m6E$($esc)[0m $($esc)[31m67$($esc)[0m $($esc)[31m20$($esc)[0m $($esc)[31m76$($esc)[0m $($esc)[31m65$($esc)[0m $($esc)[31m72$($esc)[0m $($esc)[31m79$($esc)[0m $($esc)[31m20$($esc)[0m $($esc)[31m6C$($esc)[0m $($esc)[31mM$($esc)[0m$($esc)[31my$($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31mS$($esc)[0m$($esc)[31mt$($esc)[0m$($esc)[31mr$($esc)[0m$($esc)[31mi$($esc)[0m$($esc)[31mn$($esc)[0m$($esc)[31mg$($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31mv$($esc)[0m$($esc)[31me$($esc)[0m$($esc)[31mr$($esc)[0m$($esc)[31my$($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31ml$($esc)[0m"
                "$($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m   !=   $($esc)[31m6F$($esc)[0m $($esc)[31m6E$($esc)[0m $($esc)[31m67$($esc)[0m $($esc)[31m20$($esc)[0m $($esc)[31m73$($esc)[0m $($esc)[31m74$($esc)[0m $($esc)[31m72$($esc)[0m $($esc)[31m69$($esc)[0m $($esc)[31m6E$($esc)[0m $($esc)[31m67$($esc)[0m $($esc)[31m20$($esc)[0m $($esc)[31m74$($esc)[0m $($esc)[31m68$($esc)[0m $($esc)[31m61$($esc)[0m $($esc)[31m74$($esc)[0m $($esc)[31m20$($esc)[0m $($esc)[31mo$($esc)[0m$($esc)[31mn$($esc)[0m$($esc)[31mg$($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31ms$($esc)[0m$($esc)[31mt$($esc)[0m$($esc)[31mr$($esc)[0m$($esc)[31mi$($esc)[0m$($esc)[31mn$($esc)[0m$($esc)[31mg$($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31mt$($esc)[0m$($esc)[31mh$($esc)[0m$($esc)[31ma$($esc)[0m$($esc)[31mt$($esc)[0m$($esc)[31m $($esc)[0m"
                "$($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m   !=   $($esc)[31m69$($esc)[0m $($esc)[31m73$($esc)[0m $($esc)[31m20$($esc)[0m $($esc)[31m6C$($esc)[0m $($esc)[31m6F$($esc)[0m $($esc)[31m6E$($esc)[0m $($esc)[31m67$($esc)[0m $($esc)[31m65$($esc)[0m $($esc)[31m72$($esc)[0m $($esc)[31m20$($esc)[0m $($esc)[31m74$($esc)[0m $($esc)[31m68$($esc)[0m $($esc)[31m61$($esc)[0m $($esc)[31m6E$($esc)[0m $($esc)[31m20$($esc)[0m $($esc)[31m61$($esc)[0m $($esc)[31mi$($esc)[0m$($esc)[31ms$($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31ml$($esc)[0m$($esc)[31mo$($esc)[0m$($esc)[31mn$($esc)[0m$($esc)[31mg$($esc)[0m$($esc)[31me$($esc)[0m$($esc)[31mr$($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31mt$($esc)[0m$($esc)[31mh$($esc)[0m$($esc)[31ma$($esc)[0m$($esc)[31mn$($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31ma$($esc)[0m"
                "$($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m                                  $($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m              !=   $($esc)[31m63$($esc)[0m $($esc)[31m74$($esc)[0m $($esc)[31m75$($esc)[0m $($esc)[31m61$($esc)[0m $($esc)[31m6C$($esc)[0m                                  $($esc)[31mc$($esc)[0m$($esc)[31mt$($esc)[0m$($esc)[31mu$($esc)[0m$($esc)[31ma$($esc)[0m$($esc)[31ml$($esc)[0m           "
                "Expected:$($esc)[0m                                                               But was:$($esc)[0m"
                "----------------------------------------------------------------        ----------------------------------------------------------------"
                "Bytes                                           Ascii                   Bytes                                           Ascii"
                "-----                                           -----                   -----                                           -----"
                "$($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m                               $($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m             !=   $($esc)[31m4C$($esc)[0m $($esc)[31m69$($esc)[0m $($esc)[31m6E$($esc)[0m $($esc)[31m65$($esc)[0m $($esc)[31m20$($esc)[0m $($esc)[31m32$($esc)[0m                               $($esc)[31mL$($esc)[0m$($esc)[31mi$($esc)[0m$($esc)[31mn$($esc)[0m$($esc)[31me$($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m2$($esc)[0m          "
                "Expected:$($esc)[0m                                                               But was:$($esc)[0m"
                "----------------------------------------------------------------        ----------------------------------------------------------------"
                "Bytes                                           Ascii                   Bytes                                           Ascii"
                "-----                                           -----                   -----                                           -----"
                "$($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m                               $($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m             !=   $($esc)[31m4C$($esc)[0m $($esc)[31m69$($esc)[0m $($esc)[31m6E$($esc)[0m $($esc)[31m65$($esc)[0m $($esc)[31m20$($esc)[0m $($esc)[31m33$($esc)[0m                               $($esc)[31mL$($esc)[0m$($esc)[31mi$($esc)[0m$($esc)[31mn$($esc)[0m$($esc)[31me$($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m3$($esc)[0m          "
            )
        }
    }

    Context 'When expected value is null' {
        It 'Should output to console' {
            $expected = $null
            $actual = @(
                'My String very long string that is longer than actual'
                'Line 2'
                'Line 3'
            )

            $result = Out-Difference -Reference $expected -Difference $actual

            $result | Should-BeBlockString @(
                "Expected:$($esc)[0m                                                               But was:$($esc)[0m"
                "----------------------------------------------------------------        ----------------------------------------------------------------"
                "Bytes                                           Ascii                   Bytes                                           Ascii"
                "-----                                           -----                   -----                                           -----"
                "$($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m   !=   $($esc)[31m4D$($esc)[0m $($esc)[31m79$($esc)[0m $($esc)[31m20$($esc)[0m $($esc)[31m53$($esc)[0m $($esc)[31m74$($esc)[0m $($esc)[31m72$($esc)[0m $($esc)[31m69$($esc)[0m $($esc)[31m6E$($esc)[0m $($esc)[31m67$($esc)[0m $($esc)[31m20$($esc)[0m $($esc)[31m76$($esc)[0m $($esc)[31m65$($esc)[0m $($esc)[31m72$($esc)[0m $($esc)[31m79$($esc)[0m $($esc)[31m20$($esc)[0m $($esc)[31m6C$($esc)[0m $($esc)[31mM$($esc)[0m$($esc)[31my$($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31mS$($esc)[0m$($esc)[31mt$($esc)[0m$($esc)[31mr$($esc)[0m$($esc)[31mi$($esc)[0m$($esc)[31mn$($esc)[0m$($esc)[31mg$($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31mv$($esc)[0m$($esc)[31me$($esc)[0m$($esc)[31mr$($esc)[0m$($esc)[31my$($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31ml$($esc)[0m"
                "$($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m   !=   $($esc)[31m6F$($esc)[0m $($esc)[31m6E$($esc)[0m $($esc)[31m67$($esc)[0m $($esc)[31m20$($esc)[0m $($esc)[31m73$($esc)[0m $($esc)[31m74$($esc)[0m $($esc)[31m72$($esc)[0m $($esc)[31m69$($esc)[0m $($esc)[31m6E$($esc)[0m $($esc)[31m67$($esc)[0m $($esc)[31m20$($esc)[0m $($esc)[31m74$($esc)[0m $($esc)[31m68$($esc)[0m $($esc)[31m61$($esc)[0m $($esc)[31m74$($esc)[0m $($esc)[31m20$($esc)[0m $($esc)[31mo$($esc)[0m$($esc)[31mn$($esc)[0m$($esc)[31mg$($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31ms$($esc)[0m$($esc)[31mt$($esc)[0m$($esc)[31mr$($esc)[0m$($esc)[31mi$($esc)[0m$($esc)[31mn$($esc)[0m$($esc)[31mg$($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31mt$($esc)[0m$($esc)[31mh$($esc)[0m$($esc)[31ma$($esc)[0m$($esc)[31mt$($esc)[0m$($esc)[31m $($esc)[0m"
                "$($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m   !=   $($esc)[31m69$($esc)[0m $($esc)[31m73$($esc)[0m $($esc)[31m20$($esc)[0m $($esc)[31m6C$($esc)[0m $($esc)[31m6F$($esc)[0m $($esc)[31m6E$($esc)[0m $($esc)[31m67$($esc)[0m $($esc)[31m65$($esc)[0m $($esc)[31m72$($esc)[0m $($esc)[31m20$($esc)[0m $($esc)[31m74$($esc)[0m $($esc)[31m68$($esc)[0m $($esc)[31m61$($esc)[0m $($esc)[31m6E$($esc)[0m $($esc)[31m20$($esc)[0m $($esc)[31m61$($esc)[0m $($esc)[31mi$($esc)[0m$($esc)[31ms$($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31ml$($esc)[0m$($esc)[31mo$($esc)[0m$($esc)[31mn$($esc)[0m$($esc)[31mg$($esc)[0m$($esc)[31me$($esc)[0m$($esc)[31mr$($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31mt$($esc)[0m$($esc)[31mh$($esc)[0m$($esc)[31ma$($esc)[0m$($esc)[31mn$($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31ma$($esc)[0m"
                "$($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m                                  $($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m              !=   $($esc)[31m63$($esc)[0m $($esc)[31m74$($esc)[0m $($esc)[31m75$($esc)[0m $($esc)[31m61$($esc)[0m $($esc)[31m6C$($esc)[0m                                  $($esc)[31mc$($esc)[0m$($esc)[31mt$($esc)[0m$($esc)[31mu$($esc)[0m$($esc)[31ma$($esc)[0m$($esc)[31ml$($esc)[0m           "
                "Expected:$($esc)[0m                                                               But was:$($esc)[0m"
                "----------------------------------------------------------------        ----------------------------------------------------------------"
                "Bytes                                           Ascii                   Bytes                                           Ascii"
                "-----                                           -----                   -----                                           -----"
                "$($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m                               $($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m             !=   $($esc)[31m4C$($esc)[0m $($esc)[31m69$($esc)[0m $($esc)[31m6E$($esc)[0m $($esc)[31m65$($esc)[0m $($esc)[31m20$($esc)[0m $($esc)[31m32$($esc)[0m                               $($esc)[31mL$($esc)[0m$($esc)[31mi$($esc)[0m$($esc)[31mn$($esc)[0m$($esc)[31me$($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m2$($esc)[0m          "
                "Expected:$($esc)[0m                                                               But was:$($esc)[0m"
                "----------------------------------------------------------------        ----------------------------------------------------------------"
                "Bytes                                           Ascii                   Bytes                                           Ascii"
                "-----                                           -----                   -----                                           -----"
                "$($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m                               $($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m             !=   $($esc)[31m4C$($esc)[0m $($esc)[31m69$($esc)[0m $($esc)[31m6E$($esc)[0m $($esc)[31m65$($esc)[0m $($esc)[31m20$($esc)[0m $($esc)[31m33$($esc)[0m                               $($esc)[31mL$($esc)[0m$($esc)[31mi$($esc)[0m$($esc)[31mn$($esc)[0m$($esc)[31me$($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m3$($esc)[0m          "
            )
        }
    }

    Context 'When expected and actual value is null' {
        It 'Should output to console' {
            $expected = $null
            $actual = $null

            $result = Out-Difference -Reference $expected -Difference $actual

            $result | Should-BeEquivalent @()
        }
    }

    Context 'When expected and actual value is both an empty string' {
        It 'Should output to console' {
            $expected = ''
            $actual = ''

            $result = Out-Difference -Reference $expected -Difference $actual

            $result | Should-BeBlockString @(
                "Expected:$($esc)[0m                                                               But was:$($esc)[0m"
                "----------------------------------------------------------------        ----------------------------------------------------------------"
                "Bytes                                           Ascii                   Bytes                                           Ascii"
                "-----                                           -----                   -----                                           -----"
            )
        }
    }

    Context 'When expected and actual value is a single string' {
        Context 'When expected and actual value is the same' {
            It 'Should output to console' {
                $expected = 'This is a test'
                $actual = 'This is a test'

                $result = Out-Difference -Reference $expected -Difference $actual -EqualIndicator '='

                $result | Should-BeBlockString @(
                    "Expected:$($esc)[0m                                                               But was:$($esc)[0m"
                    "----------------------------------------------------------------        ----------------------------------------------------------------"
                    "Bytes                                           Ascii                   Bytes                                           Ascii"
                    "-----                                           -----                   -----                                           -----"
                    "54 68 69 73 20 69 73 20 61 20 74 65 73 74       This is a test     =    54 68 69 73 20 69 73 20 61 20 74 65 73 74       This is a test  "
                )
            }
        }

        Context 'When expected and actual value is different' {
            It 'Should output to console' {
                $expected = 'This is a test'
                $actual = 'This is another test'

                $result = Out-Difference -Reference $expected -Difference $actual -NotEqualIndicator '!'

                $result | Should-BeBlockString @(
                    "Expected:$($esc)[0m                                                               But was:$($esc)[0m"
                    "----------------------------------------------------------------        ----------------------------------------------------------------"
                    "Bytes                                           Ascii                   Bytes                                           Ascii"
                    "-----                                           -----                   -----                                           -----"
                    "54 68 69 73 20 69 73 20 61 $($esc)[31m20$($esc)[0m $($esc)[31m74$($esc)[0m $($esc)[31m65$($esc)[0m $($esc)[31m73$($esc)[0m $($esc)[31m74$($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m This is a$($esc)[31m $($esc)[0m$($esc)[31mt$($esc)[0m$($esc)[31me$($esc)[0m$($esc)[31ms$($esc)[0m$($esc)[31mt$($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m   !    54 68 69 73 20 69 73 20 61 $($esc)[31m6E$($esc)[0m $($esc)[31m6F$($esc)[0m $($esc)[31m74$($esc)[0m $($esc)[31m68$($esc)[0m $($esc)[31m65$($esc)[0m $($esc)[31m72$($esc)[0m $($esc)[31m20$($esc)[0m This is a$($esc)[31mn$($esc)[0m$($esc)[31mo$($esc)[0m$($esc)[31mt$($esc)[0m$($esc)[31mh$($esc)[0m$($esc)[31me$($esc)[0m$($esc)[31mr$($esc)[0m$($esc)[31m $($esc)[0m"
                    "$($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m                                     $($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m               !    $($esc)[31m74$($esc)[0m $($esc)[31m65$($esc)[0m $($esc)[31m73$($esc)[0m $($esc)[31m74$($esc)[0m                                     $($esc)[31mt$($esc)[0m$($esc)[31me$($esc)[0m$($esc)[31ms$($esc)[0m$($esc)[31mt$($esc)[0m            "
                )
            }
        }

        Context 'When expected and actual value contain line breaks and new line' {
            It 'Should output to console' {
                $expected = "This is`r`na test"
                $actual = "This Is`r`nAnother`r`nTest"

                $result = Out-Difference -Reference $expected -Difference $actual

                $result | Should-BeBlockString @(
                    "Expected:$($esc)[0m                                                               But was:$($esc)[0m"
                    "----------------------------------------------------------------        ----------------------------------------------------------------"
                    "Bytes                                           Ascii                   Bytes                                           Ascii"
                    "-----                                           -----                   -----                                           -----"
                    "54 68 69 73 20 $($esc)[31m69$($esc)[0m 73 0D 0A $($esc)[31m61$($esc)[0m $($esc)[31m20$($esc)[0m $($esc)[31m74$($esc)[0m $($esc)[31m65$($esc)[0m $($esc)[31m73$($esc)[0m $($esc)[31m74$($esc)[0m $($esc)[31m  $($esc)[0m This $($esc)[31mi$($esc)[0ms␍␊$($esc)[31ma$($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31mt$($esc)[0m$($esc)[31me$($esc)[0m$($esc)[31ms$($esc)[0m$($esc)[31mt$($esc)[0m$($esc)[31m $($esc)[0m   !=   54 68 69 73 20 $($esc)[31m49$($esc)[0m 73 0D 0A $($esc)[31m41$($esc)[0m $($esc)[31m6E$($esc)[0m $($esc)[31m6F$($esc)[0m $($esc)[31m74$($esc)[0m $($esc)[31m68$($esc)[0m $($esc)[31m65$($esc)[0m $($esc)[31m72$($esc)[0m This $($esc)[31mI$($esc)[0ms␍␊$($esc)[31mA$($esc)[0m$($esc)[31mn$($esc)[0m$($esc)[31mo$($esc)[0m$($esc)[31mt$($esc)[0m$($esc)[31mh$($esc)[0m$($esc)[31me$($esc)[0m$($esc)[31mr$($esc)[0m"
                    "$($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m                               $($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m             !=   $($esc)[31m0D$($esc)[0m $($esc)[31m0A$($esc)[0m $($esc)[31m54$($esc)[0m $($esc)[31m65$($esc)[0m $($esc)[31m73$($esc)[0m $($esc)[31m74$($esc)[0m                               $($esc)[31m␍$($esc)[0m$($esc)[31m␊$($esc)[0m$($esc)[31mT$($esc)[0m$($esc)[31me$($esc)[0m$($esc)[31ms$($esc)[0m$($esc)[31mt$($esc)[0m          "
                )
            }
        }

        Context 'When expected and actual value just different in case sensitivity' {
            It 'Should output to console' {
                $expected = @('Test','a','b')
                $actual = @('test','a','b')

                $result = Out-Difference -Reference $expected -Difference $actual

                $result | Should-BeBlockString @(
                    "Expected:$($esc)[0m                                                               But was:$($esc)[0m"
                    "----------------------------------------------------------------        ----------------------------------------------------------------"
                    "Bytes                                           Ascii                   Bytes                                           Ascii"
                    "-----                                           -----                   -----                                           -----"
                    "$($esc)[31m54$($esc)[0m 65 73 74                                     $($esc)[31mT$($esc)[0mest               !=   $($esc)[31m74$($esc)[0m 65 73 74                                     $($esc)[31mt$($esc)[0mest            "
                    "Expected:$($esc)[0m                                                               But was:$($esc)[0m"
                    "----------------------------------------------------------------        ----------------------------------------------------------------"
                    "Bytes                                           Ascii                   Bytes                                           Ascii"
                    "-----                                           -----                   -----                                           -----"
                    "61                                              a                  ==   61                                              a               "
                    "Expected:$($esc)[0m                                                               But was:$($esc)[0m"
                    "----------------------------------------------------------------        ----------------------------------------------------------------"
                    "Bytes                                           Ascii                   Bytes                                           Ascii"
                    "-----                                           -----                   -----                                           -----"
                    "62                                              b                  ==   62                                              b               "
                )
            }
        }

        Context 'When concatenating string array' {
            It 'Should output to console' {
                $expected = @('Test','a','b')
                $actual = @('test','a','b')

                $result = Out-Difference -Reference $expected -Difference $actual -ConcatenateArray -ConcatenateChar ''

                $result | Should-BeBlockString @(
                    "Expected:$($esc)[0m                                                               But was:$($esc)[0m"
                    "----------------------------------------------------------------        ----------------------------------------------------------------"
                    "Bytes                                           Ascii                   Bytes                                           Ascii"
                    "-----                                           -----                   -----                                           -----"
                    "$($esc)[31m54$($esc)[0m 65 73 74 61 62                               $($esc)[31mT$($esc)[0mestab             !=   $($esc)[31m74$($esc)[0m 65 73 74 61 62                               $($esc)[31mt$($esc)[0mestab          "
                )
            }
        }
    }

    Context 'When expected and actual value have different lengths but similar content' {
        It 'Should output to console' {
            $expected = 'This is a test string that is quite long'
            $actual = 'This is a test string'

            $result = Out-Difference -Reference $expected -Difference $actual

            $result | Should-BeBlockString @(
                "Expected:$($esc)[0m                                                               But was:$($esc)[0m"
                "----------------------------------------------------------------        ----------------------------------------------------------------"
                "Bytes                                           Ascii                   Bytes                                           Ascii"
                "-----                                           -----                   -----                                           -----"
                "54 68 69 73 20 69 73 20 61 20 74 65 73 74 20 73 This is a test s   ==   54 68 69 73 20 69 73 20 61 20 74 65 73 74 20 73 This is a test s"
                "74 72 69 6E 67 $($esc)[31m20$($esc)[0m $($esc)[31m74$($esc)[0m $($esc)[31m68$($esc)[0m $($esc)[31m61$($esc)[0m $($esc)[31m74$($esc)[0m $($esc)[31m20$($esc)[0m $($esc)[31m69$($esc)[0m $($esc)[31m73$($esc)[0m $($esc)[31m20$($esc)[0m $($esc)[31m71$($esc)[0m $($esc)[31m75$($esc)[0m tring$($esc)[31m $($esc)[0m$($esc)[31mt$($esc)[0m$($esc)[31mh$($esc)[0m$($esc)[31ma$($esc)[0m$($esc)[31mt$($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31mi$($esc)[0m$($esc)[31ms$($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31mq$($esc)[0m$($esc)[31mu$($esc)[0m   !=   74 72 69 6E 67 $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m tring$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m"
                "$($esc)[31m69$($esc)[0m $($esc)[31m74$($esc)[0m $($esc)[31m65$($esc)[0m $($esc)[31m20$($esc)[0m $($esc)[31m6C$($esc)[0m $($esc)[31m6F$($esc)[0m $($esc)[31m6E$($esc)[0m $($esc)[31m67$($esc)[0m                         $($esc)[31mi$($esc)[0m$($esc)[31mt$($esc)[0m$($esc)[31me$($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31ml$($esc)[0m$($esc)[31mo$($esc)[0m$($esc)[31mn$($esc)[0m$($esc)[31mg$($esc)[0m           !=   $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m $($esc)[31m  $($esc)[0m                         $($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m$($esc)[31m $($esc)[0m        "
            )
        }
    }

    Context 'When expected and actual value contain special characters' {
        It 'Should output to console' {
            $expected = 'This is a test string with special characters: !@#$%^&*()'
            $actual = 'This is a test string with special characters: !@#$%^&*()'

            $result = Out-Difference -Reference $expected -Difference $actual

            $result | Should-BeBlockString @(
                "Expected:$($esc)[0m                                                               But was:$($esc)[0m"
                "----------------------------------------------------------------        ----------------------------------------------------------------"
                "Bytes                                           Ascii                   Bytes                                           Ascii"
                "-----                                           -----                   -----                                           -----"
                "54 68 69 73 20 69 73 20 61 20 74 65 73 74 20 73 This is a test s   ==   54 68 69 73 20 69 73 20 61 20 74 65 73 74 20 73 This is a test s"
                "74 72 69 6E 67 20 77 69 74 68 20 73 70 65 63 69 tring with speci   ==   74 72 69 6E 67 20 77 69 74 68 20 73 70 65 63 69 tring with speci"
                "61 6C 20 63 68 61 72 61 63 74 65 72 73 3A 20 21 al characters: !   ==   61 6C 20 63 68 61 72 61 63 74 65 72 73 3A 20 21 al characters: !"
                "40 23 24 25 5E 26 2A 28 29                      @#$%^&*()          ==   40 23 24 25 5E 26 2A 28 29                      @#$%^&*()       "
            )
        }
    }

    Context 'When expected and actual value are empty arrays' {
        It 'Should output to console' {
            $expected = @()
            $actual = @()

            $result = Out-Difference -Reference $expected -Difference $actual

            $result | Should-BeEquivalent @()
        }
    }

    Context 'When expected and actual value contain mixed content' {
        It 'Should output to console' {
            $expected = @('String', 123, 'Another String')
            $actual = @('String', 456, 'Another String')

            $result = Out-Difference -Reference $expected -Difference $actual

            $result | Should-BeBlockString @(
                "Expected:$($esc)[0m                                                               But was:$($esc)[0m"
                "----------------------------------------------------------------        ----------------------------------------------------------------"
                "Bytes                                           Ascii                   Bytes                                           Ascii"
                "-----                                           -----                   -----                                           -----"
                "53 74 72 69 6E 67                               String             ==   53 74 72 69 6E 67                               String          "
                "Expected:$($esc)[0m                                                               But was:$($esc)[0m"
                "----------------------------------------------------------------        ----------------------------------------------------------------"
                "Bytes                                           Ascii                   Bytes                                           Ascii"
                "-----                                           -----                   -----                                           -----"
                "$($esc)[31m31$($esc)[0m $($esc)[31m32$($esc)[0m $($esc)[31m33$($esc)[0m                                        $($esc)[31m1$($esc)[0m$($esc)[31m2$($esc)[0m$($esc)[31m3$($esc)[0m                !=   $($esc)[31m34$($esc)[0m $($esc)[31m35$($esc)[0m $($esc)[31m36$($esc)[0m                                        $($esc)[31m4$($esc)[0m$($esc)[31m5$($esc)[0m$($esc)[31m6$($esc)[0m             "
                "Expected:$($esc)[0m                                                               But was:$($esc)[0m"
                "----------------------------------------------------------------        ----------------------------------------------------------------"
                "Bytes                                           Ascii                   Bytes                                           Ascii"
                "-----                                           -----                   -----                                           -----"
                "41 6E 6F 74 68 65 72 20 53 74 72 69 6E 67       Another String     ==   41 6E 6F 74 68 65 72 20 53 74 72 69 6E 67       Another String  "
            )
        }
    }

    Context 'When expected and actual value contain Unicode characters' -Skip:($PSEdition -eq 'Desktop') {
        It 'Should output to console' {
            $expected = 'This is a test string with Unicode: 你好, Привіт, hello' # cSpell: disable-line
            $actual = 'This is a test string with Unicode: 你好, Привіт, hello' # cSpell: disable-line

            $result = Out-Difference -Reference $expected -Difference $actual

            $result | Should-BeBlockString @(
                "Expected:$($esc)[0m                                                               But was:$($esc)[0m"
                "----------------------------------------------------------------        ----------------------------------------------------------------"
                "Bytes                                           Ascii                   Bytes                                           Ascii"
                "-----                                           -----                   -----                                           -----"
                "54 68 69 73 20 69 73 20 61 20 74 65 73 74 20 73 This is a test s   ==   54 68 69 73 20 69 73 20 61 20 74 65 73 74 20 73 This is a test s"
                "74 72 69 6E 67 20 77 69 74 68 20 55 6E 69 63 6F tring with Unico   ==   74 72 69 6E 67 20 77 69 74 68 20 55 6E 69 63 6F tring with Unico"
                "64 65 3A 20 E4 BD A0 E5 A5 BD 2C 20 D0 9F D1 80 de: ä½ å¥½, ÐÑ   ==   64 65 3A 20 E4 BD A0 E5 A5 BD 2C 20 D0 9F D1 80 de: ä½ å¥½, ÐÑ"
                "D0 B8 D0 B2 D1 96 D1 82 2C 20 68 65 6C 6C 6F    Ð¸Ð²ÑÑ, hello    ==   D0 B8 D0 B2 D1 96 D1 82 2C 20 68 65 6C 6C 6F    Ð¸Ð²ÑÑ, hello "
            )
        }
    }

    Context 'When expected and actual value contain escaped characters' {
        It 'Should output to console' {
            $expected = "escaped characters: `0 `a `b `f `n `r `t"
            $actual = "escaped characters: `0 `a `b `f `n `r `t"

            $result = Out-Difference -Reference $expected -Difference $actual

            $result | Should-BeBlockString @(
                "Expected:$($esc)[0m                                                               But was:$($esc)[0m"
                "----------------------------------------------------------------        ----------------------------------------------------------------"
                "Bytes                                           Ascii                   Bytes                                           Ascii"
                "-----                                           -----                   -----                                           -----"
                "65 73 63 61 70 65 64 20 63 68 61 72 61 63 74 65 escaped characte   ==   65 73 63 61 70 65 64 20 63 68 61 72 61 63 74 65 escaped characte"
                "72 73 3A 20 00 20 07 20 08 20 0C 20 0A 20 0D 20 rs: ␀ ␇ ␈ ␌ ␊ ␍    ==   72 73 3A 20 00 20 07 20 08 20 0C 20 0A 20 0D 20 rs: ␀ ␇ ␈ ␌ ␊ ␍ "
                "09                                              ␉                  ==   09                                              ␉               "
            )
        }
    }

    Context 'When NoHexOutput is specified' {
        It 'Should output only ascii character groups without hex columns' {
            $longStr = 'A' * 70
            $result = Out-Difference -Reference $longStr -Difference $longStr -NoHexOutput
            $result | Should-BeBlockString @(
                "Expected:$($esc)[0m                                                               But was:$($esc)[0m"
                "----------------------------------------------------------------        ----------------------------------------------------------------"
                "Ascii                                                                   Ascii"
                "----------------------------------------------------------------        ----------------------------------------------------------------"
                "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA   ==   AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
                "AAAAAA                                                             ==   AAAAAA                                                          "
            )
        }
    }

    # cSpell: enable
}
