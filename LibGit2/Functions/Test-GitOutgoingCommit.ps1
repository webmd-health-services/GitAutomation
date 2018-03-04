# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

function Test-GitOutgoingCommit
{
    <#
    .SYNOPSIS
    Tests for un-pushed commits in a git repository.

    .DESCRIPTION
    The `Test-GitOutgoingCommit` function checks for un-pushed commits in a git repository.

    It defaults to the current repository and only the current branch. Use the `RepoRoot` parameter to specify an explicit path to another repo, and the `All` switch to test all local branches.

    This function implements the `git log remotes/origin/branch..branch` command.

    .EXAMPLE
    Test-GitOutgoingChange

    Demonstrates how to check for unpushed commits in the current repo on the current branch.

    .EXAMPLE
    Test-GitOutgoingCommit -RepoRoot 'C:\Projects\LibGit2' -All

    Demonstrates how to check for unpushed commits on all branches of a repository that isn't the current directory.
    #>
    [CmdletBinding()]
    param(
        [string]
        # The repository to test for outgoing changes. Defaults to the current directory.
        $RepoRoot = (Get-Location).ProviderPath,

        [Switch]
        # Check for un-pushed commits on all branches. Otherwise, just current.
        $All
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
   
    $repo = Find-GitRepository -Path $RepoRoot -Verify
    if( -not $repo )
    {
        return
    }

    $outgoingChange = $false

    try
    {
        $currentBranch = $repo.Head.FriendlyName
        $filter = New-Object -TypeName 'LibGit2Sharp.CommitFilter'
        $filter.IncludeReachableFrom = $repo.Branches[$currentBranch]
        $filter.ExcludeReachableFrom = $repo.Branches["remotes/origin/$currentBranch"]

        $numOut = $repo.Commits.QueryBy($filter) | Measure-Object | Select-Object -ExpandProperty Count    
        if( $numOut -gt 0 )
        {
            $outgoingChange = $true
        }

        if( $All )
        {
            $repo.Branches | Where-Object { -not $_.IsRemote -and -not $_.IsCurrentRepositoryHead } | ForEach-Object {
                $branchName = $_.FriendlyName
                $filter = New-Object -TypeName 'LibGit2Sharp.CommitFilter'
                $filter.IncludeReachableFrom = $_
                $filter.ExcludeReachableFrom = $repo.Branches["remotes/origin/$branchName"]

                $numOut += $repo.Commits.QueryBy($filter) | Measure-Object | Select-Object -ExpandProperty Count
                if( $numOut -gt 0 )
                {
                    $outgoingChange =  $true
                }
            }
        }
    }
    finally
    {
        $repo.Dispose()
    }

    return $outgoingChange
   
}