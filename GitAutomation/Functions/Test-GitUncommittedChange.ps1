
function Test-GitUncommittedChange
{
     <#
    .SYNOPSIS
    Tests for uncommitted changes in a git repository.

    .DESCRIPTION
    The `Test-GitUncommittedChange` function checks for any uncommited changes in a git repository.

    It defaults to the current repository and only the current branch. Use the `RepoRoot` parameter to specify an explicit path to another repo.

    Implements the `git diff --exit-code` command ( No output if no uncommitted changes, otherwise output diff )

    .EXAMPLE
    Test-GitUncommittedChange -RepoRoot 'C:\Projects\GitAutomation'

    Demonstrates how to check for uncommitted changes in a repository that isn't the current directory.
    #>

    [CmdletBinding()]
    param(
        [string]
        # The repository to check for uncommitted changes. Defaults to current directory
        $RepoRoot = (Get-Location).ProviderPath
    )

    Set-StrictMode -Version 'Latest'

    if( Get-GitRepositoryStatus -RepoRoot $RepoRoot )
    {
        return $true
    }
 
    return $false   
}