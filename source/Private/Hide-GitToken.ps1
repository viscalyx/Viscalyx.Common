<#
    .SYNOPSIS
        Redacts token from Invoke-Git command.

    .DESCRIPTION
        Redacts the token from the specified git command so that the command can be safely outputted in logs.

    .PARAMETER Command
        Command passed to Invoke-Git

    .EXAMPLE
        Hide-GitToken -Command @( 'remote', 'add', 'origin', 'https://user:1b7270718ad84857b52941b36a632f369d18ff72@github.com/Owner/Repo.git' )

        Returns a string to be used for logs.
#>

function Hide-GitToken
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory=$true, Position = 0)]
        [AllowNull()]
        [AllowEmptyCollection()]
        [AllowEmptyString()]
        [System.String[]]
        $InputString
    )

    if ($null -ne $InputString)
    {
        [System.String] $InputString = $InputString -join ' '

        [System.String] $InputString = $InputString -replace "gh(p|o|u|s|r)_([A-Za-z0-9]{1,251})",'**REDACTED-TOKEN**'

        [System.String] $InputString = $InputString -replace "[0-9a-f]{40}",'**REDACTED-TOKEN**'
    }

    return $InputString
}
