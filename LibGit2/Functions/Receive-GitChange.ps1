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
    Recieves remote changes for a repository

    .DESCRIPTION
    The `Recieve-GitChange` function fetches the remotes for the specified repository.

    It defaults to the current repository. Use the `RepoRoot` parameter to specify an explicit path to another repo, and the `All` switch to fetch all remotes.

    This function implements the `git fetch` and `git fetch --all` commands.

    .EXAMPLE
    Test-GitOutgoingChange -RepoRoot 'C:\Projects\LibGit2' -All

    Demonstrates how to fetch all remotes for a repository that isn't the current directory.
    #>
    [CmdletBinding()]
    param(
        [string]
        # The repository to fetch updates for. Defaults to the current directory.
        $RepoRoot = (Get-Location).ProviderPath,

        [Switch]
        # Receive updates for all remotes.
        $All
    )


    Set-StrictMode -Version 'Latest'

    $repo = Find-GitRepository -Path $RepoRoot -Verify
    if( -not $repo )
    {
        return
    }

    try
    {
        if( $All )
        {
            foreach( $remote in $repo.Network.Remotes )
            {
                $repo.Network.Fetch($remote)
            }
        }
        else
        {
            $remote = $repo.Network.Remotes["origin"]
            $repo.Network.Fetch($remote)
        }
    }
    finally
    {
        $repo.Dispose()
    }

}