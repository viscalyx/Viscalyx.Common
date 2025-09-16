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
        System.Collections.Generic.IEnumerable`1[[System.Management.Automation.Language.TypeDefinitionAst]]

        Returns a collection of TypeDefinitionAst objects representing the class
        definitions found in the script file. Returns an empty collection if no
        classes are found or when filtering for a non-existent class name.
#>
function Get-ClassAst
{
    [CmdletBinding()]
    [OutputType([System.Collections.Generic.IEnumerable`1[[System.Management.Automation.Language.Ast]]])]
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

    # Check if the script file exists
    if (-not (Test-Path -Path $ScriptFile -PathType Leaf))
    {
        $PSCmdlet.ThrowTerminatingError(
            [System.Management.Automation.ErrorRecord]::new(
                ($script:localizedData.Get_ClassAst_ScriptFileNotFound -f $ScriptFile),
                'GCA0005', # cspell: disable-line
                [System.Management.Automation.ErrorCategory]::ObjectNotFound,
                $ScriptFile
            )
        )
    }

    $tokens = $null
    $parseErrors = $null

    $ast = [System.Management.Automation.Language.Parser]::ParseFile($ScriptFile, [ref] $tokens, [ref] $parseErrors)

    if ($parseErrors)
    {
        $PSCmdlet.ThrowTerminatingError(
            [System.Management.Automation.ErrorRecord]::new(
                ($script:localizedData.Get_ClassAst_ParseFailed -f $ScriptFile, ($parseErrors -join '; ')),
                'GCA0006', # cspell: disable-line
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
            param
            (
                [Parameter()]
                $Node
            )

            $Node -is [System.Management.Automation.Language.TypeDefinitionAst] -and $Node.IsClass -and $Node.Name -eq $ClassName
        }
    }
    else
    {
        Write-Debug -Message $script:localizedData.Get_ClassAst_ReturningAllClasses

        # Get all class resources.
        $astFilter = {
            param
            (
                [Parameter()]
                $Node
            )

            $Node -is [System.Management.Automation.Language.TypeDefinitionAst] -and $Node.IsClass
        }
    }

    $classAst = $ast.FindAll($astFilter, $true)

    Write-Debug -Message ($script:localizedData.Get_ClassAst_FoundClassCount -f $classAst.Count)

    return $classAst
}
