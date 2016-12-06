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

function New-GitBranch
{
    <#
    .SYNOPSIS

    Creates a new branch in the given repository.

    .DESCRIPTION

    The `New-GitBranch` creates a new branch in the given repository and then switches to that branch

    It defaults to the current repository. Use the `RepoRoot` parameter to specify an explicit path to another repo.

    This function implements the `git checkout -b <branchname> <startpoint>` command

    .EXAMPLE

    New-GitBranch -RepoRoot 'C:\Projects\LibGit2' -Name 'develop'

    Demonstrates how to create a new branch named 'develop' in the specified repository.
    #>
    [CmdletBinding()]
    param(
        [string]
        # Specifies which git repository to add a branch to. Defaults to the current directory.
        $RepoRoot = (Get-Location).ProviderPath,

        [Parameter(Mandatory=$true)]
        [string]
        # The name of the new branch.
        $Name,

        [string]
        # The starting point of the branch. Defaults to "HEAD"
        $StartPoint = "HEAD"
    )

    Set-StrictMode -Version 'Latest'

    $repo = Find-GitRepository -Path $RepoRoot -Verify
    if( -not $repo )
    {
        return
    }

    try
    {
        if( Test-GitBranch -RepoRoot $RepoRoot -Name $Name )
        {
            Write-Warning ('Branch {0} already exists in repository {1}' -f $Name, $RepoRoot)
            return
        }

        $newBranch = $repo.Branches.Add($Name, $StartPoint)
        $checkoutOptions = New-Object LibGit2Sharp.CheckoutOptions
        $repo.Checkout($newBranch, $checkoutOptions)
    }
    catch [LibGit2Sharp.LibGit2SharpException]
    {
        Write-Error ("Could not create branch '{0}' from invalid starting point: '{1}'" -f $Name, $StartPoint)
    }
    finally
    {
        $repo.Dispose()
    }
}