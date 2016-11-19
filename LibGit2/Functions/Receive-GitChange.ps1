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

function Receive-GitChange
{
    <#
    .SYNOPSIS
    Pulls remote changes for a repository

    .DESCRIPTION
    The `Recieve-GitChange` function fetches and merges the remote changes for the specified repository that can be fast-forwarded.

    It defaults to the current repository. Use the `RepoRoot` parameter to specify an explicit path to another repo.

    This function implements the `git pull`

    .EXAMPLE
    Test-GitOutgoingChange -RepoRoot 'C:\Projects\LibGit2'

    Demonstrates how to pull remotes changes for a repository that isn't the current directory.
    #>
    [CmdletBinding()]
    param(
        [string]
        # The repository to fetch updates for. Defaults to the current directory.
        $RepoRoot = (Get-Location).ProviderPath
    )


    Set-StrictMode -Version 'Latest'

    $repo = Find-GitRepository -Path $RepoRoot -Verify
    if( -not $repo )
    {
        return
    }

    try
    {
        $pullOptions = New-Object LibGit2Sharp.PullOptions
        $mergeOptions = New-Object LibGit2Sharp.MergeOptions
        $mergeOptions.FastForwardStrategy = [LibGit2Sharp.FastForwardStrategy]::FastForwardOnly
        $pullOptions.MergeOptions = $mergeOptions
        $signature = $repo.Config.BuildSignature((Get-Date))
        $repo.Network.Pull($signature, $pullOptions)
    }
    finally
    {
        $repo.Dispose()
    }

}