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

function New-GitTag{
    <#
    .SYNOPSIS
    Creates a new tag.
    
    .DESCRIPTION
    Can create a new tag, or update the target of an existing tag.

    This function implements the `git tag <tagname> <target>` command.
    
    .EXAMPLE
    New-GitTag -Name 'BranchBaseline'
    
    Creates a new tag, `BranchBaseline`, for the HEAD of the current directory.
    
    .EXAMPLE
    New-GitTag -Name 'BranchBaseline' -Target 'branch'
    
    Demonstrates how to create a tag pointing to the head of a branch.
    
    .EXAMPLE
    New-GitTag -Name 'BranchBaseline' -Force
    
    Demonstrates how to change the target a tag points to, to the current HEAD.
    #>

    [CmdletBinding()]
    param(
        [string]
        # Specifies which git repository to add the tag to. Defaults to the current directory.
        $RepoRoot = (Get-Location).ProviderPath,

        [Parameter(Mandatory=$true)]
        [string]
        # The name of the tag.
        $Name,

        [string]
        # The commit this tag should point at. Defaults to "HEAD".
        $Target = "HEAD",

        [Switch]
        # Overwrite existing tag to point at new target
        $Force
    )

    Set-StrictMode -Version 'Latest'

    $repo = Find-GitRepository -Path $RepoRoot -Verify
    if( -not $repo )
    {
        return
    }

    try
    {
        if( -not $Force -and (Test-GitTag -RepoRoot $RepoRoot -Name $Name) )
        {
            Write-Error ("Tag '{0}' already exists. Please use a different tag name." -f $Name)
            return
        }

        $validTarget = $repo.Lookup($Target)
        if( -not $validTarget )
        {
            Write-Error ("No valid git object identified by '{0}' exists in the repository." -f $Target)
            return
        }

        $allowOverwrite = $false
        if( $Force )
        {
            $allowOverwrite = $true
        }
        
        $repo.Tags.Add($Name, $Target, $allowOverwrite)
    }
    finally
    {
        $repo.Dispose()
    }

}