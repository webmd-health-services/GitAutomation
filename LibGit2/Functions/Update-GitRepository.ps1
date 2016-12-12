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

function Update-GitRepository
{
    <#
    .SYNOPSIS

    Creates a detached head state, and updates the repo to the given target

    .DESCRIPTION

    The `Update-GitRepository` function updates the repo to the given target. Unless this target is a branch name, the repo will then be in a detached head state.

    The default target is "HEAD". Use the `Target` parameter to specifiy a different target

    It defaults to the current repository. Use the `RepoRoot` parameter to specify an explicit path to another repo.

    This function implements the `git checkout <target>` command.

    .EXAMPLE

    Update-GitRepository -RepoRoot 'C:\Projects\LibGit2' -Target 'feature/ticket'

    Demonstrates how to checkout the 'feature/ticket' branch of the given repository.

    .EXAMPLE

    Update-GitRepository -RepoRoot 'C:\Projects\LibGit2' -Target 'refs/tags/tag1'

    Demonstrates how to create a detached head at the tag 'tag1'.
    #>

    [CmdletBinding()]
    param(
        [string]
        # Specifies which git repository to update. Defaults to the current directory.
        $RepoRoot = (Get-Location).ProviderPath,

        [string]
        # The target to update the repo to. Defaults to "HEAD"
        $Target = "HEAD"
    )

    Set-StrictMode -Version 'Latest'

    $repo = Find-GitRepository -Path $RepoRoot -Verify
    if( -not $repo )
    {
        return
    }

    try
    {
        $validTarget = $repo.Lookup($Target)
        if( -not $validTarget )
        {
            Write-Error ("No valid git object identified by '{0}' exists in the repository." -f $Target)
            return
        }

        $options = New-Object LibGit2Sharp.CheckoutOptions
        $repo.Checkout($Target, $options)
    }
    finally
    {
        $repo.Dispose()
    }
}