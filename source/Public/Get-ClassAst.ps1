<#
    .SYNOPSIS
        Gets class definitions from a PowerShell script file using AST parsing.

    .DESCRIPTION
        The Get-ClassAst function parses a PowerShell script file and extracts
        class definitions using Abstract Syntax Tree (AST) parsing. It can return
        all classes in the file or filter for a specific class by name.

    .PARAMETER Path
        The path(s) to the PowerShell script file(s) to parse. Accepts pipeline input
        from strings (file paths).

    .PARAMETER ScriptFile
        FileInfo object(s) representing the PowerShell script file(s) to parse. 
        Accepts pipeline input from Get-ChildItem and other commands that return FileInfo objects.

    .PARAMETER ClassName
        Optional parameter to filter for a specific class by name. If not provided,
        all classes in the script file are returned.

    .EXAMPLE
        Get-ClassAst -Path 'C:\Scripts\MyClasses.ps1'

        Returns all class definitions found in the specified script file.

    .EXAMPLE
        Get-ClassAst -Path 'C:\Scripts\MyClasses.ps1' -ClassName 'MyDscResource'

        Returns only the 'MyDscResource' class definition from the specified script file.

    .EXAMPLE
        'C:\Scripts\Class1.ps1', 'C:\Scripts\Class2.ps1' | Get-ClassAst

        Returns all class definitions found in the specified script files using pipeline input.

    .EXAMPLE
        Get-ChildItem -Path 'C:\Scripts\*.ps1' | Get-ClassAst -ClassName 'MyDscResource'

        Returns 'MyDscResource' class definitions from all PowerShell script files in the specified directory.

    .INPUTS
        System.String[]

        You can pipe file paths as strings to this function.

    .INPUTS
        System.IO.FileInfo[]

        You can pipe FileInfo objects to this function.

    .OUTPUTS
        System.Collections.Generic.IEnumerable`1[[System.Management.Automation.Language.TypeDefinitionAst]]

        Returns a collection of TypeDefinitionAst objects representing the class
        definitions found in the script file. Returns an empty collection if no
        classes are found or when filtering for a non-existent class name.
#>
function Get-ClassAst
{
    [CmdletBinding(DefaultParameterSetName = 'String')]
    [OutputType([System.Collections.Generic.IEnumerable`1[[System.Management.Automation.Language.Ast]]])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = 'String')]
        [System.String[]]
        $Path,

        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = 'FileInfo')]
        [System.IO.FileInfo[]]
        $ScriptFile,

        [Parameter()]
        [System.String]
        $ClassName
    )

    begin
    {
        # Initialize the AST filter once in the begin block
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
    }

    process
    {
        # Determine which parameter set is being used and get the appropriate file collection
        if ($PSCmdlet.ParameterSetName -eq 'String')
        {
            $filesToProcess = $Path
        }
        else
        {
            $filesToProcess = $ScriptFile
        }

        foreach ($file in $filesToProcess)
        {
            # Convert FileInfo objects to string paths, or use string directly
            if ($file -is [System.IO.FileInfo])
            {
                $filePath = $file.FullName
            }
            else
            {
                # String is expected for the String parameter set
                $filePath = $file
            }

            Write-Debug -Message ($script:localizedData.Get_ClassAst_ParsingScriptFile -f $filePath)

            # Check if the script file exists
            if (-not (Test-Path -Path $filePath -PathType Leaf))
            {
                $PSCmdlet.ThrowTerminatingError(
                    [System.Management.Automation.ErrorRecord]::new(
                        ($script:localizedData.Get_ClassAst_ScriptFileNotFound -f $filePath),
                        'GCA0005', # cspell: disable-line
                        [System.Management.Automation.ErrorCategory]::ObjectNotFound,
                        $filePath
                    )
                )
            }

            $tokens = $null
            $parseErrors = $null

            $ast = [System.Management.Automation.Language.Parser]::ParseFile($filePath, [ref] $tokens, [ref] $parseErrors)

            if ($parseErrors)
            {
                $PSCmdlet.ThrowTerminatingError(
                    [System.Management.Automation.ErrorRecord]::new(
                        ($script:localizedData.Get_ClassAst_ParseFailed -f $filePath, ($parseErrors -join '; ')),
                        'GCA0006', # cspell: disable-line
                        [System.Management.Automation.ErrorCategory]::ParserError,
                        $filePath
                    )
                )
            }

            $classAst = $ast.FindAll($astFilter, $true)

            Write-Debug -Message ($script:localizedData.Get_ClassAst_FoundClassCount -f $classAst.Count)

            # Output the results for this file
            $classAst
        }
    }
}
