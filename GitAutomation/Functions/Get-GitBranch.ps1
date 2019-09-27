
function Get-GitBranch
{
   <#
   .SYNOPSIS
   Gets the branches in a Git repository.
    
   .DESCRIPTION
   The `Get-GitBranch` function returns a list of all the branches in a repository.
    
   Use the `Current` switch to return just the current branch.

   It defaults to the current repository. Use the `RepoRoot` parameter to specify an explicit path to another repo.

   .EXAMPLE
   Get-GitBranch -RepoRoot 'C:\Projects\GitAutomation' -Current
    
   Returns an object representing the current branch for the specified repo.

   .EXAMPLE
   Get-GitBranch

   Returns objects for all the branches in the current directory.
   #>
   [CmdletBinding()]
   [OutputType([Git.Automation.BranchInfo])]
    param(
        [string]
        # Specifies which git repository to check. Defaults to the current directory.
        $RepoRoot = (Get-Location).ProviderPath,

        [Switch]
        # Get the current branch only. Otherwise all branches are returned.
        $Current
    )

    Set-StrictMode -Version 'Latest'

    $repo = Find-GitRepository -Path $RepoRoot -Verify
    if( -not $repo )
    {
        return
    }

    try
    {
        if( $Current )
        {
            New-Object Git.Automation.BranchInfo $repo.Head
            return
        }
        else
        {
            $repo.Branches | ForEach-Object { New-Object Git.Automation.BranchInfo $_ }
            return
        }

    }
    finally
    {
        $repo.Dispose()
    }
}