
function Remove-GitItem
{
    <#
    .SYNOPSIS
    Function to Remove files from both working directory and in the repository

    .DESCRIPTION
    This function will delete the files from the working directory and stage the files to be deleted in the next commit. Multiple filepaths can be passed at once.

    .EXAMPLE
    Remove-GitItem -RepoRoot $repoRoot -Path 'file.ps1'

    .Example
    Remove-GitItem -Path 'file.ps1'

    .Example
    Get-ChildItem '.\GitAutomation\Functions','.\Tests' | Remove-GitItem

    #>

    param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [String[]]
        # The paths to the files/directories to remove in the next commit.
        $Path,

        [string]
        # The path to the repository where the files should be removed. The default is the current directory as returned by Get-Location.
        $RepoRoot = (Get-Location).ProviderPath
    )
    
    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $repo = Find-GitRepository -Path $RepoRoot -Verify

    if( -not $repo )
    {
        return
    }

    foreach( $pathItem in $Path )
    {
        if( -not [IO.Path]::IsPathRooted($pathItem) )
        {
            $pathItem = Join-Path -Path $repo.Info.WorkingDirectory -ChildPath $pathItem
        }
        [LibGit2Sharp.Commands]::Remove($repo, $pathItem, $true, $null)
    }
    $repo.Dispose()
}