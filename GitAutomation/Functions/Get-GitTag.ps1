
function Get-GitTag{
    <#
    .SYNOPSIS
    Gets the tags in a Git repository.

    .DESCRIPTION
    The `Get-GitTag` function returns a list of all the tags in a Git repository.

    To get a specific tag, pass its name to the `Name` parameter. Wildcard characters are supported in the tag name. Only tags that match the wildcard pattern will be returned.

    .EXAMPLE
    Get-GitTag

    Demonstrates how to get all the tags in a repository.

    .EXAMPLE
    Get-GitTag -Name 'LastSuccessfulBuild'

    Demonstrates how to return a specific tag.  If no tag matches, then `$null` is returned.

    .EXAMPLE
    Get-GitTag -Name '13.8.*' -RepoRoot 'C:\Projects\GitAutomation'

    Demonstrates how to return all tags that match a wildcard in the given repository.'
    #>


   [CmdletBinding()]
   [OutputType([Git.Automation.TagInfo])]
    param(
        [string]
        # Specifies which git repository to check. Defaults to the current directory.
        $RepoRoot = (Get-Location).ProviderPath,

        [string]
        # The name of the tag to return. Wildcards accepted.
        $Name
    )

    Set-StrictMode -Version 'Latest'

    $repo = Find-GitRepository -Path $RepoRoot -Verify
    if( -not $repo )
    {
        return
    }

    try
    {
        $repo.Tags | ForEach-Object {
            New-Object Git.Automation.TagInfo $_
            } |
            Where-Object {
                if( $PSBoundParameters.ContainsKey('Name') )
                {
                    return $_.Name -like $Name
                }
                return $true
            }
    }
    finally
    {
        $repo.Dispose()
    }
}