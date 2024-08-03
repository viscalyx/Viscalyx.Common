<#
    .SYNOPSIS
        The localized resource strings in English (en-US). This file should only
        contain localized strings for private functions, public command, and
        classes (that are not a DSC resource).
#>

ConvertFrom-StringData @'
    ## Remove-History
    Convert_PesterSyntax_ShouldProcessVerboseDescription = Converting the script file '{0}'.
    Convert_PesterSyntax_ShouldProcessVerboseWarning = Are you sure you want to convert the script file '{0}'?
    # This string shall not end with full stop (.) since it is used as a title of ShouldProcess messages.
    Convert_PesterSyntax_ShouldProcessCaption = Convert script file
'@
