<#
    .SYNOPSIS
        Invokes a git command.

    .DESCRIPTION
        Invokes a git command with command line arguments using System.Diagnostics.Process.

        Throws an error when git ExitCode -ne 0 and -PassThru switch -eq $false (or omitted).

    .PARAMETER WorkingDirectory
        The path to the git working directory.

    .PARAMETER Timeout
        Milliseconds to wait for process to exit.

    .PARAMETER PassThru
        Switch parameter when enabled will return result object of running git command.

    .PARAMETER Arguments
        The arguments to pass to the Git executable.

    .EXAMPLE
        Invoke-Git -WorkingDirectory 'C:\SomeDirectory' -Arguments @( 'clone', 'https://github.com/X-Guardian/xActiveDirectory.wiki.git', '--quiet' )

        Invokes the Git executable to clone the specified repository to the working directory.

    .EXAMPLE
        Invoke-Git -WorkingDirectory 'C:\SomeDirectory' -Arguments @( 'status' ) -TimeOut 10000 -PassThru

        Invokes the Git executable to return the status while having a 10000 millisecond timeout.

    .EXAMPLE
        $result = Invoke-Git -WorkingDirectory 'C:\SomeDirectory' -Arguments @( 'status' ) -PassThru

        Invokes the Git executable to return the status and stores the result in the $result variable.

        The $result variable will contain a hashtable with the following keys:
            ExitCode
            StandardOutput
            StandardError

    .EXAMPLE
        Invoke-Git -WorkingDirectory $script:testRepoPath -Arguments @('config', 'user.name', '"Test User"')

        Configures the git user name for the repository located in $script:testRepoPath.
#>
function Invoke-Git
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $WorkingDirectory,

        [Parameter()]
        [System.Int32]
        $TimeOut = 120000,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $PassThru,

        [Parameter(ValueFromRemainingArguments = $true)]
        [System.String[]]
        $Arguments
    )

    $gitResult = @{
        'ExitCode'         = -1
        'Output'           = $null
        'StandardError'    = $null
    }

    # TODO: If an argument in the array contains a space, it needs to be quoted with double quotes unless it's already quoted.

    Write-Verbose -Message ($script:localizedData.Invoke_Git_InvokingGitMessage -f (Hide-GitToken -InputString $Arguments))

    try
    {
        $process = New-Object -TypeName System.Diagnostics.Process
        $process.StartInfo.Arguments = $Arguments
        $process.StartInfo.CreateNoWindow = $true
        $process.StartInfo.FileName = 'git'
        $process.StartInfo.RedirectStandardOutput = $true
        $process.StartInfo.RedirectStandardError = $true
        $process.StartInfo.UseShellExecute = $false
        $process.StartInfo.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Hidden
        $process.StartInfo.WorkingDirectory = $WorkingDirectory

        if ($process.Start() -eq $true)
        {
            if ($process.WaitForExit($TimeOut) -eq $true)
            {
                $gitResult.ExitCode = $process.ExitCode
                $gitResult.Output = $process.StandardOutput.ReadToEnd().Trim() # Trim to remove trailing newline
                $gitResult.StandardError = $process.StandardError.ReadToEnd()
            }
        }
    }
    catch
    {
        throw $_
    }
    finally
    {
        if ($process)
        {
            $process.Dispose()
        }

        if ($VerbosePreference -ne 'SilentlyContinue' -or `
            $DebugPreference -ne 'SilentlyContinue' -or `
            $PSBoundParameters['Verbose'] -eq $true -or `
            $PSBoundParameters['Debug'] -eq $true)
        {
            Write-Verbose -Message ($script:localizedData.Invoke_Git_StandardOutputMessage -f $gitResult.Output)
            Write-Verbose -Message ($script:localizedData.Invoke_Git_StandardErrorMessage -f $gitResult.StandardError)
            Write-Verbose -Message ($script:localizedData.Invoke_Git_ExitCodeMessage -f $gitResult.ExitCode)

            Write-Debug -Message ($script:localizedData.Invoke_Git_CommandDebug -f ('git {0}' -f (Hide-GitToken -InputString $Arguments)))
            Write-Debug -Message ($script:localizedData.Invoke_Git_WorkingDirectoryDebug -f $WorkingDirectory)
        }

        if ($gitResult.ExitCode -ne 0 -and $PassThru -eq $false)
        {
            $throwMessage = "$($script:localizedData.Invoke_Git_CommandDebug -f ('git {0}' -f (Hide-GitToken -InputString $Arguments)))`n" +`
                            "$($script:localizedData.Invoke_Git_ExitCodeMessage -f $gitResult.ExitCode)`n" +`
                            "$($script:localizedData.Invoke_Git_StandardOutputMessage -f $gitResult.Output)`n" +`
                            "$($script:localizedData.Invoke_Git_StandardErrorMessage -f $gitResult.StandardError)`n" +`
                            "$($script:localizedData.Invoke_Git_WorkingDirectoryDebug -f $WorkingDirectory)`n"

            throw $throwMessage
        }
    }

    if ($PassThru.IsPresent)
    {
        return $gitResult
    }
}
