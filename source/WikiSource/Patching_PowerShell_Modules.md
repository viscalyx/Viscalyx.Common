# Patching PowerShell Modules

PowerShell modules are a fantastic way to organize and share reusable code.
However, there are times when you might need to make a small change to a module
without directly modifying its original source. This is especially useful when
dealing with third-party modules. This article guides you through patching a
PowerShell module, using `ModuleBuilder` as an example.

> [!CAUTION]
> This patching technique is intended as a temporary solution, primarily for
> development or pipeline environments, until the module's next official
> release. Always verify the contents of every patch file, even from trusted
> sources before applying it to a module. Applying a patch to a signed module
> will invalidate the signature.

## What is Module Patching?

Module patching involves applying targeted changes to a module's files
without altering the original files directly. This is useful for:

- Fixing minor bugs in third-party modules.
- Adding small features or tweaks.
- Applying temporary workarounds.

> [!IMPORTANT]
> **Backup:** Always back up the original module file before applying any
> patches. Verify every patch file before using them to patch a file.

## Prerequisites

- PowerShell 5.1 or later
- `Viscalyx.Common` module installed (containing the `Install-ModulePatch`
  command).

    ```powershell
    Install-Module -Name Viscalyx.Common -Force
    ```

- `ModuleBuilder` module installed. We'll use this as our example module.

    ```powershell
    Install-Module -Name ModuleBuilder -RequiredVersion 3.1.7 -Force
    ```

## Step 1: Identifying the Changes

Let's say we want to modify `ModuleBuilder` to fix a parse error that occurs
in Window PowerShell when `ModuleBuilder` handles SemVer versions. Specifically,
we need to adjust how the module parses the version string.

First, locate the `ModuleBuilder.psm1` file. You can find the path using:

```powershell
$moduleBase = (Get-Module -Name 'ModuleBuilder' -ListAvailable).ModuleBase
$moduleBase
```

This will output the directory where the `ModuleBuilder.psm1` file is located.

## Step 2: Finding the Text Offset

We need to pinpoint the exact location of the code we want to change. The
`Get-TextOffset` command from `Viscalyx.Common` helps us with this.

<!-- markdownlint-disable MD013 - Line length -->
```powershell
$filePath = Join-Path -Path $moduleBase -ChildPath 'ModuleBuilder.psm1'
$textToFind = '@{
            Version       = if (($V = $BuildInfo.SemVer.Split("+")[0].Split("-", 2)[0])) {
                                [version]$V
                            }
            Prerelease    = $BuildInfo.SemVer.Split("+")[0].Split("-", 2)[1]
            BuildMetadata = $BuildInfo.SemVer.Split("+", 2)[1]
        }'

$codeOffset = Get-TextOffset -FilePath $filePath -TextToFind $textToFind
$codeOffset | Format-List
```
<!-- markdownlint-enable MD013 - Line length -->

> [!NOTE]
> You have to copy the code section to find exactly as it is in the script
> file. Regular expressions are not yet supported. Also make sure to correctly
> escape any quotes in the string.

This command will output the `StartOffset` and `EndOffset` of the specified
text within the `ModuleBuilder.psm1` file.

**Example Output:**

<!-- markdownlint-disable MD013 - Line length -->
```plaintext
ScriptFile  : C:\Program Files\WindowsPowerShell\Modules\ModuleBuilder\3.1.7\ModuleBuilder.psm1
StartOffset : 21167
EndOffset   : 21484
```
<!-- markdownlint-enable MD013 - Line length -->

## Step 3: Finding the script file SHA256

To ensure we only patch the correct unpatched version, we need to find the
script file's SHA256 hash. The hash acts as a unique fingerprint for the
file. If the file is modified in any way, the SHA256 hash will change.

The `Get-FileHash` helps use retrieve the correct hash:

<!-- markdownlint-disable MD013 - Line length -->
```powershell
$hash256 = Get-FileHash -Path $filePath -Algorithm 'SHA256' | Select-Object -ExpandProperty 'Hash'
$hash256
```
<!-- markdownlint-enable MD013 - Line length -->

>[!NOTE]
> The `Get-ModuleFileSha` command from `Viscalyx.Common`can be used to
> output SHA256 hash for all the PowerShell script files in the specified
> module.

## Step 4: Creating the Patch File

Now, we'll create a JSON file that describes the patch. This file will contain
the module name, module version, the SHA256 hash of the original
script file, the SHA256 hash of the patched script file, and an array of
module patches. Each patch contains the script file name, the start and
end offsets of the original content, and the replacement content.

This will output the needed JSON for the json file:

