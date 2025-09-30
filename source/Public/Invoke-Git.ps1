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

    .INPUTS
        None. This function does not accept pipeline input.

    .OUTPUTS
        System.Collections.Hashtable

        Returns a hashtable when PassThru parameter is specified containing ExitCode, StandardOutput, and StandardError.

    .EXAMPLE
        Invoke-Git -WorkingDirectory 'C:\SomeDirectory' -Arguments @( 'clone', 'https://github.com/X-Guardian/xActiveDirectory.wiki.git', '--quiet' )

        Invokes the Git executable to clone the specified repository to the working directory.

    .EXAMPLE
        Invoke-Git -WorkingDirectory 'C:\SomeDirectory' -Arguments @( 'status' ) -Timeout 10000 -PassThru

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
        $Timeout = 120000,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $PassThru,

        [Parameter(ValueFromRemainingArguments = $true)]
        [System.String[]]
        $Arguments
    )

    $gitResult = @{
        ExitCode        = -1
        StandardOutput  = $null
        StandardError   = $null
    }

    # Process arguments to add quotes around arguments containing spaces if not already quoted
    $processedArguments = foreach ($argument in $Arguments)
    {
        if ($argument -match '\s' -and $argument -notmatch '^".*"$')
        {
            '"{0}"' -f $argument
        }
        else
        {
            $argument
        }
    }

    Write-Verbose -Message ($script:localizedData.Invoke_Git_InvokingGitMessage -f (Hide-GitToken -InputString $processedArguments))

    try
    {
        $process = New-Object -TypeName System.Diagnostics.Process
        $process.StartInfo.Arguments = $processedArguments
        $process.StartInfo.CreateNoWindow = $true
        $process.StartInfo.FileName = 'git'
        $process.StartInfo.RedirectStandardOutput = $true
        $process.StartInfo.RedirectStandardError = $true
        $process.StartInfo.UseShellExecute = $false
        $process.StartInfo.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Hidden
        $process.StartInfo.WorkingDirectory = $WorkingDirectory

        if ($process.Start() -eq $true)
        {
            $processTimedOut = $false

            if ($process.WaitForExit($Timeout) -eq $false)
            {
                # Timeout occurred - kill the process if it's still running
                $processTimedOut = $true

                if (-not $process.HasExited)
                {
                    try
                    {
                        $process.Kill()
                        # Wait for process to fully terminate after kill
                        [void] $process.WaitForExit()
                    }
                    catch
                    {
                        # Process may have exited between HasExited check and Kill()
                        Write-Verbose -Message ($script:localizedData.Invoke_Git_KillProcessFailed -f $_.Exception.Message)
                    }
                }
            }

            # Read streams after process has exited (normal or after timeout)
            try
            {
                $gitResult.StandardError = $process.StandardError.ReadToEnd()
                $rawOutput = $process.StandardOutput.ReadToEnd()

                $gitResult.StandardOutput = foreach ($line in ($rawOutput -split '\r?\n'))
                {
                    $trimmed = $line.Trim()
                    if (-not [System.String]::IsNullOrEmpty($trimmed))
                    {
                        $trimmed
                    }
                }
            }
            catch
            {
                # If stream reading fails, set empty values
                $gitResult.StandardError = ''
                $gitResult.StandardOutput = @()
            }

            # Set exit code and throw error if timeout occurred
            if ($processTimedOut)
            {
                $gitResult.ExitCode = -1

                $errorMessage = $script:localizedData.Invoke_Git_TimeoutError -f $Timeout, (Hide-GitToken -InputString $processedArguments)

                $PSCmdlet.ThrowTerminatingError(
                    [System.Management.Automation.ErrorRecord]::new(
                        [System.InvalidOperationException]::new($errorMessage),
                        'IG0007',
                        [System.Management.Automation.ErrorCategory]::OperationTimeout,
                        $Arguments
                    )
                )
            }
            else
            {
                $gitResult.ExitCode = $process.ExitCode
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

        if (
            $VerbosePreference -ne 'SilentlyContinue' -or
            $DebugPreference -ne 'SilentlyContinue' -or
            $PSBoundParameters['Verbose'] -eq $true -or
            $PSBoundParameters['Debug'] -eq $true
        )
        {
            Write-Verbose -Message ($script:localizedData.Invoke_Git_StandardOutputMessage -f $gitResult.StandardOutput)
            Write-Verbose -Message ($script:localizedData.Invoke_Git_StandardErrorMessage -f $gitResult.StandardError)
            Write-Verbose -Message ($script:localizedData.Invoke_Git_ExitCodeMessage -f $gitResult.ExitCode)

            Write-Debug -Message ($script:localizedData.Invoke_Git_CommandDebug -f ('git {0}' -f (Hide-GitToken -InputString $processedArguments)))
            Write-Debug -Message ($script:localizedData.Invoke_Git_WorkingDirectoryDebug -f $WorkingDirectory)
        }

        if ($gitResult.ExitCode -ne 0 -and $PassThru -eq $false)
        {
            $errorMessage = $script:localizedData.Invoke_Git_CommandFailed -f $gitResult.ExitCode

            $detailsMessage = @(
                "$($script:localizedData.Invoke_Git_CommandDebug -f ('git {0}' -f (Hide-GitToken -InputString $processedArguments)))"
                "$($script:localizedData.Invoke_Git_StandardOutputMessage -f $gitResult.StandardOutput)"
                "$($script:localizedData.Invoke_Git_StandardErrorMessage -f $gitResult.StandardError)"
                "$($script:localizedData.Invoke_Git_WorkingDirectoryDebug -f $WorkingDirectory)"
            ) -join "`n"

            $exception = [System.InvalidOperationException]::new("$errorMessage`n$detailsMessage")
            $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                $exception,
                'IG0009',
                [System.Management.Automation.ErrorCategory]::InvalidOperation,
                $processedArguments
            )

            $PSCmdlet.ThrowTerminatingError($errorRecord)
        }
    }

    if ($PassThru.IsPresent)
    {
        return $gitResult
    }
}
