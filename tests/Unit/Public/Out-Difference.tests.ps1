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
                & "$PSScriptRoot/../../../build.ps1" -Tasks 'noop' 2>&1 4>&1 5>&1 6>&1 > $null
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

    # Unload the module being tested so that it doesn't impact any other tests.
    Get-Module -Name $script:dscModuleName -All | Remove-Module -Force
}

Describe 'Out-Difference' {
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
                "Expected:`e[0m                                                               But was:`e[0m"
                "----------------------------------------------------------------        ----------------------------------------------------------------"
                "Bytes                                           Ascii                   Bytes                                           Ascii"
                "-----                                           -----                   -----                                           -----"
                "4D 79 20 `e[31m53`e[0m 74 72 69 6E 67 20 `e[31m76`e[0m `e[31m65`e[0m `e[31m72`e[0m `e[31m79`e[0m 20 `e[31m6C`e[0m My `e[31mS`e[0mtring `e[31mv`e[0m`e[31me`e[0m`e[31mr`e[0m`e[31my`e[0m `e[31ml`e[0m   !=   4D 79 20 `e[31m73`e[0m 74 72 69 6E 67 20 `e[31m74`e[0m `e[31m68`e[0m `e[31m61`e[0m `e[31m74`e[0m 20 `e[31m69`e[0m My `e[31ms`e[0mtring `e[31mt`e[0m`e[31mh`e[0m`e[31ma`e[0m`e[31mt`e[0m `e[31mi`e[0m"
                "`e[31m6F`e[0m `e[31m6E`e[0m `e[31m67`e[0m `e[31m20`e[0m `e[31m73`e[0m `e[31m74`e[0m `e[31m72`e[0m `e[31m69`e[0m `e[31m6E`e[0m `e[31m67`e[0m `e[31m20`e[0m `e[31m74`e[0m `e[31m68`e[0m `e[31m61`e[0m `e[31m74`e[0m `e[31m20`e[0m `e[31mo`e[0m`e[31mn`e[0m`e[31mg`e[0m`e[31m `e[0m`e[31ms`e[0m`e[31mt`e[0m`e[31mr`e[0m`e[31mi`e[0m`e[31mn`e[0m`e[31mg`e[0m`e[31m `e[0m`e[31mt`e[0m`e[31mh`e[0m`e[31ma`e[0m`e[31mt`e[0m`e[31m `e[0m   !=   `e[31m73`e[0m `e[31m20`e[0m `e[31m73`e[0m `e[31m68`e[0m `e[31m6F`e[0m `e[31m72`e[0m `e[31m74`e[0m `e[31m65`e[0m `e[31m72`e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31ms`e[0m`e[31m `e[0m`e[31ms`e[0m`e[31mh`e[0m`e[31mo`e[0m`e[31mr`e[0m`e[31mt`e[0m`e[31me`e[0m`e[31mr`e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m"
                "`e[31m69`e[0m `e[31m73`e[0m `e[31m20`e[0m `e[31m6C`e[0m `e[31m6F`e[0m `e[31m6E`e[0m `e[31m67`e[0m `e[31m65`e[0m `e[31m72`e[0m `e[31m20`e[0m `e[31m74`e[0m `e[31m68`e[0m `e[31m61`e[0m `e[31m6E`e[0m `e[31m20`e[0m `e[31m61`e[0m `e[31mi`e[0m`e[31ms`e[0m`e[31m `e[0m`e[31ml`e[0m`e[31mo`e[0m`e[31mn`e[0m`e[31mg`e[0m`e[31me`e[0m`e[31mr`e[0m`e[31m `e[0m`e[31mt`e[0m`e[31mh`e[0m`e[31ma`e[0m`e[31mn`e[0m`e[31m `e[0m`e[31ma`e[0m   !=   `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m"
                "`e[31m63`e[0m `e[31m74`e[0m `e[31m75`e[0m `e[31m61`e[0m `e[31m6C`e[0m                                  `e[31mc`e[0m`e[31mt`e[0m`e[31mu`e[0m`e[31ma`e[0m`e[31ml`e[0m              !=   `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m                                  `e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m           "
                "Expected:`e[0m                                                               But was:`e[0m"
                "----------------------------------------------------------------        ----------------------------------------------------------------"
                "Bytes                                           Ascii                   Bytes                                           Ascii"
                "-----                                           -----                   -----                                           -----"
                "4C 69 6E 65 20 32                               Line 2             ==   4C 69 6E 65 20 32                               Line 2          "
                "Expected:`e[0m                                                               But was:`e[0m"
                "----------------------------------------------------------------        ----------------------------------------------------------------"
                "Bytes                                           Ascii                   Bytes                                           Ascii"
                "-----                                           -----                   -----                                           -----"
                "4C 69 6E 65 20 33 `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m Line 3`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m   !=   4C 69 6E 65 20 33 `e[31m20`e[0m `e[31m69`e[0m `e[31m73`e[0m `e[31m20`e[0m `e[31m6C`e[0m `e[31m6F`e[0m `e[31m6E`e[0m `e[31m67`e[0m `e[31m65`e[0m `e[31m72`e[0m Line 3`e[31m `e[0m`e[31mi`e[0m`e[31ms`e[0m`e[31m `e[0m`e[31ml`e[0m`e[31mo`e[0m`e[31mn`e[0m`e[31mg`e[0m`e[31me`e[0m`e[31mr`e[0m"
                "`e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m       `e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m     !=   `e[31m20`e[0m `e[31m74`e[0m `e[31m68`e[0m `e[31m61`e[0m `e[31m6E`e[0m `e[31m20`e[0m `e[31m65`e[0m `e[31m78`e[0m `e[31m70`e[0m `e[31m65`e[0m `e[31m63`e[0m `e[31m74`e[0m `e[31m65`e[0m `e[31m64`e[0m       `e[31m `e[0m`e[31mt`e[0m`e[31mh`e[0m`e[31ma`e[0m`e[31mn`e[0m`e[31m `e[0m`e[31me`e[0m`e[31mx`e[0m`e[31mp`e[0m`e[31me`e[0m`e[31mc`e[0m`e[31mt`e[0m`e[31me`e[0m`e[31md`e[0m  "
                "Expected:`e[0m                                                               But was:`e[0m"
                "----------------------------------------------------------------        ----------------------------------------------------------------"
                "Bytes                                           Ascii                   Bytes                                           Ascii"
                "-----                                           -----                   -----                                           -----"
                "`e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m                               `e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m             !=   `e[31m4C`e[0m `e[31m69`e[0m `e[31m6E`e[0m `e[31m65`e[0m `e[31m20`e[0m `e[31m34`e[0m                               `e[31mL`e[0m`e[31mi`e[0m`e[31mn`e[0m`e[31me`e[0m`e[31m `e[0m`e[31m4`e[0m          "
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
                "Expected:`e[0m                                                               But was:`e[0m"
                "----------------------------------------------------------------        ----------------------------------------------------------------"
                "4D 79 20 `e[31m53`e[0m 74 72 69 6E 67 20 `e[31m76`e[0m `e[31m65`e[0m `e[31m72`e[0m `e[31m79`e[0m 20 `e[31m6C`e[0m My `e[31mS`e[0mtring `e[31mv`e[0m`e[31me`e[0m`e[31mr`e[0m`e[31my`e[0m `e[31ml`e[0m   !=   4D 79 20 `e[31m73`e[0m 74 72 69 6E 67 20 `e[31m74`e[0m `e[31m68`e[0m `e[31m61`e[0m `e[31m74`e[0m 20 `e[31m69`e[0m My `e[31ms`e[0mtring `e[31mt`e[0m`e[31mh`e[0m`e[31ma`e[0m`e[31mt`e[0m `e[31mi`e[0m"
                "`e[31m6F`e[0m `e[31m6E`e[0m `e[31m67`e[0m `e[31m20`e[0m `e[31m73`e[0m `e[31m74`e[0m `e[31m72`e[0m `e[31m69`e[0m `e[31m6E`e[0m `e[31m67`e[0m `e[31m20`e[0m `e[31m74`e[0m `e[31m68`e[0m `e[31m61`e[0m `e[31m74`e[0m `e[31m20`e[0m `e[31mo`e[0m`e[31mn`e[0m`e[31mg`e[0m`e[31m `e[0m`e[31ms`e[0m`e[31mt`e[0m`e[31mr`e[0m`e[31mi`e[0m`e[31mn`e[0m`e[31mg`e[0m`e[31m `e[0m`e[31mt`e[0m`e[31mh`e[0m`e[31ma`e[0m`e[31mt`e[0m`e[31m `e[0m   !=   `e[31m73`e[0m `e[31m20`e[0m `e[31m73`e[0m `e[31m68`e[0m `e[31m6F`e[0m `e[31m72`e[0m `e[31m74`e[0m `e[31m65`e[0m `e[31m72`e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31ms`e[0m`e[31m `e[0m`e[31ms`e[0m`e[31mh`e[0m`e[31mo`e[0m`e[31mr`e[0m`e[31mt`e[0m`e[31me`e[0m`e[31mr`e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m"
                "`e[31m69`e[0m `e[31m73`e[0m `e[31m20`e[0m `e[31m6C`e[0m `e[31m6F`e[0m `e[31m6E`e[0m `e[31m67`e[0m `e[31m65`e[0m `e[31m72`e[0m `e[31m20`e[0m `e[31m74`e[0m `e[31m68`e[0m `e[31m61`e[0m `e[31m6E`e[0m `e[31m20`e[0m `e[31m61`e[0m `e[31mi`e[0m`e[31ms`e[0m`e[31m `e[0m`e[31ml`e[0m`e[31mo`e[0m`e[31mn`e[0m`e[31mg`e[0m`e[31me`e[0m`e[31mr`e[0m`e[31m `e[0m`e[31mt`e[0m`e[31mh`e[0m`e[31ma`e[0m`e[31mn`e[0m`e[31m `e[0m`e[31ma`e[0m   !=   `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m"
                "`e[31m63`e[0m `e[31m74`e[0m `e[31m75`e[0m `e[31m61`e[0m `e[31m6C`e[0m                                  `e[31mc`e[0m`e[31mt`e[0m`e[31mu`e[0m`e[31ma`e[0m`e[31ml`e[0m              !=   `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m                                  `e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m           "
                "Expected:`e[0m                                                               But was:`e[0m"
                "----------------------------------------------------------------        ----------------------------------------------------------------"
                "4C 69 6E 65 20 32                               Line 2             ==   4C 69 6E 65 20 32                               Line 2          "
                "Expected:`e[0m                                                               But was:`e[0m"
                "----------------------------------------------------------------        ----------------------------------------------------------------"
                "4C 69 6E 65 20 33 `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m Line 3`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m   !=   4C 69 6E 65 20 33 `e[31m20`e[0m `e[31m69`e[0m `e[31m73`e[0m `e[31m20`e[0m `e[31m6C`e[0m `e[31m6F`e[0m `e[31m6E`e[0m `e[31m67`e[0m `e[31m65`e[0m `e[31m72`e[0m Line 3`e[31m `e[0m`e[31mi`e[0m`e[31ms`e[0m`e[31m `e[0m`e[31ml`e[0m`e[31mo`e[0m`e[31mn`e[0m`e[31mg`e[0m`e[31me`e[0m`e[31mr`e[0m"
                "`e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m       `e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m     !=   `e[31m20`e[0m `e[31m74`e[0m `e[31m68`e[0m `e[31m61`e[0m `e[31m6E`e[0m `e[31m20`e[0m `e[31m65`e[0m `e[31m78`e[0m `e[31m70`e[0m `e[31m65`e[0m `e[31m63`e[0m `e[31m74`e[0m `e[31m65`e[0m `e[31m64`e[0m       `e[31m `e[0m`e[31mt`e[0m`e[31mh`e[0m`e[31ma`e[0m`e[31mn`e[0m`e[31m `e[0m`e[31me`e[0m`e[31mx`e[0m`e[31mp`e[0m`e[31me`e[0m`e[31mc`e[0m`e[31mt`e[0m`e[31me`e[0m`e[31md`e[0m  "
                "Expected:`e[0m                                                               But was:`e[0m"
                "----------------------------------------------------------------        ----------------------------------------------------------------"
                "`e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m                               `e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m             !=   `e[31m4C`e[0m `e[31m69`e[0m `e[31m6E`e[0m `e[31m65`e[0m `e[31m20`e[0m `e[31m34`e[0m                               `e[31mL`e[0m`e[31mi`e[0m`e[31mn`e[0m`e[31me`e[0m`e[31m `e[0m`e[31m4`e[0m          "
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
                "4D 79 20 `e[31m53`e[0m 74 72 69 6E 67 20 `e[31m76`e[0m `e[31m65`e[0m `e[31m72`e[0m `e[31m79`e[0m 20 `e[31m6C`e[0m My `e[31mS`e[0mtring `e[31mv`e[0m`e[31me`e[0m`e[31mr`e[0m`e[31my`e[0m `e[31ml`e[0m   !=   4D 79 20 `e[31m73`e[0m 74 72 69 6E 67 20 `e[31m74`e[0m `e[31m68`e[0m `e[31m61`e[0m `e[31m74`e[0m 20 `e[31m69`e[0m My `e[31ms`e[0mtring `e[31mt`e[0m`e[31mh`e[0m`e[31ma`e[0m`e[31mt`e[0m `e[31mi`e[0m"
                "`e[31m6F`e[0m `e[31m6E`e[0m `e[31m67`e[0m `e[31m20`e[0m `e[31m73`e[0m `e[31m74`e[0m `e[31m72`e[0m `e[31m69`e[0m `e[31m6E`e[0m `e[31m67`e[0m `e[31m20`e[0m `e[31m74`e[0m `e[31m68`e[0m `e[31m61`e[0m `e[31m74`e[0m `e[31m20`e[0m `e[31mo`e[0m`e[31mn`e[0m`e[31mg`e[0m`e[31m `e[0m`e[31ms`e[0m`e[31mt`e[0m`e[31mr`e[0m`e[31mi`e[0m`e[31mn`e[0m`e[31mg`e[0m`e[31m `e[0m`e[31mt`e[0m`e[31mh`e[0m`e[31ma`e[0m`e[31mt`e[0m`e[31m `e[0m   !=   `e[31m73`e[0m `e[31m20`e[0m `e[31m73`e[0m `e[31m68`e[0m `e[31m6F`e[0m `e[31m72`e[0m `e[31m74`e[0m `e[31m65`e[0m `e[31m72`e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31ms`e[0m`e[31m `e[0m`e[31ms`e[0m`e[31mh`e[0m`e[31mo`e[0m`e[31mr`e[0m`e[31mt`e[0m`e[31me`e[0m`e[31mr`e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m"
                "`e[31m69`e[0m `e[31m73`e[0m `e[31m20`e[0m `e[31m6C`e[0m `e[31m6F`e[0m `e[31m6E`e[0m `e[31m67`e[0m `e[31m65`e[0m `e[31m72`e[0m `e[31m20`e[0m `e[31m74`e[0m `e[31m68`e[0m `e[31m61`e[0m `e[31m6E`e[0m `e[31m20`e[0m `e[31m61`e[0m `e[31mi`e[0m`e[31ms`e[0m`e[31m `e[0m`e[31ml`e[0m`e[31mo`e[0m`e[31mn`e[0m`e[31mg`e[0m`e[31me`e[0m`e[31mr`e[0m`e[31m `e[0m`e[31mt`e[0m`e[31mh`e[0m`e[31ma`e[0m`e[31mn`e[0m`e[31m `e[0m`e[31ma`e[0m   !=   `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m"
                "`e[31m63`e[0m `e[31m74`e[0m `e[31m75`e[0m `e[31m61`e[0m `e[31m6C`e[0m                                  `e[31mc`e[0m`e[31mt`e[0m`e[31mu`e[0m`e[31ma`e[0m`e[31ml`e[0m              !=   `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m                                  `e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m           "
                "Bytes                                           Ascii                   Bytes                                           Ascii"
                "-----                                           -----                   -----                                           -----"
                "4C 69 6E 65 20 32                               Line 2             ==   4C 69 6E 65 20 32                               Line 2          "
                "Bytes                                           Ascii                   Bytes                                           Ascii"
                "-----                                           -----                   -----                                           -----"
                "4C 69 6E 65 20 33 `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m Line 3`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m   !=   4C 69 6E 65 20 33 `e[31m20`e[0m `e[31m69`e[0m `e[31m73`e[0m `e[31m20`e[0m `e[31m6C`e[0m `e[31m6F`e[0m `e[31m6E`e[0m `e[31m67`e[0m `e[31m65`e[0m `e[31m72`e[0m Line 3`e[31m `e[0m`e[31mi`e[0m`e[31ms`e[0m`e[31m `e[0m`e[31ml`e[0m`e[31mo`e[0m`e[31mn`e[0m`e[31mg`e[0m`e[31me`e[0m`e[31mr`e[0m"
                "`e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m       `e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m     !=   `e[31m20`e[0m `e[31m74`e[0m `e[31m68`e[0m `e[31m61`e[0m `e[31m6E`e[0m `e[31m20`e[0m `e[31m65`e[0m `e[31m78`e[0m `e[31m70`e[0m `e[31m65`e[0m `e[31m63`e[0m `e[31m74`e[0m `e[31m65`e[0m `e[31m64`e[0m       `e[31m `e[0m`e[31mt`e[0m`e[31mh`e[0m`e[31ma`e[0m`e[31mn`e[0m`e[31m `e[0m`e[31me`e[0m`e[31mx`e[0m`e[31mp`e[0m`e[31me`e[0m`e[31mc`e[0m`e[31mt`e[0m`e[31me`e[0m`e[31md`e[0m  "
                "Bytes                                           Ascii                   Bytes                                           Ascii"
                "-----                                           -----                   -----                                           -----"
                "`e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m                               `e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m             !=   `e[31m4C`e[0m `e[31m69`e[0m `e[31m6E`e[0m `e[31m65`e[0m `e[31m20`e[0m `e[31m34`e[0m                               `e[31mL`e[0m`e[31mi`e[0m`e[31mn`e[0m`e[31me`e[0m`e[31m `e[0m`e[31m4`e[0m          "
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
                "4D 79 20 `e[31m53`e[0m 74 72 69 6E 67 20 `e[31m76`e[0m `e[31m65`e[0m `e[31m72`e[0m `e[31m79`e[0m 20 `e[31m6C`e[0m My `e[31mS`e[0mtring `e[31mv`e[0m`e[31me`e[0m`e[31mr`e[0m`e[31my`e[0m `e[31ml`e[0m   !=   4D 79 20 `e[31m73`e[0m 74 72 69 6E 67 20 `e[31m74`e[0m `e[31m68`e[0m `e[31m61`e[0m `e[31m74`e[0m 20 `e[31m69`e[0m My `e[31ms`e[0mtring `e[31mt`e[0m`e[31mh`e[0m`e[31ma`e[0m`e[31mt`e[0m `e[31mi`e[0m"
                "`e[31m6F`e[0m `e[31m6E`e[0m `e[31m67`e[0m `e[31m20`e[0m `e[31m73`e[0m `e[31m74`e[0m `e[31m72`e[0m `e[31m69`e[0m `e[31m6E`e[0m `e[31m67`e[0m `e[31m20`e[0m `e[31m74`e[0m `e[31m68`e[0m `e[31m61`e[0m `e[31m74`e[0m `e[31m20`e[0m `e[31mo`e[0m`e[31mn`e[0m`e[31mg`e[0m`e[31m `e[0m`e[31ms`e[0m`e[31mt`e[0m`e[31mr`e[0m`e[31mi`e[0m`e[31mn`e[0m`e[31mg`e[0m`e[31m `e[0m`e[31mt`e[0m`e[31mh`e[0m`e[31ma`e[0m`e[31mt`e[0m`e[31m `e[0m   !=   `e[31m73`e[0m `e[31m20`e[0m `e[31m73`e[0m `e[31m68`e[0m `e[31m6F`e[0m `e[31m72`e[0m `e[31m74`e[0m `e[31m65`e[0m `e[31m72`e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31ms`e[0m`e[31m `e[0m`e[31ms`e[0m`e[31mh`e[0m`e[31mo`e[0m`e[31mr`e[0m`e[31mt`e[0m`e[31me`e[0m`e[31mr`e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m"
                "`e[31m69`e[0m `e[31m73`e[0m `e[31m20`e[0m `e[31m6C`e[0m `e[31m6F`e[0m `e[31m6E`e[0m `e[31m67`e[0m `e[31m65`e[0m `e[31m72`e[0m `e[31m20`e[0m `e[31m74`e[0m `e[31m68`e[0m `e[31m61`e[0m `e[31m6E`e[0m `e[31m20`e[0m `e[31m61`e[0m `e[31mi`e[0m`e[31ms`e[0m`e[31m `e[0m`e[31ml`e[0m`e[31mo`e[0m`e[31mn`e[0m`e[31mg`e[0m`e[31me`e[0m`e[31mr`e[0m`e[31m `e[0m`e[31mt`e[0m`e[31mh`e[0m`e[31ma`e[0m`e[31mn`e[0m`e[31m `e[0m`e[31ma`e[0m   !=   `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m"
                "`e[31m63`e[0m `e[31m74`e[0m `e[31m75`e[0m `e[31m61`e[0m `e[31m6C`e[0m                                  `e[31mc`e[0m`e[31mt`e[0m`e[31mu`e[0m`e[31ma`e[0m`e[31ml`e[0m              !=   `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m                                  `e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m           "
                "4C 69 6E 65 20 32                               Line 2             ==   4C 69 6E 65 20 32                               Line 2          "
                "4C 69 6E 65 20 33 `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m Line 3`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m   !=   4C 69 6E 65 20 33 `e[31m20`e[0m `e[31m69`e[0m `e[31m73`e[0m `e[31m20`e[0m `e[31m6C`e[0m `e[31m6F`e[0m `e[31m6E`e[0m `e[31m67`e[0m `e[31m65`e[0m `e[31m72`e[0m Line 3`e[31m `e[0m`e[31mi`e[0m`e[31ms`e[0m`e[31m `e[0m`e[31ml`e[0m`e[31mo`e[0m`e[31mn`e[0m`e[31mg`e[0m`e[31me`e[0m`e[31mr`e[0m"
                "`e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m       `e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m     !=   `e[31m20`e[0m `e[31m74`e[0m `e[31m68`e[0m `e[31m61`e[0m `e[31m6E`e[0m `e[31m20`e[0m `e[31m65`e[0m `e[31m78`e[0m `e[31m70`e[0m `e[31m65`e[0m `e[31m63`e[0m `e[31m74`e[0m `e[31m65`e[0m `e[31m64`e[0m       `e[31m `e[0m`e[31mt`e[0m`e[31mh`e[0m`e[31ma`e[0m`e[31mn`e[0m`e[31m `e[0m`e[31me`e[0m`e[31mx`e[0m`e[31mp`e[0m`e[31me`e[0m`e[31mc`e[0m`e[31mt`e[0m`e[31me`e[0m`e[31md`e[0m  "
                "`e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m                               `e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m             !=   `e[31m4C`e[0m `e[31m69`e[0m `e[31m6E`e[0m `e[31m65`e[0m `e[31m20`e[0m `e[31m34`e[0m                               `e[31mL`e[0m`e[31mi`e[0m`e[31mn`e[0m`e[31me`e[0m`e[31m `e[0m`e[31m4`e[0m          "
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
                "Expected:`e[0m                                                               But was:`e[0m"
                "----------------------------------------------------------------        ----------------------------------------------------------------"
                "Bytes                                           Ascii                   Bytes                                           Ascii"
                "-----                                           -----                   -----                                           -----"
                "`e[31m4D`e[0m `e[31m79`e[0m `e[31m20`e[0m `e[31m53`e[0m `e[31m74`e[0m `e[31m72`e[0m `e[31m69`e[0m `e[31m6E`e[0m `e[31m67`e[0m `e[31m20`e[0m `e[31m76`e[0m `e[31m65`e[0m `e[31m72`e[0m `e[31m79`e[0m `e[31m20`e[0m `e[31m6C`e[0m `e[31mM`e[0m`e[31my`e[0m`e[31m `e[0m`e[31mS`e[0m`e[31mt`e[0m`e[31mr`e[0m`e[31mi`e[0m`e[31mn`e[0m`e[31mg`e[0m`e[31m `e[0m`e[31mv`e[0m`e[31me`e[0m`e[31mr`e[0m`e[31my`e[0m`e[31m `e[0m`e[31ml`e[0m   !=   `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m"
                "`e[31m6F`e[0m `e[31m6E`e[0m `e[31m67`e[0m `e[31m20`e[0m `e[31m73`e[0m `e[31m74`e[0m `e[31m72`e[0m `e[31m69`e[0m `e[31m6E`e[0m `e[31m67`e[0m `e[31m20`e[0m `e[31m74`e[0m `e[31m68`e[0m `e[31m61`e[0m `e[31m74`e[0m `e[31m20`e[0m `e[31mo`e[0m`e[31mn`e[0m`e[31mg`e[0m`e[31m `e[0m`e[31ms`e[0m`e[31mt`e[0m`e[31mr`e[0m`e[31mi`e[0m`e[31mn`e[0m`e[31mg`e[0m`e[31m `e[0m`e[31mt`e[0m`e[31mh`e[0m`e[31ma`e[0m`e[31mt`e[0m`e[31m `e[0m   !=   `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m"
                "`e[31m69`e[0m `e[31m73`e[0m `e[31m20`e[0m `e[31m6C`e[0m `e[31m6F`e[0m `e[31m6E`e[0m `e[31m67`e[0m `e[31m65`e[0m `e[31m72`e[0m `e[31m20`e[0m `e[31m74`e[0m `e[31m68`e[0m `e[31m61`e[0m `e[31m6E`e[0m `e[31m20`e[0m `e[31m61`e[0m `e[31mi`e[0m`e[31ms`e[0m`e[31m `e[0m`e[31ml`e[0m`e[31mo`e[0m`e[31mn`e[0m`e[31mg`e[0m`e[31me`e[0m`e[31mr`e[0m`e[31m `e[0m`e[31mt`e[0m`e[31mh`e[0m`e[31ma`e[0m`e[31mn`e[0m`e[31m `e[0m`e[31ma`e[0m   !=   `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m"
                "`e[31m63`e[0m `e[31m74`e[0m `e[31m75`e[0m `e[31m61`e[0m `e[31m6C`e[0m                                  `e[31mc`e[0m`e[31mt`e[0m`e[31mu`e[0m`e[31ma`e[0m`e[31ml`e[0m              !=   `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m                                  `e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m           "
                "Expected:`e[0m                                                               But was:`e[0m"
                "----------------------------------------------------------------        ----------------------------------------------------------------"
                "Bytes                                           Ascii                   Bytes                                           Ascii"
                "-----                                           -----                   -----                                           -----"
                "`e[31m4C`e[0m `e[31m69`e[0m `e[31m6E`e[0m `e[31m65`e[0m `e[31m20`e[0m `e[31m32`e[0m                               `e[31mL`e[0m`e[31mi`e[0m`e[31mn`e[0m`e[31me`e[0m`e[31m `e[0m`e[31m2`e[0m             !=   `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m                               `e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m          "
                "Expected:`e[0m                                                               But was:`e[0m"
                "----------------------------------------------------------------        ----------------------------------------------------------------"
                "Bytes                                           Ascii                   Bytes                                           Ascii"
                "-----                                           -----                   -----                                           -----"
                "`e[31m4C`e[0m `e[31m69`e[0m `e[31m6E`e[0m `e[31m65`e[0m `e[31m20`e[0m `e[31m33`e[0m                               `e[31mL`e[0m`e[31mi`e[0m`e[31mn`e[0m`e[31me`e[0m`e[31m `e[0m`e[31m3`e[0m             !=   `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m                               `e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m          "
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
                "Expected:`e[0m                                                               But was:`e[0m"
                "----------------------------------------------------------------        ----------------------------------------------------------------"
                "Bytes                                           Ascii                   Bytes                                           Ascii"
                "-----                                           -----                   -----                                           -----"
                "`e[31m4D`e[0m `e[31m79`e[0m `e[31m20`e[0m `e[31m53`e[0m `e[31m74`e[0m `e[31m72`e[0m `e[31m69`e[0m `e[31m6E`e[0m `e[31m67`e[0m `e[31m20`e[0m `e[31m76`e[0m `e[31m65`e[0m `e[31m72`e[0m `e[31m79`e[0m `e[31m20`e[0m `e[31m6C`e[0m `e[31mM`e[0m`e[31my`e[0m`e[31m `e[0m`e[31mS`e[0m`e[31mt`e[0m`e[31mr`e[0m`e[31mi`e[0m`e[31mn`e[0m`e[31mg`e[0m`e[31m `e[0m`e[31mv`e[0m`e[31me`e[0m`e[31mr`e[0m`e[31my`e[0m`e[31m `e[0m`e[31ml`e[0m   !=   `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m"
                "`e[31m6F`e[0m `e[31m6E`e[0m `e[31m67`e[0m `e[31m20`e[0m `e[31m73`e[0m `e[31m74`e[0m `e[31m72`e[0m `e[31m69`e[0m `e[31m6E`e[0m `e[31m67`e[0m `e[31m20`e[0m `e[31m74`e[0m `e[31m68`e[0m `e[31m61`e[0m `e[31m74`e[0m `e[31m20`e[0m `e[31mo`e[0m`e[31mn`e[0m`e[31mg`e[0m`e[31m `e[0m`e[31ms`e[0m`e[31mt`e[0m`e[31mr`e[0m`e[31mi`e[0m`e[31mn`e[0m`e[31mg`e[0m`e[31m `e[0m`e[31mt`e[0m`e[31mh`e[0m`e[31ma`e[0m`e[31mt`e[0m`e[31m `e[0m   !=   `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m"
                "`e[31m69`e[0m `e[31m73`e[0m `e[31m20`e[0m `e[31m6C`e[0m `e[31m6F`e[0m `e[31m6E`e[0m `e[31m67`e[0m `e[31m65`e[0m `e[31m72`e[0m `e[31m20`e[0m `e[31m74`e[0m `e[31m68`e[0m `e[31m61`e[0m `e[31m6E`e[0m `e[31m20`e[0m `e[31m61`e[0m `e[31mi`e[0m`e[31ms`e[0m`e[31m `e[0m`e[31ml`e[0m`e[31mo`e[0m`e[31mn`e[0m`e[31mg`e[0m`e[31me`e[0m`e[31mr`e[0m`e[31m `e[0m`e[31mt`e[0m`e[31mh`e[0m`e[31ma`e[0m`e[31mn`e[0m`e[31m `e[0m`e[31ma`e[0m   !=   `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m"
                "`e[31m63`e[0m `e[31m74`e[0m `e[31m75`e[0m `e[31m61`e[0m `e[31m6C`e[0m                                  `e[31mc`e[0m`e[31mt`e[0m`e[31mu`e[0m`e[31ma`e[0m`e[31ml`e[0m              !=   `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m                                  `e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m           "
                "Expected:`e[0m                                                               But was:`e[0m"
                "----------------------------------------------------------------        ----------------------------------------------------------------"
                "Bytes                                           Ascii                   Bytes                                           Ascii"
                "-----                                           -----                   -----                                           -----"
                "`e[31m4C`e[0m `e[31m69`e[0m `e[31m6E`e[0m `e[31m65`e[0m `e[31m20`e[0m `e[31m32`e[0m                               `e[31mL`e[0m`e[31mi`e[0m`e[31mn`e[0m`e[31me`e[0m`e[31m `e[0m`e[31m2`e[0m             !=   `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m                               `e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m          "
                "Expected:`e[0m                                                               But was:`e[0m"
                "----------------------------------------------------------------        ----------------------------------------------------------------"
                "Bytes                                           Ascii                   Bytes                                           Ascii"
                "-----                                           -----                   -----                                           -----"
                "`e[31m4C`e[0m `e[31m69`e[0m `e[31m6E`e[0m `e[31m65`e[0m `e[31m20`e[0m `e[31m33`e[0m                               `e[31mL`e[0m`e[31mi`e[0m`e[31mn`e[0m`e[31me`e[0m`e[31m `e[0m`e[31m3`e[0m             !=   `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m `e[31m  `e[0m                               `e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m`e[31m `e[0m          "
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
                "Expected:[0m                                                               But was:[0m"
                "----------------------------------------------------------------        ----------------------------------------------------------------"
                "Bytes                                           Ascii                   Bytes                                           Ascii"
                "-----                                           -----                   -----                                           -----"
                "[31m  [0m [31m  [0m [31m  [0m [31m  [0m [31m  [0m [31m  [0m [31m  [0m [31m  [0m [31m  [0m [31m  [0m [31m  [0m [31m  [0m [31m  [0m [31m  [0m [31m  [0m [31m  [0m [31m [0m[31m [0m[31m [0m[31m [0m[31m [0m[31m [0m[31m [0m[31m [0m[31m [0m[31m [0m[31m [0m[31m [0m[31m [0m[31m [0m[31m [0m[31m [0m   !=   [31m4D[0m [31m79[0m [31m20[0m [31m53[0m [31m74[0m [31m72[0m [31m69[0m [31m6E[0m [31m67[0m [31m20[0m [31m76[0m [31m65[0m [31m72[0m [31m79[0m [31m20[0m [31m6C[0m [31mM[0m[31my[0m[31m [0m[31mS[0m[31mt[0m[31mr[0m[31mi[0m[31mn[0m[31mg[0m[31m [0m[31mv[0m[31me[0m[31mr[0m[31my[0m[31m [0m[31ml[0m"
                "[31m  [0m [31m  [0m [31m  [0m [31m  [0m [31m  [0m [31m  [0m [31m  [0m [31m  [0m [31m  [0m [31m  [0m [31m  [0m [31m  [0m [31m  [0m [31m  [0m [31m  [0m [31m  [0m [31m [0m[31m [0m[31m [0m[31m [0m[31m [0m[31m [0m[31m [0m[31m [0m[31m [0m[31m [0m[31m [0m[31m [0m[31m [0m[31m [0m[31m [0m[31m [0m   !=   [31m6F[0m [31m6E[0m [31m67[0m [31m20[0m [31m73[0m [31m74[0m [31m72[0m [31m69[0m [31m6E[0m [31m67[0m [31m20[0m [31m74[0m [31m68[0m [31m61[0m [31m74[0m [31m20[0m [31mo[0m[31mn[0m[31mg[0m[31m [0m[31ms[0m[31mt[0m[31mr[0m[31mi[0m[31mn[0m[31mg[0m[31m [0m[31mt[0m[31mh[0m[31ma[0m[31mt[0m[31m [0m"
                "[31m  [0m [31m  [0m [31m  [0m [31m  [0m [31m  [0m [31m  [0m [31m  [0m [31m  [0m [31m  [0m [31m  [0m [31m  [0m [31m  [0m [31m  [0m [31m  [0m [31m  [0m [31m  [0m [31m [0m[31m [0m[31m [0m[31m [0m[31m [0m[31m [0m[31m [0m[31m [0m[31m [0m[31m [0m[31m [0m[31m [0m[31m [0m[31m [0m[31m [0m[31m [0m   !=   [31m69[0m [31m73[0m [31m20[0m [31m6C[0m [31m6F[0m [31m6E[0m [31m67[0m [31m65[0m [31m72[0m [31m20[0m [31m74[0m [31m68[0m [31m61[0m [31m6E[0m [31m20[0m [31m61[0m [31mi[0m[31ms[0m[31m [0m[31ml[0m[31mo[0m[31mn[0m[31mg[0m[31me[0m[31mr[0m[31m [0m[31mt[0m[31mh[0m[31ma[0m[31mn[0m[31m [0m[31ma[0m"
                "[31m  [0m [31m  [0m [31m  [0m [31m  [0m [31m  [0m                                  [31m [0m[31m [0m[31m [0m[31m [0m[31m [0m              !=   [31m63[0m [31m74[0m [31m75[0m [31m61[0m [31m6C[0m                                  [31mc[0m[31mt[0m[31mu[0m[31ma[0m[31ml[0m           "
                "Expected:[0m                                                               But was:[0m"
                "----------------------------------------------------------------        ----------------------------------------------------------------"
                "Bytes                                           Ascii                   Bytes                                           Ascii"
                "-----                                           -----                   -----                                           -----"
                "[31m  [0m [31m  [0m [31m  [0m [31m  [0m [31m  [0m [31m  [0m                               [31m [0m[31m [0m[31m [0m[31m [0m[31m [0m[31m [0m             !=   [31m4C[0m [31m69[0m [31m6E[0m [31m65[0m [31m20[0m [31m32[0m                               [31mL[0m[31mi[0m[31mn[0m[31me[0m[31m [0m[31m2[0m          "
                "Expected:[0m                                                               But was:[0m"
                "----------------------------------------------------------------        ----------------------------------------------------------------"
                "Bytes                                           Ascii                   Bytes                                           Ascii"
                "-----                                           -----                   -----                                           -----"
                "[31m  [0m [31m  [0m [31m  [0m [31m  [0m [31m  [0m [31m  [0m                               [31m [0m[31m [0m[31m [0m[31m [0m[31m [0m[31m [0m             !=   [31m4C[0m [31m69[0m [31m6E[0m [31m65[0m [31m20[0m [31m33[0m                               [31mL[0m[31mi[0m[31mn[0m[31me[0m[31m [0m[31m3[0m          "
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
                "Expected:[0m                                                               But was:[0m"
                "----------------------------------------------------------------        ----------------------------------------------------------------"
                "Bytes                                           Ascii                   Bytes                                           Ascii"
                "-----                                           -----                   -----                                           -----"
                "[31m  [0m [31m  [0m [31m  [0m [31m  [0m [31m  [0m [31m  [0m [31m  [0m [31m  [0m [31m  [0m [31m  [0m [31m  [0m [31m  [0m [31m  [0m [31m  [0m [31m  [0m [31m  [0m [31m [0m[31m [0m[31m [0m[31m [0m[31m [0m[31m [0m[31m [0m[31m [0m[31m [0m[31m [0m[31m [0m[31m [0m[31m [0m[31m [0m[31m [0m[31m [0m   !=   [31m4D[0m [31m79[0m [31m20[0m [31m53[0m [31m74[0m [31m72[0m [31m69[0m [31m6E[0m [31m67[0m [31m20[0m [31m76[0m [31m65[0m [31m72[0m [31m79[0m [31m20[0m [31m6C[0m [31mM[0m[31my[0m[31m [0m[31mS[0m[31mt[0m[31mr[0m[31mi[0m[31mn[0m[31mg[0m[31m [0m[31mv[0m[31me[0m[31mr[0m[31my[0m[31m [0m[31ml[0m"
                "[31m  [0m [31m  [0m [31m  [0m [31m  [0m [31m  [0m [31m  [0m [31m  [0m [31m  [0m [31m  [0m [31m  [0m [31m  [0m [31m  [0m [31m  [0m [31m  [0m [31m  [0m [31m  [0m [31m [0m[31m [0m[31m [0m[31m [0m[31m [0m[31m [0m[31m [0m[31m [0m[31m [0m[31m [0m[31m [0m[31m [0m[31m [0m[31m [0m[31m [0m[31m [0m   !=   [31m6F[0m [31m6E[0m [31m67[0m [31m20[0m [31m73[0m [31m74[0m [31m72[0m [31m69[0m [31m6E[0m [31m67[0m [31m20[0m [31m74[0m [31m68[0m [31m61[0m [31m74[0m [31m20[0m [31mo[0m[31mn[0m[31mg[0m[31m [0m[31ms[0m[31mt[0m[31mr[0m[31mi[0m[31mn[0m[31mg[0m[31m [0m[31mt[0m[31mh[0m[31ma[0m[31mt[0m[31m [0m"
                "[31m  [0m [31m  [0m [31m  [0m [31m  [0m [31m  [0m [31m  [0m [31m  [0m [31m  [0m [31m  [0m [31m  [0m [31m  [0m [31m  [0m [31m  [0m [31m  [0m [31m  [0m [31m  [0m [31m [0m[31m [0m[31m [0m[31m [0m[31m [0m[31m [0m[31m [0m[31m [0m[31m [0m[31m [0m[31m [0m[31m [0m[31m [0m[31m [0m[31m [0m[31m [0m   !=   [31m69[0m [31m73[0m [31m20[0m [31m6C[0m [31m6F[0m [31m6E[0m [31m67[0m [31m65[0m [31m72[0m [31m20[0m [31m74[0m [31m68[0m [31m61[0m [31m6E[0m [31m20[0m [31m61[0m [31mi[0m[31ms[0m[31m [0m[31ml[0m[31mo[0m[31mn[0m[31mg[0m[31me[0m[31mr[0m[31m [0m[31mt[0m[31mh[0m[31ma[0m[31mn[0m[31m [0m[31ma[0m"
                "[31m  [0m [31m  [0m [31m  [0m [31m  [0m [31m  [0m                                  [31m [0m[31m [0m[31m [0m[31m [0m[31m [0m              !=   [31m63[0m [31m74[0m [31m75[0m [31m61[0m [31m6C[0m                                  [31mc[0m[31mt[0m[31mu[0m[31ma[0m[31ml[0m           "
                "Expected:[0m                                                               But was:[0m"
                "----------------------------------------------------------------        ----------------------------------------------------------------"
                "Bytes                                           Ascii                   Bytes                                           Ascii"
                "-----                                           -----                   -----                                           -----"
                "[31m  [0m [31m  [0m [31m  [0m [31m  [0m [31m  [0m [31m  [0m                               [31m [0m[31m [0m[31m [0m[31m [0m[31m [0m[31m [0m             !=   [31m4C[0m [31m69[0m [31m6E[0m [31m65[0m [31m20[0m [31m32[0m                               [31mL[0m[31mi[0m[31mn[0m[31me[0m[31m [0m[31m2[0m          "
                "Expected:[0m                                                               But was:[0m"
                "----------------------------------------------------------------        ----------------------------------------------------------------"
                "Bytes                                           Ascii                   Bytes                                           Ascii"
                "-----                                           -----                   -----                                           -----"
                "[31m  [0m [31m  [0m [31m  [0m [31m  [0m [31m  [0m [31m  [0m                               [31m [0m[31m [0m[31m [0m[31m [0m[31m [0m[31m [0m             !=   [31m4C[0m [31m69[0m [31m6E[0m [31m65[0m [31m20[0m [31m33[0m                               [31mL[0m[31mi[0m[31mn[0m[31me[0m[31m [0m[31m3[0m          "
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
                "Expected:[0m                                                               But was:[0m"
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
                    "Expected:[0m                                                               But was:[0m"
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
                    "Expected:[0m                                                               But was:[0m"
                    "----------------------------------------------------------------        ----------------------------------------------------------------"
                    "Bytes                                           Ascii                   Bytes                                           Ascii"
                    "-----                                           -----                   -----                                           -----"
                    "54 68 69 73 20 69 73 20 61 [31m20[0m [31m74[0m [31m65[0m [31m73[0m [31m74[0m [31m  [0m [31m  [0m This is a[31m [0m[31mt[0m[31me[0m[31ms[0m[31mt[0m[31m [0m[31m [0m   !    54 68 69 73 20 69 73 20 61 [31m6E[0m [31m6F[0m [31m74[0m [31m68[0m [31m65[0m [31m72[0m [31m20[0m This is a[31mn[0m[31mo[0m[31mt[0m[31mh[0m[31me[0m[31mr[0m[31m [0m"
                    "[31m  [0m [31m  [0m [31m  [0m [31m  [0m                                     [31m [0m[31m [0m[31m [0m[31m [0m               !    [31m74[0m [31m65[0m [31m73[0m [31m74[0m                                     [31mt[0m[31me[0m[31ms[0m[31mt[0m            "
                )
            }
        }

        Context 'When expected and actual value contain line breaks and new line' {
            It 'Should output to console' {
                $expected = "This is`r`na test"
                $actual = "This Is`r`nAnother`r`nTest"

                $result = Out-Difference -Reference $expected -Difference $actual

                $result | Should-BeBlockString @(
                    "Expected:[0m                                                               But was:[0m"
                    "----------------------------------------------------------------        ----------------------------------------------------------------"
                    "Bytes                                           Ascii                   Bytes                                           Ascii"
                    "-----                                           -----                   -----                                           -----"
                    "54 68 69 73 20 [31m69[0m 73 0D 0A [31m61[0m [31m20[0m [31m74[0m [31m65[0m [31m73[0m [31m74[0m [31m  [0m This [31mi[0ms␍␊[31ma[0m[31m [0m[31mt[0m[31me[0m[31ms[0m[31mt[0m[31m [0m   !=   54 68 69 73 20 [31m49[0m 73 0D 0A [31m41[0m [31m6E[0m [31m6F[0m [31m74[0m [31m68[0m [31m65[0m [31m72[0m This [31mI[0ms␍␊[31mA[0m[31mn[0m[31mo[0m[31mt[0m[31mh[0m[31me[0m[31mr[0m"
                    "[31m  [0m [31m  [0m [31m  [0m [31m  [0m [31m  [0m [31m  [0m                               [31m [0m[31m [0m[31m [0m[31m [0m[31m [0m[31m [0m             !=   [31m0D[0m [31m0A[0m [31m54[0m [31m65[0m [31m73[0m [31m74[0m                               [31m␍[0m[31m␊[0m[31mT[0m[31me[0m[31ms[0m[31mt[0m          "
                )
            }
        }

        Context 'When expected and actual value just different in case sensitivity' {
            It 'Should output to console' {
                $expected = @('Test','a','b')
                $actual = @('test','a','b')

                $result = Out-Difference -Reference $expected -Difference $actual

                $result | Should-BeBlockString @(
                    "Expected:[0m                                                               But was:[0m"
                    "----------------------------------------------------------------        ----------------------------------------------------------------"
                    "Bytes                                           Ascii                   Bytes                                           Ascii"
                    "-----                                           -----                   -----                                           -----"
                    "[31m54[0m 65 73 74                                     [31mT[0mest               !=   [31m74[0m 65 73 74                                     [31mt[0mest            "
                    "Expected:[0m                                                               But was:[0m"
                    "----------------------------------------------------------------        ----------------------------------------------------------------"
                    "Bytes                                           Ascii                   Bytes                                           Ascii"
                    "-----                                           -----                   -----                                           -----"
                    "61                                              a                  ==   61                                              a               "
                    "Expected:[0m                                                               But was:[0m"
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
                    "Expected:[0m                                                               But was:[0m"
                    "----------------------------------------------------------------        ----------------------------------------------------------------"
                    "Bytes                                           Ascii                   Bytes                                           Ascii"
                    "-----                                           -----                   -----                                           -----"
                    "[31m54[0m 65 73 74 61 62                               [31mT[0mestab             !=   [31m74[0m 65 73 74 61 62                               [31mt[0mestab          "
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
                "Expected:[0m                                                               But was:[0m"
                "----------------------------------------------------------------        ----------------------------------------------------------------"
                "Bytes                                           Ascii                   Bytes                                           Ascii"
                "-----                                           -----                   -----                                           -----"
                "54 68 69 73 20 69 73 20 61 20 74 65 73 74 20 73 This is a test s   ==   54 68 69 73 20 69 73 20 61 20 74 65 73 74 20 73 This is a test s"
                "74 72 69 6E 67 [31m20[0m [31m74[0m [31m68[0m [31m61[0m [31m74[0m [31m20[0m [31m69[0m [31m73[0m [31m20[0m [31m71[0m [31m75[0m tring[31m [0m[31mt[0m[31mh[0m[31ma[0m[31mt[0m[31m [0m[31mi[0m[31ms[0m[31m [0m[31mq[0m[31mu[0m   !=   74 72 69 6E 67 [31m  [0m [31m  [0m [31m  [0m [31m  [0m [31m  [0m [31m  [0m [31m  [0m [31m  [0m [31m  [0m [31m  [0m [31m  [0m tring[31m [0m[31m [0m[31m [0m[31m [0m[31m [0m[31m [0m[31m [0m[31m [0m[31m [0m[31m [0m[31m [0m"
                "[31m69[0m [31m74[0m [31m65[0m [31m20[0m [31m6C[0m [31m6F[0m [31m6E[0m [31m67[0m                         [31mi[0m[31mt[0m[31me[0m[31m [0m[31ml[0m[31mo[0m[31mn[0m[31mg[0m           !=   [31m  [0m [31m  [0m [31m  [0m [31m  [0m [31m  [0m [31m  [0m [31m  [0m [31m  [0m                         [31m [0m[31m [0m[31m [0m[31m [0m[31m [0m[31m [0m[31m [0m[31m [0m        "
            )
        }
    }

    Context 'When expected and actual value contain special characters' {
        It 'Should output to console' {
            $expected = 'This is a test string with special characters: !@#$%^&*()'
            $actual = 'This is a test string with special characters: !@#$%^&*()'

            $result = Out-Difference -Reference $expected -Difference $actual

            $result | Should-BeBlockString @(
                "Expected:[0m                                                               But was:[0m"
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
                "Expected:[0m                                                               But was:[0m"
                "----------------------------------------------------------------        ----------------------------------------------------------------"
                "Bytes                                           Ascii                   Bytes                                           Ascii"
                "-----                                           -----                   -----                                           -----"
                "53 74 72 69 6E 67                               String             ==   53 74 72 69 6E 67                               String          "
                "Expected:[0m                                                               But was:[0m"
                "----------------------------------------------------------------        ----------------------------------------------------------------"
                "Bytes                                           Ascii                   Bytes                                           Ascii"
                "-----                                           -----                   -----                                           -----"
                "[31m31[0m [31m32[0m [31m33[0m                                        [31m1[0m[31m2[0m[31m3[0m                !=   [31m34[0m [31m35[0m [31m36[0m                                        [31m4[0m[31m5[0m[31m6[0m             "
                "Expected:[0m                                                               But was:[0m"
                "----------------------------------------------------------------        ----------------------------------------------------------------"
                "Bytes                                           Ascii                   Bytes                                           Ascii"
                "-----                                           -----                   -----                                           -----"
                "41 6E 6F 74 68 65 72 20 53 74 72 69 6E 67       Another String     ==   41 6E 6F 74 68 65 72 20 53 74 72 69 6E 67       Another String  "
            )
        }
    }

    Context 'When expected and actual value contain Unicode characters' {
        It 'Should output to console' {
            $expected = 'This is a test string with Unicode: 你好, Привіт, hello' # cSpell: disable-line
            $actual = 'This is a test string with Unicode: 你好, Привіт, hello' # cSpell: disable-line

            $result = Out-Difference -Reference $expected -Difference $actual

            $result | Should-BeBlockString @(
                "Expected:[0m                                                               But was:[0m"
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
                "Expected:[0m                                                               But was:[0m"
                "----------------------------------------------------------------        ----------------------------------------------------------------"
                "Bytes                                           Ascii                   Bytes                                           Ascii"
                "-----                                           -----                   -----                                           -----"
                "65 73 63 61 70 65 64 20 63 68 61 72 61 63 74 65 escaped characte   ==   65 73 63 61 70 65 64 20 63 68 61 72 61 63 74 65 escaped characte"
                "72 73 3A 20 00 20 07 20 08 20 0C 20 0A 20 0D 20 rs: ␀ ␇ ␈ ␌ ␊ ␍    ==   72 73 3A 20 00 20 07 20 08 20 0C 20 0A 20 0D 20 rs: ␀ ␇ ␈ ␌ ␊ ␍ "
                "09                                              ␉                  ==   09                                              ␉               "
            )
        }
    }
}
