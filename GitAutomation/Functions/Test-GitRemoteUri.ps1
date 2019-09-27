
function Test-GitRemoteUri
{
    <#
    .SYNOPSIS
    Tests if the uri leads to a git repository

    .DESCRIPTION
    The `Test-GitRemoteUri` tries to list remote references for the specified uri. A uri that is not a git repo will throw a LibGit2SharpException.

    This function is similar to `git ls-remote` but returns a bool based on if there is any output

    .EXAMPLE
    Test-GitRemoteUri -Uri 'ssh://git@stash.portal.webmd.com:7999/whs/blah.git'

    Demonstrates how to check if there is a repo at the specified uri
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The uri to test
        $Uri
    )

    Set-StrictMode -Version 'Latest'

    try
    {
        [LibGit2Sharp.Repository]::ListRemoteReferences($Uri) | Out-Null
    }
    catch [LibGit2Sharp.LibGit2SharpException]
    {
        return $false
    }
    return $true
}