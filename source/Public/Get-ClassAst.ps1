<#
    .SYNOPSIS
        Gets class definitions from a PowerShell script file using AST parsing.

    .DESCRIPTION
        The Get-ClassAst function parses a PowerShell script file and extracts
        class definitions using Abstract Syntax Tree (AST) parsing. It can return
        all classes in the file or filter for a specific class by name.

    .PARAMETER ScriptFile
        The path to the PowerShell script file to parse.

    .PARAMETER ClassName
        Optional parameter to filter for a specific class by name. If not provided,
        all classes in the script file are returned.

    .EXAMPLE
        Get-ClassAst -ScriptFile 'C:\Scripts\MyClasses.ps1'

        Returns all class definitions found in the specified script file.

    .EXAMPLE
        Get-ClassAst -ScriptFile 'C:\Scripts\MyClasses.ps1' -ClassName 'MyDscResource'

        Returns only the 'MyDscResource' class definition from the specified script file.

    .INPUTS
        None. You cannot pipe input to this function.

    .OUTPUTS
        [System.Management.Automation.Language.TypeDefinitionAst]

        Returns one or more TypeDefinitionAst objects representing the class
        definitions found in the script file.

#>
function Get-ClassAst
{
    [CmdletBinding()]
    [OutputType([System.Management.Automation.Language.TypeDefinitionAst])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $ScriptFile,

        [Parameter()]
        [System.String]
        $ClassName
    )

    Write-Debug -Message ($script:localizedData.Get_ClassAst_ParsingScriptFile -f $ScriptFile)

    $tokens = $null
    $parseErrors = $null

    $ast = [System.Management.Automation.Language.Parser]::ParseFile($ScriptFile, [ref] $tokens, [ref] $parseErrors)

    if ($parseErrors)
    {
        $PSCmdlet.ThrowTerminatingError(
            [System.Management.Automation.ErrorRecord]::new(
                ($parseErrors -join '; '),
                'ParseError',
                [System.Management.Automation.ErrorCategory]::ParserError,
                $ScriptFile
            )
        )
    }

    if ($PSBoundParameters.ContainsKey('ClassName') -and $ClassName)
    {
        Write-Debug -Message ($script:localizedData.Get_ClassAst_FilteringForClass -f $ClassName)

        # Get only the specific class resource.
        $astFilter = {
            $args[0] -is [System.Management.Automation.Language.TypeDefinitionAst] `
                -and $args[0].IsClass `
                -and $args[0].Name -eq $ClassName
        }
    }
    else
    {
        Write-Debug -Message $script:localizedData.Get_ClassAst_ReturningAllClasses

        # Get all class resources.
        $astFilter = {
            $args[0] -is [System.Management.Automation.Language.TypeDefinitionAst] `
                -and $args[0].IsClass
        }
    }

    $classAst = $ast.FindAll($astFilter, $true)

    Write-Debug -Message ($script:localizedData.Get_ClassAst_FoundClassCount -f $classAst.Count)

    return $classAst
}