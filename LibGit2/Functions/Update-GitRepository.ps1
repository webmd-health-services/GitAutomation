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
    Updates the working directory of a Git repository to a specific commit.

    .DESCRIPTION
    The `Update-GitRepository` function updates a Git repository to a specific commit, i.e. it checks out a specific commit.

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
        # The revision checkout, i.e. update the repository to. A revision can be a specific commit ID/sha (short or long), branch name, tag name, etc. Run git help gitrevisions or go to https://git-scm.com/docs/gitrevisions for full documentation on Git's revision syntax.
        $Revision = "HEAD"
    )

    Set-StrictMode -Version 'Latest'

    $repo = Find-GitRepository -Path $RepoRoot -Verify
    if( -not $repo )
    {
        return
    }

    try
    {
        $validTarget = $repo.Lookup($Revision)
        if( -not $validTarget )
        {
            Write-Error ("No valid git object identified by '{0}' exists in the repository." -f $Revision)
            return
        }

        $options = New-Object LibGit2Sharp.CheckoutOptions
        $repo.Checkout($Revision, $options)
    }
    finally
    {
        $repo.Dispose()
    }
}