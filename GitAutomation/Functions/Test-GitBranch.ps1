
function Test-GitBranch
{
    <#
    .SYNOPSIS
    Checks if a branch exists in a Git repository.

    .DESCRIPTION
    The `Test-GitBranch` command tests if a branch exists in a Git repository. It returns $true if a branch exists; $false otherwise.
    
    Pass the branch name to test to the `Name` parameter

    .EXAMPLE
    Test-GitBranch -Name 'develop'

    Demonstrates how to check if the 'develop' branch exists in the current directory.

    .EXAMPLE
    Test-GitBranch -RepoRoot 'C:\Projects\GitAutomation' -Name 'develop'

    Demonstrates how to check if the 'develop' branch exists in a specific repository.
    #>
    [CmdletBinding()]
    param(
        [string]
        # Specifies which git repository to check. Defaults to the current directory.
        $RepoRoot = (Get-Location).ProviderPath,

        [Parameter(Mandatory=$true)]
        [string]
        # The name of the branch.
        $Name
    )

    Set-StrictMode -Version 'Latest'

    $branch = Get-GitBranch -RepoRoot $RepoRoot | Where-Object { $_.Name -ceq $Name }
    if( $branch )
    {
        return $true
    }
    else
    {
        return $false
    }
    
}