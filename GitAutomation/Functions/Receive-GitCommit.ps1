
function Receive-GitCommit
{
    <#
    .SYNOPSIS
    Downloads all branches (and their commits) from remote repositories.

    .DESCRIPTION
    The `Recieve-GitCommit` function gets all the commits on all branches from all remote repositories and brings them into your repository.

    It defaults to the repository in the current directory. Pass the path to a different repository to the `RepoRoot` parameter.

    This function implements the `git fetch` command.

    .EXAMPLE
    Receive-GitCommit 

    Demonstrates how to get all branches from a remote repository.
    #>
    [CmdletBinding()]
    param(
        [string]
        # The repository to fetch updates for. Defaults to the current directory.
        $RepoRoot = (Get-Location).ProviderPath,

        [pscredential]
        # The credentials to use to connect to the source repository.
        $Credential
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    $repo = Find-GitRepository -Path $RepoRoot -Verify
    if( -not $repo )
    {
        return
    }

    $options = New-Object 'libgit2sharp.FetchOptions'
    if( $Credential )
    {
        $gitCredential = New-Object 'LibGit2Sharp.SecureUsernamePasswordCredentials'
        $gitCredential.Username = $Credential.UserName
        $gitCredential.Password = $Credential.Password
        $options.CredentialsProvider = { return $gitCredential }
    }

    try
    {
        foreach( $remote in $repo.Network.Remotes )
        {
            [string[]]$refspecs = $remote.FetchRefSpecs | Select-Object -ExpandProperty 'Specification'
            [LibGit2Sharp.Commands]::Fetch($repo, $remote.Name, $refspecs, $options, $null)
        } 
    }
    finally
    {
        $repo.Dispose()
    }

}