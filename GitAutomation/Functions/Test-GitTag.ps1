
function Test-GitTag
{
    <#
    .SYNOPSIS
    Tests if a tag exists in a Git repository.

    .DESCRIPTION
    The `Test-GitTag function tests if a tag exists in a Git repository.

    If a tag exists, returns $true; otherwise $false. Pass the name of the tag to check for to the `Name` parameter.

    .EXAMPLE
    Test-GitTag -Name 'Hello'

    Demonstrates how to check if the tag 'Hello' exists in the current directory.
    #>

    [CmdletBinding()]
    param(
        [string]
        # Specifies which git repository to check. Defaults to the current directory.
        $RepoRoot = (Get-Location).ProviderPath,

        [Parameter(Mandatory=$true)]
        [string]
        # The name of the tag to check for.
        $Name
    )

    Set-StrictMode -Version 'Latest'

    $tag = Get-GitTag -RepoRoot $RepoRoot -Name $Name |
                Where-Object { $_.Name -eq $Name }

    return ($tag -ne $null)
}