<!-- markdownlint-disable MD013 - Line length -->
```powershell
# The code we use to replace the original content between start offset and end offset.
$patchCode = '@{
            Prerelease    = $BuildInfo.SemVer.Split("+")[0].Split("-", 2)[1]
            BuildMetadata = $BuildInfo.SemVer.Split("+", 2)[1]
            Version       = if (($V = $BuildInfo.SemVer.Split("+")[0].Split("-", 2)[0])) {
                [version]$V
            }
        }'

# Use an ordered hashtable so that the JSON output has the same order.
$patchObject = [ordered] @{
    ModuleName      = 'ModuleBuilder'
    ModuleVersion   = "3.1.7"
    ModuleFiles     = @(
        @{
            ScriptFileName = 'ModuleBuilder.psm1'
            OriginalHashSHA = $hash256
            ValidationHashSHA  = 'NEW_HASH_HERE' # Replace with the actual hash of the patched file
            FilePatches   = @(
                @{
                    StartOffset    = $codeOffset.StartOffset
                    EndOffset      = $codeOffset.EndOffset
                    PatchContent   = $patchCode
                }
            )
        }
    )
}

# Ensuring it's treated as an array. This works in both PowerShell 5.1 and 7.x.
ConvertTo-Json -InputObject @($patchObject) -Depth 10 |
    Out-File -FilePath './patches/ModuleBuilder_3.1.7_patch.json' -Encoding 'utf8' -NoClobber
```
<!-- markdownlint-enable MD013 - Line length -->

Here's an example `ModuleBuilder_3.1.7_patch.json` file:

<!-- markdownlint-disable MD013 - Line length -->
```json
{
  "ModuleName": "ModuleBuilder",
  "ModuleVersion": "3.1.7",
  "ModuleFiles": [
    {
      "ScriptFileName": "ModuleBuilder.psm1",
      "OriginalHashSHA": "4723258D788733FACED8BF20F60DFCBAD03E7AEB659D1B9C891DD9F86FEA2E73",
      "ValidationHashSHA": "4444D5073A54B838128FC53D61B87A40142E5181A38C593CC4BA728D6F1AD16B",
      "FilePatches": [
        {
          "StartOffset": 21167,
          "EndOffset": 21484,
          "PatchContent": "@{\n            Prerelease    = $BuildInfo.SemVer.Split(\"+\")[0].Split(\"-\", 2)[1]\n            BuildMetadata = $BuildInfo.SemVer.Split(\"+\", 2)[1]\n            Version       = if (($V = $BuildInfo.SemVer.Split(\"+\")[0].Split(\"-\", 2)[0])) {\n                [version]$V\n            }\n        }"
        }
      ]
    }
  ]
}
```
<!-- markdownlint-enable MD013 - Line length -->

- **ModuleName**: The name of the module (e.g. `ModuleBuilder`).
- **ModuleVersion**: The version of the module (e.g. `3.1.7`).
- **ModuleFiles**: An array of all the files that have patches
  - **ScriptFileName**: The name of the script file to patch, this can use
    the relative path from module base (e.g. `ModuleBuilder.psm1`, or
    `en-US/localized.strings.psd1`).
  - **OriginalHashSHA**: The SHA256 hash of the *original* content of the entire
    script file (e.g. `ModuleBuilder.psm1`, or `en-US/localized.strings.psd1`).
  - **ValidationHashSHA**: The SHA256 hash of the *patched* content of the entire
    script file (e.g. `ModuleBuilder.psm1`, or `en-US/localized.strings.psd1`).
  - **FilePatches**: An array of patches to apply to the script file.
    - **StartOffset**: The starting character position of the text to replace
      (e.g. 21167).
    - **EndOffset**: The ending character position of the text to replace
      (e.g. 21484).
    - **PatchContent**: The new (patch) content that will be replace the
      original content.

> [!IMPORTANT]
> The JSON file can contain multiple entries for the same script file or
> multiple script files within the same module and version. If you need
> to patch multiple modules or different module versions, create a separate
> JSON file for each unique module and version.

## Step 5: Applying the Patch

Now that we have our patch file, we can apply the patch using the `Install-ModulePatch`
command:

```powershell
Install-ModulePatch -Path './patches/ModuleBuilder_3.1.7_patch.json'
```

Replace the path with the actual path to your patch file. The `-Force`
parameter can be used to bypasses the confirmation prompt.

> [!NOTE]
> It also possible to use the parameter `-Uri` to get patches hosted on
> web pages or web services.

## Step 6: Verify the Patch

To verify the patch, you can check the content of the `ModuleBuilder.psm1`
file at the specified start offset.

## Conclusion

Patching PowerShell modules can be a useful technique for making targeted
changes without directly modifying the original module files. By following
these steps, you can effectively apply patches to enhance or fix installed
modules.
