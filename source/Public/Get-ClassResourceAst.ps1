<#
    .SYNOPSIS
        Gets DSC class resource definitions from a PowerShell script file using AST parsing.

    .DESCRIPTION
        The Get-ClassResourceAst function parses a PowerShell script file and extracts
        DSC class resource definitions using Abstract Syntax Tree (AST) parsing. It filters
        for classes that have the [DscResource()] attribute. It can return all DSC class
        resources in the file or filter for a specific class by name.

    .PARAMETER Path
        The path(s) to the PowerShell script file(s) to parse. Accepts pipeline input
        from strings (file paths).

    .PARAMETER ScriptFile
        FileInfo object(s) representing the PowerShell script file(s) to parse.
        Accepts pipeline input from Get-ChildItem and other commands that return FileInfo objects.

    .PARAMETER ClassName
        Optional parameter to filter for a specific DSC class resource by name. If not provided,
        all DSC class resources in the script file are returned.

    .EXAMPLE
        Get-ClassResourceAst -Path 'C:\Scripts\MyDscResources.ps1'

        Returns all DSC class resource definitions found in the specified script file.

    .EXAMPLE
        Get-ClassResourceAst -Path 'C:\Scripts\MyDscResources.ps1' -ClassName 'MyDscResource'

        Returns only the 'MyDscResource' DSC class resource definition from the specified script file.

    .EXAMPLE
        'C:\Scripts\Resource1.ps1', 'C:\Scripts\Resource2.ps1' | Get-ClassResourceAst

        Returns all DSC class resource definitions found in the specified script files using pipeline input.

    .EXAMPLE
        Get-ChildItem -Path 'C:\Scripts\*.ps1' | Get-ClassResourceAst -ClassName 'MyDscResource'

        Returns 'MyDscResource' DSC class resource definitions from all PowerShell script files in the specified directory.

    .INPUTS
        System.String[]

        You can pipe file paths as strings to this function.

    .INPUTS
        System.IO.FileInfo[]

        You can pipe FileInfo objects to this function.

    .OUTPUTS
        System.Collections.Generic.IEnumerable`1[[System.Management.Automation.Language.Ast]]

        Returns a collection of AST nodes (items are TypeDefinitionAst) representing
        the DSC class resource definitions found in the script file. Returns an empty collection
        if no DSC class resources are found or when filtering for a non-existent class name.
#>
function Get-ClassResourceAst
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('UseSyntacticallyCorrectExamples', '', Justification = 'Because the examples are syntactically correct. The rule does not seem to understand that there is pipeline input.')]
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

    process
    {
        # Use Get-ClassAst to get all classes, then filter for DSC resources
        $classAstResults = if ($PSCmdlet.ParameterSetName -eq 'String')
        {
            Get-ClassAst -Path $Path -ClassName $ClassName
        }
        else
        {
            Get-ClassAst -ScriptFile $ScriptFile -ClassName $ClassName
        }

        # Filter the results to only include DSC resources (classes with [DscResource()] attribute)
        $dscClassResourceAst = $classAstResults | Where-Object {
            $_.Attributes.Extent.Text -imatch '\[DscResource\(.*\)\]'
        }

        Write-Debug -Message ($script:localizedData.Get_ClassResourceAst_FoundClassCount -f $dscClassResourceAst.Count)

        # Output the results
        $dscClassResourceAst
    }
}