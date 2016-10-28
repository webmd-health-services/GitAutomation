
function Set-GitConfiguration
{
    <#
    .SYNOPSIS
    Sets Git configuration options

    .DESCRIPTION
    The `Set-GitConfiguration` function sets Git configuration variables. These variables change Git's behavior. Git has hundreds of variables and we can't document them here. Some are shared between Git commands. Some variables are only used by specific commands. The `git help config` help topic lists most of them.

    By default, this function sets options at the repository level. To set options globally, across all repositories, use the `-Global` switch.

    This function implements the `git config` command.

    .EXAMPLE
    Set-GitConfiguration -Name 'core.autocrlf' -Value 'false'

    Demonstrates how to set the `core.autocrlf` setting to `false` for the repository in the current directory.

    .EXAMPLE
    Set-GitConfiguration -Name 'core.autocrlf' -Value 'false' -Global

    Demonstrates how to set a configuration variable so that it applies across all a user's repositories by using the `-Global` switch.

    .EXAMPLE
    Set-GitConfiguration -Name 'core.autocrlf' -Value 'false' -RepoRoot 'C:\Projects\LibGit2.PowerShell'

    Demonstrates how to set a configuration variable for a specific repository. In this case, the configuration for the repository at `C:\Projects\LibGit2.PowerShell` will be updated.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true,Position=0)]
        [string]
        # The name of the configuration variable to set.
        $Name,

        [Parameter(Mandatory=$true,Position=1)]
        [string]
        # The value of the configuration variable.
        $Value,

        [LibGit2Sharp.ConfigurationLevel]
        # Where to set the configuration value. Local means the value will be set for a specific repository. Global means set for the current user. System means set for all users on the current computer. The default is `Local`.
        $Scope = ([LibGit2Sharp.ConfigurationLevel]::Local),

        [string]
        # The path to the repository whose configuration variables to set.
        $RepoRoot
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $repoRootParam = @{}
    if( $RepoRoot )
    {
        $repoRootParam['RepoRoot'] = $RepoRoot
    }

    $repo = Get-GitRepository @repoRootParam
    if( -not $repo )
    {
        return
    }

    try
    {
        $repo.Config.Set($Name,$Value,$Scope)
    }
    finally
    {
        $repo.Dispose()
    }
}
