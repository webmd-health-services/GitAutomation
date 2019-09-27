
function New-GitSignature
{
    <#
    .SYNOPSIS
    Creates an author signature object used to identify who created a commit.

    .DESCRIPTION
    The `New-GitSignature` object creates `LibGit2Sharp.Signature` objects. These objects are added when committing changes to identify the author of the commit and when the commit was made.

    With no parameters, this function reads author metadata from the "user.name" and "user.email" user level or system level configuration. If there is no user or system-level "user.name" or "user.email" setting, you'll get an error and nothing will be returned.

    To use explicit author information, pass the author's name and email address to the "Name" and "EmailAddress" parameters.

    .EXAMPLE
    New-GitSignature

    Demonstrates how to get create a Git author signature from the current user's user-level and system-level Git configuration files.

    .EXAMPLE
    New-GitSignature -Name 'Jock Nealy' -EmailAddress 'email@example.com'

    Demonstrates how to create a Git author signature using an explicit name and email address.
    #>
    [CmdletBinding(DefaultParameterSetName='FromConfiguration')]
    [OutputType([LibGit2Sharp.Signature])]
    param(
        [Parameter(Mandatory=$true,ParameterSetName='FromParameter')]
        [string]
        # The author's name, i.e. GivenName Surname.
        $Name,

        [Parameter(Mandatory=$true,ParameterSetName='FromParameter')]
        [string]
        # The author's email address.
        $EmailAddress,

        [Parameter(Mandatory=$true,ParameterSetName='FromRepositoryConfiguration')]
        [string]
        $RepoRoot
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    function Get-Signature
    {
        param(
            [LibGit2Sharp.Configuration]
            $Configuration
        )

        $signature = $Configuration.BuildSignature([DateTimeOffset]::Now)
        if( -not $signature )
        {
            Write-Error -Message ('Failed to build author signature from Git configuration files. Please pass custom author information to the "Name" and "EmailAddress" parameters or set author information in Git''s user-level configuration files by running these commands:
 
    git config --global user.name "GIVEN_NAME SURNAME"
    git config --global user.email "email@example.com"
 ') -ErrorAction $ErrorActionPreference
            return
        }
        return $signature
    }

    if( $PSCmdlet.ParameterSetName -eq 'FromRepositoryConfiguration' )
    {
        $repo = Get-GitRepository -RepoRoot $RepoRoot
        if( -not $repo )
        {
            return 
        }

        try
        {
            return Get-Signature -Configuration $repo.Config
        }
        finally
        {
            $repo.Dispose()
        }
    }

    if( $PSCmdlet.ParameterSetName -eq 'FromConfiguration' )
    {
        $blankGitConfigPath = Join-Path -Path $binRoot -ChildPath 'gitconfig' -Resolve
        [LibGit2Sharp.Configuration]$config = [LibGit2Sharp.Configuration]::BuildFrom($blankGitConfigPath)

        try
        {
            return Get-Signature -Configuration $config
        }
        finally
        {
            $config.Dispose()
        }
    }

    New-Object -TypeName 'LibGit2Sharp.Signature' -ArgumentList $Name,$EmailAddress,([DateTimeOffset]::Now)
}