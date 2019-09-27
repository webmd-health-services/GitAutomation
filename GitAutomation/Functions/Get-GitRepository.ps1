
function Get-GitRepository
{
    <#
    .SYNOPSIS
    Gets an object representing a Git repository.

    .DESCRIPTION
    The `Get-GitRepository` function gets a `LibGit2Sharp.Repository` object representing a Git repository. By default, it gets the current directory's repository. You can get an object for a specific repository using the `RepoRoot` parameter. If the `RepoRoot` path doesn't point to the root of a Git repository, or, if not using the `RepoRoot` parameter and the current directory isn't the root of a Git repository, you'll get an error.

    The repository object contains resources that don't get automatically removed from memory by .NET. To avoid memory leaks, you must call its `Dispose()` method when you're done using it.

    .EXAMPLE
    Get-GitRepository

    Demonstrates how to get a `LibGit2Sharp.Repository` object for the repository in the current directory.

    .EXAMPLE
    Get-GitRepository -RepoRoot 'C:\Projects\GitAutomation'

    Demonstrates how to get a `LibGit2Sharp.Repository` object for a specific repository.
    #>
    [CmdletBinding()]
    [OutputType([LibGit2Sharp.Repository])]
    param(
        [string]
        # The root to the repository to get. Defaults to the current directory.
        $RepoRoot = (Get-Location).ProviderPath
    )

    Set-StrictMode -Version 'Latest'

    $RepoRoot = Resolve-Path -Path $RepoRoot -ErrorAction Ignore | Select-Object -ExpandProperty 'ProviderPath'
    if( -not $RepoRoot )
    {
        Write-Error -Message ('Repository ''{0}'' does not exist.' -f $PSBoundParameters['RepoRoot'])
        return
    }

    try
    {
        New-Object 'LibGit2Sharp.Repository' ($RepoRoot)
    }
    catch
    {
        Write-Error -ErrorRecord $_
    }
}