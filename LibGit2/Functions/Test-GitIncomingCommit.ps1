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

function Test-GitIncomingCommit
{
    <#
    .SYNOPSIS
    Tests for incoming commits not in your local directory for a given repository.

    .DESCRIPTION
    The `Test-GitIncomingCommit` function checks if there are commits in the remote repository that are not in the local repository.

    If the -All switch is used, all branches are checked. Otherwise, just the current branch.

    It defaults to the current repository. Use the `RepoRoot` parameter to specify an explicit path to another repo.

    This function implements the `git log branch..remotes/origin/branch` command

    .EXAMPLE
    Test-GitIncomingChange -RepoRoot 'C:\Projects\LibGit2'

    Demonstrates how to check for incoming changes for a repository that isn't the current directory.
    #>

    [CmdletBinding()]
    param(
        [string]
        # The repository to test for incoming changes. Defaults to the current directory.
        $RepoRoot = (Get-Location).ProviderPath,

        [Switch]
        # Check for incoming commits on all branches. Otherwise, just current.
        $All
    )

    Set-StrictMode -Version 'Latest'
   
    $repo = Find-GitRepository -Path $RepoRoot -Verify
    if( -not $repo )
    {
        return
    }

    $incomingChange = $false

    try
    {
        # fetch any remote commits
        Receive-GitCommit -RepoRoot $RepoRoot -Fetch

        $currentBranch = $repo.Head.Name
        $filter = New-Object LibGit2Sharp.CommitFilter
        $filter.Until = $repo.Branches[$currentBranch]
        $filter.Since = $repo.Branches["remotes/origin/$currentBranch"]

        $numIn = $repo.Commits.QueryBy($filter) | Measure-Object | Select-Object -ExpandProperty Count    
        if( $numIn -gt 0 )
        {
            $incomingChange = $true
        }

        if( $All )
        {
            $repo.Branches | Where-Object { -not $_.IsRemote -and -not $_.IsCurrentRepositoryHead } | ForEach-Object {
                $branchName = $_.Name
                $filter = New-Object LibGit2Sharp.CommitFilter
                $filter.Until = $_
                $filter.Since = $repo.Branches["remotes/origin/$branchName"]

                $numIn += $repo.Commits.QueryBy($filter) | Measure-Object | Select-Object -ExpandProperty Count
                if( $numIn -gt 0 )
                {
                    $incomingChange =  $true
                }
            }
        }
    }
    finally
    {
        $repo.Dispose()
    }

    return $incomingChange

}