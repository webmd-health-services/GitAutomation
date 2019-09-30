
function New-GitRepository
{
    <#
    .SYNOPSIS
    Creates a new Git repository.

    .DESCRIPTION
    The `New-GitRepository` function creates a new Git repository. Set the `Path` parameter to the directory where the repository should be created. If the path does not exist, it is created and that directory becomes the new repository's root. If the path does exist, it also becomes the root of a new repository. If the path exists and it is already a repository, nothing happens.

    To create a bare repository (i.e. a repository that doesn't have a working directory) use the `Bare` switch.

    This function implements the `git init` command.

    .OUTPUTS
    Git.Automation.RepositoryInfo.

    .EXAMPLE
    New-GitRepository -Path 'C:\Projects\MyCoolNewRepo'

    Demonstrates how to create a new Git repository. In this case, a new repository is created in `C:\Projects\MyCoolNewRepo'.

    .EXAMPLE
    New-GitRepository -Path 'C:\Projects\MyCoolNewRepo' -Bare

    Demonstrates how to create a repository that doesn't have a working directory. Git calls these "Bare" repositories.
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    [OutputType([Git.Automation.RepositoryInfo])]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The path to the repository to create.
        $Path,

        [Switch]
        $Bare
    )

    Set-StrictMode -Version 'Latest'

    if( -not [IO.Path]::IsPathRooted($Path) )
    {
        $Path = Join-Path -Path (Get-Location).ProviderPath -ChildPath $Path
        $Path = [IO.Path]::GetFullPath($Path)
    }

    $whatIfMessage = 'create Git repository at ''{0}''' -f $Path
    if( -not $PSCmdlet.ShouldProcess($whatIfMessage, $whatIfMessage, 'New-GitRepository' ) )
    {
        return
    }

    $repoPath = [LibGit2Sharp.Repository]::Init($Path, $Bare.IsPresent)
    $repo = New-Object 'LibGit2Sharp.Repository' $repoPath
    try
    {
        return New-Object 'Git.Automation.RepositoryInfo' $repo.Info
    }
    finally
    {
        $repo.Dispose()
    }
}