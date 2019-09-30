
function New-GitBranch
{
    <#
    .SYNOPSIS

    Creates a new branch in a Git repository.

    .DESCRIPTION

    The `New-GitBranch` creates a new branch in a Git repository and then switches to (i.e. checks out) that branch.

    It defaults to the current repository. Use the `RepoRoot` parameter to specify an explicit path to another repo.

    This function implements the `git branch <branchname> <startpoint>` and `git checkout <branchname>` commands.

    .EXAMPLE

    New-GitBranch -RepoRoot 'C:\Projects\GitAutomation' -Name 'develop'

    Demonstrates how to create a new branch named 'develop' in the specified repository.

    .EXAMPLE

    New-GitBranch -Name 'develop

    Demonstrates how to create a new branch named 'develop' in the current directory.
    #>
    [CmdletBinding()]
    param(
        [string]
        # Specifies which git repository to add a branch to. Defaults to the current directory.
        $RepoRoot = (Get-Location).ProviderPath,

        [Parameter(Mandatory=$true)]
        [string]
        # The name of the new branch.
        $Name,

        [string]
        # The revision where the branch should be started/created. A revision can be a specific commit ID/sha (short or long), branch name, tag name, etc. Run git help gitrevisions or go to https://git-scm.com/docs/gitrevisions for full documentation on Git's revision syntax.
        $Revision = "HEAD"
    )

    Set-StrictMode -Version 'Latest'

    $repo = Find-GitRepository -Path $RepoRoot -Verify
    if( -not $repo )
    {
        return
    }

    try
    {
        if( Test-GitBranch -RepoRoot $RepoRoot -Name $Name )
        {
            Write-Warning ('Branch {0} already exists in repository {1}' -f $Name, $RepoRoot)
            return
        }

        $newBranch = $repo.Branches.Add($Name, $Revision)
        $checkoutOptions = New-Object LibGit2Sharp.CheckoutOptions
        [LibGit2Sharp.Commands]::Checkout($repo, $newBranch, $checkoutOptions)
    }
    catch [LibGit2Sharp.LibGit2SharpException]
    {
        Write-Error ("Could not create branch '{0}' from invalid starting point: '{1}'" -f $Name, $Revision)
    }
    finally
    {
        $repo.Dispose()
    }
}