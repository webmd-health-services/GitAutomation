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

function Test-GitBranch
{
    <#
    .SYNOPSIS

    Checks if a branch exists.

    .DESCRIPTION

    Returns true if branch exists.  False otherwise.

    .EXAMPLE

    Test-GitBranch -RepoRoot 'C:\Projects\LibGit2' -Name 'develop'

    Demonstrates how to check if the 'develop' branch exists in the given repository.
    #>
    [CmdletBinding()]
    param(
        [string]
        # Specifies which git repository to check. Defaults to the current directory.
        $RepoRoot = (Get-Location).ProviderPath,

        [Parameter(Mandatory=$true)]
        [string]
        # The name of the branch.
        $Name
    )

    Set-StrictMode -Version 'Latest'

    $branch = Get-GitBranch -RepoRoot $RepoRoot | Where-Object { $_.Name -ceq $Name }
    if( $branch )
    {
        return $true
    }
    else
    {
        return $false
    }
    
}